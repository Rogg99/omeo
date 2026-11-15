#!/usr/bin/env bash
# Installe la config nginx d'Omeo sur le VPS (nginx de l'hôte), puis recharge nginx.
#   sudo ./deploy/nginx/install.sh
# Idempotent. Ne touche pas aux autres sites. Annule tout si `nginx -t` échoue.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "à lancer avec sudo" >&2; exit 1; }

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NGINX=/etc/nginx
BACKUP="$(mktemp -d /tmp/omeo-nginx-backup.XXXXXX)"

# Ports des conteneurs sur 127.0.0.1 : web admin api media
PROD_PORTS=(10200 10201 10202 10203)
STAGING_PORTS=(10210 10211 10212 10213)

# ssl_reject_handshake (00-omeo-default.conf) demande nginx 1.19.4+
ver="$(nginx -v 2>&1 | sed -E 's|.*/([0-9.]+).*|\1|')"
if [[ "$(printf '%s\n1.19.4\n' "$ver" | sort -V | head -1)" != 1.19.4 ]]; then
  echo "nginx $ver trop ancien (1.19.4 minimum) : installer la version du dépôt nginx.org" >&2; exit 1
fi
if grep -rqs --exclude="*omeo*" "default_server" "$NGINX/sites-enabled" "$NGINX/conf.d"; then
  echo "un autre vhost déclare déjà default_server : le retirer d'abord" >&2; exit 1
fi

for f in /etc/ssl/omeo/origin.pem /etc/ssl/omeo/origin.key "$NGINX/snippets/omeo-admin-allow.conf"; do
  [[ -f "$f" ]] || { echo "manquant : $f (voir deploy/nginx/README.md)" >&2; exit 1; }
done

render() {  # render <site> <www> <api> <admin> <media> <noindex> <access> <ports...>
  local noindex="" access=""
  [[ "$6" == yes ]] && noindex='add_header X-Robots-Tag "noindex, nofollow" always;'
  [[ "$7" == restricted ]] && access='include snippets/omeo-admin-allow.conf;'
  sed -e "s|{{SITE}}|$1|g" -e "s|{{WWW}}|$2|g" -e "s|{{API}}|$3|g" \
      -e "s|{{ADMIN}}|$4|g" -e "s|{{MEDIA}}|$5|g" \
      -e "s|{{NOINDEX}}|$noindex|g" -e "s|{{SITE_ACCESS}}|$access|g" \
      -e "s|{{PORT_WEB}}|$8|g" -e "s|{{PORT_ADMIN}}|$9|g" \
      -e "s|{{PORT_API}}|${10}|g" -e "s|{{PORT_MEDIA}}|${11}|g" \
      "$SRC/sites-available/omeo.conf.template"
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
  "conf.d/10-omeo-http.conf"
  "conf.d/05-cloudflare-realip.conf"
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
grep -q set_real_ip_from <<<"$realip" || { echo "impossible de récupérer les IP Cloudflare" >&2; exit 1; }

install -m 644 "$SRC/conf.d/00-omeo-default.conf" "$NGINX/conf.d/"
install -m 644 "$SRC/conf.d/10-omeo-http.conf"    "$NGINX/conf.d/"
printf '%s\n' "$realip" > "$NGINX/conf.d/05-cloudflare-realip.conf"
install -m 644 "$SRC/snippets/omeo-tls.conf"   "$NGINX/snippets/"
install -m 644 "$SRC/snippets/omeo-proxy.conf" "$NGINX/snippets/"

render my-omeo.app www.my-omeo.app api.my-omeo.app admin.my-omeo.app media.my-omeo.app \
  no public "${PROD_PORTS[@]}" > "$NGINX/sites-available/my-omeo.app"
render staging.my-omeo.app www-staging.my-omeo.app staging-api.my-omeo.app staging-admin.my-omeo.app staging-media.my-omeo.app \
  yes restricted "${STAGING_PORTS[@]}" > "$NGINX/sites-available/staging.my-omeo.app"

ln -sfn "$NGINX/sites-available/my-omeo.app"         "$NGINX/sites-enabled/my-omeo.app"
ln -sfn "$NGINX/sites-available/staging.my-omeo.app" "$NGINX/sites-enabled/staging.my-omeo.app"

nginx -t || restore
systemctl reload nginx
echo "nginx rechargé. Sauvegarde de l'ancienne config : $BACKUP"
