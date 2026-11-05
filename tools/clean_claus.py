"""clean_claus.py - (5 Nov) two smears on the Claus Manor hosts' models:
  host-mrclaus:  (the soot smudge on his cap made a hole in the 3D shape -
                 painted off his front picture instead; this pass is a no-op
                 safety net) dark gray on the cap -> the cap's red
  host-mrsclaus: her holly sprig's red and green smeared over the side and
                 back of her white bun - red / green on the head that does not
                 face the front -> her hair's white (the sprig stays in front)
Only the texture changes (clean_hair.swap_image); the earlier model is kept
as <name>-toon-before-clean.glb. Run with the Stable Fast 3D Python:
  <sf3d-venv>\\Scripts\\python.exe tools\\clean_claus.py host-mrclaus host-mrsclaus
"""
import io
import shutil
import sys
from pathlib import Path

import numpy as np
import trimesh
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from paint_toon import raster  # noqa: E402
from clean_hair import swap_image  # noqa: E402
from check_toon_models import check  # noqa: E402

MODELS = Path(__file__).resolve().parent.parent / "art" / "models"


def clean(name):
    glb = MODELS / f"{name}-toon.glb"
    before = MODELS / f"{name}-toon-before-clean.glb"
    if not before.exists():
        shutil.copy2(glb, before)
    mesh = trimesh.load(before, force="scene", process=False).dump()[0]
    V = np.asarray(mesh.vertices, np.float64)
    F = np.asarray(mesh.faces)
    uv = np.asarray(mesh.visual.uv, np.float64)
    tex = np.asarray(mesh.visual.material.baseColorTexture.convert("RGB")).copy()
    TH, TW = tex.shape[:2]
    uvpx = np.stack([uv[:, 0] * TW, (1 - uv[:, 1]) * TH], axis=1)
    fn = mesh.face_normals
    lo, hi = V.min(0), V.max(0)
    size = hi - lo
    cen = V[F].mean(axis=1)
    fy = (cen[:, 1] - lo[1]) / size[1]

    if name == "host-mrclaus":
        region = fy > 0.80  # the cap (above his eyes, which sit at about 0.7 of his height)
        def bad(c):
            sat = c.max(axis=1) - c.min(axis=1)
            return (c.sum(axis=1) < 330) & (sat < 45)
        def good(c):
            return (c[:, 0] > 110) & (c[:, 1] < 0.45 * c[:, 0]) & (c[:, 2] < 0.45 * c[:, 0])
    else:
        region = (fy > 0.80) & (fn[:, 2] < 0.45)  # her head, not the front of it
        def bad(c):
            r, g, b = c[:, 0], c[:, 1], c[:, 2]
            red = (r > 110) & (g < 0.6 * r) & (b < 0.6 * r)
            green = (g > r + 15) & (g > b + 10)
            # the smear's pale pink and pale green blends into the white
            pink = (r > 150) & (r - g > 28)
            pale_green = (g > r + 6) & (g > b + 6)
            return red | green | pink | pale_green
        def good(c):
            return c.min(axis=1) > 200

    samples = []
    for f in np.nonzero(region)[0]:
        pts, _ = raster(uvpx[F[f]], TW, TH)
        if pts is not None and len(pts):
            c = tex[pts[:, 1], pts[:, 0]].astype(np.float32)
            samples.append(c[good(c)])
    colour = np.median(np.concatenate(samples), axis=0).astype(np.uint8)
    changed = 0
    for f in np.nonzero(region)[0]:
        pts, _ = raster(uvpx[F[f]], TW, TH)
        if pts is None or len(pts) == 0:
            continue
        c = tex[pts[:, 1], pts[:, 0]].astype(np.float32)
        b = bad(c)
        if b.any():
            tex[pts[b, 1], pts[b, 0]] = colour
            changed += int(b.sum())
    buf = io.BytesIO()
    Image.fromarray(tex).save(buf, format="PNG")
    swap_image(before, buf.getvalue(), glb)
    print(f"{name}: {changed} texels -> {colour.tolist()}")
    problems = check(glb)
    print(f"{name}: checked - " + ("all good" if not problems else "; ".join(map(str, problems))))


for n in sys.argv[1:]:
    clean(n)
