# Escape Crew - session handoff

Last updated: 10 Oct 2026, end of the seventh session (long: the skill-ladder
fix A/B/C, the Lobby Characters screen with Skills / Skins windows, a sound
audit, and the **toon model upgrade** - new cartoon models for all 8
characters, 9 skins and (in progress) 6 hosts, made on Brent's PC with Stable
Fast 3D and repainted by our own tools). Latest commits on `main`. **Brent
last published both places some time after 0264fb7 (exact commit not
recorded); nothing from this session is published. Hold publishing until the
toon switch-over is done (below).**

## What it is

**Escape Crew** is a co-operative horror-escape game on **Roblox** for ages 8+.
A party of 1-6 kids picks characters with skills and escapes one floor of a
haunted building before a host catches them. Each escape unlocks the next
floor. Design: `GAME_DESIGN.md` (sections 0 and 0b); the build plan and what
is done: `ROADMAP.md`; floor-plan rules: `MAP_PLAN.md`.

- **Experience:** "Escape Crew", owner **Bwoodmanw**, universe 10769485212.
  - **Escape Crew** = the start place = the **Lobby** (place 115501124890066).
    Its name is the experience's name: **never rename it**.
  - **Party House** = the game place (place 110069561824739). The name must
    stay exactly `Party House`.
- **Access:** Public, "Ages 16+ and trusted friends" while Roblox's review
  runs. Do **not** pay the 50,000 Robux expedited review. Console ticked.
  Private servers on (100 Robux), automatic translation on, notifications,
  Halloween Roblox Event page live (`EVENTS.md`).
- **Repo:** https://github.com/bwoodmanw/do-you-know-where-you-are (public:
  no recognisable film/cartoon/game characters or brand logos, even in AI art
  - this session caught a swoosh, three stripes and a famous sneaker colorway
  in AI pictures).
- **American English** in everything players read.
- **Parked:** the web version (`src/`, `public/`, Cloudflare Worker),
  Experience Subscriptions, B8 analytics.

## The game today

