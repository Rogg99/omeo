"""Entrées et sorties du support."""

from __future__ import annotations

from typing import Any

from rest_framework import serializers

from apps.support import services
from apps.support.models import DataExport, TicketCategory


class TicketInputSerializer(serializers.Serializer[Any]):
    category = serializers.ChoiceField(choices=TicketCategory.choices)
    subject = serializers.CharField(min_length=3, max_length=120)
    message = serializers.CharField(min_length=10, max_length=5000)
    email = serializers.EmailField(required=False)
    name = serializers.CharField(max_length=80, required=False, allow_blank=True, default="")
    attachment_ids = serializers.ListField(child=serializers.UUIDField(), max_length=3, required=False, default=list)
    captcha = serializers.CharField(max_length=2048, required=False)
    meta = serializers.DictField(child=serializers.CharField(max_length=80), required=False, default=dict)


def export_out(export: DataExport) -> dict[str, Any]:
    return {
        "id": export.id,
        "status": export.status,
        "requested_at": export.requested_at,
        "download_url": services.export_download_url(export),
        "expires_at": export.expires_at,
    }
