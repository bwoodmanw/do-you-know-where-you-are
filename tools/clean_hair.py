"""clean_hair.py - (Holly and Clone, see PROFILES) repaints a toon model's long hair where Stable Fast 3D's
guess left other colors on it (4 Nov, Holly: the ends of her hair, hanging
behind her back, carried her sweater's red and green stripes, and her
peppermint bows smeared red round the sides and back of her head).

Only the texture changes - the shape, UVs and normals are left exactly as
they are (the image inside the .glb is swapped), so the model still passes
tools/check_toon_models.py and imports the same way.

What is repainted to the hair color (taken from the model's own back hair):
  1. the head (top 30% of the height), wherever it does not face the front:
     red and green there are the smeared bows - the bows stay on the front;
  2. the hair hanging behind the body: below the head, behind the back of
     the body and as wide as the hair-colored part at that height:
     red and green there are the sweater's stripes.
Skin, white and anything else is left alone.

Run with the Stable Fast 3D Python (numpy, trimesh, PIL):
  <sf3d-venv>\\Scripts\\python.exe tools\\clean_hair.py holly
Writes art/models/<name>-toon.glb (the one before is kept as
<name>-toon-before-hair.glb); then make the x5 copy again with scale_glb.py.
"""
import io
import json
import shutil
import struct
import sys
from pathlib import Path

import numpy as np
import trimesh
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from paint_toon import raster  # noqa: E402

PROJECT = Path(__file__).resolve().parent.parent
INPUT = PROJECT / "art" / "model-input"
MODELS = PROJECT / "art" / "models"


def yellow_hair(c):
    return (c[:, 0] > 150) & (c[:, 1] > 0.6 * c[:, 0]) & (c[:, 2] < 0.55 * c[:, 1])


def dark_hair(c):
    return c.sum(axis=1) < 150


def orange(c):
    r, g, b = c[:, 0], c[:, 1], c[:, 2]
    return (r > 80) & (g > 0.25 * r) & (g < 0.75 * r) & (b < 0.3 * r)  # (skin has more blue)


def dull_brown(c):
    """the goggles' orange half-blended into black hair (about 110, 75, 45):
    darker than his skin (about 200, 130, 90 - skin shadows stay above 135)"""
    r, g, b = c[:, 0], c[:, 1], c[:, 2]
    return (r > 85) & (r < 135) & (g < 0.85 * r) & (b < 0.6 * r) & (r - b > 30)


def pinkish(c):
    return (c[:, 0] > 150) & (c[:, 1] < 0.7 * c[:, 0]) & (c[:, 1] < 150) & (c[:, 2] < 0.85 * c[:, 0])


# per character: the hair color test, what is wrong on the hair, whether the
# top of the head is cleaned too (Holly's bows - not Clone's goggles, which sit
# on top at the front), and whether long hair hangs behind the body
def brown_hair(c):
    r, g, b = c[:, 0], c[:, 1], c[:, 2]
    return (r > 60) & (r < 170) & (g < 0.7 * r) & (b < 0.55 * r)


def yellowish(c):
    r, g, b = c[:, 0], c[:, 1], c[:, 2]
    return (r > 170) & (g > 0.7 * r) & (b < 0.6 * g)


