#!/usr/bin/env python3
"""Brummy boot assets — gera halo glow, dots, barra e fundo GRUB a partir da logo.

Uso:  python3 make-assets.py [logo.png]   (default: assets/logo.png)
Saída: assets/glow.png, dot.png, bar-bg.png, bar-fill.png, grub-background.png + .assets-ok

A logo é a que o dbrum enviou (B branco com glow/orbita em fundo escuro).
Se assets/logo.png não existir, o script falha com instrução — salve a imagem
anexada no chat como brummy-linux/boot/assets/logo.png e rode de novo.
"""
import os
import sys

try:
    from PIL import Image, ImageFilter, ImageDraw
except ImportError:
    print("ERRO: Pillow não instalado (Arch: python-pillow). Rode ./install.sh que ele instala.")
    sys.exit(1)

HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.join(HERE, "assets")
LOGO = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ASSETS, "logo.png")

if not os.path.isfile(LOGO):
    print(f"ERRO: logo não encontrada: {LOGO}")
    print("Salve a logo enviada no chat como brummy-linux/boot/assets/logo.png e rode de novo.")
    sys.exit(1)

os.makedirs(ASSETS, exist_ok=True)
logo = Image.open(LOGO).convert("RGBA")
print(f"logo: {logo.size}")

# --- glow.png: halo respirável (cópia ampliada + blur pesado + boost) ---
w, h = logo.size
canvas = Image.new("RGBA", (int(w * 1.6), int(h * 1.6)), (0, 0, 0, 0))
big = logo.resize((int(w * 1.3), int(h * 1.3)), Image.LANCZOS)
canvas.alpha_composite(big, ((canvas.width - big.width) // 2, (canvas.height - big.height) // 2))
glow = canvas.filter(ImageFilter.GaussianBlur(radius=max(w, h) // 8))
# boost de brilho no halo
px = glow.load()
for y in range(0, glow.height, 2):
    for x in range(0, glow.width, 2):
        r, g, b, a = px[x, y]
        px[x, y] = (min(255, r + 40), min(255, g + 40), min(255, b + 50), int(a * 0.85))
glow.save(os.path.join(ASSETS, "glow.png"))
print("glow.png ok")

# --- dot.png: ponto de loading (14px, branco com borda suave) ---
dot = Image.new("RGBA", (28, 28), (0, 0, 0, 0))
d = ImageDraw.Draw(dot)
d.ellipse((4, 4, 24, 24), fill=(255, 255, 255, 255))
dot = dot.filter(ImageFilter.GaussianBlur(radius=1.2))
dot.save(os.path.join(ASSETS, "dot.png"))
print("dot.png ok")

# --- barra de progresso: fundo escuro + preenchimento claro (440x10) ---
bar_bg = Image.new("RGBA", (440, 10), (0, 0, 0, 0))
ImageDraw.Draw(bar_bg).rounded_rectangle((0, 0, 440, 10), radius=5, fill=(255, 255, 255, 38))
bar_bg.save(os.path.join(ASSETS, "bar-bg.png"))
bar_fill = Image.new("RGBA", (440, 10), (0, 0, 0, 0))
dr = ImageDraw.Draw(bar_fill)
for x in range(440):
    t = x / 439
    v = int(200 + 55 * t)  # gradiente 200 -> 255
    dr.line([(x, 0), (x, 10)], fill=(v, v, 255, 255))
mask = Image.new("L", (440, 10), 0)
ImageDraw.Draw(mask).rounded_rectangle((0, 0, 440, 10), radius=5, fill=255)
bar_fill.putalpha(mask)
bar_fill.save(os.path.join(ASSETS, "bar-fill.png"))
print("bar-bg/fill ok")

# --- grub-background.png: 1920x1080 escuro + glow radial + logo centralizada ---
W, H = 1920, 1080
bg = Image.new("RGBA", (W, H), (5, 5, 10, 255))
halo = Image.new("RGBA", (W, H), (0, 0, 0, 0))
hd = ImageDraw.Draw(halo)
hd.ellipse((W // 2 - 480, H // 2 - 480, W // 2 + 480, H // 2 + 480), fill=(90, 90, 140, 255))
halo = halo.filter(ImageFilter.GaussianBlur(radius=220))
bg.alpha_composite(halo)
fit = logo.copy()
fit.thumbnail((760, 760), Image.LANCZOS)
bg.alpha_composite(fit, ((W - fit.width) // 2, (H - fit.height) // 2 - 20))
bg.convert("RGB").save(os.path.join(ASSETS, "grub-background.png"))
print("grub-background.png ok")

open(os.path.join(ASSETS, ".assets-ok"), "w").write("ok\n")
print("Assets prontos em", ASSETS)
