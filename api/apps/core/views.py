"""Vues de base : refus par défaut. Une vue publique le déclare explicitement (`PublicAPIView`)."""

from __future__ import annotations

from typing import Any, ClassVar

from rest_framework.permissions import AllowAny, BasePermission, IsAuthenticated
from rest_framework.request import Request
from rest_framework.serializers import Serializer
from rest_framework.throttling import BaseThrottle
from rest_framework.views import APIView

from apps.core.audit import RequestMeta, client_ip
from apps.core.permissions import HasPermission
from apps.core.throttles import UserThrottle


def validated(serializer_class: type[Serializer[Any]], data: Any, **kwargs: Any) -> dict[str, Any]:
    serializer = serializer_class(data=data, **kwargs)
    serializer.is_valid(raise_exception=True)
    return dict(serializer.validated_data)


class PublicAPIView(APIView):
    """Opération `security: []` du contrat."""

    authentication_classes: ClassVar[list[type[Any]]] = []
    permission_classes: ClassVar[list[type[BasePermission]]] = [AllowAny]
    throttle_classes: ClassVar[list[type[BaseThrottle]]] = []


class AppAPIView(APIView):
    """Opération d'un utilisateur connecté (`/me/*`, catalogue)."""

    permission_classes: ClassVar[list[type[BasePermission]]] = [IsAuthenticated]
    throttle_classes: ClassVar[list[type[BaseThrottle]]] = [UserThrottle]


class AdminAPIView(APIView):
    """Opération `/admin/*` : `required_permission` (ou `permission_map`) est obligatoire."""

    permission_classes: ClassVar[list[type[BasePermission]]] = [IsAuthenticated, HasPermission]
    throttle_classes: ClassVar[list[type[BaseThrottle]]] = [UserThrottle]
    required_permission: ClassVar[str | None] = None
    permission_map: ClassVar[dict[str, str] | None] = None


def request_meta(request: Request) -> RequestMeta:
    return RequestMeta(ip=client_ip(request), user_agent=request.headers.get("User-Agent", "")[:255])
