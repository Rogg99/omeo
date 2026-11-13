"""Estimation des calories par la méthode des METs (module pur). kcal = MET × poids (kg) × durée (h)."""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from dataclasses import dataclass

from apps.nutrition.calculations import round_int


def met_for(table: Mapping[str, Mapping[str, float]], activity_type: str, intensity: str | None) -> float:
    by_intensity = table.get(activity_type) or table["other"]
    return float(by_intensity.get(intensity or "moderate", by_intensity["moderate"]))


def kcal(*, met: float, weight_kg: float, duration_s: int) -> int:
    return round_int(met * weight_kg * duration_s / 3600)


@dataclass(frozen=True, slots=True)
class StepEffort:
    met: float
    seconds: int


def step_seconds(*, mode: str, duration_s: int | None, reps: int | None, seconds_per_rep: int) -> int:
    if mode == "time":
        return int(duration_s or 0)
    return int(reps or 0) * seconds_per_rep


def average_met(steps: Sequence[StepEffort]) -> float:
    """MET moyen d'une séance, pondéré par la durée de chaque étape."""
    total = sum(s.seconds for s in steps)
    if total == 0:
        return 0.0
    return sum(s.met * s.seconds for s in steps) / total


def overlaps(start_a: float, end_a: float, start_b: float, end_b: float, *, min_ratio: float = 0.5) -> bool:
    """Deux séances se recouvrent si l'intersection couvre au moins `min_ratio` de la plus courte."""
    intersection = min(end_a, end_b) - max(start_a, start_b)
    shortest = min(end_a - start_a, end_b - start_b)
    return shortest > 0 and intersection / shortest >= min_ratio
