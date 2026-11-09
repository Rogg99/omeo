# 04 — Sport & activité

Principe : **automatique d'abord**. Les données viennent de Health Connect (Android) et d'Apple Health (iOS). La saisie manuelle n'est qu'un secours.

## Données importées
| Donnée | À quoi elle sert |
|---|---|
| Pas | Jauge du jour, challenges, analyses |
| Distance | Affichage |
| Calories dépensées | Balance du jour, ajustement de l'objectif |
| Séances (type, durée, calories, fréquence cardiaque) | Journal d'activité, points |
| Poids | Suivi du poids ([03](03-suivi-nutrition.md#poids)) |

- Omeo **lit** ces données et n'écrit jamais rien. L'app l'indique clairement (« Données lues : … / Données écrites : aucune »).
- Le mobile récupère les données à l'ouverture de l'app et en arrière-plan, puis les envoie à l'API sous forme de **totaux par jour** et de résumés de séances. **C'est l'API qui en tire la balance, les objectifs, les points et la validation des challenges.**
- L'autorisation est demandée au moment où elle sert (écran Progression ou Sport), pas pendant l'onboarding. Un refus ne bloque rien.

## Saisie manuelle (secours)
- L'utilisateur choisit une activité (marche, course, football, danse, vélo, musculation, natation, autre), une durée et une intensité.
- L'API estime les calories dépensées à partir de l'activité, de la durée et du poids.
- Si une séance importée recouvre une saisie manuelle, on propose de les fusionner.

## Balance et objectif
- Balance du jour et de la semaine : calories consommées contre calories dépensées.
- Les jours actifs, l'objectif calorique augmente selon l'activité ([règles](../03-regles-metier.md)). L'utilisateur peut désactiver cet ajustement.

## Analyses croisées (Plus)
- Chaque semaine, l'API compare alimentation et activité et en tire des constats. Exemples :
  - « Tu bouges plus le week-end, mais tu manges plus aussi. »
  - « 3 jours sous les 4 000 pas cette semaine. »
- Affichées sur l'accueil et envoyées en notification.

## Exercices et séances guidées
- **Bibliothèque d'exercices**, alimentée depuis l'admin : nom, vidéo courte, consignes, muscles travaillés, niveau, matériel (aucun par défaut).
- **Séances** : enchaînements d'exercices (durée ou répétitions, temps de repos), avec un niveau, une durée totale et un but (cardio, renforcement, mobilité).
- **Lecteur** : vidéo, minuteur, exercice suivant, pause, signal sonore et vibration. À la fin : récapitulatif, calories estimées par l'API, points gagnés.
- Téléchargement pour regarder sans connexion (Plus).
- Free : une sélection de séances. Plus : toutes.
- Vidéos sous-titrées dans toutes les langues de l'app.
