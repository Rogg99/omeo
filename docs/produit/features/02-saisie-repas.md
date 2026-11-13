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

### « Pas satisfait ? » : les autres plats possibles
L'écran de vérification met en avant le plat principal détecté. En bas, une rubrique douce, **« Pas satisfait ? »**, propose les autres plats que le modèle a envisagés (3 au plus), du plus probable au moins probable, chacun avec sa probabilité (« 22 % »).
- Toucher une proposition remplace le plat : l'API recharge sa composition type depuis le catalogue et recalcule les totaux. **Pas de nouvel appel à l'IA, pas de quota décompté.**
- **« Autre chose »** ouvre la recherche de plats (noms locaux compris), avec un lien pour décrire le plat si on ne le trouve pas.
- Le choix vaut avis « mauvais plat » : il est enregistré sans étape supplémentaire et nourrit les règles de confusion (voir [foodscan.md](../../technique/foodscan.md)). Un toast léger remercie l'utilisateur.
- Une proposition absente du catalogue reste affichée. La toucher ouvre la recherche, pré-remplie avec son nom.
- Ton : léger et bienveillant, jamais culpabilisant (« On hésitait aussi avec… », « Merci, on retient ! »). La rubrique est repliable et reste discrète quand la confiance est élevée. Quand la confiance est faible, elle est dépliée d'office.
- Les probabilités sont celles du modèle, fournies par l'API. L'app les affiche telles quelles, sans calcul (D1).

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
