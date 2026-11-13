"""
Réglages Django de l'API Omeo. Toute configuration vient de l'environnement (voir .env.example).

Règle d'architecture : l'API est la SEULE à faire les calculs (objectifs, apports, quotas, points, challenges…).
Les clients (mobile, admin, web) se contentent d'afficher.
"""

from pathlib import Path

import environ

BASE_DIR = Path(__file__).resolve().parent.parent

env = environ.Env(DEBUG=(bool, False))
environ.Env.read_env(BASE_DIR / ".env")

ENV = env("ENV", default="development")  # development | test | staging | production
IS_PRODUCTION = ENV == "production"

SECRET_KEY = env("SECRET_KEY")
DEBUG = env("DEBUG") and not IS_PRODUCTION
ALLOWED_HOSTS = env.list("ALLOWED_HOSTS", default=["localhost", "127.0.0.1"])

DJANGO_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "django.contrib.postgres",
]
THIRD_PARTY_APPS = [
    "rest_framework",
    "corsheaders",
    "drf_spectacular",
]
LOCAL_APPS = [
    "apps.core",  # socle : identifiants, erreurs, idempotence, audit, quatre yeux, événements
    "apps.accounts",  # comptes, profils, consentements, parrainage, équipe
    "apps.nutrition",  # aliments, plats, objectifs, calculs nutritionnels
    "apps.meals",  # repas, analyses IA (OpenRouter), avis d'analyse
    "apps.foodscan",  # moteur de scan des repas : IA guidée par les avis validés
    "apps.activity",  # données santé, activités, poids, exercices, séances
    "apps.programs",  # programmes et challenges
    "apps.gamification",  # points, niveaux, badges, séries
    "apps.content",  # recettes, plantes, prévention, FAQ, légal
    "apps.billing",  # offres, quotas, abonnements, paiements
    "apps.notifications",  # push, centre de notifications, campagnes
    "apps.support",  # tickets de support
]
INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

AUTH_USER_MODEL = "accounts.User"

MIDDLEWARE = [
    "apps.core.middleware.RequestIdMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "apps.core.middleware.SecurityHeadersMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.locale.LocaleMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
    "apps.core.middleware.MinimumAppVersionMiddleware",
]

ROOT_URLCONF = "config.urls"
APPEND_SLASH = False

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
DATABASES["default"]["CONN_MAX_AGE"] = env.int("DB_CONN_MAX_AGE", default=60)
DATABASES["default"]["CONN_HEALTH_CHECKS"] = True
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.redis.RedisCache",
        "LOCATION": env("REDIS_URL", default="redis://localhost:6379/0"),
        "KEY_PREFIX": "omeo",
    }
}

# ───────────────────────── Mots de passe ─────────────────────────
PASSWORD_HASHERS = [
    "django.contrib.auth.hashers.Argon2PasswordHasher",
    "django.contrib.auth.hashers.PBKDF2PasswordHasher",  # lecture des anciens hachages seulement
]
AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator", "OPTIONS": {"min_length": 10}},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
    {"NAME": "apps.accounts.validators.PasswordComplexityValidator"},
]

# ───────────────────────── Langues ─────────────────────────
# Code exposé « zh » ; Django utilise « zh-hans » en interne (voir apps/core/i18n.py).
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
LOCALE_PATHS = [BASE_DIR / "locale"]
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"

# ───────────────────────── Stockage S3 ─────────────────────────
# Voir apps/core/storage.py.
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
        "OPTIONS": {
            **_s3_common,
            "bucket_name": S3_PRIVATE_BUCKET,
            "default_acl": None,
            "querystring_auth": True,
            "querystring_expire": DOWNLOAD_URL_TTL_SECONDS,
            "custom_domain": None,
        },
    },
    # Médias des contenus publiés : lecture publique, cache long (servis par CDN en prod)
    "public": {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {
            **_s3_common,
            "bucket_name": S3_PUBLIC_BUCKET,
            "querystring_auth": False,
            "object_parameters": {"CacheControl": "public, max-age=31536000, immutable"},
        },
    },
    "staticfiles": {"BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage"},
}

