"""
Erreurs `application/problem+json` (RFC 9457). Le `code` est stable ; `title` et `detail` sont traduits (gettext).

Les services lèvent des `ApiError` ; le gestionnaire DRF `problem_exception_handler` les sérialise,
ainsi que les exceptions natives de DRF et de Django.
"""

from __future__ import annotations

from collections.abc import Mapping
from typing import Any

from django.core.exceptions import PermissionDenied as DjangoPermissionDenied
from django.http import Http404
from django.utils.translation import gettext_lazy as _
from rest_framework import exceptions as drf_exceptions
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import exception_handler as drf_exception_handler

from apps.core.request_context import current_request_id

ERROR_TYPE_BASE = "https://omeo.app/errors/"
PROBLEM_CONTENT_TYPE = "application/problem+json"


class ApiError(Exception):
    status_code: int = status.HTTP_400_BAD_REQUEST
    code: str = "bad_request"
    title: Any = _("Requête invalide")

    def __init__(
        self,
        detail: Any = None,
        *,
        code: str | None = None,
        status_code: int | None = None,
        meta: Mapping[str, Any] | None = None,
        errors: Mapping[str, list[dict[str, str]]] | None = None,
        headers: Mapping[str, str] | None = None,
    ) -> None:
        super().__init__(str(detail or self.title))
        self.detail = detail
        if code is not None:
            self.code = code
        if status_code is not None:
            self.status_code = status_code
        self.meta = dict(meta or {})
        self.errors = dict(errors or {})
        self.headers = dict(headers or {})


class ValidationFailed(ApiError):
    status_code = 400
    code = "validation_error"
    title = _("Données invalides")


class NotAuthenticated(ApiError):
    status_code = 401
    code = "not_authenticated"
    title = _("Authentification requise")


class InvalidCredentials(ApiError):
    status_code = 401
    code = "invalid_credentials"
    title = _("Identifiants invalides")


class TokenExpired(ApiError):
    status_code = 401
    code = "token_expired"
    title = _("Session expirée")


class MfaRequired(ApiError):
    status_code = 401
    code = "mfa_required"
    title = _("Double authentification requise")


class StepUpRequired(ApiError):
    status_code = 401
    code = "step_up_required"
    title = _("Confirme ton code de double authentification")


class Forbidden(ApiError):
    status_code = 403
    code = "forbidden"
    title = _("Action non autorisée")


class ForbiddenRole(Forbidden):
    code = "forbidden_role"
    title = _("Ton rôle ne permet pas cette action")


class PlanRequired(Forbidden):
    code = "plan_required"
    title = _("Fonction réservée à Omeo Plus")


class EmailNotVerified(Forbidden):
    code = "email_not_verified"
    title = _("Vérifie d'abord ton adresse email")


class AccountSuspended(Forbidden):
    code = "account_suspended"
    title = _("Ce compte est suspendu")


class SelfApprovalForbidden(Forbidden):
    code = "self_approval_forbidden"
    title = _("Tu ne peux pas valider ta propre demande")


class NotFound(ApiError):
    status_code = 404
    code = "not_found"
    title = _("Introuvable")


class Conflict(ApiError):
    status_code = 409
    code = "conflict"
    title = _("Conflit")


class IdempotencyConflict(Conflict):
    code = "idempotency_conflict"
    title = _("Cette clé d'idempotence a déjà servi pour une autre requête")


class ApprovalPending(Conflict):
    code = "approval_pending"
    title = _("Une demande identique est déjà en attente")


class UpgradeRequired(ApiError):
    status_code = 426
    code = "upgrade_required"
    title = _("Mets à jour l'application")


class QuotaExceeded(ApiError):
    status_code = 429
    code = "quota_exceeded"
    title = _("Quota atteint")


class RateLimited(ApiError):
    status_code = 429
    code = "rate_limited"
    title = _("Trop de requêtes, réessaie dans un instant")


class AiUnavailable(ApiError):
    status_code = 503
    code = "ai_unavailable"
    title = _("L'analyse est momentanément indisponible")


