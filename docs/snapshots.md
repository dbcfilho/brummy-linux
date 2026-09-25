# Snapshots: a rede de segurança das atualizações

Arch é rolling. Quase sempre o `pacman -Syu` passa liso, mas quando não passa o
sintoma costuma ser o pior possível: a sessão gráfica não sobe. Com o `/` em
**btrfs**, o Brummy tira um snapshot antes e outro depois de cada transação do
pacman, e dá para dar boot direto num snapshot pelo GRUB.

## O que o `install.sh` faz

Só quando `findmnt -no FSTYPE /` diz `btrfs` (e sem `--no-snapshots`):

| Peça | Papel |
|---|---|
| `snapper` | cria e gerencia os snapshots do `/` (config `root`) |
| `snap-pac` | gancho do pacman: snapshot *pre* e *post* em toda transação |
| `grub-btrfs` + `grub-btrfsd` | põe os snapshots num submenu do GRUB, atualizado sozinho |
| `snapper-cleanup.timer` | apaga os antigos: guarda 10 (5 "importantes") |

A lista de pacotes está em `packages/btrfs.packages`.

O `archinstall` com btrfs cria o subvolume `@.snapshots` montado em
`/.snapshots`, e o `snapper create-config` recusa diretório existente. O
instalador segue a receita da Arch Wiki: desmonta, deixa o snapper criar a
config, apaga o subvolume que ele criou e remonta o `@.snapshots` original.

Sem btrfs não há nada automático — o instalador e o `brummy doctor` avisam.
Numa instalação nova, escolha btrfs no archinstall.

## No dia a dia

```bash
brummy snapshot                     # lista
brummy snapshot create antes-de-mexer-no-grub
brummy update                       # já sai protegido pelo snap-pac
brummy snapshot rollback            # mostra o caminho de volta
```

## Voltando no tempo

1. Reinicie. No GRUB, entre em **Arch Linux snapshots** e escolha um snapshot
   de antes do problema. Ele sobe **só-leitura** — serve para confirmar que
   ali estava bom, não para trabalhar.
2. Descubra o número dele: `brummy snapshot list`.
3. Monte a raiz do btrfs (o subvolume de topo, id 5) e troque o `@`:

```bash
sudo mount -o subvolid=5 /dev/<sua-partição> /mnt     # lsblk -f para achar
sudo mv /mnt/@ /mnt/@.quebrado-$(date +%F)
sudo btrfs subvolume snapshot /mnt/@.snapshots/<N>/snapshot /mnt/@
```

4. **Antes de reiniciar**, confira o `fstab` do novo `@`:

```bash
grep ' / ' /mnt/@/etc/fstab
```

Se a linha do `/` tiver `subvolid=256` (o archinstall costuma pôr), apague só o
`subvolid=...,` e deixe `subvol=/@`. O `@` novo ganhou outro id; montando por id,
o boot procura o subvolume antigo. O `brummy doctor` avisa quando isso existe.

5. `sudo umount /mnt && reboot`. Deu tudo certo por uns dias? Apague o antigo:
   `sudo btrfs subvolume delete /mnt/@.quebrado-<data>` (com `/mnt` montado de
   novo como no passo 3).

`/home` fica em `@home`, fora dos snapshots do `/`: voltar o sistema nunca
desfaz seus arquivos.
