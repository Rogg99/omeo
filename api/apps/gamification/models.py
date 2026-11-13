"""Points, niveaux, badges et séries."""

from __future__ import annotations

from typing import ClassVar

from django.conf import settings
from django.db import models

from apps.core.i18n import I18nTextField
from apps.core.models import BaseModel, ContentStatus


class CapPeriod(models.TextChoices):
    DAY = "day"
    WEEK = "week"
    NONE = "none"


class PointRule(BaseModel):
    action = models.CharField(max_length=30, unique=True)
    points = models.PositiveIntegerField()
    cap = models.PositiveIntegerField(null=True, blank=True)
    cap_period = models.CharField(max_length=4, choices=CapPeriod.choices, default=CapPeriod.NONE)


class PointEvent(BaseModel):
    """La même action sur la même référence ne rapporte jamais deux fois (contrainte unique)."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="point_events")
    action = models.CharField(max_length=30)
    points = models.IntegerField()
    date = models.DateField()
    ref_type = models.CharField(max_length=30)
    ref_id = models.CharField(max_length=64)

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["user", "action", "ref_type", "ref_id"], name="point_event_uniq"),
        ]
        indexes: ClassVar[list[models.Index]] = [
            models.Index(fields=["user", "action", "date"]),
            models.Index(fields=["user", "-created_at"]),
        ]


class Level(BaseModel):
    rank = models.PositiveSmallIntegerField(unique=True)
    name = I18nTextField()
    min_points = models.PositiveIntegerField()
    icon_key = models.CharField(max_length=255, blank=True)


class BadgeFamily(models.TextChoices):
    STREAK = "streak"
    NUTRITION = "nutrition"
    HYDRATION = "hydration"
    ACTIVITY = "activity"
    CHALLENGE = "challenge"
    PROGRAM = "program"
    DISCOVERY = "discovery"
    REFERRAL = "referral"


class Badge(BaseModel):
    code = models.CharField(max_length=40, unique=True)
    family = models.CharField(max_length=10, choices=BadgeFamily.choices)
    name = I18nTextField()
    description = I18nTextField()
    icon_key = models.CharField(max_length=255, blank=True)
    condition = models.JSONField()  # {"metric": "streak_days", "gte": 7}
    bonus_points = models.PositiveIntegerField(default=0)
    status = models.CharField(max_length=10, choices=ContentStatus.choices, default=ContentStatus.PUBLISHED)


class UserBadge(BaseModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="badges")
    badge = models.ForeignKey(Badge, on_delete=models.CASCADE, related_name="+")
    progress = models.DecimalField(max_digits=4, decimal_places=3, default=0)
    earned_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["user", "badge"], name="user_badge_uniq"),
        ]


class UserStats(BaseModel):
    """Projection des récompenses. `counters` alimente les conditions des badges (meals_total, workouts_total…)."""

    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="stats")
    total_points = models.PositiveIntegerField(default=0)
    level = models.ForeignKey(Level, null=True, blank=True, on_delete=models.SET_NULL, related_name="+")
    current_streak = models.PositiveIntegerField(default=0)
    best_streak = models.PositiveIntegerField(default=0)
    streak_freezes_used_week = models.PositiveSmallIntegerField(default=0)
    last_meal_date = models.DateField(null=True, blank=True)
    counters = models.JSONField(default=dict)
