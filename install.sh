#!/usr/bin/env bash
# Brummy Linux - instalador MVP (Arch + Hyprland híbrido)
# Idempotente: pode rodar várias vezes. Faz backup .bak antes de linkar.
set -euo pipefail

# --- perfis Brummy: --profile auto|desktop|thinkpad|general (default: auto) ---
# auto: DMI "ThinkPad T430" (ou outro ThinkPad/laptop) -> thinkpad;
#       VGA AMD discreta (RX 6600 XT) -> desktop; senão -> general.
# --no-dev: pula bundle dev. --with-android: inclui Android Studio (pesado, ~1GB+).
# --no-snapshots: não configura snapper mesmo com / em btrfs.
PROFILE="auto"
WITH_DEV=1
WITH_ANDROID=0
WITH_BOOT=1
WITH_SNAPSHOTS=1
BOOT_ONLY=0
USER_ONLY=0
while (( $# )); do
  arg="$1"; shift
  case "$arg" in
    --profile=*) PROFILE="${arg#*=}" ;;
    --profile) PROFILE="${1:-auto}"; shift || true ;;   # aceita "--profile thinkpad" também
    --no-dev) WITH_DEV=0 ;;
    --with-android) WITH_ANDROID=1 ;;
    --no-boot) WITH_BOOT=0 ;;
    --no-snapshots) WITH_SNAPSHOTS=0 ;;
    --boot-only) BOOT_ONLY=1 ;;
    --user-only) USER_ONLY=1 ;;   # só a camada de usuário: configs, tema, helpers
    -h|--help) echo "Uso: ./install.sh [--profile auto|desktop|thinkpad|general] [--no-dev] [--with-android] [--no-boot] [--no-snapshots] [--boot-only] [--user-only]"; exit 0 ;;
    *) echo "[brummy] arg desconhecido: $arg (ignorado)" ;;
  esac
done
case "$PROFILE" in
  auto|desktop|thinkpad|general) ;;
  *) echo "ERRO: perfil '$PROFILE' não existe (use auto, desktop, thinkpad ou general)"; exit 1 ;;
esac

# Log de tudo que o instalador fala: quando der erro na máquina de alguém,
# é este arquivo que conta o que aconteceu.
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/brummy"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "==> [brummy] log desta instalação: $LOG_FILE"

detect_profile() {
  local dmi="" chassis=""
  [[ -r /sys/devices/virtual/dmi/id/product_name ]] && dmi="$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null)"
  [[ -r /sys/devices/virtual/dmi/id/chassis_type ]] && chassis="$(cat /sys/devices/virtual/dmi/id/chassis_type 2>/dev/null)"
  # Só linhas que são sempre notebook. Aspire e Vivo têm desktop também,
  # por isso ficaram de fora: quem decide é o chassi ou a bateria, abaixo.
  if echo "$dmi" | grep -qi 'thinkpad\|latitude\|elitebook\|probook\|ideapad'; then
    echo "thinkpad"; return
  fi
  # SMBIOS chassis type: 8 portátil, 9 laptop, 10 notebook, 14 sub-notebook,
  # 30 tablet, 31 conversível, 32 destacável.
  case "$chassis" in
    8|9|10|14|30|31|32) echo "thinkpad"; return ;;
  esac
  if [[ -d /sys/class/power_supply/BAT0 || -d /sys/class/power_supply/BAT1 ]]; then
    echo "thinkpad"; return
  fi
  if lspci -nn 2>/dev/null | grep -qi 'AMD.*Radeon.*RX\|AMD.*Navi'; then
    echo "desktop"; return
  fi
  echo "general"
}

if [[ "$PROFILE" == "auto" ]]; then
  PROFILE="$(detect_profile)"
  echo "==> [brummy] perfil auto-detectado: $PROFILE"
else
  echo "==> [brummy] perfil forçado: $PROFILE"
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$REPO_DIR/config"
BIN_SRC="$REPO_DIR/bin/brummy"
TARGET_BIN="$HOME/.local/bin/brummy"

echo "==> [brummy] checando base..."
if [[ ! -f /etc/arch-release ]]; then
  echo "ERRO: o Brummy só roda sobre Arch Linux. Você está em: $(cat /etc/os-release 2>/dev/null | grep PRETTY || echo desconhecido)"
  exit 1
