"""Routes admin des avis sur les analyses (préfixe /api/v1)."""

from __future__ import annotations

from django.urls import path

from apps.meals.admin_api import views

urlpatterns = [
    path("admin/feedback", views.FeedbackListView.as_view()),
    path("admin/feedback/stats", views.FeedbackStatsView.as_view()),
    path("admin/feedback/<uuid:id>", views.FeedbackDetailView.as_view()),
    path("admin/feedback/<uuid:id>/resolve", views.FeedbackResolveView.as_view()),
]
