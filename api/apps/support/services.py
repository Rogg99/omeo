"""
Support : demandes (app connectée ou formulaire public avec captcha), fil de discussion, exports RGPD.

L'export rassemble toutes les données de l'utilisateur (JSON + CSV dans une archive ZIP), stockée dans le bucket
privé et servie par un lien signé valable 24 h.
"""

from __future__ import annotations

import csv
import io
import json
import zipfile
from datetime import timedelta
from typing import Any, Final

from celery import current_app
from django.core.serializers.json import DjangoJSONEncoder
from django.db import transaction
from django.utils import timezone

from apps.core import exports, settings_store, storage
from apps.core.errors import NotFound, RateLimited, ValidationFailed
from apps.meals.services import consume_upload
from apps.support.models import (
    DataExport,
    Direction,
    ExportStatus,
    Ticket,
    TicketCounter,
    TicketMessage,
)

EXPORT_TTL: Final = timedelta(hours=24)
EXPORT_COOLDOWN: Final = timedelta(hours=24)
BUILD_EXPORT_TASK: Final = "apps.support.tasks.build_export"


def _next_number() -> str:
    counter, _created = TicketCounter.objects.select_for_update().get_or_create(pk=1)
    counter.value += 1
    counter.save(update_fields=["value"])
    prefix = str(settings_store.get("support.ticket_prefix", "OM"))
    return f"{prefix}-{counter.value}"


@transaction.atomic
def create_ticket(
    *,
    user: Any,
    category: str,
    subject: str,
    message: str,
    email: str | None,
    name: str,
    attachment_ids: list[Any],
    meta: dict[str, Any],
    channel: str,
) -> Ticket:
    if user is None and not email:
        raise ValidationFailed(errors={"email": [{"code": "required", "message": "required without account"}]})
    ticket = Ticket.objects.create(
        number=_next_number(),
        user=user,
        email=(email or user.email).strip().lower(),
        name=name or (user.profile.first_name if user is not None else ""),
        category=category,
        subject=subject.strip(),
        channel=channel,
        meta={k: str(v)[:80] for k, v in meta.items() if k in ("app_version", "os", "device")},
    )
    first = TicketMessage.objects.create(ticket=ticket, author=user, direction=Direction.INBOUND, body=message.strip())
    if attachment_ids:
        if user is None:
            raise ValidationFailed(errors={"attachment_ids": [{"code": "forbidden", "message": "sign in to attach"}]})
        first.attachments.set(
            [consume_upload(user=user, upload_id=upload_id, kind="support_attachment") for upload_id in attachment_ids]
        )
    return ticket


def own_ticket(*, user: Any, ticket_id: Any) -> Ticket:
    ticket = Ticket.objects.filter(pk=ticket_id, user=user).first()
    if ticket is None:
        raise NotFound()
    return ticket


def mark_ticket_read(ticket: Ticket) -> None:
    Ticket.objects.filter(pk=ticket.pk).update(user_last_read_at=timezone.now())


# ───────────────────────── Exports RGPD ─────────────────────────


@transaction.atomic
def request_export(*, user: Any) -> DataExport:
    recent = DataExport.objects.filter(user=user, requested_at__gt=timezone.now() - EXPORT_COOLDOWN).first()
    if recent is not None:
        raise RateLimited(meta={"retry_after": int(EXPORT_COOLDOWN.total_seconds())})
    export = DataExport.objects.create(user=user)
    transaction.on_commit(lambda: current_app.send_task(BUILD_EXPORT_TASK, args=[str(export.pk)]))
    return export


def _cell(value: Any) -> Any:
    return json.dumps(value, cls=DjangoJSONEncoder) if isinstance(value, dict | list) else value


def _csv(rows: list[dict[str, Any]]) -> str:
    if not rows:
        return ""
    buffer = io.StringIO()
    writer = csv.DictWriter(buffer, fieldnames=list(rows[0]))
    writer.writeheader()
    for row in rows:
        writer.writerow(
            {k: json.dumps(v, cls=DjangoJSONEncoder) if isinstance(v, (dict, list)) else v for k, v in row.items()}
        )
    return buffer.getvalue()


def build_export(*, export_id: Any) -> DataExport | None:
    """Corps de la tâche Celery (idempotent : un export prêt n'est jamais reconstruit)."""
    export = DataExport.objects.select_related("user").filter(pk=export_id, status=ExportStatus.QUEUED).first()
    if export is None:
        return None
    data = exports.collect(export.user)
    archive = io.BytesIO()
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as bundle:
        bundle.writestr("omeo-export.json", json.dumps(data, cls=DjangoJSONEncoder, ensure_ascii=False, indent=2))
        for name, rows in data.items():
            bundle.writestr(f"{name}.csv", _csv(rows))
    key = storage.build_key(prefix="exports", owner_id=export.user_id, extension="zip")
    storage.put_bytes(key=key, data=archive.getvalue(), content_type="application/zip")
    now = timezone.now()
    DataExport.objects.filter(pk=export.pk).update(
        status=ExportStatus.READY, storage_key=key, ready_at=now, expires_at=now + EXPORT_TTL
    )
    export.refresh_from_db()
    return export


def export_download_url(export: DataExport) -> str | None:
    if export.status != ExportStatus.READY or not export.storage_key:
        return None
    if export.expires_at and export.expires_at <= timezone.now():
        return None
    return storage.presign_download(
        key=export.storage_key, filename="omeo-export.zip", ttl=int(EXPORT_TTL.total_seconds())
    )


def expire_exports() -> int:
    """Tâche planifiée : supprime les archives échues."""
    expired = 0
    for export in DataExport.objects.filter(status=ExportStatus.READY, expires_at__lte=timezone.now()):
        storage.delete(key=export.storage_key)
        DataExport.objects.filter(pk=export.pk).update(status=ExportStatus.EXPIRED, storage_key="")
        expired += 1
    return expired
