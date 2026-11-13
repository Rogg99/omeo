"""Lectures de content (publiées uniquement), avec favoris annotés et sans N+1."""

from __future__ import annotations

from collections.abc import Sequence
from typing import Any

from django.db.models import Exists, F, OuterRef, Prefetch, Q, QuerySet
from django.db.models.fields.json import KT

from apps.content.models import (
    FaqItem,
    FavoritePlant,
    FavoriteRecipe,
    Plant,
    PreventionTip,
    Recipe,
    RecipeIngredient,
    UserTip,
    WeeklyReport,
)
from apps.core.models import ContentStatus


def recipes_for(*, user: Any) -> QuerySet[Recipe]:
    return Recipe.objects.filter(status=ContentStatus.PUBLISHED).annotate(
        is_favorite=Exists(FavoriteRecipe.objects.filter(user=user, recipe=OuterRef("pk"))),
        total_minutes=F("prep_minutes") + F("cook_minutes"),
    )


def filter_recipes(
    queryset: QuerySet[Recipe],
    *,
    q: str | None,
    country: str | None,
    goal: str | None,
    tags: Sequence[str],
    max_minutes: int | None,
    favorites: bool,
) -> QuerySet[Recipe]:
    if q:
        queryset = queryset.annotate(name_fr=KT("name__fr"), name_en=KT("name__en")).filter(
            Q(name_fr__unaccent__icontains=q) | Q(name_en__unaccent__icontains=q)
        )
    if country:
        queryset = queryset.filter(country=country.upper())
    if goal:
        queryset = queryset.filter(goals__contains=[goal])
    if tags:
        queryset = queryset.filter(tags__contains=list(tags))
    if max_minutes:
        queryset = queryset.filter(total_minutes__lte=max_minutes)
    if favorites:
        queryset = queryset.filter(is_favorite=True)
    return queryset


def recipe_detail(*, user: Any, recipe_id: Any) -> Recipe | None:
    return (
        recipes_for(user=user)
        .prefetch_related(
            Prefetch("ingredients", queryset=RecipeIngredient.objects.select_related("food")),
            "steps",
            Prefetch("related_plants", queryset=plants_for(user=user)),
        )
        .filter(pk=recipe_id)
        .first()
    )


def plants_for(*, user: Any) -> QuerySet[Plant]:
    return Plant.objects.filter(status=ContentStatus.PUBLISHED).annotate(
        is_favorite=Exists(FavoritePlant.objects.filter(user=user, plant=OuterRef("pk")))
    )


def filter_plants(queryset: QuerySet[Plant], *, q: str | None, tag: str | None, favorites: bool) -> QuerySet[Plant]:
    if q:
        queryset = queryset.annotate(name_fr=KT("common_name__fr")).filter(
            Q(name_fr__unaccent__icontains=q) | Q(scientific_name__icontains=q)
        )
    if tag:
        queryset = queryset.filter(tags__contains=[tag])
    if favorites:
        queryset = queryset.filter(is_favorite=True)
    return queryset


def plant_detail(*, user: Any, plant_id: Any) -> Plant | None:
    return (
        plants_for(user=user)
        .prefetch_related(Prefetch("related_recipes", queryset=recipes_for(user=user)))
        .filter(pk=plant_id)
        .first()
    )


def active_tips(*, user: Any) -> list[UserTip]:
    return list(
        UserTip.objects.filter(user=user, dismissed_at__isnull=True, tip__status=ContentStatus.PUBLISHED)
        .select_related("tip")
        .prefetch_related(
            Prefetch("tip__related_recipes", queryset=recipes_for(user=user)),
            Prefetch("tip__related_plants", queryset=plants_for(user=user)),
        )
        .order_by("-triggered_on")[:10]
    )


def latest_tip(*, user: Any) -> UserTip | None:
    return (
        UserTip.objects.filter(user=user, dismissed_at__isnull=True, read_at__isnull=True)
        .select_related("tip")
        .order_by("-triggered_on")
        .first()
    )


def latest_weekly_report(*, user: Any) -> WeeklyReport | None:
    return WeeklyReport.objects.filter(user=user).order_by("-week_start").first()


def faq(*, audience: str | None) -> list[FaqItem]:
    queryset = FaqItem.objects.filter(status=ContentStatus.PUBLISHED)
    if audience:
        queryset = queryset.filter(audience__in=[audience, "both"])
    return list(queryset.order_by("order", "created_at"))


def tips_published() -> QuerySet[PreventionTip]:
    return PreventionTip.objects.filter(status=ContentStatus.PUBLISHED)
