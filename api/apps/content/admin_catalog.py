"""
Registre des types de contenus gérés dans l'admin (`/admin/content/{type}`).

Chaque type déclare : son modèle, son champ titre, ses champs traduits (couverture des langues), la validation de
`data`, la lecture (`to_data`), l'écriture (y compris les structures imbriquées) et les valeurs calculées.
Les types sans workflow éditorial (niveaux, barème, villes) sont considérés comme publiés.
"""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass
from decimal import Decimal
from typing import Any

from django.db import models
from rest_framework import serializers

from apps.accounts.models import City, LegalDocument
from apps.activity.models import Exercise, Workout, WorkoutStep
from apps.content.models import FaqItem, Plant, PreventionTip, Recipe, RecipeIngredient, RecipeStep
from apps.content.services import refresh_recipe_nutrients
from apps.core.i18n import LOCALES, validate_i18n_text
from apps.gamification.models import Badge, Level, PointRule
from apps.nutrition import services as nutrition
from apps.nutrition.models import Dish, DishComponent, Food
from apps.programs.models import Challenge, Program, ProgramDay, ProgramTask, Rule

I18N = {"validators": [validate_i18n_text]}


def i18n(required: bool = True) -> serializers.JSONField:
    return serializers.JSONField(required=required, **I18N)


@dataclass(frozen=True)
class ContentType:
    name: str
    model: type[models.Model]
    title_field: str
    i18n_fields: tuple[str, ...]
    serializer: type[serializers.Serializer[Any]]
    flat_fields: tuple[str, ...]
    write_nested: Callable[[Any, dict[str, Any]], None] = lambda obj, data: None
    read_nested: Callable[[Any], dict[str, Any]] = lambda obj: {}
    computed: Callable[[Any], dict[str, Any]] = lambda obj: {}
    has_status: bool = True
    prepare: Callable[[Any, dict[str, Any]], None] = lambda obj, data: None
    after_save: Callable[[Any], None] = lambda obj: None

    def status_of(self, obj: Any) -> str:
        if isinstance(obj, LegalDocument):
            return "published" if obj.published_at else "draft"
        return str(obj.status) if self.has_status else "published"

    def to_data(self, obj: Any) -> dict[str, Any]:
        data = {name: _plain(getattr(obj, name)) for name in self.flat_fields}
        data.update(self.read_nested(obj))
        return data

    def write(self, obj: Any, data: dict[str, Any]) -> Any:
        for name in self.flat_fields:
            if name in data:
                setattr(obj, name, data[name])
        self.prepare(obj, data)
        obj.save()
        self.write_nested(obj, data)
        self.after_save(obj)
        return obj

    def missing_locales(self, obj: Any) -> list[str]:
        title = getattr(obj, self.title_field, None)
        if not isinstance(title, dict):
            return []
        return [locale for locale in LOCALES if not title.get(locale)]


def _plain(value: Any) -> Any:
    if isinstance(value, Decimal):
        return float(value)
    return value


# ───────────────────────── Sérialiseurs ─────────────────────────


class FoodData(serializers.Serializer[Any]):
    name = i18n()
    aliases = serializers.ListField(child=serializers.CharField(max_length=80), required=False, default=list)
    category = serializers.CharField(max_length=12)
    kcal = serializers.DecimalField(max_digits=6, decimal_places=2, min_value=0, max_value=900)
    protein_g = serializers.DecimalField(max_digits=6, decimal_places=2, min_value=0, max_value=100)
    carbs_g = serializers.DecimalField(max_digits=6, decimal_places=2, min_value=0, max_value=100)
    sugars_g = serializers.DecimalField(max_digits=6, decimal_places=2, min_value=0, max_value=100, required=False)
    fat_g = serializers.DecimalField(max_digits=6, decimal_places=2, min_value=0, max_value=100)
    saturated_fat_g = serializers.DecimalField(
        max_digits=6, decimal_places=2, min_value=0, max_value=100, required=False
    )
    fiber_g = serializers.DecimalField(max_digits=6, decimal_places=2, min_value=0, max_value=100, required=False)
    salt_g = serializers.DecimalField(max_digits=6, decimal_places=2, min_value=0, max_value=100, required=False)
    default_portion_g = serializers.DecimalField(max_digits=6, decimal_places=1, required=False, allow_null=True)
    source = serializers.CharField(max_length=40, required=False, allow_blank=True)


class ItemData(serializers.Serializer[Any]):
    food_id = serializers.UUIDField()
    grams = serializers.DecimalField(max_digits=6, decimal_places=1, min_value=Decimal("0.1"))


