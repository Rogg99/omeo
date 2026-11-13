"""Vues minces de meals : analyses, avis, quotas, repas."""

from __future__ import annotations

from datetime import timedelta
from typing import Any, ClassVar, Final

from django.db.models import QuerySet
from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.request import Request
from rest_framework.response import Response

from apps.billing.services import all_quota_states, quota_state
from apps.core import settings_store
from apps.core.errors import NotFound, ValidationFailed
from apps.core.idempotency import idempotent
from apps.core.pagination import cursor_body, cursor_paginate
from apps.core.rewards import collect_rewards
from apps.core.views import AppAPIView, validated
from apps.meals import selectors, services
from apps.meals import serializers as s
from apps.meals.models import Analysis, AnalysisStatus, Meal
from apps.nutrition.constants import nutrition_constants
from apps.nutrition.presenters import day_summary_out

MAX_LIST_RANGE_DAYS: Final = 92


def _analysis_body(analysis: Analysis, *, quota: dict[str, Any] | None = None) -> dict[str, Any]:
    meal_type, _ = services.suggest_meal_type(user=analysis.user)
    return s.analysis_out(
        analysis,
        foods=selectors.foods_by_id(i["food_id"] for i in analysis.items),
        dishes=selectors.dishes_by_id(a.get("dish_id") for a in analysis.alternatives),
        quota=quota,
        suggested_meal_type=meal_type,
    )


def _poll_headers(analysis: Analysis) -> dict[str, str]:
    if analysis.status in (AnalysisStatus.QUEUED, AnalysisStatus.PROCESSING):
        return {"Retry-After": str(settings_store.get("meals.analysis_poll_seconds", 2))}
    return {}


def _meal_write_body(write: services.MealWrite, rewards: dict[str, Any]) -> dict[str, Any]:
    c = nutrition_constants()
    meal = selectors.meal_for(user=write.meal.user, meal_id=write.meal.pk)
    if meal is None:
        raise NotFound()
    return {
        "meal": s.meal_out(meal),
        "day": day_summary_out(write.day, c=c),
        "previous_day": day_summary_out(write.previous_day, c=c) if write.previous_day else None,
        "rewards": rewards,
    }


class AnalysesView(AppAPIView):
    conditional_entitlements: ClassVar[dict[str, str]] = {"POST": "text_analysis"}

    @extend_schema(operation_id="createAnalysis", request=s.AnalysisInputSerializer)
    @idempotent
    def post(self, request: Request) -> Response:
        data = validated(s.AnalysisInputSerializer, request.data)
        created = services.create_analysis(
            user=request.user, kind=data["kind"], upload_id=data.get("upload_id"), text=data.get("text")
        )
        analysis = created.analysis
        return Response(
            _analysis_body(analysis, quota=created.quota.as_dict()),
            status=status.HTTP_202_ACCEPTED,
            headers=_poll_headers(analysis),
        )


class AnalysisDetailView(AppAPIView):
    @extend_schema(operation_id="getAnalysis")
    def get(self, request: Request, id: Any) -> Response:  # noqa: A002 - nom imposé par le contrat
        analysis = selectors.analysis_for(user=request.user, analysis_id=id)
        if analysis is None:
            raise NotFound()
        quota = quota_state(user=request.user, feature=analysis.quota_feature) if analysis.quota_feature else None
        return Response(
            _analysis_body(analysis, quota=quota.as_dict() if quota else None), headers=_poll_headers(analysis)
        )


class AnalysisDishView(AppAPIView):
    @extend_schema(operation_id="selectAnalysisDish", request=s.SelectDishSerializer)
    @idempotent
    def post(self, request: Request, id: Any) -> Response:  # noqa: A002
        data = validated(s.SelectDishSerializer, request.data)
        analysis = services.select_dish(user=request.user, analysis_id=id, dish_id=data["dish_id"])
        return Response(_analysis_body(analysis))


class AnalysisFeedbackView(AppAPIView):
    @extend_schema(operation_id="putAnalysisFeedback", request=s.FeedbackInputSerializer)
    def put(self, request: Request, id: Any) -> Response:  # noqa: A002
        data = validated(s.FeedbackInputSerializer, request.data)
        with collect_rewards() as rewards:
            services.submit_feedback(
                user=request.user,
                analysis_id=id,
                rating=data["rating"],
                reason=data.get("reason"),
                corrected_dish_label=data.get("corrected_dish_label"),
                comment=data.get("comment"),
            )
        return Response({"rewards": rewards.as_dict()})


