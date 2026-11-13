"""Back-office des comptes : profil du membre, double authentification, équipe, recherche et fiche utilisateur."""

from __future__ import annotations

from typing import Any, ClassVar

from django.db.models import Count, Q, QuerySet
from django.utils import timezone
from drf_spectacular.utils import extend_schema
from rest_framework import serializers, status
from rest_framework.permissions import BasePermission, IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response

from apps.accounts import admin_services, selectors
from apps.accounts.admin_services import ACTION_PERMISSIONS
from apps.accounts.models import Role, TOTPDevice, User
from apps.accounts.permissions import can_decide_domain, permissions_for_user
from apps.accounts.presenters import targets_out
from apps.accounts.serializers import session_out
from apps.billing.presenters import subscription_state
from apps.billing.services import entitlement_for
from apps.core.errors import NotFound
from apps.core.localtime import local_today
from apps.core.models import ApprovalRequest
from apps.core.pagination import apply_ordering, page_body, page_paginate
from apps.core.permissions import AUTHENTICATED_STAFF, STEP_UP_WINDOW, HasPermission, RequiresStepUp
from apps.core.views import AdminAPIView, validated
from apps.nutrition.selectors import target_on
from apps.support.presenters import ticket_summary_out

DOMAINS = ("content", "finance", "settings")


def staff_out(member: User, *, session: Any = None) -> dict[str, Any]:
    roles = sorted(member.staff_roles.values_list("role", flat=True))
    verified = getattr(session, "mfa_verified_at", None)
    pending = 0
    if session is not None:
        decidable = [d for d in DOMAINS if can_decide_domain(member, d)]
        pending = (
            ApprovalRequest.objects.filter(status="pending", domain__in=decidable).exclude(requested_by=member).count()
        )
    return {
        "id": member.id,
        "email": member.email,
        "name": member.email.split("@")[0],
        "roles": roles,
        "permissions": sorted(permissions_for_user(member)),
        "mfa_verified_until": verified + STEP_UP_WINDOW if verified else None,
        "pending_approvals": pending,
        "mfa_enabled": TOTPDevice.objects.filter(user=member, confirmed_at__isnull=False).exists(),
        "active": member.is_active,
        "last_login_at": member.last_seen_at,
    }


class AdminMeView(AdminAPIView):
    required_permission = AUTHENTICATED_STAFF

    @extend_schema(operation_id="adminGetMe")
    def get(self, request: Request) -> Response:
        return Response(staff_out(request.user, session=getattr(request, "auth_session", None)))  # type: ignore[arg-type]


class MfaSetupSerializer(serializers.Serializer[Any]):
    code = serializers.RegexField(r"^[0-9A-Za-z-]{6,12}$", required=False)


class MfaSetupView(AdminAPIView):
    required_permission = AUTHENTICATED_STAFF

    @extend_schema(operation_id="adminSetupMfa", request=MfaSetupSerializer)
    def post(self, request: Request) -> Response:
        data = validated(MfaSetupSerializer, request.data or {})
        return Response(admin_services.setup_mfa(member=request.user, code=data.get("code")))  # type: ignore[arg-type]


class InviteSerializer(serializers.Serializer[Any]):
    email = serializers.EmailField()
    roles = serializers.ListField(child=serializers.ChoiceField(choices=Role.choices), min_length=1)


class StaffUpdateSerializer(serializers.Serializer[Any]):
    roles = serializers.ListField(child=serializers.ChoiceField(choices=Role.choices), required=False)
    active = serializers.BooleanField(required=False)
    reset_mfa = serializers.BooleanField(required=False, default=False)


