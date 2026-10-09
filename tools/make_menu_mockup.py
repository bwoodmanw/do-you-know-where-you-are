"""Pictures of the proposed pop-up menus and in-game screen in the new clean
style (dark glass panels, cream borders, our icon pictures, capped text
sizes), for Brent to approve before code changes.

    python tools/make_menu_mockup.py art/ui-mockups/menus-v2.png art/ui-mockups/hud-v2.png
"""
import random
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1600, 900
F = "C:/Windows/Fonts/"
EMOJI = ImageFont.truetype(F + "seguiemj.ttf", 44)
EMOJI_S = ImageFont.truetype(F + "seguiemj.ttf", 30)
NIGHT, PLUM, CREAM, PUMP, GREEN, RED = (26, 15, 38), (75, 58, 102), (255, 244, 224), (255, 138, 31), (70, 209, 96), (232, 60, 70)
ICONS = "art/ui-icons/"


def title_font(n):
    return ImageFont.truetype(F + "seguibl.ttf", n)  # chunky titles (like FredokaOne)


def body_font(n):
    return ImageFont.truetype(F + "segoeuib.ttf", n)  # clean body text (like Builder Sans Bold)


def backdrop(dark_scene):
    img = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(img)
    for y in range(H):
        t = y / H
        c = dark_scene
        d.line([(0, y), (W, y)], fill=(int(c[0] + 25 * t), int(c[1] + 18 * t), int(c[2] + 12 * t)))
    rnd = random.Random(4)
    for _ in range(40):
        x, y = rnd.randrange(W), rnd.randrange(H)
        d.ellipse((x - 30, y - 30, x + 30, y + 30), fill=(c[0] + 30, c[1] + 25, c[2] + 30))
    return img.filter(ImageFilter.GaussianBlur(8))


def panel(d, box, title, icon=None, img=None):
    x0, y0, x1, y1 = box
    d.rounded_rectangle(box, 20, fill=(22, 13, 34), outline=CREAM, width=3)
    if icon and img:
        ic = Image.open(ICONS + icon).convert("RGBA").resize((52, 52))
        img.paste(ic, (x0 + 18, y0 + 14), ic)
    d.text((x0 + (82 if icon else 22), y0 + 18), title, font=title_font(30), fill=PUMP)
    # round close button
    d.ellipse((x1 - 58, y0 + 16, x1 - 18, y0 + 56), fill=RED, outline=CREAM, width=3)
    d.text((x1 - 46, y0 + 16), "\u00D7", font=title_font(30), fill=CREAM)
    d.line([(x0 + 18, y0 + 76), (x1 - 18, y0 + 76)], fill=(70, 55, 95), width=2)


