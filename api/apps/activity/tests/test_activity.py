"""Activity : METs, tendance, pesées (règle du jour, chiffrement), synchronisation, activités, séances, catalogue."""

from __future__ import annotations

import uuid
from collections.abc import Callable
from datetime import date, timedelta
from decimal import Decimal
from typing import Any

import pytest
from django.db import connection
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.activity import met, services, trends
from apps.activity.models import Activity, DailyActivity, Exercise, WeightEntry, Workout, WorkoutStep
from apps.billing.models import Trial
from apps.billing.services import invalidate_entitlement
from apps.core.localtime import local_today
from apps.nutrition.calculations import round_int
from apps.nutrition.models import DailySummary, NutritionTarget
from conftest import login_client

TABLE = {"walking": {"light": 2.8, "moderate": 3.5, "vigorous": 5.0}, "other": {"light": 3, "moderate": 4.5, "vigorous": 6}}


def idem() -> dict[str, str]:
    return {"HTTP_IDEMPOTENCY_KEY": str(uuid.uuid4())}


class TestPure:
    def test_met_kcal(self) -> None:
        assert met.kcal(met=3.5, weight_kg=78.4, duration_s=3600) == 274

    def test_met_lookup_fallback(self) -> None:
        assert met.met_for(TABLE, "parkour", "vigorous") == 6
        assert met.met_for(TABLE, "walking", None) == 3.5

    def test_average_met_weighted(self) -> None:
        steps = [met.StepEffort(met=8, seconds=60), met.StepEffort(met=4, seconds=180)]
        assert met.average_met(steps) == 5
        assert met.average_met([]) == 0

    def test_reps_duration(self) -> None:
        assert met.step_seconds(mode="reps", duration_s=None, reps=12, seconds_per_rep=3) == 36

    def test_overlap(self) -> None:
        assert met.overlaps(0, 3600, 1800, 5400)
        assert not met.overlaps(0, 3600, 3300, 7200)

    def test_trend(self) -> None:
        points = [trends.WeightPoint(day=date(2026, 10, 1) + timedelta(days=7 * i), weight_kg=80 - 0.5 * i) for i in range(4)]
        slope = trends.kg_per_week(points)
        assert slope == -0.5
        assert trends.trend_label(slope, stable_threshold=0.1) == "down"
        assert trends.trend_label(0.05, stable_threshold=0.1) == "stable"
        assert trends.trend_label(None, stable_threshold=0.1) == "unknown"

    def test_bmi(self) -> None:
        assert trends.bmi(weight_kg=78.4, height_cm=175) == 25.6

    def test_insight_rules(self) -> None:
        days = [
            trends.DayPoint(day=date(2026, 11, d), steps=s, consumed_kcal=k, meals_count=3)
            for d, s, k in [(2, 9000, 2000), (3, 10000, 2100), (4, 3000, 1700), (5, 2000, 1800)]
        ]
        draft = trends.active_vs_rest_intake(days, steps_goal=8000)
        assert draft is not None
        assert draft.data["difference_kcal"] == 300



@pytest.mark.django_db
class TestWeights:
    def _post(self, client: APIClient, weight: float, **extra: Any) -> Any:
        return client.post("/api/v1/me/weights", {"weight_kg": weight, **extra}, format="json", **idem())

    def test_add_updates_profile_and_targets(self, api: APIClient, user: User) -> None:
        before = NutritionTarget.objects.get(user=user).bmr_kcal
        response = self._post(api, 76)
        assert response.status_code == 201
        body = response.json()
        assert body["overview"]["current_kg"] == 76
        assert body["targets"]["bmr_kcal"] < before
        user.profile.refresh_from_db()
        assert user.profile.current_weight_kg == Decimal("76.00")
        assert DailySummary.objects.get(user=user, date=local_today(user)).weight_logged

    def test_encrypted_at_rest(self, api: APIClient, user: User) -> None:
        self._post(api, 77.5)
        with connection.cursor() as cursor:
            cursor.execute("SELECT weight_kg FROM activity_weightentry")
            stored = cursor.fetchone()[0]
        assert "77" not in stored

    def test_manual_wins_over_import_same_day(self, api: APIClient, user: User) -> None:
        today = local_today(user)
        services.sync_health(
            user=user,
            source="health_connect",
            days=[],
            workouts=[],
            weights=[{"measured_at": timezone.now(), "weight_kg": Decimal("79.0")}],
        )
        self._post(api, 78.4)
        effective = WeightEntry.objects.get(user=user, date=today, is_effective=True)
        assert effective.source == "manual"
        services.sync_health(
            user=user,
            source="health_connect",
            days=[],
            workouts=[],
            weights=[{"measured_at": timezone.now() + timedelta(seconds=1), "weight_kg": Decimal("80.0")}],
        )
        assert WeightEntry.objects.get(user=user, date=today, is_effective=True).source == "manual"

    def test_delete_falls_back(self, api: APIClient, user: User) -> None:
        first = self._post(api, 78).json()["overview"]["series"][-1]["id"]
        api.delete(f"/api/v1/me/weights/{first}")
        assert not WeightEntry.objects.filter(user=user).exists()

    def test_other_users_weight_404(self, api: APIClient, make_user: Callable[..., User]) -> None:
        entry_id = self._post(api, 78).json()["overview"]["series"][-1]["id"]
        other = login_client(make_user())
        assert other.delete(f"/api/v1/me/weights/{entry_id}").status_code == 404


