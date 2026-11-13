"""Matrice offre → fonctionnalités et droits effectifs (essai, Plus, jours offerts)."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import Any

import pytest
from django.utils import timezone

from apps.billing import entitlements
from apps.billing.models import GrantedDays, Plan, Subscription, Trial
from apps.billing.services import entitlement_for, invalidate_entitlement

NOW = datetime(2026, 11, 13, 12, tzinfo=UTC)
ALL_ON: dict[str, bool] = {}


class TestPureMatrix:
    def test_free_has_nothing(self) -> None:
        e = entitlements.build(now=NOW, trial_ends_at=None, plus_until=None, switches=ALL_ON)
        assert e.tier == "free"
        assert not any(e.features.values())

    def test_trial(self) -> None:
        e = entitlements.build(now=NOW, trial_ends_at=NOW + timedelta(days=1), plus_until=None, switches=ALL_ON)
        assert e.tier == "trial"
        assert e.allows("programs")
        assert e.allows("text_analysis")
        assert not e.allows("offline_workouts")
        assert not e.allows("streak_freeze")

    def test_plus_wins_over_trial(self) -> None:
        e = entitlements.build(
            now=NOW, trial_ends_at=NOW + timedelta(days=1), plus_until=NOW + timedelta(days=30), switches=ALL_ON
        )
        assert e.tier == "plus"
        assert all(e.features.values())

    def test_expired_plus_is_free(self) -> None:
        e = entitlements.build(now=NOW, trial_ends_at=None, plus_until=NOW - timedelta(seconds=1), switches=ALL_ON)
        assert e.tier == "free"
        assert e.plus_until is None

    def test_global_switch_disables_feature(self) -> None:
        e = entitlements.build(now=NOW, trial_ends_at=None, plus_until=NOW + timedelta(days=1), switches={"programs": False})
        assert not e.allows("programs")
        assert e.allows("insights")

    def test_unknown_feature_denied(self) -> None:
        e = entitlements.build(now=NOW, trial_ends_at=None, plus_until=NOW + timedelta(days=1), switches=ALL_ON)
        assert not e.allows("teleportation")


@pytest.mark.django_db
class TestEntitlementFor:
    def _expire_trial(self, user: Any) -> None:
        Trial.objects.filter(user=user).update(ends_at=timezone.now() - timedelta(minutes=1))
        invalidate_entitlement(user.pk)

    def test_new_account_is_in_trial(self, user: Any) -> None:
        assert entitlement_for(user).tier == "trial"

    def test_after_trial_free(self, user: Any) -> None:
        self._expire_trial(user)
        assert entitlement_for(user).tier == "free"

    def test_active_subscription(self, user: Any) -> None:
        self._expire_trial(user)
        Subscription.objects.create(
            user=user,
            plan=Plan.objects.get(code="plus_monthly"),
            channel="google_play",
            status="active",
            current_period_start=timezone.now() - timedelta(days=1),
            current_period_end=timezone.now() + timedelta(days=29),
            external_id="token-1",
        )
        invalidate_entitlement(user.pk)
        assert entitlement_for(user).tier == "plus"

    def test_canceled_keeps_access_until_period_end(self, user: Any) -> None:
        self._expire_trial(user)
        Subscription.objects.create(
            user=user,
            plan=Plan.objects.get(code="plus_monthly"),
            channel="app_store",
            status="canceled",
            current_period_start=timezone.now() - timedelta(days=20),
            current_period_end=timezone.now() + timedelta(days=10),
            external_id="otx-1",
            auto_renew=False,
        )
        invalidate_entitlement(user.pk)
        assert entitlement_for(user).tier == "plus"

    def test_refunded_gives_nothing(self, user: Any) -> None:
        self._expire_trial(user)
        Subscription.objects.create(
            user=user,
            plan=Plan.objects.get(code="plus_monthly"),
            channel="web",
            status="refunded",
            current_period_start=timezone.now() - timedelta(days=1),
            current_period_end=timezone.now() + timedelta(days=29),
            external_id="pay-1",
        )
        invalidate_entitlement(user.pk)
        assert entitlement_for(user).tier == "free"

    def test_granted_days(self, user: Any) -> None:
        self._expire_trial(user)
        GrantedDays.objects.create(
            user=user, days=7, reason="referral", starts_at=timezone.now(), ends_at=timezone.now() + timedelta(days=7)
        )
        invalidate_entitlement(user.pk)
        assert entitlement_for(user).tier == "plus"

    def test_never_read_from_cache_after_invalidation(self, user: Any) -> None:
        assert entitlement_for(user).tier == "trial"
        self._expire_trial(user)
        assert entitlement_for(user).tier == "free"
