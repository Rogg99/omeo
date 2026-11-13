"""
Écritures du back-office sur les comptes : actions sur un utilisateur (motif obligatoire, audit), révélation des
données de santé (journalisée), équipe (invitations, rôles, désactivation), double authentification du staff.
"""

from __future__ import annotations

import logging
from datetime import timedelta
from typing import Any, Final

from django.db import transaction
from django.utils import timezone

from apps.accounts import emails, mfa, one_time_tokens, services, tokens
from apps.accounts.models import OneTimeTokenPurpose, Role, StaffRole, TOTPDevice, User
from apps.billing import services as billing
from apps.billing.models import QuotaUsage, Trial
from apps.billing.subscriptions import grant_days
from apps.core import audit
from apps.core.errors import Conflict, NotFound, ValidationFailed
from apps.core.models import AuditLog
from apps.support.services import request_export

logger = logging.getLogger(__name__)

# Action d'admin → permission requise (« users.<action> » dans le contrat).
ACTION_PERMISSIONS: Final[dict[str, str]] = {
    "suspend": "users.suspend",
    "reactivate": "users.suspend",
    "resend_verification": "users.resend_verification",
    "send_password_reset": "users.send_password_reset",
    "extend_trial": "users.extend_trial",
    "grant_plus_days": "users.grant_plus_days",
    "reset_quota": "users.reset_quota",
    "export_data": "users.export_data",
    "delete_data": "users.delete_data",
}
MAX_TRIAL_EXTENSION_DAYS: Final = 14
HEALTH_VIEWS_ALERT_PER_HOUR: Final = 20


def _user(user_id: Any) -> User:
    user = User.objects.select_related("profile").filter(pk=user_id, is_staff=False).first()
    if user is None:
        raise NotFound()
    return user


@transaction.atomic
def user_action(
    *, actor: User, user_id: Any, action: str, reason: str, days: int | None, feature: str | None, request: Any
) -> User:
    user = _user(user_id)
    before = {"is_active": user.is_active}
    if action == "suspend":
        services.suspend_user(user=user, actor=actor, reason=reason, request=request)
        return user
    if action == "reactivate":
        user.is_active = True
        user.suspended_at = None
        user.save(update_fields=["is_active", "suspended_at", "updated_at"])
    elif action == "resend_verification":
        services.send_verification_email(user=user)
    elif action == "send_password_reset":
        services.forgot_password(email=user.email)
    elif action == "extend_trial":
        days = _days(days, maximum=MAX_TRIAL_EXTENSION_DAYS)
        trial = Trial.objects.select_for_update().filter(user=user).first()
        if trial is None:
            raise Conflict(detail="no trial")
        base = max(trial.ends_at, timezone.now())
        Trial.objects.filter(pk=trial.pk).update(
            ends_at=base + timedelta(days=days), extended_by_days=trial.extended_by_days + days
        )
        transaction.on_commit(lambda: billing.invalidate_entitlement(user.pk))
    elif action == "grant_plus_days":
        grant_days(user=user, days=_days(days, maximum=365), reason="support", created_by=actor)
    elif action == "reset_quota":
        if feature not in ("photo_analysis", "text_analysis"):
            raise ValidationFailed(errors={"feature": [{"code": "required", "message": "photo or text"}]})
        state = billing.quota_state(user=user, feature=feature)
        QuotaUsage.objects.filter(user=user, feature=feature, period_start=state.period_start).update(used=0)
    elif action == "export_data":
        request_export(user=user)
    elif action == "delete_data":
        services.schedule_deletion(user=user)
        User.objects.filter(pk=user.pk).update(deletion_scheduled_at=timezone.now())
        services.purge_account(user_id=user.pk)
    else:
        raise ValidationFailed(errors={"action": [{"code": "invalid_choice", "message": action}]})
    audit.record(
        actor=actor,
        action=f"user.{action}",
        target_type="user",
        target_id=user_id,
        before=before,
        after={"days": days, "feature": feature},
        reason=reason,
        request=request,
    )
    return user


def _days(days: int | None, *, maximum: int) -> int:
    if days is None or not 1 <= days <= maximum:
        raise ValidationFailed(errors={"days": [{"code": "out_of_range", "message": f"1..{maximum}"}]})
    return days


