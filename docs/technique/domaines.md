# Domaines et sous-domaines

Omeo utilise un seul nom de domaine : **my-omeo.app**. Tous les livrables s'y rattachent. Aucune URL, aucune adresse email et aucun hôte ne doit pointer vers un autre domaine.

## Production

| Hôte | Rôle | Livrable |
|---|---|---|
| `my-omeo.app` | Site vitrine, tarifs, pages légales, support, paiement web | web |
| `my-omeo.app/i/{code}` | Lien d'invitation (parrainage), ouvert dans l'app si elle est installée | web et mobile |
| `api.my-omeo.app/api/v1` | API REST (contrat [openapi.yaml](../../contracts/openapi.yaml)) | api |
| `admin.my-omeo.app` | Back-office de l'équipe | admin |
| `media.my-omeo.app` | Médias publics (vidéos HLS, images) et envois présignés | api (stockage objet et CDN) |

`www.my-omeo.app` redirige en 301 vers `my-omeo.app`.

## Staging

Même découpage, préfixé : `staging.my-omeo.app`, `api.staging.my-omeo.app`, `admin.staging.my-omeo.app` et `media.staging.my-omeo.app`. Ces hôtes ne sont jamais indexés (`X-Robots-Tag: noindex`).

## Développement local

Rien ne change : `http://api.localhost` (nginx). Depuis l'émulateur Android : `http://10.0.2.2`.

## Liens profonds (mobile)

- **Schéma** : `omeo://` (ouverture depuis les notifications et les liens internes).
- **App Links (Android)** : `https://my-omeo.app/.well-known/assetlinks.json`, servi par le site, avec l'empreinte SHA-256 du certificat de signature Play.
- **Universal Links (iOS)** : `https://my-omeo.app/.well-known/apple-app-site-association`, servi en `application/json` sans redirection. Associated Domains : `applinks:my-omeo.app`.
- **Chemins pris en charge par l'app** : `/i/*` uniquement. Toutes les autres URL restent dans le navigateur.

## Emails

| Adresse | Usage |
|---|---|
| `no-reply@my-omeo.app` | Emails transactionnels (vérification, réinitialisation, reçus) |
| `support@my-omeo.app` | Support utilisateur |

Les comptes de démonstration (seeders) utilisent `@demo.my-omeo.app` et les comptes d'équipe de test `@staff.my-omeo.app`. Ces sous-domaines n'ont pas d'enregistrement MX : aucun email ne peut y être livré.

## Erreurs problem+json

Le champ `type` des erreurs vaut `https://my-omeo.app/errors/{code}`. Les clients ne s'en servent jamais : leur comportement dépend uniquement du `code`.

## Sécurité

- HTTPS partout et HSTS avec `includeSubDomains` et `preload` (le TLD `.app` est déjà dans la liste de préchargement des navigateurs).
- L'app mobile épingle la clé publique du certificat de `api.my-omeo.app` (avec une clé de secours) en staging et en production.
- Les cookies de session de l'admin sont limités à `admin.my-omeo.app` (pas d'attribut `Domain`), pour ne jamais être partagés avec le site.
- CORS de l'API : seuls `https://my-omeo.app` et `https://admin.my-omeo.app` (et leurs équivalents de staging) sont autorisés.
