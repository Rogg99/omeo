# API Omeo (Django)

API unique d'Omeo, pour le mobile, l'admin et le site. Elle fait **tous** les calculs ; les clients affichent.
Contrat : [contracts/openapi.yaml](../contracts/openapi.yaml). Conventions : [docs/technique/conventions-api.md](../docs/technique/conventions-api.md).

## Démarrage

```bash
cp api/.env.example api/.env   # puis renseigner FIELD_ENCRYPTION_KEYS (commande dans le fichier)
docker compose up
```

Au démarrage, le conteneur `api` lance `migrate`, `seed_reference`, puis `seed_demo` si `SEED_DEMO=true`
(jamais en production). L'API répond sur http://api.localhost/api/v1, la documentation sur `/api/v1/docs/`
(hors production).

Premier compte d'administration : `docker compose exec api python manage.py create_superadmin --email …`
(mot de passe demandé, QR de la double authentification affiché).

## Architecture

| Couche | Fichier | Rôle |
|---|---|---|
| Données | `models.py` | champs et contraintes uniquement |
| Lectures | `selectors.py` | requêtes optimisées, sans N+1 |
| Écritures | `services.py` | règles métier transactionnelles, arguments nommés |
| Calculs | `calculations.py`, `entitlements.py`, `rules.py`, `met.py` | modules purs, sans ORM |
| Entrée/sortie | `serializers.py` | validation et forme des réponses, sans logique |
| HTTP | `api/views.py`, `api/urls.py`, `admin_api/` | vues minces |
| Asynchrone | `tasks.py` | tâches Celery idempotentes (file `ai` pour l'IA) |

Socle commun (`apps/core`) : UUID v7 et horodatage, `I18nText`, erreurs problem+json, pagination (curseur pour l'app,
page pour l'admin), `Idempotency-Key`, permissions (`HasPermission`, `RequiresStepUp`, `RequiresVerifiedEmail`,
`RequiresFeature`), journal d'audit, validation à quatre yeux, événements de domaine, limites de débit, réglages en
cache, chiffrement des données de santé, journaux JSON sans données personnelles.

Les applications communiquent par services et événements (`apps/core/events.py`), jamais par leurs vues ou leurs
sérialiseurs.

## Contrôle d'accès

- Catalogue des permissions et rôles : `apps/accounts/permissions.py` (constante relue en revue).
- Toute vue hérite de `PublicAPIView`, `AppAPIView` ou `AdminAPIView` (`apps/core/views.py`) : refus par défaut.
- `tests/test_contract_access.py` lit le contrat et vérifie chaque marqueur (`x-permission`, `x-step-up`,
  `x-email-verified`, `x-entitlement`, `Idempotency-Key`) sur chaque opération, avec un test par rôle refusé.

## Qualité

```bash
pip install -r requirements-dev.txt
ruff check . && ruff format --check . && mypy .
pytest --cov                     # couverture ≥ 90 % sur services et calculs
python manage.py spectacular --file /tmp/schema.yaml --validate
```

La CI (`.github/workflows/api.yml`) lance le lint, le typage, les tests, la vérification des migrations,
`oasdiff` contre le contrat et le build Docker.

## Variables d'environnement

Toutes sont documentées dans [.env.example](.env.example).
