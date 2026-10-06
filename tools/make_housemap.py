"""Builds roblox/src/shared/HouseMap.luau - the Party House floor plans - and checks them.

Edit the layouts here, not in HouseMap.luau. Run: python tools/make_housemap.py

Each game the server (shared/MapGen.luau) picks one floor plan at random and
scatters the balloons, presents, search spots, hiding places and skill puzzles
over that plan's checked SLOTS. This script:
  - checks every plan: rooms behind the locked doors only reachable through
    them, the exit and Muscle's hole reachable once both are open;
  - works out the slots (floor tiles against a wall or furniture, clear of
    doorways, starts, patrol points, the cage and the cabinet; wall tiles
    with a room to their south for the posters);
  - plays MapGen's picking 500 times per plan and checks every result: every
    room still reachable, every object can be walked up to.

Map key: # wall, . floor, T furniture, L locked door, D the big exit door,
H the hole behind the cabinet (Muscle), C the host's door.
"""
import os
import random
from collections import deque

W, H = 40, 30


class Plan:
    def __init__(self, pid, name):
        self.id, self.name = pid, name
        self.grid = [['.'] * W for _ in range(H)]
        for x in range(W):
            self.grid[0][x] = self.grid[H - 1][x] = '#'
        for y in range(H):
            self.grid[y][0] = self.grid[y][W - 1] = '#'
        self.floors, self.furniture, self.fixed, self.patrol, self.props = [], [], [], [], []
        self.start, self.spawn, self.cake = [], None, None

    def rect(self, x0, y0, x1, y1, ch='#'):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.grid[y][x] = ch

    def put(self, x, y, ch):
        self.grid[y][x] = ch

    def furnish(self, x0, y0, x1, y1, kind):
        self.rect(x0, y0, x1, y1, 'T')
        self.furniture.append((x0, y0, x1, y1, kind))

    def c(self, x, y):
        return self.grid[y][x] if 0 <= x < W and 0 <= y < H else '#'


