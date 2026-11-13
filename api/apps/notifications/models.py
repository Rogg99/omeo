"""Appareils push, préférences, centre de notifications et campagnes."""

from __future__ import annotations

from typing import ClassVar

from django.conf import settings
from django.db import models

from apps.core.i18n import I18nTextField
from apps.core.models import BaseModel


class PushDevice(BaseModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="push_devices")
    session = models.ForeignKey("accounts.Session", null=True, blank=True, on_delete=models.SET_NULL, related_name="+")
    platform = models.CharField(max_length=8)
    token = models.CharField(max_length=4096, unique=True)
    locale = models.CharField(max_length=2, default="fr")
    app_version = models.CharField(max_length=20, blank=True)
    last_seen_at = models.DateTimeField(auto_now=True)
    disabled_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        indexes: ClassVar[list[models.Index]] = [models.Index(fields=["user", "disabled_at"])]

    def __str__(self) -> str:
        return f"{self.platform}:{self.user_id}"


DEFAULT_CATEGORIES: dict[str, bool] = {
    "meal_reminders": True,
    "hydration": True,
    "weigh_in": True,
    "programs_challenges": True,
    "rewards": True,
    "prevention": True,
    "campaigns": False,
}
DEFAULT_MEAL_TIMES: dict[str, str] = {"breakfast": "08:00", "lunch": "12:30", "dinner": "19:30"}


def _default_categories() -> dict[str, bool]:
    return dict(DEFAULT_CATEGORIES)


def _default_meal_times() -> dict[str, str]:
    return dict(DEFAULT_MEAL_TIMES)


class NotificationPreference(BaseModel):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="notification_preference"
    )
    categories = models.JSONField(default=_default_categories)
    meal_reminder_times = models.JSONField(default=_default_meal_times)
    weigh_in_weekday = models.PositiveSmallIntegerField(default=1)  # 1 = lundi
    quiet_start = models.CharField(max_length=5, default="22:00")
    quiet_end = models.CharField(max_length=5, default="07:00")

    def __str__(self) -> str:
        return f"preferences:{self.user_id}"


class Category(models.TextChoices):
    MEAL_REMINDER = "meal_reminder"
    HYDRATION = "hydration"
    WEIGH_IN = "weigh_in"
    PROGRAM = "program"
    CHALLENGE = "challenge"
    REWARD = "reward"
    PREVENTION = "prevention"
    SUBSCRIPTION = "subscription"
    CAMPAIGN = "campaign"
    SUPPORT = "support"


class Notification(BaseModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="notifications")
    category = models.CharField(max_length=16, choices=Category.choices)
    title = models.CharField(max_length=140)
    body = models.CharField(max_length=500)
    deeplink = models.CharField(max_length=200, blank=True)
    image_key = models.CharField(max_length=255, blank=True)
    data = models.JSONField(default=dict)
    dedupe_key = models.CharField(max_length=120, blank=True)  # une seule notification par clé (idempotence)
    pushed_at = models.DateTimeField(null=True, blank=True)
    read_at = models.DateTimeField(null=True, blank=True)
    opened_at = models.DateTimeField(null=True, blank=True)
    campaign = models.ForeignKey("Campaign", null=True, blank=True, on_delete=models.SET_NULL, related_name="+")

    class Meta:
        indexes: ClassVar[list[models.Index]] = [models.Index(fields=["user", "-created_at"])]
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(
                fields=["user", "dedupe_key"], condition=~models.Q(dedupe_key=""), name="notification_dedupe_uniq"
            ),
        ]

    def __str__(self) -> str:
        return f"{self.category}:{self.user_id}"


class CampaignStatus(models.TextChoices):
    DRAFT = "draft"
    SCHEDULED = "scheduled"
    SENDING = "sending"
    SENT = "sent"
    CANCELED = "canceled"


class Campaign(BaseModel):
    title = I18nTextField()
    body = I18nTextField()
    deeplink = models.CharField(max_length=200, blank=True)
    segment = models.JSONField(default=dict)  # langues, pays, offres, objectifs, inactif depuis N jours
    scheduled_at = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=10, choices=CampaignStatus.choices, default=CampaignStatus.DRAFT)
    sent_count = models.PositiveIntegerField(default=0)
    opened_count = models.PositiveIntegerField(default=0)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="+")

    def __str__(self) -> str:
        return str(self.title.get("fr", self.pk))
