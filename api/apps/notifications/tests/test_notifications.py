"""Notifications : règles pures, préférences, centre, rappels (pas de rappel si le repas est enregistré), campagnes."""

from __future__ import annotations

from datetime import datetime, time
from typing import Any
from zoneinfo import ZoneInfo

import pytest
from freezegun import freeze_time
from rest_framework.test import APIClient

from apps.accounts.models import Consent, User
from apps.notifications import rules, selectors, services
from apps.notifications.models import Notification


class TestRules:
    def test_quiet_hours_across_midnight(self) -> None:
        assert rules.in_quiet_hours(time(23, 0), start="22:00", end="07:00")
        assert rules.in_quiet_hours(time(6, 59), start="22:00", end="07:00")
        assert not rules.in_quiet_hours(time(12, 0), start="22:00", end="07:00")

    def test_cap_except_subscription(self) -> None:
        assert not rules.may_push(category="hydration", pushed_today=3, max_per_day=3, quiet=False)
        assert rules.may_push(category="subscription", pushed_today=9, max_per_day=3, quiet=True)
        assert not rules.may_push(category="rewards", pushed_today=0, max_per_day=3, quiet=True)

    def test_campaign_needs_marketing_consent(self) -> None:
        prefs = {"campaigns": True}
        assert not rules.category_enabled("campaign", prefs, marketing_consent=False)
        assert rules.category_enabled("campaign", prefs, marketing_consent=True)
        assert rules.category_enabled("subscription", {}, marketing_consent=False)

    def test_reminder_window(self) -> None:
        zone = ZoneInfo("Africa/Douala")
        assert rules.reminder_due(local_now=datetime(2026, 11, 13, 12, 35, tzinfo=zone), at="12:30")
        assert not rules.reminder_due(local_now=datetime(2026, 11, 13, 12, 50, tzinfo=zone), at="12:30")


@pytest.fixture(autouse=True)
def _no_broker(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(services.current_app, "send_task", lambda name, args: None)


@pytest.mark.django_db
class TestNotify:
    def test_dedupe(self, user: User) -> None:
        first = services.notify(user=user, category="reward", title="Bravo", body="Badge", dedupe_key="badge:1")
        second = services.notify(user=user, category="reward", title="Bravo", body="Badge", dedupe_key="badge:1")
        assert first is not None
        assert second is None

    def test_disabled_category(self, user: User) -> None:
        services.update_preferences(
            user=user, data={"categories": {"rewards": False}, "quiet_start": "22:00", "quiet_end": "07:00"}
        )
        assert services.notify(user=user, category="reward", title="x", body="y") is None

    def test_rendered_in_user_language(self, user: User) -> None:
        user.locale = "en"
        user.save()
        notification = services.notify(user=user, category="reward", title={"fr": "Salut", "en": "Hi"}, body="x")
        assert notification is not None
        assert notification.title == "Hi"


@pytest.mark.django_db
class TestCenter:
    def test_list_and_mark_read(self, api: APIClient, user: User) -> None:
        for index in range(3):
            services.notify(user=user, category="reward", title=f"t{index}", body="b", dedupe_key=str(index))
        body = api.get("/api/v1/me/notifications").json()
        assert body["unread_count"] == 3
        first_id = body["results"][0]["id"]
        assert api.post("/api/v1/me/notifications/read", {"ids": [first_id]}, format="json").json()["unread_count"] == 2
        assert api.post("/api/v1/me/notifications/read", {"all": True}, format="json").json()["unread_count"] == 0

    def test_preferences_subscription_always_on(self, api: APIClient) -> None:
        payload = {
            "categories": {"subscription": False, "hydration": False},
            "quiet_start": "21:00",
            "quiet_end": "06:30",
        }
        body = api.put("/api/v1/me/notification-preferences", payload, format="json").json()
        assert body["categories"]["subscription"] is True
        assert body["categories"]["hydration"] is False
        assert body["quiet_start"] == "21:00"

    def test_devices(self, api: APIClient) -> None:
        assert (
            api.post("/api/v1/me/devices", {"token": "fcm-1", "platform": "android"}, format="json").status_code == 204
        )
        assert api.delete("/api/v1/me/devices/fcm-1").status_code == 204
        assert api.delete("/api/v1/me/devices/fcm-1").status_code == 404

    def test_opened_other_user_404(self, api: APIClient, make_user: Any) -> None:
        other = make_user()
        notification = services.notify(user=other, category="reward", title="t", body="b")
        assert notification is not None
        assert api.post(f"/api/v1/me/notifications/{notification.pk}/opened").status_code == 404


@pytest.mark.django_db
class TestReminders:
    def test_no_reminder_when_meal_logged(self, user: User) -> None:
        user.profile.timezone = "Africa/Douala"
        user.profile.save()
        with freeze_time("2026-11-13 11:35:00"):  # 12:35 à Douala
            assert services.send_due_reminders(user=user, logged_meal_types={"lunch"}, water_ml=0, water_target=0) == 0
            assert services.send_due_reminders(user=user, logged_meal_types=set(), water_ml=0, water_target=0) == 1
            assert services.send_due_reminders(user=user, logged_meal_types=set(), water_ml=0, water_target=0) == 0
        assert Notification.objects.filter(user=user, category="meal_reminder").count() == 1


@pytest.mark.django_db
def test_campaign_audience_requires_marketing(make_user: Any) -> None:
    consenting = make_user()
    refusing = make_user()
    Consent.objects.create(user=consenting, kind="marketing", granted=True)
    Consent.objects.create(user=refusing, kind="marketing", granted=True)
    Consent.objects.create(user=refusing, kind="marketing", granted=False)
    audience = set(selectors.campaign_audience({}).values_list("pk", flat=True))
    assert consenting.pk in audience
    assert refusing.pk not in audience
