#!/usr/bin/env bash
# build-iso.sh — roda DENTRO do container Arch (chamado por iso/build.sh).
set -euo pipefail

REPO_DIR=/brummy
PROFILE=/tmp/brummy-profile
WORK=/tmp/brummy-work
AUR_DIR=/tmp/brummy-aur          # iso/build.sh monta o cache iso/.cache/aur aqui
OUT=/out
RELENG=/usr/share/archiso/configs/releng
NO_CACHE=""
[[ "${1:-}" == "--no-cache" ]] && NO_CACHE="--no-cache"

# Liga o multilib (Steam, drivers lib32). O sed sozinho não basta: na 2ª build
# do CI ele não casou com o pacman.conf da imagem Docker e o mkarchiso
# sincronizou só core e extra — "target not found: lib32-mesa, steam...".
# Mesma rede de segurança que o install.sh já tinha: se não pegou, acrescenta.
garante_multilib() {
  local conf="$1"
  sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' "$conf"
  grep -q '^\[multilib\]' "$conf" || printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >> "$conf"
  grep -q '^\[multilib\]' "$conf" || { echo "ERRO: não consegui ligar o multilib em $conf"; exit 1; }
}

echo "==> [1/7] dependências da build"
pacman-key --init &>/dev/null || true
# multilib também no container: sem ele, dependência lib32 de pacote do AUR
# parece "não existe" e o pacote falha
garante_multilib /etc/pacman.conf
# -Syu, não -Sy: atualização parcial é o jeito clássico de quebrar um Arch.
# dosfstools + mtools: o mkarchiso monta a partição EFI da ISO com eles.
# curl + jq: o aur-repo.sh resolve dependências pela API do AUR.
pacman -Syu --noconfirm --needed archiso git base-devel sudo squashfs-tools \
  dosfstools mtools curl jq

echo "==> [2/7] pacotes AUR -> repositório local"
bash "$REPO_DIR/iso/builder/aur-repo.sh" "$REPO_DIR" "$AUR_DIR" "$NO_CACHE"

echo "==> [3/7] perfil: boot do releng + airootfs do Brummy"
rm -rf "$PROFILE"
mkdir -p "$PROFILE"
# Do releng vem o que faz a ISO bootar (grub, syslinux, efiboot). O airootfs
# NÃO vem inteiro: ele é o ambiente do instalador do Arch — root sem senha,
# autologin de root no tty1, sshd aceitando root, networkd + iwd brigando com
# o NetworkManager. E o Calamares copia o live para o disco de quem instala.
cp -r "$RELENG/grub" "$RELENG/syslinux" "$RELENG/efiboot" "$RELENG/bootstrap_packages" "$PROFILE/"
cp -f "$REPO_DIR/iso/profile/profiledef.sh" "$PROFILE/profiledef.sh"
# Só o que o live precisa para bootar e ter pacman. O brummy-pos-instalacao
# tira isto do sistema instalado.
for f in \
    etc/mkinitcpio.conf.d/archiso.conf \
    etc/systemd/system/pacman-init.service \
    etc/systemd/system/etc-pacman.d-gnupg.mount \
    etc/systemd/system/multi-user.target.wants/pacman-init.service \
    etc/systemd/journald.conf.d/volatile-storage.conf \
    etc/systemd/logind.conf.d/do-not-suspend.conf \
    etc/pacman.d/hooks/uncomment-mirrors.hook \
    etc/pacman.d/hooks/zzzz99-remove-custom-hooks-from-airootfs.hook \
    etc/locale.conf; do
  if [[ -e "$RELENG/airootfs/$f" || -L "$RELENG/airootfs/$f" ]]; then
    mkdir -p "$PROFILE/airootfs/$(dirname "$f")"
    cp -a "$RELENG/airootfs/$f" "$PROFILE/airootfs/$f"
  else
    echo "  AVISO: o releng não tem mais $f — confira se o live ainda boota"
  fi
done
cp -rT "$REPO_DIR/iso/profile/airootfs" "$PROFILE/airootfs"

echo "==> [4/7] pacman.conf com multilib + repositório AUR local"
# Do releng, NÃO do container: o pacman.conf da imagem Docker do Arch tem
# NoExtract para ela ser pequena, e o pacstrap obedece. Na 3ª build do CI o
# live saiu sem /etc/pacman.conf e sem mirrorlist por isso — e também sairia
# sem usr/share/locale e i18n, ou seja, sem pt_BR no live e no instalado.
cp -f "$RELENG/pacman.conf" "$PROFILE/pacman.conf"
if grep -q '^NoExtract' "$PROFILE/pacman.conf"; then
  echo "ERRO: o pacman.conf do perfil tem NoExtract — a ISO sairia faltando arquivos"; exit 1
fi
garante_multilib "$PROFILE/pacman.conf"
cat >> "$PROFILE/pacman.conf" <<PACMAN

[brummy-aur]
SigLevel = Optional TrustAll
Server = file://$AUR_DIR
PACMAN

echo "==> [5/7] lista de pacotes"
bash "$REPO_DIR/iso/builder/gen-packages.sh" "$REPO_DIR" "$PROFILE/packages.x86_64"
# tira da lista o que o AUR não conseguiu construir
if [[ -f "$AUR_DIR/FALHARAM.txt" ]]; then
  while read -r p; do
    [[ -n "$p" ]] && sed -i "/^${p}$/d" "$PROFILE/packages.x86_64"
  done < "$AUR_DIR/FALHARAM.txt"
