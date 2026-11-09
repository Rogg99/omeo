# Décisions & questions ouvertes

## Décisions (9 novembre 2026)

| # | Sujet | Décision |
|---|---|---|
| D1 | Architecture | **Seule l'API fait les calculs. Le mobile se contente d'afficher.** |
| D2 | Mobile | Flutter, Android et iOS |
| D3 | IA | Modèles d'IA via OpenRouter |
| D4 | Communauté | Retirée |
| D5 | Scan de produits | Retiré (ni code-barres, ni emballage) |
| D6 | Recettes | Produites par l'équipe uniquement |
| D7 | Sport | Automatique d'abord (Health Connect, Apple Health), saisie manuelle en secours |
| D8 | Exercices | Bibliothèque d'exercices en vidéo et séances guidées |
| D9 | Poids | Saisie manuelle, et import depuis Health Connect / Apple Health quand c'est possible |
| D10 | Programmes et challenges | Un programme actif à la fois, plusieurs challenges en parallèle |
| D11 | Gamification | Points, niveaux et badges |
| D12 | Free / Plus | Free : une sélection de séances, un challenge, 3 analyses photo par jour, pas de saisie vocale. Plus : tout le reste |
| D13 | Essai | 3 jours, 7 jours pour un filleul |
| D14 | Parrainage | 7 jours de Plus par filleul pour le parrain, jusqu'à 35 jours |
| D15 | Devise | Tout en USD |
| D16 | Paiement | Stores dans l'app. Carte, Apple Pay et Google Pay via un agrégateur sur le site. Pas de Mobile Money |
| D17 | Site web | Vitrine et landing, plus la page de paiement |
| D18 | Admin | Rôles contenu, support, finance et modération des avis. Gestion des avis sur les analyses |
| D19 | Langues | 8 au lancement : FR, EN, ES, PT, AR, ZH, JA, DE. D'autres ensuite |
| D20 | Notifications | Rappels (repas, eau, pesée, challenges) et campagnes depuis l'admin |
| D21 | Design | Couleurs actuelles conservées, vert désaturé, alternance noir et vert |
| D22 | Onboarding hors connexion | Exception à D1 : l'avertissement « poids cible incohérent avec l'objectif » (étape 7) est une simple validation de saisie, faite par le mobile. Les objectifs eux-mêmes restent calculés par l'API |
| D23 | Unités | L'API stocke et renvoie tout en métrique. Le mobile convertit en lb, ft ou oz uniquement pour l'affichage et la saisie |
| D24 | Saisie vocale | Transcription sur l'appareil (reconnaissance vocale du système). L'API reçoit le texte |
| D25 | Contrat d'API | Écrit avant le code ([contracts/openapi.yaml](../../contracts/openapi.yaml)). Les clients TypeScript et Dart sont générés à partir de ce fichier |
| D26 | Autorisations | Le code vérifie des permissions atomiques, jamais des rôles. Correspondance rôle → permissions dans le code, refus par défaut, matrice dans [controle-acces.md](../technique/controle-acces.md) |
| D27 | Validation à quatre yeux | Publier un contenu, programmer une campagne, modifier un prix ou des quotas, modifier les constantes nutritionnelles, rembourser plus de 50 $ : validation par une autre personne, jamais par l'auteur |
| D28 | Step-up | Les actions sensibles de l'admin exigent un TOTP de moins de 15 min |
| D29 | Droits Plus | Recalculés par l'API à chaque requête, jamais lus dans le jeton |
| D30 | Email non vérifié | App utilisable. Paiement web, changement d'email, export de données et validation du parrainage exigent un email vérifié |
| D31 | Compte suspendu | Sessions révoquées, tout accès refusé, sauf le support et la suppression du compte (RGPD) |
| D32 | Design tokens et traductions | Tokens dans un JSON unique (format W3C) d'où sont générés le CSS et le thème Flutter. Traductions en ICU MessageFormat, avec le français comme source |

## Questions ouvertes
1. Prix en USD : 4,49 $ et 46,99 $, ou 4,99 $ et 49,99 $ ?
2. Quotas de l'essai sur 3 jours (aujourd'hui 28 analyses et 10 saisies vocales, prévus pour 4 jours).
3. Choix de l'agrégateur de paiement (carte, Apple Pay, Google Pay, en USD).
4. Pays où l'app pourra renvoyer vers le paiement sur le site.
5. Âge minimum pour s'inscrire.
6. Liste définitive des objectifs proposés à l'onboarding.
7. Production des vidéos d'exercices.
8. Validation des calculs nutritionnels par un ou une nutritionniste.
9. Noms des niveaux.
10. Modèles OpenRouter retenus et budget d'IA par utilisateur.