# ---------------------------------------------------------------- plan A
def plan_a():
    p = Plan('a', 'The Party House')
    for x in (10, 20, 30):
        p.rect(x, 0, x, H - 1)
    for y in (9, 19):
        p.rect(0, y, W - 1, y)
    for y in range(1, H - 1):
        p.grid[y][0] = '#'
        p.grid[y][W - 1] = '#'
    p.rect(20, 20, 20, 28, '.')     # the Front Hall spans B and C
    for x, y in [(10, 24), (30, 25), (15, 19), (25, 19), (10, 14), (5, 19), (30, 13), (20, 16), (35, 19), (10, 4), (30, 4)]:
        p.put(x, y, '.')
    p.put(15, 9, 'L')
    p.put(20, 5, 'L')
    p.put(25, 0, 'D')
    p.put(39, 6, 'H')
    p.put(0, 14, 'C')
    p.rect(20, 22, 20, 24)
    p.rect(25, 11, 25, 13)
    p.rect(34, 21, 34, 23)
    for x, y in [(23, 3), (27, 3), (23, 6), (27, 6)]:
        p.put(x, y, '#')
    p.rect(4, 4, 6, 4)
    for f in [(2, 11, 6, 11, 'counter'), (4, 15, 6, 16, 'counter'), (12, 13, 17, 14, 'table'), (12, 3, 17, 3, 'shelf'),
              (13, 6, 18, 6, 'shelf'), (2, 21, 8, 21, 'shelf'), (2, 25, 6, 25, 'shelf'), (14, 23, 17, 24, 'table'),
              (22, 15, 23, 16, 'table'), (33, 14, 36, 14, 'planter'), (33, 3, 35, 3, 'piano')]:
        p.furnish(*f)
    p.floors = [(1, 1, 9, 8, 'carpet', 'Parlour'), (11, 1, 19, 8, 'green', 'Library'), (21, 1, 29, 8, 'boards', 'Corridor'),
                (31, 1, 38, 8, 'purple', 'Music Room'), (1, 10, 9, 18, 'tiles', 'Kitchen'), (11, 10, 19, 18, 'wood', 'Dining Room'),
                (21, 10, 29, 18, 'purple', 'Game Room'), (31, 10, 38, 18, 'green', 'Conservatory'), (1, 20, 9, 28, 'boards', 'Pantry'),
                (11, 20, 29, 28, 'wood', 'Front Hall'), (31, 20, 38, 28, 'tiles', 'Bathroom')]
    p.fixed = [dict(id='door', kind='door', x=25, y=0), dict(id='hole', kind='hole', x=39, y=6), dict(id='cab', kind='cabinet', x=38, y=6),
               dict(id='L1', kind='lock', x=15, y=9, name='Library door'), dict(id='L2', kind='lock', x=20, y=5, name='Corridor door'),
               dict(id='cage', kind='cage', x=12, y=27)]
    p.start = [(17, 27), (18, 27), (19, 27), (21, 27), (22, 27), (23, 27)]
    p.spawn, p.cake = (1, 14), (14, 13)
    p.patrol = [(5, 13), (15, 16), (24, 17), (34, 16), (35, 25), (24, 21), (13, 26), (5, 27),
                (15, 5, 'L1'), (6, 7, 'L1'), (25, 5, 'L2'), (35, 6, 'L2')]
    p.props = [
        ("Fireplace", 9, 2, 1, 2, 9, "w"), ("Armchair", 7, 2, 1, 1, 5, "w"), ("Rug", 6, 6, 2, 2, 0.4, "s"),
        ("Chandelier", 4, 2, 2, 2, 5, "s", True), ("GrandfatherClock", 1, 3, 1, 1, 11, "e"),
        ("Desk", 12, 1, 2, 1, 4.5, "s"), ("DeskChair", 12, 2, 1, 1, 5, "n"), ("Globe", 19, 2, 1, 1, 5, "w"),
        ("FloorLamp", 11, 1, 1, 1, 9, "s"), ("Rug", 13, 4, 4, 2, 0.4, "s"),
        ("Bench", 21, 1, 2, 1, 4, "s"), ("Bench", 28, 8, 2, 1, 4, "n"), ("PottedPlant", 29, 1, 1, 1, 7, "w"),
        ("PottedPlant", 21, 8, 1, 1, 7, "e"), ("Rug", 24, 2, 3, 5, 0.4, "s"),
        ("FloorLamp", 31, 1, 1, 1, 9, "s"), ("BeanBag", 34, 6, 1, 1, 3, "n"), ("DiscoBall", 34, 4, 1, 1, 3, "s", True),
        ("Armchair", 37, 4, 1, 1, 5, "w"),
        ("Fridge", 1, 16, 1, 1, 10, "e"), ("Stove", 1, 18, 1, 1, 5, "e"), ("KitchenTable", 7, 13, 2, 1, 4, "s"),
        ("DiningChair", 8, 16, 1, 1, 5, "w"),
        ("DiningChair", 12, 12, 1, 1, 5, "s"), ("DiningChair", 14, 12, 1, 1, 5, "s"), ("DiningChair", 16, 12, 1, 1, 5, "s"),
        ("DiningChair", 13, 15, 1, 1, 5, "n"), ("DiningChair", 17, 15, 1, 1, 5, "n"), ("Chandelier", 14, 13, 2, 2, 5, "s", True),
        ("SideTable", 19, 10, 1, 1, 4, "w"),
        ("ArcadeMachine", 29, 10, 1, 1, 8, "w"), ("PoolTable", 26, 15, 2, 1, 4, "s"), ("BallPit", 27, 11, 2, 2, 3, "w"),
        ("BeanBag", 21, 18, 1, 1, 3, "e"), ("DiscoBall", 24, 14, 1, 1, 3, "s", True),
        ("PottedPlant", 31, 10, 1, 1, 7, "e"), ("PottedPlant", 38, 14, 1, 1, 7, "w"), ("Bench", 33, 17, 2, 1, 4, "n"),
        ("Pumpkin", 1, 23, 1, 1, 2.5, "e"),
        ("CoatRack", 28, 28, 1, 1, 8, "n"), ("Pumpkin", 11, 28, 1, 1, 2.5, "e"), ("DiningChair", 13, 23, 1, 1, 5, "e"),
        ("DiningChair", 18, 24, 1, 1, 5, "w"), ("Chandelier", 15, 23, 2, 2, 5, "s", True), ("Rug", 22, 21, 4, 3, 0.4, "s"),
    ]
    return p


