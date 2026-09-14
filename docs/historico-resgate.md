# Brummy Linux — Contexto resgatado (sessão antiga com erro)
# Sessão origem: ses_f6e27170bffeiBCJDetOVnYFp9 — "Criar sistema operacional próprio"
# Motivo do resgate: histórico continha `reasoningEncryptedContent` inválido para o Caller atual (Console / muse-spark-1.3-contributor-free). Continuar aquela sessão sempre falha no step 0.
# Use este arquivo para continuar em SESSÃO NOVA, sem carregar os blocos criptografados.

## O que é
Brummy Linux v0.1 em `brummy-linux/` — ideia tipo Omarchy do DDH: não é kernel do zero, é Arch + Hyprland com cara própria. Hobby, para uso real.
Conceito: mistura minimalista (tiling, teclado, Catppuccin Mocha) + tradicional (mouse, taskbar clicável, dock).

## Estado atual do scaffold
- `install.sh` idempotente para Arch fresco, instala tudo + linka `config/` para `~/.config/` com backup, instala `brummy` em `~/.local/bin`
- `bin/brummy`: `help / update / apps / doctor / theme`
- `config/hypr, waybar, kitty, wofi, fish` já no híbrido
- `README.md` com filosofia

## Híbrido mouse + tiling
- `config/hypr/hyprland.conf`: resize_on_border, SUPER+arrastar e ALT+arrastar, SUPER+scroll troca workspace, SUPER+clique-meio fecha, SUPER+SHIFT+botão-dir flutua, foco segue mouse, cursor 28px, tap-to-click, swipe 3 dedos
- Waybar virou taskbar tradicional: botão logo abre menu, workspaces clicáveis + scroll, título no meio, scroll no volume, botão power abre wlogout
- Extras: `wlogout, hyprshot, cliphist, nwg-look`

## Estética macOS
- Waybar topbar flutuante com margem, cantos 14px, vidro fosco rgba(20,20,28,0.55) + blur
- Dock embaixo `nwg-dock-hyprland` centralizada, auto-hide, ícones 48px
- Spotlight: SUPER+ESPAÇO abre wofi centralizado 620px, cantos 20px, seleção #0a84ff
- Janelas: rounding 16px, sombra, blur 3 passes, dim_inactive
- Wallpaper: `wallpaper_2560x1440_v2.jpg` -> `themes/macos/wallpaper.jpg` e `~/Pictures/brummy-wallpaper.jpg` via hyprpaper

## Bundle omakase (última versão pedida pelo usuário)
- Web: `helium-browser-bin` (AUR, default SUPER+B) + `firefox` (chromium removido)
- Code: `vscodium-bin` (não vscode) + nvim + docker/lazydocker/lazygit/gh/mise/tmux/fzf/rg/fd/bat/eza/zoxide
- Office: `libreoffice-fresh` + `onlyoffice-desktopeditors` + gnome-text-editor + evince + gnome-calculator + obsidian
- Chat: removido tudo (sem signal/telegram)
- Mídia: `obs-studio` (usuário escreveu "obstudio", considerar obs-studio) + mpv + pinta + spotify-launcher (kdenlive removido)
- AI: `opencode-bin + claude-code + claude-desktop`
- Extras: `discord`, `docker`, `localsend`, `udiskie`, `blueman`, `satty/hyprshot`, `wlogout`, `nwg-dock`
- `packages/base.packages` + `packages/aur.packages`, `brummy apps / doctor`, `brummy-remove-preinstalls`

## GPU + Gaming
- GPU: AMD Radeon RX 6600 XT — driver open-source: mesa+lib32, vulkan-radeon+lib32, vulkan-icd-loader, libva-mesa-driver, mesa-vdpau, xf86-video-amdgpu, vulkan-tools, amd-ucode
- `install.sh` habilita [multilib] sozinho
- Hyprland: AMD_VULKAN_ICD=RADV + radeonsi, regras fullscreen sem sombra/blur, immediate
- Gaming: steam + lutris + bottles + wine/winetricks + protonplus + gamemode/lib32 + gamescope + mangohud/lib32
- Fluxo: ProtonPlus -> Proton-GE latest -> Steam Compatibilidade -> gamemoderun %command%

## Últimos pedidos em aberto (não concluídos na sessão antiga)
1. KVM para virtualização de máquinas
2. btop
3. Extensões: "claude usage" e "astra monitor" — verificar compatibilidade (uma funciona, outra não — checagem iniciada mas não aplicada)
4. Definir Helium como default (`xdg-settings`) e VSCodium como EDITOR alternativo — perguntado, sem confirmação

## Como continuar
Cole no início da nova sessão:
"Estou continuando o Brummy Linux. Contexto completo em brummy-linux/docs/historico-resgate.md. Próximo passo: KVM + btop + checar extensões claude-usage / astra-monitor."
