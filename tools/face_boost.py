"""Give a Meshy character's head a bigger share of its texture.

Roblox shows at most 1024x1024 pixels of a model's texture, and Meshy packs
the face into a small patch of it. This re-lays the texture: triangles above
the neck are cut into their own UV islands and drawn larger in a new
1024x1024 picture (base colour and normal map), the body gets the rest. One
mesh and one material, so Studio's Import and Avatar Setup work as before.

The gain depends on the Meshy texture: from a 2048 or 4096 texture the face
gets real extra pixels; from a 1024 one it is only drawn bigger.

Usage: python tools/face_boost.py in.glb out.glb [--head 0.22] [--share 0.4]
  --head   fraction of the model's height counted as head (from the top)
  --share  fraction of the new texture given to the head
Writes out.glb, plus out-head.png (head triangles marked red) to check --head.
"""
import io
import json
import math
import struct
import sys
from PIL import Image, ImageDraw

args = sys.argv[1:]
src, dst = args[0], args[1]
HEAD = float(args[args.index('--head') + 1]) if '--head' in args else 0.22
SHARE = float(args[args.index('--share') + 1]) if '--share' in args else 0.4
N = 1024   # Roblox's texture limit
PAD = 3    # pixels around every island in the new picture

data = open(src, 'rb').read()
clen = struct.unpack('<I', data[12:16])[0]
gltf = json.loads(data[20:20 + clen])
binary = data[20 + clen + 8:]
CT = {5126: ('f', 4), 5125: ('I', 4), 5123: ('H', 2), 5121: ('B', 1)}
NC = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}


def accessor(i):
    a = gltf['accessors'][i]
    bv = gltf['bufferViews'][a['bufferView']]
    fmt, size = CT[a['componentType']]
    n = NC[a['type']]
    start = bv.get('byteOffset', 0) + a.get('byteOffset', 0)
    stride = bv.get('byteStride', size * n)
    out = []
    for k in range(a['count']):
        vals = struct.unpack('<' + fmt * n, binary[start + k * stride:start + k * stride + size * n])
        out.append(vals if n > 1 else vals[0])
    return out


assert len(gltf['meshes']) == 1 and len(gltf['meshes'][0]['primitives']) == 1, 'expects one mesh, one primitive'
prim = gltf['meshes'][0]['primitives'][0]
pos = accessor(prim['attributes']['POSITION'])
uv = accessor(prim['attributes']['TEXCOORD_0'])
nrm = accessor(prim['attributes']['NORMAL']) if 'NORMAL' in prim['attributes'] else None
idx = accessor(prim['indices'])
mat = gltf['materials'][prim.get('material', 0)]


def image_of(tex_index):
    img_i = gltf['textures'][tex_index]['source']
    bv = gltf['bufferViews'][gltf['images'][img_i]['bufferView']]
    return Image.open(io.BytesIO(binary[bv.get('byteOffset', 0):bv.get('byteOffset', 0) + bv['byteLength']]))


base_img = image_of(mat['pbrMetallicRoughness']['baseColorTexture']['index']).convert('RGB')
normal_img = image_of(mat['normalTexture']['index']).convert('RGB') if 'normalTexture' in mat else None

# ---- which triangles are head ----
ys = [p[1] for p in pos]
top, bottom = max(ys), min(ys)
neck = top - HEAD * (top - bottom)
tris = [(idx[t], idx[t + 1], idx[t + 2]) for t in range(0, len(idx), 3)]
is_head = [(ys[a] + ys[b] + ys[c]) / 3 >= neck for a, b, c in tris]

# ---- islands: triangles joined by shared vertices, head and body kept apart ----
parent = list(range(len(tris)))


def find(i):
    while parent[i] != i:
        parent[i] = parent[parent[i]]
        i = parent[i]
    return i


owner = {}
for t, (a, b, c) in enumerate(tris):
    for v in (a, b, c):
        key = (v, is_head[t])
        if key in owner:
            ra, rb = find(owner[key]), find(t)
            if ra != rb:
                parent[ra] = rb
        else:
            owner[key] = t
