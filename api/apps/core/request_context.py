"""Contexte de la requête courante (identifiant, langue), accessible hors des vues (journaux, erreurs)."""

from __future__ import annotations

from contextvars import ContextVar

_request_id: ContextVar[str | None] = ContextVar("request_id", default=None)


def current_request_id() -> str | None:
    return _request_id.get()


def set_request_id(value: str | None) -> None:
    _request_id.set(value)
