"""Tendance du poids, IMC et règles d'analyses croisées (module pur)."""

from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass
from datetime import date

from apps.nutrition.calculations import round_1

DAYS_PER_WEEK = 7
MIN_POINTS_FOR_TREND = 2


@dataclass(frozen=True, slots=True)
class WeightPoint:
    day: date
    weight_kg: float


def kg_per_week(points: Sequence[WeightPoint]) -> float | None:
    """Pente de la droite des moindres carrés, en kg par semaine (None avec moins de 2 points distincts)."""
    if len(points) < MIN_POINTS_FOR_TREND:
        return None
    origin = points[0].day
    xs = [(p.day - origin).days for p in points]
    ys = [p.weight_kg for p in points]
    n = len(points)
    mean_x, mean_y = sum(xs) / n, sum(ys) / n
    denominator = sum((x - mean_x) ** 2 for x in xs)
    if denominator == 0:
        return None
    slope_per_day = sum((x - mean_x) * (y - mean_y) for x, y in zip(xs, ys, strict=True)) / denominator
    return round_1(slope_per_day * DAYS_PER_WEEK)


def trend_label(slope: float | None, *, stable_threshold: float) -> str:
    if slope is None:
        return "unknown"
    if abs(slope) < stable_threshold:
        return "stable"
    return "down" if slope < 0 else "up"


def bmi(*, weight_kg: float | None, height_cm: float) -> float | None:
    if weight_kg is None or height_cm <= 0:
        return None
    return round_1(weight_kg / (height_cm / 100) ** 2)


@dataclass(frozen=True, slots=True)
class DayPoint:
    day: date
    steps: int
    consumed_kcal: int
    meals_count: int


@dataclass(frozen=True, slots=True)
class InsightDraft:
    kind: str
    data: dict[str, int | float | str]


def active_vs_rest_intake(days: Sequence[DayPoint], *, steps_goal: int, min_days: int = 2) -> InsightDraft | None:
    """Compare l'apport calorique des jours actifs (objectif de pas atteint) et des autres jours de la semaine."""
    logged = [d for d in days if d.meals_count > 0]
    active = [d.consumed_kcal for d in logged if d.steps >= steps_goal]
    rest = [d.consumed_kcal for d in logged if d.steps < steps_goal]
    if len(active) < min_days or len(rest) < min_days:
        return None
    difference = round(sum(active) / len(active) - sum(rest) / len(rest))
    return InsightDraft(
        kind="active_days_intake",
        data={"active_days": len(active), "rest_days": len(rest), "difference_kcal": difference},
    )


def steps_streak(days: Sequence[DayPoint], *, steps_goal: int) -> InsightDraft | None:
    reached = sum(1 for d in days if d.steps >= steps_goal)
    if reached == 0:
        return None
    return InsightDraft(kind="steps_goal_days", data={"days": reached, "goal": steps_goal})
