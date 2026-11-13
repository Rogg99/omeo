#!/usr/bin/env bash
# Génère le client Dart de l'API (packages/omeo_api) depuis contracts/openapi.yaml.
# Ne jamais modifier packages/omeo_api à la main : relancer ce script après chaque évolution du contrat.
#
# Prérequis : Node (npx), Java 11 ou plus (JAVA_HOME, par exemple le JBR d'Android Studio), FVM (version de Flutter dans .fvmrc).
# Usage : depuis mobile/, `bash tool/gen_api.sh`
set -euo pipefail

cd "$(dirname "$0")/.."
SPEC="../contracts/openapi.yaml"
OUT="packages/omeo_api"

if [ -n "${JAVA_HOME:-}" ]; then
  export PATH="$JAVA_HOME/bin:$PATH"
fi
java -version 2>&1 | grep -qE 'version "(1[1-9]|[2-9][0-9])' || {
  echo "Java 11 ou plus est requis (définir JAVA_HOME)." >&2
  exit 1
}

# Version du générateur figée dans openapitools.json (créé au premier lancement).
rm -rf "$OUT"
npx --yes @openapitools/openapi-generator-cli@2 generate \
  -i "$SPEC" \
  -g dart-dio \
  -o "$OUT" \
  --additional-properties=pubName=omeo_api,serializationLibrary=json_serializable,dateLibrary=core,finalProperties=true

# Métadonnées du paquet : version du contrat, et SDK assez récent pour le code émis par json_serializable.
CONTRACT_VERSION="$(sed -n 's/^  version: //p' "$SPEC" | head -1)"
sed -i \
  -e "s/^version: .*/version: $CONTRACT_VERSION/" \
  -e "s/^description: .*/description: Client généré de l'API Omeo (contracts\/openapi.yaml). Ne pas modifier à la main./" \
  -e "/^homepage: /d" \
  -e "s/^  sdk: .*/  sdk: ^3.10.0/" \
  -e "1a publish_to: none" \
  "$OUT/pubspec.yaml"
# Les tests émis sont des squelettes vides : on ne les garde pas.
rm -rf "$OUT/test"

# Fichiers de modèles et de sérialisation (json_serializable)
(cd "$OUT" && fvm dart pub get && fvm dart run build_runner build --delete-conflicting-outputs && fvm dart fix --apply && fvm dart format lib)

echo "Client généré dans $OUT"
