# 01 — Onboarding & compte

## Objectif
Recueillir le minimum nécessaire pour calculer les objectifs de l'utilisateur, puis créer son compte, en moins de 2 minutes.

## Parcours
Écran de démarrage → langue (détectée automatiquement, modifiable) → questionnaire en 9 étapes → création du compte → présentation de Omeo Plus (on peut la fermer) → accueil.

| Étape | Question | Réponse attendue |
|---|---|---|
| 1 | Comment vous appelez-vous ? | Nom et prénom (2 à 60 caractères) |
| 2 | Quel âge avez-vous ? | Date de naissance |
| 3 | Quel est votre genre ? | Homme ou Femme (nécessaire au calcul) |
| 4 | Dans quelle ville vivez-vous ? | Saisie avec suggestions (Dakar, Abidjan, Lomé, Yaoundé…) |
| 5 | Quelle est votre taille ? | En cm (100 à 250) |
| 6 | Quel est votre poids ? | En kg (30 à 300) |
| 7 | Quel est votre objectif de poids ? | En kg, avec un avertissement si la cible contredit l'objectif |
| 8 | Quels sont vos objectifs ? | Un ou plusieurs : perdre du poids, prendre de la masse, manger équilibré, prévenir le diabète, prévenir l'hypertension |
| 9 | Créez votre compte | Email et mot de passe, ou Google / Apple. Code d'invitation facultatif. Acceptation des CGU et des consentements |

- Chaque étape affiche « n / 9 » et permet de revenir en arrière.
- Les réponses sont gardées sur le téléphone jusqu'à la création du compte : fermer l'app ne fait rien perdre. Seule l'étape 9 nécessite une connexion.
- Une fois le compte créé, les objectifs sont calculés ([règles](../03-regles-metier.md)) et l'essai commence : 3 jours, ou 7 avec un code d'invitation valide.

## Compte
- **Mot de passe** : au moins 10 caractères, avec une minuscule, une majuscule, un chiffre et un caractère spécial.
- **Code d'invitation** : 10 caractères maximum, à saisir avant de créer le compte, y compris avec Google ou Apple. Un code invalide est signalé, mais on peut s'inscrire sans.
- **Vérification de l'email** : l'app reste utilisable en attendant, avec un rappel.
- **Mot de passe oublié** : lien de réinitialisation envoyé par email.
- **Consentements** (CGU, confidentialité, données de santé, marketing) : chaque version est enregistrée. Si un document change, l'utilisateur doit l'accepter à nouveau.
- **Suppression du compte** : après confirmation, les données sont effacées sous 30 jours. Un abonnement pris sur un store doit être résilié dans le store, et on l'explique à l'utilisateur.
- **Déconnexion** de l'appareil ou de tous les appareils.