@pytest.mark.django_db
class TestHealthSync:
    def test_upsert_is_idempotent(self, api: APIClient, user: User) -> None:
        today = str(local_today(user))
        body = {
            "source": "health_connect",
            "days": [{"date": today, "steps": 9500, "active_kcal": 320, "total_burned_kcal": 2300}],
            "workouts": [
                {"external_id": "hc-1", "type": "running", "started_at": timezone.now().isoformat(), "duration_s": 1800, "kcal": 300}
            ],
        }
        for _ in range(2):
            response = api.post("/api/v1/me/health/sync", body, format="json", **idem())
            assert response.status_code == 200
        assert DailyActivity.objects.filter(user=user).count() == 1
        assert Activity.objects.filter(user=user).count() == 1
        summary = DailySummary.objects.get(user=user, date=today)
        assert summary.steps == 9500
        assert summary.burned_kcal == 2300
        target = NutritionTarget.objects.get(user=user)
        assert summary.target_kcal == target.base_kcal + round_int((2300 - target.tdee_kcal) / 2)

    def test_too_old_rejected(self, api: APIClient, user: User) -> None:
        old = str(local_today(user) - timedelta(days=40))
        response = api.post(
            "/api/v1/me/health/sync", {"source": "health_connect", "days": [{"date": old, "steps": 1}]}, format="json", **idem()
        )
        assert response.status_code == 400

    def test_merge_suggestion(self, api: APIClient, user: User) -> None:
        start = timezone.now() - timedelta(hours=2)
        manual = api.post(
            "/api/v1/me/activities",
            {"type": "running", "duration_s": 1800, "intensity": "moderate", "started_at": start.isoformat()},
            format="json",
            **idem(),
        ).json()["activity"]
        sync = api.post(
            "/api/v1/me/health/sync",
            {
                "source": "health_connect",
                "days": [],
                "workouts": [{"external_id": "hc-2", "type": "running", "started_at": start.isoformat(), "duration_s": 1700}],
            },
            format="json",
            **idem(),
        ).json()
        suggestion = sync["merge_suggestions"][0]
        assert suggestion["manual_id"] == manual["id"]
        merged = api.post(f"/api/v1/me/activities/{manual['id']}/merge", {"into_id": suggestion["imported_id"]}, format="json")
        assert merged.status_code == 200
        assert Activity.objects.get(pk=manual["id"]).merged_into_id is not None


@pytest.mark.django_db
class TestActivities:
    def test_manual_kcal_estimated(self, api: APIClient, user: User) -> None:
        body = api.post(
            "/api/v1/me/activities", {"type": "walking", "duration_s": 3600, "intensity": "moderate"}, format="json", **idem()
        ).json()
        assert body["activity"]["kcal"] == 274  # 3,5 MET × 78,4 kg × 1 h
        assert body["activity"]["editable"] is True
        assert body["day"]["meals_count"] == 0

    def test_imported_not_editable(self, api: APIClient, user: User) -> None:
        services.sync_health(
            user=user,
            source="apple_health",
            days=[],
            workouts=[{"external_id": "ah-1", "type": "walk", "started_at": timezone.now(), "duration_s": 600}],
            weights=[],
        )
        imported = Activity.objects.get(user=user)
        response = api.patch(
            f"/api/v1/me/activities/{imported.pk}", {"type": "walking", "duration_s": 600, "intensity": "light"}, format="json"
        )
        assert response.status_code == 409

    def test_overview_query_budget(self, api: APIClient, django_assert_max_num_queries: Any) -> None:
        with django_assert_max_num_queries(8):
            response = api.get("/api/v1/me/activity")
        assert response.status_code == 200
        assert response.json()["steps"]["target"] == 8000
        assert len(response.json()["balance_week"]) == 7


