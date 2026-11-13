"""Sorties publiques d'accounts, réutilisables par les autres applications."""

from __future__ import annotations

from typing import Any

from django.utils.translation import gettext_lazy as _

from apps.core.i18n import resolve

TARGET_WARNINGS: dict[str, Any] = {
    "target_above_current_for_loss": _(
        "Ton poids cible est supérieur à ton poids actuel alors que tu veux perdre du poids."
    ),
    "target_below_current_for_gain": _(
        "Ton poids cible est inférieur à ton poids actuel alors que tu veux prendre de la masse."
    ),
}


def targets_out(target: Any) -> dict[str, Any] | None:
    if target is None:
        return None
    return {
        "kcal": target.base_kcal,
        "protein_g": target.protein_g,
        "carbs_g": target.carbs_g,
        "fat_g": target.fat_g,
        "fiber_g": target.fiber_g,
        "salt_max_g": float(target.salt_max_g),
        "water_ml": target.water_ml,
        "bmr_kcal": target.bmr_kcal,
        "valid_from": target.valid_from,
        "warning": str(TARGET_WARNINGS[target.warning]) if target.warning in TARGET_WARNINGS else None,
    }


def legal_ref_out(document: Any) -> dict[str, Any]:
    return {"kind": document.kind, "version": document.version, "title": resolve(document.title)}


def city_out(city: Any) -> dict[str, Any] | None:
    if city is None:
        return None
    return {"id": city.id, "name": resolve(city.name), "country": city.country, "timezone": city.timezone}
