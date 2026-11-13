"""Écriture du journal d'audit : toute action du staff, avec l'état avant et après."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from django.conf import settings
from rest_framework.request import Request

from apps.core.models import AuditLog


@dataclass(frozen=True, slots=True)
class RequestMeta:
    """IP et agent utilisateur, enregistrés avec les consentements et les sessions."""

    ip: str | None
    user_agent: str


def client_ip(request: Request | None) -> str | None:
    if request is None:
        return None
    """IP du client vue par le dernier proxy de confiance (la partie gauche d'X-Forwarded-For est falsifiable)."""
    meta = request.META
    proxies: int = settings.TRUSTED_PROXY_COUNT
    forwarded = [ip.strip() for ip in meta.get("HTTP_X_FORWARDED_FOR", "").split(",") if ip.strip()]
    if proxies and len(forwarded) >= proxies:
        return forwarded[-proxies]
    return meta.get("REMOTE_ADDR") or None


def record(
    *,
    actor: Any,
    action: str,
    target_type: str = "",
    target_id: Any = "",
    before: dict[str, Any] | None = None,
    after: dict[str, Any] | None = None,
    reason: str = "",
    request: Request | None = None,
) -> AuditLog:
    return AuditLog.objects.create(
        actor=actor if getattr(actor, "pk", None) else None,
        action=action,
        target_type=target_type,
        target_id=str(target_id or ""),
        before=before,
        after=after,
        reason=reason,
        ip=client_ip(request),
    )
