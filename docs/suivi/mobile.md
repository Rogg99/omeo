# Suivi du développement mobile

> Mis à jour le 16 novembre 2026. Les maquettes de référence sont dans [previews/mobile/screens](../../previews/mobile/screens), et le cahier des charges dans [docs/prompts/mobile.md](../prompts/mobile.md).
> **Mise à jour :** chaque session modifie ce fichier dans le commit qui termine un écran ou un module. Elle change le statut, la branche et la date de la ligne concernée.

## Légende

| Statut | Signification |
|---|---|
| ✅ Fait | Terminé et fusionné dans `main` |
| 🔀 À fusionner | Terminé sur la branche de la session, pas encore dans `main` |
| 🚧 En cours | Commencé par la session responsable |
| ⏳ À faire | Pas commencé |
| ⛔ Bloqué | Attend une décision ou un changement externe (voir [Blocages](#blocages)) |

## Sessions

| Session | Branche | Dossier | Périmètre |
|---|---|---|---|
| Socle | `main` | `omeo/` | Socle, widgets, réseau, accueil, routeur. Terminé. |
| **A** | `mobile-a` | `omeo-mobile-a/` | Onboarding, Compte, Journal, Progression, Profil, Notifications, Support |
| **B** | `mobile-b` | `omeo-mobile-b/` | Repas et hors connexion, Plus et Parrainage, Sport et Séances, Programmes, Challenges, Récompenses, Contenus |

## Vue d'ensemble

| Module | Session | Écrans | ✅ | 🔀 | 🚧 | ⏳ |
|---|---|---|---|---|---|---|
| Accueil | Socle | 5 | 5 | | | |
| Onboarding | A | 16 | 16 | | | |
| Compte | A | 6 | 6 | | | |
| Journal | A | 4 | 4 | | | |
| Progression | A | 7 | 7 | | | |
| Profil | A | 13 | | | | 13 |
| Notifications | A | 3 | | | | 3 |
| Support | A | 4 | | | | 4 |
| Repas | B | 17 | 17 | | | |
| Plus et Parrainage | B | 7 | 7 | | | |
| Sport | B | 5 | 5 | | | |
| Séances | B | 7 | | | 7 | |
| Programmes | B | 6 | | | | 6 |
| Challenges | B | 5 | | | | 5 |
| Récompenses | B | 4 | | | | 4 |
| Recettes | B | 4 | | | | 4 |
| Plantes et Prévention | B | 4 | | | | 4 |
| États système | Socle, A, B | 10 | 10 | | | |
| **Total** | | **127** | **77** | | **7** | **43** |

Avancement : **77 écrans terminés sur 127 (61 %)**, tous dans `main`.

## Détail par écran

### Socle (terminé)

| Écran | Titre | Statut | Commit |
|---|---|---|---|
| HOM-01 | Accueil · journée en cours | ✅ | `9c2a11e` |
| HOM-02 | Accueil · premier jour | ✅ | `9c2a11e` (sans la checklist, voir B-01) |
| HOM-03 | Accueil · jour passé | ✅ | `9c2a11e` |
| HOM-04 | Accueil · objectif dépassé | ✅ | `751b782` |
| HOM-05 | Accueil · calcul en attente | ✅ | `79622b6` (file hors connexion, session B) |
| SYS-01 | Chargement (squelette) | ✅ | `9c2a11e` |
| SYS-03 | Erreur de chargement | ✅ | `9c2a11e` |
| SYS-04 | Mise à jour exigée | ✅ | `5cb8c45` |
| SYS-08 | Accueil · thème sombre | ✅ | `9c2a11e` |
| SYS-09 | Accueil · arabe (RTL) | ✅ | `9c2a11e` |

### Session A

| Écran | Titre | Statut | Branche | Commit |
|---|---|---|---|---|
| ONB-01 à ONB-16 | Démarrage, langue, bienvenue, étapes 1 à 9, code invalide, calcul et plan prêt | ✅ | `main` | `752855d` |
| ACC-01 à ACC-06 | Connexion, erreur, mot de passe oublié, lien envoyé, nouveau mot de passe, vérification de l'email | ✅ | `main` | `752855d` |
| SYS-05 | Nouvelles CGU à accepter | ✅ | `main` | `752855d` |
| HIS-01 | Journal du jour | ✅ | `main` | `a6e7b1e` |
| HIS-02 | Calendrier | ✅ | `main` | `a6e7b1e` |
| HIS-03 | Ajouter de l'eau | ✅ | `main` | `a6e7b1e` |
| HIS-04 | Journée vide | ✅ | `main` | `a6e7b1e` |
| PRO-01 | Progression · 7 jours | ✅ | `main` | `a6e7b1e` |
| PRO-02 | Progression · sel | ✅ | `main` | `a6e7b1e` |
| PRO-03 | Période réservée à Plus | ✅ | `main` | `a6e7b1e` |
| PRO-04 | Progression · vide | ✅ | `main` | `a6e7b1e` |
| PRO-05 | Autorisation santé | ✅ | `main` | `a6e7b1e` |
| PRO-06 | Suivi du poids | ✅ | `main` | `a6e7b1e` |
| PRO-07 | Nouvelle pesée | ✅ | `main` | `a6e7b1e` |
| PRF-01 à PRF-13 | Profil, corps et objectif, compte, mot de passe, santé, paramètres, langue, unités, confidentialité, déconnexion, suppression (2), noter Omeo | ⏳ | | |
| NOT-01 à NOT-03 | Centre de notifications, aucune notification, réglages | ⏳ | | |
| SUP-01 à SUP-04 | Aide et contact, formulaire, message envoyé, réponse du support | ⏳ | | |

### Session B

| Écran | Titre | Statut | Branche | Commit |
|---|---|---|---|---|
| MEA-01 | Menu « + » | ✅ | `main` | `aec703b` |
| MEA-02 | Viseur photo | ✅ | `main` | `f75dcee` |
| MEA-03 | Analyse en cours | ✅ | `main` | `a7f31b2` |
| MEA-04 à MEA-07 | Ingrédients présélectionnés, confiance faible, ajout d'ingrédient, quantité, « Pas satisfait ? » | ✅ | `main` | `64a831e` |
| MEA-08 | Photo inexploitable | ✅ | `main` | `a7f31b2` |
| MEA-09, MEA-10 | Repas enregistré, avis négatif | ✅ | `main` | `2a89e49` |
| MEA-11, MEA-12 | Saisie vocale, saisie en texte | ✅ | `main` | `146ec3c` |
| MEA-13, MEA-14 | Catalogue de plats, portion | ✅ | `main` | `e61403c` |
| MEA-15 à MEA-17 | Détail, déplacement, suppression d'un repas | ✅ | `main` | `255f0d8` |
| SYS-02 | Hors connexion | ✅ | `main` | `79622b6` |
| SYS-06 | Caméra refusée | ✅ | `main` | `f75dcee` |
| SYS-07 | Annuler une action | ✅ | `main` | `255f0d8` |
| PLS-01 | Présentation d'Omeo Plus (et SYS-10 en sombre) | ✅ | `main` | `1f29fa0` |
| PLS-02, PLS-03 | Quota épuisé en Free, en Plus | ✅ | `main` | `a89d73e` |
| PLS-04 à PLS-06 | Mon abonnement, paiement en échec, historique | ✅ | `main` | `7daf424` |
| REF-01 | Parrainage | ✅ | `main` | `1f5a057` (voir B-04) |
| SPO-01 à SPO-05 | Sport : aujourd'hui, ajout, fusion, balance de la semaine, analyses croisées | ✅ | `main` | `9ef27af` (voir B-03) |
| EXO-01 à EXO-07 | Bibliothèque, fiche, séances guidées, détail, lecteur exercice, repos, séance terminée | 🚧 | `mobile-b` | dépôts `eb926a6`, dépendances `00aa926`, moteur du lecteur `49ed165` |
| PRG-01 à PRG-06 | Programmes | ⏳ | | |
| CHA-01 à CHA-05 | Challenges | ⏳ | | |
| REW-01 à REW-04 | Récompenses | ⏳ | | |
| REC-01 à REC-04 | Recettes | ⏳ | | |
| PLA-01, PLA-02, PRV-01, PRV-02 | Plantes et prévention | ⏳ | | |

## Blocages

Les décisions marquées « toi » attendent une réponse de l'utilisateur.

| # | Sujet | Ce qui bloque | Impact | Qui |
|---|---|---|---|---|
| B-01 | Contrat `Home.getting_started` | Proposition dans [CHANGES.md](../../contracts/CHANGES.md), non validée | Checklist « Pour bien démarrer » de HOM-02 absente | toi, puis A |
| B-02 | Contrat `DaySummary.activity` | Proposition non validée | Ligne des pas et de la synchro absente de la balance (HOM-01) | toi, puis A |
| B-03 | Contrat `ActivityOverview.week_summary` | Proposition non validée (sur `mobile-b`) | Résumé de la semaine de SPO-04 | toi, puis B |
| B-04 | Contrat `ReferralOverview.days_per_referral` et `referee_trial_days` | Proposition non validée (sur `mobile-b`) | Textes de REF-01 sur les jours gagnés | toi, puis B |
| B-05 | Doublon dans CHANGES.md | Une ligne « servers / staging » est encore « Proposé » alors que le changement est appliqué (contrat 1.1.5) | Aucun ; ligne à clore | toi (validation) |
| A-01 | Intégrations natives Google / Apple et Health Connect / HealthKit | Identifiants OAuth par flavor et paquet `health` à configurer | Boutons sociaux et connexion santé masqués hors mock | toi |
| B-06 | `Gauge.over_by` côté API | Champ dans le contrat 1.1.5, pas encore renvoyé par l'API | HOM-04 vide hors mock | agent API |

## Avant la mise en production

Ces valeurs à renseigner ne bloquent pas le développement.

| Sujet | Où | État |
|---|---|---|
| Empreintes TLS de l'API (deux, dont une de secours) | `mobile/config/staging.json`, `prod.json` : `API_PINS` | ⏳ `A_RENSEIGNER`, l'app refuse de démarrer sans |
| Identifiant App Store | `IOS_APP_STORE_ID` | ⏳ vide |
| Traductions es, pt, ar, zh, ja, de | `shared/i18n/<langue>.json` | ⏳ repli sur l'anglais |
| Icônes et écrans de démarrage, Fastlane, CI GitHub Actions | `mobile/` | ⏳ non commencés (livrables annexes) |
| Liens profonds `omeo://`, App Links et Universal Links | routeur, fichiers `.well-known` du site | ⏳ non commencés |

## Fusions

| Date | Branche → `main` | Contenu |
|---|---|---|
| 2026-11-16 | `mobile-b` | Repas (sauf MEA-04 à 07), file hors connexion, Plus, Parrainage |
| 2026-11-16 | `mobile-a` | Onboarding, Compte, SYS-05, Journal, Progression |
| 2026-11-16 | `mobile-b` | MEA-04 à 07, Sport, dépôts et moteur des Séances |
| à faire | `mobile-b` | Séances (écrans), Programmes, Challenges, Récompenses, Contenus |
