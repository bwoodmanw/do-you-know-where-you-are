"""Builds roblox/src/shared/HouseMap.luau - the Party House floor plans - and checks them.

Edit the layouts here, not in HouseMap.luau. Run: python tools/make_housemap.py

Each game the server (shared/MapGen.luau) picks one floor plan at random and
scatters the balloons, presents, search spots, hiding places and skill puzzles
over that plan's checked SLOTS. This script:
  - checks every plan: rooms behind the locked doors only reachable through
    them, the exit reachable once both are open (each game one of the two
    locked doors is Muscle's blocked passage instead - same check);
  - works out the slots (floor tiles against a wall or furniture, clear of
    doorways, starts, patrol points and the cage; wall tiles
    with a room to their south for the posters);
  - plays MapGen's picking 2000 times per plan and checks every result: every
    room still reachable, every object can be walked up to.

Each plan also gets two bonus store rooms (add_closets): B1 locked, B2 blocked.

Map key: # wall, . floor, T furniture, L locked door (or the blocked passage),
D the big exit door, C the host's door.
"""
import os
import random
from collections import deque

W, H = 40, 30
TRIALS = int(os.environ.get("TRIALS", "2000"))


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
        self.exit_style = 'garden'  # 'stairs' on upper floors: the way out is a stairwell
        self.loft = None             # a raised gallery inside a tall room (see plan_bedrooms)
        self.tall = set()            # rooms with a high ceiling
        self.exit_text = ''          # the sign over an upper floor's way out
        self.building, self.floor_no = 'partyhouse', 1
        self.theme = 'party'         # colours, materials and decorations
        self.pads = []               # bounce pads (Gummy Bounce House)
        self.closets = []            # the two bonus store rooms' inside tiles (add_closets)

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
    p.fixed = [dict(id='door', kind='door', x=25, y=0),
               dict(id='L1', kind='lock', x=15, y=9, name='Library door'), dict(id='L2', kind='lock', x=20, y=5, name='Corridor door'),
               dict(id='cage', kind='cage', x=12, y=27),
               # crawl vents: through a wall between two rooms of the same zone
               dict(id='v1a', kind='vent', pair='v1', x=9, y=17), dict(id='v1b', kind='vent', pair='v1', x=11, y=17),
               dict(id='v2a', kind='vent', pair='v2', x=29, y=11), dict(id='v2b', kind='vent', pair='v2', x=31, y=11)]
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
    p.exit_style, p.tall, p.exit_text = a.exit_style, set(a.tall), a.exit_text
    p.building, p.floor_no, p.theme = a.building, a.floor_no, a.theme
    p.pads = [(m(x), y) for x, y in a.pads]
    p.fixed = [dict(o, ix=m(o['ix'])) if 'ix' in o else o for o in p.fixed]
    p.closets = [(m(x), y) for x, y in a.closets]
    if a.loft:
        L = dict(a.loft)
        L['x0'], L['x1'], L['stair_x'] = m(a.loft['x1']), m(a.loft['x0']), m(a.loft['stair_x'])
        p.loft = L
    return p


# ---------------------------------------------------------------- Gummy Bounce House, floor 1: Bounce Hall
def plan_bounce():
    p = Plan('gum_a', 'Gummy Bounce House - Bounce Hall')
    p.building, p.floor_no, p.theme = 'gummy', 1, 'gummy'
    p.exit_style = 'clouds'
    for x in (10, 20, 30):
        p.rect(x, 0, x, H - 1)
    for y in (9, 19):
        p.rect(0, y, W - 1, y)
    for y in range(1, H - 1):
        p.grid[y][0] = '#'
        p.grid[y][W - 1] = '#'
    p.rect(20, 20, 20, 28, '.')     # the Gummy Lobby spans B and C
    for x, y in [(10, 14), (20, 15), (30, 14), (15, 19), (25, 19), (35, 19), (30, 24), (10, 24), (5, 19), (10, 4), (30, 4)]:
        p.put(x, y, '.')
    p.put(5, 9, 'L')     # L1: Candy Kitchen -> Sprinkle Room
    p.put(20, 4, 'L')    # L2: Bear Gallery -> Jelly Corridor
    p.put(25, 0, 'D')
    p.put(0, 14, 'C')
    for x, y in [(23, 3), (27, 3), (23, 6), (27, 6)]:
        p.put(x, y, '#')             # candy-cane pillars
    p.rect(20, 22, 20, 24)
    for f in [(2, 11, 6, 11, 'counter'), (13, 12, 17, 16, 'pit'), (2, 23, 8, 23, 'shelf'), (14, 23, 17, 24, 'table'),
              (33, 22, 36, 22, 'planter'), (12, 3, 17, 3, 'shelf'), (3, 3, 6, 5, 'table'), (33, 3, 34, 4, 'table')]:
        p.furnish(*f)
    p.floors = [(1, 1, 9, 8, 'mint', 'Sprinkle Room'), (11, 1, 19, 8, 'lilac', 'Bear Gallery'), (21, 1, 29, 8, 'caramel', 'Jelly Corridor'),
                (31, 1, 38, 8, 'mint', 'Taffy Hall'), (1, 10, 9, 18, 'pinktiles', 'Candy Kitchen'), (11, 10, 19, 18, 'lilac', 'Ball Pit'),
                (21, 10, 29, 18, 'caramel', 'Slide Tower'), (31, 10, 38, 18, 'pinktiles', 'Bounce Room'), (1, 20, 9, 28, 'lilac', 'Sticky Storage'),
                (11, 20, 29, 28, 'pinktiles', 'Gummy Lobby'), (31, 20, 38, 28, 'mint', 'Lollipop Garden')]
    p.tall = {'Slide Tower'}
    p.loft = dict(x0=21, y0=10, x1=29, y1=12, h=7, stair_x=28, stair_y0=13, stair_y1=16)
    p.pads = [(33, 12), (36, 15), (33, 16)]
    p.fixed = [dict(id='door', kind='door', x=25, y=0),
               dict(id='L1', kind='lock', x=5, y=9, name='Sprinkle Room door'), dict(id='L2', kind='lock', x=20, y=4, name='Jelly Corridor door'),
               dict(id='cage', kind='cage', x=12, y=27),
               dict(id='v1a', kind='vent', pair='v1', x=9, y=26), dict(id='v1b', kind='vent', pair='v1', x=11, y=26),
               dict(id='v2a', kind='vent', pair='v2', x=31, y=17), dict(id='v2b', kind='vent', pair='v2', x=29, y=17)]
    p.start = [(17, 27), (18, 27), (19, 27), (21, 27), (22, 27), (23, 27)]
    p.spawn, p.cake = (1, 14), (15, 23)
    p.patrol = [(5, 15), (12, 18), (24, 15), (35, 13), (35, 25), (25, 25), (15, 25), (5, 25),
                (7, 7, 'L1'), (15, 5, 'L1'), (25, 5, 'L2'), (35, 6, 'L2')]
    return p


