"""Entrées et sorties de meals (analyses, repas, avis, quotas). Aucune logique métier."""

from __future__ import annotations

from typing import Any, Final

from django.utils.translation import gettext_lazy as _
from rest_framework import serializers

from apps.core.presenters import image_out
from apps.meals.models import Analysis, FeedbackRating, FeedbackReason, MealSource, MealType
from apps.nutrition import calculations
from apps.nutrition.models import Dish
from apps.nutrition.presenters import dish_summary_out, nutrients_out

FAILURE_MESSAGES: Final[dict[str, Any]] = {
    "blurry": _("La photo est floue. Reprends-la avec plus de lumière, sans bouger."),
    "no_food": _("Aucun aliment n'a été reconnu sur cette photo."),
    "unsupported": _("Ce fichier n'est pas une image lisible."),
    "provider_error": _("L'analyse n'a pas abouti. Réessaie dans un instant."),
    "timeout": _("L'analyse a pris trop de temps. Réessaie dans un instant."),
}


# ───────────────────────── Entrées ─────────────────────────


class AnalysisInputSerializer(serializers.Serializer[Any]):
    kind = serializers.ChoiceField(choices=["photo", "text"])
    upload_id = serializers.UUIDField(required=False)
    text = serializers.CharField(min_length=3, max_length=500, required=False)

    def validate(self, attrs: dict[str, Any]) -> dict[str, Any]:
        if attrs["kind"] == "photo" and not attrs.get("upload_id"):
            raise serializers.ValidationError({"upload_id": "required for photo"}, code="required")
        if attrs["kind"] == "text" and not attrs.get("text"):
            raise serializers.ValidationError({"text": "required for text"}, code="required")
        return attrs


class SelectDishSerializer(serializers.Serializer[Any]):
    dish_id = serializers.UUIDField()


class FeedbackInputSerializer(serializers.Serializer[Any]):
    rating = serializers.ChoiceField(choices=FeedbackRating.choices)
    reason = serializers.ChoiceField(choices=FeedbackReason.choices, required=False)
    corrected_dish_label = serializers.CharField(max_length=80, required=False, allow_blank=True)
    comment = serializers.CharField(max_length=1000, required=False, allow_blank=True)


class MealItemInputSerializer(serializers.Serializer[Any]):
    food_id = serializers.UUIDField()
    grams = serializers.DecimalField(max_digits=6, decimal_places=1, min_value=0.1, max_value=3000)


class MealInputSerializer(serializers.Serializer[Any]):
    source = serializers.ChoiceField(choices=[c for c in MealSource.values if c != MealSource.DUPLICATE])
    meal_type = serializers.ChoiceField(choices=MealType.choices)
    date = serializers.DateField(required=False)
    eaten_at = serializers.DateTimeField(required=False)
    analysis_id = serializers.UUIDField(required=False)
    dish_id = serializers.UUIDField(required=False)
    recipe_id = serializers.UUIDField(required=False)
    portions = serializers.DecimalField(max_digits=4, decimal_places=2, min_value=0.25, max_value=10, required=False)
    items = MealItemInputSerializer(many=True, required=False, max_length=40)
    keep_photo = serializers.BooleanField(default=True)


class MealUpdateSerializer(serializers.Serializer[Any]):
    meal_type = serializers.ChoiceField(choices=MealType.choices, required=False)
    date = serializers.DateField(required=False)
    items = MealItemInputSerializer(many=True, required=False, min_length=1, max_length=40)
    portions = serializers.DecimalField(max_digits=4, decimal_places=2, min_value=0.25, max_value=10, required=False)

    def validate(self, attrs: dict[str, Any]) -> dict[str, Any]:
        if not attrs:
            raise serializers.ValidationError("at least one field", code="min_properties")
        return attrs


class MealListSerializer(serializers.Serializer[Any]):
    date = serializers.DateField(required=False)
    to = serializers.DateField(required=False)

    def to_internal_value(self, data: Any) -> Any:
        values = super().to_internal_value(data)
        raw_from = data.get("from")
        if raw_from:
            values["from"] = serializers.DateField().to_internal_value(raw_from)
        return values


class DuplicateSerializer(serializers.Serializer[Any]):
    date = serializers.DateField()
    meal_type = serializers.ChoiceField(choices=MealType.choices)


# ───────────────────────── Sorties ─────────────────────────


def _item_out(item: dict[str, Any], foods: dict[str, Any]) -> dict[str, Any]:
    out = dict(item)
    food = foods.get(item["food_id"])
    if food is not None:
        values = {key: getattr(food, key) for key in calculations.NUTRIENT_KEYS}
        out["nutrients"] = nutrients_out(calculations.scale_nutrients(values, item["grams"]))
    return out


def analysis_out(
    analysis: Analysis,
    *,
    foods: dict[str, Any],
    dishes: dict[str, Dish],
    quota: dict[str, Any] | None,
    suggested_meal_type: str,
) -> dict[str, Any]:
    items = [_item_out(i, foods) for i in analysis.items]
    totals = calculations.sum_nutrients(
        [
            calculations.scale_nutrients(
                {k: getattr(foods[i["food_id"]], k) for k in calculations.NUTRIENT_KEYS}, i["grams"]
            )
            for i in analysis.items
            if i["food_id"] in foods
        ]
    )
    body: dict[str, Any] = {
        "id": analysis.id,
        "kind": analysis.kind,
        "status": analysis.status,
        "failure_reason": analysis.failure_reason or None,
        "failure_message": str(FAILURE_MESSAGES[analysis.failure_reason]) if analysis.failure_reason else None,
        "photo": image_out(analysis.upload),
        "dish": dish_summary_out(analysis.dish_guess) if analysis.dish_guess else None,
        "dish_label": analysis.corrected_dish_label or analysis.dish_label or None,
        "confidence": round(analysis.confidence, 2) if analysis.confidence is not None else None,
        "low_confidence": analysis.low_confidence,
        "alternatives": [
            {
                "label": alt["label"],
                "dish": dish_summary_out(dishes[alt["dish_id"]]) if alt.get("dish_id") in dishes else None,
                "probability_percent": alt["probability_percent"],
            }
            for alt in analysis.alternatives
        ],
        "items": items,
        "totals": nutrients_out(totals),
        "suggested_meal_type": suggested_meal_type,
        "suggested_recipe_id": None,
        "created_at": analysis.created_at,
    }
    if quota is not None:
        body["quota"] = quota
    return body
