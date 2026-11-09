# 05 — Programmes & challenges

Programmes et challenges sont créés dans l'admin. **La progression et la validation sont calculées par l'API.**

## Programmes (Plus)
Un parcours de plusieurs semaines lié à un objectif : perdre du poids, prendre de la masse, prévenir le diabète…

- **Un seul programme actif à la fois.** En commencer un autre remplace le précédent, après confirmation.
- Chaque jour peut contenir :
  - des **repas suggérés**, tirés des recettes, à ajouter en un geste ;
  - une **séance guidée** ;
  - un **conseil du jour** ;
  - des **tâches**, validées automatiquement quand c'est possible, sinon cochées par l'utilisateur.
- Vue du jour, vue par semaine, pourcentage d'avancement.
- Un jour manqué ne bloque pas la suite.
- À la fin : un bilan (poids, assiduité), un badge et des points.

## Challenges
Plus courts et plus ludiques : **de 7 à 30 jours**, avec **une seule règle par jour**.

| Exemple | Règle quotidienne | Validation |
|---|---|---|
| Hydratation | Boire 2 L d'eau | automatique |
| Assiette équilibrée | Enregistrer un repas suffisamment riche en protéines | automatique |
| 8 000 pas | Faire au moins 8 000 pas | automatique (Health Connect / Apple Health) |
| Bouger 20 minutes | Une séance ou une activité d'au moins 20 minutes | automatique |
| Zéro soda | — | l'utilisateur coche |

- **Plusieurs challenges en même temps** en Plus. Un seul en Free.
- Suivi : calendrier des jours réussis et ratés, série en cours, taux de réussite.
- Un challenge est réussi quand le taux de réussite atteint le seuil fixé (80 % par défaut).
- Récompenses : points et badge.

## Validation
- **Automatique** : l'API vérifie la règle à partir des données (repas, eau, pas, séances, poids), au fil de la journée et en fin de journée.
- **Manuelle** : l'utilisateur coche lui-même.
- Dans l'admin, une règle se définit par une donnée, une condition, un seuil et une période.
