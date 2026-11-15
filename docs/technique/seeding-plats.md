# Seeding des plats par pays

Comment constituer, pays par pays, le catalogue de plats qui permet à l'analyse IA de reconnaître un repas et d'en calculer les nutriments. Complète [seeders.md](seeders.md) (section Catalogue).

## Principes

1. **Un plat = une composition, pas des chiffres.** Un plat est une liste d'aliments en grammes pour une portion standard. Les nutriments sont toujours recalculés depuis les aliments (`refresh_dish`). On ne saisit jamais de kcal pour un plat.
2. **Aliments d'abord.** Un plat ne référence que des aliments déjà importés depuis une table de composition (`import_foods`). L'ordre de priorité est WAFCT 2019, puis CIQUAL, puis USDA. Une référence manquante bloque tout le fichier.
3. **Un fichier par pays** : `api/seeds/catalog/dishes/<ISO>.yaml`, versionné et relu en PR. Le modèle est `_TEMPLATE.yaml`.
4. **Brouillon, puis quatre yeux.** L'import crée des brouillons. Une autre personne (rôle `content`) relit et publie dans l'admin, avec une vraie photo sous licence (règle D27).
5. **Les noms locaux font la reconnaissance.** Le rapprochement trigram et l'IA s'appuient sur `aliases` : orthographes, langues locales, noms de rue (garba, tiep, ceebu jen…).

## Déroulé pour un pays

| Étape | Qui | Livrable |
|---|---|---|
| 1. **Inventaire** : les 30 à 50 plats réellement mangés au quotidien (petit-déjeuner, plats de rue, plats de fête), classés par fréquence | Référent pays + nutritionniste | Liste priorisée (les 15 premiers sont prioritaires) |
| 2. **Aliments manquants** : vérifier que chaque ingrédient existe dans le catalogue, sinon l'ajouter depuis WAFCT, CIQUAL ou USDA (`import_foods`) | Équipe données | Aliments publiés, avec `source:source_ref` |
| 3. **Composition type** : grammes par ingrédient pour une portion standard, à partir de **pesées réelles** (3 portions minimum : maison, maquis ou restaurant, vente de rue) ou d'une référence publiée | Nutritionniste | Fichier `<ISO>.yaml` avec ses `sources` |
| 4. **Noms** : `fr`, `en` et autres noms (langues locales, variantes d'orthographe sans accents) | Référent pays | `aliases` |
| 5. **Import** : `manage.py import_dishes seeds/catalog/dishes/<ISO>.yaml --dry-run`, puis sans `--dry-run` | Équipe données | Plats en brouillon |
| 6. **Relecture et publication** : contrôle des nutriments calculés, photo, traduction IA des autres langues à relire | Rôle `content` (une autre personne) | Plats publiés |
| 7. **Validation terrain** : scanner 20 photos réelles par plat prioritaire et vérifier la reconnaissance avec `foodscan_benchmark` | Équipe IA | Rapport de précision, avec ajout d'autres noms si besoin |

## Règles de composition

- **Grammes cuits, partie comestible**, pour une portion standard servie à un adulte. Le riz se compte cuit, le poisson sans arêtes.
- **L'huile se compte à part**, avec une ligne dédiée. C'est la première source d'erreur calorique : mieux vaut la peser que l'estimer.
- **Le bouillon cube et le sel ajouté** se comptent aussi, car ils déterminent l'alerte sel.
- **Variantes** : un plat différent seulement si la composition change nettement (ndolé crevettes et ndolé viande, par exemple). Sinon, un seul plat et des autres noms.
- **Contrôle de cohérence avant PR** : après un `--dry-run`, comparer l'ordre de grandeur des kcal par portion à une référence publiée. Un écart de plus de 25 % se justifie dans `sources`.

## Format et import

```yaml
country: CI
dishes:
  attieke_poisson:
    name: { fr: Attiéké poisson braisé, en: Attieke with grilled fish }
    aliases: [garba, attieke poisson]
    components: { "wafct2019:<code>": 250, "wafct2019:<code>": 150 }
    sources: ["pesée : Abidjan, maquis, 3 portions"]
```

```bash
manage.py import_dishes seeds/catalog/dishes/CI.yaml --dry-run   # valide tout, n'écrit rien
manage.py import_dishes seeds/catalog/dishes/                     # tous les pays
manage.py import_dishes seeds/catalog/dishes/CI.yaml --update-drafts
```

- Le fichier entier est validé avant toute écriture : code pays, nom du fichier, langues `fr` et `en`, bornes des grammes, aliments existants. Un import échoué n'écrit rien.
- **Idempotent.** La clé est le couple (pays, nom français). Un plat existant est ignoré. `--update-drafts` remplace la composition d'un plat encore en brouillon. Un plat publié se corrige uniquement dans l'admin, qui fait foi.
- La démo (`seeds/demo/dishes.yaml`, chargée par `seed_demo`) reste séparée : ses aliments sont des ordres de grandeur, jamais réutilisés en production.

## Ordre de déploiement des pays

Par taille d'audience visée, avec la cible au lancement de 60 à 100 plats :

| Vague | Pays | Plats |
|---|---|---|
| 1 | Côte d'Ivoire (CI), Cameroun (CM), Sénégal (SN) | 20 à 25 chacun |
| 2 | Mali (ML), Burkina Faso (BF), Bénin (BJ), Togo (TG) | 10 à 15 chacun |
| 3 | Guinée (GN), Niger (NE), Gabon (GA), Congo (CG), RD Congo (CD) | selon la demande observée dans les scans non reconnus |

Les scans non reconnus (`foodscan`, avis 👎 avec correction) alimentent les vagues suivantes : un plat corrigé souvent devient prioritaire.
