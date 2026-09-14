#!/usr/bin/env bash
# tools/vm.sh — VM de teste do Brummy sem GNOME Boxes.
#
# Por que existe: o Boxes não deixa ligar aceleração 3D, não deixa escolher o
# modelo de vídeo e manda teclas por SPICE de um jeito que embaralha teclado
# ABNT2 (digitar "a" sai "9;9u"). Para testar um compositor Wayland isso é
# inviável. Aqui é QEMU na mão, com as opções que importam.
#
# Uso:
#   ./tools/vm.sh deps             mostra o que instalar no Debian
#   ./tools/vm.sh achar            procura discos de VM que você já tem
#   ./tools/vm.sh criar            cria um disco novo (25G, qcow2)
#   ./tools/vm.sh iso arquivo.iso  boota uma ISO (instalar Arch / testar a ISO do Brummy)
#   ./tools/vm.sh overlay disco    boota um disco existente SEM escrever nele
#   ./tools/vm.sh rodar [disco]    boota o disco instalado
#   ./tools/vm.sh enviar [usuario]  copia o repo inteiro para dentro da VM
#   ./tools/vm.sh ssh [usuario]     entra por SSH na VM (porta 2222)
#
# Para reaproveitar a VM que já existe no Boxes, sem reinstalar nada:
#   ./tools/vm.sh achar            → mostra o comando pronto, com o caminho certo
# Feche a VM no Boxes antes: dois QEMU no mesmo disco corrompem a imagem.
#
# Variáveis: BRUMMY_VM_DISK, BRUMMY_VM_DIR, BRUMMY_VM_RAM (4096),
#            BRUMMY_VM_CPUS (4), BRUMMY_VM_SIZE (25G), BRUMMY_VM_GL (1),
#            BRUMMY_VM_UEFI (rodar=0, iso=1)
#
# Parou em ">>Start PXE over IPv4"? É o firmware errado para este disco.
# Um disco instalado em BIOS não boota em UEFI, e vice-versa. Inverta:
#   BRUMMY_VM_UEFI=1 ./tools/vm.sh rodar <disco>
#
# Dentro da VM o host é 10.0.2.2, então `git pull` e `scp` continuam valendo.
set -euo pipefail

VM_DIR="${BRUMMY_VM_DIR:-$HOME/VMs/brummy}"
DISK="${BRUMMY_VM_DISK:-$VM_DIR/brummy.qcow2}"
DISK_SIZE="${BRUMMY_VM_SIZE:-25G}"
RAM="${BRUMMY_VM_RAM:-4096}"
CPUS="${BRUMMY_VM_CPUS:-4}"
USE_GL="${BRUMMY_VM_GL:-1}"
SSH_PORT=2222

die() { echo "ERRO: $*" >&2; exit 1; }

check_kvm() {
  [[ -e /dev/kvm ]] || die "sem /dev/kvm — virtualização desligada na BIOS, ou módulo kvm_intel/kvm_amd não carregado"
  [[ -r /dev/kvm && -w /dev/kvm ]] || die "sem permissão em /dev/kvm — rode: sudo usermod -aG kvm \$USER (e relogue)"
}

# Áudio: nem todo QEMU do Debian tem pipewire compilado. Testa e cai para o que
# existir; sem áudio nenhum a VM ainda sobe (só não toca som).
pick_audio() {
  local list; list="$(qemu-system-x86_64 -audiodev help 2>/dev/null || true)"
  for a in pipewire pa alsa sdl; do
    grep -qw "$a" <<< "$list" && { echo "$a"; return; }
  done
  echo ""
}

# Vídeo: virtio-vga-gl + gl=on dá virgl (3D real). Sem isso o Hyprland sobe mas
# arrasta e o blur fica impraticável. BRUMMY_VM_GL=0 desliga, se o host não tiver.
# Teclado: com display gtk o QEMU manda scancode cru, então o layout do
# convidado (br-abnt2) é respeitado — é isto que conserta o teclado do Boxes.
build_args() {
  qemu_args=(
    -enable-kvm
    -cpu host
    -m "$RAM"
    -smp "$CPUS"
    -machine q35,accel=kvm
    -device virtio-tablet-pci          # ponteiro absoluto: o mouse não fica preso
    -device virtio-keyboard-pci
    -netdev "user,id=net0,hostfwd=tcp::${SSH_PORT}-:22"
    -device virtio-net-pci,netdev=net0
    -object rng-random,id=rng0,filename=/dev/urandom
    -device virtio-rng-pci,rng=rng0
  )
  if [[ "$USE_GL" == "1" ]]; then
    qemu_args+=(-device virtio-vga-gl -display gtk,gl=on,show-cursor=off)
  else
    qemu_args+=(-device virtio-vga -display gtk,show-cursor=off)
  fi
  local aud; aud="$(pick_audio)"
  if [[ -n "$aud" ]]; then
    qemu_args+=(-audiodev "$aud,id=snd0" -device intel-hda -device hda-output,audiodev=snd0)
  else
    echo "  (aviso: nenhum backend de áudio disponível neste QEMU — seguindo sem som)" >&2
  fi
}

