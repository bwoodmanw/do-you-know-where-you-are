# Toon characters - the full workflow (10 Oct)

TinkerToon (9-10 Oct) worked in the game, with two faults that came from
Meshy *guessing the back*: dark blue smudges across the back of the orange
shirt, and very pale arms. So every toon now gets **two pictures, front and
back**, and Meshy builds from both (multi-view). The order after Tinker:
Brainy, Shadow, Muscle, Glow, Patch, Echo, Bramble.

Checked in the old pictures (`art/model-input/<name>/a-pose-front.png`):
- **Muscle's sneakers have a swoosh logo** - a brand mark; the prompt
  forbids logos and swooshes.
- **Echo's hoodie has a printed graphic** - the prompt says plain.
- **Glow's raincoat is see-through and glowing** - Meshy can't make that;
  the prompt asks for a solid lime-green raincoat.

## Step 0 - fix TinkerToon's texture in Meshy (Retexture)

Names move between Meshy versions; if a screen differs, send Brent's photo.

1. **meshy.ai** -> **My Assets** (or Workspace) -> open the TinkerToon model.
   If it isn't there: left menu **AI Texturing / Retexture** -> **Upload
   model** -> `art/models/tinker-toon.glb`.
2. Click **Retexture** (or **Texture**).
3. **Reference image:** `art/model-input/tinker/front-toon.png`.
4. **Text prompt:**
   > Cartoon boy mechanic in a clean toy style, flat solid colors, no
   > texture. Warm tan skin on the face, arms and hands. Orange T-shirt,
   > solid orange all the way round, including the back. Medium-blue
   > overalls, the straps going over both shoulders on the front and the
   > back. Brown tool belt with a brass buckle. Blue cap, brown hair, brass
   > goggles with dark lenses. Blue high-top sneakers with cream soles and
   > cream laces. No dirt, no stains, no smudges, no painted shadows, no
   > denim grain, no stitching, no logos.
5. **Negative prompt** (if there is a box):
   > dirt, smudges, dark patches, painted shadows, wrinkles, denim texture,
   > stitching, grime, logos, text, pale white skin
6. Settings: **Art style: Cartoon** (or Stylized), **PBR: off**, **Remove
   lighting / Delight: on**, **Keep original UV: on** if offered.
7. Generate, pick the best (check the **back** and the **arms**),
   **Download .glb** as `art/models/tinker-toon-2.glb`. Claude renders it
   before Studio.

## Step 1 - the pictures (one ChatGPT workflow)