PROFILES = {
    # 4 Nov (Brent: Gridiron Muscle's chest missing its jersey): the neckline
    # came out deep as skin; and his headband's yellow on the back of his hair
    # (his headband goes all the way round, knotted at the back: the yellow
    # there is right - nothing on the head is repainted)
    "gridiron-muscle": {"hair": brown_hair, "bad": lambda c: np.zeros(len(c), bool), "head_bad": None, "top": False, "ends": False,
                        "head": 0.2, "chest": True},
    # 4 Nov: the sweater's stripes on her hair ends, the bows smeared round
    "holly": {"hair": yellow_hair, "bad": lambda c: red_or_green(c), "head_bad": pinkish, "top": True, "ends": True},
    # 4 Nov (Brent): the goggles' orange on the top and back of his hair
    "clone": {"hair": dark_hair, "bad": orange, "head_bad": dull_brown, "top": False, "ends": False, "head": 0.2, "zcut": 0.7}  # (0.5 left orange on his crown behind the goggles)  # (0.3 reached his collar),
    ,
    # 4 Nov, the Thanksgiving skins: the same smears from their accessories
    # Harvest Gala Clone: the gold goggles on the top and back of his hair
    "gala-clone": {"hair": dark_hair, "bad": lambda c: orange(c) | yellowish(c), "head_bad": dull_brown, "top": False, "ends": False, "head": 0.2, "zcut": 0.7},
    # Cranberry Spice Holly: the cranberry clusters and leaves round her head,
    # the sweater's red and brown on her hair ends
    "cranberry-holly": {"hair": yellow_hair, "bad": lambda c: red_or_green(c) | (orange(c) & ~yellow_hair(c)), "head_bad": pinkish, "top": True, "ends": True},
    # Pumpkin Pie Harmony: skin-brown blended into the sides of her black hair
    "pie-harmony": {"hair": dark_hair, "bad": lambda c: (c.sum(axis=1) >= 150) & (c[:, 0] < 175) & (c[:, 0] > c[:, 2] + 15), "head_bad": None, "top": True, "ends": True},  # (zcut 0.8 painted hair over her ear and jaw)
    # Autumn Breeze Cloud: the orange leaf clip smeared over her pale hair
    # 5 Nov: Frostfoot the Yeti - his small navy ears smeared into big navy
    # patches over the white fur on both sides of his head (the face stays)
    "host-yeti": {"hair": lambda c: c.min(axis=1) > 185, "bad": lambda c: (c.sum(axis=1) < 640) & (c[:, 2] > c[:, 0] + 10) & (c[:, 1] >= c[:, 0] - 3) & (c[:, 1] < c[:, 0] + 0.5 * (c[:, 2] - c[:, 0])), "head_bad": None, "top": False, "ends": False, "head": 0.25, "zcut": 0.8},  # navy and its gray-blue blend (lavender has less green than red; the hat and scarf have far more)
    # 5 Nov, the Christmas skins: Ice Skater Patch - the white earmuffs
    # smeared pale patches over the sides and back of her blonde hair (the
    # muffs sit at the middle of the head, so only behind them is cleaned)
    "skater-patch": {"hair": yellow_hair, "bad": lambda c: (c[:, 0] > 170) & (c[:, 2] > 0.68 * c[:, 1]) & (c[:, 1] > 0.75 * c[:, 0]), "head_bad": None, "top": False, "ends": True, "head": 0.25, "zcut": 0.42},
    # Jingle Bell Echo: the red goggle strap smeared wide through the brown
    # curls at the sides and back, with pale streaks from the white collar
    "jinglebell-echo": {"hair": brown_hair, "bad": lambda c: ((c[:, 0] > 120) & (c[:, 1] < 0.45 * c[:, 0]) & (c[:, 2] < 0.6 * c[:, 0])) | ((c.sum(axis=1) > 420) & (c[:, 2] > 0.75 * c[:, 0])), "head_bad": None, "top": False, "ends": False, "head": 0.22, "zcut": 0.55},
    # Snowflake Nutmeg: her brown reindeer ears smeared down the sides of the
    # white hood (the "hair" here is the hood; the ears stand up on top)
    "snowflake-nutmeg": {"hair": lambda c: c.min(axis=1) > 200, "bad": lambda c: (c.sum(axis=1) < 600) & (c[:, 0] > c[:, 2] + 20), "head_bad": None, "top": False, "ends": False, "head": 0.25, "zcut": 0.55},
    # Carol Singer Harmony: ghosts of her gold music-note clip and skin-brown
    # patches in the back and sides of her black hair (her red beret stays:
    # red has far less green)
    "carol-harmony": {"hair": dark_hair, "bad": lambda c: yellowish(c) | ((c.sum(axis=1) >= 150) & (c[:, 0] > c[:, 2] + 15) & (c[:, 1] > 0.5 * c[:, 0])), "head_bad": None, "top": False, "ends": True, "head": 0.25, "zcut": 0.6},
    "autumn-cloud": {"hair": lambda c: (c.min(axis=1) > 165) & (c[:, 2] >= c[:, 0] - 12), "bad": orange, "head_bad": None, "top": True, "ends": False, "head": 0.25, "zcut": 0.85,
                     "pale": (0.13, lambda c: (c[:, 0] > 190) & (c[:, 2] < c[:, 0] - 25) & (c[:, 1] > 0.6 * c[:, 0]))},
}


def red_or_green(col):
    r, g, b = col[:, 0], col[:, 1], col[:, 2]
    red = (r > 110) & (g < 0.5 * r) & (b < 0.7 * r)  # (skin shadows are near 0.6)
    green = (g > r * 1.05) & (g > b * 1.15) & (g > 60)
    return red | green


