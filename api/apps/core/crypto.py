"""
Chiffrement au repos des données de santé (poids, mesures) : Fernet (AES-128-CBC + HMAC-SHA256).

`FIELD_ENCRYPTION_KEYS` liste les clés, la première chiffre ; les suivantes servent seulement à déchiffrer
(rotation sans réécriture immédiate). Les champs chiffrés ne sont ni filtrables ni triables en SQL.
"""

from __future__ import annotations

from decimal import Decimal
from functools import cache
from typing import Any

from cryptography.fernet import Fernet, InvalidToken, MultiFernet
from django.conf import settings
from django.core.exceptions import ImproperlyConfigured
from django.db import models


@cache
def _fernet() -> MultiFernet:
    keys: list[str] = list(getattr(settings, "FIELD_ENCRYPTION_KEYS", []))
    if not keys:
        raise ImproperlyConfigured("FIELD_ENCRYPTION_KEYS is empty")
    return MultiFernet([Fernet(key.encode()) for key in keys])


def encrypt(value: str) -> str:
    return _fernet().encrypt(value.encode()).decode()


def decrypt(token: str) -> str:
    try:
        return _fernet().decrypt(token.encode()).decode()
    except InvalidToken as exc:
        raise ValueError("Cannot decrypt field (wrong key?)") from exc


class EncryptedDecimalField(models.TextField):
    """Décimal chiffré, stocké en texte. `decimal_places` fixe l'arrondi avant chiffrement."""

    def __init__(self, *args: Any, decimal_places: int = 2, **kwargs: Any) -> None:
        self.decimal_places = decimal_places
        super().__init__(*args, **kwargs)

    def deconstruct(self) -> tuple[str, str, list[Any], dict[str, Any]]:
        name, path, args, kwargs = super().deconstruct()
        kwargs["decimal_places"] = self.decimal_places
        return name, path, args, kwargs

    def from_db_value(self, value: str | None, expression: Any, connection: Any) -> Decimal | None:
        if value is None:
            return None
        return Decimal(decrypt(value))

    def to_python(self, value: Any) -> Decimal | None:
        if value is None or isinstance(value, Decimal):
            return value
        return Decimal(str(value))

    def get_prep_value(self, value: Any) -> str | None:
        if value is None:
            return None
        quantized = Decimal(str(value)).quantize(Decimal(1).scaleb(-self.decimal_places))
        return encrypt(str(quantized))
