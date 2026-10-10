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
FOLDERS = ["tinker", "brainy", "shadow", "muscle", "glow", "patch", "echo", "bramble", "halloween-nurse-patch"]
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

    out = tex.copy()
    best = np.zeros((TH, TW), np.float32)  # the strongest view painted so far
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
            keep = w > best[ty, tx]
            tx, ty = tx[keep], ty[keep]
            col = img[iy[seen][keep], ix[seen][keep]].astype(np.float32)
            out[ty, tx] = tex[ty, tx] * (1 - w) + col * w
            best[ty, tx] = w
    # the sides (painted by neither picture) keep Stable Fast 3D's washed-out
    # colors: learn how it shifted colors where both are known (fully painted
    # texels) and undo that shift everywhere it left its own colors
    full = best >= 0.99
    if full.sum() > 500:
        X = np.concatenate([tex[full], np.ones((int(full.sum()), 1), np.float32)], axis=1)
        M, *_ = np.linalg.lstsq(X, out[full], rcond=None)
        allX = np.concatenate([tex.reshape(-1, 3), np.ones((TH * TW, 1), np.float32)], axis=1)
        corrected = (allX @ M).reshape(TH, TW, 3)
        out = out + (corrected - tex) * (1 - best)[..., None]
    print(f"{name}: painted {int((best > 0).sum() * 100 / (TH * TW))}% of the texture from the pictures, colors matched elsewhere")

    material = trimesh.visual.material.PBRMaterial(
        baseColorTexture=Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)),
        metallicFactor=0.0, roughnessFactor=1.0)
    mesh.visual = trimesh.visual.TextureVisuals(uv=uv, material=material)
    mesh.export(glb)
    print(f"{name}: wrote {glb.name} ({len(F)} triangles, no normal map)")


if __name__ == "__main__":
    for n in sys.argv[1:] or FOLDERS:
        paint(n)
