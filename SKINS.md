# Character skins (B9) - art, models, Game Passes

The code is in and hidden: a skin appears in the Lobby's **Characters** screen
only once its Game Pass id is in `Config.SKINS` (`roblox/src/shared/Config.luau`).
In Studio every skin can be tried for free (`Config.SKINS_FREE_IN_STUDIO`).

A skin is a whole different 3D model of the same kid. The player buys it once
(a Game Pass), picks it on the Characters screen (the Skins row under the
skill ladder), and from the next game their character uses that model; the 3D
previews show it too. Skins change looks only, never skills.

## The nine skins

| # | Skin | Character | Picture folder (`art/model-input/`) | Model file (`art/models/`) | Name in Studio | Picture |
|---|---|---|---|---|---|---|
| 1 | Pumpkin Patch Tinker | Tinker | `tinker-pumpkin/` | `tinker-pumpkin.glb` | `TinkerPumpkin` | ready (checked 7 Oct) |
| 2 | Ghostly Shadow | Shadow | `ghostly-shadow/` | `ghostly-shadow.glb` | `ShadowGhost` | ready (checked 7 Oct) |
| 3 | Candy Glow | Glow | `candy-glow/` | `candy-glow.glb` | `GlowCandy` | ready (checked 7 Oct) |
| 4 | Night Nurse Patch | Patch | `night-nurse-patch/` | `night-nurse-patch.glb` | `PatchNurse` | ready (checked 7 Oct) |
| 5 | Space Cadet Brainy | Brainy | `space-cadet-brainy/` | `space-cadet-brainy.glb` | `BrainySpace` | ready (checked 7 Oct) |
| 6 | Snow Day Muscle | Muscle | `snow-day-muscle/` | `snow-day-muscle.glb` | `MuscleSnow` | ready - see the scarf note |
| 7 | Starlight Echo | Echo | `starlight-echo/` | `starlight-echo.glb` | `EchoStar` | ready (checked 7 Oct) |
| 8 | Autumn Leaf Bramble | Bramble | `autumn-leaf-bramble/` | `autumn-leaf-bramble.glb` | `BrambleAutumn` | ready (checked 7 Oct) |
| 9 | Halloween Nurse Patch | Patch | `halloween-nurse-patch/` | `halloween-nurse-patch.glb` | `PatchHalloween` | ready (checked 7 Oct) |

The **Name in Studio** must be exact (capitals too): the game finds the model
by that name. Suggested price 99 Robux each.

### What I checked (7 Oct)

All nine: full body, A-pose, facing the camera, plain grey background, the
same face as the character, no logos, no likeness to known characters - ready
for Meshy.
- **Pumpkin Patch Tinker** - very good; same proportions as Tinker.
- **Ghostly Shadow** - first model (7 Oct): the wide ragged hoodie hangs
  from the arms down to the hips, so Meshy made one sheet of cloth joining
  hand to hip, and Avatar Setup ties it to both: it stretches and flaps when
  he walks. Make the picture again with prompt **2b** (a fitted hoodie with
  air between the arms and the body), then the model with **T-Pose**.
