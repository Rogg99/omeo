"""
Tâches Celery de billing (idempotentes) :
- fin d'essai et expiration (notifications d'abonnement, une seule fois grâce aux clés de déduplication) ;
- rapprochement des abonnements stores avec Google Play et l'App Store ;
- nettoyage des compteurs de quotas des périodes révolues (la remise à zéro découle de la période elle-même).
"""

from __future__ import annotations

import logging
from datetime import timedelta
from typing import Final

from celery import shared_task
from django.utils import timezone
from django.utils.translation import gettext_noop

from apps.billing import subscriptions
from apps.billing.models import ENTITLING_STATUSES, Channel, QuotaUsage, Subscription, Trial
from apps.billing.providers import google_play
from apps.billing.providers.base import ProviderError
from apps.notifications.services import notify

logger = logging.getLogger(__name__)
TRIAL_WARNING: Final = timedelta(hours=24)
QUOTA_RETENTION: Final = timedelta(days=120)


@shared_task(acks_late=True, ignore_result=True)
def trial_notifications() -> int:
    """Prévient la veille de la fin d'essai, puis le jour où l'essai est terminé."""
    now = timezone.now()
    sent = 0
    ending = Trial.objects.filter(ends_at__gt=now, ends_at__lte=now + TRIAL_WARNING).select_related("user")
    for trial in ending:
        sent += (
            notify(
                user=trial.user,
                category="subscription",
                title=gettext_noop("Ton essai se termine demain"),
                body=gettext_noop("Passe à Omeo Plus pour garder toutes tes fonctions."),
                deeplink="omeo://subscription",
                dedupe_key=f"trial_ending:{trial.pk}",
            )
            is not None
        )
    ended = Trial.objects.filter(ends_at__lte=now, ends_at__gt=now - timedelta(days=1)).select_related("user")
    for trial in ended:
        sent += (
            notify(
                user=trial.user,
                category="subscription",
                title=gettext_noop("Ton essai est terminé"),
                body=gettext_noop("Tu passes à l'offre Free. Tes données sont conservées."),
                deeplink="omeo://subscription",
                dedupe_key=f"trial_ended:{trial.pk}",
            )
            is not None
        )
    return sent


@shared_task(acks_late=True, ignore_result=True)
def reconcile_store_subscriptions() -> int:
    """Revérifie auprès de Google Play les abonnements qui arrivent à échéance (filet de sécurité des RTDN)."""
    now = timezone.now()
    checked = 0
    due = Subscription.objects.filter(
        channel=Channel.GOOGLE_PLAY,
        status__in=ENTITLING_STATUSES,
        current_period_end__lte=now + timedelta(days=1),
    ).select_related("user")
    for subscription in due:
        try:
            verified = google_play.verify_subscription(purchase_token=subscription.external_id)
        except ProviderError:
            logger.warning("store reconciliation failed", extra={"subscription_id": str(subscription.pk)})
            continue
        subscriptions.apply_verified(user=subscription.user, verified=verified)
        checked += 1
    return checked


@shared_task(acks_late=True, ignore_result=True)
def purge_old_quota_usage() -> int:
    deleted, _ = QuotaUsage.objects.filter(period_start__lt=(timezone.now() - QUOTA_RETENTION).date()).delete()
    return deleted
