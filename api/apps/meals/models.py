"""Repas, éléments de repas, analyses IA (moteur : apps/foodscan), avis sur les analyses, téléversements."""

from __future__ import annotations

from typing import ClassVar

from django.conf import settings
from django.db import models

from apps.core.models import BaseModel


class UploadKind(models.TextChoices):
    MEAL_PHOTO = "meal_photo"
    SUPPORT_ATTACHMENT = "support_attachment"
    AVATAR = "avatar"


class UploadStatus(models.TextChoices):
    PENDING = "pending"
    READY = "ready"
    REJECTED = "rejected"


class Upload(BaseModel):
    """Fichier téléversé directement vers S3 par URL présignée, puis vérifié (type réel, taille, EXIF retiré)."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="uploads")
    kind = models.CharField(max_length=20, choices=UploadKind.choices)
    storage_key = models.CharField(max_length=255, unique=True)
    content_type = models.CharField(max_length=40)
    size = models.PositiveIntegerField()
    width = models.PositiveIntegerField(null=True, blank=True)
    height = models.PositiveIntegerField(null=True, blank=True)
    status = models.CharField(max_length=10, choices=UploadStatus.choices, default=UploadStatus.PENDING)
    rejected_reason = models.CharField(max_length=32, blank=True)
    expires_at = models.DateTimeField()

    class Meta:
        indexes: ClassVar[list[models.Index]] = [models.Index(fields=["user", "kind", "-created_at"])]


class MealType(models.TextChoices):
    BREAKFAST = "breakfast"
    LUNCH = "lunch"
    SNACK = "snack"
    DINNER = "dinner"


class AnalysisKind(models.TextChoices):
    PHOTO = "photo"
    TEXT = "text"


class AnalysisStatus(models.TextChoices):
    QUEUED = "queued"
    PROCESSING = "processing"
    SUCCEEDED = "succeeded"
    FAILED = "failed"


class FailureReason(models.TextChoices):
    BLURRY = "blurry"
    NO_FOOD = "no_food"
    UNSUPPORTED = "unsupported"
    PROVIDER_ERROR = "provider_error"
    TIMEOUT = "timeout"


class Analysis(BaseModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="analyses")
    kind = models.CharField(max_length=5, choices=AnalysisKind.choices)
    upload = models.ForeignKey(Upload, null=True, blank=True, on_delete=models.SET_NULL, related_name="+")
    input_text = models.CharField(max_length=500, blank=True)
    status = models.CharField(max_length=10, choices=AnalysisStatus.choices, default=AnalysisStatus.QUEUED)
    failure_reason = models.CharField(max_length=16, choices=FailureReason.choices, blank=True)
    # Traçabilité (ScanResult de foodscan)
    model = models.CharField(max_length=120, blank=True)
    prompt_version = models.CharField(max_length=40, blank=True)
    raw_response = models.JSONField(default=dict, blank=True)
    context = models.JSONField(default=dict, blank=True)
    tokens_in = models.PositiveIntegerField(default=0)
    tokens_out = models.PositiveIntegerField(default=0)
    cost_usd_micros = models.PositiveBigIntegerField(null=True, blank=True)
    # Résultat
    dish_guess = models.ForeignKey(
        "nutrition.Dish", null=True, blank=True, on_delete=models.SET_NULL, related_name="+"
    )
    dish_label = models.CharField(max_length=120, blank=True)
    corrected_dish_label = models.CharField(max_length=80, blank=True)
    confidence = models.FloatField(null=True, blank=True)
    low_confidence = models.BooleanField(default=False)
    alternatives = models.JSONField(default=list, blank=True)  # [{label, dish_id|null, probability_percent}]
    items = models.JSONField(default=list, blank=True)  # [{food_id, label, grams, confidence}]
    # Quota
    quota_feature = models.CharField(max_length=20, blank=True)
    quota_period_start = models.DateField(null=True, blank=True)
    counted_in_quota = models.BooleanField(default=False)
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name_plural = "analyses"
        indexes: ClassVar[list[models.Index]] = [
            models.Index(fields=["user", "-created_at"]),
            models.Index(fields=["status", "created_at"]),
        ]


class MealSource(models.TextChoices):
    PHOTO = "photo"
    TEXT = "text"
    DISH = "dish"
    RECIPE = "recipe"
    FOODS = "foods"
    DUPLICATE = "duplicate"
    PROGRAM = "program"


class Meal(BaseModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="meals")
    date = models.DateField()
    eaten_at = models.DateTimeField()
    meal_type = models.CharField(max_length=10, choices=MealType.choices)
    source = models.CharField(max_length=10, choices=MealSource.choices)
    analysis = models.OneToOneField(
        Analysis, null=True, blank=True, on_delete=models.SET_NULL, related_name="meal"
    )
    dish = models.ForeignKey("nutrition.Dish", null=True, blank=True, on_delete=models.SET_NULL, related_name="+")
    recipe_id = models.UUIDField(null=True, blank=True)
    photo = models.ForeignKey(Upload, null=True, blank=True, on_delete=models.SET_NULL, related_name="+")
    title = models.CharField(max_length=120)
    portions = models.DecimalField(max_digits=4, decimal_places=2, default=1)
    kcal = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    protein_g = models.DecimalField(max_digits=7, decimal_places=2, default=0)
    carbs_g = models.DecimalField(max_digits=7, decimal_places=2, default=0)
    sugars_g = models.DecimalField(max_digits=7, decimal_places=2, default=0)
    fat_g = models.DecimalField(max_digits=7, decimal_places=2, default=0)
    saturated_fat_g = models.DecimalField(max_digits=7, decimal_places=2, default=0)
    fiber_g = models.DecimalField(max_digits=7, decimal_places=2, default=0)
    salt_g = models.DecimalField(max_digits=6, decimal_places=2, default=0)

    class Meta:
        indexes: ClassVar[list[models.Index]] = [
            models.Index(fields=["user", "date"]),
            models.Index(fields=["user", "-created_at"]),
        ]


class MealItem(BaseModel):
    """Valeurs toujours calculées depuis `Food`, jamais depuis l'IA."""

    meal = models.ForeignKey(Meal, on_delete=models.CASCADE, related_name="items")
    food = models.ForeignKey("nutrition.Food", on_delete=models.PROTECT, related_name="+")
    label = models.CharField(max_length=120)
    grams = models.DecimalField(max_digits=6, decimal_places=1)
    position = models.PositiveSmallIntegerField(default=0)
    kcal = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    protein_g = models.DecimalField(max_digits=7, decimal_places=2, default=0)
    carbs_g = models.DecimalField(max_digits=7, decimal_places=2, default=0)
    sugars_g = models.DecimalField(max_digits=7, decimal_places=2, default=0)
    fat_g = models.DecimalField(max_digits=7, decimal_places=2, default=0)
    saturated_fat_g = models.DecimalField(max_digits=7, decimal_places=2, default=0)
    fiber_g = models.DecimalField(max_digits=7, decimal_places=2, default=0)
    salt_g = models.DecimalField(max_digits=6, decimal_places=2, default=0)

    class Meta:
        ordering: ClassVar[list[str]] = ["position"]


