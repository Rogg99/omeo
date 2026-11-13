"""
Écritures de `meals` : téléversements, analyses IA (moteur foodscan), avis, repas.

Règles :
- les nutriments viennent TOUJOURS de `nutrition.Food`, jamais de l'IA ;
- le quota est décompté dans la transaction de création de l'analyse (verrou de ligne) et rendu si elle échoue
  (une photo floue ou sans aliment ne compte pas) ;
- chaque écriture de repas recalcule le jour (`recompute_day`) dans la même transaction ;
- le pays vient toujours de `Profile.country`, jamais d'une position ;
- le commentaire libre d'un avis n'entre jamais dans un prompt.
"""

from __future__ import annotations

import logging
from collections.abc import Sequence
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from decimal import Decimal
from typing import Any, Final

from celery import current_app
from django.conf import settings
from django.db import transaction
from django.db.models import Count, Sum
from django.utils import timezone

from apps.billing import services as billing
from apps.core import events, settings_store, storage
from apps.core.errors import Conflict, NotFound, ValidationFailed
from apps.core.i18n import resolve
from apps.core.localtime import local_date_of, local_now
from apps.core.models import ContentStatus
from apps.core.permissions import require_feature
from apps.foodscan import services as foodscan
from apps.meals import images, providers, rules
from apps.meals.models import (
    Analysis,
    AnalysisFeedback,
    AnalysisKind,
    AnalysisStatus,
    FeedbackReason,
    Meal,
    MealItem,
    MealSource,
    Upload,
    UploadStatus,
)
from apps.nutrition import calculations
from apps.nutrition import services as nutrition
from apps.nutrition.models import DailySummary, Dish, Food

logger = logging.getLogger(__name__)

PENDING_TTL: Final = timedelta(hours=1)
RUN_ANALYSIS_TASK: Final = "apps.meals.tasks.run_analysis"  # routée vers la file « ai »
FEATURE_BY_KIND: Final[dict[str, str]] = {AnalysisKind.PHOTO: "photo_analysis", AnalysisKind.TEXT: "text_analysis"}
NUTRIENT_KEYS: Final = calculations.NUTRIENT_KEYS


# ───────────────────────── Téléversements ─────────────────────────


@transaction.atomic
def create_upload(*, user: Any, kind: str, content_type: str, size: int) -> tuple[Upload, storage.PresignedUpload]:
    if content_type not in storage.ALLOWED_IMAGE_TYPES:
        raise ValidationFailed(errors={"content_type": [{"code": "invalid_choice", "message": content_type}]})
    if not 0 < size <= settings.UPLOAD_MAX_BYTES:
        raise ValidationFailed(errors={"size": [{"code": "out_of_range", "message": "1..8388608"}]})
    key = storage.build_key(prefix=kind, owner_id=user.pk, extension=storage.ALLOWED_IMAGE_TYPES[content_type])
    ticket = storage.presign_upload(key=key, content_type=content_type, size=size)
    upload = Upload.objects.create(
        user=user,
        kind=kind,
        storage_key=key,
        content_type=content_type,
        size=size,
        expires_at=timezone.now() + PENDING_TTL,
    )
    return upload, ticket


def _reject(upload: Upload, reason: str) -> None:
    upload.status = UploadStatus.REJECTED
    upload.rejected_reason = reason
    upload.save(update_fields=["status", "rejected_reason", "updated_at"])
    transaction.on_commit(lambda: storage.delete(key=upload.storage_key))