# ---------------------------------------------------------------- Gummy Bounce House, floor 2: Candy Factory
def plan_factory():
    p = Plan('fac_a', 'Gummy Bounce House - Candy Factory')
    p.building, p.floor_no, p.theme = 'gummy', 2, 'gummy'
    p.exit_style, p.exit_text = 'stairs', 'Up to the Jelly Vault'
    for x in (8, 20, 31):
        p.rect(x, 0, x, H - 1)
    for y in (10, 19):
        p.rect(0, y, W - 1, y)
    for y in range(1, H - 1):
        p.grid[y][0] = '#'
        p.grid[y][W - 1] = '#'
    p.rect(20, 11, 20, 18, '.')     # the Conveyor Hall spans the middle
    p.rect(20, 20, 20, 28, '.')     # and so does the Factory Floor
    for x, y in [(8, 14), (31, 15), (4, 19), (14, 19), (26, 19), (35, 19), (8, 24), (31, 25), (8, 5), (31, 4)]:
        p.put(x, y, '.')
    p.put(14, 10, 'L')   # L1: Conveyor Hall -> Chocolate River
    p.put(20, 5, 'L')    # L2: Chocolate River -> Packing Hall
    p.put(25, 0, 'D')
    p.put(0, 14, 'C')
    for x, y in [(23, 3), (27, 3), (23, 7), (27, 7)]:
        p.put(x, y, '#')             # giant lollipop sticks holding up the roof
    for f in [(11, 14, 18, 14, 'counter'), (22, 16, 28, 16, 'counter'), (2, 12, 6, 12, 'shelf'), (2, 16, 4, 16, 'shelf'),
              (2, 22, 6, 22, 'shelf'), (2, 26, 6, 26, 'shelf'), (14, 22, 16, 23, 'table'), (24, 22, 26, 23, 'table'),
              (34, 23, 36, 24, 'table'), (34, 12, 36, 13, 'bath'), (11, 3, 17, 3, 'counter'), (11, 7, 17, 7, 'counter'),
              (3, 3, 5, 4, 'table'), (2, 8, 6, 8, 'shelf'), (34, 3, 36, 4, 'table'), (33, 7, 34, 7, 'desk')]:
        p.furnish(*f)
    p.floors = [(1, 1, 7, 9, 'mint', 'Wrapper Room'), (9, 1, 19, 9, 'caramel', 'Chocolate River'), (21, 1, 30, 9, 'pinktiles', 'Packing Hall'),
                (32, 1, 38, 9, 'lilac', 'Taste Lab'), (1, 11, 7, 18, 'caramel', 'Sugar Store'), (9, 11, 30, 18, 'pinktiles', 'Conveyor Hall'),
                (32, 11, 38, 18, 'mint', 'Boiler Room'), (1, 20, 7, 28, 'lilac', 'Locker Room'), (9, 20, 30, 28, 'mint', 'Factory Floor'),
                (32, 20, 38, 28, 'caramel', 'Loading Dock')]
    p.fixed = [dict(id='door', kind='door', x=25, y=0),
               dict(id='L1', kind='lock', x=14, y=10, name='Chocolate River door'), dict(id='L2', kind='lock', x=20, y=5, name='Packing Hall door'),
               dict(id='cage', kind='cage', x=10, y=27),
               dict(id='v1a', kind='vent', pair='v1', x=7, y=17), dict(id='v1b', kind='vent', pair='v1', x=9, y=17),
               dict(id='v2a', kind='vent', pair='v2', x=30, y=22), dict(id='v2b', kind='vent', pair='v2', x=32, y=22)]
    p.start = [(17, 27), (18, 27), (19, 27), (21, 27), (22, 27), (23, 27)]
    p.spawn, p.cake = (1, 14), (15, 22)
    p.patrol = [(4, 14), (15, 16), (25, 13), (35, 15), (35, 25), (25, 25), (12, 24), (4, 24),
                (14, 5, 'L1'), (4, 6, 'L1'), (25, 5, 'L2'), (35, 5, 'L2')]
    return p


