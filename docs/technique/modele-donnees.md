# Modèle de données

Toutes les entités de l'API, rangées par application Django (`api/apps/*`). Le contrat HTTP est dans [contracts/openapi.yaml](../../contracts/openapi.yaml) et les conventions dans [conventions-api.md](conventions-api.md).

## Règles communes

| Règle | Détail |
|---|---|
| Identifiant | `id` en UUID v7 (triable dans le temps), seul identifiant exposé. Jamais d'entier séquentiel dans l'API |
| Horodatage | `created_at` et `updated_at` sur toutes les tables (mixin `TimeStampedModel`), stockés en UTC |
| Journée | Champ `date` (type DATE) = journée **locale** de l'utilisateur, calculée par l'API à partir de `Profile.timezone` |
| Unités | Tout est stocké en métrique : g, kg, cm, ml, kcal, m, s. La conversion vers lb, ft ou oz est faite par le mobile, à l'affichage |
| Argent | `amount_cents` (entier) avec `currency` (toujours `USD` pour nos prix) |
| Traductions | Les champs traduits sont en JSONB `{"fr": "...", "en": "..."}` (type `I18nText`). Ordre de repli : langue demandée, puis anglais, puis français |
| Workflow éditorial | Contenus : `status` ∈ `draft`, `review`, `published`, `archived`. Seul `published` est visible dans l'app |
| Suppression | Données utilisateur : suppression réelle 30 jours après la demande (`User.deletion_scheduled_at`). Contenus : archivage |
| Données de santé | Chiffrées au repos (poids, mesures) via un champ chiffré. Consultation dans l'admin journalisée |

Légende : **PK** clé primaire, **FK** clé étrangère, **U** unique, **I** index, `?` facultatif.

---

## accounts — comptes, profils, consentements, parrainage, équipe

### User
| Champ | Type | Notes |
|---|---|---|
| id | uuid PK | |
| email | citext U | normalisé en minuscules |
| password | hash | Argon2. Vide si le compte est créé uniquement via Google ou Apple |
| email_verified_at | datetime? | |
| is_active | bool | `false` = suspendu |
| is_staff | bool | membre de l'équipe (accès admin) |
| locale | enum langue | `fr`, `en`, `es`, `pt`, `ar`, `zh`, `ja`, `de` |
| last_seen_at | datetime? | |
| deletion_requested_at | datetime? | |
| deletion_scheduled_at | datetime? | date de purge, à J+30 |

### SocialAccount
`id`, `user` FK, `provider` (`google` ou `apple`), `subject` (identifiant chez le fournisseur), `email?`. Unicité sur (`provider`, `subject`).

