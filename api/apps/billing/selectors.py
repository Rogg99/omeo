"""Lectures billing."""

from __future__ import annotations

from typing import Any

from django.utils import timezone

from apps.billing.models import ENTITLING_STATUSES, Channel, Subscription

STORE_CHANNELS: tuple[str, ...] = (Channel.GOOGLE_PLAY, Channel.APP_STORE)


def active_store_channel(user: Any) -> str | None:
    """Canal store d'un abonnement encore renouvelé : à résilier par l'utilisateur dans le store avant suppression."""
    subscription = (
        Subscription.objects.filter(
            user=user,
            channel__in=STORE_CHANNELS,
            status__in=ENTITLING_STATUSES,
            auto_renew=True,
            current_period_end__gt=timezone.now(),
        )
        .only("channel")
        .first()
    )
    return subscription.channel if subscription else None
