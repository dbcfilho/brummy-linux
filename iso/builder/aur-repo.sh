#!/usr/bin/env bash
# aur-repo.sh — constrói os pacotes AUR do Brummy num repositório pacman local.
#
# Por que isso existe: mkarchiso só instala do pacman. helium, vscodium,
# WhiteSur, Bibata, wlogout e o próprio calamares vêm do AUR, então precisam
# virar .pkg.tar.zst antes. É a parte mais lenta e a que mais quebra — por isso
# cada pacote falha sozinho, sem derrubar a build.
set -uo pipefail

REPO_DIR="${1:-/brummy}"
AUR_DIR="${2:-/tmp/brummy-aur}"
BUILD_USER="builder"

mkdir -p "$AUR_DIR"

# makepkg se recusa a rodar como root.
id "$BUILD_USER" &>/dev/null || useradd -m "$BUILD_USER"
echo "$BUILD_USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder
chown -R "$BUILD_USER" "$AUR_DIR"

# Lista: o aur.packages do repo + o instalador gráfico.
mapfile -t PKGS < <(grep -v '^\s*#' "$REPO_DIR/packages/aur.packages" | grep -v '^\s*$')
PKGS+=("calamares")

FAILED=()
for pkg in "${PKGS[@]}"; do
  if compgen -G "$AUR_DIR/${pkg}-*.pkg.tar.zst" > /dev/null; then
    echo "[aur] cache: $pkg"
    continue
  fi
  echo "[aur] construindo: $pkg"
  if ! sudo -u "$BUILD_USER" bash -c "
      set -e
      cd /tmp
      rm -rf /tmp/aur-$pkg
      git clone --depth 1 https://aur.archlinux.org/$pkg.git /tmp/aur-$pkg
      cd /tmp/aur-$pkg
      makepkg -s --noconfirm --needed
      cp -f ./*.pkg.tar.zst '$AUR_DIR'/
    "; then
    echo "[aur] FALHOU: $pkg (segue sem ele)"
    FAILED+=("$pkg")
  fi
done

repo-add "$AUR_DIR/brummy-aur.db.tar.gz" "$AUR_DIR"/*.pkg.tar.zst 2>/dev/null || true
chmod -R a+rX "$AUR_DIR"

echo ""
echo "[aur] prontos: $(ls "$AUR_DIR"/*.pkg.tar.zst 2>/dev/null | wc -l) pacotes em $AUR_DIR"
if ((${#FAILED[@]})); then
  echo "[aur] NÃO construídos: ${FAILED[*]}"
  echo "[aur] a ISO vai sair sem eles — o usuário instala depois com ./install.sh"
  printf '%s\n' "${FAILED[@]}" > "$AUR_DIR/FALHARAM.txt"
fi
