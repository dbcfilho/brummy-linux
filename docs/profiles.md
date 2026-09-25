# Brummy — perfis de máquina

Base é igual em todo PC (Hyprland macOS híbrido + Waybar + bundle). O que muda por perfil é **monitores + GPU + energia**, escolhido pelo `install.sh`:

| Perfil | Quando | Monitores | GPU | Energia |
|---|---|---|---|---|
| `desktop` | Xeon + RX 6600 XT, 2x 1080p | DP-1 esq + HDMI-A-1 dir + fallback | `gpu-amd` (RADV/radeonsi) | gaming, sem TLP |
| `thinkpad` | T430 / qualquer laptop (auto via nome ou tipo de chassi no DMI, ou bateria) | eDP-1 1366x768 + fallback externo | `gpu-intel` (i965) | TLP + thermald + thinkfan |
| `general` | resto / hardware desconhecido | `preferred auto` tudo | auto (AMD discreta? RADV : Intel) | sem TLP |

## Uso

```bash
./install.sh                            # auto-detecta
./install.sh --profile desktop          # força desktop
./install.sh --profile thinkpad         # força T430/laptop
./install.sh --profile general          # neutro
./install.sh --no-dev                   # sem bundle dev
./install.sh --with-android             # + Android Studio (~1GB)
```

O instalador cria dois links (gerados, pode ignorar no git):
`~/.config/hypr/conf.d/profile-monitors.conf` e `profile-gpu.conf` → arquivos em `config/hypr/conf.d/`.
`brummy doctor` mostra o perfil ativo no topo.

## Detalhes por máquina

**Desktop dbrum** (Xeon E5-2670 v3 24 threads, 31 GiB, RX 6600 XT, M24CAB 24" + 2270W 22"):
- Gaming e multilib já no base; workspaces 1→DP-1, 2→HDMI-A-1 (comente em `monitors-desktop.conf` se não curtir).
- Conectores podem aparecer como DP-2/HDMI-A-2 — confira com `hyprctl monitors` e ajuste.

**ThinkPad T430** (Ivy Bridge, HD 4000, LVDS):
- Sem driver `xf86-video-intel` de propósito (modesetting do kernel é o recomendado hoje).
- HD 4000 não tem Vulkan nativo — `vulkan-intel` + lavapipe do mesa cobrem o básico; Hyprland roda, mas reduza blur se pesar (`decoration.blur.enabled = false`).
- Se seu T430 for HD+ **1600x900**, troque a linha comentada em `monitors-thinkpad.conf`.
- TrackPoint com scroll no botão do meio já em `trackpoint.conf`.
- TLP entra em conflito com `power-profiles-daemon` — o instalador mascara o PPD no perfil thinkpad.
- thinkfan: suba o serviço e calibre (`/etc/thinkfan.yaml`) — o instalador tenta enable, mas cada T430 tem curva própria.
