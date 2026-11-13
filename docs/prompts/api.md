# Prompt — API (Django)

> Coller d'abord le [socle commun](README.md#socle-commun-à-coller-en-tête-de-chaque-prompt).

```text
LIVRABLE : l'API d'Omeo, dans api/. Django 6.1, DRF, PostgreSQL 17, Celery et Redis, drf-spectacular, simplejwt.
Elle tourne dans Docker (compose.yml) et est accessible sur http://api.localhost.

OBJECTIF : implémenter intégralement contracts/openapi.yaml (173 opérations), conformément à
docs/technique/modele-donnees.md et docs/technique/conventions-api.md. Le schéma généré
(/api/v1/schema/) doit être conforme au contrat : la CI le vérifie avec oasdiff et échoue en cas de
changement incompatible.

ARCHITECTURE (à respecter strictement) :
- Les apps existantes (accounts, nutrition, meals, activity, programs, gamification, content, billing,
  notifications, support) plus un nouveau paquet apps/core, qui contient :
  mixins (UUIDv7, horodatage), I18nText, problem+json, pagination, idempotence, permissions de rôle,
  journal d'audit, événements de domaine et throttles.
- Chaque app est découpée en couches :
  - models.py : données et contraintes uniquement ;
  - selectors.py : lectures optimisées (select_related et prefetch_related, sans N+1) ;
  - services.py : écritures et règles métier, transactionnelles, avec arguments nommés et types ;
  - serializers.py : entrée et sortie, sans logique métier ;
  - api/views.py et api/urls.py : vues minces qui appellent les services ;
  - tasks.py : Celery, idempotent ;
  - admin_api/ : les endpoints /admin/*.
- Calculs dans des modules purs, sans ORM, testables isolément : nutrition/calculations.py (métabolisme
  de Mifflin-St Jeor, dépense de base, objectifs, macros, eau, fibres, sel, ajustement selon l'activité),
  activity/met.py, gamification/rules.py, programs/rules.py (évaluation des règles contre DailySummary).
  Toutes les constantes viennent de Setting et sont mises en cache dans Redis.
- DailySummary est la projection matérialisée lue par tous les écrans. nutrition.services.recompute_day
  est appelé, dans la même transaction, après chaque écriture de repas, d'eau, d'activité, de poids
  ou de synchronisation santé.
- Les apps communiquent par services et événements de domaine (core/events.py, par exemple MealLogged ou
  DayRecomputed), jamais en important les vues ou les sérialiseurs d'une autre app.
- Typage strict avec mypy et django-stubs. Lint avec ruff (règles strictes) et formatage ruff.

CONTRÔLE D'ACCÈS (docs/technique/controle-acces.md, à appliquer à la lettre) :
- apps/accounts/permissions.py contient le catalogue des permissions et la correspondance avec les
  rôles (constante typée).
- Classes DRF dans apps/core/permissions.py :
  - HasPermission : lit `required_permission` sur la vue (ou `permission_map` par action) ;
  - RequiresStepUp : 401 step_up_required ;
  - RequiresVerifiedEmail ;
  - RequiresFeature : entitlement recalculé à chaque requête, jamais lu dans le JWT.
- Quatre yeux : un service ApprovalService (create, approve, reject, expire) avec une contrainte en
  base : celui qui décide n'est jamais celui qui demande. L'action est rejouée dans la transaction
  d'approbation. Réponse 202 avec ApprovalRequest.
- Les marqueurs x-permission, x-step-up, x-four-eyes, x-entitlement, x-quota et x-email-verified du
  contrat sont la spécification. Un test lit contracts/openapi.yaml et vérifie, pour CHAQUE
  opération, que la vue applique le marqueur correspondant :
  - pour x-permission, un test paramétré par rôle refusé ;
  - pour x-entitlement, un test avec un compte Free ;
  - pour x-step-up, un test sans step-up.
- Test d'accès par objet : pour chaque route /me/*, un utilisateur B obtient 404 sur la ressource de A.
- Un compte suspendu est refusé partout (403 account_suspended), sessions révoquées.

SÉCURITÉ :
- Mots de passe hachés avec Argon2. Mot de passe : au moins 10 caractères, avec une minuscule,
  une majuscule, un chiffre et un caractère spécial.
- JWT : accès de 15 min, renouvellement de 30 jours avec rotation et liste noire. Le rejeu d'un ancien
  jeton de renouvellement révoque toute la session. Session liée au modèle Session.
- Google : id_token vérifié via JWKS. Apple : identity token vérifié, avec le nonce.
- Staff : TOTP obligatoire (pyotp), codes de secours hachés, accès de 10 min, déconnexion après 30 min
  d'inactivité. Permissions par rôle déclarées sur chaque vue, plus un test par endpoint admin et par
  rôle refusé.
- Accès par objet : chaque requête /me/* est filtrée par request.user. Un objet appartenant à un autre
  utilisateur renvoie 404.
- Limites de débit (throttles) comme dans conventions-api.md. Captcha Turnstile vérifié côté serveur
  sur les formulaires publics.
- Uploads : URL présignées vers un stockage S3 (django-storages et boto3 ; MinIO en dev, à ajouter
  dans compose.yml). Ensuite : vérification du type réel (magic bytes), taille de 8 Mo au plus,
  retrait des métadonnées EXIF (Pillow), et conversion des images HEIC en JPEG.
- Données de santé (poids, mesures) chiffrées au repos. Leur consultation dans l'admin est journalisée.
- AuditLog sur toute action du staff, avec l'état avant et après.
- Webhooks : signature JWS Apple (ASSN v2), jeton OIDC Pub/Sub pour Google RTDN, HMAC pour l'agrégateur.
  Événements idempotents (WebhookEvent).
- Production : DEBUG désactivé, HSTS, SECURE_* activés, en-têtes de sécurité, CORS fermé, et aucune
  donnée personnelle ou de santé dans les journaux (journaux JSON structurés avec request_id).
- Sentry, avec un filtre qui retire les données personnelles.

IDEMPOTENCE ET HORS CONNEXION :
- Idempotency-Key obligatoire sur les POST du mobile marqués dans le contrat. La réponse est stockée
  24 h (Redis et une table). Même clé avec un autre corps : 409 idempotency_conflict.
- Journée locale calculée à partir de Profile.timezone, mis à jour par l'en-tête X-Timezone.

IA (OpenRouter, D3, D37) :
- Le moteur d'analyse existe déjà : apps/foodscan (docs/technique/foodscan.md, à lire en entier). Ne le
  réécris pas et ne crée pas de second client IA. Il fournit le client OpenRouter (délai, nouvelles
  tentatives, coupe-circuit, coût), la sortie JSON stricte (ScanOutput), le prompt versionné
  (PROMPT_VERSION), le contexte géographique, les fiches de plats et les règles de confusion.
- meals appelle uniquement les services de foodscan, jamais ses vues :
  services.scan_photo(image_bytes, country=Profile.country, locale) et services.scan_text(...).
  Le pays vient toujours de Profile.country, jamais d'une position GPS.
- La file Celery « ai » exécute l'analyse. Statuts : queued, processing, succeeded ou failed.
  Analysis enregistre les champs de ScanResult (modèle, prompt_version, tokens, coût, réponse brute,
  contexte injecté). result.low_confidence alimente l'invitation à vérifier ; result.counted_in_quota
  décide du décompte.
- Avis : PUT /me/analyses/{id}/feedback appelle services.submit_review dès qu'un plat corrigé est fourni
  (motif wrong_dish). Le commentaire libre est enregistré mais n'entre jamais dans un prompt.
- Alternatives : Analysis.alternatives reprend ScanOutput.alternatives, rapprochées du catalogue de plats
  (dish null si aucun plat ne correspond), avec probability_percent arrondi par l'API.
  POST /me/analyses/{id}/dish remplace le plat par un plat du catalogue : composition type rechargée,
  items et totals recalculés, avis wrong_dish enregistré via submit_review, sans appel IA ni quota.
- corrected_dish_label, alternatives et POST /me/analyses/{id}/dish sont des évolutions du contrat
  proposées dans contracts/CHANGES.md : ne les implémente qu'une fois validées.
- Rapprochement des ingrédients : recherche trigram et unaccent sur Food.name et Food.aliases, plus
  un seuil. Les valeurs nutritionnelles viennent toujours de Food.
- Le quota est décompté dans la transaction (SELECT FOR UPDATE sur QuotaUsage) et rendu si l'analyse
  échoue. Un échec de type blurry ou no_food ne compte pas.
- Coût (tokens et USD) enregistré pour le tableau de bord.
- Traduction automatique des contenus pour l'admin (modèle texte), proposée et jamais publiée directement.

ABONNEMENTS :
- Google Play Developer API (purchases.subscriptionsv2), App Store Server API et StoreKit 2 (JWS),
  et un agrégateur web derrière une interface PaymentProvider. L'implémentation par défaut est un
  adaptateur Stripe, interchangeable (question ouverte n°3).
- L'Entitlement est calculé par billing.services.entitlement_for(user) et mis en cache, puis invalidé à
  chaque événement. Il fusionne l'essai, les abonnements et les jours offerts. Une permission DRF
  RequiresFeature("programs") renvoie 403 plan_required.
- Parrainage : validé quand le filleul a vérifié son email et enregistré au moins un repas, avec une
  empreinte d'appareil différente de celle du parrain et une limite de 35 jours.

TÂCHES PLANIFIÉES (Celery beat), toutes idempotentes :
- clôture des journées et des challenges, par fuseau horaire ;
- remise à zéro des quotas ;
- calcul des séries ;
- rappels (repas, eau, pesée), qui respectent les heures calmes, la limite de 3 push par jour,
  les préférences et la règle « pas de rappel si le repas est déjà enregistré » ;
- analyses croisées hebdomadaires et bilans de prévention ;
- envoi des campagnes (FCM HTTP v1 via firebase-admin) ;
- purge des comptes à J+30 ;
- exports de données ;
- expiration des essais ;
- rapprochement des abonnements avec les stores.

LANGUES :
- Accept-Language, avec repli vers en, puis fr.
- Le code de langue exposé est « zh » ; aligne LANGUAGES dans settings.py (zh-hans en interne).
- Les messages d'erreur problem+json sont traduits avec gettext.

PERFORMANCE :
- Index décrits dans le modèle de données. Contrainte unique partielle pour le programme actif.
- Les endpoints d'agrégation (/me/home, /me/days/{date}, /me/activity) font au plus 8 requêtes SQL.
  Un test le vérifie avec assertNumQueries.
- Réponse en moins de 150 ms au 95e percentile en local, hors IA.
- Pagination par curseur pour l'app, par page pour l'admin.

SEEDERS (docs/technique/seeders.md, à appliquer à la lettre) :
- seed_reference : idempotente, lancée à chaque démarrage après migrate. Elle lit api/seeds/reference/
  (réglages, offres, quotas, points, niveaux, badges, villes, textes légaux) et n'écrase jamais une
  valeur existante. En production, elle refuse de publier les textes légaux s'il reste des [crochets].
- create_superadmin : commande interactive (mot de passe, QR de la double authentification).
- import_foods (WAFCT 2019, sel = sodium × 2,5, source et identifiant d'origine conservés) et
  import_content (contenus importés en brouillon).
- seed_demo [--reset] [--seed 42] : interdite en production, déterministe, passe par les vrais
  services. Comptes et données de docs/technique/seeders.md, avec les mêmes données que les maquettes.
- Démarrage du conteneur api : migrate, seed_reference, puis seed_demo si SEED_DEMO=true.
  Ajoute SEED_DEMO=true dans .env.example.

TESTS (pytest-django, factory_boy, freezegun) :
- Couverture d'au moins 90 % sur services et calculations.
- Cas limites : changement de jour local et de fuseau, quotas concurrents, rejeu d'idempotence,
  jeton de renouvellement réutilisé, webhooks dupliqués ou désordonnés, et chaque refus de rôle.
- Tests du contrat avec schemathesis sur le schéma généré.

OUTILLAGE À LIVRER :
- pyproject.toml (ruff, mypy, pytest) et pre-commit.
- GitHub Actions : lint, typage, tests, oasdiff contre contracts/openapi.yaml, et build Docker.
- Mise à jour de .env.example et du README de l'API.

ORDRE : socle core et auth en premier, car les clients en dépendent. Ensuite seed_reference et
seed_demo (squelette, enrichi à chaque module), pour que l'API ait tout de suite de vraies données.
Puis les modules dans l'ordre du socle commun ; chaque module complète seed_demo avec ses données. Après chaque module : migrations, tests, vérification du schéma, commit.
```
