"""Journée locale de l'utilisateur : toujours calculée par l'API à partir de `Profile.timezone`."""

from __future__ import annotations

from datetime import date, datetime, time
from typing import Any, Final
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError, available_timezones

from django.utils import timezone

DEFAULT_TZ: Final = "Africa/Abidjan"


def is_valid_timezone(name: str) -> bool:
    if not name or len(name) > 64:
        return False
    try:
        ZoneInfo(name)
    except (ZoneInfoNotFoundError, ValueError):
        return False
    return name in available_timezones() or name == "UTC"


def user_zone(user: Any) -> ZoneInfo:
    profile = getattr(user, "profile", None)
    name = getattr(profile, "timezone", None) or DEFAULT_TZ
    try:
        return ZoneInfo(name)
    except (ZoneInfoNotFoundError, ValueError):
        return ZoneInfo(DEFAULT_TZ)


def local_now(user: Any) -> datetime:
    return timezone.now().astimezone(user_zone(user))


def local_today(user: Any) -> date:
    return local_now(user).date()


def local_date_of(user: Any, moment: datetime) -> date:
    return moment.astimezone(user_zone(user)).date()


def day_bounds(user: Any, day: date) -> tuple[datetime, datetime]:
    """Début (inclus) et fin (exclue) d'une journée locale, en datetime conscients."""
    zone = user_zone(user)
    start = datetime.combine(day, time.min, tzinfo=zone)
    end = datetime.combine(date.fromordinal(day.toordinal() + 1), time.min, tzinfo=zone)
    return start, end


def next_local_midnight(user: Any) -> datetime:
    return day_bounds(user, local_today(user))[1]
