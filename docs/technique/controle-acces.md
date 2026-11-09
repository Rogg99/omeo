# Contrôle d'accès

Ce document est la référence unique des autorisations de l'API. Il s'applique au contrat ([contracts/openapi.yaml](../../contracts/openapi.yaml)), à l'API et à l'admin. Décisions D26 à D32.

## Principes

1. **On vérifie des permissions, jamais des rôles.** Le code teste une permission atomique (`billing.refund`). Un rôle n'est qu'un regroupement de permissions, défini dans un seul fichier de l'API : `apps/accounts/permissions.py`. C'est une constante versionnée et relue en revue de code, pas une table modifiable depuis l'admin.
2. **Tout est refusé par défaut.** Un endpoint qui ne déclare ni permission, ni `security: []` (public), ni authentification utilisateur fait échouer la CI.
3. **Moindre privilège.** Chaque rôle n'a que ce dont il a besoin. Les actions irréversibles ou financières demandent en plus une double authentification récente (« step-up »), et parfois une validation par une autre personne (« 4 yeux »).
4. **L'API est l'autorité.** L'admin masque ce qui n'est pas permis, mais l'API revérifie systématiquement. Un 403 de l'API l'emporte toujours.
5. **Tout est tracé.** Chaque action du staff est enregistrée dans `AuditLog` (qui, quoi, quand, avant, après, IP, motif), en ajout seul.

Dans l'API, ces principes se traduisent ainsi :
- chaque vue admin déclare `required_permission = "billing.refund"` ;
- une classe DRF unique, `HasPermission`, fait la vérification, complétée par `RequiresStepUp` et `RequiresVerifiedEmail` ;
- un test paramétré parcourt **toutes** les routes `/admin/*` et vérifie que chaque rôle n'ayant pas la permission reçoit `403 forbidden_role`.

---

## 1. Utilisateurs de l'app

| Couche | Règle |
|---|---|
| Authentification | JWT d'accès (15 min) et de renouvellement (30 jours) avec rotation. Le rejeu d'un ancien jeton de renouvellement révoque la session |
| Propriété | Toute requête `/me/*` est filtrée par `request.user` (sélecteurs `for_user(user)`). L'objet d'un autre utilisateur renvoie **404**, jamais 403. Un test automatique tente de lire, modifier et supprimer chaque ressource d'un autre utilisateur ; la couverture visée est de 100 % des routes `/me/*` |
| Droits (Free, essai, Plus) | Recalculés **à chaque requête** côté serveur (`entitlement_for(user)`, en cache Redis, invalidé à chaque événement d'abonnement). **Jamais lus dans le JWT** : un jeton émis avant une résiliation ne prolonge pas l'accès |
| Contenus Plus | Une liste renvoie l'élément avec `locked: true`. Le détail renvoie `403 plan_required` |
| Quotas | `429 quota_exceeded`, avec `meta.resets_at` et `meta.upgrade` |

### Marqueurs du contrat
- `x-entitlement: { feature, when? }` : l'opération, ou le cas décrit par `when`, exige la fonctionnalité. Sinon : `403 plan_required`.
- `x-quota: <feature>` : l'opération consomme ou vérifie un quota.
- `x-email-verified: true` : l'opération exige un email vérifié. Sinon : `403 email_not_verified`.

| Fonctionnalité (`feature`) | Free | Essai | Plus | Opérations concernées |
|---|---|---|---|---|
| `text_analysis` | ✖ | ✔ | ✔ | `createAnalysis` (quand `kind=text`) |
| `progress_long_range` | ✖ | ✔ | ✔ | `getProgress` (quand `range` vaut autre chose que `7d`) |
| `insights` | ✖ | ✔ | ✔ | `listInsights` |
| `programs` | ✖ | ✔ | ✔ | `enrollProgram`, `checkProgramTask` |
| `offline_workouts` | ✖ | ✖ | ✔ | `getWorkoutDownload` |
| `full_catalog` | sélection | ✔ | ✔ | `getRecipe`, `getExercise`, `getWorkout` (quand le contenu n'est pas `is_free`) |
| `weekly_report` | ✖ | ✔ | ✔ | `getPrevention` (champ `weekly_report` verrouillé, pas de 403) |
| `streak_freeze` | ✖ | ✖ | ✔ | Appliqué automatiquement par l'API |

### Email non vérifié
L'app reste entièrement utilisable, et un bandeau incite à vérifier l'email. Exigent un email vérifié :
- `createWebCheckout` et `createBillingPortal` ;
- `changeEmail` ;
- `requestDataExport` ;
- la validation d'un parrainage (règle interne, pas d'endpoint).

Au bout de 7 jours sans vérification, le rappel devient insistant, sans blocage.

### Compte suspendu
- Toutes les sessions sont révoquées immédiatement.
- Toute requête authentifiée, y compris `/auth/login` et `/auth/refresh`, renvoie `403 account_suspended` avec `meta.support_url`.
- Restent accessibles sans compte : les pages légales, la FAQ, le formulaire de support (`createTicket` avec captcha) et la suppression de compte par email (`/account-deletion`), qui est un droit RGPD.

### Suppression demandée
La demande révoque les sessions. Une connexion pendant le délai de 30 jours propose d'annuler la suppression. Cet endpoint sera ajouté plus tard (voir [contracts/CHANGES.md](../../contracts/CHANGES.md)).

---

## 2. Équipe (admin)

### Authentification
- Email et mot de passe, plus TOTP **obligatoire**. Pas de connexion Google ou Apple pour le staff.
- Jeton d'accès de 10 min. Session de 12 h maximum, fermée après 30 min d'inactivité. Cookies `__Host-`, SameSite=Strict.
- En production, l'admin est accessible uniquement derrière Cloudflare Access (ou un VPN, ou une liste d'IP autorisées), **en plus** de l'authentification applicative.
- Comptes nominatifs uniquement : aucun compte partagé. Les invitations expirent en 72 h.
- Un compte staff est désactivé après 90 jours sans connexion.

