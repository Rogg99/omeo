# Image de l'API Omeo (utilisée aussi par le worker et le beat Celery)
FROM python:3.13-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

# --- Dev : code monté en volume, rechargement automatique ---
FROM base AS dev
CMD ["sh", "-c", "python manage.py migrate --noinput && python manage.py runserver 0.0.0.0:8000"]

# --- Prod ---
FROM base AS prod
RUN useradd --create-home omeo
COPY . .
RUN SECRET_KEY=build DATABASE_URL=sqlite:///tmp/build.db python manage.py collectstatic --noinput
USER omeo
CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "3"]
