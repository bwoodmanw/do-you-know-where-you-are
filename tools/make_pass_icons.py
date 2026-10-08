"""Makes the 512 x 512 Game Pass pictures for the character skins from their
own art (art/model-input/<skin>/a-pose-front.png): the head and shoulders cut
out of the grey background, on a glowing circle in the skin's colour. No
text (Roblox shows the pass name). Roblox shows pass pictures as a circle,
so everything sits inside the middle circle.

Run: python tools/make_pass_icons.py  -> art/roblox-store/passes/
"""
import os
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, '..', 'art', 'model-input')
OUT = os.path.join(HERE, '..', 'art', 'roblox-store', 'passes')
os.makedirs(OUT, exist_ok=True)

# folder, file name, inner colour, outer colour
SKINS = [
    ('tinker-pumpkin', 'pass-tinker-pumpkin.png', (255, 170, 70), (120, 45, 10)),
    ('ghostly-shadow', 'pass-ghostly-shadow.png', (200, 180, 255), (45, 30, 90)),
    ('candy-glow', 'pass-candy-glow.png', (255, 190, 225), (150, 50, 120)),
    ('space-cadet-brainy', 'pass-space-cadet-brainy.png', (140, 210, 255), (20, 40, 110)),
    ('snow-day-muscle', 'pass-snow-day-muscle.png', (220, 240, 255), (150, 30, 40)),
    ('starlight-echo', 'pass-starlight-echo.png', (255, 215, 110), (25, 25, 80)),
    ('autumn-leaf-bramble', 'pass-autumn-leaf-bramble.png', (255, 190, 90), (110, 50, 15)),
    ('halloween-nurse-patch', 'pass-halloween-nurse-patch.png', (255, 175, 80), (60, 25, 60)),
]


def grey(c):
    return max(c) - min(c) < 22 and 60 < sum(c) / 3 < 235


def grow(px, bgm, w, h, stack):
    while stack:
        x, y = stack.pop()
        c = px[x, y]
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not bgm[ny * w + nx]:
                n = px[nx, ny]
                if grey(n) and abs(n[0] - c[0]) + abs(n[1] - c[1]) + abs(n[2] - c[2]) < 18:
                    bgm[ny * w + nx] = 1
                    stack.append((nx, ny))


def cutout(im):
    """The figure without its grey studio background (grown in from the
    edges, as in tools/make_art.py)."""
    w, h = im.size
    px = im.load()
    bgm = bytearray(w * h)
    stack = []
    for x in range(w):
        stack += [(x, 0)]
    for y in range(h):
        stack += [(0, y), (w - 1, y)]
    stack = [(x, y) for (x, y) in stack if grey(px[x, y])]
    for x, y in stack:
        bgm[y * w + x] = 1
    grow(px, bgm, w, h, stack)
    mask = Image.frombytes('L', (w, h), bytes(0 if v else 255 for v in bgm))
    mask = mask.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.8))
    rgba = im.convert('RGBA')
    rgba.putalpha(mask)
    return rgba


for folder, name, inner, outer in SKINS:
    src = Image.open(os.path.join(SRC, folder, 'a-pose-front.png')).convert('RGB')
    W, H = src.size
    # head and shoulders: the top half of the picture, the middle of it
    # a T-pose (arms straight out) is cropped closer so the figure stays big
    side = 0.3 if folder == 'ghostly-shadow' else 0.18
    bust = cutout(src.crop((int(W * side), 0, int(W * (1 - side)), int(H * 0.5))))
    bb = bust.getchannel('A').point(lambda v: 255 if v > 40 else 0).getbbox()
    bust = bust.crop((bb[0], bb[1], bb[2], bust.height))
    if folder == 'ghostly-shadow':
        # arms cut at the sides: fade them out instead of a hard edge
        a = bust.getchannel('A')
        ramp = Image.new('L', bust.size, 255)
        rd = ImageDraw.Draw(ramp)
        f = 70
        for i in range(f):
            v = int(255 * i / f)
            rd.line([(i, 0), (i, bust.height)], fill=v)
            rd.line([(bust.width - 1 - i, 0), (bust.width - 1 - i, bust.height)], fill=v)
        from PIL import ImageChops
        bust.putalpha(ImageChops.multiply(a, ramp))
    # the background: a glowing circle in the skin's colours
    S = 512
    bg = Image.new('RGBA', (S, S))
    d = ImageDraw.Draw(bg)
    for r in range(S // 2, 0, -2):
        t = r / (S / 2)
        col = tuple(int(inner[i] * (1 - t) + outer[i] * t) for i in range(3)) + (255,)
        d.ellipse((S / 2 - r, S / 2 - r, S / 2 + r, S / 2 + r), fill=col)
    # a few sparkles (it is a special look)
    for sx, sy, sr in ((90, 120, 9), (420, 150, 7), (400, 380, 10), (110, 400, 6)):
        d.ellipse((sx - sr, sy - sr, sx + sr, sy + sr), fill=(255, 255, 240, 230))
    # the figure: as tall as most of the circle, standing on its lower edge
    scale = min(440 / bust.height, 400 / bust.width)
    fig = bust.resize((round(bust.width * scale), round(bust.height * scale)), Image.LANCZOS)
    shadow = Image.new('RGBA', fig.size, (0, 0, 0, 0))
    shadow.putalpha(fig.getchannel('A').point(lambda v: v * 0.45))
    shadow = shadow.filter(ImageFilter.GaussianBlur(10))
    x, y = (S - fig.width) // 2, S - fig.height - 20
    bg.alpha_composite(shadow, (x + 6, y + 10))
    bg.alpha_composite(fig, (x, y))
    # keep it all inside the circle Roblox shows
    circle = Image.new('L', (S, S), 0)
    ImageDraw.Draw(circle).ellipse((2, 2, S - 3, S - 3), fill=255)
    out = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    out.paste(bg, (0, 0), circle)
    out.save(os.path.join(OUT, name), optimize=True)
    print(name)

# a contact sheet to look at them all at once
sheet = Image.new('RGB', (4 * 256, 2 * 256), (40, 40, 48))
for i, (_, name, _, _) in enumerate(SKINS):
    im = Image.open(os.path.join(OUT, name)).resize((256, 256), Image.LANCZOS)
    sheet.paste(im, ((i % 4) * 256, (i // 4) * 256), im)
sheet.save(os.path.join(OUT, '_all.png'))
print('sheet')
