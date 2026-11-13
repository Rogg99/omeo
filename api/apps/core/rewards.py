"""
Récompenses gagnées pendant une écriture (`RewardDelta` du contrat), sans couplage entre applications.

La vue ouvre `with collect_rewards() as rewards:` autour de l'appel de service. Les abonnés aux événements
(gamification) appellent `add_points` / `add_badge` / `set_totals` ; la vue renvoie `rewards.as_dict()`.
Hors collecte (tâche Celery, seed), les ajouts sont ignorés : les points restent écrits en base par gamification.
"""

from __future__ import annotations

from collections.abc import Iterator
from contextlib import contextmanager
from contextvars import ContextVar
from dataclasses import dataclass, field
from typing import Any


@dataclass(slots=True)
class RewardDelta:
    points: int = 0
    total_points: int | None = None
    level_up: dict[str, Any] | None = None
    badges: list[dict[str, Any]] = field(default_factory=list)
    streak: int | None = None

    def as_dict(self) -> dict[str, Any]:
        body: dict[str, Any] = {"points": self.points, "level_up": self.level_up, "badges": list(self.badges)}
        if self.total_points is not None:
            body["total_points"] = self.total_points
        if self.streak is not None:
            body["streak"] = self.streak
        return body


_current: ContextVar[RewardDelta | None] = ContextVar("reward_delta", default=None)


@contextmanager
def collect_rewards() -> Iterator[RewardDelta]:
    delta = RewardDelta()
    token = _current.set(delta)
    try:
        yield delta
    finally:
        _current.reset(token)


def add_points(points: int) -> None:
    delta = _current.get()
    if delta is not None:
        delta.points += points


def add_badge(badge: dict[str, Any]) -> None:
    delta = _current.get()
    if delta is not None:
        delta.badges.append(badge)


def set_totals(*, total_points: int, streak: int, level_up: dict[str, Any] | None = None) -> None:
    delta = _current.get()
    if delta is not None:
        delta.total_points = total_points
        delta.streak = streak
        if level_up is not None:
            delta.level_up = level_up