fi

if [[ "$USER_ONLY" == "1" ]]; then
  echo "==> [brummy] --user-only: pulando pacotes, serviços e boot (só configs de usuário)"
  WITH_BOOT=0
fi

if [[ "$USER_ONLY" == "0" ]]; then
echo "==> [brummy] habilitando multilib (necessário p/ Steam + drivers lib32 RX 6600 XT)..."
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
  sudo sed -i '/#\[multilib\]/,/#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' /etc/pacman.conf
  grep -q '^\[multilib\]' /etc/pacman.conf || {
    echo -e '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist' | sudo tee -a /etc/pacman.conf > /dev/null
  }
  echo "  multilib habilitado"
else
  echo "  multilib já ativo"
fi

echo "==> [brummy] atualizando sistema (pacman)..."
sudo pacman -Syu --needed --noconfirm

# paru para AUR (waybar já está no extra, mas deixamos porta aberta)
# Checa se funciona, não só se o binário existe: um paru velho linkado contra
# libalpm.so < atual (o -Syu acima sobe a soname) existe mas está quebrado,
# e aí todo o AUR falha em silêncio.
paru_ok() { command -v paru &>/dev/null && paru --version &>/dev/null 2>&1; }
yay_ok()  { command -v yay  &>/dev/null && yay  --version &>/dev/null 2>&1; }
if ! paru_ok && ! yay_ok; then
  echo "==> [brummy] instalando paru (AUR helper)..."
  sudo pacman -S --needed --noconfirm base-devel git
  tmp=$(mktemp -d)
  # paru-bin primeiro: binário pré-compilado, evita OOM do rustc+LTO em máquina fraca
  if ! (git clone https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin" && (cd "$tmp/paru-bin" && makepkg -si --noconfirm)); then
    echo "  (paru-bin falhou, tentando compilar paru fonte com -j2...)"
    git clone https://aur.archlinux.org/paru.git "$tmp/paru"
    (cd "$tmp/paru" && MAKEFLAGS="-j2" CARGO_BUILD_JOBS=2 makepkg -si --noconfirm)
  fi
  # paru-bin é prebuilt; se veio linkado contra libalpm.so antiga, instalar
  # de novo não resolve — compila a fonte para relinkar contra a atual.
  if ! paru_ok; then
    echo "  (paru-bin veio quebrado, compilando a fonte...)"
    if git clone https://aur.archlinux.org/paru.git "$tmp/paru"; then
      # o paru-bin quebrado continua instalado e conflita com o paru fonte
      sudo -n pacman -R --noconfirm paru-bin paru-bin-debug 2>/dev/null || true
      (cd "$tmp/paru" && MAKEFLAGS="-j2" CARGO_BUILD_JOBS=2 makepkg -si --noconfirm)
    fi
  fi
  rm -rf "$tmp"
fi
AUR="paru -S --needed --noconfirm"
paru_ok || AUR="yay -S --needed --noconfirm"

# Alguns PKGBUILD (ex: whitesur-gtk-theme) usam `setterm` e quebram sem TERM
# (rodando via nohup/SSH). Garante um TERM mínimo pro build não falhar.
export TERM="${TERM:-xterm}"

echo "==> [brummy] instalando pacotes..."
# Bundle opinionado estilo Omarchy: lê de packages/*.packages
# Edite os arquivos pra sua cara, rode ./install.sh de novo (idempotente).
if [[ "$BOOT_ONLY" == "1" ]]; then
  echo "  (--boot-only: pulando pacotes)"
else
  # Um por vez com || true: nome inexistente/quebrado não aborta o resto (set -e)
  while read -r pkg; do
    [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
    sudo pacman -S --needed --noconfirm "$pkg" || echo "[brummy] pacman pulou: $pkg"
  done < <(grep -v '^#' "$REPO_DIR/packages/base.packages" | grep -v '^$')
fi

echo "==> [brummy] instalando AUR (opcional, não trava se falhar)..."
if [[ "$BOOT_ONLY" == "1" ]]; then
  echo "  (--boot-only: pulando AUR)"
else
  while read -r pkg; do
    [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
    $AUR "$pkg" || echo "[brummy] AUR opcional falhou: $pkg"
  done < "$REPO_DIR/packages/aur.packages"
fi

if [[ "$BOOT_ONLY" == "1" ]]; then
  echo "==> [brummy] dev bundle pulado (--boot-only)"
elif [[ "$WITH_DEV" == "1" ]]; then
  echo "==> [brummy] dev bundle (Java + Node + Python + DBs + k8s)..."
  while read -r pkg; do
    [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
    sudo pacman -S --needed --noconfirm "$pkg" || echo "[brummy] dev pacman pulou: $pkg"
  done < <(grep -v '^#' "$REPO_DIR/packages/dev.packages" | grep -v '^$')
  while read -r pkg; do
    [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
    $AUR "$pkg" || echo "[brummy] dev AUR opcional falhou: $pkg"
  done < "$REPO_DIR/packages/dev-aur.packages"
  # Java default: latest (espelha Temurin 25 do Debian); LTS 21 de fallback
  sudo archlinux-java set java-25-openjdk 2>/dev/null || sudo archlinux-java set java-21-openjdk 2>/dev/null || true
  # Postgres local (espelha cluster 17 do Debian): initdb só na 1ª vez
  if [[ ! -s /var/lib/postgres/data/PG_VERSION ]]; then
    echo "  initdb postgres..."
    sudo -iu postgres initdb -D /var/lib/postgres/data --locale pt_BR.UTF-8 2>/dev/null || sudo -iu postgres initdb -D /var/lib/postgres/data || true
  fi
  sudo systemctl enable --now postgresql.service 2>/dev/null || true
else
  echo "==> [brummy] dev bundle pulado (--no-dev)"
fi

if [[ "$BOOT_ONLY" == "1" ]]; then
  echo "==> [brummy] Android (--boot-only: pulado)"
elif [[ "$WITH_ANDROID" == "1" ]]; then
  echo "==> [brummy] Android Studio (pesado)..."
  while read -r pkg; do
    [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
    $AUR "$pkg" || echo "[brummy] android AUR opcional falhou: $pkg"
  done < "$REPO_DIR/packages/android-aur.packages"
fi

if [[ "$BOOT_ONLY" == "1" ]]; then
  echo "==> [brummy] stack laptop pulada (--boot-only)"
elif [[ "$PROFILE" == "thinkpad" ]]; then
  echo "==> [brummy] perfil thinkpad/T430 (Intel HD4000 + bateria)..."
  while read -r pkg; do
    [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
    sudo pacman -S --needed --noconfirm "$pkg" || echo "[brummy] laptop pacman pulou: $pkg"
  done < <(grep -v '^#' "$REPO_DIR/packages/laptop.packages" | grep -v '^$')
  sudo systemctl enable --now tlp.service NetworkManager.service acpid.service 2>/dev/null || true
  sudo systemctl enable --now thermald.service 2>/dev/null || true
  sudo systemctl mask power-profiles-daemon.service 2>/dev/null || true  # conflita com TLP
  sudo systemctl enable --now thinkfan.service 2>/dev/null || echo "  thinkfan: ajuste /etc/thinkfan.yaml no T430 e dê enable manual"
  sudo tlp start 2>/dev/null || true
else
  echo "==> [brummy] perfil $PROFILE: sem stack laptop (TLP/thinkfan só no thinkpad)"
fi

# Snapshots: numa rolling, uma atualização ruim pode deixar a sessão gráfica
# sem subir. Com / em btrfs, o snapper + snap-pac tiram um snapshot antes e
# depois de todo pacman, e o grub-btrfs põe esses snapshots no menu do GRUB
# para dar boot num estado que funcionava. Sem btrfs, só avisa.
if [[ "$BOOT_ONLY" == "1" || "$WITH_SNAPSHOTS" == "0" ]]; then
  echo "==> [brummy] snapshots pulados"
elif [[ "$(findmnt -no FSTYPE / 2>/dev/null)" == "btrfs" ]]; then
  echo "==> [brummy] snapshots (/ em btrfs: snapper + snap-pac + grub-btrfs)..."
  while read -r pkg; do
    [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
    sudo pacman -S --needed --noconfirm "$pkg" || echo "[brummy] snapshots pacman pulou: $pkg"
  done < <(grep -v '^#' "$REPO_DIR/packages/btrfs.packages" | grep -v '^$')
  if [[ -f /etc/snapper/configs/root ]]; then
    echo "  snapper já configurado para /"
  elif command -v snapper &>/dev/null; then
    # O archinstall cria o subvolume @.snapshots montado em /.snapshots, e o
    # create-config recusa se o diretório já existe. Receita da Arch Wiki:
    # desmonta, deixa o snapper criar o dele, troca pelo @.snapshots de novo.
    if mountpoint -q /.snapshots; then
      sudo umount /.snapshots && sudo rmdir /.snapshots \
        && sudo snapper -c root create-config / \
        && sudo btrfs subvolume delete /.snapshots \
        && sudo mkdir /.snapshots \
        && sudo mount -a \
        || echo "  AVISO: não consegui configurar o snapper sobre o /.snapshots existente — veja docs/snapshots.md"
    else
      sudo snapper -c root create-config / || echo "  AVISO: snapper create-config falhou — veja docs/snapshots.md"
    fi
    sudo chmod 750 /.snapshots 2>/dev/null || true
  fi
  if [[ -f /etc/snapper/configs/root ]]; then
    # Retenção modesta: snap-pac cria dois por transação e o disco enche rápido.
    sudo snapper -c root set-config NUMBER_LIMIT=10 NUMBER_LIMIT_IMPORTANT=5 TIMELINE_CREATE=no 2>/dev/null || true
    sudo systemctl enable --now snapper-cleanup.timer 2>/dev/null || true
    sudo systemctl enable --now grub-btrfsd.service 2>/dev/null || true
    echo "  ok: todo pacman agora tira snapshot antes/depois (veja: brummy snapshot)"
  fi
else
  echo "==> [brummy] snapshots: / não é btrfs ($(findmnt -no FSTYPE / 2>/dev/null || echo '?')) — sem rede de segurança automática"
  echo "  (numa instalação nova, escolha btrfs no archinstall para ganhar snapshots)"
fi

fi  # fim do bloco que precisa de root (pacotes, perfis de máquina)

echo "==> [brummy] wallpapers (padrões do sistema)..."
mkdir -p "$HOME/Pictures/Brummy"
for w in "$REPO_DIR/themes/wallpapers/"*.jpg "$REPO_DIR/themes/wallpapers/"*.jpeg "$REPO_DIR/themes/wallpapers/"*.png; do
  [[ -f "$w" ]] && cp -f "$w" "$HOME/Pictures/Brummy/"
done
# Padrão: space1.jpg; respeita troca já feita via `brummy wallpaper`.
# O link se chama current.JPG porque o hyprpaper escolhe o decodificador pela
# extensão — assim ele aplica o papel de parede sozinho, mesmo que nada mais
# do Brummy tenha sido instalado ainda.
if [[ ! -L "$HOME/Pictures/Brummy/current.jpg" ]]; then
  ln -sf "$HOME/Pictures/Brummy/space1.jpg" "$HOME/Pictures/Brummy/current.jpg"
fi
# Sobra de versão anterior: o link sem extensão não servia para nada
[[ -L "$HOME/Pictures/Brummy/current" ]] && rm -f "$HOME/Pictures/Brummy/current"
# Legado: mantém brummy-wallpaper.jpg apontando pro atual
ln -sf "$HOME/Pictures/Brummy/current.jpg" "$HOME/Pictures/brummy-wallpaper.jpg"

echo "==> [brummy] linkando configs (com backup)..."
mkdir -p "$HOME/.config" "$HOME/.local/bin"

link_dir() {
  local name="$1"
  local src="$CONFIG_SRC/$name"
  local dst="$HOME/.config/$name"
  [[ -e "$src" ]] || return 0
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    echo "  ok $name já linkado"
    return 0
  fi
  # Link apontando para o vazio (repo movido/apagado): remove em vez de tentar
  # backup. Em ~/.config/hypr isso impede o Hyprland de subir, com a mensagem
  # "Couldn't create config home directory (File exists)" — e o login não entra.
  if [[ -L "$dst" && ! -e "$dst" ]]; then
    echo "  link quebrado em $name (-> $(readlink "$dst")): removendo"
    rm -f "$dst"
  fi
  if [[ -e "$dst" ]]; then
    echo "  backup $dst -> $dst.bak-brummy"
    mv "$dst" "$dst.bak-brummy-$(date +%s)"
  fi
  ln -s "$src" "$dst"
  echo "  link $name"
}

for d in hypr waybar kitty wofi fish nwg-dock-hyprland fastfetch; do
  link_dir "$d"
done

# Logo do Brummy fora do repo, para o fastfetch em modo imagem (kitty)
mkdir -p "$HOME/.local/share/brummy"
cp -f "$REPO_DIR/boot/assets/logo.png" "$HOME/.local/share/brummy/logo.png" 2>/dev/null || true

# GTK: settings.ini é COPIADO (não linkado) porque nwg-look/GTK escrevem nele
# e não queremos que uma mexida na GUI suje o repo sem querer.
echo "==> [brummy] tema GTK (WhiteSur-Dark + Bibata)..."
for g in gtk-3.0 gtk-4.0; do
  [[ -f "$CONFIG_SRC/$g/settings.ini" ]] || continue
  mkdir -p "$HOME/.config/$g"
  if [[ -f "$HOME/.config/$g/settings.ini" ]] && ! cmp -s "$CONFIG_SRC/$g/settings.ini" "$HOME/.config/$g/settings.ini"; then
    cp -f "$HOME/.config/$g/settings.ini" "$HOME/.config/$g/settings.ini.bak-brummy-$(date +%s)"
  fi
  cp -f "$CONFIG_SRC/$g/settings.ini" "$HOME/.config/$g/settings.ini"
done
# GTK2 (apps velhos) lê ~/.gtkrc-2.0
cat > "$HOME/.gtkrc-2.0" <<'GTK2'
gtk-theme-name="WhiteSur-Dark"
gtk-icon-theme-name="WhiteSur"
gtk-cursor-theme-name="Bibata-Modern-Ice"
gtk-cursor-theme-size=28
gtk-font-name="Inter 11"
GTK2
# Cursor global (XWayland + apps que leem o índice padrão)
mkdir -p "$HOME/.icons/default"
printf '[Icon Theme]\nInherits=Bibata-Modern-Ice\n' > "$HOME/.icons/default/index.theme"

echo "==> [brummy] perfil Hyprland: $PROFILE (monitores + GPU)..."
# Config em Lua (Hyprland 0.55+). O hyprlang/.conf sai de cena na 0.57;
# a versão antiga ficou em config/hypr/legacy/ só para consulta.
HYPR_DIR="$HOME/.config/hypr"
case "$PROFILE" in
  desktop) MON="monitors-desktop.lua"; GPU="gpu-amd.lua" ;;
  thinkpad) MON="monitors-thinkpad.lua"; GPU="gpu-intel.lua" ;;
  *) MON="monitors-general.lua"
     # general: AMD discreta usa RADV, resto Intel
     if lspci -nn 2>/dev/null | grep -qi 'AMD.*Radeon.*RX\|AMD.*Navi'; then GPU="gpu-amd.lua"; else GPU="gpu-intel.lua"; fi ;;
esac
ln -sf "$HYPR_DIR/modules/$MON" "$HYPR_DIR/modules/profile-monitors.lua"
ln -sf "$HYPR_DIR/modules/$GPU" "$HYPR_DIR/modules/profile-gpu.lua"
echo "  monitores: $MON | gpu: $GPU"
# Sobra de instalação antiga: um hyprland.conf solto ganha do .lua em algumas
# versões. Se existir fora do repo, tira do caminho.
if [[ -f "$HYPR_DIR/hyprland.conf" && ! -L "$HYPR_DIR" ]]; then
  mv "$HYPR_DIR/hyprland.conf" "$HYPR_DIR/hyprland.conf.pre-lua-$(date +%s)"
  echo "  hyprland.conf antigo movido (agora vale o hyprland.lua)"
fi

# Conferência: link que não resolve = login gráfico que não entra.
for d in hypr waybar kitty wofi fish nwg-dock-hyprland fastfetch; do
  alvo="$HOME/.config/$d"
  if [[ -L "$alvo" && ! -e "$alvo" ]]; then
    echo "  AVISO: $alvo aponta para o vazio — rode 'brummy fix'"
  fi
done
echo "  (os configs são LINKS para este repo em $REPO_DIR —"
echo "   se você mover ou apagar esta pasta, rode 'brummy fix' antes de deslogar)"

echo "==> [brummy] instalando comando brummy..."
ln -sf "$BIN_SRC" "$TARGET_BIN"
for helper in brummy-remove-preinstalls brummy-wallpaper-apply brummy-hide-apps brummy-minimizados; do
  ln -sf "$REPO_DIR/bin/$helper" "$HOME/.local/bin/$helper"
  chmod +x "$REPO_DIR/bin/$helper"
done
chmod +x "$TARGET_BIN"
export PATH="$HOME/.local/bin:$PATH"

echo "==> [brummy] shell padrão: fish (só se quiser, não forçado)..."
if [[ "$SHELL" != *fish ]]; then
  echo "  rode: chsh -s /usr/bin/fish  (opcional)"
fi

if [[ "$USER_ONLY" == "0" ]]; then
echo "==> [brummy] habilitando serviços..."
systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
sudo systemctl enable --now NetworkManager 2>/dev/null || true
echo "==> [brummy] login gráfico (greetd -> Hyprland)..."
sudo mkdir -p /etc/greetd
sudo cp -f "$REPO_DIR/config/greetd/config.toml" /etc/greetd/config.toml
sudo systemctl enable greetd.service 2>/dev/null || true

echo "==> [brummy] KVM/libvirt (virt-manager)..."
sudo systemctl enable --now libvirtd.service 2>/dev/null || true
sudo virsh net-autostart default 2>/dev/null || true
sudo virsh net-start default 2>/dev/null || true
sudo usermod -aG libvirt,kvm,docker "$USER" 2>/dev/null || true
echo "  (relogue para valer os grupos: libvirt kvm docker)"

fi  # fim dos serviços de sistema

echo "==> [brummy] claudebar (uso Claude na Waybar)..."
if ! command -v claudebar &>/dev/null; then
  curl -fsSL https://raw.githubusercontent.com/mryll/claudebar/master/claudebar -o "$HOME/.local/bin/claudebar" && chmod +x "$HOME/.local/bin/claudebar" || echo "  claudebar via curl falhou (tente AUR claudebar)"
fi
chmod +x "$REPO_DIR/config/waybar/scripts/"*.sh 2>/dev/null || true

echo "==> [brummy] defaults: Helium como browser padrão + VSCodium como editor gráfico..."
# Helium (helium-browser-bin) como default, com fallback para firefox
if command -v helium-browser &>/dev/null; then
  HELIUM_DESKTOP="$(grep -rl 'Exec=.*helium' /usr/share/applications/ ~/.local/share/applications/ 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo 'helium-browser.desktop')"
  xdg-settings set default-web-browser "$HELIUM_DESKTOP" 2>/dev/null || true
  xdg-mime default "$HELIUM_DESKTOP" x-scheme-handler/http x-scheme-handler/https text/html 2>/dev/null || true
  echo "  default browser: $HELIUM_DESKTOP"
elif command -v helium &>/dev/null; then
  xdg-settings set default-web-browser helium.desktop 2>/dev/null || true
  echo "  default browser: helium (binário alternativo)"
else
  echo "  helium ainda não instalado (vai no próximo ./install.sh após AUR)"
fi
# VSCodium como VISUAL/EDITOR gráfico (nvim segue como EDITOR terminal no fish)
if command -v codium &>/dev/null; then
  echo "  vscodium detectado: VISUAL=codium (configurado no fish)"
else
  echo "  vscodium ainda não instalado (vai no próximo ./install.sh após AUR)"
fi
echo "==> [brummy] defaults: Nautilus como gerenciador + accent azul (estilo ChromaLeon)..."
if command -v nautilus &>/dev/null; then
  NAUTILUS_DESKTOP="$(grep -rl '^Exec=.*nautilus' /usr/share/applications/ ~/.local/share/applications/ 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo 'org.gnome.Nautilus.desktop')"
  xdg-mime default "$NAUTILUS_DESKTOP" inode/directory 2>/dev/null || true
  echo "  gerenciador padrão: $NAUTILUS_DESKTOP (thunar segue instalado)"
fi
# Accent azul nos apps Adwaita (Nautilus) — mesmo efeito do ChromaLeon, sem GNOME Shell
gsettings set org.gnome.desktop.interface accent-color 'blue' 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur' 2>/dev/null || true
# ESTA é a chave que os apps GTK4/libadwaita (Nautilus, Calculadora,
# Text Editor) obedecem — sem ela eles abrem brancos no meio do tema escuro.
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice' 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-size 28 2>/dev/null || true
gsettings set org.gnome.desktop.interface font-name 'Inter 11' 2>/dev/null || true
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11' 2>/dev/null || true

echo "==> [brummy] limpando o launcher (apps parasitas de dependência)..."
"$REPO_DIR/bin/brummy-hide-apps" || true

echo ""
if [[ "$WITH_BOOT" == "1" ]]; then
  echo "==> [brummy] boot: Plymouth + GRUB com a logo..."
  if [[ ! -f "$REPO_DIR/boot/assets/.assets-ok" ]]; then
    echo "  gerando assets da logo..."
    python3 "$REPO_DIR/boot/make-assets.py" || echo "  AVISO: salve a logo em boot/assets/logo.png e rode ./install.sh --boot-only"
  fi
  if [[ -f "$REPO_DIR/boot/assets/.assets-ok" ]]; then
    echo "  instalando tema Plymouth 'brummy'..."
    sudo mkdir -p /usr/share/plymouth/themes/brummy/assets
    sudo cp -f "$REPO_DIR/boot/plymouth/brummy.plymouth" "$REPO_DIR/boot/plymouth/brummy.script" /usr/share/plymouth/themes/brummy/
    sudo cp -f "$REPO_DIR/boot/assets/logo.png" "$REPO_DIR/boot/assets/glow.png" "$REPO_DIR/boot/assets/dot.png" "$REPO_DIR/boot/assets/bar-bg.png" "$REPO_DIR/boot/assets/bar-fill.png" /usr/share/plymouth/themes/brummy/assets/
    sudo plymouth-set-default-theme -R brummy 2>/dev/null || {
      sudo plymouth-set-default-theme brummy
      if ! grep -q 'plymouth' /etc/mkinitcpio.conf; then
        sudo sed -i 's/^HOOKS=(\(.*\)udev\(.*\))/HOOKS=(\1udev plymouth\2)/' /etc/mkinitcpio.conf
      fi
      sudo mkinitcpio -P
    }
    echo "  fundo do GRUB..."
    sudo mkdir -p /boot/grub
    sudo cp -f "$REPO_DIR/boot/assets/grub-background.png" /boot/grub/brummy-background.png
    sudo sed -i 's/^#\?GRUB_BACKGROUND=.*/GRUB_BACKGROUND="\/boot\/grub\/brummy-background.png"/' /etc/default/grub 2>/dev/null || echo 'GRUB_BACKGROUND="/boot/grub/brummy-background.png"' | sudo tee -a /etc/default/grub > /dev/null
    sudo sed -i 's/^#\?GRUB_GFXMODE=.*/GRUB_GFXMODE=1920x1080,auto/' /etc/default/grub
    sudo sed -i 's/^#\?GRUB_COLOR_NORMAL=.*/GRUB_COLOR_NORMAL="white\/black"/' /etc/default/grub
    sudo sed -i 's/^#\?GRUB_COLOR_HIGHLIGHT=.*/GRUB_COLOR_HIGHLIGHT="white\/dark-gray"/' /etc/default/grub
    if ! grep -q 'splash' /etc/default/grub; then
      sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\([^"]*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 quiet splash"/' /etc/default/grub
    fi
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    echo "  boot pronto: GRUB com logo + splash com luz pulsante"
  else
    echo "  boot pulado: sem assets (adicione a logo e rode ./install.sh --boot-only)"
  fi
else
  echo "==> [brummy] boot pulado (--no-boot)"
fi

if [[ "$BOOT_ONLY" == "1" ]]; then
  echo "==> [brummy] --boot-only: só boot refeito, saindo."
  exit 0
fi

echo ""
echo "==> Pronto! Brummy Linux instalado."
echo "  - Logout e entre na sessão Hyprland"
echo "  - SUPER+ESPAÇO: launcher | SUPER+Q: terminal | SUPER+E: arquivos | SUPER+L: bloquear"
echo "  - Rode: brummy help   (algo estranho? brummy doctor)"
echo "  - Barras de título clicáveis (opcional): brummy bars on  — dentro da sessão"
echo "  - Log desta instalação: $LOG_FILE"
