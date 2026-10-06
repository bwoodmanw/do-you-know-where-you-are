# Escape Crew - session handoff

Last updated: 5 Oct 2026, end of the first build session.

## What it is

**Escape Crew** (first called "Do You Know Where You Are?") is a co-operative
horror-escape game on **Roblox** for ages 8+. A party of 1-6 kids is tricked
into a haunted birthday party; they pick characters with skills, solve
puzzles and escape the Party House before the pumpkin-headed host catches
them. Full design: `GAME_DESIGN.md` (sections 0 and 0b record the Roblox move
and progression; later sections describe the parked web version).

- **Roblox experience:** "Escape Crew", owner **Bwoodmanw**.
  - **Escape Crew** = the start place = the **Lobby**. Its name is shared with
    the whole experience: never rename it to "Lobby".
  - **Party House** = the game place. The name must stay exactly `Party House`
    (the Lobby finds it by name).
- **Access:** Public. Reach is **"Ages 16+ and trusted friends"** while
  Roblox's safety review of a new experience runs (no published duration).
  Brent updated the Maturity questionnaire to repeated mild fear ("Mild");
  check it was submitted. Do **not** pay the 50,000 Robux expedited review.
- **Repo:** https://github.com/bwoodmanw/do-you-know-where-you-are (public).
  Folder: `Documents\Kids Games\Do You Know Where You Are`.
- **Parked web version:** https://play.escapecrew.workers.dev/ (Cloudflare
  Worker "play", subdomain "escapecrew", wrangler signed in). Left as is.

## Where things are

```
roblox/
  game.project.json   -> Party House place   (Rojo port 34872)
  lobby.project.json  -> Escape Crew (Lobby)  (Rojo port 34873)
  src/shared/
    Config.luau     numbers, skills (+icons, SKILL_INFO), difficulty, phrases,
                    ROBUX_PRODUCTS (ids, 0 = not on sale), place names
    HouseMap.luau   the Party House layout (30x22 tiles, 6 rooms, objects)
    Progress.luau   maps + unlock order, boosts, levels, the skill ladder (mods)
    Profile.luau    saved profile (DataStore EscapeCrew_Profile_v1) + leaderboards
    Places.luau     finds the Lobby / Party House place ids by name
  src/game/server/
    Main.server.luau  the referee: rounds, prompts, skills, boosts, mods, XP,
                      unlocks, results, play-again vote, teleport to lobby,
                      copies Characters to ReplicatedStorage.Previews
    House.luau      builds the house in 3D from HouseMap
    Host.luau       the host: imported model or built from parts; AI (patrol,
                    hear, see, chase, frenzy), catching
    Characters.luau swaps avatars for imported characters (ServerStorage/Characters)
    Props.luau      places furniture from ServerStorage/Props (31 spots)
    Effects.luau    particle bursts for skills and pickups
  src/game/client/Hud.client.luau   all game screens: character select (3D
                    viewer), top strip, bars, actions, quick chat, keypad,
                    spectate, results + vote, jumpscare + host close-up, mouse look
  src/lobby/server/Lobby.server.luau  lobby scene, parties (friends only),
                    shop (points + Robux receipts), ladder picks, map votes,
                    leaderboard boards, shop stall, teleport with data
  src/lobby/server/LobbyScene.luau  the drop-off scene: shop stall + waving
                    shopkeeper, leaderboard wall, parked cars and benches with
                    Seats (sit, no driving); ServerStorage/LobbyProps can swap in
                    store models named Car / Bench
  src/lobby/client/LobbyUi.client.luau  lobby screens
art/
  sheets/        42 ChatGPT images renamed to their prompt names (characters,
                 hosts, rooms, textures) - the design references
  model-input/   per-character views cut for Meshy (+ Brent's Glow A-pose set)
  models/        glow.glb, host.glb (Meshy output, unrigged, ~8.5k triangles)
  roblox-store/  icon-512.png and thumbnail-1920x1080.jpg (uploaded)
  reference/     code-drawn reference sheets from the web version
ART_PROMPTS.md / .docx   all image prompts (49); tools/make_prompts_docx.js
MESHY_GUIDE.md    sheet -> Meshy -> Studio import -> Avatar Setup -> Characters
FURNITURE.md      Creator Store shopping list for ServerStorage/Props
tools/            preview_glb.py (render a .glb), make_art.py, serve.js, ...
.tools/           rojo.exe 7.7.1, luau-compile/analyze (git-ignored)
```

