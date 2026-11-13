"""Routes admin des campagnes (préfixe /api/v1)."""

from __future__ import annotations

from django.urls import path

from apps.notifications.admin_api import views

urlpatterns = [
    path("admin/campaigns", views.CampaignsView.as_view()),
    path("admin/campaigns/audience", views.AudienceView.as_view()),
    path("admin/campaigns/<uuid:id>", views.CampaignDetailView.as_view()),
    path("admin/campaigns/<uuid:id>/<str:action>", views.CampaignActionView.as_view()),
]