@transaction.atomic
def consume_upload(*, user: Any, upload_id: Any, kind: str) -> Upload:
    """Valide un téléversement de l'utilisateur et le rend utilisable. 404 s'il appartient à un autre utilisateur."""
    upload = Upload.objects.select_for_update().filter(pk=upload_id, user=user, kind=kind).first()
    if upload is None:
        raise NotFound()
    if upload.status == UploadStatus.READY:
        return upload
    if upload.status == UploadStatus.REJECTED or upload.expires_at <= timezone.now():
        raise ValidationFailed(errors={"upload_id": [{"code": "upload_invalid", "message": "upload rejected"}]})
    head = storage.head(key=upload.storage_key)
    if head is None:
        raise ValidationFailed(errors={"upload_id": [{"code": "upload_missing", "message": "file not uploaded"}]})
    if int(str(head["size"])) > settings.UPLOAD_MAX_BYTES:
        _reject(upload, "too_large")
        raise ValidationFailed(errors={"upload_id": [{"code": "too_large", "message": "max 8 MB"}]})
    raw = storage.read_bytes(key=upload.storage_key)
    try:
        cleaned = images.sanitize(raw)
    except images.InvalidImageError as exc:
        _reject(upload, exc.reason)
        raise ValidationFailed(errors={"upload_id": [{"code": exc.reason, "message": "invalid image"}]}) from None
    storage.put_bytes(key=upload.storage_key, data=cleaned.data, content_type=cleaned.content_type)
    upload.content_type = cleaned.content_type
    upload.size = len(cleaned.data)
    upload.width, upload.height = cleaned.width, cleaned.height
    upload.status = UploadStatus.READY
    upload.save(update_fields=["content_type", "size", "width", "height", "status", "updated_at"])
    return upload


# ───────────────────────── Nutriments ─────────────────────────


def food_values(food: Food) -> dict[str, Decimal]:
    return {key: getattr(food, key) for key in NUTRIENT_KEYS}


def item_payload(
    food: Food, grams: Decimal, *, label: str | None = None, confidence: float | None = None
) -> dict[str, Any]:
    payload: dict[str, Any] = {"food_id": str(food.pk), "label": label or resolve(food.name), "grams": float(grams)}
    if confidence is not None:
        payload["confidence"] = round(confidence, 2)
    return payload


def _published_foods(ids: Sequence[Any]) -> dict[str, Food]:
    foods = Food.objects.filter(pk__in=list(ids), status=ContentStatus.PUBLISHED)
    return {str(food.pk): food for food in foods}


# ───────────────────────── Analyses ─────────────────────────


@dataclass(frozen=True, slots=True)
class AnalysisCreated:
    analysis: Analysis
    quota: billing.QuotaState


@transaction.atomic
def create_analysis(*, user: Any, kind: str, upload_id: Any = None, text: str | None = None) -> AnalysisCreated:
    """Crée l'analyse en file : droits, quota décompté sous verrou, tâche lancée après validation."""
    if kind == AnalysisKind.TEXT:
        require_feature(user, "text_analysis")
        if not text or not 3 <= len(text.strip()) <= 500:
            raise ValidationFailed(errors={"text": [{"code": "invalid", "message": "3..500 characters"}]})
    feature = FEATURE_BY_KIND[kind]
    quota = billing.consume_quota(user=user, feature=feature)
    upload = consume_upload(user=user, upload_id=upload_id, kind="meal_photo") if kind == AnalysisKind.PHOTO else None
    analysis = Analysis.objects.create(
        user=user,
        kind=kind,
        upload=upload,
        input_text=(text or "").strip(),
        quota_feature=feature,
        quota_period_start=quota.period_start,
        counted_in_quota=True,
    )
    transaction.on_commit(lambda: current_app.send_task(RUN_ANALYSIS_TASK, args=[str(analysis.pk)]))
    return AnalysisCreated(analysis=analysis, quota=quota)


def _claim(analysis_id: Any) -> Analysis | None:
    """Passe l'analyse de `queued` à `processing` (une seule fois, même si la tâche est rejouée)."""
    with transaction.atomic():
        analysis = (
            Analysis.objects.select_for_update()
            .select_related("user__profile", "upload")
            .filter(pk=analysis_id)
            .first()
        )
        if analysis is None or analysis.status != AnalysisStatus.QUEUED:
            return None
        analysis.status = AnalysisStatus.PROCESSING
        analysis.started_at = timezone.now()
        analysis.save(update_fields=["status", "started_at", "updated_at"])
        return analysis


def _scan(analysis: Analysis) -> foodscan.ScanResult:
    profile = analysis.user.profile
    locale = analysis.user.locale
    if analysis.kind == AnalysisKind.PHOTO and analysis.upload is not None:
        data = storage.read_bytes(key=analysis.upload.storage_key)
        return foodscan.scan_photo(image_bytes=data, country=profile.country, locale=locale)
    return foodscan.scan_text(text=analysis.input_text, country=profile.country, locale=locale)


