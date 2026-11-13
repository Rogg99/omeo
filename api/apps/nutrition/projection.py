"""
Contributeurs de `DailySummary`.

`nutrition` ne lit pas directement les tables des autres applications : chaque application enregistre, dans son
`AppConfig.ready()`, une fonction pure côté lecture qui renvoie sa part du résumé du jour :
- meals    : consumed_kcal, protein_g, carbs_g, fat_g, fiber_g, salt_g, sugars_g, meals_count ;
- activity : burned_kcal, active_kcal, steps, distance_m, active_minutes, workouts_completed, weight_logged.
L'eau est fournie par nutrition elle-même.
"""

from __future__ import annotations

from collections.abc import Callable
from datetime import date
from typing import Any

Contributor = Callable[[Any, date], dict[str, Any]]

_contributors: dict[str, Contributor] = {}


def register_contributor(name: str, contributor: Contributor) -> None:
    _contributors[name] = contributor


def collect(user: Any, day: date) -> dict[str, Any]:
    values: dict[str, Any] = {}
    for contributor in _contributors.values():
        values.update(contributor(user, day))
    return values


RecentDishes = Callable[[Any, int], list[Any]]
_recent_dishes: list[RecentDishes] = []


def register_recent_dishes(provider: RecentDishes) -> None:
    """meals fournit les identifiants des plats récemment enregistrés par l'utilisateur (du plus récent au plus ancien)."""
    _recent_dishes[:] = [provider]


def recent_dish_ids(user: Any, limit: int) -> list[Any]:
    return _recent_dishes[0](user, limit) if _recent_dishes else []
