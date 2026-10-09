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


def drop_specks(im, keep=0.01):
    """Make loose bits smaller than `keep` of the drawing transparent."""
    w, h = im.size
    px = im.load()
    seen = bytearray(w * h)
    blobs = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 30 and not seen[y * w + x]:
                stack, blob = [(x, y)], []
                seen[y * w + x] = 1
                while stack:
                    cx, cy = stack.pop()
                    blob.append((cx, cy))
                    for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                        if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx] and px[nx, ny][3] > 30:
                            seen[ny * w + nx] = 1
                            stack.append((nx, ny))
                blobs.append(blob)
    total = sum(len(b) for b in blobs)
    for b in blobs:
        if len(b) < total * keep:
            for x, y in b:
                r, g, bl, _ = px[x, y]
                px[x, y] = (r, g, bl, 0)
    return im


def cut(sheet_path):
    sheet = Image.open(sheet_path).convert("RGBA")
    w, h = sheet.size
    out_dir = os.path.dirname(sheet_path) or "."
    for i, name in enumerate(NAMES):
        c, r = i % COLS, i // COLS
        # a little in from the cell's edges, so bits of a neighbor stay out
        mx, my = w // COLS // 40, h // ROWS // 40
        cell = sheet.crop((c * w // COLS + mx, r * h // ROWS + my, (c + 1) * w // COLS - mx, (r + 1) * h // ROWS - my))
        cell = drop_specks(clear_background(cell))
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
