#!/usr/bin/env bash
# gen-packages.sh — transforma packages/*.packages no packages.x86_64 do archiso.
#
# Fonte única da verdade continua sendo packages/: a ISO não tem lista própria.
# Extras só dois, em iso/profile/: packages.sistema (base, kernel, grub — o que
# o install.sh não precisa porque roda sobre um Arch pronto) e packages.live
# (o que existe só no live e sai depois de instalar).
#
# Uso: gen-packages.sh <repo> <saída>          packages.x86_64 do archiso
#      gen-packages.sh --remocao <repo>        YAML da lista de remoção do Calamares
set -euo pipefail

limpa() { grep -v '^\s*#' "$1" | grep -v '^\s*$' | tr -d '\r'; }

if [[ "${1:-}" == "--remocao" ]]; then
  REPO_DIR="${2:-/brummy}"
  limpa "$REPO_DIR/iso/profile/packages.live" | sed 's/^/      - /'
  exit 0
fi

REPO_DIR="${1:-/brummy}"
OUT="${2:-/tmp/brummy-profile/packages.x86_64}"

# Quais listas entram na ISO. dev.packages é pesado (~1GB) — comente se a ISO
# estiver grande demais; o usuário instala depois com ./install.sh.
LISTS=(base.packages dev.packages laptop.packages)

# Listas AUR: os pacotes foram construídos por aur-repo.sh e ficam disponíveis
# no repositório local [brummy-aur], então entram na instalação como qualquer
# outro. Quem falhar é removido depois pelo build-iso.sh.
AUR_LISTS=(aur.packages dev-aur.packages laptop-aur.packages)

# BRUMMY_ISO_SEM_DEV=1: ISO menor (o CI usa por padrão); o bundle dev entra
# depois com ./install.sh.
if [[ "${BRUMMY_ISO_SEM_DEV:-0}" == "1" ]]; then
  LISTS=(base.packages laptop.packages)
  AUR_LISTS=(aur.packages laptop-aur.packages)
fi

{
  echo "# Gerado por iso/builder/gen-packages.sh — NÃO edite à mão."
  echo "# Fonte: packages/{$(IFS=,; echo "${LISTS[*]}")} + iso/profile/packages.{sistema,live}"
  echo ""
  echo "# --- sistema (base, kernel, bootloader) ---"
  limpa "$REPO_DIR/iso/profile/packages.sistema"
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
  limpa "$REPO_DIR/iso/profile/packages.live"
} > "$OUT"

# dedup preservando os comentários de seção
awk '/^#/ || /^$/ {print; next} !seen[$0]++ {print}' "$OUT" > "$OUT.tmp" && mv "$OUT.tmp" "$OUT"
echo "[brummy-iso] $(grep -vc '^#\|^$' "$OUT") pacotes em $OUT"
