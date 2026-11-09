# 06 — Gamification

Points, niveaux et badges. **Tout est calculé et attribué par l'API**, puis affiché par le mobile.

## Points
Barème de départ, modifiable dans l'admin :

| Action | Points | Limite |
|---|---|---|
| Repas enregistré | 10 | 4 par jour |
| Journée complète (au moins 3 repas) | 20 | 1 par jour |
| Objectif d'eau atteint | 10 | 1 par jour |
| Objectif calorique respecté (à 10 % près) | 20 | 1 par jour |
| Objectif de pas atteint | 15 | 1 par jour |
| Séance guidée terminée | 30 | 2 par jour |
| Pesée enregistrée | 5 | 1 par semaine |
| Jour de challenge réussi | 10 | — |
| Challenge réussi | 100 | — |
| Programme terminé | 300 | — |
| Avis donné sur une analyse | 5 | 3 par jour |
| Filleul inscrit | 50 | — |

Les limites évitent qu'on accumule des points en répétant la même action.

## Niveaux
- Chaque niveau demande un peu plus de points que le précédent.
- Chaque palier porte un nom sur un thème culinaire (noms à choisir), traduit dans toutes les langues.
- Passer un niveau déclenche une animation et une notification.

## Badges
- Familles : régularité (7, 30, 100 jours d'affilée), nutrition, hydratation, activité, challenges, programmes, découverte (recettes et plantes consultées), parrainage.
- Chaque badge s'affiche verrouillé, en cours (avec progression) ou obtenu (avec sa date).
- Les badges se créent dans l'admin : icône, nom, condition d'obtention, points bonus.

## Séries
- La série compte les jours consécutifs avec au moins un repas enregistré.
- En Plus, un jour manqué par semaine peut être couvert sans casser la série.

## Écran « Mes récompenses »
Niveau actuel, progression vers le suivant, points de la semaine, badges obtenus et à venir, historique des points.

Pas de classement entre utilisateurs, puisqu'il n'y a pas de communauté.
