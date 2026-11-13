"""
Écritures nutritionnelles :
- objectifs (à chaque nouveau poids retenu ou modification du profil) ;
- projection `DailySummary` (`recompute_day`, appelée dans la transaction de chaque écriture) ;
- eau, favoris, catalogue (texte de recherche, nutriments des plats) ;
- rapprochement d'un libellé d'ingrédient avec `Food` (trigram + unaccent).
"""

from __future__ import annotations

from dataclasses import asdict
from datetime import date
from decimal import Decimal
from typing import Any, Final

from django.contrib.postgres.search import TrigramWordSimilarity
from django.db import transaction
from django.db.models import Sum

from apps.core import events
from apps.core.errors import NotFound, ValidationFailed
from apps.core.localtime import local_today
from apps.core.models import ContentStatus
from apps.nutrition import calculations, projection, search, selectors
from apps.nutrition.constants import nutrition_constants
from apps.nutrition.models import DailySummary, Dish, FavoriteDish, Food, NutritionTarget, WaterEntry

MATCH_THRESHOLD: Final = 0.45
# Un plat du pays de l'utilisateur l'emporte s'il est presque aussi proche que le meilleur résultat.
LOCAL_PREFERENCE_MARGIN: Final = 0.05


# ───────────────────────── Objectifs ─────────────────────────


@transaction.atomic
def recompute_targets(*, user: Any, valid_from: date | None = None) -> NutritionTarget:
    profile = user.profile
    day = valid_from or local_today(user)
    constants = nutrition_constants()
    body = calculations.BodyInput(
        sex=profile.sex,
        birth_date=profile.birth_date,
        height_cm=float(profile.height_cm),
        weight_kg=float(profile.current_weight_kg),
        target_weight_kg=float(profile.target_weight_kg),
        goals=list(profile.goals),
    )
    result = calculations.compute_targets(body, today=day, c=constants)
    computed_from = {
        "sex": body.sex,
        "age": calculations.age_on(body.birth_date, day),
        "height_cm": body.height_cm,
        "weight_kg": body.weight_kg,
        "goals": list(body.goals),
        "primary_goal": result.primary_goal,
        "constants": asdict(constants),
    }
    target, _ = NutritionTarget.objects.update_or_create(
        user=user,
        valid_from=day,
        defaults={
            "bmr_kcal": result.bmr_kcal,
            "tdee_kcal": result.tdee_kcal,
            "base_kcal": result.base_kcal,
            "protein_g": result.protein_g,
            "carbs_g": result.carbs_g,
            "fat_g": result.fat_g,
            "fiber_g": result.fiber_g,
            "salt_max_g": result.salt_max_g,
            "water_ml": result.water_ml,
            "warning": result.warning or "",
            "computed_from": computed_from,
        },
    )
    if DailySummary.objects.filter(user=user, date=day).exists():
        recompute_day(user=user, day=day)
    return target


# ───────────────────────── Projection du jour ─────────────────────────


def _water_ml(user: Any, day: date) -> int:
    total = WaterEntry.objects.filter(user=user, date=day).aggregate(total=Sum("amount_ml"))["total"] or 0
    return max(int(total), 0)


@transaction.atomic
def recompute_day(*, user: Any, day: date) -> DailySummary:
    """Recalcule entièrement et de façon idempotente le résumé d'un jour à partir des données brutes."""
    constants = nutrition_constants()
    target = selectors.target_on(user=user, day=day)
    values = projection.collect(user, day)
    values["water_ml"] = _water_ml(user, day)

    base_kcal = target.base_kcal if target else 0
    tdee_kcal = target.tdee_kcal if target else 0
    burned = values.get("burned_kcal")
    active_minutes = int(values.get("active_minutes", 0))
    adjust = bool(getattr(user.profile, "activity_adjustment", True))
    meals_count = int(values.get("meals_count", 0))

    defaults: dict[str, Any] = {
        "base_kcal": base_kcal,
        "target_kcal": calculations.activity_adjusted_kcal(
            base_kcal=base_kcal, tdee_kcal=tdee_kcal, burned_kcal=burned, enabled=adjust, c=constants
        ),
        "target_protein_g": target.protein_g if target else 0,
        "target_carbs_g": target.carbs_g if target else 0,
        "target_fat_g": target.fat_g if target else 0,
        "target_fiber_g": target.fiber_g if target else 0,
        "target_salt_max_g": target.salt_max_g if target else Decimal(0),
        "target_water_ml": calculations.adjusted_water_ml(
            base_water_ml=target.water_ml, active_minutes=active_minutes, c=constants
        )
        if target
        else 0,
        "consumed_kcal": calculations.round_int(float(values.get("consumed_kcal", 0))),
        "protein_g": calculations.round_1(float(values.get("protein_g", 0))),
        "carbs_g": calculations.round_1(float(values.get("carbs_g", 0))),
        "fat_g": calculations.round_1(float(values.get("fat_g", 0))),
        "fiber_g": calculations.round_1(float(values.get("fiber_g", 0))),
        "salt_g": round(float(values.get("salt_g", 0)), 2),
        "sugars_g": calculations.round_1(float(values.get("sugars_g", 0))),
        "water_ml": values["water_ml"],
        "burned_kcal": burned,
        "active_kcal": int(values.get("active_kcal", 0)),
        "steps": int(values.get("steps", 0)),
        "distance_m": int(values.get("distance_m", 0)),
        "active_minutes": active_minutes,
        "workouts_completed": int(values.get("workouts_completed", 0)),
        "weight_logged": bool(values.get("weight_logged", False)),
        "meals_count": meals_count,
        "is_complete": meals_count >= calculations.MEALS_FOR_COMPLETE_DAY,
    }
    summary, _ = DailySummary.objects.update_or_create(user=user, date=day, defaults=defaults)
    events.publish(events.DayRecomputed(user_id=user.pk, day=day))
    return summary


