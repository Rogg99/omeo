# Prompt : application mobile (Flutter)

> Coller d'abord le [socle commun](README.md#socle-commun-à-coller-en-tête-de-chaque-prompt).

```text
LIVRABLE : l'application mobile Nyam, dans mobile/. Flutter, version fixée par FVM, pour Android et iOS.
C'est le produit principal.

RÉFÉRENCE VISUELLE : previews/mobile/ (127 écrans, avec thème sombre et arabe).
- Reproduis fidèlement chaque écran et chaque état.
- previews/shared/tokens.css devient le ThemeData : couleurs claires et sombres, typographies
  (Space Grotesk, DM Sans, Instrument Serif et IBM Plex Sans Arabic, embarquées dans l'app, sans
  Google Fonts au runtime), rayons, ombres, espacements.
- Les composants de previews/mobile/components.js (ring, bar, sheet, macro, tabbar, appbar…) deviennent
  des widgets dans lib/core/widgets/.

RÈGLE ABSOLUE : le mobile affiche, l'API calcule (D1). Aucune somme, différence, pourcentage ou
arrondi métier côté client. Seules exceptions :
- D22 : avertissement « poids cible » à l'étape 7 de l'onboarding ;
- D23 : conversion kg/lb, cm/ft et cl/oz à l'affichage et à la saisie, dans un seul helper testé
  (lib/core/units/).

STACK :
- État et injection de dépendances : flutter_riverpod (avec riverpod_generator).
- Navigation : go_router, avec liens profonds nyam:// et App Links / Universal Links pour /i/{code}.
- Client HTTP : généré depuis contracts/openapi.yaml (openapi-generator, dart-dio) dans packages/nyam_api,
  jamais modifié à la main. Script tool/gen_api.sh.
- Modèles UI : freezed. Stockage local : drift (SQLite), pour le cache et la file d'attente hors connexion.
- Jetons : flutter_secure_storage.
- Santé : package health (Health Connect et HealthKit, en lecture seule).
- Push : firebase_messaging et flutter_local_notifications.
- Achats : in_app_purchase (StoreKit 2 et Play Billing).
- Médias : camera ou image_picker et image (compression), video_player avec chewie ou media_kit
  (HLS et sous-titres VTT).
- Saisie vocale : speech_to_text, transcription sur l'appareil (D24).
- Langues : flutter_localizations avec des fichiers ARB pour les 8 langues (intl). Arabe de droite à
  gauche avec Directionality.
- Qualité : very_good_analysis (lint strict), tests unitaires, de widgets et golden (alchemist),
  et integration_test.

ARCHITECTURE (lib/) :
- app/ : bootstrap, routeur, thème, gestion des erreurs globales.
- core/ : api (intercepteurs), l10n, router, theme, widgets, units, offline (file d'attente),
  analytics, config.
- features/<module>/ : data (dépôts qui encapsulent le client généré et le cache), application
  (providers et contrôleurs), presentation (écrans et widgets). Modules : onboarding, auth, meals,
  tracking, activity, programs, gamification, content, subscription, notifications, profile, support.
  Un dossier training est à ajouter (exercices et lecteur de séance).
- Pas de logique dans les widgets. Les écrans consomment des AsyncValue et gèrent quatre états :
  données, chargement (squelettes comme dans les maquettes), erreur (selon le code de l'erreur) et
  vide.

RÉSEAU ET SÉCURITÉ :
- Intercepteur d'authentification : renouvellement unique et partagé en cas de 401 token_expired.
  Sur 401 not_authenticated, déconnexion propre.
- En-têtes sur chaque appel : Accept-Language, X-Timezone (flutter_timezone), X-Client.
  Idempotency-Key générée et persistée avec chaque écriture mise en file d'attente.
- Gestion globale des codes d'erreur :
  - 426 upgrade_required : écran de mise à jour forcée ;
  - 403 plan_required : présentation de Plus ;
  - 429 quota_exceeded : feuille de quota (en Free, proposer Plus ; en Plus, date de remise à zéro) ;
  - 403 consent_required : réacceptation des CGU ;
  - 403 account_suspended : écran dédié.
- Épinglage TLS du domaine de production. Aucune donnée sensible dans les logs. Écran masqué dans le
  sélecteur d'apps sur iOS. Pas de capture d'écran sur l'écran de paiement (Android FLAG_SECURE).
- Hors connexion :
  - les étapes 1 à 8 de l'onboarding sont persistées localement (drift) jusqu'à la création du compte ;
  - repas, eau, poids et activités sont mis en file d'attente puis rejoués au retour du réseau
    (connectivity_plus et WorkManager / BGTaskScheduler) ;
  - un élément en attente s'affiche « en cours de calcul » et les totaux ne changent qu'à la réponse
    de l'API ;
  - les lectures servent le cache puis le rafraîchissent (stale-while-revalidate) ;
  - une bannière signale l'absence de connexion.

PARCOURS CLÉS :
- Photo :
  - prise de vue ou galerie, compression à 1600 px maximum en JPEG qualité 80 sur l'appareil ;
  - POST /me/uploads, PUT présigné, puis POST /me/analyses ;
  - interrogation de GET /me/analyses/{id} en respectant Retry-After, avec une animation d'analyse ;
  - écran « Ingrédients présélectionnés », puis POST /me/meals ;
  - mise à jour du jour avec la réponse (day et rewards), animation des points, avis 👍/👎.
- Quotas : GET /me/quotas affiché avant chaque photo.
- Santé :
  - permission demandée au moment où elle sert (écran Progression ou Sport), jamais à l'onboarding ;
  - synchronisation à l'ouverture et en arrière-plan : totaux par jour depuis last_sync_at (30 jours
    au maximum), envoyés à POST /me/health/sync ;
  - aucune écriture dans Health Connect ou HealthKit.
- Lecteur de séance : vidéo HLS, minuteur, repos, signal sonore et vibration, pause, mode portrait
  et paysage, écran maintenu allumé (wakelock_plus), téléchargement hors connexion pour Plus.
- Achats : produits lus dans /billing/plans, achat via le store, puis POST /me/subscription/verify.
  L'achat n'est terminé (completePurchase) qu'après la réponse de l'API. Restauration des achats.
  Lien vers le site uniquement si web_checkout_allowed est vrai.
- Parrainage : partage WhatsApp en priorité (share_plus). Code d'invitation récupéré depuis le lien
  d'installation (Play Install Referrer sur Android) et prérempli.
- Notifications : jeton enregistré via POST /me/devices. Les liens profonds ouvrent le bon écran.
  Centre de notifications avec badge du nombre de non lues.

FLUIDITÉ ET RESPONSIVITÉ :
- 60 ou 120 images par seconde : listes paresseuses, const partout où c'est possible,
  RepaintBoundary sur les graphiques, images en cache (cached_network_image) avec blurhash en attendant.
- Démarrage à froid en moins de 2 s sur un Android d'entrée de gamme : écran de démarrage natif,
  chargement différé des modules lourds.
- Mise en page adaptative : du petit téléphone (320 dp) à la tablette, sans débordement. Tester la
  taille de texte à 200 %, le mode sombre, l'arabe et les mouvements réduits.
- Retour haptique sur les actions clés. Animations courtes (200 à 300 ms) avec des courbes cohérentes.

ACCESSIBILITÉ : Semantics sur les éléments interactifs et les graphiques (valeur lue en texte),
contraste AA, cibles de 48 dp.

TESTS :
- Unitaires : dépôts, file d'attente hors connexion, unités, intercepteurs.
- Widgets et golden : chaque écran clé en clair, sombre et arabe.
- integration_test : onboarding complet, ajout d'un repas par photo, achat (sandbox), parcours
  hors connexion puis retour du réseau.

DÉVELOPPEMENT EN PARALLÈLE :
- Tant que l'API n'est pas prête : `npx @stoplight/prism-cli mock contracts/openapi.yaml -p 4010`,
  avec un flavor « mock » qui pointe dessus.
- Flavors : mock, dev (http://api.localhost, ou http://10.0.2.2 depuis l'émulateur), staging, prod.
  Configuration par --dart-define-from-file.

LIVRABLES ANNEXES :
- README du mobile (installation, flavors, génération du client, tests).
- CI GitHub Actions : analyse, tests et build Android et iOS.
- Fastlane (squelette).
- Icônes et écrans de démarrage (flutter_launcher_icons, flutter_native_splash).
```