class TeamView(AdminAPIView):
    permission_classes: ClassVar[list[type[BasePermission]]] = [IsAuthenticated, HasPermission, RequiresStepUp]
    required_permission = "team.manage"

    @extend_schema(operation_id="adminListTeam")
    def get(self, request: Request) -> Response:
        members = User.objects.filter(is_staff=True).prefetch_related("staff_roles").order_by("email")
        return Response([staff_out(m) for m in members])

    @extend_schema(operation_id="adminInviteStaff", request=InviteSerializer)
    def post(self, request: Request) -> Response:
        data = validated(InviteSerializer, request.data)
        member = admin_services.invite_staff(
            actor=request.user, email=data["email"], roles=data["roles"], request=request
        )  # type: ignore[arg-type]
        return Response(staff_out(member), status=status.HTTP_201_CREATED)


class TeamMemberView(AdminAPIView):
    permission_classes: ClassVar[list[type[BasePermission]]] = [IsAuthenticated, HasPermission, RequiresStepUp]
    required_permission = "team.manage"

    @extend_schema(operation_id="adminUpdateStaff", request=StaffUpdateSerializer)
    def patch(self, request: Request, id: Any) -> Response:  # noqa: A002 - nom imposé par le contrat
        data = validated(StaffUpdateSerializer, request.data)
        member = admin_services.update_staff(
            actor=request.user,  # type: ignore[arg-type]
            member_id=id,
            roles=data.get("roles"),
            active=data.get("active"),
            reset_mfa=data["reset_mfa"],
            request=request,
        )
        return Response(staff_out(member))


# ───────────────────────── Utilisateurs ─────────────────────────


def _status(user: User) -> str:
    if not user.is_active:
        return "suspended"
    return "deletion_pending" if user.deletion_scheduled_at else "active"


def user_row_out(user: User) -> dict[str, Any]:
    profile = getattr(user, "profile", None)
    last_session = getattr(user, "last_platform", None)
    return {
        "id": user.id,
        "email": user.email,
        "name": f"{profile.first_name} {profile.last_name}" if profile else "",
        "country": (profile.country or None) if profile else None,
        "locale": user.locale,
        "tier": entitlement_for(user).tier,
        "status": _status(user),
        "platform": last_session,
        "last_seen_at": user.last_seen_at,
        "created_at": user.created_at,
    }


class UserFilterSerializer(serializers.Serializer[Any]):
    q = serializers.CharField(max_length=120, required=False)
    plan = serializers.ChoiceField(choices=["trial", "free", "plus"], required=False)
    status = serializers.ChoiceField(choices=["active", "suspended", "deletion_pending"], required=False)
    country = serializers.CharField(min_length=2, max_length=2, required=False)


def _users(params: dict[str, Any]) -> QuerySet[User]:
    queryset = User.objects.filter(is_staff=False).select_related("profile")
    if params.get("q"):
        term = params["q"].strip()
        queryset = queryset.filter(
            Q(email__icontains=term) | Q(profile__first_name__icontains=term) | Q(profile__last_name__icontains=term)
        )
    status_filter = params.get("status")
    if status_filter == "suspended":
        queryset = queryset.filter(is_active=False)
    elif status_filter == "deletion_pending":
        queryset = queryset.filter(is_active=True, deletion_scheduled_at__isnull=False)
    elif status_filter == "active":
        queryset = queryset.filter(is_active=True, deletion_scheduled_at__isnull=True)
    if params.get("country"):
        queryset = queryset.filter(profile__country=params["country"].upper())
    now = timezone.now()
    plan = params.get("plan")
    if plan == "plus":
        queryset = queryset.filter(
            Q(
                subscriptions__status__in=["active", "grace", "canceled", "trial"],
                subscriptions__current_period_end__gt=now,
            )
            | Q(granted_days__ends_at__gt=now)
        ).distinct()
    elif plan == "trial":
        queryset = queryset.filter(trial__ends_at__gt=now)
    elif plan == "free":
        queryset = queryset.exclude(trial__ends_at__gt=now).exclude(
            Q(subscriptions__current_period_end__gt=now) | Q(granted_days__ends_at__gt=now)
        )
    return queryset