# Chiffrement au repos des données de santé (Fernet). Première clé = chiffrement ; suivantes = déchiffrement seul.
FIELD_ENCRYPTION_KEYS = env.list("FIELD_ENCRYPTION_KEYS")

# ───────────────────────── API ─────────────────────────
TRUSTED_PROXY_COUNT = env.int("TRUSTED_PROXY_COUNT", default=1)

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": ["apps.accounts.authentication.SessionJWTAuthentication"],
    # Refus par défaut : chaque vue hérite d'AppAPIView, AdminAPIView ou PublicAPIView (apps/core/views.py).
    "DEFAULT_PERMISSION_CLASSES": ["rest_framework.permissions.IsAuthenticated"],
    "DEFAULT_THROTTLE_CLASSES": ["apps.core.throttles.UserThrottle"],
    "DEFAULT_THROTTLE_RATES": {
        "auth": "5/min",
        "register": "10/hour",
        "public_form": "5/hour",
        "public_read": "60/min",
        "user": "120/min",
        "staff": "600/min",
    },
    "NUM_PROXIES": TRUSTED_PROXY_COUNT,
    "EXCEPTION_HANDLER": "apps.core.errors.problem_exception_handler",
    "DEFAULT_RENDERER_CLASSES": ["rest_framework.renderers.JSONRenderer"],
    "DEFAULT_PARSER_CLASSES": ["rest_framework.parsers.JSONParser"],
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    "DEFAULT_PAGINATION_CLASS": None,
    "UNAUTHENTICATED_USER": "django.contrib.auth.models.AnonymousUser",
    "COERCE_DECIMAL_TO_STRING": False,
}
# Jetons : durées et rotation gérées par apps/accounts/tokens.py (liées au modèle Session).
SIMPLE_JWT = {
    "ALGORITHM": "HS256",
    "SIGNING_KEY": env("JWT_SIGNING_KEY", default=SECRET_KEY),
    "USER_ID_FIELD": "id",
    "USER_ID_CLAIM": "user_id",
    "JTI_CLAIM": "jti",
    "UPDATE_LAST_LOGIN": False,
}
SPECTACULAR_SETTINGS = {
    "TITLE": "Omeo API",
    "DESCRIPTION": "API unique d'Omeo (mobile, admin, site). Tous les calculs sont faits ici.",
    "VERSION": "1.1.3",
    "SCHEMA_PATH_PREFIX": "/api/v1",
    "SERVE_INCLUDE_SCHEMA": False,
    "COMPONENT_SPLIT_REQUEST": True,
}

# CORS fermé : aucun navigateur n'appelle l'API directement (web et admin passent par leur proxy serveur).
CORS_ALLOWED_ORIGINS = env.list("CORS_ALLOWED_ORIGINS", default=[])

# ───────────────────────── Authentification externe ─────────────────────────
GOOGLE_CLIENT_IDS = env.list("GOOGLE_CLIENT_IDS", default=[])
APPLE_CLIENT_IDS = env.list("APPLE_CLIENT_IDS", default=[])
TURNSTILE_SECRET_KEY = env("TURNSTILE_SECRET_KEY", default="")

# ───────────────────────── Emails ─────────────────────────
WEB_BASE_URL = env("WEB_BASE_URL", default="http://localhost")
DEFAULT_FROM_EMAIL = env("DEFAULT_FROM_EMAIL", default="Omeo <no-reply@omeo.app>")
EMAIL_BACKEND = env("EMAIL_BACKEND", default="django.core.mail.backends.console.EmailBackend")
EMAIL_HOST = env("EMAIL_HOST", default="localhost")
EMAIL_PORT = env.int("EMAIL_PORT", default=587)
EMAIL_HOST_USER = env("EMAIL_HOST_USER", default="")
EMAIL_HOST_PASSWORD = env("EMAIL_HOST_PASSWORD", default="")
EMAIL_USE_TLS = env.bool("EMAIL_USE_TLS", default=True)

