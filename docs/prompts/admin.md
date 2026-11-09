# Prompt : Admin (Next.js)

> Coller d'abord le [socle commun](README.md#socle-commun-à-coller-en-tête-de-chaque-prompt).

```text
LIVRABLE : le back-office Nyam, dans admin/. Next.js 16 (App Router), React 19, TypeScript strict,
Tailwind 4 et pnpm. Il tourne dans Docker sur http://admin.localhost.

RÉFÉRENCE : previews/admin/ (toutes les vues, menu filtré par rôle) et docs/produit/admin.md.
Endpoints concernés : /admin/* et /auth/* dans contracts/openapi.yaml.

RÈGLE DE SÉCURITÉ ABSOLUE : le navigateur ne connaît jamais l'adresse de l'API ni les jetons.
- Tout passe par le serveur Next. Une base existe déjà : src/app/api/[...path]/route.ts et
  src/lib/api.ts. Il faut la durcir.
- L'API est appelée depuis le serveur (Server Components et Server Actions) avec API_URL_INTERNAL,
  dans un module marqué import "server-only".
- Jetons rangés dans des cookies httpOnly, Secure, SameSite=Strict, avec le préfixe __Host- en
  production. Renouvellement transparent côté serveur.
- Le proxy route handler n'autorise que /admin/* et /auth/* (liste blanche), retire les en-têtes
  sensibles et transmet X-Forwarded-For.
- Protection CSRF sur toutes les mutations (vérification de l'en-tête Origin et jeton double-submit).
- En-têtes : CSP stricte avec nonce, frame-ancestors 'none', HSTS, Referrer-Policy et
  Permissions-Policy, configurés dans next.config.ts et le middleware.
- Le middleware redirige vers /login si la session est absente. Déconnexion après 30 min d'inactivité
  et au bout de 12 h au maximum.

AUTHENTIFICATION :
- Connexion par email et mot de passe, puis double authentification (TOTP ou code de secours).
- Première connexion : enrôlement de la double authentification (QR de l'URI otpauth, codes de secours
  à télécharger).
- Pas d'inscription publique : les comptes sont créés par invitation.

AUTORISATIONS :
- GET /admin/me fournit les rôles et les permissions. Un helper `can(permission)` est partagé entre
  serveur et client.
- Le menu, les pages, les boutons et les actions sont filtrés par permission. Le serveur revérifie
  toujours (l'API reste l'autorité ; un 403 forbidden_role affiche un écran dédié).

STACK :
- Client typé généré depuis le contrat avec openapi-typescript et openapi-fetch (src/lib/api/schema.d.ts,
  script `pnpm gen:api`). Aucun type d'API écrit à la main.
- Données : Server Components pour les lectures, Server Actions pour les mutations, avec validation
  zod en entrée. TanStack Query uniquement pour les vues très interactives (filtres en direct,
  interrogation périodique).
- UI : composants maison sur Radix UI (accessibles), avec les design tokens de previews/shared/tokens.css
  repris en variables CSS et thème Tailwind. Tables avec TanStack Table (tri, filtres et pagination
  côté serveur, état dans l'URL). Formulaires avec react-hook-form et zod.
- Graphiques du tableau de bord : Recharts ou visx, accessibles, cohérents en clair et en sombre.
- Éditeur multilingue :
  - un onglet par langue, avec le nombre de traductions manquantes ;
  - bouton « Proposer une traduction IA » (POST /admin/content/{type}/{id}/translate), dont le résultat
    est relu avant d'être enregistré ;
  - aperçu en arabe, de droite à gauche.
- Médias : téléversement direct vers une URL présignée (POST /admin/media), avec progression, aperçu
  et sous-titres VTT par langue.
- Langue de l'interface admin : français (next-intl), structure prête pour l'anglais.

MODULES (parité complète avec les maquettes) :
- Tableau de bord, avec filtres de période, pays, langue et plateforme. Les blocs non autorisés sont
  masqués.
- Utilisateurs :
  - recherche et filtres ;
  - fiche (offre, quotas, paiements, parrainages, appareils, consentements, demandes de support) ;
  - données de santé masquées, révélées seulement avec un motif obligatoire (journalisé) ;
  - actions avec confirmation et motif.
- Contenus : CRUD typé pour les 15 types, workflow brouillon → relecture → publié → archivé,
  historique des versions, verrou optimiste (conflit 409 : proposer de recharger ou de fusionner).
  Éditeurs dédiés :
  - recette : ingrédients reliés à Food et nutriments calculés par l'API ;
  - programme : jour par jour ;
  - challenge : constructeur de règle (donnée, condition, seuil) ;
  - badges, niveaux et barème de points ;
  - conseils de prévention, avec leurs déclencheurs.
- Traductions : couverture par type de contenu et par langue.
- Avis sur les analyses :
  - les 👎 en premier, avec des filtres ;
  - comparaison côte à côte : photo, réponse de l'IA, version corrigée ;
  - actions : créer un plat ou un aliment, ajouter un autre nom, signaler un défaut, ignorer ;
  - statistiques.
- Abonnements et paiements : offres et prix en USD, quotas, listes, remboursement (web uniquement),
  codes promo.
- Support : file des demandes, assignation, réponse avec modèles, notes internes, statuts.
- Campagnes : rédaction multilingue, segment avec estimation de l'audience en direct, programmation,
  envoi de test, statistiques.
- Réglages : constantes de calcul (avec leurs bornes), IA (modèle, prompt, seuil, budget), features,
  langues, version minimale, pays autorisés pour le paiement web.
- Équipe et rôles, journal d'audit (avec la différence avant et après).

UX :
- Pensé pour l'ordinateur, utilisable sur tablette.
- Barre latérale repliable, raccourcis clavier (⌘K pour la recherche globale).
- Squelettes de chargement, états vides, notifications (toasts), confirmation des actions
  destructives (en tapant le nom).
- Annulation (undo) quand l'action le permet.
- Tous les filtres sont dans l'URL, donc partageables.

QUALITÉ :
- ESLint strict, TypeScript strict avec noUncheckedIndexedAccess, Prettier.
- Vitest et Testing Library pour les composants et les helpers d'autorisation.
- Playwright pour les parcours de bout en bout (connexion avec double authentification, filtrage du
  menu par rôle, publication d'un contenu, traitement d'un avis, remboursement), sur le serveur
  fictif Prism puis sur l'API réelle.
- Accessibilité vérifiée avec axe dans Playwright.

DÉVELOPPEMENT EN PARALLÈLE : tant que l'API n'est pas prête, lance
`npx @stoplight/prism-cli mock contracts/openapi.yaml` et fais pointer API_URL_INTERNAL dessus.

LIVRABLES ANNEXES : README de l'admin, .env.example, CI (lint, typage, tests, build).
```