# ---------------------------------------------------------------- Gummy Bounce House, floor 3: Jelly Vault
def plan_vault():
    p = Plan('vault_a', 'Gummy Bounce House - Jelly Vault')
    p.building, p.floor_no, p.theme = 'gummy', 3, 'gummy'
    p.exit_style = 'clouds'
    for x in (13, 26):
        p.rect(x, 0, x, H - 1)
    for y in (10, 20):
        p.rect(0, y, W - 1, y)
    for x, y in [(13, 24), (26, 25), (19, 20), (13, 14), (26, 12), (36, 20), (6, 20), (26, 4)]:
        p.put(x, y, '.')
    p.put(6, 10, 'L')    # L1: Wobble Room -> Gold Gumdrop Room
    p.put(13, 5, 'L')    # L2: Gold Gumdrop Room -> Vault Door Hall
    p.put(19, 0, 'D')
    p.put(0, 24, 'C')
    for x, y in [(17, 3), (22, 3), (17, 7), (22, 7)]:
        p.put(x, y, '#')             # the vault's striped pillars
    for f in [(16, 14, 21, 16, 'pit'), (2, 13, 4, 14, 'table'), (8, 17, 10, 17, 'shelf'), (29, 13, 30, 14, 'table'),
              (33, 16, 36, 16, 'shelf'), (2, 23, 9, 23, 'shelf'), (16, 23, 18, 24, 'table'), (30, 23, 32, 23, 'desk'),
              (3, 3, 10, 3, 'shelf'), (3, 6, 9, 6, 'shelf'), (29, 7, 35, 7, 'shelf'), (30, 3, 32, 3, 'counter')]:
        p.furnish(*f)
    p.floors = [(1, 1, 12, 9, 'caramel', 'Gold Gumdrop Room'), (14, 1, 25, 9, 'pinktiles', 'Vault Door Hall'), (27, 1, 38, 9, 'lilac', 'Jelly Bank'),
                (1, 11, 12, 19, 'mint', 'Wobble Room'), (14, 11, 25, 19, 'lilac', 'Jelly Pool'), (27, 11, 38, 19, 'caramel', 'Sticky Archive'),
                (1, 21, 12, 28, 'pinktiles', 'Gumball Store'), (14, 21, 25, 28, 'mint', 'Vault Entrance'), (27, 21, 38, 28, 'lilac', 'Security Room')]
    p.pads = [(34, 25), (29, 27)]   # wobbly jelly you can bounce on
    p.fixed = [dict(id='door', kind='door', x=19, y=0),
               dict(id='L1', kind='lock', x=6, y=10, name='Gold Gumdrop door'), dict(id='L2', kind='lock', x=13, y=5, name='Vault door'),
               dict(id='cage', kind='cage', x=15, y=27),
               dict(id='v1a', kind='vent', pair='v1', x=3, y=19), dict(id='v1b', kind='vent', pair='v1', x=3, y=21),
               dict(id='v2a', kind='vent', pair='v2', x=25, y=17), dict(id='v2b', kind='vent', pair='v2', x=27, y=17),
               dict(id='v3a', kind='vent', pair='v3', x=31, y=19), dict(id='v3b', kind='vent', pair='v3', x=31, y=21)]
    p.start = [(18, 27), (19, 27), (20, 27), (21, 27), (22, 27), (23, 27)]
    p.spawn, p.cake = (1, 24), (17, 23)
    p.patrol = [(6, 16), (23, 12), (32, 18), (35, 22), (20, 25), (6, 26), (6, 5, 'L1'), (10, 8, 'L1'), (19, 5, 'L2'), (33, 4, 'L2')]
    return p


# ---------------------------------------------------------------- Abandoned Hospital, floor 1: Ground Floor
def plan_hospital():
    p = Plan('hosp_a', 'Abandoned Hospital - Ground Floor')
    p.building, p.floor_no, p.theme = 'hospital', 1, 'hospital'
    for x in (10, 20, 30):
        p.rect(x, 0, x, 9)          # the rooms along the top
        p.rect(x, 14, x, H - 1)     # and along the bottom
    for y in (9, 14):
        p.rect(0, y, W - 1, y)      # the Main Corridor runs between them
    p.rect(0, 22, 9, 22)            # Waiting Room / Laundry
    p.rect(30, 22, W - 1, 22)       # X-Ray Room / Canteen
    for y in range(1, H - 1):
        p.grid[y][0] = '#'
        p.grid[y][W - 1] = '#'
    p.rect(20, 15, 20, 28, '.')     # Reception spans the middle
    for x, y in [(5, 14), (15, 14), (25, 14), (35, 14), (5, 22), (10, 25), (30, 18), (35, 22), (10, 4), (30, 4)]:
        p.put(x, y, '.')
    p.put(15, 9, 'L')    # L1: Main Corridor -> Pharmacy
    p.put(20, 5, 'L')    # L2: Pharmacy -> Ambulance Bay
    p.put(25, 0, 'D')
    p.put(0, 11, 'C')
    for x, y in [(23, 6), (27, 6)]:
        p.put(x, y, '#')             # concrete pillars in the Ambulance Bay
    for f in [(3, 19, 6, 19, 'table'), (2, 24, 3, 25, 'bath'), (6, 27, 8, 27, 'shelf'), (13, 17, 18, 17, 'counter'),
              (22, 24, 24, 25, 'table'), (26, 17, 27, 17, 'desk'), (33, 16, 34, 17, 'bed'), (36, 20, 37, 20, 'desk'),
              (32, 25, 34, 26, 'table'), (33, 28, 37, 28, 'counter'), (24, 10, 25, 10, 'bed'), (8, 13, 9, 13, 'table'),
              (2, 3, 8, 3, 'shelf'), (2, 6, 8, 6, 'shelf'), (12, 2, 18, 2, 'counter'), (12, 7, 14, 7, 'shelf'),
              (22, 3, 23, 4, 'bed'), (33, 3, 35, 4, 'table'), (37, 7, 38, 7, 'desk')]:
        p.furnish(*f)
    p.floors = [(1, 1, 9, 8, 'greylino', 'Records Room'), (11, 1, 19, 8, 'whitetiles', 'Pharmacy'), (21, 1, 29, 8, 'greylino', 'Ambulance Bay'),
                (31, 1, 38, 8, 'mintlino', 'Staff Room'), (1, 10, 38, 13, 'mintlino', 'Main Corridor'), (1, 15, 9, 21, 'whitetiles', 'Waiting Room'),
                (1, 23, 9, 28, 'greylino', 'Laundry'), (11, 15, 29, 28, 'whitetiles', 'Reception'), (31, 15, 38, 21, 'greylino', 'X-Ray Room'),
                (31, 23, 38, 28, 'mintlino', 'Canteen')]
    p.fixed = [dict(id='door', kind='door', x=25, y=0),
               dict(id='L1', kind='lock', x=15, y=9, name='Pharmacy door'), dict(id='L2', kind='lock', x=20, y=5, name='Ambulance Bay door'),
               dict(id='cage', kind='cage', x=12, y=27),
               dict(id='v1a', kind='vent', pair='v1', x=9, y=20), dict(id='v1b', kind='vent', pair='v1', x=11, y=20),
               dict(id='v2a', kind='vent', pair='v2', x=29, y=16), dict(id='v2b', kind='vent', pair='v2', x=31, y=16),
               dict(id='v3a', kind='vent', pair='v3', x=37, y=21), dict(id='v3b', kind='vent', pair='v3', x=37, y=23)]
    p.start = [(17, 27), (18, 27), (19, 27), (21, 27), (22, 27), (23, 27)]
    p.spawn, p.cake = (1, 11), (23, 24)
    p.patrol = [(5, 12), (20, 11), (34, 12), (5, 18), (5, 25), (16, 22), (28, 26), (34, 18), (35, 25),
                (15, 5, 'L1'), (5, 5, 'L1'), (25, 4, 'L2'), (35, 5, 'L2')]
    p.props = [("Bench", 2, 15, 2, 1, 4, "s"), ("PottedPlant", 11, 15, 1, 1, 7, "e"), ("PottedPlant", 29, 15, 1, 1, 7, "w"),
               ("Bench", 31, 8, 2, 1, 4, "n")]
    return p


