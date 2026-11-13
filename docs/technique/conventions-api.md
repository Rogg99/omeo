# Conventions de l'API

Ces règles s'appliquent à tous les endpoints de [contracts/openapi.yaml](../../contracts/openapi.yaml) et sont communes aux trois clients.

## Base
- Préfixe : `/api/v1`. Un changement incompatible crée `/api/v2`. Les ajouts de champs ne sont pas des changements incompatibles : les clients **ignorent les champs inconnus**.
- JSON en UTF-8, noms de champs en `snake_case`.
- Espaces de noms :
  - `/auth/*` : authentification ;
  - `/me/*` : données de l'utilisateur connecté ;
  - ressources publiques ou de catalogue : `/recipes`, `/plants`… ;
  - `/admin/*` : back-office, réservé au staff ;
  - `/webhooks/*` : fournisseurs externes.

## Authentification

| Client | Mécanisme |
|---|---|
| Mobile | JWT : jeton d'accès de 15 min et jeton de renouvellement de 30 jours, avec **rotation et détection de réutilisation**. Toute la session est révoquée si un ancien jeton de renouvellement est rejoué. Stockage : Keychain sur iOS, EncryptedSharedPreferences sur Android (`flutter_secure_storage`) |
| Web (page Abonnement) | Le serveur Next appelle `/auth/login` et range les jetons dans des **cookies httpOnly, Secure, SameSite=Lax**. Le navigateur ne voit jamais de jeton ni l'URL de l'API. Le proxy `/api/[...path]` ajoute `Authorization` et renouvelle les jetons de façon transparente |
| Admin | Même principe que le web, avec la double authentification (TOTP) obligatoire : `/auth/login` renvoie `mfa_required` et un `mfa_token`, puis `/auth/mfa/verify`. Jeton d'accès de 10 min, session de 12 h maximum, déconnexion après 30 min d'inactivité |

- `Authorization: Bearer <access>` sur tous les appels authentifiés.
- Autorisations : voir [controle-acces.md](controle-acces.md). Chaque opération `/admin/*` déclare une permission atomique (`x-permission`), et éventuellement `x-step-up` ou `x-four-eyes`. Côté app, les marqueurs sont `x-entitlement`, `x-quota` et `x-email-verified`. Un refus renvoie `403 forbidden_role`.

## En-têtes

