"""The Candy Corn Hunt badge: a candy corn on a dark purple night with little
stars, in an orange ring like the other badges.

    python tools/make_corn_badge.py art/roblox-store/badges/badge-corn.png
"""
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


pic = Image.new("RGB", (W, W), (40, 22, 62))
d = ImageDraw.Draw(pic)
rnd = random.Random(3)
for _ in range(60):
    x, y, r = rnd.randrange(W), rnd.randrange(W), rnd.choice((3, 4, 6)) * S // 2
    d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 236, 190))
# a soft glow behind the candy corn
glow = Image.new("L", (W, W), 0)
ImageDraw.Draw(glow).ellipse((W * 0.22, W * 0.2, W * 0.78, W * 0.84), fill=150)
glow = glow.filter(ImageFilter.GaussianBlur(60 * S // 4))
pic.paste((255, 150, 60), mask=glow)
# the candy corn: a rounded triangle in three bands (yellow, orange, white tip)
cx, top, bot, half = W / 2, W * 0.2, W * 0.8, W * 0.24


def band(t0, t1, col):
    # the triangle between heights t0..t1 (0 = tip, 1 = base)
    y0, y1 = top + (bot - top) * t0, top + (bot - top) * t1
    w0, w1 = half * t0, half * t1
    d.polygon([(cx - w0, y0), (cx + w0, y0), (cx + w1, y1), (cx - w1, y1)], fill=col)


band(0.0, 0.34, (255, 250, 240))
band(0.34, 0.68, (255, 140, 30))
band(0.68, 1.0, (255, 214, 50))
d.ellipse((cx - half, bot - half * 0.28, cx + half, bot + half * 0.28), fill=(255, 214, 50))
# a little shine
d.ellipse((cx - half * 0.35, top + (bot - top) * 0.45, cx - half * 0.2, top + (bot - top) * 0.62), fill=(255, 200, 140))

badge = Image.new("RGBA", (W, W), (0, 0, 0, 0))
badge.paste((30, 20, 40, 255), mask=disc(254))
badge.paste((255, 138, 31, 255), mask=disc(246))
badge.paste(pic, mask=disc(222))
badge.resize((N, N), Image.LANCZOS).save(sys.argv[1])
