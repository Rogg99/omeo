"""Tâches Celery du compte (idempotentes)."""

from __future__ import annotations

from celery import shared_task
from django.conf import settings
from django.core.mail import send_mail
from django.utils import timezone

from apps.accounts.emails import SEND_ACCOUNT_EMAIL_TASK
from apps.accounts.models import User
from apps.accounts.services import purge_account


@shared_task(name=SEND_ACCOUNT_EMAIL_TASK, bind=True, max_retries=5, default_retry_delay=30, acks_late=True)
def send_account_email(self, *, to: str, subject: str, body: str) -> None:  # type: ignore[no-untyped-def]
    try:
        send_mail(subject, body, settings.DEFAULT_FROM_EMAIL, [to], fail_silently=False)
    except OSError as exc:
        raise self.retry(exc=exc) from exc


@shared_task(acks_late=True, ignore_result=True)
def purge_deleted_accounts() -> int:
    """Suppression réelle des comptes 30 jours après la demande (fichiers du stockage compris). Idempotente."""
    purged = 0
    for user_id in User.objects.filter(deletion_scheduled_at__lte=timezone.now()).values_list("pk", flat=True):
        purge_account(user_id=user_id)
        purged += 1
    return purged