def field_errors(errors: Mapping[str, list[str]], *, code: str = "invalid") -> dict[str, list[dict[str, str]]]:
    return {field: [{"code": code, "message": str(m)} for m in messages] for field, messages in errors.items()}


def problem_body(
    *,
    status_code: int,
    code: str,
    title: Any,
    detail: Any = None,
    errors: Mapping[str, Any] | None = None,
    meta: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    body: dict[str, Any] = {
        "type": f"{ERROR_TYPE_BASE}{code}",
        "title": str(title),
        "status": status_code,
        "code": code,
    }
    if detail is not None:
        body["detail"] = str(detail)
    if errors:
        body["errors"] = dict(errors)
    if meta:
        body["meta"] = dict(meta)
    request_id = current_request_id()
    if request_id:
        body["request_id"] = request_id
    return body


def problem_response(error: ApiError) -> Response:
    response = Response(
        problem_body(
            status_code=error.status_code,
            code=error.code,
            title=error.title,
            detail=error.detail,
            errors=error.errors,
            meta=error.meta,
        ),
        status=error.status_code,
        headers=error.headers,
        content_type=PROBLEM_CONTENT_TYPE,
    )
    return response


def _flatten_drf_errors(data: Any, prefix: str = "") -> dict[str, list[dict[str, str]]]:
    """Aplatis les erreurs imbriquées de DRF : `profile.height_cm`, `consents.0.kind`."""
    out: dict[str, list[dict[str, str]]] = {}
    if isinstance(data, Mapping):
        for key, value in data.items():
            name = "non_field_errors" if key == "non_field_errors" and not prefix else f"{prefix}{key}"
            out.update(_flatten_drf_errors(value, f"{name}."))
    elif isinstance(data, list):
        if data and all(isinstance(item, drf_exceptions.ErrorDetail | str) for item in data):
            field = prefix.rstrip(".") or "non_field_errors"
            out[field] = [{"code": getattr(item, "code", "invalid") or "invalid", "message": str(item)} for item in data]
        else:
            for index, item in enumerate(data):
                out.update(_flatten_drf_errors(item, f"{prefix}{index}."))
    elif data is not None:
        field = prefix.rstrip(".") or "non_field_errors"
        out[field] = [{"code": getattr(data, "code", "invalid") or "invalid", "message": str(data)}]
    return out


_DRF_MAP: dict[type[Exception], type[ApiError]] = {
    drf_exceptions.NotAuthenticated: NotAuthenticated,
    drf_exceptions.AuthenticationFailed: NotAuthenticated,
    drf_exceptions.PermissionDenied: Forbidden,
    drf_exceptions.NotFound: NotFound,
}


def problem_exception_handler(exc: Exception, context: Mapping[str, Any]) -> Response | None:
    if isinstance(exc, ApiError):
        return problem_response(exc)
    if isinstance(exc, Http404):
        return problem_response(NotFound())
    if isinstance(exc, DjangoPermissionDenied):
        return problem_response(Forbidden())
    if isinstance(exc, drf_exceptions.ValidationError):
        return problem_response(ValidationFailed(errors=_flatten_drf_errors(exc.detail)))
    if isinstance(exc, drf_exceptions.Throttled):
        wait = int(exc.wait or 1)
        return problem_response(RateLimited(headers={"Retry-After": str(wait)}, meta={"retry_after": wait}))
    if isinstance(exc, drf_exceptions.AuthenticationFailed):
        token_code = getattr(exc, "get_codes", lambda: None)()
        if isinstance(token_code, dict) and token_code.get("code") == "token_not_valid":
            return problem_response(TokenExpired())
    for drf_class, api_class in _DRF_MAP.items():
        if isinstance(exc, drf_class):
            return problem_response(api_class())
    response = drf_exception_handler(exc, dict(context))
    if response is None:
        return None
    response.data = problem_body(
        status_code=response.status_code,
        code=getattr(exc, "default_code", "error"),
        title=getattr(exc, "detail", _("Erreur")),
    )
    response.content_type = PROBLEM_CONTENT_TYPE
    return response