## Key runtime facts

- **Characters:** a model named e.g. `Glow` in the Party House's
  **ServerStorage/Characters** replaces the avatar of whoever picks Glow
  (Characters.apply; scaled to 5.4 studs; keeps the avatar's Animate script).
  `Host` there replaces the parts-built host (10.5 studs, R15 walk/run
  animations by id). Built with Studio's Import + Avatar Setup.
- **Teleport data** from the Lobby: `{ difficulty, spook, map }`.
- **RoundState** (ReplicatedStorage Configuration) attributes: Spook,
  Difficulty, Map, Status, DoorOpen, CluesLeft, EndsAt, Frenzy, HostOut,
  Known1..3.
- **Player attributes:** Skill, Energy, Shield, Hidden, HideSpot, Caged,
  Escaped, Waiting, Frozen, SneakUntil, CoolUntil (server clock), CandyCharges,
  ProfileJson, and ladder mods StaminaMult, RunMult, SightMult, HoldMult,
  CooldownMult, SneakTime, GlowRange, HealAmount, HealShield, EchoRange.
- **Leaderboards:** OrderedDataStores EC_TopPoints, EC_TopRescues,
  EC_Fast_<map>_<difficulty>_w<week> (stored negative so fastest sorts first).
- **API access** (DataStores) is one experience-wide setting: on.

## Verified so far

- Lobby published; Party House added and published; **Lobby -> Party House
  solo teleport works** in the live game (Brent).
- **Glow imported** (Import -> Avatar Setup -> ServerStorage/Characters/Glow)
  and **works**: picking Glow turns you into her, with the name tag and her
  glowing bulb (Studio screenshot, and live solo).
- Store icon live on the game page; thumbnail Active in Creator Hub (the game
  page was still showing the default when last checked - caching).
- All Luau compiles and passes the analyser; both place files build.

## Not verified yet (written since Brent's last live test)

The new Lobby scene (stall, shopkeeper, board wall, cars, benches - the
Lobby menu, points, stall and boards themselves were seen working live),
camera follow after the character swap (the fix for "mouse can't turn the
camera"), mouse look (M), effects, pickup pop-ups, spectate, play-again /
back-to-lobby vote, the whole progression system (profile, shop, ladder, map
votes, boosts, XP and level-ups, unlocks, leaderboard boards), the 3D
character select screen, furniture placement (no Props imported yet), the
host model in game, and friends joining a party (blocked by the age review).

Added 5 Oct (late), also untested in Roblox: the shop's Take/Taking toggle
answers at once and shows "Next game: ..." (max 2, a third tap explains);
in the game, boosts arrive as a **bag**: Candy, Energy Drink and Extra Clue
are tap-to-use buttons above the action buttons (keys 1 and 2), Shield and
Head Start are automatic ON badges; unused bag boosts carry over on Play
again and go back to the saved boosts when the player leaves. A **corner
map** (N or the Map button) shows rooms as you find them, doorways, the exit
door, you as an arrow and teammates as dots (red = caged).

Added 6 Oct, untested in Roblox: **sounds** (Roblox's licensed library,
ids in `Config.SOUNDS`: balloon pop, hide/unhide, lock pick, unlock, wrong
code, shove, presents, candy crunch, drink gulp, cage, rescue, cheer, skill
sounds, keypad clicks), the host **breathes** (3D, louder when close) and a
**heartbeat** speeds up with the footprints; the **caught close-up** rushes in
until the face fills the screen (lit, red flash, roar or giggle, host holds
still 1.8 s). **Leaderboards:** points earned ever (spending does not lower
it), most escapes, most rescues, fastest escapes this week with map and
difficulty (new board names, so they start empty). Next big build waits for
a yes: `MAP_PLAN.md` (bigger house, locked doors and keys, Tinker no longer
opens the exit).

Built 6 Oct (later), untested in Roblox: **Party House v2** (`MAP_PLAN.md`):
11 rooms on 40x30, two locked inner doors (Library door, Corridor door) -
Tinker picks them, everyone else finds the key hidden at random in one of
12 searchable things; Tinker no longer opens the exit; decoy balloons and
empty presents; hiding spots hold 1 or 2 ("Fits 1/2"), 8 of them, some rooms
none; decorations (flags, pictures, cobwebs, pumpkins, balloon bunches,
rugs); hints name rooms and point at keys; furniture spots redrawn; timers
+2 min. **Host fixes:** placed by its real bounding box (it had been put
half into the ceiling and walked on the roof), sent home if it ever ends up
above the walls, and reaches 4 studs further for kids standing on furniture.
**Shop:** + buys, - sells a points-bought boost back for its full price.
**Edit the layout in `tools/make_housemap.py`, never HouseMap.luau by hand.**

Added 6 Oct (latest), untested in Roblox: **a different house every game.**
Three floor plans (A; B = A mirrored left-right; C = a 3x3 house), one picked
at random each game by `shared/MapGen.luau`, which also scatters the clue
and trick balloons, presents, 11 search spots, 8 hiding places and the
skill puzzles over each plan's checked slots (the plan is sent to screens as
RoundState `MapJson` for the corner map). `tools/make_housemap.py` checks the
plans and replays the picking 500 times per plan; the Luau MapGen was also
run 300 times with `.tools/luau.exe` (no overlaps, all objects placed).
Furniture spots (Props) come with the plan (A and B; C has none yet).
**Opened things look opened:** lids lift, drawers slide out, coats swing,
vases tip, present lids pop off, a gold key floats up where a key is found.
**Close-up:** aims by the host's body direction (the head part's own
direction may be backwards on imports), lasts 2-2.6 s, host frozen 2.8 s.
**No changing character mid-game** (button hidden, server refuses).

