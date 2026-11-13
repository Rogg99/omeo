"""Routes admin du socle (préfixe /api/v1/admin)."""

from __future__ import annotations

from django.urls import path

from apps.core.admin_api import views

urlpatterns = [
    path("admin/approvals", views.ApprovalsView.as_view()),
    path("admin/approvals/<uuid:id>/decision", views.ApprovalDecisionView.as_view()),
    path("admin/approvals/<uuid:id>/cancel", views.ApprovalCancelView.as_view()),
    path("admin/audit", views.AuditView.as_view()),
    path("admin/settings", views.SettingsView.as_view()),
]
