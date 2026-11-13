"""Back-office des avis sur les analyses IA : file de modération, détail (réponse brute), traitement, statistiques."""

from __future__ import annotations

from decimal import Decimal
from typing import Any

from django.db import transaction
from django.db.models import Count, Q, QuerySet
from django.utils import timezone
from drf_spectacular.utils import extend_schema
from rest_framework import serializers
from rest_framework.request import Request
from rest_framework.response import Response

from apps.core import audit
from apps.core.errors import NotFound, ValidationFailed
from apps.core.i18n import resolve
from apps.core.models import ContentStatus
from apps.core.pagination import page_body, page_paginate
from apps.core.presenters import image_out
from apps.core.views import AdminAPIView, validated
from apps.foodscan import services as foodscan
from apps.foodscan.models import ScanReview
from apps.meals.models import AnalysisFeedback, HandledAction, ModerationStatus
from apps.nutrition import services as nutrition
from apps.nutrition.models import Dish, DishComponent, Food


def _feedback_queryset() -> QuerySet[AnalysisFeedback]:
    return AnalysisFeedback.objects.select_related(
        "analysis", "analysis__upload", "user", "user__profile", "handled_by"
    )


def feedback_row_out(feedback: AnalysisFeedback) -> dict[str, Any]:
    analysis = feedback.analysis
    return {
        "id": feedback.id,
        "rating": feedback.rating,
        "reason": feedback.reason or None,
        "status": feedback.moderation_status,
        "dish_label": analysis.dish_label or None,
        "confidence": analysis.confidence,
        "locale": feedback.user.locale,
        "country": feedback.user.profile.country or None,
        "thumbnail": image_out(analysis.upload),
        "created_at": feedback.created_at,
    }


class FeedbackListView(AdminAPIView):
    required_permission = "feedback.view"

    @extend_schema(operation_id="adminListFeedback")
    def get(self, request: Request) -> Response:
        params = request.query_params
        queryset = _feedback_queryset()
        if params.get("rating"):
            queryset = queryset.filter(rating=params["rating"])
        if params.get("reason"):
            queryset = queryset.filter(reason=params["reason"])
        if params.get("status"):
            queryset = queryset.filter(moderation_status=params["status"])
        if params.get("dish_id"):
            queryset = queryset.filter(analysis__dish_guess_id=params["dish_id"])
        if params.get("max_confidence"):
            queryset = queryset.filter(analysis__confidence__lte=float(params["max_confidence"]))
        if params.get("locale"):
            queryset = queryset.filter(user__locale=params["locale"])
        if params.get("from"):
            queryset = queryset.filter(created_at__date__gte=params["from"])
        if params.get("to"):
            queryset = queryset.filter(created_at__date__lte=params["to"])
        rows, meta = page_paginate(request, queryset.order_by("-created_at"))
        return Response(page_body([feedback_row_out(f) for f in rows], meta))


class FeedbackDetailView(AdminAPIView):
    required_permission = "feedback.view"

    @extend_schema(operation_id="adminGetFeedback")
    def get(self, request: Request, id: Any) -> Response:  # noqa: A002 - nom imposé par le contrat
        feedback = _feedback_queryset().filter(pk=id).first()
        if feedback is None:
            raise NotFound()
        analysis = feedback.analysis
        return Response(
            {
                **feedback_row_out(feedback),
                "photo": image_out(analysis.upload),
                "input_text": analysis.input_text or None,
                "comment": feedback.comment or None,
                "model": analysis.model,
                "prompt_version": analysis.prompt_version,
                "ai_raw": analysis.raw_response,
                "ai_items": analysis.items,
                "corrected_items": feedback.corrected_items,
                "handled_by": feedback.handled_by.email if feedback.handled_by else None,
                "handled_action": feedback.handled_action or None,
            }
        )


class ResolveSerializer(serializers.Serializer[Any]):
    action = serializers.ChoiceField(
        choices=["handled", "ignore", "create_dish", "create_food", "add_alias", "report_defect"]
    )
    dish_id = serializers.UUIDField(required=False)
    alias = serializers.CharField(max_length=80, required=False)
    note = serializers.CharField(max_length=1000, required=False, allow_blank=True, default="")


def _create_dish_draft(feedback: AnalysisFeedback) -> Dish:
    analysis = feedback.analysis
    label = feedback.corrected_dish_label or analysis.dish_label or "Plat à nommer"
    items = feedback.corrected_items or analysis.items
    dish = Dish.objects.create(
        name={"fr": label},
        country=feedback.user.profile.country,
        standard_portion_g=Decimal(str(sum(float(i["grams"]) for i in items) or 300)),
        status=ContentStatus.DRAFT,
    )
    foods = {str(f.pk): f for f in Food.objects.filter(pk__in=[i["food_id"] for i in items])}
    for item in items:
        if item["food_id"] in foods:
            DishComponent.objects.get_or_create(
                dish=dish, food=foods[item["food_id"]], defaults={"grams": Decimal(str(item["grams"]))}
            )
    return nutrition.refresh_dish(dish=dish)


