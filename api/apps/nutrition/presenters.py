"""Sorties publiques de nutrition (jauges du jour, plats, nutriments), réutilisables par les autres applications."""

from __future__ import annotations

from typing import Any, Final

from django.utils.translation import gettext_lazy as _

from apps.core.i18n import resolve
from apps.core.presenters import image_out
from apps.nutrition import calculations
from apps.nutrition.calculations import NutritionConstants
from apps.nutrition.models import DailySummary, Dish

QUICK_ADD_ML: Final = [250, 500]


BALANCE_LABELS: Final[dict[str, Any]] = {
    "deficit": _("Tu as dépensé plus que tu n'as mangé"),
    "balanced": _("Apports et dépenses équilibrés"),
    "surplus": _("Tu as mangé plus que tu n'as dépensé"),
}


def nutrients_out(values: dict[str, float]) -> dict[str, int | float]:
    return calculations.display_nutrients(values)


def dish_summary_out(dish: Dish) -> dict[str, Any]:
    portion = calculations.scale_nutrients(dish.nutrients_per_100g, dish.standard_portion_g)
    return {
        "id": dish.id,
        "name": resolve(dish.name),
        "country": dish.country,
        "image": image_out(dish.image),
        "standard_portion_g": float(dish.standard_portion_g),
        "kcal_per_portion": calculations.round_int(portion["kcal"]),
        "is_favorite": bool(getattr(dish, "is_favorite", False)),
    }


def day_summary_out(s: DailySummary, *, c: NutritionConstants) -> dict[str, Any]:
    """`s` vient de `selectors.day_view` : ligne réelle, ou jour sans écriture avec ses objectifs."""
    day = s.date
    balance = calculations.balance(consumed_kcal=s.consumed_kcal, burned_kcal=s.burned_kcal)
    if balance is not None:
        balance["label"] = str(BALANCE_LABELS[balance["status"]])
    return {
        "date": day,
        "kcal": calculations.gauge(value=s.consumed_kcal, target=s.target_kcal, c=c),
        "protein": calculations.gauge(value=float(s.protein_g), target=float(s.target_protein_g), c=c),
        "carbs": calculations.gauge(value=float(s.carbs_g), target=float(s.target_carbs_g), c=c),
        "fat": calculations.gauge(value=float(s.fat_g), target=float(s.target_fat_g), c=c),
        "fiber": calculations.gauge(value=float(s.fiber_g), target=float(s.target_fiber_g), c=c),
        "salt": calculations.gauge(value=float(s.salt_g), target=float(s.target_salt_max_g), upper_bound=True),
        "water": calculations.gauge(value=s.water_ml, target=s.target_water_ml, c=c),
        "target_adjusted_by_activity_kcal": max(s.target_kcal - s.base_kcal, 0),
        "balance": balance,
        "meals_count": s.meals_count,
    }


def water_out(s: DailySummary, *, c: NutritionConstants) -> dict[str, Any]:
    return {
        "date": s.date,
        "gauge": calculations.gauge(value=s.water_ml, target=s.target_water_ml, c=c),
        "quick_add_ml": QUICK_ADD_ML,
    }
