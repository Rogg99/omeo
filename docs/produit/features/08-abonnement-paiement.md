# 08 — Abonnement, paiement & parrainage

## Présentation d'Omeo Plus
- Elle apparaît après l'inscription (on peut la fermer), quand un quota est épuisé, et quand l'utilisateur touche une feature réservée à Plus.
- Elle montre la situation actuelle (Free ou essai, jours et quotas restants), les offres mensuelle et annuelle (l'annuelle mise en avant) et les avantages de Plus.
- Prix en USD : voir [Offres, prix & quotas](../02-offres-quotas.md).

## Moyens de paiement
| Où | Comment | Renouvellement |
|---|---|---|
| App Android | Google Play | automatique |
| App iOS | App Store | automatique |
| Site web (page Abonnement) | **Carte bancaire, Apple Pay, Google Pay**, via un agrégateur de paiement (à choisir) | automatique |

- Pas de Mobile Money.
- Dans l'app, Apple et Google imposent leur propre système de paiement pour un abonnement numérique. La carte, Apple Pay et Google Pay via l'agrégateur sont donc proposés **sur le site**. Un lien depuis l'app vers le site n'est autorisé que dans certains pays ; il sera activé pays par pays.
- L'abonnement est rattaché au **compte Omeo** : payé sur le site ou dans un store, il est reconnu partout.
- **L'API fait foi** : elle vérifie les achats auprès de Google, d'Apple et de l'agrégateur, et c'est elle qui détermine l'état de l'abonnement.
- États possibles : essai, actif, en période de grâce (paiement en échec), résilié (actif jusqu'à la fin de la période), expiré, remboursé.
- L'utilisateur peut restaurer ses achats, gérer son abonnement (dans le store, ou sur le site pour un paiement web) et consulter ses paiements.

## Parrainage
- Chaque utilisateur a un **code d'invitation** et un lien à partager, WhatsApp en priorité.
- Le filleul saisit le code à l'inscription ([01](01-onboarding-compte.md)).
- Le **filleul** obtient **7 jours d'essai** au lieu de 3.
- Le **parrain** gagne **7 jours de Plus** par filleul, dans la limite de **35 jours** au total.
- Un parrainage n'est validé que si le filleul a confirmé son email et enregistré au moins un repas. On vérifie aussi qu'il ne s'agit pas du même appareil.
- L'écran Parrainage affiche le code, le bouton de partage, les filleuls validés et les jours gagnés sur 35.