islands = {}
for t in range(len(tris)):
    islands.setdefault(find(t), []).append(t)
islands = list(islands.values())

# ---- new vertices: a vertex used by head and body triangles is split in two ----
new_pos, new_uv, new_nrm, new_idx, remap = [], [], [], [], {}
vert_island = []
for isl_no, isl in enumerate(islands):
    for t in isl:
        for v in tris[t]:
            key = (v, isl_no)
            if key not in remap:
                remap[key] = len(new_pos)
                new_pos.append(pos[v])
                new_uv.append(uv[v])
                new_nrm.append(nrm[v] if nrm else None)
                vert_island.append(isl_no)
            new_idx.append(remap[key])

# ---- island boxes in UV space ----
boxes = []
for isl_no, isl in enumerate(islands):
    us = [uv[v][0] for t in isl for v in tris[t]]
    vs = [uv[v][1] for t in isl for v in tris[t]]
    head = is_head[isl[0]]
    boxes.append([min(us), min(vs), max(us), max(vs), head])

S = base_img.size[0]
area_h = sum((b[2] - b[0]) * (b[3] - b[1]) for b in boxes if b[4]) * S * S
area_b = sum((b[2] - b[0]) * (b[3] - b[1]) for b in boxes if not b[4]) * S * S
ratio = math.sqrt(SHARE * area_b / ((1 - SHARE) * area_h)) if area_h > 0 else 1.0


def pack(k):
    """Shelf-pack every island at k (body) / k*ratio (head) pixels per source pixel."""
    rects = []
    for i, b in enumerate(boxes):
        kk = k * (ratio if b[4] else 1.0)
        w = max(1, math.ceil((b[2] - b[0]) * S * kk)) + 2 * PAD
        h = max(1, math.ceil((b[3] - b[1]) * S * kk)) + 2 * PAD
        rects.append((h, w, i, kk))
    rects.sort(reverse=True)
    x = y = row_h = 0
    placed = {}
    for h, w, i, kk in rects:
        if w > N:
            return None
        if x + w > N:
            x, y, row_h = 0, y + row_h, 0
        if y + h > N:
            return None
        placed[i] = (x, y, kk)
        x += w
        row_h = max(row_h, h)
    return placed


lo, hi = 0.01, 4.0
best = None
for _ in range(40):
    mid = (lo + hi) / 2
    p = pack(mid)
    if p:
        best, lo = (p, mid), mid
    else:
        hi = mid
placed, k_body = best
k_head = k_body * ratio
print('islands: %d (head %d); source %dpx; body scale %.2f, head scale %.2f' % (
    len(boxes), sum(1 for b in boxes if b[4]), S, k_body, k_head))


def relay(img):
    s = img.size[0]
    out = Image.new('RGB', (N, N), (0, 0, 0))
    for i, b in enumerate(boxes):
        x, y, kk = placed[i]
        w = max(1, math.ceil((b[2] - b[0]) * S * kk)) + 2 * PAD
        h = max(1, math.ceil((b[3] - b[1]) * S * kk)) + 2 * PAD
        # the source rectangle (in this image's pixels) that lands on (x, y, w, h)
        px = PAD / (kk * S)
        extent = ((b[0] - px) * s, (b[1] - px) * s, (b[0] - px) * s + w / (kk * S) * s, (b[1] - px) * s + h / (kk * S) * s)
        piece = img.transform((w, h), Image.EXTENT, extent, resample=Image.BICUBIC)
        out.paste(piece, (x, y))
    return out


new_base = relay(base_img)
new_normal = relay(normal_img) if normal_img else None
for vi in range(len(new_uv)):
    b = boxes[vert_island[vi]]
    x, y, kk = placed[vert_island[vi]]
    u, v = new_uv[vi]
    new_uv[vi] = ((x + PAD + (u - b[0]) * S * kk) / N, (y + PAD + (v - b[1]) * S * kk) / N)