def _match_items(result: foodscan.ScanResult) -> list[dict[str, Any]]:
    threshold = float(settings_store.get("meals.food_match_threshold", nutrition.MATCH_THRESHOLD))
    items: list[dict[str, Any]] = []
    if result.output is None:
        return items
    for scanned in result.output.items:
        food = nutrition.match_food(label=scanned.label, threshold=threshold)
        if food is not None:
            items.append(item_payload(food, Decimal(str(scanned.grams)), confidence=scanned.confidence))
    return items


def _match_alternatives(result: foodscan.ScanResult, country: str | None) -> list[dict[str, Any]]:
    if result.output is None:
        return []
    alternatives = []
    for alternative in result.output.alternatives:
        dish = nutrition.match_dish(label=alternative.dish_label, country=country)
        alternatives.append(
            {
                "label": alternative.dish_label,
                "dish_id": str(dish.pk) if dish else None,
                "probability_percent": rules.probability_percent(alternative.confidence),
            }
        )
    return alternatives


def run_analysis(*, analysis_id: Any) -> Analysis | None:
    """Corps de la tâche Celery (file `ai`). Idempotent : une analyse déjà traitée n'est jamais relancée."""
    analysis = _claim(analysis_id)
    if analysis is None:
        return None
    try:
        result = _scan(analysis)
    except Exception:
        logger.exception("foodscan raised", extra={"analysis_id": str(analysis_id)})
        result = foodscan.ScanResult(
            succeeded=False,
            failure_reason="provider_error",
            output=None,
            low_confidence=False,
            model="",
            prompt_version="",
        )
    return _store_result(analysis_id=analysis.pk, result=result)


@transaction.atomic
def _store_result(*, analysis_id: Any, result: foodscan.ScanResult) -> Analysis:
    analysis = Analysis.objects.select_for_update().select_related("user__profile").get(pk=analysis_id)
    country = analysis.user.profile.country or None
    analysis.model = result.model
    analysis.prompt_version = result.prompt_version
    analysis.raw_response = result.raw_response
    analysis.context = result.context
    analysis.tokens_in = result.tokens_in
    analysis.tokens_out = result.tokens_out
    analysis.cost_usd_micros = result.cost_usd_micros
    analysis.completed_at = timezone.now()
    if result.succeeded and result.output is not None:
        output = result.output
        dish = nutrition.match_dish(label=output.dish_label or "", country=country) if output.dish_label else None
        analysis.status = AnalysisStatus.SUCCEEDED
        analysis.dish_label = output.dish_label or ""
        analysis.dish_guess = dish
        analysis.confidence = output.confidence
        analysis.low_confidence = result.low_confidence
        analysis.items = _match_items(result)
        analysis.alternatives = _match_alternatives(result, country)
    else:
        analysis.status = AnalysisStatus.FAILED
        analysis.failure_reason = result.failure_reason or "provider_error"
    if not result.counted_in_quota and analysis.counted_in_quota and analysis.quota_period_start:
        billing.refund_quota(
            user=analysis.user, feature=analysis.quota_feature, period_start=analysis.quota_period_start
        )
        analysis.counted_in_quota = False
    analysis.save()
    return analysis


def _own_analysis(*, user: Any, analysis_id: Any, for_update: bool = False) -> Analysis:
    queryset = Analysis.objects.filter(pk=analysis_id, user=user)
    if for_update:
        queryset = queryset.select_for_update()
    analysis = queryset.select_related("upload", "dish_guess").first()
    if analysis is None:
        raise NotFound()
    return analysis


@transaction.atomic
def select_dish(*, user: Any, analysis_id: Any, dish_id: Any) -> Analysis:
    """« Pas satisfait ? » : remplace le plat détecté par un plat du catalogue, sans IA ni quota."""
    analysis = _own_analysis(user=user, analysis_id=analysis_id, for_update=True)
    if analysis.status != AnalysisStatus.SUCCEEDED or Meal.objects.filter(analysis=analysis).exists():
        raise Conflict(detail="analysis not editable")
    dish = Dish.objects.filter(pk=dish_id, status=ContentStatus.PUBLISHED).prefetch_related("components__food").first()
    if dish is None:
        raise NotFound()
    predicted = analysis.dish_label
    analysis.dish_guess = dish
    analysis.dish_label = resolve(dish.name)
    analysis.confidence = 1.0
    analysis.low_confidence = False
    analysis.items = [item_payload(c.food, c.grams) for c in dish.components.all()]
    analysis.save(update_fields=["dish_guess", "dish_label", "confidence", "low_confidence", "items", "updated_at"])
    _record_feedback(
        analysis=analysis,
        rating="down",
        reason=FeedbackReason.WRONG_DISH,
        corrected_dish_label=resolve(dish.name),
        comment="",
        predicted_label=predicted,
    )
    return analysis


