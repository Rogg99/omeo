"""
Journaux JSON structurés, avec `request_id`. Aucune donnée personnelle ni de santé : les clés sensibles sont masquées
et les adresses email réduites à leur domaine. Le même nettoyage sert au filtre Sentry (`before_send`).
"""

from __future__ import annotations

import json
import logging
import re
from collections.abc import Mapping
from datetime import UTC, datetime
from typing import Any, Final

from apps.core.request_context import current_request_id

SENSITIVE_KEYS: Final = frozenset(
    {
        "password",
        "token",
        "access",
        "refresh",
        "authorization",
        "cookie",
        "secret",
        "id_token",
        "mfa_token",
        "code",
        "email",
        "first_name",
        "last_name",
        "birth_date",
        "weight_kg",
        "current_weight_kg",
        "target_weight_kg",
        "height_cm",
        "measurements",
        "ip",
        "phone",
    }
)
_EMAIL_RE: Final = re.compile(r"[A-Za-z0-9._%+-]+@([A-Za-z0-9.-]+\.[A-Za-z]{2,})")
REDACTED: Final = "[redacted]"


def scrub_text(value: str) -> str:
    return _EMAIL_RE.sub(r"***@\1", value)


def scrub(value: Any, depth: int = 0) -> Any:
    if depth > 8:
        return REDACTED
    if isinstance(value, Mapping):
        return {
            k: (REDACTED if str(k).lower() in SENSITIVE_KEYS else scrub(v, depth + 1)) for k, v in value.items()
        }
    if isinstance(value, list | tuple):
        return [scrub(v, depth + 1) for v in value]
    if isinstance(value, str):
        return scrub_text(value)
    return value


_RESERVED: Final = frozenset(logging.LogRecord("", 0, "", 0, "", (), None).__dict__) | {"message", "asctime"}


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload: dict[str, Any] = {
            "ts": datetime.fromtimestamp(record.created, UTC).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "msg": scrub_text(record.getMessage()),
            "request_id": current_request_id(),
        }
        extra = {k: v for k, v in record.__dict__.items() if k not in _RESERVED and not k.startswith("_")}
        if extra:
            payload["extra"] = scrub(extra)
        if record.exc_info:
            payload["exc"] = scrub_text(self.formatException(record.exc_info))
        return json.dumps(payload, default=str, ensure_ascii=False)


def sentry_before_send(event: dict[str, Any], hint: dict[str, Any]) -> dict[str, Any]:
    """Filtre Sentry : retire les données personnelles (corps, cookies, en-têtes, utilisateur)."""
    request = event.get("request")
    if isinstance(request, dict):
        request.pop("cookies", None)
        request.pop("data", None)
        headers = request.get("headers")
        if isinstance(headers, dict):
            request["headers"] = {k: v for k, v in headers.items() if k.lower() not in {"authorization", "cookie"}}
    user = event.get("user")
    if isinstance(user, dict):
        event["user"] = {"id": user.get("id")}
    for key in ("extra", "contexts", "breadcrumbs"):
        if key in event:
            event[key] = scrub(event[key])
    return event
