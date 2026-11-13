"""Sonde de vie (orchestrateur, nginx)."""

from __future__ import annotations

from rest_framework.request import Request
from rest_framework.response import Response

from apps.core.views import PublicAPIView


class HealthView(PublicAPIView):
    def get(self, request: Request) -> Response:
        return Response({"status": "ok"})
