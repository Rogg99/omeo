"""Règles pures des repas : type proposé selon l'heure locale, probabilités des alternatives, titre d'un repas."""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from datetime import time
from typing import Final

from apps.nutrition.calculations import round_int

MEAL_TYPES: Final[tuple[str, ...]] = ("breakfast", "lunch", "snack", "dinner")
MAX_TITLE_LENGTH: Final = 120


def parse_hhmm(value: str) -> time:
    hours, minutes = value.split(":")
    return time(int(hours), int(minutes))


def suggest_meal_type(local_time: time, starts: Mapping[str, str]) -> str:
    """
    `starts` : heure de début de chaque type (`{"breakfast": "05:00", "lunch": "10:30", …}`, réglage
    `meals.meal_type_starts`). Avant le premier début, c'est encore le dîner de la veille.
    """
    ordered = sorted(((parse_hhmm(starts[t]), t) for t in MEAL_TYPES), key=lambda pair: pair[0])
    current = ordered[-1][1]
    for start, meal_type in ordered:
        if local_time >= start:
            current = meal_type
    return current


def probability_percent(confidence: float) -> int:
    return max(0, min(100, round_int(confidence * 100)))


def meal_title(labels: Sequence[str], *, fallback: str) -> str:
    """Titre d'un repas composé d'aliments : les trois premiers noms, sinon `fallback`."""
    names = [label for label in labels if label][:3]
    title = ", ".join(names) if names else fallback
    return title[:MAX_TITLE_LENGTH]
