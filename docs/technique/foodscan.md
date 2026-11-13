# Scan des repas — `apps/foodscan`

Moteur d'analyse des photos (et des descriptions) de repas. **V1 : aucun modèle entraîné.** Un modèle de vision généraliste, appelé via OpenRouter (D3), est orienté par une base de connaissances que les avis des utilisateurs enrichissent. L'entraînement d'un modèle spécialisé viendra plus tard, avec les avis validés comme jeu de données (voir la section *Et ensuite*).

L'app s'inspire du prototype `foodscanner/` (YOLO, détecteur hors domaine et arbitrage GPT) et en reprend les leçons :
- juger le plat qui **domine** l'assiette, jamais l'accompagnement ;
- nommer le plat par son **nom usuel** ;
- injecter une **description visuelle** de chaque plat local ;
- redresser la photo selon l'EXIF ;
- valider strictement la sortie de l'IA ;
- versionner le prompt.

## Ce que fait foodscan, et ce qu'il ne fait pas

| foodscan fait | foodscan ne fait pas |
|---|---|
| Identifier le plat, ses alternatives et sa confiance | Calculer des nutriments : ils viennent **toujours** de `nutrition.Food` (règle de [02-saisie-repas.md](../produit/features/02-saisie-repas.md)) |
| Lister les ingrédients et leur masse estimée | Rapprocher les ingrédients de `Food` : c'est le rôle de `nutrition` (recherche trigram) |
| Tenir compte du pays de l'utilisateur | Lire une position GPS : le pays vient de `Profile.country` |
| Recevoir les corrections et en tirer des règles | Stocker `Analysis` et `AnalysisFeedback` : ces modèles restent dans `meals` |

