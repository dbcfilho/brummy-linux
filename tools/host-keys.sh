#!/usr/bin/env bash
# tools/host-keys.sh — libera os atalhos com SUPER no HOST (GNOME) para eles
# chegarem na VM, e devolve tudo como estava depois.
#
# O problema: o Brummy usa SUPER+C, SUPER+E, SUPER+L, SUPER+V e SUPER+1..9.
# O GNOME do seu Debian reserva exatamente esses. Mesmo com o QEMU capturando
# o teclado (Ctrl+Alt+G), num host Wayland o compositor fica com eles antes.
#
# Uso:
#   ./tools/host-keys.sh liberar     antes de testar na VM
#   ./tools/host-keys.sh restaurar   quando terminar
#   ./tools/host-keys.sh status      mostra o que está valendo agora
#
# Nada é perdido: os valores originais vão para ~/.cache/brummy/host-keys.bak
# e o 'restaurar' reaplica um por um.
set -uo pipefail

BAK_DIR="$HOME/.cache/brummy"
BAK="$BAK_DIR/host-keys.bak"

# schema | chave | valor neutro
CHAVES=(
  "org.gnome.mutter|overlay-key|''"
  "org.gnome.desktop.wm.keybindings|panel-main-menu|@as []"
  "org.gnome.desktop.wm.keybindings|panel-run-dialog|@as []"
  "org.gnome.desktop.wm.keybindings|show-desktop|@as []"
  "org.gnome.shell.keybindings|toggle-overview|@as []"
  "org.gnome.shell.keybindings|toggle-application-view|@as []"
  "org.gnome.shell.keybindings|toggle-message-tray|@as []"
  "org.gnome.shell.keybindings|focus-active-notification|@as []"
  "org.gnome.shell.keybindings|screenshot|@as []"
  "org.gnome.settings-daemon.plugins.media-keys|screensaver|@as []"
  "org.gnome.settings-daemon.plugins.media-keys|home|@as []"
  "org.gnome.settings-daemon.plugins.media-keys|control-center|@as []"
)
for i in 1 2 3 4 5 6 7 8 9; do
  CHAVES+=("org.gnome.shell.keybindings|switch-to-application-$i|@as []")
done

command -v gsettings &>/dev/null || { echo "gsettings não encontrado — este script é para hosts GNOME."; exit 1; }

existe() { gsettings writable "$1" "$2" &>/dev/null; }

case "${1:-status}" in
  liberar)
    mkdir -p "$BAK_DIR"
    if [[ -f "$BAK" ]]; then
      echo "Já existe um backup em $BAK — rode 'restaurar' antes de liberar de novo."
      exit 1
    fi
    : > "$BAK"
    n=0
    for entrada in "${CHAVES[@]}"; do
      IFS='|' read -r schema chave neutro <<< "$entrada"
      existe "$schema" "$chave" || continue
      atual="$(gsettings get "$schema" "$chave" 2>/dev/null)" || continue
      printf 'gsettings set %s %s %q\n' "$schema" "$chave" "$atual" >> "$BAK"
      gsettings set "$schema" "$chave" "$neutro" 2>/dev/null && n=$((n+1))
    done
    echo "$n atalhos do host liberados. Original guardado em $BAK"
    echo "Agora o SUPER chega na VM. Quando terminar: ./tools/host-keys.sh restaurar"
    ;;

  restaurar)
    [[ -f "$BAK" ]] || { echo "sem backup em $BAK — nada a restaurar"; exit 0; }
    bash "$BAK" && rm -f "$BAK"
    echo "atalhos do host restaurados"
    ;;

  status)
    if [[ -f "$BAK" ]]; then
      echo "LIBERADO (os atalhos do host estão desligados)"
      echo "  backup: $BAK  —  restaure com: ./tools/host-keys.sh restaurar"
    else
      echo "normal (os atalhos do host estão ativos; o SUPER fica no Debian)"
    fi
    echo ""
    echo "Alguns valores agora:"
    for entrada in "${CHAVES[@]:0:6}"; do
      IFS='|' read -r schema chave _ <<< "$entrada"
      existe "$schema" "$chave" && printf '  %-28s %s\n' "$chave" "$(gsettings get "$schema" "$chave")"
    done
    ;;

  *)
    awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' "${BASH_SOURCE[0]}"
    ;;
esac
