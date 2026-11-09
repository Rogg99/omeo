"""
Réglages Django de l'API Nyam.

Règle d'architecture : l'API est la SEULE à faire les calculs
(objectifs, apports, quotas, points, challenges…). Les clients
(mobile, admin, web) se contentent d'afficher.
"""

from datetime import timedelta
from pathlib import Path

import environ

BASE_DIR = Path(__file__).resolve().parent.parent

env = environ.Env(DEBUG=(bool, False))
environ.Env.read_env(BASE_DIR / ".env")

SECRET_KEY = env("SECRET_KEY")
DEBUG = env("DEBUG")
ALLOWED_HOSTS = env.list("ALLOWED_HOSTS", default=["localhost", "127.0.0.1"])

DJANGO_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
]
THIRD_PARTY_APPS = [
    "rest_framework",
    "rest_framework_simplejwt",
    "corsheaders",
    "drf_spectacular",
]
LOCAL_APPS = [
    "apps.accounts",       # comptes, profils, consentements, parrainage
    "apps.nutrition",      # aliments, plats, objectifs, calculs nutritionnels
    "apps.meals",          # repas, analyses IA (OpenRouter), avis d'analyse
    "apps.activity",       # données santé, activités, poids, exercices, séances
    "apps.programs",       # programmes et challenges
    "apps.gamification",   # points, niveaux, badges, séries
    "apps.content",        # recettes, plantes, prévention, FAQ, légal
    "apps.billing",        # offres, quotas, abonnements, paiements
    "apps.notifications",  # push, centre de notifications, campagnes
    "apps.support",        # tickets de support
]
INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.locale.LocaleMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"

DATABASES = {"default": env.db("DATABASE_URL")}

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator", "OPTIONS": {"min_length": 10}},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

# Langues : 8 au lancement (voir docs/produit/features/10-profil-parametres-support.md)
LANGUAGE_CODE = "fr"
LANGUAGES = [
    ("fr", "Français"),
    ("en", "English"),
    ("es", "Español"),
    ("pt", "Português"),
    ("ar", "العربية"),
    ("zh-hans", "简体中文"),
    ("ja", "日本語"),
    ("de", "Deutsch"),
]
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
MEDIA_URL = "media/"
MEDIA_ROOT = BASE_DIR / "media"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# API
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": ["rest_framework.permissions.IsAuthenticated"],
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 20,
}
SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=15),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=30),
    "ROTATE_REFRESH_TOKENS": True,
}
SPECTACULAR_SETTINGS = {
    "TITLE": "Nyam API",
    "DESCRIPTION": "API unique de Nyam (mobile, admin, site). Tous les calculs sont faits ici.",
    "VERSION": "0.1.0",
}

CORS_ALLOWED_ORIGINS = env.list("CORS_ALLOWED_ORIGINS", default=[])

# Tâches asynchrones (analyses IA, notifications, validation des challenges)
CELERY_BROKER_URL = env("REDIS_URL", default="redis://localhost:6379/0")
CELERY_TIMEZONE = "UTC"

# IA
OPENROUTER_API_KEY = env("OPENROUTER_API_KEY", default="")
OPENROUTER_VISION_MODEL = env("OPENROUTER_VISION_MODEL", default="")
OPENROUTER_TEXT_MODEL = env("OPENROUTER_TEXT_MODEL", default="")
