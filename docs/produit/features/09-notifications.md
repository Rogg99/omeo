# 09 — Notifications

Les notifications sont **décidées et envoyées par l'API**. Le mobile les reçoit et les affiche.

## Canaux
- **Push** sur Android et iOS.
- **Centre de notifications** dans l'app (la cloche) : historique, avec les notifications lues et non lues.
- **Email**, uniquement pour le transactionnel : vérification de l'email, mot de passe, reçus, échec de paiement pour un abonnement pris sur le site.

## Types
| Catégorie | Exemples | Désactivable |
|---|---|---|
| Rappels de repas | « Tu n'as pas encore enregistré ton déjeuner » (heures réglables) | oui |
| Hydratation | Rappels espacés, qui s'arrêtent une fois l'objectif atteint | oui |
| Pesée | Une fois par semaine, jour au choix | oui |
| Programmes et challenges | Tâche du jour, jour à valider, fin proche | oui |
| Récompenses | Niveau atteint, badge obtenu, série en danger | oui |
| Prévention | Nouveau conseil, bilan de la semaine | oui |
| Abonnement | Fin d'essai, expiration, quota bientôt épuisé | non |
| Campagnes (depuis l'admin) | Nouveautés, nouveaux contenus, offres | oui (consentement marketing) |

## Règles
- Réglages par catégorie, et des **heures calmes** (22 h à 7 h par défaut).
- 3 notifications push par jour au maximum, hors abonnement.
- Pas de rappel de repas si le repas est déjà enregistré.
- Chaque notification est envoyée dans la langue de l'utilisateur et à son heure locale.
- Les campagnes peuvent cibler une langue, un pays, une offre, un objectif ou les utilisateurs inactifs.