def tile(img, d, box, word, icon=None, emoji=None, fill=PLUM, text=CREAM, size=18):
    x0, y0, x1, y1 = box
    d.rounded_rectangle(box, 14, fill=fill, outline=CREAM, width=2)
    w, h = x1 - x0, y1 - y0
    if icon:
        s = int(min(w, h) * 0.55)
        ic = Image.open(ICONS + icon).convert("RGBA").resize((s, s))
        img.paste(ic, (x0 + (w - s) // 2, y0 + 6), ic)
    elif emoji:
        ew = d.textlength(emoji, font=EMOJI)
        d.text((x0 + (w - ew) / 2, y0 + 8), emoji, font=EMOJI, embedded_color=True)
    f = body_font(size)
    tw = d.textlength(word, font=f)
    d.text((x0 + (w - tw) / 2, y1 - size - 12), word, font=f, fill=text)


def row(d, box, text, sub=None, action=None):
    x0, y0, x1, y1 = box
    d.rounded_rectangle(box, 12, fill=PLUM)
    d.text((x0 + 16, y0 + 10), text, font=body_font(20), fill=CREAM)
    if sub:
        d.text((x0 + 16, y0 + 36), sub, font=body_font(15), fill=(190, 175, 215))
    if action:
        bw = d.textlength(action, font=body_font(18)) + 30
        d.rounded_rectangle((x1 - bw - 12, y0 + 12, x1 - 12, y1 - 12), 10, fill=GREEN)
        d.text((x1 - bw + 3, y0 + 18), action, font=body_font(18), fill=NIGHT)


def note(d, x, y, lines):
    for i, t in enumerate(lines):
        d.text((x, y + i * 28), t, font=body_font(20), fill=(230, 220, 245))


def menus(out):
    img = backdrop((40, 30, 55))
    d = ImageDraw.Draw(img)
    d.text((40, 24), "Pop-up menus: one look everywhere", font=title_font(34), fill=PUMP)
    # 1. invite panel
    panel(d, (40, 90, 560, 600), "Invite friends", "invite.png", img)
    d.text((62, 112 + 70), "Friends online", font=body_font(18), fill=(190, 175, 215))
    row(d, (62, 216, 538, 280), "Jamie", "In the Lobby", "Invite")
    row(d, (62, 290, 538, 354), "Sam", "Playing Escape Crew", "Invite")
    row(d, (62, 364, 538, 428), "Alex", "Online", "Invite")
    d.rounded_rectangle((62, 520, 538, 578), 14, fill=GREEN, outline=CREAM, width=2)
    t = "Open Roblox's invite list"
    d.text((300 - d.textlength(t, font=body_font(22)) / 2, 533), t, font=body_font(22), fill=NIGHT)
    # 2. emote picker: a small pop-up beside the Emote tile, not over everything
    panel(d, (620, 90, 1060, 420), "Emote", "emote.png", img)
    em = [("\U0001F44B", "Wave"), ("\U0001F449", "Point"), ("\U0001F389", "Cheer"), ("\U0001F602", "Laugh"),
          ("\U0001F57A", "Dance 1"), ("\U0001F483", "Dance 2"), ("\U0001F3B6", "Dance 3"), ("\u270B", "Stop")]
    for i, (e, w) in enumerate(em):
        x = 640 + (i % 4) * 102
        y = 180 + (i // 4) * 116
        tile(img, d, (x, y, x + 94, y + 106), w, emoji=e, size=17)
    # 3. a shop row the same way
    panel(d, (1100, 90, 1560, 600), "Shop", "shop.png", img)
    for i, (e, n, p) in enumerate([("\U0001F6E1", "Party Shield", "120"), ("\U0001F36C", "Candy Corn", "60"), ("\U0001F4A1", "Extra Clue", "80"), ("\U0001F9CA", "Frozen Pop", "150")]):
        y = 186 + i * 96
        d.rounded_rectangle((1120, y, 1540, y + 84), 12, fill=PLUM)
        d.text((1134, y + 18), e, font=EMOJI, embedded_color=True)
        d.text((1196, y + 14), n, font=body_font(20), fill=CREAM)
        d.text((1196, y + 44), "You have 2", font=body_font(15), fill=(190, 175, 215))
        d.rounded_rectangle((1420, y + 18, 1526, y + 66), 10, fill=GREEN)
        d.text((1432, y + 25), "\u2B50", font=EMOJI_S, embedded_color=True)
        d.text((1472, y + 26), p, font=body_font(19), fill=NIGHT)
    note(d, 40, 640, [
        "\u2022 Dark glass panels with a cream border and our own picture by the title - the same as the tiles.",
        "\u2022 Text stays a normal size (titles 30, buttons 20-22, small print 15) instead of stretching to fill each box.",
        "\u2022 The rounded game font only for titles; a clean bold font for everything else.",
        "\u2022 Light buttons only for the one main action (green); everything else plum with a cream edge.",
        "\u2022 One pop-up at a time; small ones (Emote) open beside their tile, not over the middle.",
    ])
    img.save(out)


def hud(out):
    img = backdrop((20, 40, 70))
    d = ImageDraw.Draw(img)
    # top bar
    d.rounded_rectangle((480, 12, 1120, 64), 18, fill=(22, 13, 34), outline=CREAM, width=2)
    d.text((500, 22), "\U0001F4CD", font=EMOJI_S, embedded_color=True)
    d.text((544, 24), "Great Tank Hall", font=body_font(22), fill=PUMP)
    d.text((760, 20), "\u23F1", font=EMOJI_S, embedded_color=True)
    d.text((800, 20), "7:01", font=title_font(26), fill=CREAM)
    d.text((930, 24), "Code", font=body_font(22), fill=CREAM)
    d.ellipse((990, 32, 1006, 48), fill=(70, 209, 96))
    d.text((1014, 20), "\u2B50", font=EMOJI_S, embedded_color=True)
    d.text((1056, 24), "?", font=body_font(22), fill=CREAM)
    # bottom left: stamina, points, map
    d.rounded_rectangle((20, 520, 340, 600), 16, fill=(22, 13, 34), outline=CREAM, width=2)
    d.text((36, 528), "Stamina", font=body_font(15), fill=(190, 175, 215))
    d.rounded_rectangle((36, 552, 324, 568), 8, fill=(50, 40, 60))
    d.rounded_rectangle((36, 552, 250, 568), 8, fill=(123, 227, 107))
    d.text((60, 574), "42 this game", font=body_font(16), fill=(255, 210, 63))
    d.ellipse((38, 577, 54, 593), fill=(255, 210, 63))
    d.rounded_rectangle((20, 610, 340, 880), 16, fill=(10, 6, 16), outline=CREAM, width=2)
    d.text((140, 735), "(the map)", font=body_font(18), fill=(120, 110, 140))
    # bottom right: action tiles with pictures
    acts = [("\U0001F3C3", "Run"), ("\U0001F319", "Sneak"), ("\U0001F4AC", "Say"), ("\U0001F4A1", "Clue 3"), ("\U0001F504", "Change"), ("\U0001F604", "Emote")]
    for i, (e, w) in enumerate(acts):
        x = 1250 + (i % 3) * 110
        y = 660 + (i // 3) * 112
        tile(img, d, (x, y, x + 100, y + 102), w, emoji=e, fill=(PLUM if i != 1 else (47, 107, 58)), size=17)
    # boosts row above them
    for i, (e, t) in enumerate([("\U0001F6E1", "ON"), ("\u26A1", "3s")]):
        x = 1480 - i * 70
        d.ellipse((x, 590, x + 58, 648), fill=(22, 13, 34), outline=(123, 227, 107), width=3)
        d.text((x + 11, 594), e, font=EMOJI_S, embedded_color=True)
        d.text((x + 16, 626), t, font=body_font(14), fill=CREAM)
    note(d, 420, 700, [
        "\u2022 The same tiles as the Lobby: a picture and one word each.",
        "\u2022 The skill tile is green and counts down on its word.",
        "\u2022 Top bar: one dark glass strip; bars and map framed the same way.",
        "\u2022 A second icon sheet would give Run, Say, Clue, Change,",
        "  the 8 skills and the emotes their own pictures.",
    ])
    img.save(out)


if __name__ == "__main__":
    menus(sys.argv[1])
    hud(sys.argv[2])
