# The look upgrade (9 Oct): posters and a cartoon-style character test

Brent's picks: 1 lighting (built), 4 the Lobby screen (picture first,
`art/ui-mockups/lobby-v2.png`), then 2 posters and 3 a character test.
Ideas taken from how clean games like Dandy's World look - the *principles*
(flat colors, simple shapes, 2D art on walls), never their characters, icons
or layout. Everything players see must have no logos and no known characters.

---

## Part C - our own pictures for the Lobby tiles

The new Lobby (built 9 Oct) shows an emoji on each tile until its own
picture is in - the same idea as the Candy Corn boost picture. One sheet
makes all twelve.

### 1. The sheet (ChatGPT, landscape)

> A sheet of 12 separate game button icons for a spooky-cute kids' game, in a
> 4 x 3 grid with wide empty gaps, each icon centred in its own equal square
> cell. Same style for all: glossy cartoon, chunky simple shapes, bright
> candy colors with purple and orange accents, a thick dark outline, a soft
> highlight, no circle or frame behind them. Transparent background. No text,
> no letters, no logos, no famous characters. In this order, left to right,
> top to bottom:
> 1 a lightning bolt with speed lines, 2 a single flashlight shining a beam,
> 3 a bunch of three balloons, 4 a cheerful cartoon kid's face with round
> glasses and a propeller beanie, 5 a striped shopping bag full of candy,
> 6 a rolled scroll with a gold check-mark seal, 7 a teddy bear plushie with a
> stitched heart, 8 an envelope with a heart seal, 9 an open door glowing
> with warm light and party streamers, 10 a waving cartoon hand, 11 an
> instant camera with a flash spark, 12 a big purple question mark with
> sparkles.

Save it as `art/ui-icons/sheet.png` and **send it to Claude**: Claude checks
it, then cuts it (`python tools/cut_icon_sheet.py art/ui-icons/sheet.png`)
into `art/ui-icons/quick.png`, `solo.png`, ... `help.png`.

### 2. Uploading

Same as the posters below: Creator Hub -> Development Items -> Images ->
Upload Asset, one per icon (name them "Icon quick", "Icon solo", ...), copy
each **Asset ID**, send Claude the twelve ids. They go in
`Config.UI_ICONS` and the tiles switch from emoji to pictures by themselves.

---

## Part A - posters for the walls (step 2)

Flat 2D pictures are where AI art looks best. Twelve posters, two per
building; the game hangs one or two in each room once their ids are in.

### Making each one (ChatGPT, portrait)

Paste this, then the poster's own line from the list below. (The first try,
9 Oct, came out too young - big smiles, blush cheeks, confetti. These aim at
8-12 year olds: mysterious and a bit creepy, like an old spooky adventure
book cover, never gory.)

> An eerie illustrated poster for a spooky adventure game for older kids,
> like a vintage creepy storybook cover: moody night lighting, deep shadows,
> one strong glow, a limited palette of dark purples, teals and burnt orange,
> painterly texture, a sense of mystery and something watching. Faces are
> sly, sinister or hidden - not smiling, not cute, no blush cheeks, no
> chibi, no confetti or party clutter. A worn paper border. Not gory, no
> blood. No text, no letters, no logos, no real brands, no famous
> characters. Portrait 2:3.

| Building | Poster 1 | Poster 2 |
|---|---|---|
| Party House | a tall old party house on a hill at night, one window glowing, the shadow of a pumpkin-headed figure in a top hat behind the curtain | a long dining table set for a party with an untouched cake, every chair empty, one candle still burning |
| Gummy Bounce House | a candy factory at night, its chimneys puffing pink smoke, a giant gummy bear's silhouette in a lit doorway | a jar of gummy bears on a shelf in the dark, one bear pressed against the glass looking out |
| Abandoned Hospital | an empty hospital corridor, a wheelchair alone under one flickering light, a door ajar at the end | an old X-ray of a hand with one finger too many, lit from behind |
| Midnight School | a school clock tower at midnight under a full moon, its hands pointing to twelve, an owl on the ledge | an empty classroom with a single desk lit by moonlight and chalk drawings of eyes on the board |
| Creepy Carnival | a vintage circus poster style picture of a carnival tent at night, a bear in a clown ruff peeking from the dark entrance | a carousel standing still at night, its painted horses' eyes catching the light |
| Sunken Aquarium | an anglerfish's glowing lure in pitch-black water, the shape of its jaws just visible | a diver's helmet on the seabed covered in coral, a faint light inside it |

