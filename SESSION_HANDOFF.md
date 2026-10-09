# Escape Crew - session handoff

Last updated: 9 Oct 2026, end of the fifth session (very long: School map
cards and its host, buildings 5 and 6, three new hosts, the Halloween
event, skills version 2 with levels to 20, many play-test fixes). Latest
commits on `main`. **Both places were published 8 Oct (late) with
everything up to commit 38a5814**; later commits (the room name in the top
bar, the last four badge ids) need one more publish of both places.

**Session 6 (9 Oct), so far:** Brent's first live-test fixes (1b0954c) and
effects step 1, the levels line, animation packs (`Config.ANIM`), American
room names and real gummy bears (26bd316) - TEST_PLAN rounds 36-37, all
untested. Party House needs a publish for these; the Lobby only for the
8 Oct items. Then (Brent published to c19d86d): Echo's idle fix (50efcb3), the Plushie Book (4ae092b, badge id still 0), emotes + rumble (521bfcd), the escape photo (d8d6f6e), the invite reward (f67e89e), the Halloween Roblox Event picture + EVENTS.md (916fb86) - TEST_PLAN rounds 38-41. Open: which character Brent was at the Bramble plant; the plushie badge id; the Halloween event page.

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
  **Private servers on (100 Robux - changing the price cancels
  subscriptions); automatic translation on; notifications set up** (8 Oct).
- **Repo:** https://github.com/bwoodmanw/do-you-know-where-you-are (public:
  no recognisable film/cartoon/game characters or brand logos, even in AI art).
- **American English** in everything players read (color, gray, closet...).
- **Parked:** the web version (`src/`, `public/`, Cloudflare Worker),
  Experience Subscriptions, B8 analytics.

## The game today

- **6 buildings, 18 floors + a secret one** (each unlocked by escaping floor
  2 of the one before): Party House (Ground, Bedrooms, Attic, + the Secret
  Basement), Gummy Bounce House, Abandoned Hospital, Midnight School
  (`SCHOOL.md`), **Creepy Carnival** (Midway, Big Top, Funhouse;
  `CARNIVAL.md`), **Sunken Aquarium** (Main Hall, Deep Sea, Rooftop Pools;
  `AQUARIUM.md`). Each floor has 2 plans (a mirror), each checked with
  2,000 random fills (39 plans). The Aquarium is built on the Carnival's
  room grids with its own rooms and look.
- **6 hosts**, each a building's own (half the time) and visiting the
  others: Pumpkin (throw), Gummy Bear Man (sticky puddles), Robot
  (blackout), **the Caretaker** (School; Lock-up: padlocks a doorway ahead
  of a kid, Tinker picks it), **the Clown Bear** (Carnival;
  Jack-in-the-Box: boxes on random spots spring when a kid comes near),
  **the Anglerfish Keeper** (Aquarium; Fake Treasure: fake presents,
  Brainy / Glow pop them; the game adds his glowing lure).
- **Set pieces:** carousel and spinning floor (carry you round), mirror
  maze, human cannon / twisty slide / water pipe (the chute, one per
  floor), bounce pads, glass Shark Tunnel, great tank with a shark, dark
  Deep Sea rooms, wading water and chocolate, whirlpool.
