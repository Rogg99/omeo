"""Nutrition : projection du jour, eau, catalogue, favoris, calendrier, progression."""

from __future__ import annotations

import uuid
from collections.abc import Callable, Iterator
from datetime import timedelta
from decimal import Decimal
from typing import Any

import pytest
from django.utils import timezone
from freezegun import freeze_time
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.billing.models import Trial
from apps.billing.services import invalidate_entitlement
from apps.core.localtime import local_today
from apps.core.models import ContentStatus
from apps.nutrition import calculations as calc
from apps.nutrition import projection, services
from apps.nutrition.models import DailySummary, Dish, DishComponent, Food, NutritionTarget, WaterEntry
from conftest import login_client

pytestmark = pytest.mark.django_db


def make_food(name: str, aliases: list[str] | None = None, **values: Any) -> Food:
    food = Food(name={"fr": name}, aliases=aliases or [], status=ContentStatus.PUBLISHED)
    for key in calc.NUTRIENT_KEYS:
        setattr(food, key, Decimal(str(values.get(key, 0))))
    return services.save_food(food=food)


@pytest.fixture
def ndole() -> Dish:
    leaves = make_food("Feuilles de ndolé", ["ndolé", "bitterleaf"], kcal=48, protein_g=4.5, fiber_g=4)
    peanut = make_food("Pâte d'arachide", ["arachide"], kcal=588, protein_g=25, fat_g=50)
    dish = Dish.objects.create(
        name={"fr": "Ndolé"}, aliases=["ndole"], country="CM", standard_portion_g=200, status="published"
    )
    DishComponent.objects.create(dish=dish, food=leaves, grams=150)
    DishComponent.objects.create(dish=dish, food=peanut, grams=50)
    return services.refresh_dish(dish=dish)


@pytest.fixture
def meal_contributor() -> Iterator[dict[str, Any]]:
    """Simule la part de `meals` dans la projection (le module meals l'enregistre en vrai)."""
    values: dict[str, Any] = {}
    projection.register_contributor("test_meals", lambda user, day: dict(values))
    yield values
    projection._contributors.pop("test_meals", None)


class TestRecomputeDay:
    def test_idempotent(self, user: User, meal_contributor: dict[str, Any]) -> None:
        meal_contributor.update({"consumed_kcal": 900.4, "protein_g": 40.26, "meals_count": 2})
        today = local_today(user)
        first = services.recompute_day(user=user, day=today)
        second = services.recompute_day(user=user, day=today)
        assert first.pk == second.pk
        assert DailySummary.objects.filter(user=user).count() == 1
        assert second.consumed_kcal == 900
        assert second.protein_g == Decimal("40.3")
        assert not second.is_complete

    def test_targets_from_nutrition_target(self, user: User) -> None:
        target = NutritionTarget.objects.get(user=user)
        summary = services.recompute_day(user=user, day=local_today(user))
        assert summary.target_kcal == target.base_kcal
        assert summary.target_water_ml == target.water_ml

    def test_activity_adjustment(self, user: User, meal_contributor: dict[str, Any]) -> None:
        target = NutritionTarget.objects.get(user=user)
        meal_contributor.update({"burned_kcal": target.tdee_kcal + 400, "active_minutes": 60})
        summary = services.recompute_day(user=user, day=local_today(user))
        assert summary.target_kcal == target.base_kcal + 200
        assert summary.target_water_ml == calc.adjusted_water_ml(
            base_water_ml=target.water_ml, active_minutes=60, c=services.nutrition_constants()
        )

    def test_adjustment_disabled(self, user: User, meal_contributor: dict[str, Any]) -> None:
        user.profile.activity_adjustment = False
        user.profile.save()
        target = NutritionTarget.objects.get(user=user)
        meal_contributor.update({"burned_kcal": target.tdee_kcal + 400})
        assert services.recompute_day(user=user, day=local_today(user)).target_kcal == target.base_kcal

    def test_complete_day(self, user: User, meal_contributor: dict[str, Any]) -> None:
        meal_contributor.update({"meals_count": 3})
        assert services.recompute_day(user=user, day=local_today(user)).is_complete


