"""Builds roblox/src/shared/HouseMap.luau (the Party House layout) and checks it.

Edit the layout here, not in HouseMap.luau. Run: python tools/make_housemap.py
Checks: every object sits on the right kind of tile, nothing overlaps, rooms
behind locked doors can only be reached through them, the exit and the hole
are reachable once both doors are open, patrol points and starts are floor.

Map key: # wall, . floor, T furniture, L locked door, D the big exit door,
H the hole behind the cabinet (Muscle), C the host's door.
"""
import os
from collections import deque

W, H = 40, 30
grid = [['.'] * W for _ in range(H)]


def wall_rect(x0, y0, x1, y1, ch='#'):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            grid[y][x] = ch


# outer walls and the room grid: columns A 1-9, B 11-19, C 21-29, D 31-38;
# rows N 1-8, M 10-18, S 20-28
for x in range(W):
    grid[0][x] = grid[H - 1][x] = '#'
for y in range(H):
    grid[y][0] = grid[y][W - 1] = '#'
for x in (10, 20, 30):
    wall_rect(x, 0, x, H - 1)
for y in (9, 19):
    wall_rect(0, y, W - 1, y)
# the Front Hall is one long room across B and C
wall_rect(20, 20, 20, 28, '.')

# doorways (zone 1: everything you can reach from the start)
for x, y in [(10, 24), (30, 25), (15, 19), (25, 19), (10, 14), (5, 19), (30, 13), (20, 16), (35, 19)]:
    grid[y][x] = '.'
grid[4][10] = '.'    # Library <-> Parlour (zone 2)
grid[4][30] = '.'    # Corridor <-> Music Room (zone 3)
grid[9][15] = 'L'    # L1: Dining Room -> Library
grid[5][20] = 'L'    # L2: Library -> Corridor
grid[0][25] = 'D'    # the big exit door
grid[6][39] = 'H'    # the hole behind the cabinet
grid[14][0] = 'C'    # the host comes out of the Kitchen wall

# walls inside rooms: corners, dead ends and places to break line of sight
wall_rect(20, 22, 20, 24)        # Front Hall divider
wall_rect(25, 11, 25, 13)        # Game Room partition
wall_rect(34, 21, 34, 23)        # Bathroom stall
for x, y in [(23, 3), (27, 3), (23, 6), (27, 6)]:
    grid[y][x] = '#'             # Corridor pillars
wall_rect(4, 4, 6, 4)            # Parlour screen wall

furniture = [
    (2, 11, 6, 11, 'counter'),    # Kitchen counter
    (4, 15, 6, 16, 'counter'),    # Kitchen island
    (12, 13, 17, 14, 'table'),    # Dining table (the cake sits here)
    (12, 3, 17, 3, 'shelf'),      # Library shelves
    (13, 6, 18, 6, 'shelf'),
    (2, 21, 8, 21, 'shelf'),      # Pantry shelves
    (2, 25, 6, 25, 'shelf'),
    (14, 23, 17, 24, 'table'),    # Front Hall party table
    (22, 15, 23, 16, 'table'),    # Game Room table
    (33, 14, 36, 14, 'planter'),  # Conservatory planters
    (33, 3, 35, 3, 'piano'),      # Music Room piano
]
for x0, y0, x1, y1, kind in furniture:
    wall_rect(x0, y0, x1, y1, 'T')

floors = [
    (1, 1, 9, 8, 'carpet', 'Parlour'),
    (11, 1, 19, 8, 'green', 'Library'),
    (21, 1, 29, 8, 'boards', 'Corridor'),
    (31, 1, 38, 8, 'purple', 'Music Room'),
    (1, 10, 9, 18, 'tiles', 'Kitchen'),
    (11, 10, 19, 18, 'wood', 'Dining Room'),
    (21, 10, 29, 18, 'purple', 'Game Room'),
    (31, 10, 38, 18, 'green', 'Conservatory'),
    (1, 20, 9, 28, 'boards', 'Pantry'),
    (11, 20, 29, 28, 'wood', 'Front Hall'),
    (31, 20, 38, 28, 'tiles', 'Bathroom'),
]

