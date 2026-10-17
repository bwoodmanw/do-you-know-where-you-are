"""Writes a copy of a .glb with every vertex position multiplied by a factor
(normals, UVs, texture untouched), so Studio's Import 3D brings it in at a
normal character size. 16 Oct: imported at 0.93 studs tall, Avatar Setup
squeezed a full-size skeleton into Halloween Patch and Glow (root above the
head, shoulders off, floating) - a 5x copy arrives about 4.7 studs tall.

    python tools/scale_glb.py art/models/halloween-nurse-patch-toon.glb 5
    -> art/models/halloween-nurse-patch-toon-x5.glb
"""
import json
import struct
import sys

src, factor = sys.argv[1], float(sys.argv[2])
out = src[:-4] + "-x%g.glb" % factor
data = bytearray(open(src, "rb").read())
assert data[:4] == b"glTF"
jlen = struct.unpack("<I", data[12:16])[0]
gltf = json.loads(bytes(data[20:20 + jlen]))
bin_start = 20 + jlen + 8
done = set()
for mesh in gltf["meshes"]:
    for prim in mesh["primitives"]:
        ai = prim["attributes"]["POSITION"]
        if ai in done:
            continue
        done.add(ai)
        acc = gltf["accessors"][ai]
        assert acc["componentType"] == 5126 and acc["type"] == "VEC3"
        bv = gltf["bufferViews"][acc["bufferView"]]
        start = bin_start + bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
        stride = bv.get("byteStride", 12)
        for k in range(acc["count"]):
            off = start + k * stride
            x, y, z = struct.unpack_from("<3f", data, off)
            struct.pack_into("<3f", data, off, x * factor, y * factor, z * factor)
        acc["min"] = [v * factor for v in acc["min"]]
        acc["max"] = [v * factor for v in acc["max"]]
# node translations scale too (the toons have none, but keep it right)
for node in gltf.get("nodes", []):
    if "translation" in node:
        node["translation"] = [v * factor for v in node["translation"]]
js = json.dumps(gltf, separators=(",", ":")).encode()
js += b" " * ((4 - len(js) % 4) % 4)
rest = bytes(data[20 + jlen:])
head = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + len(rest))
open(out, "wb").write(head + struct.pack("<II", len(js), 0x4E4F534A) + js + rest)
print("wrote", out)