# ---------------------------------------------------------------- plan B: A turned left-to-right
def mirror(a, pid, name):
    p = Plan(pid, name)
    p.grid = [list(reversed(row)) for row in a.grid]
    m = lambda x: W - 1 - x
    p.floors = [(m(x1), y0, m(x0), y1, k, n) for x0, y0, x1, y1, k, n in a.floors]
    p.furniture = [(m(x1), y0, m(x0), y1, k) for x0, y0, x1, y1, k in a.furniture]
    p.fixed = [dict(o, x=m(o['x'])) for o in a.fixed]
    p.start = [(m(x), y) for x, y in a.start]
    p.spawn, p.cake = (m(a.spawn[0]), a.spawn[1]), (m(a.cake[0]), a.cake[1])
    p.patrol = [(m(t[0]),) + tuple(t[1:]) for t in a.patrol]
    flip = {'e': 'w', 'w': 'e', 'n': 'n', 's': 's'}
    p.props = [(s[0], W - s[1] - s[3]) + tuple(s[2:6]) + (flip[s[6]],) + tuple(s[7:]) for s in a.props]
    return p


# ---------------------------------------------------------------- plan C: a 3 x 3 house
def plan_c():
    p = Plan('c', 'The Party House')
    for x in (13, 26):
        p.rect(x, 0, x, H - 1)
    for y in (10, 20):
        p.rect(0, y, W - 1, y)
    for x, y in [(13, 25), (26, 24), (19, 20), (22, 20), (6, 20), (13, 15), (26, 16), (33, 20), (26, 4)]:
        p.put(x, y, '.')
    p.put(6, 10, 'L')
    p.put(13, 5, 'L')
    p.put(19, 0, 'D')
    p.put(39, 5, 'H')
    p.put(0, 24, 'C')
    for x, y in [(17, 3), (22, 3), (17, 7), (22, 7)]:
        p.put(x, y, '#')
    p.rect(21, 12, 21, 14)
    p.rect(20, 23, 20, 25)
    p.rect(31, 22, 31, 24)
    for f in [(2, 3, 10, 3, 'shelf'), (3, 6, 11, 6, 'shelf'), (2, 13, 8, 13, 'counter'), (5, 16, 7, 17, 'counter'),
              (29, 14, 35, 15, 'table'), (16, 16, 17, 17, 'table'), (2, 22, 10, 22, 'shelf'), (2, 26, 8, 26, 'shelf'),
              (30, 3, 32, 3, 'piano'), (15, 22, 17, 23, 'table')]:
        p.furnish(*f)
    p.floors = [(1, 1, 12, 9, 'green', 'Library'), (14, 1, 25, 9, 'boards', 'Corridor'), (27, 1, 38, 9, 'purple', 'Music Room'),
                (1, 11, 12, 19, 'tiles', 'Kitchen'), (14, 11, 25, 19, 'purple', 'Game Room'), (27, 11, 38, 19, 'wood', 'Dining Room'),
                (1, 21, 12, 28, 'boards', 'Pantry'), (14, 21, 25, 28, 'wood', 'Front Hall'), (27, 21, 38, 28, 'tiles', 'Bathroom')]
    p.fixed = [dict(id='door', kind='door', x=19, y=0), dict(id='hole', kind='hole', x=39, y=5), dict(id='cab', kind='cabinet', x=38, y=5),
               dict(id='L1', kind='lock', x=6, y=10, name='Library door'), dict(id='L2', kind='lock', x=13, y=5, name='Corridor door'),
               dict(id='cage', kind='cage', x=15, y=27)]
    p.start = [(18, 27), (19, 27), (20, 27), (21, 27), (22, 27), (23, 27)]
    p.spawn, p.cake = (1, 24), (32, 14)
    p.patrol = [(6, 14), (19, 16), (32, 17), (33, 25), (19, 24), (6, 27), (6, 4, 'L1'), (10, 8, 'L1'), (19, 5, 'L2'), (33, 6, 'L2')]
    return p


