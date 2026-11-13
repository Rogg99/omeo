"""Écritures nutritionnelles : recalcul des objectifs (à chaque nouveau poids retenu ou modification du profil)."""

from __future__ import annotations

from dataclasses import asdict
from datetime import date
from typing import Any

from django.db import transaction

from apps.core.localtime import local_today
from apps.nutrition import calculations
from apps.nutrition.constants import nutrition_constants
from apps.nutrition.models import NutritionTarget


@transaction.atomic
def recompute_targets(*, user: Any, valid_from: date | None = None) -> NutritionTarget:
    profile = user.profile
    day = valid_from or local_today(user)
    constants = nutrition_constants()
    body = calculations.BodyInput(
        sex=profile.sex,
        birth_date=profile.birth_date,
        height_cm=float(profile.height_cm),
        weight_kg=float(profile.current_weight_kg),
        target_weight_kg=float(profile.target_weight_kg),
        goals=list(profile.goals),
    )
    result = calculations.compute_targets(body, today=day, c=constants)
    computed_from = {
        "sex": body.sex,
        "age": calculations.age_on(body.birth_date, day),
        "height_cm": body.height_cm,
        "weight_kg": body.weight_kg,
        "goals": list(body.goals),
        "primary_goal": result.primary_goal,
        "constants": asdict(constants),
    }
    target, _ = NutritionTarget.objects.update_or_create(
        user=user,
        valid_from=day,
        defaults={
            "bmr_kcal": result.bmr_kcal,
            "tdee_kcal": result.tdee_kcal,
            "base_kcal": result.base_kcal,
            "protein_g": result.protein_g,
            "carbs_g": result.carbs_g,
            "fat_g": result.fat_g,
            "fiber_g": result.fiber_g,
            "salt_max_g": result.salt_max_g,
            "water_ml": result.water_ml,
            "warning": result.warning or "",
            "computed_from": computed_from,
        },
    )
    return target