# ───────────────────────── Celery ─────────────────────────
CELERY_BROKER_URL = env("REDIS_URL", default="redis://localhost:6379/0")
CELERY_TIMEZONE = "UTC"
CELERY_TASK_ACKS_LATE = True
CELERY_TASK_REJECT_ON_WORKER_LOST = True
CELERY_WORKER_PREFETCH_MULTIPLIER = 1
CELERY_TASK_ROUTES = {"apps.meals.tasks.*": {"queue": "ai"}}

# ───────────────────────── IA ─────────────────────────
OPENROUTER_API_KEY = env("OPENROUTER_API_KEY", default="")
OPENROUTER_VISION_MODEL = env("OPENROUTER_VISION_MODEL", default="")
OPENROUTER_TEXT_MODEL = env("OPENROUTER_TEXT_MODEL", default="")
OPENROUTER_BASE_URL = env("OPENROUTER_BASE_URL", default="https://openrouter.ai/api/v1")

# Scan des repas (apps/foodscan, voir docs/technique/foodscan.md)
FOODSCAN_VISION_MODEL = env("FOODSCAN_VISION_MODEL", default=OPENROUTER_VISION_MODEL)
FOODSCAN_TIMEOUT_S = env.float("FOODSCAN_TIMEOUT_S", default=30.0)
FOODSCAN_LOW_CONFIDENCE = env.float("FOODSCAN_LOW_CONFIDENCE", default=0.6)
FOODSCAN_MAX_DISH_HINTS = env.int("FOODSCAN_MAX_DISH_HINTS", default=40)
FOODSCAN_MAX_RULES = env.int("FOODSCAN_MAX_RULES", default=20)
# Une correction devient règle quand assez d'utilisateurs DISTINCTS l'ont faite
FOODSCAN_CONSENSUS_MIN_USERS = env.int("FOODSCAN_CONSENSUS_MIN_USERS", default=3)
FOODSCAN_CONSENSUS_MIN_AGREEMENT = env.float("FOODSCAN_CONSENSUS_MIN_AGREEMENT", default=0.6)

# ───────────────────────── Proxy et sécurité ─────────────────────────
# Derrière nginx et les proxys Next (web/admin) : liens générés sur le domaine d'origine
USE_X_FORWARDED_HOST = True
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_REFERRER_POLICY = "no-referrer"
X_FRAME_OPTIONS = "DENY"

if IS_PRODUCTION:
    SECURE_SSL_REDIRECT = True
    SECURE_HSTS_SECONDS = 63_072_000  # 2 ans
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_REDIRECT_EXEMPT = [r"^api/v1/health$"]

# ───────────────────────── Journaux ─────────────────────────
# JSON structuré avec request_id ; aucune donnée personnelle ni de santé (apps/core/logging.py).
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {"json": {"()": "apps.core.logging.JsonFormatter"}},
    "handlers": {"console": {"class": "logging.StreamHandler", "formatter": "json"}},
    "root": {"handlers": ["console"], "level": env("LOG_LEVEL", default="INFO")},
    "loggers": {
        "django.request": {"level": "WARNING"},
        "django.db.backends": {"level": "WARNING"},
    },
}

SENTRY_DSN = env("SENTRY_DSN", default="")
if SENTRY_DSN:
    import sentry_sdk
    from sentry_sdk.integrations.celery import CeleryIntegration
    from sentry_sdk.integrations.django import DjangoIntegration

    from apps.core.logging import sentry_before_send

    sentry_sdk.init(
        dsn=SENTRY_DSN,
        environment=ENV,
        integrations=[DjangoIntegration(), CeleryIntegration()],
        send_default_pii=False,
        traces_sample_rate=env.float("SENTRY_TRACES_SAMPLE_RATE", default=0.0),
        before_send=sentry_before_send,  # type: ignore[arg-type]
    )
