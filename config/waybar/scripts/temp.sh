#!/usr/bin/env bash
# temp.sh — temperatura da CPU sem caminho fixo.
# O hwmon0 muda de máquina para máquina (e some em VM): procura um sensor
# de CPU de verdade e, se não achar, imprime vazio para a Waybar esconder.
set -uo pipefail

pick() {
  # 1) hwmon com nome conhecido de CPU
  for h in /sys/class/hwmon/hwmon*; do
    n=$(cat "$h/name" 2>/dev/null || true)
    case "$n" in
      coretemp|k10temp|zenpower|cpu_thermal|acpitz)
        for f in "$h"/temp1_input "$h"/temp2_input; do
          [[ -r "$f" ]] && { cat "$f"; return 0; }
        done ;;
    esac
  done
  # 2) thermal_zone tipo x86_pkg_temp
  for z in /sys/class/thermal/thermal_zone*; do
    t=$(cat "$z/type" 2>/dev/null || true)
    case "$t" in
      x86_pkg_temp|cpu-thermal|CPU*|acpitz)
        [[ -r "$z/temp" ]] && { cat "$z/temp"; return 0; } ;;
    esac
  done
  return 1
}

raw=$(pick) || { printf '{"text":""}\n'; exit 0; }
c=$(awk -v v="$raw" 'BEGIN{printf "%.0f", (v>1000 ? v/1000 : v)}')
cls=low; (( c >= 85 )) && cls=critical || (( c >= 70 )) && cls=high
printf '{"text":" %s°C","tooltip":"CPU %s°C","class":"%s"}\n' "$c" "$c" "$cls"
