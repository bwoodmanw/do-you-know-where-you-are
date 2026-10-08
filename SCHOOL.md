# Midnight School - building 4 (built 8 Oct)

Three floors, unlocked like the others: escaping the Hospital's Wards opens
the School's Ground Floor; each floor escaped opens the next. Tower Run works
here too. Plans in `tools/make_housemap.py` (plan_school, plan_school2,
plan_school3, each with a mirror), each checked with 2,000 random fills.

| Floor | Start | Behind the 1st lock | Way out (behind the 2nd) | Other rooms |
|---|---|---|---|---|
| 1 Ground Floor | Assembly Hall | Head's Office | Front Lobby (out to the playground) | Long Hallway (lockers), Lost Property, Staff Room, Cafeteria, Kitchen, Music Room, Art Room |
| 2 Classrooms | Landing | Science Lab | Upper Stairs ("Up to the Clock Tower") | the Library (two storeys, a balcony), Computer Room, Trophy Room, Classroom 2B and 2C, Art Room, Washrooms, Caretaker's Room |
| 3 Clock Tower | Exam Hall | Old Classroom | Clock Tower ("Out onto the tower roof!") | Bell Room (a big bell you can ring - the host hears it), Observatory (a telescope), Top Corridor, Storage Loft, Boiler Room, Locker Room, Detention Room |

Look: old green walls, warm lamps, cream ceilings; school desks with chairs,
wooden tables on metal legs, chalkboards with something chalked on them,
trophy cabinets, school pictures (apple, pencil, books, bell, owl). Studio
Play builds it now (`Config.STUDIO_MAP = "school"`).

## Pictures for the Lobby map screen (done 8 Oct)

In `Config.MAP_IMAGES`: building-school 108429364285668, Ground Floor
86527371561332, Classrooms 83786060551446, Clock Tower 111098812594935.
The prompts below made them. Make each at 16:9
(like the others, e.g. 1536 x 864), save to `art/roblox-store/maps/`, upload
in Studio (Lobby place: View -> Asset Manager -> Import, or Creator Hub ->
Development Items -> Decals) and send me the 4 image ids.

Style line for every prompt (the other cards' look):
> Stylised 3D diorama, a cut-away room seen from above at an angle, at night, warm lamps and Halloween string lights in orange and purple, little paper bats, a friendly-spooky mood for kids, no people, no text, no logos.

1. **building-school.png** - "An old red-brick school at night with a tall clock tower, the clock face glowing, arched windows lit warmly, a playground with a hopscotch grid and a swing in front, jack-o'-lanterns on the steps." + the style line (this one is the outside, not a cut-away).
2. **floor-school-ground.png** - "A school's main corridor lined with blue lockers, a trophy cabinet, an assembly hall with rows of chairs and a small stage through an open door, a cafeteria with trays beyond." + the style line.
3. **floor-school-classrooms.png** - "A two-storey school library with a balcony and a spiral of bookshelves, next to a classroom with rows of small desks and a chalkboard, a science lab with beakers." + the style line.
4. **floor-school-clocktower.png** - "Inside a school clock tower: the back of a giant clock face, big gears and a brass bell, an exam hall of desks below, a telescope by a round window." + the style line.

## "Top of the Class" badge

Picture: `art/roblox-store/badges/badge-school.png` (made with
`python tools/make_badge.py art/roblox-store/maps/floor-school-clocktower.png
art/roblox-store/badges/badge-school.png 235,120,55 520 0 941`: the Clock
Tower card's bell, gears and exam hall in a brick-orange ring, like the
other badges). Name: **Top of the Class**. Description: **Escaped the
Midnight School's Clock Tower.** The id goes into `Config.BADGES.school`.

## The school's host: the Caretaker

A tall, thin night caretaker who never went home - friendly-spooky, not
gory. Model name in Studio: **HostCaretaker** (Party House ServerStorage ->
Characters). Picture: `art/model-input/host-caretaker/a-pose-front.png`.

Prompt (no reference picture; Meshy settings as for the other hosts, A-Pose):
> A tall, thin, ghostly school caretaker for a kids' spooky game. Pale mint-grey skin with a soft glow, big round glowing yellow eyes, a long nose, a big bushy white moustache, short tufty white hair, a small grey flat cap sitting high on the back of his head (not over his forehead). A short buttoned dusty-green work jacket that ends at the hips, rolled-up sleeves, dark green work trousers, chunky black boots, a wide brown belt with a big ring of old brass keys hanging at one hip and a feather duster tucked in it, a short mop strapped across his back with the mop head sticking up behind one shoulder. Long thin arms with a clear gap of air between each arm and the body, nothing hanging from the arms. Spooky but friendly, a little grumpy. Stylised 3D animated-film look, full body, standing in an A-pose facing the camera, plain light grey background, soft even lighting, no text, no logos.

Kept away from known characters on purpose: no cat, no long stringy hair,
no patched brown coat (a famous film-school caretaker has all three).

His power, **Lock-up** (Brent picked it 8 Oct; built): when he can see a
kid, he padlocks a plain doorway within 3 tiles of them on the far side
(away from him) - iron bars, crossed chains, a brass padlock - for 6 s.
Never a locked door, the exit or the host's door, never on top of anyone.
He walks through it himself (collision groups); Tinker picks it at once
(F / Y). Cooldown 30 / 22 / 18 / 14 s by difficulty
(`Config.HOST_SKILLS.lockup`). He is the School's own host
(`Config.BUILDING_HOST.school = "caretaker"`) and visits the other
buildings like the others do. Until his model is imported he is the
built host in green.

## Decisions

- **The school's own host** (Brent: yes, 8 Oct): the Caretaker above.
- **"All floors" badge.** It still means the original 9 floors (its badge
  says 9); the School and the Basement are extra. A new badge "Top of the
  Class" for the School's Clock Tower: make it in Creator Hub (Badges) and
  send me the id (`Config.BADGES.school`).
