"""
Périodes de quotas (module pur) — docs/produit/02-offres-quotas.md :
- Free : remise à zéro chaque jour à minuit, heure locale ;
- Plus : chaque mois, à la date anniversaire de l'abonnement ;
- Essai : un seul compteur pour toute la durée de l'essai.
"""

from __future__ import annotations

import calendar
from dataclasses import dataclass
from datetime import date, datetime, time, timedelta
from zoneinfo import ZoneInfo


@dataclass(frozen=True, slots=True)
class Period:
    start: date
    resets_at: datetime | None  # None : pas de remise à zéro (essai)


def add_months(day: date, months: int, anchor_day: int) -> date:
    month_index = day.month - 1 + months
    year, month = day.year + month_index // 12, month_index % 12 + 1
    return date(year, month, min(anchor_day, calendar.monthrange(year, month)[1]))


def monthly_period(*, today: date, anchor: date, zone: ZoneInfo) -> Period:
    """Période mensuelle ancrée sur le jour anniversaire (le 31 devient le dernier jour des mois courts)."""
    months = (today.year - anchor.year) * 12 + today.month - anchor.month
    start = add_months(anchor, months, anchor.day)
    if start > today:
        start = add_months(anchor, months - 1, anchor.day)
    end = add_months(start, 1, anchor.day)
    return Period(start=start, resets_at=datetime.combine(end, time.min, tzinfo=zone))


def daily_period(*, today: date, zone: ZoneInfo) -> Period:
    return Period(start=today, resets_at=datetime.combine(today + timedelta(days=1), time.min, tzinfo=zone))


def period_for(*, tier: str, period: str, today: date, zone: ZoneInfo, anchor: date | None) -> Period:
    if period == "trial" or tier == "trial":
        return Period(start=anchor or today, resets_at=None)
    if period == "month":
        return monthly_period(today=today, anchor=anchor or today.replace(day=1), zone=zone)
    return daily_period(today=today, zone=zone)


def remaining(limit: int | None, used: int) -> int | None:
    return None if limit is None else max(limit - used, 0)
