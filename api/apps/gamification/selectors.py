"""Lectures de gamification."""

from __future__ import annotations

from typing import Any

from django.db.models import QuerySet

from apps.gamification.models import Badge, PointEvent, UserBadge, UserStats


def published_badges() -> list[Badge]:
    return list(Badge.objects.filter(status="published").order_by("family", "bonus_points"))


def owned_badges(*, user: Any) -> dict[Any, UserBadge]:
    return {ub.badge_id: ub for ub in UserBadge.objects.filter(user=user)}


def metrics(stats: UserStats) -> dict[str, float]:
    return {**{k: float(v) for k, v in stats.counters.items()}, "streak_days": float(stats.current_streak)}


def point_events(*, user: Any) -> QuerySet[PointEvent]:
    return PointEvent.objects.filter(user=user)
