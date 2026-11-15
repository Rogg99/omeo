# nginx de production (VPS)

nginx tourne **sur l'hôte** (systemd), pas dans Docker. Il termine le TLS (certificat Let's Encrypt) et relaie
vers les conteneurs Omeo, qui ne publient leurs ports que sur `127.0.0.1`. Tout le trafic public arrive par le
proxy Cloudflare.

| Hôte | Prod | Staging |
|---|---|---|
| Site | `my-omeo.app` → 10200 | `staging.my-omeo.app` → 10210 |
| Admin | `admin.my-omeo.app` → 10201 | `staging-admin.my-omeo.app` → 10211 |
| API | `api.my-omeo.app` → 10202 | `staging-api.my-omeo.app` → 10212 |
| Médias (MinIO) | `media.my-omeo.app` → 10203 | `staging-media.my-omeo.app` → 10213 |

- Accès direct par l'IP ou hôte inconnu : connexion coupée (`444`, poignée de main TLS refusée).
- Admin et tout le staging (sauf médias) : réservés aux IP de `snippets/omeo-admin-allow.conf`.
- IP réelle des visiteurs lue dans `CF-Connecting-IP`, uniquement depuis les IP Cloudflare.
- Limitation de débit : 20 req/s par IP sur l'API, 10 req/min sur la connexion et l'inscription.

## Médias : rien n'est public, MinIO est invisible

`media.*` n'accepte que deux formes de requêtes ; tout le reste répond `404`, sans en-tête ni page d'erreur MinIO.

1. **Média publié** : `/m/{expire}/{jeton}/{dossier}/-/{fichier}`, URL signée par l'API (`public_url()` dans
   `api/apps/core/storage.py`) et vérifiée par le module `secure_link`. Le jeton couvre le dossier : les
   segments et variantes d'un manifeste HLS restent valides. Durée : entre 1 et 2 × `MEDIA_URL_TTL_SECONDS`.
2. **URL présignée S3** (`X-Amz-Signature`) : envois `PUT` et lecture des fichiers privés. `GET`, `HEAD` et
   `PUT` uniquement, sur une clé d'objet (jamais la racine ni la liste d'un bucket).

Le secret de signature est différent en prod et en staging, et identique côté API (`MEDIA_URL_SECRET`) et
côté nginx (`/etc/omeo/media-url-secret.<env>`).

## Installation

1. **Jeton API Cloudflare** (défi DNS-01 de Let's Encrypt) : My Profile → API Tokens → Create Token →
   modèle « Edit zone DNS », zone `my-omeo.app` uniquement.
   ```bash
   sudo install -d -m 700 /etc/letsencrypt
   echo "dns_cloudflare_api_token = <jeton>" | sudo tee /etc/letsencrypt/cloudflare.ini >/dev/null
   sudo chmod 600 /etc/letsencrypt/cloudflare.ini
   ```
2. **Secrets des médias** (copier ensuite chaque valeur dans `MEDIA_URL_SECRET` du `.env` correspondant) :
   ```bash
   sudo install -d -m 700 /etc/omeo
   openssl rand -hex 32 | sudo tee /etc/omeo/media-url-secret.prod >/dev/null
   openssl rand -hex 32 | sudo tee /etc/omeo/media-url-secret.staging >/dev/null
   sudo chmod 600 /etc/omeo/media-url-secret.*
   ```
3. **IP autorisées** sur l'admin et le staging :
   ```bash
   sudo cp deploy/nginx/snippets/omeo-admin-allow.conf.example /etc/nginx/snippets/omeo-admin-allow.conf
   sudo nano /etc/nginx/snippets/omeo-admin-allow.conf
   ```
4. **Installation** :
   ```bash
   sudo LETSENCRYPT_EMAIL=toi@exemple.com ./deploy/nginx/install.sh
   ```
   Le script installe certbot et son extension Cloudflare, obtient le certificat `my-omeo.app` + `*.my-omeo.app`
   (une seule fois, renouvelé ensuite par `certbot.timer` avec rechargement de nginx), vérifie la version de
   nginx (1.19.4 minimum) et l'absence d'un autre `default_server`, rafraîchit les IP Cloudflare, puis
   annule tout si `nginx -t` échoue. Le relancer après chaque modification de cette config.
5. Cloudflare : SSL/TLS en **Full (strict)**.

Vérifier le renouvellement : `sudo certbot renew --dry-run`.

## Limites

Cloudflare gratuit refuse les corps de requête de plus de 100 Mo : les vidéos d'exercices plus lourdes ne
passent pas par `media.my-omeo.app`.