def swap_image(glb_path, png_bytes, out_path):
    data = open(glb_path, "rb").read()
    jlen = struct.unpack("<I", data[12:16])[0]
    gltf = json.loads(data[20:20 + jlen])
    bstart = 20 + jlen + 8
    blen = struct.unpack("<I", data[20 + jlen:24 + jlen])[0]
    binary = data[bstart:bstart + blen]
    assert len(gltf["images"]) == 1, "expected one image"
    img_bv = gltf["images"][0]["bufferView"]
    pieces, off = [], 0
    for i, bv in enumerate(gltf["bufferViews"]):
        chunk = png_bytes if i == img_bv else binary[bv.get("byteOffset", 0):bv.get("byteOffset", 0) + bv["byteLength"]]
        pad = (-off) % 4
        pieces.append(b"\0" * pad)
        off += pad
        bv["byteOffset"] = off
        bv["byteLength"] = len(chunk)
        pieces.append(chunk)
        off += len(chunk)
    newbin = b"".join(pieces)
    newbin += b"\0" * ((-len(newbin)) % 4)
    gltf["buffers"][0]["byteLength"] = len(newbin)
    js = json.dumps(gltf, separators=(",", ":")).encode()
    js += b" " * ((-len(js)) % 4)
    total = 12 + 8 + len(js) + 8 + len(newbin)
    out = (b"glTF" + struct.pack("<II", 2, total) + struct.pack("<I", len(js)) + b"JSON" + js
           + struct.pack("<I", len(newbin)) + b"BIN\0" + newbin)
    open(out_path, "wb").write(out)


