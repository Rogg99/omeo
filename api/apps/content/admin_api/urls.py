"""Routes admin éditoriales (préfixe /api/v1)."""

from __future__ import annotations

from django.urls import path

from apps.content.admin_api import views

urlpatterns = [
    path("admin/content/<str:type>", views.ContentListView.as_view()),
    path("admin/content/<str:type>/<uuid:id>", views.ContentDetailView.as_view()),
    path("admin/content/<str:type>/<uuid:id>/transition", views.ContentTransitionView.as_view()),
    path("admin/content/<str:type>/<uuid:id>/revisions", views.ContentRevisionsView.as_view()),
    path("admin/content/<str:type>/<uuid:id>/translate", views.ContentTranslateView.as_view()),
    path("admin/translations", views.TranslationCoverageView.as_view()),
    path("admin/media", views.MediaUploadView.as_view()),
]
