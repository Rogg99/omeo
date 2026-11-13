"""Lectures nutritionnelles."""

from __future__ import annotations

from datetime import date
from typing import Any

from apps.nutrition.models import NutritionTarget


def target_on(*, user: Any, day: date) -> NutritionTarget | None:
    return NutritionTarget.objects.filter(user=user, valid_from__lte=day).order_by("-valid_from").first()
