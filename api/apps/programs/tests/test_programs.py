"""Programmes et challenges : règles pures, inscription, validation auto/manuelle, quota, clôture, points."""

from __future__ import annotations

from collections.abc import Callable
from datetime import date, timedelta
from decimal import Decimal
from typing import Any

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.billing.models import Trial
from apps.billing.services import invalidate_entitlement
from apps.core.localtime import local_today
from apps.gamification.models import PointEvent
from apps.nutrition import services as nutrition
from apps.programs import rules, services
from apps.programs.models import (
    Challenge,
    ChallengeDay,
    ChallengeParticipation,
    Enrollment,
    Program,
    ProgramDay,
    ProgramTask,
    Rule,
    TaskCompletion,
)
from conftest import login_client

TODAY = date(2026, 11, 13)


class TestRules:
    def test_gte_progress(self) -> None:
        result = rules.evaluate(rules.RuleSpec("water_ml", "gte", 2000), {"water_ml": 1500})
        assert (result.passed, result.progress) == (False, 0.75)
        assert rules.evaluate(rules.RuleSpec("water_ml", "gte", 2000), {"water_ml": 2100}).passed

    def test_lte(self) -> None:
        assert rules.evaluate(rules.RuleSpec("meals_count", "lte", 4), {"meals_count": 3}).passed

    def test_success_rate_ignores_pending(self) -> None:
        assert rules.success_rate(["success", "failed", "pending", "success"]) == pytest.approx(2 / 3)

    def test_streak(self) -> None:
        statuses = {TODAY - timedelta(days=i): "success" for i in (1, 2)}
        statuses[TODAY] = "pending"
        assert rules.current_streak(statuses, TODAY) == 2

    def test_day_status(self) -> None:
        assert rules.program_day_status(day=TODAY, today=TODAY, done=0, total=2) == "today"
        assert rules.program_day_status(day=TODAY - timedelta(days=1), today=TODAY, done=2, total=2) == "done"
        assert rules.program_day_status(day=TODAY - timedelta(days=1), today=TODAY, done=1, total=2) == "partial"
        assert rules.program_day_status(day=TODAY - timedelta(days=1), today=TODAY, done=0, total=2) == "missed"
        assert rules.program_day_status(day=TODAY + timedelta(days=1), today=TODAY, done=0, total=2) == "upcoming"


@pytest.fixture
def water_rule(db: Any) -> Rule:
    return Rule.objects.create(metric="water_ml", operator="gte", threshold=Decimal(2000))


@pytest.fixture
def program(water_rule: Rule) -> Program:
    item = Program.objects.create(
        name={"fr": "Équilibre"}, description={"fr": ""}, goal="eat_balanced", weeks=1, points=300, status="published"
    )
    for index in range(1, 8):
        day = ProgramDay.objects.create(program=item, day_index=index, tip={"fr": f"Conseil {index}"})
        ProgramTask.objects.create(day=day, label={"fr": "Boire 2 L"}, rule=water_rule, order=1)
        ProgramTask.objects.create(day=day, label={"fr": "Marcher après le repas"}, order=2)
    return item


def expire_trial(user: User) -> None:
    Trial.objects.filter(user=user).update(ends_at=timezone.now() - timedelta(days=1))
    invalidate_entitlement(user.pk)


@pytest.mark.django_db
class TestPrograms:
    def test_free_refused(self, api: APIClient, user: User, program: Program) -> None:
        expire_trial(user)
        response = api.post(f"/api/v1/programs/{program.pk}/enroll", {}, format="json")
        assert response.status_code == 403
        assert response.json()["code"] == "plan_required"
        assert api.get("/api/v1/programs").json()[0]["locked"] is True

    def test_enroll_conflict_and_replace(self, api: APIClient, user: User, program: Program) -> None:
        other = Program.objects.create(
            name={"fr": "Autre"}, description={}, goal="lose_weight", weeks=2, status="published"
        )
        assert api.post(f"/api/v1/programs/{program.pk}/enroll", {}, format="json").status_code == 201
        conflict = api.post(f"/api/v1/programs/{other.pk}/enroll", {}, format="json")
        assert conflict.status_code == 409
        assert conflict.json()["code"] == "already_enrolled"
        assert api.post(f"/api/v1/programs/{other.pk}/enroll", {"replace": True}, format="json").status_code == 201
        assert Enrollment.objects.get(program=program).status == "replaced"
        assert Enrollment.objects.filter(user=user, status="active").count() == 1

    def test_auto_task_follows_water(self, api: APIClient, user: User, program: Program) -> None:
        api.post(f"/api/v1/programs/{program.pk}/enroll", {}, format="json")
        nutrition.add_water(user=user, amount_ml=2000)
        body = api.get("/api/v1/me/program").json()
        tasks = {t["label"]: t for t in body["today"]["tasks"]}
        assert tasks["Boire 2 L"]["done"] is True
        assert tasks["Boire 2 L"]["validation"] == "auto"
        assert tasks["Marcher après le repas"]["done"] is False
        assert len(body["week"]) == 7

    def test_manual_task_and_auto_refused(self, api: APIClient, user: User, program: Program) -> None:
        api.post(f"/api/v1/programs/{program.pk}/enroll", {}, format="json")
        manual = ProgramTask.objects.get(day__day_index=1, rule__isnull=True)
        auto = ProgramTask.objects.get(day__day_index=1, rule__isnull=False)
        response = api.put(f"/api/v1/me/program/tasks/{manual.pk}", {"done": True}, format="json")
        assert response.status_code == 200
        assert api.put(f"/api/v1/me/program/tasks/{auto.pk}", {"done": True}, format="json").status_code == 409

    def test_completion_awards_points(self, user: User, program: Program) -> None:
        enrollment = services.enroll(user=user, program_id=program.pk, replace=False)
        Enrollment.objects.filter(pk=enrollment.pk).update(started_on=local_today(user) - timedelta(days=7))
        services.close_day(user=user, day=local_today(user) - timedelta(days=1))
        enrollment.refresh_from_db()
        assert enrollment.status == "completed"
        assert enrollment.report is not None
        assert PointEvent.objects.filter(user=user, action="program_completed").count() == 1

    def test_quit(self, api: APIClient, program: Program) -> None:
        api.post(f"/api/v1/programs/{program.pk}/enroll", {}, format="json")
        assert api.delete("/api/v1/me/program").status_code == 204
        assert api.get("/api/v1/me/program").status_code == 404


