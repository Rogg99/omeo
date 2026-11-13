"""Routes nutrition (préfixe /api/v1)."""

from __future__ import annotations

from django.urls import path

from apps.core.converters import register_converters
from apps.nutrition.api import views

register_converters()

urlpatterns = [
    path("foods", views.FoodSearchView.as_view()),
    path("dishes", views.DishSearchView.as_view()),
    path("dishes/<uuid:id>", views.DishDetailView.as_view()),
    path("dishes/<uuid:id>/favorite", views.DishFavoriteView.as_view()),
    path("me/water", views.WaterView.as_view()),
    path("me/home", views.HomeView.as_view()),
    path("me/days/<isodate:date>", views.DayView.as_view()),
    path("me/calendar", views.CalendarView.as_view()),
    path("me/progress", views.ProgressView.as_view()),
]
