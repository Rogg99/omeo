"""Compte : lecture de `Me`, profil, sessions (accès par objet), consentements, fuseau, suppression."""

from __future__ import annotations

from collections.abc import Callable
from typing import Any

import pytest
from rest_framework.test import APIClient

from apps.accounts.models import Consent, Profile, Session, User
from apps.nutrition.models import NutritionTarget
from conftest import PASSWORD, login_client

pytestmark = pytest.mark.django_db


class TestMe:
    def test_requires_auth(self, anon: APIClient, reference: None) -> None:
        response = anon.get("/api/v1/me")
        assert response.status_code == 401
        assert response.json()["code"] == "not_authenticated"

    def test_shape(self, api: APIClient) -> None:
        body = api.get("/api/v1/me").json()
        assert body["profile"]["initials"] == "AD"
        assert body["profile"]["age"] >= 16
        assert set(body["targets"]) >= {"kcal", "protein_g", "carbs_g", "fat_g", "fiber_g", "salt_max_g", "water_ml"}
        assert body["entitlements"]["features"]["programs"] is True
        assert body["preferences"]["unit_weight"] == "kg"
        assert body["has_password"] is True

    def test_query_count_is_bounded(self, api: APIClient, django_assert_max_num_queries: Any) -> None:
        with django_assert_max_num_queries(10):
            api.get("/api/v1/me")


class TestProfile:
    def test_update_recomputes_targets(self, api: APIClient, user: User) -> None:
        before = NutritionTarget.objects.get(user=user).base_kcal
        response = api.patch("/api/v1/me/profile", {"goals": ["gain_muscle"], "target_weight_kg": 85}, format="json")
        assert response.status_code == 200
        assert response.json()["targets"]["kcal"] > before

    def test_preferences_do_not_recompute(self, api: APIClient, user: User) -> None:
        api.patch("/api/v1/me/profile", {"theme": "dark"}, format="json")
        assert NutritionTarget.objects.filter(user=user).count() == 1

    def test_empty_body_rejected(self, api: APIClient) -> None:
        assert api.patch("/api/v1/me/profile", {}, format="json").status_code == 400

    def test_out_of_bounds(self, api: APIClient) -> None:
        response = api.patch("/api/v1/me/profile", {"height_cm": 300}, format="json")
        assert response.status_code == 400
        assert "height_cm" in response.json()["errors"]

    def test_locale(self, api: APIClient, user: User) -> None:
        api.patch("/api/v1/me/profile", {"locale": "zh"}, format="json")
        user.refresh_from_db()
        assert user.locale == "zh"


class TestTimezoneHeader:
    def test_updates_profile(self, api: APIClient, user: User) -> None:
        api.get("/api/v1/me", HTTP_X_TIMEZONE="Africa/Dakar")
        assert Profile.objects.get(user=user).timezone == "Africa/Dakar"

    def test_invalid_ignored(self, api: APIClient, user: User) -> None:
        api.get("/api/v1/me", HTTP_X_TIMEZONE="Mars/Olympus")
        assert Profile.objects.get(user=user).timezone == "Africa/Douala"


class TestSessions:
    def test_list_marks_current(self, api: APIClient, user: User) -> None:
        login_client(user)
        sessions = api.get("/api/v1/me/sessions").json()
        assert len(sessions) == 2
        assert sum(s["current"] for s in sessions) == 1

    def test_revoke_own(self, api: APIClient, user: User) -> None:
        other = login_client(user)
        target = Session.objects.filter(user=user).order_by("-created_at").first()
        assert target is not None
        assert api.delete(f"/api/v1/me/sessions/{target.pk}").status_code == 204
        assert other.get("/api/v1/me").status_code == 401

    def test_other_users_session_is_404(self, api: APIClient, make_user: Callable[..., User]) -> None:
        other = make_user()
        login_client(other)
        target = Session.objects.get(user=other)
        response = api.delete(f"/api/v1/me/sessions/{target.pk}")
        assert response.status_code == 404
        assert response.json()["code"] == "not_found"
        target.refresh_from_db()
        assert target.revoked_at is None


