# Brummy ISO — esqueleto

Gera uma ISO live que **já é o Brummy**, com instalador gráfico Calamares.
A pessoa baixa, dá boot, olha o sistema rodando, clica em "Instalar" e pronto.

> **Estado: esqueleto que ainda não foi construído nenhuma vez.** A estrutura,
> os scripts e as configs estão aqui e passam em `bash -n`, mas a primeira build
> vai quebrar em algum lugar — sempre quebra. Veja "O que esperar" no fim.

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

**O `install.sh` não roda na máquina de quem instala.** Ele roda uma vez, no
live, em modo `--user-only` (configs, tema, helpers — sem tocar em pacotes),
e o resultado é copiado junto com o resto do sistema.

## Construir

```bash
sudo apt install docker.io
sudo usermod -aG docker $USER      # relogue depois disto
./iso/build.sh
```

Primeira build: 40-90 minutos (a maior parte é compilar AUR). As seguintes usam
o cache em `iso/.cache/` e caem para uns 20.

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
2. **Tamanho.** Com `dev.packages` dentro passa de 4GB. Se incomodar, tire
   `dev.packages` do `LISTS` no `gen-packages.sh`.
3. **`install_dir`.** Está `brummy` no `profiledef.sh` e o `unpackfs.conf`
   aponta para `/run/archiso/bootmnt/brummy/x86_64/airootfs.sfs`. Mudou um,
   mude o outro — é o erro nº1 de quem monta ISO com Calamares.
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
