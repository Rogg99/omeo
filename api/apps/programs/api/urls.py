"""Routes des programmes et challenges (préfixe /api/v1)."""

from __future__ import annotations

from django.urls import path

from apps.core.converters import register_converters
from apps.programs.api import views

register_converters()

urlpatterns = [
    path("programs", views.ProgramsView.as_view()),
    path("programs/<uuid:id>", views.ProgramDetailView.as_view()),
    path("programs/<uuid:id>/enroll", views.EnrollView.as_view()),
    path("me/program", views.ActiveProgramView.as_view()),
    path("me/program/tasks/<uuid:id>", views.ProgramTaskView.as_view()),
    path("challenges", views.ChallengesView.as_view()),
    path("challenges/<uuid:id>", views.ChallengeDetailView.as_view()),
    path("challenges/<uuid:id>/join", views.JoinChallengeView.as_view()),
    path("me/challenges", views.MyChallengesView.as_view()),
    path("me/challenges/<uuid:id>", views.MyChallengeDetailView.as_view()),
    path("me/challenges/<uuid:id>/days/<isodate:date>", views.ChallengeDayView.as_view()),
]
