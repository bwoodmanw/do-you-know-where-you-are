"""paint_toon.py - paints a toon model's colors straight from its pictures.

Stable Fast 3D builds the shape well from the front picture but guesses the
back (Tinker's blue smudge on his orange shirt) and washes colors out
(Shadow's black pants came out gray, 10 Oct). This keeps the model's shape
and UVs and repaints its color texture:
  - every part of the surface facing the front is colored from front-toon.png,
  - every part facing the back from back-toon.png,
  - sides (facing neither) keep Stable Fast 3D's colors, blended at the edges,
  - only what the camera can actually see is painted (a depth check, so the
    back picture never lands on the inside of an arm),
and drops the bumpy normal map and shine (flat cartoon colors, "PBR off").

The model's left-right width and height are lined up with the character's
outline in each picture (the plain gray background is found automatically).

Run with the Stable Fast 3D Python (it has trimesh and numpy):
  <sf3d-venv>\\Scripts\\python.exe tools\\paint_toon.py tinker [shadow ...]
  (no names: every art/models/<name>-toon.glb that has its two pictures)
Writes art/models/<name>-toon.glb (the unpainted one is kept as
<name>-toon-raw.glb the first time).
"""
import shutil
import sys
from pathlib import Path

import numpy as np
import trimesh
from PIL import Image

PROJECT = Path(__file__).resolve().parent.parent
MODELS = PROJECT / "art" / "models"
INPUT = PROJECT / "art" / "model-input"
FOLDERS = ["tinker", "brainy", "shadow", "muscle", "glow", "patch", "echo", "bramble", "halloween-nurse-patch",
           "tinker-pumpkin", "ghostly-shadow", "candy-glow", "space-cadet-brainy", "snow-day-muscle", "starlight-echo", "autumn-leaf-bramble", "muscle-mummy",
           "host", "host-gummy", "host-hospital", "host-caretaker", "host-clownbear", "host-anglerfish"]
FACING_MIN, FACING_FULL = 0.12, 0.45  # blend from side-on to fully facing


def outline(img):
    """the character's box in a picture: everything not the plain background"""
    a = img.astype(np.float32)
    border = np.concatenate([a[0], a[-1], a[:, 0], a[:, -1]])
    bg = np.median(border, axis=0)
    mask = np.abs(a - bg).sum(axis=2) > 40
    ys, xs = np.nonzero(mask)
    return mask, (xs.min(), xs.max(), ys.min(), ys.max())


def bary_grid(p, tri):
    """barycentric coordinates of points p (n,2) in triangle tri (3,2)"""
    a, b, c = tri
    v0, v1, v2 = b - a, c - a, p - a
    d00, d01, d11 = v0 @ v0, v0 @ v1, v1 @ v1
    den = d00 * d11 - d01 * d01
    if abs(den) < 1e-12:
        return None
    d20, d21 = v2 @ v0, v2 @ v1
    v = (d11 * d20 - d01 * d21) / den
    w = (d00 * d21 - d01 * d20) / den
    return np.stack([1 - v - w, v, w], axis=1)


def raster(tri, w, h):
    """pixel centers inside a triangle (pixel space) and their barycentrics"""
    x0, y0 = np.floor(tri.min(axis=0)).astype(int)
    x1, y1 = np.ceil(tri.max(axis=0)).astype(int)
    x0, y0, x1, y1 = max(x0, 0), max(y0, 0), min(x1, w - 1), min(y1, h - 1)
    if x1 < x0 or y1 < y0:
        return None, None
    xs, ys = np.meshgrid(np.arange(x0, x1 + 1), np.arange(y0, y1 + 1))
    pts = np.stack([xs.ravel() + 0.5, ys.ravel() + 0.5], axis=1)
    bc = bary_grid(pts, tri)
    if bc is None:
        return None, None
    inside = (bc >= -1e-4).all(axis=1)
    return pts[inside].astype(int), bc[inside]