# ---------------------------------------------------------------- Abandoned Hospital, floor 2: the Wards
def plan_wards():
    p = Plan('ward_a', 'Abandoned Hospital - Wards')
    p.building, p.floor_no, p.theme = 'hospital', 2, 'hospital'
    p.exit_style, p.exit_text = 'stairs', 'Up to the Labs'
    for x in (10, 20, 30):
        p.rect(x, 0, x, H - 1)
    for y in (9, 19):
        p.rect(0, y, W - 1, y)
    for y in range(1, H - 1):
        p.grid[y][0] = '#'
        p.grid[y][W - 1] = '#'
    p.rect(20, 20, 20, 28, '.')     # the Nurses' Station spans the bottom middle
    for x, y in [(10, 24), (30, 25), (15, 19), (25, 19), (10, 14), (5, 19), (30, 13), (20, 16), (35, 19), (10, 4), (30, 4)]:
        p.put(x, y, '.')
    p.put(15, 9, 'L')    # L1: Ward B -> Medicine Store
    p.put(20, 5, 'L')    # L2: Medicine Store -> Stairwell
    p.put(25, 0, 'D')
    p.put(0, 14, 'C')
    p.rect(20, 22, 20, 24)
    p.rect(25, 11, 25, 13)
    p.rect(34, 21, 34, 23)
    for x, y in [(23, 3), (27, 3), (23, 6), (27, 6)]:
        p.put(x, y, '#')
    p.rect(4, 4, 6, 4)
    for f in [(2, 11, 6, 11, 'bed'), (4, 15, 6, 16, 'bed'), (12, 13, 17, 14, 'bed'), (12, 3, 17, 3, 'shelf'),
              (13, 6, 18, 6, 'shelf'), (2, 21, 8, 21, 'shelf'), (2, 25, 6, 25, 'shelf'), (14, 23, 17, 24, 'counter'),
              (22, 15, 23, 16, 'table'), (33, 14, 36, 14, 'bed'), (33, 3, 35, 3, 'desk')]:
        p.furnish(*f)
    p.floors = [(1, 1, 9, 8, 'greylino', "Nurses' Office"), (11, 1, 19, 8, 'whitetiles', 'Medicine Store'), (21, 1, 29, 8, 'greylino', 'Stairwell'),
                (31, 1, 38, 8, 'mintlino', 'Quiet Room'), (1, 10, 9, 18, 'mintlino', 'Ward A'), (11, 10, 19, 18, 'mintlino', 'Ward B'),
                (21, 10, 29, 18, 'whitetiles', 'Day Room'), (31, 10, 38, 18, 'whitetiles', "Children's Ward"), (1, 20, 9, 28, 'greylino', 'Linen Room'),
                (11, 20, 29, 28, 'whitetiles', "Nurses' Station"), (31, 20, 38, 28, 'whitetiles', 'Bathroom')]
    p.fixed = [dict(id='door', kind='door', x=25, y=0),
               dict(id='L1', kind='lock', x=15, y=9, name='Medicine Store door'), dict(id='L2', kind='lock', x=20, y=5, name='Stairwell door'),
               dict(id='cage', kind='cage', x=12, y=27),
               dict(id='v1a', kind='vent', pair='v1', x=9, y=17), dict(id='v1b', kind='vent', pair='v1', x=11, y=17),
               dict(id='v2a', kind='vent', pair='v2', x=29, y=11), dict(id='v2b', kind='vent', pair='v2', x=31, y=11)]
    p.start = [(17, 27), (18, 27), (19, 27), (21, 27), (22, 27), (23, 27)]
    p.spawn, p.cake = (1, 14), (22, 15)
    p.patrol = [(5, 13), (15, 16), (24, 17), (34, 16), (35, 25), (24, 21), (13, 26), (5, 27),
                (15, 5, 'L1'), (6, 7, 'L1'), (25, 5, 'L2'), (35, 6, 'L2')]
    return p


# ---------------------------------------------------------------- Abandoned Hospital, floor 3: the Labs
def plan_labs():
    p = Plan('lab_a', 'Abandoned Hospital - Labs')
    p.building, p.floor_no, p.theme = 'hospital', 3, 'hospital'
    p.exit_style, p.exit_text = 'stairs', 'Out onto the helipad!'
    for x in (13, 26):
        p.rect(x, 0, x, H - 1)
    for y in (10, 20):
        p.rect(0, y, W - 1, y)
    for x, y in [(13, 25), (26, 24), (19, 20), (22, 20), (6, 20), (13, 15), (26, 16), (33, 20), (26, 4)]:
        p.put(x, y, '.')
    p.put(6, 10, 'L')    # L1: Science Lab -> Lab Store
    p.put(13, 5, 'L')    # L2: Lab Store -> Helipad Stairs
    p.put(19, 0, 'D')
    p.put(0, 24, 'C')
    for x, y in [(17, 3), (22, 3), (17, 7), (22, 7)]:
        p.put(x, y, '#')
    p.rect(21, 12, 21, 14)
    p.rect(20, 23, 20, 25)
    p.rect(31, 22, 31, 24)
    for f in [(2, 3, 10, 3, 'shelf'), (3, 6, 11, 6, 'shelf'), (2, 13, 8, 13, 'counter'), (5, 16, 7, 17, 'counter'),
              (29, 14, 35, 15, 'planter'), (16, 16, 17, 17, 'table'), (2, 22, 10, 22, 'shelf'), (2, 26, 8, 26, 'shelf'),
              (30, 3, 32, 3, 'desk'), (15, 22, 17, 23, 'counter')]:
        p.furnish(*f)
    p.floors = [(1, 1, 12, 9, 'greylino', 'Lab Store'), (14, 1, 25, 9, 'greylino', 'Helipad Stairs'), (27, 1, 38, 9, 'mintlino', 'Radio Room'),
                (1, 11, 12, 19, 'whitetiles', 'Science Lab'), (14, 11, 25, 19, 'mintlino', 'Lift Lobby'), (27, 11, 38, 19, 'greylino', 'Plant Lab'),
                (1, 21, 12, 28, 'greylino', 'Supply Room'), (14, 21, 25, 28, 'whitetiles', 'Lab Entrance'), (27, 21, 38, 28, 'greylino', 'Generator Room')]
    p.fixed = [dict(id='door', kind='door', x=19, y=0),
               dict(id='L1', kind='lock', x=6, y=10, name='Lab Store door'), dict(id='L2', kind='lock', x=13, y=5, name='Helipad door'),
               dict(id='cage', kind='cage', x=15, y=27),
               dict(id='v1a', kind='vent', pair='v1', x=12, y=18), dict(id='v1b', kind='vent', pair='v1', x=14, y=18),
               dict(id='v2a', kind='vent', pair='v2', x=36, y=19), dict(id='v2b', kind='vent', pair='v2', x=36, y=21)]
    p.start = [(18, 27), (19, 27), (20, 27), (21, 27), (22, 27), (23, 27)]
    p.spawn, p.cake = (1, 24), (16, 16)
    p.patrol = [(6, 14), (19, 14), (32, 17), (33, 25), (19, 24), (6, 27), (6, 4, 'L1'), (10, 8, 'L1'), (19, 5, 'L2'), (33, 6, 'L2')]
    return p