@pytest.fixture
def challenges(water_rule: Rule) -> dict[str, Challenge]:
    manual = Rule.objects.create(metric="manual", threshold=Decimal(1))
    return {
        "water": Challenge.objects.create(
            name={"fr": "Hydratation"}, description={}, duration_days=7, rule=water_rule, status="published"
        ),
        "soda": Challenge.objects.create(
            name={"fr": "Zéro soda"}, description={}, duration_days=7, rule=manual, status="published"
        ),
    }


@pytest.mark.django_db
class TestChallenges:
    def test_rule_label(self, api: APIClient, challenges: dict[str, Challenge]) -> None:
        labels = {c["name"]: c["rule_label"] for c in api.get("/api/v1/challenges").json()}
        assert labels["Hydratation"] == "Boire 2 L d'eau"
        assert labels["Zéro soda"] == "Zéro soda"

    def test_free_one_active(self, api: APIClient, user: User, challenges: dict[str, Challenge]) -> None:
        expire_trial(user)
        assert api.post(f"/api/v1/challenges/{challenges['water'].pk}/join").status_code == 201
        response = api.post(f"/api/v1/challenges/{challenges['soda'].pk}/join")
        assert response.status_code == 429
        assert response.json()["code"] == "quota_exceeded"

    def test_join_twice_conflict(self, api: APIClient, challenges: dict[str, Challenge]) -> None:
        api.post(f"/api/v1/challenges/{challenges['water'].pk}/join")
        assert api.post(f"/api/v1/challenges/{challenges['water'].pk}/join").status_code == 409

    def test_auto_day_success_awards_once(self, api: APIClient, user: User, challenges: dict[str, Challenge]) -> None:
        participation_id = api.post(f"/api/v1/challenges/{challenges['water'].pk}/join").json()["id"]
        nutrition.add_water(user=user, amount_ml=1000)
        body = api.get(f"/api/v1/me/challenges/{participation_id}").json()
        assert body["today"]["today_status"] == "pending"
        assert body["today"]["today_label"] == "1,0 L sur 2 L"
        nutrition.add_water(user=user, amount_ml=1500)
        nutrition.add_water(user=user, amount_ml=250)
        body = api.get(f"/api/v1/me/challenges/{participation_id}").json()
        assert body["today"]["today_status"] == "success"
        assert PointEvent.objects.filter(user=user, action="challenge_day").count() == 1

    def test_manual_check_window(self, api: APIClient, user: User, challenges: dict[str, Challenge]) -> None:
        participation_id = api.post(f"/api/v1/challenges/{challenges['soda'].pk}/join").json()["id"]
        today = local_today(user)
        ok = api.put(f"/api/v1/me/challenges/{participation_id}/days/{today}", {"done": True}, format="json")
        assert ok.status_code == 200
        assert ok.json()["participation"]["streak"] == 1
        late = api.put(
            f"/api/v1/me/challenges/{participation_id}/days/{today - timedelta(days=3)}", {"done": True}, format="json"
        )
        assert late.status_code == 400

    def test_auto_challenge_cannot_be_checked(
        self, api: APIClient, user: User, challenges: dict[str, Challenge]
    ) -> None:
        participation_id = api.post(f"/api/v1/challenges/{challenges['water'].pk}/join").json()["id"]
        response = api.put(
            f"/api/v1/me/challenges/{participation_id}/days/{local_today(user)}", {"done": True}, format="json"
        )
        assert response.status_code == 409

    def test_close_fails_pending_and_finishes(self, user: User, challenges: dict[str, Challenge]) -> None:
        participation = services.join_challenge(user=user, challenge_id=challenges["soda"].pk)
        start = local_today(user) - timedelta(days=7)
        ChallengeParticipation.objects.filter(pk=participation.pk).update(started_on=start)
        participation.refresh_from_db()
        for offset in range(6):
            ChallengeDay.objects.create(
                participation=participation, date=start + timedelta(days=offset), status="success"
            )
        services.close_day(user=user, day=start + timedelta(days=6))
        participation.refresh_from_db()
        assert ChallengeDay.objects.get(participation=participation, date=start + timedelta(days=6)).status == "failed"
        assert participation.status == "succeeded"  # 6/7 = 86 % ≥ 80 %
        assert PointEvent.objects.filter(user=user, action="challenge_completed").count() == 1

    def test_other_users_participation_404(
        self, api: APIClient, make_user: Callable[..., User], challenges: dict[str, Challenge]
    ) -> None:
        participation_id = api.post(f"/api/v1/challenges/{challenges['water'].pk}/join").json()["id"]
        other = login_client(make_user())
        assert other.get(f"/api/v1/me/challenges/{participation_id}").status_code == 404
        assert other.delete(f"/api/v1/me/challenges/{participation_id}").status_code == 404


def test_task_completion_model_is_unique_per_day() -> None:
    constraint_names = {c.name for c in TaskCompletion._meta.constraints}
    assert "task_completion_uniq" in constraint_names
