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

head_ "hyprbars: o bloco do plugin, com e sem o plugin carregado"
# O --verify-config não carrega plugins (hl.plugin.load só registra o
# caminho), então o bloco do hyprbars nunca é validado por ele. Aqui ele
# roda com um `hl` de mentira que confere o que o main.cpp do plugin exige.
LUA="$(command -v lua5.4 || command -v lua || true)"
if [[ -n "$LUA" ]]; then
  for modo in com sem; do
    out="$(HOME="$(mktemp -d)" MODO="$modo" "$LUA" - <<'LUAEOF' 2>&1
local modo = os.getenv("MODO")
local botoes, plugcfg, regras = {}, nil, {}
local stub
stub = setmetatable({}, { __index = function() return stub end, __call = function() return stub end })
hl = setmetatable({}, { __index = function() return stub end })
hl.plugin = { load = function() end }
if modo == "com" then
  hl.plugin.hyprbars = { add_button = function(b) botoes[#botoes + 1] = b end }
end
hl.config = function(t) if t.plugin then plugcfg = t.plugin end end
hl.window_rule = function(t) regras[#regras + 1] = t end
assert(loadfile("config/hypr/hyprland.lua"))()

local erros = {}
local function falha(m) erros[#erros + 1] = m end
local function cor(v) return math.type(v) == "integer" or (type(v) == "string" and v:match("^rgba?%(%x+%)$")) end
local function acao(v) return type(v) == "string" and v:match("^hyprctl dispatch '.*hl%.dsp%.") end
-- opções registradas pelo main.cpp do hyprbars (addConfigValueV2)
local conhecidas = { enabled=1, bar_color=1, bar_height=1, bar_blur=1, bar_title_enabled=1,
  bar_text_size=1, bar_text_weight=1, bar_text_font=1, bar_text_align=1, bar_buttons_alignment=1,
  bar_part_of_window=1, bar_precedence_over_border=1, bar_padding=1, bar_button_padding=1,
  icon_on_hover=1, buttons_on_hover=1, inactive_button_color=1, on_double_click=1, col=1 }

if modo == "com" then
  if #botoes == 0 then falha("nenhum add_button chamado") end
  for i, b in ipairs(botoes) do
    if not cor(b.bg_color) then falha("botão " .. i .. ": bg_color inválido") end
    if not cor(b.fg_color) then falha("botão " .. i .. ": fg_color inválido (é obrigatório)") end
    if math.type(b.size) ~= "integer" then falha("botão " .. i .. ": size precisa ser inteiro") end
    if type(b.icon) ~= "string" then falha("botão " .. i .. ": icon precisa ser string") end
    if not acao(b.action) then falha("botão " .. i .. ": action não é hyprctl dispatch 'hl.dsp...'") end
  end
  local hb = plugcfg and plugcfg.hyprbars
  if not hb then falha("hl.config({ plugin = { hyprbars = ... } }) não foi chamado")
  else
    for k in pairs(hb) do if not conhecidas[k] then falha("opção desconhecida do hyprbars: " .. k) end end
    if hb.on_double_click and not acao(hb.on_double_click) then falha("on_double_click com sintaxe antiga") end
  end
else
  if plugcfg then falha("config do hyprbars aplicada sem o plugin carregado") end
  for _, r in ipairs(regras) do
    for k in pairs(r) do
      if type(k) == "string" and k:match("^hyprbars:") then falha("regra " .. k .. " fora do if (erro sem o plugin)") end
    end
  end
end
if #erros > 0 then print(table.concat(erros, "\n")); os.exit(1) end
LUAEOF
)" && ok "hyprland.lua $modo o plugin" || { bad "hyprland.lua $modo o plugin"; echo "$out" | sed 's/^/        /'; }
  done
else
  echo "  (pulado: instale lua5.4 para checar)"
fi

head_ "hyprctl dispatch com sintaxe Lua"
# Config em Lua: `hyprctl dispatch X` vira hl.dispatch(X). A sintaxe antiga
# (hyprctl dispatch workspace e+1) falha calada — foi assim que o scroll dos
# workspaces na Waybar quebrou.
antigos="$(grep -rnE "hyprctl dispatch +[^'\"\$ ]" config bin 2>/dev/null | grep -v '/legacy/' | grep -vE '^[^:]+:[0-9]+:[[:space:]]*(#|--)' || true)"
if [[ -z "$antigos" ]]; then
  ok "nenhum hyprctl dispatch no formato antigo"
else
  bad "hyprctl dispatch no formato antigo:"; echo "$antigos" | sed 's/^/        /'
fi

head_ "brummy-minimizados com hyprctl de mentira"
STUB="$(mktemp -d)"
cat > "$STUB/hyprctl" <<'SH'
#!/bin/sh
case "$1 $2" in
  "clients -j") echo '[{"address":"0xaa","class":"kitty","title":"fish","workspace":{"id":-98,"name":"special:minimizado"}},{"address":"0xbb","class":"firefox","title":"x","workspace":{"id":1,"name":"1"}}]' ;;
  "activeworkspace -j") echo '{"id":3}' ;;
  dispatch*) echo "$2" > "$(dirname "$0")/despachado" ;;
esac
SH
chmod +x "$STUB/hyprctl"
if command -v jq &>/dev/null; then
  st="$(PATH="$STUB:$PATH" ./bin/brummy-minimizados status)"
  [[ "$(jq -r .text <<<"$st")" == "󰖰 1" ]] && ok "status conta 1 minimizada" || bad "status: $st"
  PATH="$STUB:$PATH" ./bin/brummy-minimizados restaurar
  [[ "$(cat "$STUB/despachado" 2>/dev/null)" == 'hl.dsp.window.move({ workspace = 3, window = "address:0xaa" })' ]] \
    && ok "restaurar move para o workspace ativo" || bad "restaurar despachou: $(cat "$STUB/despachado" 2>/dev/null)"
else
  echo "  (pulado: instale jq)"
fi
rm -rf "$STUB"

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
