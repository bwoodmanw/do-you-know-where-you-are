# Toon characters - the full workflow (updated 10 Oct)

Brent makes both the pictures **and** the 3D models with ChatGPT workflows
(no Meshy). Two workflows, in his format:

1. **Pictures:** a front and a back picture of each character.
2. **3D models:** a `.glb` built from both pictures.

Send Claude the pictures after workflow 1 (Claude checks logos, look-alikes,
the A-pose, that front and back match) and the `.glb` files after workflow 2
(Claude renders each before Studio).

Why the back picture: TinkerToon (9-10 Oct) worked, but his model had dark
blue smudges across the back of the orange shirt and very pale arms - the 3D
step had to *guess* the back. With a back picture it copies it instead.

Checked in the old pictures (`art/model-input/<name>/a-pose-front.png`):
- **Muscle's sneakers have a swoosh logo** (a brand mark) - forbidden now.
- **Echo's hoodie has a printed graphic** - the prompt says plain.
- **Glow's raincoat is see-through and glowing** - a 3D model can't keep
  that; the prompt asks for a solid lime-green raincoat.

What the 3D prompt needs (and why), all in the [Model Standard] below:

| Need | Why |
|---|---|
| Copy the front **and back** pictures exactly | no guessed colors on the back (Tinker's smudges) |
| Every area one flat color in **one base-color texture**; no normal / roughness / metal maps | the "PBR off" setting: bumpy maps look blotchy in the game's light |
| **No baked lighting, shadows or dark creases** | the "remove lighting" setting: painted shadows look dirty in-game |
| **Warm tan skin** on face, arms and hands | Tinker's arms came out nearly white |
| **A-pose**, arms 45 degrees down, not touching the body; legs apart; left and right symmetrical | Roblox's Avatar Setup must find arms and legs to rig them |
| Face looking straight forward, standing upright, feet flat at the bottom | so it imports facing the right way |
| **One closed mesh, no skeleton, no animation**, no floor or background | Roblox rigs it itself; extra parts confuse Avatar Setup |
| **5,000-8,000 triangles**, texture 1024 x 1024 embedded in the .glb | low enough for Avatar Setup and phones; cartoon shapes need no more |
| Nothing big sticking out (brims, bags, antennas stay close) | big pieces stretch or tear when the character runs |

## Workflow 1 - the pictures

```
create new workflow to create images based on the [Picture Standard], [Reference] and [Picture]. For each picture, attach the [Reference] picture, then save to "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\[folder]\[file name]". For example, C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input\brainy\front-toon.png.
The [Picture Standard] will be included with every picture prompt. The [Picture] prompt is added to [Picture Standard] and changes per prompt. The [Reference] and [file name] are defined per picture. Make the pictures in the order of the table: each back view uses the front view made just before it as its reference.
[Picture Standard] = "Use the attached reference picture as the exact character: the same face, hair, hairstyle, clothes, colors and accessories. Redraw them in a clean, simple 3D cartoon toy style: every area one smooth, flat, solid color, with no texture at all - no fabric grain, no denim, no knit, no stitching, no dirt, no mud, no stains, no scuffs, no freckles, no folds or wrinkles painted on, no shading or shadows painted on, nothing see-through and nothing glowing. Simple rounded shapes, slightly chunky proportions, big clear eyes, warm tan skin (never pale or white). Small details (buckles, buttons, goggles, pockets) as simple solid shapes. No logos, brand marks, swooshes, printed words or graphics anywhere. Full body standing in an A-pose: arms straight and angled down and away from the body, hands open, legs slightly apart, feet flat. Centered and filling the whole height, nothing cropped. Plain flat light-gray background, even soft light, no floor shadow. One character only, no text. A FRONT view faces the camera straight on; a BACK view is seen from directly behind, same pose, showing the back of the hair, hat or hood, clothes and shoes, every color the same as the front."
[folder]="model-input"
Table for each [Picture], [Reference] and [file name] combination is below:
[Picture] | [Reference] | [file name]
[BACK view of Tinker: backwards blue cap with brass goggles, messy brown hair, orange T-shirt (solid orange on the back), blue overalls with both straps crossing the back, brown tool belt, blue high-top sneakers.] | [model-input\tinker\front-toon.png] | [tinker\back-toon.png]
[FRONT view of Brainy: a boy with messy brown hair and big brown eyes behind round black glasses, a red knit beanie with a small blue propeller on top, a yellow pencil tucked behind his ear, an open white lab coat over a light-blue sweater, khaki cargo pants with rolled cuffs, red high-top sneakers with white soles.] | [model-input\brainy\a-pose-front.png] | [brainy\front-toon.png]
[BACK view of Brainy, matching the reference exactly: the red beanie and propeller, the back of the white lab coat, khaki pants, red sneakers.] | [model-input\brainy\front-toon.png] | [brainy\back-toon.png]
[FRONT view of Shadow: a boy with black hair and purple eyes, a purple hoodie with the hood up, a plain black face mask over his nose and mouth, purple fingerless gloves, black jogger pants, plain black sneakers with purple laces - no stripes.] | [model-input\shadow\a-pose-front.png] | [shadow\front-toon.png]
[BACK view of Shadow, matching the reference exactly: the purple hood up, the back of the purple hoodie, black jogger pants, black sneakers.] | [model-input\shadow\front-toon.png] | [shadow\back-toon.png]
[FRONT view of Muscle: a strong, sturdy boy with spiky brown hair, a yellow headband and yellow wristbands, a red T-shirt with rolled sleeves, black shorts with a gray side stripe, white socks, plain solid red high-top sneakers with white soles and white laces - one color, no panels, no logo or swoosh.] | [model-input\muscle\a-pose-front.png] | [muscle\front-toon.png]
[BACK view of Muscle, matching the reference exactly: spiky brown hair with the yellow headband tied at the back, the back of the red T-shirt, black shorts, white socks, plain sneakers.] | [model-input\muscle\front-toon.png] | [muscle\back-toon.png]
[FRONT view of Glow: a girl with curly brown hair in a bun and green eyes, a green headband with a little antenna ending in a round yellow bulb, a solid lime-green raincoat (not see-through, not glowing) over a cream sweater, a round yellow lamp on a strap at her chest, dark olive pants, dark green rain boots.] | [model-input\glow\a-pose-front.png] | [glow\front-toon.png]
[BACK view of Glow, matching the reference exactly: the hair bun, the headband and antenna, the back of the solid lime-green raincoat with its hood down, dark olive pants, green rain boots.] | [model-input\glow\front-toon.png] | [glow\back-toon.png]
[FRONT view of Patch (her new look, 10 Oct): a girl with long straight golden-blonde hair in a high ponytail with a pink scrunchie, a small bandage on her forehead, blue eyes, a pink vest with pockets over a cream long-sleeve top, a pink shoulder bag with a white heart on it, light-blue jeans, pink-and-cream sneakers.] | [model-input\patch\a-pose-front.png] | [patch\front-toon.png]
[BACK view of Patch, matching the reference exactly: the long blonde ponytail and pink scrunchie, the back of the pink vest with the bag strap across it, light-blue jeans, pink-and-cream sneakers.] | [model-input\patch\front-toon.png] | [patch\back-toon.png]
[FRONT view of Echo: a girl with curly brown hair in a bun and brown eyes, brass goggles pushed up on her head, big purple headphones around her neck, a yellow jacket over a plain purple hoodie (no print), a small black backpack, plain purple jogger pants, purple-and-yellow chunky sneakers.] | [model-input\echo\a-pose-front.png] | [echo\front-toon.png]
[BACK view of Echo, matching the reference exactly: the hair bun and goggle strap, the small black backpack on the back of the yellow jacket, purple pants, purple-and-yellow sneakers.] | [model-input\echo\front-toon.png] | [echo\back-toon.png]
[FRONT view of Bramble: a boy with tousled brown hair and green eyes, a crown of green leaves with one small white flower, a green hooded poncho with a leaf-shaped zigzag edge, a brown strap bag holding acorns, a brown belt, brown cargo shorts, green socks, clean brown lace-up boots.] | [model-input\bramble\a-pose-front.png] | [bramble\front-toon.png]
[BACK view of Bramble, matching the reference exactly: the leaf crown, the back of the green poncho with its zigzag edge and the hood down, brown shorts, green socks, brown boots.] | [model-input\bramble\front-toon.png] | [bramble\back-toon.png]
```

## Workflow 2 - the 3D models

**Updated 10 Oct.** The 3D models are made by **Stable Fast 3D** on Brent's
PC (his RTX 4050), through `tools/make_toon_models.py`. The first try had the
workflow write its own script, which pointed Stable Fast 3D straight at the
OneDrive game folder (a path with spaces) and stalled with nothing made. The
new script works the way the 7-8 Oct batch did - a copy of the picture in a
work folder without spaces, outside OneDrive - and only the finished model
comes back to `art/models/`. All settings are in the script (one 1024 x 1024
texture, about 8,000 triangles), so the workflow only runs it.

**Then the script paints the model's colors from the pictures**
(`tools/paint_toon.py`, added 10 Oct): the front picture onto everything
facing forward, the back picture onto everything facing back, the sides
color-matched - so the back is no longer guessed (Tinker's smudge is gone)
and the colors are not washed out (Shadow's black pants). It keeps the
unpainted model as `<name>-toon-raw.glb`. To repaint one:
`<sf3d-venv python> tools\paint_toon.py tinker`.

**Stable Fast 3D builds the SHAPE from ONE picture - the front.** The back pictures are
checked but not used; Claude renders every model from behind, and any back
that comes out wrong gets fixed (see the end of this section).

**Close Roblox Studio (and games, and browser tabs with video) first.**
Stable Fast 3D needs all of the graphics card's 6 GB (it peaked at 6.2 GB on
Brainy, 10 Oct); anything else using the card makes it crash with exit code
3221225477. The script tries twice, then says so.

Tested 10 Oct on Brainy: about a minute, 6,786 triangles, the back of the lab
coat, hair and beanie came out right; **thin parts can go missing** (his
propeller did) - Claude's render check lists anything lost.

Run it one character at a time (about a minute each), Tinker first:

```
create new workflow to make the 3D models for [Model] using the [Run Standard]. For each row of the table, in order: run the [Run Standard] command with that row's [Model], wait until it prints "DONE", then tell me that row's [file name], its "triangles" number and whether it printed "FAILED". If a row FAILED, show me the last 20 lines it printed and go on to the next row. Do not change tools\make_toon_models.py, do not write a new script, do not change any settings, and do not edit any other file.
[Run Standard] = open a terminal in "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are" and run:
"C:\Users\bwood\Documents\Codex\2026-10-05\referenced-chatgpt-conversation-this-is-an\work\sf3d-venv\Scripts\python.exe" tools\make_toon_models.py [Model]
Table for each [Model] and [file name] combination is below:
[Model] | [file name]
[tinker] | [art\models\tinker-toon.glb]
[brainy] | [art\models\brainy-toon.glb]
[shadow] | [art\models\shadow-toon.glb]
[muscle] | [art\models\muscle-toon.glb]
[glow] | [art\models\glow-toon.glb]
[patch] | [art\models\patch-toon.glb]
[echo] | [art\models\echo-toon.glb]
[bramble] | [art\models\bramble-toon.glb]
[halloween-nurse-patch] | [art\models\halloween-nurse-patch-toon.glb]
```

Or without the workflow: open **PowerShell**, then paste (all nine in one go):

```
cd "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are"
& "C:\Users\bwood\Documents\Codex\2026-10-05\referenced-chatgpt-conversation-this-is-an\work\sf3d-venv\Scripts\python.exe" tools\make_toon_models.py
```

Then tell Claude - Claude renders each model (front, back, side) before you
import anything.

**If a back comes out wrong** (smudges, wrong colors): first re-run just that
character (each run comes out a little different). If it stays wrong, the fix
is a multi-view model maker that uses the back picture too (Hunyuan3D-2
multi-view runs on this PC; Meshy and Tripo do it online) - Claude sets that
up for those characters only.

## Step 3 - into Studio (Party House), one character at a time

1. **Avatar** tab -> **Import 3D** -> the `.glb` -> **Import**. If the
   preview shows the back, change **World Forward** until the face looks at
   you.
2. Select it -> **Avatar** tab -> **Avatar Setup** -> **Body** -> finish
   (OK on dynamic-head warnings).
3. Check the new copy has **Head, UpperTorso...** (about 15 parts); delete
   the single-mesh import.
4. Rename it `<Name>Toon` (e.g. `BrainyToon`; Tinker's new one replaces the
   old `TinkerToon` - delete the old one first) and drag it into
   **ServerStorage -> Characters**.
5. Claude adds it to `Config.STUDIO_TRY_MODEL` so you play it (Studio and
   live, only you); compare photos; if it wins, Claude switches it over
   (both places: the Lobby's Characters screen has its own copy).

## After workflow 2 - the order of work

1. **Claude checks every .glb** (renders front, back and side with
   `tools/preview_glb.py`): the back matches the back picture, skin colored
   arms, A-pose, nothing sticking out, triangles under 8,000, no logos.
   Any that fail get a re-run of just that row.
2. **Brent imports them into Party House** (Step 3 above), named
   `TinkerToon`, `BrainyToon`, `ShadowToon`, `MuscleToon`, `GlowToon`,
   `PatchToon`, `EchoToon`, `BrambleToon`, `PatchHalloweenToon`.
3. **Claude switches all of them on for Brent only** (`STUDIO_TRY_MODEL`):
   Studio and live, everyone else keeps the old ones.
4. **Brent plays each one** (Studio, then live): photos front / back /
   running, F9 Server lines (a broken model says `[Characters] ... died`
   and the old one plays instead). Claude fixes walk / hip height / face
   problems; a bad model gets its row re-run.
5. **Switch over, one character at a time** (Party House):
   - make a folder **ServerStorage -> CharactersOld** and drag the old model
     (e.g. `Patch`) into it - out of `Characters`, so it is never picked by
     mistake, but kept in case we go back;
   - rename `PatchToon` to `Patch` (and `PatchHalloweenToon` to
     `PatchHalloween`);
   - right-click it -> **Save to Roblox** -> copy the new asset id to Claude.
6. **Claude updates the code**: `Config.CHARACTER_ASSETS` (the Lobby's 3D
   characters load from these ids), clears `STUDIO_TRY_MODEL`, tunes the
   Lobby preview size (`Config.PREVIEW_SCALE`) and the plain-idle / plain-run
   lists (`Config.ANIM`: the T-pose fixes may not be needed for A-pose models).
7. **Patch's pictures**: upload the new `Patch.png` portrait in each place
   (Claude gives the clicks) and the new Halloween Nurse Patch picture as the
   Game Pass image in Creator Hub; Claude puts the two portrait ids in
   `Config.PORTRAITS` / `Config.PORTRAITS_GAME`.
8. **Publish both places**, a live test of the Lobby Characters screen (3D
   models, Skins window) and a game with each character.
9. **Then the other 7 skins** (Pumpkin Patch Tinker, Ghostly Shadow, Candy
   Glow, Space Cadet Brainy, Snow Day Muscle, Starlight Echo, Autumn Leaf
   Bramble) the same way - workflow 1 rows from their skin pictures, then
   workflow 2 - so skins match the new look. Decision for Brent: all at once
   or after the 8 characters are live.

## Patch's new look (Brent, 10 Oct): her pictures to remake

Brent kept the new toon Patch: long golden-blonde ponytail, blue eyes,
light-blue jeans (the rest as before). Everything that shows the old
brown-haired Patch is remade to match:

| Picture | File | Where it shows |
|---|---|---|
| Portrait | `art/roblox-store/portraits/Patch.png` | Lobby portrait buttons and Plain skin tile (`Config.PORTRAITS`), the game's card (`Config.PORTRAITS_GAME`) - uploaded once per place |
| Skin art | `art/roblox-store/passes/pass-halloween-nurse-patch.png` | the Game Pass picture, and her tile in the Lobby's Skins window |
| Skin model pictures | `art/model-input/halloween-nurse-patch/front-toon.png`, `back-toon.png` | for remaking the Halloween Nurse Patch 3D skin (workflow 2) |

Unchanged: her skill icon (a heart), the store thumbnail and icons (she is
not in them). The prompt is in the chat of 10 Oct and below.

```
create new workflow to create images based on the [Picture Standard], [Reference] and [Picture]. For each picture, attach every [Reference] picture listed, then save to "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\[file name]", replacing the file already there. For example, C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\roblox-store\portraits\Patch.png.
The [Picture Standard] will be included with every picture prompt. The [Picture] prompt is added to [Picture Standard] and changes per prompt. The [Reference] and [file name] are defined per picture. Make the pictures in the order of the table: the back view uses the front view made just before it.
[Picture Standard] = "The character is Patch, a kind, caring girl of about 9, exactly as in the attached Patch picture (model-input\patch\front-toon.png): long straight golden-blonde hair in a high ponytail with a scrunchie, big blue eyes, a small skin-colored bandage on her forehead, a gentle smile, warm light skin. Clean, simple 3D cartoon toy style: smooth flat colors, soft rounded shapes, big clear eyes, no texture, no dirt, no freckles. No logos, brand marks, printed words or text anywhere. Not a copy of any existing cartoon or game character. Bright, friendly and right for young kids."
Table for each [Picture], [Reference] and [file name] combination is below:
[Picture] | [Reference] | [file name]
[PORTRAIT, square: Patch from the chest up, turned slightly toward the camera, in her pink vest with pockets over a cream long-sleeve top, the brown strap of her shoulder bag across her chest. Behind her a soft glowing pink circle on a deep plum-purple background. In the bottom-right corner a round badge: a cream circle with a pink heart and a small bandage across it. Lay it out exactly like the attached old portrait - same framing, glow and badge - with Patch's new look.] | [model-input\patch\front-toon.png, roblox-store\portraits\Patch.png] | [roblox-store\portraits\Patch.png]
[SKIN PICTURE, square, for "Halloween Nurse Patch": Patch from the waist up, wearing the Halloween nurse outfit from the attached outfit picture - a dark gray cardigan over a black nurse top with a small orange pumpkin badge, a little penlight on a cord, an orange shoulder bag with a friendly jack-o'-lantern face on a brown strap, an orange scrunchie. Inside a big circle with a glowing orange-to-plum background and a few soft white dots, on a dark background - laid out exactly like the attached old skin picture, with Patch's new look.] | [model-input\patch\front-toon.png, model-input\halloween-nurse-patch\a-pose-front.png, roblox-store\passes\pass-halloween-nurse-patch.png] | [roblox-store\passes\pass-halloween-nurse-patch.png]
[FRONT view, full body, for the 3D skin: Patch in the Halloween nurse outfit from the attached outfit picture - dark gray cardigan over a black nurse top with a small orange pumpkin badge, a penlight on a cord, an orange jack-o'-lantern shoulder bag on a brown strap, plain orange jogger pants with no pockets, white sneakers with small orange pumpkin dots, an orange scrunchie. Every area one flat solid color. Standing in an A-pose: arms straight and angled down and away from the body, hands open, legs slightly apart, feet flat; facing the camera straight on; centered and filling the whole height. Plain flat light-gray background, even soft light, no floor shadow.] | [model-input\patch\front-toon.png, model-input\halloween-nurse-patch\a-pose-front.png] | [model-input\halloween-nurse-patch\front-toon.png]
[BACK view, full body, for the 3D skin: the same Patch in the same Halloween nurse outfit as the attached front view, seen from directly behind in the same A-pose - the long blonde ponytail with the orange scrunchie, the back of the gray cardigan with the bag strap across it, plain orange jogger pants, white-and-orange sneakers. Every color the same as the front. Plain flat light-gray background, even soft light.] | [model-input\halloween-nurse-patch\front-toon.png] | [model-input\halloween-nurse-patch\back-toon.png]
```

## The skins (10 Oct): the same two workflows

The 8 skins become toons the same way as the characters. Each skin's FRONT
picture attaches TWO references: the character's new toon picture (face,
hair, eyes) and the skin's old picture (the outfit). Checked in the old
pictures: no logos or look-alikes; Candy Glow's see-through raincoat and
Ghostly Shadow's glowing hem become solid (3D can't do see-through or glow).
Space Cadet Brainy loses his thin propeller like Brainy - the built one goes
on (`Config.PROPELLER`). The model step needs no new prompt: the script
already paints every model (back from the back picture, colors corrected,
seams padded).

### Skins workflow 1 - the pictures

Updated 10 Oct: the skins follow the characters' new toon looks - the pants
of Shadow, Glow, Echo and Patch are plain joggers / jeans with NO pockets, so
their skins' pants are too (Brainy, Bramble and Tinker kept theirs); shoes
plain and logo-free; anything a skin does not change matches the character's
toon picture.

```
create new workflow to create images based on the [Picture Standard], [Reference] and [Picture]. For each picture, attach every [Reference] picture listed, in that order, then save to "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input\[file name]". For example, C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input\tinker-pumpkin\front-toon.png.
The [Picture Standard] will be included with every picture prompt. The [Picture] prompt is added to [Picture Standard] and changes per prompt. The [Reference] and [file name] are defined per picture. Make the pictures in the order of the table: each back view uses the front view made just before it as its reference.
[Picture Standard] = "For a FRONT view two pictures are attached: the FIRST is the character's approved toon look - keep exactly their face, hair, eye color, skin tone and style; the SECOND is the skin's outfit - dress them in that outfit as described in this prompt. Where the prompt and the outfit picture differ, follow the prompt (it has the approved changes: plain pants without pockets where it says so, plain logo-free shoes, solid colors instead of see-through or glowing). For a BACK view one picture is attached: the same character in the same outfit, seen from directly behind. Clean, simple 3D cartoon toy style: every area one smooth, flat, solid color, with no texture at all - no fabric grain, no knit, no stitching, no dirt, no mud, no stains, no scuffs, no freckles, no folds or wrinkles painted on, no shading or shadows painted on, nothing see-through and nothing glowing. Simple rounded shapes, slightly chunky proportions, big clear eyes, warm skin tone (never pale or white). Small details as simple solid shapes. No logos, brand marks, swooshes, stripes on shoes, printed words or graphics. Full body standing in an A-pose: arms straight and angled down and away from the body, hands open, legs slightly apart, feet flat. Centered and filling the whole height, nothing cropped. Plain flat light-gray background, even soft light, no floor shadow. One character only, no text. A FRONT view faces the camera straight on; a BACK view is seen from directly behind, same pose, showing the back of the hair, hat or hood, clothes and shoes, every color the same as the front."
Table for each [Picture], [Reference] and [file name] combination is below:
[Picture] | [Reference] | [file name]
[FRONT view of Pumpkin Patch Tinker: Tinker in an orange knit beanie with a small green pumpkin stem on top and brass goggles, a dark green long-sleeve shirt, orange overalls with side leg pockets like Tinker's own overalls and one green leaf patch on a knee, a brown tool belt with a wrench and a small smiling jack-o'-lantern charm, plain green high-top sneakers with cream soles.] | [model-input\tinker\front-toon.png, model-input\tinker-pumpkin\a-pose-front.png] | [tinker-pumpkin\front-toon.png]
[BACK view of Pumpkin Patch Tinker, matching the reference exactly: the orange beanie and goggle strap, the back of the green shirt with the orange overall straps crossing, the tool belt, green sneakers.] | [model-input\tinker-pumpkin\front-toon.png] | [tinker-pumpkin\back-toon.png]
[FRONT view of Ghostly Shadow: Shadow in a pale lavender hoodie with the hood up and a wavy, ghost-like bottom edge (solid lavender, not glowing), a plain light gray face mask, gray fingerless gloves, plain light gray jogger pants with NO pockets (like Shadow's own black joggers), plain white sneakers with lavender laces and no stripes.] | [model-input\shadow\front-toon.png, model-input\ghostly-shadow\a-pose-front.png] | [ghostly-shadow\front-toon.png]
[BACK view of Ghostly Shadow, matching the reference exactly: the lavender hood up, the back of the hoodie with its wavy edge, plain gray joggers, white sneakers.] | [model-input\ghostly-shadow\front-toon.png] | [ghostly-shadow\back-toon.png]
[FRONT view of Candy Glow: Glow with a pink headband and a little pink antenna ending in a swirl lollipop, a solid bubblegum-pink raincoat (not see-through, not glowing) over a mint-and-cream striped sweater, a round swirl-lollipop pendant, plain lilac jogger pants with NO pockets (like Glow's own plain pants), pink rain boots.] | [model-input\glow\front-toon.png, model-input\candy-glow\a-pose-front.png] | [candy-glow\front-toon.png]
[BACK view of Candy Glow, matching the reference exactly: the hair bun and lollipop antenna, the back of the solid pink raincoat with its hood down, plain lilac joggers, pink rain boots.] | [model-input\candy-glow\front-toon.png] | [candy-glow\back-toon.png]
[FRONT view of Space Cadet Brainy: Brainy with his round black glasses, red beanie with a small blue propeller and pencil, in a white space suit with light-blue panels, orange cuffs and orange knee pads, a round silver badge on the chest, an orange belt with a silver buckle, white-and-gray space boots.] | [model-input\brainy\front-toon.png, model-input\space-cadet-brainy\a-pose-front.png] | [space-cadet-brainy\front-toon.png]
[BACK view of Space Cadet Brainy, matching the reference exactly: the red beanie and propeller, a small silver air tank on the back of the white space suit, the orange belt, white-and-gray boots.] | [model-input\space-cadet-brainy\front-toon.png] | [space-cadet-brainy\back-toon.png]
[FRONT view of Snow Day Muscle: Muscle in a yellow knit hat with ear flaps and a pom-pom, a puffy red winter jacket over a cream sweater with a simple white snowflake, a red-and-cream striped scarf, yellow mittens, plain dark gray snow pants with NO pockets, plain brown snow boots with cream fur trim.] | [model-input\muscle\front-toon.png, model-input\snow-day-muscle\a-pose-front.png] | [snow-day-muscle\front-toon.png]
[BACK view of Snow Day Muscle, matching the reference exactly: the yellow hat and pom-pom, the back of the puffy red jacket with the scarf ends, yellow mittens, plain gray snow pants, brown boots.] | [model-input\snow-day-muscle\front-toon.png] | [snow-day-muscle\back-toon.png]
[FRONT view of Starlight Echo: Echo with her brass goggles and purple headphones, in a navy jacket with small gold stars and a gold zipper over a plain purple hoodie, a small gold crescent-moon bag at her side, plain purple jogger pants with NO pockets (exactly like Echo's own), navy sneakers with small gold stars and cream soles.] | [model-input\echo\front-toon.png, model-input\starlight-echo\a-pose-front.png] | [starlight-echo\front-toon.png]
[BACK view of Starlight Echo, matching the reference exactly: the hair bun and goggle strap, the back of the starry navy jacket, the moon bag, plain purple joggers, starry sneakers.] | [model-input\starlight-echo\front-toon.png] | [starlight-echo\back-toon.png]
[FRONT view of Autumn Leaf Bramble: Bramble with a crown of orange, red and yellow autumn leaves, a poncho of overlapping orange, red and gold leaves with a brown hood, a brown strap bag with acorns, leaf bracelets, brown cargo shorts like Bramble's own, mustard-yellow socks, clean brown lace-up boots.] | [model-input\bramble\front-toon.png, model-input\autumn-leaf-bramble\a-pose-front.png] | [autumn-leaf-bramble\front-toon.png]
[BACK view of Autumn Leaf Bramble, matching the reference exactly: the leaf crown, the back of the autumn-leaf poncho with the brown hood down, brown shorts, mustard socks, brown boots.] | [model-input\autumn-leaf-bramble\front-toon.png] | [autumn-leaf-bramble\back-toon.png]
[FRONT view of Muscle Mummy: Muscle as a friendly cartoon mummy - his face uncovered and smiling, a cream bandage headband, his body, arms and legs wrapped in smooth cream bandages with a few small orange and purple patches, yellow wristbands, plain gray sneakers with white soles and no logo.] | [model-input\muscle\front-toon.png, model-input\Muscle Mummy\a-pose-front.png] | [muscle-mummy\front-toon.png]
[BACK view of Muscle Mummy, matching the reference exactly: his spiky brown hair and the knot of the bandage headband, the back of the cream bandage wraps with a patch or two, gray sneakers.] | [model-input\muscle-mummy\front-toon.png] | [muscle-mummy\back-toon.png]
```

Send Claude the 16 pictures to check before the models.

### Skins workflow 2 - the models

The same script as the characters - it makes each model and paints it
(colors corrected, back from the back picture, seams padded). **Close Roblox
Studio first** (the graphics card needs all its memory).

```
create new workflow to make the 3D models for [Model] using the [Run Standard]. For each row of the table, in order: run the [Run Standard] command with that row's [Model], wait until it prints "DONE", then tell me that row's [file name], its "triangles" number and whether it printed "FAILED". If a row FAILED, show me the last 20 lines it printed and go on to the next row. Do not change tools\make_toon_models.py or tools\paint_toon.py, do not write a new script, do not change any settings, and do not edit any other file.
[Run Standard] = open a terminal in "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are" and run:
"C:\Users\bwood\Documents\Codex\2026-10-05\referenced-chatgpt-conversation-this-is-an\work\sf3d-venv\Scripts\python.exe" tools\make_toon_models.py [Model]
Table for each [Model] and [file name] combination is below:
[Model] | [file name]
[tinker-pumpkin] | [art\models\tinker-pumpkin-toon.glb]
[ghostly-shadow] | [art\models\ghostly-shadow-toon.glb]
[candy-glow] | [art\models\candy-glow-toon.glb]
[space-cadet-brainy] | [art\models\space-cadet-brainy-toon.glb]
[snow-day-muscle] | [art\models\snow-day-muscle-toon.glb]
[starlight-echo] | [art\models\starlight-echo-toon.glb]
[autumn-leaf-bramble] | [art\models\autumn-leaf-bramble-toon.glb]
[muscle-mummy] | [art\models\muscle-mummy-toon.glb]
```

Or without the workflow, in PowerShell (all 8, about 10 minutes):

```
cd "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are"
& "C:\Users\bwood\Documents\Codex\2026-10-05\referenced-chatgpt-conversation-this-is-an\work\sf3d-venv\Scripts\python.exe" tools\make_toon_models.py tinker-pumpkin ghostly-shadow candy-glow space-cadet-brainy snow-day-muscle starlight-echo autumn-leaf-bramble muscle-mummy
```

Then Claude renders each model. Into Studio (Party House): Import 3D ->
Avatar Setup -> ServerStorage -> Characters, named:

| File | Name in Studio |
|---|---|
| tinker-pumpkin-toon.glb | TinkerPumpkinToon |
| ghostly-shadow-toon.glb | ShadowGhostToon |
| candy-glow-toon.glb | GlowCandyToon |
| space-cadet-brainy-toon.glb | BrainySpaceToon |
| snow-day-muscle-toon.glb | MuscleSnowToon |
| starlight-echo-toon.glb | EchoStarToon |
| autumn-leaf-bramble-toon.glb | BrambleAutumnToon |
| muscle-mummy-toon.glb | MuscleMummyToon |

Each is already switched on for Brent (`Config.STUDIO_TRY_MODEL`): wear the
skin in the Lobby, play it in Party House. When one looks right: move the old
skin model to ServerStorage -> CharactersOld, rename the toon to the old name
(e.g. TinkerPumpkinToon -> TinkerPumpkin), right-click -> Save to Roblox, and
send Claude the id (the Lobby's 3D view loads it).
