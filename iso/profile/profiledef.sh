#!/usr/bin/env bash
# shellcheck disable=SC2034
# Brummy Linux — perfil archiso.
# Referência: /usr/share/archiso/configs/releng/profiledef.sh

iso_name="brummy"
iso_label="BRUMMY_$(date +%Y%m)"
iso_publisher="Brummy Linux <https://github.com/dbcfilho/brummy-linux>"
iso_application="Brummy Linux Live"
iso_version="$(date +%Y.%m.%d)"
install_dir="brummy"          # vira /run/archiso/bootmnt/brummy — o unpackfs do
                              # Calamares aponta para cá; se mudar, mude lá também
buildmodes=('iso')
bootmodes=(
  'bios.syslinux.mbr'
  'bios.syslinux.eltorito'
  'uefi-x64.grub.esp'
  'uefi-x64.grub.eltorito'
)
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '19' '-b' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')

file_permissions=(
  ["/etc/gshadow"]="0:0:0400"
  ["/etc/shadow"]="0:0:0400"
  ["/root"]="0:0:750"
  ["/usr/local/bin/brummy-live-setup"]="0:0:755"
  ["/usr/local/bin/brummy-instalar"]="0:0:755"
  ["/usr/local/bin/brummy-pos-instalacao"]="0:0:755"
)
