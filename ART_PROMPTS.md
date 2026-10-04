# Art prompts - sheets for development

**How this works.** Brent runs a prompt in an image tool and saves the result
into `art/sheets/` with the filename given. Claude checks it, looks at it, and
uses it. Until a sheet arrives, the game keeps its code-drawn art, so nothing
waits.

**Give the image tool the reference sheets too.** `art/reference/` holds the
code-drawn versions of what is in the game today - attach the matching one to
each prompt ("match this style and these characters") so the AI sheets look
like the same game:

| Reference | Shows |
|---|---|
| `art/reference/characters.png` | All 8 characters (5 starters + 3 unlockables), standing / walking / scared |
| `art/reference/host-party.png` | The Halloween party host: wandering, hunting, stunned |
| `art/reference/parts-today.png` | The eyes, headwear and body colours the game can draw today |

**The repo is public.** Before saving, check nothing looks like a character
from a film, cartoon, anime, game or toy brand (no Roblox, Minecraft, Among Us,
Five Nights at Freddy's, Pokemon, Jack Skellington, Haribo bears). If it does,
regenerate.

## How the sheets get used (decision 1 in chat)

AI image tools do not keep parts exactly the same size and position from one
picture to the next, and a 2.5D game needs every part to line up on every
character. So:

- **Character, host and parts sheets are design references.** Claude redraws
  each part in code to match them. Customisation stays endless, tiny and
  offline, and every part fits every body.
- **Room sheets and hosts can also be used directly** as backdrops, jumpscare
  pictures and title art, because nothing has to line up with a tile.

## Style line - paste at the start of every prompt

> Children's game art for ages 6 and up. Spooky-cute, never gory: no blood,
> wounds or weapons. Round, chunky, soft shapes; thick soft outlines; flat
> colour with gentle shading, like a modern picture book or a friendly mobile
> game. Characters are small rounded blob-bodies with big expressive eyes,
> stubby feet and no arms, as in the attached reference. No text, letters,
> logos or watermark. Plain light background unless the prompt says otherwise.

## 1. Character sheets - one per character

Filename: `art/sheets/char-<name>.png`, e.g. `char-tinker.png`. 2048 x 1024.

> Character turnaround sheet for one character, in a 4 x 2 grid of equal
> squares, same size and scale in every square: front, three-quarter front,
> side, back; then happy, scared (mouth an O), sneaking (crouched, eyes
> narrow), cheering. [CHARACTER DESCRIPTION]

| Name | Description to paste |
|---|---|
| Tinker | An orange blob with a blue lower half like overalls, round brown-rimmed goggles over big eyes, a blue cap worn slightly sideways with a yellow button. A little spanner tucked in a pocket. Cheerful and curious. |
| Shadow | A lavender-purple blob with a dark purple lower half, a black ninja-style mask band across the eyes with tails that flutter, sleepy half-closed eyes. Quiet and sly. |
| Brainy | A sky-blue blob with a white lower half like a lab coat, big round black glasses, a red beanie with a blue propeller on top. Clever and excitable. |
| Muscle | A red blob with a charcoal lower half, a yellow sweatband with tails, determined eyebrows, a confident grin. Strong and kind. |
| Glow | A lime-green blob with a dark green lower half, huge shiny eyes, a curly antenna on top with a glowing yellow bulb. Gentle and bright. |
| Patch (unlock) | A pink blob with a white lower half, big friendly eyes, a sticking plaster on the forehead, a little first-aid bag (no cross symbol). Caring and fast. |
| Echo (unlock) | A yellow blob with a purple lower half, round goggles, big dark headphones over the top. Always listening. |
| Bramble (unlock) | A leafy-green blob with a brown lower half like bark, sleepy eyes, a crown of green leaves growing from the head, a tiny flower. Calm, talks to plants. |

## 2. Host sheets - one per theme

Filename: `art/sheets/host-<theme>.png`. 2048 x 1024, light background, 4 x 2
grid: front, three-quarter, side, back; wandering, hunting (reaching), stunned,
silly moment.

| Theme | Host description to paste |
|---|---|
| Party (Halloween) | A very tall, thin party host in a dark purple tailcoat and bow tie, long thin arms, white gloves. His head is a carved pumpkin mask, melting a little - orange drips. Triangle eyes and a jagged grin glow candle-yellow (red when hunting). A tilted striped green party hat. Creepy but funny: too eager for you to stay for cake. Silly moment: the mask has slipped and he is trying to push it back up. |
| Gummy Bounce House | A giant wobbly jelly ringmaster made of translucent raspberry gummy, a tiny top hat, a sparkly cane, a wide grin of sugar-crystal teeth. Bounces instead of walking; leaves a sticky trail. Silly moment: stuck to the floor by his own goo. |
| Abandoned Hospital | A tall, rattling night-shift robot: a lamp for a head that flickers, a body like an old drip stand on squeaky wheels, long bendy arms holding a clipboard. Wants to "take your temperature". No blood, no needles shown. Silly moment: the lamp head blows a bulb and it bumps into a trolley. |

Add a jumpscare picture per host too: `art/sheets/host-<theme>-scare.png`,
1536 x 1024, black background:

> Extreme close-up of [host] lunging toward the viewer out of total darkness,
> only the face lit. Startling, not gory.

## 3. Room sheets - one per room

Filename: `art/sheets/room-<theme>-<room>.png`. 1536 x 1024.

> Isometric game room, seen from above at an angle like a cosy tablet game,
> the floor a diamond grid, low walls on the near sides so you can see in, tall
> walls at the back. [ROOM DESCRIPTION] Plenty of floor space to walk around.
> Lighting: [LIGHT]. No characters in the room.

### The Party House (Halloween) - built in the game now

| File | Room description | Light |
|---|---|---|
| `room-party-parlour.png` | A Victorian parlour: plum carpet, a tall wardrobe, a squashy purple sofa, a framed party invitation on the back wall, a numbered party balloon, a fireplace with a carved pumpkin. | candle-yellow, cosy-creepy |
| `room-party-corridor.png` | A long wooden-floored corridor leading to a huge front door with a coloured keypad; a blue wrapped present on the floor; portraits whose eyes follow you. | moonlight through a fanlight |
| `room-party-library.png` | A library: green carpet, two long rows of bookshelves, a curtained reading nook, faint glow-paint squiggles on the back wall. | dark, one green lamp |
| `room-party-kitchen.png` | A kitchen: black-and-white checker floor, a long counter with party food, a pantry cupboard, a dark creature-door in the side wall with two red eyes, a numbered balloon, a red present. | fridge glow |
| `room-party-hall.png` | The front hall: wooden floor, a long party table with a white cloth, orange scalloped edge and a birthday cake, a cage in the corner with a cushion inside, a red curtain. | chandelier, flickering |
| `room-party-gameroom.png` | A games room: purple carpet, a big wooden cabinet against the side wall hiding a hole, a cardboard box, a numbered balloon, board games and a ball pit. | disco-ball sparkles |
| `room-party-garden.png` | The safe area: the back garden at night, fairy lights, parents waving by a gate, a cheerful glow. | warm and safe |

### Gummy Bounce House (next theme)

| File | Room description |
|---|---|
| `room-gummy-lobby.png` | A bouncy-castle lobby made of jelly, gummy-bear-shaped (not branded) statues, candy-stripe walls. |
| `room-gummy-pit.png` | A giant ball pit of gumdrops with hiding spots under the balls. |
| `room-gummy-slide.png` | A rainbow sprinkle slide tower with platforms and sparkle-power pads. |
| `room-gummy-vault.png` | A sticky caramel vault with a wobbling jelly door and colour switches. |
| `room-gummy-safe.png` | Safe area: a cloud of candyfloss above the castle. |

### Abandoned Hospital (later theme)

| File | Room description |
|---|---|
| `room-hospital-waiting.png` | A dusty waiting room: tipped chairs, a fish tank with one cheerful fish, a reception desk with a bell. |
| `room-hospital-ward.png` | A ward of empty beds with curtains to hide behind, wheeled trolleys. |
| `room-hospital-xray.png` | An X-ray room with a glowing lightbox showing a silly skeleton doing a dance. |
| `room-hospital-pharmacy.png` | A pharmacy with tall shelves of coloured bottles (no pills or needles shown) and a locked hatch. |
| `room-hospital-boiler.png` | A basement boiler room, pipes, steam, a big red lever. |
| `room-hospital-safe.png` | Safe area: an ambulance bay at dawn, parents waiting. |

## 4. Customisation part sheets

Filename: `art/sheets/parts-<kind>.png`. 2048 x 2048, a 4 x 4 grid of equal
squares, one item per square, all drawn **on the same plain lavender blob
body** (from `parts-today.png`), same size, same position, facing front, light
background.

> Customisation sheet for a character creator: sixteen variations of
> [PART], each in its own square on the same plain lavender blob character,
> identical body size and position in every square, only the [PART] changes.

| File | [PART] - ask for variety like this |
|---|---|
| `parts-eyes.png` | eyes: round, sleepy, starry, heart, wink, tiny dots, huge sparkly, cat, robot screen, spiral, googly, lashes, half-moon, cross-eyed silly, glowing, one big one small |
| `parts-eyebrows.png` | eyebrows: none, thin, bushy, angry, worried, raised, unibrow, zigzag, dots, thick straight, curly, sparkles |
| `parts-mouths.png` | mouths: smile, big grin with teeth, O, tongue out, toothy gap, fangs (cute), wobbly, cat mouth, whistle, laugh, smirk, braces |
| `parts-noses.png` | noses: none, button, round red, triangle, pig snout, freckles, whiskers, star, long, heart |
| `parts-hair.png` | hair and hats: spiky, curly afro, pigtails, bob, mohawk, beanie, cap, wizard hat, crown, bunny ears, cat ears, bandana, top hat, bow, flower, leaves |
| `parts-tops.png` | shirts on the lower half of the body: striped tee, hoodie, dungarees, lab coat, superhero cape, raincoat, jumper with a pumpkin, tank top, sports jersey (no team names), pyjamas, ninja wrap, sequins |
| `parts-bottoms.png` | bottoms visible above the feet: shorts, skirt, tutu, jeans, swim shorts, kilt-style skirt, leggings, cargo shorts |
| `parts-shoes.png` | feet and shoes: trainers, wellies, slippers, roller skates, flippers, cowboy boots, ballet shoes, rocket boots |
| `parts-extras.png` | extras: backpack, scarf, cape, wings, tail, glasses, eyepatch (pirate), medal, bow tie, necklace, wand, umbrella, balloon on a string, pet mouse, torch, lollipop |

## After saving

Tell Claude which files are in `art/sheets/`. Claude checks each for
resemblance to known characters, looks at it, and either redraws the parts in
code to match (characters, parts) or wires the picture in (rooms, scares,
title).
