#!/usr/bin/env bash
# gpu.sh — módulo Waybar de GPU, agnóstico de máquina.
# AMD (amdgpu sysfs) > NVIDIA (nvidia-smi) > Intel/virtual (sem contador).
# Sem GPU legível: imprime texto vazio e a Waybar esconde o módulo sozinha,
# em vez de deixar um buraco na barra (era o que acontecia dentro da VM).
set -uo pipefail

json() { printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$1" "$2" "$3"; }
empty() { printf '{"text":""}\n'; exit 0; }

classify() { # $1 = uso %
  local u="$1"
  if   (( u >= 90 )); then echo critical
  elif (( u >= 75 )); then echo high
  elif (( u >= 50 )); then echo mid
  else echo low; fi
}

# --- AMD: gpu_busy_percent no sysfs ---
BUSY=$(ls -d /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1)
if [[ -n "${BUSY:-}" ]]; then
  DEV=$(dirname "$BUSY")
  usage=$(cat "$BUSY" 2>/dev/null || echo 0)
  name=$(cat "$DEV/../device/product_name" 2>/dev/null || echo "GPU AMD")
  temp="--"
  for f in "$DEV"/hwmon/hwmon*/temp1_input; do
    [[ -f "$f" ]] && { temp=$(awk '{printf "%.0f", $1/1000}' "$f"); break; }
  done
  vram=""
  if [[ -f "$DEV/mem_info_vram_used" && -f "$DEV/mem_info_vram_total" ]]; then
    used=$(awk '{printf "%.1f", $1/1073741824}' "$DEV/mem_info_vram_used")
    tot=$(awk  '{printf "%.0f", $1/1073741824}' "$DEV/mem_info_vram_total")
    vram=" | VRAM ${used}/${tot}G"
  fi
  json "󰢮 ${usage}%" "AMD — ${usage}% | ${temp}°C${vram}" "$(classify "$usage")"
  exit 0
fi

# --- NVIDIA: nvidia-smi ---
if command -v nvidia-smi &>/dev/null; then
  read -r usage temp mem_u mem_t < <(nvidia-smi \
    --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total \
    --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' ' | tr ',' ' ')
  [[ -z "${usage:-}" ]] && empty
  json "󰢮 ${usage}%" "NVIDIA — ${usage}% | ${temp}°C | ${mem_u}/${mem_t} MiB" "$(classify "$usage")"
  exit 0
fi

# --- Intel / virtio / sem contador: some da barra ---
empty
