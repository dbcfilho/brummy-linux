#!/usr/bin/env bash
# aur-repo.sh — constrói os pacotes AUR do Brummy num repositório pacman local.
#
# Por que isso existe: mkarchiso só instala do pacman. helium, vscodium,
# WhiteSur, Bibata, wlogout e o próprio calamares vêm do AUR, então precisam
# virar .pkg.tar.zst antes. É a parte mais lenta e a que mais quebra — por isso
# cada pacote falha sozinho, sem derrubar a build.
#
# O que a primeira build no CI ensinou (e este script resolve):
#   - pacote que saiu do AUR para os repositórios oficiais (spotify-launcher):
#     o clone vem vazio. Se o pacman tem, não é trabalho nosso.
#   - pacote que depende de outro do AUR (walker-bin -> elephant, bottles ->
#     vkbasalt-cli): o makepkg -s só resolve dependência do pacman. Aqui as
#     dependências do AUR são construídas antes, recursivamente.
#   - assinatura PGP (helium, wlogout): o container não conhece a chave do
#     autor. As validpgpkeys do PKGBUILD são importadas antes.
#   - whitesur-gtk-theme chama setterm e quebra sem TERM.
set -uo pipefail

REPO_DIR="${1:-/brummy}"
AUR_DIR="${2:-/tmp/brummy-aur}"
NO_CACHE="${3:-}"
BUILD_USER="builder"
export TERM="${TERM:-xterm}"

