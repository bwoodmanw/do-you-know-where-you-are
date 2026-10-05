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

Camera follow after the character swap (the fix for "mouse can't turn the
camera"), mouse look (M), effects, pickup pop-ups, spectate, play-again /
back-to-lobby vote, the whole progression system (profile, shop, ladder, map
votes, boosts, XP and level-ups, unlocks, leaderboard boards), the 3D
character select screen, furniture placement (no Props imported yet), the
host model in game, and friends joining a party (blocked by the age review).

## Brent's to-do list (from the end of this session)

1. **Sync both places with Rojo and publish** (two PowerShell windows,
   commands in `roblox/README.md`), then test and send photos and F9 errors.
2. **Import the host:** `art/models/host.glb` -> Party House, same steps as
   Glow, name it `Host` (steps in `MESHY_GUIDE.md`).
3. Make the **5 boost icons** in ChatGPT (prompts in the session chat and in
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
- **Soft faces on Meshy models come from small input pictures** (Glow's were
  ~485x821). Use one big front picture.
- **Rojo started from Claude's shell dies after 2 hours;** Brent runs it in
  his own PowerShell. `npx` is blocked by PowerShell's script policy - use
  `npx.cmd`. The app's Terminal panel did not start (missing integration
  script).
- AI images: check sneakers and clothes for real brand logos before upload.
