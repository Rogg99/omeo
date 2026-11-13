"""Nutrition : objectifs datés (aliments, plats, eau et résumé du jour arrivent avec le module nutrition)."""

from __future__ import annotations

from typing import ClassVar

from django.conf import settings
from django.db import models

from apps.core.models import BaseModel


class NutritionTarget(BaseModel):
    """Une ligne par recalcul. L'objectif d'un jour est la dernière ligne dont `valid_from` ≤ ce jour."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="nutrition_targets")
    valid_from = models.DateField()
    bmr_kcal = models.PositiveIntegerField()
    tdee_kcal = models.PositiveIntegerField()
    base_kcal = models.PositiveIntegerField()
    protein_g = models.PositiveIntegerField()
    carbs_g = models.PositiveIntegerField()
    fat_g = models.PositiveIntegerField()
    fiber_g = models.PositiveIntegerField()
    salt_max_g = models.DecimalField(max_digits=4, decimal_places=1)
    water_ml = models.PositiveIntegerField()
    warning = models.CharField(max_length=40, blank=True)
    computed_from = models.JSONField()

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["user", "valid_from"], name="target_user_valid_from_uniq"),
        ]
        indexes: ClassVar[list[models.Index]] = [models.Index(fields=["user", "-valid_from"])]
