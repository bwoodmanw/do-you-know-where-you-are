"""Builds the web-sized art the game loads (public/art/) from the full-size
sheets in art/sheets/. Run: python tools/make_art.py
- pictures -> JPEG, sized for a Fire HD 10 screen
- textures -> 512px JPEG tiles
- the party host -> cut out of its grey background (PNG with transparency)"""
import os
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, '..', 'art', 'sheets')
OUT = os.path.join(HERE, '..', 'public', 'art')
os.makedirs(OUT, exist_ok=True)


def jpg(name, out, width, q=80):
    im = Image.open(os.path.join(SRC, name)).convert('RGB')
    if im.width > width:
        im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
    im.save(os.path.join(OUT, out), 'JPEG', quality=q, optimize=True, progressive=True)
    return os.path.getsize(os.path.join(OUT, out)) // 1024


def cutout(name, box, out, height):
    """Crop one cell of a turnaround sheet and remove its grey studio
    background. The background shades from light to dark, so it is grown
    from the cell's edges pixel by pixel: a pixel joins if it is grey (low
    colour) and close to the neighbour it was reached from."""
    im = Image.open(os.path.join(SRC, name)).convert('RGB').crop(box)
    w, h = im.size
    px = im.load()
    bgm = bytearray(w * h)
    def grey(c):
        return max(c) - min(c) < 22 and 60 < sum(c) / 3 < 235
    stack = []
    for x in range(w):
        stack.append((x, 0)); stack.append((x, h - 1))
    for y in range(h):
        stack.append((0, y)); stack.append((w - 1, y))
    for (x, y) in stack:
        if grey(px[x, y]):
            bgm[y * w + x] = 1
    stack = [(x, y) for (x, y) in stack if bgm[y * w + x]]
    grow(px, bgm, w, h, stack)
    # pockets of background enclosed by the figure (between an arm and the
    # body): seed grey pixels whose brightness matches the background found
    # in the same band of rows, then grow those too
    rows = []
    for y in range(h):
        vals = [sum(px[x, y]) / 3 for x in range(0, w, 2) if bgm[y * w + x]]
        rows.append(sum(vals) / len(vals) if vals else None)
    for y in range(h):
        band = [v for v in rows[max(0, y - 30):y + 30] if v is not None]
        if not band:
            continue
        hi, lo = max(band), min(band)
        for x in range(w):
            c = px[x, y]
            b = sum(c) / 3
            if not bgm[y * w + x] and max(c) - min(c) < 14 and lo - 6 < b < hi + 6:
                bgm[y * w + x] = 1
                stack.append((x, y))
    grow(px, bgm, w, h, stack)
    mask = Image.frombytes('L', (w, h), bytes(0 if v else 255 for v in bgm))
    mask = mask.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.8))
    rgba = im.convert('RGBA')
    rgba.putalpha(mask)
    bb = mask.point(lambda v: 255 if v > 40 else 0).getbbox()
    rgba = rgba.crop(bb)
    rgba = rgba.resize((round(rgba.width * height / rgba.height), height), Image.LANCZOS)
    rgba.save(os.path.join(OUT, out), optimize=True)
    return os.path.getsize(os.path.join(OUT, out)) // 1024, rgba.size


def grow(px, bgm, w, h, stack):
    def grey(c):
        return max(c) - min(c) < 22 and 60 < sum(c) / 3 < 235
    while stack:
        x, y = stack.pop()
        c = px[x, y]
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not bgm[ny * w + nx]:
                n = px[nx, ny]
                if grey(n) and abs(n[0] - c[0]) + abs(n[1] - c[1]) + abs(n[2] - c[2]) < 18:
                    bgm[ny * w + nx] = 1
                    stack.append((nx, ny))


report = []
report.append(('title.jpg', jpg('title.png', 'title.jpg', 1600, 82)))
report.append(('story-door.jpg', jpg('story-door.png', 'story-door.jpg', 1280)))
report.append(('host-party-scare.jpg', jpg('host-party-scare.png', 'host-party-scare.jpg', 1280, 82)))
for r in ('hall', 'kitchen', 'library', 'gameroom', 'garden'):
    report.append(('room-party-%s.jpg' % r, jpg('room-party-%s.png' % r, 'room-party-%s.jpg' % r, 1280)))
for t in ('wood', 'darkwood', 'carpet-plum', 'carpet-green', 'carpet-purple', 'tiles', 'wallpaper'):
    report.append(('tex-%s.jpg' % t, jpg('tex-%s.png' % t, 'tex-%s.jpg' % t, 512, 85)))
# the host sheet is a 4 x 2 grid of 384 x 512 cells
report.append(('host-party-stand.png', cutout('host-party.png', (0, 0, 384, 500), 'host-party-stand.png', 420)))
report.append(('host-party-hunt.png', cutout('host-party.png', (384, 512, 768, 1012), 'host-party-hunt.png', 420)))
report.append(('host-party-face.png', cutout('host-party.png', (100, 0, 290, 175), 'host-party-face.png', 160)))
for name, info in report:
    print(name, info)
