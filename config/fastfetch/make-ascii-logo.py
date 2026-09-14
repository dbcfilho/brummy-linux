#!/usr/bin/env python3
"""Gera o logo ASCII do Brummy para o fastfetch a partir de boot/assets/logo.png.

Uso:  python3 config/fastfetch/make-ascii-logo.py [largura] [limiar]
Saída: config/fastfetch/brummy.txt (com o placeholder $1 de cor do fastfetch)

Truque dos meios-blocos: cada caractere carrega DOIS pixels verticais
(▀ em cima, ▄ embaixo, █ nos dois), então a resolução vertical dobra e o
desenho sai nítido em vez de borrado.
"""
import sys, pathlib
from PIL import Image

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent
SRC = REPO / "boot" / "assets" / "logo.png"
DST = HERE / "brummy.txt"

WIDTH = int(sys.argv[1]) if len(sys.argv) > 1 else 54
THRESH = float(sys.argv[2]) if len(sys.argv) > 2 else 0.45

img = Image.open(SRC).convert("RGBA")
rows = max(2, round(WIDTH * img.height / img.width))
rows += rows % 2                      # par: dois pixels por linha de texto
img = img.resize((WIDTH, rows), Image.LANCZOS)

def on(x, y):
    r, g, b, a = img.getpixel((x, y))
    lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255
    return (a / 255) * lum >= THRESH

lines = []
for y in range(0, rows, 2):
    row = []
    for x in range(WIDTH):
        t, b = on(x, y), on(x, y + 1)
        row.append("█" if t and b else "▀" if t else "▄" if b else " ")
    lines.append("".join(row).rstrip())

while lines and not lines[0].strip():
    lines.pop(0)
while lines and not lines[-1].strip():
    lines.pop()

DST.write_text("\n".join("$1" + l for l in lines) + "\n", encoding="utf-8")
print(f"{DST} — {WIDTH}x{len(lines)} linhas")
