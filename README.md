# Brummy Linux

[![check](https://github.com/dbcfilho/brummy-linux/actions/workflows/check.yml/badge.svg)](https://github.com/dbcfilho/brummy-linux/actions/workflows/check.yml)

Camada opinionada sobre **Arch Linux + Hyprland**. Não é um fork nem um kernel do
zero: é a mesma ideia do [Omarchy](https://omarchy.org) do DHH — pegar um Arch
limpo e deixá-lo pronto para o dia a dia com um comando — com visão própria.

**Híbrido minimalista + tradicional.** Rápido e guiado pelo teclado como um
gerenciador de janelas em tiling, descobrível e clicável como GNOME ou KDE. Quem
sabe os atalhos voa; quem não sabe tem barra com bandeja, dock, launcher com
ícones, gerenciador de arquivos gráfico, barras de título com botões e um
`brummy help` que conta tudo.

> **Estado: v1.4, primeira ISO construída.** O `install.sh` completo foi
> validado numa VM limpa, a config do Hyprland passa no `--verify-config` a cada
> push, e a ISO live com instalador gráfico saiu inteira do GitHub Actions pela
> primeira vez. Faltam: testar a ISO de ponta a ponta numa VM, ver as barras de
> título desenhando, e rodar no hardware real dos perfis `desktop` e `thinkpad`.
> Veja o [roadmap](#roadmap). Por enquanto, de preferência numa VM.

---

## Sumário

- [A ideia](#a-ideia)
- [O que vem dentro](#o-que-vem-dentro)
- [Instalação](#instalação) — [pela ISO](#caminho-a-pela-iso-live) ou [sobre um Arch](#caminho-b-sobre-um-arch-já-instalado)
- [O que o install.sh faz](#o-que-o-installsh-faz-passo-a-passo)
- [Perfis de máquina](#perfis-de-máquina)
- [A área de trabalho](#a-área-de-trabalho)
- [Atalhos](#atalhos)
- [O comando brummy](#o-comando-brummy)
- [Snapshots](#snapshots-a-rede-de-segurança)
- [A ISO live](#a-iso-live)
- [Para quem quiser mexer](#para-quem-quiser-mexer)
- [Quando algo dá errado](#quando-algo-dá-errado)
- [Documentação](#documentação)
- [Roadmap](#roadmap)
- [Licença e créditos](#licença-e-créditos)

---

## A ideia

Três escolhas guiam tudo o que está aqui:

1. **Tudo versionado, nada mágico.** `~/.config/hypr`, `~/.config/waybar` e
   companhia são *links* para `config/` neste repositório. Editou uma config, a
   mudança já está no git. Nada é gerado escondido na sua home.
2. **Uma fonte de verdade para pacotes.** As listas em `packages/` servem ao
   `install.sh` *e* à ISO. Mexeu numa lista, mexeu nos dois.
3. **Falhar alto, nunca calado.** Link de config quebrado, pacote do AUR que não
   instalou, plugin que não carregou, snapshot desligado: o `brummy doctor` conta.
   A lição veio de erros que só apareciam na hora do login.

---

## O que vem dentro

| | |
|---|---|
| **Base** | Arch Linux (rolling). ~165 pacotes oficiais + ~20 do AUR, todos listados em `packages/` |
| **Compositor** | Hyprland 0.55+, config em **Lua**, tiling automático com mouse tradicional |
| **Login** | greetd + tuigreet, entrando no Hyprland pelo `start-hyprland` |
| **Barra** | Waybar flutuante com bandeja; módulos de GPU, temperatura e bateria somem sozinhos quando o hardware não existe |
| **Dock** | nwg-dock-hyprland, largura total, com a logo do Brummy abrindo o launcher |
| **Launcher** | wofi no `SUPER+Espaço`, estilo Spotlight, sem apps "parasitas" de dependência |
| **Janelas** | barras de título com fechar / minimizar / maximizar (hyprbars, opcional) e minimizar de verdade |
| **Arquivos** | Nautilus (`SUPER+E`), Thunar de reserva |
| **Terminal** | kitty, com cadeia de fallback até o xterm — ficar sem terminal não é estado válido |
| **Shell** | fish + starship (opcional: o instalador não troca seu shell) |
| **Tema** | WhiteSur-Dark + accent azul, ícones WhiteSur, cursor Bibata, Inter + JetBrains Mono Nerd |
| **Boot** | logo do Brummy no GRUB + splash Plymouth com halo respirando |
| **Segurança** | snapshots automáticos antes de cada atualização (com `/` em btrfs) |

### Os pacotes, por categoria

Tudo em `packages/` — edite à vontade e rode o `./install.sh` de novo.

| Categoria | O que entra |
|---|---|
| Desktop | hyprland, hyprlock, hypridle, hyprpaper, portais xdg, waybar, nwg-dock, wofi, kitty, fish, starship |
| Captura e utilidades | hyprshot, grim, slurp, satty, cliphist, brightnessctl, pavucontrol, polkit-gnome, gnome-keyring, udiskie, blueman, NetworkManager |
| Arquivos e imagem | nautilus, thunar, sushi, gvfs (mtp, smb), file-roller, gparted, evince, loupe, pinta |
| Navegador | helium (padrão, AUR) + firefox |
| Escrita e office | obsidian, gnome-text-editor, gnome-calculator, libreoffice-fresh, onlyoffice (AUR) |
| Mídia e voz | mpv, obs-studio, spotify-launcher, discord, qbittorrent, easyeffects |
| Desenvolvimento (base) | neovim, tmux, git, github-cli, lazygit, docker + compose, lazydocker, mise, fzf, ripgrep, fd, bat, eza, zoxide, btop, jq, vscodium (AUR) |
| Desenvolvimento (bundle dev) | Java (openjdk latest + 21), maven, gradle, node, npm, python, uv, postgresql, redis, sqlite, dbeaver, kubectl, k9s, helm, kustomize, httpie, git-delta, direnv, postman (AUR) |
| Android (opcional) | android-studio (AUR), android-tools, scrcpy |
| GPU AMD | mesa, vulkan-radeon, libva, e as versões lib32 para jogos |
| Jogos | steam, lutris, bottles, wine, winetricks, gamemode, gamescope, mangohud, protonup-qt |
| Virtualização | qemu, libvirt, virt-manager, virt-viewer, gnome-boxes, swtpm, OVMF |
| Monitoramento | btop, mission-center, radeontop, nvtop |
| Laptop (só `thinkpad`) | tlp, thermald, thinkfan (AUR), powertop, acpi, drivers Intel |
| Snapshots (só btrfs) | snapper, snap-pac, grub-btrfs |
| Outros apps (AUR) | opencode, claude-code, claude-desktop, claudebar (módulo de uso na Waybar), localsend, etcher |

---

## Instalação

Dois caminhos. A ISO é o mais simples; o `install.sh` é o mais testado.

### Caminho A: pela ISO live

A ISO **já é o Brummy**: você dá boot, vê o sistema rodando antes de instalar e
clica em "Instalar o Brummy Linux". O instalador gráfico (Calamares) copia o live
para o disco — funciona sem internet, e o que você vê é o que você instala.

**Onde pegar:** a ISO é construída no GitHub Actions (aba **Actions → iso → Run
workflow**) e fica como artefato do run por 3 dias:

```bash
gh workflow run iso.yml --ref main     # dispara a build (~30 min)
gh run watch                           # acompanha
gh run download <id-do-run> -n brummy-iso -D iso/out
```

Ou construa localmente, com Docker — veja [A ISO live](#a-iso-live).

**Gravar no pendrive** (confira o dispositivo com `lsblk` antes):

```bash
sudo dd if=iso/out/brummy-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

A ISO tem ~5 GB, então o pendrive precisa ter 8 GB ou mais.

### Caminho B: sobre um Arch já instalado

Instale um Arch base — `archinstall` na ISO oficial resolve por menu — e rode
**um comando**:

```bash
git clone https://github.com/dbcfilho/brummy-linux.git
cd brummy-linux
./install.sh
```

No `archinstall`, **escolha btrfs como sistema de arquivos**: é o que liga os
snapshots automáticos. Prefere instalador gráfico? EndeavourOS também serve de
base. Os caminhos, do mais fácil ao mais cru, estão em `docs/install.md`.

O `install.sh` é **idempotente**: pode rodar quantas vezes quiser, e faz backup
de toda config que substitui (`~/.config/<nome>.bak-brummy-<data>`).

| Opção | O que faz |
|---|---|
| `--profile desktop\|thinkpad\|general` | força o perfil em vez de detectar (aceita `--profile=x` também) |
| `--no-dev` | pula o bundle de desenvolvimento |
| `--with-android` | inclui o Android Studio (pesado, ~1 GB) |
| `--no-snapshots` | não configura o snapper, mesmo com `/` em btrfs |
| `--no-boot` | não mexe no GRUB nem no Plymouth |
| `--boot-only` | só refaz GRUB + Plymouth |
| `--user-only` | só a camada de usuário: configs, tema, helpers — sem tocar em pacotes nem serviços |

Cada execução deixa um log completo em `~/.local/state/brummy/install-*.log`.

---

## O que o install.sh faz, passo a passo

1. **Detecta o perfil** da máquina (veja [Perfis](#perfis-de-máquina)).
2. **Liga o multilib** no `/etc/pacman.conf` (Steam e drivers lib32).
3. **Atualiza o sistema** (`pacman -Syu`).
4. **Instala o paru** como ajudante do AUR — conferindo se ele *funciona*, não só
   se existe (um paru linkado contra uma libalpm antiga existe, mas quebra tudo).
5. **Instala os pacotes**, um por vez: nome inexistente não derruba o resto.
   Oficiais pelo pacman, AUR pelo paru, depois o bundle dev, Android (se pedido)
   e a pilha de laptop (só no perfil `thinkpad`).
6. **Configura snapshots** se `/` for btrfs: snapper, snap-pac, grub-btrfs,
   retenção de 10 snapshots.
7. **Copia os papéis de parede** para `~/Pictures/Brummy/`.
8. **Linka as configs** de `config/` em `~/.config/` (com backup do que existia),
   e remove links que apontem para o vazio.
9. **Aplica o tema** GTK 2/3/4, ícones, cursor, fontes e `color-scheme` escuro
   (a chave que faz os apps GTK4/libadwaita abrirem escuros).
10. **Escolhe os módulos do Hyprland** do perfil (monitores e GPU).
11. **Instala o comando `brummy`** e os helpers em `~/.local/bin`.
12. **Liga os serviços**: PipeWire, NetworkManager, greetd, libvirt; põe você
    nos grupos libvirt, kvm e docker.
13. **Define os padrões**: Helium como navegador, Nautilus para pastas.
14. **Limpa o launcher** de apps parasitas de dependência.
15. **Monta o boot**: tema Plymouth, fundo do GRUB, `quiet splash`.

---

## Perfis de máquina

Detectados sozinhos pelo DMI (nome e tipo de chassi), pela bateria e pelo `lspci`.

| Perfil | Quando | Monitores | GPU | Energia |
|---|---|---|---|---|
| `desktop` | Xeon + RX 6600 XT, dois monitores 1080p | DP-1 à esquerda + HDMI-A-1 à direita | `gpu-amd` (RADV) | sem TLP, pensado para jogos |
| `thinkpad` | T430 e qualquer laptop (chassi portátil ou bateria presente) | eDP-1 1366x768 + monitor externo | `gpu-intel` | TLP, thermald, thinkfan, TrackPoint |
| `general` | todo o resto | `preferred, auto` | AMD se houver Radeon, senão Intel | sem TLP |

Os módulos ficam em `config/hypr/modules/`; o instalador aponta
`profile-monitors.lua` e `profile-gpu.lua` para os do perfil. Detalhes em
`docs/profiles.md`.

---

## A área de trabalho

**Tiling com mouse de verdade.** Janela nova entra e se acomoda sozinha, como em
qualquer tiling. Mas dá para puxar a borda para redimensionar, arrastar com `ALT`
para mover, e apps "de janelinha" (arquivos, volume, rede) já abrem flutuando e
centralizados. Jogos entram em tela cheia, sem blur nem sombra.

**Waybar** (topo), da esquerda para a direita:

- logo do Brummy (abre o launcher), workspaces clicáveis (a roda do mouse troca),
  o contador `󰖰 N` de janelas minimizadas (clique restaura) e o título da janela;
- relógio no centro;
- uso do Claude, CPU, memória, GPU, temperatura, bandeja, volume (roda do mouse
  ajusta), rede, bateria, calendário e ⏻ para desligar.

Os módulos de GPU, temperatura e bateria imprimem vazio quando não se aplicam, e a
Waybar esconde em vez de deixar buraco.

**Janelas clicáveis** (opcional, `brummy bars on`): cada janela ganha uma barra de
título com as três bolinhas à esquerda, na ordem do macOS — fechar, minimizar,
maximizar. O símbolo aparece com o mouse em cima; duplo clique na barra maximiza.
O tiling continua igual. Detalhes e custos em `docs/janelas-clicaveis.md`.

**Minimizar de verdade.** O Hyprland não tem minimizar; o Brummy manda a janela
para uma gaveta (`special:minimizado`) e a traz de volta pelo `SUPER+SHIFT+M` ou
pelo `󰖰` da barra. Com mais de uma na gaveta, o wofi pergunta qual.

**Papel de parede:** uma foto da Terra vista da ISS (NASA) por padrão, mais duas
da NASA e três recortes de uma foto do Parque do Ibitipoca. `brummy wallpaper
next` troca.

---

## Atalhos

`brummy help` mostra tudo, a qualquer momento.

**Teclado**

| Atalho | Ação | Atalho | Ação |
|---|---|---|---|
| `SUPER+Espaço` ou `SUPER+D` | launcher | `SUPER+Q` ou `SUPER+Enter` | terminal |
| `SUPER+E` | arquivos | `SUPER+B` | navegador |
| `SUPER+SHIFT+C` | editor (VSCodium) | `SUPER+L` | bloquear a tela |
| `SUPER+C` | fechar a janela | `SUPER+F` | tela cheia |
| `SUPER+V` | flutuar / voltar ao tiling | `SUPER+SHIFT+S` | captura de tela |
| `SUPER+M` | minimizar | `SUPER+SHIFT+M` | restaurar minimizada |
| `SUPER+J` / `SUPER+K` | próxima / anterior janela | `SUPER+SHIFT+Q` | sair do Hyprland |
| `SUPER+1..9` | ir para o workspace | `SUPER+SHIFT+1..9` | mandar a janela para o workspace |

Teclas de mídia, volume e brilho funcionam, inclusive com a tela bloqueada.

**Mouse**

| Gesto | Ação |
|---|---|
| puxar a borda da janela | redimensionar, sem tecla nenhuma |
| `SUPER` ou `ALT` + arrastar (botão esquerdo) | mover |
| `SUPER` ou `ALT` + arrastar (botão direito) | redimensionar |
| `SUPER` + roda | trocar de workspace |
| `SUPER` + clique do meio | fechar |
| `SUPER+SHIFT` + clique direito | flutuar / voltar ao tiling |
| três dedos para o lado (touchpad) | trocar de workspace |

---

## O comando `brummy`

| Comando | O que faz |
|---|---|
| `brummy help` | atalhos e comandos, sem precisar decorar nada |
| `brummy apps` | o que veio instalado, por categoria |
| `brummy doctor` | diagnóstico completo (abaixo) |
| `brummy update` | snapshot, `pacman -Syu`, recompila plugins do Hyprland, refaz os links |
| `brummy fix` | remove links de config quebrados e refaz a camada de usuário |
| `brummy wallpaper list \| set <arquivo> \| next` | troca o papel de parede |
| `brummy hide [--list \| --undo]` | esconde do launcher os apps parasitas |
| `brummy bars on \| off \| status` | barras de título clicáveis (rode dentro da sessão) |
| `brummy snapshot list \| create <descrição> \| rollback` | pontos de restauração |
| `brummy extras` | instala os apps do AUR que faltam (os que falharam, ou que a ISO pública não traz) |
| `brummy uninstall` | tira os links e devolve os backups das suas configs |
| `brummy theme` | onde mexer no tema |

**O `brummy doctor` é o primeiro lugar para olhar** quando algo parecer errado.
Ele confere: o perfil ativo, os pacotes de que o visual depende, **links de config
apontando para o vazio** (a causa nº 1 de "o login gráfico não entra"), a config
Lua do Hyprland, o greetd, o tema escuro, o papel de parede, **cada pacote do AUR
que falhou calado na instalação**, os snapshots, as barras de título, o bundle
dev, a pilha de laptop, o boot, a GPU e o KVM.

---

## Snapshots: a rede de segurança

Arch é rolling. Quase sempre o `pacman -Syu` passa liso; quando não passa, o
sintoma costuma ser o pior: a sessão gráfica não sobe.

Com `/` em **btrfs**, o `install.sh` liga:

- **snapper** — cria e gerencia os snapshots do `/`;
- **snap-pac** — um snapshot antes e outro depois de *toda* transação do pacman;
- **grub-btrfs** — os snapshots aparecem num submenu do GRUB, para dar boot num
  estado que funcionava;
- **limpeza automática** — guarda os 10 mais recentes.

```bash
brummy snapshot                      # lista
brummy snapshot create antes-do-driver
brummy snapshot rollback             # mostra o caminho de volta
```

O `/home` fica fora dos snapshots do `/`: voltar o sistema nunca desfaz seus
arquivos. O passo a passo da restauração está em `docs/snapshots.md`.

---

## A ISO live

Construída com o **archiso**, rodando dentro de um container Arch (o archiso só
roda em Arch; assim dá para construir de qualquer distro com Docker).

```
iso/build.sh                  roda no seu PC (ou no GitHub Actions)
  └─ docker run archlinux     privilegiado: o mkarchiso monta loop devices
       └─ builder/build-iso.sh
            ├─ aur-repo.sh      AUR → repositório pacman local (com cache)
            ├─ gen-packages.sh  packages/*.packages → lista do archiso
            ├─ perfil           boot do releng + airootfs do Brummy
            └─ mkarchiso        → iso/out/brummy-AAAA.MM.DD-x86_64.iso
```

**Construir localmente:**

```bash
sudo apt install docker.io && sudo usermod -aG docker $USER   # relogue depois
./iso/build.sh                       # 40-90 min na primeira vez
BRUMMY_ISO_SEM_DEV=1 ./iso/build.sh  # sem o bundle dev (ISO menor)
BRUMMY_ISO_PUBLICA=1 ./iso/build.sh  # para distribuir: sem o que não pode ser redistribuído
./iso/build.sh --no-cache            # reconstrói todos os pacotes do AUR
./iso/build.sh --shell               # shell no container, para depurar
```

**ISO para distribuir.** Alguns apps do AUR são binários de terceiros que não
podem ser redistribuídos. No modo público (opção `publica` no workflow), a build
lê a licença de cada pacote e deixa de fora os restritos, além dos listados em
`packages/iso-publica.exclui`; toda build publica um `LICENCAS.txt` com o que
entrou e por quê. Quem instala pega o resto com `brummy extras`.

**Construir no GitHub:** aba **Actions → iso → Run workflow**. Mesmo script, cache
dos pacotes do AUR entre builds (salvo até quando a build falha), e ao fim o run
lista o que ficou de fora.

**Testar sem gravar nada:**

```bash
./tools/vm.sh criar
./tools/vm.sh iso iso/out/brummy-*.iso
```

**O que acontece na instalação.** O live carrega coisas que num sistema instalado
seriam perigosas ou quebradas. O Calamares roda o `brummy-pos-instalacao` no
sistema novo, que:

- põe o kernel no `/boot` (o mkarchiso esvazia o `/boot` do live);
- tira os serviços e configs que só servem ao live (chaveiro em tmpfs, journal
  em RAM, initramfs do archiso);
- trava o root — o acesso é por `sudo`, como no Arch;
- cria o chaveiro do pacman de verdade e liga o multilib;
- põe o login com senha (tuigreet) no lugar do login automático do live;
- aplica a camada do Brummy no usuário criado, com o repositório em
  `~/brummy-linux` — um clone de verdade, onde `git pull` funciona;
- aplica o fundo do GRUB e o splash do Plymouth.

Tudo sobre a ISO, inclusive o histórico de cada build, está em `iso/README.md`.

---

## Para quem quiser mexer

### Estrutura

```
brummy-linux/
  install.sh              instalador idempotente (perfis + opções)
  packages/               listas de pacotes: fonte única, do install.sh e da ISO
    base, dev, laptop, btrfs          pelo pacman
    aur, dev-aur, laptop-aur,
    android-aur                       pelo paru
  bin/                    brummy (CLI) e helpers
    brummy-wallpaper-apply  aplica o papel de parede (fala as duas IPCs do hyprpaper)
    brummy-hide-apps        limpa o launcher
    brummy-minimizados      a gaveta das janelas minimizadas
    brummy-remove-preinstalls
  config/                 vira ~/.config/* por link simbólico
    hypr/hyprland.lua       config principal (Lua, Hyprland 0.55+)
    hypr/modules/           perfis de monitor, GPU e trackpoint
    hypr/legacy/            a config .conf antiga, só para consulta
    waybar/                 config, estilo e scripts dos módulos
    kitty/ wofi/ fish/ fastfetch/ nwg-dock-hyprland/ gtk-3.0/ gtk-4.0/ greetd/
    brummy/hidden-apps.list
  themes/wallpapers/      papéis de parede (ORIGEM.md diz de onde veio cada um)
  boot/                   tema Plymouth, gerador de assets, fundo do GRUB
  iso/                    ISO live com Calamares
    build.sh                orquestrador (Docker)
    builder/                build-iso, aur-repo, gen-packages
    profile/                profiledef, airootfs, pacotes só da ISO
    calamares/              configuração e identidade visual do instalador
  tools/
    check.sh                todas as checagens que dão para fazer sem instalar nada
    vm.sh                   criar, bootar e acessar VMs de teste
    host-keys.sh            solta o SUPER do host (GNOME) durante o teste
  .github/workflows/
    check.yml               check.sh + hyprland --verify-config por perfil, a cada push
    iso.yml                 build da ISO, manual
  docs/                   as notas técnicas
```

### Checagens

```bash
./tools/check.sh
```

Roda, em segundos: sintaxe e **shellcheck** de todo script; JSON da Waybar e do
fastfetch; sintaxe Lua; o bloco das barras de título conferido contra o que o
plugin exige (com e sem o plugin carregado); nenhum `hyprctl dispatch` com a
sintaxe antiga; a gaveta de minimizados com um `hyprctl` de mentira; a ISO
(pacotes essenciais, `install_dir`, YAML do Calamares); e cada subcomando do
`vm.sh` e do `brummy`.

No GitHub, a cada push, o mesmo `check.sh` roda junto com o **`hyprland
--verify-config` num container Arch para cada perfil**: config inválida deixa o
commit vermelho, sem precisar abrir a VM.

### Testar numa VM

```bash
./tools/vm.sh deps                # o que instalar no host
./tools/vm.sh criar               # disco novo
./tools/vm.sh achar               # acha discos de VM que você já tem
./tools/vm.sh overlay <disco>     # boota um deles sem escrever nele
./tools/vm.sh enviar              # manda o repo para dentro da VM
./tools/vm.sh ssh                 # terminal na VM, sem depender de atalho
./tools/host-keys.sh liberar      # solta o SUPER do GNOME do host (e devolve depois)
```

Roteiro completo, e como sair de cada enrosco, em `docs/teste-vm.md`.

### Lições que viraram regra

- **Nunca confie em API de terceiro para o Hyprland.** Um `hl.print` inexistente
  derrubou o login. Hoje a config sai do código-fonte e passa pelo
  `--verify-config` no CI.
- **Com config em Lua, `hyprctl dispatch` recebe Lua.** `hyprctl dispatch
  workspace e+1` falha calado; o certo é `hyprctl dispatch
  'hl.dsp.focus({ workspace = "e+1" })'`. O `check.sh` reprova o formato antigo.
- **Autostart nunca derruba a sessão.** Cada comando roda dentro de `pcall`.
- **Link de config quebrado impede o login.** Por isso `brummy fix` e a checagem
  no `doctor`.

---

## Quando algo dá errado

| Sintoma | O que fazer |
|---|---|
| O login gráfico não entra | num TTY (`Ctrl+Alt+F2`), rode `brummy fix`; depois `brummy doctor` |
| Mexi numa config e a sessão quebrou | `hyprland --verify-config` aponta a linha |
| Uma atualização quebrou o sistema | no GRUB, entre em "Arch Linux snapshots"; depois `docs/snapshots.md` |
| As barras de título sumiram depois de atualizar | `brummy bars on`, dentro da sessão |
| Um app do AUR não veio | `brummy doctor` lista; `paru -S <pacote>` mostra o erro |
| Apps GTK abrem claros | `brummy doctor` confere o `color-scheme`; `./install.sh --user-only` reaplica |
| Apareceu lixo no launcher | `brummy hide` |
| Quero voltar às minhas configs antigas | `brummy uninstall` |

---

## Documentação

| Nota | Assunto |
|---|---|
| `docs/install.md` | os caminhos de instalação, do mais fácil ao mais cru |
| `docs/profiles.md` | perfis de máquina, monitores e GPU |
| `docs/dev.md` | o bundle de desenvolvimento |
| `docs/boot.md` | GRUB e Plymouth com a logo |
| `docs/hyprland-lua.md` | a migração para Lua, equivalências e como validar |
| `docs/janelas-clicaveis.md` | barras de título, minimizar, e como é testado |
| `docs/snapshots.md` | snapper + grub-btrfs, e como voltar a um snapshot |
| `docs/teste-vm.md` | roteiro de teste em VM |
| `docs/extensions.md` | extensões do GNOME (como o Astra Monitor) e o equivalente no Brummy |
| `iso/README.md` | a ISO live: como funciona, como construir, histórico das builds |

---

## Roadmap

- [x] **v1** — scaffold, perfis, bundle dev, boot com logo, Nautilus
- [x] **v1.1** — primeiro boot analisado em vídeo e corrigido: config migrada
      para Lua (o `.conf` sai na 0.57), papel de parede, tema escuro nos apps
      GTK4, cursor, Waybar sem buracos, launcher sem apps parasitas, logo do
      Brummy no fastfetch
- [x] **v1.1a** — `hyprland --verify-config` na VM: config ok
- [x] **v1.2** — `./install.sh` completo validado numa VM limpa; CI com
      shellcheck e verify-config por perfil; snapshots antes de atualizar;
      `brummy uninstall`; log da instalação
- [x] **v1.3** — janelas clicáveis (hyprbars) e minimizar/restaurar com `󰖰` na
      Waybar; scroll dos workspaces corrigido para a sintaxe Lua
- [x] **v1.4** — ISO live com Calamares: revisada contra o código do archiso,
      construída no GitHub Actions (quatro builds até a primeira ISO inteira)
- [ ] **v1.4a** — ISO testada de ponta a ponta numa VM: boot BIOS e UEFI,
      instalação pelo Calamares, sistema instalado subindo com a cara do Brummy
- [ ] **v1.3a** — barras de título vistas desenhando na VM
- [ ] **v1.2a** — `./install.sh` no hardware real: T430 (`thinkpad`) e
      RX 6600 XT (`desktop`)
- [ ] **v1.5** — btrfs com subvolumes na ISO (snapshots também para quem instala
      por ela), menu de boot da ISO com o nome do Brummy, ISO publicada para
      download
- [ ] futuro — LFS / kernel próprio, para aprender (em outro repositório)

---

## Licença e créditos

**MIT** — veja `LICENSE`.

- Inspirado no [Omarchy](https://omarchy.org), de David Heinemeier Hansson.
- Papéis de parede: foto do Parque Estadual do Ibitipoca (MG) do autor, e três
  fotos da NASA em domínio público. As origens estão em
  `themes/wallpapers/ORIGEM.md`.
- Construído sobre o trabalho de Arch Linux, Hyprland, archiso, Calamares e de
  cada mantenedor de pacote do AUR que ele usa.

Feito para usar todo dia, e mexer por prazer.