class TestLocalDay:
    def test_day_changes_at_local_midnight(self, user: User) -> None:
        user.profile.timezone = "Asia/Tokyo"
        user.profile.save()
        with freeze_time("2026-11-13 15:30:00"):  # 00:30 à Tokyo le 14
            assert str(local_today(user)) == "2026-11-14"
        user.profile.timezone = "America/Los_Angeles"
        user.profile.save()
        with freeze_time("2026-11-13 05:00:00"):  # 21:00 la veille à Los Angeles
            assert str(local_today(user)) == "2026-11-12"


class TestWater:
    def _post(self, client: APIClient, amount: int, **extra: Any) -> Any:
        return client.post(
            "/api/v1/me/water", {"amount_ml": amount, **extra}, format="json", HTTP_IDEMPOTENCY_KEY=str(uuid.uuid4())
        )

    def test_add_and_gauge(self, api: APIClient, user: User) -> None:
        response = self._post(api, 250)
        assert response.status_code == 201
        body = response.json()
        assert body["water"]["gauge"]["value"] == 250
        assert body["water"]["quick_add_ml"] == [250, 500]
        assert body["rewards"]["points"] == 0
        assert DailySummary.objects.get(user=user).water_ml == 250

    def test_negative_cancels(self, api: APIClient, user: User) -> None:
        self._post(api, 500)
        assert self._post(api, -250).json()["water"]["gauge"]["value"] == 250

    def test_cannot_go_below_zero(self, api: APIClient) -> None:
        response = self._post(api, -250)
        assert response.status_code == 400
        assert response.json()["errors"]["amount_ml"][0]["code"] == "below_zero"

    def test_zero_rejected(self, api: APIClient) -> None:
        assert self._post(api, 0).status_code == 400

    def test_future_date_rejected(self, api: APIClient, user: User) -> None:
        tomorrow = local_today(user) + timedelta(days=1)
        assert self._post(api, 250, date=str(tomorrow)).status_code == 400

    def test_replay_does_not_double_count(self, api: APIClient, user: User) -> None:
        key = str(uuid.uuid4())
        for _ in range(2):
            api.post("/api/v1/me/water", {"amount_ml": 250}, format="json", HTTP_IDEMPOTENCY_KEY=key)
        assert WaterEntry.objects.filter(user=user).count() == 1


class TestCatalog:
    def test_food_search_by_local_name_unaccented(self, api: APIClient, ndole: Dish) -> None:
        results = api.get("/api/v1/foods", {"q": "ndole"}).json()["results"]
        assert results[0]["name"] == "Feuilles de ndolé"
        assert results[0]["matched_alias"] == "ndolé"
        assert results[0]["per_100g"]["kcal"] == 48

    def test_draft_food_hidden(self, api: APIClient) -> None:
        food = Food(name={"fr": "Brouillon secret"}, status=ContentStatus.DRAFT)
        services.save_food(food=food)
        assert api.get("/api/v1/foods", {"q": "brouillon"}).json()["results"] == []

    def test_dish_nutrients_from_components(self, ndole: Dish) -> None:
        # (150 × 48 + 50 × 588) / 200 g
        assert ndole.nutrients_per_100g["kcal"] == pytest.approx((72 + 294) / 2)

    def test_dish_detail(self, api: APIClient, ndole: Dish) -> None:
        body = api.get(f"/api/v1/dishes/{ndole.pk}").json()
        assert body["kcal_per_portion"] == 366
        assert {c["label"] for c in body["components"]} == {"Feuilles de ndolé", "Pâte d'arachide"}

    def test_unpublished_dish_404(self, api: APIClient, ndole: Dish) -> None:
        Dish.objects.filter(pk=ndole.pk).update(status="draft")
        assert api.get(f"/api/v1/dishes/{ndole.pk}").status_code == 404
        assert api.put(f"/api/v1/dishes/{ndole.pk}/favorite").status_code == 404

    def test_favorites(self, api: APIClient, ndole: Dish, make_user: Callable[..., User]) -> None:
        assert api.put(f"/api/v1/dishes/{ndole.pk}/favorite").status_code == 204
        assert api.put(f"/api/v1/dishes/{ndole.pk}/favorite").status_code == 204
        favorites = api.get("/api/v1/dishes", {"scope": "favorites"}).json()["results"]
        assert [d["id"] for d in favorites] == [str(ndole.pk)]
        assert favorites[0]["is_favorite"] is True
        other = login_client(make_user())
        assert other.get("/api/v1/dishes", {"scope": "favorites"}).json()["results"] == []
        api.delete(f"/api/v1/dishes/{ndole.pk}/favorite")
        assert api.get("/api/v1/dishes", {"scope": "favorites"}).json()["results"] == []

    def test_match_food_threshold(self, ndole: Dish) -> None:
        assert services.match_food(label="bitter leaf ndolé") is not None
        assert services.match_food(label="chocolat noir") is None

    def test_match_dish_prefers_country(self, ndole: Dish) -> None:
        assert services.match_dish(label="ndole", country="CM") == ndole


