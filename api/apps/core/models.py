"""Modèles et mixins communs : identifiant UUID v7, horodatage, réglages, audit, idempotence, quatre yeux."""

from __future__ import annotations

from typing import Any, ClassVar

from django.conf import settings
from django.db import models
from django.db.models import Q

from apps.core.ids import uuid7


class UUIDModel(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid7, editable=False)

    class Meta:
        abstract = True


class TimeStampedModel(models.Model):
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class BaseModel(UUIDModel, TimeStampedModel):
    """Base de toutes les tables : `id` UUID v7, `created_at`, `updated_at` en UTC."""

    class Meta:
        abstract = True


class ContentStatus(models.TextChoices):
    DRAFT = "draft"
    REVIEW = "review"
    PUBLISHED = "published"
    ARCHIVED = "archived"


class Setting(TimeStampedModel):
    """Réglage typé clé/valeur (constantes de calcul, IA, app…). Lu via `apps.core.settings_store`."""

    key = models.CharField(max_length=120, primary_key=True)
    value = models.JSONField()
    updated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name="+"
    )

    def __str__(self) -> str:
        return self.key


class AuditLog(UUIDModel):
    """Journal des actions du staff, en ajout seul (avant, après, IP, motif)."""

    actor = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name="+"
    )
    action = models.CharField(max_length=80, db_index=True)
    target_type = models.CharField(max_length=60, blank=True)
    target_id = models.CharField(max_length=64, blank=True, db_index=True)
    before = models.JSONField(null=True, blank=True)
    after = models.JSONField(null=True, blank=True)
    reason = models.CharField(max_length=500, blank=True)
    ip = models.GenericIPAddressField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        ordering: ClassVar[list[str]] = ["-created_at"]
        indexes: ClassVar[list[models.Index]] = [models.Index(fields=["target_type", "target_id"])]

    def save(self, *args: Any, **kwargs: Any) -> None:
        if not self._state.adding:
            raise ValueError("AuditLog is append-only")
        super().save(*args, **kwargs)

    def delete(self, *args: Any, **kwargs: Any) -> tuple[int, dict[str, int]]:
        raise ValueError("AuditLog is append-only")


class IdempotencyRecord(BaseModel):
    """Réponse mémorisée 24 h pour une `Idempotency-Key` (copie durable de l'entrée Redis)."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="+")
    key = models.UUIDField()
    method = models.CharField(max_length=8)
    path = models.CharField(max_length=255)
    body_hash = models.CharField(max_length=64)
    status_code = models.PositiveSmallIntegerField()
    response_body = models.JSONField(null=True)
    expires_at = models.DateTimeField(db_index=True)

    class Meta:
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.UniqueConstraint(fields=["user", "key"], name="idempotency_user_key_uniq"),
        ]


class ApprovalKind(models.TextChoices):
    CONTENT_PUBLISH = "content_publish"
    CAMPAIGN_SCHEDULE = "campaign_schedule"
    PLAN_UPDATE = "plan_update"
    QUOTA_UPDATE = "quota_update"
    REFUND = "refund"
    SETTINGS_NUTRITION = "settings_nutrition"


class ApprovalDomain(models.TextChoices):
    CONTENT = "content"
    FINANCE = "finance"
    SETTINGS = "settings"


class ApprovalStatus(models.TextChoices):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    EXPIRED = "expired"
    CANCELED = "canceled"


class ApprovalRequest(BaseModel):
    """Action à quatre yeux : rejouée dans la transaction d'approbation, jamais par son demandeur."""

    kind = models.CharField(max_length=32, choices=ApprovalKind.choices)
    domain = models.CharField(max_length=16, choices=ApprovalDomain.choices)
    payload = models.JSONField()
    diff = models.JSONField(default=dict)
    target_type = models.CharField(max_length=60)
    target_id = models.CharField(max_length=64)
    reason = models.CharField(max_length=500)
    requested_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="+")
    status = models.CharField(max_length=16, choices=ApprovalStatus.choices, default=ApprovalStatus.PENDING)
    decided_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.PROTECT, related_name="+"
    )
    decision_comment = models.CharField(max_length=500, blank=True)
    decided_at = models.DateTimeField(null=True, blank=True)
    expires_at = models.DateTimeField(db_index=True)

    class Meta:
        ordering: ClassVar[list[str]] = ["-created_at"]
        constraints: ClassVar[list[models.BaseConstraint]] = [
            models.CheckConstraint(
                condition=Q(decided_by__isnull=True) | ~Q(decided_by=models.F("requested_by")),
                name="approval_decider_not_requester",
            ),
            models.UniqueConstraint(
                fields=["target_type", "target_id", "kind"],
                condition=Q(status="pending"),
                name="approval_one_pending_per_target",
            ),
        ]