class QuotasView(AppAPIView):
    @extend_schema(operation_id="getQuotas")
    def get(self, request: Request) -> Response:
        return Response([state.as_dict() for state in all_quota_states(user=request.user)])


class MealsView(AppAPIView):
    @extend_schema(operation_id="listMeals")
    def get(self, request: Request) -> Response:
        params = validated(s.MealListSerializer, request.query_params)
        queryset: QuerySet[Meal]
        if params.get("date"):
            queryset = selectors.meals_between(user=request.user, start=params["date"], end=params["date"])
        elif params.get("from") and params.get("to"):
            start, end = params["from"], params["to"]
            if end < start or end - start > timedelta(days=MAX_LIST_RANGE_DAYS):
                raise ValidationFailed(errors={"to": [{"code": "invalid_range", "message": "max 92 days"}]})
            queryset = selectors.meals_between(user=request.user, start=start, end=end)
        else:
            queryset = selectors.meals_for(user=request.user)
        rows, next_cursor = cursor_paginate(request, queryset, order_field="eaten_at")
        return Response(cursor_body([s.meal_out(m) for m in rows], next_cursor))

    @extend_schema(operation_id="createMeal", request=s.MealInputSerializer)
    @idempotent
    def post(self, request: Request) -> Response:
        data = validated(s.MealInputSerializer, request.data)
        with collect_rewards() as rewards:
            write = services.create_meal(
                user=request.user,
                source=data["source"],
                meal_type=data["meal_type"],
                day=data.get("date"),
                eaten_at=data.get("eaten_at"),
                analysis_id=data.get("analysis_id"),
                dish_id=data.get("dish_id"),
                recipe_id=data.get("recipe_id"),
                portions=data.get("portions"),
                items=[dict(i) for i in data.get("items", [])],
                keep_photo=data["keep_photo"],
            )
        return Response(_meal_write_body(write, rewards.as_dict()), status=status.HTTP_201_CREATED)


class MealDetailView(AppAPIView):
    @extend_schema(operation_id="getMeal")
    def get(self, request: Request, id: Any) -> Response:  # noqa: A002
        meal = selectors.meal_for(user=request.user, meal_id=id)
        if meal is None:
            raise NotFound()
        return Response(s.meal_out(meal))

    @extend_schema(operation_id="updateMeal", request=s.MealUpdateSerializer)
    def patch(self, request: Request, id: Any) -> Response:  # noqa: A002
        data = validated(s.MealUpdateSerializer, request.data)
        with collect_rewards() as rewards:
            write = services.update_meal(
                user=request.user,
                meal_id=id,
                meal_type=data.get("meal_type"),
                day=data.get("date"),
                items=[dict(i) for i in data["items"]] if "items" in data else None,
                portions=data.get("portions"),
            )
        return Response(_meal_write_body(write, rewards.as_dict()))

    @extend_schema(operation_id="deleteMeal")
    def delete(self, request: Request, id: Any) -> Response:  # noqa: A002
        summary = services.delete_meal(user=request.user, meal_id=id)
        return Response({"day": day_summary_out(summary, c=nutrition_constants())})


class MealDuplicateView(AppAPIView):
    @extend_schema(operation_id="duplicateMeal", request=s.DuplicateSerializer)
    @idempotent
    def post(self, request: Request, id: Any) -> Response:  # noqa: A002
        data = validated(s.DuplicateSerializer, request.data)
        with collect_rewards() as rewards:
            write = services.duplicate_meal(
                user=request.user, meal_id=id, day=data["date"], meal_type=data["meal_type"]
            )
        return Response(_meal_write_body(write, rewards.as_dict()), status=status.HTTP_201_CREATED)


class MealPhotoView(AppAPIView):
    @extend_schema(operation_id="deleteMealPhoto")
    def delete(self, request: Request, id: Any) -> Response:  # noqa: A002
        services.delete_meal_photo(user=request.user, meal_id=id)
        return Response(status=status.HTTP_204_NO_CONTENT)


class MealTypeSuggestionView(AppAPIView):
    @extend_schema(operation_id="suggestMealType")
    def get(self, request: Request) -> Response:
        meal_type, day = services.suggest_meal_type(user=request.user)
        return Response({"meal_type": meal_type, "date": day})
