# Art prompts - The Party at the End of the Lane

How this works: Brent runs a prompt in an image tool and saves the file into
`art/` with the exact filename given. Claude sizes it, wires it in, renders the
screen and looks at it before it ships. Until a file arrives, the game uses
the code-drawn version, so nothing waits on art.

**The repo is public.** Before saving any image, check it does not look like a
character from a film, cartoon, anime or game (no Jack Skellington, no
Pumpkinhead, no Five Nights at Freddy's, no Roblox characters). If it does,
regenerate.

## Style - paste this at the start of every prompt

> Children's game illustration, ages 6 and up. Spooky-cute, not gory: no
> blood, no wounds, no weapons. Bold clean shapes, thick soft outlines, flat
> colour with gentle shading, like a modern picture book. Night palette: deep
> purple #1a1026, pumpkin orange #ff8a1f, slime green #7be36b, warm candle
> yellow #ffd23f. No text, no letters, no logos, no watermark.

## What the room grid needs

The rooms themselves (floor, walls, table, objects) stay **drawn in code**,
because every object sits on an exact tile the rules use. AI art is used where
a picture does not have to line up with the tiles:

| File | Used for | Size | Background |
|---|---|---|---|
| `art/host.png` | The creature: toasts, the jumpscare, the title | 1024 x 1536 | transparent |
| `art/host-face.png` | Spooky-mode jumpscare close-up | 1536 x 1024 | solid black |
| `art/title.png` | Title screen | 1536 x 1024 | full scene |
| `art/story.png` | The story card before room 1 | 1536 x 1024 | full scene |
| `art/hall-wall.png` | A repeating wallpaper strip for the Front Hall walls | 512 x 512 | tileable |

## Prompts (after the style line)

### `art/host.png` - the party host
> Full-body character, standing, facing the viewer, on a transparent
> background. A very tall, thin party host in a dark purple tailcoat and a
> purple bow tie, long arms, white gloves. His head is a carved pumpkin mask
> that is melting slightly - drips of orange running down from the chin. Two
> triangle eyes and a jagged grin glow candle-yellow from inside. A small
> striped green party hat sits tilted on top of the pumpkin. Creepy but
> funny: his pose is a little too eager, like he really wants you to stay for
> cake.

### `art/host-face.png` - jumpscare close-up
> Extreme close-up of the same melting pumpkin-mask party host leaning toward
> the viewer out of total darkness. Only the pumpkin face is lit, from inside:
> glowing triangle eyes and a jagged grin, orange drips. Tilted party hat. Pure
> black background. Startling, not gory.

### `art/title.png` - title screen
> A tall, crooked house at the end of a dark country lane at night. Party
> balloons tied to the gate, warm yellow light and bunting in the windows, a
> crescent moon. In one upstairs window, a tall silhouette with a pumpkin head
> and a party hat is watching. A small group of cartoon kids with torches
> walks up the lane toward the gate. Leave the top third mostly sky for the
> game's title.

### `art/story.png` - story card
> A cheerful-looking front door with a "party" balloon arch, seen from the
> doorstep at night. The door has just swung shut behind the viewer and a
> brass lock is clicking. Inside, through a glass panel, a long table with a
> birthday cake and no guests. Eerie, quiet, a little funny.

### `art/hall-wall.png` - wallpaper tile
> Seamless tileable wallpaper pattern, square. Faded Victorian party
> wallpaper: thin vertical stripes in dark purple and plum with small orange
> balloons and tiny pumpkins. Slightly peeling. Must tile with no visible
> seam.

## After saving

Tell Claude which files are in `art/`. Claude checks each one for resemblance
to known characters, sizes them, wires them in, renders the screen and looks
at it, then deploys. Art is cached separately from the game code, so tablets
download each image once.
