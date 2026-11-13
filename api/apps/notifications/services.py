"""
Notifications : appareils, préférences, centre de notifications, envoi push (FCM HTTP v1) et rappels.

`notify` crée la notification dans la langue de l'utilisateur, puis la pousse si les règles l'autorisent : catégorie
activée, hors heures calmes, 3 push par jour au maximum (hors abonnement et support).
"""

from __future__ import annotations

import json
import logging
from collections.abc import Sequence
from functools import cache
from typing import Any, Final

import firebase_admin
from celery import current_app
from django.conf import settings
from django.db import IntegrityError, transaction
from django.db.models import F
from django.utils import timezone, translation
from django.utils.translation import gettext_noop
from firebase_admin import credentials, messaging

from apps.accounts.selectors import latest_consents
from apps.core import settings_store
from apps.core.errors import NotFound, ValidationFailed
from apps.core.i18n import resolve, to_django_locale
from apps.core.localtime import day_bounds, local_now
from apps.notifications import rules
from apps.notifications.models import Campaign, Notification, NotificationPreference, PushDevice

logger = logging.getLogger(__name__)
SEND_PUSH_TASK = "apps.notifications.tasks.send_push"


# ───────────────────────── Appareils et préférences ─────────────────────────


@transaction.atomic
def register_device(*, user: Any, token: str, platform: str, app_version: str, session: Any) -> PushDevice:
    device, _created = PushDevice.objects.update_or_create(
        token=token,
        defaults={
            "user": user,
            "session": session,
            "platform": platform,
            "app_version": app_version,
            "locale": user.locale,
            "disabled_at": None,
        },
    )
    return device


def unregister_device(*, user: Any, token: str) -> None:
    deleted, _ = PushDevice.objects.filter(user=user, token=token).delete()
    if not deleted:
        raise NotFound()


def preferences_for(user: Any) -> NotificationPreference:
    preference, _created = NotificationPreference.objects.get_or_create(
        user=user,
        defaults={
            "quiet_start": settings_store.get("notifications.default_quiet_start", "22:00"),
            "quiet_end": settings_store.get("notifications.default_quiet_end", "07:00"),
        },
    )
    return preference


@transaction.atomic
def update_preferences(*, user: Any, data: dict[str, Any]) -> NotificationPreference:
    preference = preferences_for(user)
    categories = {k: v for k, v in data["categories"].items() if k != "subscription"}
    preference.categories = {**preference.categories, **categories}
    if "meal_reminder_times" in data:
        preference.meal_reminder_times = {**preference.meal_reminder_times, **data["meal_reminder_times"]}
    if "weigh_in_weekday" in data:
        preference.weigh_in_weekday = data["weigh_in_weekday"]
    preference.quiet_start = data["quiet_start"]
    preference.quiet_end = data["quiet_end"]
    preference.save()
    return preference


# ───────────────────────── Centre de notifications ─────────────────────────


def unread_count(user: Any) -> int:
    return Notification.objects.filter(user=user, read_at__isnull=True).count()


def mark_read(*, user: Any, ids: Sequence[Any] | None, all_: bool) -> int:
    if not all_ and not ids:
        raise ValidationFailed(errors={"ids": [{"code": "required", "message": "ids or all"}]})
    queryset = Notification.objects.filter(user=user, read_at__isnull=True)
    if not all_:
        queryset = queryset.filter(pk__in=list(ids or []))
    queryset.update(read_at=timezone.now())
    return unread_count(user)


@transaction.atomic
def track_opened(*, user: Any, notification_id: Any) -> None:
    notification = Notification.objects.select_for_update().filter(pk=notification_id, user=user).first()
    if notification is None:
        raise NotFound()
    if notification.opened_at is None:
        notification.opened_at = timezone.now()
        notification.read_at = notification.read_at or notification.opened_at
        notification.save(update_fields=["opened_at", "read_at", "updated_at"])
        if notification.campaign_id:
            Campaign.objects.filter(pk=notification.campaign_id).update(opened_count=F("opened_count") + 1)


# ───────────────────────── Envoi ─────────────────────────


def _marketing_consent(user: Any) -> bool:
    consent = latest_consents(user).get("marketing")
    return bool(consent and consent.granted)


def _render(user: Any, text: dict[str, str] | str, params: dict[str, Any] | None) -> str:
    """Texte dans la langue de l'utilisateur : I18nText résolu, ou chaîne gettext traduite."""
    with translation.override(to_django_locale(user.locale)):
        value = resolve(text, user.locale) if isinstance(text, dict) else translation.gettext(text)
    return value % params if params else value


@transaction.atomic
def notify(
    *,
    user: Any,
    category: str,
    title: dict[str, str] | str,
    body: dict[str, str] | str,
    params: dict[str, Any] | None = None,
    deeplink: str = "",
    dedupe_key: str = "",
    campaign: Any = None,
    push: bool = True,
) -> Notification | None:
    """Crée la notification (une seule par `dedupe_key`) puis programme la push si les règles l'autorisent."""
    preference = preferences_for(user)
    if not rules.category_enabled(category, preference.categories, marketing_consent=_marketing_consent(user)):
        return None
    try:
        with transaction.atomic():
            notification = Notification.objects.create(
                user=user,
                category=category,
                title=_render(user, title, params)[:140],
                body=_render(user, body, params)[:500],
                deeplink=deeplink,
                dedupe_key=dedupe_key,
                campaign=campaign,
            )
    except IntegrityError:
        return None
    if push and _may_push(user, category, preference):
        transaction.on_commit(lambda: current_app.send_task(SEND_PUSH_TASK, args=[str(notification.pk)]))
    return notification


