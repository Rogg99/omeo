#!/usr/bin/env bash
# Installe la config nginx d'Omeo sur le VPS (nginx de l'hôte) et son certificat Let's Encrypt, puis recharge nginx.
#   sudo LETSENCRYPT_EMAIL=toi@exemple.com ./deploy/nginx/install.sh
# Idempotent. Ne touche pas aux autres sites. Annule tout si `nginx -t` échoue. Voir README.md.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "à lancer avec sudo" >&2; exit 1; }

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NGINX=/etc/nginx
DOMAIN=my-omeo.app
CF_CREDENTIALS=/etc/letsencrypt/cloudflare.ini
SECRETS_DIR=/etc/omeo
BACKUP="$(mktemp -d /tmp/omeo-nginx-backup.XXXXXX)"

# Ports des conteneurs sur 127.0.0.1 : web admin api media
PROD_PORTS=(10200 10201 10202 10203)
STAGING_PORTS=(10210 10211 10212 10213)

die() { echo "erreur : $*" >&2; exit 1; }

# ─────────────────────────── Prérequis ───────────────────────────
# ssl_reject_handshake (00-omeo-default.conf) demande nginx 1.19.4+
ver="$(nginx -v 2>&1 | sed -E 's|.*/([0-9.]+).*|\1|')"
[[ "$(printf '%s\n1.19.4\n' "$ver" | sort -V | head -1)" == 1.19.4 ]] \
  || die "nginx $ver trop ancien (1.19.4 minimum) : installer la version du dépôt nginx.org"
# HTTP/2 : directive « http2 on; » depuis 1.25.1, option de « listen » avant
if [[ "$(printf '%s\n1.25.1\n' "$ver" | sort -V | head -1)" == 1.25.1 ]]; then
  HTTP2_DIRECTIVE='http2 on;'; HTTP2_LISTEN=''
else
  HTTP2_DIRECTIVE=''; HTTP2_LISTEN=' http2'
fi
# Ajoute l'option http2 aux « listen ... 443 ssl » (anciennes versions de nginx)
http2_listen() { sed -E "s/^( *listen [^;]*443 ssl)( default_server)?;/\1$HTTP2_LISTEN\2;/"; }
if grep -rqs --exclude="*omeo*" "default_server" "$NGINX/sites-enabled" "$NGINX/conf.d"; then
  die "un autre vhost déclare déjà default_server : le retirer d'abord"
fi
[[ -f "$NGINX/snippets/omeo-admin-allow.conf" ]] \
  || die "manquant : $NGINX/snippets/omeo-admin-allow.conf (modèle : snippets/omeo-admin-allow.conf.example)"

# Secret des URL de médias signées : même valeur que MEDIA_URL_SECRET dans le .env de l'environnement
media_secret() {
  local file="$SECRETS_DIR/media-url-secret.$1" value
  [[ -f "$file" ]] || die "manquant : $file (même valeur que MEDIA_URL_SECRET de l'API $1, voir README.md)"
  value="$(tr -d '[:space:]' < "$file")"
  [[ "$value" =~ ^[A-Za-z0-9_-]{32,}$ ]] || die "$file : 32 caractères minimum, [A-Za-z0-9_-] uniquement"
  printf '%s' "$value"
}
PROD_MEDIA_SECRET="$(media_secret prod)"
STAGING_MEDIA_SECRET="$(media_secret staging)"
[[ "$PROD_MEDIA_SECRET" != "$STAGING_MEDIA_SECRET" ]] || die "les secrets de médias prod et staging doivent différer"

# ─────────────────────────── Certificat Let's Encrypt ───────────────────────────
# Défi DNS-01 via l'API Cloudflare : fonctionne derrière le proxy, sans port ouvert, et couvre le wildcard.
# Un seul certificat (my-omeo.app + *.my-omeo.app) : un seul nom apparaît dans les journaux CT.
# Renouvellement : certbot.timer (paquet certbot), puis rechargement de nginx par le hook ci-dessous.
ensure_certificate() {
  local live="/etc/letsencrypt/live/$DOMAIN"
  if ! command -v certbot >/dev/null || ! dpkg -s python3-certbot-dns-cloudflare >/dev/null 2>&1; then
    apt-get update -qq
    apt-get install -y -qq certbot python3-certbot-dns-cloudflare
  fi

  install -d -m 755 /etc/letsencrypt/renewal-hooks/deploy
  cat > /etc/letsencrypt/renewal-hooks/deploy/omeo-reload-nginx.sh <<'HOOK'
#!/bin/sh
# Installé par deploy/nginx/install.sh : recharge nginx après chaque renouvellement.
nginx -t -q && systemctl reload nginx
HOOK
  chmod 755 /etc/letsencrypt/renewal-hooks/deploy/omeo-reload-nginx.sh

  [[ -f "$live/fullchain.pem" ]] && { echo "certificat présent : $live (renouvelé par certbot.timer)"; return; }

  [[ -f "$CF_CREDENTIALS" ]] \
    || die "manquant : $CF_CREDENTIALS avec « dns_cloudflare_api_token = ... » (jeton Zone:DNS:Edit sur $DOMAIN)"
  chmod 600 "$CF_CREDENTIALS"
  [[ -n "${LETSENCRYPT_EMAIL:-}" ]] || die "LETSENCRYPT_EMAIL requis pour le premier certificat"

  certbot certonly --non-interactive --agree-tos --email "$LETSENCRYPT_EMAIL" \
    --dns-cloudflare --dns-cloudflare-credentials "$CF_CREDENTIALS" --dns-cloudflare-propagation-seconds 30 \
    --cert-name "$DOMAIN" -d "$DOMAIN" -d "*.$DOMAIN" \
    --key-type ecdsa
}
ensure_certificate

