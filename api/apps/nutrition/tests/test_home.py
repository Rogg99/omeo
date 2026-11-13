"""Écrans agrégés : accueil et journal du jour (forme, contenu, budget de 8 requêtes SQL)."""

from __future__ import annotations

import uuid
from datetime import timedelta
from typing import Any

import pytest
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.core.localtime import local_today
from apps.core.models import ContentStatus
from apps.nutrition.models import Food
from apps.nutrition.services import add_water, save_food

pytestmark = pytest.mark.django_db


def log_meal(client: APIClient, meal_type: str = "lunch", grams: int = 200) -> Any:
    food = Food.objects.filter(name__fr="Riz").first() or save_food(
        food=Food(name={"fr": "Riz"}, kcal=130, protein_g=2.7, status=ContentStatus.PUBLISHED)
    )
    return client.post(
        "/api/v1/me/meals",
        {"source": "foods", "meal_type": meal_type, "items": [{"food_id": str(food.pk), "grams": grams}]},
        format="json",
        HTTP_IDEMPOTENCY_KEY=str(uuid.uuid4()),
    )


class TestHome:
    def test_shape(self, api: APIClient, user: User) -> None:
        log_meal(api)
        body = api.get("/api/v1/me/home").json()
        assert body["greeting"].endswith("Awa")
        assert len(body["week"]) == 7
        assert sum(d["is_today"] for d in body["week"]) == 1
        assert body["day"]["kcal"]["value"] == 260
        assert {a["kind"] for a in body["quick_actions"]} == {"photo", "voice", "catalog"}
        assert body["rewards"]["total_points"] > 0
        assert body["shortcuts"] == ["nutrition", "sport", "recipes", "plants"]

    def test_empty_day_shows_targets(self, api: APIClient) -> None:
        body = api.get("/api/v1/me/home").json()
        assert body["day"]["kcal"]["value"] == 0
        assert body["day"]["kcal"]["target"] > 0
        assert any(b["kind"] == "connect_health" for b in body["banners"])

    def test_query_budget(self, api: APIClient, user: User, django_assert_max_num_queries: Any) -> None:
        log_meal(api)
        add_water(user=user, amount_ml=500)
        api.get("/api/v1/me/home")  # caches chauds : réglages, droits, règles de quotas, niveaux, documents
        with django_assert_max_num_queries(8):
            assert api.get("/api/v1/me/home").status_code == 200

    def test_verify_email_banner(self, make_user: Any) -> None:
        from conftest import login_client

        client = login_client(make_user(verified=False))
        kinds = {b["kind"] for b in client.get("/api/v1/me/home").json()["banners"]}
        assert "verify_email" in kinds


class TestDay:
    def test_meals_grouped_by_type(self, api: APIClient, user: User) -> None:
        log_meal(api, "breakfast", 100)
        log_meal(api, "lunch", 200)
        body = api.get(f"/api/v1/me/days/{local_today(user)}").json()
        kcal_by_type = {g["meal_type"]: g["kcal"] for g in body["meals_by_type"]}
        assert kcal_by_type == {"breakfast": 130, "lunch": 260, "snack": 0, "dinner": 0}
        assert body["next_date"] is None
        assert body["message"]

    def test_past_day_navigation(self, api: APIClient, user: User) -> None:
        yesterday = local_today(user) - timedelta(days=1)
        body = api.get(f"/api/v1/me/days/{yesterday}").json()
        assert body["next_date"] == str(local_today(user))
        assert body["previous_date"] == str(yesterday - timedelta(days=1))

    def test_future_day_404(self, api: APIClient, user: User) -> None:
        assert api.get(f"/api/v1/me/days/{local_today(user) + timedelta(days=1)}").status_code == 404

    def test_query_budget(self, api: APIClient, user: User, django_assert_max_num_queries: Any) -> None:
        for meal_type in ("breakfast", "lunch", "dinner"):
            log_meal(api, meal_type)
        api.get(f"/api/v1/me/days/{local_today(user)}")
        with django_assert_max_num_queries(8):
            api.get(f"/api/v1/me/days/{local_today(user)}")
