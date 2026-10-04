# Art prompts - sheets for ChatGPT's image maker

**Audience is now 8+** (decided 4 Oct 2026), and the look is **realistic,
stylised 3D** - the level of detail kids know from online hide-and-seek and
murder-mystery games - not the simple blobs drawn in code today.

## How to use these

1. Open ChatGPT, choose image creation.
2. Paste the **style block** below, then the prompt for one sheet.
3. Use the size given (ChatGPT offers square 1024 x 1024, wide 1536 x 1024,
   tall 1024 x 1536).
4. If the first result is close but not right, reply in the same chat with
   what to change ("make the goggles brass", "same character, but the back
   view") - it keeps the character more consistent than starting again.
5. Save each image into `art/sheets/` with the exact filename given, and tell
   Claude which ones are there.

**The repo is public, so the site is public.** Reject and regenerate anything
that looks like a character from a film, show, toy, or game - including
Roblox avatars, Minecraft, Among Us, Five Nights at Freddy's, Pokemon, Jack
Skellington, or branded sweets. No logos, no brand names, no text in the
image.

**What each sheet is for** (Brent's decision, 4 Oct 2026):

| Sheet | Used how |
|---|---|
| Characters, customisation parts | **Design guide.** Claude redraws them in the game to match, so every part fits every character and works offline. |
| Hosts, jumpscares | **Go in directly** - the jumpscare, the host's portrait, the title screen. |
| Rooms | **Go in directly** as the room's arrival card, loading and safe-area screens, and they set the look of the playable room. |
| Textures | **Go in directly** onto the floors and walls of the playable rooms. |

## Style block - paste first, every time

> Stylised 3D game render, like a polished modern online kids' horror-escape
> game (hide-and-seek / murder-mystery style), for ages 8 and up. Realistic
> lighting and soft shadows, detailed materials (fabric, wood, plastic,
> metal), slightly chunky, appealing proportions. Creepy and tense but never
> gory: no blood, wounds, weapons or body horror. Not blocky toy avatars. No
> text, letters, logos, brand names or watermark.

## 1. Character turnaround sheets (8)

Size: **1536 x 1024**. Filename: `art/sheets/char-<name>.png`.

> Character turnaround sheet of ONE child character, about 10 years old, full
> body, on a plain light grey background. Top row, four views, same size and
> pose height: front, three-quarter front, side, back. Bottom row, four
> poses: running, hiding (crouched, peeking), scared (jumping back), cheering.
> Same outfit and colours in all eight. [CHARACTER]

| Name | [CHARACTER] |
|---|---|
| Tinker | An inventive kid in blue dungarees over an orange T-shirt, brass-rimmed workshop goggles pushed up on a blue cap worn slightly sideways, a tool belt with a small spanner and screwdriver, scuffed trainers. Curious, quick grin. |
| Shadow | A quiet, sly kid in a dark purple hoodie with the hood up, a black cloth mask over the lower face, dark joggers and soft black sneakers, purple fingerless gloves. Moves like a cat. |
| Brainy | A clever kid in a white lab coat over a sky-blue jumper, big round black glasses, a red beanie with a little blue propeller, a notebook and pencil behind the ear. Excitable. |
| Muscle | A strong, kind kid in a red sports jersey with no team name, charcoal shorts, a yellow sweatband, high-top trainers, rolled-up sleeves. Confident. |
| Glow | A gentle kid in a lime-green glow-in-the-dark raincoat, a headband with a curly antenna and a glowing bulb, a head torch around the neck, green wellies. Bright eyes. |
| Patch | A caring kid in a pink medic-style vest over a white top, a sticking plaster on the forehead, a small first-aid satchel with a heart (no red cross), comfy trainers. |
| Echo | A watchful kid in a yellow bomber jacket and purple trousers, big dark headphones around the neck, round goggles, a little handheld sound gadget. |
| Bramble | An outdoorsy kid in a leaf-green poncho and brown cargo shorts, a crown of real leaves and one small flower in the hair, muddy boots, a pouch of seeds. Calm. |

## 2. Host sheets - one per theme, plus a jumpscare each

Turnaround: **1536 x 1024**, `art/sheets/host-<theme>.png`:

> Creature turnaround sheet on a plain light grey background. Top row: front,
> three-quarter, side, back. Bottom row: wandering, hunting (lunging, arms
> reaching), stunned, a funny moment. The creature is about twice the height of
> a 10-year-old. [HOST]

Jumpscare: **1536 x 1024**, `art/sheets/host-<theme>-scare.png`:

> Extreme close-up of [HOST NAME] lunging out of total darkness toward the
> viewer, only the face and hands lit from below, dramatic. Startling, not gory.

| Theme | [HOST] |
|---|---|
| `party` (Halloween, now) | **The Party Host.** Very tall and thin, in a worn dark purple tailcoat, bow tie and white gloves, long arms. His head is a carved pumpkin mask that is melting - glossy orange drips at the chin - with triangle eyes and a jagged grin glowing candle-yellow (red when hunting). A crooked striped party hat. Funny moment: his mask has slipped sideways and he is pushing it back. |
| `gummy` (next) | **The Jelly Ringmaster.** A towering, translucent raspberry-gummy figure with light passing through it, a tiny top hat, a sparkly cane, a wide grin of sugar-crystal teeth. Wobbles and bounces, leaves a glossy sticky trail. Funny moment: stuck to the floor by his own goo. |
| `hospital` (later) | **The Night Shift.** A tall, creaking robot built from an old drip stand on squeaky wheels, a flickering examination lamp for a head, long jointed arms holding a clipboard and a thermometer. Wants to "take your temperature". No needles, no blood. Funny moment: its lamp pops and it rolls into a trolley. |

## 3. Room pictures

Size: **1536 x 1024**. Filename: `art/sheets/room-<theme>-<room>.png`.

> Isometric three-quarter view from above of one room in a game level, like a
> diorama with the near walls cut away so you can see in. Realistic lighting
> and materials. No people or creatures. [ROOM] Lighting: [LIGHT].

### Party House (Halloween) - in the game now

| Filename | [ROOM] | [LIGHT] |
|---|---|---|
| `room-party-parlour.png` | A Victorian parlour: plum carpet, tall dark wardrobe, squashy purple sofa, fireplace with a carved pumpkin, a framed party invitation on the back wall, one white balloon with a number 2 on it. | candlelight, cosy but wrong |
| `room-party-corridor.png` | A long wooden corridor ending in a huge front door with a four-colour keypad, old portraits on the walls, a blue wrapped present on the floor. | cold moonlight through a fanlight |
| `room-party-library.png` | Two long rows of bookshelves, green carpet, a curtained reading nook, a large leafy potted plant in the corner, faint glow-paint scribbles on the back wall. | one green banker's lamp |
| `room-party-kitchen.png` | Black-and-white tiled floor, a long counter of party food, a pantry cupboard, a small dark door in the side wall with two red eyes inside, a white balloon numbered 1, a red present. | the glow of an open fridge |
| `room-party-hall.png` | The front hall: wooden floor, a long party table with a white cloth, orange scalloped trim and a birthday cake, a metal cage with a cushion in the corner, a red velvet curtain. | flickering chandelier |
| `room-party-gameroom.png` | Purple carpet, a big wooden cabinet against the side wall, a large cardboard box, a white balloon numbered 3, board games, a ball pit, a disco ball. | disco-ball sparkles in the dark |
| `room-party-garden.png` | The safe area: the back garden at night with fairy lights and a gate; warm light; a welcoming bench. | warm and safe |

### Gummy Bounce House (next theme)

| Filename | [ROOM] |
|---|---|
| `room-gummy-lobby.png` | A bouncy-castle lobby made of jelly, candy-stripe walls, giant gummy statues (not any brand). |
| `room-gummy-pit.png` | A giant pit of gumdrops with hiding gaps underneath. |
| `room-gummy-slide.png` | A rainbow sprinkle slide tower with platforms and glowing sparkle-power pads. |
| `room-gummy-vault.png` | A caramel vault with a wobbling jelly door and colour switches. |
| `room-gummy-safe.png` | Safe area: a floating cloud of candyfloss above the castle. |

### Abandoned Hospital (later theme)

| Filename | [ROOM] |
|---|---|
| `room-hospital-waiting.png` | A dusty waiting room: tipped chairs, a reception desk with a bell, a fish tank with one cheerful fish. |
| `room-hospital-ward.png` | A ward of empty beds with curtains to hide behind, wheeled trolleys. |
| `room-hospital-xray.png` | An X-ray room with a glowing lightbox showing a cartoon skeleton dancing. |
| `room-hospital-pharmacy.png` | Tall shelves of coloured bottles (no pills or needles), a locked hatch. |
| `room-hospital-boiler.png` | A basement boiler room: pipes, steam, a big red lever. |
| `room-hospital-safe.png` | Safe area: an ambulance bay at dawn, a waiting family car. |

## 4. Textures for the playable rooms

Size: **1024 x 1024**. Filename: `art/sheets/tex-<name>.png`.

> Seamless tileable texture, viewed straight from above, evenly lit, no
> shadows, no objects: [SURFACE]. It must tile with no visible seam.

| Filename | [SURFACE] |
|---|---|
| `tex-wood.png` | old honey-coloured wooden floorboards |
| `tex-darkwood.png` | dark worn wooden corridor boards |
| `tex-carpet-plum.png` | faded plum Victorian carpet with a subtle pattern |
| `tex-carpet-green.png` | worn green library carpet |
| `tex-carpet-purple.png` | purple games-room carpet with a faint star pattern |
| `tex-tiles.png` | black-and-white checker kitchen tiles, slightly grimy |
| `tex-wallpaper.png` | peeling Victorian party wallpaper, dark purple stripes with small orange balloons |

## 5. Customisation sheets (9) - design guides

Size: **1024 x 1024**. Filename: `art/sheets/parts-<kind>.png`.

> Character-creator sheet: a 4 x 4 grid of sixteen equal squares on a plain
> light grey background. In every square the SAME plain 10-year-old
> mannequin-style character (grey T-shirt, grey shorts, neutral face), same
> pose, same size, same position - only the [PART] changes. Each square shows
> a different [PART]: [LIST].

| Filename | [PART] | [LIST] |
|---|---|---|
| `parts-eyes.png` | eyes | round, sleepy, starry, wink, narrow and sly, huge and sparkly, cat-like, glowing, worried, determined, tired with bags, one eyebrow raised, laughing shut, wide with fright, heterochromia, freckled under-eye |
| `parts-eyebrows.png` | eyebrows | none, thin, bushy, angry, worried, raised, unibrow, zigzag, thick straight, curly, pierced-look (no metal), scar notch, arched, flat, tiny, sparkly |
| `parts-mouths.png` | mouth | smile, big toothy grin, O, tongue out, gap tooth, braces, cheeky smirk, nervous, laughing, whistling, frown, determined line, cat mouth, buck teeth, lollipop in mouth, face mask |
| `parts-noses.png` | nose | small button, round, pointed, freckled, wide, upturned, long, sunburnt, plaster on nose, clown red, whiskers drawn on, narrow, hooked, tiny, star sticker, snub |
| `parts-hair.png` | hair or headwear | short spiky, curly afro, two puffs, long braids, bob, mohawk, beanie, baseball cap, bucket hat, wizard hat, bunny ears, cat ears, bandana, top hat, flower crown, hood up |
| `parts-tops.png` | top | striped tee, hoodie, dungarees, lab coat, superhero cape, raincoat, Halloween-pumpkin jumper, tank top, plain sports jersey, pyjamas, ninja wrap, sequin jacket, denim jacket, puffer coat, knitted cardigan, explorer shirt |
| `parts-bottoms.png` | bottoms | shorts, skirt, tutu, jeans, joggers, cargo shorts, leggings, dungaree legs, kilt-style skirt, pyjama bottoms, swim shorts, ripped jeans, snow trousers, karate trousers, tracksuit, overall shorts |
| `parts-shoes.png` | shoes | trainers, wellies, slippers, roller skates, flippers, cowboy boots, ballet shoes, rocket boots, flip-flops, hiking boots, light-up trainers, socks only, clogs, football boots (no logos), sandals, bunny slippers |
| `parts-extras.png` | accessory | backpack, scarf, cape, small wings, tail, round glasses, eyepatch, medal, bow tie, necklace, wand, umbrella, balloon on a string, pet mouse on the shoulder, torch, skateboard |

## After saving

Tell Claude which files are in `art/sheets/`. Claude checks each one for
resemblance to known characters or brands, looks at it, and then either wires
it in (hosts, scares, rooms, textures) or redraws the game's characters and
parts to match (characters, parts) - the character creator screen gets built
once the parts sheets are in.