# ---------------------------------------------------------------- floor 3: the Attic
def plan_attic():
    p = Plan('attic_a', 'The Party House - Attic')
    p.floor_no = 3
    p.exit_style, p.exit_text = 'stairs', 'Out onto the roof!'
    for x in (13, 26):
        p.rect(x, 0, x, H - 1)
    for y in (10, 20):
        p.rect(0, y, W - 1, y)
    for x, y in [(13, 24), (26, 25), (19, 20), (13, 14), (26, 12), (36, 20), (6, 20), (26, 4)]:
        p.put(x, y, '.')
    p.put(6, 10, 'L')    # L1: Trunk Room -> Clock Room
    p.put(13, 5, 'L')    # L2: Clock Room -> Rooftop Stairs
    p.put(19, 0, 'D')
    p.put(0, 24, 'C')
    for x, y in [(17, 13), (22, 13), (17, 17), (22, 17), (17, 3), (22, 3), (17, 7), (22, 7)]:
        p.put(x, y, '#')             # rafters holding up the roof
    for f in [(2, 13, 4, 14, 'table'), (8, 17, 10, 17, 'shelf'), (2, 23, 9, 23, 'shelf'), (29, 13, 30, 14, 'bed'),
              (33, 16, 36, 16, 'shelf'), (16, 23, 18, 24, 'table'), (30, 23, 33, 24, 'bath'), (3, 3, 10, 3, 'shelf'),
              (3, 6, 9, 6, 'shelf'), (29, 7, 35, 7, 'shelf'), (30, 3, 32, 3, 'piano')]:
        p.furnish(*f)
    p.floors = [(1, 1, 12, 9, 'boards', 'Clock Room'), (14, 1, 25, 9, 'boards', 'Rooftop Stairs'), (27, 1, 38, 9, 'purple', 'Doll Room'),
                (1, 11, 12, 19, 'wood', 'Trunk Room'), (14, 11, 25, 19, 'boards', 'Dusty Storage'), (27, 11, 38, 19, 'carpet', 'Old Nursery'),
                (1, 21, 12, 28, 'boards', 'Box Room'), (14, 21, 25, 28, 'wood', 'Attic Landing'), (27, 21, 38, 28, 'tiles', 'Water Tank Room')]
    p.fixed = [dict(id='door', kind='door', x=19, y=0),
               dict(id='L1', kind='lock', x=6, y=10, name='Clock Room door'), dict(id='L2', kind='lock', x=13, y=5, name='Roof door'),
               dict(id='cage', kind='cage', x=15, y=27),
               dict(id='v1a', kind='vent', pair='v1', x=3, y=19), dict(id='v1b', kind='vent', pair='v1', x=3, y=21),
               dict(id='v2a', kind='vent', pair='v2', x=25, y=16), dict(id='v2b', kind='vent', pair='v2', x=27, y=16),
               dict(id='v3a', kind='vent', pair='v3', x=31, y=19), dict(id='v3b', kind='vent', pair='v3', x=31, y=21)]
    p.start = [(18, 27), (19, 27), (20, 27), (21, 27), (22, 27), (23, 27)]
    p.spawn, p.cake = (1, 24), (17, 23)
    p.patrol = [(6, 16), (19, 15), (32, 18), (34, 26), (19, 25), (6, 26), (6, 5, 'L1'), (10, 8, 'L1'), (19, 5, 'L2'), (33, 4, 'L2')]
    return p


