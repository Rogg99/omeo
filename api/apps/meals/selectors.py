"""Lectures de meals, filtrées par utilisateur (un objet d'un autre utilisateur est introuvable)."""

from __future__ import annotations

from collections.abc import Iterable
from datetime import date
from typing import Any

from django.db.models import Exists, OuterRef, Prefetch, QuerySet

from apps.meals.models import Analysis, AnalysisFeedback, Meal, MealItem
from apps.nutrition.models import Dish, Food


def analysis_for(*, user: Any, analysis_id: Any) -> Analysis | None:
    return (
        Analysis.objects.filter(pk=analysis_id, user=user)
        .select_related("upload", "dish_guess", "dish_guess__image")
        .first()
    )


def dishes_by_id(ids: Iterable[Any]) -> dict[str, Dish]:
    wanted = [i for i in ids if i]
    if not wanted:
        return {}
    return {str(d.pk): d for d in Dish.objects.filter(pk__in=wanted).select_related("image")}


def meals_for(*, user: Any) -> QuerySet[Meal]:
    return (
        Meal.objects.filter(user=user)
        .select_related("photo")
        .prefetch_related(Prefetch("items", queryset=MealItem.objects.order_by("position")))
        .annotate(feedback_given=Exists(AnalysisFeedback.objects.filter(analysis_id=OuterRef("analysis_id"))))
    )


def meals_between(*, user: Any, start: date, end: date) -> QuerySet[Meal]:
    return meals_for(user=user).filter(date__gte=start, date__lte=end)


def meal_for(*, user: Any, meal_id: Any) -> Meal | None:
    return meals_for(user=user).filter(pk=meal_id).first()


def foods_by_id(ids: Iterable[Any]) -> dict[str, Food]:
    wanted = [i for i in ids if i]
    if not wanted:
        return {}
    return {str(f.pk): f for f in Food.objects.filter(pk__in=wanted)}