| En-tête | Sens | Envoyé par |
|---|---|---|
| `Accept-Language` | Langue des textes renvoyés (contenus, messages, noms d'aliments) | tous les clients |
| `X-Timezone` | Fuseau IANA de l'appareil. L'API met à jour `Profile.timezone` s'il a changé | mobile |
| `X-Client` | `mobile/1.4.0 (android 15)`, `web/…`, `admin/…` | tous les clients |
| `Idempotency-Key` | UUID v4, **obligatoire** sur les `POST` qui créent une ressource depuis le mobile (repas, eau, poids, activité, analyse, séance). L'API garde la réponse 24 h et la renvoie telle quelle si la requête est rejouée | mobile |
| `X-Request-Id` | Renvoyé dans chaque réponse, à citer au support | API |

## Formats
- **Datetime** : ISO 8601 en UTC, par exemple `2026-11-09T12:30:00Z`.
- **Journée locale** : `date` au format `YYYY-MM-DD`. Elle est calculée par l'API, jamais par le client.
- **Unités** : métriques uniquement (`_g`, `_kg`, `_cm`, `_ml`, `_kcal`, `_m`, `_s`). Le mobile convertit en lb, ft ou oz pour l'affichage et la saisie (décision D23).
- **Nombres** : les quantités sont des nombres décimaux, arrondis par l'API à la précision d'affichage (kcal entiers, grammes à 0,1 près).
- **Argent** : `{ "amount_cents": 449, "currency": "USD" }`.
- **Texte traduit** : l'API renvoie une chaîne déjà résolue dans la langue demandée. Seuls les endpoints `/admin/*` renvoient l'objet complet `{"fr": …, "en": …}`.
- **Médias** : URL signées et temporaires, servies par le CDN. Les images sont fournies en plusieurs tailles (`{ "url", "width", "height", "blurhash" }`).

## Erreurs : `application/problem+json` (RFC 9457)

```json
{
  "type": "https://omeo.app/errors/quota_exceeded",
  "title": "Quota atteint",
  "status": 429,
  "code": "quota_exceeded",
  "detail": "Tu as utilisé tes 3 analyses du jour.",
  "errors": { "email": [{ "code": "invalid", "message": "Email invalide" }] },
  "meta": { "feature": "photo_analysis", "resets_at": "2026-11-10T00:00:00Z", "upgrade": true },
  "request_id": "01JC…"
}
```

- `code` est **stable** : les clients basent leur comportement sur `code`, jamais sur le texte. `detail` est traduit et peut être affiché tel quel.
- Codes principaux :

| HTTP | `code` |
|---|---|
| 400 | `validation_error` (détail par champ dans `errors`), `invalid_invite_code` |
| 401 | `not_authenticated`, `token_expired`, `invalid_credentials`, `mfa_required`, `step_up_required` (TOTP de plus de 15 min, action sensible) |
| 403 | `forbidden`, `forbidden_role`, `plan_required` (fonction réservée à Plus ; `meta.feature`), `email_not_verified`, `consent_required` (`meta.documents`), `account_suspended` (`meta.support_url`), `self_approval_forbidden` |
| 404 | `not_found` |
| 202 | (succès) action à quatre yeux : renvoie une `ApprovalRequest` en attente de validation |
| 409 | `conflict`, `already_enrolled`, `idempotency_conflict`, `approval_pending` (une demande identique est déjà en attente) |
| 422 | `analysis_rejected` (`meta.reason` : `blurry` ou `no_food`) |
| 426 | `upgrade_required` (version de l'app inférieure au minimum fixé dans l'admin) |
| 429 | `quota_exceeded` (`meta.resets_at`, `meta.upgrade`), `rate_limited` (`Retry-After`) |
| 5xx | `server_error`, `ai_unavailable` |

## Pagination
- **Listes de l'app** : par curseur. `?cursor=…&limit=20` (100 maximum) renvoie `{ "results": [], "next_cursor": "…" | null }`. Pas de `count`, pour rester rapide.
- **Listes de l'admin** : par page. `?page=1&page_size=25` renvoie `{ "results": [], "count": 1234, "page": 1, "page_size": 25 }`.
- **Filtres** : paramètres de requête simples. Tri : `?ordering=-created_at`, sur une liste de champs autorisés.

## Calculs et réponses « vue »
- Le client n'additionne, ne soustrait et n'arrondit rien. Les endpoints de lecture renvoient les valeurs **prêtes à afficher** : `remaining_kcal`, `percent`, `delta_vs_yesterday`, `trend`, `progress`…
- Une écriture qui change les totaux renvoie dans sa réponse les données recalculées dont l'écran a besoin. Par exemple, `POST /me/meals` renvoie le repas, plus `day` (le résumé du jour) et `rewards` (points ou badges gagnés). Le client n'a ainsi pas besoin d'un second appel.
- Les endpoints d'agrégation comme `GET /me/home` regroupent tout un écran en **un seul appel**.

## Asynchrone
- Analyse IA : `POST /me/analyses` renvoie `202` avec `status=queued`. Le client interroge ensuite `GET /me/analyses/{id}`, en suivant l'intervalle recommandé par `Retry-After`. Une analyse dure 2 à 8 s.
- Le mobile met en file d'attente ses écritures faites hors connexion, avec leur `Idempotency-Key`. Il affiche l'état « en cours de calcul » jusqu'à la réponse de l'API.

## Limitation du débit (rate limiting)

| Portée | Limite |
|---|---|
| `/auth/login`, `/auth/password/forgot`, `/auth/mfa/verify` | 5 par minute par IP et par compte, puis délai croissant |
| `/auth/register` | 10 par heure par IP |
| Formulaires publics (contact, suppression de compte) | 5 par heure par IP, plus un captcha (Cloudflare Turnstile) |
| Utilisateur connecté | 120 par minute |
| Admin | 600 par minute |

## Sécurité
- Seul HTTPS est accepté en production, avec HSTS. CORS est fermé : aucun navigateur n'appelle l'API directement.
- **Validation côté serveur**, avec des bornes sur tous les champs. Toutes les requêtes passent par l'ORM (aucun SQL construit à la main).
- **Contrôle d'accès par objet** : chaque requête `/me/*` est filtrée par `request.user`. Un identifiant qui appartient à un autre utilisateur renvoie 404, jamais 403, pour ne pas révéler son existence.
- Les secrets viennent de l'environnement. Les données de santé sont chiffrées au repos. Les journaux ne contiennent ni email complet, ni jeton, ni valeur de santé.
- Les webhooks ne sont acceptés qu'après vérification de leur signature : JWS Apple, Pub/Sub Google avec un jeton OIDC, et HMAC de l'agrégateur.
- **Version minimale de l'app** : `GET /app/config` renvoie `min_version`, et l'API répond `426` aux versions trop anciennes.

## Contrat et génération de code
- [contracts/openapi.yaml](../../contracts/openapi.yaml) est le **contrat cible**, écrit avant le code.
- Le schéma généré par drf-spectacular (`/api/v1/schema/`) doit lui être conforme. La CI compare les deux avec `oasdiff` et échoue en cas de changement incompatible.
- Lint du contrat, sans erreur ni avertissement : `npx @redocly/cli lint contracts/openapi.yaml` (règles dans `redocly.yaml`).
- Clients générés à partir du contrat, jamais modifiés à la main, à régénérer après chaque évolution :
  - TypeScript pour l'admin et le web (`openapi-typescript` et `openapi-fetch`) : `pnpm gen:api` dans `admin/` et `web/`, qui écrit `src/lib/api/schema.d.ts`. Le client typé est `api`, exporté par `src/lib/api`.
  - Dart pour le mobile (`openapi-generator`, générateur `dart-dio`, sérialisation `json_serializable`) : `bash tool/gen_api.sh` dans `mobile/`, qui écrit `packages/omeo_api`. Il faut Java 11 ou plus (`JAVA_HOME`, par exemple le JBR d'Android Studio) et FVM : Dart et Flutter passent toujours par `fvm dart` et `fvm flutter`, à la version de `mobile/.fvmrc`. La version du générateur est figée dans `mobile/openapitools.json`.
- Le générateur Dart ne gère pas les booléens `const` : décrire la valeur imposée dans `description`.
- Pendant le développement du front, un serveur fictif sert le contrat : `npx @stoplight/prism-cli mock contracts/openapi.yaml`.
