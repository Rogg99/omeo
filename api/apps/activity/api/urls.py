"""Routes activity (préfixe /api/v1)."""

from __future__ import annotations

from django.urls import path

from apps.activity.api import views

urlpatterns = [
    path("me/weights", views.WeightsView.as_view()),
    path("me/weights/<uuid:id>", views.WeightDetailView.as_view()),
    path("me/health/connection", views.HealthConnectionView.as_view()),
    path("me/health/sync", views.HealthSyncView.as_view()),
    path("me/activity", views.ActivityOverviewView.as_view()),
    path("me/activities", views.ActivitiesView.as_view()),
    path("me/activities/<uuid:id>", views.ActivityDetailView.as_view()),
    path("me/activities/<uuid:id>/merge", views.ActivityMergeView.as_view()),
    path("me/insights", views.InsightsView.as_view()),
    path("exercises", views.ExercisesView.as_view()),
    path("exercises/<uuid:id>", views.ExerciseDetailView.as_view()),
    path("workouts", views.WorkoutsView.as_view()),
    path("workouts/<uuid:id>", views.WorkoutDetailView.as_view()),
    path("workouts/<uuid:id>/download", views.WorkoutDownloadView.as_view()),
    path("me/workout-sessions", views.WorkoutSessionsView.as_view()),
]
