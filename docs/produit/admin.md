# Admin

Application web réservée à l'équipe Omeo. Connexion par email et mot de passe, avec double authentification obligatoire.

## Rôles
| Rôle | Ce qu'il gère |
|---|---|
| **Super-admin** | Tout, y compris les comptes de l'équipe, les rôles et les réglages |
| **Contenu** | Aliments, plats, recettes, plantes, exercices, séances, programmes, challenges, badges, conseils de prévention, FAQ, traductions |
| **Support** | Demandes des utilisateurs. Consultation des comptes, et quelques actions : renvoyer l'email de vérification, réinitialiser le mot de passe, prolonger l'essai |
| **Finance** | Offres, prix (USD), quotas, abonnements, paiements, remboursements, codes promo, parrainage |
| **Modération des avis** | Avis des utilisateurs sur les analyses de l'IA |

- Une personne peut avoir plusieurs rôles.
- Chaque action est **historisée** : qui, quoi, quand, avant et après.
- Les données de santé sont masquées par défaut, et chaque consultation est historisée.

## Modules

### Tableau de bord
Inscriptions, utilisateurs actifs, rétention, passage de l'essai à Plus, revenus par canal (stores, site), analyses par jour, coût de l'IA, part d'avis négatifs, demandes de support en attente. Filtres par période, pays, langue et plateforme.

### Utilisateurs
- Recherche par email, nom ou identifiant.
- Fiche : profil, offre, quotas, paiements, parrainages, appareils, consentements.
- Actions : suspendre ou réactiver, offrir des jours de Plus, remettre un quota à zéro, exporter ou supprimer les données.

### Contenus
- Chaque contenu passe par les étapes brouillon, relecture, publié, archivé.
- Édition langue par langue, avec un indicateur de traductions manquantes et une traduction automatique à relire.
- Médias : images, vidéos d'exercices, sous-titres par langue.
- Contenus gérés : aliments, plats, recettes, plantes, exercices, séances, programmes (jour par jour), challenges (avec leurs règles), badges, barème de points, niveaux, conseils de prévention (avec leurs déclencheurs), FAQ, CGU et politique de confidentialité (versionnées).

### Avis sur les analyses
- Liste des avis, avec les 👎 en premier et des filtres : motif, plat détecté, niveau de confiance, langue, date.
- Détail : la photo, la réponse d'origine de l'IA, la version corrigée par l'utilisateur, son commentaire.
- Actions : marquer comme traité, créer ou compléter un plat ou un aliment à partir de la correction, ajouter un autre nom à un plat, signaler un défaut de l'analyse, ignorer.
- Statistiques : fiabilité perçue par plat et par pays, plats les plus contestés.

### Abonnements et paiements
- Offres, prix en USD et quotas.
- Abonnements et paiements de tous les canaux (Google Play, App Store, site), avec leur état.
- Remboursements, codes promo, réglages du parrainage.

### Support
Demandes avec statut, catégorie et personne assignée. Réponse par email avec notification dans l'app, modèles de réponse, notes internes.

### Notifications et campagnes
Rédiger une notification dans toutes les langues, choisir les destinataires (langue, pays, offre, objectif, inactivité), la programmer, suivre les envois et les ouvertures.

### Réglages
Constantes de calcul ([règles métier](03-regles-metier.md)), modèle d'IA utilisé sur OpenRouter et ses instructions, activation de features, langues actives, version minimale de l'app exigée.
