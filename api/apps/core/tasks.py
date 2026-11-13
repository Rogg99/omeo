"""Tâches Celery du socle (idempotentes) : demandes à quatre yeux expirées, réponses d'idempotence échues."""

from __future__ import annotations

from celery import shared_task

from apps.core import idempotency
from apps.core.approvals import ApprovalService


@shared_task(acks_late=True, ignore_result=True)
def expire_approvals() -> int:
    return ApprovalService.expire()


@shared_task(acks_late=True, ignore_result=True)
def purge_idempotency_records() -> int:
    return idempotency.purge_expired()