# ---------------------------------------------------------------- floor 2: the Bedrooms
def plan_bedrooms():
    p = Plan('bed_a', 'The Party House - Bedrooms')
    p.floor_no = 2
    p.exit_style, p.exit_text = 'stairs', 'Up to the Attic'
    for x in (10, 20, 30):
        p.rect(x, 0, x, H - 1)
    for y in (9, 19):
        p.rect(0, y, W - 1, y)
    for y in range(1, H - 1):
        p.grid[y][0] = '#'
        p.grid[y][W - 1] = '#'
    p.rect(20, 10, 20, 18, '.')     # the Gallery spans B and C, two storeys high
    for x, y in [(10, 24), (20, 25), (30, 24), (15, 19), (25, 19), (10, 15), (30, 14), (35, 19), (5, 19), (10, 4), (30, 4)]:
        p.put(x, y, '.')
    p.put(5, 9, 'L')     # L1: Kids' Bedroom -> Master Bedroom
    p.put(20, 4, 'L')    # L2: Study -> Stairwell Hall
    p.put(25, 0, 'D')
    p.put(0, 14, 'C')
    for x, y in [(23, 3), (27, 3), (23, 6), (27, 6)]:
        p.put(x, y, '#')
    p.rect(27, 21, 27, 23)          # bathroom stall
    for f in [(2, 11, 3, 12, 'bed'), (6, 11, 7, 12, 'bed'), (3, 2, 6, 4, 'bed'), (13, 2, 15, 2, 'desk'), (12, 6, 17, 6, 'shelf'),
              (33, 3, 34, 4, 'table'), (14, 15, 17, 16, 'table'), (33, 11, 35, 12, 'bed'), (2, 21, 3, 22, 'bed'),
              (22, 21, 25, 22, 'bath'), (32, 23, 36, 23, 'shelf')]:
        p.furnish(*f)
    p.floors = [(1, 1, 9, 8, 'carpet', 'Master Bedroom'), (11, 1, 19, 8, 'green', 'Study'), (21, 1, 29, 8, 'boards', 'Stairwell Hall'),
                (31, 1, 38, 8, 'purple', 'Playroom'), (1, 10, 9, 18, 'carpet', "Kids' Bedroom"), (11, 10, 29, 18, 'wood', 'Gallery'),
                (31, 10, 38, 18, 'green', 'Guest Room'), (1, 20, 9, 28, 'purple', 'Nursery'), (11, 20, 19, 28, 'boards', 'Landing'),
                (21, 20, 29, 28, 'tiles', 'Bathroom'), (31, 20, 38, 28, 'wood', 'Linen Room')]
    p.tall = {'Gallery'}
    # the loft: rows 10-12 of the Gallery, 7 studs up, a ramp down at x 28
    p.loft = dict(x0=11, y0=10, x1=29, y1=12, h=7, stair_x=28, stair_y0=13, stair_y1=16)
    p.fixed = [dict(id='door', kind='door', x=25, y=0),
               dict(id='L1', kind='lock', x=5, y=9, name='Master Bedroom door'), dict(id='L2', kind='lock', x=20, y=4, name='Stairwell door'),
               dict(id='cage', kind='cage', x=12, y=27),
               dict(id='v1a', kind='vent', pair='v1', x=9, y=26), dict(id='v1b', kind='vent', pair='v1', x=11, y=26),
               dict(id='v2a', kind='vent', pair='v2', x=31, y=17), dict(id='v2b', kind='vent', pair='v2', x=29, y=17)]
    p.start = [(14, 27), (15, 27), (16, 27), (17, 27), (18, 27), (19, 27)]
    p.spawn, p.cake = (1, 14), (15, 15)
    p.patrol = [(5, 15), (20, 15), (35, 15), (35, 26), (25, 25), (15, 24), (5, 25),
                (5, 5, 'L1'), (15, 4, 'L1'), (25, 5, 'L2'), (35, 6, 'L2')]
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
    p.fixed = [dict(id='door', kind='door', x=19, y=0),
               dict(id='L1', kind='lock', x=6, y=10, name='Library door'), dict(id='L2', kind='lock', x=13, y=5, name='Corridor door'),
               dict(id='cage', kind='cage', x=15, y=27),
               dict(id='v1a', kind='vent', pair='v1', x=12, y=18), dict(id='v1b', kind='vent', pair='v1', x=14, y=18),
               dict(id='v2a', kind='vent', pair='v2', x=36, y=19), dict(id='v2b', kind='vent', pair='v2', x=36, y=21)]
    p.start = [(18, 27), (19, 27), (20, 27), (21, 27), (22, 27), (23, 27)]
    p.spawn, p.cake = (1, 24), (32, 14)
    p.patrol = [(6, 14), (19, 16), (32, 17), (33, 25), (19, 24), (6, 27), (6, 4, 'L1'), (10, 8, 'L1'), (19, 5, 'L2'), (33, 6, 'L2')]
    return p