class DishData(serializers.Serializer[Any]):
    name = i18n()
    aliases = serializers.ListField(child=serializers.CharField(max_length=80), required=False, default=list)
    country = serializers.CharField(max_length=2)
    standard_portion_g = serializers.DecimalField(max_digits=6, decimal_places=1)
    components = ItemData(many=True)


class RecipeIngredientData(serializers.Serializer[Any]):
    food_id = serializers.UUIDField()
    grams = serializers.DecimalField(max_digits=6, decimal_places=1)
    display = i18n(required=False)


class RecipeStepData(serializers.Serializer[Any]):
    text = i18n()


class RecipeData(serializers.Serializer[Any]):
    name = i18n()
    description = i18n(required=False)
    country = serializers.CharField(max_length=2, required=False, allow_blank=True)
    prep_minutes = serializers.IntegerField(min_value=0, required=False)
    cook_minutes = serializers.IntegerField(min_value=0, required=False)
    difficulty = serializers.ChoiceField(choices=["easy", "medium", "hard"], required=False)
    servings = serializers.IntegerField(min_value=1)
    tags = serializers.ListField(child=serializers.CharField(max_length=30), required=False)
    goals = serializers.ListField(child=serializers.CharField(max_length=24), required=False)
    is_free = serializers.BooleanField(required=False)
    ingredients = RecipeIngredientData(many=True)
    steps = RecipeStepData(many=True)


class PlantData(serializers.Serializer[Any]):
    common_name = i18n()
    scientific_name = serializers.CharField(max_length=120)
    tags = serializers.ListField(child=serializers.CharField(max_length=30), required=False)
    traditional_use = i18n()
    nutritional_benefits = i18n()
    precautions = i18n()
    contraindications = serializers.ListField(child=serializers.CharField(max_length=40), required=False)
    related_recipe_ids = serializers.ListField(child=serializers.UUIDField(), required=False)


class ExerciseData(serializers.Serializer[Any]):
    name = i18n()
    instructions = i18n()
    muscles = serializers.ListField(child=serializers.CharField(max_length=30), required=False)
    level = serializers.ChoiceField(choices=["beginner", "intermediate", "advanced"])
    equipment = serializers.ListField(child=serializers.CharField(max_length=30), required=False)
    met = serializers.DecimalField(max_digits=4, decimal_places=1, min_value=1, max_value=20)
    is_free = serializers.BooleanField(required=False)


class WorkoutStepData(serializers.Serializer[Any]):
    exercise_id = serializers.UUIDField()
    mode = serializers.ChoiceField(choices=["time", "reps"])
    duration_s = serializers.IntegerField(min_value=1, required=False, allow_null=True)
    reps = serializers.IntegerField(min_value=1, required=False, allow_null=True)
    rest_s = serializers.IntegerField(min_value=0)


class WorkoutData(serializers.Serializer[Any]):
    name = i18n()
    description = i18n(required=False)
    goal = serializers.ChoiceField(choices=["cardio", "strength", "mobility"])
    level = serializers.ChoiceField(choices=["beginner", "intermediate", "advanced"])
    is_free = serializers.BooleanField(required=False)
    steps = WorkoutStepData(many=True, min_length=1)


class RuleData(serializers.Serializer[Any]):
    metric = serializers.ChoiceField(
        choices=[
            "water_ml",
            "steps",
            "active_minutes",
            "meals_count",
            "protein_g",
            "kcal_within_target",
            "workout_completed",
            "weight_logged",
            "manual",
        ]
    )
    operator = serializers.ChoiceField(choices=["gte", "lte"])
    threshold = serializers.DecimalField(max_digits=8, decimal_places=2)


class ProgramTaskData(serializers.Serializer[Any]):
    label = i18n()
    rule = RuleData(required=False, allow_null=True)


class ProgramDayData(serializers.Serializer[Any]):
    day_index = serializers.IntegerField(min_value=1)
    tip = i18n(required=False)
    workout_id = serializers.UUIDField(required=False, allow_null=True)
    recipe_ids = serializers.ListField(child=serializers.UUIDField(), required=False, default=list)
    tasks = ProgramTaskData(many=True, required=False, default=list)


class ProgramData(serializers.Serializer[Any]):
    name = i18n()
    description = i18n(required=False)
    goal = serializers.CharField(max_length=24)
    weeks = serializers.IntegerField(min_value=1, max_value=52)
    points = serializers.IntegerField(min_value=0, required=False)
    badge_id = serializers.UUIDField(required=False, allow_null=True)
    days = ProgramDayData(many=True)


