"""Content : prévention (règles pures), recettes et plantes (verrous, favoris, découvertes), FAQ, légal, repas."""

from __future__ import annotations

import uuid
from datetime import date, timedelta
from decimal import Decimal
from typing import Any

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.billing.models import Trial
from apps.billing.services import invalidate_entitlement
from apps.content import prevention, services
from apps.content.models import FaqItem, Plant, PreventionTip, Recipe, RecipeIngredient, UserTip
from apps.core.localtime import local_today
from apps.core.models import ContentStatus
from apps.gamification.services import stats_for
from apps.nutrition.models import DailySummary, Food
from apps.nutrition.services import save_food

TODAY = date(2026, 11, 13)
SALT = {"metric": "salt_g", "op": "gte", "value": 5, "consecutive_days": 3}


def day(offset: int, meals: int = 3, **values: float) -> prevention.DayValues:
    return prevention.DayValues(day=TODAY - timedelta(days=offset), meals_count=meals, values=values)


class TestPreventionRules:
    def test_consecutive_days(self) -> None:
        assert prevention.trigger_matches(SALT, [day(1, salt_g=6), day(2, salt_g=5.5), day(3, salt_g=7)], today=TODAY)

    def test_break_in_streak(self) -> None:
        assert not prevention.trigger_matches(SALT, [day(1, salt_g=6), day(2, salt_g=3), day(3, salt_g=7)], today=TODAY)

    def test_unlogged_day_does_not_count(self) -> None:
        days = [day(1, salt_g=6), day(2, meals=0, salt_g=9), day(3, salt_g=7)]
        assert not prevention.trigger_matches(SALT, days, today=TODAY)

    def test_activity_metric_ignores_meals(self) -> None:
        trigger = {"metric": "steps", "op": "lte", "value": 3000, "consecutive_days": 2}
        assert prevention.trigger_matches(trigger, [day(1, meals=0, steps=100), day(2, meals=0, steps=200)], today=TODAY)

    def test_enough_data(self) -> None:
        assert not prevention.has_enough_data([day(1), day(2)], today=TODAY)
        assert prevention.has_enough_data([day(1), day(2), day(5)], today=TODAY)

    def test_weekly_report(self) -> None:
        report = prevention.weekly_report(
            [day(1, salt_g=6, consumed_kcal=1800, on_target=1), day(2, salt_g=5, consumed_kcal=2000)],
            targets={"salt_max_g": 5},
        )
        assert report["average_salt_g"] == 5.5
        assert report["salt_over_limit"] is True
        assert report["days_on_target"] == 1


@pytest.fixture
def recipes(db: Any) -> dict[str, Recipe]:
    rice = save_food(food=Food(name={"fr": "Riz"}, kcal=130, protein_g=2.7, status=ContentStatus.PUBLISHED))
    free = Recipe.objects.create(name={"fr": "Riz simple"}, servings=2, is_free=True, status="published", tags=["quick"])
    paid = Recipe.objects.create(name={"fr": "Riz premium"}, servings=1, status="published")
    for recipe in (free, paid):
        RecipeIngredient.objects.create(recipe=recipe, food=rice, grams=Decimal(400), display={"fr": "Riz"}, order=1)
        services.refresh_recipe_nutrients(recipe=recipe)
    return {"free": free, "paid": paid}


def expire_trial(user: User) -> None:
    Trial.objects.filter(user=user).update(ends_at=timezone.now() - timedelta(days=1))
    invalidate_entitlement(user.pk)


