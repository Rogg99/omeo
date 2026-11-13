"""Repas et analyses IA. Ce lot contient les téléversements ; repas, analyses et avis arrivent avec le module meals."""

from __future__ import annotations

from typing import ClassVar

from django.conf import settings
from django.db import models

from apps.core.models import BaseModel


class UploadKind(models.TextChoices):
    MEAL_PHOTO = "meal_photo"
    SUPPORT_ATTACHMENT = "support_attachment"
    AVATAR = "avatar"


class UploadStatus(models.TextChoices):
    PENDING = "pending"
    READY = "ready"
    REJECTED = "rejected"


class Upload(BaseModel):
    """Fichier téléversé directement vers S3 par URL présignée, puis vérifié (type réel, taille, EXIF retiré)."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="uploads")
    kind = models.CharField(max_length=20, choices=UploadKind.choices)
    storage_key = models.CharField(max_length=255, unique=True)
    content_type = models.CharField(max_length=40)
    size = models.PositiveIntegerField()
    width = models.PositiveIntegerField(null=True, blank=True)
    height = models.PositiveIntegerField(null=True, blank=True)
    status = models.CharField(max_length=10, choices=UploadStatus.choices, default=UploadStatus.PENDING)
    rejected_reason = models.CharField(max_length=32, blank=True)
    expires_at = models.DateTimeField()

    class Meta:
        indexes: ClassVar[list[models.Index]] = [models.Index(fields=["user", "kind", "-created_at"])]
