"""Routes des notifications (préfixe /api/v1)."""

from __future__ import annotations

from django.urls import path

from apps.notifications.api import views

urlpatterns = [
    path("me/devices", views.DevicesView.as_view()),
    path("me/devices/<str:token>", views.DeviceDetailView.as_view()),
    path("me/notification-preferences", views.PreferencesView.as_view()),
    path("me/notifications", views.NotificationsView.as_view()),
    path("me/notifications/read", views.MarkReadView.as_view()),
    path("me/notifications/<uuid:id>/opened", views.OpenedView.as_view()),
]
