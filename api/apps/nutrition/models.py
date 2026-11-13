"""Nutrition : aliments, plats du catalogue, objectifs datés, eau et projection quotidienne (DailySummary)."""

from __future__ import annotations

from typing import ClassVar

from django.conf import settings
from django.contrib.postgres.fields import ArrayField
from django.contrib.postgres.indexes import GinIndex
from django.db import models
from django.db.models import Q

from apps.core.i18n import I18nTextField
from apps.core.models import BaseModel, ContentStatus

def _nutrient() -> models.DecimalField:  # type: ignore[type-arg]
    return models.DecimalField(max_digits=7, decimal_places=2, default=0)


class FoodCategory(models.TextChoices):
    CEREALS = "cereals"
    TUBERS = "tubers"
    VEGETABLES = "vegetables"
    FRUITS = "fruits"
    MEAT = "meat"
    FISH = "fish"
    LEGUMES = "legumes"
    OILS = "oils"
    DRINKS = "drinks"
    SPICES = "spices"
    OTHER = "other"


class Food(BaseModel):
    """Aliment, valeurs pour 100 g. Source unique des nutriments (jamais l'IA)."""

    name = I18nTextField()
    aliases = ArrayField(models.CharField(max_length=80), default=list, blank=True)
    search_text = models.TextField(blank=True, editable=False)  # noms et alias normalisés (index trigram)
    category = models.CharField(max_length=12, choices=FoodCategory.choices, default=FoodCategory.OTHER)
    kcal = _nutrient()
    protein_g = _nutrient()
    carbs_g = _nutrient()
    sugars_g = _nutrient()
    fat_g = _nutrient()
    saturated_fat_g = _nutrient()
    fiber_g = _nutrient()
    salt_g = _nutrient()
    default_portion_g = models.DecimalField(max_digits=6, decimal_places=1, null=True, blank=True)
    source = models.CharField(max_length=40, blank=True)
    source_ref = models.CharField(max_length=40, blank=True)
    status = models.CharField(max_length=10, choices=ContentStatus.choices, default=ContentStatus.DRAFT)

    class Meta:
        indexes: ClassVar[list[models.Index]] = [
            GinIndex(name="food_search_trgm", fields=["search_text"], opclasses=["gin_trgm_ops"]),
            models.Index(fields=["status", "category"]),
        ]
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(
                fields=["source", "source_ref"], condition=~Q(source_ref=""), name="food_source_ref_uniq"
            ),
        ]


class Dish(BaseModel):
    name = I18nTextField()
    aliases = ArrayField(models.CharField(max_length=80), default=list, blank=True)
    search_text = models.TextField(blank=True, editable=False)
    country = models.CharField(max_length=2, blank=True, db_index=True)
    standard_portion_g = models.DecimalField(max_digits=6, decimal_places=1)
    image = models.ForeignKey("meals.Upload", null=True, blank=True, on_delete=models.SET_NULL, related_name="+")
    # Recalculé à chaque modification de la composition (nutrition.services.refresh_dish_nutrients)
    nutrients_per_100g = models.JSONField(default=dict)
    status = models.CharField(max_length=10, choices=ContentStatus.choices, default=ContentStatus.DRAFT)

    class Meta:
        verbose_name_plural = "dishes"
        indexes: ClassVar[list[models.Index]] = [
            GinIndex(name="dish_search_trgm", fields=["search_text"], opclasses=["gin_trgm_ops"]),
        ]


class DishComponent(BaseModel):
    dish = models.ForeignKey(Dish, on_delete=models.CASCADE, related_name="components")
    food = models.ForeignKey(Food, on_delete=models.PROTECT, related_name="+")
    grams = models.DecimalField(max_digits=6, decimal_places=1)  # pour une portion standard

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["dish", "food"], name="dish_component_uniq"),
        ]


class FavoriteDish(BaseModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="favorite_dishes")
    dish = models.ForeignKey(Dish, on_delete=models.CASCADE, related_name="+")

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["user", "dish"], name="favorite_dish_uniq"),
        ]


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


class WaterEntry(BaseModel):
    """Ajout d'eau ; une valeur négative annule un ajout."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="water_entries")
    date = models.DateField()
    amount_ml = models.IntegerField()

    class Meta:
        indexes: ClassVar[list[models.Index]] = [models.Index(fields=["user", "date"])]


class DailySummary(BaseModel):
    """
    Projection matérialisée par utilisateur et par jour, source de TOUTES les lectures (accueil, journal,
    progression, challenges, points). Recalculée de façon idempotente par `nutrition.services.recompute_day`.
    """

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="daily_summaries")
    date = models.DateField()
    # Objectifs du jour
    base_kcal = models.PositiveIntegerField(default=0)
    target_kcal = models.PositiveIntegerField(default=0)  # ajusté selon l'activité
    target_protein_g = models.PositiveIntegerField(default=0)
    target_carbs_g = models.PositiveIntegerField(default=0)
    target_fat_g = models.PositiveIntegerField(default=0)
    target_fiber_g = models.PositiveIntegerField(default=0)
    target_salt_max_g = models.DecimalField(max_digits=4, decimal_places=1, default=0)
    target_water_ml = models.PositiveIntegerField(default=0)
    # Consommation
    consumed_kcal = models.PositiveIntegerField(default=0)
    protein_g = models.DecimalField(max_digits=7, decimal_places=1, default=0)
    carbs_g = models.DecimalField(max_digits=7, decimal_places=1, default=0)
    fat_g = models.DecimalField(max_digits=7, decimal_places=1, default=0)
    fiber_g = models.DecimalField(max_digits=7, decimal_places=1, default=0)
    salt_g = models.DecimalField(max_digits=6, decimal_places=2, default=0)
    sugars_g = models.DecimalField(max_digits=7, decimal_places=1, default=0)
    water_ml = models.PositiveIntegerField(default=0)
    # Activité
    burned_kcal = models.PositiveIntegerField(null=True, blank=True)  # dépense totale importée
    active_kcal = models.PositiveIntegerField(default=0)
    steps = models.PositiveIntegerField(default=0)
    distance_m = models.PositiveIntegerField(default=0)
    active_minutes = models.PositiveIntegerField(default=0)
    workouts_completed = models.PositiveSmallIntegerField(default=0)
    weight_logged = models.BooleanField(default=False)
    # Repas
    meals_count = models.PositiveSmallIntegerField(default=0)
    is_complete = models.BooleanField(default=False)  # au moins 3 repas
    computed_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["user", "date"], name="daily_summary_user_date_uniq"),
        ]
        indexes: ClassVar[list[models.Index]] = [models.Index(fields=["user", "-date"])]
