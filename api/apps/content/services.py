"""
Écritures de content : nutriments des recettes, favoris, consultations, prévention et bilan hebdomadaire.
Fournit aussi à `meals` la composition d'une recette (repas `source = recipe | program`).
"""

from __future__ import annotations

from datetime import date, timedelta
from decimal import Decimal
from typing import Any

from django.db import IntegrityError, transaction
from django.utils import timezone

from apps.billing.services import entitlement_for
from apps.content import prevention
from apps.content.models import (
    ContentView,
    FavoritePlant,
    FavoriteRecipe,
    Plant,
    PreventionTip,
    Recipe,
    UserTip,
    WeeklyReport,
)
from apps.core.errors import NotFound
from apps.core.i18n import resolve
from apps.core.localtime import local_today
from apps.core.models import ContentStatus
from apps.gamification import services as gamification
from apps.meals.providers import RecipeComposition
from apps.nutrition import calculations
from apps.nutrition.constants import nutrition_constants
from apps.nutrition.models import DailySummary

FULL_CATALOG = "full_catalog"


# ───────────────────────── Recettes ─────────────────────────


@transaction.atomic
def refresh_recipe_nutrients(*, recipe: Recipe) -> Recipe:
    parts = [
        calculations.scale_nutrients({k: getattr(i.food, k) for k in calculations.NUTRIENT_KEYS}, i.grams)
        for i in recipe.ingredients.select_related("food")
        if i.food is not None and i.grams
    ]
    total = calculations.sum_nutrients(parts)
    servings = max(recipe.servings, 1)
    recipe.nutrients_per_serving = {key: value / servings for key, value in total.items()}
    recipe.save(update_fields=["nutrients_per_serving", "updated_at"])
    return recipe


def _published_recipe(recipe_id: Any) -> Recipe:
    recipe = Recipe.objects.filter(pk=recipe_id, status=ContentStatus.PUBLISHED).first()
    if recipe is None:
        raise NotFound()
    return recipe


def _published_plant(plant_id: Any) -> Plant:
    plant = Plant.objects.filter(pk=plant_id, status=ContentStatus.PUBLISHED).first()
    if plant is None:
        raise NotFound()
    return plant


def favorite_recipe(*, user: Any, recipe_id: Any, favorite: bool) -> None:
    recipe = _published_recipe(recipe_id)
    if favorite:
        FavoriteRecipe.objects.get_or_create(user=user, recipe=recipe)
    else:
        FavoriteRecipe.objects.filter(user=user, recipe=recipe).delete()


def favorite_plant(*, user: Any, plant_id: Any, favorite: bool) -> None:
    plant = _published_plant(plant_id)
    if favorite:
        FavoritePlant.objects.get_or_create(user=user, plant=plant)
    else:
        FavoritePlant.objects.filter(user=user, plant=plant).delete()


@transaction.atomic
def record_view(*, user: Any, content_type: str, object_id: Any) -> None:
    """Première consultation d'une recette ou d'une plante : compteur des badges « découverte »."""
    try:
        with transaction.atomic():
            ContentView.objects.create(user=user, content_type=content_type, object_id=object_id)
    except IntegrityError:
        return
    gamification.bump(user=user, metric="contents_viewed")


def recipe_composition(user: Any, recipe_id: Any) -> RecipeComposition | None:
    """Fournisseur enregistré auprès de meals : composition d'UNE portion, droits Plus vérifiés."""
    recipe = (
        Recipe.objects.filter(pk=recipe_id, status=ContentStatus.PUBLISHED).prefetch_related("ingredients__food").first()
    )
    if recipe is None:
        return None
    if not recipe.is_free and not entitlement_for(user).allows(FULL_CATALOG):
        return None
    servings = Decimal(max(recipe.servings, 1))
    items = [
        (i.food, (i.grams / servings).quantize(Decimal("0.1")))
        for i in recipe.ingredients.all()
        if i.food is not None and i.grams
    ]
    return RecipeComposition(recipe_id=recipe.pk, title=resolve(recipe.name), items=items)


# ───────────────────────── Prévention ─────────────────────────


def _day_values(user: Any, start: date, end: date) -> list[prevention.DayValues]:
    c = nutrition_constants()
    rows = DailySummary.objects.filter(user=user, date__gte=start, date__lte=end)
    return [
        prevention.DayValues(
            day=row.date,
            meals_count=row.meals_count,
            values={
                "consumed_kcal": row.consumed_kcal,
                "salt_g": float(row.salt_g),
                "sugars_g": float(row.sugars_g),
                "fiber_g": float(row.fiber_g),
                "protein_g": float(row.protein_g),
                "fat_g": float(row.fat_g),
                "water_ml": row.water_ml,
                "steps": row.steps,
                "active_minutes": row.active_minutes,
                "on_target": calculations.kcal_within_target(
                    consumed=row.consumed_kcal, target=row.target_kcal, c=c
                ),
            },
        )
        for row in rows
    ]


@transaction.atomic
def evaluate_prevention(*, user: Any, today: date | None = None) -> list[UserTip]:
    """Idempotent pour un jour donné : déclenche au plus une fois chaque conseil par jour."""
    today = today or local_today(user)
    days = _day_values(user, today - timedelta(days=prevention.WINDOW_DAYS), today - timedelta(days=1))
    if not prevention.has_enough_data(days, today=today):
        return []
    triggered = []
    for tip in PreventionTip.objects.filter(status=ContentStatus.PUBLISHED):
        if prevention.trigger_matches(tip.trigger, days, today=today):
            user_tip, _created = UserTip.objects.get_or_create(
                user=user, tip=tip, triggered_on=today, defaults={"data": dict(tip.trigger)}
            )
            triggered.append(user_tip)
    return triggered


@transaction.atomic
def generate_weekly_report(*, user: Any, week_start: date) -> WeeklyReport:
    days = _day_values(user, week_start, week_start + timedelta(days=6))
    summary = DailySummary.objects.filter(user=user, date__lte=week_start + timedelta(days=6)).order_by("-date").first()
    targets = {"salt_max_g": float(summary.target_salt_max_g)} if summary else {}
    report, _created = WeeklyReport.objects.update_or_create(
        user=user, week_start=week_start, defaults={"data": prevention.weekly_report(days, targets=targets)}
    )
    return report


@transaction.atomic
def update_user_tip(*, user: Any, tip_id: Any, read: bool | None, dismissed: bool | None) -> None:
    tip = UserTip.objects.select_for_update().filter(pk=tip_id, user=user).first()
    if tip is None:
        raise NotFound()
    now = timezone.now()
    if read is not None:
        tip.read_at = now if read else None
    if dismissed is not None:
        tip.dismissed_at = now if dismissed else None
    tip.save(update_fields=["read_at", "dismissed_at", "updated_at"])


def has_enough_data(*, user: Any, today: date) -> bool:
    days = _day_values(user, today - timedelta(days=prevention.WINDOW_DAYS), today - timedelta(days=1))
    return prevention.has_enough_data(days, today=today)
