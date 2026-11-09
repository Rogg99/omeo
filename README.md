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

Tout tourne dans Docker sauf le mobile. nginx sert de point d'entrée unique :

| URL | Service |
|---|---|
| http://localhost | Site web |
| http://admin.localhost | Back-office |
| http://api.localhost | API, pour le dev et le mobile (doc sur `/api/v1/docs/`). Le web et l'admin ne l'exposent jamais : ils relaient `/api/...` côté serveur |
| http://10.0.2.2 | API depuis l'émulateur Android |

```bash
cp api/.env.example api/.env
docker compose up -d --build        # les migrations s'appliquent au démarrage de l'api
docker compose logs -f api          # suivre les logs d'un service

# Commandes Django
docker compose exec api python manage.py makemigrations
docker compose exec api python manage.py createsuperuser
docker compose exec api python manage.py shell

# Après ajout d'une dépendance (requirements.txt ou package.json)
docker compose up -d --build api worker beat   # ou admin / web

# Mobile (hors Docker)
cd mobile && fvm flutter pub get && fvm flutter run
```
