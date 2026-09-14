# Extensões: o que funciona no Brummy (Hyprland)

## Astra Monitor — não funciona no Hyprland
Astra Monitor é extensão do **GNOME Shell**. O Brummy roda **Hyprland** (compositor Wayland próprio, sem GNOME Shell), então ela não carrega.

Cobertura nativa já no bundle (mesma ideia, sem GNOME):
- Waybar: `cpu` + `memory` (clique abre `btop`), `custom/gpu` (`gpu-amd.sh` → clique abre `radeontop`), `temperature`
- GUI: `mission-center` (estilo gerenciador de tarefas), `btop`, `radeontop`, `nvtop`
- Clique no monitor da bar abre `btop`/`radeontop` — ver `config/waybar/config`

Se quiser Astra mesmo, teria que trocar a sessão para GNOME — fora do escopo do Brummy v0.1.

## Claude Usage — usar claudebar na Waybar
Não precisa de extensão GNOME. O Brummy já vem com:
- `claudebar-git` (AUR) + fallback via curl no `install.sh`
- Módulo `custom/claude` na Waybar: `exec: claudebar`, atualiza a cada 300s, clique abre `https://claude.ai/settings/usage`
- Checagem: `brummy doctor` mostra `ok claudebar`

Requisito: estar logado no Claude (o `claudebar` lê o uso da conta). Se `claudebar` falhar, rode `claudebar` no terminal para ver o erro de auth.

## ChromaLeon — extensão GNOME Shell, não roda no Hyprland

O ChromaLeon (accent colors dinâmicas pelo wallpaper, p/ GNOME Shell + apps Adwaita + ícones)
é extensão do **GNOME Shell** — igual o Astra Monitor, não carrega no Hyprland.

O que o Brummy faz em vez disso (mesmo efeito no Nautilus):
- `install.sh` fixa `accent-color blue` + tema `WhiteSur-Dark` via gsettings — todo app
  libadwaita (Nautilus, Boxes, Text Editor) já abre temado, sem extensão
- `whitesur-gtk-theme` + `whitesur-icon-theme` (AUR) + `nwg-look` pra trocar sem decorar
- Troque o accent depois com: `gsettings set org.gnome.desktop.interface accent-color 'teal'`
  (opções: blue, teal, green, yellow, orange, red, pink, purple, slate)

