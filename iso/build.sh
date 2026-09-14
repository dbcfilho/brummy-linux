#!/usr/bin/env bash
# Brummy ISO — orquestrador (roda no SEU PC, Debian ou qualquer um com Docker).
#
# archiso só roda em Arch, e você está no Debian: por isso a build acontece
# dentro de um container Arch privilegiado (mesma estratégia do omarchy-iso).
#
# Uso:
#   ./iso/build.sh                # build completo
#   ./iso/build.sh --no-cache     # ignora o cache de pacotes AUR
#   ./iso/build.sh --shell        # abre um shell no container p/ depurar
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$REPO_DIR/iso/out"
CACHE_DIR="$REPO_DIR/iso/.cache"
IMAGE="archlinux:latest"
MODE="build"
EXTRA=()

for arg in "$@"; do
  case "$arg" in
    --shell) MODE="shell" ;;
    --no-cache) EXTRA+=(--no-cache) ;;
    -h|--help) echo "Uso: ./iso/build.sh [--no-cache] [--shell]"; exit 0 ;;
    *) echo "[brummy-iso] arg desconhecido: $arg"; exit 1 ;;
  esac
done

command -v docker &>/dev/null || { echo "ERRO: docker não encontrado. sudo apt install docker.io && sudo usermod -aG docker \$USER"; exit 1; }

mkdir -p "$OUT_DIR" "$CACHE_DIR"

# --privileged: o mkarchiso monta loop devices e roda mkinitcpio em chroot.
DOCKER_ARGS=(
  --rm -it
  --privileged
  -v "$REPO_DIR":/brummy
  -v "$OUT_DIR":/out
  -v "$CACHE_DIR":/var/cache/pacman/pkg
  -w /brummy
)

if [[ "$MODE" == "shell" ]]; then
  echo "==> shell no container Arch (o repo está em /brummy, saída em /out)"
  exec docker run "${DOCKER_ARGS[@]}" "$IMAGE" bash
fi

echo "==> [brummy-iso] build dentro do container $IMAGE"
docker run "${DOCKER_ARGS[@]}" "$IMAGE" bash /brummy/iso/builder/build-iso.sh "${EXTRA[@]}"

echo ""
echo "==> ISO pronta em: $OUT_DIR"
ls -lh "$OUT_DIR"/*.iso 2>/dev/null || echo "   (nada gerado — veja o log acima)"
echo ""
echo "Testar em QEMU sem gravar nada:"
echo "  qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 \\"
echo "    -bios /usr/share/ovmf/OVMF.fd \\"
echo "    -cdrom $OUT_DIR/brummy-*.iso"