**Make one first** (the Party House poster 1) and send it to Claude before
the rest - if it is still too young or too scary, we change the prompt once,
not twelve times.

Save each as `art/posters/<building>-1.png` / `-2.png` (for example
`art/posters/gummy-1.png`). **Send Claude the pictures first** - Claude
checks each one (no text, no logos, nothing like a known character) before
anything is uploaded.

### Uploading (the same way as the map cards)

1. Open **create.roblox.com** -> **Creations** -> **Development Items** -> **Images**
   (some versions: **Decals**), then **Upload Asset**.
2. Pick the poster file, name it like the file (for example "Poster gummy-1"),
   click **Upload**.
3. When it is approved, click it and copy the **Asset ID**.
4. Send Claude the 12 ids, saying which is which.

Claude then puts them in `Config.POSTERS` and the rooms hang them.

---

## Part B - one character in a clean cartoon style (step 3)

Our characters come from Meshy, whose textures add fabric grain, shading and
fake shadows - they look blotchy in the game's light. Games that look clean
use **flat colors** (each part of the outfit one solid color) and simple
shapes. Test with **Tinker** first; if he looks better, the rest follow one
at a time (and their skins later).

### 1. A new picture (ChatGPT, portrait)

Attach `art/model-input/tinker/a-pose-front.png` (his current picture) and
paste:

> Use the attached character as the exact reference: the same boy with the
> same face, messy brown hair, brown eyes, backwards blue cap with brass
> goggles on top, orange T-shirt, blue overalls with rolled-up cuffs, a
> brown tool belt with a wrench and a screwdriver, and blue high-top
> sneakers. Redraw him in a clean, simple 3D cartoon toy style: every area
> one smooth flat color, no texture at all - no denim grain, no stitching, no
> dirt, no stains, no scuffs, no freckles, no fabric folds painted on, no
> shading or shadows painted on. Simple rounded shapes, slightly chunky
> proportions, big clear eyes, the goggles and belt buckle as simple solid
> shapes. One full-body image, front view, standing in an A-pose (arms
> angled down and away from the body, legs slightly apart), centred and
> filling the whole height. Plain flat light-grey background, even light.
> No text, no logos, no other characters.

(The current picture shows why we're doing this: the denim grain, dirt,
scuffs and freckles all get painted into the 3D model's texture and turn
blotchy in the game's light.)

Save it as `art/model-input/tinker/front-toon.png` and **send it to Claude
to check** before Meshy.

### 2. Meshy (Image to 3D)

1. **meshy.ai** -> **Image to 3D** -> upload `front-toon.png`.
2. Settings (names move between versions - look under **Advanced**):
   - **Art style / Texture style:** Cartoon (or Stylized) if offered
   - **PBR maps:** **off** (keeps the colors flat - no bumpy shine)
   - **Remove lighting / Delight:** **on** if offered
   - **Polycount / Topology:** the lower option (smoother, simpler shapes)
   - **Pose:** A-pose
3. Generate; pick the cleanest of the results; **Download** as **.glb** into
   `art/models/tinker-toon.glb`. Claude renders it to check before Studio.

### 3. Into Studio, without replacing Tinker

1. Open the **Party House** in Studio.
2. **Avatar** tab -> **Import 3D** -> pick `tinker-toon.glb` -> **Import**.
3. **Avatar** tab -> **Avatar Setup** on the new model (as for the others),
   then rename it **TinkerToon** and drag it into **ServerStorage** ->
   **Characters**.
4. Click **Play** and pick **Tinker**: in Studio only, the game uses
   TinkerToon (`Config.STUDIO_TRY_MODEL`). Live players still get the old
   Tinker.
5. Send Claude photos side by side (walking, standing, close up). If the new
   one wins, Claude switches Tinker over and we do the next character.
