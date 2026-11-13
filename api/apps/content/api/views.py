"""Vues minces de content : recettes, plantes, prévention, FAQ, documents légaux."""

from __future__ import annotations

from typing import Any, ClassVar, Final

from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.throttling import BaseThrottle

from apps.accounts.presenters import legal_ref_out
from apps.accounts.selectors import latest_published_documents
from apps.billing.services import entitlement_for
from apps.content import selectors, services
from apps.content import serializers as s
from apps.content.presenters import plant_summary_out, recipe_summary_out
from apps.core.errors import NotFound
from apps.core.i18n import resolve
from apps.core.localtime import local_today
from apps.core.pagination import cursor_body, cursor_paginate
from apps.core.permissions import require_feature
from apps.core.throttles import PublicReadThrottle
from apps.core.views import AppAPIView, PublicAPIView, validated

FULL_CATALOG: Final = "full_catalog"
MAX_TAGS: Final = 5


def _full(user: Any) -> bool:
    return entitlement_for(user).allows(FULL_CATALOG)


class RecipesView(AppAPIView):
    @extend_schema(operation_id="listRecipes")
    def get(self, request: Request) -> Response:
        params = validated(s.RecipeFilterSerializer, request.query_params)
        queryset = selectors.filter_recipes(
            selectors.recipes_for(user=request.user),
            q=params.get("q"),
            country=params.get("country"),
            goal=params.get("goal"),
            tags=request.query_params.getlist("tag")[:MAX_TAGS],
            max_minutes=params.get("max_minutes"),
            favorites=params["favorites"],
        )
        full = _full(request.user)
        rows, next_cursor = cursor_paginate(request, queryset)
        return Response(cursor_body([recipe_summary_out(r, full_catalog=full) for r in rows], next_cursor))


class RecipeDetailView(AppAPIView):
    conditional_entitlements: ClassVar[dict[str, str]] = {"GET": FULL_CATALOG}

    @extend_schema(operation_id="getRecipe")
    def get(self, request: Request, id: Any) -> Response:  # noqa: A002 - nom imposé par le contrat
        recipe = selectors.recipe_detail(user=request.user, recipe_id=id)
        if recipe is None:
            raise NotFound()
        if not recipe.is_free:
            require_feature(request.user, FULL_CATALOG)
        services.record_view(user=request.user, content_type="recipe", object_id=recipe.pk)
        return Response(s.recipe_detail_out(recipe, full_catalog=_full(request.user)))


class RecipeFavoriteView(AppAPIView):
    @extend_schema(operation_id="favoriteRecipe", request=None)
    def put(self, request: Request, id: Any) -> Response:  # noqa: A002
        services.favorite_recipe(user=request.user, recipe_id=id, favorite=True)
        return Response(status=status.HTTP_204_NO_CONTENT)

    @extend_schema(operation_id="unfavoriteRecipe")
    def delete(self, request: Request, id: Any) -> Response:  # noqa: A002
        services.favorite_recipe(user=request.user, recipe_id=id, favorite=False)
        return Response(status=status.HTTP_204_NO_CONTENT)


class PlantsView(AppAPIView):
    @extend_schema(operation_id="listPlants")
    def get(self, request: Request) -> Response:
        params = validated(s.PlantFilterSerializer, request.query_params)
        queryset = selectors.filter_plants(
            selectors.plants_for(user=request.user),
            q=params.get("q"),
            tag=params.get("tag"),
            favorites=params["favorites"],
        )
        rows, next_cursor = cursor_paginate(request, queryset)
        return Response(cursor_body([plant_summary_out(p) for p in rows], next_cursor))


class PlantDetailView(AppAPIView):
    @extend_schema(operation_id="getPlant")
    def get(self, request: Request, id: Any) -> Response:  # noqa: A002
        plant = selectors.plant_detail(user=request.user, plant_id=id)
        if plant is None:
            raise NotFound()
        services.record_view(user=request.user, content_type="plant", object_id=plant.pk)
        return Response(s.plant_detail_out(plant, full_catalog=_full(request.user)))


class PlantFavoriteView(AppAPIView):
    @extend_schema(operation_id="favoritePlant", request=None)
    def put(self, request: Request, id: Any) -> Response:  # noqa: A002
        services.favorite_plant(user=request.user, plant_id=id, favorite=True)
        return Response(status=status.HTTP_204_NO_CONTENT)

    @extend_schema(operation_id="unfavoritePlant")
    def delete(self, request: Request, id: Any) -> Response:  # noqa: A002
        services.favorite_plant(user=request.user, plant_id=id, favorite=False)
        return Response(status=status.HTTP_204_NO_CONTENT)


class PreventionView(AppAPIView):
    @extend_schema(operation_id="getPrevention")
    def get(self, request: Request) -> Response:
        user = request.user
        entitlement = entitlement_for(user)
        plus = entitlement.tier == "plus"
        full = entitlement.allows(FULL_CATALOG)
        enough = services.has_enough_data(user=user, today=local_today(user))
        report_allowed = entitlement.allows("weekly_report")
        report = selectors.latest_weekly_report(user=user) if report_allowed else None
        return Response(
            {
                "state": "ok" if enough else "not_enough_data",
                "tips": [s.user_tip_out(t, plus=plus, full_catalog=full) for t in selectors.active_tips(user=user)],
                "weekly_report": {"week_start": report.week_start, **report.data} if report else None,
                "weekly_report_locked": not report_allowed,
            }
        )


class UserTipView(AppAPIView):
    @extend_schema(operation_id="updateUserTip", request=s.UserTipUpdateSerializer)
    def patch(self, request: Request, id: Any) -> Response:  # noqa: A002
        data = validated(s.UserTipUpdateSerializer, request.data)
        services.update_user_tip(user=request.user, tip_id=id, read=data.get("read"), dismissed=data.get("dismissed"))
        return Response(status=status.HTTP_204_NO_CONTENT)


class FaqView(PublicAPIView):
    throttle_classes: ClassVar[list[type[BaseThrottle]]] = [PublicReadThrottle]

    @extend_schema(operation_id="listFaq")
    def get(self, request: Request) -> Response:
        params = validated(s.FaqFilterSerializer, request.query_params)
        return Response(s.faq_out(selectors.faq(audience=params.get("audience"))))


class LegalDocumentView(PublicAPIView):
    throttle_classes: ClassVar[list[type[BaseThrottle]]] = [PublicReadThrottle]

    @extend_schema(operation_id="getLegalDocument")
    def get(self, request: Request, kind: str) -> Response:
        document = latest_published_documents().get(kind)
        if document is None:
            raise NotFound()
        return Response(
            {**legal_ref_out(document), "body": resolve(document.body), "published_at": document.published_at}
        )