def resolve_day(*, user: Any, day: date | None) -> date:
    """Journée locale demandée (défaut : aujourd'hui). Une date future est refusée."""
    today = local_today(user)
    if day is None:
        return today
    if day > today:
        raise ValidationFailed(errors={"date": [{"code": "future_date", "message": "date in the future"}]})
    return day


# ───────────────────────── Eau ─────────────────────────


@transaction.atomic
def add_water(*, user: Any, amount_ml: int, day: date | None = None) -> DailySummary:
    if amount_ml == 0:
        raise ValidationFailed(errors={"amount_ml": [{"code": "invalid", "message": "must not be 0"}]})
    day = resolve_day(user=user, day=day)
    if amount_ml < 0 and _water_ml(user, day) + amount_ml < 0:
        raise ValidationFailed(errors={"amount_ml": [{"code": "below_zero", "message": "cannot go below 0"}]})
    entry = WaterEntry.objects.create(user=user, date=day, amount_ml=amount_ml)
    summary = recompute_day(user=user, day=day)
    events.publish(events.WaterLogged(user_id=user.pk, entry_id=entry.pk, day=day))
    return summary


# ───────────────────────── Favoris ─────────────────────────


def _published_dish(dish_id: Any) -> Dish:
    dish = Dish.objects.filter(pk=dish_id, status=ContentStatus.PUBLISHED).first()
    if dish is None:
        raise NotFound()
    return dish


def favorite_dish(*, user: Any, dish_id: Any) -> None:
    FavoriteDish.objects.get_or_create(user=user, dish=_published_dish(dish_id))


def unfavorite_dish(*, user: Any, dish_id: Any) -> None:
    FavoriteDish.objects.filter(user=user, dish=_published_dish(dish_id)).delete()


# ───────────────────────── Catalogue ─────────────────────────


@transaction.atomic
def save_food(*, food: Food) -> Food:
    food.search_text = search.search_text(food.name, food.aliases)
    food.save()
    return food


@transaction.atomic
def refresh_dish(*, dish: Dish) -> Dish:
    """Texte de recherche et nutriments pour 100 g, recalculés depuis la composition."""
    components = list(dish.components.select_related("food"))
    parts = [
        calculations.scale_nutrients({k: getattr(c.food, k) for k in calculations.NUTRIENT_KEYS}, c.grams)
        for c in components
    ]
    total_grams = float(sum((c.grams for c in components), Decimal(0)))
    dish.nutrients_per_100g = calculations.per_100g(calculations.sum_nutrients(parts), total_grams)
    dish.search_text = search.search_text(dish.name, dish.aliases)
    dish.save(update_fields=["nutrients_per_100g", "search_text", "updated_at"])
    return dish


def match_food(*, label: str, threshold: float = MATCH_THRESHOLD) -> Food | None:
    """Aliment publié le plus proche d'un libellé (noms et autres noms, sans accents), au-dessus du seuil."""
    term = search.normalize(label)
    if not term:
        return None
    return (
        Food.objects.filter(status=ContentStatus.PUBLISHED)
        .annotate(similarity=TrigramWordSimilarity(term, "search_text"))
        .filter(similarity__gte=threshold)
        .order_by("-similarity", "id")
        .first()
    )


def match_dish(*, label: str, country: str | None, threshold: float = MATCH_THRESHOLD) -> Dish | None:
    term = search.normalize(label)
    if not term:
        return None
    queryset = (
        Dish.objects.filter(status=ContentStatus.PUBLISHED)
        .annotate(similarity=TrigramWordSimilarity(term, "search_text"))
        .filter(similarity__gte=threshold)
    )
    rows = list(queryset.order_by("-similarity", "id")[:5])
    if not rows:
        return None
    if country:
        local = [d for d in rows if d.country == country and d.similarity >= rows[0].similarity - LOCAL_PREFERENCE_MARGIN]  # type: ignore[attr-defined]
        if local:
            return local[0]
    return rows[0]
