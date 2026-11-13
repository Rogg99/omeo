"""Gamification : règles pures, plafonds, idempotence, séries avec jour couvert, badges, niveaux, écrans."""

from __future__ import annotations

import uuid
from datetime import date, timedelta
from typing import Any

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.billing.models import GrantedDays
from apps.billing.services import invalidate_entitlement
from apps.core.localtime import local_today
from apps.core.rewards import collect_rewards
from apps.gamification import rules, services
from apps.gamification.models import PointEvent, UserBadge
from apps.nutrition.models import DailySummary

LEVELS = [rules.LevelStep(rank=1, min_points=0), rules.LevelStep(rank=2, min_points=300), rules.LevelStep(rank=3, min_points=1000)]
MONDAY = date(2026, 11, 9)


class TestRules:
    def test_period_start(self) -> None:
        assert rules.period_start(date(2026, 11, 12), "week") == MONDAY
        assert rules.period_start(MONDAY, "none") is None

    def test_cap(self) -> None:
        assert rules.within_cap(already=3, cap=4)
        assert not rules.within_cap(already=4, cap=4)
        assert rules.within_cap(already=999, cap=None)

    def test_levels(self) -> None:
        current, following = rules.level_for(450, LEVELS)
        assert (current.rank, following.rank if following else None) == (2, 3)
        assert rules.progress_percent(450, current, following) == 21
        top, none = rules.level_for(5000, LEVELS)
        assert top.rank == 3
        assert none is None
        assert rules.progress_percent(5000, top, none) == 100

    def test_badge_progress(self) -> None:
        assert rules.badge_progress({"metric": "meals_total", "gte": 4}, {"meals_total": 3})[2] == 0.75
        assert rules.badge_progress({"metric": "meals_total", "gte": 4}, {"meals_total": 9})[2] == 1.0

    def test_streak_counts_until_yesterday_when_today_empty(self) -> None:
        today = date(2026, 11, 13)
        logged = {today - timedelta(days=i) for i in range(1, 6)}
        assert rules.streak(logged_days=logged, today=today, freeze_allowed=False).current == 5

    def test_streak_breaks_without_freeze(self) -> None:
        today = date(2026, 11, 13)
        logged = {today, today - timedelta(days=1), today - timedelta(days=3)}
        assert rules.streak(logged_days=logged, today=today, freeze_allowed=False).current == 2

    def test_streak_freeze_once_per_week(self) -> None:
        today = date(2026, 11, 13)  # vendredi
        logged = {today, today - timedelta(days=1), today - timedelta(days=3), today - timedelta(days=5)}
        result = rules.streak(logged_days=logged, today=today, freeze_allowed=True)
        assert result.current == 3  # le 2e trou de la même semaine casse la série
        assert result.freezes_used == (today - timedelta(days=2),)


@pytest.mark.django_db
class TestAward:
    def test_once_per_reference(self, user: User) -> None:
        ref = uuid.uuid4()
        assert services.award(user=user, action="meal_logged", ref_type="meal", ref_id=ref) == 10
        assert services.award(user=user, action="meal_logged", ref_type="meal", ref_id=ref) == 0
        assert services.stats_for(user).total_points == 10

    def test_daily_cap(self, user: User) -> None:
        gained = [services.award(user=user, action="meal_logged", ref_type="meal", ref_id=uuid.uuid4()) for _ in range(6)]
        assert gained == [10, 10, 10, 10, 0, 0]

    def test_weekly_cap(self, user: User) -> None:
        today = local_today(user)
        assert services.award(user=user, action="weight_logged", ref_type="weight", ref_id=1, day=today) == 5
        assert services.award(user=user, action="weight_logged", ref_type="weight", ref_id=2, day=today) == 0

    def test_rewards_collected(self, user: User) -> None:
        with collect_rewards() as delta:
            services.award(user=user, action="meal_logged", ref_type="meal", ref_id=uuid.uuid4())
        assert delta.points == 10
        assert delta.total_points == 10

    def test_level_up(self, user: User) -> None:
        stats = services.stats_for(user)
        stats.total_points = 295
        stats.save()
        with collect_rewards() as delta:
            services.award(user=user, action="day_complete", ref_type="day", ref_id="d1")
        assert delta.level_up is not None
        assert delta.level_up["rank"] == 2


@pytest.mark.django_db
class TestEvents:
    def _meal(self, client: APIClient) -> Any:
        from apps.core.models import ContentStatus
        from apps.nutrition.models import Food
        from apps.nutrition.services import save_food

        food = save_food(food=Food(name={"fr": "Riz"}, kcal=130, status=ContentStatus.PUBLISHED))
        return client.post(
            "/api/v1/me/meals",
            {"source": "foods", "meal_type": "lunch", "items": [{"food_id": str(food.pk), "grams": 100}]},
            format="json",
            HTTP_IDEMPOTENCY_KEY=str(uuid.uuid4()),
        )

    def test_first_meal_points_badge_and_streak(self, api: APIClient, user: User) -> None:
        rewards = self._meal(api).json()["rewards"]
        assert rewards["points"] >= 10
        assert rewards["streak"] == 1
        assert {b["code"] for b in rewards["badges"]} >= {"first_meal"}
        assert UserBadge.objects.get(user=user, badge__code="first_meal").earned_at is not None

    def test_water_goal_points(self, user: User) -> None:
        DailySummary.objects.create(user=user, date=local_today(user), water_ml=2600, target_water_ml=2500)
        from apps.core import events

        events.publish(events.DayRecomputed(user_id=user.pk, day=local_today(user)))
        assert PointEvent.objects.filter(user=user, action="water_goal").count() == 1

    def test_kcal_goal_only_at_day_close(self, user: User) -> None:
        day = local_today(user) - timedelta(days=1)
        DailySummary.objects.create(user=user, date=day, consumed_kcal=1800, target_kcal=1800, meals_count=3, is_complete=True)
        services.close_day(user=user, day=day)
        services.close_day(user=user, day=day)
        assert PointEvent.objects.filter(user=user, action="kcal_goal").count() == 1

    def test_streak_freeze_for_plus(self, user: User) -> None:
        GrantedDays.objects.create(
            user=user, days=30, reason="support", starts_at=timezone.now(), ends_at=timezone.now() + timedelta(days=30)
        )
        invalidate_entitlement(user.pk)
        today = local_today(user)
        for offset in (0, 2, 3):
            DailySummary.objects.create(user=user, date=today - timedelta(days=offset), meals_count=1)
        assert services.refresh_streak(user=user) == 3


@pytest.mark.django_db
class TestScreens:
    def test_rewards_overview(self, api: APIClient, user: User) -> None:
        body = api.get("/api/v1/me/rewards").json()
        assert body["level"]["rank"] == 1
        assert body["next_level"]["rank"] == 2
        assert body["points_to_next"] == 300
        assert len(body["badges_next"]) <= 3

    def test_badges_and_points(self, api: APIClient, user: User) -> None:
        services.award(user=user, action="meal_logged", ref_type="meal", ref_id=uuid.uuid4())
        badges = api.get("/api/v1/me/badges").json()
        assert all(b["state"] in {"locked", "in_progress", "earned"} for b in badges)
        points = api.get("/api/v1/me/points").json()["results"]
        assert points[0]["label"] == "Repas enregistré"

    def test_me_has_rewards_summary(self, api: APIClient) -> None:
        assert api.get("/api/v1/me").json()["rewards_summary"]["total_points"] == 0
