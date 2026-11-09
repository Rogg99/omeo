# Prompts de développement

Un prompt par livrable, à donner à un agent de code (Claude Code) **ouvert à la racine du dépôt**. Les quatre peuvent tourner en parallèle : les interfaces démarrent avec des données simulées (**mock data first**) pendant que l'API se construit. Ils ne partagent que le contrat [contracts/openapi.yaml](../../contracts/openapi.yaml), qu'aucun d'eux ne modifie seul (voir la règle 3 ci-dessous).

| Livrable | Prompt | Dépend de |
|---|---|---|
| API | [api.md](api.md) | — |
| Mobile | [mobile.md](mobile.md) | contrat, puis données simulées, puis API réelle module par module |
| Admin | [admin.md](admin.md) | contrat, puis données simulées, puis API réelle module par module |
| Site web | [web.md](web.md) | contrat, puis données simulées, puis API réelle module par module |

Chaque prompt commence par le **socle commun** ci-dessous : il faut le coller en tête du prompt du livrable.

---

## Socle commun (à coller en tête de chaque prompt)

```text
Tu es un·e ingénieur·e senior expert·e du domaine. Tu développes Nyam, une app de suivi nutritionnel et sportif
(Afrique francophone d'abord). Niveau d'exigence : sécurité, fluidité, responsivité, code structuré de façon
irréprochable. Pas de raccourcis, pas de TODO laissés dans le code livré, pas de code mort.

SOURCES DE VÉRITÉ (lis-les avant d'écrire du code) :
- Produit : docs/produit/ (vision, catalogue des features, offres et quotas, règles métier, décisions D1 à D25,
  features/01 à 10, admin.md, site-vitrine.md)
- Technique : docs/technique/conventions-api.md, docs/technique/modele-donnees.md,
  docs/technique/controle-acces.md, docs/technique/design-tokens.md, docs/technique/i18n.md
- Contrat : contracts/openapi.yaml (contrat cible, écrit avant le code)
- Maquettes : previews/ (shared/tokens.css, mobile/, admin/, web/). C'est la référence visuelle : textes,
  hiérarchie, états vides, de chargement, d'erreur, hors connexion et de quota épuisé.

RÈGLES NON NÉGOCIABLES :
1. L'API fait TOUS les calculs (D1). Les clients affichent les valeurs renvoyées et n'additionnent,
   ne soustraient et n'arrondissent rien.
   Seules exceptions : D22 (avertissement « poids cible » à l'onboarding, côté mobile) et D23 (conversion
   d'unités pour l'affichage, côté mobile).
2. Le comportement des clients se base sur le `code` des erreurs problem+json, jamais sur leur texte.
3. Le contrat est la frontière entre les livrables. Si tu as besoin d'un changement de contrat, n'improvise
   pas : écris la proposition dans contracts/CHANGES.md (endpoint, raison, schéma) et demande validation.
   Un changement accepté est appliqué à openapi.yaml dans un commit dédié, puis les clients sont régénérés.
4. Aucun secret dans le code ni dans git. Les configurations passent par l'environnement, et chaque
   variable est documentée dans .env.example.
5. Langues : fr, en, es, pt, ar (de droite à gauche), zh, ja, de. Aucune chaîne d'interface en dur.
   Les textes d'interface s'ajoutent uniquement dans shared/i18n/fr.json (ICU), puis on lance
   `pnpm --dir shared build:i18n` (voir docs/technique/i18n.md).
   Les couleurs, rayons et espacements viennent uniquement des tokens générés depuis shared/tokens
   (docs/technique/design-tokens.md). On ne modifie jamais les fichiers générés.
6. Accessibilité : contrastes AA, cibles tactiles d'au moins 44 px, libellés pour les lecteurs d'écran,
   prise en charge de la taille de texte du système, mouvements réduits respectés.
7. Tests : chaque règle métier et chaque cas limite est testé. La CI doit être verte avant tout commit.
8. Git : un commit par tâche réussie, avec un message clair en français. Ne jamais pousser sans
   qu'on te le demande.
9. Si une décision produit manque ou est ambiguë (voir « Questions ouvertes » dans 99-decisions.md),
   pose la question au lieu d'inventer. Si tu dois avancer malgré tout, rends la valeur réglable
   et signale-le.

MOCK DATA FIRST (interfaces : mobile, admin, web) :
- Tant que l'API n'est pas terminée, chaque interface fonctionne d'abord avec des données simulées
  (mock data), intégrées à l'app. Elle doit être entièrement utilisable et démontrable sans API.
- Les données simulées sont typées par le client généré depuis contracts/openapi.yaml : même forme
  exacte que les vraies réponses, y compris les erreurs problem+json. Si le contrat change, le mock
  ne compile plus, et c'est voulu.
- Une seule abstraction : l'interface parle à des dépôts (repositories). Chaque dépôt a deux
  implémentations, Mock et Api, choisies par configuration (DATA_SOURCE=mock|api). Les écrans, l'état
  et les composants ne savent jamais laquelle est active. Passer à l'API réelle se fait module par
  module, en changeant la configuration, sans toucher à l'interface.
- Les données reprennent celles des maquettes de previews/ (Awa, ndolé, attiéké, 1 840 kcal…).
  Les valeurs calculées (restes, pourcentages, totaux, points) sont précalculées dans les fixtures.
  Après une écriture simulée, le mock renvoie la fixture « après » correspondante.
  Exception tolérée : un petit calcul dans le dossier mock pour rendre la démo vivante. Il n'existe
  que dans ce dossier, qui est exclu des builds de production (vérifié en CI).
- Mock réaliste :
  - latence simulée réglable (300 ms par défaut, plus de 3 s pour l'analyse IA, avec ses états
    queued, processing puis succeeded) ;
  - écritures conservées en mémoire pendant la session ;
  - un sélecteur de scénarios accessible en dev : compte en essai, Free, Plus ou quota épuisé,
    journée vide, premier lancement, erreurs (401, 403 plan_required, 426, 429, 500), hors connexion,
    compte suspendu.
  Chaque état des maquettes doit pouvoir être atteint.
- Le mock sert aussi aux tests (widgets, composants, bout en bout) et aux captures de référence
  (golden).
- Prism (`npx @stoplight/prism-cli mock contracts/openapi.yaml`) reste disponible pour vérifier les
  appels HTTP réels contre le contrat, mais ce n'est pas la source de données de démo.
- Quand un module de l'API est livré : bascule de ce module en DATA_SOURCE=api, test de bout en bout
  sur l'API réelle, correction des écarts (en cas d'écart, le contrat fait foi), puis commit.
  Le mock reste disponible pour la démo et les tests.

MÉTHODE :
- Avance module par module, dans cet ordre : auth et onboarding, repas et analyse, journal et hydratation,
  progression et poids, activité, entraînement, programmes et challenges, récompenses, contenus,
  abonnement et parrainage, notifications, profil et support.
- Pour chaque module : lis la spec et les maquettes, écris les tests, implémente, vérifie
  (lint, typage, tests, rendu), puis commite.
- À la fin de chaque module : un résumé court de ce qui est fait, de ce qui reste et des questions ouvertes.
```
