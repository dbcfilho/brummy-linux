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
NO_CACHE="${3:-}"
BUILD_USER="builder"

mkdir -p "$AUR_DIR"
[[ "$NO_CACHE" == "--no-cache" ]] && { echo "[aur] --no-cache: reconstruindo tudo"; rm -f "$AUR_DIR"/*.pkg.tar.zst; }
# lista de falhas é desta build, não de uma antiga
rm -f "$AUR_DIR/FALHARAM.txt" "$AUR_DIR"/brummy-aur.*

# makepkg se recusa a rodar como root.
id "$BUILD_USER" &>/dev/null || useradd -m "$BUILD_USER"
echo "$BUILD_USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder
chown -R "$BUILD_USER" "$AUR_DIR"

# Lista: o aur.packages do repo + o instalador gráfico.
mapfile -t PKGS < <(grep -v '^\s*#' "$REPO_DIR/packages/aur.packages" | grep -v '^\s*$')
PKGS+=("calamares")

# Já construído? Compara o nome exato: "claude-code-*" também casaria com um
# hipotético claude-code-router. Nome = arquivo sem versão-release-arch.
ja_construido() {
  local f n
  for f in "$AUR_DIR"/*.pkg.tar.zst; do
    [[ -e "$f" ]] || continue
    n="$(basename "$f")"; n="${n%-*-*-*}"
    [[ "$n" == "$1" ]] && return 0
  done
  return 1
}

FAILED=()
for pkg in "${PKGS[@]}"; do
  if ja_construido "$pkg"; then
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

# Sem o Calamares não há instalador: não adianta seguir por 40 minutos.
for f in "${FAILED[@]}"; do
  if [[ "$f" == "calamares" ]]; then
    echo "[aur] ERRO: calamares não construiu — sem instalador, parando a build."
    exit 1
  fi
done

repo-add "$AUR_DIR/brummy-aur.db.tar.gz" "$AUR_DIR"/*.pkg.tar.zst
chmod -R a+rX "$AUR_DIR"

echo ""
echo "[aur] prontos: $(ls "$AUR_DIR"/*.pkg.tar.zst 2>/dev/null | wc -l) pacotes em $AUR_DIR"
if ((${#FAILED[@]})); then
  echo "[aur] NÃO construídos: ${FAILED[*]}"
  echo "[aur] a ISO vai sair sem eles — o usuário instala depois com ./install.sh"
  printf '%s\n' "${FAILED[@]}" > "$AUR_DIR/FALHARAM.txt"
fi
