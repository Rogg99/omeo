"""Tâches Celery d'activity (idempotentes)."""

from __future__ import annotations

from datetime import timedelta

from celery import shared_task

from apps.accounts.models import User
from apps.activity import services
from apps.billing.services import entitlement_for
from apps.core.localtime import local_today


@shared_task(acks_late=True, ignore_result=True)
def weekly_insights() -> int:
    """Chaque lundi : analyses croisées de la semaine écoulée (comptes ayant le droit `insights`)."""
    count = 0
    for user in (
        User.objects.filter(is_active=True, is_staff=False, deletion_scheduled_at__isnull=True)
        .select_related("profile")
        .iterator()
    ):
        if not entitlement_for(user).allows("insights"):
            continue
        today = local_today(user)
        week_start = today - timedelta(days=today.weekday() + 7)
        count += len(services.generate_weekly_insights(user=user, week_start=week_start))
    return count