**Lobby 3D characters (built 6 Oct, untested):** `Config.CHARACTER_ASSETS`
(name -> model asset id, all 0 until Brent saves them; steps in
MESHY_GUIDE Part 5) loaded with InsertService by `shared/CharacterAssets.luau`
into ReplicatedStorage.Previews in both places (and into the Party House's
ServerStorage/Characters for any character not imported there). The Lobby's
Characters screen has a turnable 3D viewer and the skill description beside
the ladder.

## Brent's to-do list (from the end of this session)

1. **Sync both places with Rojo and publish** (two PowerShell windows,
   commands in `roblox/README.md`), then test and send photos and F9 errors.
2. **Import the host:** `art/models/host.glb` -> Party House, same steps as
   Glow, name it `Host` (steps in `MESHY_GUIDE.md`).
3. Boost icons are made (`art/roblox-store/boost-*-512.png`): upload them
   in Studio's Asset Manager and send the five Image ids for
   `Config.BOOST_IMAGES`; the same pictures go on the Developer Products.
   (Old step:) Make the **5 boost icons** in ChatGPT (prompts in the session chat and in
   `ART_PROMPTS.md`), then the **Developer Products** (Creator Hub ->
   Monetization) and send the product ids. Suggested prices: Candy 25,
   Energy 25, Clue 40, Head Start 50, Shield 60 Robux (not yet confirmed).
4. **Tinker** has no sheet yet; the remaining kids need Meshy models.
   For sharper faces, give Meshy one large front A-pose picture (prompt in
   `MESHY_GUIDE.md`).
5. Add furniture from `FURNITURE.md`.

## Next for Claude, in order

1. **Fix whatever Brent's test shows** (start every session by asking for it).
2. **3D characters in the Lobby** (Brent said yes): the Lobby cannot see the
   Party House's ServerStorage. Plan: Brent right-clicks each finished
   character -> **Save to Roblox** (a model asset he owns); its id goes into a
   new `Config.CHARACTER_ASSETS`; both places load them with
   `InsertService:LoadAsset` into ReplicatedStorage.Previews. Then the Lobby's
   Characters screen gets the same turnable viewer as the game's select screen,
   with the skill ladder beside it. (Alternative: Packages.)
3. **Robux:** put the product ids in `Config.ROBUX_PRODUCTS`; size the boost
   icons to 512x512 (`art/roblox-store/boost-*.png`).
