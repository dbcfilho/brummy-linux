# Teste do Brummy na VM

Roteiro para validar a v1.1 (config em Lua, wallpaper, tema escuro, Waybar,
launcher limpo) antes de pensar em ISO.

## 0. Antes de tudo: snapshot

O `install.sh` mexe em `/etc/greetd`, GRUB, mkinitcpio e gsettings. Se o login
gráfico quebrar, você quer voltar em 30 segundos, não reinstalar.

- **virt-manager:** VM → Snapshots → `+` → nome `antes-v1.1`
- **Boxes:** clique direito na VM → Snapshots → Novo
- **QEMU na mão:** `qemu-img snapshot -c antes-v1.1 disco.qcow2` (com a VM desligada)

## 1. Loop rápido — só a config do Hyprland (2 minutos)

Isso pega quase todo erro sem instalar nada. Leve só a pasta `config/hypr` para
a VM e rode lá dentro:

```bash
hyprland --verify-config
```

Saída limpa = os nomes das opções batem com a sua versão do Hyprland.
Saída com erro = o erro diz arquivo, linha e opção; conserte e rode de novo.

Se já estiver numa sessão Hyprland rodando:

```bash
hyprctl reload        # aplica sem deslogar
```

> `luac -p` só pega erro de sintaxe Lua. Nome de opção errado (que foi o que
> apareceu no primeiro boot) **só** o `--verify-config` pega.

## 2. Instalação completa

```bash
cd brummy-linux
./install.sh                 # auto-detecta o perfil
brummy doctor                # checagem pós-instalação
```

O `doctor` agora responde, entre outras coisas:

- versão do Hyprland e se existe `start-hyprland`
- se o `hyprland.lua` está no lugar e se sobrou um `hyprland.conf` solto
- se o greetd usa `start-hyprland`
- `color-scheme` (tem que conter `dark`) e o tema de cursor
- se o wallpaper atual existe de verdade

Depois: **logout e volte pela tela de login** (não só `hyprctl reload`) — é o
único jeito de testar o greetd, o autostart e o wallpaper no caminho real.

## 3. Checklist na tela

Cada item abaixo estava quebrado no vídeo `brummy-firstboot.mp4`:

- [ ] **Sem caixa vermelha** de erro no topo da tela
- [ ] **Sem o aviso** "started without start-hyprland"
- [ ] **Sem o aviso** de formato `.conf` deprecado
- [ ] **Wallpaper do Ibitipoca**, não o fundo padrão do Hyprland ("Read the wiki")
- [ ] **Dock aparece** ao encostar o mouse embaixo
- [ ] **Waybar sem buracos**: em VM, GPU e temperatura simplesmente não aparecem
- [ ] **Nautilus (SUPER+E) abre escuro**, não branco
- [ ] **Cursor Bibata**, não o X preto do padrão
- [ ] **SUPER+D sem lixo**: nada de Avahi, xgps, Qt V4L2, OpenJDK Console
- [ ] **`fastfetch` mostra a logo do Brummy**, não a do Arch
- [ ] **SUPER+SHIFT+S** abre a captura de tela (hyprshot → satty)
- [ ] **SUPER+5..9** trocam de workspace (antes só ia até o 4)

## 4. Se o login gráfico quebrar

A tela preta no boot quase sempre é greetd ou Hyprland caindo. Você não fica
preso: **Ctrl+Alt+F2** cai num TTY de texto, e de lá:

```bash
sudo systemctl stop greetd        # para de tentar a tela de login
hyprland --verify-config          # o erro está aqui, quase sempre
journalctl -b -u greetd | tail -40
journalctl -b --user -t Hyprland | tail -40
```

Para voltar ao estado anterior sem reinstalar:

```bash
# o install.sh guarda backup de tudo que substituiu
ls -d ~/.config/*.bak-brummy-*
sudo systemctl disable greetd     # volta a bootar em texto
```

E, no pior caso, restaure o snapshot do passo 0.

## 5. O que anotar para a próxima rodada

Enquanto testa, vale anotar: quanto tempo levou o `install.sh`, quais pacotes o
pacman/AUR pulou (ele imprime `[brummy] pacman pulou: X`), e o que ficou feio
mas não quebrado. É essa lista que vira a v1.2 — e é ela que decide o que entra
na ISO.

## GNOME Boxes não serve para isto

O primeiro teste de verdade (14/09/2026) travou menos no Brummy e mais no Boxes:

- **Teclado embaralhado.** Digitar virava `9;9u9;9u9;9u...` na tela. O Boxes
  manda teclas por SPICE assumindo o mapa do convidado, e com ABNT2 isso vira
  ruído. Nem `sudo localectl set-keymap br-abnt2` resolve, porque o problema
  está na camada de transporte, não no convidado.
- **Sem controle de vídeo.** Não dá para ligar aceleração 3D nem escolher o
  modelo de GPU virtual. Testar um compositor Wayland assim é testar no escuro.
- **Transferência de arquivo na unha.** Meia hora de `scp` arquivo por arquivo.

Use o `tools/vm.sh`, que é QEMU direto com as opções que importam
(`virtio-vga-gl` + `gtk,gl=on` para 3D de verdade, scancode cru para o teclado
funcionar, SSH na porta 2222):

```bash
./tools/vm.sh criar                       # cria o disco uma vez
./tools/vm.sh iso ~/Downloads/archlinux.iso
./tools/vm.sh rodar                       # depois de instalado
./tools/vm.sh ssh                         # entra sem mexer na janela
```

E pare de usar `scp`: com o repo no GitHub, dentro da VM é

```bash
git clone https://github.com/dbcfilho/brummy-linux.git   # uma vez
cd brummy-linux && git pull && ./install.sh              # a cada rodada
```

Se preferir interface gráfica, o **virt-manager** (`sudo apt install
virt-manager`) dá os mesmos controles do QEMU numa janela — só o Boxes que não.

### Parou em ">>Start PXE over IPv4"?

É o firmware errado para aquele disco, não um disco quebrado. Um sistema
instalado em BIOS legado não boota em UEFI, e vice-versa: o firmware não acha
bootloader nenhum e cai no boot por rede. A tela mostra antes:

```
BdsDxe: failed to load Boot0001 "UEFI Misc Device" ... : Not Found
>>Start PXE over IPv4.
```

O `tools/vm.sh` usa BIOS no `rodar` (é como o GNOME Boxes instala) e UEFI no
`iso` (instalação nova). Para inverter:

```bash
BRUMMY_VM_UEFI=1 ./tools/vm.sh rodar <disco>    # força UEFI
BRUMMY_VM_UEFI=0 ./tools/vm.sh iso <arquivo>    # força BIOS
```

Para descobrir em qual modo uma VM do Boxes foi instalada, olhe a primeira tela
do boot dela: **SeaBIOS** = BIOS legado, **TianoCore** = UEFI.
