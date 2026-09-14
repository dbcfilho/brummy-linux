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
