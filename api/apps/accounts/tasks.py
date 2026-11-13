"""Tâches Celery du compte (idempotentes)."""

from __future__ import annotations

from celery import shared_task
from django.conf import settings
from django.core.mail import send_mail


@shared_task(bind=True, max_retries=5, default_retry_delay=30, acks_late=True)
def send_account_email(self, *, to: str, subject: str, body: str) -> None:  # type: ignore[no-untyped-def]
    try:
        send_mail(subject, body, settings.DEFAULT_FROM_EMAIL, [to], fail_silently=False)
    except OSError as exc:
        raise self.retry(exc=exc) from exc
