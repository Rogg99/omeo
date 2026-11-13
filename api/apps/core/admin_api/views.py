"""Back-office du socle : validations à quatre yeux, journal d'audit, réglages de l'application."""

from __future__ import annotations

from typing import Any, ClassVar, Final

from django.db import transaction
from django.db.models import Q
from drf_spectacular.utils import extend_schema
from rest_framework import serializers
from rest_framework.permissions import BasePermission, IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response

from apps.core import access, audit, settings_store
from apps.core.approvals import ApprovalService, is_enabled
from apps.core.errors import ForbiddenRole, NotFound, ValidationFailed
from apps.core.models import ApprovalKind, ApprovalRequest, AuditLog
from apps.core.pagination import apply_ordering, page_body, page_paginate
from apps.core.permissions import AUTHENTICATED_STAFF, HasPermission, RequiresStepUp
from apps.core.presenters import approval_out, staff_name
from apps.core.views import AdminAPIView, validated

SETTING_SECTIONS: Final = (
    "four_eyes",
    "billing",
    "nutrition",
    "ai",
    "app",
    "trial",
    "referral",
    "challenges",
    "notifications",
)
SUPERADMIN_ONLY_SECTIONS: Final = frozenset({"four_eyes"})


class ApprovalFilterSerializer(serializers.Serializer[Any]):
    status = serializers.ChoiceField(choices=["pending", "approved", "rejected", "expired", "canceled"], required=False)
    mine = serializers.BooleanField(required=False, default=False)


class DecisionSerializer(serializers.Serializer[Any]):
    decision = serializers.ChoiceField(choices=["approve", "reject"])
    comment = serializers.CharField(max_length=500, required=False, allow_blank=True, default="")


class ApprovalsView(AdminAPIView):
    required_permission = "approvals.decide"

    @extend_schema(operation_id="adminListApprovals")
    def get(self, request: Request) -> Response:
        params = validated(ApprovalFilterSerializer, request.query_params)
        user = request.user
        domains = [d for d in ("content", "finance", "settings") if access.can_decide_domain(user, d)]
        queryset = ApprovalRequest.objects.select_related("requested_by", "decided_by")
        queryset = (
            queryset.filter(requested_by=user)
            if params["mine"]
            else queryset.filter(Q(domain__in=domains) | Q(requested_by=user))
        )
        if params.get("status"):
            queryset = queryset.filter(status=params["status"])
        rows, meta = page_paginate(request, queryset.order_by("-created_at"))
        return Response(page_body([approval_out(a) for a in rows], meta))


class ApprovalDecisionView(AdminAPIView):
    permission_classes: ClassVar[list[type[BasePermission]]] = [IsAuthenticated, HasPermission, RequiresStepUp]
    required_permission = "approvals.decide"

    @extend_schema(operation_id="adminDecideApproval", request=DecisionSerializer)
    def post(self, request: Request, id: Any) -> Response:  # noqa: A002 - nom imposé par le contrat
        data = validated(DecisionSerializer, request.data)
        if not ApprovalRequest.objects.filter(pk=id).exists():
            raise NotFound()
        if data["decision"] == "approve":
            approval = ApprovalService.approve(
                approval_id=id, decider=request.user, comment=data["comment"], request=request
            )
        else:
            approval = ApprovalService.reject(
                approval_id=id, decider=request.user, comment=data["comment"], request=request
            )
        return Response(approval_out(approval))


class ApprovalCancelView(AdminAPIView):
    required_permission = AUTHENTICATED_STAFF

    @extend_schema(operation_id="adminCancelApproval", request=None)
    def post(self, request: Request, id: Any) -> Response:  # noqa: A002
        if not ApprovalRequest.objects.filter(pk=id).exists():
            raise NotFound()
        return Response(approval_out(ApprovalService.cancel(approval_id=id, actor=request.user, request=request)))


class AuditFilterSerializer(serializers.Serializer[Any]):
    actor_id = serializers.UUIDField(required=False)
    action = serializers.CharField(max_length=80, required=False)
    target_type = serializers.CharField(max_length=60, required=False)
    target_id = serializers.CharField(max_length=64, required=False)
    to = serializers.DateTimeField(required=False)


