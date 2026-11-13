"""
Données « vue » de nutrition, prêtes à afficher : calendrier d'un mois et progression d'un nutriment.
Lectures uniquement (projection DailySummary), calculs délégués à `calculations`.
"""

from __future__ import annotations

import calendar
from datetime import date, timedelta
from typing import Any, Final

from apps.nutrition import calculations, selectors
from apps.nutrition.calculations import NutritionConstants
from apps.nutrition.models import DailySummary

RANGE_DAYS: Final[dict[str, int]] = {"7d": 7, "30d": 30, "90d": 90, "1y": 365}
# métrique du contrat → (champ consommé, champ objectif, unité, objectif = maximum)
METRICS: Final[dict[str, tuple[str, str, str, bool]]] = {
    "kcal": ("consumed_kcal", "target_kcal", "kcal", False),
    "protein": ("protein_g", "target_protein_g", "g", False),
    "carbs": ("carbs_g", "target_carbs_g", "g", False),
    "fat": ("fat_g", "target_fat_g", "g", False),
    "fiber": ("fiber_g", "target_fiber_g", "g", False),
    "salt": ("salt_g", "target_salt_max_g", "g", True),
}


def status_of(s: DailySummary, c: NutritionConstants) -> str:
    return calculations.day_status(
        meals_count=s.meals_count, consumed_kcal=s.consumed_kcal, target_kcal=s.target_kcal, c=c
    )


def calendar_month(*, user: Any, year: int, month: int, today: date, c: NutritionConstants) -> list[dict[str, Any]]:
    first = date(year, month, 1)
    last = date(year, month, calendar.monthrange(year, month)[1])
    end = min(last, today)
    if end < first:
        return []
    rows = selectors.summaries_between(user=user, start=first, end=end)
    return [
        {"date": d, "status": status_of(rows[d], c) if d in rows else "empty"} for d in selectors.days(first, end)
    ]


def _value(s: DailySummary, field: str, unit: str) -> float:
    raw = float(getattr(s, field))
    return float(calculations.round_int(raw)) if unit == "kcal" else calculations.round_1(raw)


def progress(*, user: Any, metric: str, range_key: str, today: date, c: NutritionConstants) -> dict[str, Any]:
    field, target_field, unit, upper_bound = METRICS[metric]
    length = RANGE_DAYS[range_key]
    start = today - timedelta(days=length - 1)
    views = selectors.day_views_between(user=user, start=min(start, today - timedelta(days=6)), end=today)

    series = []
    logged: list[float] = []
    for d in selectors.days(start, today):
        s = views[d]
        if s.meals_count == 0:
            series.append({"date": d, "value": None, "status": "empty"})
            continue
        value = _value(s, field, unit)
        logged.append(value)
        gauge = calculations.gauge(value=value, target=float(getattr(s, target_field)), c=c, upper_bound=upper_bound)
        series.append({"date": d, "value": value, "status": gauge["status"]})

    today_view, yesterday_view = views[today], views[today - timedelta(days=1)]
    today_value = _value(today_view, field, unit)
    yesterday_value = _value(yesterday_view, field, unit)
    target = float(getattr(today_view, target_field))
    return {
        "metric": metric,
        "range": range_key,
        "unit": unit,
        "today": today_value,
        "delta_vs_yesterday": calculations.round_1(today_value - yesterday_value),
        "delta_percent": calculations.delta_percent(today_value, yesterday_value),
        "target": (calculations.round_1(target) if unit == "g" else target) if target > 0 else None,
        "average": calculations.round_1(sum(logged) / len(logged)) if logged else 0,
        "empty": not logged,
        "series": series,
        "summary_last_7": [
            {"date": d, "kcal": views[d].consumed_kcal, "status": status_of(views[d], c)}
            for d in selectors.days(today - timedelta(days=6), today)
        ],
    }