# ─────────────────────────── Config nginx ───────────────────────────
render() {  # render <site> <www> <api> <admin> <media> <noindex> <access> <media_secret> <ports web admin api media>
  local noindex="" access=""
  [[ "$6" == yes ]] && noindex='add_header X-Robots-Tag "noindex, nofollow" always;'
  [[ "$7" == restricted ]] && access='include snippets/omeo-admin-allow.conf;'
  sed -e "s|{{SITE}}|$1|g" -e "s|{{WWW}}|$2|g" -e "s|{{API}}|$3|g" \
      -e "s|{{ADMIN}}|$4|g" -e "s|{{MEDIA}}|$5|g" \
      -e "s|{{NOINDEX}}|$noindex|g" -e "s|{{SITE_ACCESS}}|$access|g" \
      -e "s|{{MEDIA_SECRET}}|$8|g" -e "s|{{HTTP2}}|$HTTP2_DIRECTIVE|g" \
      -e "s|{{PORT_WEB}}|$9|g" -e "s|{{PORT_ADMIN}}|${10}|g" \
      -e "s|{{PORT_API}}|${11}|g" -e "s|{{PORT_MEDIA}}|${12}|g" \
      "$SRC/sites-available/omeo.conf.template" | http2_listen
}

cloudflare_realip() {
  echo "# Généré par deploy/nginx/install.sh le $(date -u +%F) depuis cloudflare.com/ips"
  local ip
  for ip in $(curl -fsS https://www.cloudflare.com/ips-v4) $(curl -fsS https://www.cloudflare.com/ips-v6); do
    echo "set_real_ip_from $ip;"
  done
  echo "real_ip_header CF-Connecting-IP;"
}

staged=(
  "conf.d/00-omeo-default.conf"
  "conf.d/05-cloudflare-realip.conf"
  "conf.d/10-omeo-http.conf"
  "snippets/omeo-tls.conf"
  "snippets/omeo-proxy.conf"
  "sites-available/my-omeo.app"
  "sites-available/staging.my-omeo.app"
  "sites-enabled/my-omeo.app"
  "sites-enabled/staging.my-omeo.app"
)
for f in "${staged[@]}"; do
  [[ -e "$NGINX/$f" || -L "$NGINX/$f" ]] && { mkdir -p "$BACKUP/$(dirname "$f")"; cp -P "$NGINX/$f" "$BACKUP/$f"; }
done

restore() {
  echo "nginx -t a échoué : restauration de la config précédente" >&2
  for f in "${staged[@]}"; do rm -f "$NGINX/$f"; done
  cp -a "$BACKUP/." "$NGINX/" 2>/dev/null || true
  exit 1
}

realip="$(cloudflare_realip)"
grep -q set_real_ip_from <<<"$realip" || die "impossible de récupérer les IP Cloudflare"

http2_listen < "$SRC/conf.d/00-omeo-default.conf" > "$NGINX/conf.d/00-omeo-default.conf"
install -m 644 "$SRC/conf.d/10-omeo-http.conf"    "$NGINX/conf.d/"
printf '%s\n' "$realip" > "$NGINX/conf.d/05-cloudflare-realip.conf"
install -m 644 "$SRC/snippets/omeo-tls.conf"   "$NGINX/snippets/"
install -m 644 "$SRC/snippets/omeo-proxy.conf" "$NGINX/snippets/"

# Les vhosts contiennent le secret des médias : lisibles par root uniquement (nginx les lit en root)
umask 077
render "$DOMAIN" "www.$DOMAIN" "api.$DOMAIN" "admin.$DOMAIN" "media.$DOMAIN" \
  no public "$PROD_MEDIA_SECRET" "${PROD_PORTS[@]}" > "$NGINX/sites-available/$DOMAIN"
render "staging.$DOMAIN" "www-staging.$DOMAIN" "staging-api.$DOMAIN" "staging-admin.$DOMAIN" "staging-media.$DOMAIN" \
  yes restricted "$STAGING_MEDIA_SECRET" "${STAGING_PORTS[@]}" > "$NGINX/sites-available/staging.$DOMAIN"
umask 022

ln -sfn "$NGINX/sites-available/$DOMAIN"         "$NGINX/sites-enabled/$DOMAIN"
ln -sfn "$NGINX/sites-available/staging.$DOMAIN" "$NGINX/sites-enabled/staging.$DOMAIN"

nginx -t || restore
systemctl reload nginx
echo "nginx rechargé. Sauvegarde de l'ancienne config : $BACKUP"
