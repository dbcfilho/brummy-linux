#!/usr/bin/env bash
# build-iso.sh — roda DENTRO do container Arch (chamado por iso/build.sh).
set -euo pipefail

REPO_DIR=/brummy
PROFILE=/tmp/brummy-profile
WORK=/tmp/brummy-work
AUR_DIR=/tmp/brummy-aur
OUT=/out

echo "==> [1/6] dependências da build"
pacman-key --init &>/dev/null || true
pacman -Sy --noconfirm --needed archiso git base-devel sudo squashfs-tools

echo "==> [2/6] pacotes AUR -> repositório local"
bash "$REPO_DIR/iso/builder/aur-repo.sh" "$REPO_DIR" "$AUR_DIR"

echo "==> [3/6] montando o perfil archiso a partir do releng"
rm -rf "$PROFILE"
cp -r /usr/share/archiso/configs/releng "$PROFILE"
# o releng sobe reflector no boot do live e isso atrasa tudo
rm -f "$PROFILE/airootfs/etc/systemd/system/multi-user.target.wants/reflector.service"
rm -rf "$PROFILE/airootfs/etc/systemd/system/reflector.service.d"

cp -f "$REPO_DIR/iso/profile/profiledef.sh" "$PROFILE/profiledef.sh"
cp -rT "$REPO_DIR/iso/profile/airootfs" "$PROFILE/airootfs"

echo "==> [4/6] pacman.conf com multilib + repositório AUR local"
cp -f /etc/pacman.conf "$PROFILE/pacman.conf"
sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' "$PROFILE/pacman.conf"
cat >> "$PROFILE/pacman.conf" <<PACMAN

[brummy-aur]
SigLevel = Optional TrustAll
Server = file://$AUR_DIR
PACMAN

echo "==> [5/6] pacotes e conteúdo do Brummy"
bash "$REPO_DIR/iso/builder/gen-packages.sh" "$REPO_DIR" "$PROFILE/packages.x86_64"
# tira da lista o que o AUR não conseguiu construir
if [[ -f "$AUR_DIR/FALHARAM.txt" ]]; then
  while read -r p; do
    [[ -n "$p" ]] && sed -i "/^${p}$/d" "$PROFILE/packages.x86_64"
  done < "$AUR_DIR/FALHARAM.txt"
fi

# o repo inteiro vai junto: é dele que sai a camada de usuário no live
# e é ele que a pessoa mexe depois de instalar
mkdir -p "$PROFILE/airootfs/opt"
cp -r "$REPO_DIR" "$PROFILE/airootfs/opt/brummy-linux"
rm -rf "$PROFILE/airootfs/opt/brummy-linux/iso" \
       "$PROFILE/airootfs/opt/brummy-linux/.git" \
       "$PROFILE/airootfs/opt/brummy-linux/_to_delete"

# configuração do instalador gráfico
mkdir -p "$PROFILE/airootfs/etc/calamares"
cp -rT "$REPO_DIR/iso/calamares" "$PROFILE/airootfs/etc/calamares"
mkdir -p "$PROFILE/airootfs/usr/share/brummy"
cp -f "$REPO_DIR/boot/assets/logo.png" "$PROFILE/airootfs/usr/share/brummy/logo.png"
cp -f "$REPO_DIR/boot/assets/logo.png" "$PROFILE/airootfs/etc/calamares/branding/brummy/logo.png"
cp -f "$REPO_DIR/boot/assets/grub-background.png" \
      "$PROFILE/airootfs/etc/calamares/branding/brummy/welcome.png" 2>/dev/null || true

# serviços ligados no live
WANTS="$PROFILE/airootfs/etc/systemd/system/multi-user.target.wants"
mkdir -p "$WANTS"
ln -sf /usr/lib/systemd/system/greetd.service          "$WANTS/greetd.service"
ln -sf /usr/lib/systemd/system/NetworkManager.service  "$WANTS/NetworkManager.service"
ln -sf ../brummy-live-setup.service                    "$WANTS/brummy-live-setup.service"

echo "==> [6/6] mkarchiso (demora — 20 a 60 min na primeira vez)"
rm -rf "$WORK"; mkdir -p "$WORK" "$OUT"
mkarchiso -v -w "$WORK" -o "$OUT" "$PROFILE"

chmod -R a+rw "$OUT" 2>/dev/null || true
echo ""
echo "==> ISO gerada:"
ls -lh "$OUT"/*.iso
