"""
Droits effectifs (`entitlement_for`) et essai.

L'Entitlement fusionne l'essai, les abonnements et les jours offerts. Il est recalculé côté serveur à chaque requête
(cache Redis court, invalidé à chaque événement d'abonnement) et n'est JAMAIS lu dans le JWT.
"""

from __future__ import annotations

from dataclasses import dataclass, replace
from datetime import date, datetime, timedelta
from typing import Any, Final

from django.core.cache import cache
from django.core.exceptions import ImproperlyConfigured
from django.db import transaction
from django.db.models import Max
from django.utils import timezone

from apps.billing import entitlements, quotas
from apps.billing.models import (
    ENTITLING_STATUSES,
    GrantedDays,
    QuotaFeature,
    QuotaRule,
    QuotaUsage,
    Subscription,
    Trial,
    TrialSource,
)
from apps.core import events, settings_store
from apps.core.errors import QuotaExceeded
from apps.core.localtime import local_today, user_zone

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


# ───────────────────────── Quotas ─────────────────────────


@dataclass(frozen=True, slots=True)
class QuotaState:
    feature: str
    limit: int | None
    used: int
    period: str
    period_start: date
    resets_at: datetime | None
    tier: str

    @property
    def remaining(self) -> int | None:
        return quotas.remaining(self.limit, self.used)

    def as_dict(self) -> dict[str, Any]:
        return {
            "feature": self.feature,
            "limit": self.limit,
            "used": self.used,
            "remaining": self.remaining,
            "period": self.period,
            "resets_at": self.resets_at,
        }


def _anchor(user: Any, tier: str) -> date | None:
    """Début de la période : essai, ou date anniversaire de l'abonnement (ou des jours offerts)."""
    zone = user_zone(user)
    now = timezone.now()
    if tier == "trial":
        trial = Trial.objects.filter(user=user).only("starts_at").first()
        return trial.starts_at.astimezone(zone).date() if trial else None
    if tier == "plus":
        subscription = (
            Subscription.objects.filter(user=user, status__in=ENTITLING_STATUSES, current_period_end__gt=now)
            .order_by("-current_period_end")
            .only("current_period_start")
            .first()
        )
        if subscription:
            return subscription.current_period_start.astimezone(zone).date()
        grant = GrantedDays.objects.filter(user=user, ends_at__gt=now).order_by("starts_at").first()
        return grant.starts_at.astimezone(zone).date() if grant else None
    return None


def _rule(tier: str, feature: str) -> QuotaRule:
    rule = QuotaRule.objects.filter(plan_tier=tier, feature=feature).first()
    if rule is None:
        raise ImproperlyConfigured(f"Missing QuotaRule {tier}.{feature} (seed_reference)")
    return rule


def quota_state(*, user: Any, feature: str) -> QuotaState:
    tier = entitlement_for(user).tier
    rule = _rule(tier, feature)
    period = quotas.period_for(
        tier=tier, period=rule.period, today=local_today(user), zone=user_zone(user), anchor=_anchor(user, tier)
    )
    usage = QuotaUsage.objects.filter(user=user, feature=feature, period_start=period.start).first()
    return QuotaState(
        feature=feature,
        limit=rule.limit,
        used=usage.used if usage else 0,
        period=rule.period,
        period_start=period.start,
        resets_at=period.resets_at,
        tier=tier,
    )


def quota_exceeded(state: QuotaState) -> QuotaExceeded:
    return QuotaExceeded(
        meta={
            "feature": state.feature,
            "resets_at": state.resets_at.isoformat() if state.resets_at else None,
            "upgrade": state.tier != "plus",
        }
    )


@transaction.atomic
def consume_quota(*, user: Any, feature: str) -> QuotaState:
    """Décompte une unité dans la transaction appelante (verrou de ligne), ou lève 429 `quota_exceeded`."""
    state = quota_state(user=user, feature=feature)
    QuotaUsage.objects.get_or_create(user=user, feature=feature, period_start=state.period_start)
    usage = QuotaUsage.objects.select_for_update().get(user=user, feature=feature, period_start=state.period_start)
    if state.limit is not None and usage.used >= state.limit:
        raise quota_exceeded(replace(state, used=usage.used))
    usage.used += 1
    usage.save(update_fields=["used", "updated_at"])
    return replace(state, used=usage.used)


@transaction.atomic
def refund_quota(*, user: Any, feature: str, period_start: date) -> None:
    """Rend une unité (analyse échouée). Sans effet si la période a déjà été remise à zéro."""
    usage = (
        QuotaUsage.objects.select_for_update().filter(user=user, feature=feature, period_start=period_start).first()
    )
    if usage is not None and usage.used > 0:
        usage.used -= 1
        usage.save(update_fields=["used", "updated_at"])


def all_quota_states(*, user: Any) -> list[QuotaState]:
    return [quota_state(user=user, feature=feature) for feature in QuotaFeature.values]
