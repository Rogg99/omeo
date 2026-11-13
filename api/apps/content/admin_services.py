"""
Écritures éditoriales de l'admin : création et modification versionnées (verrou optimiste), transitions du
workflow (brouillon → relecture → publié → archivé), publication à quatre yeux (D27) et correction mineure
(`content.publish_own`, motif obligatoire).
"""

from __future__ import annotations

import json
from typing import Any

from django.core.serializers.json import DjangoJSONEncoder
from django.db import transaction
from django.utils import timezone

from apps.accounts.permissions import has_permission
from apps.accounts.selectors import invalidate_legal_documents
from apps.content import admin_catalog
from apps.content.models import ContentRevision
from apps.core import audit
from apps.core.approvals import ApprovalService, is_enabled
from apps.core.errors import Conflict, NotFound, ValidationFailed
from apps.core.models import ApprovalKind, ApprovalRequest

ALLOWED_TRANSITIONS: dict[str, set[str]] = {
    "draft": {"review", "archived"},
    "review": {"draft", "published", "archived"},
    "published": {"archived", "draft"},
    "archived": {"draft"},
}


def version_of(content_type: str, object_id: Any) -> int:
    return ContentRevision.objects.filter(content_type=content_type, object_id=object_id).count()


def last_author(content_type: str, object_id: Any) -> Any:
    revision = (
        ContentRevision.objects.filter(content_type=content_type, object_id=object_id)
        .order_by("-created_at")
        .select_related("author")
        .first()
    )
    return revision.author if revision else None


def _snapshot(kind: admin_catalog.ContentType, obj: Any) -> dict[str, Any]:
    data: dict[str, Any] = json.loads(json.dumps(kind.to_data(obj), cls=DjangoJSONEncoder))
    return data


def get_object(kind: admin_catalog.ContentType, object_id: Any, *, for_update: bool = False) -> Any:
    queryset = kind.model.objects.all()
    if for_update:
        queryset = queryset.select_for_update()
    obj = queryset.filter(pk=object_id).first()
    if obj is None:
        raise NotFound()
    return obj


@transaction.atomic
def save_content(*, kind: admin_catalog.ContentType, obj: Any, data: dict[str, Any], actor: Any, request: Any) -> Any:
    before = _snapshot(kind, obj) if obj.pk else None
    obj = kind.write(obj, data)
    ContentRevision.objects.create(
        content_type=kind.name, object_id=obj.pk, author=actor, snapshot=_snapshot(kind, obj)
    )
    audit.record(
        actor=actor,
        action=f"content.{'update' if before else 'create'}",
        target_type=kind.name,
        target_id=obj.pk,
        before=before,
        after={"version": version_of(kind.name, obj.pk)},
        request=request,
    )
    return obj


def update_content(
    *,
    kind: admin_catalog.ContentType,
    object_id: Any,
    data: dict[str, Any],
    version: int | None,
    actor: Any,
    request: Any,
) -> Any:
    with transaction.atomic():
        obj = get_object(kind, object_id, for_update=True)
        if version is None:
            raise ValidationFailed(errors={"version": [{"code": "required", "message": "optimistic lock"}]})
        if version != version_of(kind.name, obj.pk):
            raise Conflict(code="version_conflict", detail="content changed since you opened it")
        return save_content(kind=kind, obj=obj, data=data, actor=actor, request=request)


@transaction.atomic
def archive_content(*, kind: admin_catalog.ContentType, object_id: Any, actor: Any, request: Any) -> None:
    obj = get_object(kind, object_id, for_update=True)
    if kind.has_status:
        obj.status = "archived"
        obj.save(update_fields=["status", "updated_at"])
    else:
        obj.delete()
    audit.record(actor=actor, action="content.archive", target_type=kind.name, target_id=object_id, request=request)


def _set_status(kind: admin_catalog.ContentType, obj: Any, status: str) -> None:
    if kind.name == "legal":
        obj.published_at = timezone.now() if status == "published" else None
        obj.save(update_fields=["published_at", "updated_at"])
        transaction.on_commit(invalidate_legal_documents)
        return
    obj.status = status
    obj.save(update_fields=["status", "updated_at"])


@transaction.atomic
def transition(
    *, kind: admin_catalog.ContentType, object_id: Any, to: str, comment: str, actor: Any, request: Any
) -> ApprovalRequest | Any:
    """Change le statut. Publier le contenu dont on est l'auteur passe par une validation à quatre yeux."""
    if not kind.has_status and kind.name != "legal":
        raise Conflict(detail="this content type has no editorial workflow")
    obj = get_object(kind, object_id, for_update=True)
    current = kind.status_of(obj)
    if kind.name == "legal" and to == "review":
        to = "published"
    if to not in ALLOWED_TRANSITIONS.get(current, set()) and not (kind.name == "legal" and to == "published"):
        raise Conflict(detail=f"{current} → {to} not allowed")
    if to == "published":
        is_author = last_author(kind.name, obj.pk) == actor
        if is_author and has_permission(actor, "content.publish_own"):
            if len(comment.strip()) < 3:
                raise ValidationFailed(errors={"comment": [{"code": "required", "message": "reason required"}]})
        elif is_author and is_enabled("content"):
            return ApprovalService.create(
                kind=ApprovalKind.CONTENT_PUBLISH,
                payload={"type": kind.name, "id": str(obj.pk)},
                diff={"before": {"status": current}, "after": {"status": "published"}},
                target_type=kind.name,
                target_id=str(obj.pk),
                reason=comment or "Publication",
                requested_by=actor,
                request=request,
            )
    _set_status(kind, obj, to)
    audit.record(
        actor=actor,
        action=f"content.{to}",
        target_type=kind.name,
        target_id=obj.pk,
        before={"status": current},
        after={"status": to},
        reason=comment,
        request=request,
    )
    return obj


def apply_content_publish(approval: ApprovalRequest, decider: Any) -> dict[str, Any]:
    kind = admin_catalog.get(approval.payload["type"])
    obj = get_object(kind, approval.payload["id"], for_update=True)
    _set_status(kind, obj, "published")
    return {"status": "published"}
