"""
Règles pures de prévention (aucun accès à l'ORM).

Un déclencheur : `{"metric": "salt_g", "op": "gte", "value": 5, "consecutive_days": 3}`. Il est vrai quand les
N derniers jours enregistrés consécutifs satisfont la condition. Les métriques nutritionnelles ne regardent que
les jours avec au moins un repas ; les métriques d'activité regardent tous les jours.
"""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from datetime import date, timedelta
from typing import Any, Final

from apps.nutrition.calculations import round_1, round_int

NUTRITION_METRICS: Final = frozenset(
    {"consumed_kcal", "salt_g", "sugars_g", "fiber_g", "protein_g", "fat_g", "water_ml"}
)
MIN_LOGGED_DAYS: Final = 3
WINDOW_DAYS: Final = 7


@dataclass(frozen=True, slots=True)
class DayValues:
    day: date
    meals_count: int
    values: Mapping[str, float]


def _compare(value: float, op: str, threshold: float) -> bool:
    return value >= threshold if op == "gte" else value <= threshold


def trigger_matches(trigger: Mapping[str, Any], days: Sequence[DayValues], *, today: date) -> bool:
    """`days` : jours de la fenêtre, dans n'importe quel ordre ; seuls les jours consécutifs jusqu'à hier comptent."""
    metric = str(trigger["metric"])
    needed = int(trigger.get("consecutive_days", 1))
    by_day = {d.day: d for d in days}
    cursor = today - timedelta(days=1)
    streak = 0
    for _ in range(needed):
        item = by_day.get(cursor)
        if item is None or (metric in NUTRITION_METRICS and item.meals_count == 0):
            return False
        if not _compare(float(item.values.get(metric, 0)), str(trigger.get("op", "gte")), float(trigger["value"])):
            return False
        streak += 1
        cursor -= timedelta(days=1)
    return streak == needed


def has_enough_data(days: Sequence[DayValues], *, today: date) -> bool:
    start = today - timedelta(days=WINDOW_DAYS)
    return sum(1 for d in days if start <= d.day < today and d.meals_count > 0) >= MIN_LOGGED_DAYS


def weekly_report(days: Sequence[DayValues], *, targets: Mapping[str, float]) -> dict[str, Any]:
    """Bilan de la semaine : moyennes sur les jours enregistrés, jours dans l'objectif, comparaisons aux repères."""
    logged = [d for d in days if d.meals_count > 0]

    def average(metric: str, pool: Sequence[DayValues]) -> float | None:
        return round_1(sum(float(d.values.get(metric, 0)) for d in pool) / len(pool)) if pool else None

    salt = average("salt_g", logged)
    return {
        "logged_days": len(logged),
        "average_kcal": round_int(average("consumed_kcal", logged) or 0) if logged else None,
        "average_salt_g": salt,
        "salt_over_limit": salt is not None and salt > float(targets.get("salt_max_g", 5)),
        "average_fiber_g": average("fiber_g", logged),
        "average_water_ml": round_int(average("water_ml", days) or 0) if days else None,
        "average_steps": round_int(average("steps", days) or 0) if days else None,
        "days_on_target": sum(1 for d in logged if d.values.get("on_target")),
    }