class FeedbackRating(models.TextChoices):
    UP = "up"
    DOWN = "down"


class FeedbackReason(models.TextChoices):
    WRONG_DISH = "wrong_dish"
    MISSING_INGREDIENT = "missing_ingredient"
    WRONG_QUANTITIES = "wrong_quantities"
    OTHER = "other"


class ModerationStatus(models.TextChoices):
    NEW = "new"
    HANDLED = "handled"
    IGNORED = "ignored"


class HandledAction(models.TextChoices):
    DISH_CREATED = "dish_created"
    FOOD_CREATED = "food_created"
    ALIAS_ADDED = "alias_added"
    DEFECT_REPORTED = "defect_reported"


class AnalysisFeedback(BaseModel):
    analysis = models.OneToOneField(Analysis, on_delete=models.CASCADE, related_name="feedback")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="+")
    rating = models.CharField(max_length=4, choices=FeedbackRating.choices)
    reason = models.CharField(max_length=20, choices=FeedbackReason.choices, blank=True)
    corrected_dish_label = models.CharField(max_length=80, blank=True)
    comment = models.CharField(max_length=1000, blank=True)  # jamais injecté dans un prompt
    corrected_items = models.JSONField(default=list, blank=True)
    moderation_status = models.CharField(
        max_length=8, choices=ModerationStatus.choices, default=ModerationStatus.NEW, db_index=True
    )
    handled_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name="+"
    )
    handled_action = models.CharField(max_length=16, choices=HandledAction.choices, blank=True)
    handled_at = models.DateTimeField(null=True, blank=True)