class AuditView(AdminAPIView):
    required_permission = "audit.view"

    @extend_schema(operation_id="adminListAudit")
    def get(self, request: Request) -> Response:
        params = validated(AuditFilterSerializer, request.query_params)
        queryset = AuditLog.objects.select_related("actor")
        for field in ("actor_id", "target_type", "target_id"):
            if params.get(field):
                queryset = queryset.filter(**{field: params[field]})
        if params.get("action"):
            queryset = queryset.filter(action__startswith=params["action"])
        if request.query_params.get("from"):
            queryset = queryset.filter(
                created_at__gte=serializers.DateTimeField().to_internal_value(request.query_params["from"])
            )
        if params.get("to"):
            queryset = queryset.filter(created_at__lte=params["to"])
        rows, meta = page_paginate(
            request, apply_ordering(request, queryset, allowed=["created_at"], default="-created_at")
        )
        return Response(
            page_body(
                [
                    {
                        "id": e.id,
                        "actor": staff_name(e.actor),
                        "action": e.action,
                        "target_type": e.target_type,
                        "target_id": e.target_id,
                        "before": e.before,
                        "after": e.after,
                        "ip": e.ip or "",
                        "created_at": e.created_at,
                    }
                    for e in rows
                ],
                meta,
            )
        )


def settings_out() -> dict[str, Any]:
    values = settings_store.all_values()
    out: dict[str, Any] = {section: {} for section in SETTING_SECTIONS}
    for key, value in values.items():
        section, _, name = key.partition(".")
        if section in out and name:
            out[section][name] = value
    return out


class SettingsView(AdminAPIView):
    permission_classes: ClassVar[list[type[BasePermission]]] = [IsAuthenticated, HasPermission, RequiresStepUp]
    permission_map: ClassVar[dict[str, str] | None] = {"GET": "settings.view", "PATCH": "settings.edit"}
    step_up_actions: ClassVar[set[str]] = {"PATCH"}

    @extend_schema(operation_id="adminGetSettings")
    def get(self, request: Request) -> Response:
        return Response(settings_out())

    @extend_schema(operation_id="adminUpdateSettings")
    def patch(self, request: Request) -> Response:
        data = dict(request.data) if isinstance(request.data, dict) else {}
        reason = str(data.pop("reason", "")).strip()
        if not 3 <= len(reason) <= 500:
            raise ValidationFailed(errors={"reason": [{"code": "required", "message": "3..500 characters"}]})
        unknown = set(data) - set(SETTING_SECTIONS)
        if unknown or not all(isinstance(v, dict) for v in data.values()):
            raise ValidationFailed(errors={"settings": [{"code": "invalid", "message": f"unknown {sorted(unknown)}"}]})
        if SUPERADMIN_ONLY_SECTIONS & set(data) and "superadmin" not in _roles(request.user):
            raise ForbiddenRole(meta={"section": "four_eyes"})
        current = settings_store.all_values()
        changes = {f"{section}.{name}": value for section, values in data.items() for name, value in values.items()}
        nutrition = {k: v for k, v in changes.items() if k.startswith("nutrition.")}
        direct = {k: v for k, v in changes.items() if k not in nutrition}
        with transaction.atomic():
            for key, value in direct.items():
                settings_store.set_value(key, value, updated_by_id=request.user.pk)
            if direct:
                audit.record(
                    actor=request.user,
                    action="settings.update",
                    target_type="setting",
                    target_id=",".join(sorted(direct)),
                    before={k: current.get(k) for k in direct},
                    after=direct,
                    reason=reason,
                    request=request,
                )
            if nutrition and is_enabled("settings"):
                approval = ApprovalService.create(
                    kind=ApprovalKind.SETTINGS_NUTRITION,
                    payload={"changes": nutrition},
                    diff={"before": {k: current.get(k) for k in nutrition}, "after": nutrition},
                    target_type="setting",
                    target_id="nutrition",
                    reason=reason,
                    requested_by=request.user,
                    request=request,
                )
                return Response(approval_out(approval), status=202)
            for key, value in nutrition.items():
                settings_store.set_value(key, value, updated_by_id=request.user.pk)
        return Response(settings_out())


def _roles(user: Any) -> list[str]:
    return list(user.staff_roles.values_list("role", flat=True))


def apply_settings_nutrition(approval: ApprovalRequest, decider: Any) -> dict[str, Any]:
    """Exécuteur à quatre yeux : applique les constantes nutritionnelles approuvées."""
    changes: dict[str, Any] = approval.payload["changes"]
    for key, value in changes.items():
        settings_store.set_value(key, value, updated_by_id=decider.pk)
    return changes
