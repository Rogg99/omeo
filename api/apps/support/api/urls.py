"""Routes du support et des exports (préfixe /api/v1)."""

from __future__ import annotations

from django.urls import path

from apps.support.api import views

urlpatterns = [
    path("support/tickets", views.TicketCreateView.as_view()),
    path("me/tickets", views.MyTicketsView.as_view()),
    path("me/tickets/<uuid:id>", views.MyTicketDetailView.as_view()),
    path("me/exports", views.ExportsView.as_view()),
]
