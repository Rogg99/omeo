# 07 — Contenus

Tous les contenus sont **produits par l'équipe** dans l'admin et **traduits** dans toutes les langues de l'app.

## Recettes
- Fiche : photo, nom, pays, temps, difficulté, nombre de portions, ingrédients, étapes, apports par portion (calculés par l'API à partir de la base d'aliments), étiquettes (healthy, végétarien, riche en protéines…).
- Recherche, filtres (pays, objectif, étiquettes, temps) et favoris.
- « Ajouter à mon repas » enregistre une portion dans le suivi.
- Free : une sélection. Plus : toutes les recettes.

## Plantes & nutrition
- Fiche : photo, nom courant, nom scientifique, étiquettes (usage traditionnel, soutien nutritionnel, prudence).
- Trois sections : **usage traditionnel**, **bienfaits nutritionnels**, **précautions d'usage**.
- Recherche et favoris.
- **Mention obligatoire** : contenu informatif, qui ne remplace pas un avis médical. Les interactions et les contre-indications (grossesse…) sont signalées.

## Prévention personnalisée
- Conseils (eau, sel, sucre, fibres, activité…) déclenchés par l'API selon les données de l'utilisateur, par exemple trop de sel trois jours de suite ou pas assez de fibres.
- Sans données suffisantes : invitation à photographier un premier repas.
- Chaque conseil renvoie vers des recettes ou des plantes utiles.
- Conseils de base en Free, conseils détaillés et bilan hebdomadaire en Plus.

## Base d'aliments et catalogue de plats
Invisibles en tant que tels pour l'utilisateur, mais indispensables à l'analyse :
- **Aliments** : valeurs pour 100 g (calories, protéines, glucides dont sucres, lipides dont saturés, fibres, sel), avec les noms locaux et les traductions.
- **Plats** : composition type, portion standard, pays d'origine, autres noms.
- Enrichis par l'équipe, notamment à partir des avis sur les analyses.
