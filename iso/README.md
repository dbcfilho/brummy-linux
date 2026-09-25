# Brummy ISO

Gera uma ISO live que **já é o Brummy**, com instalador gráfico Calamares.
A pessoa baixa, dá boot, olha o sistema rodando, clica em "Instalar" e pronto.

> **Estado: revisado, ainda não construído.** Uma revisão contra o código do
> archiso achou dez problemas que só apareceriam na primeira build ou, pior, no
> sistema de quem instalou (tabela abaixo). O `tools/check.sh` confere o que dá
> sem Docker; o resto é a build de verdade — pelo GitHub Actions ou local.

## Como funciona

```
iso/build.sh              você roda isto no Debian
   └─ docker run archlinux (privilegiado, porque mkarchiso monta loop devices)
        └─ builder/build-iso.sh
             ├─ aur-repo.sh      AUR → repositório pacman local
             ├─ gen-packages.sh  packages/*.packages → packages.x86_64
             ├─ monta o perfil a partir do releng do archiso
             └─ mkarchiso        → iso/out/brummy-*.iso
```

Decisões que valem entender:

**Docker.** `archiso` só roda em Arch e você está no Debian. É o mesmo caminho
que o `omarchy-iso` faz.

**Instalação offline por `unpackfs`.** O Calamares copia o squashfs do live
direto para o disco, em vez de baixar pacotes na hora. Duas consequências boas
(instala sem internet; o que a pessoa vê é exatamente o que ela instala) e uma
ruim: a ISO fica com 3-4GB, e o sistema recém-instalado precisa de um
`pacman -Syu` para ficar em dia.

**`packages/` continua sendo a fonte única.** A ISO não tem lista própria de
pacotes: o `gen-packages.sh` gera a lista do archiso a partir dos mesmos
arquivos que o `install.sh` usa. Mexeu em `packages/base.packages`, mexeu na ISO.

**O live não é o sistema instalado, mesmo sendo copiado dele.** O unpackfs
copia o squashfs como está, e o squashfs carrega coisas de live. Quem arruma é
o `brummy-pos-instalacao`, que o Calamares roda no chroot em duas etapas
(`shellprocess@brummy` e `shellprocess@brummy-grub`). Ele também aplica a
camada do Brummy (`install.sh --user-only`) no usuário criado na instalação:
a que o live aplicou no boot mora na RAM, não no squashfs.

### O que a revisão achou (e onde foi corrigido)

| Problema | Efeito | Correção |
|---|---|---|
| listas sem `base`, `linux`, `syslinux`, `grub`, `efibootmgr` | a build nem sai | `profile/packages.sistema` |
| `mkarchiso` apaga o `/boot` do squashfs | instalado sem kernel, não boota | `brummy-pos-instalacao` copia o `vmlinuz` |
| airootfs do releng: `root` sem senha, `sshd` com `PermitRootLogin yes`, autologin de root no tty1 | root aberto no sistema instalado | `build-iso.sh` só leva o necessário do releng; `profile/airootfs/etc/shadow` trava o root |
| networkd + iwd + resolved do releng | brigam com o NetworkManager | fora da lista do releng |
| `pacman-init` monta o chaveiro em tmpfs | pacman sem chaveiro a cada boot | removido no pós-instalação, chaveiro criado de verdade |
| `mkinitcpio.conf.d/archiso.conf` | initramfs do live no instalado | removido antes do `initcpiocfg` |
| camada de usuário aplicada no boot do live | usuário instalado sem nada do Brummy | `install.sh --user-only` no chroot, com `dbus-run-session` |
| greetd do live copiado | autologin num usuário que não existe | greetd do `config/` no pós-instalação |
| módulo `packages` com `skip_if_no_internet` | instalar offline deixava Calamares e archiso | `false`; lista gerada do `packages.live` |
| `/etc/pacman.conf` do instalado sem multilib | Steam sem atualização | multilib no pós-instalação |

Também: `--no-cache` era ignorado, o cache do AUR se perdia a cada build, um
`FALHARAM.txt` velho tirava da ISO pacotes que agora constroem, `-it` quebrava
sem terminal, e a build seguia 40 minutos mesmo sem o Calamares.

## Construir

```bash
sudo apt install docker.io
sudo usermod -aG docker $USER      # relogue depois disto
./iso/build.sh
```

Primeira build: 40-90 minutos (a maior parte é compilar AUR). As seguintes usam
o cache em `iso/.cache/` (pacman e AUR) e caem para uns 20.
`BRUMMY_ISO_SEM_DEV=1 ./iso/build.sh` deixa o bundle dev de fora.

### Pelo GitHub, sem Docker local

Aba **Actions → iso → Run workflow**. Roda o mesmo `./iso/build.sh` num runner,
com cache do AUR entre runs, e a ISO sai como artefato (3 dias). Por padrão sem
o bundle dev; marque a opção para incluir.

## Testar sem gravar nada

```bash
qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 \
  -bios /usr/share/ovmf/OVMF.fd \
  -cdrom iso/out/brummy-*.iso
```

Teste os dois modos de boot: com `-bios OVMF.fd` (UEFI) e sem (BIOS legado).
Vale também um disco de mentira (`-drive file=teste.qcow2`) para o Calamares ter
onde instalar de verdade.

## Gravar no pendrive

```bash
sudo dd if=iso/out/brummy-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

(`lsblk` antes, para não errar o `/dev/sdX`.)

## O que esperar de problema na primeira build

Coisas que quase sempre precisam de ajuste, em ordem de probabilidade:

1. **AUR quebrando.** `claude-desktop`, `helium-browser-bin` e afins mudam de
   fonte e falham. O `aur-repo.sh` deixa cada um falhar sozinho e anota em
   `FALHARAM.txt`; o `build-iso.sh` tira os falhados da lista. A ISO sai sem
   eles e o usuário instala depois. Se `calamares` falhar, aí sim para tudo.
2. **Tamanho.** Com `dev.packages` dentro passa de 4GB. `BRUMMY_ISO_SEM_DEV=1`
   deixa ele de fora (o CI já faz isso por padrão).
3. **`install_dir`.** Está `brummy` no `profiledef.sh` e o `unpackfs.conf`
   aponta para `/run/archiso/bootmnt/brummy/x86_64/airootfs.sfs`. O
   `tools/check.sh` reprova se os dois se desencontrarem.
4. **Plymouth no initcpio.** O `initcpiocfg.conf` já põe o hook `plymouth`
   depois do `udev`. Se o boot do sistema instalado ficar sem splash, é aqui.
5. **greetd no sistema instalado.** O `services-systemd.conf` liga o greetd e
   desliga o `brummy-live-setup`. Se a máquina instalada bootar em texto, veja
   se o serviço foi mesmo habilitado.
6. **Slideshow do Calamares.** O `show.qml` usa a API 2; se a versão do
   Calamares reclamar, é só apagar a linha `slideshow` do `branding.desc`.

## Alternativa mais simples, se isto travar

Se a ISO virar um poço sem fundo, o caminho do Omarchy continua valendo: ISO
que sobe um instalador de texto (`archinstall` com um JSON de perfil) e roda o
`install.sh` no fim. Menos bonito, muito menos peça móvel.

## Depois da primeira build

- Particionamento: o Calamares usa ext4 por padrão, então quem instala pela ISO
  fica sem os snapshots do `docs/snapshots.md`. Btrfs com subvolumes no
  `partition.conf`/`mount.conf` é o próximo passo, depois de a ISO bootar.
- O menu de boot da ISO ainda é o do releng ("Arch Linux install medium").
