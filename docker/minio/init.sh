#!/bin/sh
# Initialise les buckets MinIO de dev. Idempotent : relançable sans effet de bord.
#   omeo-private : fichiers des utilisateurs (photos, avatars, pièces jointes, exports), accès par URL signée uniquement
#   omeo-public  : médias des contenus publiés (recettes, plantes, exercices), lecture publique
set -eu
# Attend que MinIO réponde (60 s au plus)
i=0
until mc alias set local http://minio:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null 2>&1; do
  i=$((i + 1))
  [ "$i" -lt 60 ] || { echo "MinIO injoignable" >&2; exit 1; }
  sleep 1
done
mc mb --ignore-existing local/omeo-private
mc mb --ignore-existing local/omeo-public
mc anonymous set none local/omeo-private
mc anonymous set download local/omeo-public
# Téléversements jamais finalisés : purgés après 2 jours
mc ilm rule add --prefix "tmp/" --expiry-days 2 local/omeo-private >/dev/null 2>&1 || true
echo "Buckets prêts"
