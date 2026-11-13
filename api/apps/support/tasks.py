"""Tâches Celery du support (idempotentes) : construction et expiration des exports de données."""

from __future__ import annotations

from celery import shared_task
from django.utils.translation import gettext_noop

from apps.notifications.services import notify
from apps.support import services


@shared_task(name=services.BUILD_EXPORT_TASK, acks_late=True, ignore_result=True)
def build_export(export_id: str) -> None:
    export = services.build_export(export_id=export_id)
    if export is not None:
        notify(
            user=export.user,
            category="support",
            title=gettext_noop("Ton export est prêt"),
            body=gettext_noop("Tes données sont disponibles pendant 24 heures depuis ton profil."),
            deeplink="omeo://profile/data",
            dedupe_key=f"export:{export.pk}",
        )


@shared_task(acks_late=True, ignore_result=True)
def expire_exports() -> int:
    return services.expire_exports()
