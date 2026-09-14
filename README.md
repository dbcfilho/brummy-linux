# Brummy Linux v1

Camada opinionada em cima de **Arch Linux + Hyprland**, inspirada no Omarchy do DHH,
mas com visão própria: **híbrido minimalista + tradicional**.

Filosofia:
- Rápido e teclado-driven como Hyprland (minimalista)
- Mas descobrível e clicável como KDE/GNOME (tradicional): bar com tray, launcher com ícones, file manager GUI, `brummy` helper com menu
- Tudo versionado aqui. Instalação idempotente via `./install.sh`

## Stack v1

- Base: Arch Linux (rolling) — 180 pacotes (ver `packages/`)
- WM: Hyprland híbrido macOS (tiling + mouse, dock, topbar, Spotlight) — config em **Lua** (0.55+)
- Bar: Waybar (cpu/mem/gpu + claudebar + tray)
- Files: **nautilus** (padrão, SUPER+E) + thunar de fallback
- Browser: helium (padrão) + firefox | Editor: vscodium + neovim
- Bundle: dev (Java/Node/Python/Postgres/k8s), gaming RX 6600 XT, KVM + Boxes
- Boot: logo no GRUB + splash Plymouth com luz pulsante
- Tema: WhiteSur-Dark + accent azul (estilo ChromaLeon, sem GNOME Shell)

## Perfis (`./install.sh --profile ...`, auto por padrão)

| Perfil | Máquina |
|---|---|
| `desktop` | Xeon + RX 6600 XT, dual 1080p |
| `thinkpad` | T430 / laptop (Intel + TLP + TrackPoint) |
| `general` | qualquer outro PC |

Flags: `--no-dev`, `--with-android`, `--no-boot`, `--boot-only`. Detalhes em `docs/`.

## Uso

O Brummy é pós-instalação: instale um Arch base (**`archinstall`** na ISO oficial
resolve sem terminal, ou EndeavourOS com Calamares gráfico) e rode **um comando**:

```bash
git clone https://github.com/dbcfilho/brummy-linux.git
cd brummy-linux
./install.sh                     # auto-detecta o perfil
./install.sh --boot-only         # só refaz GRUB + Plymouth (precisa de boot/assets/logo.png)
./install.sh --user-only         # só a camada de usuário (configs, tema, helpers)
```

Detalhes dos caminhos (incl. instalador fácil) em `docs/install.md`.
Roteiro de validação em VM: `docs/teste-vm.md`.

Também dá para gerar uma **ISO live** com instalador gráfico (Calamares), que já
vem com o Brummy pronto — veja `iso/README.md`:

```bash
./iso/build.sh          # precisa de Docker; a ISO sai em iso/out/
```

O script:
1. Checa que é Arch, detecta o perfil
2. Instala pacotes pacman + AUR (paru/yay)
3. Links de `config/*` -> `~/.config/*` (com backup) + perfil Hyprland em Lua
   (GTK é copiado, não linkado: nwg-look escreve nesses arquivos)
4. Postgres (initdb), Java default, TLP (thinkpad), Plymouth + GRUB
5. Instala `brummy` em `~/.local/bin`

```bash
brummy help | apps | doctor | wallpaper | theme | hide | update
```

## Estrutura

```
brummy-linux/
  install.sh            # instalador idempotente (perfis + flags)
  packages/             # base, dev, laptop, android, AUR
  bin/brummy            # CLI helper descobrível
  config/hypr/          # hyprland.lua + modules/ (monitores, GPU, trackpoint)
  config/waybar/        # bar tradicional + scripts que somem quando não se aplicam
  config/gtk-3.0/4.0/   # WhiteSur-Dark + cursor Bibata
  config/brummy/        # hidden-apps.list (o que não aparece no launcher)
  config/kitty/wofi/fish/
  themes/wallpapers/    # papéis de parede padrão
  boot/                 # tema Plymouth + gerador de assets + fundo GRUB
  iso/                  # ISO live com Calamares (archiso rodando em Docker)
  tools/vm.sh           # VM de teste em QEMU (o Boxes não dá conta)
  docs/                 # profiles, dev, boot, teste-vm, hyprland-lua
```

## Roadmap

- [x] v1 — scaffold + perfis + dev + boot + Nautilus
- [x] v1.1 — primeiro boot em VM analisado: config migrada para Lua (Hyprland 0.57
      aposenta o `.conf`), wallpaper/GTK escuro/cursor corrigidos, Waybar que não
      deixa buraco em máquina sem GPU, launcher sem apps parasitas
- [x] v1.1a — `hyprland --verify-config` na VM: **config ok** (a migração Lua
      está validada; `hl.print` não existia e foi corrigido)
- [ ] v1.2 — `./install.sh` completo validado de ponta a ponta
- [ ] v1.3 — ISO live (esqueleto pronto em `iso/`, falta a primeira build)
- [ ] futuro: LFS / kernel próprio pra aprender (separado deste repo)

Feito pra usar todo dia, mexer por prazer.