def reveal_health(*, actor: User, user_id: Any, reason: str, request: Any) -> User:
    """Révélation des données de santé : motif obligatoire, journalisée ; alerte au-delà de 20 par heure."""
    if not 3 <= len(reason.strip()) <= 500:
        raise ValidationFailed(errors={"reason": [{"code": "required", "message": "3..500 characters"}]})
    user = _user(user_id)
    audit.record(
        actor=actor, action="health.view", target_type="user", target_id=user.pk, reason=reason, request=request
    )
    recent = AuditLog.objects.filter(
        actor=actor, action="health.view", created_at__gte=timezone.now() - timedelta(hours=1)
    ).count()
    if recent > HEALTH_VIEWS_ALERT_PER_HOUR:
        logger.warning("health reveal rate exceeded", extra={"actor_id": str(actor.pk), "count": recent})
    return user


# ───────────────────────── Équipe ─────────────────────────


def _superadmins_active() -> int:
    return User.objects.filter(is_staff=True, is_active=True, staff_roles__role=Role.SUPERADMIN).distinct().count()


@transaction.atomic
def invite_staff(*, actor: User, email: str, roles: list[str], request: Any) -> User:
    email = email.strip().lower()
    if User.objects.filter(email__iexact=email).exists():
        raise Conflict(code="email_taken", detail="account already exists")
    member = User.objects.create_user(email=email, password=None, is_staff=True)
    StaffRole.objects.bulk_create(StaffRole(user=member, role=role) for role in dict.fromkeys(roles))
    raw = one_time_tokens.issue(user=member, purpose=OneTimeTokenPurpose.PASSWORD_RESET)
    transaction.on_commit(lambda: emails.send(user=member, kind="password_reset", token=raw))
    audit.record(
        actor=actor,
        action="team.invite",
        target_type="user",
        target_id=member.pk,
        after={"roles": roles},
        request=request,
    )
    return member


@transaction.atomic
def update_staff(
    *, actor: User, member_id: Any, roles: list[str] | None, active: bool | None, reset_mfa: bool, request: Any
) -> User:
    member = User.objects.select_for_update().filter(pk=member_id, is_staff=True).first()
    if member is None:
        raise NotFound()
    before = {"roles": sorted(member.staff_roles.values_list("role", flat=True)), "active": member.is_active}
    was_superadmin = Role.SUPERADMIN in before["roles"]
    loses_superadmin = was_superadmin and ((roles is not None and Role.SUPERADMIN not in roles) or active is False)
    if loses_superadmin and member.pk == actor.pk:
        raise Conflict(code="self_demotion_forbidden", detail="cannot remove your own superadmin role")
    if loses_superadmin and _superadmins_active() <= 1:
        raise Conflict(code="last_superadmin", detail="cannot remove the last active superadmin")
    if roles is not None:
        member.staff_roles.all().delete()
        StaffRole.objects.bulk_create(StaffRole(user=member, role=role) for role in dict.fromkeys(roles))
    if active is not None and active != member.is_active:
        member.is_active = active
        member.save(update_fields=["is_active", "updated_at"])
        if not active:
            tokens.revoke_all(member, reason="staff_disabled")
    if reset_mfa:
        TOTPDevice.objects.filter(user=member).delete()
        member.recovery_codes.all().delete()
        tokens.revoke_all(member, reason="mfa_reset")
    after = {
        "roles": roles if roles is not None else before["roles"],
        "active": member.is_active,
        "reset_mfa": reset_mfa,
    }
    audit.record(
        actor=actor,
        action="team.update",
        target_type="user",
        target_id=member.pk,
        before=before,
        after=after,
        request=request,
    )
    return member


@transaction.atomic
def setup_mfa(*, member: User, code: str | None) -> dict[str, Any]:
    """Sans code : génère le secret (si la double authentification n'est pas encore confirmée). Avec code : confirme."""
    device = TOTPDevice.objects.filter(user=member).first()
    if code is None:
        if device is not None and device.confirmed_at is not None:
            raise Conflict(code="mfa_already_enabled", detail="ask an administrator to reset it")
        _secret, uri, codes = mfa.enroll(member)
        return {"otpauth_uri": uri, "recovery_codes": codes, "confirmed": False}
    mfa.verify_code(member, code)
    return {"confirmed": True}
