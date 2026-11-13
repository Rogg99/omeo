"""
Validation à quatre yeux (`ApprovalService`).

Chaque type d'action enregistre un exécuteur (`register_executor`). `create` mémorise l'action et renvoie la demande
(réponse 202) ; `approve` la rejoue dans la même transaction, puis écrit l'audit. Celui qui décide n'est jamais celui
qui demande : vérifié ici (403 `self_approval_forbidden`) et par une contrainte en base.
"""

from __future__ import annotations

from collections.abc import Callable
from datetime import timedelta
from typing import Any, Final

from django.db import IntegrityError, transaction
from django.utils import timezone

from apps.core import audit, settings_store
from apps.core.errors import ApprovalPending, Conflict, ForbiddenRole, SelfApprovalForbidden
from apps.core.models import ApprovalDomain, ApprovalKind, ApprovalRequest, ApprovalStatus

EXPIRY: Final = timedelta(days=7)
DECIDE_PERMISSION: Final = "approvals.decide"

Executor = Callable[[ApprovalRequest, Any], dict[str, Any] | None]
_executors: dict[str, Executor] = {}

DOMAIN_OF_KIND: Final[dict[str, str]] = {
    ApprovalKind.CONTENT_PUBLISH: ApprovalDomain.CONTENT,
    ApprovalKind.CAMPAIGN_SCHEDULE: ApprovalDomain.CONTENT,
    ApprovalKind.PLAN_UPDATE: ApprovalDomain.FINANCE,
    ApprovalKind.QUOTA_UPDATE: ApprovalDomain.FINANCE,
    ApprovalKind.REFUND: ApprovalDomain.FINANCE,
    ApprovalKind.SETTINGS_NUTRITION: ApprovalDomain.SETTINGS,
}


def register_executor(kind: str, executor: Executor) -> None:
    _executors[kind] = executor


def is_enabled(domain: str) -> bool:
    """Réglage `four_eyes.<domaine>` : désactivable par un superadmin pour une équipe trop petite."""
    return bool(settings_store.get(f"four_eyes.{domain}", True))


class ApprovalService:
    @staticmethod
    @transaction.atomic
    def create(
        *,
        kind: str,
        payload: dict[str, Any],
        diff: dict[str, Any],
        target_type: str,
        target_id: str,
        reason: str,
        requested_by: Any,
        request: Any = None,
    ) -> ApprovalRequest:
        try:
            with transaction.atomic():
                approval = ApprovalRequest.objects.create(
                    kind=kind,
                    domain=DOMAIN_OF_KIND[kind],
                    payload=payload,
                    diff=diff,
                    target_type=target_type,
                    target_id=str(target_id),
                    reason=reason,
                    requested_by=requested_by,
                    expires_at=timezone.now() + EXPIRY,
                )
        except IntegrityError:
            raise ApprovalPending() from None
        audit.record(
            actor=requested_by,
            action=f"approval.request.{kind}",
            target_type=target_type,
            target_id=target_id,
            after={"approval_id": str(approval.id), "diff": diff},
            reason=reason,
            request=request,
        )
        return approval

    @staticmethod
    def _lock_pending(approval_id: Any) -> ApprovalRequest:
        approval = ApprovalRequest.objects.select_for_update().get(pk=approval_id)
        if approval.status != ApprovalStatus.PENDING:
            raise Conflict(detail="approval is not pending")
        if approval.expires_at <= timezone.now():
            approval.status = ApprovalStatus.EXPIRED
            approval.save(update_fields=["status", "updated_at"])
            raise Conflict(detail="approval expired")
        return approval

    @staticmethod
    def _check_decider(approval: ApprovalRequest, decider: Any) -> None:
        from apps.accounts.permissions import can_decide_domain

        if approval.requested_by_id == decider.pk:
            raise SelfApprovalForbidden()
        if not can_decide_domain(decider, approval.domain):
            raise ForbiddenRole(meta={"permission": DECIDE_PERMISSION, "domain": approval.domain})

    @classmethod
    @transaction.atomic
    def approve(cls, *, approval_id: Any, decider: Any, comment: str = "", request: Any = None) -> ApprovalRequest:
        approval = cls._lock_pending(approval_id)
        cls._check_decider(approval, decider)
        result = _executors[approval.kind](approval, decider)
        approval.status = ApprovalStatus.APPROVED
        approval.decided_by = decider
        approval.decided_at = timezone.now()
        approval.decision_comment = comment
        approval.save(update_fields=["status", "decided_by", "decided_at", "decision_comment", "updated_at"])
        audit.record(
            actor=decider,
            action=f"approval.approve.{approval.kind}",
            target_type=approval.target_type,
            target_id=approval.target_id,
            before=approval.diff.get("before") if isinstance(approval.diff, dict) else None,
            after=result or (approval.diff.get("after") if isinstance(approval.diff, dict) else None),
            reason=comment or approval.reason,
            request=request,
        )
        return approval

    @classmethod
    @transaction.atomic
    def reject(cls, *, approval_id: Any, decider: Any, comment: str, request: Any = None) -> ApprovalRequest:
        approval = cls._lock_pending(approval_id)
        cls._check_decider(approval, decider)
        approval.status = ApprovalStatus.REJECTED
        approval.decided_by = decider
        approval.decided_at = timezone.now()
        approval.decision_comment = comment
        approval.save(update_fields=["status", "decided_by", "decided_at", "decision_comment", "updated_at"])
        audit.record(
            actor=decider,
            action=f"approval.reject.{approval.kind}",
            target_type=approval.target_type,
            target_id=approval.target_id,
            reason=comment,
            request=request,
        )
        return approval

    @staticmethod
    @transaction.atomic
    def cancel(*, approval_id: Any, actor: Any, request: Any = None) -> ApprovalRequest:
        approval = ApprovalRequest.objects.select_for_update().get(pk=approval_id)
        if approval.requested_by_id != actor.pk:
            raise ForbiddenRole()
        if approval.status != ApprovalStatus.PENDING:
            raise Conflict(detail="approval is not pending")
        approval.status = ApprovalStatus.CANCELED
        approval.save(update_fields=["status", "updated_at"])
        audit.record(
            actor=actor,
            action=f"approval.cancel.{approval.kind}",
            target_type=approval.target_type,
            target_id=approval.target_id,
            request=request,
        )
        return approval

    @staticmethod
    def expire() -> int:
        """Tâche planifiée : passe en `expired` les demandes en attente depuis plus de 7 jours."""
        return ApprovalRequest.objects.filter(status=ApprovalStatus.PENDING, expires_at__lte=timezone.now()).update(
            status=ApprovalStatus.EXPIRED, updated_at=timezone.now()
        )