def pad_islands(img, uvpx, F, grow=24):
    """the texture is cut into islands; the empty space between them shows up
    as dark lines along the seams once Studio shrinks the texture (Patch's face,
    10 Oct). Fill the space next to every island with its own edge colors."""
    H, W = img.shape[:2]
    used = np.zeros((H, W), bool)
    for f in F:
        pts, _ = raster(uvpx[f], W, H)
        if pts is not None and len(pts):
            used[pts[:, 1], pts[:, 0]] = True
    # 1 texel of slack round each triangle (they are rasterized at centers)
    grown = used.copy()
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        grown |= np.roll(np.roll(used, dy, 0), dx, 1)
    used = grown
    out = img.copy()
    for _ in range(grow):
        total = np.zeros_like(out)
        count = np.zeros((H, W), np.float32)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)):
            m = np.roll(np.roll(used, dy, 0), dx, 1)
            c = np.roll(np.roll(out, dy, 0), dx, 1)
            total += c * m[..., None]
            count += m
        edge = (~used) & (count > 0)
        if not edge.any():
            break
        out[edge] = total[edge] / count[edge][:, None]
        used = used | edge
    return out


def render_front(V, F, uv, T, px_h=900):
    """the model seen from the front (it faces -Z), colored from texture T"""
    lo, hi = V.min(axis=0), V.max(axis=0)
    scale = px_h / (hi[1] - lo[1])
    W, H = int((hi[0] - lo[0]) * scale) + 2, px_h + 2
    P = np.stack([(hi[0] - V[:, 0]) * scale, (hi[1] - V[:, 1]) * scale], axis=1)  # viewer's right is -X
    near = -V[:, 2]
    TH, TW = T.shape[:2]
    img = np.zeros((H, W, 3), np.float32)
    depth = np.full((H, W), -np.inf, np.float32)
    for f in range(len(F)):
        pts, bc = raster(P[F[f]], W, H)
        if pts is None or len(pts) == 0:
            continue
        z = bc @ near[F[f]]
        nearer = z > depth[pts[:, 1], pts[:, 0]]
        if not nearer.any():
            continue
        pts, bc, z = pts[nearer], bc[nearer], z[nearer]
        u = bc @ uv[F[f]]
        tx = np.clip((u[:, 0] * TW).astype(int), 0, TW - 1)
        ty = np.clip(((1 - u[:, 1]) * TH).astype(int), 0, TH - 1)
        img[pts[:, 1], pts[:, 0]] = T[ty, tx]
        depth[pts[:, 1], pts[:, 0]] = z
    return img, scale, lo, hi


def _gray(a):
    return a[..., :3].astype(np.float32) @ np.array([0.3, 0.59, 0.11], np.float32)


def _ncc(a, b):
    a = a - a.mean()
    b = b - b.mean()
    d = np.sqrt((a * a).sum() * (b * b).sum())
    return float((a * b).sum() / d) if d > 0 else -1.0


FACE_SHARE = 0.25  # the face's corner: a quarter of the texture's width and height


