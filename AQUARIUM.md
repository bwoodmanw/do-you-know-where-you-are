# Sunken Aquarium - building 6 (built 8 Oct)

Three floors, unlocked like the others: escaping the Carnival's Big Top
opens the Main Hall; each floor escaped opens the next. Tower Run works
here too. Plans in `tools/make_housemap.py` (plan_mainhall, plan_deepsea,
plan_rooftop, each with a mirror), each checked with 2,000 random fills.
They are built on the Carnival's room grids (so the store rooms and the
checks fit) with their own rooms, furniture and look; the Main Hall has its
own glass Shark Tunnel. Studio Play builds it now (`Config.STUDIO_MAP = "aquarium"`).

| Floor | Start | Behind the 1st lock | Way out (behind the 2nd) | Other rooms |
|---|---|---|---|---|
| 1 Main Hall | Entrance Hall | Keeper's Office | Front Doors | Great Tank Hall (a round tank with a shark circling), Shark Tunnel (a winding tunnel of glass and water), Touch Pools, Jellyfish Room, Cafe, Seahorse Room, Gift Shop |
| 2 Deep Sea | Deep Sea Lift | Submarine Bay | Pump Stairs ("Up to the Rooftop Pools") | Whale Skeleton Hall (two storeys, a balcony), Kelp Forest, Anglerfish Den and Coral Cave (these three start dark), Bubble Vents (3 bubble jets bounce you up), Pipe Room (the water pipe), Research Lab, Diving Locker (a little yellow submarine) |
| 3 Rooftop Pools | Sea Lion Stadium | Pump Room (a whirlpool floor that turns) | Water Slide ("Down the water slide!") | Penguin Ice, Otter Pool and Rock Pool (wading is slow), Splash Slide (the twisty slide), Feed Store, Lighthouse Deck, Snack Kiosk |

What plays differently:
- **Glass and water:** the Shark Tunnel's walls are see-through water with fish; tanks everywhere.
- **Dark Deep Sea:** three rooms start dark - the host sees less far there; Glow lights up, or use the light switch.
- **Wading:** shallow pools (Touch Pools, Otter Pool, Rock Pool, Sea Lion Stadium) slow everyone, the host too.
- **Bubble jets** bounce you up (Deep Sea); **the water pipe** (Deep Sea) and **the splash slide** (Rooftop) carry you to a far room - the host can't follow.
- **The whirlpool** (Pump Room) turns you round if you stand on it.

## The host: the Anglerfish Keeper

Model `HostAnglerfish` (saved id 100510711229549), with the game's glowing
lure on his head. He is the Aquarium's own host and visits the other
buildings like the others.

**Fake Treasure** (`Config.HOST_SKILLS.fakegift`): while he patrols (not
while chasing) he leaves a present every 35 / 25 / 20 / 15 s (Easy ->
Nightmare); at most 3 at once, each lasts 60 s, never by a doorway. It looks
exactly like a real present. Open it and it was a trick: you glow for 3 s
and he comes to look. **Brainy and Glow** see "Pop it - it's a fake!" (F / Y)
and pop it safely.

## Pictures for the Lobby map screen (done 8 Oct)

In `Config.MAP_IMAGES`: building-aquarium 112735362765924, Main Hall
91974787928356, Deep Sea 75069384210834, Rooftop Pools 111966719661004.

Style line for every prompt:
> Stylised 3D diorama, a cut-away room seen from above at an angle, at night, warm lamps and Halloween string lights in orange and purple, little paper bats, a friendly-spooky mood for kids, no people, no text, no logos.

1. **building-aquarium.png** - "An old seaside aquarium building at night on a rocky harbour: a big glass dome glowing blue, rooftop pools, a little lighthouse, a twisting water slide down the side, jack-o'-lanterns on the steps, waves and a full moon." + the style line (the outside, not a cut-away).
2. **floor-aquarium-mainhall.png** - "An aquarium's main hall: a giant round fish tank with a shark circling, a winding glass tunnel full of fish, a touch pool with starfish, glowing jellyfish tanks, a ticket desk." + the style line.
3. **floor-aquarium-deepsea.png** - "A dark deep-sea aquarium gallery: a huge whale skeleton hanging from the ceiling with a balcony around it, a kelp forest, glowing coral, a small yellow submarine, bubble jets, big brass pipes." + the style line.
4. **floor-aquarium-rooftop.png** - "Aquarium rooftop pools: a sea lion show pool with stands, a penguin ice area with little penguins, an otter pool, a twisting water slide, a small lighthouse, a whirlpool." + the style line.

## Badge

**Making a Splash** - "Escaped the Aquarium's Rooftop Pools." (`Config.BADGES.aquarium`).
Picture: `art/roblox-store/badges/badge-aquarium.png` (made from the Rooftop card).
