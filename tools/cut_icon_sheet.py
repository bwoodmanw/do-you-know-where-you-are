"""Cut a sheet of 12 Lobby icons (4 across, 3 down, the order in
STYLE_UPGRADE.md part C) into one 512 x 512 picture each, trimmed and
centred, in art/ui-icons/<name>.png.

    python tools/cut_icon_sheet.py art/ui-icons/sheet.png

A transparent sheet stays transparent; on a plain background the corner
color is made transparent (anything close to it).
"""
import os
import sys
from PIL import Image

NAMES = ["quick", "solo", "party", "characters", "shop", "quests", "plushies", "invite", "join", "emote", "photo", "help"]
COLS, ROWS, OUT = 4, 3, 512


def clear_background(im):
    px = im.load()
    w, h = im.size
    bg = px[2, 2]
    if bg[3] < 20:
        return im  # already transparent
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2]) < 40:
                px[x, y] = (r, g, b, 0)
    return im


def cut(sheet_path):
    sheet = Image.open(sheet_path).convert("RGBA")
    w, h = sheet.size
    out_dir = os.path.dirname(sheet_path) or "."
    for i, name in enumerate(NAMES):
        c, r = i % COLS, i // COLS
        cell = sheet.crop((c * w // COLS, r * h // ROWS, (c + 1) * w // COLS, (r + 1) * h // ROWS))
        cell = clear_background(cell)
        box = cell.getbbox()
        if box:
            cell = cell.crop(box)
        side = max(cell.size)
        square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        square.paste(cell, ((side - cell.size[0]) // 2, (side - cell.size[1]) // 2))
        square = square.resize((int(OUT * 0.9), int(OUT * 0.9)), Image.LANCZOS)
        final = Image.new("RGBA", (OUT, OUT), (0, 0, 0, 0))
        final.paste(square, (int(OUT * 0.05), int(OUT * 0.05)), square)
        final.save(os.path.join(out_dir, name + ".png"))
        print("wrote", name)


if __name__ == "__main__":
    cut(sys.argv[1])