Paste into ChatGPT (Brent's workflow format). The back pictures use the
front picture made just before them as the reference, so they match.

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
[FRONT view of Shadow: a boy with black hair and purple eyes, a purple hoodie with the hood up, a plain black face mask over his nose and mouth, purple fingerless gloves, black cargo jogger pants, black sneakers with purple stripes.] | [model-input\shadow\a-pose-front.png] | [shadow\front-toon.png]
[BACK view of Shadow, matching the reference exactly: the purple hood up, the back of the purple hoodie, black jogger pants, black sneakers.] | [model-input\shadow\front-toon.png] | [shadow\back-toon.png]
[FRONT view of Muscle: a strong, sturdy boy with spiky brown hair, a yellow headband and yellow wristbands, a red T-shirt with rolled sleeves, black shorts with a gray side stripe, white socks, black-and-white high-top sneakers with red panels - plain sneakers, no logo or swoosh.] | [model-input\muscle\a-pose-front.png] | [muscle\front-toon.png]
[BACK view of Muscle, matching the reference exactly: spiky brown hair with the yellow headband tied at the back, the back of the red T-shirt, black shorts, white socks, plain sneakers.] | [model-input\muscle\front-toon.png] | [muscle\back-toon.png]
[FRONT view of Glow: a girl with curly brown hair in a bun and green eyes, a green headband with a little antenna ending in a round yellow bulb, a solid lime-green raincoat (not see-through, not glowing) over a cream sweater, a round yellow lamp on a strap at her chest, dark olive pants, dark green rain boots.] | [model-input\glow\a-pose-front.png] | [glow\front-toon.png]
[BACK view of Glow, matching the reference exactly: the hair bun, the headband and antenna, the back of the solid lime-green raincoat with its hood down, dark olive pants, green rain boots.] | [model-input\glow\front-toon.png] | [glow\back-toon.png]
[FRONT view of Patch: a girl with long wavy brown hair in a high ponytail with a pink scrunchie, a small bandage on her forehead, brown eyes, a pink vest with pockets over a cream long-sleeve top, a pink shoulder bag with a white heart on it, olive-green cargo jogger pants, pink-and-cream sneakers.] | [model-input\patch\a-pose-front.png] | [patch\front-toon.png]
[BACK view of Patch, matching the reference exactly: the long ponytail and pink scrunchie, the back of the pink vest with the bag strap across it, olive pants, pink-and-cream sneakers.] | [model-input\patch\front-toon.png] | [patch\back-toon.png]
[FRONT view of Echo: a girl with curly brown hair in a bun and brown eyes, brass goggles pushed up on her head, big purple headphones around her neck, a yellow jacket over a plain purple hoodie (no print), a small black backpack, purple cargo pants, purple-and-yellow chunky sneakers.] | [model-input\echo\a-pose-front.png] | [echo\front-toon.png]
[BACK view of Echo, matching the reference exactly: the hair bun and goggle strap, the small black backpack on the back of the yellow jacket, purple pants, purple-and-yellow sneakers.] | [model-input\echo\front-toon.png] | [echo\back-toon.png]
[FRONT view of Bramble: a boy with tousled brown hair and green eyes, a crown of green leaves with one small white flower, a green hooded poncho with a leaf-shaped zigzag edge, a brown strap bag holding acorns, a brown belt, brown cargo shorts, green socks, clean brown lace-up boots.] | [model-input\bramble\a-pose-front.png] | [bramble\front-toon.png]
[BACK view of Bramble, matching the reference exactly: the leaf crown, the back of the green poncho with its zigzag edge and the hood down, brown shorts, green socks, brown boots.] | [model-input\bramble\front-toon.png] | [bramble\back-toon.png]
```

**Send Claude the pictures before Meshy** - Claude checks for logos,
likeness to known characters, the A-pose and that front and back match.

## Step 2 - Meshy, one character at a time (Image to 3D, multi-view)

1. **meshy.ai** -> **Image to 3D** -> choose **Multi-view** (or "multiple
   images") -> upload `front-toon.png` as **Front** and `back-toon.png` as
   **Back**. (No multi-view? Upload the front only.)
2. Settings (look under **Advanced**):
   - **Art style / Texture style:** Cartoon (or Stylized)
   - **PBR:** off
   - **Remove lighting / Delight:** on
   - **Polycount / Topology:** the lower option (about 5,000-8,000)
   - **Pose:** A-pose
   - **Symmetry:** on (or Auto)
   - Do **not** use Auto-Rig, Rigging or Animate (Roblox rigs it)
3. Generate, then turn each result round: pick the one whose **back** is
   clean and whose **arms** are skin colored. Check the face looks forward.
4. **Download .glb** as `art/models/<name>-toon.glb` (e.g.
   `brainy-toon.glb`). Claude renders it before Studio.

## Step 3 - into Studio (Party House)

1. **Avatar** tab -> **Import 3D** -> the `.glb` -> **Import**.
2. Select it -> **Avatar** tab -> **Avatar Setup** -> **Body** -> finish
   (OK on dynamic-head warnings).
3. Check the new copy has **Head, UpperTorso...** (about 15 parts); delete
   the single-mesh import.
4. Rename it `<Name>Toon` (e.g. `BrainyToon`), drag it into
   **ServerStorage -> Characters**.
5. Claude adds it to `Config.STUDIO_TRY_MODEL` so you play it (Studio and
   live, only you); compare photos; if it wins, Claude switches it over
   (both places: the Lobby's Characters screen has its own copy).