### Step-up (double authentification récente)
Les actions marquées 🔐 exigent une validation TOTP datant de **moins de 15 minutes** (`Session.mfa_verified_at`). Sinon, l'API renvoie `401 step_up_required`. L'admin demande alors le code, appelle `POST /auth/mfa/step-up`, puis rejoue l'action.

### Validation à quatre yeux
Les actions marquées 👥 ne s'appliquent pas directement. L'API crée une `ApprovalRequest` (réponse `202`), qui doit être approuvée par **une autre personne** ayant la permission `approvals.decide` sur le même domaine.
- On ne peut **jamais** approuver sa propre demande, superadmin compris (`403 self_approval_forbidden`).
- Une demande expire au bout de 7 jours.
- Pour une équipe de moins de deux personnes par domaine, le réglage `four_eyes.<domaine>.enabled` permet de désactiver temporairement la validation. Ce réglage ne peut être changé que par un superadmin, avec step-up et une entrée d'audit, et une alerte reste affichée sur le tableau de bord tant qu'il est désactivé.

| Action à quatre yeux | Domaine | Déclencheur |
|---|---|---|
| Publier un contenu (passage de `review` à `published`) | contenu | toujours, sauf permission `content.publish_own` |
| Programmer une campagne | contenu | toujours |
| Modifier un prix ou une offre | finance | toujours |
| Modifier les quotas | finance | toujours |
| Rembourser | finance | montant supérieur à `billing.refund_approval_threshold_usd` (50 $ par défaut) |
| Modifier les constantes de calcul nutritionnel | réglages | toujours |

