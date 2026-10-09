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

Paste this, then the poster's own line from the list below:

> A cute spooky cartoon poster for a kids' game, flat colors, thick dark
> outlines, simple shapes, bold and readable from far away, soft purple and
> orange night palette, a plain colored border. No text, no letters, no
> logos, no real brands, no famous characters. Portrait 2:3.

| Building | Poster 1 | Poster 2 |
|---|---|---|
| Party House | a jack-o'-lantern wearing a party hat, with balloons and streamers | a friendly ghost blowing out candles on a giant cake |
| Gummy Bounce House | three gummy bears bouncing on a trampoline of cotton candy | a candy machine pouring out lollipops and gumdrops |
| Abandoned Hospital | a smiling skeleton waving from an X-ray screen | a ghost nurse holding a giant bandage and a teddy bear |
| Midnight School | an owl in glasses reading a big book by candlelight | a chalkboard covered in doodles of bats and stars |
| Creepy Carnival | a vintage circus poster of a clown bear juggling pumpkins | a carousel at night with glowing lights and painted horses |
| Sunken Aquarium | a smiling anglerfish with a glowing lure in the deep sea | a parade of glowing jellyfish over a coral reef |

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

Attach `art/sheets/char-tinker.png` and paste:

> Use the attached character as the exact reference: same kid, same face,
> same hair, same outfit and colors. One full-body image, front view,
> standing in an A-pose (arms angled down and away from the body, legs
> slightly apart), centred and filling the whole height. Clean cartoon
> style: flat solid colors with no texture, no fabric pattern, no shading
> painted on, simple smooth shapes, big clear eyes, thin dark outlines.
> Plain flat light-grey background, even light with no shadows. No text, no
> logos, no other characters.

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