# objects. zone: 1 from the start, 2 behind L1, 3 behind L2.
# wall: the object hangs on a wall tile and faces the room to its south.
objects = [
    dict(id='door', kind='door', x=25, y=0, wall=True),
    dict(id='hole', kind='hole', x=39, y=6, wall=True),
    dict(id='cab', kind='cabinet', x=38, y=6),
    dict(id='L1', kind='lock', x=15, y=9, name='Library door', wall=True),
    dict(id='L2', kind='lock', x=20, y=5, name='Corridor door', wall=True),
    dict(id='cage', kind='cage', x=12, y=27),
    # the three clue balloons, and decoys that look the same
    dict(id='b0', kind='balloon', n=1, x=7, y=17),
    dict(id='b1', kind='balloon', n=2, x=3, y=2),
    dict(id='b2', kind='balloon', n=3, x=37, y=17),
    dict(id='x0', kind='balloon', n=1, decoy=True, x=23, y=26),
    dict(id='x1', kind='balloon', n=2, decoy=True, x=28, y=17),
    dict(id='x2', kind='balloon', n=3, decoy=True, x=18, y=1),
    # skill puzzles
    dict(id='invite', kind='invite', x=5, y=0, wall=True),
    dict(id='uv', kind='uv', x=14, y=0, wall=True),
    dict(id='plant', kind='plant', x=37, y=11),
    # presents: two real, two empty
    dict(id='p0', kind='present', boost='candy', x=8, y=27),
    dict(id='p1', kind='present', boost='shield', x=37, y=27),
    dict(id='p2', kind='present', x=18, y=11),
    dict(id='p3', kind='present', x=36, y=7),
    # hiding places: some rooms have none; cap = how many fit
    dict(id='wardrobe', kind='hide', look='wardrobe', cap=2, x=1, y=1),
    dict(id='sofa', kind='hide', look='sofa', cap=1, x=3, y=7),
    dict(id='curtain', kind='hide', look='curtain', cap=1, x=19, y=8),
    dict(id='closet', kind='hide', look='wardrobe', cap=2, x=1, y=28),
    dict(id='box', kind='hide', look='box', cap=1, x=29, y=18),
    dict(id='cloth', kind='hide', look='cloth', cap=1, x=18, y=21),
    dict(id='shower', kind='hide', look='curtain', cap=1, x=38, y=21),
    dict(id='nook', kind='hide', look='curtain', cap=1, x=38, y=1),
    # things to search: one per locked door hides its key each game
    dict(id='s1', kind='search', look='drawer', zone=1, x=9, y=12),
    dict(id='s2', kind='search', look='crate', zone=1, x=8, y=23),
    dict(id='s3', kind='search', look='cakebox', zone=1, x=11, y=11),
    dict(id='s4', kind='search', look='coat', zone=1, x=29, y=20),
    dict(id='s5', kind='search', look='toybox', zone=1, x=21, y=11),
    dict(id='s6', kind='search', look='vase', zone=1, x=31, y=17),
    dict(id='s7', kind='search', look='laundry', zone=1, x=32, y=28),
    dict(id='s8', kind='search', look='chest', zone=1, x=11, y=21),
    dict(id='s9', kind='search', look='drawer', zone=2, x=11, y=8),
    dict(id='s10', kind='search', look='vase', zone=2, x=1, y=5),
    dict(id='s11', kind='search', look='chest', zone=2, x=9, y=8),
    dict(id='s12', kind='search', look='toybox', zone=3, x=31, y=8),
]
start = [(17, 27), (18, 27), (19, 27), (21, 27), (22, 27), (23, 27)]
spawn = (1, 14)
cake = (14, 13)
# patrol: points behind a locked door are skipped until it opens
patrol = [(5, 13), (15, 16), (24, 17), (34, 16), (35, 25), (24, 21), (13, 26), (5, 27),
          (15, 5, 'L1'), (6, 7, 'L1'), (25, 5, 'L2'), (35, 6, 'L2')]

# ------------------------------------------------------------------ checks
problems = []


def at(x, y):
    return grid[y][x]


def room_of(x, y):
    for f in floors:
        if f[0] <= x <= f[2] and f[1] <= y <= f[3]:
            return f[5]
    return None


used = {}
for o in objects:
    key = (o['x'], o['y'])
    if key in used and not (o['kind'] in ('hole',) or used[key] in ('hole',)):
        problems.append('%s overlaps %s' % (o['id'], used[key]))
    used[key] = o['id']
    c = at(o['x'], o['y'])
    want = {'door': 'D', 'hole': 'H', 'lock': 'L'}.get(o['kind'])
    if want:
        if c != want:
            problems.append('%s should sit on %s, is on %r' % (o['id'], want, c))
    elif o.get('wall'):
        if c != '#':
            problems.append('%s should hang on a wall, is on %r' % (o['id'], c))
        elif at(o['x'], o['y'] + 1) not in '.':
            problems.append('%s faces %r, not floor' % (o['id'], at(o['x'], o['y'] + 1)))
    elif c != '.':
        problems.append('%s should stand on floor, is on %r' % (o['id'], c))
for p in start + [spawn, cake]:
    if (p is cake and at(*p) != 'T') or (p is not cake and at(*p) != '.'):
        problems.append('bad tile %r at %s' % (at(*p), p))
    if p is not cake and p in used:
        problems.append('%s is on %s' % (p, used[p]))
for p in patrol:
    if at(p[0], p[1]) != '.' or (p[0], p[1]) in used:
        problems.append('patrol point %s is not free floor' % (p,))