@pytest.fixture
def workout(db: Any) -> Workout:
    free = Exercise.objects.create(name={"fr": "Squat"}, instructions={"fr": "…"}, met=5, is_free=True, status="published")
    paid = Exercise.objects.create(
        name={"fr": "Burpee"}, instructions={"fr": "…"}, met=8, status="published", download_key="x/burpee.mp4"
    )
    item = Workout.objects.create(name={"fr": "Cardio 10"}, description={"fr": ""}, goal="cardio", duration_s=600, status="published")
    WorkoutStep.objects.create(workout=item, order=1, exercise=free, mode="time", duration_s=300)
    WorkoutStep.objects.create(workout=item, order=2, exercise=paid, mode="time", duration_s=300)
    return item


@pytest.mark.django_db
class TestTraining:
    def test_free_user_sees_locked(self, api: APIClient, user: User, workout: Workout) -> None:
        Trial.objects.filter(user=user).update(ends_at=timezone.now() - timedelta(days=1))
        invalidate_entitlement(user.pk)
        exercises = {e["name"]: e["locked"] for e in api.get("/api/v1/exercises").json()["results"]}
        assert exercises == {"Squat": False, "Burpee": True}
        paid = Exercise.objects.get(name__fr="Burpee")
        response = api.get(f"/api/v1/exercises/{paid.pk}")
        assert response.status_code == 403
        assert response.json()["meta"]["feature"] == "full_catalog"
        assert api.get(f"/api/v1/workouts/{workout.pk}").status_code == 403

    def test_session_kcal_and_completion(self, api: APIClient, user: User, workout: Workout) -> None:
        start = timezone.now() - timedelta(minutes=10)
        response = api.post(
            "/api/v1/me/workout-sessions",
            {
                "workout_id": str(workout.pk),
                "started_at": start.isoformat(),
                "ended_at": (start + timedelta(minutes=10)).isoformat(),
                "completed_steps": 2,
            },
            format="json",
            **idem(),
        )
        assert response.status_code == 201
        body = response.json()
        assert body["completed"] is True
        assert body["kcal"] == met.kcal(met=6.5, weight_kg=78.4, duration_s=600)
        assert DailySummary.objects.get(user=user).workouts_completed == 1

    def test_partial_session(self, api: APIClient, workout: Workout) -> None:
        start = timezone.now() - timedelta(minutes=5)
        body = api.post(
            "/api/v1/me/workout-sessions",
            {"workout_id": str(workout.pk), "started_at": start.isoformat(), "ended_at": timezone.now().isoformat(), "completed_steps": 1},
            format="json",
            **idem(),
        ).json()
        assert body["completed"] is False

    def test_download_requires_plus(self, api: APIClient, workout: Workout) -> None:
        response = api.get(f"/api/v1/workouts/{workout.pk}/download")
        assert response.status_code == 403
        assert response.json()["meta"]["feature"] == "offline_workouts"


@pytest.mark.django_db
def test_weekly_insights_idempotent(user: User) -> None:
    week_start = local_today(user) - timedelta(days=local_today(user).weekday() + 7)
    for offset, (steps, kcal) in enumerate([(9000, 2000), (10000, 2100), (3000, 1700), (2000, 1800)]):
        DailySummary.objects.create(
            user=user, date=week_start + timedelta(days=offset), steps=steps, consumed_kcal=kcal, meals_count=3
        )
    first = services.generate_weekly_insights(user=user, week_start=week_start)
    second = services.generate_weekly_insights(user=user, week_start=week_start)
    assert {i.kind for i in first} == {"active_days_intake", "steps_goal_days"}
    assert [i.pk for i in first] == [i.pk for i in second]
    assert "300" in first[0].message["fr"]
    assert first[0].message["en"]

