"""Renders a quick textured preview of a .glb from the front (+Z), the back
(-Z) and the side, so a model can be checked before importing it.
Usage: python tools/preview_glb.py art/models/glow.glb out.png"""
import io
import json
import struct
import sys
from PIL import Image, ImageDraw

path, out = sys.argv[1], sys.argv[2]
data = open(path, 'rb').read()
clen = struct.unpack('<I', data[12:16])[0]
gltf = json.loads(data[20:20 + clen])
bin_start = 20 + clen + 8
binary = data[bin_start:]

CT = {5126: ('f', 4), 5125: ('I', 4), 5123: ('H', 2), 5121: ('B', 1)}
NC = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}


def accessor(i):
    a = gltf['accessors'][i]
    bv = gltf['bufferViews'][a['bufferView']]
    fmt, size = CT[a['componentType']]
    n = NC[a['type']]
    start = bv.get('byteOffset', 0) + a.get('byteOffset', 0)
    stride = bv.get('byteStride', size * n)
    res = []
    for k in range(a['count']):
        off = start + k * stride
        vals = struct.unpack('<' + fmt * n, binary[off:off + size * n])
        res.append(vals if n > 1 else vals[0])
    return res


prim = gltf['meshes'][0]['primitives'][0]
pos = accessor(prim['attributes']['POSITION'])
uv = accessor(prim['attributes']['TEXCOORD_0'])
idx = accessor(prim['indices'])
mat = gltf['materials'][prim.get('material', 0)]
tex_i = mat['pbrMetallicRoughness']['baseColorTexture']['index']
img_i = gltf['textures'][tex_i]['source']
bv = gltf['bufferViews'][gltf['images'][img_i]['bufferView']]
tex = Image.open(io.BytesIO(binary[bv.get('byteOffset', 0):bv.get('byteOffset', 0) + bv['byteLength']])).convert('RGB')
tw, th = tex.size


def render(axis_u, axis_v, depth, flip_u, size=420):
    xs = [p[axis_u] * (-1 if flip_u else 1) for p in pos]
    ys = [p[axis_v] for p in pos]
    minx, maxx, miny, maxy = min(xs), max(xs), min(ys), max(ys)
    sc = (size - 40) / max(maxx - minx, maxy - miny)
    im = Image.new('RGB', (size, size), (40, 26, 58))
    d = ImageDraw.Draw(im)
    tris = []
    for t in range(0, len(idx), 3):
        a, b, c = idx[t], idx[t + 1], idx[t + 2]
        z = (depth(pos[a]) + depth(pos[b]) + depth(pos[c])) / 3
        tris.append((z, a, b, c))
    tris.sort()
    for z, a, b, c in tris:
        pts = [((xs[v] - minx) * sc + 20, size - ((ys[v] - miny) * sc + 20)) for v in (a, b, c)]
        u = (uv[a][0] + uv[b][0] + uv[c][0]) / 3
        v = (uv[a][1] + uv[b][1] + uv[c][1]) / 3
        col = tex.getpixel((min(tw - 1, max(0, int(u * tw))), min(th - 1, max(0, int(v * th)))))
        d.polygon(pts, fill=col)
    return im


# glTF is Y-up; draw far triangles first (painter's algorithm)
front = render(0, 1, lambda p: -p[2], False)    # camera on +Z looking toward -Z
back = render(0, 1, lambda p: p[2], True)       # camera on -Z
side = render(2, 1, lambda p: -p[0], False)     # camera on +X
sheet = Image.new('RGB', (1300, 460), (20, 12, 30))
for i, (im, name) in enumerate(((front, 'seen from +Z'), (back, 'seen from -Z'), (side, 'seen from +X'))):
    sheet.paste(im, (10 + i * 430, 10))
    ImageDraw.Draw(sheet).text((20 + i * 430, 436), name, fill=(255, 255, 255))
sheet.save(out)
print('rendered', len(idx) // 3, 'triangles')
