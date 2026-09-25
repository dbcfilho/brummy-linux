# Brummy Linux

[![check](https://github.com/dbcfilho/brummy-linux/actions/workflows/check.yml/badge.svg)](https://github.com/dbcfilho/brummy-linux/actions/workflows/check.yml)

O Brummy é o meu Arch Linux com Hyprland, do jeito que eu gosto de usar. Ele
não é um fork e não tem kernel próprio. A ideia é a mesma do
[Omarchy](https://omarchy.org), do DHH: você instala um Arch limpo, roda um
comando e a máquina fica pronta para o dia a dia. Só que as escolhas são minhas.

Eu queria as duas coisas: a velocidade de um tiling, em que as janelas
se arrumam sozinhas e tudo tem atalho, e o conforto de um GNOME ou KDE, em que
dá para fazer tudo com o mouse sem decorar nada. Então o Brummy tem barra com
bandeja, dock, launcher com ícones, gerenciador de arquivos, botões nas janelas
e um `brummy help` para quando a memória falha.

> Estado atual: v1.4. O `install.sh` completo rodou numa VM limpa, a
> configuração do Hyprland é validada a cada push e a primeira ISO live saiu do
> GitHub Actions. Ainda falta instalar a partir da ISO, ver as barras de título
> funcionando numa sessão de verdade e rodar no meu hardware (o T430 e o
> desktop). Enquanto isso, prefira testar numa VM. O [roadmap](#roadmap) tem o
> resto.

---

## Sumário

- [Como o projeto pensa](#como-o-projeto-pensa)
- [O que vem dentro](#o-que-vem-dentro)
- [Instalação](#instalação): [pela ISO](#pela-iso-live) ou [sobre um Arch](#sobre-um-arch-já-instalado)
- [O que o install.sh faz](#o-que-o-installsh-faz)
- [Perfis de máquina](#perfis-de-máquina)
- [A área de trabalho](#a-área-de-trabalho)
- [Atalhos](#atalhos)
- [O comando brummy](#o-comando-brummy)
- [Snapshots](#snapshots)
- [A ISO live](#a-iso-live)
- [Para quem quiser mexer](#para-quem-quiser-mexer)
- [Quando algo dá errado](#quando-algo-dá-errado)
- [Documentação](#documentação)
- [Roadmap](#roadmap)
- [Licença e créditos](#licença-e-créditos)

---

## Como o projeto pensa

Tudo fica no git. As pastas `~/.config/hypr`, `~/.config/waybar` e as outras são
links para `config/` neste repositório, então editou uma config, a mudança já
está versionada. Nada é gerado escondido na sua home.

Os pacotes têm uma lista só. Os arquivos em `packages/` servem tanto ao
`install.sh` quanto à ISO, e por isso as duas coisas nunca saem de sincronia.

E quando algo falha, o sistema avisa. Eu aprendi isso do jeito ruim: link de
config apontando para o vazio, pacote do AUR que não instalou, plugin que não
carregou. Tudo isso só aparecia na hora do login, com a tela preta. Hoje o
`brummy doctor` conta.

---

## O que vem dentro

| | |
|---|---|
| Base | Arch Linux (rolling). ~165 pacotes oficiais e ~20 do AUR, todos listados em `packages/` |
| Compositor | Hyprland 0.55+, com a config em Lua. Tiling automático, mas com mouse de verdade |
| Login | greetd com tuigreet, entrando no Hyprland pelo `start-hyprland` |
| Barra | Waybar flutuante com bandeja. Os módulos de GPU, temperatura e bateria somem quando o hardware não existe |
| Dock | nwg-dock-hyprland na largura toda, com a logo do Brummy abrindo o launcher |
| Launcher | wofi no `SUPER+Espaço`, no estilo do Spotlight, sem os apps que as dependências espalham |
| Janelas | barras de título com fechar, minimizar e maximizar (opcional), e um minimizar que funciona |
| Arquivos | Nautilus no `SUPER+E`, com o Thunar de reserva |
| Terminal | kitty. Se ele não abrir, o atalho tenta outros até chegar no xterm |
| Shell | fish com starship. O instalador não troca o seu shell sem você pedir |
| Tema | WhiteSur-Dark com destaque azul, ícones WhiteSur, cursor Bibata, fontes Inter e JetBrains Mono Nerd |
| Boot | a logo do Brummy no GRUB e um splash do Plymouth com uma luz que pulsa |
| Proteção | snapshot antes de cada atualização, quando o `/` é btrfs |

### Os pacotes

Estão todos em `packages/`. Mudou alguma lista, é só rodar o `./install.sh` de
novo.

| Categoria | O que entra |
|---|---|
| Desktop | hyprland, hyprlock, hypridle, hyprpaper, portais xdg, waybar, nwg-dock, wofi, kitty, fish, starship |
| Captura e utilidades | hyprshot, grim, slurp, satty, cliphist, brightnessctl, pavucontrol, polkit-gnome, gnome-keyring, udiskie, blueman, NetworkManager |
| Arquivos e imagem | nautilus, thunar, sushi, gvfs (mtp, smb), file-roller, gparted, evince, loupe, pinta |
| Navegador | helium (padrão, AUR) e firefox |
| Escrita e office | obsidian, gnome-text-editor, gnome-calculator, libreoffice-fresh, onlyoffice (AUR) |
| Mídia e voz | mpv, obs-studio, spotify-launcher, discord, qbittorrent, easyeffects |
| Desenvolvimento (base) | neovim, tmux, git, github-cli, lazygit, docker e compose, lazydocker, mise, fzf, ripgrep, fd, bat, eza, zoxide, btop, jq, vscodium (AUR) |
| Desenvolvimento (bundle dev) | Java (openjdk mais recente e o 21), maven, gradle, node, npm, python, uv, postgresql, redis, sqlite, dbeaver, kubectl, k9s, helm, kustomize, httpie, git-delta, direnv, postman (AUR) |
| Android (opcional) | android-studio (AUR), android-tools, scrcpy |
| GPU AMD | mesa, vulkan-radeon, libva, e as versões lib32 para jogos |
| Jogos | steam, lutris, bottles, wine, winetricks, gamemode, gamescope, mangohud, protonup-qt |
| Virtualização | qemu, libvirt, virt-manager, virt-viewer, gnome-boxes, swtpm, OVMF |
| Monitoramento | btop, mission-center, radeontop, nvtop |
| Laptop (só no perfil `thinkpad`) | tlp, thermald, thinkfan (AUR), powertop, acpi, drivers Intel |
| Snapshots (só com btrfs) | snapper, snap-pac, grub-btrfs |
| Outros apps (AUR) | opencode, claude-code, claude-desktop, claudebar (o módulo de uso na Waybar), localsend, etcher |

---

## Instalação

Tem dois caminhos. A ISO é o mais fácil. O `install.sh` é o que mais foi
testado até agora.

### Pela ISO live

A ISO já é o Brummy. Você dá boot, usa o sistema antes de decidir e, se gostar,
clica em "Instalar o Brummy Linux". O instalador gráfico (o Calamares) copia o
sistema do pendrive para o disco. Funciona sem internet, e o que você viu é o
que vai ficar instalado.

Por enquanto a ISO não tem página de download. Ela é construída no GitHub
Actions (aba Actions, workflow `iso`, botão "Run workflow") e fica disponível no
próprio run por 3 dias:

```bash
gh workflow run iso.yml --ref main     # dispara a build, uns 30 minutos
gh run watch                           # acompanha
gh run download <id-do-run> -n brummy-iso -D iso/out
```

Também dá para construir na sua máquina com Docker, como está em
[A ISO live](#a-iso-live).

Para gravar no pendrive, confira o dispositivo com `lsblk` antes, porque o `dd`
apaga o que estiver lá:

```bash
sudo dd if=iso/out/brummy-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

A ISO tem uns 5 GB, então use um pendrive de 8 GB ou mais.

### Sobre um Arch já instalado

Instale um Arch base (o `archinstall`, na ISO oficial, resolve tudo por menu) e
rode:

```bash
git clone https://github.com/dbcfilho/brummy-linux.git
cd brummy-linux
./install.sh
```

Uma dica: no `archinstall`, escolha btrfs como sistema de arquivos. É isso que
liga os snapshots automáticos. Se preferir um instalador gráfico, o EndeavourOS
também serve de base. O `docs/install.md` explica os caminhos com mais calma.

Pode rodar o `install.sh` quantas vezes quiser. Ele não refaz o que já está
feito, e antes de substituir qualquer config guarda uma cópia em
`~/.config/<nome>.bak-brummy-<data>`.

| Opção | O que faz |
|---|---|
| `--profile desktop\|thinkpad\|general` | força um perfil em vez de detectar (`--profile=x` também funciona) |
| `--no-dev` | pula o bundle de desenvolvimento |
| `--with-android` | inclui o Android Studio, que pesa mais de 1 GB |
| `--no-snapshots` | não configura o snapper, mesmo com `/` em btrfs |
| `--no-boot` | não mexe no GRUB nem no Plymouth |
| `--boot-only` | refaz só o GRUB e o Plymouth |
| `--user-only` | aplica só a parte do usuário (configs, tema, helpers), sem tocar em pacotes nem serviços |

Cada execução grava um log completo em `~/.local/state/brummy/install-*.log`. Se
der problema, é o primeiro arquivo que eu olharia.

---

## O que o install.sh faz

Na ordem em que acontece:

1. Descobre o perfil da máquina (mais sobre isso em [Perfis](#perfis-de-máquina)).
2. Liga o multilib no `/etc/pacman.conf`, que a Steam e os drivers de 32 bits precisam.
3. Atualiza o sistema com `pacman -Syu`.
4. Instala o paru para os pacotes do AUR. Ele confere se o paru funciona, e não
   só se o binário existe, porque um paru compilado contra uma libalpm antiga
   existe, abre e quebra tudo em silêncio.
5. Instala os pacotes um por vez, para que um nome errado não derrube os outros.
   Primeiro os oficiais, depois os do AUR, o bundle dev, o Android se você pediu,
   e as coisas de laptop no perfil `thinkpad`.
6. Se o `/` for btrfs, configura o snapper, o snap-pac e o grub-btrfs, guardando
   os 10 snapshots mais recentes.
7. Copia os papéis de parede para `~/Pictures/Brummy/`.
8. Linka as configs de `config/` em `~/.config/`, com backup do que existia, e
   remove links que apontam para lugar nenhum.
9. Aplica o tema no GTK 2, 3 e 4, ícones, cursor, fontes e o `color-scheme`
   escuro. Sem essa última chave, os apps GTK4 abrem claros no meio do tema escuro.
10. Escolhe os módulos do Hyprland (monitores e GPU) do perfil.
11. Instala o comando `brummy` e os helpers em `~/.local/bin`.
12. Liga o PipeWire, o NetworkManager, o greetd e o libvirt, e coloca você nos
    grupos libvirt, kvm e docker.
13. Define o Helium como navegador padrão e o Nautilus para abrir pastas.
14. Tira do launcher os apps que as dependências espalham.
15. Monta o boot: tema do Plymouth, fundo do GRUB e `quiet splash` na linha do kernel.

---

## Perfis de máquina

O instalador detecta sozinho pelo DMI (o nome e o tipo de chassi), pela bateria
e pelo `lspci`.

| Perfil | Quando | Monitores | GPU | Energia |
|---|---|---|---|---|
| `desktop` | o meu Xeon com RX 6600 XT e dois monitores 1080p | DP-1 à esquerda, HDMI-A-1 à direita | `gpu-amd` (RADV) | sem TLP, pensado para jogar |
| `thinkpad` | o meu T430, e qualquer laptop (chassi portátil ou bateria presente) | eDP-1 em 1366x768, mais um monitor externo | `gpu-intel` | TLP, thermald, thinkfan e TrackPoint |
| `general` | o resto | `preferred, auto` | AMD se houver Radeon, senão Intel | sem TLP |

Os módulos ficam em `config/hypr/modules/`. O instalador só aponta
`profile-monitors.lua` e `profile-gpu.lua` para os do perfil escolhido. O
`docs/profiles.md` tem os detalhes.

---

## A área de trabalho

É um tiling que aceita mouse. As janelas novas entram e se arrumam sozinhas,
mas você pode puxar a borda para redimensionar ou segurar `ALT` e arrastar para
mover. Janelas pequenas, como as de arquivos, volume e rede, já abrem flutuando
e no centro. Jogos abrem em tela cheia, sem blur nem sombra.

A Waybar fica no topo. À esquerda estão a logo do Brummy (que abre o launcher),
os workspaces (clique para ir, role a roda para trocar), o contador `󰖰 N` de
janelas minimizadas e o título da janela ativa. O relógio fica no centro. À
direita vêm o uso do Claude, CPU, memória, GPU, temperatura, a bandeja, o volume
(a roda do mouse ajusta), rede, bateria, calendário e o ⏻ para desligar. Os
módulos de GPU, temperatura e bateria somem quando não fazem sentido, em vez de
deixar um buraco na barra.

As barras de título são opcionais. Com `brummy bars on`, cada janela ganha três
bolinhas à esquerda, na ordem do macOS: fechar, minimizar e maximizar. O símbolo
aparece quando o mouse passa por cima, e dois cliques na barra maximizam. O
tiling continua igual. Os detalhes, e o que isso custa, estão em
`docs/janelas-clicaveis.md`.

O Hyprland não tem minimizar. O que o Brummy faz é guardar a janela numa gaveta
(um workspace especial chamado `special:minimizado`) e trazer de volta pelo
`SUPER+SHIFT+M` ou pelo `󰖰` da barra. Se tiver mais de uma guardada, o wofi
pergunta qual.

O papel de parede padrão é uma foto que a NASA tirou da ISS. Tem mais
duas da NASA e três recortes de uma foto que eu tirei no Parque do Ibitipoca.
`brummy wallpaper next` troca.

---

## Atalhos

Esqueceu algum? `brummy help` mostra todos.

Teclado:

| Atalho | Ação | Atalho | Ação |
|---|---|---|---|
| `SUPER+Espaço` ou `SUPER+D` | launcher | `SUPER+Q` ou `SUPER+Enter` | terminal |
| `SUPER+E` | arquivos | `SUPER+B` | navegador |
| `SUPER+SHIFT+C` | editor (VSCodium) | `SUPER+L` | bloquear a tela |
| `SUPER+C` | fechar a janela | `SUPER+F` | tela cheia |
| `SUPER+V` | soltar a janela do tiling (e voltar) | `SUPER+SHIFT+S` | captura de tela |
| `SUPER+M` | minimizar | `SUPER+SHIFT+M` | trazer de volta a minimizada |
| `SUPER+J` / `SUPER+K` | próxima / anterior janela | `SUPER+SHIFT+Q` | sair do Hyprland |
| `SUPER+1..9` | ir para o workspace | `SUPER+SHIFT+1..9` | mandar a janela para o workspace |

As teclas de mídia, volume e brilho funcionam mesmo com a tela bloqueada.

Mouse:

| Gesto | Ação |
|---|---|
| puxar a borda da janela | redimensionar, sem tecla nenhuma |
| `SUPER` ou `ALT` e arrastar com o botão esquerdo | mover |
| `SUPER` ou `ALT` e arrastar com o botão direito | redimensionar |
| `SUPER` e a roda | trocar de workspace |
| `SUPER` e o clique do meio | fechar |
| `SUPER+SHIFT` e o clique direito | soltar do tiling (e voltar) |
| três dedos para o lado, no touchpad | trocar de workspace |

---

## O comando `brummy`

| Comando | O que faz |
|---|---|
| `brummy help` | atalhos e comandos, para não precisar decorar |
| `brummy apps` | o que veio instalado, por categoria |
| `brummy doctor` | o diagnóstico completo (explicado abaixo) |
| `brummy update` | tira um snapshot, roda o `pacman -Syu`, recompila os plugins do Hyprland e refaz os links |
| `brummy fix` | apaga links de config quebrados e refaz a parte do usuário |
| `brummy wallpaper list \| set <arquivo> \| next` | troca o papel de parede |
| `brummy hide [--list \| --undo]` | esconde do launcher os apps que não interessam |
| `brummy bars on \| off \| status` | liga ou desliga as barras de título (rode dentro da sessão) |
| `brummy snapshot list \| create <descrição> \| rollback` | pontos de restauração |
| `brummy extras` | instala os apps do AUR que faltam: os que falharam na instalação e os que a ISO pública não traz |
| `brummy uninstall` | tira os links e devolve os backups das suas configs |
| `brummy theme` | mostra onde mexer no tema |

Quando algo parece errado, eu começo pelo `brummy doctor`. Ele confere o perfil
ativo, os pacotes de que o visual depende, os links de config (um link apontando
para o vazio é o motivo mais comum de o login gráfico não entrar), a config em
Lua do Hyprland, o greetd, o tema escuro, o papel de parede, cada pacote do AUR
que falhou sem avisar na instalação, os snapshots, as barras de título, o bundle
dev, as coisas de laptop, o boot, a GPU e o KVM.

---

## Snapshots

O Arch é rolling release. Quase sempre o `pacman -Syu` passa sem problema.
Quando não passa, costuma ser do pior jeito possível: a sessão gráfica não sobe
e você fica olhando para um terminal.

Com o `/` em btrfs, o `install.sh` configura quatro coisas. O snapper cria e
gerencia os snapshots. O snap-pac tira um snapshot antes e outro depois de cada
`pacman`. O grub-btrfs coloca esses snapshots num submenu do GRUB, para você dar
boot num estado que funcionava. E uma limpeza automática guarda só os 10 mais
recentes.

```bash
brummy snapshot                      # lista
brummy snapshot create antes-do-driver
brummy snapshot rollback             # mostra o caminho de volta
```

O `/home` fica de fora dos snapshots do `/`, então voltar o sistema nunca desfaz
os seus arquivos. O passo a passo da restauração está em `docs/snapshots.md`.

---

## A ISO live

A ISO é feita com o archiso. Como ele só roda em Arch, a build acontece dentro de
um container Docker com Arch, o que permite construir a partir de qualquer
distro.

```
iso/build.sh                  roda no seu PC ou no GitHub Actions
  └─ docker run archlinux     com --privileged, porque o mkarchiso monta loop devices
       └─ builder/build-iso.sh
            ├─ aur-repo.sh      compila o AUR num repositório local, com cache
            ├─ gen-packages.sh  junta packages/*.packages na lista do archiso
            ├─ perfil           boot do releng e o airootfs do Brummy
            └─ mkarchiso        gera iso/out/brummy-AAAA.MM.DD-x86_64.iso
```

Para construir na sua máquina:

```bash
sudo apt install docker.io && sudo usermod -aG docker $USER   # depois, saia e entre de novo
./iso/build.sh                       # de 40 a 90 minutos na primeira vez
BRUMMY_ISO_SEM_DEV=1 ./iso/build.sh  # sem o bundle dev, para uma ISO menor
BRUMMY_ISO_PUBLICA=1 ./iso/build.sh  # para distribuir (explicado abaixo)
./iso/build.sh --no-cache            # recompila todos os pacotes do AUR
./iso/build.sh --shell               # abre um shell no container, para depurar
```

Pelo GitHub, é a aba Actions, workflow `iso`, "Run workflow". O script é o
mesmo. Os pacotes do AUR ficam em cache entre as builds, inclusive quando a build
falha (no começo não ficavam, e cada tentativa recompilava tudo). No fim, o run
lista o que ficou de fora.

Se a ideia for publicar a ISO, tem um detalhe. Alguns apps do AUR são binários
de terceiros que não podem ser redistribuídos. No modo público (a opção
`publica` no workflow), a build lê a licença de cada pacote e deixa os restritos
de fora, além dos que estão em `packages/iso-publica.exclui`. Toda build gera um
`LICENCAS.txt` dizendo o que entrou e por quê, e quem instala pega o resto
depois com `brummy extras`.

Para testar sem gravar nada:

```bash
./tools/vm.sh criar
./tools/vm.sh iso iso/out/brummy-*.iso
```

Um cuidado que a ISO exige: o sistema live carrega coisas que seriam perigosas
ou quebradas num sistema instalado. Por isso o Calamares roda o
`brummy-pos-instalacao` no sistema novo antes de terminar. Ele:

- coloca o kernel no `/boot`, que o mkarchiso deixa vazio;
- remove o que só serve ao live, como o chaveiro do pacman em memória, o journal
  em RAM e o initramfs do archiso;
- trava a conta root, porque o acesso é por `sudo`, como no Arch;
- cria o chaveiro do pacman de verdade e liga o multilib;
- troca o login automático do live pelo login com senha;
- aplica o Brummy no usuário que você criou, com o repositório em
  `~/brummy-linux`, que é um clone de verdade (o `git pull` funciona);
- coloca o fundo do GRUB e o splash do Plymouth.

O `iso/README.md` tem tudo sobre a ISO, inclusive o histórico de cada build que
quebrou até a primeira dar certo.

---

## Para quem quiser mexer

### Estrutura

```
brummy-linux/
  install.sh              o instalador (perfis e opções)
  packages/               listas de pacotes, usadas pelo install.sh e pela ISO
    base, dev, laptop, btrfs          vão pelo pacman
    aur, dev-aur, laptop-aur,
    android-aur                       vão pelo paru
    iso-publica.exclui/.permite       o que a ISO pública deixa de fora ou libera
  bin/                    o comando brummy e os helpers
    brummy-wallpaper-apply  aplica o papel de parede (fala as duas IPCs do hyprpaper)
    brummy-hide-apps        limpa o launcher
    brummy-minimizados      a gaveta das janelas minimizadas
    brummy-remove-preinstalls
  config/                 vira ~/.config/* por link simbólico
    hypr/hyprland.lua       a config principal (Lua, Hyprland 0.55+)
    hypr/modules/           perfis de monitor, GPU e trackpoint
    hypr/legacy/            a config .conf antiga, só para consulta
    waybar/                 config, estilo e os scripts dos módulos
    kitty/ wofi/ fish/ fastfetch/ nwg-dock-hyprland/ gtk-3.0/ gtk-4.0/ greetd/
    brummy/hidden-apps.list
  themes/wallpapers/      papéis de parede (o ORIGEM.md diz de onde veio cada um)
  boot/                   tema do Plymouth, o gerador de imagens e o fundo do GRUB
  iso/                    a ISO live com Calamares
    build.sh                o orquestrador (Docker)
    builder/                build-iso, aur-repo, gen-packages
    profile/                profiledef, airootfs e os pacotes que só a ISO usa
    calamares/              configuração e visual do instalador
  tools/
    check.sh                as checagens que dá para fazer sem instalar nada
    vm.sh                   cria, liga e acessa as VMs de teste
    host-keys.sh            libera a tecla SUPER do GNOME do host durante o teste
  .github/workflows/
    check.yml               check.sh e hyprland --verify-config, a cada push
    iso.yml                 a build da ISO, disparada à mão
  docs/                   as notas técnicas
```

### Checagens

```bash
./tools/check.sh
```

Em poucos segundos ele passa o shellcheck em todos os scripts, valida o JSON da
Waybar e do fastfetch e a sintaxe do Lua, e confere se o bloco das barras de
título tem o que o plugin exige, com e sem o plugin carregado. Também reprova
qualquer `hyprctl dispatch` escrito do jeito antigo, testa a gaveta de
minimizados com um `hyprctl` de mentira, confere a ISO (pacotes essenciais,
`install_dir`, o YAML do Calamares, a lista de exclusão) e roda cada subcomando
do `vm.sh` e do `brummy`.

No GitHub, a cada push, o mesmo `check.sh` roda junto com o `hyprland
--verify-config` num container Arch, uma vez para cada perfil. Se a config
estiver inválida, o commit fica vermelho, e não preciso abrir a VM para
descobrir.

### Testar numa VM

```bash
./tools/vm.sh deps                # o que instalar no host
./tools/vm.sh criar               # cria um disco novo
./tools/vm.sh achar               # procura discos de VM que você já tem
./tools/vm.sh overlay <disco>     # liga um deles sem escrever nele
./tools/vm.sh enviar              # manda o repositório para dentro da VM
./tools/vm.sh ssh                 # abre um terminal na VM, sem depender de atalho
./tools/host-keys.sh liberar      # solta o SUPER do GNOME do host (e devolve depois)
```

O roteiro completo, e como sair de cada enrosco, está em `docs/teste-vm.md`.

### O que eu aprendi errando

Não confio mais em documentação de terceiros sobre o Hyprland. Uma função
`hl.print` que não existe derrubou o meu login. Hoje a config sai do código-fonte
e passa pelo `--verify-config` no CI antes de chegar em qualquer máquina.

Com a config em Lua, o `hyprctl dispatch` recebe Lua. Escrever `hyprctl dispatch
workspace e+1`, como antes, falha sem dar erro nenhum. O certo é `hyprctl
dispatch 'hl.dsp.focus({ workspace = "e+1" })'`, e o `check.sh` reprova o
formato antigo. Foi assim que eu descobri que a roda do mouse nos workspaces
estava quebrada fazia quase duas semanas.

Nada no autostart pode derrubar a sessão. Cada comando roda dentro de um `pcall`.

E um link de config quebrado impede o login. Por isso existem o `brummy fix` e a
checagem no `doctor`.

---

## Quando algo dá errado

| Sintoma | O que fazer |
|---|---|
| O login gráfico não entra | num terminal (`Ctrl+Alt+F2`), rode `brummy fix` e depois `brummy doctor` |
| Mexi numa config e a sessão quebrou | `hyprland --verify-config` aponta a linha |
| Uma atualização quebrou o sistema | no GRUB, entre em "Arch Linux snapshots" e siga o `docs/snapshots.md` |
| As barras de título sumiram depois de atualizar | `brummy bars on`, dentro da sessão |
| Um app do AUR não veio | `brummy extras` instala o que falta; `brummy doctor` mostra a lista |
| Os apps GTK abrem claros | o `brummy doctor` confere o `color-scheme`; `./install.sh --user-only` reaplica |
| Apareceu coisa estranha no launcher | `brummy hide` |
| Quero voltar às minhas configs antigas | `brummy uninstall` |

---

## Documentação

| Nota | Assunto |
|---|---|
| `docs/install.md` | os caminhos de instalação, do mais fácil ao mais trabalhoso |
| `docs/profiles.md` | perfis de máquina, monitores e GPU |
| `docs/dev.md` | o bundle de desenvolvimento |
| `docs/boot.md` | o GRUB e o Plymouth com a logo |
| `docs/hyprland-lua.md` | a migração para Lua e como validar |
| `docs/janelas-clicaveis.md` | as barras de título, o minimizar e como isso é testado |
| `docs/snapshots.md` | snapper e grub-btrfs, e como voltar a um snapshot |
| `docs/teste-vm.md` | o roteiro de teste em VM |
| `docs/extensions.md` | extensões do GNOME (como o Astra Monitor) e o que usar no lugar |
| `iso/README.md` | a ISO: como funciona, como construir e o histórico das builds |

---

## Roadmap

- [x] v1: a estrutura, os perfis, o bundle dev, o boot com a logo e o Nautilus
- [x] v1.1: gravei o primeiro boot em vídeo e corrigi o que apareceu. A config
      foi para Lua (o formato `.conf` sai na 0.57), e arrumei o papel de parede,
      o tema escuro dos apps GTK4, o cursor, os buracos da Waybar, os apps
      estranhos no launcher e a logo do Brummy no fastfetch
- [x] v1.1a: `hyprland --verify-config` na VM respondeu `config ok`
- [x] v1.2: o `./install.sh` completo rodou numa VM limpa. Vieram junto o CI com
      shellcheck e verify-config para cada perfil, os snapshots antes de
      atualizar, o `brummy uninstall` e o log da instalação
- [x] v1.3: as barras de título e o minimizar com o `󰖰` na Waybar. De quebra,
      consertei a roda do mouse nos workspaces, que estava com a sintaxe antiga
- [x] v1.4: a ISO live com o Calamares. Revisei tudo contra o código do archiso
      e foram quatro builds no GitHub Actions até a primeira sair inteira
- [ ] v1.4a: testar a ISO de ponta a ponta numa VM, com boot em BIOS e em UEFI,
      instalação pelo Calamares e o sistema instalado subindo com a cara do Brummy
- [ ] v1.3a: ver as barras de título funcionando numa VM
- [ ] v1.2a: rodar o `./install.sh` no meu hardware, o T430 (`thinkpad`) e o
      desktop com a RX 6600 XT (`desktop`)
- [ ] v1.5: btrfs com subvolumes na ISO, para quem instala por ela também ter
      snapshots; o menu de boot da ISO com o nome do Brummy; e a ISO publicada
      para download
- [ ] algum dia: um Linux From Scratch, ou um kernel próprio, só para aprender.
      Isso vai para outro repositório

---

## Licença e créditos

A licença é MIT (veja o `LICENSE`).

A ideia veio do [Omarchy](https://omarchy.org), do David Heinemeier Hansson. A
foto do Parque Estadual do Ibitipoca é minha, e as outras três são da NASA, em
domínio público. As origens de cada uma estão em `themes/wallpapers/ORIGEM.md`.

O resto é trabalho dos outros: Arch Linux, Hyprland, archiso, Calamares e quem
mantém cada pacote do AUR que o Brummy usa. Eu só junto as peças.

Feito para usar todo dia, e mexer por prazer.