mkdir -p "$AUR_DIR"
[[ "$NO_CACHE" == "--no-cache" ]] && { echo "[aur] --no-cache: reconstruindo tudo"; rm -f "$AUR_DIR"/*.pkg.tar.zst; }
# lista de falhas é desta build, não de uma antiga
rm -f "$AUR_DIR/FALHARAM.txt" "$AUR_DIR"/brummy-aur.*

# makepkg se recusa a rodar como root.
id "$BUILD_USER" &>/dev/null || useradd -m "$BUILD_USER"
echo "$BUILD_USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder
chown -R "$BUILD_USER" "$AUR_DIR"

# Lista: o aur.packages do repo (+ dev-aur se a ISO leva o bundle dev) + o
# instalador gráfico.
mapfile -t PKGS < <(grep -v '^\s*#' "$REPO_DIR/packages/aur.packages" | grep -v '^\s*$')
if [[ "${BRUMMY_ISO_SEM_DEV:-0}" != "1" && -f "$REPO_DIR/packages/dev-aur.packages" ]]; then
  mapfile -t -O "${#PKGS[@]}" PKGS < <(grep -v '^\s*#' "$REPO_DIR/packages/dev-aur.packages" | grep -v '^\s*$')
fi
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

# Instala no container o que já foi construído, para servir de dependência
# (o makepkg -s do próximo pacote só enxerga o que o pacman enxerga).
instala_local() {
  local f n alvo=()
  for f in "$AUR_DIR"/*.pkg.tar.zst; do
    [[ -e "$f" ]] || continue
    n="$(basename "$f")"; n="${n%-*-*-*}"
    [[ "$n" == "$1" ]] && alvo+=("$f")
  done
  ((${#alvo[@]})) && pacman -U --noconfirm --needed "${alvo[@]}" >/dev/null
}

# Dependência já resolvida por algo instalado ou pelos repositórios oficiais?
satisfeita() {
  pacman -T "$1" &>/dev/null && return 0
  pacman -Sp --print-format '%n' "$1" &>/dev/null
}

# nome de dependência sem restrição de versão: "elephant>=1.2" -> "elephant"
sem_versao() { local d="${1%%[<>=]*}"; echo "$d"; }

# Nome do repositório AUR que fornece $1 (pkgbase pode diferir do pkgname,
# e há quem dependa de um "provides").
base_aur() {
  local nome="$1" r
  r="$(curl -fsS "https://aur.archlinux.org/rpc/v5/info?arg[]=$nome" 2>/dev/null | jq -r '.results[0].PackageBase // empty')"
  [[ -z "$r" ]] && r="$(curl -fsS "https://aur.archlinux.org/rpc/v5/search/$nome?by=provides" 2>/dev/null \
                         | jq -r '.results | sort_by(-.NumVotes) | .[0].PackageBase // empty')"
  echo "$r"
}

FAILED=()
declare -A VISTO=()

construir() {
  local pkg="$1" nivel="${2:-0}" base dir dep d chaves
  [[ -n "${VISTO[$pkg]:-}" ]] && return 0
  VISTO[$pkg]=1

  if ja_construido "$pkg"; then
    echo "[aur] cache: $pkg"
    # só dependência precisa estar instalada no container
    (( nivel > 0 )) && instala_local "$pkg"
    return 0
  fi
  # Nível 0 = pedido na lista. Se o pacman já tem, a ISO pega de lá.
  if (( nivel == 0 )) && pacman -Si "$pkg" &>/dev/null; then
    echo "[aur] oficial: $pkg (vem dos repositórios do Arch, não do AUR)"
    return 0
  fi

  base="$(base_aur "$pkg")"
  if [[ -z "$base" ]]; then
    echo "[aur] FALHOU: $pkg não existe no AUR nem nos repositórios"
    return 1
  fi
  dir="/tmp/aur-$base"
  echo "[aur] construindo: $pkg (AUR: $base)"
  rm -rf "$dir"
  sudo -u "$BUILD_USER" git clone -q --depth 1 "https://aur.archlinux.org/$base.git" "$dir" || return 1

  # dependências do AUR primeiro
  while read -r dep; do
    d="$(sem_versao "$dep")"
    [[ -z "$d" ]] && continue
    satisfeita "$dep" && continue
    echo "[aur]   $pkg precisa de $d (AUR)"
    construir "$d" $((nivel + 1)) || { echo "[aur]   dependência $d falhou"; return 1; }
  done < <(cd "$dir" && sudo -u "$BUILD_USER" makepkg --printsrcinfo 2>/dev/null \
             | sed -n 's/^\s*\(depends\|makedepends\|checkdepends\)\(_x86_64\)\? = //p' | sort -u)

  # chaves PGP que o PKGBUILD declara
  chaves="$(cd "$dir" && sudo -u "$BUILD_USER" makepkg --printsrcinfo 2>/dev/null | sed -n 's/^\s*validpgpkeys = //p')"
  if [[ -n "$chaves" ]]; then
    # shellcheck disable=SC2086
    sudo -u "$BUILD_USER" gpg --batch --keyserver hkps://keyserver.ubuntu.com --recv-keys $chaves &>/dev/null \
      || sudo -u "$BUILD_USER" gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys $chaves &>/dev/null \
      || echo "[aur]   aviso: não consegui importar as chaves PGP de $base"
  fi

  if ! (cd "$dir" && sudo -u "$BUILD_USER" env TERM="$TERM" makepkg -s --noconfirm --needed); then
    return 1
  fi
  cp -f "$dir"/*.pkg.tar.zst "$AUR_DIR"/
  chown "$BUILD_USER" "$AUR_DIR"/*.pkg.tar.zst
  (( nivel > 0 )) && instala_local "$pkg"
  return 0
}

for pkg in "${PKGS[@]}"; do
  if ! construir "$pkg" 0; then
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
echo "[aur] prontos: $(find "$AUR_DIR" -name '*.pkg.tar.zst' | wc -l) pacotes em $AUR_DIR"
if ((${#FAILED[@]})); then
  echo "[aur] NÃO construídos: ${FAILED[*]}"
  echo "[aur] a ISO vai sair sem eles — o usuário instala depois com ./install.sh"
  printf '%s\n' "${FAILED[@]}" > "$AUR_DIR/FALHARAM.txt"
fi
