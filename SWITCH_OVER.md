# Toon switch-over (11 Oct 2026)

Every toon is painted with its side pictures and passes
`tools/check_toon_models.py` (ALL GOOD). This puts them in the game for
everyone: each toon takes the old model's name in Party House
ServerStorage -> Characters, the old one moves to CharactersOld (nothing is
deleted, so any one can be switched back), and each is saved to Roblox so the
Lobby's 3D characters load it by id (`Config.CHARACTER_ASSETS`).

Close nothing; Rojo stays connected. Party House place.

## Once, first

1. Explorer -> right-click **ServerStorage** -> **Insert Object** -> **Folder**
   -> name it `CharactersOld`. Do it again for `CharactersRaw` (skip any that
   already exist).
2. Open **ServerStorage -> Characters**. Drag every model whose name is
   lowercase or has a dash (`shadow`, `tinker`, `host-gummy`...) into
   **CharactersRaw** - Studio matches names regardless of capitals, so
   these leftovers can stand in for the real characters.
3. Drag every old `...Toon` model (`TinkerToon`, `PatchToon`, ...) into
   CharactersRaw too - they are older paintings. **Except `EchoToon`** (the
   one you just approved and saved).

## For each model in the table

1. Drag the OLD model with that name (e.g. `Tinker`) from **Characters** into
   **CharactersOld**.
2. **Avatar** tab -> **Import 3D** -> the file -> **Open** -> **Import**
   (default settings). Wait for the colors.
3. Select the import -> **Avatar** tab -> **Avatar Setup** -> **Body** ->
   finish (OK on dynamic-head warnings). Keep **Platform Avatar**.
4. Check it has **Head, UpperTorso...** (about 15 parts); delete the
   single-mesh import.
5. Rename it to the **Studio name** in the table and drag it into
   **Characters**.
6. Right-click it -> **Save to Roblox...** -> save as a new model -> send
   Claude the id (as you did for Echo: 88227116066224).

Echo: only steps 1 and 5 - drag the old `Echo` to CharactersOld and rename
`EchoToon` to `Echo` (its id is already in).

Send the ids in batches (e.g. after every 4). Claude puts them into
`Config.CHARACTER_ASSETS` and empties `Config.STUDIO_TRY_MODEL`.

| # | File (`art/models/`) | Studio name | Notes |
|---|---|---|---|
| 1 | echo-toon.glb | Echo | rename only (above) |
| 2 | patch-toon.glb | Patch | |
| 3 | tinker-toon.glb | Tinker | |
| 4 | brainy-toon.glb | Brainy | propeller is added by the game |
| 5 | shadow-toon.glb | Shadow | |
| 6 | muscle-toon.glb | Muscle | |
| 7 | glow-toon.glb | Glow | |
| 8 | bramble-toon.glb | Bramble | |
| 9 | halloween-nurse-patch-toon.glb | PatchHalloween | |
| 10 | tinker-pumpkin-toon.glb | TinkerPumpkin | |
| 11 | ghostly-shadow-toon.glb | ShadowGhost | |
| 12 | candy-glow-toon.glb | GlowCandy | |
| 13 | space-cadet-brainy-toon.glb | BrainySpace | |
| 14 | snow-day-muscle-toon.glb | MuscleSnow | |
| 15 | starlight-echo-toon.glb | EchoStar | NEW model: headphones on her ears |
| 16 | autumn-leaf-bramble-toon.glb | BrambleAutumn | |
| 17 | muscle-mummy-toon.glb | MuscleMummy | |
| 18 | host-toon.glb | Host | |
| 19 | host-gummy-toon.glb | HostGummy | |
| 20 | host-hospital-toon.glb | HostRobot | wheels: if Avatar Setup refuses, photo + keep the old |
| 21 | host-caretaker-toon.glb | HostCaretaker | mop lump: photo, judge |
| 22 | host-clownbear-toon.glb | HostClownBear | |
| 23 | host-anglerfish-toon.glb | HostAnglerfish | the lure on its stalk may be missing (lost by the model maker): photo |

The Thanksgiving models (Chef Brainy, Gobble Shadow, Pie Baker Patch,
Harvest Glow, Scarecrow Tinker, Gridiron Muscle, Feast DJ Echo, Cozy Cocoa
Echo, Acorn Bramble, the Gobbler, the turkey) are imported later, with the
Thanksgiving build (step 3) - their names come with that code.

## Photos to send

- Any import Avatar Setup refuses (a photo of the message).
- The Robot, the Caretaker and the Anglerfish in the Avatar Setup preview.
- One Play test as Patch and one as Starlight Echo, a face photo each, plus
  any red lines in **View -> Output**. (Studio plays plain characters
  whatever skin you wear - `Config.STUDIO_NO_SKINS`; Claude turns that off
  when you're ready to test the skins.)