class TestConsents:
    def test_list(self, api: APIClient) -> None:
        body = api.get("/api/v1/me/consents").json()
        kinds = {c["kind"]: c for c in body["consents"]}
        assert kinds["terms"]["withdrawable"] is False
        assert kinds["health_data"]["withdrawable"] is True
        assert body["pending_documents"] == []

    def test_append_only(self, api: APIClient, user: User) -> None:
        response = api.post("/api/v1/me/consents", {"consents": [{"kind": "marketing", "granted": True}]}, format="json")
        assert response.status_code == 200
        api.post("/api/v1/me/consents", {"consents": [{"kind": "marketing", "granted": False}]}, format="json")
        assert Consent.objects.filter(user=user, kind="marketing").count() == 2
        state = {c["kind"]: c for c in api.get("/api/v1/me/consents").json()["consents"]}
        assert state["marketing"]["granted"] is False

    def test_terms_not_withdrawable(self, api: APIClient) -> None:
        response = api.post("/api/v1/me/consents", {"consents": [{"kind": "terms", "granted": False}]}, format="json")
        assert response.status_code == 400


class TestPassword:
    def test_change_revokes_other_sessions(self, api: APIClient, user: User) -> None:
        other = login_client(user)
        response = api.post(
            "/api/v1/me/password", {"current_password": PASSWORD, "new_password": "Autre-S3cret!"}, format="json"
        )
        assert response.status_code == 204
        assert api.get("/api/v1/me").status_code == 200
        assert other.get("/api/v1/me").status_code == 401

    def test_wrong_current(self, api: APIClient) -> None:
        response = api.post(
            "/api/v1/me/password", {"current_password": "Wrong-1!xyz", "new_password": "Autre-S3cret!"}, format="json"
        )
        assert response.status_code == 400


class TestDeletion:
    def test_schedules_and_revokes(self, api: APIClient, user: User) -> None:
        response = api.delete("/api/v1/me", {"confirm": "DELETE", "password": PASSWORD}, format="json")
        assert response.status_code == 200
        assert response.json()["store_subscription_active"] is False
        user.refresh_from_db()
        assert user.deletion_scheduled_at is not None
        assert api.get("/api/v1/me").status_code == 401

    def test_requires_confirmation(self, api: APIClient) -> None:
        assert api.delete("/api/v1/me", {"confirm": "yes", "password": PASSWORD}, format="json").status_code == 400

    def test_public_form_is_silent(self, anon: APIClient, user: User) -> None:
        for email in (user.email, "ghost@example.com"):
            response = anon.post("/api/v1/account-deletion", {"email": email, "captcha": "x"}, format="json")
            assert response.status_code == 204


class TestAppConfig:
    def test_public(self, anon: APIClient, reference: None) -> None:
        body = anon.get("/api/v1/app/config").json()
        assert body["trial_days"] == {"default": 3, "with_invite": 7}
        assert "zh" in body["locales"]
        assert body["legal_versions"]["terms"] == 1

    def test_upgrade_required(self, api: APIClient, reference: None) -> None:
        response = api.get("/api/v1/me", HTTP_X_CLIENT="mobile/0.9.0 (android 15)")
        assert response.status_code == 426
        assert response.json()["code"] == "upgrade_required"

    def test_cities_suggested(self, anon: APIClient, reference: None) -> None:
        results = anon.get("/api/v1/app/cities", {"country": "SN"}).json()["results"]
        assert {c["name"] for c in results} >= {"Dakar"}

    def test_cities_search_unaccented(self, anon: APIClient, reference: None) -> None:
        results = anon.get("/api/v1/app/cities", {"q": "lome"}).json()["results"]
        assert [c["name"] for c in results] == ["Lomé"]
