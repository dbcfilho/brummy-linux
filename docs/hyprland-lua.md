# Brummy — config do Hyprland em Lua

## Por que mudou

O Hyprland aposentou o hyprlang (o formato `.conf`). A 0.55 introduziu a config
em Lua e marcou o `.conf` como deprecado; a **0.57 remove o suporte**. Na 0.56.2,
que é o que o Brummy roda hoje, o `.conf` ainda funciona mas a sessão abre com:

```
You are using the .conf config format, support for which will be removed in Hyprland 0.57.
```

Como o primeiro boot em VM também acusou 19 erros de opção inexistente, a
migração e a correção viraram a mesma tarefa.

## O que estava quebrado no `.conf` antigo

| Erro | Causa |
|---|---|
| `general:snap { enabled` não existe | chaves aninhadas **em uma linha só** não são válidas: o parser lê `snap { enabled` como nome da opção. Mesmo caso em `touchpad { ... }` e `gestures { ... }` |
| `decoration:drop_shadow` não existe | virou a subcategoria `shadow { enabled = true }` |
| `decoration:shadow_range` | virou `shadow { range }` |
| `decoration:shadow_render_power` | virou `shadow { render_power }` |
| `decoration:col.shadow` | virou `shadow { color }` |
| `gestures:workspace_swipe` | virou `hl.gesture({ fingers, direction, action })` |
| `windowrulev2 = ...` | virou `hl.window_rule({ match = {...}, ... })` |

## Estrutura nova

```
config/hypr/
  hyprland.lua              # config principal (única que o Hyprland lê)
  hyprpaper.conf            # só o daemon; a imagem vem do brummy-wallpaper-apply
  modules/
    monitors-desktop.lua    # perfis de monitor
    monitors-thinkpad.lua
    monitors-general.lua
    gpu-amd.lua             # variáveis de GPU
    gpu-intel.lua
    trackpoint.lua
    profile-monitors.lua -> link criado pelo install.sh
    profile-gpu.lua      -> link criado pelo install.sh
  legacy/                   # a config antiga, só para consulta
```

O `hyprland.lua` carrega os módulos com `require("modules.<nome>")` e, se o
`package.path` não cobrir `~/.config/hypr`, cai para `loadfile` no caminho
absoluto. Módulo faltando nunca derruba a sessão — só loga.

## Equivalências rápidas

| hyprlang (antigo) | Lua (agora) |
|---|---|
| `exec-once = waybar` | `hl.on("hyprland.start", function() hl.exec_cmd("waybar") end)` |
| `env = XCURSOR_SIZE,28` | `hl.env("XCURSOR_SIZE", "28")` |
| `general { gaps_in = 8 }` | `hl.config({ general = { gaps_in = 8 } })` |
| `monitor = DP-1, 1920x1080@60, 0x0, 1` | `hl.monitor({ output = "DP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })` |
| `bind = SUPER, Q, exec, kitty` | `hl.bind("SUPER + Q", hl.dsp.exec_cmd("kitty"))` |
| `bindm = SUPER, mouse:272, movewindow` | `hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })` |
| `windowrulev2 = float, class:^(x)$` | `hl.window_rule({ name = "x", match = { class = "^(x)$" }, float = true })` |
| `layerrule = blur, waybar` | `hl.layer_rule({ name = "blur-waybar", match = { namespace = "^waybar$" }, blur = true })` |
| `device { name = ... }` | `hl.device({ name = "...", ... })` |

## Como validar

```bash
hyprland --verify-config     # checa a config sem subir a sessão
hyprctl reload               # recarrega na sessão viva
brummy doctor                # confere perfil, versão, greetd e tema
```

Um parser Lua qualquer (`luac -p hyprland.lua`) pega erro de sintaxe, mas só o
`--verify-config` pega nome de opção errado.

## Como a sessão sobe

Desde a 0.53 o jeito suportado é o wrapper `start-hyprland` (crash recovery e
safe mode). O `config/greetd/config.toml` do Brummy já usa:

```toml
command = "tuigreet --cmd start-hyprland --remember --remember-session --asterisks --time --greeting 'Brummy Linux'"
```

Chamar o binário `Hyprland` direto ainda funciona, mas a sessão abre avisando
`Hyprland was started without start-hyprland`.
