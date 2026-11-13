"""Vues minces nutrition : catalogue (aliments, plats, favoris), eau, calendrier, progression."""

from __future__ import annotations

from typing import Any, ClassVar

from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.request import Request
from rest_framework.response import Response

from apps.core.errors import NotFound
from apps.core.idempotency import idempotent
from apps.core.localtime import local_today
from apps.core.pagination import cursor_body, cursor_paginate
from apps.core.permissions import require_feature
from apps.core.rewards import collect_rewards
from apps.core.views import AppAPIView, validated
from apps.nutrition import selectors, services, views_data
from apps.nutrition import serializers as s
from apps.nutrition.constants import nutrition_constants

LONG_RANGE_FEATURE = "progress_long_range"


class FoodSearchView(AppAPIView):
    @extend_schema(operation_id="searchFoods")
    def get(self, request: Request) -> Response:
        params = validated(s.FoodSearchSerializer, request.query_params)
        foods = selectors.search_foods(q=params["q"], limit=params["limit"])
        return Response({"results": [s.food_out(f, query=params["q"]) for f in foods]})


class DishSearchView(AppAPIView):
    @extend_schema(operation_id="searchDishes")
    def get(self, request: Request) -> Response:
        params = validated(s.DishSearchSerializer, request.query_params)
        queryset = selectors.dishes_for(
            user=request.user, q=params.get("q"), country=params.get("country"), scope=params["scope"]
        )
        rows, next_cursor = cursor_paginate(request, queryset)
        return Response(cursor_body([s.dish_summary_out(d) for d in rows], next_cursor))


class DishDetailView(AppAPIView):
    @extend_schema(operation_id="getDish")
    def get(self, request: Request, id: Any) -> Response:  # noqa: A002 - nom imposé par le contrat
        dish = selectors.dish_detail(user=request.user, dish_id=id)
        if dish is None:
            raise NotFound()
        return Response(s.dish_detail_out(dish))


class DishFavoriteView(AppAPIView):
    @extend_schema(operation_id="favoriteDish", request=None)
    def put(self, request: Request, id: Any) -> Response:  # noqa: A002
        services.favorite_dish(user=request.user, dish_id=id)
        return Response(status=status.HTTP_204_NO_CONTENT)

    @extend_schema(operation_id="unfavoriteDish")
    def delete(self, request: Request, id: Any) -> Response:  # noqa: A002
        services.unfavorite_dish(user=request.user, dish_id=id)
        return Response(status=status.HTTP_204_NO_CONTENT)


class WaterView(AppAPIView):
    @extend_schema(operation_id="addWater", request=s.WaterInputSerializer)
    @idempotent
    def post(self, request: Request) -> Response:
        data = validated(s.WaterInputSerializer, request.data)
        with collect_rewards() as rewards:
            summary = services.add_water(user=request.user, amount_ml=data["amount_ml"], day=data.get("date"))
        body = {"water": s.water_out(summary, c=nutrition_constants()), "rewards": rewards.as_dict()}
        return Response(body, status=status.HTTP_201_CREATED)


class CalendarView(AppAPIView):
    @extend_schema(operation_id="getCalendar")
    def get(self, request: Request) -> Response:
        params = validated(s.CalendarSerializer, request.query_params)
        year, month = (int(part) for part in params["month"].split("-"))
        return Response(
            views_data.calendar_month(
                user=request.user, year=year, month=month, today=local_today(request.user), c=nutrition_constants()
            )
        )


class ProgressView(AppAPIView):
    conditional_entitlements: ClassVar[dict[str, str]] = {"GET": LONG_RANGE_FEATURE}

    @extend_schema(operation_id="getProgress")
    def get(self, request: Request) -> Response:
        params = validated(s.ProgressSerializer, request.query_params)
        if params["range"] != "7d":
            require_feature(request.user, LONG_RANGE_FEATURE)
        return Response(
            views_data.progress(
                user=request.user,
                metric=params["metric"],
                range_key=params["range"],
                today=local_today(request.user),
                c=nutrition_constants(),
            )
        )
