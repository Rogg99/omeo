"""
Règles pures de gamification (aucun accès à l'ORM) — docs/produit/features/06-gamification.md.

- plafonds de points par jour ou par semaine ;
- niveau atteint et progression vers le suivant ;
- progression d'un badge (`condition = {"metric": …, "gte": N}`) ;
- série de jours avec au moins un repas, avec un jour couvert par semaine en Plus.
"""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from datetime import date, timedelta

from apps.nutrition.calculations import round_int


def period_start(day: date, cap_period: str) -> date | None:
    """Début de la période de plafond : le jour, le lundi de la semaine, ou None (pas de plafond)."""
    if cap_period == "day":
        return day
    if cap_period == "week":
        return day - timedelta(days=day.weekday())
    return None


def within_cap(*, already: int, cap: int | None) -> bool:
    return cap is None or already < cap


@dataclass(frozen=True, slots=True)
class LevelStep:
    rank: int
    min_points: int


def level_for(points: int, levels: Sequence[LevelStep]) -> tuple[LevelStep, LevelStep | None]:
    """Niveau courant et niveau suivant (None au dernier). `levels` est trié par `min_points`."""
    ordered = sorted(levels, key=lambda lvl: lvl.min_points)
    current = ordered[0]
    following: LevelStep | None = None
    for index, level in enumerate(ordered):
        if points >= level.min_points:
            current = level
            following = ordered[index + 1] if index + 1 < len(ordered) else None
    return current, following


def progress_percent(points: int, current: LevelStep, following: LevelStep | None) -> int:
    if following is None:
        return 100
    span = following.min_points - current.min_points
    return max(0, min(100, round_int((points - current.min_points) / span * 100)))


def badge_progress(condition: Mapping[str, object], metrics: Mapping[str, float]) -> tuple[float, float, float]:
    """(valeur, seuil, progression 0..1) d'un badge."""
    metric = str(condition["metric"])
    threshold = float(condition["gte"])  # type: ignore[arg-type]
    value = float(metrics.get(metric, 0))
    ratio = 1.0 if threshold <= 0 else min(value / threshold, 1.0)
    return value, threshold, ratio


@dataclass(frozen=True, slots=True)
class Streak:
    current: int
    freezes_used: tuple[date, ...]


def streak(*, logged_days: set[date], today: date, freeze_allowed: bool, max_days: int = 400) -> Streak:
    """
    Jours consécutifs avec au moins un repas, en remontant depuis aujourd'hui (ou hier si rien n'est encore
    enregistré aujourd'hui : la journée n'est pas finie). En Plus, un jour manqué par semaine (lundi à dimanche)
    est couvert, sauf s'il s'agit du jour le plus récent de la série.
    """
    cursor = today if today in logged_days else today - timedelta(days=1)
    count = 0
    freezes: list[date] = []
    weeks_frozen: set[date] = set()
    for _ in range(max_days):
        if cursor in logged_days:
            count += 1
        else:
            week = cursor - timedelta(days=cursor.weekday())
            previous = cursor - timedelta(days=1)
            if freeze_allowed and count > 0 and week not in weeks_frozen and previous in logged_days:
                weeks_frozen.add(week)
                freezes.append(cursor)
            else:
                break
        cursor -= timedelta(days=1)
    return Streak(current=count, freezes_used=tuple(freezes))