fi
# Um nome que nenhum repositório tem derruba o mkarchiso inteiro no fim da
# build (o pacstrap não pula nada). Confere antes, com o mesmo pacman.conf,
# e tira com aviso: melhor uma ISO sem um pacote do que nenhuma ISO.
pacman --config "$PROFILE/pacman.conf" -Sy >/dev/null
sumidos=()
while read -r p; do
  [[ -z "$p" || "$p" == \#* ]] && continue
  # -Si: o nome existe? -Sp só de reserva, para nome virtual (provides)
  pacman --config "$PROFILE/pacman.conf" -Si "$p" &>/dev/null \
    || pacman --config "$PROFILE/pacman.conf" -Sp --print-format '%n' "$p" &>/dev/null \
    || sumidos+=("$p")
done < "$PROFILE/packages.x86_64"
if ((${#sumidos[@]})); then
  echo "  AVISO: nenhum repositório tem: ${sumidos[*]} — saem da ISO"
  for p in "${sumidos[@]}"; do sed -i "/^${p}$/d" "$PROFILE/packages.x86_64"; done
  printf '%s\n' "${sumidos[@]}" > "$OUT/SUMIDOS.txt"
fi

echo "==> [6/7] conteúdo do Brummy"
# O repo vai junto, com .git: é dele que sai a camada de usuário (no live e na
# instalação), e no sistema instalado ele vira ~/brummy-linux, um clone de
# verdade — git pull funciona. Sem o que é saída ou cache da própria build.
mkdir -p "$PROFILE/airootfs/opt/brummy-linux"
tar -C "$REPO_DIR" \
    --exclude='./iso/out' --exclude='./iso/.cache' --exclude='./_to_delete' \
    -cf - . | tar -C "$PROFILE/airootfs/opt/brummy-linux" -xf -

# instalador gráfico
mkdir -p "$PROFILE/airootfs/etc/calamares"
cp -rT "$REPO_DIR/iso/calamares" "$PROFILE/airootfs/etc/calamares"
# a lista de remoção vem do packages.live, não de uma cópia à mão
PACKAGES_CONF="$PROFILE/airootfs/etc/calamares/modules/packages.conf"
REMOCAO="$(bash "$REPO_DIR/iso/builder/gen-packages.sh" --remocao "$REPO_DIR")"
REMOCAO="$REMOCAO" awk '/@@PACOTES_LIVE@@/ { print ENVIRON["REMOCAO"]; next } { print }' "$PACKAGES_CONF" > "$PACKAGES_CONF.tmp"
mv "$PACKAGES_CONF.tmp" "$PACKAGES_CONF"
mkdir -p "$PROFILE/airootfs/usr/share/brummy"
cp -f "$REPO_DIR/boot/assets/logo.png" "$PROFILE/airootfs/usr/share/brummy/logo.png"
cp -f "$REPO_DIR/boot/assets/logo.png" "$PROFILE/airootfs/etc/calamares/branding/brummy/logo.png"
cp -f "$REPO_DIR/boot/assets/grub-background.png" \
      "$PROFILE/airootfs/etc/calamares/branding/brummy/welcome.png" 2>/dev/null || true

# Boot com a cara do Brummy no sistema instalado: tema Plymouth e fundo do
# GRUB dentro da imagem (o /boot é esvaziado pelo mkarchiso; o fundo vai para
# /usr/share e o brummy-pos-instalacao grub o põe no lugar).
PLY="$PROFILE/airootfs/usr/share/plymouth/themes/brummy"
mkdir -p "$PLY/assets" "$PROFILE/airootfs/etc/plymouth"
cp -f "$REPO_DIR/boot/plymouth/brummy.plymouth" "$REPO_DIR/boot/plymouth/brummy.script" "$PLY/"
for a in logo glow dot bar-bg bar-fill; do
  cp -f "$REPO_DIR/boot/assets/$a.png" "$PLY/assets/"
done
printf '[Daemon]\nTheme=brummy\n' > "$PROFILE/airootfs/etc/plymouth/plymouthd.conf"
cp -f "$REPO_DIR/boot/assets/grub-background.png" "$PROFILE/airootfs/usr/share/brummy/grub-background.png"

# serviços ligados no live
WANTS="$PROFILE/airootfs/etc/systemd/system/multi-user.target.wants"
mkdir -p "$WANTS"
ln -sf /usr/lib/systemd/system/greetd.service          "$WANTS/greetd.service"
ln -sf /usr/lib/systemd/system/NetworkManager.service  "$WANTS/NetworkManager.service"
ln -sf ../brummy-live-setup.service                    "$WANTS/brummy-live-setup.service"

echo "==> [7/7] mkarchiso (demora — 20 a 60 min na primeira vez)"
rm -rf "$WORK"; mkdir -p "$WORK" "$OUT"
mkarchiso -v -w "$WORK" -o "$OUT" "$PROFILE"

chmod -R a+rw "$OUT" 2>/dev/null || true
echo ""
echo "==> ISO gerada:"
ls -lh "$OUT"/*.iso