class FeedbackResolveView(AdminAPIView):
    required_permission = "feedback.resolve"

    @extend_schema(operation_id="adminResolveFeedback", request=ResolveSerializer)
    def post(self, request: Request, id: Any) -> Response:  # noqa: A002
        data = validated(ResolveSerializer, request.data)
        action = data["action"]
        created: Any = None
        with transaction.atomic():
            feedback = _feedback_queryset().select_for_update(of=("self",)).filter(pk=id).first()
            if feedback is None:
                raise NotFound()
            handled_action = ""
            if action == "create_dish":
                created = _create_dish_draft(feedback)
                handled_action = HandledAction.DISH_CREATED
            elif action == "create_food":
                label = data.get("alias") or feedback.corrected_dish_label or "Aliment à compléter"
                created = nutrition.save_food(food=Food(name={"fr": label}, status=ContentStatus.DRAFT))
                handled_action = HandledAction.FOOD_CREATED
            elif action == "add_alias":
                dish = Dish.objects.select_for_update().filter(pk=data.get("dish_id")).first()
                alias = (data.get("alias") or "").strip()
                if dish is None or not alias:
                    raise ValidationFailed(errors={"alias": [{"code": "required", "message": "dish_id and alias"}]})
                if alias not in dish.aliases:
                    dish.aliases = [*dish.aliases, alias]
                    nutrition.refresh_dish(dish=dish)
                handled_action = HandledAction.ALIAS_ADDED
            elif action == "report_defect":
                handled_action = HandledAction.DEFECT_REPORTED
            review = ScanReview.objects.filter(analysis_id=feedback.analysis_id).first()
            if review is not None and action != "report_defect":
                foodscan.moderate_review(
                    review=review, moderator=request.user, approve=action != "ignore", hint=data["note"]
                )
            feedback.moderation_status = ModerationStatus.IGNORED if action == "ignore" else ModerationStatus.HANDLED
            feedback.handled_by = request.user  # type: ignore[assignment]
            feedback.handled_action = handled_action
            feedback.handled_at = timezone.now()
            feedback.save(
                update_fields=["moderation_status", "handled_by", "handled_action", "handled_at", "updated_at"]
            )
            audit.record(
                actor=request.user,
                action=f"feedback.{action}",
                target_type="feedback",
                target_id=feedback.pk,
                after={"created": str(created.pk) if created else None},
                reason=data["note"],
                request=request,
            )
        return Response({"status": feedback.moderation_status, "created_content_id": created.pk if created else None})


class FeedbackStatsView(AdminAPIView):
    required_permission = "feedback.view"

    @extend_schema(operation_id="adminFeedbackStats")
    def get(self, request: Request) -> Response:
        queryset = AnalysisFeedback.objects.all()
        if request.query_params.get("from"):
            queryset = queryset.filter(created_at__date__gte=request.query_params["from"])
        if request.query_params.get("to"):
            queryset = queryset.filter(created_at__date__lte=request.query_params["to"])
        negative = Count("id", filter=Q(rating="down"))
        by_dish = (
            queryset.filter(analysis__dish_guess__isnull=False)
            .values("analysis__dish_guess_id", "analysis__dish_guess__name")
            .annotate(total=Count("id"), negatives=negative)
            .order_by("-negatives")[:50]
        )
        by_country = (
            queryset.values("user__profile__country").annotate(total=Count("id"), negatives=negative).order_by("-total")
        )
        return Response(
            {
                "by_dish": [
                    {
                        "dish_id": str(row["analysis__dish_guess_id"]),
                        "dish": resolve(row["analysis__dish_guess__name"]),
                        "total": row["total"],
                        "negative_rate": round(row["negatives"] / row["total"], 3) if row["total"] else 0,
                    }
                    for row in by_dish
                ],
                "by_country": [
                    {
                        "country": row["user__profile__country"] or "",
                        "total": row["total"],
                        "negative_rate": round(row["negatives"] / row["total"], 3) if row["total"] else 0,
                    }
                    for row in by_country
                ],
                "top_contested": [
                    {"dish": resolve(row["analysis__dish_guess__name"]), "negatives": row["negatives"]}
                    for row in list(by_dish)[:10]
                    if row["negatives"]
                ],
            }
        )
