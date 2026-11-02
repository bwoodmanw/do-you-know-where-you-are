"""Game Pass pictures (512 x 512) for the Thanksgiving skins, from each skin's
approved front picture (art/model-input/<folder>/front-toon.png): the plain
gray background cut away (flood fill from the edges), head and shoulders in
an autumn circle like the other pass pictures. 2 Nov.

    python tools/make_pass_pictures.py
    -> art/roblox-store/passes/pass-<folder>.png and _thanksgiving.png
"""
import os
from collections import deque

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKINS = ["pie-baker-patch", "chef-brainy", "gobble-shadow", "harvest-glow", "scarecrow-tinker",
         "gridiron-muscle", "dj-echo", "cocoa-echo", "acorn-bramble"]
S = 512


def cut_background(img):
    a = np.asarray(img.convert("RGB")).astype(int)
    h, w = a.shape[:2]
    bg = np.median(np.concatenate([a[0], a[-1], a[:, 0], a[:, -1]]), axis=0)
    near = np.abs(a - bg).sum(2) < 34
    seen = np.zeros((h, w), bool)
    q = deque()
    for x in range(w):
        q.extend([(0, x), (h - 1, x)])
    for y in range(h):
        q.extend([(y, 0), (y, w - 1)])
    while q:
        y, x = q.popleft()
        if y < 0 or x < 0 or y >= h or x >= w or seen[y, x] or not near[y, x]:
            continue
        seen[y, x] = True
        q.extend([(y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)])
    # 2 Nov (Brent): gray left in the gaps of curly hair (Feast DJ and Cozy
    # Cocoa Echo) - background pockets the fill can't reach. Any patch of
    # background gray bigger than a few pixels goes too
    pocket = near & ~seen
    left = np.zeros((h, w), bool)
    for sy, sx in zip(*np.nonzero(pocket)):
        if left[sy, sx]:
            continue
        comp, q = [], deque([(sy, sx)])
        left[sy, sx] = True
        while q:
            y, x = q.popleft()
            comp.append((y, x))
            for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                if 0 <= ny < h and 0 <= nx < w and pocket[ny, nx] and not left[ny, nx]:
                    left[ny, nx] = True
                    q.append((ny, nx))
        if len(comp) >= 40:
            for y, x in comp:
                seen[y, x] = True
    alpha = Image.fromarray(np.where(seen, 0, 255).astype(np.uint8)).filter(ImageFilter.MinFilter(5)).filter(ImageFilter.GaussianBlur(1.2))  # 2px off the outline: no pale fringe
    out = img.convert("RGBA")
    out.putalpha(alpha)
    return out, ~seen


def picture(folder):
    src = Image.open(os.path.join(ROOT, "art", "model-input", folder, "front-toon.png"))
    cut, body = cut_background(src)
    ys, xs = np.nonzero(body)
    top, bottom = ys.min(), ys.max()
    cx = (xs.min() + xs.max()) / 2
    # head and shoulders: the top 46% of the figure, square
    side = int((bottom - top) * 0.46)
    left = int(cx - side / 2)
    crop = cut.crop((left, top - int(side * 0.04), left + side, top - int(side * 0.04) + side)).resize((S - 36, S - 36), Image.LANCZOS)
    # an autumn circle: deep orange to brown, a few soft leaves of light
    yy, xx = np.mgrid[0:S, 0:S]
    t = np.clip(np.hypot(xx - S / 2, yy - S * 0.4) / (S * 0.62), 0, 1)[..., None]
    inner, outer = np.array([232, 140, 60]), np.array([120, 52, 26])
    bg = Image.fromarray((inner * (1 - t) + outer * t).astype(np.uint8)).convert("RGBA")
    d = ImageDraw.Draw(bg)
    for (x, y, r) in [(70, 120, 9), (440, 150, 7), (95, 380, 6), (420, 400, 8), (380, 70, 5)]:
        d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 214, 140, 255))
    bg.alpha_composite(crop, (18, 30))
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).ellipse((2, 2, S - 3, S - 3), fill=255)
    out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    out.paste(bg, (0, 0), mask)
    return out


pics = []
for f in SKINS:
    p = picture(f)
    p.save(os.path.join(ROOT, "art", "roblox-store", "passes", "pass-%s.png" % f))
    pics.append(p)
sheet = Image.new("RGBA", (3 * 260, 3 * 260), (30, 20, 40, 255))
for i, p in enumerate(pics):
    sheet.alpha_composite(p.resize((250, 250)), ((i % 3) * 260 + 5, (i // 3) * 260 + 5))
sheet.save(os.path.join(ROOT, "art", "roblox-store", "passes", "_thanksgiving.png"))
print("wrote", len(pics), "pass pictures")
