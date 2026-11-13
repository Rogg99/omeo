"""Routes admin du support (préfixe /api/v1)."""

from __future__ import annotations

from django.urls import path

from apps.support.admin_api import views

urlpatterns = [
    path("admin/tickets", views.TicketsView.as_view()),
    path("admin/tickets/<uuid:id>", views.TicketDetailView.as_view()),
    path("admin/tickets/<uuid:id>/messages", views.TicketMessagesView.as_view()),
    path("admin/reply-templates", views.ReplyTemplatesView.as_view()),
]
