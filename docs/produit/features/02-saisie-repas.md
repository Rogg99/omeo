# 02 — Saisie des repas

On ajoute un repas depuis le bouton central **« + »** de la barre de navigation, ou depuis les actions rapides de l'accueil. Il y a trois façons de le faire.

## 1. Photo du plat (analyse par l'IA)
1. L'utilisateur prend une photo ou en choisit une dans sa galerie.
2. La photo est analysée par un modèle d'IA via OpenRouter. Il renvoie le nom du plat, les ingrédients, leur quantité estimée et un niveau de confiance.
3. Chaque ingrédient est rapproché de la base d'aliments d'Omeo. **Les valeurs nutritionnelles viennent de cette base**, pas de l'IA.
4. L'écran « Ingrédients présélectionnés » permet de décocher un ingrédient, d'ajuster une quantité ou d'en ajouter un.
5. L'utilisateur confirme le type de repas (proposé selon l'heure), puis valide.
6. Le repas est enregistré, les totaux du jour se mettent à jour et l'utilisateur gagne des points.

Cas particuliers :
- Photo floue ou sans nourriture : message explicite, et l'analyse ne compte pas dans le quota.
- Confiance faible : on invite l'utilisateur à vérifier les ingrédients.
- Plat présent dans le catalogue : on propose la recette correspondante.
- La photo est conservée avec le repas et l'utilisateur peut la supprimer.

## 2. Saisie vocale ou en texte libre (Plus)
- L'utilisateur dicte ou tape son repas, par exemple « une assiette de ndolé avec deux plantains frits ».
- L'IA en extrait les ingrédients et les quantités, puis on arrive sur le même écran de correction que pour la photo.

## 3. Plat du catalogue
- Recherche dans le catalogue de plats, avec un filtre par pays, plus les plats récents et favoris.
- La portion standard est modifiable.

## Avis sur une analyse
Après chaque analyse par l'IA (photo ou saisie vocale) :
- L'utilisateur peut donner un 👍 ou un 👎, préciser un motif (mauvais plat, ingrédient manquant, quantités fausses, autre) et laisser un commentaire.
- Les corrections qu'il a faites sont enregistrées avec l'avis, à côté de la réponse d'origine de l'IA.
- Les avis arrivent dans l'admin. L'équipe s'en sert pour enrichir la base de plats et améliorer l'analyse.

## Gestion des repas
- Modifier, supprimer, déplacer vers un autre repas ou un autre jour.
- Dupliquer un repas déjà mangé.
- Sans connexion : les photos et les saisies sont mises en attente, puis envoyées au retour du réseau. Comme les calculs sont faits par l'API, un repas en attente s'affiche « en cours de calcul » et les totaux ne se mettent à jour qu'à la réponse du serveur.

## Quotas
Le nombre d'analyses restantes est affiché avant chaque photo. Le détail est dans [Offres, prix & quotas](../02-offres-quotas.md).
