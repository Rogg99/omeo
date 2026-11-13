"""Sorties publiques de billing (état d'abonnement), réutilisées par la fiche utilisateur du back-office."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any

from apps.billing import serializers as s
from apps.billing import subscriptions
from apps.billing.services import entitlement_for, quota_states
from apps.core import settings_store
from apps.core.i18n import active_locale


def subscription_state(user: Any) -> dict[str, Any]:
    locale = active_locale()
    entitlement = entitlement_for(user)
    subscription = subscriptions.active_subscription(user)
    now = datetime.now(UTC)
    trial_days = (
        (entitlement.trial_ends_at - now).days if entitlement.tier == "trial" and entitlement.trial_ends_at else None
    )
    can_manage = "none"
    if subscription is not None:
        can_manage = "store" if subscription.channel in subscriptions.STORE_CHANNELS else "web"
    country = getattr(user.profile, "country", "")
    return {
        "entitlements": entitlement.as_dict(),
        "subscription": s.subscription_out(subscription, locale=locale),
        "trial_days_left": max(trial_days, 0) if trial_days is not None else None,
        "granted_days_left": (entitlement.plus_until - now).days
        if subscription is None and entitlement.plus_until
        else None,
        "quotas": [q.as_dict() for q in quota_states(user=user)],
        "can_purchase_in_app": subscription is None or subscription.channel in subscriptions.STORE_CHANNELS,
        "can_manage": can_manage,
        "web_checkout_allowed": country in settings_store.get("app.web_checkout_countries", []),
    }
