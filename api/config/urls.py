"""Routes racine. Toute l'API est sous /api/v1 ; le schéma généré est comparé au contrat en CI (oasdiff)."""

from django.conf import settings
from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

from apps.core.api.views import HealthView

api_v1 = [
    path("health", HealthView.as_view()),
    path("schema/", SpectacularAPIView.as_view(), name="schema"),
    path("", include("apps.accounts.api.urls")),
]

urlpatterns = [path("api/v1/", include(api_v1))]

if settings.ENV != "production":
    api_v1.append(path("docs/", SpectacularSwaggerView.as_view(url_name="schema")))
    # Écrans de modération provisoires de foodscan, jamais exposés en production
    urlpatterns.append(path("django-admin/", admin.site.urls))
