"""Routes des programmes et challenges (préfixe /api/v1)."""

from __future__ import annotations

from datetime import date

from django.urls import path, register_converter

from apps.programs.api import views


class IsoDateConverter:
    regex = r"\d{4}-\d{2}-\d{2}"

    def to_python(self, value: str) -> date:
        return date.fromisoformat(value)

    def to_url(self, value: date) -> str:
        return str(value)


register_converter(IsoDateConverter, "isodate")

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
