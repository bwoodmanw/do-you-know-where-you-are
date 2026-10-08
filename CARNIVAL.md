# Creepy Carnival - building 5 (built 8 Oct)

Three floors, unlocked like the others: escaping the Midnight School's
Classrooms opens the Midway; each floor escaped opens the next. Tower Run
works here too. Plans in `tools/make_housemap.py` (plan_midway, plan_bigtop,
plan_funhouse, each with a mirror), each checked with 2,000 random fills.
Studio Play builds it now (`Config.STUDIO_MAP = "carnival"`).

| Floor | Start | Behind the 1st lock | Way out (behind the 2nd) | Other rooms |
|---|---|---|---|---|
| 1 The Midway | Ticket Booth | Fortune Teller's Tent (a glowing crystal ball) | Main Gate | Carousel, Hall of Mirrors (a little maze of mirror walls), Popcorn Stand, Duck Pond, Toffee Apple Stall, Ring-Toss Stall, Prize Tent |
| 2 The Big Top | Backstage | Ringmaster's Wagon | Funhouse Stairs ("Up to the Funhouse") | The Ring (two storeys, a balcony, circus seats), Trapeze Nets (3 bounce pads), Cannon Deck (the human cannon), Costume Wagon, Juggler's Room, Clown Car Garage, Band Stand, Strongman's Gym |
| 3 The Funhouse | Rolling-Barrel Hall | Spinning Room (a turning floor) | Big Wheel ("Out onto the Big Wheel!") | Slide Tower (the twisty slide), Ball Pit, Laughing Gallery and Clown Mirror Room (wavy mirrors), Tilted Room, Bumper Car Room, Joke Shop |

What plays differently:
- **The carousel** (Midway) turns slowly; hop on and it carries you round.
- **The Hall of Mirrors** is a little maze with mirror walls.
- **Trapeze nets** (Big Top) bounce you up, like the Gummy Bounce House.
- **The human cannon** (Big Top's Cannon Deck) fires you across the floor to
  the far room - the host can't follow (it works like the laundry chute).
- **The twisty slide** (Funhouse's Slide Tower) does the same.
- **The Spinning Room's floor** turns (faster than the carousel).
- The rolling barrel in the Rolling-Barrel Hall is scenery for now.

Look: dark red tent walls, warm bulbs, a purple tent roof; striped stalls,
popcorn carts, a duck pond, a clown car, circus seats, a band stage, prize
walls, costume racks, juggling pins, a strongman's "1 TON" barbell.

## Pictures for the Lobby map screen (Brent)

16:9 (e.g. 1536 x 864), save to `art/roblox-store/maps/`, upload in the
Lobby place (View -> Asset Manager -> Import) and send me the image ids.

Style line for every prompt (the other cards' look):
> Stylised 3D diorama, a cut-away room seen from above at an angle, at night, warm lamps and Halloween string lights in orange and purple, little paper bats, a friendly-spooky mood for kids, no people, no text, no logos.

1. **building-carnival.png** - "A small travelling carnival at night in a field: a red-and-white striped big top tent, a lit Ferris wheel, a carousel with painted horses, striped game stalls, popcorn carts, strings of bulbs between poles, jack-o'-lanterns by the entrance arch, a little fog." + the style line (the outside, not a cut-away).
2. **floor-carnival-midway.png** - "A carnival midway under strings of bulbs: a ticket booth, a carousel with painted horses, a duck pond game with yellow rubber ducks, a popcorn cart, a ring-toss stall with prize shelves, the entrance to a hall of mirrors." + the style line.
3. **floor-carnival-bigtop.png** - "Inside a circus big top: a round ring with sawdust, rising red and blue seats, a balcony, trapeze safety nets, a striped human cannon, a tiny clown car, costume racks backstage." + the style line.
4. **floor-carnival-funhouse.png** - "Inside a funhouse: a giant rolling striped barrel tunnel, a spinning floor with a swirl, wavy fun mirrors, a ball pit, a twisty slide, a crooked tilted room." + the style line.
5. **floor-partyhouse-basement.png** (the Secret Basement's own card, and its badge) - "A cosy-spooky old house cellar: stone walls, cobwebs, wine-rack-style shelves of jam jars, an old furnace glowing orange, candles, a laundry basket, a narrow staircase up to a little door with light under it." + the style line.

## Badges (Brent: Creator Hub -> Escape Crew -> Engagement -> Badges)

| Picture (I make it from the card picture) | Name | Description | Config |
|---|---|---|---|
| `badge-basement.png` (from picture 5) | **Down in the Dark** | Escaped the Party House's Secret Basement. | `BADGES.basement` |
| `badge-tower.png` (made, from the School's clock tower) | **Tower Climber** | Reached the top of a building in one Tower Run. | `BADGES.tower` |
| `badge-carnival.png` (from picture 4) | **Star of the Show** | Escaped the Carnival's Funhouse. | `BADGES.carnival` |
| `badge-aquarium.png` (when the Aquarium is built) | **Making a Splash** | Escaped the Aquarium's Rooftop Pools. | `BADGES.aquarium` |

The code already awards all four once their ids are in (the Basement used
to give the Party House's Attic badge by mistake - fixed).

## The Clown Bear (host)

Picture `art/model-input/host-clownbear/a-pose-front.png` - checked 8 Oct:
no top hat, bow tie or microphone, no tummy symbol, not a known character.
Model name in Studio: **HostClownBear** (Party House ServerStorage ->
Characters). Until his model and power are in, the Carnival's own host is
the Pumpkin Host.

His power - Brent to pick (numbers can change):
- **Jack-in-the-Box (recommended).** At the start of a floor where he is the
  host, 3 / 4 / 5 / 6 boxes (Easy / Normal / Hard / Nightmare) appear on the
  floor's checked spots, like presents (never by a doorway, the exit or the
  starting room). They stay all game. Walk within 6 studs of one (not
  sneaking, not hidden) and it springs open with a honk and a spotlight: he
  knows where you are and comes running. It winds itself back up after 30 s.
  Tinker can wind one down for good (hold 2 s). Shadow sneaks past.
- **Balloon Traps.** While he patrols (not while chasing) he ties a bunch of
  balloons in a doorway he walks through, every 15 / 12 / 10 / 8 s; at most
  3 at once (the oldest floats away), each lasts 45 s. Run through one and
  it pops with a BANG and he heads there. Shadow sneaks through without
  popping it.

## The Aquarium's host: the Anglerfish Keeper (building 6, after the Carnival)

Prompt (no reference picture; Meshy A-Pose as for the other hosts):
> A tall, stooped anglerfish keeper for a kids' spooky game. A big round deep-sea anglerfish head with a wide grin of small blunt teeth, big round milky-blue glowing eyes, dark teal-blue skin with pale spots, a glowing round lure on a thin stalk curving up from his forehead and hanging high above his head. He wears a long yellow fisherman's oilskin coat that ends at the knees, buttoned, a dark blue knitted jumper underneath, a keeper's lanyard with a key card, dark wellington boots. Long thin arms with webbed hands, a clear gap of air between each arm and the body, nothing hanging from the arms. Spooky but friendly, a little sly. Stylised 3D animated-film look, full body, standing in an A-pose facing the camera, plain light grey background, soft even lighting, no text, no logos.

His power: **Fake Treasure** - he leaves glowing decoy presents; open one
and it flashes and calls him over. Glow's light shows a fake; Brainy can
spot them.
