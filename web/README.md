# Site Omeo (`web/`)

Le site public d'Omeo : accueil, fonctionnalités, tarifs, FAQ, contact, pages légales, suppression de
compte, invitations et page Abonnement. Next.js 16 (App Router), React 19, TypeScript strict,
Tailwind 4, pnpm. Référence visuelle : `previews/web/`.

## Démarrer

```bash
# Avec toute la stack (http://localhost, mode mock par défaut)
docker compose up web nginx

# Seul, en données simulées
cp .env.example .env      # DATA_SOURCE=mock
pnpm install
pnpm dev                  # http://localhost:3000
```

Pour viser l'API réelle : `WEB_DATA_SOURCE=api docker compose up`, ou `DATA_SOURCE=api` dans
`web/.env`, avec `API_URL_INTERNAL`, `REVALIDATE_SECRET` et `TURNSTILE_SITE_KEY` renseignés.
Toutes les variables sont décrites dans [.env.example](.env.example). Aucune n'est envoyée au
navigateur.

## Mode démonstration (`DATA_SOURCE=mock`)

Données simulées, mêmes formes et mêmes codes d'erreur que le contrat. Mot de passe commun :
`omeo-demo`.

| Compte | Scénario |
|---|---|
| `essai@omeo.demo` | Essai Plus en cours |
| `free@omeo.demo` | Free |
| `plus@omeo.demo` | Plus payé sur le site |
| `store@omeo.demo` | Plus payé dans Google Play |
| `echec@omeo.demo` | Dernier paiement échoué |
| `nonverifie@omeo.demo` | Email non vérifié (paiement refusé) |
| `offert@omeo.demo` | Jours de Plus offerts |
| `trop@omeo.demo` / `panne@omeo.demo` | Erreurs 429 et 500 |

- **Paiement simulé.** `/fr/subscription/mock-checkout` remplace l'agrégateur et propose trois
  issues : succès, échec ou abandon. Après un succès, l'abonnement s'active 4 s plus tard,
  comme avec le webhook réel.
- **Code promo.** `BIENVENUE20` donne −20 %.
- **Codes d'invitation.** `AWA2026` (Awa, 7 jours) et `KOFI7`.
- **Formulaires.** Le captcha est désactivé. Le lien de suppression « envoyé par email » s'affiche
  directement sur la page.

`next build` refuse le mode mock : le code simulé n'est jamais livré. La CI vérifie que le marqueur
`omeo-mock-data-source` est absent du build.

## Architecture

- **Couche de données.** Elle vit dans `src/server/data/` : une interface (`types.ts`) et deux
  implémentations, `api/` et `mock/`. L'alias `@/server/data/source` choisit l'implémentation au
  build. Les types viennent du client généré (`pnpm gen:api`).
- **Appels à l'API.** Ils partent uniquement du serveur (`import "server-only"`) vers
  `API_URL_INTERNAL`. Les îlots client passent par `/api/...`, une liste blanche servie par la
  couche de données et limitée en débit par IP.
- **Session de la page Abonnement.**
  - Les jetons sont dans des cookies httpOnly, SameSite=Lax, Secure en HTTPS.
  - Le renouvellement se fait côté serveur : `src/proxy.ts` redirige vers `/session/refresh` avant
    le rendu. Les Server Actions et `/api` renouvellent directement.
- **Sécurité.**
  - CSRF : `proxy.ts` vérifie l'Origin de toutes les mutations. Seuls `/hooks/revalidate` (signé)
    et le retour Apple (état vérifié) sont exemptés.
  - CSP stricte avec un nonce par requête.
  - HSTS, Referrer-Policy et Permissions-Policy dans `next.config.ts`.
  - IP de limitation de débit : `X-Real-IP` posée par nginx, jamais la tête de `X-Forwarded-For`.
- **Connexion Google et Apple.** Elle se fait côté serveur (`/auth/{provider}/start` puis
  `callback`), avec PKCE, un état et un nonce en cookie httpOnly, et sans script tiers. Un compte
  social sans compte Omeo est renvoyé vers l'app.
- **Rendu et cache.**
  - Chaque page est rendue à la requête (nonce).
  - Les tarifs, la FAQ et les pages légales sont en cache 10 min (`'use cache'`, tags `plans`,
    `faq`, `legal`).
- **Webhook de revalidation.** L'API l'appelle à la publication d'un contenu (à brancher côté API) :
  - requête `POST /hooks/revalidate` ;
  - en-têtes `X-Omeo-Timestamp` (secondes) et `X-Omeo-Signature` (`sha256=` suivi du HMAC-SHA256 de
    `${timestamp}.${corps}` avec `REVALIDATE_SECRET`) ;
  - corps `{"tags":["faq"]}` ;
  - fenêtre de 5 min contre le rejeu.
- **Abonnement.**
  - Une route par état. L'étape suit `can_manage` renvoyé par l'API : `store` vers store, `web`
    vers manage, `none` vers plan. Une page qui ne correspond plus à l'état renvoie vers la bonne
    étape, ce qui gère le retour arrière.
  - Le paiement se fait par redirection vers `checkout_url`, sans aucune donnée de carte sur le
    site.
  - Au retour en succès, la page interroge `/me/subscription` jusqu'à l'activation.
- **Langues.**
  - 8 langues, une adresse par langue, via next-intl.
  - La langue est détectée par Accept-Language à la première visite, puis gardée dans le cookie
    `NEXT_LOCALE`.
  - Les messages sont générés : `pnpm --dir ../shared build:i18n`. Pour l'instant, seuls fr et en
    sont traduits, les autres langues suivent le repli en → fr.
- **Mesure d'audience.** Plausible ou Umami, servi depuis `/stats` et chargé seulement après
  consentement. Refuser est aussi simple qu'accepter.
- **Styles.**
  - `src/styles/tokens.css` est généré depuis `shared/tokens` ; `globals.css` est porté des
    maquettes.
  - Les propriétés logiques gèrent l'arabe en RTL.
  - Cibles tactiles de 44 px, mouvement réduit respecté.

## Vérifier

```bash
pnpm lint && pnpm typecheck
pnpm test          # Vitest : helpers de sécurité et règles métier du mock
pnpm test:e2e      # Playwright (mode mock) : parcours, axe, mobile ; installer d'abord chromium
pnpm build         # avec DATA_SOURCE=api et les variables requises
pnpm lighthouse    # après le build : 95 minimum sur les quatre axes, en mobile
```

## Limites connues

- **Contenus de démonstration.** La FAQ et le comparatif existent en fr et en ; les pages légales
  en fr uniquement (repli de l'API).
- **Prism.** Il sert le contrat à la racine (`/faq`), alors que le client appelle `/api/v1/...`.
  Pour valider les appels contre Prism, il faut un préfixe (proxy ou option de base path).