def face_corner(name, V, F, uv, fn, tex, pic):
    """Stable Fast 3D gives a toon's face ~50 x 50 texture pixels (blurry eyes in
    Roblox, 10 Oct). The front of the head gets its own corner of the texture
    (256 x 256 of 1024), filled straight from the approved picture, lined up
    with the model's own face by best match; everything else is shrunk to the
    other 3/4 of the texture. Returns new vertices, triangles, UVs, texture."""
    TH, TW = tex.shape[:2]
    render, scale, lo, hi = render_front(V, F, uv, tex)
    RH, RW = render.shape[:2]
    h = hi[1] - lo[1]
    cx = (lo[0] + hi[0]) / 2
    # line the picture up with the model's own (blurry) face
    _, (bx0, bx1, by0, by1) = outline(pic)
    fy0, fy1 = int(0.085 * RH), int(0.245 * RH)
    rcx = (hi[0] - cx) * scale
    fw = int(0.15 * RH)
    model_face = _gray(render[fy0:fy1, int(rcx - fw / 2):int(rcx + fw / 2)])
    pg = _gray(pic)
    s0 = (by1 - by0) / RH
    best = (-2.0, (s0, 0, 0))
    for ds in np.linspace(0.9, 1.1, 21):
        s = s0 * ds
        for dy in range(-30, 31, 3):
            for dx in range(-30, 31, 3):
                x0 = bx0 + (rcx - fw / 2) * s + dx
                y0 = by0 + fy0 * s + dy
                x1, y1 = x0 + fw * s, y0 + (fy1 - fy0) * s
                if x0 < 0 or y0 < 0 or x1 >= pic.shape[1] or y1 >= pic.shape[0]:
                    continue
                crop = Image.fromarray(pg[int(y0):int(y1), int(x0):int(x1)].astype(np.uint8))
                crop = np.asarray(crop.resize(model_face.shape[::-1]), np.float32)
                score = _ncc(crop, model_face)
                if score > best[0]:
                    best = (score, (s, dx, dy))
    score, (s, dx, dy) = best
    # the front of the head: facing forward, from the top down to the chin
    c = V[F].mean(axis=1)
    sel = (-fn[:, 2] > 0.55) & (c[:, 1] > hi[1] - 0.27 * h) & (np.abs(c[:, 0] - cx) < 0.13 * h)
    if sel.sum() < 20 or score < 0.2:
        print(f"{name}: face corner skipped (face match {score:.2f}, {int(sel.sum())} triangles)")
        return V, F, uv, tex
    # Also repaint the head's front in the ORIGINAL texture from the picture,
    # lined up the same way (10 Oct: in Roblox some face triangles still showed
    # Stable Fast 3D's brownish old face - Avatar Setup can merge the face's
    # copied corners back; then they fall back here, now with the right
    # colors). Cheeks and jaw just outside the sharp corner get it too.
    fg_mask0, _ = outline(pic)
    TH0, TW0 = tex.shape[:2]
    uvpx0 = np.stack([uv[:, 0] * TW0, (1 - uv[:, 1]) * TH0], axis=1)
    near_face = (-fn[:, 2] > 0.2) & (c[:, 1] > hi[1] - 0.29 * h) & (np.abs(c[:, 0] - cx) < 0.16 * h)
    tex = tex.copy()
    for f in np.nonzero(near_face)[0]:
        pts, bc = raster(uvpx0[F[f]], TW0, TH0)
        if pts is None or len(pts) == 0:
            continue
        p3 = bc @ V[F[f]]
        rx = (hi[0] - p3[:, 0]) * scale
        ry = (hi[1] - p3[:, 1]) * scale
        ix = np.clip((bx0 + rx * s + dx).astype(int), 0, pic.shape[1] - 1)
        iy = np.clip((by0 + ry * s + dy).astype(int), 0, pic.shape[0] - 1)
        ok = fg_mask0[iy, ix]
        # blend in toward the sides, so there is no hard edge to the side hair
        w = min(1.0, (-fn[f, 2] - 0.2) / 0.3)
        tx, ty = pts[ok, 0], pts[ok, 1]
        tex[ty, tx] = tex[ty, tx] * (1 - w) + pic[iy[ok], ix[ok]].astype(np.float32) * w
    used = np.unique(F[sel])
    x0b, x1b = V[used, 0].min(), V[used, 0].max()
    y0b, y1b = V[used, 1].min(), V[used, 1].max()
    side = max(x1b - x0b, y1b - y0b) * 1.04
    mx, my = (x0b + x1b) / 2, (y0b + y1b) / 2
    xmax, ymin = mx + side / 2, my - side / 2
    # everything else: 3/4 size in the texture's lower-left
    k = 1 - FACE_SHARE
    uv2 = uv * k
    new_tex = np.zeros_like(tex)
    small = np.asarray(Image.fromarray(np.clip(tex, 0, 255).astype(np.uint8)).resize(
        (int(TW * k), int(TH * k)), Image.LANCZOS), np.float32)
    new_tex[TH - small.shape[0]:, :small.shape[1]] = small
    # the face triangles get their own copies of their corners, mapped flat
    # (as seen from the front) into the upper-right corner
    remap = {}
    V2, uvl, F2 = [V], [uv2], F.copy()
    extra_v, extra_uv = [], []
    for f in np.nonzero(sel)[0]:
        for j in range(3):
            vi = F[f, j]
            if vi not in remap:
                remap[vi] = len(V) + len(extra_v)
                extra_v.append(V[vi])
                u = k + FACE_SHARE * (xmax - V[vi, 0]) / side
                v = k + FACE_SHARE * (V[vi, 1] - ymin) / side
                extra_uv.append([u, v])
            F2[f, j] = remap[vi]
    V2 = np.concatenate([V, np.array(extra_v)])
    uv2 = np.concatenate([uv2, np.array(extra_uv)])
    # fill the corner from the picture: corner pixel -> the model -> the picture
    cw, ch = int(TW * FACE_SHARE), int(TH * FACE_SHARE)
    xs, ys = np.meshgrid(np.arange(cw), np.arange(ch))
    ul = (xs + 0.5) / cw
    vl = 1 - (ys + 0.5) / ch
    mxp = xmax - ul * side
    myp = ymin + vl * side
    rx = (hi[0] - mxp) * scale
    ry = (hi[1] - myp) * scale
    px = np.clip(bx0 + rx * s + dx, 0, pic.shape[1] - 1).astype(int)
    py = np.clip(by0 + ry * s + dy, 0, pic.shape[0] - 1).astype(int)
    corner = pic[py, px].astype(np.float32)
    # where the picture shows its gray background (just past the hair or the
    # jaw), use the nearest color of the character instead (Echo's hairline)
    fg_mask, _ = outline(pic)
    known = fg_mask[py, px].copy()
    for _ in range(60):
        if known.all():
            break
        total = np.zeros_like(corner)
        count = np.zeros(known.shape, np.float32)
        for oy, ox in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            m = np.roll(np.roll(known, oy, 0), ox, 1)
            total += np.roll(np.roll(corner, oy, 0), ox, 1) * m[..., None]
            count += m
        grow = (~known) & (count > 0)
        corner[grow] = total[grow] / count[grow][:, None]
        known |= grow
    new_tex[0:ch, TW - cw:TW] = corner
    print(f"{name}: face corner from the picture (match {score:.2f}, {int(sel.sum())} triangles, {cw}x{ch} pixels for the face)")
    return V2, F2, uv2, new_tex