def _record_feedback(
    *,
    analysis: Analysis,
    rating: str,
    reason: str,
    corrected_dish_label: str,
    comment: str,
    predicted_label: str | None = None,
) -> AnalysisFeedback:
    feedback, _ = AnalysisFeedback.objects.update_or_create(
        analysis=analysis,
        defaults={
            "user": analysis.user,
            "rating": rating,
            "reason": reason,
            "corrected_dish_label": corrected_dish_label,
            "comment": comment,
            "corrected_items": analysis.items,
            "moderation_status": "new",
        },
    )
    if reason == FeedbackReason.WRONG_DISH and corrected_dish_label:
        analysis.corrected_dish_label = corrected_dish_label[:80]
        analysis.save(update_fields=["corrected_dish_label", "updated_at"])
        foodscan.submit_review(
            user=analysis.user,
            country=analysis.user.profile.country or None,
            analysis_id=analysis.pk,
            predicted_label=predicted_label if predicted_label is not None else analysis.dish_label,
            correct_label=corrected_dish_label,
        )
    events.publish(events.FeedbackGiven(user_id=analysis.user_id, analysis_id=analysis.pk, rating=rating))
    return feedback


@transaction.atomic
def submit_feedback(
    *,
    user: Any,
    analysis_id: Any,
    rating: str,
    reason: str | None,
    corrected_dish_label: str | None,
    comment: str | None,
) -> AnalysisFeedback:
    analysis = _own_analysis(user=user, analysis_id=analysis_id, for_update=True)
    if analysis.status != AnalysisStatus.SUCCEEDED:
        raise Conflict(detail="analysis not finished")
    if reason == FeedbackReason.WRONG_DISH and not (corrected_dish_label or "").strip():
        raise ValidationFailed(
            errors={"corrected_dish_label": [{"code": "required", "message": "required for wrong_dish"}]}
        )
    return _record_feedback(
        analysis=analysis,
        rating=rating,
        reason=reason or "",
        corrected_dish_label=(corrected_dish_label or "").strip(),
        comment=(comment or "").strip(),
    )


# ───────────────────────── Repas ─────────────────────────


@dataclass(frozen=True, slots=True)
class MealWrite:
    meal: Meal
    day: DailySummary
    previous_day: DailySummary | None = None


def suggest_meal_type(*, user: Any) -> tuple[str, date]:
    now = local_now(user)
    return rules.suggest_meal_type(now.time(), settings_store.get("meals.meal_type_starts")), now.date()


def _resolve_moment(*, user: Any, day: date | None, eaten_at: datetime | None) -> tuple[date, datetime]:
    eaten_at = eaten_at or timezone.now()
    if eaten_at > timezone.now() + timedelta(minutes=5):
        raise ValidationFailed(errors={"eaten_at": [{"code": "future", "message": "in the future"}]})
    day = nutrition.resolve_day(user=user, day=day or local_date_of(user, eaten_at))
    return day, eaten_at


def _items_from_input(
    items: Sequence[dict[str, Any]], *, labels: dict[str, str] | None = None
) -> list[tuple[Food, Decimal, str]]:
    if not items:
        raise ValidationFailed(errors={"items": [{"code": "required", "message": "at least one item"}]})
    foods = _published_foods([i["food_id"] for i in items])
    resolved = []
    for index, item in enumerate(items):
        food = foods.get(str(item["food_id"]))
        if food is None:
            raise ValidationFailed(
                errors={f"items.{index}.food_id": [{"code": "not_found", "message": "unknown food"}]}
            )
        label = (labels or {}).get(str(food.pk)) or resolve(food.name)
        resolved.append((food, Decimal(str(item["grams"])), label))
    return resolved


