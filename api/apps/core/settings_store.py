"""
Lecture des réglages (`Setting`) avec cache Redis. Les clés sont des chemins pointés : `nutrition.salt_max_g`.

Toutes les constantes métier passent par ici : aucune valeur n'est codée en dur dans les modules de calcul.
"""

from __future__ import annotations

from typing import Any, Final

from django.core.cache import cache
from django.db import transaction

from apps.core.models import Setting

_CACHE_KEY: Final = "settings:all:v1"
_CACHE_TTL_S: Final = 300
_MISSING: Final = object()


def _load_all() -> dict[str, Any]:
    cached = cache.get(_CACHE_KEY)
    if cached is not None:
        return dict(cached)
    values = dict(Setting.objects.values_list("key", "value"))
    cache.set(_CACHE_KEY, values, _CACHE_TTL_S)
    return values


def invalidate() -> None:
    cache.delete(_CACHE_KEY)


def get(key: str, default: Any = _MISSING) -> Any:
    """Valeur d'une clé exacte (`nutrition.salt_max_g`), ou d'un préfixe (`nutrition` renvoie un dict)."""
    values = _load_all()
    if key in values:
        return values[key]
    prefix = f"{key}."
    nested = {k[len(prefix) :]: v for k, v in values.items() if k.startswith(prefix)}
    if nested:
        return _unflatten(nested)
    if default is _MISSING:
        raise KeyError(f"Missing setting: {key}")
    return default


def all_values() -> dict[str, Any]:
    return _load_all()


def set_value(key: str, value: Any, *, updated_by_id: Any = None) -> None:
    Setting.objects.update_or_create(key=key, defaults={"value": value, "updated_by_id": updated_by_id})
    transaction.on_commit(invalidate)


def flatten(data: dict[str, Any], prefix: str = "") -> dict[str, Any]:
    """`{"nutrition": {"salt_max_g": 5}}` → `{"nutrition.salt_max_g": 5}`. Les feuilles dict de valeurs restent entières
    quand elles sont des tables (sexe, objectif) : seules les sections de premier et deuxième niveau sont dépliées."""
    out: dict[str, Any] = {}
    for key, value in data.items():
        path = f"{prefix}{key}"
        if isinstance(value, dict) and not prefix:
            out.update(flatten(value, f"{path}."))
        else:
            out[path] = value
    return out


def _unflatten(values: dict[str, Any]) -> dict[str, Any]:
    out: dict[str, Any] = {}
    for key, value in values.items():
        node = out
        parts = key.split(".")
        for part in parts[:-1]:
            node = node.setdefault(part, {})
        node[parts[-1]] = value
    return out
