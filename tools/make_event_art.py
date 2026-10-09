"""A 1920 x 1080 picture for a Roblox Event page (Creator Hub -> Events):
a night-sky panel on the left with the event's name and a few lines, a
square picture on the right fading into it, and an optional small icon by
the title.

    python tools/make_event_art.py <event> <out.png>

Events are listed in EVENTS below (Halloween now; Thanksgiving and
Christmas get added once their designs are picked).
"""
import random
import sys
from PIL import Image, ImageChops, ImageDraw, ImageFont

W, H = 1920, 1080
FONTS = "C:/Windows/Fonts/"

EVENTS = {
    "halloween": dict(
        art="art/roblox-store/icon-halloween.png",
        icon="art/roblox-store/boost-candy-512.png",
        sky=((34, 16, 58), (70, 26, 70)),
        kicker="HALLOWEEN EVENT",
        title=["CANDY CORN", "HUNT"],
        lines=["6 candy corns hidden on every floor",
               "Spend them in the Lobby's Candy Shop",
               "100 corns: the Muscle Mummy skin",
               "Until November 1"],
        accent=(255, 150, 40),
    ),
}


def font(name, size):
    return ImageFont.truetype(FONTS + name, size)


def make(key, out):
    e = EVENTS[key]
    img = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(img)
    top, bot = e["sky"]
    for y in range(H):
        t = y / (H - 1)
        d.line([(0, y), (W, y)], fill=tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3)))
    rnd = random.Random(5)
    for _ in range(140):
        x, y, r = rnd.randrange(W), rnd.randrange(H), rnd.choice((1, 2, 2, 3))
        d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 240, 200))
    # the picture on the right, fading into the sky on its left edge
    S = 960
    art = Image.open(e["art"]).convert("RGB").resize((S, S), Image.LANCZOS)
    # fades in from its left and top edges (the darker of the two wins)
    fade = 240
    left = Image.new("L", (S, S), 255)
    top_ = Image.new("L", (S, S), 255)
    ld, td = ImageDraw.Draw(left), ImageDraw.Draw(top_)
    for i in range(fade):
        ld.line([(i, 0), (i, S)], fill=int(255 * i / fade))
        td.line([(0, i), (S, i)], fill=int(255 * i / fade))
    mask = ImageChops.darker(left, top_)
    img.paste(art, (W - S, H - S), mask)
    # the words on the left
    d = ImageDraw.Draw(img)
    x0 = 90
    y = 150
    kf = font("GILB____.TTF", 54)
    d.text((x0, y), e["kicker"], font=kf, fill=e["accent"])
    y += 90
    tf = font("GILSANUB.TTF", 100)
    for line in e["title"]:
        d.text((x0 + 6, y + 6), line, font=tf, fill=(20, 10, 30))
        d.text((x0, y), line, font=tf, fill=(255, 244, 224))
        y += 120
    if e.get("icon"):
        icon = Image.open(e["icon"]).convert("RGBA").resize((160, 160), Image.LANCZOS)
        round_ = Image.new("L", (160, 160), 0)
        ImageDraw.Draw(round_).ellipse((4, 4, 156, 156), fill=255)
        w = d.textlength(e["title"][-1], font=tf)
        img.paste(icon, (int(x0 + w + 30), y - 120 - 22), round_)
    y += 40
    lf = font("segoeuib.ttf", 42)
    for line in e["lines"]:
        d.ellipse((x0, y + 16, x0 + 20, y + 36), fill=e["accent"])
        d.text((x0 + 40, y), line, font=lf, fill=(255, 236, 210))
        y += 72
    img.save(out)


if __name__ == "__main__":
    make(sys.argv[1], sys.argv[2])
