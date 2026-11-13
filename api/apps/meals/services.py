"""
Écritures de `meals`. Ce lot : téléversements (URL présignée, puis vérification du fichier reçu).

Vérification à la consommation : type réel (magic bytes), taille ≤ 8 Mo, conversion HEIC → JPEG, retrait EXIF.
Le fichier nettoyé remplace l'original dans le stockage.
"""

from __future__ import annotations

from datetime import timedelta
from typing import Any, Final

from django.conf import settings
from django.db import transaction
from django.utils import timezone

from apps.core import storage
from apps.core.errors import NotFound, ValidationFailed
from apps.meals import images
from apps.meals.models import Upload, UploadStatus

PENDING_TTL: Final = timedelta(hours=1)


@transaction.atomic
def create_upload(*, user: Any, kind: str, content_type: str, size: int) -> tuple[Upload, storage.PresignedUpload]:
    if content_type not in storage.ALLOWED_IMAGE_TYPES:
        raise ValidationFailed(errors={"content_type": [{"code": "invalid_choice", "message": content_type}]})
    if not 0 < size <= settings.UPLOAD_MAX_BYTES:
        raise ValidationFailed(errors={"size": [{"code": "out_of_range", "message": "1..8388608"}]})
    key = storage.build_key(prefix=kind, owner_id=user.pk, extension=storage.ALLOWED_IMAGE_TYPES[content_type])
    ticket = storage.presign_upload(key=key, content_type=content_type, size=size)
    upload = Upload.objects.create(
        user=user,
        kind=kind,
        storage_key=key,
        content_type=content_type,
        size=size,
        expires_at=timezone.now() + PENDING_TTL,
    )
    return upload, ticket


def _reject(upload: Upload, reason: str) -> None:
    upload.status = UploadStatus.REJECTED
    upload.rejected_reason = reason
    upload.save(update_fields=["status", "rejected_reason", "updated_at"])
    transaction.on_commit(lambda: storage.delete(key=upload.storage_key))


@transaction.atomic
def consume_upload(*, user: Any, upload_id: Any, kind: str) -> Upload:
    """Valide un téléversement de l'utilisateur et le rend utilisable. 404 s'il appartient à un autre utilisateur."""
    upload = Upload.objects.select_for_update().filter(pk=upload_id, user=user, kind=kind).first()
    if upload is None:
        raise NotFound()
    if upload.status == UploadStatus.READY:
        return upload
    if upload.status == UploadStatus.REJECTED or upload.expires_at <= timezone.now():
        raise ValidationFailed(errors={"upload_id": [{"code": "upload_invalid", "message": "upload rejected"}]})
    head = storage.head(key=upload.storage_key)
    if head is None:
        raise ValidationFailed(errors={"upload_id": [{"code": "upload_missing", "message": "file not uploaded"}]})
    if int(str(head["size"])) > settings.UPLOAD_MAX_BYTES:
        _reject(upload, "too_large")
        raise ValidationFailed(errors={"upload_id": [{"code": "too_large", "message": "max 8 MB"}]})
    raw = storage.read_bytes(key=upload.storage_key)
    try:
        cleaned = images.sanitize(raw)
    except images.InvalidImageError as exc:
        _reject(upload, exc.reason)
        raise ValidationFailed(errors={"upload_id": [{"code": exc.reason, "message": "invalid image"}]}) from None
    storage.put_bytes(key=upload.storage_key, data=cleaned.data, content_type=cleaned.content_type)
    upload.content_type = cleaned.content_type
    upload.size = len(cleaned.data)
    upload.width, upload.height = cleaned.width, cleaned.height
    upload.status = UploadStatus.READY
    upload.save(update_fields=["content_type", "size", "width", "height", "status", "updated_at"])
    return upload
