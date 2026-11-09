# Prompt : site web (Next.js)

> Coller d'abord le [socle commun](README.md#socle-commun-à-coller-en-tête-de-chaque-prompt).

```text
LIVRABLE : le site public d'Omeo, dans web/. Next.js 16 (App Router), React 19, TypeScript strict,
Tailwind 4 et pnpm. Il tourne dans Docker sur http://localhost.

RÉFÉRENCE : previews/web/ (accueil, fonctionnalités, tarifs, abonnement et tous ses états, FAQ, contact,
pages légales, suppression de compte, invitation) et docs/produit/site-vitrine.md.
Pas d'espace utilisateur, à part la page Abonnement.

ENDPOINTS UTILISÉS (contracts/openapi.yaml) :
- /billing/plans, /faq, /legal/{kind}, /referral/check, /support/tickets, /account-deletion,
  /account-deletion/confirm ;
- /auth/login, /auth/social, /auth/refresh, /auth/logout ;
- /me/subscription, /me/payments, /me/billing/checkout, /me/billing/promo-check, /me/billing/portal.

SÉCURITÉ :
- L'adresse de l'API et les jetons ne sont jamais visibles du navigateur. Le proxy existe déjà :
  src/app/api/[...path]/route.ts et src/lib/api.ts.
- Le proxy n'autorise qu'une liste blanche des endpoints ci-dessus, avec limitation de débit
  côté Next.
- Appels serveur via API_URL_INTERNAL, dans un module marqué import "server-only".
- Session de la page Abonnement : jetons dans des cookies httpOnly, Secure, SameSite=Lax,
  avec renouvellement côté serveur.
- CSRF sur les mutations (vérification de l'Origin). CSP stricte avec nonce : seuls le domaine de
  l'agrégateur de paiement et Turnstile sont autorisés. HSTS, Referrer-Policy, Permissions-Policy.
- Les formulaires publics (contact, suppression de compte) passent par des Server Actions, avec
  validation zod et captcha Cloudflare Turnstile vérifié par l'API.
- Le paiement est hébergé par l'agrégateur, par redirection vers checkout_url : aucune donnée de carte
  ne transite par le site.

LANGUES ET RÉFÉRENCEMENT :
- 8 langues avec une adresse par langue (/fr, /en, /es, /pt, /ar, /zh, /ja, /de), via next-intl (messages/<lang>.json générés depuis shared/i18n).
  Langue détectée par Accept-Language à la première visite, puis mémorisée dans un cookie.
- Arabe affiché de droite à gauche (dir="rtl", propriétés CSS logiques partout).
- Pages statiques ou ISR : la FAQ, les pages légales et les tarifs sont revalidés toutes les 10 min
  et à la demande, via un webhook de revalidation signé appelé par l'API à la publication.
- Métadonnées par page, hreflang, URL canoniques, Open Graph et Twitter, images OG générées
  (next/og), sitemap.xml, robots.txt, données structurées JSON-LD (Organization, SoftwareApplication,
  FAQPage, Product et Offer pour les tarifs).

PERFORMANCE (réseau mobile lent, priorité absolue) :
- Lighthouse au moins 95 sur les quatre axes, en mobile.
- LCP sous 2 s en 4G lente, CLS sous 0,05, INP sous 200 ms.
- JavaScript minimal : Server Components par défaut, îlots client seulement là où c'est nécessaire.
- Polices auto-hébergées (next/font) avec sous-ensembles et `display: swap`.
- Images en AVIF et WebP, dimensionnées et chargées en différé (next/image).
- Aucun script tiers bloquant.
- Mesure d'audience respectueuse de la vie privée (Plausible ou Umami), chargée seulement après
  consentement si elle utilise des cookies. Bandeau de cookies conforme (refuser aussi simple
  qu'accepter).

PAGES :
- Accueil :
  - accroche « Mange mieux. À ton rythme. » ;
  - boutons des stores et QR code (généré au build) ;
  - planche des fonctionnalités, sport et santé, tarifs (depuis /billing/plans, en USD, prix calculés
    par l'API), témoignages, FAQ, appel final.
- Fonctionnalités, Tarifs (comparatif renvoyé par l'API), FAQ (avec recherche), Contact (crée une
  demande dans l'admin).
- Pages légales : CGU, confidentialité, cookies, mentions légales, avec version et date.
- Suppression de compte : page exigée par Google Play, double confirmation par email.
- Invitation /i/{code} :
  - vérifie le code via /referral/check et affiche « {prénom} t'offre 7 jours » ;
  - détecte la plateforme et renvoie vers le bon store en conservant le code (paramètre referrer
    de Play Install Referrer), avec copie du code pour iOS ;
  - aperçu Open Graph personnalisé.
- Abonnement, avec tous les états des maquettes (une route par état, gestion du retour arrière) :
  1. connexion (email et mot de passe, Google ou Apple) ;
  2. choix de l'offre, annuelle mise en avant, code promo vérifié par l'API ;
  3. redirection vers le paiement de l'agrégateur ;
  4. retour en succès (interroge /me/subscription jusqu'à l'activation par le webhook) ou en échec ;
  5. gestion (portail de l'agrégateur, historique des paiements) ;
  6. cas « abonnement pris dans un store » : explication et lien vers le store, pas de double
     abonnement.

UI :
- src/styles/tokens.css (généré depuis shared/tokens) branché sur le thème Tailwind 4. Thèmes clair
  et sombre (prefers-color-scheme).
- Composants accessibles (Radix UI quand c'est utile). Navigation au clavier, focus visible,
  contrastes AA, prefers-reduced-motion respecté.
- Responsive de 320 px à 1920 px, sans défilement horizontal.

QUALITÉ :
- ESLint et TypeScript stricts, Prettier.
- Client généré depuis le contrat avec openapi-typescript et openapi-fetch (`pnpm gen:api`).
- Vitest pour les helpers.
- Playwright pour les parcours de bout en bout (invitation sur Android et iOS, contact, suppression,
  parcours d'abonnement complet sur le serveur fictif Prism), avec axe et Lighthouse CI.

MOCK DATA FIRST (voir le socle commun) :
- Couche de données dans src/server/data/, avec une interface, une implémentation mock et une
  implémentation api, choisies par DATA_SOURCE=mock|api (variable serveur uniquement).
- Fixtures typées avec les types générés, dans les 8 langues : offres et prix (USD), comparatif,
  FAQ, documents légaux, codes d'invitation valides et invalides, et comptes de démo pour la page
  Abonnement (essai, Free, Plus web, Plus store, paiement échoué).
- Le paiement est simulé : une page interne remplace la redirection vers l'agrégateur et permet de
  choisir succès, échec ou abandon. Le retour en succès simule l'activation par webhook, après un
  délai.
- Les formulaires (contact, suppression de compte) sont simulés avec la validation et les erreurs
  du contrat. Le captcha est désactivé en mode mock uniquement.
- Le mode mock est interdit en production : le build échoue si DATA_SOURCE=mock. Prism reste
  disponible pour valider les appels contre le contrat.

LIVRABLES ANNEXES : README du site, .env.example, CI (lint, typage, tests, build, Lighthouse).
```
