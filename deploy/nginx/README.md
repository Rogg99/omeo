# nginx de production (VPS)

nginx tourne **sur l'hôte** (systemd), pas dans Docker. Il termine le TLS et relaie vers les conteneurs Omeo,
qui ne publient leurs ports que sur `127.0.0.1`. Tout le trafic public arrive par le proxy Cloudflare.

| Hôte | Prod | Staging |
|---|---|---|
| Site | `my-omeo.app` → 10200 | `staging.my-omeo.app` → 10210 |
| Admin | `admin.my-omeo.app` → 10201 | `staging-admin.my-omeo.app` → 10211 |
| API | `api.my-omeo.app` → 10202 | `staging-api.my-omeo.app` → 10212 |
| Médias (MinIO) | `media.my-omeo.app` → 10203 | `staging-media.my-omeo.app` → 10213 |

- Accès direct par l'IP ou hôte inconnu : connexion coupée (`444`, poignée de main TLS refusée).
- Admin et tout le staging (sauf médias) : réservés aux IP de `snippets/omeo-admin-allow.conf`.
- Staging : `X-Robots-Tag: noindex`.
- IP réelle des visiteurs lue dans `CF-Connecting-IP`, uniquement depuis les IP Cloudflare.
- Limitation de débit : 20 req/s par IP sur l'API, 10 req/min sur la connexion et l'inscription.

## Installation

1. Cloudflare : SSL/TLS en **Full (strict)**, puis **Origin Server → Create Certificate** pour
   `my-omeo.app` et `*.my-omeo.app`. Sur le VPS :
   ```bash
   sudo install -d -m 700 /etc/ssl/omeo
   sudo nano /etc/ssl/omeo/origin.pem   # certificat
   sudo nano /etc/ssl/omeo/origin.key   # clé privée
   sudo chmod 600 /etc/ssl/omeo/origin.key
   ```
2. IP autorisées sur l'admin et le staging (fichier hors dépôt) :
   ```bash
   sudo cp deploy/nginx/snippets/omeo-admin-allow.conf.example /etc/nginx/snippets/omeo-admin-allow.conf
   sudo nano /etc/nginx/snippets/omeo-admin-allow.conf
   ```
3. `sudo ./deploy/nginx/install.sh`. Le script vérifie la version de nginx (1.19.4 minimum) et l'absence
   d'un autre `default_server`, rafraîchit les IP Cloudflare, puis annule tout si `nginx -t` échoue.
   Le relancer après chaque modification de cette config, et de temps en temps pour les IP Cloudflare.

## Limites

Cloudflare gratuit refuse les corps de requête de plus de 100 Mo : les vidéos d'exercices plus lourdes ne
passent pas par `media.my-omeo.app`.
