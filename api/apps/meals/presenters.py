"""Sorties publiques de meals (repas), réutilisées par l'accueil et le journal du jour."""

from __future__ import annotations

from typing import Any

from apps.core.presenters import image_out
from apps.meals.models import Meal
from apps.nutrition import calculations
from apps.nutrition.presenters import nutrients_out


def meal_out(meal: Meal) -> dict[str, Any]:
    items = [
        {
            "food_id": item.food_id,
            "label": item.label,
            "grams": float(item.grams),
            "nutrients": nutrients_out({key: float(getattr(item, key)) for key in calculations.NUTRIENT_KEYS}),
        }
        for item in meal.items.all()
    ]
    return {
        "id": meal.id,
        "date": meal.date,
        "eaten_at": meal.eaten_at,
        "meal_type": meal.meal_type,
        "source": meal.source,
        "title": meal.title,
        "photo": image_out(meal.photo),
        "nutrients": nutrients_out({key: float(getattr(meal, key)) for key in calculations.NUTRIENT_KEYS}),
        "items": items,
        "analysis_id": meal.analysis_id,
        "feedback_given": bool(getattr(meal, "feedback_given", False)),
        "created_at": meal.created_at,
    }
