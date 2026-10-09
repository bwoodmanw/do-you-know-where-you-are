"""Game-ready copies of the posters in art/posters/: brightened (a gamma
curve that lifts the shadows, so they still read on a dim wall), sized to
683 x 1024 (Roblox shrinks anything over 1024), with short names the code
uses: art/posters/game/<building>-<n>.png.

    python tools/prep_posters.py
"""
import math
import os
from PIL import Image, ImageEnhance, ImageStat

SRC = "art/posters"
OUT = "art/posters/game"
NAMES = {
    "Party House": "partyhouse", "Gummy Bounce House": "gummy", "Abandoned Hospital": "hospital",
    "Midnight School": "school", "Creepy Carnival": "carnival", "Sunken Aquarium": "aquarium",
}
TARGET = 66  # mean brightness (0-255) to aim for


def main():
    os.makedirs(OUT, exist_ok=True)
    for f in sorted(os.listdir(SRC)):
        base, ext = os.path.splitext(f)
        if ext.lower() != ".png" or "-" not in base:
            continue
        building, n = base.rsplit("-", 1)
        key = NAMES.get(building)
        if not key:
            continue
        im = Image.open(os.path.join(SRC, f)).convert("RGB")
        mean = ImageStat.Stat(im.convert("L")).mean[0]
        g = 1.0
        if mean < TARGET:
            g = max(0.65, math.log(TARGET / 255) / math.log(max(mean, 1) / 255))
        lut = [min(255, round(255 * (v / 255) ** g)) for v in range(256)]
        im = im.point(lut * 3).resize((683, 1024), Image.LANCZOS)
        # the lift flattens it a little: give back some color and contrast
        im = ImageEnhance.Contrast(ImageEnhance.Color(im).enhance(1.15)).enhance(1.08)
        name = f"{key}-{n}.png"
        im.save(os.path.join(OUT, name))
        print(f"{name}: brightness {mean:.0f} -> {ImageStat.Stat(im.convert('L')).mean[0]:.0f}")


if __name__ == "__main__":
    main()
