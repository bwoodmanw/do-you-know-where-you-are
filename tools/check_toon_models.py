"""check_toon_models.py - checks a finished toon model before it goes to Roblox.

Everything here broke at least once on 10 Oct; paint_toon.py runs this on
every file it writes and stops (FAILED in make_toon_models) if any fails:

  - NORMAL saved, and pointing the way the surface faces: without normals
    Studio welds points that share a spot and the texture breaks along every
    seam (lines across Patch's face, her striped legs),
  - TEXCOORD_0 and one embedded color texture, 1024 x 1024 (Roblox's limit),
  - one mesh, 1,000 - 12,000 triangles,
  - facing forward for Roblox (+Z): Stable Fast 3D makes them facing -Z and
    Roblox showed them back to front,
  - characters and skins (not hosts): the sharp face corner is there (the
    texture's top-right quarter is in use) and the triangles using it face
    forward.

Run by hand (any Python with trimesh, e.g. the Stable Fast 3D one):
  <sf3d-venv>\\Scripts\\python.exe tools\\check_toon_models.py          (all)
  <sf3d-venv>\\Scripts\\python.exe tools\\check_toon_models.py patch    (one)
"""
import json
import struct
import sys
from pathlib import Path

import numpy as np
import trimesh

PROJECT = Path(__file__).resolve().parent.parent
MODELS = PROJECT / "art" / "models"


def gltf_json(path):
    b = path.read_bytes()
    if b[:4] != b"glTF":
        raise ValueError("not a .glb file")
    n = struct.unpack_from("<I", b, 12)[0]
    return json.loads(b[20:20 + n])


def check(path, host=None):
    """the problems with one model file ([] = good)"""
    path = Path(path)
    name = path.name.replace("-toon.glb", "")
    if host is None:
        host = name.startswith("host")
    problems = []
    try:
        j = gltf_json(path)
    except Exception as e:
        return [f"can't read it: {e}"]
    meshes = j.get("meshes", [])
    prims = [p for m in meshes for p in m.get("primitives", [])]
    if len(prims) != 1:
        problems.append(f"{len(prims)} meshes - Avatar Setup wants one")
    attrs = prims[0].get("attributes", {}) if prims else {}
    if "NORMAL" not in attrs:
        problems.append("no NORMAL (surface directions) - Studio would weld the seams and break the texture")
    if "TEXCOORD_0" not in attrs:
        problems.append("no TEXCOORD_0 (texture coordinates)")
    if len(j.get("images", [])) != 1:
        problems.append(f"{len(j.get('images', []))} textures embedded - expected exactly 1")

    scene = trimesh.load(path, force="scene")
    parts = scene.dump()
    if len(parts) != 1:
        return problems + [f"{len(parts)} meshes after loading"]
    m = parts[0]
    tris = len(m.faces)
    if not 1000 <= tris <= 12000:
        problems.append(f"{tris} triangles - expected 1,000 - 12,000")
    tex = getattr(m.visual.material, "baseColorTexture", None)
    if tex is None:
        return problems + ["no color texture on the material"]
    if tex.size != (1024, 1024):
        problems.append(f"texture {tex.size[0]}x{tex.size[1]} - Roblox shows at most 1024x1024")
    fn = m.face_normals
    if "NORMAL" in attrs:
        vn = np.asarray(m.vertex_normals)
        agree = float((vn[m.faces] * fn[:, None, :]).sum(-1).mean())
        if agree < 0.85:
            problems.append(f"normals point the wrong way (agreement {agree:.2f}, want 0.85+)")
    # facing forward: the head's front (top quarter, the middle) faces +Z
    V = m.vertices
    lo, hi = V.min(axis=0), V.max(axis=0)
    h = hi[1] - lo[1]
    c = V[m.faces].mean(axis=1)
    head = (c[:, 1] > hi[1] - 0.25 * h) & (np.abs(c[:, 0] - (lo[0] + hi[0]) / 2) < 0.1 * h)
    area = m.area_faces
    if head.any():
        facing = float((fn[head, 2] * area[head]).sum() / area[head].sum())
    else:
        facing = 0.0
    uv = m.visual.uv
    corner = (uv[m.faces][:, :, 0].min(axis=1) > 0.74) & (uv[m.faces][:, :, 1].min(axis=1) > 0.74)
    if not host:
        if corner.sum() < 20:
            problems.append(f"no sharp face corner ({int(corner.sum())} triangles use it) - paint_toon's face step didn't run")
        else:
            fz = float((fn[corner, 2] * area[corner]).sum() / area[corner].sum())
            if fz < 0.3:
                problems.append(f"the face looks backward (face triangles facing {fz:+.2f} on Z, want +) - not turned round for Roblox")
    elif facing < -0.05:
        problems.append(f"the head's front faces -Z ({facing:+.2f}) - not turned round for Roblox")
    return problems


def main():
    names = sys.argv[1:]
    files = [MODELS / f"{n}-toon.glb" for n in names] if names else sorted(MODELS.glob("*-toon.glb"))
    bad = 0
    for f in files:
        if not f.exists():
            print(f"MISSING {f.name}")
            bad += 1
            continue
        problems = check(f)
        if problems:
            bad += 1
            print(f"PROBLEM {f.name}:")
            for p in problems:
                print(f"   - {p}")
        else:
            print(f"ok      {f.name}")
    print("ALL GOOD" if bad == 0 else f"{bad} model(s) need fixing")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