- **Candy Glow** - good. The see-through raincoat comes out as solid pink (the
  same happened with Glow's green coat and looked fine).

- **Night Nurse Patch** - good: hearts, no cross, the plaster and freckles
  kept, a clear A-pose. (Folder renamed from `Night nurse patch` to
  `night-nurse-patch` to match the others.) If Avatar Setup joins the
  shoulder bag to her arm, regenerate in Meshy with **T-Pose**.
- **Halloween Nurse Patch** (Brent's own extra) - good: black scrubs and grey
  cardigan, orange trousers, pumpkin faces on the pocket, bag and trainers.
- **Space Cadet Brainy** - very good: the badge is a plain ringed planet, no
  flags or agency marks. The air tanks behind his shoulders may merge into
  the back in 3D (fine).
- **Snow Day Muscle** - good; plain snow boots with no marks (plain Muscle's
  own trainers still have the swoosh-like mark - a separate fix). Note: a red-and-gold striped scarf is the look of a
  famous wizard-school scarf. Low risk, but if you want to be safe, make it
  again with "a red and white striped scarf" (decision in chat).
- **Starlight Echo** - good: gold stars, crescent-moon backpack, star
  headphones, no brand marks on the trainers. (Its file had no `.png` ending;
  renamed.)
- **Autumn Leaf Bramble** - good. The leaf poncho is very spiky and hangs
  over the arms: if Avatar Setup joins the leaves to the arms, regenerate in
  Meshy with **T-Pose** (the first Bramble's poncho worked).

## Art prompts

Attach the character's own picture from `art/model-input/<character>/a-pose-front.png`
as the reference image so the face, hair and body stay the same. Every prompt
ends with the line the originals used. Save each result as
`art/model-input/<picture folder>/a-pose-front.png` (folders in the table).

**1. Pumpkin Patch Tinker** (done)
> The same boy as the reference picture, same face, freckles and messy brown hair. Halloween outfit: pumpkin-orange denim overalls with a green leaf-shaped patch on one knee, a dark green long-sleeved top, a soft orange knitted beanie with a short green stem on top, his brass goggles pushed up on the beanie, a brown tool belt with a small wrench and a little toy pumpkin hanging from it, green high-top trainers. Friendly smile. Stylised 3D animated-film look, full body, standing in an A-pose facing the camera, plain light grey background, soft even lighting, no text, no logos.

**2. Ghostly Shadow** (done)
> The same child as the reference picture, same purple eyes and dark hair. Ghost costume: a loose pale lavender-white hoodie with soft wavy ragged hem and sleeve ends like a friendly ghost, a faint glow at the edges, the hood up, a grey cloth face mask, light grey cargo trousers, white trainers with lavender laces, fingerless grey gloves. Mysterious but friendly. Stylised 3D animated-film look, full body, standing in an A-pose facing the camera, plain light grey background, soft even lighting, no text, no logos.

**2b. Ghostly Shadow, fitted** (use this one: the first made a cloak that joined hand to hip)
> The same child as the reference picture, same purple eyes and dark hair. Ghost costume: a fitted pale lavender-white hoodie (not a cape, poncho or cloak) with the hood up; close-fitting long sleeves that end at the wrists with a short wavy ghost-trim cuff; the hem stops at the waist with a short wavy ghost-trim edge; a clear gap of air between each arm and the body all the way down, nothing hanging from the arms; a faint glow along the trims, a grey cloth face mask, slim light grey cargo trousers, white trainers with lavender laces, fingerless grey gloves. Mysterious but friendly. Stylised 3D animated-film look, full body, standing in a T-pose facing the camera, arms straight out to the sides, plain light grey background, soft even lighting, no text, no logos.

**3. Candy Glow** (done)
> The same girl as the reference picture, same curly brown hair bun, freckles and green eyes. Candy outfit: a see-through glowing raincoat in candy pink with small sweet-shaped buttons, a striped mint and white jumper, lilac trousers, glossy pink wellington boots, her glowing headband antenna now ends in a little glowing lollipop, a round candy-shaped lamp on her chest. Cheerful. Stylised 3D animated-film look, full body, standing in an A-pose facing the camera, plain light grey background, soft even lighting, no text, no logos.

**4. Night Nurse Patch**
> The same girl as the reference picture, same curly brown ponytail, plaster on her forehead and freckles. Night-time nurse outfit: a mint green nurse's tunic with a small pink heart on the pocket (no cross symbol), a navy cardigan over it, a little torch on a lanyard, navy trousers, white trainers with pink hearts, her pink first-aid shoulder bag. Kind and brave. Stylised 3D animated-film look, full body, standing in an A-pose facing the camera, plain light grey background, soft even lighting, no text, no logos.

(No red cross on Patch: the Red Cross emblem is protected and Roblox removes it.)

**5. Space Cadet Brainy**
> The same boy as the reference picture, same round black glasses, brown eyes and messy brown hair. Space cadet outfit: a puffy white and pale blue spacesuit-style jumpsuit with chunky orange cuffs and knee pads, a round silver badge with a small ringed planet on the chest (no flags, no agency logos, no words), a little backpack air tank, white moon boots with grey soles, his red beanie with the blue propeller still on his head, a pencil behind his ear. Curious and excited. Stylised 3D animated-film look, full body, standing in an A-pose facing the camera, plain light grey background, soft even lighting, no text, no logos.

**6. Snow Day Muscle**
> The same boy as the reference picture, same spiky brown hair, brown eyes and strong arms. Winter outfit: a puffy red winter jacket left open over a cream knitted jumper with a white snowflake pattern, a yellow knitted bobble hat with ear flaps, yellow mittens, dark grey snow trousers, chunky brown snow boots, a long striped red and yellow scarf. Big happy grin. Plain clothes and boots with no logos or brand marks. Stylised 3D animated-film look, full body, standing in an A-pose facing the camera, plain light grey background, soft even lighting, no text, no logos.

**7. Starlight Echo**
> The same girl as the reference picture, same curly brown hair, freckles and brown eyes, her goggles on her head. Night-sky outfit: a deep navy bomber jacket covered in small gold stars, a purple hoodie under it, her big headphones now navy with a small glowing star on each ear cup, purple cargo trousers with gold stitching, navy and gold trainers, a small backpack shaped like a crescent moon. Cool and confident. Stylised 3D animated-film look, full body, standing in an A-pose facing the camera, plain light grey background, soft even lighting, no text, no logos.

**8. Autumn Leaf Bramble**
> The same child as the reference picture, same messy brown hair, green eyes and freckles. Autumn outfit: a poncho made of orange, red and golden autumn leaves with a brown hood, a crown of oak leaves and acorns instead of the flower crown, a pouch of conkers and pine cones on a strap, brown cord shorts, mustard knitted socks, muddy brown boots, vine bracelets with small red berries. Gentle smile. Stylised 3D animated-film look, full body, standing in an A-pose facing the camera, plain light grey background, soft even lighting, no text, no logos.

Send me each new picture before making its model: I look at every one for
logos, words and resemblance to known characters (the game is public).

## Muscle's trainers: the clean texture (7 Oct)

Muscle's own model had a red swoosh-like mark smeared along each trainer
(from the source picture). `art/models/muscle-texture-clean.png` is his
texture with only the red on the shoes repainted grey
(`art/models/muscle-shoes-before-after.png`: before on top, after below;
made by `tools/repaint_shoes.py`). To put it on him:

1. Studio, the **Party House** place, game stopped. **View** -> **Asset
   Manager** -> the **Import** button (arrow up) -> choose
   `art/models/muscle-texture-clean.png` -> it appears under **Images**.
   Right-click it -> **Copy Asset ID**.
2. **Explorer** -> **ServerStorage -> Characters -> Muscle**: select it ->
   **Plugins** tab -> **Escape Crew** -> **Soften Patch** (this moves his
   skin onto TextureID, so the next step can change it; skip if it says
   there is nothing to soften).
3. **View** -> **Command Bar**. Paste this, put the copied number where it
   says PASTE, press Enter:
   `local id = "rbxassetid://PASTE" local n = 0 for _, d in ipairs(game.ServerStorage.Characters.Muscle:GetDescendants()) do if d:IsA("MeshPart") then d.TextureID = id n += 1 end end print("Muscle: new texture on " .. n .. " parts")`
4. Look at his shoes (zoom in on him in the viewport, or press Play and pick
   Muscle): plain grey and white. If anything else looks wrong, **Ctrl+Z**
   and send me a photo.
5. Right-click **Muscle** -> **Save to Roblox** -> choose **Overwrite** the
   existing `Escape Crew - Muscle` asset (keeps its id, so the Lobby picks it
   up), then **File -> Publish to Roblox**.

## Make each 3D model (as in MESHY_GUIDE.md)

1. **Meshy** -> Image to 3D -> the picture from its folder; the same settings as
   the characters (A-Pose, Triangle, 10,000, Symmetry on, Texture on; no
   Auto-Rig).
2. **Download** (GLB or FBX, textures included) and save it in the game folder
   as `art/models/<model file>` from the table (e.g. `art/models/tinker-pumpkin.glb`).
3. Studio, the **Party House** place: **File -> Import** (or **Avatar** tab ->
   **Import 3D**) -> the file -> **Import**.
4. Select it -> **Avatar** tab -> **Avatar Setup** -> **Body** -> finish. Keep
   the rigged copy (Humanoid, HumanoidRootPart, Head, UpperTorso...), delete
   the plain imported copy.
5. **Explorer** -> drag it into **ServerStorage -> Characters** and rename it
   exactly as in the **Name in Studio** column (e.g. `TinkerPumpkin`).
6. Blotchy face? Stop the game, select the model -> **Plugins** tab ->
   **Escape Crew** -> **Soften Patch**.
7. **Try it** (still in Studio): Play the **Lobby** place -> Characters ->
   Tinker -> Skins row -> **Pumpkin Patch Tinker** (free in Studio). Then Play
   the **Party House**: choose Tinker - the new model, walking and running.

## After the model works

8. **Save it to Roblox** (so the Lobby can show it in 3D): right-click it in
   ServerStorage -> Characters -> **Save to Roblox** -> **Create new asset**,
   Name `Escape Crew - Pumpkin Patch Tinker`, Distribute on Creator Store
   **off** -> **Save**. Toolbox -> **Inventory** -> **My Models** -> right-click
   it -> **Copy Asset ID**. Send me the id (it goes in `Config.CHARACTER_ASSETS`
   under the model's name).
9. **Make the Game Pass**: create.roblox.com -> **Creations** -> **Escape
   Crew** -> **Monetization** -> **Passes** -> **Create a Pass** -> a 512 x 512
   picture (I make it from the art: ask), Name: the skin's name, Description:
   `A new look for Tinker. Looks only - skills stay the same.` -> **Create
   Pass**. Click the pass -> **Sales** -> **Item for Sale** on -> Price **99**
   -> **Save Changes**. Passes list -> **...** on the pass -> **Copy Asset ID**.
   Send me the id (it goes in `Config.SKINS` as `pass = <id>`; until then the
   skin stays hidden in the live game).
10. **File -> Publish to Roblox** in Studio (with Rojo connected; never a
    .rbxlx). Live: the skin button says "(R$)" and opens Roblox's purchase
    window; after buying, "... is yours" and it is worn next game.

If a screen looks different from these steps, send me a photo of it.
