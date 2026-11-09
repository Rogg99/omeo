# Seeders

Objectif : qu'`docker compose up` donne une API **immédiatement utilisable**, avec de vraies données, dans tous les environnements. Trois niveaux de données, avec des règles différentes.

```text
docker compose up
  └─ api : migrate
         → seed_reference          (toujours, tous environnements, idempotent)
         → seed_demo               (seulement si SEED_DEMO=true ; interdit en production)
```

## 1. Référence : `manage.py seed_reference`

Ce sont les données sans lesquelles l'API ne fonctionne pas. La commande est lancée à **chaque déploiement**, après les migrations.

| Fichier source ([api/seeds/reference/](../../api/seeds/reference/)) | Modèle | Clé stable |
|---|---|---|
| `settings.yaml` | Setting | chemin de la clé (`nutrition.salt_max_g`) |
| `plans.yaml` | Plan | `code` |
| `quotas.yaml` | QuotaRule | (`plan_tier`, `feature`) |
| `point_rules.yaml` | PointRule | `action` |
| `levels.yaml` | Level | `rank` |
| `badges.yaml` | Badge | `code` |
| `cities.yaml` | City | (`country`, nom fr) |
| `legal/*.fr.md` (`terms`, `privacy`, `cookies`, `legal_notice`) | LegalDocument, version 1 | (`kind`, `version`) |

**Règles :**
- **Idempotente** : la commande crée ce qui manque et **n'écrase jamais** une valeur existante, puisque l'admin fait foi après la première installation. Avec `--dry-run`, elle affiche ce qui serait créé.
- **Pas d'écriture d'audit** pour la création initiale : l'acteur enregistré est `system`.
- **Documents légaux** : publiés directement en version 1, car l'inscription l'exige. **En production, la commande échoue tant qu'un texte contient une mention entre `[crochets]`** (identité de l'éditeur, âge minimum, hébergeur…).
- Les textes du seed n'existent qu'en français et en anglais. Les autres langues se complètent dans l'admin, avec la traduction IA à relire. L'ordre de repli est anglais, puis français.
- **Premier superadmin** : `manage.py create_superadmin --email …`, une commande interactive qui demande le mot de passe et affiche le QR de la double authentification. Ce n'est jamais une fixture ni une variable d'environnement.

## 2. Catalogue : `manage.py import_foods`, `import_content`

Le cœur de la valeur produit : sans aliments, l'analyse IA ne peut rapprocher aucun ingrédient.

| Donnée | Source | Volume de départ |
|---|---|---|
| **Aliments**, pour 100 g | **FAO/INFOODS WAFCT 2019** (table de composition des aliments d'Afrique de l'Ouest), complétée par CIQUAL (ANSES) et USDA FoodData Central pour les aliments génériques | 300 à 500 |
| **Plats** | Équipe (composition type, portion standard, autres noms locaux) | 60 à 100 |
| **Recettes, plantes, exercices, séances, programmes, challenges, conseils de prévention, FAQ** | Équipe | selon la production |

**Règles :**
- `import_foods <fichier.csv> --source wafct2019` : correspondance des colonnes vers nos champs (`kcal`, `protein_g`, `carbs_g`, `sugars_g`, `fat_g`, `saturated_fat_g`, `fiber_g`, `salt_g`). Le sel vient du sodium, avec sel = sodium × 2,5.
  - Chaque aliment garde sa source et son identifiant d'origine.
  - Réimporter met à jour les valeurs nutritionnelles, mais jamais les noms ni les autres noms édités dans l'admin.
- Les noms locaux (ndolé, gombo, attiéké, fonio, bissap…) sont ajoutés comme autres noms. Ce sont eux qui font fonctionner le rapprochement trigram.
- `import_content <dossier>` importe les contenus éditoriaux **en brouillon**. Une autre personne relit et publie, selon la règle des quatre yeux (D27).
- **Images** :
  - **Aliments : pas de photo.** La table WAFCT n'en contient pas, et les aliments ne sont jamais montrés seuls à l'utilisateur (ils servent à l'analyse et aux lignes d'ingrédients). Chaque catégorie a une **icône**, avec une douzaine d'icônes dans le design system.
  - **Plats et recettes : vraies photos obligatoires** avant publication. Elles sont produites par l'équipe ou achetées sous licence, avec la licence enregistrée dans le média. Pas d'image générée par IA pour représenter un vrai plat : elle tromperait sur l'aspect réel et sur la portion.
  - **Plantes et exercices** : photos et vidéos de l'équipe, ou banques sous licence.
  - En **dev et démo** : placeholders en dégradé (les mêmes que dans les maquettes) envoyés dans MinIO.

## 3. Démo : `manage.py seed_demo [--reset]`

Pour développer, tester et faire des démos, avec les mêmes données que les maquettes. **La commande refuse de tourner si `ENV=production`.**

| Données | Contenu |
|---|---|
| Mini-catalogue | Environ 150 aliments (extrait WAFCT), 40 plats (ndolé, thiéboudienne, attiéké poisson, mafé, yassa, alloco, foutou sauce graine, eru, kedjenou…), 30 recettes, 20 plantes, 40 exercices, 10 séances, 3 programmes, 6 challenges, 10 conseils de prévention, la FAQ. **Tout est publié** |
| Comptes utilisateurs, avec le mot de passe `Demo-Omeo-2026!` | `awa@demo.omeo.app` (essai), `moussa@…` (Free), `fatou@…` (Plus mensuel, store), `koffi@…` (Plus annuel, web), `aicha@…` (Free, quota épuisé), `nouveau@…` (compte neuf, aucune donnée), `suspendu@…` (suspendu) |
| Comptes staff, TOTP de démo affiché par la commande | Un compte par rôle (superadmin, content, support, finance, moderation), plus un second compte content et un second finance, pour tester les quatre yeux |
| Historique | 60 jours par compte actif : repas variés, eau, poids en baisse ou stable, activité. Les jours sont mélangés : complets, vides, excès de sel, objectif atteint. On y trouve aussi une série en cours, un challenge actif, un programme à mi-parcours, des badges obtenus et en cours |
| Situations particulières | Avis IA 👍/👎 avec photos et corrections, demandes de support à tous les statuts, paiements (dont un échoué et un remboursé), parrainages validés et en attente, campagnes (brouillon, programmée, envoyée), demandes de validation en attente, notifications lues et non lues |

**Règles :**
- **Déterministe** : factory_boy avec une graine fixe (`--seed 42`). Les mêmes données reviennent à chaque exécution, ce qui permet les comparaisons avec les maquettes, les tests de bout en bout et les captures de référence.
- **Passe par les vrais services** (`log_meal`, `add_water`, `sync_health`, `recompute_day`, `award_points`…), jamais par des insertions directes : la démo vérifie les calculs au lieu de les contourner. Les dates sont relatives à aujourd'hui (aujourd'hui moins N jours).
- `--reset` vide uniquement les données de démo (comptes `@demo.omeo.app` et contenus étiquetés `demo`), jamais les données de référence.
- Durée cible : moins de 60 secondes.

## Tests
- `seed_reference` lancée deux fois de suite ne crée rien la seconde fois, et ne modifie pas une valeur changée entre-temps.
- `seed_demo` échoue avec `ENV=production`.
- Après `seed_demo`, `GET /me/home` et `GET /me/days/{date}` d'Awa renvoient les valeurs attendues (test de non-régression des calculs).
- En production, la publication échoue s'il reste un `[crochet]` dans les textes légaux.