def paint(name):
    glb = MODELS / f"{name}-toon.glb"
    raw = MODELS / f"{name}-toon-raw.glb"
    pics = {d: INPUT / name / f"{d}-toon.png" for d in ("front", "back")}
    if not glb.exists() or not all(p.exists() for p in pics.values()):
        print(f"skip {name}: needs {glb.name} and both pictures")
        return
    if not raw.exists():
        shutil.copy2(glb, raw)  # always paint from the untouched model
    parts = trimesh.load(raw, force="scene").dump()  # the mesh, placed as in the scene
    if len(parts) != 1:
        print(f"skip {name}: expected one mesh, found {len(parts)}")
        return
    mesh = parts[0]
    V, F = mesh.vertices, mesh.faces
    uv = mesh.visual.uv
    tex = np.asarray(mesh.visual.material.baseColorTexture.convert("RGB")).astype(np.float32)
    TH, TW = tex.shape[:2]
    fn = mesh.face_normals
    lo, hi = V.min(axis=0), V.max(axis=0)
    size = hi - lo
    # texel position of each vertex (glTF images start at the top)
    uvpx = np.stack([uv[:, 0] * TW, (1 - uv[:, 1]) * TH], axis=1)

    # 10 Oct (Patch's face came out smeared): the FRONT keeps Stable Fast 3D's
    # own colors - it built the shape from that very picture, so its face lines
    # up exactly - and only has its colors corrected (learned from the front
    # picture); the BACK, which it guessed, is painted from the back picture.
    painted = np.zeros((TH, TW, 3), np.float32)  # the back picture's colors
    best = np.zeros((TH, TW), np.float32)  # how much of each texel they cover
    pairs_tex, pairs_pic = [], []  # front: Stable Fast 3D's color -> the picture's
    # Stable Fast 3D's models face -Z (checked on Tinker and Shadow, 10 Oct)
    for view, sign in (("front", -1.0), ("back", 1.0)):
        img = np.asarray(Image.open(pics[view]).convert("RGB"))
        IH, IW = img.shape[:2]
        mask, (bx0, bx1, by0, by1) = outline(img)
        # the model's box -> the outline's box (a camera looking along -Z has +X
        # on its right; one looking along +Z has +X on its left)
        fx = (V[:, 0] - lo[0]) / size[0] if sign > 0 else (hi[0] - V[:, 0]) / size[0]
        px = bx0 + fx * (bx1 - bx0)
        py = by0 + (hi[1] - V[:, 1]) / size[1] * (by1 - by0)
        near = sign * V[:, 2]  # bigger = nearer this view's camera
        P = np.stack([px, py], axis=1)
        # depth from this view: the nearest surface at each picture pixel
        depth = np.full((IH, IW), -np.inf, np.float32)
        facing = sign * fn[:, 2]
        for f in np.nonzero(facing > 0)[0]:
            pts, bc = raster(P[F[f]], IW, IH)
            if pts is None or len(pts) == 0:
                continue
            z = bc @ near[F[f]]
            cur = depth[pts[:, 1], pts[:, 0]]
            depth[pts[:, 1], pts[:, 0]] = np.maximum(cur, z)
        eps = 0.02 * size[2] + 1e-6
        # paint every texel of the faces that face this view
        for f in np.nonzero(facing > FACING_MIN)[0]:
            pts, bc = raster(uvpx[F[f]], TW, TH)
            if pts is None or len(pts) == 0:
                continue
            ip = bc @ P[F[f]]
            ix = np.clip(ip[:, 0].astype(int), 0, IW - 1)
            iy = np.clip(ip[:, 1].astype(int), 0, IH - 1)
            z = bc @ near[F[f]]
            seen = (z >= depth[iy, ix] - eps) & mask[iy, ix]
            if not seen.any():
                continue
            w = min(1.0, (facing[f] - FACING_MIN) / (FACING_FULL - FACING_MIN))
            tx, ty = pts[seen, 0], pts[seen, 1]
            col = img[iy[seen], ix[seen]].astype(np.float32)
            if view == "front":
                if w >= 0.99:  # squarely facing: a good sample for the color fit
                    pairs_tex.append(tex[ty, tx])
                    pairs_pic.append(col)
                continue
            keep = w > best[ty, tx]
            painted[ty[keep], tx[keep]] = col[keep]
            best[ty[keep], tx[keep]] = w
    # how Stable Fast 3D shifted the colors (washed out), from the front, undone
    # everywhere; then the back picture laid over its guessed back
    out = tex.copy()
    if pairs_tex and sum(len(p) for p in pairs_tex) > 500:
        A = np.concatenate(pairs_tex)
        B = np.concatenate(pairs_pic)
        X = np.concatenate([A, np.ones((len(A), 1), np.float32)], axis=1)
        M, *_ = np.linalg.lstsq(X, B, rcond=None)
        allX = np.concatenate([tex.reshape(-1, 3), np.ones((TH * TW, 1), np.float32)], axis=1)
        out = (allX @ M).reshape(TH, TW, 3)
    out = out * (1 - best)[..., None] + painted * best[..., None]
    print(f"{name}: front colors corrected, back painted from the back picture ({int((best > 0).sum() * 100 / (TH * TW))}% of the texture)")
    # the face gets its own sharp corner of the texture, from the picture
    front_pic = np.asarray(Image.open(pics["front"]).convert("RGB"))
    if name.startswith("host"):
        V2, F2, uv2 = V, F, uv  # hosts: pumpkins, lamps and fish heads - no face corner
    else:
        V2, F2, uv2, out = face_corner(name, V, F, uv, fn, out, front_pic)
    uvpx2 = np.stack([uv2[:, 0] * TW, (1 - uv2[:, 1]) * TH], axis=1)
    out = pad_islands(out, uvpx2, F2)

    material = trimesh.visual.material.PBRMaterial(
        baseColorTexture=Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)),
        metallicFactor=0.0, roughnessFactor=1.0)
    mesh = trimesh.Trimesh(vertices=V2, faces=F2, process=False)
    mesh.visual = trimesh.visual.TextureVisuals(uv=uv2, material=material)
    F = F2
    # Stable Fast 3D's models face -Z; Roblox's Import 3D shows them back to
    # front (Brent had to set World Forward each time). Turned round here, they
    # import facing forward with the default settings.
    mesh.apply_transform(trimesh.transformations.rotation_matrix(np.pi, [0, 1, 0]))
    mesh.export(glb)
    print(f"{name}: wrote {glb.name} ({len(F)} triangles, no normal map)")


if __name__ == "__main__":
    for n in sys.argv[1:] or FOLDERS:
        paint(n)
