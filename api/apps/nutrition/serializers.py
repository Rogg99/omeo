"""Entrées et sorties nutrition. Les valeurs sont prêtes à afficher (jauges, arrondis faits par calculations)."""

from __future__ import annotations

from typing import Any, Final

from django.utils.translation import gettext_lazy as _
from rest_framework import serializers

from apps.accounts.serializers import image_out
from apps.core.i18n import resolve
from apps.nutrition import calculations
from apps.nutrition.calculations import NutritionConstants
from apps.nutrition.models import DailySummary, Dish, Food
from apps.nutrition.search import normalize

QUICK_ADD_ML: Final = [250, 500]
BALANCE_LABELS: Final[dict[str, Any]] = {
    "deficit": _("Tu as dépensé plus que tu n'as mangé"),
    "balanced": _("Apports et dépenses équilibrés"),
    "surplus": _("Tu as mangé plus que tu n'as dépensé"),
}


# ───────────────────────── Entrées ─────────────────────────


class WaterInputSerializer(serializers.Serializer[Any]):
    amount_ml = serializers.IntegerField(min_value=-2000, max_value=3000)
    date = serializers.DateField(required=False)

    def validate_amount_ml(self, value: int) -> int:
        if value == 0:
            raise serializers.ValidationError("must not be 0", code="invalid")
        return value


class FoodSearchSerializer(serializers.Serializer[Any]):
    q = serializers.CharField(min_length=2, max_length=60)
    limit = serializers.IntegerField(min_value=1, max_value=100, default=20)


class DishSearchSerializer(serializers.Serializer[Any]):
    q = serializers.CharField(max_length=60, required=False, allow_blank=True)
    country = serializers.CharField(min_length=2, max_length=2, required=False)
    scope = serializers.ChoiceField(choices=["all", "recent", "favorites"], default="all")


class CalendarSerializer(serializers.Serializer[Any]):
    month = serializers.RegexField(r"^\d{4}-(0[1-9]|1[0-2])$")


class ProgressSerializer(serializers.Serializer[Any]):
    metric = serializers.ChoiceField(choices=["kcal", "carbs", "fat", "protein", "fiber", "salt"])
    range = serializers.ChoiceField(choices=["7d", "30d", "90d", "1y"], default="7d")


# ───────────────────────── Sorties ─────────────────────────


def nutrients_out(values: dict[str, float]) -> dict[str, int | float]:
    return calculations.display_nutrients(values)


def food_out(food: Food, *, query: str | None = None) -> dict[str, Any]:
    matched = None
    if query:
        term = normalize(query)
        matched = next((alias for alias in food.aliases if term in normalize(alias)), None)
    per_100g = {key: float(getattr(food, key)) for key in calculations.NUTRIENT_KEYS}
    return {
        "id": food.id,
        "name": resolve(food.name),
        "matched_alias": matched,
        "category": food.category,
        "default_portion_g": float(food.default_portion_g) if food.default_portion_g is not None else None,
        "per_100g": nutrients_out(per_100g),
    }


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


def dish_detail_out(dish: Dish) -> dict[str, Any]:
    components = []
    for component in dish.components.all():
        per_100g = {key: getattr(component.food, key) for key in calculations.NUTRIENT_KEYS}
        components.append(
            {
                "food_id": component.food_id,
                "label": resolve(component.food.name),
                "grams": float(component.grams),
                "nutrients": nutrients_out(calculations.scale_nutrients(per_100g, component.grams)),
            }
        )
    return {
        **dish_summary_out(dish),
        "aliases": list(dish.aliases),
        "components": components,
        "nutrients_per_portion": nutrients_out(
            calculations.scale_nutrients(dish.nutrients_per_100g, dish.standard_portion_g)
        ),
        "recipe_id": None,
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
