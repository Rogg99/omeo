"""Constantes nutritionnelles lues depuis les réglages (cache Redis via `settings_store`)."""

from __future__ import annotations

from apps.core import settings_store
from apps.nutrition.calculations import NutritionConstants


def nutrition_constants() -> NutritionConstants:
    return NutritionConstants.from_mapping(settings_store.get("nutrition"))
