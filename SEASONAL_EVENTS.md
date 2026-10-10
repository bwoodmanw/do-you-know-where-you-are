# Seasonal events - Thanksgiving and Christmas, every year (ideas, 10 Oct 2026)

Brent's brief: a few new **skins** for Thanksgiving, **two new characters**
for Christmas (mistletoe, holly, maybe a reindeer friend; a combined ability
when they play together), a new host and a new map for each, new badges, a
community-wide goal, and **years factored in** - the events come back every
year and grow. Pets: later, cosmetic only (ROADMAP). Nothing here is built
yet: Brent picks, then Claude builds.

## 1. The yearly calendar (the "years" part)

Today the Halloween hunt has a fixed 2026 end time in `Config.EVENT`. Each
event becomes a **season with yearly rules**, worked out from the date, so it
returns every year with no code change:

| Season | Runs (US Eastern) | 2026 | Event page by (7+ days ahead, for featuring) |
|---|---|---|---|
| Halloween - Candy Corn Hunt | 1 Oct - 1 Nov | running now | done |
| Thanksgiving | 2 Nov - the Monday after Thanksgiving (4th Thursday of Nov) | 2 - 30 Nov | **26 Oct 2026** |
| Christmas / winter | 1 Dec - 4 Jan (New Year inside it) | 1 Dec - 4 Jan 2027 | **24 Nov 2026** |

- Each season's shop stays open a week after it ends (as the Candy Shop does).
- **What returns every year:** the season's map (secret seasonal floor),
  host, hunt, shop and skins (on sale again). Players keep the season's
  currency between years (corns found in 2026 still count in 2027).
- **What is new each year:** one more host or map and a few skins (e.g.
  Thanksgiving 2027 adds the second host idea below). Each year's event page
  says what is new.
- **Badges:** one permanent badge per season (earned in any year). Decision
  below on a yearly badge as well.
- Clocks: Halloween's end time today is midnight Eastern; the rules use
  Eastern time each year (daylight saving changes on 1 Nov 2026 - the code
  works it out, no fixed numbers).

## 2. Thanksgiving - pick one (3 skins, a host, a map, a badge, a community goal)

All four share the same skins and badge; they differ in the hunt, the host
and the map.

**Skins (3, plus a 4th if wanted)** - for the characters with the fewest
skins, all kid-safe, no pilgrim or Native costumes (stereotypes), no team
logos:
- **Chef Brainy** - tall white chef's hat (propeller on top), white chef
  jacket, checked pants, a wooden spoon behind his ear instead of the pencil.
- **Gobble Shadow** - a brown turkey-costume hoodie with a little beak on the
  hood and a fan of tail feathers on the back: the sneakiest turkey.
- **Pie Baker Patch** - an orange-and-cream apron over her vest, oven mitts, a
  flour smudge, a pie-shaped bag.
- (4th, optional) **Harvest Glow** - a corn-yellow raincoat with a lantern
  shaped like a tiny pumpkin pie.

