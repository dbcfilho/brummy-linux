#!/usr/bin/env bash
# gen-packages.sh — transforma packages/*.packages no packages.x86_64 do archiso.
#
# Fonte única da verdade continua sendo packages/: a ISO não tem lista própria.
# Só os pacotes exclusivos do ambiente live (archiso, calamares) são extras.
set -euo pipefail

REPO_DIR="${1:-/brummy}"
OUT="${2:-/tmp/brummy-profile/packages.x86_64}"

# Quais listas entram na ISO. dev.packages é pesado (~1GB) — comente se a ISO
# estiver grande demais; o usuário instala depois com ./install.sh.
LISTS=(base.packages dev.packages laptop.packages)

# Listas AUR: os pacotes foram construídos por aur-repo.sh e ficam disponíveis
# no repositório local [brummy-aur], então entram na instalação como qualquer
# outro. Quem falhar é removido depois pelo build-iso.sh.
AUR_LISTS=(aur.packages dev-aur.packages)

{
  echo "# Gerado por iso/builder/gen-packages.sh — NÃO edite à mão."
  echo "# Fonte: packages/{$(IFS=,; echo "${LISTS[*]}")} + iso/profile/packages.live"
  echo ""
  for l in "${LISTS[@]}"; do
    f="$REPO_DIR/packages/$l"
    [[ -f "$f" ]] || continue
    echo "# --- $l ---"
    grep -v '^\s*#' "$f" | grep -v '^\s*$' | tr -d '\r'
    echo ""
  done
  for l in "${AUR_LISTS[@]}"; do
    f="$REPO_DIR/packages/$l"
    [[ -f "$f" ]] || continue
    echo "# --- $l (via repositório local brummy-aur) ---"
    grep -v '^\s*#' "$f" | grep -v '^\s*$' | tr -d '\r'
    echo ""
  done
  echo "# --- exclusivos do ambiente live ---"
  grep -v '^\s*#' "$REPO_DIR/iso/profile/packages.live" | grep -v '^\s*$'
} > "$OUT"

# dedup preservando os comentários de seção
awk '/^#/ || /^$/ {print; next} !seen[$0]++ {print}' "$OUT" > "$OUT.tmp" && mv "$OUT.tmp" "$OUT"
echo "[brummy-iso] $(grep -vc '^#\|^$' "$OUT") pacotes em $OUT"
