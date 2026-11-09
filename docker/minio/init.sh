#!/bin/sh
# Initialise les buckets MinIO de dev. Idempotent : relançable sans effet de bord.
#   nyam-private : fichiers des utilisateurs (photos, avatars, pièces jointes, exports), accès par URL signée uniquement
#   nyam-public  : médias des contenus publiés (recettes, plantes, exercices), lecture publique
set -eu
mc alias set local http://minio:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null
mc mb --ignore-existing local/nyam-private
mc mb --ignore-existing local/nyam-public
mc anonymous set none local/nyam-private
mc anonymous set download local/nyam-public
# Téléversements jamais finalisés : purgés après 2 jours
mc ilm rule add --prefix "tmp/" --expiry-days 2 local/nyam-private >/dev/null 2>&1 || true
echo "Buckets prêts"
