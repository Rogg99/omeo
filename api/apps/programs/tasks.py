"""Tâches Celery des programmes et challenges (idempotentes)."""

from __future__ import annotations

from datetime import timedelta
from typing import Final

from celery import shared_task

from apps.accounts.models import User
from apps.core.localtime import local_now
from apps.programs import services

CLOSE_HOUR: Final = 0


@shared_task(acks_late=True, ignore_result=True)
def close_days() -> int:
    """Toutes les heures : fige la veille (jours en attente → ratés) et clôture ce qui est échu, par fuseau."""
    closed = 0
    users = User.objects.filter(is_active=True, is_staff=False, participations__status="active").distinct()
    enrolled = User.objects.filter(is_active=True, is_staff=False, enrollments__status="active").distinct()
    for user in (users | enrolled).distinct().select_related("profile").iterator():
        now = local_now(user)
        if now.hour == CLOSE_HOUR:
            services.close_day(user=user, day=now.date() - timedelta(days=1))
            closed += 1
    return closed
