"""Lectures nutritionnelles : objectifs, résumés quotidiens (projection), catalogue d'aliments et de plats."""

from __future__ import annotations

from datetime import date, timedelta
from typing import Any

from django.contrib.postgres.search import TrigramWordSimilarity
from django.db.models import Exists, OuterRef, Prefetch, QuerySet

from apps.core.models import ContentStatus
from apps.nutrition import projection, search
from apps.nutrition.models import DailySummary, Dish, DishComponent, FavoriteDish, Food, NutritionTarget

FOOD_SEARCH_THRESHOLD = 0.3


def target_on(*, user: Any, day: date) -> NutritionTarget | None:
    return NutritionTarget.objects.filter(user=user, valid_from__lte=day).order_by("-valid_from").first()


def summaries_between(*, user: Any, start: date, end: date) -> dict[date, DailySummary]:
    """Résumés existants de `start` à `end` inclus (un jour sans écriture n'a pas de ligne : il est vide)."""
    rows = DailySummary.objects.filter(user=user, date__gte=start, date__lte=end)
    return {row.date: row for row in rows}


def empty_day(*, day: date, target: NutritionTarget | None) -> DailySummary:
    """Jour sans écriture : résumé non enregistré, avec les objectifs en vigueur ce jour-là."""
    if target is None:
        return DailySummary(date=day)
    return DailySummary(
        date=day,
        base_kcal=target.base_kcal,
        target_kcal=target.base_kcal,
        target_protein_g=target.protein_g,
        target_carbs_g=target.carbs_g,
        target_fat_g=target.fat_g,
        target_fiber_g=target.fiber_g,
        target_salt_max_g=target.salt_max_g,
        target_water_ml=target.water_ml,
    )


def day_view(*, user: Any, day: date) -> DailySummary:
    summary = DailySummary.objects.filter(user=user, date=day).first()
    return summary or empty_day(day=day, target=target_on(user=user, day=day))


def targets_between(*, user: Any, start: date, end: date) -> list[NutritionTarget]:
    """Objectifs applicables sur la période (le dernier avant `start` inclus), du plus ancien au plus récent."""
    before = NutritionTarget.objects.filter(user=user, valid_from__lte=start).order_by("-valid_from")[:1]
    during = NutritionTarget.objects.filter(user=user, valid_from__gt=start, valid_from__lte=end)
    return sorted([*before, *during], key=lambda t: t.valid_from)


def target_for_day(targets: list[NutritionTarget], day: date) -> NutritionTarget | None:
    applicable = [t for t in targets if t.valid_from <= day]
    return applicable[-1] if applicable else None


def day_views_between(*, user: Any, start: date, end: date) -> dict[date, DailySummary]:
    """Résumés de chaque jour de la période en 3 requêtes, jours vides compris."""
    rows = summaries_between(user=user, start=start, end=end)
    targets = targets_between(user=user, start=start, end=end)
    return {d: rows.get(d) or empty_day(day=d, target=target_for_day(targets, d)) for d in days(start, end)}


def days(start: date, end: date) -> list[date]:
    return [start + timedelta(days=i) for i in range((end - start).days + 1)]


def search_foods(*, q: str, limit: int) -> list[Food]:
    term = search.normalize(q)
    return list(
        Food.objects.filter(status=ContentStatus.PUBLISHED)
        .annotate(similarity=TrigramWordSimilarity(term, "search_text"))
        .filter(similarity__gte=FOOD_SEARCH_THRESHOLD)
        .order_by("-similarity", "id")[:limit]
    )


def _dishes_base(user: Any) -> QuerySet[Dish]:
    return (
        Dish.objects.filter(status=ContentStatus.PUBLISHED)
        .select_related("image")
        .annotate(is_favorite=Exists(FavoriteDish.objects.filter(user=user, dish=OuterRef("pk"))))
    )


def dishes_for(*, user: Any, q: str | None, country: str | None, scope: str) -> QuerySet[Dish]:
    queryset = _dishes_base(user)
    if scope == "favorites":
        queryset = queryset.filter(is_favorite=True)
    elif scope == "recent":
        queryset = queryset.filter(pk__in=projection.recent_dish_ids(user, 50))
    if country:
        queryset = queryset.filter(country=country.upper())
    if q:
        queryset = queryset.filter(search_text__icontains=search.normalize(q))
    return queryset


def dish_detail(*, user: Any, dish_id: Any) -> Dish | None:
    return (
        _dishes_base(user)
        .prefetch_related(Prefetch("components", queryset=DishComponent.objects.select_related("food")))
        .filter(pk=dish_id)
        .first()
    )
