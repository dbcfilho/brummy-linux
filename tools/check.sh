#!/usr/bin/env bash
# tools/check.sh — o que dá para verificar sem instalar nada.
#
# Existe porque dois bugs bobos chegaram na VM do jeito mais caro possível:
# uma variável usada e nunca definida (REPO_DIR no vm.sh) e uma função de API
# inexistente (hl.print). `bash -n` não pega nenhum dos dois — só rodar pega.
#
# Uso: ./tools/check.sh
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

falhas=0
ok()   { printf '  \033[32mok\033[0m    %s\n' "$*"; }
bad()  { printf '  \033[31mFALHA\033[0m %s\n' "$*"; falhas=$((falhas+1)); }
head_() { printf '\n== %s\n' "$*"; }

head_ "sintaxe dos scripts shell"
while IFS= read -r f; do
  bash -n "$f" 2>/dev/null && ok "$f" || bad "$f"
done < <(find bin tools iso install.sh -type f \( -name '*.sh' -o ! -name '*.*' \) 2>/dev/null | sort)

head_ "shellcheck (avisos e erros)"
# Pega o que bash -n não pega: variável sem aspas, cd sem checagem, ls | grep...
if command -v shellcheck &>/dev/null; then
  while IFS= read -r f; do
    out="$(LC_ALL=C.UTF-8 shellcheck -S warning -f gcc "$f" 2>&1)" && ok "$f" || { bad "$f"; echo "$out" | sed 's/^/        /'; }
  done < <({ find bin tools iso install.sh -type f \( -name '*.sh' -o ! -name '*.*' \); find config -name '*.sh'; } 2>/dev/null | sort)
else
  echo "  (pulado: instale shellcheck — sudo apt install shellcheck)"
fi

head_ "JSON / JSONC"
python3 - <<'PY' && ok "config/waybar/config" || bad "config/waybar/config"
import json; json.load(open('config/waybar/config'))
PY
python3 - <<'PY' && ok "config/fastfetch/config.jsonc" || bad "config/fastfetch/config.jsonc"
import json, re
s = open('config/fastfetch/config.jsonc', encoding='utf-8').read()
json.loads(re.sub(r'^\s*//.*$', '', s, flags=re.M))
PY

head_ "sintaxe Lua"
if command -v luac5.4 &>/dev/null || command -v luac &>/dev/null; then
  LUAC="$(command -v luac5.4 || command -v luac)"
  while IFS= read -r f; do
    "$LUAC" -p "$f" 2>/dev/null && ok "$f" || bad "$f"
  done < <(find config/hypr -name '*.lua' | sort)
else
  echo "  (pulado: instale lua5.4 para checar — sudo apt install lua5.4)"
fi

head_ "tools/vm.sh: todo subcomando roda sem variável não associada"
# set -u só estoura em tempo de execução, então cada caminho precisa ser
# percorrido de verdade. Stubs no PATH para nada de pesado acontecer.
STUB="$(mktemp -d)"
for c in qemu-system-x86_64 qemu-img ssh tar; do
  printf '#!/bin/sh\nexit 0\n' > "$STUB/$c"; chmod +x "$STUB/$c"
done
for sub in "" help deps achar criar rodar "iso /tmp/x.iso" "overlay /tmp/x" enviar ssh; do
  out="$(PATH="$STUB:$PATH" ./tools/vm.sh $sub 2>&1)"
  if grep -qiE 'unbound variable|variável não associada' <<<"$out"; then
    bad "vm.sh ${sub:-<sem argumento>}"; echo "$out" | tail -2 | sed 's/^/        /'
  else
    ok "vm.sh ${sub:-<sem argumento>}"
  fi
done
rm -rf "$STUB"

head_ "brummy: subcomandos que não mexem no sistema"
for sub in help apps; do
  ./bin/brummy "$sub" &>/dev/null && ok "brummy $sub" || bad "brummy $sub"
done

echo ""
if (( falhas == 0 )); then
  echo "Tudo passou. (Isto NÃO substitui 'hyprland --verify-config' na VM:"
  echo "nome de opção errado do Hyprland só a versão real detecta.)"
else
  echo "$falhas falha(s)."
  exit 1
fi
