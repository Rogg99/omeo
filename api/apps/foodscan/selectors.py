"""Lectures de la base de connaissances, prêtes à injecter dans le prompt."""

from __future__ import annotations

from django.db.models import Q

from apps.foodscan.models import ConfusionRule, DishKnowledge
from apps.foodscan.regions import normalize_country, region_of
from apps.foodscan.schemas import ConfusionHint, DishHint


def dish_hints_for(*, country: str | None, limit: int) -> list[DishHint]:
    """Fiches du pays d'abord, puis celles de sa région, dans la limite donnée."""
    code = normalize_country(country)
    region = region_of(code)
    if not code and not region:
        return []

    scope_filter = Q(scope=DishKnowledge.Scope.COUNTRY, country=code) if code else Q(pk__in=[])
    if region:
        scope_filter |= Q(scope=DishKnowledge.Scope.REGION, region=region)

    rows = (
        DishKnowledge.objects.filter(scope_filter, is_active=True)
        .order_by("scope", "name")  # "country" < "region" : le pays passe en premier
        .values("key", "name", "aliases", "scope", "visual_description", "distinguishing_tips")
    )

    hints: list[DishHint] = []
    seen: set[str] = set()
    for row in rows:
        if row["key"] in seen:
            continue  # une fiche du pays remplace la fiche régionale du même plat
        seen.add(row["key"])
        hints.append(
            DishHint(
                key=row["key"],
                name=row["name"],
                visual_description=row["visual_description"],
                distinguishing_tips=row["distinguishing_tips"],
                aliases=tuple(str(a) for a in row["aliases"] or ()),
                scope=row["scope"],
            )
        )
        if len(hints) >= limit:
            break
    return hints


def confusion_hints_for(*, country: str | None, limit: int) -> list[ConfusionHint]:
    code = normalize_country(country)
    if not code:
        return []
    rows = (
        ConfusionRule.objects.filter(country=code, status=ConfusionRule.Status.ACTIVE)
        .order_by("-support", "predicted_key")
        .values("predicted_key", "predicted_label", "correct_key", "correct_label", "support", "hint")[:limit]
    )
    return [ConfusionHint(**row) for row in rows]
