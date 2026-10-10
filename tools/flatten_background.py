"""flatten_background.py - makes a model picture's background ONE plain gray.

The turkey pictures (10 Oct) came back with a darker band across the middle
of the gray background: paint_toon's outline found the "character" filling
the whole width, and Stable Fast 3D's background removal can trip on it too.
Every background shade that touches the picture's edge (no strong edge in
between) is set to one light gray; the character is untouched. The original
is kept as <name>-orig.png the first time.

  python tools/flatten_background.py art/model-input/turkey/front-toon.png [...]
"""
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

GRAY = np.array([215, 217, 220], np.uint8)


def flatten(path):
    path = Path(path)
    orig = path.with_name(path.stem + "-orig.png")
    if not orig.exists():
        shutil.copy2(path, orig)
    a = np.asarray(Image.open(orig).convert("RGB")).astype(np.int32)
    # background = gray-ish (low saturation), light, and changing slowly
    sat = a.max(axis=2) - a.min(axis=2)
    light = a.mean(axis=2)
    gy = np.abs(np.diff(a, axis=0, prepend=a[:1])).sum(axis=2)
    gx = np.abs(np.diff(a, axis=1, prepend=a[:, :1])).sum(axis=2)
    smooth = np.maximum(gx, gy) < 30  # the band's edge is a soft step; the character's outline is not
    cand = (sat < 18) & (light > 150) & smooth
    lab, _ = ndimage.label(cand)
    edge = np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))
    bg = np.isin(lab, edge[edge > 0])
    # the band's edge line itself (closing trims the picture's border: keep it)
    bg = (ndimage.binary_closing(bg, iterations=2) | bg) & (sat < 18)
    rim = np.zeros_like(bg)  # the band's ends on the picture's edge (a sharp step there)
    rim[:3], rim[-3:], rim[:, :3], rim[:, -3:] = True, True, True, True
    bg |= rim & (sat < 18) & (light > 150)
    out = a.astype(np.uint8).copy()
    out[bg] = GRAY
    Image.fromarray(out).save(path)
    print(f"{path}: {int(bg.mean() * 100)}% background set to one gray")


if __name__ == "__main__":
    for p in sys.argv[1:]:
        flatten(p)
