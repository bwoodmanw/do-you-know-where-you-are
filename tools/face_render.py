"""Render a .glb's head close up from the front, textured, the way Roblox
would show it (the texture squeezed to 1024x1024 first).
Usage: python tools/face_render.py in.glb out.png [--head 0.25] [--size 420]"""
import io
import json
import struct
import sys
from PIL import Image

args = sys.argv[1:]
src, out = args[0], args[1]
HEAD = float(args[args.index('--head') + 1]) if '--head' in args else 0.25
SIZE = int(args[args.index('--size') + 1]) if '--size' in args else 420

data = open(src, 'rb').read()
clen = struct.unpack('<I', data[12:16])[0]
gltf = json.loads(data[20:20 + clen])
binary = data[20 + clen + 8:]
CT = {5126: ('f', 4), 5125: ('I', 4), 5123: ('H', 2)}
NC = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3}


def accessor(i):
    a = gltf['accessors'][i]
    bv = gltf['bufferViews'][a['bufferView']]
    fmt, size = CT[a['componentType']]
    n = NC[a['type']]
    start = bv.get('byteOffset', 0) + a.get('byteOffset', 0)
    stride = bv.get('byteStride', size * n)
    return [struct.unpack('<' + fmt * n, binary[start + k * stride:start + k * stride + size * n]) if n > 1
            else struct.unpack('<' + fmt, binary[start + k * stride:start + k * stride + size])[0]
            for k in range(a['count'])]


prim = gltf['meshes'][0]['primitives'][0]
pos = accessor(prim['attributes']['POSITION'])
uv = accessor(prim['attributes']['TEXCOORD_0'])
idx = accessor(prim['indices'])
mat = gltf['materials'][prim.get('material', 0)]
img_i = gltf['textures'][mat['pbrMetallicRoughness']['baseColorTexture']['index']]['source']
bv = gltf['bufferViews'][gltf['images'][img_i]['bufferView']]
tex = Image.open(io.BytesIO(binary[bv.get('byteOffset', 0):bv.get('byteOffset', 0) + bv['byteLength']])).convert('RGB')
if tex.size[0] > 1024:
    tex = tex.resize((1024, 1024), Image.LANCZOS)  # Roblox's limit
tw, th = tex.size
px = tex.load()

ys = [p[1] for p in pos]
top, bottom = max(ys), min(ys)
neck = top - HEAD * (top - bottom)
tris = [(idx[t], idx[t + 1], idx[t + 2]) for t in range(0, len(idx), 3)]
tris = [t for t in tris if sum(ys[v] for v in t) / 3 >= neck]
vs = set(v for t in tris for v in t)
minx, maxx = min(pos[v][0] for v in vs), max(pos[v][0] for v in vs)
miny, maxy = min(pos[v][1] for v in vs), max(pos[v][1] for v in vs)
sc = (SIZE - 20) / max(maxx - minx, maxy - miny)
cx, cy = (minx + maxx) / 2, (miny + maxy) / 2

img = Image.new('RGB', (SIZE, SIZE), (40, 26, 58))
out_px = img.load()
zbuf = [[-1e9] * SIZE for _ in range(SIZE)]
for a, b, c in tris:
    P = [(SIZE / 2 - (pos[v][0] - cx) * sc, SIZE / 2 - (pos[v][1] - cy) * sc, -pos[v][2]) for v in (a, b, c)]  # Meshy faces -Z: camera there
    T = [uv[v] for v in (a, b, c)]
    (x0, y0, z0), (x1, y1, z1), (x2, y2, z2) = P
    den = (y1 - y2) * (x0 - x2) + (x2 - x1) * (y0 - y2)
    if abs(den) < 1e-12:
        continue
    for y in range(max(0, int(min(y0, y1, y2))), min(SIZE, int(max(y0, y1, y2)) + 1)):
        for x in range(max(0, int(min(x0, x1, x2))), min(SIZE, int(max(x0, x1, x2)) + 1)):
            w0 = ((y1 - y2) * (x + 0.5 - x2) + (x2 - x1) * (y + 0.5 - y2)) / den
            w1 = ((y2 - y0) * (x + 0.5 - x2) + (x0 - x2) * (y + 0.5 - y2)) / den
            w2 = 1 - w0 - w1
            if w0 < 0 or w1 < 0 or w2 < 0:
                continue
            z = w0 * z0 + w1 * z1 + w2 * z2
            if z <= zbuf[y][x]:
                continue
            zbuf[y][x] = z
            u = w0 * T[0][0] + w1 * T[1][0] + w2 * T[2][0]
            v = w0 * T[0][1] + w1 * T[1][1] + w2 * T[2][1]
            out_px[x, y] = px[min(tw - 1, max(0, int(u * tw))), min(th - 1, max(0, int(v * th)))]
img.save(out)
print('rendered', len(tris), 'head triangles')
