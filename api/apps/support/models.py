"""Demandes au support, messages, modèles de réponse et exports de données personnelles."""

from __future__ import annotations

from typing import ClassVar

from django.conf import settings
from django.db import models

from apps.core.i18n import I18nTextField
from apps.core.models import BaseModel


class TicketCategory(models.TextChoices):
    QUESTION = "question"
    TECHNICAL = "technical"
    BILLING = "billing"
    SUGGESTION = "suggestion"
    PERSONAL_DATA = "personal_data"
    ACCOUNT_DELETION = "account_deletion"


class TicketStatus(models.TextChoices):
    NEW = "new"
    OPEN = "open"
    WAITING_USER = "waiting_user"
    RESOLVED = "resolved"
    CLOSED = "closed"


class Priority(models.TextChoices):
    LOW = "low"
    NORMAL = "normal"
    HIGH = "high"


class TicketCounter(models.Model):
    """Compteur des numéros lisibles (une ligne, verrouillée à chaque création)."""

    value = models.PositiveIntegerField(default=10000)

    def __str__(self) -> str:
        return str(self.value)


class Ticket(BaseModel):
    number = models.CharField(max_length=20, unique=True)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name="tickets"
    )
    email = models.EmailField()
    name = models.CharField(max_length=80, blank=True)
    category = models.CharField(max_length=16, choices=TicketCategory.choices)
    subject = models.CharField(max_length=120)
    status = models.CharField(max_length=12, choices=TicketStatus.choices, default=TicketStatus.NEW, db_index=True)
    priority = models.CharField(max_length=6, choices=Priority.choices, default=Priority.NORMAL)
    assignee = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name="+"
    )
    channel = models.CharField(max_length=3, default="app")
    meta = models.JSONField(default=dict)
    user_last_read_at = models.DateTimeField(null=True, blank=True)

    def __str__(self) -> str:
        return self.number


class Direction(models.TextChoices):
    INBOUND = "inbound"
    OUTBOUND = "outbound"
    INTERNAL_NOTE = "internal_note"


class TicketMessage(BaseModel):
    ticket = models.ForeignKey(Ticket, on_delete=models.CASCADE, related_name="messages")
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name="+"
    )
    direction = models.CharField(max_length=13, choices=Direction.choices)
    body = models.TextField(max_length=5000)
    attachments = models.ManyToManyField("meals.Upload", blank=True, related_name="+")

    class Meta:
        ordering: ClassVar[list[str]] = ["created_at"]

    def __str__(self) -> str:
        return f"{self.ticket_id}:{self.direction}"


class ReplyTemplate(BaseModel):
    name = models.CharField(max_length=80)
    body = I18nTextField()
    category = models.CharField(max_length=16, choices=TicketCategory.choices, blank=True)

    def __str__(self) -> str:
        return self.name


class ExportStatus(models.TextChoices):
    QUEUED = "queued"
    READY = "ready"
    EXPIRED = "expired"


class DataExport(BaseModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="data_exports")
    status = models.CharField(max_length=8, choices=ExportStatus.choices, default=ExportStatus.QUEUED)
    storage_key = models.CharField(max_length=255, blank=True)
    requested_at = models.DateTimeField(auto_now_add=True)
    ready_at = models.DateTimeField(null=True, blank=True)
    expires_at = models.DateTimeField(null=True, blank=True)

    def __str__(self) -> str:
        return f"export:{self.user_id}:{self.status}"
