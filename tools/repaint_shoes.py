"""Repaints the red marks on a character's shoes in its texture (Muscle's
trainers carried a swoosh-like mark from the source picture).

Usage: python tools/repaint_shoes.py art/models/muscle.glb <out folder>
Writes <out>/color-clean.png (the new texture to upload to Roblox) and
<out>/clean.glb (the same model with it, for tools/preview_glb.py).

The shoes are found from the model: every triangle in the bottom 9% of its
height. Only red-ish pixels inside those triangles change, to grey of the
same brightness, so the shoes keep their shading.
"""
import io
import json
import os
import struct
import sys
from PIL import Image, ImageDraw, ImageFilter

src, outdir = sys.argv[1], sys.argv[2]
os.makedirs(outdir, exist_ok=True)
data = open(src, "rb").read()
jlen = struct.unpack("<I", data[12:16])[0]
gltf = json.loads(data[20:20 + jlen])
bin_start = 20 + jlen + 8
binary = data[bin_start:]

CT = {5126: ("f", 4), 5125: ("I", 4), 5123: ("H", 2), 5121: ("B", 1)}
NC = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def accessor(i):
    a = gltf["accessors"][i]
    bv = gltf["bufferViews"][a["bufferView"]]
    fmt, size = CT[a["componentType"]]
    n = NC[a["type"]]
    start = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    stride = bv.get("byteStride", size * n)
    res = []
    for k in range(a["count"]):
        off = start + k * stride
        vals = struct.unpack("<" + fmt * n, binary[off:off + size * n])
        res.append(vals if n > 1 else vals[0])
    return res


prim = gltf["meshes"][0]["primitives"][0]
pos = accessor(prim["attributes"]["POSITION"])
uv = accessor(prim["attributes"]["TEXCOORD_0"])
idx = accessor(prim["indices"])
mat = gltf["materials"][prim.get("material", 0)]
tex_i = mat["pbrMetallicRoughness"]["baseColorTexture"]["index"]
img_i = gltf["textures"][tex_i]["source"]
bv = gltf["bufferViews"][gltf["images"][img_i]["bufferView"]]
img_bytes = binary[bv.get("byteOffset", 0): bv.get("byteOffset", 0) + bv["byteLength"]]
tex = Image.open(io.BytesIO(img_bytes)).convert("RGB")
W, H = tex.size

ys = [p[1] for p in pos]
y0, y1 = min(ys), max(ys)
cut = y0 + (y1 - y0) * 0.09
mask = Image.new("L", (W, H), 0)
draw = ImageDraw.Draw(mask)
shoe_tris = 0
for t in range(0, len(idx), 3):
    a, b, c = idx[t], idx[t + 1], idx[t + 2]
    if max(pos[a][1], pos[b][1], pos[c][1]) <= cut:
        shoe_tris += 1
        draw.polygon([(uv[v][0] * W, uv[v][1] * H) for v in (a, b, c)], fill=255)
mask = mask.filter(ImageFilter.MaxFilter(9))  # cover the seams round each piece

px = tex.load()
m = mask.load()
changed = 0
for y in range(H):
    for x in range(W):
        if m[x, y]:
            r, g, b = px[x, y]
            if r > g + 30 and r > b + 30:
                lum = int(0.3 * r + 0.59 * g + 0.11 * b)
                grey = max(30, min(200, int(lum * 0.9)))
                px[x, y] = (grey, grey, grey + 4)
                changed += 1

tex.save(os.path.join(outdir, "color-clean.png"))
mask.save(os.path.join(outdir, "shoe-mask.png"))

# the same model with the new texture, for a preview render
buf = io.BytesIO()
tex.save(buf, "JPEG", quality=92)
new_img = buf.getvalue()
old_off, old_len = bv.get("byteOffset", 0), bv["byteLength"]
new_bin = bytearray(binary[:old_off] + new_img + binary[old_off + old_len:])
delta = len(new_img) - old_len
for v in gltf["bufferViews"]:
    if v.get("byteOffset", 0) > old_off:
        v["byteOffset"] = v.get("byteOffset", 0) + delta
bv["byteLength"] = len(new_img)
while len(new_bin) % 4:
    new_bin += b"\x00"
gltf["buffers"][0]["byteLength"] = len(new_bin)
js = json.dumps(gltf).encode()
while len(js) % 4:
    js += b" "
out = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(new_bin))
out += struct.pack("<II", len(js), 0x4E4F534A) + js + struct.pack("<II", len(new_bin), 0x004E4942) + bytes(new_bin)
open(os.path.join(outdir, "clean.glb"), "wb").write(out)
print(f"shoe triangles {shoe_tris}, pixels repainted {changed}")
