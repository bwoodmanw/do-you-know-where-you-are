"""The Turkey Wrangler badge (Thanksgiving): a round cartoon turkey with its
tail fan up, a golden feather beside it, on a dark purple night with little
stars, in an orange ring like the other badges (make_corn_badge.py).

    python tools/make_turkey_badge.py art/roblox-store/badges/badge-feather.png
"""
import math
import random
import sys
from PIL import Image, ImageDraw, ImageFilter

S, N = 4, 512
W = N * S


def disc(r):
    m = Image.new("L", (W, W), 0)
    c = W / 2
    ImageDraw.Draw(m).ellipse((c - r * S, c - r * S, c + r * S, c + r * S), fill=255)
    return m


def ellipse(d, cx, cy, rx, ry, col):
    d.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=col)


def petal(img, cx, cy, length, width, angle, col):
    """one tail feather: a long ellipse from (cx, cy) outward at angle (deg, 0 = up)"""
    layer = Image.new("L", (W, W), 0)
    ImageDraw.Draw(layer).ellipse((W / 2 - width / 2, W / 2 - length, W / 2 + width / 2, W / 2), fill=255)
    layer = layer.rotate(-angle, center=(W / 2, W / 2), resample=Image.BICUBIC)
    shifted = Image.new("L", (W, W), 0)
    shifted.paste(layer, (int(cx - W / 2), int(cy - W / 2)))
    img.paste(col, mask=shifted)


pic = Image.new("RGB", (W, W), (40, 22, 62))
d = ImageDraw.Draw(pic)
rnd = random.Random(7)
for _ in range(60):
    x, y, r = rnd.randrange(W), rnd.randrange(W), rnd.choice((3, 4, 6)) * S // 2
    d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 236, 190))
glow = Image.new("L", (W, W), 0)
ImageDraw.Draw(glow).ellipse((W * 0.18, W * 0.18, W * 0.82, W * 0.86), fill=150)
glow = glow.filter(ImageFilter.GaussianBlur(60 * S // 4))
pic.paste((255, 150, 60), mask=glow)

cx, cy = W * 0.5, W * 0.58
# the tail fan: three rings of feathers (red, orange, yellow), outer first
for length, col in ((W * 0.36, (214, 58, 40)), (W * 0.31, (255, 140, 30)), (W * 0.25, (255, 206, 60))):
    for a in range(-80, 81, 20):
        petal(pic, cx, cy, length, W * 0.11, a, col)
d = ImageDraw.Draw(pic)
BROWN, DARK, CREAM = (126, 72, 40), (90, 50, 28), (246, 222, 180)
# legs and feet
for sx in (-1, 1):
    x = cx + sx * W * 0.07
    d.rectangle((x - W * 0.012, cy + W * 0.16, x + W * 0.012, cy + W * 0.23), fill=(255, 140, 30))
    for t in (-1, 0, 1):
        d.line((x, cy + W * 0.23, x + t * W * 0.035, cy + W * 0.25), fill=(255, 140, 30), width=int(W * 0.018))
# body, wings, belly
ellipse(d, cx, cy + W * 0.04, W * 0.17, W * 0.16, BROWN)
ellipse(d, cx - W * 0.15, cy + W * 0.05, W * 0.06, W * 0.1, DARK)
ellipse(d, cx + W * 0.15, cy + W * 0.05, W * 0.06, W * 0.1, DARK)
ellipse(d, cx, cy + W * 0.08, W * 0.1, W * 0.1, CREAM)
# head, eyes, beak, wattle
hx, hy = cx, cy - W * 0.15
ellipse(d, hx, hy, W * 0.095, W * 0.09, BROWN)
for sx in (-1, 1):
    ellipse(d, hx + sx * W * 0.035, hy - W * 0.015, W * 0.026, W * 0.03, (255, 255, 255))
    ellipse(d, hx + sx * W * 0.03, hy - W * 0.01, W * 0.013, W * 0.016, (30, 20, 20))
d.polygon([(hx - W * 0.025, hy + W * 0.02), (hx + W * 0.025, hy + W * 0.02), (hx, hy + W * 0.06)], fill=(255, 160, 40))
ellipse(d, hx + W * 0.022, hy + W * 0.06, W * 0.014, W * 0.03, (220, 40, 40))
# a little golden feather at the lower left
fx, fy = W * 0.24, W * 0.72
petal(pic, fx, fy, W * 0.2, W * 0.06, -35, (255, 196, 46))
petal(pic, fx, fy, W * 0.17, W * 0.018, -35, (255, 236, 160))
d = ImageDraw.Draw(pic)
d.line((fx, fy, fx + W * 0.03 * math.sin(math.radians(145)), fy - W * 0.03 * math.cos(math.radians(145))), fill=(214, 150, 40), width=int(W * 0.01))

badge = Image.new("RGBA", (W, W), (0, 0, 0, 0))
badge.paste((30, 20, 40, 255), mask=disc(254))
badge.paste((255, 138, 31, 255), mask=disc(246))
badge.paste(pic, mask=disc(222))
badge.resize((N, N), Image.LANCZOS).save(sys.argv[1])
print("wrote", sys.argv[1])