# ---------------------------------------------------------------- bonus store rooms
def add_closets(p):
    """Carves two 3 x 3 store rooms into corners of rooms open from the start:
    B1 behind a locked door (Tinker or its key), B2 behind a blocked door
    (Muscle or a Party Popper). A present waits inside each. They are off the
    way out, so a team without Tinker or Muscle can still escape."""
    z1 = reach(p, ())
    rooms1 = [f for f in p.floors if any((x, y) in z1 for y in range(f[1], f[3] + 1) for x in range(f[0], f[2] + 1))]
    keep = set(p.start) | {p.spawn}
    for o in p.fixed:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                keep.add((o['x'] + dx, o['y'] + dy))
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            keep.add((p.cake[0] + dx, p.cake[1] + dy))
            for x, y in p.pads:
                keep.add((x + dx, y + dy))
    for y in range(H):
        for x in range(W):
            if gap(p, x, y):
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        keep.add((x + dx, y + dy))
    if p.loft:
        L = p.loft
        for y in range(L['y0'] - 1, L['stair_y1'] + 2):
            for x in range(L['x0'] - 1, L['x1'] + 2):
                keep.add((x, y))

    def hits(rect, tiles):
        return any(rect[0] <= x <= rect[2] and rect[1] <= y <= rect[3] for x, y in tiles)

    def search(may_go):
      found = []
      for f in rooms1:
        if f[5] in p.tall or (f[2] - f[0]) < 5 or (f[3] - f[1]) < 5:
            continue
        for cx, cy, dx, dy in ((f[0], f[1], 1, 1), (f[2], f[1], -1, 1), (f[0], f[3], 1, -1), (f[2], f[3], -1, -1)):
            inside = [(cx + i * dx, cy + j * dy) for i in range(3) for j in range(3)]
            walls = [(cx + 3 * dx, cy + j * dy) for j in range(4)] + [(cx + i * dx, cy + 3 * dy) for i in range(3)]
            door = (cx + 3 * dx, cy + dy)
            around = [(cx + 4 * dx, cy + j * dy) for j in range(5)] + [(cx + i * dx, cy + 4 * dy) for i in range(4)]
            if any(p.c(*t) not in '.T' or t in keep for t in inside + walls):
                continue
            # furniture in the corner goes (never the cake's table)
            gone = [fu for fu in p.furniture if hits(fu, inside + walls)]
            # only plain shelves and tables may go (never a bath, bed, piano, planter...)
            if any(hits(fu, [p.cake]) for fu in gone) or any(fu[4] not in may_go for fu in gone):
                continue
            freed = {(x, y) for fu in gone for y in range(fu[1], fu[3] + 1) for x in range(fu[0], fu[2] + 1)}
            if any(p.c(*t) not in '.T' or (p.c(*t) == 'T' and t not in freed) for t in around):
                continue
            found.append((len(gone), f, inside, walls, door, gone))
      found.sort(key=lambda c: (c[0], any(s in c[2] for s in p.start), c[1][5]))
      return [c[1:] for c in found]
    # plain shelves and tables may go; if that leaves room for fewer than two
    # store rooms, counters and desks may too (never a bath, bed, piano, planter, pit)
    found = search(('shelf', 'table'))
    if len({c[0][5] for c in found}) < 2:
        found = search(('shelf', 'table', 'counter', 'desk'))
    if len({c[0][5] for c in found}) < 2:
        found = search(('shelf', 'table', 'counter', 'desk', 'bath'))
    picked, used = [], set()
    for c in found:
        if c[0][5] not in used and not any(set(c[1] + c[2]) & set(d[1] + d[2]) for d in picked):
            picked.append(c)
            used.add(c[0][5])
        if len(picked) == 2:
            break
    assert len(picked) == 2, 'plan %s: room for only %d store rooms' % (p.id, len(picked))
    for n, (f, inside, walls, door, gone) in enumerate(picked):
        for fu in gone:
            p.furniture.remove(fu)
            p.rect(fu[0], fu[1], fu[2], fu[3], '.')
        p.props = [s for s in p.props if len(s) > 7 or not hits((s[1], s[2], s[1] + s[3] - 1, s[2] + s[4] - 1), inside + walls)]
        for t in walls:
            p.put(t[0], t[1], '#')
        p.put(door[0], door[1], 'L')
        mid = inside[4]
        if n == 0:
            p.fixed.append(dict(id='B1', kind='lock', bonus=True, name='Store Room door', x=door[0], y=door[1], ix=mid[0], iy=mid[1]))
        else:
            p.fixed.append(dict(id='B2', kind='lock', bonus=True, blocked=True, name='Junk Cupboard door', x=door[0], y=door[1], ix=mid[0], iy=mid[1]))
        p.closets += inside
        # the host's patrol points never inside: moved just outside the door
        out = (door[0] + (door[0] - mid[0]), door[1])
        p.patrol = [((out[0], out[1]) + tuple(t[2:])) if (t[0], t[1]) in inside or (t[0], t[1]) in walls else t for t in p.patrol]
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
        want = {'door': 'D', 'lock': 'L'}.get(o['kind'], '.')
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
    for o in p.fixed:
        if o['kind'] == 'cage' and not any((o['x'] + dx, o['y'] + dy) in allopen for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            problems.append('%s cannot be reached' % o['id'])
    # vents: floor at both ends, one wall between, same zone (no way round a lock)
    zone_tiles = {n: reach(p, set(l)) for n, l in ((1, ()), (2, ('L1',)), (3, ('L1', 'L2')))}
    def zone_at(t):
        return 1 if t in zone_tiles[1] else 2 if t in zone_tiles[2] else 3
    pairs = {}
    for o in p.fixed:
        if o['kind'] == 'vent':
            pairs.setdefault(o['pair'], []).append((o['x'], o['y']))
    for pid, ends in pairs.items():
        if len(ends) != 2:
            problems.append('vent %s needs two ends' % pid)
            continue
        (ax, ay), (bx, by) = ends
        mid = ((ax + bx) // 2, (ay + by) // 2)
        if abs(ax - bx) + abs(ay - by) != 2 or p.c(*mid) != '#':
            problems.append('vent %s ends must be two tiles apart with a wall between' % pid)
        if zone_at(ends[0]) != zone_at(ends[1]):
            problems.append('vent %s would skip a locked door' % pid)
    every = reach(p, {'L1', 'L2', 'B1', 'B2'})
    for o in p.fixed:
        if o.get('bonus') and (o['ix'], o['iy']) not in every:
            problems.append('store room %s cannot be reached' % o['id'])
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
    keep |= set(p.start) | {(t[0], t[1]) for t in p.patrol} | {p.spawn} | set(p.closets)
    for o in p.fixed:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                keep.add((o['x'] + dx, o['y'] + dy))
    for s in p.props:
        if len(s) > 7 or s[5] <= 1:
            continue
        for yy in range(s[2], s[2] + s[4]):
            for xx in range(s[1], s[1] + s[3]):
                keep.add((xx, yy))
    # one-tile-wide aisles (between a wall and a shelf), and the tiles round
    # them: something there could seal a little pocket off
    def is_aisle(x, y):
        return p.c(x, y) == '.' and ((p.c(x, y - 1) in '#T' and p.c(x, y + 1) in '#T') or (p.c(x - 1, y) in '#T' and p.c(x + 1, y) in '#T'))
    for y in range(H):
        for x in range(W):
            if is_aisle(x, y) and not gap(p, x, y):
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        keep.add((x + dx, y + dy))
    for x, y in p.pads:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                keep.add((x + dx, y + dy))
    under_loft = set()
    if p.loft:
        L = p.loft
        for y in range(L['y0'], L['y1'] + 1):
            for x in range(L['x0'], L['x1'] + 1):
                under_loft.add((x, y))
        keep |= under_loft
        for y in range(L['stair_y0'] - 1, L['stair_y1'] + 2):
            for dx in (-1, 0, 1):
                keep.add((L['stair_x'] + dx, y))
    floor, wall = [], []
    for y in range(1, H - 1):
        for x in range(1, W - 1):
            r = room_of(p, x, y)
            if p.c(x, y) == '.' and r and (x, y) not in keep and (x, y) in allopen:
                against = any(p.c(x + dx, y + dy) in '#T' for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                # never in a one-tile-wide aisle (between a wall and a shelf)
                aisle = (p.c(x, y - 1) in '#T' and p.c(x, y + 1) in '#T') or (p.c(x - 1, y) in '#T' and p.c(x + 1, y) in '#T')
                if against and not aisle:
                    floor.append((x, y, zone_of[r], r, 0))
    # up on the loft: the back two rows (the front row stays a walkway)
    if p.loft:
        L = p.loft
        for y in range(L['y0'], L['y1']):
            for x in range(L['x0'], L['x1'] + 1):
                if abs(x - L['stair_x']) > 1:
                    r = room_of(p, x, y)
                    floor.append((x, y, zone_of[r], r, L['h']))
    for y in range(0, H - 1):
        for x in range(W):
            r = room_of(p, x, y + 1)
            if p.c(x, y) == '#' and p.c(x, y + 1) == '.' and r and (x, y + 1) not in keep and (x, y) not in keep and (x, y + 1) not in under_loft:
                wall.append((x, y, zone_of[r], r))
    return floor, wall


# ---------------------------------------------------------------- MapGen's picking, as in shared/MapGen.luau
def pick_all(floor, wall, rnd):
    taken, used_rooms, out = set(), {}, []

    def ok(s):
        return all((s[0] + dx, s[1] + dy) not in taken for dx in (-1, 0, 1) for dy in (-1, 0, 1))

    def pick(pool, zones, kind=None, room_limit=None):
        cands = [s for s in pool if s[2] in zones and ok(s) and not (kind == 'balloon' and len(s) > 4 and s[4] > 0)]
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
a = add_closets(plan_a())
bed = add_closets(plan_bedrooms())
att = add_closets(plan_attic())
gum = add_closets(plan_bounce())
fac = add_closets(plan_factory())
vault = add_closets(plan_vault())
hosp = add_closets(plan_hospital())
ward = add_closets(plan_wards())
lab = add_closets(plan_labs())
for p in (a, mirror(a, 'b', 'The Party House'), add_closets(plan_c()), bed, mirror(bed, 'bed_b', 'The Party House - Bedrooms'),
          att, mirror(att, 'attic_b', 'The Party House - Attic'), gum, mirror(gum, 'gum_b', 'Gummy Bounce House - Bounce Hall'),
          fac, mirror(fac, 'fac_b', 'Gummy Bounce House - Candy Factory'), vault, mirror(vault, 'vault_b', 'Gummy Bounce House - Jelly Vault'),
          hosp, mirror(hosp, 'hosp_b', 'Abandoned Hospital - Ground Floor'),
          ward, mirror(ward, 'ward_b', 'Abandoned Hospital - Wards'), lab, mirror(lab, 'lab_b', 'Abandoned Hospital - Labs')):
    problems, zone_of, allopen = check(p)
    floor, wall = slots(p, zone_of, allopen)
    print('plan %s: zones %s; %d floor slots, %d wall slots (zone 2: %d)' % (
        p.id, {z: sorted(r for r in zone_of if zone_of[r] == z) for z in (1, 2, 3)}, len(floor), len(wall), sum(1 for s in wall if s[2] == 2)))
    rnd = random.Random(1)
    seen = set()
    for _ in range(TRIALS):
        for prob in trial(p, floor, wall, rnd):
            seen.add(prob)
    problems += sorted(seen)
    for row in p.grid:
        print('  ' + ''.join(row))
    if problems:
        raise SystemExit('PLAN %s PROBLEMS:\n  ' % p.id + '\n  '.join(problems))
    plans.append((p, zone_of, floor, wall, p.floor_no))


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
       '\tMap key: # wall, . floor, T furniture, L locked door (or the blocked',
       '\tpassage), D the big exit door, C the host\'s door.',
       '\tReturns building -> floor number -> list of plans.',
       ']]', '', 'return {']
for bld in ('partyhouse', 'gummy', 'hospital'):
 out.append('\t%s = {' % bld)
 for fl in sorted({pfl for p, _, _, _, pfl in plans if p.building == bld}):
  out.append('\t[%d] = {' % fl)
  for p, zone_of, floor, wall, pfl in plans:
    if pfl != fl or p.building != bld:
        continue
    out += ['\t{', '\t\tid = "%s",' % p.id, '\t\tname = "%s",' % p.name, '\t\tw = %d,' % W, '\t\th = %d,' % H,
            '\t\texitStyle = "%s",' % p.exit_style, '\t\texitText = "%s",' % p.exit_text, '\t\ttheme = "%s",' % p.theme,
            '\t\tpads = { %s },' % ', '.join('{ %d, %d }' % t for t in p.pads)]
    if p.loft:
        L = p.loft
        out.append('\t\tloft = { x0 = %d, y0 = %d, x1 = %d, y1 = %d, h = %d, stairX = %d, stairY0 = %d, stairY1 = %d },' % (
            L['x0'], L['y0'], L['x1'], L['y1'], L['h'], L['stair_x'], L['stair_y0'], L['stair_y1']))
    out += ['\t\tmap = {']
    out += ['\t\t\t"%s",' % ''.join(r) for r in p.grid]
    out += ['\t\t},', '\t\tfloors = {']
    out += ['\t\t\t{ x0 = %d, y0 = %d, x1 = %d, y1 = %d, kind = "%s", name = "%s", zone = %d%s },' % (f + (zone_of[f[5]], ', tall = true' if f[5] in p.tall else '')) for f in p.floors]
    out += ['\t\t},', '\t\tfurniture = {']
    out += ['\t\t\t{ x0 = %d, y0 = %d, x1 = %d, y1 = %d, kind = "%s" },' % f for f in p.furniture]
    out += ['\t\t},',
            '\t\tstart = { %s },' % ', '.join('{ %d, %d }' % t for t in p.start),
            '\t\tspawn = { %d, %d },' % p.spawn,
            '\t\tcake = { %d, %d },' % p.cake,
            '\t\tpatrol = { %s },' % ', '.join(('{ %d, %d, lock = "%s" }' % t) if len(t) == 3 else ('{ %d, %d }' % t) for t in p.patrol),
            '\t\tfixed = {']
    for o in p.fixed:
        out.append('\t\t\t{ %s },' % ', '.join('%s = %s' % (k, lua(o[k])) for k in ('id', 'kind', 'name', 'pair', 'x', 'y', 'bonus', 'blocked', 'ix', 'iy') if k in o))
    out += ['\t\t},', '\t\tprops = {']
    for s in p.props:
        out.append('\t\t\t{ name = "%s", x = %d, y = %d, w = %d, d = %d, h = %s, face = "%s"%s },' % (s[0], s[1], s[2], s[3], s[4], s[5], s[6], ', hang = true' if len(s) > 7 else ''))
    out += ['\t\t},', '\t\tfloorSlots = {']
    out += ['\t\t\t{ %d, %d, %d, "%s", %d },' % s for s in floor]
    out += ['\t\t},', '\t\twallSlots = {']
    out += ['\t\t\t{ %d, %d, %d, "%s" },' % s for s in wall]
    out += ['\t\t},', '\t},']
  out.append('\t},')
 out.append('\t},')
out += ['}', '']
path = os.path.join(os.path.dirname(__file__), '..', 'roblox', 'src', 'shared', 'HouseMap.luau')
open(path, 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
print('wrote', os.path.normpath(path))