- **8 characters, skills version 2** (`SKILLS_V2.md`): every character has
  a button (R on a computer): Tinker Toolkit, Shadow Sneak, Brainy Think!,
  Muscle Barricade / Ground Pound, Glow Flare (lifts friends near her),
  Patch Shield, Echo Noise (+ her own burst), Bramble Vines. **Levels 1-20**
  (XP to 78,500); big powers at 10 and 20; guard rails on stuns
  (`Config.SKILL_STUN`). Each button counts down while it works, then its
  recharge (Shadow's recharge starts after the sneak).
  `tools/check_ladder.luau` and `tools/check_ladder_repeats.luau` check the
  ladders (no repeated picks).
- **Halloween:** Candy Corn Hunt (6 corns a floor until 1 Nov, badge at 50
  found), **Candy Shop** in the Lobby (boosts for corns, open until 8 Nov),
  **Muscle Mummy** skin bought for 100 corns on hand.
- **Screens:** bigger map (bottom left) with icons (locks, junk, cage,
  exit), stamina / points / building above it, the room you're in at the
  top left; countdown effects at 1:00 / 0:30 / 0:10; FRENZY at 0:00 (all
  building lights red, "TIME'S UP"); quick chat with pins (T); Invisicam
  camera that stops at walls.
- **Engagement:** daily reward (boost pictures), daily + weekly quests,
  friends bonus, 14 badges (all ids in), favorites prompt, Quick Play,
  rejoin, clue log, controller support, notifications.
- **Money:** boosts and Skill Reset (Developer Products), 8 skins (Game
  Passes, 99 Robux), private servers. The owner wears every skin free.
- **Owner-only test tools** (live: only Bwoodmanw): Lobby -> Characters ->
  🧪 Lv 1/5/10/15/20 (sets a character's XP - set it back after testing),
  🎁 Gift (corns / points to players in the Lobby).

## Where things are

```
roblox/
  game.project.json   -> Party House (Rojo port 34872, servePlaceIds locked)
  lobby.project.json  -> Escape Crew / Lobby (Rojo port 34873, locked)
  src/shared/
    Config.luau       every number and id (HOSTS / HOST_SKILLS, BUILDING_HOST,
                      COOLDOWN, GLOW_FLARE, ECHO_BURST, VINES, CLONE, SKILL_STUN,
                      CHARACTER_ASSETS, SKINS, MAP_IMAGES, BADGES, EVENT (hunt +
                      shop + gifts), MUSIC, NOTIFY, STUDIO_MAP / STUDIO_HOST)
    HouseMap.luau     GENERATED by tools/make_housemap.py - never edit by hand
    MapGen.luau       each game: picks a plan, scatters objects (floorSlots too)
    Progress.luau     MAPS, BUILDINGS, boosts, LEVEL_XP (20), the skill ladders
    Profile.luau      saved profile (stats.corn / cornSpent / cornGift,
                      skinsEarned), leaderboards
    Quests, Gamepad, ModelBounds, PreviewPose, CharacterAssets, MusicPlayer, ...
  src/game/server/
    Main.server.luau  the referee: rounds, skills (skillV2 / skillAfter,
                      skillStun), host powers (Lock-up, Jack-in-the-Box, Fake
                      Treasure), candy corns, Frenzy, votes, rejoin, badges
    House.luau        builds the floor (themes party/gummy/hospital/school/
                      carnival/aquarium; carousel/spinner/whirlpool spin())
    Rooms.luau        dresses rooms by name (LOOKS, PIECES), chutes, windows
    Host.luau         host AI (vines, wading, stuck hop that never crosses doors)
  src/game/client/Hud.client.luau  game screens (top level ~138 locals: wrap
                      new code in do ... end); camera keeper at the end
  src/lobby/server/Lobby.server.luau  parties, Quick Play, shops (points, Candy
                      Shop), skins, owner tools, daily reward, notifications
  src/lobby/client/LobbyUi.client.luau
tools/  make_housemap.py (plans; run in the background), check_rooms.luau,
        check_ladder.luau, check_ladder_repeats.luau, count_locals.py,
        make_badge.py, make_corn_badge.py, make_pass_icons.py, preview_glb.py,
        face_render.py, face_boost.py
art/roblox-store/  badges/, maps/, passes/, portraits/
art/model-input/<name>/a-pose-front.png   art/models/  (Meshy .glb)
```

Docs: `SKILLS_V2.md`, `CARNIVAL.md`, `AQUARIUM.md`, `SCHOOL.md`, `SKINS.md`,
`PASSES.md`, `NOTIFICATIONS.md`, `MESHY_GUIDE.md`, `TEST_PLAN.md` (rounds
12-35, newest first, none fully play-tested yet), `ROADMAP.md`,
`NEXT_SESSION_PROMPT.md`.

## What Brent has in Roblox (not in the repo)

- **Party House ServerStorage/Characters:** characters, skins and hosts
  (Host, HostGummy, HostRobot, HostCaretaker, HostClownBear,
  HostAnglerfish). Saved ids in `Config.CHARACTER_ASSETS` (new 8 Oct:
  ShadowGhost and Echo remade in A-pose, MuscleMummy, the three hosts).
  The Party House uses its own ServerStorage copy first; the Lobby always
  loads the saved copy. Old `EchoOld` / `ShadowGhostOld` copies can go.
- ServerStorage/Props (the Generator's bad Sound deleted 8 Oct),
  Lobby ServerStorage/LobbyProps/House.
- Developer Products, 8 skin Game Passes, 14 badges, uploaded images (boosts,
  map cards for all 6 buildings + the Basement, portraits, pass pictures,
  the Muscle Mummy icon), songs (2 added 8 Oct), notification string,
  Open Cloud key + Secret `notifications`.
- **Never publish a .rbxlx over a live place** - it wipes all of the above.
  Code goes in with Rojo; publish from Studio (File -> Publish to Roblox).

## Verified

- Every change: `luau-compile --null -g2`, `luau-analyze` (no new
  warnings), both places build; plans: 39 x 2,000 fills and
  `check_rooms.luau`; ladders: `check_ladder.luau` (two choices at every
  level, inside the caps) and `check_ladder_repeats.luau` (no repeats).
- Every id on Roblox's public API (models, images, badges, songs).
- Brent's Studio / live tests this session: the notifications prompt shows;
  shops, skins, map cards; fixes made after his reports (Toolkit, map,
  camera twice, vote, peppermint icons, swings, host through junk).
  **Not yet play-tested:** most of TEST_PLAN rounds 12-35, especially the
  new hosts' powers, skills version 2, Frenzy and the countdown.

## Open items and decisions waiting on Brent

1. **Publish both places once more** (the top-bar room name and the last 4
   badge ids came after the 8 Oct publish).
2. **Play-test live** TEST_PLAN rounds 12-35 (photos + F9 Client/Server).
   Two-player checks: Back to lobby (only you leave), Glow's Flare / Beacon,
   quick-chat pins, rejoin. Does the daily-reward notification arrive?
3. **Seasonal:** from 1 Nov upload the normal `icon-512.png` again (Creator
   Hub -> Icon). The hunt and the Candy Shop end by themselves (1 Nov /
   8 Nov).
4. **Host balance:** after a week live, read the 📊 Balance table and tune
   toward 70 / 50 / 35 / 20% wins on Easy / Normal / Hard / Nightmare (Glow's
   Beacon is the strongest new power to watch).
5. **Decisions still open:** Lantern (Glow level 17: keep Warm Glow -
   recommended); the Aquarium's room grids (keep - recommended).
6. **Next builds (Brent's ideas):** Thanksgiving and Christmas events (a
   secret seasonal floor; a community-wide goal); the collectibles book;
   the community group bonus; translation fixes after a week of data.

## Lessons (keep)

- Don't rename the start place. Teleports, invites, Game Pass purchases and
  private servers only work live.
- Rojo: Lobby = 34873, Party House = 34872; locked to their place ids.
  Rojo started from Claude's shell dies after a few hours (exit code 4):
  restart it and reconnect the Studio plugin.
- **Patch scripts:** write them with the Write tool (a bash heredoc eats
  `\u{...}` and regex backslashes), assert every anchor, `.tmp` +
  `os.replace`, normalize paths (one file listed twice broke a patch).
  Player text is American now - anchors must say "color", not "colour".
- **Roblox shapes:** a Ball part is always a sphere (a stretched size is squashed round) - use `Shapes.fix` (block + sphere mesh) for eggs and ovals; a Cylinder's Y and Z (the round sides) are forced equal, and its height is X (upright with `rot = UP`: size = (height, diameter, diameter)).
- Don't blindly drop every "Unknown global" from luau-analyze: list the names and check none is ours (9 Oct: `Config` used in Characters.luau without a top-level require).
- A local used inside a function must be declared above it (twice a new
  block went above `clueSteps` / `selected`).
- Studio compiles at debug level 2: `luau-compile --null -g2`;
  `tools/count_locals.py` (Studio stops at 200 top-level locals).
- **Imported characters:** never move their parts by hand; play an
  animation. **Make every model in an A-pose** (T-posed ones look
  short-armed in Roblox). Headphones round the neck broke Avatar Setup
  (remesh in Meshy fixed it). Keep faces clear of big hats and goggles.
- The word filter hides some asset names ("####") - harmless.
- There is no candy-corn emoji (Unicode's "candy" is a wrapped sweet): use
  the Candy Corn boost picture.
- Look at every picture and model before using it (logos, known
  characters; AI added wine bottles once).
- Ladder "hold" picks reach the 0.5 cap early: big powers must do something
  new (instant, a stun, a lift), not "x2 hold".
- A skill's recharge must start when its effect ends if the effect can be
  longer than the recharge (Shadow could stay hidden forever).
