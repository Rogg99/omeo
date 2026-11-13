"""
Évaluation pure des règles de programmes et de challenges contre les valeurs d'un DailySummary (aucun ORM).
"""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from datetime import date, timedelta

from apps.nutrition.calculations import round_int

BOOLEAN_METRICS = frozenset({"kcal_within_target", "workout_completed", "weight_logged"})


@dataclass(frozen=True, slots=True)
class RuleSpec:
    metric: str
    operator: str
    threshold: float


@dataclass(frozen=True, slots=True)
class Evaluation:
    passed: bool
    value: float
    progress: float  # 0..1, pour les jauges des tâches automatiques


def evaluate(rule: RuleSpec, values: Mapping[str, float]) -> Evaluation:
    value = float(values.get(rule.metric, 0))
    if rule.operator == "lte":
        passed = value <= rule.threshold
        progress = 1.0 if passed else 0.0
    else:
        passed = value >= rule.threshold
        progress = 1.0 if rule.threshold <= 0 else min(value / rule.threshold, 1.0)
    return Evaluation(passed=passed, value=value, progress=round(progress, 3))


def day_index(started_on: date, day: date) -> int:
    """1 le jour du début."""
    return (day - started_on).days + 1


def success_rate(statuses: Sequence[str]) -> float:
    """Part des jours réussis sur les jours écoulés (en attente exclus)."""
    decided = [s for s in statuses if s in ("success", "failed")]
    return 0.0 if not decided else sum(1 for s in decided if s == "success") / len(decided)


def current_streak(statuses_by_day: Mapping[date, str], today: date) -> int:
    """Jours réussis consécutifs jusqu'à aujourd'hui (aujourd'hui en attente n'interrompt pas la série)."""
    cursor = today if statuses_by_day.get(today) == "success" else today - timedelta(days=1)
    count = 0
    while statuses_by_day.get(cursor) == "success":
        count += 1
        cursor -= timedelta(days=1)
    return count


def percent(done: int, total: int) -> int:
    return 0 if total == 0 else round_int(done / total * 100)


def program_day_status(*, day: date, today: date, done: int, total: int) -> str:
    if day > today:
        return "upcoming"
    if day == today:
        return "today"
    if total and done == total:
        return "done"
    return "partial" if done else "missed"