# Firmware. Isto NÃO se adivinha pelo disco: um disco instalado em BIOS não
# boota em UEFI e vice-versa. Sintoma do modo errado: a tela para em
# "BdsDxe: failed to load Boot0001" e cai em ">>Start PXE over IPv4".
# Padrão: BIOS no `rodar` (é como o Boxes instala), UEFI no `iso` (instalação nova).
uefi_code() {
  for f in /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd \
           /usr/share/OVMF/OVMF_CODE.secboot.fd /usr/share/ovmf/OVMF.fd; do
    [[ -f "$f" ]] && { echo "$f"; return; }
  done
  echo ""
}

# O UEFI precisa de um espaço gravável para as variáveis de boot. Sem isso o
# firmware esquece onde está o bootloader a cada reinício.
uefi_vars() {
  local dst="$VM_DIR/OVMF_VARS.fd"
  [[ -f "$dst" ]] && { echo "$dst"; return; }
  for t in /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/OVMF/OVMF_VARS.fd /usr/share/ovmf/OVMF_VARS.fd; do
    [[ -f "$t" ]] && { mkdir -p "$VM_DIR"; cp "$t" "$dst"; echo "$dst"; return; }
  done
  echo ""
}

# $1 = modo padrão deste comando (bios|uefi). BRUMMY_VM_UEFI=1/0 manda mais.
add_firmware() {
  local modo="${BRUMMY_VM_UEFI:+x}"
  if [[ -n "$modo" ]]; then
    [[ "$BRUMMY_VM_UEFI" == "1" ]] && modo="uefi" || modo="bios"
  else
    modo="$1"
  fi

  if [[ "$modo" == "bios" ]]; then
    echo "  firmware: BIOS legado (SeaBIOS). Se parar em '>>Start PXE over IPv4', esta VM é UEFI: BRUMMY_VM_UEFI=1" >&2
    return
  fi

  local code vars; code="$(uefi_code)"; vars="$(uefi_vars)"
  [[ -n "$code" ]] || die "UEFI pedido mas não achei o OVMF — sudo apt install ovmf"
  qemu_args+=(-drive "if=pflash,format=raw,readonly=on,file=$code")
  [[ -n "$vars" ]] && qemu_args+=(-drive "if=pflash,format=raw,file=$vars")
  echo "  firmware: UEFI (OVMF). Se parar em '>>Start PXE over IPv4', esta VM é BIOS: BRUMMY_VM_UEFI=0" >&2
}

case "${1:-help}" in
  deps)
    cat <<'DEPS'
No Debian/Ubuntu:

  sudo apt install qemu-system-x86 qemu-system-gui qemu-utils ovmf
  sudo usermod -aG kvm $USER     # e RELOGUE (ou reinicie) para valer

  qemu-system-gui é o que traz a janela GTK e o virgl (3D). Sem ele o
  -display gtk,gl=on não existe.

Conferir depois:
  ls -l /dev/kvm && qemu-system-x86_64 --version
