"""Routes meals (préfixe /api/v1)."""

from __future__ import annotations

from django.urls import path

from apps.meals.api import views

urlpatterns = [
    path("me/analyses", views.AnalysesView.as_view()),
    path("me/analyses/<uuid:id>", views.AnalysisDetailView.as_view()),
    path("me/analyses/<uuid:id>/dish", views.AnalysisDishView.as_view()),
    path("me/analyses/<uuid:id>/feedback", views.AnalysisFeedbackView.as_view()),
    path("me/quotas", views.QuotasView.as_view()),
    path("me/meals", views.MealsView.as_view()),
    path("me/meals/<uuid:id>", views.MealDetailView.as_view()),
    path("me/meals/<uuid:id>/duplicate", views.MealDuplicateView.as_view()),
    path("me/meals/<uuid:id>/photo", views.MealPhotoView.as_view()),
    path("me/meal-type-suggestion", views.MealTypeSuggestionView.as_view()),
]
