"""
Droits effectifs (`entitlement_for`) et essai.

L'Entitlement fusionne l'essai, les abonnements et les jours offerts. Il est recalculé côté serveur à chaque requête
(cache Redis court, invalidé à chaque événement d'abonnement) et n'est JAMAIS lu dans le JWT.
"""

from __future__ import annotations

from datetime import datetime, timedelta
from typing import Any, Final

from django.core.cache import cache
from django.db import transaction
from django.db.models import Max
from django.utils import timezone

from apps.billing import entitlements
from apps.billing.models import ENTITLING_STATUSES, GrantedDays, Subscription, Trial, TrialSource
from apps.core import events, settings_store

_CACHE_TTL_S: Final = 60


def _cache_key(user_id: Any) -> str:
    return f"entitlement:v1:{user_id}"


def invalidate_entitlement(user_id: Any) -> None:
    cache.delete(_cache_key(user_id))


def _plus_until(user: Any, now: datetime) -> datetime | None:
    subscription_end = (
        Subscription.objects.filter(user=user, status__in=ENTITLING_STATUSES, current_period_end__gt=now)
        .aggregate(end=Max("current_period_end"))
        .get("end")
    )
    grant_end = (
        GrantedDays.objects.filter(user=user, ends_at__gt=now).aggregate(end=Max("ends_at")).get("end")
    )
    candidates = [d for d in (subscription_end, grant_end) if d is not None]
    return max(candidates) if candidates else None


def entitlement_for(user: Any) -> entitlements.Entitlement:
    key = _cache_key(user.pk)
    cached = cache.get(key)
    now = timezone.now()
    if cached is not None:
        trial_ends_at, plus_until = cached
    else:
        trial = Trial.objects.filter(user=user).only("ends_at").first()
        trial_ends_at = trial.ends_at if trial else None
        plus_until = _plus_until(user, now)
        cache.set(key, (trial_ends_at, plus_until), _CACHE_TTL_S)
    switches: dict[str, bool] = settings_store.get("app.features", {})
    return entitlements.build(now=now, trial_ends_at=trial_ends_at, plus_until=plus_until, switches=switches)


def trial_days(*, with_invite: bool) -> int:
    key = "trial.invite_days" if with_invite else "trial.default_days"
    return int(settings_store.get(key, 7 if with_invite else 3))


@transaction.atomic
def start_trial(*, user: Any, with_invite: bool) -> Trial:
    now = timezone.now()
    trial, _ = Trial.objects.get_or_create(
        user=user,
        defaults={
            "starts_at": now,
            "ends_at": now + timedelta(days=trial_days(with_invite=with_invite)),
            "source": TrialSource.REFERRAL if with_invite else TrialSource.SIGNUP,
        },
    )
    transaction.on_commit(lambda: invalidate_entitlement(user.pk))
    return trial


def _on_entitlement_changed(event: events.EntitlementChanged) -> None:
    transaction.on_commit(lambda: invalidate_entitlement(event.user_id))


def connect_events() -> None:
    events.subscribe(events.EntitlementChanged, _on_entitlement_changed)
