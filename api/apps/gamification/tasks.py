"""Tâches Celery de gamification (idempotentes : un point n'est jamais attribué deux fois)."""

from __future__ import annotations

from datetime import timedelta
from typing import Final

from celery import shared_task

from apps.accounts.models import User
from apps.core.localtime import local_now
from apps.gamification import services

CLOSE_HOUR: Final = 0  # la veille est clôturée pendant la première heure locale


@shared_task(acks_late=True, ignore_result=True)
def close_days() -> int:
    """Lancée toutes les heures : clôture la veille des utilisateurs dont il est minuit passé, heure locale."""
    closed = 0
    for user in User.objects.filter(is_active=True, is_staff=False).select_related("profile").iterator():
        now = local_now(user)
        if now.hour == CLOSE_HOUR:
            services.close_day(user=user, day=now.date() - timedelta(days=1))
            closed += 1
    return closed