def clean(name):
    glb = MODELS / f"{name}-toon.glb"
    before = MODELS / f"{name}-toon-before-hair.glb"
    if not before.exists():
        shutil.copy2(glb, before)  # always clean from the painted model
    mesh = trimesh.load(before, force="scene", process=False).dump()[0]
    V = np.asarray(mesh.vertices, np.float64)  # painted models face +Z
    F = np.asarray(mesh.faces)
    uv = np.asarray(mesh.visual.uv, np.float64)
    tex = np.asarray(mesh.visual.material.baseColorTexture.convert("RGB")).copy()
    TH, TW = tex.shape[:2]
    uvpx = np.stack([uv[:, 0] * TW, (1 - uv[:, 1]) * TH], axis=1)
    fn = mesh.face_normals
    lo, hi = V.min(0), V.max(0)
    size = hi - lo
    cen = V[F].mean(axis=1)
    head_y = hi[1] - PROFILES[name].get("head", 0.30) * size[1]

    # the hair hanging behind the body, found on the model itself: in each
    # thin band of height below the head, the yellow (hair-colored) triangles
    # behind the body's back (the back of the waist, just below the hair).
    # (A first try lined it up with the back picture: it missed the ends.)
    fy = (cen[:, 1] - lo[1]) / size[1]
    mid = np.zeros((len(F), 3), np.float32)
    for f in range(len(F)):
        u, v = uvpx[F[f]].mean(axis=0)
        mid[f] = tex[int(np.clip(v, 0, TH - 1)), int(np.clip(u, 0, TW - 1))]
    prof = PROFILES[name]
    yel = prof["hair"](mid)
    step = 0.025
    bands = np.arange(0.0, (head_y - lo[1]) / size[1], step)
    with_hair = [b for b in bands if (yel & (fy >= b) & (fy < b + step) & (cen[:, 2] < 0)).sum() >= 20]
    region2 = np.zeros(len(F), bool)
    if with_hair and prof["ends"]:
        bottom = min(with_hair)
        below = (fy >= bottom - 0.08) & (fy < bottom - 0.01)
        z_body = cen[below, 2].min() - 0.005  # the back of the body under the hair
        for b0 in bands[bands >= bottom - step]:
            sel = (fy >= b0) & (fy < b0 + step)
            hx = cen[sel & yel & (cen[:, 2] < z_body), 0]
            if len(hx) < 5:
                continue
            region2 |= sel & (cen[:, 2] < z_body) & (cen[:, 0] > hx.min() - 0.01) & (cen[:, 0] < hx.max() + 0.01)
        print(f"{name}: hair ends at {bottom:.3f} of the height, body's back z {z_body:.3f}")
    # the head: only behind its middle, or up where the bows are (the cheeks,
    # jaw and neck keep their colors - their shadows are reddish)
    head = cen[:, 1] > head_y
    z_mid = cen[head, 2].min() + PROFILES[name].get("zcut", 0.5) * (cen[head, 2].max() - cen[head, 2].min())
    region1 = head & (fn[:, 2] < 0.35) & ((cen[:, 2] < z_mid) | ((cen[:, 1] > hi[1] - 0.13 * size[1]) & prof["top"]))
    todo = np.nonzero(region1 | region2)[0]

    # the hair color: the median of the yellow texels on the back of the head
    samples = []
    for f in np.nonzero((cen[:, 1] > head_y) & (fn[:, 2] < -0.6))[0]:
        pts, _ = raster(uvpx[F[f]], TW, TH)
        if pts is not None and len(pts):
            c = tex[pts[:, 1], pts[:, 0]].astype(np.float32)
            ok = prof["hair"](c)
            samples.append(c[ok])
    hair = np.median(np.concatenate(samples), axis=0)

    changed = 0
    for f in todo:
        pts, _ = raster(uvpx[F[f]], TW, TH)
        if pts is None or len(pts) == 0:
            continue
        c = tex[pts[:, 1], pts[:, 0]].astype(np.float32)
        bad = prof["bad"](c)
        # on the head a few pale-pink in-betweens of the smear go too
        if cen[f, 1] > head_y and prof["head_bad"]:
            bad |= prof["head_bad"](c)
        # (autumn-cloud) the pale blend of a clip into white hair, only high
        # on the head - above the ears and face, where there is no skin
        if prof.get("pale") and cen[f, 1] > hi[1] - prof["pale"][0] * size[1]:
            bad |= prof["pale"][1](c)
        if bad.any():
            tex[pts[bad, 1], pts[bad, 0]] = hair.astype(np.uint8)
            changed += int(bad.sum())
    # the chest: skin where the front picture shows the shirt -> the shirt's color
    if prof.get("chest"):
        from paint_toon import outline
        pic = np.asarray(Image.open(INPUT / name / "front-toon.png").convert("RGB")).astype(np.float32)
        _, (bx0, bx1, by0, by1) = outline(pic)
        fixed = 0
        band = (fn[:, 2] > 0.2) & (fy > 0.55) & (fy < 0.75)
        # the model's own shirt color there (the picture's is a shade darker:
        # its color would show as a patch)
        own = []
        for f in np.nonzero(band)[0]:
            pts, _ = raster(uvpx[F[f]], TW, TH)
            if pts is not None and len(pts):
                c = tex[pts[:, 1], pts[:, 0]].astype(np.float32)
                own.append(c[(c[:, 0] < 150) & (c[:, 1] < 0.7 * c[:, 0]) & (c.sum(axis=1) < 280)])
        shirt_col = np.median(np.concatenate(own), axis=0).astype(np.uint8)
        for f in np.nonzero(band)[0]:
            pts, bc = raster(uvpx[F[f]], TW, TH)
            if pts is None or len(pts) == 0:
                continue
            p3 = bc @ V[F[f]]
            # painted models face +Z: seen from the front, +X is on the picture's right
            ix = np.clip((bx0 + (p3[:, 0] - lo[0]) / size[0] * (bx1 - bx0)).astype(int), 0, pic.shape[1] - 1)
            iy = np.clip((by0 + (hi[1] - p3[:, 1]) / size[1] * (by1 - by0)).astype(int), 0, pic.shape[0] - 1)
            want = pic[iy, ix]
            have = tex[pts[:, 1], pts[:, 0]].astype(np.float32)
            skin = (have[:, 0] > 170) & (have[:, 1] > 0.5 * have[:, 0])
            shirt = (want[:, 0] < 140) & (want[:, 1] < 0.65 * want[:, 0] + 10) & (want.sum(axis=1) < 260)
            go = skin & shirt
            if go.any():
                tex[pts[go, 1], pts[go, 0]] = shirt_col
                fixed += int(go.sum())
        print(f"{name}: chest - {fixed} texels of skin where the picture shows the shirt -> {shirt_col.tolist()}")
    buf = io.BytesIO()
    Image.fromarray(tex).save(buf, format="PNG")
    swap_image(before, buf.getvalue(), glb)
    print(f"{name}: hair color {hair.astype(int).tolist()}, {len(todo)} triangles looked at, "
          f"{changed} texels repainted -> {glb.name}")
    from check_toon_models import check
    problems = check(glb)
    if problems:
        raise RuntimeError(f"{glb.name} failed its check: " + "; ".join(problems))
    print(f"{name}: checked - all good")


if __name__ == "__main__":
    for n in sys.argv[1:]:
        clean(n)
