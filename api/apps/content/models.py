"""Recettes, plantes, prévention, FAQ et historique éditorial. Seul `published` est visible dans l'app."""

from __future__ import annotations

from typing import ClassVar

from django.conf import settings
from django.contrib.postgres.fields import ArrayField
from django.db import models

from apps.core.i18n import I18nTextField
from apps.core.models import BaseModel, ContentStatus


def _status() -> models.CharField:  # type: ignore[type-arg]
    return models.CharField(max_length=10, choices=ContentStatus.choices, default=ContentStatus.DRAFT, db_index=True)


class Difficulty(models.TextChoices):
    EASY = "easy"
    MEDIUM = "medium"
    HARD = "hard"


class Recipe(BaseModel):
    name = I18nTextField()
    description = I18nTextField()
    country = models.CharField(max_length=2, blank=True)
    prep_minutes = models.PositiveSmallIntegerField(default=0)
    cook_minutes = models.PositiveSmallIntegerField(default=0)
    difficulty = models.CharField(max_length=6, choices=Difficulty.choices, default=Difficulty.EASY)
    servings = models.PositiveSmallIntegerField(default=1)
    image_key = models.CharField(max_length=255, blank=True)
    tags = ArrayField(models.CharField(max_length=30), default=list, blank=True)
    goals = ArrayField(models.CharField(max_length=24), default=list, blank=True)
    is_free = models.BooleanField(default=False)
    nutrients_per_serving = models.JSONField(default=dict)  # calculé depuis les ingrédients
    status = _status()
    is_demo = models.BooleanField(default=False)


class RecipeIngredient(BaseModel):
    recipe = models.ForeignKey(Recipe, on_delete=models.CASCADE, related_name="ingredients")
    food = models.ForeignKey("nutrition.Food", null=True, blank=True, on_delete=models.PROTECT, related_name="+")
    grams = models.DecimalField(max_digits=6, decimal_places=1, null=True, blank=True)  # pour toute la recette
    display = I18nTextField()  # « 2 plantains mûrs »
    order = models.PositiveSmallIntegerField()

    class Meta:
        ordering: ClassVar[list[str]] = ["order"]


class RecipeStep(BaseModel):
    recipe = models.ForeignKey(Recipe, on_delete=models.CASCADE, related_name="steps")
    order = models.PositiveSmallIntegerField()
    text = I18nTextField()
    image_key = models.CharField(max_length=255, blank=True)

    class Meta:
        ordering: ClassVar[list[str]] = ["order"]


class FavoriteRecipe(BaseModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="+")
    recipe = models.ForeignKey(Recipe, on_delete=models.CASCADE, related_name="+")

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["user", "recipe"], name="favorite_recipe_uniq"),
        ]


class Plant(BaseModel):
    common_name = I18nTextField()
    scientific_name = models.CharField(max_length=120)
    image_key = models.CharField(max_length=255, blank=True)
    tags = ArrayField(models.CharField(max_length=30), default=list, blank=True)
    traditional_use = I18nTextField()
    nutritional_benefits = I18nTextField()
    precautions = I18nTextField()
    contraindications = ArrayField(models.CharField(max_length=40), default=list, blank=True)
    related_recipes = models.ManyToManyField(Recipe, blank=True, related_name="related_plants")
    status = _status()
    is_demo = models.BooleanField(default=False)


class FavoritePlant(BaseModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="+")
    plant = models.ForeignKey(Plant, on_delete=models.CASCADE, related_name="+")

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["user", "plant"], name="favorite_plant_uniq"),
        ]


class TipTier(models.TextChoices):
    FREE = "free"
    PLUS = "plus"


class PreventionTip(BaseModel):
    code = models.CharField(max_length=40, unique=True)
    topic = models.CharField(max_length=10)  # water, salt, sugar, fiber, activity, protein
    title = I18nTextField()
    body = I18nTextField()
    trigger = models.JSONField()  # {"metric": "salt_g", "op": "gte", "value": 5, "consecutive_days": 3}
    tier = models.CharField(max_length=4, choices=TipTier.choices, default=TipTier.FREE)
    related_recipes = models.ManyToManyField(Recipe, blank=True, related_name="+")
    related_plants = models.ManyToManyField(Plant, blank=True, related_name="+")
    status = _status()


class UserTip(BaseModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="tips")
    tip = models.ForeignKey(PreventionTip, on_delete=models.CASCADE, related_name="+")
    triggered_on = models.DateField()
    data = models.JSONField(default=dict)
    read_at = models.DateTimeField(null=True, blank=True)
    dismissed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["user", "tip", "triggered_on"], name="user_tip_uniq"),
        ]


class WeeklyReport(BaseModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="weekly_reports")
    week_start = models.DateField()
    data = models.JSONField()
    generated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["user", "week_start"], name="weekly_report_uniq"),
        ]


class FaqAudience(models.TextChoices):
    APP = "app"
    WEB = "web"
    BOTH = "both"


class FaqItem(BaseModel):
    category = I18nTextField()
    question = I18nTextField()
    answer = I18nTextField()
    order = models.PositiveSmallIntegerField(default=0)
    audience = models.CharField(max_length=4, choices=FaqAudience.choices, default=FaqAudience.BOTH)
    status = _status()


class ContentView(BaseModel):
    """Première consultation d'un contenu par un utilisateur (badges « découverte »)."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="+")
    content_type = models.CharField(max_length=10)
    object_id = models.UUIDField()

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["user", "content_type", "object_id"], name="content_view_uniq"),
        ]


class ContentRevision(BaseModel):
    content_type = models.CharField(max_length=30)
    object_id = models.UUIDField()
    author = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="+")
    snapshot = models.JSONField()

    class Meta:
        indexes: ClassVar[list[models.Index]] = [models.Index(fields=["content_type", "object_id", "-created_at"])]
