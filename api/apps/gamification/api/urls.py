"""Routes de gamification (préfixe /api/v1)."""

from __future__ import annotations

from django.urls import path

from apps.gamification.api import views

urlpatterns = [
    path("me/rewards", views.RewardsView.as_view()),
    path("me/badges", views.BadgesView.as_view()),
    path("me/points", views.PointEventsView.as_view()),
]
