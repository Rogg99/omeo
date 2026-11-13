"""Santé connectée, activités, poids (chiffré), exercices, séances guidées, analyses croisées."""

from __future__ import annotations

from typing import ClassVar

from django.conf import settings
from django.contrib.postgres.fields import ArrayField
from django.db import models
from django.db.models import Q

from apps.core.crypto import EncryptedDecimalField
from apps.core.i18n import I18nTextField
from apps.core.models import BaseModel, ContentStatus


class HealthSource(models.TextChoices):
    HEALTH_CONNECT = "health_connect"
    APPLE_HEALTH = "apple_health"


class ActivitySource(models.TextChoices):
    MANUAL = "manual"
    HEALTH_CONNECT = "health_connect"
    APPLE_HEALTH = "apple_health"
    WORKOUT = "workout"


class ActivityType(models.TextChoices):
    WALKING = "walking"
    RUNNING = "running"
    FOOTBALL = "football"
    DANCING = "dancing"
    CYCLING = "cycling"
    STRENGTH = "strength"
    SWIMMING = "swimming"
    OTHER = "other"


class Intensity(models.TextChoices):
    LIGHT = "light"
    MODERATE = "moderate"
    VIGOROUS = "vigorous"


class Level(models.TextChoices):
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"


class HealthConnection(BaseModel):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="health_connection")
    source = models.CharField(max_length=16, choices=HealthSource.choices)
    granted_types = ArrayField(models.CharField(max_length=20), default=list)
    last_sync_at = models.DateTimeField(null=True, blank=True)
    disconnected_at = models.DateTimeField(null=True, blank=True)


class DailyActivity(BaseModel):
    """Totaux du jour envoyés par le mobile (upsert par source)."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="daily_activities")
    date = models.DateField()
    source = models.CharField(max_length=16, choices=ActivitySource.choices)
    steps = models.PositiveIntegerField(default=0)
    distance_m = models.PositiveIntegerField(default=0)
    active_kcal = models.PositiveIntegerField(default=0)
    total_burned_kcal = models.PositiveIntegerField(null=True, blank=True)

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["user", "date", "source"], name="daily_activity_uniq"),
        ]


class Activity(BaseModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="activities")
    date = models.DateField()
    started_at = models.DateTimeField()
    duration_s = models.PositiveIntegerField()
    type = models.CharField(max_length=10, choices=ActivityType.choices)
    label = models.CharField(max_length=60, blank=True)
    intensity = models.CharField(max_length=8, choices=Intensity.choices, blank=True)
    kcal = models.PositiveIntegerField()
    distance_m = models.PositiveIntegerField(null=True, blank=True)
    avg_hr = models.PositiveSmallIntegerField(null=True, blank=True)
    source = models.CharField(max_length=16, choices=ActivitySource.choices)
    external_id = models.CharField(max_length=128, blank=True)
    merged_into = models.ForeignKey("self", null=True, blank=True, on_delete=models.SET_NULL, related_name="+")
    workout_session = models.OneToOneField(
        "activity.WorkoutSession", null=True, blank=True, on_delete=models.CASCADE, related_name="activity"
    )

    class Meta:
        verbose_name_plural = "activities"
        indexes: ClassVar[list[models.Index]] = [models.Index(fields=["user", "date"])]
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(
                fields=["user", "source", "external_id"], condition=~Q(external_id=""), name="activity_external_uniq"
            ),
        ]


class WeightEntry(BaseModel):
    """Pesée. `weight_kg` est chiffré au repos. Une seule valeur retenue par jour (`is_effective`)."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="weights")
    date = models.DateField()
    weight_kg = EncryptedDecimalField(decimal_places=2)
    source = models.CharField(max_length=16, choices=ActivitySource.choices)
    measured_at = models.DateTimeField()
    is_effective = models.BooleanField(default=False)

    class Meta:
        indexes: ClassVar[list[models.Index]] = [models.Index(fields=["user", "date"])]
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(
                fields=["user", "date"], condition=Q(is_effective=True), name="weight_one_effective_per_day"
            ),
            models.UniqueConstraint(fields=["user", "source", "measured_at"], name="weight_measure_uniq"),
        ]


class Exercise(BaseModel):
    name = I18nTextField()
    instructions = I18nTextField()
    video_key = models.CharField(max_length=255, blank=True)  # manifeste HLS (bucket public)
    video_duration_s = models.PositiveIntegerField(null=True, blank=True)
    download_key = models.CharField(max_length=255, blank=True)  # MP4 hors connexion (bucket privé)
    download_size = models.PositiveIntegerField(null=True, blank=True)
    subtitles = models.JSONField(default=dict, blank=True)  # {locale: clé VTT}
    thumbnail_key = models.CharField(max_length=255, blank=True)
    muscles = ArrayField(models.CharField(max_length=30), default=list, blank=True)
    level = models.CharField(max_length=12, choices=Level.choices, default=Level.BEGINNER)
    equipment = ArrayField(models.CharField(max_length=30), default=list, blank=True)
    met = models.DecimalField(max_digits=4, decimal_places=1, default=4)
    is_free = models.BooleanField(default=False)
    status = models.CharField(max_length=10, choices=ContentStatus.choices, default=ContentStatus.DRAFT)


class WorkoutGoal(models.TextChoices):
    CARDIO = "cardio"
    STRENGTH = "strength"
    MOBILITY = "mobility"


class Workout(BaseModel):
    name = I18nTextField()
    description = I18nTextField()
    goal = models.CharField(max_length=10, choices=WorkoutGoal.choices)
    level = models.CharField(max_length=12, choices=Level.choices, default=Level.BEGINNER)
    duration_s = models.PositiveIntegerField(default=0)  # calculé depuis les étapes
    cover_key = models.CharField(max_length=255, blank=True)
    is_free = models.BooleanField(default=False)
    status = models.CharField(max_length=10, choices=ContentStatus.choices, default=ContentStatus.DRAFT)


class StepMode(models.TextChoices):
    TIME = "time"
    REPS = "reps"


class WorkoutStep(BaseModel):
    workout = models.ForeignKey(Workout, on_delete=models.CASCADE, related_name="steps")
    order = models.PositiveSmallIntegerField()
    exercise = models.ForeignKey(Exercise, on_delete=models.PROTECT, related_name="+")
    mode = models.CharField(max_length=4, choices=StepMode.choices)
    duration_s = models.PositiveIntegerField(null=True, blank=True)
    reps = models.PositiveSmallIntegerField(null=True, blank=True)
    rest_s = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering: ClassVar[list[str]] = ["order"]
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["workout", "order"], name="workout_step_order_uniq"),
        ]


class WorkoutSession(BaseModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="workout_sessions")
    workout = models.ForeignKey(Workout, on_delete=models.PROTECT, related_name="+")
    date = models.DateField()
    started_at = models.DateTimeField()
    completed_at = models.DateTimeField()
    duration_s = models.PositiveIntegerField()
    completed_steps = models.PositiveSmallIntegerField()
    completed = models.BooleanField(default=False)
    kcal = models.PositiveIntegerField()

    class Meta:
        indexes: ClassVar[list[models.Index]] = [models.Index(fields=["user", "date"])]


class Insight(BaseModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="insights")
    week_start = models.DateField()
    kind = models.CharField(max_length=40)
    message = I18nTextField()
    data = models.JSONField(default=dict)
    read_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["user", "week_start", "kind"], name="insight_week_kind_uniq"),
        ]
