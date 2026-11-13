"""Lectures d'activity : pesées, connexion santé, activités, catalogue d'entraînement, analyses croisées."""

from __future__ import annotations

from datetime import date
from typing import Any

from django.db.models import Count, Prefetch, Q, QuerySet

from apps.activity.models import Activity, Exercise, HealthConnection, Insight, WeightEntry, Workout, WorkoutStep
from apps.core.models import ContentStatus


def effective_weights(*, user: Any, since: date | None) -> list[WeightEntry]:
    queryset = WeightEntry.objects.filter(user=user, is_effective=True)
    if since is not None:
        queryset = queryset.filter(date__gte=since)
    return list(queryset.order_by("date"))


def health_connection(*, user: Any) -> HealthConnection | None:
    return HealthConnection.objects.filter(user=user, disconnected_at__isnull=True).first()


def activities_for(*, user: Any) -> QuerySet[Activity]:
    return Activity.objects.filter(user=user, merged_into__isnull=True)


def activities_on(*, user: Any, day: date) -> list[Activity]:
    return list(activities_for(user=user).filter(date=day).order_by("started_at"))


def exercises(*, q: str | None, muscle: str | None, level: str | None, equipment: str | None) -> QuerySet[Exercise]:
    queryset = Exercise.objects.filter(status=ContentStatus.PUBLISHED)
    if q:
        queryset = queryset.filter(Q(name__fr__icontains=q) | Q(name__en__icontains=q))
    if muscle:
        queryset = queryset.filter(muscles__contains=[muscle])
    if level:
        queryset = queryset.filter(level=level)
    if equipment == "none":
        queryset = queryset.filter(equipment=[])
    return queryset


def exercise(*, exercise_id: Any) -> Exercise | None:
    return Exercise.objects.filter(pk=exercise_id, status=ContentStatus.PUBLISHED).first()


def workouts(*, goal: str | None, level: str | None, max_minutes: int | None) -> QuerySet[Workout]:
    queryset = Workout.objects.filter(status=ContentStatus.PUBLISHED).annotate(exercises_count=Count("steps"))
    if goal:
        queryset = queryset.filter(goal=goal)
    if level:
        queryset = queryset.filter(level=level)
    if max_minutes:
        queryset = queryset.filter(duration_s__lte=max_minutes * 60)
    return queryset


def workout(*, workout_id: Any) -> Workout | None:
    return (
        Workout.objects.filter(pk=workout_id, status=ContentStatus.PUBLISHED)
        .annotate(exercises_count=Count("steps"))
        .prefetch_related(Prefetch("steps", queryset=WorkoutStep.objects.select_related("exercise").order_by("order")))
        .first()
    )


def recommended_workouts(*, limit: int = 3) -> list[Workout]:
    return list(workouts(goal=None, level=None, max_minutes=None).order_by("-is_free", "duration_s")[:limit])


def insights_for(*, user: Any) -> QuerySet[Insight]:
    return Insight.objects.filter(user=user)
