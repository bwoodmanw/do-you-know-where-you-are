"""The Plushie Collector badge: a teddy bear plushie on a dark purple night
with little stars, in a pink ring like the other badges.

    python tools/make_plushie_badge.py art/roblox-store/badges/badge-plushies.png
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


def oval(d, cx, cy, rx, ry, col):
    d.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=col)


pic = Image.new("RGB", (W, W), (40, 22, 62))
d = ImageDraw.Draw(pic)
rnd = random.Random(7)
for _ in range(60):
    x, y, r = rnd.randrange(W), rnd.randrange(W), rnd.choice((3, 4, 6)) * S // 2
    d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 236, 190))
# a soft pink glow behind the bear
glow = Image.new("L", (W, W), 0)
ImageDraw.Draw(glow).ellipse((W * 0.2, W * 0.18, W * 0.8, W * 0.86), fill=150)
glow = glow.filter(ImageFilter.GaussianBlur(60 * S // 4))
pic.paste((255, 140, 190), mask=glow)

FUR, PALE, DARK = (196, 128, 74), (240, 200, 150), (45, 28, 30)
u = W / 100  # 1 unit = 1% of the picture
cx = W / 2
# legs, body, arms
oval(d, cx - 13 * u, 74 * u, 9 * u, 7 * u, FUR)
oval(d, cx + 13 * u, 74 * u, 9 * u, 7 * u, FUR)
oval(d, cx - 13 * u, 75 * u, 5 * u, 4 * u, PALE)
oval(d, cx + 13 * u, 75 * u, 5 * u, 4 * u, PALE)
oval(d, cx, 60 * u, 18 * u, 17 * u, FUR)
oval(d, cx, 62 * u, 11 * u, 11 * u, PALE)
oval(d, cx - 19 * u, 56 * u, 6 * u, 10 * u, FUR)
oval(d, cx + 19 * u, 56 * u, 6 * u, 10 * u, FUR)
# head, ears, muzzle, eyes, nose, smile
oval(d, cx - 14 * u, 22 * u, 7 * u, 7 * u, FUR)
oval(d, cx + 14 * u, 22 * u, 7 * u, 7 * u, FUR)
oval(d, cx - 14 * u, 22 * u, 4 * u, 4 * u, PALE)
oval(d, cx + 14 * u, 22 * u, 4 * u, 4 * u, PALE)
oval(d, cx, 34 * u, 17 * u, 15 * u, FUR)
oval(d, cx, 40 * u, 8 * u, 6 * u, PALE)
oval(d, cx - 7 * u, 31 * u, 2.2 * u, 2.6 * u, DARK)
oval(d, cx + 7 * u, 31 * u, 2.2 * u, 2.6 * u, DARK)
oval(d, cx - 6.5 * u, 30 * u, 0.8 * u, 0.8 * u, (255, 255, 255))
oval(d, cx + 7.5 * u, 30 * u, 0.8 * u, 0.8 * u, (255, 255, 255))
oval(d, cx, 38 * u, 3 * u, 2 * u, DARK)
d.arc((cx - 4 * u, 38 * u, cx + 4 * u, 44 * u), 20, 160, fill=DARK, width=int(0.8 * u))
# a pink heart on the belly
hx, hy, hr = cx, 62 * u, 3.2 * u
oval(d, hx - hr * 0.6, hy - hr * 0.3, hr * 0.75, hr * 0.75, (240, 90, 140))
oval(d, hx + hr * 0.6, hy - hr * 0.3, hr * 0.75, hr * 0.75, (240, 90, 140))
d.polygon([(hx - hr * 1.3, hy - hr * 0.1), (hx + hr * 1.3, hy - hr * 0.1), (hx, hy + hr * 1.3)], fill=(240, 90, 140))

badge = Image.new("RGBA", (W, W), (0, 0, 0, 0))
badge.paste((30, 20, 40, 255), mask=disc(254))
badge.paste((240, 110, 170, 255), mask=disc(246))
badge.paste(pic, mask=disc(222))
badge.resize((N, N), Image.LANCZOS).save(sys.argv[1])
