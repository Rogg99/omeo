"""Routes de content (préfixe /api/v1)."""

from __future__ import annotations

from django.urls import path, register_converter

from apps.content.api import views


class LegalKindConverter:
    regex = "terms|privacy|cookies|legal_notice"

    def to_python(self, value: str) -> str:
        return value

    def to_url(self, value: str) -> str:
        return value


register_converter(LegalKindConverter, "legal_kind")

urlpatterns = [
    path("recipes", views.RecipesView.as_view()),
    path("recipes/<uuid:id>", views.RecipeDetailView.as_view()),
    path("recipes/<uuid:id>/favorite", views.RecipeFavoriteView.as_view()),
    path("plants", views.PlantsView.as_view()),
    path("plants/<uuid:id>", views.PlantDetailView.as_view()),
    path("plants/<uuid:id>/favorite", views.PlantFavoriteView.as_view()),
    path("me/prevention", views.PreventionView.as_view()),
    path("me/prevention/tips/<uuid:id>", views.UserTipView.as_view()),
    path("faq", views.FaqView.as_view()),
    path("legal/<legal_kind:kind>", views.LegalDocumentView.as_view()),
]
