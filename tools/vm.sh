#!/usr/bin/env bash
# tools/vm.sh — VM de teste do Brummy sem GNOME Boxes.
#
# Por que existe: o Boxes não deixa ligar aceleração 3D, não deixa escolher o
# modelo de vídeo e manda teclas por SPICE de um jeito que embaralha teclado
# ABNT2 (digitar "a" sai "9;9u"). Para testar um compositor Wayland isso é
# inviável. Aqui é QEMU na mão, com as opções que importam.
#
# Uso:
#   ./tools/vm.sh criar            cria o disco (25G, qcow2)
#   ./tools/vm.sh iso caminho.iso  boota uma ISO (instalar o Arch / testar a ISO do Brummy)
#   ./tools/vm.sh rodar            boota o disco já instalado
#   ./tools/vm.sh ssh              entra por SSH na VM (porta 2222)
#
# Dentro da VM, o host é 10.0.2.2 — então `git pull` ou
# `scp -P 22 dbrum@10.0.2.2:...` continuam funcionando.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VM_DIR="${BRUMMY_VM_DIR:-$HOME/VMs/brummy}"
DISK="$VM_DIR/brummy.qcow2"
DISK_SIZE="${BRUMMY_VM_SIZE:-25G}"
RAM="${BRUMMY_VM_RAM:-4096}"
CPUS="${BRUMMY_VM_CPUS:-4}"
SSH_PORT=2222

need() { command -v "$1" &>/dev/null || { echo "ERRO: falta $1 — sudo apt install $2"; exit 1; }; }

# Vídeo: virtio-vga-gl + gl=on dá virgl (3D de verdade). Sem isso o Hyprland
# até sobe, mas arrasta e o blur fica impraticável.
# Teclado: com display gtk o QEMU manda scancode cru, então o layout do
# convidado (br-abnt2) é respeitado — é isto que conserta o teclado do Boxes.
qemu_common=(
  -enable-kvm
  -cpu host
  -m "$RAM"
  -smp "$CPUS"
  -machine q35,accel=kvm
  -device virtio-vga-gl
  -display gtk,gl=on,show-cursor=off
  -device virtio-tablet-pci          # ponteiro absoluto: sem "prender" o mouse
  -device virtio-keyboard-pci
  -audiodev pipewire,id=snd0 -device intel-hda -device hda-output,audiodev=snd0
  -netdev "user,id=net0,hostfwd=tcp::${SSH_PORT}-:22"
  -device virtio-net-pci,netdev=net0
  -object rng-random,id=rng0,filename=/dev/urandom
  -device virtio-rng-pci,rng=rng0
)

uefi_firmware() {
  for f in /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd /usr/share/ovmf/OVMF.fd; do
    [[ -f "$f" ]] && { echo "$f"; return; }
  done
  echo ""
}

cmd="${1:-help}"
case "$cmd" in
  criar)
    need qemu-img qemu-utils
    mkdir -p "$VM_DIR"
    [[ -f "$DISK" ]] && { echo "já existe: $DISK"; exit 0; }
    qemu-img create -f qcow2 "$DISK" "$DISK_SIZE"
    echo "disco criado: $DISK ($DISK_SIZE)"
    echo "agora: ./tools/vm.sh iso ~/Downloads/archlinux.iso"
    ;;

  iso)
    need qemu-system-x86_64 qemu-system-x86
    ISO="${2:-}"
    [[ -f "$ISO" ]] || { echo "uso: ./tools/vm.sh iso <arquivo.iso>"; exit 1; }
    [[ -f "$DISK" ]] || { echo "sem disco — rode ./tools/vm.sh criar"; exit 1; }
    FW="$(uefi_firmware)"
    args=("${qemu_common[@]}" -drive "file=$DISK,if=virtio,format=qcow2"
          -cdrom "$ISO" -boot order=d)
    [[ -n "$FW" ]] && args+=(-drive "if=pflash,format=raw,readonly=on,file=$FW")
    echo "==> bootando $ISO (UEFI: ${FW:-não, BIOS legado})"
    exec qemu-system-x86_64 "${args[@]}"
    ;;

  rodar)
    need qemu-system-x86_64 qemu-system-x86
    [[ -f "$DISK" ]] || { echo "sem disco — rode ./tools/vm.sh criar"; exit 1; }
    FW="$(uefi_firmware)"
    args=("${qemu_common[@]}" -drive "file=$DISK,if=virtio,format=qcow2" -boot order=c)
    [[ -n "$FW" ]] && args+=(-drive "if=pflash,format=raw,readonly=on,file=$FW")
    echo "==> bootando o disco instalado (SSH na porta $SSH_PORT)"
    exec qemu-system-x86_64 "${args[@]}"
    ;;

  ssh)
    exec ssh -p "$SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      "${2:-dbrum}@127.0.0.1"
    ;;

  help|--help|-h|*)
    awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' "${BASH_SOURCE[0]}"
    ;;
esac
