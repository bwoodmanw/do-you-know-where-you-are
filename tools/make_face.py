"""make_face.py - a crisp face for a toon model, cut from its approved picture.

Stable Fast 3D gives a toon's whole face only ~50 x 50 texture pixels, so the
eyes and mouth come out blurry in Roblox (Echo, 10 Oct). This makes a face
picture to lay on the head (a Roblox Texture, Config.FACES / Faces.luau):

  1. render the model's own (blurry but correctly placed) face from the front,
  2. slide and scale the approved front picture until its face lines up with
     that render (best match),
  3. cut the face (brows to chin) out of the picture with soft edges, centered
     on a transparent square, and print where it sits on the model.

Run with the Stable Fast 3D Python:
  <sf3d-venv>\\Scripts\\python.exe tools\\make_face.py echo
Writes art/faces/<name>-face.png (upload it) and prints the Config.FACES line.
"""
import sys
from pathlib import Path

import numpy as np
import trimesh
from PIL import Image, ImageDraw, ImageFilter

PROJECT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))
from paint_toon import outline, raster  # noqa: E402

CANVAS = 1024  # the face picture: the face fills the middle third
FACE_SHARE = 1 / 3


def render_front(mesh, tex, px_h=900):
    """the model seen from the front (it faces -Z), colored from its texture"""
    V, F, uv = mesh.vertices, mesh.faces, mesh.visual.uv
    lo, hi = V.min(axis=0), V.max(axis=0)
    size = hi - lo
    scale = px_h / size[1]
    W, H = int(size[0] * scale) + 2, px_h + 2
    # seen from -Z: the viewer's right is -X
    P = np.stack([(hi[0] - V[:, 0]) * scale, (hi[1] - V[:, 1]) * scale], axis=1)
    near = -V[:, 2]
    T = np.asarray(tex.convert("RGB")).astype(np.float32)
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


def gray(a):
    return a[..., :3].astype(np.float32) @ np.array([0.3, 0.59, 0.11], np.float32)


def ncc(a, b):
    a = a - a.mean()
    b = b - b.mean()
    d = np.sqrt((a * a).sum() * (b * b).sum())
    return float((a * b).sum() / d) if d > 0 else -1.0


def make(name):
    glb = PROJECT / "art" / "models" / f"{name}-toon.glb"
    pic_path = PROJECT / "art" / "model-input" / name / "front-toon.png"
    mesh = trimesh.load(glb, force="scene").dump()[0]
    # paint_toon turns the models round to face +Z for Roblox; face -Z again here
    mesh.apply_transform(trimesh.transformations.rotation_matrix(np.pi, [0, 1, 0]))
    render, scale, lo, hi = render_front(mesh, mesh.visual.material.baseColorTexture)
    RH, RW = render.shape[:2]
    body_h = hi[1] - lo[1]
    # the face on the model: brows to chin, the middle of the head (render px)
    fy0, fy1 = int(0.085 * RH), int(0.245 * RH)
    cx = RW / 2
    fw = int(0.15 * RH)
    model_face = gray(render[fy0:fy1, int(cx - fw / 2):int(cx + fw / 2)])

    pic = np.asarray(Image.open(pic_path).convert("RGB"))
    _, (bx0, bx1, by0, by1) = outline(pic)
    # first guess: the picture's outline over the model's (as the painting does)
    s0 = (by1 - by0) / RH
    best = (-2.0, None)
    pg = gray(pic)
    for ds in np.linspace(0.9, 1.1, 21):
        s = s0 * ds
        for dy in range(-30, 31, 3):
            for dx in range(-30, 31, 3):
                # model render px -> picture px
                x0 = bx0 + (cx - fw / 2) * s + dx
                y0 = by0 + fy0 * s + dy
                x1, y1 = x0 + fw * s, y0 + (fy1 - fy0) * s
                if x0 < 0 or y0 < 0 or x1 >= pic.shape[1] or y1 >= pic.shape[0]:
                    continue
                crop = Image.fromarray(pg[int(y0):int(y1), int(x0):int(x1)].astype(np.uint8))
                crop = np.asarray(crop.resize(model_face.shape[::-1]), np.float32)
                score = ncc(crop, model_face)
                if score > best[0]:
                    best = (score, (s, dx, dy))
    score, (s, dx, dy) = best
    print(f"{name}: picture lined up with the model's face (match {score:.2f}; 1.0 = perfect)")

    # the face rectangle in picture px, a little roomier than brows-to-chin
    pad = 0.12
    fx0 = bx0 + (cx - fw / 2 * (1 + pad)) * s + dx
    fx1 = bx0 + (cx + fw / 2 * (1 + pad)) * s + dx
    fy0p = by0 + (fy0 - (fy1 - fy0) * pad / 2) * s + dy
    fy1p = by0 + (fy1 + (fy1 - fy0) * pad / 2) * s + dy
    face = Image.fromarray(pic).crop((int(fx0), int(fy0p), int(fx1), int(fy1p)))
    # soft oval edges, so it fades into the model's skin
    fwpx, fhpx = face.size
    mask = Image.new("L", face.size, 0)
    ImageDraw.Draw(mask).ellipse((fwpx * 0.06, fhpx * 0.04, fwpx * 0.94, fhpx * 0.98), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(min(fwpx, fhpx) * 0.06))
    face.putalpha(mask)
    # on a transparent square: the face in the middle third
    side = int(max(fwpx, fhpx) / FACE_SHARE)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(face, ((side - fwpx) // 2, (side - fhpx) // 2), face)
    canvas = canvas.resize((CANVAS, CANVAS), Image.LANCZOS)
    out = PROJECT / "art" / "faces" / f"{name}-face.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out)

    # where the face sits, in character heights: its center below the top, its
    # offset to the character's right, and the whole square's size
    # (the picture was shifted to fit the model, so on the model the face is
    # where the model's own face area is)
    top = (fy0 + fy1) / 2 / RH
    right = 0.0  # centered on the head
    square = side / s / RH
    print(f"{name}: wrote {out.relative_to(PROJECT)} ({fwpx}x{fhpx} picture pixels for the face)")
    print(f'Config.FACES line: {name}: {{ top = {top:.4f}, left = {right:.4f}, size = {square:.4f} }}')
    return out


if __name__ == "__main__":
    for n in sys.argv[1:] or ["echo"]:
        make(n)