def _write_items(meal: Meal, rows: Sequence[tuple[Food, Decimal, str]]) -> None:
    meal.items.all().delete()
    totals = dict.fromkeys(NUTRIENT_KEYS, 0.0)
    objects = []
    for position, (food, grams, label) in enumerate(rows):
        nutrients = calculations.scale_nutrients(food_values(food), grams)
        for key in NUTRIENT_KEYS:
            totals[key] += nutrients[key]
        objects.append(
            MealItem(
                meal=meal,
                food=food,
                label=label[:120],
                grams=grams,
                position=position,
                **{key: Decimal(str(round(nutrients[key], 2))) for key in NUTRIENT_KEYS},
            )
        )
    MealItem.objects.bulk_create(objects)
    for key in NUTRIENT_KEYS:
        setattr(meal, key, Decimal(str(round(totals[key], 2))))
    meal.save(update_fields=[*NUTRIENT_KEYS, "updated_at"])


def _scaled(rows: Sequence[tuple[Food, Decimal, str]], portions: Decimal) -> list[tuple[Food, Decimal, str]]:
    return [(food, (grams * portions).quantize(Decimal("0.1")), label) for food, grams, label in rows]


def _dish_rows(dish_id: Any) -> tuple[Dish, list[tuple[Food, Decimal, str]]]:
    dish = Dish.objects.filter(pk=dish_id, status=ContentStatus.PUBLISHED).prefetch_related("components__food").first()
    if dish is None:
        raise NotFound()
    return dish, [(c.food, c.grams, resolve(c.food.name)) for c in dish.components.all()]


@transaction.atomic
def create_meal(
    *,
    user: Any,
    source: str,
    meal_type: str,
    day: date | None = None,
    eaten_at: datetime | None = None,
    analysis_id: Any = None,
    dish_id: Any = None,
    recipe_id: Any = None,
    portions: Decimal | None = None,
    items: Sequence[dict[str, Any]] | None = None,
    keep_photo: bool = True,
) -> MealWrite:
    day, eaten_at = _resolve_moment(user=user, day=day, eaten_at=eaten_at)
    portions = portions or Decimal(1)
    meal = Meal(user=user, date=day, eaten_at=eaten_at, meal_type=meal_type, source=source, portions=portions)
    if source in (MealSource.PHOTO, MealSource.TEXT):
        if not analysis_id:
            raise ValidationFailed(errors={"analysis_id": [{"code": "required", "message": "required"}]})
        analysis = _own_analysis(user=user, analysis_id=analysis_id, for_update=True)
        if analysis.status != AnalysisStatus.SUCCEEDED or Meal.objects.filter(analysis=analysis).exists():
            raise Conflict(detail="analysis not usable")
        labels = {i["food_id"]: i["label"] for i in analysis.items}
        rows = _items_from_input(items or [], labels=labels)
        meal.analysis = analysis
        meal.dish = analysis.dish_guess
        meal.photo = analysis.upload if keep_photo else None
        meal.title = (
            analysis.corrected_dish_label or analysis.dish_label or rules.meal_title([r[2] for r in rows], fallback="—")
        )[:120]
    elif source == MealSource.DISH:
        if not dish_id:
            raise ValidationFailed(errors={"dish_id": [{"code": "required", "message": "required"}]})
        dish, base = _dish_rows(dish_id)
        rows = _scaled(base, portions)
        meal.dish = dish
        meal.title = resolve(dish.name)[:120]
    elif source in (MealSource.RECIPE, MealSource.PROGRAM):
        if not recipe_id:
            raise ValidationFailed(errors={"recipe_id": [{"code": "required", "message": "required"}]})
        recipe = providers.resolve_recipe(user=user, recipe_id=recipe_id)
        if recipe is None:
            raise NotFound()
        rows = _scaled([(food, grams, resolve(food.name)) for food, grams in recipe.items], portions)
        meal.recipe_id = recipe.recipe_id
        meal.title = recipe.title[:120]
    elif source == MealSource.FOODS:
        rows = _items_from_input(items or [])
        meal.title = rules.meal_title([r[2] for r in rows], fallback="—")
    else:
        raise ValidationFailed(errors={"source": [{"code": "invalid_choice", "message": source}]})
    meal.save()
    _write_items(meal, rows)
    summary = nutrition.recompute_day(user=user, day=day)
    events.publish(events.MealLogged(user_id=user.pk, meal_id=meal.pk, day=day))
    return MealWrite(meal=meal, day=summary)


def _own_meal(*, user: Any, meal_id: Any) -> Meal:
    meal = Meal.objects.select_for_update().filter(pk=meal_id, user=user).first()
    if meal is None:
        raise NotFound()
    return meal