class ChallengeData(serializers.Serializer[Any]):
    name = i18n()
    description = i18n(required=False)
    duration_days = serializers.IntegerField(min_value=7, max_value=30)
    rule = RuleData()
    success_threshold = serializers.DecimalField(
        max_digits=3, decimal_places=2, min_value=Decimal("0.5"), max_value=1, required=False
    )
    points_per_day = serializers.IntegerField(min_value=0, required=False)
    points_completion = serializers.IntegerField(min_value=0, required=False)
    badge_id = serializers.UUIDField(required=False, allow_null=True)


class BadgeData(serializers.Serializer[Any]):
    code = serializers.RegexField(r"^[a-z0-9_]+$")
    family = serializers.ChoiceField(
        choices=["streak", "nutrition", "hydration", "activity", "challenge", "program", "discovery", "referral"]
    )
    name = i18n()
    description = i18n(required=False)
    condition = serializers.DictField()
    bonus_points = serializers.IntegerField(min_value=0, required=False)


class LevelData(serializers.Serializer[Any]):
    rank = serializers.IntegerField(min_value=1)
    name = i18n()
    min_points = serializers.IntegerField(min_value=0)


class PointRuleData(serializers.Serializer[Any]):
    action = serializers.CharField(max_length=30)
    points = serializers.IntegerField(min_value=0)
    cap = serializers.IntegerField(min_value=1, required=False, allow_null=True)
    cap_period = serializers.ChoiceField(choices=["day", "week", "none"], required=False)


class TipData(serializers.Serializer[Any]):
    code = serializers.CharField(max_length=40)
    topic = serializers.ChoiceField(choices=["water", "salt", "sugar", "fiber", "activity", "protein"])
    title = i18n()
    body = i18n()
    trigger = serializers.DictField()
    tier = serializers.ChoiceField(choices=["free", "plus"])
    related_recipe_ids = serializers.ListField(child=serializers.UUIDField(), required=False)
    related_plant_ids = serializers.ListField(child=serializers.UUIDField(), required=False)


class FaqData(serializers.Serializer[Any]):
    category = serializers.CharField(max_length=80)
    question = i18n()
    answer = i18n()
    order = serializers.IntegerField(min_value=0, required=False)
    audience = serializers.ChoiceField(choices=["app", "web", "both"], required=False)


class LegalData(serializers.Serializer[Any]):
    kind = serializers.ChoiceField(choices=["terms", "privacy", "cookies", "legal_notice"])
    body = i18n()
    requires_reaccept = serializers.BooleanField(required=False)


class CityData(serializers.Serializer[Any]):
    name = i18n()
    country = serializers.CharField(min_length=2, max_length=2)
    timezone = serializers.CharField(max_length=64)
    is_suggested = serializers.BooleanField(required=False)


# ───────────────────────── Structures imbriquées ─────────────────────────


def _dish_write(dish: Dish, data: dict[str, Any]) -> None:
    if "components" not in data:
        return
    dish.components.all().delete()
    foods = {str(f.pk): f for f in Food.objects.filter(pk__in=[c["food_id"] for c in data["components"]])}
    DishComponent.objects.bulk_create(
        DishComponent(dish=dish, food=foods[str(c["food_id"])], grams=c["grams"])
        for c in data["components"]
        if str(c["food_id"]) in foods
    )


def _recipe_write(recipe: Recipe, data: dict[str, Any]) -> None:
    if "ingredients" in data:
        recipe.ingredients.all().delete()
        foods = {str(f.pk): f for f in Food.objects.filter(pk__in=[i["food_id"] for i in data["ingredients"]])}
        RecipeIngredient.objects.bulk_create(
            RecipeIngredient(
                recipe=recipe,
                food=foods.get(str(i["food_id"])),
                grams=i["grams"],
                display=i.get("display") or {},
                order=index,
            )
            for index, i in enumerate(data["ingredients"], start=1)
        )
    if "steps" in data:
        recipe.steps.all().delete()
        RecipeStep.objects.bulk_create(
            RecipeStep(recipe=recipe, order=index, text=step["text"])
            for index, step in enumerate(data["steps"], start=1)
        )
    refresh_recipe_nutrients(recipe=recipe)


def _workout_write(workout: Workout, data: dict[str, Any]) -> None:
    if "steps" not in data:
        return
    workout.steps.all().delete()
    exercises = {str(e.pk): e for e in Exercise.objects.filter(pk__in=[s["exercise_id"] for s in data["steps"]])}
    steps = [
        WorkoutStep(
            workout=workout,
            order=index,
            exercise=exercises[str(s["exercise_id"])],
            mode=s["mode"],
            duration_s=s.get("duration_s"),
            reps=s.get("reps"),
            rest_s=s["rest_s"],
        )
        for index, s in enumerate(data["steps"], start=1)
        if str(s["exercise_id"]) in exercises
    ]
    WorkoutStep.objects.bulk_create(steps)
    workout.duration_s = sum((s.duration_s or (s.reps or 0) * 3) + s.rest_s for s in steps)
    workout.save(update_fields=["duration_s", "updated_at"])


