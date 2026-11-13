#!/bin/sh
# Démarrage de l'API : migrations, données de référence, puis démo si SEED_DEMO=true (jamais en production).
# Seul le serveur HTTP initialise la base ; le worker et le beat Celery démarrent directement.
set -eu
case "$*" in
  *runserver*|gunicorn*)
    python manage.py migrate --noinput
    python manage.py seed_reference
    if [ "${SEED_DEMO:-false}" = "true" ] && [ "${ENV:-development}" != "production" ]; then
      python manage.py seed_demo
    fi
    ;;
esac
exec "$@"
