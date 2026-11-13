"""Règles pures d'envoi : heures calmes, plafond quotidien, catégories, échéance des rappels (aucun ORM)."""

from __future__ import annotations

from collections.abc import Mapping
from datetime import datetime, time, timedelta
from typing import Final

# Catégorie de notification → clé de préférence (None : non désactivable).
PREFERENCE_KEY: Final[dict[str, str | None]] = {
    "meal_reminder": "meal_reminders",
    "hydration": "hydration",
    "weigh_in": "weigh_in",
    "program": "programs_challenges",
    "challenge": "programs_challenges",
    "reward": "rewards",
    "prevention": "prevention",
    "campaign": "campaigns",
    "subscription": None,
    "support": None,
}
CAP_EXEMPT: Final = frozenset({"subscription", "support"})
REMINDER_WINDOW: Final = timedelta(minutes=15)


def parse_hhmm(value: str) -> time:
    hours, minutes = value.split(":")
    return time(int(hours), int(minutes))


def in_quiet_hours(now: time, *, start: str, end: str) -> bool:
    """Heures calmes, éventuellement à cheval sur minuit (22:00 → 07:00)."""
    begin, finish = parse_hhmm(start), parse_hhmm(end)
    if begin <= finish:
        return begin <= now < finish
    return now >= begin or now < finish


def category_enabled(category: str, preferences: Mapping[str, bool], *, marketing_consent: bool) -> bool:
    key = PREFERENCE_KEY.get(category)
    if key is None:
        return True
    if category == "campaign" and not marketing_consent:
        return False
    return bool(preferences.get(key, True))


def may_push(*, category: str, pushed_today: int, max_per_day: int, quiet: bool) -> bool:
    """Push autorisée : hors heures calmes, et dans la limite quotidienne (sauf abonnement et support)."""
    if category in CAP_EXEMPT:
        return True
    return not quiet and pushed_today < max_per_day


def reminder_due(*, local_now: datetime, at: str) -> bool:
    """Vrai pendant les 15 minutes qui suivent l'heure du rappel (la tâche tourne toutes les 15 minutes)."""
    target = datetime.combine(local_now.date(), parse_hhmm(at), tzinfo=local_now.tzinfo)
    return target <= local_now < target + REMINDER_WINDOW