def _rule(data: dict[str, Any] | None) -> Rule | None:
    return Rule.objects.create(**data) if data else None


def _program_write(program: Program, data: dict[str, Any]) -> None:
    if "badge_id" in data:
        program.badge_id = data["badge_id"]
        program.save(update_fields=["badge", "updated_at"])
    if "days" not in data:
        return
    program.days.all().delete()
    for day_data in data["days"]:
        day = ProgramDay.objects.create(
            program=program,
            day_index=day_data["day_index"],
            tip=day_data.get("tip") or {},
            workout_id=day_data.get("workout_id"),
        )
        day.suggested_recipes.set(day_data.get("recipe_ids", []))
        for order, task in enumerate(day_data.get("tasks", [])):
            ProgramTask.objects.create(day=day, label=task["label"], rule=_rule(task.get("rule")), order=order)


def _challenge_write(challenge: Challenge, data: dict[str, Any]) -> None:
    changed = []
    if "rule" in data:
        challenge.rule = _rule(data["rule"])  # type: ignore[assignment]
        changed.append("rule")
    if "badge_id" in data:
        challenge.badge_id = data["badge_id"]
        changed.append("badge")
    if changed:
        challenge.save(update_fields=[*changed, "updated_at"])


def _plant_write(plant: Plant, data: dict[str, Any]) -> None:
    if "related_recipe_ids" in data:
        plant.related_recipes.set(data["related_recipe_ids"])


def _tip_write(tip: PreventionTip, data: dict[str, Any]) -> None:
    if "related_recipe_ids" in data:
        tip.related_recipes.set(data["related_recipe_ids"])
    if "related_plant_ids" in data:
        tip.related_plants.set(data["related_plant_ids"])


def _faq_prepare(item: FaqItem, data: dict[str, Any]) -> None:
    if "category" in data:
        item.category = {**(item.category or {}), "fr": data["category"]}


LEGAL_TITLES: dict[str, dict[str, str]] = {
    "terms": {"fr": "Conditions générales d'utilisation", "en": "Terms of use"},
    "privacy": {"fr": "Politique de confidentialité", "en": "Privacy policy"},
    "cookies": {"fr": "Politique relative aux cookies", "en": "Cookie policy"},
    "legal_notice": {"fr": "Mentions légales", "en": "Legal notice"},
}


def _legal_prepare(document: LegalDocument, data: dict[str, Any]) -> None:
    """Un texte légal publié ne change jamais : toute modification crée une nouvelle version en brouillon."""
    if document.pk is None or document.published_at is not None:
        latest = LegalDocument.objects.filter(kind=document.kind).order_by("-version").first()
        document.pk = None
        document.id = None  # type: ignore[assignment]
        document._state.adding = True
        document.version = (latest.version if latest else 0) + 1
        document.published_at = None
        document.title = LEGAL_TITLES[document.kind]


def _rule_out(rule: Rule | None) -> dict[str, Any] | None:
    if rule is None:
        return None
    return {"metric": rule.metric, "operator": rule.operator, "threshold": float(rule.threshold), "period": "day"}