- **6 buildings, 18 floors + a secret one**, 39 floor plans (2,000 fills each).
- **6 hosts**, **8 characters, skills version 2**, levels 1-20.
- **Skill ladder (this session, LADDER_FIX.md):** A - powers no longer wipe
  out earlier picks (Fortress = two barricades, Guardian Angel = two shields,
  Iron Lungs = stamina refills 2x, Rocket Boots = a run after each Toolkit,
  Brainy's 11/17 = Long/Deep Think); sneak / clone / light / flare / throw /
  burst / vines / barricade picks add up (`Progress.ADDS`). B - each
  character's own picks fit under the limits (no character run picks).
  C - one free Skill Reset per character (`Config.FREE_RESET`).
  `tools/check_ladder_waste.luau` says "OK: no pick is ever wasted". Shadow's
  speed and "Glow fastest": both closed by Brent.
- **Lobby Characters screen (this session):** the description under the
  level bar (each button on its own line: Toolkit:, Sneak:, Think!:...), two
  buttons - **Skills** (blue, orange when upgrades wait) and **Skins**
  (magenta, worn skin's picture) - each opening its own window (ladder +
  resets; picture tiles from the Game Pass pictures); a red X on the screen.
  Owner buttons (Balance / Gift) sit above the Candy Corn banner.
- **Sounds (this session):** pickups ding (collected), Candy Corn munches,
  Second Wind gulps, plushies squeak, shield thumps, the stunned host bonks,
  light switches click (5 new library sounds in `Config.SOUNDS`).
- **Wall fish / jelly tanks** are solid.
- Everything earlier (effects, plushies, loot, parties, look, icons, posters,
  emotes, invite reward, Halloween) as before.

## The toon model upgrade (in progress - the main thing to finish)

New cartoon models replace the old ones. All files are in the repo; the
recipe is **`TOON_WORKFLOW.md`** (Brent's ChatGPT workflows, copy-paste).

1. **Pictures** (ChatGPT, workflow 1): `art/model-input/<name>/front-toon.png`
   and `back-toon.png`. Done and checked for all 8 characters, 9 skins
   (incl. Halloween Nurse Patch) and 6 hosts. Patch's look changed on purpose
   (blonde, blue eyes, jeans - Brent); her portrait and Halloween Nurse pass
   picture were remade.
2. **Models** (`tools/make_toon_models.py`, Stable Fast 3D on Brent's RTX
   4050 - close Studio first, it needs all 6 GB): `art/models/<name>-toon.glb`.
   Done for the 8 characters and 9 skins; **hosts next** (Brent runs hosts
   workflow 2).
3. **Painting** (`tools/paint_toon.py`, runs automatically after each model):
   front colors corrected from the front picture (Stable Fast 3D washes them
   out), the back painted from the back picture (it guesses the back), seams
   padded, the model turned to face +Z (imports facing forward - no World
   Forward change), **the face given its own sharp 256x256 corner of the
   texture from the approved picture** (Stable Fast 3D gave each face only
   ~50 px; not for hosts), and - fixed last - **the surface normals kept**
   (they were dropped; Studio then welded seam points and broke the texture:
   face lines, smudges, Patch's striped legs). The unpainted originals are
   kept as `<name>-toon-raw.glb`. Brainy's propeller (lost by Stable Fast 3D)
   is built from parts in the game (`shared/Propeller.luau`).
4. **Studio import** (Brent): Import 3D (default settings) -> wait for
   colors -> Avatar Setup -> Body -> name `<Name>Toon` -> ServerStorage ->
   Characters. **Every toon imported before commit 3c59e29 must be
   re-imported** (no normals). Test in Play; Studio's Output names the model
   worn (`[Characters] ... is now wearing ...`). `Config.STUDIO_TRY_MODEL`
   plays each toon for the owner (Studio + live; hosts Studio only);
   `Config.STUDIO_NO_SKINS` = Studio ignores the worn skin.
5. **Switch-over** (per model, once it looks right): old model ->
   ServerStorage -> CharactersOld; rename the toon to the old name; right-click
   -> Save to Roblox -> the id into `Config.CHARACTER_ASSETS` (the Lobby loads
   its 3D characters from these ids). Ids so far: Patch 82716883621716 (saved
   before the normals fix - re-save), Echo 138682489420791 and Bramble
   115700894998579 (old blurry saves - re-save), Halloween Nurse
   108839284344455 (old - re-save).
6. **Open:** test plain Patch first (re-import after 3c59e29: photos in
   Avatar Setup and in game); if clean, re-import all; Characters cleanup
   (leftover plain imports named `shadow`, `tinker`, `host-gummy`... count as
   the real characters - case-insensitive - move them to CharactersRaw with
   the Command Bar line in this session's notes / below); hosts workflow 2
   and imports (the Robot has wheels - Avatar Setup may refuse him); Echo
   plain idle (`Config.ANIM.plainIdle`) not needed for A-pose toons; Muscle
   Mummy's zombie walk carries to its toon; `Config.FACES` / `Faces.luau`
   (a face laid on the head) is OFF - the head's SurfaceAppearance hid it.

Command Bar line - move plain imports out of Characters:

```
local f=game.ServerStorage.Characters local raw=game.ServerStorage:FindFirstChild("CharactersRaw") or Instance.new("Folder") raw.Name="CharactersRaw" raw.Parent=game.ServerStorage for _,m in ipairs(f:GetChildren()) do if not m:FindFirstChildWhichIsA("Humanoid",true) then m.Parent=raw print("moved to CharactersRaw (no Humanoid):",m.Name) end end print("Characters now:",#f:GetChildren(),"models")
```

## Where things are

```
roblox/
  game.project.json   -> Party House (Rojo port 34872, servePlaceIds locked)
  lobby.project.json  -> Escape Crew / Lobby (Rojo port 34873, locked)
  src/shared/
    Config.luau       every number and id (CHARACTER_ASSETS, STUDIO_TRY_MODEL,
                      STUDIO_NO_SKINS, PROPELLER, FACES (off), FREE_RESET,
                      SOUNDS, PORTRAITS, ...)
    Progress.luau     the ladder (ADDS, CAPS)   Propeller.luau  Faces.luau
    CharacterAssets.luau  Lobby / previews load saved models (strips
                      scripts and FaceControls)
  src/game/server/
    Main.server.luau  the referee (modelFor / tryModel)
    Characters.luau   puts models on players: checks joints (Motor6D and
                      AnimationConstraint rigs), quick-death report, Studio
                      "[Characters]" messages, host test models
    Effects.luau (burst/at take an optional sound)  Rooms.luau  House.luau
  src/game/client/Hud.client.luau  (top level 140 locals)
  src/lobby/client/LobbyUi.client.luau  (top level 129 locals)
tools/  make_toon_models.py, paint_toon.py, make_face.py (unused now),
        check_ladder*.luau (incl. check_ladder_waste), preview_glb.py, ...
art/model-input/<name>/front-toon.png, back-toon.png   art/models/*-toon.glb
art/faces/echo-face.png (from the off approach)
```

Docs: `TOON_WORKFLOW.md` (the whole model recipe, skins and hosts
workflows), `LADDER_FIX.md`, `TEST_PLAN.md` (rounds 12-61), `ROADMAP.md`,
`STYLE_UPGRADE.md`, `EVENTS.md`, `SKILLS_V2.md`, `NEXT_SESSION_PROMPT.md`.
Brent's agent copies: `CORE_TOON_MODEL_WORKFLOW.md`,
`SKIN_TOON_PICTURE_WORKFLOW.md`, `HOST_TOON_PICTURE_WORKFLOW.md`.

## What Brent has in Roblox (not in the repo)

- Party House ServerStorage/Characters (old characters, skins, hosts, toons
  being tested, leftovers - see cleanup), CharactersOld (to make),
  ServerStorage/Props, Lobby ServerStorage/LobbyProps/House.
- Developer Products, 8 skin Game Passes, 15 badges, uploaded images (incl.
  Patch's new portrait 91991148472934, echo-face 135489459825461), songs,
  notifications, the Halloween Event page.
- **Never publish a .rbxlx over a live place.** Code goes in with Rojo.

## Verified this session

- Every Luau change: `-g2` compile, analyzer warning counts unchanged (unknown
  globals only Roblox built-ins), top-level locals checked; both places
  rebuilt; ladder checks (LADDER OK, NO REPEATS, no wasted picks).
- Every AI picture looked at (logos, look-alikes, A-pose, front/back match);
  every model rendered front / back / side after painting; every id checked
  on Roblox's public API.
- In Studio by Brent: the Skins / Skills windows, the X, the sharp faces
  arriving (eyes), the toons wearing (Output). **Not yet:** a clean face and
  body after the normals fix; ladder A/B/C, sounds, tanks, free reset in play
  (TEST_PLAN 55-61).

## Decisions waiting on Brent

1. After Patch's re-import: do the faces / legs look right? (then re-import
   all).
2. Hosts: run workflow 2, import; if Avatar Setup refuses the wheeled Robot,
   keep the old Robot or have a legged robot?
3. Ghostly Shadow's back-of-pants patches / Starlight Echo's muddy jacket
   front: fine-tune or leave (judge in Studio).
4. Publish both places once the switch-overs are done (both, together).
5. Still from earlier: host balance from the 📊 Balance table (from ~15 Oct),
   translation fixes, Thanksgiving event ideas (after 1 Nov; event page 7+
   days ahead), community group bonus, store icon back to `icon-512.png`
   from 1 Nov.

## Lessons (keep)

- Don't rename the start place. Teleports, invites, purchases, parties and
  private servers only work live.
- Rojo: Lobby = 34873, Party House = 34872. Rojo started from Claude's shell
  dies after a few hours (it did overnight): restart it.
- **Patch scripts:** Write tool, never a bash heredoc for text with `\u{}` or
  backslashes; and never backticks inside a double-quoted `python -c` (bash
  runs them - it blanked a doc line). Assert anchors; `.tmp` + `os.replace`
  with a retry (OneDrive / Rojo lock files briefly).
- **Model files for Roblox must keep NORMAL** in the glb, or Studio welds
  seam points and the texture breaks along every seam.
- **...and no two points at the same spot may share a normal** (11 Oct):
  Studio welds same-spot same-normal points and keeps one UV. The face
  corner's copies had their twin's exact normal - brown smudges on Patch's
  jaw and chin in game while the file rendered clean. `paint_toon` now
  splits them 5+ deg apart and drops unused points; the checker reads the
  STORED normals (trimesh recomputes them) and fails any such pair.
  `tools/preview_glb.py` drew every view from the wrong side until 4784acb.
- **Avatar Setup** adds a face rig (FaceControls - stripped by our code), may
  join parts with AnimationConstraints instead of Motor6Ds (our joint check
  accepts both), and puts a SurfaceAppearance on parts (it hides Decals /
  Textures laid on top; the running game can't read its ColorMap).
- New uploads show nothing until Roblox's review finishes ("Pending" on the
  thumbnails API) - check before debugging.
- Stable Fast 3D: one picture in (the front), faces get ~50 px, thin parts get
  lost (propellers, antenna bulbs), needs all of the 6 GB GPU (crash code
  3221225477 = close Studio). Models face -Z; Roblox wants +Z.
- A name in ServerStorage/Characters matches regardless of capitals - leftover
  imports can stand in for real characters.
- Look at every picture and model before using it; give Brent one ChatGPT
  workflow prompt in his format for any batch of pictures.
