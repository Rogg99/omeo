#!/usr/bin/env bash
# Gestion du .env global d'Omeo (voir .env.example).
#
#   ./scripts/env.sh init [fichier]       crée le fichier (défaut : .env) depuis .env.example
#                                         et génère les secrets __GEN_*__
#   ./scripts/env.sh dispatch [fichier]   écrit api/.env et web/.env depuis le fichier
#   ./scripts/env.sh check [fichier]      liste les variables vides et les marqueurs restants
#
# Fonctionne sous Linux, macOS et Git Bash (Windows). Dépendances : awk, openssl.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$ROOT/.env.example"
TARGETS=(api web)

die() { echo "erreur : $*" >&2; exit 1; }

resolve() {
  local file="${1:-.env}"
  [[ "$file" = /* ]] || file="$ROOT/$file"
  printf '%s' "$file"
}

gen() {
  case "$1" in
    HEX)    openssl rand -hex 32 ;;
    TOKEN)  openssl rand -base64 64 | tr -d '\n=' | tr '+/' '-_' ;;
    FERNET) openssl rand -base64 32 | tr '+/' '-_' ;;
    *)      die "marqueur inconnu : __GEN_$1__" ;;
  esac
}

cmd_init() {
  local out; out="$(resolve "${1:-}")"
  [[ -e "$out" ]] && die "$out existe déjà : supprime-le d'abord si tu veux le régénérer"
  command -v openssl >/dev/null || die "openssl introuvable"

  umask 077
  local line kind
  while IFS= read -r line || [[ -n "$line" ]]; do
    while [[ "$line" =~ __GEN_([A-Z]+)__ ]]; do
      kind="${BASH_REMATCH[1]}"
      line="${line/__GEN_${kind}__/$(gen "$kind")}"
    done
    printf '%s\n' "$line"
  done < "$TEMPLATE" > "$out"
  chmod 600 "$out"
  echo "créé : $out (secrets générés). Complète les clés des services externes puis lance dispatch."
}

# Écrit sur la sortie standard les lignes destinées à une cible.
extract() {
  awk -v target="$2" '
    /^#[[:space:]]*@/ {
      sub(/^#[[:space:]]*@/, ""); gsub(/[[:space:]]/, "")
      n = split($0, list, ","); keep = 0
      for (i = 1; i <= n; i++) if (list[i] == target) keep = 1
      next
    }
    /^[A-Za-z_][A-Za-z0-9_]*=/ { if (keep) print }
  ' "$1"
}

cmd_check() {
  local src; src="$(resolve "${1:-}")"
  [[ -f "$src" ]] || die "$src introuvable (lance d'abord : init)"
  local markers empty
  markers="$(grep -nE '__GEN_[A-Z]+__' "$src" || true)"
  empty="$(grep -nE '^[A-Za-z_][A-Za-z0-9_]*=$' "$src" | cut -d= -f1 || true)"
  [[ -n "$markers" ]] && { echo "marqueurs non générés :"; echo "$markers"; }
  [[ -n "$empty" ]] && { echo "variables vides :"; echo "$empty"; }
  [[ -z "$markers" ]] || return 1
  return 0
}

cmd_dispatch() {
  local src; src="$(resolve "${1:-}")"
  [[ -f "$src" ]] || die "$src introuvable (lance d'abord : init)"
  grep -qE '__GEN_[A-Z]+__' "$src" && die "$src contient encore des marqueurs __GEN_*__ (lance init)"

  umask 077
  local target out tmp
  for target in "${TARGETS[@]}"; do
    out="$ROOT/$target/.env"
    tmp="$(mktemp "$ROOT/$target/.env.XXXXXX")"
    {
      echo "# Généré par scripts/env.sh depuis ${src#"$ROOT"/}. Ne pas éditer : modifier la source puis relancer dispatch."
      extract "$src" "$target"
    } > "$tmp"
    [[ -f "$out" ]] && ! cmp -s "$out" "$tmp" && cp -p "$out" "$out.bak"
    mv "$tmp" "$out"
    chmod 600 "$out"
    echo "écrit : ${out#"$ROOT"/} ($(($(wc -l < "$out") - 1)) variables)"
  done
}

case "${1:-}" in
  init)     shift; cmd_init "$@" ;;
  dispatch) shift; cmd_dispatch "$@" ;;
  check)    shift; cmd_check "$@" ;;
  *)        sed -n '2,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