DEPS
    ;;

  achar)
    echo "Discos de VM encontrados nesta máquina:"
    found=0; FOUND_FILES=()
    for d in "$HOME/.local/share/gnome-boxes/images" \
             "$HOME/.var/app/org.gnome.Boxes/data/gnome-boxes/images" \
             "/var/lib/libvirt/images" "$HOME/.local/share/libvirt/images" \
             "$HOME/VMs"; do
      [[ -d "$d" ]] || continue
      while IFS= read -r f; do
        printf '  %-10s %s\n' "$(du -h "$f" 2>/dev/null | cut -f1)" "$f"
        FOUND_FILES+=("$f"); found=1
      done < <(find "$d" -maxdepth 2 -type f \( -name '*.qcow2' -o -name '*.img' -o ! -name '*.*' \) -size +100M 2>/dev/null)
    done
    [[ "$found" == 1 ]] || { echo "  (nenhum)"; exit 0; }
    echo ""
    echo "Para bootar sem reinstalar — copie e cole uma destas linhas:"
    echo "(feche a VM no Boxes antes: dois QEMU no mesmo disco corrompem a imagem)"
    echo ""
    for f in "${FOUND_FILES[@]}"; do
      printf '  ./tools/vm.sh overlay %q\n' "$f"
    done
    echo ""
    echo "O 'overlay' cria um disco novo que aponta para esse, então a VM"
    echo "original do Boxes nunca é escrita. Para mexer no disco original"
    echo "mesmo, troque 'overlay' por 'rodar'."
    ;;

  criar)
    command -v qemu-img &>/dev/null || die "falta qemu-img — veja: ./tools/vm.sh deps"
    mkdir -p "$(dirname "$DISK")"
    [[ -f "$DISK" ]] && { echo "já existe: $DISK"; exit 0; }
    qemu-img create -f qcow2 "$DISK" "$DISK_SIZE"
    echo "disco criado: $DISK ($DISK_SIZE)"
    echo "agora: ./tools/vm.sh iso ~/Downloads/archlinux-x86_64.iso"
    ;;

  iso)
    command -v qemu-system-x86_64 &>/dev/null || die "falta qemu-system-x86_64 — veja: ./tools/vm.sh deps"
    check_kvm
    ISO="${2:-}"
    [[ -f "$ISO" ]] || die "uso: ./tools/vm.sh iso <arquivo.iso>"
    [[ -f "$DISK" ]] || die "sem disco — rode ./tools/vm.sh criar"
    build_args
    qemu_args+=(-drive "file=$DISK,if=virtio,format=qcow2" -cdrom "$ISO" -boot order=d)
    echo "==> bootando $ISO"
    add_firmware uefi
    exec qemu-system-x86_64 "${qemu_args[@]}"
    ;;

  rodar)
    command -v qemu-system-x86_64 &>/dev/null || die "falta qemu-system-x86_64 — veja: ./tools/vm.sh deps"
    check_kvm
    [[ -n "${2:-}" ]] && DISK="$2"
    [[ -f "$DISK" ]] || die "disco não encontrado: $DISK (veja ./tools/vm.sh achar)"
    build_args
    qemu_args+=(-drive "file=$DISK,if=virtio,format=qcow2" -boot order=c)
    echo "==> bootando $DISK (SSH em 127.0.0.1:$SSH_PORT)"
    add_firmware bios
    exec qemu-system-x86_64 "${qemu_args[@]}"
    ;;

  overlay)
    command -v qemu-img &>/dev/null || die "falta qemu-img — veja: ./tools/vm.sh deps"
    BASE="${2:-}"
    [[ -f "$BASE" ]] || die "uso: ./tools/vm.sh overlay <disco-base>  (veja ./tools/vm.sh achar)"
    BASE="$(readlink -f "$BASE")"
    FMT="$(qemu-img info "$BASE" 2>/dev/null | awk -F': ' '/^file format:/ { print $2; exit }')"
    [[ -n "$FMT" ]] || die "não consegui ler o formato de $BASE (é mesmo um disco de VM?)"
    mkdir -p "$VM_DIR"
    OVL="$VM_DIR/$(basename "$BASE")-overlay.qcow2"
    if [[ -f "$OVL" ]]; then
      echo "overlay já existe: $OVL"
    else
      qemu-img create -f qcow2 -b "$BASE" -F "$FMT" "$OVL" >/dev/null
      echo "overlay criado: $OVL"
      echo "  base (nunca é escrita): $BASE [$FMT]"
    fi
    echo ""
    echo "Bootando. Da próxima vez, direto:  ./tools/vm.sh rodar $OVL"
    echo "Para recomeçar do zero, apague o overlay e rode este comando de novo."
    echo "(o overlay depende do disco base — se você apagar a VM no Boxes, ele para de funcionar)"
    echo ""
    exec "$0" rodar "$OVL"
    ;;

  enviar)
    # Manda o repo INTEIRO para a VM em um comando, pela porta 2222 que o
    # `rodar` já encaminha. Usa tar em vez de scp de propósito: o caminho deste
    # repo tem espaço ("Default Project"), e scp passa o caminho por mais uma
    # camada de shell — é por isso que `scp -r ...:Documentos/Default Project/...`
    # falha com "Could not resolve hostname". Com tar o caminho nunca viaja.
    USER_VM="${2:-dbrum}"
    echo "==> enviando $REPO_DIR para $USER_VM@VM:~/brummy-linux"
    echo "    (a VM precisa estar rodando, com sshd ligado: sudo systemctl start sshd)"
    tar -C "$(dirname "$REPO_DIR")" --exclude=.git --exclude=iso/out --exclude=iso/.cache \
        -czf - "$(basename "$REPO_DIR")" \
      | ssh -p "$SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            "$USER_VM@127.0.0.1" 'rm -rf ~/brummy-linux.novo && mkdir -p ~/brummy-linux.novo &&
              tar -xzf - -C ~/brummy-linux.novo --strip-components=1 &&
              rm -rf ~/brummy-linux.antigo &&
              { [ -e ~/brummy-linux ] && mv ~/brummy-linux ~/brummy-linux.antigo || true; } &&
              mv ~/brummy-linux.novo ~/brummy-linux &&
              echo "  recebido em ~/brummy-linux ($(ls ~/brummy-linux | wc -l) itens no topo)"'
    echo ""
    echo "Na VM agora:  cd ~/brummy-linux && ./install.sh"
    ;;

  ssh)
    exec ssh -p "$SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      "${2:-dbrum}@127.0.0.1"
    ;;

  *)
    awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' "${BASH_SOURCE[0]}"
    ;;
esac