4. **Realistic rooms:** upload the `art/sheets/tex-*.png` textures to Roblox
   and use them as **MaterialVariants** on floors and walls; check the props
   placement with real Creator Store models; wallpaper, wainscot, windows.
5. **Halloween polish (live by 29 Oct):** sounds (Roblox audio library:
   footsteps, heartbeat, stinger, pop, cheer), the uploaded jumpscare image
   (`Config.IMAGES.scare`), the first-game tutorial on Roblox, more rooms
   dressed, balancing the host per difficulty.
6. **November:** the Gummy Bounce House map (art ready in `art/sheets/`),
   then the Hospital. Maps unlock in order (Progress.MAPS); a map needs its
   own HouseMap-style layout, puzzles and host.

## Open decisions

- Robux prices (suggestion above).
- Lobby 3D models: Save to Roblox + InsertService (recommended) or Packages.
- Whether "time's up" should stay a frenzy or end the round.

## Lessons from this session

- **Don't rename the start place** - it renames the experience.
- **Add a place:** File -> Publish to Roblox As -> the experience tile ->
  "Add as a new place". Asset Manager's Places view was not obvious in this
  Studio version.
- **Max players:** File -> Experience Settings -> Places -> the place's "..."
  -> Configure Place.
- **Import:** File -> Import (the 3D importer). Rig Type: No Rig; Avatar
  Setup adds the R15 rig. Its "4 Warnings" (dynamic head expressions) only
  matter for selling on the Avatar Marketplace - ignore them.
- **Teleports, invites and returning to the lobby only work in the published
  game**, never in a Studio test.
- **New experiences start at "Ages 16+ and trusted friends"** until Roblox's
  review; an inaccurate questionnaire gets rejected and restarts the review.
- **Swapping a player's character can leave the camera on the old avatar:**
  the client re-attaches it on CharacterAdded.
- **Glow's face is ~60 pixels wide in her 1024x1024 texture** (checked 5 Oct):
  Meshy gives the face a tiny patch of one texture, and Roblox caps a
  texture at 1024. A bigger input picture helps detail inside that patch;
  Tried without Blender (`tools/face_boost.py` re-lays the texture so the
  head gets ~40% of it; `tools/face_render.py` renders the face as Roblox
  would): the Host's face gained 1.7x the pixels but looks almost the same,
  and Glow none (her texture is only 1024) - see
  `art/reference/face-check/`. **The limit is how blurry Meshy's own texture
  is, not Roblox's 1024 cap.** Sharper faces need a sharper source: Meshy at
  its highest texture setting from a big front picture (what made the Host
  good), or projecting a high-res face portrait onto the head (not built).
- **The imported Host works live** (5 Oct, Brent: "Host is awesome"); raised
  from 10.5 to 12 studs at his ask (rooms are 14).
- **Soft faces on Meshy models come from small input pictures** (Glow's were
  ~485x821). Use one big front picture.
- **Rojo started from Claude's shell dies after 2 hours;** Brent runs it in
  his own PowerShell. `npx` is blocked by PowerShell's script policy - use
  `npx.cmd`. The app's Terminal panel did not start (missing integration
  script).
- AI images: check sneakers and clothes for real brand logos before upload.
- **Rojo's Studio panel remembers the last port.** Lobby = `lobby.project.json`
  on **34873**; Party House = `game.project.json` on **34872**. Set the port in
  the Rojo panel before Connect, and check ServerScriptService/Server (Lobby has
  one script `Lobby` (+ LobbyScene); Party House has Main, Characters, Effects,
  Host, House, Props) before publishing. Both places were once synced with the
  wrong project this way; it was caught before publishing.
- **Rojo is now locked to the right place** (6 Oct): `servePlaceIds` in each
  project file (Party House 110069561824739, Escape Crew/Lobby
  115501124890066) makes Rojo refuse to connect to the wrong place, and
  Main/Lobby scripts warn "WRONG PLACE" in F9 and stop if they ever land in
  the other place (`Config.PLACE_IDS`).
- **"Failed to fetch place info" in Studio:** log out, close Studio fully,
  log back in (a known Roblox issue).
