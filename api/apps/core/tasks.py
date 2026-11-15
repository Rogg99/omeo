"""Tâches Celery du socle (idempotentes) : demandes à quatre yeux expirées, réponses d'idempotence échues."""

from __future__ import annotations

import time

import httpx
from celery import shared_task
from django.conf import settings

from apps.core import idempotency
from apps.core.approvals import ApprovalService
from apps.core.web_cache import body_for, sign


@shared_task(acks_late=True, ignore_result=True)
def expire_approvals() -> int:
    return ApprovalService.expire()


@shared_task(acks_late=True, ignore_result=True)
def purge_idempotency_records() -> int:
    return idempotency.purge_expired()


@shared_task(
    acks_late=True,
    ignore_result=True,
    autoretry_for=(httpx.HTTPError,),
    retry_backoff=True,
    retry_kwargs={"max_retries": 5},
)
def revalidate_web(tags: list[str]) -> None:
    """Appelle le webhook signé du site pour invalider son cache (idempotent)."""
    if not settings.REVALIDATE_SECRET or not settings.WEB_INTERNAL_URL:
        return
    body = body_for(tags)
    timestamp = str(int(time.time()))
    response = httpx.post(
        f"{settings.WEB_INTERNAL_URL.rstrip('/')}/hooks/revalidate",
        content=body,
        headers={
            "Content-Type": "application/json",
            "X-Omeo-Timestamp": timestamp,
            "X-Omeo-Signature": sign(settings.REVALIDATE_SECRET, timestamp, body),
        },
        timeout=5,
    )
    response.raise_for_status()
