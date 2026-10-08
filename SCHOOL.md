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

## Pictures for the Lobby map screen (Brent)

The map cards show a plain colour until these exist. Make each at 16:9
(like the others, e.g. 1536 x 864), save to `art/roblox-store/maps/`, upload
in Studio (Lobby place: View -> Asset Manager -> Import, or Creator Hub ->
Development Items -> Decals) and send me the 4 image ids.

Style line for every prompt (the other cards' look):
> Stylised 3D diorama, a cut-away room seen from above at an angle, at night, warm lamps and Halloween string lights in orange and purple, little paper bats, a friendly-spooky mood for kids, no people, no text, no logos.

1. **building-school.png** - "An old red-brick school at night with a tall clock tower, the clock face glowing, arched windows lit warmly, a playground with a hopscotch grid and a swing in front, jack-o'-lanterns on the steps." + the style line (this one is the outside, not a cut-away).
2. **floor-school-ground.png** - "A school's main corridor lined with blue lockers, a trophy cabinet, an assembly hall with rows of chairs and a small stage through an open door, a cafeteria with trays beyond." + the style line.
3. **floor-school-classrooms.png** - "A two-storey school library with a balcony and a spiral of bookshelves, next to a classroom with rows of small desks and a chalkboard, a science lab with beakers." + the style line.
4. **floor-school-clocktower.png** - "Inside a school clock tower: the back of a giant clock face, big gears and a brass bell, an exam hall of desks below, a telescope by a round window." + the style line.

## Decisions

- **The school's own host.** For now the School uses the Pumpkin Host half
  the time (and the Gummy Bear Man or the Robot the other half). A school
  host (say a ghostly caretaker with a mop and a jangle of keys) would need
  a picture, a Meshy model and an import like the other hosts.
- **"All floors" badge.** It still means the original 9 floors (its badge
  says 9); the School and the Basement are extra. A new badge "Top of the
  Class" for the School's Clock Tower: make it in Creator Hub (Badges) and
  send me the id (`Config.BADGES.school`).
