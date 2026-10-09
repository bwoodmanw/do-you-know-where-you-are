"""A picture of the proposed Lobby screen (icon tiles instead of text
buttons), for Brent to approve before any code changes.

    python tools/make_lobby_mockup.py art/ui-mockups/lobby-v2.png
"""
import random
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1600, 900
F = "C:/Windows/Fonts/"
EMOJI = ImageFont.truetype(F + "seguiemj.ttf", 64)
EMOJI_S = ImageFont.truetype(F + "seguiemj.ttf", 40)
BOLD = F + "seguibl.ttf"

PLUM = (75, 58, 102)
NIGHT = (26, 15, 38)
CREAM = (255, 244, 224)
PUMP = (255, 138, 31)
GREEN = (70, 209, 96)
RED = (232, 60, 70)


def font(size):
    return ImageFont.truetype(BOLD, size)


def rounded(d, box, r, fill, outline=CREAM, width=5):
    d.rounded_rectangle(box, r, fill=fill, outline=outline, width=width)


def centered(d, cx, y, text, f, fill=CREAM):
    w = d.textlength(text, font=f)
    d.text((cx - w / 2, y), text, font=f, fill=fill)


def tile(img, d, x, y, w, h, icon, word, fill=PLUM, badge=None, icon_font=EMOJI, word_size=26):
    if len(word) > 8:
        word_size = min(word_size, 21)
    rounded(d, (x, y, x + w, y + h), 22, fill)
    iw = d.textlength(icon, font=icon_font)
    d.text((x + w / 2 - iw / 2, y + h * 0.12), icon, font=icon_font, embedded_color=True)
    centered(d, x + w / 2, y + h - word_size - 18, word, font(word_size))
    if badge:
        bx, by = x + w - 18, y + 4
        d.ellipse((bx - 20, by - 20, bx + 20, by + 20), fill=RED, outline=CREAM, width=4)
        centered(d, bx, by - 19, badge, font(26))


def make(out):
    img = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(img)
    # the 3D Lobby behind (a night lane, blurred, only to show where the screen sits)
    for y in range(H):
        t = y / H
        d.line([(0, y), (W, y)], fill=(int(40 + 30 * t), int(28 + 20 * t), int(70 + 10 * t)))
    rnd = random.Random(2)
    for _ in range(90):
        x, y = rnd.randrange(W), rnd.randrange(int(H * 0.55))
        d.ellipse((x - 2, y - 2, x + 2, y + 2), fill=(255, 240, 200))
    d.polygon([(560, H), (760, 380), (840, 380), (1040, H)], fill=(70, 55, 60))
    d.rectangle((620, 230, 980, 400), fill=(55, 40, 70))
    for wx in (660, 760, 860):
        d.rectangle((wx, 270, wx + 70, 340), fill=(255, 190, 90))
    img = img.filter(ImageFilter.GaussianBlur(3))
    d = ImageDraw.Draw(img)
    centered(d, W / 2, 470, "(the 3D Lobby, as now)", font(22), fill=(200, 185, 220))

    # top: the name, small
    centered(d, W / 2, 18, "ESCAPE CREW", font(46), fill=PUMP)

    # left: big tiles, two columns
    x0, y0 = 28, 110
    rounded(d, (x0, y0, x0 + 300, y0 + 110), 24, GREEN)
    d.text((x0 + 22, y0 + 18), "\u26A1", font=EMOJI, embedded_color=True)
    d.text((x0 + 104, y0 + 24), "QUICK", font=font(34), fill=NIGHT)
    d.text((x0 + 104, y0 + 60), "PLAY", font=font(34), fill=NIGHT)
    tiles = [
        ("\u25B6\uFE0F", "Solo", None), ("\U0001F388", "Party", None),
        ("\U0001F9D2", "Characters", None), ("\U0001F6D2", "Shop", None),
        ("\U0001F4DC", "Quests", "!"), ("\U0001F9F8", "Plushies", "3"),
    ]
    for i, (icon, word, badge) in enumerate(tiles):
        cx = x0 + (i % 2) * 154
        cy = y0 + 130 + (i // 2) * 154
        tile(img, d, cx, cy, 146, 146, icon, word, badge=badge)

    # right: a slim bar of round-cornered icons, one word each
    rx, ry = W - 128, 110
    bar = [("\u2709\uFE0F", "Invite"), ("\U0001F389", "Join"), ("\U0001F604", "Emote"), ("\U0001F4F8", "Photo"), ("\U0001F3B5", "Music"), ("\u2753", "Help"), ("\u2699\uFE0F", "Settings")]
    for i, (icon, word) in enumerate(bar):
        tile(img, d, rx, ry + i * 104, 100, 96, icon, word, icon_font=EMOJI_S, word_size=18, badge="2" if word == "Join" else None)

    # bottom left: what you have, as chips
    def chip(x, y, icon, text, pic=None):
        rounded(d, (x, y, x + 250, y + 70), 35, NIGHT)
        if pic:
            p = Image.open(pic).convert("RGBA").resize((54, 54))
            m = Image.new("L", (54, 54), 0)
            ImageDraw.Draw(m).ellipse((1, 1, 53, 53), fill=255)
            img.paste(p, (x + 10, y + 8), m)
        else:
            d.text((x + 14, y + 10), icon, font=EMOJI_S, embedded_color=True)
        d.text((x + 76, y + 12), text, font=font(36), fill=CREAM)
    chip(28, H - 170, "\u2B50", "5,095")
    chip(28, H - 90, None, "42", pic="art/roblox-store/boost-candy-512.png")

    # bottom middle: the event, as a slim pill
    rounded(d, (W / 2 - 300, H - 86, W / 2 + 300, H - 26), 30, (90, 40, 20), outline=PUMP)
    centered(d, W / 2, H - 78, "Candy Corn Hunt  12 / 50  -  Candy Shop", font(28), fill=CREAM)

    # notes for Brent
    d.text((360, H - 150), "One word per button, a big picture on each.", font=font(22), fill=(230, 220, 245))
    d.text((360, H - 120), "Red dots: something new (a quest done, plushies found).", font=font(22), fill=(230, 220, 245))
    img.save(out)


if __name__ == "__main__":
    make(sys.argv[1])
