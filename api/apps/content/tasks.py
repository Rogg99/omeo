"""Tâches Celery de content (idempotentes) : conseils de prévention quotidiens, bilans hebdomadaires."""

from __future__ import annotations

from collections.abc import Iterator
from datetime import timedelta
from typing import Final

from celery import shared_task

from apps.accounts.models import User
from apps.billing.services import entitlement_for
from apps.content import services
from apps.core.localtime import local_now

RUN_HOUR: Final = 6  # heure locale d'évaluation des conseils


def _active_users() -> Iterator[User]:
    return (
        User.objects.filter(is_active=True, is_staff=False, deletion_scheduled_at__isnull=True)
        .select_related("profile")
        .iterator()
    )


@shared_task(acks_late=True, ignore_result=True)
def evaluate_prevention() -> int:
    """Toutes les heures : évalue les conseils des utilisateurs pour qui il est 6 h, heure locale."""
    count = 0
    for user in _active_users():
        now = local_now(user)
        if now.hour == RUN_HOUR:
            count += len(services.evaluate_prevention(user=user, today=now.date()))
    return count


@shared_task(acks_late=True, ignore_result=True)
def weekly_reports() -> int:
    """Le lundi : bilan de la semaine écoulée pour les comptes ayant le droit `weekly_report`."""
    count = 0
    for user in _active_users():
        if not entitlement_for(user).allows("weekly_report"):
            continue
        today = local_now(user).date()
        services.generate_weekly_report(user=user, week_start=today - timedelta(days=today.weekday() + 7))
        count += 1
    return count
