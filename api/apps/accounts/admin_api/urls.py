"""Routes admin des comptes (préfixe /api/v1)."""

from __future__ import annotations

from django.urls import path

from apps.accounts.admin_api import dashboard, views

urlpatterns = [
    path("admin/me", views.AdminMeView.as_view()),
    path("admin/dashboard", dashboard.DashboardView.as_view()),
    path("admin/mfa/setup", views.MfaSetupView.as_view()),
    path("admin/team", views.TeamView.as_view()),
    path("admin/team/<uuid:id>", views.TeamMemberView.as_view()),
    path("admin/users", views.UsersView.as_view()),
    path("admin/users/<uuid:id>", views.UserDetailView.as_view()),
    path("admin/users/<uuid:id>/health", views.UserHealthView.as_view()),
    path("admin/users/<uuid:id>/actions", views.UserActionView.as_view()),
]
