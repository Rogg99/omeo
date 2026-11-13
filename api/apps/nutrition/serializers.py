"""Entrées et sorties nutrition. Les valeurs sont prêtes à afficher (jauges, arrondis faits par calculations)."""

from __future__ import annotations

from typing import Any

from rest_framework import serializers

from apps.core.i18n import resolve
from apps.nutrition import calculations
from apps.nutrition.models import Dish, Food
from apps.nutrition.presenters import dish_summary_out, nutrients_out
from apps.nutrition.search import normalize

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
