"""Programmes (Plus) et challenges. La validation est calculée par l'API à partir de DailySummary."""

from __future__ import annotations

from typing import ClassVar

from django.conf import settings
from django.db import models
from django.db.models import Q

from apps.core.i18n import I18nTextField
from apps.core.models import BaseModel, ContentStatus


class Metric(models.TextChoices):
    WATER_ML = "water_ml"
    STEPS = "steps"
    ACTIVE_MINUTES = "active_minutes"
    MEALS_COUNT = "meals_count"
    PROTEIN_G = "protein_g"
    KCAL_WITHIN_TARGET = "kcal_within_target"
    WORKOUT_COMPLETED = "workout_completed"
    WEIGHT_LOGGED = "weight_logged"
    MANUAL = "manual"


class Operator(models.TextChoices):
    GTE = "gte"
    LTE = "lte"


class Rule(BaseModel):
    """Règle de validation quotidienne, partagée par les challenges et les tâches de programme."""

    metric = models.CharField(max_length=20, choices=Metric.choices)
    operator = models.CharField(max_length=3, choices=Operator.choices, default=Operator.GTE)
    threshold = models.DecimalField(max_digits=8, decimal_places=2, default=1)
    period = models.CharField(max_length=3, default="day")


class Program(BaseModel):
    name = I18nTextField()
    description = I18nTextField()
    goal = models.CharField(max_length=24)
    weeks = models.PositiveSmallIntegerField()
    cover_key = models.CharField(max_length=255, blank=True)
    badge = models.ForeignKey("gamification.Badge", null=True, blank=True, on_delete=models.SET_NULL, related_name="+")
    points = models.PositiveIntegerField(default=0)
    status = models.CharField(max_length=10, choices=ContentStatus.choices, default=ContentStatus.DRAFT)
    is_demo = models.BooleanField(default=False)


class ProgramDay(BaseModel):
    program = models.ForeignKey(Program, on_delete=models.CASCADE, related_name="days")
    day_index = models.PositiveSmallIntegerField()  # 1 à N
    tip = I18nTextField(blank=True)
    workout = models.ForeignKey("activity.Workout", null=True, blank=True, on_delete=models.SET_NULL, related_name="+")
    suggested_recipes = models.ManyToManyField("content.Recipe", blank=True, related_name="+")

    class Meta:
        ordering: ClassVar[list[str]] = ["day_index"]
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["program", "day_index"], name="program_day_uniq"),
        ]


class ProgramTask(BaseModel):
    day = models.ForeignKey(ProgramDay, on_delete=models.CASCADE, related_name="tasks")
    label = I18nTextField()
    rule = models.ForeignKey(Rule, null=True, blank=True, on_delete=models.PROTECT, related_name="+")  # vide = manuelle
    order = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering: ClassVar[list[str]] = ["order"]


class EnrollmentStatus(models.TextChoices):
    ACTIVE = "active"
    COMPLETED = "completed"
    ABANDONED = "abandoned"
    REPLACED = "replaced"


class Enrollment(BaseModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="enrollments")
    program = models.ForeignKey(Program, on_delete=models.PROTECT, related_name="+")
    started_on = models.DateField()
    status = models.CharField(max_length=10, choices=EnrollmentStatus.choices, default=EnrollmentStatus.ACTIVE)
    ended_at = models.DateTimeField(null=True, blank=True)
    start_weight_kg = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    report = models.JSONField(null=True, blank=True)

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(
                fields=["user"], condition=Q(status="active"), name="enrollment_one_active_per_user"
            ),
        ]


class TaskSource(models.TextChoices):
    AUTO = "auto"
    MANUAL = "manual"


class TaskCompletion(BaseModel):
    enrollment = models.ForeignKey(Enrollment, on_delete=models.CASCADE, related_name="completions")
    task = models.ForeignKey(ProgramTask, on_delete=models.CASCADE, related_name="+")
    date = models.DateField()
    done = models.BooleanField(default=False)
    progress = models.DecimalField(max_digits=4, decimal_places=3, null=True, blank=True)
    source = models.CharField(max_length=6, choices=TaskSource.choices)

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["enrollment", "task", "date"], name="task_completion_uniq"),
        ]


class Challenge(BaseModel):
    name = I18nTextField()
    description = I18nTextField()
    duration_days = models.PositiveSmallIntegerField()  # 7 à 30
    rule = models.ForeignKey(Rule, on_delete=models.PROTECT, related_name="+")
    success_threshold = models.DecimalField(max_digits=3, decimal_places=2, default=0.8)
    points_per_day = models.PositiveIntegerField(default=10)
    points_completion = models.PositiveIntegerField(default=100)
    badge = models.ForeignKey("gamification.Badge", null=True, blank=True, on_delete=models.SET_NULL, related_name="+")
    cover_key = models.CharField(max_length=255, blank=True)
    status = models.CharField(max_length=10, choices=ContentStatus.choices, default=ContentStatus.DRAFT)
    is_demo = models.BooleanField(default=False)


class ParticipationStatus(models.TextChoices):
    ACTIVE = "active"
    SUCCEEDED = "succeeded"
    FAILED = "failed"
    ABANDONED = "abandoned"


class ChallengeParticipation(BaseModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="participations")
    challenge = models.ForeignKey(Challenge, on_delete=models.PROTECT, related_name="+")
    started_on = models.DateField()
    status = models.CharField(max_length=10, choices=ParticipationStatus.choices, default=ParticipationStatus.ACTIVE)
    success_rate = models.DecimalField(max_digits=4, decimal_places=3, default=0)

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(
                fields=["user", "challenge"], condition=Q(status="active"), name="participation_one_active"
            ),
        ]


class ChallengeDayStatus(models.TextChoices):
    PENDING = "pending"
    SUCCESS = "success"
    FAILED = "failed"


class ChallengeDay(BaseModel):
    participation = models.ForeignKey(ChallengeParticipation, on_delete=models.CASCADE, related_name="days")
    date = models.DateField()
    status = models.CharField(max_length=8, choices=ChallengeDayStatus.choices, default=ChallengeDayStatus.PENDING)
    value = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    source = models.CharField(max_length=6, choices=TaskSource.choices, default=TaskSource.AUTO)

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["participation", "date"], name="challenge_day_uniq"),
        ]