# ---- write the new .glb ----
chunks = []


def add_view(raw):
    while sum(len(c) for c in chunks) % 4:
        chunks.append(b'\0')
    off = sum(len(c) for c in chunks)
    chunks.append(raw)
    return {'buffer': 0, 'byteOffset': off, 'byteLength': len(raw)}


def png(img):
    b = io.BytesIO()
    img.save(b, 'PNG', optimize=True)
    return b.getvalue()


views = [add_view(struct.pack('<%dI' % len(new_idx), *new_idx)),
         add_view(b''.join(struct.pack('<3f', *p) for p in new_pos)),
         add_view(b''.join(struct.pack('<2f', *t) for t in new_uv))]
if nrm:
    views.append(add_view(b''.join(struct.pack('<3f', *n) for n in new_nrm)))
img_views = [len(views)]
views.append(add_view(png(new_base)))
if new_normal:
    img_views.append(len(views))
    views.append(add_view(png(new_normal)))

acc = [
    {'bufferView': 0, 'componentType': 5125, 'count': len(new_idx), 'type': 'SCALAR', 'max': [max(new_idx)], 'min': [min(new_idx)]},
    {'bufferView': 1, 'componentType': 5126, 'count': len(new_pos), 'type': 'VEC3',
     'max': [max(p[i] for p in new_pos) for i in range(3)], 'min': [min(p[i] for p in new_pos) for i in range(3)]},
    {'bufferView': 2, 'componentType': 5126, 'count': len(new_uv), 'type': 'VEC2'},
]
attrs = {'POSITION': 1, 'TEXCOORD_0': 2}
if nrm:
    acc.append({'bufferView': 3, 'componentType': 5126, 'count': len(new_nrm), 'type': 'VEC3'})
    attrs['NORMAL'] = 3
gltf['accessors'] = acc
gltf['bufferViews'] = views
gltf['meshes'][0]['primitives'][0]['attributes'] = attrs
gltf['meshes'][0]['primitives'][0]['indices'] = 0
gltf['images'] = [{'bufferView': v, 'mimeType': 'image/png'} for v in img_views]
gltf['textures'] = [{'source': i} for i in range(len(img_views))]
m = gltf['materials'][prim.get('material', 0)]
m['pbrMetallicRoughness']['baseColorTexture'] = {'index': 0}
if new_normal:
    m['normalTexture'] = {'index': 1}
gltf['materials'] = [m]
gltf['meshes'][0]['primitives'][0]['material'] = 0
binblob = b''.join(chunks)
while len(binblob) % 4:
    binblob += b'\0'
gltf['buffers'] = [{'byteLength': len(binblob)}]
js = json.dumps(gltf, separators=(',', ':')).encode()
while len(js) % 4:
    js += b' '
total = 12 + 8 + len(js) + 8 + len(binblob)
with open(dst, 'wb') as f:
    f.write(struct.pack('<III', 0x46546C67, 2, total))
    f.write(struct.pack('<II', len(js), 0x4E4F534A) + js)
    f.write(struct.pack('<II', len(binblob), 0x004E4942) + binblob)
print('wrote', dst, '(%d triangles, %d vertices)' % (len(new_idx) // 3, len(new_pos)))

# ---- check picture: head triangles in red, seen from the front ----
xs = [p[0] for p in pos]
sz = 420
sc = (sz - 40) / max(max(xs) - min(xs), top - bottom)
chk = Image.new('RGB', (sz, sz), (40, 26, 58))
d = ImageDraw.Draw(chk)
order = sorted(range(len(tris)), key=lambda t: sum(-pos[v][2] for v in tris[t]))
for t in order:
    pts = [((xs[v] - min(xs)) * sc + 20, sz - ((ys[v] - bottom) * sc + 20)) for v in tris[t]]
    d.polygon(pts, fill=(230, 60, 60) if is_head[t] else (150, 150, 160))
chk.save(dst[:-4] + '-head.png')
