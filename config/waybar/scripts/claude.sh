#!/usr/bin/env bash
# claude.sh — uso do Claude na barra, só se o claudebar existir.
# Sem ele instalado a Waybar ficava logando erro e deixando espaço morto.
set -uo pipefail
if command -v claudebar &>/dev/null; then
  claudebar 2>/dev/null || printf '{"text":""}\n'
else
  printf '{"text":""}\n'
fi
