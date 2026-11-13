"""
Textes traduits (`I18nText`) : JSONB `{"fr": "…", "en": "…"}`.

Les clés exposées sont les codes du contrat (`zh`, pas `zh-hans`). Repli : langue demandée, anglais, français.
"""

from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Final

from django.core.exceptions import ValidationError
from django.db import models
from django.utils import translation

LOCALES: Final[tuple[str, ...]] = ("fr", "en", "es", "pt", "ar", "zh", "ja", "de")
FALLBACK_CHAIN: Final[tuple[str, ...]] = ("en", "fr")
_DJANGO_TO_API: Final[dict[str, str]] = {"zh-hans": "zh", "zh-hant": "zh"}


def to_api_locale(language: str | None) -> str:
    """Code Django (`zh-hans`, `fr-fr`) vers code du contrat (`zh`, `fr`)."""
    if not language:
        return "fr"
    language = language.lower()
    if language in _DJANGO_TO_API:
        return _DJANGO_TO_API[language]
    base = language.split("-")[0]
    return base if base in LOCALES else "fr"


def to_django_locale(locale: str) -> str:
    return "zh-hans" if locale == "zh" else locale


def active_locale() -> str:
    return to_api_locale(translation.get_language())


def resolve(text: Mapping[str, str] | None, locale: str | None = None) -> str:
    """Chaîne résolue dans la langue demandée, avec repli anglais puis français."""
    if not text:
        return ""
    wanted = locale or active_locale()
    for candidate in (wanted, *FALLBACK_CHAIN):
        value = text.get(candidate)
        if value:
            return value
    return next((value for value in text.values() if value), "")


def validate_i18n_text(value: Any) -> None:
    if not isinstance(value, dict):
        raise ValidationError("I18nText must be an object")
    unknown = set(value) - set(LOCALES)
    if unknown:
        raise ValidationError(f"Unknown locales: {sorted(unknown)}")
    if any(not isinstance(v, str) for v in value.values()):
        raise ValidationError("I18nText values must be strings")


class I18nTextField(models.JSONField):
    """JSONB typé `I18nText`, validé (clés = langues du contrat, valeurs = chaînes)."""

    def __init__(self, *args: Any, **kwargs: Any) -> None:
        kwargs.setdefault("default", dict)
        validators = list(kwargs.pop("validators", []))
        validators.append(validate_i18n_text)
        super().__init__(*args, validators=validators, **kwargs)
