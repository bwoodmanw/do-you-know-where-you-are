"""The Candy Cane Hunt badge (Christmas, 3 Nov): a striped candy cane on a
deep blue snowy night, in a red ring with a white rim, like the other badges.

    python tools/make_cane_badge.py art/roblox-store/badges/badge-cane.png
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


pic = Image.new("RGB", (W, W), (22, 34, 78))
d = ImageDraw.Draw(pic)
rnd = random.Random(7)
# snowflakes: little dots and a few six-armed flakes
for _ in range(70):
    x, y, r = rnd.randrange(W), rnd.randrange(W), rnd.choice((3, 4, 6)) * S // 2
    d.ellipse((x - r, y - r, x + r, y + r), fill=(235, 242, 255))
for _ in range(9):
    x, y, r = rnd.randrange(W), rnd.randrange(W), rnd.randrange(14, 24) * S
    for k in range(3):
        a = k * math.pi / 3
        d.line((x - r * math.cos(a), y - r * math.sin(a), x + r * math.cos(a), y + r * math.sin(a)), fill=(200, 220, 255), width=3 * S)
# a soft glow behind the cane
glow = Image.new("L", (W, W), 0)
ImageDraw.Draw(glow).ellipse((W * 0.2, W * 0.15, W * 0.8, W * 0.85), fill=140)
glow = glow.filter(ImageFilter.GaussianBlur(60 * S // 4))
pic.paste((150, 190, 255), mask=glow)

# the cane's shape: a thick stick and a round hook, as a mask
thick = W * 0.11
cane = Image.new("L", (W, W), 0)
cd = ImageDraw.Draw(cane)
sx, top, bot = W * 0.42, W * 0.36, W * 0.84
hr = W * 0.13  # the hook's radius (to the middle of the stick)
cd.line((sx, top, sx, bot), fill=255, width=int(thick))
cd.ellipse((sx - thick / 2, bot - thick / 2, sx + thick / 2, bot + thick / 2), fill=255)
hx = sx + hr
for i in range(181):
    a = math.pi + i / 180 * math.pi * 1.0  # from the stick's top over to the right
    px, py = hx + hr * math.cos(a), top + hr * math.sin(a)
    cd.ellipse((px - thick / 2, py - thick / 2, px + thick / 2, py + thick / 2), fill=255)
end_x, end_y = hx + hr, top + W * 0.06
cd.line((hx + hr, top, end_x, end_y), fill=255, width=int(thick))
cd.ellipse((end_x - thick / 2, end_y - thick / 2, end_x + thick / 2, end_y + thick / 2), fill=255)
# white cane, then red stripes slanting across it
pic.paste((252, 252, 255), mask=cane)
stripes = Image.new("L", (W, W), 0)
sd = ImageDraw.Draw(stripes)
step = W * 0.09
for k in range(-12, 14):
    x0 = k * step
    sd.polygon([(x0, W), (x0 + step * 0.45, W), (x0 + step * 0.45 + W, 0), (x0 + W, 0)], fill=255)
red = Image.new("L", (W, W), 0)
red.paste(stripes, mask=cane)
pic.paste((214, 30, 45), mask=red)
# a little shine down the stick
d.line((sx - thick * 0.22, top + W * 0.05, sx - thick * 0.22, bot - W * 0.05), fill=(255, 235, 235), width=int(thick * 0.12))

badge = Image.new("RGBA", (W, W), (0, 0, 0, 0))
badge.paste((30, 20, 40, 255), mask=disc(254))
badge.paste((214, 30, 45, 255), mask=disc(246))
badge.paste((250, 250, 255, 255), mask=disc(228))
badge.paste(pic, mask=disc(220))
badge.resize((N, N), Image.LANCZOS).save(sys.argv[1])