def _may_push(user: Any, category: str, preference: NotificationPreference) -> bool:
    now = local_now(user)
    start, end = day_bounds(user, now.date())
    pushed_today = (
        Notification.objects.filter(user=user, pushed_at__gte=start, pushed_at__lt=end)
        .exclude(category__in=rules.CAP_EXEMPT)
        .count()
    )
    return rules.may_push(
        category=category,
        pushed_today=pushed_today,
        max_per_day=int(settings_store.get("notifications.max_push_per_day", 3)),
        quiet=rules.in_quiet_hours(now.time(), start=preference.quiet_start, end=preference.quiet_end),
    )


@cache
def _firebase_app() -> Any:
    info = settings.FIREBASE_CREDENTIALS_JSON
    if not info:
        return None
    return firebase_admin.initialize_app(credentials.Certificate(json.loads(info)), name="omeo")


def send_push(*, notification_id: Any) -> int:
    """Envoie la push à tous les appareils actifs (idempotent : déjà poussée = rien). Désactive les jetons invalides."""
    notification = Notification.objects.filter(pk=notification_id, pushed_at__isnull=True).first()
    app = _firebase_app()
    if notification is None or app is None:
        return 0
    devices = list(PushDevice.objects.filter(user_id=notification.user_id, disabled_at__isnull=True))
    if not devices:
        return 0
    message = messaging.MulticastMessage(
        tokens=[d.token for d in devices],
        notification=messaging.Notification(title=notification.title, body=notification.body),
        data={
            "notification_id": str(notification.pk),
            "deeplink": notification.deeplink,
            "category": notification.category,
        },
    )
    response = messaging.send_each_for_multicast(message, app=app)
    for device, result in zip(devices, response.responses, strict=True):
        if not result.success and isinstance(result.exception, messaging.UnregisteredError):
            PushDevice.objects.filter(pk=device.pk).update(disabled_at=timezone.now())
    Notification.objects.filter(pk=notification.pk).update(pushed_at=timezone.now())
    return int(response.success_count)


# ───────────────────────── Rappels ─────────────────────────

# Textes marqués pour l'extraction (gettext_noop), traduits à l'envoi dans la langue de l'utilisateur.
MEAL_REMINDERS: Final[dict[str, tuple[str, str]]] = {
    "breakfast": (
        gettext_noop("Ton petit-déjeuner ?"),
        gettext_noop("Tu n'as pas encore enregistré ton petit-déjeuner."),
    ),
    "lunch": (gettext_noop("Ton déjeuner ?"), gettext_noop("Tu n'as pas encore enregistré ton déjeuner.")),
    "dinner": (gettext_noop("Ton dîner ?"), gettext_noop("Tu n'as pas encore enregistré ton dîner.")),
}
HYDRATION_REMINDER_AT: Final = "15:00"
WEIGH_IN_REMINDER_AT: Final = "08:00"
HYDRATION_THRESHOLD: Final = 0.5
HYDRATION_TEXT: Final = (
    gettext_noop("Pense à boire"),
    gettext_noop("Tu es à moins de la moitié de ton objectif d'eau."),
)
WEIGH_IN_TEXT: Final = (
    gettext_noop("C'est le jour de la pesée"),
    gettext_noop("Monte sur la balance pour suivre ta progression."),
)


def due_reminders(
    *, user: Any, logged_meal_types: set[str], water_ml: int, water_target: int
) -> list[tuple[str, str, str, str, str]]:
    """Rappels dus maintenant (catégorie, titre, texte, lien, clé). Pas de rappel pour un repas déjà enregistré."""
    preference = preferences_for(user)
    now = local_now(user)
    today = now.date()
    due: list[tuple[str, str, str, str, str]] = []
    for meal_type, (title, body) in MEAL_REMINDERS.items():
        at = preference.meal_reminder_times.get(meal_type)
        if at and meal_type not in logged_meal_types and rules.reminder_due(local_now=now, at=at):
            due.append(("meal_reminder", title, body, "omeo://meals/new", f"meal:{today}:{meal_type}"))
    thirsty = water_target > 0 and water_ml < water_target * HYDRATION_THRESHOLD
    if thirsty and rules.reminder_due(local_now=now, at=HYDRATION_REMINDER_AT):
        due.append(("hydration", *HYDRATION_TEXT, "omeo://water", f"water:{today}"))
    weigh_day = now.isoweekday() == preference.weigh_in_weekday
    if weigh_day and rules.reminder_due(local_now=now, at=WEIGH_IN_REMINDER_AT):
        due.append(("weigh_in", *WEIGH_IN_TEXT, "omeo://weight", f"weigh:{today}"))
    return due


def send_due_reminders(*, user: Any, logged_meal_types: set[str], water_ml: int, water_target: int) -> int:
    sent = 0
    for category, title, body, deeplink, key in due_reminders(
        user=user, logged_meal_types=logged_meal_types, water_ml=water_ml, water_target=water_target
    ):
        notification = notify(user=user, category=category, title=title, body=body, deeplink=deeplink, dedupe_key=key)
        sent += int(notification is not None)
    return sent