# ---------------------------------------------------------------- checks and slots
def gap(p, x, y):
    c = p.c(x, y)
    return c in '.LDHC' and ((p.c(x - 1, y) in '#' and p.c(x + 1, y) in '#') or (p.c(x, y - 1) in '#' and p.c(x, y + 1) in '#'))


def room_of(p, x, y):
    for f in p.floors:
        if f[0] <= x <= f[2] and f[1] <= y <= f[3]:
            return f[5]
    return None


def reach(p, open_locks, blocked=()):
    locks = {(o['x'], o['y']): o['id'] for o in p.fixed if o['kind'] == 'lock'}
    solid = {(o['x'], o['y']) for o in p.fixed if o['kind'] in ('cage', 'cabinet')} | set(blocked)
    start = p.start[0]
    seen, q = {start}, deque([start])
    while q:
        x, y = q.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (x + dx, y + dy)
            if n in seen or n in solid:
                continue
            c = p.c(*n)
            if c == '.' or (c == 'L' and locks.get(n) in open_locks):
                seen.add(n)
                q.append(n)
    return seen


def check(p):
    problems = []
    for o in p.fixed:
        want = {'door': 'D', 'hole': 'H', 'lock': 'L'}.get(o['kind'], '.')
        if p.c(o['x'], o['y']) != want:
            problems.append('%s on %r, wants %r' % (o['id'], p.c(o['x'], o['y']), want))
    for t in p.start + [p.spawn]:
        if p.c(*t) != '.':
            problems.append('start/spawn %s on %r' % (t, p.c(*t)))
    if p.c(*p.cake) != 'T':
        problems.append('the cake is not on a table')
    for t in p.patrol:
        if p.c(t[0], t[1]) != '.':
            problems.append('patrol %s on %r' % (t, p.c(t[0], t[1])))
    zones = {}
    for n, locks in ((1, ()), (2, ('L1',)), (3, ('L1', 'L2'))):
        zones[n] = {room_of(p, x, y) for x, y in reach(p, set(locks))} - {None}
    z1, z2, z3 = zones[1], zones[2] - zones[1], zones[3] - zones[2]
    corridor = room_of(p, [o for o in p.fixed if o['id'] == 'door'][0]['x'], 1)
    if corridor not in z3:
        problems.append('the exit room is not behind both locks')
    if not z2:
        problems.append('nothing behind the first lock')
    if len(zones[3]) != len(p.floors):
        problems.append('rooms never reachable: %s' % ({f[5] for f in p.floors} - zones[3]))
    allopen = reach(p, {'L1', 'L2'})
    cab = [o for o in p.fixed if o['kind'] == 'cabinet'][0]
    if (cab['x'], cab['y'] + 1) not in allopen:
        problems.append('the cabinet has nowhere to be shoved')
    for o in p.fixed:
        if o['kind'] in ('cage', 'cabinet') and not any((o['x'] + dx, o['y'] + dy) in allopen for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            problems.append('%s cannot be reached' % o['id'])
    cage = [o for o in p.fixed if o['kind'] == 'cage'][0]
    if (cage['x'] + 1, cage['y']) not in allopen:
        problems.append('the cage has no outside tile')
    zone_of = {}
    for f in p.floors:
        zone_of[f[5]] = 1 if f[5] in z1 else 2 if f[5] in z2 else 3
    return problems, zone_of, allopen


def slots(p, zone_of, allopen):
    keep = set()
    for y in range(H):
        for x in range(W):
            if gap(p, x, y):
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        keep.add((x + dx, y + dy))
    keep |= set(p.start) | {(t[0], t[1]) for t in p.patrol} | {p.spawn}
    for o in p.fixed:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                keep.add((o['x'] + dx, o['y'] + dy))
    cab = [o for o in p.fixed if o['kind'] == 'cabinet'][0]
    keep.add((cab['x'], cab['y'] + 2))
    for s in p.props:
        if len(s) > 7 or s[5] <= 1:
            continue
        for yy in range(s[2], s[2] + s[4]):
            for xx in range(s[1], s[1] + s[3]):
                keep.add((xx, yy))
    floor, wall = [], []
    for y in range(1, H - 1):
        for x in range(1, W - 1):
            r = room_of(p, x, y)
            if p.c(x, y) == '.' and r and (x, y) not in keep and (x, y) in allopen:
                against = any(p.c(x + dx, y + dy) in '#T' for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                # never in a one-tile-wide aisle (between a wall and a shelf)
                aisle = (p.c(x, y - 1) in '#T' and p.c(x, y + 1) in '#T') or (p.c(x - 1, y) in '#T' and p.c(x + 1, y) in '#T')
                if against and not aisle:
                    floor.append((x, y, zone_of[r], r))
    for y in range(0, H - 1):
        for x in range(W):
            r = room_of(p, x, y + 1)
            if p.c(x, y) == '#' and p.c(x, y + 1) == '.' and r and (x, y + 1) not in keep and (x, y) not in keep:
                wall.append((x, y, zone_of[r], r))
    return floor, wall


# ---------------------------------------------------------------- MapGen's picking, as in shared/MapGen.luau
def pick_all(floor, wall, rnd):
    taken, used_rooms, out = set(), {}, []

    def ok(s):
        return all((s[0] + dx, s[1] + dy) not in taken for dx in (-1, 0, 1) for dy in (-1, 0, 1))

    def pick(pool, zones, kind=None, room_limit=None):
        cands = [s for s in pool if s[2] in zones and ok(s)]
        if kind and room_limit is not None:
            fresh = [s for s in cands if used_rooms.get((kind, s[3]), 0) < room_limit]
            if fresh:
                cands = fresh
        if not cands:
            return None
        s = cands[rnd.randrange(len(cands))]
        taken.add((s[0], s[1]))
        if kind:
            used_rooms[(kind, s[3])] = used_rooms.get((kind, s[3]), 0) + 1
        return s

    plan = ([('balloon', (1,), 1)] * 2 + [('balloon', (2,), 1)] + [('plant', (1,), None)] + [('present', (1,), 1)] * 2
            + [('present', (1, 2), 1)] * 2 + [('search', (1,), 1)] * 7 + [('search', (2,), 1)] * 3 + [('search', (3,), 1)]
            + [('hide', (1, 2, 3), 1)] * 8 + [('decoy', (1, 2, 3), 1)] * 3)
    for kind, zones, limit in plan:
        k = 'balloon' if kind == 'decoy' else kind
        s = pick(floor, zones, k, limit)
        out.append((kind, s))
    wtaken = set()
    for kind in ('invite', 'uv'):
        cands = [s for s in wall if s[2] == 2 and all((s[0] + dx, s[1]) not in wtaken for dx in (-1, 0, 1))]
        s = cands[rnd.randrange(len(cands))] if cands else None
        if s:
            wtaken.add((s[0], s[1]))
        out.append((kind, s))
    return out


def trial(p, floor, wall, rnd):
    out = pick_all(floor, wall, rnd)
    problems = []
    placed = [s for _, s in out if s]
    for kind, s in out:
        if s is None:
            problems.append('no slot for %s' % kind)
    solid = [(s[0], s[1]) for k, s in out if s and k not in ('invite', 'uv')]
    allopen = reach(p, {'L1', 'L2'}, solid)
    rooms = {room_of(p, x, y) for x, y in allopen} - {None}
    if len(rooms) != len(p.floors):
        problems.append('objects cut off a room')
    for k, s in out:
        if s and k not in ('invite', 'uv') and not any((s[0] + dx, s[1] + dy) in allopen for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            problems.append('%s at %s cannot be reached' % (k, s[:2]))
    for o in p.fixed:
        if o['kind'] in ('door',):
            if (o['x'], o['y'] + 1) not in allopen:
                problems.append('the exit is cut off')
    return problems


# ---------------------------------------------------------------- run
plans = []
a = plan_a()
for p in (a, mirror(a, 'b', 'The Party House'), plan_c()):
    problems, zone_of, allopen = check(p)
    floor, wall = slots(p, zone_of, allopen)
    print('plan %s: zones %s; %d floor slots, %d wall slots (zone 2: %d)' % (
        p.id, {z: sorted(r for r in zone_of if zone_of[r] == z) for z in (1, 2, 3)}, len(floor), len(wall), sum(1 for s in wall if s[2] == 2)))
    rnd = random.Random(1)
    seen = set()
    for _ in range(500):
        for prob in trial(p, floor, wall, rnd):
            seen.add(prob)
    problems += sorted(seen)
    for row in p.grid:
        print('  ' + ''.join(row))
    if problems:
        raise SystemExit('PLAN %s PROBLEMS:\n  ' % p.id + '\n  '.join(problems))
    plans.append((p, zone_of, floor, wall))


def lua(v):
    if isinstance(v, bool):
        return 'true' if v else 'false'
    if isinstance(v, (int, float)):
        return repr(v)
    return '"%s"' % v


out = ['--[[',
       '\tHouseMap - the Party House floor plans. GENERATED by tools/make_housemap.py:',
       '\tedit that file and run it, do not edit this one by hand.',
       '\tEach game shared/MapGen.luau picks a plan and scatters the movable',
       '\tobjects over its checked slots { x, y, zone, room }.',
       '\tMap key: # wall, . floor, T furniture, L locked door, D the big exit',
       '\tdoor, H the hole behind the cabinet (Muscle), C the host\'s door.',
       ']]', '', 'return {']
for p, zone_of, floor, wall in plans:
    out += ['\t{', '\t\tid = "%s",' % p.id, '\t\tname = "%s",' % p.name, '\t\tw = %d,' % W, '\t\th = %d,' % H, '\t\tmap = {']
    out += ['\t\t\t"%s",' % ''.join(r) for r in p.grid]
    out += ['\t\t},', '\t\tfloors = {']
    out += ['\t\t\t{ x0 = %d, y0 = %d, x1 = %d, y1 = %d, kind = "%s", name = "%s", zone = %d },' % (f + (zone_of[f[5]],)) for f in p.floors]
    out += ['\t\t},', '\t\tfurniture = {']
    out += ['\t\t\t{ x0 = %d, y0 = %d, x1 = %d, y1 = %d, kind = "%s" },' % f for f in p.furniture]
    out += ['\t\t},',
            '\t\tstart = { %s },' % ', '.join('{ %d, %d }' % t for t in p.start),
            '\t\tspawn = { %d, %d },' % p.spawn,
            '\t\tcake = { %d, %d },' % p.cake,
            '\t\tpatrol = { %s },' % ', '.join(('{ %d, %d, lock = "%s" }' % t) if len(t) == 3 else ('{ %d, %d }' % t) for t in p.patrol),
            '\t\tfixed = {']
    for o in p.fixed:
        out.append('\t\t\t{ %s },' % ', '.join('%s = %s' % (k, lua(o[k])) for k in ('id', 'kind', 'name', 'x', 'y') if k in o))
    out += ['\t\t},', '\t\tprops = {']
    for s in p.props:
        out.append('\t\t\t{ name = "%s", x = %d, y = %d, w = %d, d = %d, h = %s, face = "%s"%s },' % (s[0], s[1], s[2], s[3], s[4], s[5], s[6], ', hang = true' if len(s) > 7 else ''))
    out += ['\t\t},', '\t\tfloorSlots = {']
    out += ['\t\t\t{ %d, %d, %d, "%s" },' % s for s in floor]
    out += ['\t\t},', '\t\twallSlots = {']
    out += ['\t\t\t{ %d, %d, %d, "%s" },' % s for s in wall]
    out += ['\t\t},', '\t},']
out += ['}', '']
path = os.path.join(os.path.dirname(__file__), '..', 'roblox', 'src', 'shared', 'HouseMap.luau')
open(path, 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
print('wrote', os.path.normpath(path))
