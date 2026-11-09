# Nyam

> Scanne. Comprends. Mange mieux.

Application de suivi nutritionnel et sportif. La documentation produit est dans [docs/](docs/README.md).

## Structure

| Dossier | Rôle | Stack |
|---|---|---|
| [api/](api/) | API unique : **seule à faire les calculs** | Django, Django REST Framework, PostgreSQL, Celery + Redis |
| [mobile/](mobile/) | Application Android / iOS : **affiche seulement** | Flutter (version fixée par FVM) |
| [admin/](admin/) | Back-office multi-rôles | Next.js |
| [web/](web/) | Site vitrine, landing et page de paiement | Next.js |
| [docs/](docs/) | Documentation produit et technique | Markdown |

## Démarrage local

```bash
# Base de données et Redis
docker compose up -d

# API (http://localhost:8000, documentation de l'API sur /api/v1/docs/)
cd api
python -m venv .venv && .venv/Scripts/pip install -r requirements.txt
cp .env.example .env
.venv/Scripts/python manage.py migrate
.venv/Scripts/python manage.py runserver

# Mobile
cd mobile && fvm flutter pub get && fvm flutter run

# Admin (http://localhost:3001)
cd admin && pnpm install && pnpm dev

# Site web (http://localhost:3000)
cd web && pnpm install && pnpm dev
```
