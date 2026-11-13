"""Entrées et sorties des notifications."""

from __future__ import annotations

from typing import Any

from rest_framework import serializers

from apps.core.presenters import image_from_key
from apps.notifications.models import Notification, NotificationPreference

HHMM = r"^([01]\d|2[0-3]):[0-5]\d$"


class DeviceSerializer(serializers.Serializer[Any]):
    token = serializers.CharField(max_length=4096)
    platform = serializers.ChoiceField(choices=["android", "ios"])
    app_version = serializers.CharField(max_length=20, required=False, allow_blank=True, default="")


class CategoriesSerializer(serializers.Serializer[Any]):
    meal_reminders = serializers.BooleanField(required=False)
    hydration = serializers.BooleanField(required=False)
    weigh_in = serializers.BooleanField(required=False)
    programs_challenges = serializers.BooleanField(required=False)
    rewards = serializers.BooleanField(required=False)
    prevention = serializers.BooleanField(required=False)
    campaigns = serializers.BooleanField(required=False)
    subscription = serializers.BooleanField(required=False)


class MealTimesSerializer(serializers.Serializer[Any]):
    breakfast = serializers.RegexField(HHMM, required=False)
    lunch = serializers.RegexField(HHMM, required=False)
    dinner = serializers.RegexField(HHMM, required=False)


class PreferencesSerializer(serializers.Serializer[Any]):
    categories = CategoriesSerializer()
    meal_reminder_times = MealTimesSerializer(required=False)
    weigh_in_weekday = serializers.IntegerField(min_value=1, max_value=7, required=False)
    quiet_start = serializers.RegexField(HHMM)
    quiet_end = serializers.RegexField(HHMM)


class ReadSerializer(serializers.Serializer[Any]):
    ids = serializers.ListField(child=serializers.UUIDField(), max_length=100, required=False)
    all = serializers.BooleanField(required=False, default=False)


class ListSerializer(serializers.Serializer[Any]):
    unread = serializers.BooleanField(required=False, default=False)


def preferences_out(preference: NotificationPreference) -> dict[str, Any]:
    return {
        "categories": {**preference.categories, "subscription": True},
        "meal_reminder_times": preference.meal_reminder_times,
        "weigh_in_weekday": preference.weigh_in_weekday,
        "quiet_start": preference.quiet_start,
        "quiet_end": preference.quiet_end,
    }


def notification_out(notification: Notification) -> dict[str, Any]:
    return {
        "id": notification.id,
        "category": notification.category,
        "title": notification.title,
        "body": notification.body,
        "deeplink": notification.deeplink or None,
        "image": image_from_key(notification.image_key),
        "created_at": notification.created_at,
        "read": notification.read_at is not None,
    }