@transaction.atomic
def update_meal(
    *,
    user: Any,
    meal_id: Any,
    meal_type: str | None = None,
    day: date | None = None,
    items: Sequence[dict[str, Any]] | None = None,
    portions: Decimal | None = None,
) -> MealWrite:
    meal = _own_meal(user=user, meal_id=meal_id)
    old_day = meal.date
    if meal_type:
        meal.meal_type = meal_type
    if day is not None:
        meal.date = nutrition.resolve_day(user=user, day=day)
    meal.save(update_fields=["meal_type", "date", "updated_at"])
    if items is not None:
        labels = {str(i.food_id): i.label for i in meal.items.all()}
        _write_items(meal, _items_from_input(items, labels=labels))
    elif portions is not None and portions != meal.portions:
        current = [(i.food, i.grams / meal.portions, i.label) for i in meal.items.select_related("food")]
        meal.portions = portions
        meal.save(update_fields=["portions", "updated_at"])
        _write_items(meal, _scaled(current, portions))
    summary = nutrition.recompute_day(user=user, day=meal.date)
    previous = nutrition.recompute_day(user=user, day=old_day) if old_day != meal.date else None
    return MealWrite(meal=meal, day=summary, previous_day=previous)


@transaction.atomic
def delete_meal(*, user: Any, meal_id: Any) -> DailySummary:
    meal = _own_meal(user=user, meal_id=meal_id)
    day = meal.date
    meal.delete()
    return nutrition.recompute_day(user=user, day=day)


@transaction.atomic
def duplicate_meal(*, user: Any, meal_id: Any, day: date, meal_type: str) -> MealWrite:
    source = Meal.objects.filter(pk=meal_id, user=user).first()
    if source is None:
        raise NotFound()
    day = nutrition.resolve_day(user=user, day=day)
    rows = [(i.food, i.grams, i.label) for i in source.items.select_related("food")]
    meal = Meal.objects.create(
        user=user,
        date=day,
        eaten_at=timezone.now(),
        meal_type=meal_type,
        source=MealSource.DUPLICATE,
        dish=source.dish,
        recipe_id=source.recipe_id,
        title=source.title,
        portions=source.portions,
    )
    _write_items(meal, rows)
    summary = nutrition.recompute_day(user=user, day=day)
    events.publish(events.MealLogged(user_id=user.pk, meal_id=meal.pk, day=day))
    return MealWrite(meal=meal, day=summary)


@transaction.atomic
def delete_meal_photo(*, user: Any, meal_id: Any) -> None:
    meal = _own_meal(user=user, meal_id=meal_id)
    photo = meal.photo
    if photo is None:
        return
    meal.photo = None
    meal.save(update_fields=["photo", "updated_at"])
    if not Meal.objects.filter(photo=photo).exists():
        key = photo.storage_key
        photo.delete()
        transaction.on_commit(lambda: storage.delete(key=key))


# ───────────────────────── Projection ─────────────────────────


def day_contribution(user: Any, day: date) -> dict[str, Any]:
    """Part de `meals` dans `DailySummary` (enregistrée dans MealsConfig.ready)."""
    totals = Meal.objects.filter(user=user, date=day).aggregate(
        count=Count("id"),
        kcal=Sum("kcal"),
        protein=Sum("protein_g"),
        carbs=Sum("carbs_g"),
        fat=Sum("fat_g"),
        fiber=Sum("fiber_g"),
        salt=Sum("salt_g"),
        sugars=Sum("sugars_g"),
    )
    return {
        "meals_count": totals["count"] or 0,
        "consumed_kcal": float(totals["kcal"] or 0),
        "protein_g": float(totals["protein"] or 0),
        "carbs_g": float(totals["carbs"] or 0),
        "fat_g": float(totals["fat"] or 0),
        "fiber_g": float(totals["fiber"] or 0),
        "salt_g": float(totals["salt"] or 0),
        "sugars_g": float(totals["sugars"] or 0),
    }


def recent_dish_ids(user: Any, limit: int) -> list[Any]:
    ids = (
        Meal.objects.filter(user=user, dish__isnull=False)
        .order_by("-created_at")
        .values_list("dish_id", flat=True)[: limit * 3]
    )
    return list(dict.fromkeys(ids))[:limit]
