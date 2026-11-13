"""
Middlewares transverses :
- `RequestIdMiddleware` : `X-Request-Id` (repris du proxy ou généré), dans chaque réponse et chaque journal ;
- `MinimumAppVersionMiddleware` : 426 `upgrade_required` si `X-Client: mobile/<version> (<os> …)` est trop ancien ;
- `SecurityHeadersMiddleware` : en-têtes de sécurité propres à une API JSON.
"""

from __future__ import annotations

import json
import re
from collections.abc import Callable
from typing import Final

from django.http import HttpRequest, HttpResponse

from apps.core import settings_store
from apps.core.errors import PROBLEM_CONTENT_TYPE, UpgradeRequired, problem_body
from apps.core.ids import uuid7
from apps.core.request_context import set_request_id

_REQUEST_ID_RE: Final = re.compile(r"^[A-Za-z0-9._-]{8,64}$")
_CLIENT_RE: Final = re.compile(r"^mobile/(?P<version>\d+(?:\.\d+){0,2})\s*\((?P<os>android|ios)\b", re.IGNORECASE)

GetResponse = Callable[[HttpRequest], HttpResponse]


class RequestIdMiddleware:
    def __init__(self, get_response: GetResponse) -> None:
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        incoming = request.headers.get("X-Request-Id", "")
        request_id = incoming if _REQUEST_ID_RE.match(incoming) else uuid7().hex
        request.request_id = request_id  # type: ignore[attr-defined]
        set_request_id(request_id)
        try:
            response = self.get_response(request)
        finally:
            set_request_id(None)
        response["X-Request-Id"] = request_id
        return response


def parse_version(value: str) -> tuple[int, ...]:
    parts = [int(p) for p in re.findall(r"\d+", value)[:3]]
    return tuple(parts + [0] * (3 - len(parts)))


class MinimumAppVersionMiddleware:
    def __init__(self, get_response: GetResponse) -> None:
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        match = _CLIENT_RE.match(request.headers.get("X-Client", ""))
        if match and request.path.startswith("/api/v1/") and not request.path.startswith("/api/v1/app/config"):
            platform = match.group("os").lower()
            minimum = str(settings_store.get(f"app.min_version_{platform}", "0.0.0"))
            if parse_version(match.group("version")) < parse_version(minimum):
                error = UpgradeRequired(meta={"min_version": minimum, "platform": platform})
                body = problem_body(status_code=426, code=error.code, title=error.title, meta=error.meta)
                return HttpResponse(json.dumps(body), status=426, content_type=PROBLEM_CONTENT_TYPE)
        return self.get_response(request)


class SecurityHeadersMiddleware:
    def __init__(self, get_response: GetResponse) -> None:
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        response = self.get_response(request)
        response.setdefault("Cache-Control", "no-store")
        response.setdefault("X-Content-Type-Options", "nosniff")
        response.setdefault("Referrer-Policy", "no-referrer")
        response.setdefault("Permissions-Policy", "camera=(), microphone=(), geolocation=()")
        if not request.path.startswith("/api/v1/docs"):
            response.setdefault("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'")
        return response
