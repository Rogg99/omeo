# Previews

Maquettes HTML haute fidélité d'Omeo, à ouvrir directement dans un navigateur (pas de serveur ni de build). Point d'entrée : [index.html](index.html).

| Dossier | Contenu |
|---|---|
| [shared/](shared/) | Design tokens communs (couleurs, typo, rayons, ombres, thème sombre) et jeu d'icônes + logo |
| [mobile/](mobile/) | Galerie de tous les écrans de l'app, classés par module. Filtres, thème sombre, arabe (RTL), zoom |
| [admin/](admin/) | Back-office navigable. Le sélecteur de rôle (en bas de la barre latérale) filtre le menu |
| [web/](web/) | Site vitrine : accueil, fonctionnalités, tarifs, abonnement (tous les états), FAQ, contact, légal, suppression de compte, invitation |

## Choix de design

- **Palette** : crème, brun, accent orange, vert désaturé (sauge / kaki profond) qui alterne avec le noir. Les couleurs de données (protéines, glucides, lipides, fibres, sel, eau) sont les mêmes sur toutes les plateformes.
- **Typographie** : Space Grotesk pour les titres et les chiffres (proche des captures), DM Sans pour le texte, Instrument Serif italique pour les accents éditoriaux (« À ton rythme. »). IBM Plex Sans Arabic pour l'arabe.
- **Mobile** :
  - une information clé par écran ;
  - cibles tactiles de 44 px au minimum ;
  - bouton principal toujours en bas, à portée du pouce ;
  - feuilles modales plutôt que des pages pour les actions courtes ;
  - états vides, de chargement, d'erreur et hors connexion prévus partout.
- **Ton** : tutoiement partout, pour la cohérence (les captures mélangeaient « vous » et « tu »).
- **Onglet « Historique »** renommé « Journal », plus parlant pour un suivi du jour.

## Ce qui a été retiré par rapport aux captures

Conformément à [docs/produit/99-decisions.md](../docs/produit/99-decisions.md) :

- la communauté ;
- le scan de produits (code-barres, emballage) ;
- la publication de recettes par les utilisateurs ;
- les prix en FCFA (tout est en USD).

## Limites

- Les photos sont des placeholders en dégradé : à remplacer par de vraies photos de plats.
- Le logo est une reconstitution SVG simplifiée : à remplacer par le fichier officiel.
- Les polices viennent de Google Fonts : sans connexion, le rendu bascule sur les polices système.
- Les drapeaux emoji s'affichent en lettres sous Windows.