def reach(open_locks):
    seen = {start[0]}
    q = deque([start[0]])
    while q:
        x, y = q.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if not (0 <= nx < W and 0 <= ny < H) or (nx, ny) in seen:
                continue
            c = at(nx, ny)
            ok = c == '.' or (c == 'L' and any(o['id'] in open_locks and (o['x'], o['y']) == (nx, ny) for o in objects))
            if ok and (nx, ny) not in used or (ok and used.get((nx, ny)) in ('L1', 'L2')):
                seen.add((nx, ny))
                q.append((nx, ny))
    return seen


zone_rooms = {}
for n, locks in ((1, ()), (2, ('L1',)), (3, ('L1', 'L2'))):
    tiles = reach(set(locks))
    zone_rooms[n] = sorted({room_of(x, y) for x, y in tiles if room_of(x, y)})
z1, z2, z3 = (set(zone_rooms[i]) for i in (1, 2, 3))
print('zone 1:', ', '.join(sorted(z1)))
print('zone 2 adds:', ', '.join(sorted(z2 - z1)))
print('zone 3 adds:', ', '.join(sorted(z3 - z2)))
if z1 & {'Library', 'Parlour', 'Corridor', 'Music Room'}:
    problems.append('zone 1 reaches rooms behind the locks')
if 'Corridor' in z2 or 'Music Room' in z2:
    problems.append('L1 alone reaches the Corridor')
if len(z3) != len(floors):
    problems.append('some room is never reachable: %s' % ({f[5] for f in floors} - z3))
all_open = reach({'L1', 'L2'})
for o in objects:
    room = room_of(o['x'], o['y'] + (1 if o.get('wall') and o['kind'] != 'lock' else 0))
    if o['kind'] == 'cabinet':
        room = room_of(o['x'], o['y'])
    zone = 1 if room in z1 else 2 if room in z2 else 3
    o['zone_found'] = zone
    if 'zone' in o and o['zone'] != zone:
        problems.append('%s is tagged zone %d but sits in zone %d (%s)' % (o['id'], o['zone'], zone, room))
    if o['kind'] not in ('door', 'hole', 'lock', 'cabinet') and not o.get('wall'):
        near = any((o['x'] + dx, o['y'] + dy) in all_open for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        if not near:
            problems.append('%s cannot be walked up to' % o['id'])
if not any((25 + dx, 0 + dy) in all_open for dx, dy in ((0, 1),)):
    problems.append('the exit door cannot be reached')
if (38, 6) not in used or not any((38 + dx, 6 + dy) in all_open for dx, dy in ((-1, 0), (0, 1), (0, -1))):
    problems.append('the cabinet cannot be reached')
for z in (1, 2):
    if sum(1 for o in objects if o['kind'] == 'search' and o.get('zone') == z) < 2:
        problems.append('zone %d needs at least two searchable things' % z)

for row in grid:
    print(''.join(row))
if problems:
    raise SystemExit('PROBLEMS:\n  ' + '\n  '.join(problems))


# ------------------------------------------------------------------ write Luau
def lua(v):
    if isinstance(v, bool):
        return 'true' if v else 'false'
    if isinstance(v, (int, float)):
        return repr(v)
    return '"%s"' % v


out = ['--[[',
       '\tHouseMap - the Party House layout. GENERATED by tools/make_housemap.py:',
       '\tedit that file and run it, do not edit this one by hand.',
       '\tMap key: # wall, . floor, T furniture, L locked door (zone 2 and 3 are',
       '\tbehind them), D the big exit door, H the hole behind the cabinet',
       '\t(Muscle), C the host\'s door. Tile (x, y) becomes a square of floor.',
       ']]', '', 'return {', '\tname = "The Party House",',
       '\tw = %d,' % W, '\th = %d,' % H, '\tmap = {']
out += ['\t\t"%s",' % ''.join(r) for r in grid]
out += ['\t},', '\tfloors = {']
out += ['\t\t{ x0 = %d, y0 = %d, x1 = %d, y1 = %d, kind = "%s", name = "%s" },' % f for f in floors]
out += ['\t},', '\tfurniture = {']
out += ['\t\t{ x0 = %d, y0 = %d, x1 = %d, y1 = %d, kind = "%s" },' % f for f in furniture]
out += ['\t},',
        '\tstart = { %s },' % ', '.join('{ %d, %d }' % p for p in start),
        '\tspawn = { %d, %d },' % spawn,
        '\tcake = { %d, %d },' % cake,
        '\tpatrol = { %s },' % ', '.join(('{ %d, %d, lock = "%s" }' % p) if len(p) == 3 else ('{ %d, %d }' % p) for p in patrol),
        '\tobjects = {']
for o in objects:
    fields = ['id', 'kind', 'n', 'decoy', 'boost', 'look', 'cap', 'name', 'x', 'y']
    parts = ['%s = %s' % (k, lua(o[k])) for k in fields if k in o]
    parts.append('zone = %d' % o['zone_found'])
    out.append('\t\t{ %s },' % ', '.join(parts))
out += ['\t},', '}', '']
path = os.path.join(os.path.dirname(__file__), '..', 'roblox', 'src', 'shared', 'HouseMap.luau')
open(path, 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
print('wrote', os.path.normpath(path))
