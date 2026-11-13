"""
`Idempotency-Key` (UUID v4) sur les POST du mobile marqués dans le contrat.

La réponse est mémorisée 24 h (Redis pour la lecture rapide, table `IdempotencyRecord` comme copie durable).
Même clé et même corps : réponse d'origine rejouée telle quelle. Même clé, autre corps : 409 `idempotency_conflict`.
Un verrou Redis empêche deux exécutions simultanées de la même clé.
"""

from __future__ import annotations

import hashlib
import json
import uuid
from collections.abc import Callable
from datetime import timedelta
from functools import wraps
from typing import Any, Final, TypeVar

from django.core.cache import cache
from django.utils import timezone
from rest_framework.request import Request
from rest_framework.response import Response

from apps.core.errors import Conflict, IdempotencyConflict, ValidationFailed
from apps.core.models import IdempotencyRecord

HEADER: Final = "HTTP_IDEMPOTENCY_KEY"
TTL: Final = timedelta(hours=24)
LOCK_TTL_S: Final = 30
REPLAY_HEADER: Final = "Idempotent-Replayed"

F = TypeVar("F", bound=Callable[..., Response])


def _body_hash(request: Request) -> str:
    payload = json.dumps(request.data, sort_keys=True, default=str, separators=(",", ":"))
    return hashlib.sha256(f"{request.method}:{request.path}:{payload}".encode()).hexdigest()


def _parse_key(request: Request) -> uuid.UUID:
    raw = request.META.get(HEADER)
    if not raw:
        raise ValidationFailed(errors={"Idempotency-Key": [{"code": "required", "message": "header required"}]})
    try:
        return uuid.UUID(raw)
    except ValueError:
        raise ValidationFailed(errors={"Idempotency-Key": [{"code": "invalid", "message": "UUID expected"}]}) from None


def _cache_key(user_id: Any, key: uuid.UUID) -> str:
    return f"idem:{user_id}:{key}"


def _replay(stored: dict[str, Any], body_hash: str) -> Response:
    if stored["body_hash"] != body_hash:
        raise IdempotencyConflict()
    response = Response(stored["body"], status=stored["status"])
    response[REPLAY_HEADER] = "true"
    return response


def idempotent(view_method: F) -> F:
    """Décorateur de méthode de vue DRF (`def post(self, request, ...)`)."""

    @wraps(view_method)
    def wrapper(self: Any, request: Request, *args: Any, **kwargs: Any) -> Response:
        key = _parse_key(request)
        user_id = request.user.pk
        body_hash = _body_hash(request)
        cache_key = _cache_key(user_id, key)

        stored = cache.get(cache_key)
        if stored is not None:
            return _replay(stored, body_hash)
        record = IdempotencyRecord.objects.filter(user_id=user_id, key=key, expires_at__gt=timezone.now()).first()
        if record is not None:
            return _replay(
                {"body_hash": record.body_hash, "status": record.status_code, "body": record.response_body}, body_hash
            )

        lock_key = f"{cache_key}:lock"
        if not cache.add(lock_key, "1", LOCK_TTL_S):
            raise Conflict(detail="request in progress")
        try:
            response = view_method(self, request, *args, **kwargs)
            if 200 <= response.status_code < 300:
                stored = {"body_hash": body_hash, "status": response.status_code, "body": response.data}
                expires_at = timezone.now() + TTL
                IdempotencyRecord.objects.update_or_create(
                    user_id=user_id,
                    key=key,
                    defaults={
                        "method": request.method or "POST",
                        "path": request.path[:255],
                        "body_hash": body_hash,
                        "status_code": response.status_code,
                        "response_body": json.loads(json.dumps(response.data, default=str)),
                        "expires_at": expires_at,
                    },
                )
                cache.set(cache_key, stored, int(TTL.total_seconds()))
            return response
        finally:
            cache.delete(lock_key)

    wrapper.idempotent = True  # type: ignore[attr-defined]
    return wrapper  # type: ignore[return-value]


def purge_expired() -> int:
    deleted, _ = IdempotencyRecord.objects.filter(expires_at__lte=timezone.now()).delete()
    return deleted