> Pour le contenu, la validation à quatre yeux **est** l'étape de relecture : l'auteur passe le contenu en `review`, une autre personne le publie. La permission `content.publish_own` (aucun rôle ne l'a par défaut) permet une correction mineure sur un contenu déjà publié (faute de frappe, traduction) sans relecture. Elle est journalisée avec un motif obligatoire.

### Catalogue des permissions et rôles

Légende : **S** superadmin, **C** contenu, **Su** support, **F** finance, **M** modération des avis. 🔐 step-up, 👥 quatre yeux.

| Permission | Description | S | C | Su | F | M |
|---|---|:-:|:-:|:-:|:-:|:-:|
| **Tableau de bord** |
| `dashboard.product` | Inscriptions, actifs, rétention, analyses, part d'avis négatifs | ✔ | ✔ | ✔ | ✔ | ✔ |
| `dashboard.finance` | Revenus, MRR, conversion, coût de l'IA | ✔ | | | ✔ | |
| `dashboard.support` | Demandes en attente | ✔ | | ✔ | | |
| **Utilisateurs** |
| `users.view` | Recherche et fiche (données de santé masquées) | ✔ | | ✔ | ✔ | |
| `users.view_health` 🔐 | Révéler les données de santé (motif obligatoire, consultation journalisée) | ✔ | | ✔ | | |
| `users.resend_verification` | Renvoyer l'email de vérification | ✔ | | ✔ | | |
| `users.send_password_reset` | Envoyer un lien de réinitialisation | ✔ | | ✔ | | |
| `users.extend_trial` | Prolonger l'essai (14 jours au maximum) | ✔ | | ✔ | | |
| `users.grant_plus_days` 🔐 | Offrir des jours de Plus | ✔ | | | ✔ | |
| `users.reset_quota` | Remettre un quota à zéro | ✔ | | ✔ | ✔ | |
| `users.suspend` 🔐 | Suspendre ou réactiver un compte | ✔ | | | | |
| `users.export_data` 🔐 | Exporter les données d'un utilisateur | ✔ | | | | |
| `users.delete_data` 🔐 | Supprimer les données d'un utilisateur | ✔ | | | | |
| **Contenus** |
| `content.view` | Lire tous les contenus et leurs versions | ✔ | ✔ | ✔ | | ✔ |
| `content.edit` | Créer, modifier, passer en relecture, archiver, téléverser des médias | ✔ | ✔ | | | |
| `content.publish` 👥 | Publier le contenu **d'une autre personne** | ✔ | ✔ | | | |
| `content.publish_own` | Publier sa propre correction mineure (motif obligatoire) | | | | | |
| `content.translate` | Proposer une traduction IA | ✔ | ✔ | | | |
| **Avis sur les analyses** |
| `feedback.view` | Liste, détail, statistiques | ✔ | ✔ | | | ✔ |
| `feedback.resolve` | Traiter, ignorer, créer un brouillon de plat ou d'aliment, ajouter un autre nom | ✔ | | | | ✔ |
| **Abonnements et paiements** |
| `billing.view` | Offres, quotas, abonnements, paiements, codes promo | ✔ | | ✔ | ✔ | |
| `billing.plans_edit` 👥 | Proposer une modification de prix ou d'offre | ✔ | | | ✔ | |
| `billing.quotas_edit` 👥 | Proposer une modification de quotas | ✔ | | | ✔ | |
| `billing.refund` 🔐 (👥 au-dessus du seuil) | Rembourser un paiement web | ✔ | | | ✔ | |
| `billing.promo_manage` | Créer et modifier les codes promo | ✔ | | | ✔ | |
| **Support** |
| `support.view` | File des demandes et fil de discussion | ✔ | | ✔ | | |
| `support.reply` | Répondre, ajouter une note interne, changer le statut, assigner | ✔ | | ✔ | | |
| `support.templates_manage` | Gérer les modèles de réponse | ✔ | | ✔ | | |
| **Campagnes** |
| `campaigns.view` | Lire les campagnes et leurs statistiques | ✔ | ✔ | | | |
| `campaigns.edit` | Rédiger, estimer l'audience, envoyer un test à soi-même | ✔ | ✔ | | | |
| `campaigns.schedule` 🔐👥 | Programmer ou annuler la campagne **d'une autre personne** | ✔ | ✔ | | | |
| **Validation** |
| `approvals.decide` 🔐 | Approuver ou rejeter les demandes de son domaine | ✔ | ✔ (contenu) | | ✔ (finance) | |
| **Réglages, équipe, audit** |
| `settings.view` | Lire les réglages | ✔ | ✔ | | ✔ | |
| `settings.edit` 🔐 (👥 pour les constantes nutritionnelles) | Modifier les réglages | ✔ | | | | |
| `team.manage` 🔐 | Inviter, changer les rôles, désactiver, réinitialiser la double authentification | ✔ | | | | |
| `audit.view` | Journal d'audit | ✔ | | | | |

- `GET /admin/me` renvoie la liste **effective** des permissions de la personne. L'admin s'en sert pour son menu et ses boutons (`can("billing.refund")`), sans jamais réimplémenter la matrice.
- Le superadmin ne peut ni retirer son propre rôle superadmin, ni désactiver le dernier superadmin actif.

### Garde-fous propres à l'admin
- **Motif obligatoire** (de 3 à 500 caractères) pour toutes les actions sur un compte utilisateur, la révélation des données de santé, les remboursements, les jours offerts et les réglages. Il est enregistré dans l'audit.
- **Confirmation forte** (taper le nom ou l'email) pour la suppression de données, la suspension et le remboursement complet.
- **Limitation de débit** à 600 requêtes par minute par membre. Alerte en cas d'export massif ou de plus de 20 révélations de données de santé par heure.
- **Données de santé** : jamais présentes dans les listes ni dans les exports CSV de l'admin. Elles ne sont accessibles qu'une à une, via `users.view_health`.

---

## 3. Services et intégrations

| Appelant | Authentification |
|---|---|
| Google Play RTDN | Jeton OIDC Pub/Sub vérifié (audience et compte de service attendus) |
| App Store Server Notifications v2 | Signature JWS vérifiée avec la chaîne de certificats Apple |
| Agrégateur de paiement | Signature HMAC et horodatage (tolérance de 5 min), événement idempotent |
| Revalidation du site web (de l'API vers le web) | HMAC partagé (`WEB_REVALIDATE_SECRET`), horodatage, liste de chemins autorisés |
| Tâches Celery | Aucun accès HTTP : les tâches appellent directement les services |

Les secrets sont différents par environnement, changés au moins une fois par an, et jamais présents dans le dépôt.
