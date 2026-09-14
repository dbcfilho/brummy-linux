# Brummy — boot com a logo (GRUB + Plymouth)

A logo (B branco com glow/orbita) aparece em dois momentos:

1. **GRUB** (menu): fundo estático 1920x1080 gerado com glow radial + logo centralizada.
   GRUB não anima — a "luz carregando" entra no passo 2.
2. **Plymouth** (splash pós-GRUB): logo central + **halo respirando** (pulso de luz via
   `SetRefreshFunction`), 5 dots dançando e barra de progresso fina. É o efeito de
   "sistema carregando" que você pediu.

## Ativar

```bash
# 1. Salve a logo enviada no chat como:
boot/assets/logo.png

# 2. Gere os assets (halo, dots, barra, fundo GRUB):
python3 boot/make-assets.py

# 3. Instale só o boot (ou ./install.sh completo):
./install.sh --boot-only
```

O instalador: copia o tema para `/usr/share/plymouth/themes/brummy/`,
ativa com `plymouth-set-default-theme -R brummy` (adiciona o hook ao mkinitcpio e
regenera o initramfs), põe o fundo no GRUB (`/boot/grub/brummy-background.png`),
força `quiet splash` no kernel e regenera `grub.cfg`.

## Notas

- T430 (BIOS/legacy) e desktop (UEFI) usam o mesmo `grub.cfg` — o instalador não
  reinstala o GRUB no MBR/ESP, só regenera o config. Se o GRUB ainda não estiver
  instalado na máquina, instale antes (grub + efibootmgr/os-prober conforme o caso).
- Sem `assets/logo.png` o boot é pulado com aviso — nada quebra.
- `brummy doctor` mostra o tema Plymouth ativo.