### Profile (1–1 avec User)
| Champ | Type | Notes |
|---|---|---|
| first_name, last_name | str | 2 à 60 caractères au total |
| birth_date | date | âge minimum : réglage de l'admin |
| sex | enum | `male`, `female` (nécessaire au calcul du métabolisme) |
| city | FK City? | |
| city_label | str? | texte libre si la ville n'est pas dans la liste |
| country | char(2) | ISO 3166, déduit de la ville ou de l'appareil |
| timezone | str | IANA, par exemple `Africa/Dakar`, envoyé par le mobile |
| height_cm | decimal(5,1) | 100 à 250 |
| current_weight_kg | decimal(5,2) | cache de la dernière pesée retenue |
| target_weight_kg | decimal(5,2) | |
| goals | array enum | `lose_weight`, `gain_muscle`, `eat_balanced`, `prevent_diabetes`, `prevent_hypertension` |
| activity_adjustment | bool | ajustement de l'objectif selon l'activité, `true` par défaut |
| avatar | image? | |
| unit_weight, unit_height, unit_volume | enum | `kg`/`lb`, `cm`/`ft`, `cl`/`oz` (préférences d'affichage) |
| theme | enum | `system`, `light`, `dark` |

### City
`id`, `name` (I18nText), `country` char(2), `timezone`, `is_suggested` (bool, pour Dakar, Abidjan, Lomé, Yaoundé…). Liste gérée dans l'admin.

### Session (appareil connecté)
`id`, `user` FK, `refresh_jti` U, `mfa_verified_at?` (staff), `device_name`, `platform` (`android`, `ios`, `web`, `admin`), `app_version`, `ip`, `last_used_at`, `revoked_at?`. Permet de « déconnecter cet appareil » ou « tous les appareils ».

### LegalDocument
`id`, `kind` (`terms`, `privacy`, `cookies`, `legal_notice`), `version` int, `body` (I18nText, en Markdown), `published_at?`, `requires_reaccept` bool. Unicité sur (`kind`, `version`).

### Consent
`id`, `user` FK, `kind` (`terms`, `privacy`, `health_data`, `marketing`), `document` FK LegalDocument?, `granted` bool, `ip`, `user_agent`, `created_at`. **Table en ajout seul** : l'état actuel est le dernier enregistrement par `kind`.

### ReferralCode
`id`, `user` 1–1, `code` U (10 caractères maximum, alphanumériques, en majuscules).

### Referral
`id`, `referrer` FK User, `referee` 1–1 User, `code` FK, `status` (`pending`, `validated`, `rejected`), `rejected_reason?` (`same_device`, `self`, `cap_reached`), `validated_at?`, `reward_days` int. Validé quand le filleul a confirmé son email et enregistré au moins un repas, et que l'empreinte d'appareil diffère de celle du parrain.

### DeviceFingerprint
`id`, `user` FK, `hash` I (empreinte hachée de l'appareil, anti-fraude du parrainage), `first_seen_at`.

### StaffRole
`user` FK, `role` (`superadmin`, `content`, `support`, `finance`, `moderation`). Une personne peut avoir plusieurs rôles. Les **permissions** ne sont pas en base : la correspondance rôle → permissions est une constante du code (`apps/accounts/permissions.py`, voir [controle-acces.md](controle-acces.md)). Un compte staff a la double authentification obligatoire : `TOTPDevice` (`user`, `secret` chiffré, `confirmed_at`) et des `RecoveryCode` hachés. `Session.mfa_verified_at` sert au step-up (TOTP de moins de 15 min).

### ApprovalRequest (validation à quatre yeux)
`id`, `kind` (`content_publish`, `campaign_schedule`, `plan_update`, `quota_update`, `refund`, `settings_nutrition`), `domain` (`content`, `finance`, `settings`), `payload` jsonb (action à rejouer), `diff` jsonb, `target_type`, `target_id`, `reason`, `requested_by` FK, `status` (`pending`, `approved`, `rejected`, `expired`, `canceled`), `decided_by` FK?, `decision_comment`, `decided_at?`, `expires_at` (J+7).
- Contrainte : `decided_by` est différent de `requested_by`.
- Une seule demande `pending` à la fois par cible (`target_type`, `target_id`, `kind`).
- À l'approbation, l'action est appliquée dans la même transaction, puis une entrée d'audit est écrite.

### AuditLog
`id`, `actor` FK User?, `action` (str, par exemple `user.suspend`), `target_type`, `target_id`, `before` jsonb, `after` jsonb, `ip`, `created_at`. En ajout seul. Inclut les consultations de données de santé dans l'admin (`health.view`).

### Setting (singleton clé/valeur typée)
`key` U, `value` jsonb, `updated_by`. Contient :
- les constantes de calcul ([règles métier](../produit/03-regles-metier.md)) ;
- le modèle et les instructions OpenRouter ;
- les features activées ;
- les langues actives ;
- la version minimale de l'app ;
- l'âge minimum ;
- les pays où le lien vers le paiement web est autorisé.

Valeurs mises en cache dans Redis.

---

## nutrition — aliments, plats, objectifs

### Food (aliment, valeurs pour 100 g)
| Champ | Type |
|---|---|
| name | I18nText |
| aliases | array str (noms locaux), index trigram |
| category | enum (céréales, tubercules, légumes, fruits, viandes, poissons, légumineuses, huiles, boissons, épices, autre) |
| kcal, protein_g, carbs_g, sugars_g, fat_g, saturated_fat_g, fiber_g, salt_g | decimal |
| default_portion_g | decimal? |
| source | str (table de référence, par exemple FAO/INFOODS West Africa) |
| status | workflow |

### Dish (plat du catalogue)
`id`, `name` I18nText, `aliases` array (« autres noms », alimentés depuis les avis), `country` char(2), `standard_portion_g`, `image?`, `recipe` FK Recipe?, `status`. Valeurs nutritionnelles calculées et mises en cache (`nutrients_per_100g` jsonb), recalculées à chaque modification de la composition.

### DishComponent
`dish` FK, `food` FK, `grams` (pour une portion standard). Unicité sur (`dish`, `food`).

### NutritionTarget (objectifs datés)
| Champ | Notes |
|---|---|
| user FK, `valid_from` date | une ligne par recalcul ; l'objectif d'un jour donné est la dernière ligne avec `valid_from` ≤ ce jour |
| bmr_kcal, tdee_kcal, base_kcal | métabolisme de base, dépense de base, objectif de base |
| protein_g, carbs_g, fat_g, fiber_g, salt_max_g, water_ml | |
| computed_from | jsonb : poids, taille, âge, sexe, objectifs et constantes utilisés (pour l'audit) |

L'objectif ajusté du jour (base + activité) est calculé dans `DailySummary`.

### WaterEntry
`id`, `user`, `date`, `amount_ml` (une valeur négative annule un ajout), `created_at`, `client_request_id` (unique par utilisateur).

### DailySummary (projection matérialisée par utilisateur et par jour)
`user` FK, `date`, U(`user`, `date`). Contient :
- l'objectif : `target_kcal` (ajusté), plus les objectifs de macros, d'eau, de fibres et de sel ;
- la consommation : `consumed_kcal`, `protein_g`, `carbs_g`, `fat_g`, `fiber_g`, `salt_g`, `sugars_g`, `water_ml` ;
- l'activité : `burned_kcal`, `active_kcal`, `steps`, `distance_m`, `active_minutes` ;
- `meals_count` et `is_complete` (au moins 3 repas).

Recalculé de façon idempotente par `nutrition.services.recompute_day(user, date)` après chaque écriture (repas, eau, activité, poids, synchronisation santé). **C'est la source de toutes les lectures** : accueil, journal, progression, challenges, points. Aucun agrégat n'est calculé à la volée sur les tables brutes.

---

## meals — repas, analyses IA, avis

### Upload
`id`, `user` FK, `kind` (`meal_photo`, `support_attachment`, `avatar`), `storage_key`, `content_type`, `size`, `status` (`pending`, `ready`, `rejected`), `expires_at`. Le téléversement se fait directement vers le stockage S3 par URL présignée. L'API vérifie ensuite le type réel du fichier, sa taille (8 Mo maximum) et retire les métadonnées EXIF (dont la position GPS).

### Analysis (analyse IA)
| Champ | Notes |
|---|---|
| user FK, `kind` | `photo` ou `text` (la saisie vocale est transcrite sur l'appareil puis envoyée comme `text`) |
| upload FK?, `input_text?` | |
| status | `queued`, `processing`, `succeeded`, `failed` |
| failure_reason? | `blurry`, `no_food`, `unsupported`, `provider_error`, `timeout` |
| model, prompt_version | traçabilité |
| raw_response | jsonb, réponse brute de l'IA (visible dans l'admin) |
| dish_guess FK Dish?, `dish_label` | |
| confidence | 0 à 1 ; en dessous du seuil (réglage), `low_confidence = true` |
| items | jsonb : liste de `{food_id, label, grams, confidence}` après rapprochement avec la base |
| tokens_in, tokens_out, cost_usd_micros | coût de l'IA, pour le tableau de bord |
| counted_in_quota | bool, `false` si l'analyse a échoué |
| client_request_id | U(`user`, `client_request_id`), pour l'idempotence |

### Meal
`id`, `user` FK, `date` I, `eaten_at` datetime, `meal_type` (`breakfast`, `lunch`, `snack`, `dinner`), `source` (`photo`, `text`, `dish`, `recipe`, `duplicate`, `program`), `analysis` FK?, `dish` FK?, `recipe` FK?, `photo` FK Upload?, `title` (str, nom affiché), les totaux calculés (`kcal`, `protein_g`, `carbs_g`, `fat_g`, `fiber_g`, `salt_g`, `sugars_g`), `client_request_id` U par utilisateur. Index sur (`user`, `date`).

### MealItem
`meal` FK, `food` FK, `grams`, `label` (nom affiché), les nutriments calculés. Les valeurs viennent **toujours** de `Food`, jamais de l'IA.

### FavoriteDish
`user`, `dish`, U.

### AnalysisFeedback
`id`, `analysis` 1–1, `user`, `rating` (`up` ou `down`), `reason?` (`wrong_dish`, `missing_ingredient`, `wrong_quantities`, `other`), `comment?` (1 000 caractères maximum), `corrected_items` jsonb (ce que l'utilisateur a validé), `moderation_status` (`new`, `handled`, `ignored`), `handled_by?`, `handled_action?` (`dish_created`, `food_created`, `alias_added`, `defect_reported`), `handled_at?`.

---

## activity — santé, activités, poids, exercices, séances

### HealthConnection
`user` 1–1, `source` (`health_connect` ou `apple_health`), `granted_types` array, `last_sync_at`.

### DailyActivity
`user`, `date`, `source` (`health_connect`, `apple_health`, `manual`), `steps`, `distance_m`, `active_kcal`, `total_burned_kcal?`. U(`user`, `date`, `source`). Envoyé en **totaux par jour**, par le mobile.

### Activity (séance importée ou saisie)
`id`, `user`, `date`, `started_at`, `duration_s`, `type` (`walking`, `running`, `football`, `dancing`, `cycling`, `strength`, `swimming`, `other`), `intensity?` (`light`, `moderate`, `vigorous`), `kcal` (importé, ou estimé par l'API avec la méthode des METs), `avg_hr?`, `source`, `external_id?` (U par source), `merged_into` FK Activity?, `workout_session` FK?.

### WeightEntry
`id`, `user`, `date`, `weight_kg` (chiffré), `source` (`manual`, `health_connect`, `apple_health`), `measured_at`. Une seule valeur retenue par jour : la saisie manuelle l'emporte sur l'import (`is_effective` est calculé). Chaque nouvelle valeur retenue relance le recalcul de `NutritionTarget`.

### Exercise
`name` I18nText, `instructions` I18nText, `video` (fichier HLS), `subtitles` (une piste VTT par langue), `thumbnail`, `muscles` array, `level` (`beginner`, `intermediate`, `advanced`), `equipment` array (vide = sans matériel), `met` (pour estimer les calories), `is_free` bool, `status`.

### Workout (séance guidée)
`name`, `description`, `goal` (`cardio`, `strength`, `mobility`), `level`, `duration_s` (calculé), `cover`, `is_free`, `status`.

### WorkoutStep
`workout` FK, `order`, `exercise` FK, `mode` (`time` ou `reps`), `duration_s?`, `reps?`, `rest_s`.

### WorkoutSession (séance faite par l'utilisateur)
`id`, `user`, `workout`, `started_at`, `completed_at?`, `completed_steps` int, `kcal` (calculé par l'API), `points_awarded`, `client_request_id` U.

### Insight (analyse croisée, Plus)
`user`, `week_start` date, `kind`, `message` I18nText rendu, `data` jsonb, `read_at?`.

---

## programs — programmes et challenges

### Program
`name`, `description` I18nText, `goal`, `weeks` int, `cover`, `badge` FK?, `points` int, `status`.

### ProgramDay
`program` FK, `day_index` (1 à N), `tip` I18nText?, `workout` FK?, `suggested_recipes` M2M Recipe.

### ProgramTask
`day` FK, `label` I18nText, `rule` FK Rule? (vide = la tâche est cochée par l'utilisateur).

### Enrollment (participation à un programme)
`id`, `user`, `program`, `started_on` date, `status` (`active`, `completed`, `abandoned`, `replaced`), `ended_at?`. **Contrainte unique partielle** : un seul `active` par utilisateur.

### TaskCompletion
`enrollment`, `task`, `date`, `done` bool, `source` (`auto` ou `manual`).

### Rule (règle de validation, partagée par les challenges et les tâches)
`metric` (`water_ml`, `steps`, `active_minutes`, `meals_count`, `protein_g`, `kcal_within_target`, `workout_completed`, `weight_logged`, `manual`), `operator` (`gte` ou `lte`), `threshold` decimal, `period` (`day`). Évaluée **uniquement** contre `DailySummary` et les tables d'activité.

### Challenge
`name`, `description`, `duration_days` (7 à 30), `rule` FK, `success_threshold` (0,8 par défaut), `points_per_day`, `points_completion`, `badge` FK?, `cover`, `status`.

### ChallengeParticipation
`id`, `user`, `challenge`, `started_on`, `status` (`active`, `succeeded`, `failed`, `abandoned`), `success_rate` (calculé). En Free, l'API refuse une deuxième participation active (quota `challenges_active`).

### ChallengeDay
`participation`, `date`, `status` (`pending`, `success`, `failed`), `value` decimal? (mesure du jour), `source`. U(`participation`, `date`). Évalué au fil de la journée (après chaque `recompute_day`) puis figé à la fin de la journée locale par une tâche Celery.

---

## gamification — points, niveaux, badges, séries

### PointRule
`action` U (`meal_logged`, `day_complete`, `water_goal`, `kcal_goal`, `steps_goal`, `workout_completed`, `weight_logged`, `challenge_day`, `challenge_completed`, `program_completed`, `feedback_given`, `referral_validated`), `points`, `cap` int?, `cap_period` (`day`, `week`, `none`). Modifiable dans l'admin.

### PointEvent
`id`, `user`, `action`, `points`, `date`, `ref_type`, `ref_id`. U(`user`, `action`, `ref_type`, `ref_id`) : la même action ne rapporte pas deux fois. Les plafonds sont vérifiés dans une transaction.

### Level
`rank` U, `name` I18nText, `min_points`, `icon`.

### Badge
`code` U, `family` (`streak`, `nutrition`, `hydration`, `activity`, `challenge`, `program`, `discovery`, `referral`), `name`, `description`, `icon`, `condition` jsonb (`{"metric": "streak_days", "gte": 7}`), `bonus_points`, `status`.

### UserBadge
`user`, `badge`, `progress` decimal (0 à 1), `earned_at?`. U(`user`, `badge`).

### UserStats (projection)
`user` 1–1, `total_points`, `level` FK, `current_streak`, `best_streak`, `streak_freezes_used_week`, `last_meal_date`.

---

## content — recettes, plantes, prévention, FAQ

### Recipe
`name`, `description`, `country`, `prep_minutes`, `cook_minutes`, `difficulty` (`easy`, `medium`, `hard`), `servings`, `image`, `tags` array (`healthy`, `vegetarian`, `high_protein`, `low_salt`…), `goals` array, `is_free` bool, `nutrients_per_serving` jsonb (calculé à partir des ingrédients), `status`.

### RecipeIngredient
`recipe`, `food` FK, `grams`, `display` I18nText (par exemple « 2 plantains mûrs »), `order`.

### RecipeStep
`recipe`, `order`, `text` I18nText, `image?`.

### FavoriteRecipe, FavoritePlant
`user` + contenu, U.

### Plant
`common_name` I18nText, `scientific_name`, `image`, `tags` array (`traditional_use`, `nutritional_support`, `caution`), `traditional_use`, `nutritional_benefits`, `precautions` (I18nText, en Markdown), `contraindications` array (`pregnancy`, `breastfeeding`, `hypertension`, `diabetes_medication`…), `related_recipes` M2M, `status`.

### PreventionTip
`code` U, `topic` (`water`, `salt`, `sugar`, `fiber`, `activity`, `protein`), `title`, `body`, `trigger` jsonb (par exemple `{"metric": "salt_g", "op": "gte", "value": 5, "consecutive_days": 3}`), `tier` (`free` ou `plus`), `related_recipes`, `related_plants`, `status`.

### UserTip (conseil déclenché)
`user`, `tip`, `triggered_on` date, `data` jsonb, `read_at?`, `dismissed_at?`.

### WeeklyReport (Plus)
`user`, `week_start`, `data` jsonb, `generated_at`.

### FaqItem
`category`, `question`, `answer` (I18nText), `order`, `audience` (`app`, `web`, `both`), `status`.

### ContentRevision
`content_type`, `object_id`, `author`, `snapshot` jsonb, `created_at`. Historique des versions de tous les contenus éditoriaux.

---

## billing — offres, quotas, abonnements, paiements

### Plan
`code` U (`free`, `trial`, `plus_monthly`, `plus_annual`), `name` I18nText, `price_cents`, `currency` (`USD`), `interval` (`month`, `year`, `none`), `is_featured`, `store_product_ids` jsonb (`{"google": "...", "apple": "..."}`), `web_price_id?`, `active`.

### QuotaRule
`plan_tier` (`trial`, `free`, `plus`), `feature` (`photo_analysis`, `text_analysis`, `challenges_active`), `limit` int? (vide = illimité), `period` (`day`, `month`, `trial`). Réglable dans l'admin.

### QuotaUsage
`user`, `feature`, `period_start` date, `used` int. U(`user`, `feature`, `period_start`). Incrémenté dans la même transaction que l'analyse, avec `SELECT … FOR UPDATE`. Remboursé si l'analyse échoue.

### Subscription
| Champ | Notes |
|---|---|
| user FK, `plan` FK, `channel` | `google_play`, `app_store`, `web`, `grant` (jours offerts : parrainage, support) |
| status | `trial`, `active`, `grace`, `canceled`, `expired`, `refunded` |
| current_period_start, current_period_end, `auto_renew` | |
| external_id | U par canal : `purchaseToken` Google, `originalTransactionId` Apple, identifiant de l'agrégateur |
| raw | jsonb, dernière réponse vérifiée |

**L'état effectif** de l'utilisateur (`Entitlement`) est calculé par `billing.services.entitlement_for(user)` : il fusionne les abonnements actifs, l'essai et les jours offerts. Le résultat est mis en cache et invalidé à chaque événement.

### Trial
`user` 1–1, `starts_at`, `ends_at`, `extended_by_days` (prolongation par le support), `source` (`signup`, `referral`).

### GrantedDays
`user`, `days`, `reason` (`referral`, `support`, `promo`), `ref_id`, `created_by?`. La limite de 35 jours pour le parrainage est vérifiée ici.

### Payment
`id`, `user`, `subscription` FK?, `channel`, `amount_cents`, `currency`, `status` (`succeeded`, `failed`, `refunded`, `pending`), `external_id` U, `paid_at`, `receipt_url?`.

### Refund
`payment` FK, `amount_cents`, `reason`, `created_by`, `external_id`.

### PromoCode
`code` U, `kind` (`percent`, `amount`, `free_days`), `value`, `plans` M2M, `max_redemptions`, `redeemed_count`, `valid_from`, `valid_until`, `active`. Utilisable sur le paiement web uniquement. **PromoRedemption** : `promo`, `user`, `payment?`.

### WebhookEvent
`provider`, `event_id` U, `type`, `payload` jsonb, `processed_at?`, `error?`. Garantit l'idempotence des notifications Google RTDN, Apple ASSN v2 et de l'agrégateur.

---

## notifications — push, centre, campagnes

### PushDevice
`id`, `user`, `session` FK, `platform`, `token` U, `locale`, `app_version`, `last_seen_at`, `disabled_at?`. Envoi par FCM (Android) et APNs via FCM.

### NotificationPreference
`user` 1–1, `categories` jsonb (`{"meal_reminders": true, …}`), `meal_reminder_times` (`{"breakfast": "08:00", …}`), `weigh_in_weekday`, `quiet_start` (22:00), `quiet_end` (07:00).

### Notification (centre de notifications)
`id`, `user` I, `category` (`meal_reminder`, `hydration`, `weigh_in`, `program`, `challenge`, `reward`, `prevention`, `subscription`, `campaign`, `support`), `title`, `body` (rendus dans la langue de l'utilisateur au moment de l'envoi), `deeplink` (par exemple `omeo://meals/new`), `data` jsonb, `pushed_at?`, `read_at?`, `campaign` FK?. Index sur (`user`, `created_at`).

### Campaign
`id`, `title` I18nText, `body` I18nText, `deeplink`, `segment` jsonb (langues, pays, offres, objectifs, inactif depuis N jours), `scheduled_at`, `status` (`draft`, `scheduled`, `sending`, `sent`, `canceled`), `sent_count`, `opened_count`, `created_by`. Seuls les utilisateurs ayant donné le consentement `marketing` sont ciblés.

---

## support — demandes

### Ticket
`id`, `number` U (lisible, par exemple `NY-10234`), `user` FK?, `email`, `category` (`question`, `technical`, `billing`, `suggestion`, `personal_data`, `account_deletion`), `subject`, `status` (`new`, `open`, `waiting_user`, `resolved`, `closed`), `priority`, `assignee` FK?, `channel` (`app`, `web`), `meta` jsonb (version de l'app, appareil, système, langue).

### TicketMessage
`ticket`, `author` FK?, `direction` (`inbound`, `outbound`, `internal_note`), `body`, `attachments` M2M Upload, `created_at`.

### ReplyTemplate
`name`, `body` I18nText, `category?`.

### DataExport
`id`, `user`, `status` (`queued`, `ready`, `expired`), `file` (archive ZIP JSON+CSV, lien signé valable 24 h), `requested_at`.

---

## Schéma des dépendances

```text
accounts ──< nutrition (NutritionTarget, DailySummary)
   │             ▲
   ├──< meals ───┘  (recompute_day)
   ├──< activity ───┘
   ├──< programs ── lit DailySummary / activity
   ├──< gamification ── écoute les événements de domaine
   ├──< billing (Entitlement → garde-fous de quotas)
   ├──< notifications
   └──< support
content ── Food / Recipe / Plant (référencés par meals, programs)
```

Les applications communiquent par **services** et **événements de domaine** (`apps/core/events.py`), jamais en important les vues ou les sérialiseurs d'une autre application. Exemple : `MealLogged`, que `gamification` et `programs` écoutent.
