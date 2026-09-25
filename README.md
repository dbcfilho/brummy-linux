# Brummy Linux

Camada opinionada sobre **Arch Linux + Hyprland**. Não é um fork nem um kernel do
zero: é a mesma ideia do [Omarchy](https://omarchy.org) do DHH, com visão própria.

**Híbrido minimalista + tradicional.** Rápido e teclado-driven como um tiling,
descobrível e clicável como GNOME/KDE. Quem sabe os atalhos voa; quem não sabe
tem barra com bandeja, launcher com ícones, gerenciador de arquivos gráfico e um
`brummy help` que conta tudo.

> **Estado: v1.2.** A config do Hyprland está em Lua, passa no
> `hyprland --verify-config`, e o `install.sh` completo foi validado de ponta a
> ponta numa VM limpa. Falta rodar no hardware de verdade dos perfis `desktop`
> e `thinkpad` — veja o [roadmap](#roadmap). Com `/` em btrfs, toda atualização
> tira snapshot antes.

---

## O que vem dentro

| | |
|---|---|
| **Base** | Arch Linux (rolling) — ~185 pacotes, listados em `packages/` |
| **Compositor** | Hyprland, config em **Lua** (0.55+), tiling com mouse tradicional |
| **Barra** | Waybar flutuante com bandeja, e módulos que somem sozinhos quando o hardware não existe |
| **Dock** | nwg-dock-hyprland, auto-hide, ícones 48px |
| **Launcher** | wofi no `SUPER+Espaço`, estilo Spotlight |
| **Arquivos** | Nautilus (`SUPER+E`), Thunar de reserva |
| **Terminal** | kitty, com cadeia de fallback até o xterm |
| **Tema** | WhiteSur-Dark + accent azul, cursor Bibata, Inter + JetBrains Mono Nerd |
| **Boot** | logo no GRUB + splash Plymouth com luz pulsante |
| **Bundles** | dev (Java/Node/Python/Postgres/k8s), gaming (RX 6600 XT), KVM + Boxes |

Atalhos principais — `brummy apps` lista todos:

```
SUPER+Espaço  launcher        SUPER+Q ou ENTER  terminal
SUPER+E       arquivos        SUPER+B           navegador
SUPER+C       fechar          SUPER+F           tela cheia
SUPER+V       flutuar         SUPER+SHIFT+S     captura de tela
SUPER+1..9    workspaces      SUPER+arrastar    mover/redimensionar
```

Sem tecla nenhuma: puxe a borda da janela para redimensionar, arraste com `ALT`
para mover, clique nos workspaces da barra, use o botão ⏻ para desligar.

---

## Instalação

O Brummy é **pós-instalação**. Instale um Arch base — `archinstall` na ISO
oficial resolve por menu, ou EndeavourOS se quiser instalador gráfico — e rode
**um comando**:

```bash
git clone https://github.com/dbcfilho/brummy-linux.git
cd brummy-linux
./install.sh
```

É idempotente: pode rodar quantas vezes quiser, faz backup do que substitui.

```bash
./install.sh --profile thinkpad   # força o perfil
./install.sh --no-dev             # pula o bundle de desenvolvimento
./install.sh --user-only          # só configs e tema, sem tocar em pacotes
./install.sh --boot-only          # só refaz GRUB + Plymouth
./install.sh --no-snapshots       # não configura snapper, mesmo em btrfs
```

Cada execução deixa um log em `~/.local/state/brummy/install-*.log`.

**Escolha btrfs no archinstall.** Com `/` em btrfs, o instalador liga snapper +
snap-pac + grub-btrfs: todo `pacman` tira um snapshot antes e depois, e dá para
dar boot num snapshot pelo GRUB se uma atualização quebrar a sessão. Detalhes e
o caminho de volta em `docs/snapshots.md`.

### Perfis

Detectados sozinhos pelo DMI (nome e tipo de chassi), pela bateria e pelo `lspci`:

| Perfil | Máquina |
|---|---|
| `desktop` | Xeon + RX 6600 XT, dois monitores 1080p |
| `thinkpad` | T430 e laptops em geral (Intel + TLP + TrackPoint) |
| `general` | qualquer outro PC |

### ISO live

Em construção. A ideia é baixar, dar boot, ver o sistema rodando e instalar pelo
Calamares. O esqueleto está em `iso/` e **ainda não foi construído nenhuma vez**:

```bash
./iso/build.sh      # precisa de Docker; a ISO sai em iso/out/
```

---

## O comando `brummy`

```bash
brummy help        atalhos e comandos, sem precisar decorar nada
brummy apps        o que veio instalado, por categoria
brummy doctor      diagnóstico: o que falta, links quebrados, tema, wallpaper
brummy wallpaper   list | set <arquivo> | next
brummy hide        esconde apps parasitas do launcher (--list, --undo)
brummy fix         conserta links de config quebrados
brummy update      snapshot, atualiza o sistema, recompila plugins e repuxa os links
brummy snapshot    list | create <descrição> | rollback
brummy uninstall   tira os links e devolve os backups das suas configs
```

O `brummy doctor` é o primeiro lugar para olhar quando algo parecer errado. Ele
diz, entre outras coisas, se algum link de config está apontando para o vazio —
que é a causa nº 1 de "o login gráfico não entra" —, quais pacotes do AUR
falharam em silêncio na instalação e se os snapshots estão ativos.

---

## Para quem quiser mexer

Tudo que o sistema usa está versionado aqui. `~/.config/hypr`, `~/.config/waybar`
e companhia são **links** para `config/` neste repo: editou, já está no git.

```bash
./tools/check.sh                  # shellcheck, JSON, Lua e todos os subcomandos
./tools/vm.sh deps                # o que instalar para testar em VM
./tools/vm.sh achar               # acha discos de VM que você já tem
./tools/vm.sh overlay <disco>     # boota um deles sem escrever nele
./tools/vm.sh enviar              # manda o repo para dentro da VM
./tools/vm.sh ssh                 # terminal na VM, sem depender de atalho
./tools/host-keys.sh liberar      # solta o SUPER do host (GNOME) e devolve depois
```

O mesmo `check.sh` roda no GitHub Actions a cada push
(`.github/workflows/check.yml`), junto com um `hyprland --verify-config` num
container Arch para cada perfil — ainda experimental, não reprova o commit.

Dentro da VM, a checagem que importa:

```bash
hyprland --verify-config
```

### Estrutura

```
brummy-linux/
  install.sh            instalador idempotente (perfis + flags)
  packages/             base, dev, laptop, btrfs, android, AUR — fonte única, inclusive da ISO
  bin/                  brummy (CLI) + helpers
  config/               vira ~/.config/* por link simbólico
    hypr/hyprland.lua     config principal (Lua, Hyprland 0.55+)
    hypr/modules/         perfis de monitor, GPU e trackpoint
    hypr/legacy/          a config .conf antiga, só para consulta
    waybar/ kitty/ wofi/ fish/ fastfetch/ gtk-3.0/ gtk-4.0/
    brummy/hidden-apps.list
  themes/wallpapers/    papéis de parede (e ORIGEM.md, com as licenças)
  boot/                 tema Plymouth, gerador de assets, fundo do GRUB
  iso/                  ISO live com Calamares (archiso rodando em Docker)
  tools/                vm.sh, check.sh, host-keys.sh
  .github/workflows/    CI: check.sh + verify-config por perfil
  docs/                 as notas técnicas
```

### Documentação

| Nota | Assunto |
|---|---|
| `docs/install.md` | os caminhos de instalação, do mais fácil ao mais cru |
| `docs/hyprland-lua.md` | a migração para Lua, equivalências e como validar |
| `docs/teste-vm.md` | roteiro de teste em VM e como sair de cada enrosco |
| `docs/snapshots.md` | snapper + grub-btrfs, e como voltar a um snapshot |
| `docs/janelas-clicaveis.md` | o plano das barras de título sobre o tiling |
| `docs/profiles.md`, `docs/dev.md`, `docs/boot.md` | perfis, bundle dev, boot |

---

## Roadmap

- [x] **v1** — scaffold, perfis, bundle dev, boot com logo, Nautilus
- [x] **v1.1** — primeiro boot analisado em vídeo e corrigido: config migrada
      para Lua (o `.conf` sai na 0.57), papel de parede, tema escuro nos apps
      GTK4, cursor, Waybar sem buracos, launcher sem apps parasitas, logo do
      Brummy no fastfetch
- [x] **v1.1a** — `hyprland --verify-config` na VM: **config ok**
- [x] **v1.2** — `./install.sh` completo validado numa VM limpa (hyprpaper 0.8,
      greetd, dock); CI com shellcheck; snapshots antes de atualizar;
      `brummy uninstall`; log da instalação
- [ ] **v1.2a** — `./install.sh` no hardware real: T430 (`thinkpad`) e
      RX 6600 XT (`desktop`)
- [ ] **v1.3** — janelas clicáveis sobre o tiling (hyprbars + taskbar), plano em
      `docs/janelas-clicaveis.md`
- [ ] **v1.4** — primeira build da ISO live
- [ ] futuro — LFS / kernel próprio, para aprender (em outro repo)

---

## Licença

MIT — veja `LICENSE`. Os papéis de parede têm origens distintas e estão
documentados em `themes/wallpapers/ORIGEM.md`.

Feito pra usar todo dia, e mexer por prazer.
