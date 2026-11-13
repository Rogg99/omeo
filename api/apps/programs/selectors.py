"""Lectures des programmes et challenges (publiés), avec préchargements pour éviter les N+1."""

from __future__ import annotations

from datetime import date
from typing import Any

from django.db.models import Prefetch, QuerySet

from apps.content.selectors import recipes_for
from apps.core.models import ContentStatus
from apps.programs.models import (
    Challenge,
    ChallengeDay,
    ChallengeParticipation,
    Enrollment,
    Program,
    ProgramDay,
    ProgramTask,
    TaskCompletion,
)


def programs(*, goal: str | None) -> QuerySet[Program]:
    queryset = Program.objects.filter(status=ContentStatus.PUBLISHED).select_related("badge")
    return queryset.filter(goal=goal) if goal else queryset


def program_days(*, user: Any, program: Program, indexes: list[int]) -> dict[int, ProgramDay]:
    rows = (
        ProgramDay.objects.filter(program=program, day_index__in=indexes)
        .select_related("workout")
        .prefetch_related(
            Prefetch("tasks", queryset=ProgramTask.objects.select_related("rule")),
            Prefetch("suggested_recipes", queryset=recipes_for(user=user)),
        )
    )
    return {row.day_index: row for row in rows}


def program(*, program_id: Any) -> Program | None:
    return Program.objects.filter(pk=program_id, status=ContentStatus.PUBLISHED).select_related("badge").first()


def completions(*, enrollment: Enrollment, start: date, end: date) -> dict[tuple[Any, date], TaskCompletion]:
    rows = TaskCompletion.objects.filter(enrollment=enrollment, date__gte=start, date__lte=end)
    return {(row.task_id, row.date): row for row in rows}


def challenges() -> QuerySet[Challenge]:
    return Challenge.objects.filter(status=ContentStatus.PUBLISHED).select_related("rule", "badge")


def challenge(*, challenge_id: Any) -> Challenge | None:
    return challenges().filter(pk=challenge_id).first()


def participations(*, user: Any, status: str | None) -> QuerySet[ChallengeParticipation]:
    queryset = ChallengeParticipation.objects.filter(user=user).select_related("challenge__rule", "challenge__badge")
    if status == "active":
        queryset = queryset.filter(status="active")
    elif status == "finished":
        queryset = queryset.exclude(status="active")
    return queryset.prefetch_related(Prefetch("days", queryset=ChallengeDay.objects.order_by("date"))).order_by(
        "-started_on"
    )


def active_challenge_ids(*, user: Any) -> set[Any]:
    return set(ChallengeParticipation.objects.filter(user=user, status="active").values_list("challenge_id", flat=True))
