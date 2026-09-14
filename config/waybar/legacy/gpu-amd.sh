#!/usr/bin/env bash
# gpu-amd.sh — módulo Waybar p/ RX 6600 XT (substituto do Astra Monitor p/ GPU)
# Lê gpu_busy_percent + temp + vram do sysfs amdgpu. Saída JSON p/ Waybar.
set -uo pipefail
CARD=$(ls -d /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1)
if [[ -z "${CARD:-}" ]]; then
  echo '{"text":"󰢮 --","tooltip":"GPU AMD não detectada","class":"error"}'
  exit 0
fi
DEV=$(dirname "$CARD")
usage=$(cat "$DEV/gpu_busy_percent" 2>/dev/null || echo 0)
temp="--"
for f in "$DEV/hwmon/hwmon"*"/temp1_input" /sys/class/hwmon/hwmon*/temp1_input; do
  [[ -f "$f" ]] && { temp=$(awk '{printf "%.0f", $1/1000}' "$f"); break; }
done
vram_used="--"; vram_total="--"
[[ -f "$DEV/mem_info_vram_used" && -f "$DEV/mem_info_vram_total" ]] && {
  vram_used=$(awk '{printf "%.1f", $1/1073741824}' "$DEV/mem_info_vram_used")
  vram_total=$(awk '{printf "%.0f", $1/1073741824}' "$DEV/mem_info_vram_total")
}
cls="low"; (( usage >= 90 )) && cls="critical" || (( usage >= 75 )) && cls="high" || (( usage >= 50 )) && cls="mid"
echo "{\"text\":\"󰢮 ${usage}%\",\"tooltip\":\"RX 6600 XT — ${usage}% | ${temp}°C | VRAM ${vram_used}/${vram_total}G\",\"class\":\"$cls\"}"
