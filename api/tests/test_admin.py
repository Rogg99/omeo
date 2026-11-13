"""Back-office : permissions effectives, step-up, quatre yeux, garde-fous de l'équipe, santé journalisée, contenus."""

from __future__ import annotations

from collections.abc import Callable
from typing import Any

import pytest
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.core.models import AuditLog
from apps.nutrition.models import Food
from conftest import login_client

pytestmark = pytest.mark.django_db
StaffFactory = Callable[..., tuple[User, str]]


def staff_client(make_staff: StaffFactory, *roles: str, step_up: bool = True) -> tuple[User, APIClient]:
    member, _secret = make_staff(*roles)
    return member, login_client(member, mfa_verified=step_up)


class TestStaffMe:
    def test_effective_permissions(self, make_staff: StaffFactory) -> None:
        _, client = staff_client(make_staff, "moderation")
        body = client.get("/api/v1/admin/me").json()
        assert "feedback.resolve" in body["permissions"]
        assert "billing.refund" not in body["permissions"]

    def test_app_user_refused(self, api: APIClient) -> None:
        response = api.get("/api/v1/admin/me")
        assert response.status_code == 403
        assert response.json()["code"] == "forbidden_role"


class TestUsers:
    def test_health_reveal_requires_step_up_and_is_audited(self, make_staff: StaffFactory, user: User) -> None:
        member, client = staff_client(make_staff, "support", step_up=False)
        url = f"/api/v1/admin/users/{user.pk}/health"
        assert client.get(url, {"reason": "Demande de l'utilisatrice"}).json()["code"] == "step_up_required"
        client = login_client(member, mfa_verified=True)
        body = client.get(url, {"reason": "Demande de l'utilisatrice"}).json()
        assert body["current_weight_kg"] == 78.4
        assert AuditLog.objects.filter(action="health.view", actor=member).count() == 1

    def test_list_hides_health(self, make_staff: StaffFactory, user: User) -> None:
        _, client = staff_client(make_staff, "support")
        row = client.get("/api/v1/admin/users", {"q": "awa"}).json()["results"][0]
        assert "current_weight_kg" not in row
        assert client.get(f"/api/v1/admin/users/{user.pk}").json()["health_masked"] is True

    def test_suspend_needs_permission_and_step_up(self, make_staff: StaffFactory, user: User) -> None:
        _, support = staff_client(make_staff, "support")
        payload = {"action": "suspend", "reason": "Fraude avérée"}
        assert support.post(f"/api/v1/admin/users/{user.pk}/actions", payload, format="json").status_code == 403
        admin, _ = make_staff("superadmin")
        no_step_up = login_client(admin, mfa_verified=False)
        response = no_step_up.post(f"/api/v1/admin/users/{user.pk}/actions", payload, format="json")
        assert response.json()["code"] == "step_up_required"
        ok = login_client(admin, mfa_verified=True).post(
            f"/api/v1/admin/users/{user.pk}/actions", payload, format="json"
        )
        assert ok.status_code == 200
        assert ok.json()["status"] == "suspended"

    def test_extend_trial_capped(self, make_staff: StaffFactory, user: User) -> None:
        _, client = staff_client(make_staff, "support")
        payload = {"action": "extend_trial", "days": 30, "reason": "Geste commercial"}
        assert client.post(f"/api/v1/admin/users/{user.pk}/actions", payload, format="json").status_code == 400


class TestTeam:
    def test_last_superadmin_protected(self, make_staff: StaffFactory) -> None:
        admin, client = staff_client(make_staff, "superadmin")
        response = client.patch(f"/api/v1/admin/team/{admin.pk}", {"roles": ["support"]}, format="json")
        assert response.status_code == 409


class TestFourEyes:
    def test_nutrition_settings_need_another_person(self, make_staff: StaffFactory) -> None:
        requester, client = staff_client(make_staff, "superadmin")
        response = client.patch(
            "/api/v1/admin/settings",
            {"reason": "Nouvelle recommandation", "nutrition": {"salt_max_g": 4}},
            format="json",
        )
        assert response.status_code == 202
        approval_id = response.json()["id"]
        own = client.post(f"/api/v1/admin/approvals/{approval_id}/decision", {"decision": "approve"}, format="json")
        assert own.json()["code"] == "self_approval_forbidden"
        _, other = staff_client(make_staff, "superadmin")
        decided = other.post(f"/api/v1/admin/approvals/{approval_id}/decision", {"decision": "approve"}, format="json")
        assert decided.json()["status"] == "approved"
        assert client.get("/api/v1/admin/settings").json()["nutrition"]["salt_max_g"] == 4

    def test_content_publish_by_author_requires_review(self, make_staff: StaffFactory) -> None:
        author, client = staff_client(make_staff, "content")
        created = client.post(
            "/api/v1/admin/content/foods",
            {
                "data": {
                    "name": {"fr": "Gombo"},
                    "category": "vegetables",
                    "kcal": 33,
                    "protein_g": 1.9,
                    "carbs_g": 7.5,
                    "fat_g": 0.2,
                }
            },
            format="json",
        ).json()
        url = f"/api/v1/admin/content/foods/{created['id']}"
        assert client.post(f"{url}/transition", {"to": "review"}, format="json").status_code == 200
        pending = client.post(f"{url}/transition", {"to": "published"}, format="json")
        assert pending.status_code == 202
        _, reviewer = staff_client(make_staff, "content")
        reviewer.post(
            f"/api/v1/admin/approvals/{pending.json()['id']}/decision", {"decision": "approve"}, format="json"
        )
        assert Food.objects.get(pk=created["id"]).status == "published"

    def test_optimistic_lock(self, make_staff: StaffFactory) -> None:
        _, client = staff_client(make_staff, "content")
        created = client.post(
            "/api/v1/admin/content/cities",
            {"data": {"name": {"fr": "Kribi"}, "country": "CM", "timezone": "Africa/Douala"}},
            format="json",
        ).json()
        url = f"/api/v1/admin/content/cities/{created['id']}"
        assert client.patch(url, {"version": 1, "data": {"is_suggested": True}}, format="json").status_code == 200
        stale = client.patch(url, {"version": 1, "data": {"is_suggested": False}}, format="json")
        assert stale.status_code == 409
        assert stale.json()["code"] == "version_conflict"


def test_revisions_and_coverage(make_staff: StaffFactory) -> None:
    _, client = staff_client(make_staff, "content")
    created = client.post(
        "/api/v1/admin/content/faq",
        {"data": {"category": "Compte", "question": {"fr": "Q ?"}, "answer": {"fr": "R."}}},
        format="json",
    ).json()
    revisions = client.get(f"/api/v1/admin/content/faq/{created['id']}/revisions").json()
    assert len(revisions) == 1
    coverage = {(c["type"], c["locale"]): c for c in client.get("/api/v1/admin/translations").json()}
    assert coverage[("faq", "en")]["missing"] >= 1


def test_unknown_content_type_404(make_staff: StaffFactory) -> None:
    _, client = staff_client(make_staff, "content")
    assert client.get("/api/v1/admin/content/unicorns").status_code == 404


def test_feedback_queue_permissions(make_staff: StaffFactory, reference: Any) -> None:
    _, finance = staff_client(make_staff, "finance")
    assert finance.get("/api/v1/admin/feedback").status_code == 403
    _, moderator = staff_client(make_staff, "moderation")
    assert moderator.get("/api/v1/admin/feedback").json()["count"] == 0
