"""
Pagination : par curseur pour l'app (`{results, next_cursor}`, pas de `count`), par page pour l'admin.

Le curseur encode, signé, la valeur de tri et l'`id` du dernier élément : (`created_at`, `id`) décroissants.
"""

from __future__ import annotations

from collections.abc import Sequence
from datetime import datetime
from typing import Any, Final

from django.core import signing
from django.db.models import Q, QuerySet
from rest_framework.request import Request

from apps.core.errors import ValidationFailed

_SALT: Final = "omeo.cursor"
DEFAULT_LIMIT: Final = 20
MAX_LIMIT: Final = 100
DEFAULT_PAGE_SIZE: Final = 25
MAX_PAGE_SIZE: Final = 200


def _int_param(request: Request, name: str, *, default: int, maximum: int) -> int:
    raw = request.query_params.get(name)
    if raw is None or raw == "":
        return default
    try:
        value = int(raw)
    except ValueError:
        raise ValidationFailed(errors={name: [{"code": "invalid", "message": "integer expected"}]}) from None
    if value < 1 or value > maximum:
        raise ValidationFailed(errors={name: [{"code": "out_of_range", "message": f"1..{maximum}"}]})
    return value


def cursor_paginate(
    request: Request, queryset: QuerySet[Any], *, order_field: str = "created_at"
) -> tuple[list[Any], str | None]:
    """Page de résultats triés par (`order_field`, `id`) décroissants, et curseur suivant (ou None)."""
    limit = _int_param(request, "limit", default=DEFAULT_LIMIT, maximum=MAX_LIMIT)
    cursor = request.query_params.get("cursor")
    queryset = queryset.order_by(f"-{order_field}", "-id")
    if cursor:
        try:
            last_value, last_id = signing.loads(cursor, salt=_SALT)
        except signing.BadSignature:
            raise ValidationFailed(errors={"cursor": [{"code": "invalid", "message": "invalid cursor"}]}) from None
        field = queryset.model._meta.get_field(order_field)
        value = field.to_python(last_value)
        queryset = queryset.filter(Q(**{f"{order_field}__lt": value}) | Q(**{order_field: value, "id__lt": last_id}))
    rows = list(queryset[: limit + 1])
    if len(rows) <= limit:
        return rows, None
    rows = rows[:limit]
    last = rows[-1]
    last_value = getattr(last, order_field)
    encoded = last_value.isoformat() if isinstance(last_value, datetime) else str(last_value)
    return rows, signing.dumps([encoded, str(last.pk)], salt=_SALT)


def cursor_body(results: Sequence[Any], next_cursor: str | None) -> dict[str, Any]:
    return {"results": list(results), "next_cursor": next_cursor}


ORDERING_PARAM: Final = "ordering"


def apply_ordering(request: Request, queryset: QuerySet[Any], *, allowed: Sequence[str], default: str) -> QuerySet[Any]:
    ordering = request.query_params.get(ORDERING_PARAM) or default
    if ordering.lstrip("-") not in allowed:
        raise ValidationFailed(errors={ORDERING_PARAM: [{"code": "invalid_choice", "message": ", ".join(allowed)}]})
    return queryset.order_by(ordering, "-id")


def page_paginate(request: Request, queryset: QuerySet[Any]) -> tuple[list[Any], dict[str, int]]:
    """Pagination de l'admin : `?page=1&page_size=25`, renvoie les lignes et `{count, page, page_size}`."""
    page = _int_param(request, "page", default=1, maximum=1_000_000)
    page_size = _int_param(request, "page_size", default=DEFAULT_PAGE_SIZE, maximum=MAX_PAGE_SIZE)
    count = queryset.count()
    start = (page - 1) * page_size
    rows = list(queryset[start : start + page_size])
    return rows, {"count": count, "page": page, "page_size": page_size}


def page_body(results: Sequence[Any], meta: dict[str, int]) -> dict[str, Any]:
    return {"results": list(results), **meta}
