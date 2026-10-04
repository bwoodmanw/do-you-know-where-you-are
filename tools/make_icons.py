"""Draws the home-screen icons: a pumpkin-masked face peeking round a door
on a night-purple background. Run: python tools/make_icons.py"""
import os
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'icons')
os.makedirs(OUT, exist_ok=True)

S = 1024  # draw big, scale down


def draw(maskable):
    im = Image.new('RGBA', (S, S), (26, 16, 38, 255))
    d = ImageDraw.Draw(im)
    pad = 170 if maskable else 60
    # a glow behind the pumpkin
    glow = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((pad + 80, pad + 80, S - pad - 80, S - pad - 80), fill=(255, 138, 31, 110))
    glow = glow.filter(ImageFilter.GaussianBlur(70))
    im.alpha_composite(glow)
    d = ImageDraw.Draw(im)
    # pumpkin
    cx, cy = S // 2, S // 2 + 40
    r = (S - 2 * pad) // 2 - 70
    d.ellipse((cx - r * 1.1, cy - r, cx + r * 1.1, cy + r), fill=(240, 120, 20))
    for k in (0.45, 0.8):
        d.ellipse((cx - r * k, cy - r * 0.98, cx + r * k, cy + r * 0.98), outline=(150, 60, 0), width=max(6, r // 28))
    # stem and party hat
    d.rectangle((cx - r * 0.07, cy - r * 1.12, cx + r * 0.07, cy - r * 0.92), fill=(74, 122, 42))
    hat = [(cx + r * 0.25, cy - r * 0.78), (cx + r * 0.75, cy - r * 0.6), (cx + r * 0.68, cy - r * 1.35)]
    d.polygon(hat, fill=(123, 227, 107))
    d.ellipse((cx + r * 0.6, cy - r * 1.45, cx + r * 0.78, cy - r * 1.27), fill=(255, 210, 63))
    # glowing eyes and grin
    eye = (255, 225, 77)
    d.polygon([(cx - r * 0.42, cy - r * 0.45), (cx - r * 0.66, cy - r * 0.02), (cx - r * 0.18, cy - r * 0.02)], fill=eye)
    d.polygon([(cx + r * 0.42, cy - r * 0.45), (cx + r * 0.66, cy - r * 0.02), (cx + r * 0.18, cy - r * 0.02)], fill=eye)
    pts = [(cx - r * 0.6, cy + r * 0.22)]
    for i in range(7):
        pts.append((cx - r * 0.6 + i * r * 0.2, cy + r * (0.36 if i % 2 else 0.5)))
    pts += [(cx + r * 0.6, cy + r * 0.22), (cx, cy + r * 0.32)]
    d.polygon(pts, fill=eye)
    # a big question mark, upper left
    qs = r * 0.9
    d.text((pad + 10, pad - 20), '?', fill=(255, 244, 224), font_size=int(qs))
    return im


for name, size, mask in (('icon-192.png', 192, False), ('icon-512.png', 512, False), ('icon-maskable-512.png', 512, True)):
    draw(mask).resize((size, size), Image.LANCZOS).save(os.path.join(OUT, name))
    print('wrote icons/' + name)
