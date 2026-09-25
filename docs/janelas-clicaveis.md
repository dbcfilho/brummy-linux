# Janelas clicáveis em cima do tiling (planejado, não implementado)

Objetivo: manter o auto-tiling como está — janela nova entra e se acomoda
sozinha — mas com botões de fechar, minimizar e maximizar no mouse, como em
qualquer sistema tradicional. É a promessa "híbrido" do Brummy levada às
janelas.

**Status: desenhado, não aplicado.** Nada disso está no `install.sh` ainda. A
ordem combinada é validar a base primeiro (o `./install.sh` completo rodando e
o visual aparecendo) e só então mexer aqui — plugin em cima de base não testada
mistura dois problemas.

## O que já funciona hoje, sem plugin nenhum

| Ação | Como |
|---|---|
| Redimensionar | puxar a borda direto, sem tecla (`resize_on_border = true`) |
| Mover | arrastar com `ALT` ou `SUPER` |
| Fechar | `SUPER+C`, ou `SUPER`+clique do meio |
| Flutuar/voltar a tilar | `SUPER+V` |
| Tela cheia | `SUPER+F` |

O que falta é só o **alvo visível pro mouse**: a barra com botões.

## A peça: hyprbars

Plugin oficial do hyprwm (`hyprland-plugins`). Põe uma barra de título com
botões em cada janela **sem** mexer no layout — o tiling continua igual. Os
botões podem ficar à esquerda, em bolinhas coloridas, no estilo macOS.

### Instalação

```bash
hyprpm update                                            # compila contra a sua versão
hyprpm add https://github.com/hyprwm/hyprland-plugins
hyprpm enable hyprbars
```

E no autostart do `hyprland.lua`, antes da waybar:

```lua
"hyprpm reload -n",
```

Precisa de `cmake`, `meson`, `cpio` e `base-devel` — todos já estão no
`packages/base.packages`. Depois de cada atualização do Hyprland o plugin
precisa ser recompilado; o `brummy update` já roda `hyprpm update` quando
encontra plugins instalados.

### Configuração (rascunho, a validar)

```lua
-- Plugin: se não estiver carregado, hl.plugin nem existe. pcall para uma
-- ausência nunca derrubar a sessão — mesma lição do hl.print.
pcall(function()
  hl.config({ plugin = { hyprbars = {
    bar_height            = 26,
    bar_color             = "rgba(1a1a24ee)",
    bar_blur              = true,
    bar_part_of_window    = true,
    bar_buttons_alignment = "left",     -- macOS: bolinhas à esquerda
    bar_title_enabled     = true,
    bar_text_align        = "center",
    bar_text_font         = "Inter",
    bar_text_size         = 11,
    bar_padding           = 10,
    bar_button_padding    = 8,
    on_double_click       = "hyprctl dispatch fullscreen 1",  -- maximizar no duplo clique
  }}})

  -- Ordem macOS: fechar, minimizar, maximizar.
  local btn = hl.plugin.hyprbars.add_button
  btn({ bg_color = 0xffff5f57, size = 11, icon = "", action = "hyprctl dispatch killactive" })
  btn({ bg_color = 0xfffebc2e, size = 11, icon = "",
        action = "hyprctl dispatch movetoworkspacesilent special:minimizado" })
  btn({ bg_color = 0xff28c840, size = 11, icon = "", action = "hyprctl dispatch fullscreen 1" })
end)
```

> ⚠️ A API Lua (`hl.plugin.hyprbars.add_button`) veio de documentação de
> terceiro, não do repo oficial. É a mesma classe de fonte que produziu o
> `hl.print` inexistente. **Validar com `hyprland --verify-config` na VM antes
> de confiar** — e o `pcall` existe justamente para o caso de estar errada.

## Minimizar: o que é possível de verdade

O Hyprland **não tem** minimizar. Não existe o conceito de janela minimizada no
compositor. O que dá para fazer é mandar a janela para um workspace especial
(uma gaveta) e ter como trazer de volta:

```
minimizar  → hyprctl dispatch movetoworkspacesilent special:minimizado
recuperar  → clicar na janela na taskbar da Waybar
```

Para a volta ser descobrível, a Waybar ganha uma taskbar tradicional:

```json
"wlr/taskbar": {
  "format": "{icon}",
  "icon-size": 18,
  "tooltip-format": "{title}",
  "on-click": "activate",
  "on-click-middle": "close",
  "ignore-list": ["wofi", "nwg-dock-hyprland"]
}
```

Entra em `modules-left`, no lugar de `hyprland/window` (o título da janela
ativa perde a graça quando existe a lista inteira).

**A validar:** se clicar numa janela que está na gaveta realmente a traz de
volta para o workspace atual, ou se apenas abre a gaveta. O `activate` do
protocolo foreign-toplevel depende de como o Hyprland o implementa.

## O custo honesto

- **Plugin é compilado contra a versão exata do Hyprland.** Toda atualização
  pede `hyprpm update`. Se a compilação falhar, o plugin não carrega naquele
  boot — a sessão sobe, só sem as barras.
- **Arch é rolling.** Isso vai acontecer. É o preço de ter barra de título num
  compositor que não tem decoração server-side.
- **Ocupa altura.** 26px por janela some rápido em tela pequena; em 1366x768
  (o T430) vale reavaliar a altura ou desligar por perfil.

## Ordem de implementação

1. `./install.sh` completo validado na VM, visual base aparecendo
2. `cmake`/`meson`/`cpio` conferidos em `packages/base.packages`
3. hyprbars via `hyprpm`, config acima, `hyprland --verify-config`
4. Se a API Lua estiver errada, cair para o formato hyprlang do plugin
   (`hyprbars-button = cor, tamanho, ícone, ação`) num arquivo separado
5. taskbar na Waybar e testar o ciclo minimizar → recuperar
6. Só então entrar no `install.sh` como padrão