class TestCalendarAndProgress:
    def test_calendar(self, api: APIClient, user: User, meal_contributor: dict[str, Any]) -> None:
        today = local_today(user)
        meal_contributor.update({"meals_count": 1, "consumed_kcal": 500})
        services.recompute_day(user=user, day=today)
        days = api.get("/api/v1/me/calendar", {"month": today.strftime("%Y-%m")}).json()
        assert days[-1] == {"date": str(today), "status": "partial"}
        assert all(d["date"] <= str(today) for d in days)

    def test_progress_7d_for_free(self, api: APIClient, user: User) -> None:
        Trial.objects.filter(user=user).update(ends_at=timezone.now() - timedelta(days=1))
        invalidate_entitlement(user.pk)
        body = api.get("/api/v1/me/progress", {"metric": "kcal"}).json()
        assert len(body["series"]) == 7
        assert body["empty"] is True
        assert len(body["summary_last_7"]) == 7

    def test_progress_long_range_requires_plus(self, api: APIClient, user: User) -> None:
        Trial.objects.filter(user=user).update(ends_at=timezone.now() - timedelta(days=1))
        invalidate_entitlement(user.pk)
        response = api.get("/api/v1/me/progress", {"metric": "kcal", "range": "30d"})
        assert response.status_code == 403
        assert response.json()["code"] == "plan_required"
        assert response.json()["meta"]["feature"] == "progress_long_range"

    def test_progress_values(self, api: APIClient, user: User, meal_contributor: dict[str, Any]) -> None:
        today = local_today(user)
        meal_contributor.update({"meals_count": 3, "consumed_kcal": 1000})
        services.recompute_day(user=user, day=today - timedelta(days=1))
        meal_contributor.update({"consumed_kcal": 1200})
        services.recompute_day(user=user, day=today)
        body = api.get("/api/v1/me/progress", {"metric": "kcal", "range": "30d"}).json()
        assert body["today"] == 1200
        assert body["delta_vs_yesterday"] == 200
        assert body["delta_percent"] == 20
        assert body["average"] == 1100
        assert len(body["series"]) == 30


class TestPureDayHelpers:

    def test_day_status(self, reference: None) -> None:
        c = services.nutrition_constants()
        assert calc.day_status(meals_count=0, consumed_kcal=0, target_kcal=1800, c=c) == "empty"
        assert calc.day_status(meals_count=2, consumed_kcal=900, target_kcal=1800, c=c) == "partial"
        assert calc.day_status(meals_count=3, consumed_kcal=1800, target_kcal=1800, c=c) == "on_target"
        assert calc.day_status(meals_count=3, consumed_kcal=2500, target_kcal=1800, c=c) == "over"
        assert calc.day_status(meals_count=3, consumed_kcal=1000, target_kcal=1800, c=c) == "under"

    def test_balance(self) -> None:
        assert calc.balance(consumed_kcal=1800, burned_kcal=None) is None
        assert calc.balance(consumed_kcal=1800, burned_kcal=1750)["status"] == "balanced"  # type: ignore[index]
        assert calc.balance(consumed_kcal=1500, burned_kcal=2100)["status"] == "deficit"  # type: ignore[index]

    def test_display_rounding(self) -> None:
        shown = calc.display_nutrients({"kcal": 365.6, "protein_g": 12.345})
        assert shown["kcal"] == 366
        assert shown["protein_g"] == 12.3
