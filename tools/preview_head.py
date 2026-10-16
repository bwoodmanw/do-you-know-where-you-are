"""A sharp close-up of a toon model's head from five sides (front, the two
three-quarters, the two sides), the texture sampled per pixel - for faces,
eyes and hoods that the whole-body preview (preview_glb.py) is too coarse for.
Models face +Z (paint_toon turns them).
Run with the Stable Fast 3D Python (numpy, trimesh):
  <sf3d-venv>\\Scripts\\python.exe tools\\preview_head.py art/models/ghostly-shadow-toon.glb out.png
"""
import sys
import numpy as np
import trimesh
from PIL import Image, ImageDraw

path, out = sys.argv[1], sys.argv[2]
mesh = trimesh.load(path, force="scene").dump()[0]
V = np.asarray(mesh.vertices, np.float64)
if len(sys.argv) > 3 and sys.argv[3] == "raw":
    V = V * np.array([-1.0, 1.0, -1.0])  # an unpainted Stable Fast 3D model faces -Z: turn it round
F = np.asarray(mesh.faces)
UV = np.asarray(mesh.visual.uv, np.float64)
tex = np.asarray(mesh.visual.material.baseColorTexture.convert("RGB"))
TH, TW = tex.shape[:2]
lo, hi = V.min(0), V.max(0)
h = hi[1] - lo[1]
head = V[:, 1] > hi[1] - 0.3 * h
c = V[head].mean(0)
S = 520


def view(yaw_deg):
    a = np.radians(yaw_deg)
    # camera looks along -Z after turning the model by -yaw (yaw 90 = from the model's left, +X... )
    R = np.array([[np.cos(a), 0, np.sin(a)], [0, 1, 0], [-np.sin(a), 0, np.cos(a)]])
    P = (V - c) @ R.T
    hv = P[head]
    span = max(np.ptp(hv[:, 0]), np.ptp(hv[:, 1])) * 1.15
    sc = S / span
    px = (P[:, 0] * sc + S / 2)
    py = (S / 2 - P[:, 1] * sc)
    z = P[:, 2]  # bigger = nearer the camera (camera on +Z)
    img = np.full((S, S, 3), (40, 26, 58), np.uint8)
    zb = np.full((S, S), -np.inf)
    for f in F:
        if not head[f].any():
            continue
        x0, y0 = px[f], py[f]
        mnx, mxx = int(max(0, np.floor(x0.min()))), int(min(S - 1, np.ceil(x0.max())))
        mny, mxy = int(max(0, np.floor(y0.min()))), int(min(S - 1, np.ceil(y0.max())))
        if mnx > mxx or mny > mxy:
            continue
        xs, ys = np.meshgrid(np.arange(mnx, mxx + 1) + 0.5, np.arange(mny, mxy + 1) + 0.5)
        (ax, bx, cx), (ay, by, cy) = x0, y0
        den = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(den) < 1e-9:
            continue
        w0 = ((by - cy) * (xs - cx) + (cx - bx) * (ys - cy)) / den
        w1 = ((cy - ay) * (xs - cx) + (ax - cx) * (ys - cy)) / den
        w2 = 1 - w0 - w1
        m = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
        if not m.any():
            continue
        zz = w0 * z[f[0]] + w1 * z[f[1]] + w2 * z[f[2]]
        yy, xx = (ys[m] - 0.5).astype(int), (xs[m] - 0.5).astype(int)
        zm = zz[m]
        nearer = zm > zb[yy, xx]
        if not nearer.any():
            continue
        yy, xx, zm = yy[nearer], xx[nearer], zm[nearer]
        u = (w0[m] * UV[f[0], 0] + w1[m] * UV[f[1], 0] + w2[m] * UV[f[2], 0])[nearer]
        v = (w0[m] * UV[f[0], 1] + w1[m] * UV[f[1], 1] + w2[m] * UV[f[2], 1])[nearer]
        tx = np.clip((u * TW).astype(int), 0, TW - 1)
        ty = np.clip(((1 - v) * TH).astype(int), 0, TH - 1)
        img[yy, xx] = tex[ty, tx]
        zb[yy, xx] = zm
    return Image.fromarray(img)


names = [(0, "front"), (-45, "3/4 left side"), (-90, "its LEFT side"), (45, "3/4 right side"), (90, "its RIGHT side")]
sheet = Image.new("RGB", (S * 5 + 60, S + 40), (20, 12, 30))
for i, (yaw, name) in enumerate(names):
    sheet.paste(view(yaw), (10 + i * (S + 10), 10))
    ImageDraw.Draw(sheet).text((20 + i * (S + 10), S + 16), name, fill=(255, 255, 255))
sheet.save(out)
print("wrote", out)
