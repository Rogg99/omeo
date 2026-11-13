"""Sorties publiques de content (recettes, plantes), réutilisables par les autres applications."""

from __future__ import annotations

from typing import Any, Final

from django.utils.translation import gettext_lazy as _

from apps.content.models import Plant, Recipe
from apps.core.i18n import resolve
from apps.core.presenters import image_from_key
from apps.nutrition import calculations

TAG_LABELS: Final[dict[str, Any]] = {
    "healthy": _("Sain"),
    "vegetarian": _("Végétarien"),
    "high_protein": _("Riche en protéines"),
    "low_salt": _("Pauvre en sel"),
    "quick": _("Rapide"),
    "traditional": _("Traditionnel"),
}


def recipe_summary_out(recipe: Recipe, *, full_catalog: bool) -> dict[str, Any]:
    body: dict[str, Any] = {
        "id": recipe.id,
        "name": resolve(recipe.name),
        "country": recipe.country,
        "total_minutes": recipe.prep_minutes + recipe.cook_minutes,
        "difficulty": recipe.difficulty,
        "kcal_per_serving": calculations.round_int(float(recipe.nutrients_per_serving.get("kcal", 0))),
        "tags": list(recipe.tags),
        "tag_labels": [str(TAG_LABELS[t]) for t in recipe.tags if t in TAG_LABELS],
        "is_favorite": bool(getattr(recipe, "is_favorite", False)),
        "locked": not (recipe.is_free or full_catalog),
    }
    image = image_from_key(recipe.image_key)
    if image:
        body["image"] = image
    return body


def plant_summary_out(plant: Plant) -> dict[str, Any]:
    body: dict[str, Any] = {
        "id": plant.id,
        "common_name": resolve(plant.common_name),
        "scientific_name": plant.scientific_name,
        "tags": list(plant.tags),
        "is_favorite": bool(getattr(plant, "is_favorite", False)),
    }
    image = image_from_key(plant.image_key)
    if image:
        body["image"] = image
    return body
