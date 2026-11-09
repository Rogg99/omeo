"""
Réglages Django de l'API Omeo.

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
    "apps.core",           # socle commun : stockage, erreurs, idempotence, audit…
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

# Stockage objet compatible S3 (MinIO en dev, S3 / R2 en prod). Voir apps/core/storage.py.
#   S3_ENDPOINT_URL        : adresse utilisée par l'API pour parler au stockage (réseau interne)
#   S3_PUBLIC_ENDPOINT_URL : adresse vue par les clients ; sert à signer les URL (le Host fait partie de la signature)
S3_ENDPOINT_URL = env("S3_ENDPOINT_URL", default=None)
S3_PUBLIC_ENDPOINT_URL = env("S3_PUBLIC_ENDPOINT_URL", default=S3_ENDPOINT_URL)
S3_REGION = env("S3_REGION", default="us-east-1")
S3_ACCESS_KEY_ID = env("S3_ACCESS_KEY_ID")
S3_SECRET_ACCESS_KEY = env("S3_SECRET_ACCESS_KEY")
S3_PRIVATE_BUCKET = env("S3_PRIVATE_BUCKET", default="omeo-private")
S3_PUBLIC_BUCKET = env("S3_PUBLIC_BUCKET", default="omeo-public")
S3_PUBLIC_BASE_URL = env("S3_PUBLIC_BASE_URL", default=f"{S3_PUBLIC_ENDPOINT_URL}/{S3_PUBLIC_BUCKET}")
UPLOAD_URL_TTL_SECONDS = 15 * 60
DOWNLOAD_URL_TTL_SECONDS = 60 * 60
UPLOAD_MAX_BYTES = 8 * 1024 * 1024

_s3_common = {
    "access_key": S3_ACCESS_KEY_ID,
    "secret_key": S3_SECRET_ACCESS_KEY,
    "endpoint_url": S3_ENDPOINT_URL,
    "region_name": S3_REGION,
    "signature_version": "s3v4",
    "addressing_style": "path",
    "file_overwrite": False,
}
STORAGES = {
    # Fichiers des utilisateurs : privés, servis uniquement par URL signée et temporaire
    "default": {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {**_s3_common, "bucket_name": S3_PRIVATE_BUCKET, "default_acl": None,
                    "querystring_auth": True, "querystring_expire": DOWNLOAD_URL_TTL_SECONDS,
                    "custom_domain": None},
    },
    # Médias des contenus publiés : lecture publique, cache long (servis par CDN en prod)
    "public": {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {**_s3_common, "bucket_name": S3_PUBLIC_BUCKET, "querystring_auth": False,
                    "object_parameters": {"CacheControl": "public, max-age=31536000, immutable"}},
    },
    "staticfiles": {"BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage"},
}

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
    "TITLE": "Omeo API",
    "DESCRIPTION": "API unique d'Omeo (mobile, admin, site). Tous les calculs sont faits ici.",
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

# Derrière nginx et les proxys Next (web/admin) : liens générés sur le domaine d'origine
USE_X_FORWARDED_HOST = True
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
