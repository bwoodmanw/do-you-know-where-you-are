"""Swings a toon model's arms further out from the body (a wider A-pose), so
Studio's Avatar Setup can tell the arms from the body. 2 Nov: Chef Brainy's
arms hung 1-2% of his height from his sides and Avatar Setup errored.

Each arm turns about its shoulder (in the front view, around the front-back
axis): fully below the armpit, fading to nothing over the shoulder, so the
mesh bends instead of tearing. Normals turn with it; UVs and the texture are
untouched. Heights are fractions of the model's height, x of its width;
the defaults are measured on Chef Brainy (cross-sections, 2 Nov).

    python tools/arms_out.py art/models/chef-brainy-toon.glb 22
    -> art/models/chef-brainy-toon-arms.glb; renamed chef-brainy-arms-toon.glb
    (check_toon_models.py chef-brainy-arms), then scale_glb.py ... 5
"""
import json
import math
import struct
import sys

src, angle = sys.argv[1], math.radians(float(sys.argv[2]))
out = src[:-4] + "-arms.glb"
# (height fraction, |x| fraction of half-width beyond which it is arm),
# between the torso's side and the arm's inner side at each height. A third
# argument picks another character's measurements (4 Nov: "cloud" - her coat
# flares out, measured in cross-sections like Brainy's)
PROFILES = {
    "brainy": ([(0.30, 0.58), (0.40, 0.58), (0.45, 0.47), (0.48, 0.43), (0.51, 0.40), (0.54, 0.39), (0.58, 0.39)], 0.50, 0.57, (0.44, 0.555)),
    "cloud": ([(0.36, 0.78), (0.38, 0.75), (0.40, 0.70), (0.44, 0.65), (0.46, 0.58), (0.48, 0.53), (0.50, 0.49), (0.52, 0.46), (0.54, 0.43), (0.58, 0.42)], 0.50, 0.57, (0.43, 0.56)),
}
BOUNDARY, FULL_BELOW, NONE_ABOVE, PIVOT = PROFILES[sys.argv[3] if len(sys.argv) > 3 else "brainy"]
# FULL_BELOW, NONE_ABOVE: the turn fades out over the shoulder; PIVOT: the
# shoulder (|x| fraction of half-width, height fraction)

data = bytearray(open(src, "rb").read())
assert data[:4] == b"glTF"
jlen = struct.unpack("<I", data[12:16])[0]
gltf = json.loads(bytes(data[20:20 + jlen]))
bin_start = 20 + jlen + 8


def view(ai):
    acc = gltf["accessors"][ai]
    assert acc["componentType"] == 5126 and acc["type"] == "VEC3"
    bv = gltf["bufferViews"][acc["bufferView"]]
    return acc, bin_start + bv.get("byteOffset", 0) + acc.get("byteOffset", 0), bv.get("byteStride", 12)


def boundary(f):
    if f <= BOUNDARY[0][0]:
        return BOUNDARY[0][1]
    for (f0, b0), (f1, b1) in zip(BOUNDARY, BOUNDARY[1:]):
        if f <= f1:
            return b0 + (b1 - b0) * (f - f0) / (f1 - f0)
    return BOUNDARY[-1][1]


def smooth(t):
    t = min(1.0, max(0.0, t))
    return t * t * (3 - 2 * t)


done = set()
moved = 0
for mesh in gltf["meshes"]:
    for prim in mesh["primitives"]:
        pa = prim["attributes"]["POSITION"]
        if pa in done:
            continue
        done.add(pa)
        acc, start, stride = view(pa)
        lo, hi = acc["min"], acc["max"]
        half = max(abs(lo[0]), abs(hi[0]))
        H = hi[1] - lo[1]
        na = prim["attributes"].get("NORMAL")
        nacc, nstart, nstride = view(na) if na is not None else (None, None, None)
        new_min, new_max = [math.inf] * 3, [-math.inf] * 3
        for k in range(acc["count"]):
            off = start + k * stride
            x, y, z = struct.unpack_from("<3f", data, off)
            f = (y - lo[1]) / H
            side = 1 if x > 0 else -1
            w = 0.0
            if f > BOUNDARY[0][0] - 0.02 and abs(x) / half > boundary(f):
                w = 1.0 - smooth((f - FULL_BELOW) / (NONE_ABOVE - FULL_BELOW))
                # a soft edge at the boundary itself
                w *= smooth((abs(x) / half - boundary(f)) / 0.04)
            if w > 0:
                a = side * angle * w
                px, py = side * PIVOT[0] * half, lo[1] + PIVOT[1] * H
                dx, dy = x - px, y - py
                c, s = math.cos(a), math.sin(a)
                x, y = px + dx * c - dy * s, py + dx * s + dy * c
                struct.pack_into("<3f", data, off, x, y, z)
                if nacc is not None:
                    noff = nstart + k * nstride
                    nx, ny, nz = struct.unpack_from("<3f", data, noff)
                    struct.pack_into("<3f", data, noff, nx * c - ny * s, nx * s + ny * c, nz)
                moved += 1
            for i, v in enumerate((x, y, z)):
                new_min[i], new_max[i] = min(new_min[i], v), max(new_max[i], v)
        acc["min"], acc["max"] = new_min, new_max
js = json.dumps(gltf, separators=(",", ":")).encode()
js += b" " * ((4 - len(js) % 4) % 4)
rest = bytes(data[20 + jlen:])
head = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + len(rest))
open(out, "wb").write(head + struct.pack("<II", len(js), 0x4E4F534A) + js + rest)
print("wrote", out, "-", moved, "points turned")
