"""Entrées et sorties de content (textes résolus dans la langue demandée)."""

from __future__ import annotations

from typing import Any, Final

from django.utils.translation import gettext_lazy as _
from rest_framework import serializers

from apps.content.models import FaqItem, Plant, Recipe
from apps.content.presenters import plant_summary_out, recipe_summary_out
from apps.core.i18n import resolve
from apps.core.presenters import image_from_key
from apps.nutrition.presenters import nutrients_out

CONTRAINDICATION_LABELS: Final[dict[str, Any]] = {
    "pregnancy": _("Grossesse"),
    "breastfeeding": _("Allaitement"),
    "hypertension": _("Hypertension"),
    "diabetes_medication": _("Traitement du diabète"),
    "anticoagulants": _("Anticoagulants"),
    "children": _("Enfants"),
}
PLANT_DISCLAIMER: Final = _(
    "Ces informations ne remplacent pas un avis médical. Parles-en à un professionnel de santé avant tout usage."
)


class RecipeFilterSerializer(serializers.Serializer[Any]):
    q = serializers.CharField(max_length=60, required=False)
    country = serializers.CharField(min_length=2, max_length=2, required=False)
    goal = serializers.ChoiceField(
        choices=["lose_weight", "gain_muscle", "eat_balanced", "prevent_diabetes", "prevent_hypertension"],
        required=False,
    )
    max_minutes = serializers.IntegerField(min_value=1, max_value=600, required=False)
    favorites = serializers.BooleanField(required=False, default=False)


class PlantFilterSerializer(serializers.Serializer[Any]):
    q = serializers.CharField(max_length=60, required=False)
    tag = serializers.ChoiceField(choices=["traditional_use", "nutritional_support", "caution"], required=False)
    favorites = serializers.BooleanField(required=False, default=False)


class UserTipUpdateSerializer(serializers.Serializer[Any]):
    read = serializers.BooleanField(required=False)
    dismissed = serializers.BooleanField(required=False)

    def validate(self, attrs: dict[str, Any]) -> dict[str, Any]:
        if not attrs:
            raise serializers.ValidationError("at least one field", code="min_properties")
        return attrs


class FaqFilterSerializer(serializers.Serializer[Any]):
    audience = serializers.ChoiceField(choices=["app", "web"], required=False)


def recipe_detail_out(recipe: Recipe, *, full_catalog: bool) -> dict[str, Any]:
    return {
        **recipe_summary_out(recipe, full_catalog=full_catalog),
        "description": resolve(recipe.description),
        "prep_minutes": recipe.prep_minutes,
        "cook_minutes": recipe.cook_minutes,
        "servings": recipe.servings,
        "ingredients": [
            {
                "label": resolve(i.display) or (resolve(i.food.name) if i.food else ""),
                **({"food_id": i.food_id} if i.food_id else {}),
                **({"grams": float(i.grams)} if i.grams else {}),
            }
            for i in recipe.ingredients.all()
        ],
        "steps": [
            {
                "order": step.order,
                "text": resolve(step.text),
                **({"image": image_from_key(step.image_key)} if step.image_key else {}),
            }
            for step in recipe.steps.all()
        ],
        "nutrients_per_serving": nutrients_out(recipe.nutrients_per_serving),
        "related_plants": [plant_summary_out(p) for p in recipe.related_plants.all()],
    }


def plant_detail_out(plant: Plant, *, full_catalog: bool) -> dict[str, Any]:
    return {
        **plant_summary_out(plant),
        "traditional_use": resolve(plant.traditional_use),
        "nutritional_benefits": resolve(plant.nutritional_benefits),
        "precautions": resolve(plant.precautions),
        "contraindications": [
            {"code": code, "label": str(CONTRAINDICATION_LABELS.get(code, code))} for code in plant.contraindications
        ],
        "disclaimer": str(PLANT_DISCLAIMER),
        "related_recipes": [recipe_summary_out(r, full_catalog=full_catalog) for r in plant.related_recipes.all()],
    }


def faq_out(items: list[FaqItem]) -> list[dict[str, Any]]:
    groups: dict[str, list[dict[str, Any]]] = {}
    for item in items:
        groups.setdefault(resolve(item.category), []).append(
            {"id": item.id, "question": resolve(item.question), "answer": resolve(item.answer)}
        )
    return [{"category": category, "items": entries} for category, entries in groups.items()]