REGISTRY: dict[str, ContentType] = {
    "foods": ContentType(
        "foods",
        Food,
        "name",
        ("name",),
        FoodData,
        (
            "name",
            "aliases",
            "category",
            "kcal",
            "protein_g",
            "carbs_g",
            "sugars_g",
            "fat_g",
            "saturated_fat_g",
            "fiber_g",
            "salt_g",
            "default_portion_g",
            "source",
        ),
        after_save=lambda food: nutrition.save_food(food=food),
    ),
    "dishes": ContentType(
        "dishes",
        Dish,
        "name",
        ("name",),
        DishData,
        ("name", "aliases", "country", "standard_portion_g"),
        write_nested=_dish_write,
        read_nested=lambda d: {
            "components": [{"food_id": c.food_id, "grams": float(c.grams)} for c in d.components.all()]
        },
        computed=lambda d: {"nutrients_per_100g": d.nutrients_per_100g},
        after_save=lambda dish: nutrition.refresh_dish(dish=dish),
    ),
    "recipes": ContentType(
        "recipes",
        Recipe,
        "name",
        ("name", "description"),
        RecipeData,
        (
            "name",
            "description",
            "country",
            "prep_minutes",
            "cook_minutes",
            "difficulty",
            "servings",
            "tags",
            "goals",
            "is_free",
        ),
        write_nested=_recipe_write,
        read_nested=lambda r: {
            "ingredients": [
                {"food_id": i.food_id, "grams": float(i.grams or 0), "display": i.display} for i in r.ingredients.all()
            ],
            "steps": [{"text": s.text} for s in r.steps.all()],
        },
        computed=lambda r: {"nutrients_per_serving": r.nutrients_per_serving},
    ),
    "plants": ContentType(
        "plants",
        Plant,
        "common_name",
        ("common_name", "traditional_use", "nutritional_benefits", "precautions"),
        PlantData,
        (
            "common_name",
            "scientific_name",
            "tags",
            "traditional_use",
            "nutritional_benefits",
            "precautions",
            "contraindications",
        ),
        write_nested=_plant_write,
        read_nested=lambda p: {"related_recipe_ids": [r.pk for r in p.related_recipes.all()]},
    ),
    "exercises": ContentType(
        "exercises",
        Exercise,
        "name",
        ("name", "instructions"),
        ExerciseData,
        ("name", "instructions", "muscles", "level", "equipment", "met", "is_free"),
    ),
    "workouts": ContentType(
        "workouts",
        Workout,
        "name",
        ("name", "description"),
        WorkoutData,
        ("name", "description", "goal", "level", "is_free"),
        write_nested=_workout_write,
        read_nested=lambda w: {
            "steps": [
                {
                    "exercise_id": s.exercise_id,
                    "mode": s.mode,
                    "duration_s": s.duration_s,
                    "reps": s.reps,
                    "rest_s": s.rest_s,
                }
                for s in w.steps.all()
            ]
        },
        computed=lambda w: {"duration_s": w.duration_s},
    ),
    "programs": ContentType(
        "programs",
        Program,
        "name",
        ("name", "description"),
        ProgramData,
        ("name", "description", "goal", "weeks", "points"),
        write_nested=_program_write,
        read_nested=lambda p: {
            "badge_id": p.badge_id,
            "days": [
                {
                    "day_index": d.day_index,
                    "tip": d.tip,
                    "workout_id": d.workout_id,
                    "recipe_ids": [r.pk for r in d.suggested_recipes.all()],
                    "tasks": [{"label": t.label, "rule": _rule_out(t.rule)} for t in d.tasks.all()],
                }
                for d in p.days.all()
            ],
        },
    ),
    "challenges": ContentType(
        "challenges",
        Challenge,
        "name",
        ("name", "description"),
        ChallengeData,
        ("name", "description", "duration_days", "success_threshold", "points_per_day", "points_completion"),
        write_nested=_challenge_write,
        read_nested=lambda c: {"rule": _rule_out(c.rule), "badge_id": c.badge_id},
    ),
    "badges": ContentType(
        "badges",
        Badge,
        "name",
        ("name", "description"),
        BadgeData,
        ("code", "family", "name", "description", "condition", "bonus_points"),
    ),
    "levels": ContentType(
        "levels", Level, "name", ("name",), LevelData, ("rank", "name", "min_points"), has_status=False
    ),
    "point-rules": ContentType(
        "point-rules",
        PointRule,
        "action",
        (),
        PointRuleData,
        ("action", "points", "cap", "cap_period"),
        has_status=False,
    ),
    "prevention-tips": ContentType(
        "prevention-tips",
        PreventionTip,
        "title",
        ("title", "body"),
        TipData,
        ("code", "topic", "title", "body", "trigger", "tier"),
        write_nested=_tip_write,
        read_nested=lambda t: {
            "related_recipe_ids": [r.pk for r in t.related_recipes.all()],
            "related_plant_ids": [p.pk for p in t.related_plants.all()],
        },
    ),
    "faq": ContentType(
        "faq",
        FaqItem,
        "question",
        ("question", "answer"),
        FaqData,
        ("question", "answer", "order", "audience"),
        prepare=_faq_prepare,
        read_nested=lambda f: {"category": f.category.get("fr", "")},
    ),
    "legal": ContentType(
        "legal",
        LegalDocument,
        "title",
        ("body",),
        LegalData,
        ("kind", "body", "requires_reaccept"),
        has_status=False,
        prepare=_legal_prepare,
    ),
    "cities": ContentType(
        "cities", City, "name", ("name",), CityData, ("name", "country", "timezone", "is_suggested"), has_status=False
    ),
}


def get(type_name: str) -> ContentType:
    content_type = REGISTRY.get(type_name)
    if content_type is None:
        raise KeyError(type_name)
    return content_type