@pytest.mark.django_db
class TestRecipes:
    def test_nutrients_per_serving(self, recipes: dict[str, Recipe]) -> None:
        assert recipes["free"].nutrients_per_serving["kcal"] == pytest.approx(260)

    def test_free_user_locked_and_403(self, api: APIClient, user: User, recipes: dict[str, Recipe]) -> None:
        expire_trial(user)
        listing = {r["name"]: r["locked"] for r in api.get("/api/v1/recipes").json()["results"]}
        assert listing == {"Riz simple": False, "Riz premium": True}
        response = api.get(f"/api/v1/recipes/{recipes['paid'].pk}")
        assert response.status_code == 403
        assert response.json()["code"] == "plan_required"
        assert api.get(f"/api/v1/recipes/{recipes['free'].pk}").status_code == 200

    def test_view_counts_once_for_discovery(self, api: APIClient, user: User, recipes: dict[str, Recipe]) -> None:
        for _ in range(2):
            api.get(f"/api/v1/recipes/{recipes['free'].pk}")
        assert stats_for(user).counters["contents_viewed"] == 1

    def test_favorites_filter(self, api: APIClient, recipes: dict[str, Recipe]) -> None:
        api.put(f"/api/v1/recipes/{recipes['free'].pk}/favorite")
        favorites = api.get("/api/v1/recipes", {"favorites": "true"}).json()["results"]
        assert [r["name"] for r in favorites] == ["Riz simple"]

    def test_unpublished_404(self, api: APIClient, recipes: dict[str, Recipe]) -> None:
        Recipe.objects.filter(pk=recipes["free"].pk).update(status="review")
        assert api.get(f"/api/v1/recipes/{recipes['free'].pk}").status_code == 404

    def test_meal_from_recipe_one_serving(self, api: APIClient, recipes: dict[str, Recipe]) -> None:
        response = api.post(
            "/api/v1/me/meals",
            {"source": "recipe", "meal_type": "lunch", "recipe_id": str(recipes["free"].pk)},
            format="json",
            HTTP_IDEMPOTENCY_KEY=str(uuid.uuid4()),
        )
        assert response.status_code == 201
        assert response.json()["meal"]["nutrients"]["kcal"] == 260

    def test_meal_from_locked_recipe_refused(self, api: APIClient, user: User, recipes: dict[str, Recipe]) -> None:
        expire_trial(user)
        response = api.post(
            "/api/v1/me/meals",
            {"source": "recipe", "meal_type": "lunch", "recipe_id": str(recipes["paid"].pk)},
            format="json",
            HTTP_IDEMPOTENCY_KEY=str(uuid.uuid4()),
        )
        assert response.status_code == 404


@pytest.mark.django_db
class TestPlantsAndPublic:
    def test_plant_detail_disclaimer(self, api: APIClient) -> None:
        plant = Plant.objects.create(
            common_name={"fr": "Moringa"}, scientific_name="Moringa oleifera", contraindications=["pregnancy"], status="published"
        )
        body = api.get(f"/api/v1/plants/{plant.pk}").json()
        assert body["disclaimer"]
        assert body["contraindications"] == [{"code": "pregnancy", "label": "Grossesse"}]

    def test_faq_public_grouped(self, anon: APIClient, reference: None) -> None:
        FaqItem.objects.create(category={"fr": "Compte"}, question={"fr": "Q1"}, answer={"fr": "R1"}, status="published")
        FaqItem.objects.create(
            category={"fr": "Compte"}, question={"fr": "Q2"}, answer={"fr": "R2"}, status="published", audience="web"
        )
        groups = anon.get("/api/v1/faq", {"audience": "app"}).json()
        assert groups == [{"category": "Compte", "items": [groups[0]["items"][0]]}]

    def test_legal_public(self, anon: APIClient, reference: None) -> None:
        body = anon.get("/api/v1/legal/terms").json()
        assert body["version"] == 1
        assert body["body"]
        assert anon.get("/api/v1/legal/unknown").status_code == 404


@pytest.mark.django_db
class TestPrevention:
    def _salty_days(self, user: User) -> None:
        today = local_today(user)
        for offset in range(1, 4):
            DailySummary.objects.create(user=user, date=today - timedelta(days=offset), salt_g=Decimal(6), meals_count=3)

    def test_not_enough_data(self, api: APIClient) -> None:
        assert api.get("/api/v1/me/prevention").json()["state"] == "not_enough_data"

    def test_trigger_once_per_day_and_dismiss(self, api: APIClient, user: User) -> None:
        PreventionTip.objects.create(
            code="salt", topic="salt", title={"fr": "Sel"}, body={"fr": "Moins de sel"}, trigger=SALT, status="published"
        )
        self._salty_days(user)
        assert len(services.evaluate_prevention(user=user)) == 1
        services.evaluate_prevention(user=user)
        assert UserTip.objects.count() == 1
        body = api.get("/api/v1/me/prevention").json()
        assert body["state"] == "ok"
        tip_id = body["tips"][0]["id"]
        assert api.patch(f"/api/v1/me/prevention/tips/{tip_id}", {"dismissed": True}, format="json").status_code == 204
        assert api.get("/api/v1/me/prevention").json()["tips"] == []

    def test_plus_tip_locked_for_free(self, api: APIClient, user: User) -> None:
        PreventionTip.objects.create(
            code="salt", topic="salt", title={"fr": "Sel"}, body={"fr": "Détail"}, trigger=SALT, tier="plus", status="published"
        )
        self._salty_days(user)
        services.evaluate_prevention(user=user)
        expire_trial(user)
        body = api.get("/api/v1/me/prevention").json()
        assert body["tips"][0]["locked"] is True
        assert body["tips"][0]["body"] == ""
        assert body["weekly_report_locked"] is True
