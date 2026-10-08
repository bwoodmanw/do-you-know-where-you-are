"""Make a 512 x 512 badge picture like the others in art/roblox-store/badges/:
a circle cut from a map picture, a coloured ring, a dark outline.

    python tools/make_badge.py <map.png> <out.png> <r,g,b> [left top size]

left / top / size pick the square to cut from the map picture (pixels);
without them it takes the middle square.
"""
import sys
from PIL import Image, ImageDraw

S = 4  # draw at 4x and shrink, for smooth edges
N = 512


def make(src, out, ring, box=None):
    im = Image.open(src).convert("RGB")
    w, h = im.size
    if box is None:
        size = min(w, h)
        box = ((w - size) // 2, (h - size) // 2, size)
    left, top, size = box
    pic = im.crop((left, top, left + size, top + size)).resize((N * S, N * S), Image.LANCZOS)

    def disc(r):
        m = Image.new("L", (N * S, N * S), 0)
        c = N * S / 2
        ImageDraw.Draw(m).ellipse((c - r * S, c - r * S, c + r * S, c + r * S), fill=255)
        return m

    badge = Image.new("RGBA", (N * S, N * S), (0, 0, 0, 0))
    badge.paste((30, 20, 40, 255), mask=disc(254))  # dark outline
    badge.paste(ring + (255,), mask=disc(246))  # coloured ring
    badge.paste(pic, mask=disc(222))
    badge.resize((N, N), Image.LANCZOS).save(out)


if __name__ == "__main__":
    ring = tuple(int(v) for v in sys.argv[3].split(","))
    box = tuple(int(v) for v in sys.argv[4:7]) if len(sys.argv) >= 7 else None
    make(sys.argv[1], sys.argv[2], ring, box)
