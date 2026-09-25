# Janelas clicáveis em cima do tiling

Objetivo: manter o auto-tiling como está — janela nova entra e se acomoda
sozinha — mas com botões de fechar, minimizar e maximizar no mouse, como em
qualquer sistema tradicional. É a promessa "híbrido" do Brummy levada às
janelas.

**Status (v1.3): implementado, opcional, falta ver na VM.** A config passa no
`tools/check.sh` e no `--verify-config` do CI; o que nenhum dos dois vê é o
plugin desenhando de verdade. Liga com:

```bash
brummy bars on       # dentro da sessão Hyprland, num terminal
brummy bars off      # desliga (o plugin continua compilado)
brummy bars status
```

## O que funciona sem plugin nenhum

| Ação | Como |
|---|---|
| Redimensionar | puxar a borda direto, sem tecla (`resize_on_border = true`) |
| Mover | arrastar com `ALT` ou `SUPER` |
| Fechar | `SUPER+C`, ou `SUPER`+clique do meio |
| Minimizar | `SUPER+M` |
| Restaurar | `SUPER+SHIFT+M`, ou clique no `󰖰 N` da Waybar |
| Flutuar/voltar a tilar | `SUPER+V` |
| Tela cheia | `SUPER+F` |

O plugin acrescenta o **alvo visível pro mouse**: a barra com os botões.

## A peça: hyprbars

Plugin oficial do hyprwm (`hyprland-plugins`). Põe uma barra de título em
cada janela **sem** mexer no layout. No Brummy: bolinhas à esquerda na ordem
do macOS (fechar, minimizar, maximizar), símbolo só com o mouse em cima,
duplo clique na barra maximiza.

### Por que `brummy bars on` e não o `install.sh`

O `hyprpm add` pergunta a versão do Hyprland **pelo socket da sessão** — fora
dela ele falha. Então a ativação é um comando para rodar de dentro da sessão.
O `brummy bars on` faz, em ordem: `hyprpm update` (headers da versão
instalada, pede sudo), `hyprpm add` do repo oficial (compila), `hyprpm enable
hyprbars` e `hyprpm reload -n`. Pré-requisitos (`cmake`, `meson`, `cpio`,
`base-devel`) já estão no `packages/base.packages`.

No login, o autostart roda `hyprpm reload -n`: carrega o que estiver
habilitado e, se o plugin não subir, avisa na tela em vez de sumir calado.

### De onde veio a config

Do código-fonte, não de documentação de terceiro — a lição do `hl.print`.
`hyprbars/main.cpp` do `hyprland-plugins`, conferido em setembro de 2026:

- `hl.plugin.hyprbars.add_button` existe e recebe `{ bg_color, fg_color,
  size, icon, action }`. **`fg_color` é obrigatório** (o rascunho antigo não
  tinha, e todo botão teria dado erro). Cores são string `rgb(...)`.
- O `hyprpm.toml` tem pin para o Hyprland 0.56.2 (`efb5099`), a versão do Arch
  e do CI hoje.
- Botões com `bar_buttons_alignment = "left"`: o primeiro adicionado fica na
  ponta. Clicar na barra foca a janela antes de rodar a ação, então as ações
  agem sobre a janela certa.
- Regras de janela do plugin (`hyprbars:no_bar`) só existem com ele carregado.
  Fora do `if`, o Hyprland acusa "unknown field".

### A pegadinha do `hyprctl dispatch`

Com config em Lua, `hyprctl dispatch X` vira `hl.dispatch(X)` (está em
`src/debug/HyprCtl.cpp`). A sintaxe antiga — `hyprctl dispatch killactive` —
**falha calada**. Por isso as ações dos botões são:

```lua
"hyprctl dispatch 'hl.dsp.window.close()'"
"hyprctl dispatch 'hl.dsp.window.move({ workspace = \"special:minimizado\", follow = false })'"
"hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = \"maximized\", action = \"toggle\" })'"
```

Isso já tinha quebrado uma coisa sem ninguém ver: o scroll nos workspaces da
Waybar usava `hyprctl dispatch workspace e+1`. Corrigido, e o `tools/check.sh`
agora reprova qualquer `hyprctl dispatch` no formato antigo em `config/` e
`bin/`.

### Como é testado

O `--verify-config` **não carrega plugins** (`hl.plugin.load` só registra o
caminho, o carregamento vem depois), então ele pula o bloco do hyprbars. Para
cobrir isso, o `tools/check.sh` roda o `hyprland.lua` duas vezes com um `hl`
de mentira:

- **com o plugin:** cada `add_button` precisa ter os campos e tipos que o
  `main.cpp` exige, as ações precisam ser `hyprctl dispatch 'hl.dsp...'`, e
  toda opção em `plugin.hyprbars` precisa existir no plugin;
- **sem o plugin:** nada do hyprbars pode vazar para fora do `if`.

## Minimizar

O Hyprland **não tem** minimizar. O botão amarelo e o `SUPER+M` mandam a
janela para a gaveta `special:minimizado`, sem seguir. A volta é o
`bin/brummy-minimizados`:

| | |
|---|---|
| `status` | JSON para a Waybar: `󰖰 N` com os títulos no tooltip, some quando vazio |
| `restaurar` | traz de volta para o workspace atual; com mais de uma, escolhe no wofi |
| `lista` | o que está na gaveta |

Ficou de fora a `wlr/taskbar` do plano original: não havia garantia de que o
`activate` dela tira a janela de um workspace especial. O módulo próprio move
a janela por endereço, que é determinístico.

## O custo honesto

- **Plugin é compilado contra a versão exata do Hyprland.** O `brummy update`
  roda `hyprpm update` depois do pacman; se ainda assim a barra sumir, `brummy
  bars on` refaz. A sessão sempre sobe, só sem as barras.
- **Arch é rolling.** Vai acontecer. É o preço de ter barra de título num
  compositor sem decoração server-side.
- **Ocupa altura.** 26px por janela; em 1366x768 (o T430) vale reavaliar.

## A validar na VM

1. `brummy bars on` compila e as bolinhas aparecem à esquerda
2. Os três botões: fechar, minimizar (some e aparece `󰖰 1` na Waybar), maximizar
3. Duplo clique na barra maximiza e volta
4. Clique no `󰖰` restaura; com duas minimizadas, o wofi pergunta qual
5. Scroll em cima dos workspaces da Waybar troca de workspace
6. wofi e wlogout sem barra