class UsersView(AdminAPIView):
    required_permission = "users.view"

    @extend_schema(operation_id="adminListUsers")
    def get(self, request: Request) -> Response:
        params = validated(UserFilterSerializer, request.query_params)
        queryset = apply_ordering(
            request, _users(params), allowed=["created_at", "last_seen_at", "email"], default="-created_at"
        )
        rows, meta = page_paginate(request, queryset)
        return Response(page_body([user_row_out(u) for u in rows], meta))


def user_detail_out(user: User) -> dict[str, Any]:
    stats = user.meals.aggregate(meals=Count("id"))
    return {
        **user_row_out(user),
        "email_verified": user.email_verified_at is not None,
        "goals": list(user.profile.goals),
        "health_masked": True,
        "subscription": subscription_state(user),
        "sessions": [session_out(s, current_id=None) for s in selectors.active_sessions(user)],
        "consents": selectors.consent_states(user),
        "tickets": [ticket_summary_out(t) for t in user.tickets.order_by("-updated_at")[:20]],
        "stats": {
            "meals": stats["meals"],
            "analyses": user.analyses.count(),
            "streak": getattr(getattr(user, "stats", None), "current_streak", 0),
            "points": getattr(getattr(user, "stats", None), "total_points", 0),
        },
    }


class UserDetailView(AdminAPIView):
    required_permission = "users.view"

    @extend_schema(operation_id="adminGetUser")
    def get(self, request: Request, id: Any) -> Response:  # noqa: A002
        user = User.objects.select_related("profile").filter(pk=id, is_staff=False).first()
        if user is None:
            raise NotFound()
        return Response(user_detail_out(user))


class HealthQuerySerializer(serializers.Serializer[Any]):
    reason = serializers.CharField(min_length=3, max_length=500)


class UserHealthView(AdminAPIView):
    permission_classes: ClassVar[list[type[BasePermission]]] = [IsAuthenticated, HasPermission, RequiresStepUp]
    required_permission = "users.view_health"

    @extend_schema(operation_id="adminRevealUserHealth")
    def get(self, request: Request, id: Any) -> Response:  # noqa: A002
        params = validated(HealthQuerySerializer, request.query_params)
        user = admin_services.reveal_health(actor=request.user, user_id=id, reason=params["reason"], request=request)  # type: ignore[arg-type]
        profile = user.profile
        return Response(
            {
                "birth_date": profile.birth_date,
                "sex": profile.sex,
                "height_cm": float(profile.height_cm),
                "current_weight_kg": float(profile.current_weight_kg),
                "target_weight_kg": float(profile.target_weight_kg),
                "targets": targets_out(target_on(user=user, day=local_today(user))),
            }
        )


class UserActionSerializer(serializers.Serializer[Any]):
    action = serializers.ChoiceField(choices=sorted(ACTION_PERMISSIONS))
    days = serializers.IntegerField(min_value=1, max_value=365, required=False)
    feature = serializers.ChoiceField(choices=["photo_analysis", "text_analysis"], required=False)
    reason = serializers.CharField(min_length=3, max_length=500)


class UserActionView(AdminAPIView):
    """Permission dynamique « users.<action> » ; step-up exigé pour les actions sensibles (🔐)."""

    dynamic_step_up = True

    def resolve_permission(self, request: Request) -> str | None:
        action = request.data.get("action") if isinstance(request.data, dict) else None
        return ACTION_PERMISSIONS.get(str(action)) if action else "users.view"

    @extend_schema(operation_id="adminUserAction", request=UserActionSerializer)
    def post(self, request: Request, id: Any) -> Response:  # noqa: A002
        data = validated(UserActionSerializer, request.data)
        user = admin_services.user_action(
            actor=request.user,  # type: ignore[arg-type]
            user_id=id,
            action=data["action"],
            reason=data["reason"],
            days=data.get("days"),
            feature=data.get("feature"),
            request=request,
        )
        if not User.objects.filter(pk=user.pk).exists():
            return Response({**user_row_out(user), "status": "deletion_pending"})
        user.refresh_from_db()
        return Response(user_detail_out(user))