Badge: **Turkey Wrangler** (reach the season's goal).

| | A. Runaway Turkey Roundup (Brent's turkey hunt) | B. The Great Feast Kitchen | C. Feather Hunt (light) | D. A + C together |
|---|---|---|---|---|
| The hunt | Little runaway turkeys hide on the secret floor; when a kid gets near, the turkey **runs** - kids chase and corner them (the reverse of the host chase) while the host chases the kids | Kids are shrunk in a giant kitchen and collect 3 ingredients (cranberry, corn, pumpkin) to bake the Golden Pie that opens the exit | Golden feathers on every floor of every building, exactly like the candy corns (the code exists) | Feathers on every floor **and** the turkey roundup on the secret floor |
| New host | **The Gobbler** - a huge, grumpy turkey in a farmer's straw hat | **Pie Crusty** - a walking pie-crust chef with a rolling pin | none (the building's own host) | The Gobbler |
| New map | **Harvest Barn** - hay bales, a corn maze room, a hayloft, a tractor shed (secret seasonal floor, open from the Lobby during the season) | **Grandma's Kitchen** - giant table, oven, pantry, sink | none | Harvest Barn |
| Community goal | **The Feast Meter**: every turkey caught by anyone adds up; at 3 stages everyone gets a reward (points, a free boost, a Lobby feast table with a giant pie) | Pies baked worldwide fill the meter | Feathers found worldwide fill the meter | Turkeys **and** feathers fill the meter |
| Work | new turkey runner (simple chase AI), host, map: medium | new collect-and-bake loop, host, map: medium-large | small (reuse the corn hunt) | medium (A plus the corn code) |

**Recommendation: D** - the feather hunt on every floor brings everyone to
the event whatever building they are on (cheap: the corn hunt's code), and
the Turkey Roundup on the Harvest Barn floor is the new fun thing (kids chase
for once - funny and different). **Pie Crusty and Grandma's Kitchen become
Thanksgiving 2027's new host and map** - that is the "years" part working.
Time: the 3 skins and the Gobbler go through TOON_WORKFLOW; the barn through
`make_housemap.py`. Tight but doable by 2 Nov if picked this week; the event
page (26 Oct) only needs the picture and the text.

## 3. Christmas - pick one (2 new characters, a combined ability, a host, a map, a badge, a community goal)

**Two new characters** (each has a skill, a power, a 20-level ladder that
must pass `tools/check_ladder*.luau`, and must not copy a current skill:
Bramble has vines, Muscle barricades, Patch heals stamina and shields):

| | Option 1: Holly + Miles (mistletoe) | Option 2: Holly + Comet (reindeer friend) |
|---|---|---|
| Character 1 | **Holly** - a girl with red holly-berry hair clips, a green coat and a red-and-white scarf. Skill **Jingle**: her bells ring when the host is near (a warning for the whole party, like a short-range Echo). Power **Wreath**: hangs a wreath on a door - friends who run through it get a 3-second speed boost | **Holly** - the same |
| Character 2 | **Miles** - a boy with a mistletoe sprig on a headband and a cozy sweater. Skill: opens gift-wrapped boxes (Christmas loot) twice as fast. Power **Mistletoe**: hangs mistletoe in a doorway - the host stops under it, puzzled, for 3 seconds | **Comet** - a kid in a reindeer hoodie with antlers and a red nose. Skill: runs fastest on snow and ice. Power **Sleigh Dash**: a short dash that carries one friend along |
| **Combined (both in the party)** | **Deck the Doorway**: a wreath and mistletoe on the same doorway within 10 seconds make a festive gate the host cannot pass for 8 seconds; kids pass freely | **Lead the Way**: Comet's nose lights the path to the next thing to do (Brainy's Think) whenever Holly's bells ring |

Both options avoid well-known characters (no red-nosed reindeer named
Rudolph, no green Christmas thief, no snowman with a corncob pipe and top hat).

**Host** (pick one): **Sir Shivers** - a tall, polite ice-sculpture butler
who leaves frost footprints; or **Blizzard Bob** - a grumpy, lumpy snow giant
with a pinecone nose and a knitted hat.

**Map** (secret seasonal floor; pick one): **Candy Cane Lane** - a toy
workshop street with a gingerbread house, a toy factory and a wrapping room;
or **Reindeer Stables** - stalls, a hay loft, a sleigh garage, a frozen pond
(slippery).

**Hunt and community goal:** lost ornaments on every floor (the corn code);
**Light the Giant Tree** - a big tree in the Lobby that gets more lights as
the whole community finds ornaments; at 3 stages everyone gets a reward, and
when it is fully lit, snow falls in the Lobby until New Year. **New Year's
Eve:** fireworks over the Lobby at midnight Eastern (small extra).

Badge: **Tree Lighter** (reach the season's goal).

**Recommendation: Option 1 (Holly + Miles)** - the mistletoe doorway is
Brent's idea, the two powers are different from everything the crew has
(a warning bell, a doorway trap), and the combined Deck the Doorway rewards
playing together without making either one weak alone. **Comet the reindeer
friend becomes Christmas 2027's new character.** Host: **Sir Shivers**
(stranger and funnier than another snow giant; Snow Day Muscle already covers
snowmen-ish looks). Map: **Candy Cane Lane** (bright and festive; the stables
can be 2027's map).

## 4. Decisions for Brent

1. **Thanksgiving: A, B, C or D?** (recommended D). Then the 3 skins as
   listed, or swap any.
2. **Thanksgiving start:** 2 Nov, straight after Halloween (recommended:
   the event page goes up by 26 Oct), or later (mid-November, page a week
   before).
3. **Christmas: Option 1 or 2?** (recommended 1), host Sir Shivers or Blizzard
   Bob, map Candy Cane Lane or Reindeer Stables.
4. **Years:** build the yearly calendar now (recommended - it replaces
   Halloween's fixed 2026 date before Thanksgiving is built), so all three
   seasons return every year by themselves.
5. **A yearly badge too** (e.g. "Thanksgiving 2026") on top of the permanent
   one? Recommended **no** for now: one badge per season keeps the badge list
   short; a yearly skin color is a better "I was there" reward.
6. **Are the new characters and skins paid or earned?** Recommended: the
   season's skins earned with its currency (like Muscle Mummy for 100 corns)
   or bought as Game Passes; the two Christmas characters free for everyone
   (characters are gameplay, not cosmetics).

Once picked: one ChatGPT picture workflow (Brent's format) for all the new
skins / characters / hosts, then TOON_WORKFLOW models, maps, code, event
pages (`tools/make_event_art.py`) and `EVENTS.md` text.