`meals` appelle foodscan par ses **services**, jamais par ses vues (voir les règles d'architecture de [prompts/api.md](../prompts/api.md)).

## La boucle

```
photo + pays ──► prompt : contexte géographique
                         + fiches des plats locaux      (DishKnowledge)
                         + confusions déjà corrigées    (ConfusionRule active)
              ──► IA de vision (OpenRouter) ──► JSON strict validé (ScanOutput)
                                                        │
règle active ◄── consensus ou validateur ◄── corrections des utilisateurs (ScanReview)
```

### 1. Le contexte géographique
Le pays sert de **probabilité a priori**, jamais de contrainte. À aspect égal, l'IA préfère un plat du pays ou de la région. Elle ne doit jamais forcer un plat local sur une image qui montre autre chose : un sushi à Douala reste un sushi.

Les régions culinaires sont définies dans `regions.py`. Le Cameroun, par exemple, appartient à l'Afrique centrale. Le prompt reçoit :
- les fiches du pays ;
- puis celles de la région ;
- jusqu'à `FOODSCAN_MAX_DISH_HINTS` fiches au total. Une fiche du pays remplace la fiche régionale du même plat.

### 2. Les fiches de plats (`DishKnowledge`)
Une fiche contient :
- une clé stable (`ndole`), un nom usuel et des noms locaux ;
- une description visuelle (couleur, texture, composition) ;
- une indication « à distinguer de » ;
- sa portée : un pays, ou une région entière.

Elles sont rédigées par l'équipe, ou créées à partir d'avis récurrents. C'est l'équivalent du glossaire visuel de `foodscanner`.

### 3. Les avis et la validation (`ScanReview` → `ConfusionRule`)
Quand un utilisateur corrige le plat (« ce n'est pas de la sauce gombo, c'est de l'eru »), `meals` appelle `services.submit_review`. **Un avis isolé ne change rien.** Une correction ne devient une règle injectée dans le prompt que dans deux cas :

| Voie | Condition |
|---|---|
| Consensus | au moins `FOODSCAN_CONSENSUS_MIN_USERS` (3) utilisateurs **distincts** font la même correction **dans le même pays**, et cette correction représente au moins `FOODSCAN_CONSENSUS_MIN_AGREEMENT` (60 %) des corrections de ce plat dans ce pays |
| Validateur de confiance | un membre de l'équipe ou un nutritionniste approuve l'avis : la règle est créée tout de suite, avec un indice visuel facultatif |

Garde-fous :
- **Un utilisateur compte une seule fois** par correction, quel que soit son nombre d'avis.
- **Un nouvel avis sur la même analyse remplace le précédent.**
- **Un avis rejeté** par un validateur sort du calcul. Si le consensus tombe, la règle est désactivée.
- **Une règle désactivée à la main** n'est jamais réactivée par le calcul.
- **Les règles sont propres à un pays.** Une confusion camerounaise n'oriente pas les analyses au Gabon.
- **Les commentaires libres des utilisateurs n'entrent jamais dans le prompt.** Seuls des libellés nettoyés (une ligne, 80 caractères au plus, sans balisage) et des textes de l'équipe y entrent. Sinon, un utilisateur pourrait glisser des consignes à l'IA.
- **Un 👍 (le plat est confirmé)** est enregistré, mais ne crée pas de règle.

`rebuild_confusion_rules(country=…)` est idempotent. On peut le relancer à tout moment.

## Utilisation depuis `meals`

```python
from apps.foodscan import services

result = services.scan_photo(image_bytes=data, country=profile.country, locale="fr")
# result.succeeded, result.failure_reason (blurry | no_food | unsupported | provider_error | timeout)
# result.output.dish_label / dish_key / confidence / alternatives / items[label, grams, confidence]
# result.low_confidence, result.counted_in_quota
# result.model, result.prompt_version, result.tokens_in/out, result.cost_usd_micros, result.raw_response
# result.context : fiches et règles injectées (pour l'admin)

services.submit_review(user=user, country=profile.country, analysis_id=analysis.id,
                       predicted_label=analysis.dish_label, correct_label="Eru")
```

Les champs de `ScanResult` correspondent à ceux de `Analysis` dans le [modèle de données](modele-donnees.md). Une analyse échouée en `blurry` ou `no_food` ne compte pas dans le quota.

`services.scan_text` fait de même pour une saisie libre ou une saisie vocale transcrite. Le texte de l'utilisateur y est traité comme une donnée, jamais comme une consigne.

**Reste à brancher dans `meals`** :
- la tâche Celery de la file `ai` ;
- l'enregistrement de `Analysis` ;
- le rapprochement des `items` avec `Food` ;
- l'appel à `submit_review` depuis `PUT /me/analyses/{id}/feedback`.

Le contrat ne prévoit pas encore le plat corrigé dans `FeedbackInput`. Il faudra y ajouter un `corrected_dish_label` facultatif (voir *Questions ouvertes*).

## Mesurer avant de croire

```bash
python manage.py foodscan_benchmark jeu_de_test/ --country CM --compare --report rapport.json
```

Le jeu de test est rangé par plat : `jeu_de_test/ndole/001.jpg`, et le nom du dossier est la clé attendue. Avec `--compare`, chaque photo passe deux fois, **sans puis avec** la base de connaissances. La commande donne le top-1, le top-3, les échecs et le coût par passe. Un ajout de fiches ou de règles ne se garde que s'il améliore ces chiffres.

Il faut un jeu fixe par région (une cinquantaine de photos), qui ne sert **jamais** à rédiger les fiches. Sinon on mesure la mémoire, pas la qualité.

## Réglages

| Variable | Défaut | Rôle |
|---|---|---|
| `FOODSCAN_VISION_MODEL` | `OPENROUTER_VISION_MODEL` | modèle de vision |
| `OPENROUTER_BASE_URL` | `https://openrouter.ai/api/v1` | |
| `FOODSCAN_TIMEOUT_S` | 30 | délai maximal par appel (2 nouvelles tentatives, puis coupe-circuit après 5 échecs pendant 60 s) |
| `FOODSCAN_LOW_CONFIDENCE` | 0,6 | en dessous, `low_confidence = true` : l'app invite à vérifier |
| `FOODSCAN_MAX_DISH_HINTS` | 40 | nombre maximal de fiches dans le prompt |
| `FOODSCAN_MAX_RULES` | 20 | nombre maximal de règles dans le prompt |
| `FOODSCAN_CONSENSUS_MIN_USERS` | 3 | utilisateurs distincts requis |
| `FOODSCAN_CONSENSUS_MIN_AGREEMENT` | 0,6 | part minimale des corrections du plat |

Toute modification du texte du prompt incrémente `PROMPT_VERSION` dans `prompting.py`.

## Fichiers

| Fichier | Rôle |
|---|---|
| `regions.py` | pays → région culinaire (pur) |
| `schemas.py` | `ScanOutput` (pydantic), `DishHint`, `ConfusionHint`, normalisation des libellés (pur) |
| `prompting.py` | construction du prompt, `PROMPT_VERSION` (pur) |
| `consensus.py` | règles de validation des avis (pur) |
| `images.py` | redressement EXIF, retrait des métadonnées, réduction à 1 280 px (pur) |
| `client.py` | client OpenRouter : délai, nouvelles tentatives, coupe-circuit, coût |
| `models.py`, `selectors.py`, `services.py` | base de connaissances, lectures, écritures |
| `admin.py` | modération provisoire dans l'admin Django, en attendant l'admin Next |
| `management/commands/foodscan_benchmark.py` | mesure de la précision |

## Et ensuite (après la V1)
1. **Exemples visuels** : retrouver les photos validées les plus proches avec des embeddings d'image (CLIP ou SigLIP, et pgvector), et en joindre 2 ou 3 au prompt pour les plats qui se ressemblent.
2. **Entraînement** : les avis validés, rangés par pays et accompagnés de leur photo (avec consentement), forment le jeu de données d'un modèle spécialisé. Il serait réservé aux régions où le benchmark montre que l'IA généraliste plafonne.

## Questions ouvertes
1. Ajouter `corrected_dish_label` dans `FeedbackInput` (contrat d'API) et le motif `wrong_dish` qui l'accompagne.
2. Consentement à la conservation des photos jointes aux avis : case dédiée, durée de conservation.
3. Qui sont les validateurs de confiance (rôle « modération des avis », D18) et comment on recrute des contributeurs locaux.
4. Rédaction des premières fiches : Afrique de l'Ouest et Afrique centrale en priorité, avec le Cameroun en tête.
