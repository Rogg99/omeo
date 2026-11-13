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
    grant_end = GrantedDays.objects.filter(user=user, ends_at__gt=now).aggregate(end=Max("ends_at")).get("end")
    candidates = [d for d in (subscription_end, grant_end) if d is not None]
    return max(candidates) if candidates else None


@dataclass(frozen=True, slots=True)
class _EntitlementData:
    """Dates mises en cache : droits et ancres des périodes de quotas (aucune requête sur le chemin chaud)."""

    trial_starts_at: datetime | None
    trial_ends_at: datetime | None
    plus_until: datetime | None
    plus_anchor: datetime | None


def _plus_anchor(user: Any, now: datetime) -> datetime | None:
    subscription = (
        Subscription.objects.filter(user=user, status__in=ENTITLING_STATUSES, current_period_end__gt=now)
        .order_by("-current_period_end")
        .only("current_period_start")
        .first()
    )
    if subscription:
        return subscription.current_period_start
    grant = GrantedDays.objects.filter(user=user, ends_at__gt=now).order_by("starts_at").only("starts_at").first()
    return grant.starts_at if grant else None


def _entitlement_data(user: Any, now: datetime) -> _EntitlementData:
    key = _cache_key(user.pk)
    cached = cache.get(key)
    if isinstance(cached, _EntitlementData):
        return cached
    trial = Trial.objects.filter(user=user).only("starts_at", "ends_at").first()
    plus_until = _plus_until(user, now)
    data = _EntitlementData(
        trial_starts_at=trial.starts_at if trial else None,
        trial_ends_at=trial.ends_at if trial else None,
        plus_until=plus_until,
        plus_anchor=_plus_anchor(user, now) if plus_until else None,
    )
    cache.set(key, data, _CACHE_TTL_S)
    return data


def entitlement_for(user: Any) -> entitlements.Entitlement:
    now = timezone.now()
    data = _entitlement_data(user, now)
    switches: dict[str, bool] = settings_store.get("app.features", {})
    return entitlements.build(now=now, trial_ends_at=data.trial_ends_at, plus_until=data.plus_until, switches=switches)


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
    data = _entitlement_data(user, timezone.now())
    moment = data.trial_starts_at if tier == "trial" else data.plus_anchor if tier == "plus" else None
    return moment.astimezone(user_zone(user)).date() if moment else None


_RULES_CACHE_KEY: Final = "quota_rules:v1"


def invalidate_quota_rules() -> None:
    cache.delete(_RULES_CACHE_KEY)


def _rules() -> dict[tuple[str, str], tuple[int | None, str]]:
    cached = cache.get(_RULES_CACHE_KEY)
    if cached is None:
        cached = {(r.plan_tier, r.feature): (r.limit, r.period) for r in QuotaRule.objects.all()}
        cache.set(_RULES_CACHE_KEY, cached, _CACHE_TTL_S * 10)
    return dict(cached)


def _rule(tier: str, feature: str) -> tuple[int | None, str]:
    rule = _rules().get((tier, feature))
    if rule is None:
        raise ImproperlyConfigured(f"Missing QuotaRule {tier}.{feature} (seed_reference)")
    return rule


def quota_limit(*, user: Any, feature: str) -> int | None:
    """Limite applicable à l'offre courante (None = illimité)."""
    limit, _period = _rule(entitlement_for(user).tier, feature)
    return limit


def quota_state(*, user: Any, feature: str) -> QuotaState:
    tier = entitlement_for(user).tier
    limit, period_kind = _rule(tier, feature)
    period = quotas.period_for(
        tier=tier, period=period_kind, today=local_today(user), zone=user_zone(user), anchor=_anchor(user, tier)
    )
    usage = QuotaUsage.objects.filter(user=user, feature=feature, period_start=period.start).first()
    return QuotaState(
        feature=feature,
        limit=limit,
        used=usage.used if usage else 0,
        period=period_kind,
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
    usage = QuotaUsage.objects.select_for_update().filter(user=user, feature=feature, period_start=period_start).first()
    if usage is not None and usage.used > 0:
        usage.used -= 1
        usage.save(update_fields=["used", "updated_at"])


def quota_states(*, user: Any, features: list[str] | None = None) -> list[QuotaState]:
    """État de plusieurs quotas avec une seule requête sur QuotaUsage (règles et ancres en cache)."""
    features = features or list(QuotaFeature.values)
    tier = entitlement_for(user).tier
    today, zone, anchor = local_today(user), user_zone(user), _anchor(user, tier)
    plans: list[tuple[str, int | None, str, quotas.Period]] = []
    for feature in features:
        limit, period_kind = _rule(tier, feature)
        period = quotas.period_for(tier=tier, period=period_kind, today=today, zone=zone, anchor=anchor)
        plans.append((feature, limit, period_kind, period))
    starts = {period.start for *_rest, period in plans}
    used = {
        (row.feature, row.period_start): row.used
        for row in QuotaUsage.objects.filter(user=user, feature__in=features, period_start__in=starts)
    }
    return [
        QuotaState(
            feature=feature,
            limit=limit,
            used=used.get((feature, period.start), 0),
            period=period_kind,
            period_start=period.start,
            resets_at=period.resets_at,
            tier=tier,
        )
        for feature, limit, period_kind, period in plans
    ]


def all_quota_states(*, user: Any) -> list[QuotaState]:
    return quota_states(user=user)
