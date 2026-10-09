# Escape Crew - session handoff

Last updated: 10 Oct 2026, end of the sixth session (very long: Brent's
live-test fixes, effects, animation packs, the Plushie Book, emotes, rumble,
escape photo, invite reward, an object audit and the round-ball shape bug,
random loot, the new look - lighting, the Lobby tile screen, our own icons,
posters, clean menus in Lobby and game - and party fixes). Latest commits on
`main` (f5e82f0 and later). **Brent last published both places some time
after 0264fb7 (exact commit not recorded - ask); publish both again to be
sure everything to the latest commit is live.**

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
  Private servers on (100 Robux), automatic translation on, notifications set
  up (8 Oct). **Halloween Roblox Event page live** (9 Oct, `EVENTS.md`).
- **Repo:** https://github.com/bwoodmanw/do-you-know-where-you-are (public:
  no recognisable film/cartoon/game characters or brand logos, even in AI art).
- **American English** in everything players read (color, gray, closet...).
- **Parked:** the web version (`src/`, `public/`, Cloudflare Worker),
  Experience Subscriptions, B8 analytics.

## The game today

- **6 buildings, 18 floors + a secret one**: Party House (Ground, Bedrooms,
  Attic, Secret Basement), Gummy Bounce House, Abandoned Hospital, Midnight
  School, Creepy Carnival, Sunken Aquarium. 39 floor plans, each checked with
  2,000 random fills. Room names American (Parlor, Elevator Lobby, Teachers'
  Lounge...).
- **6 hosts** (Pumpkin, Gummy Bear Man, Robot, Caretaker, Clown Bear,
  Anglerfish Keeper), each with a power; **animation packs** per host and
  kid (`Config.ANIM`; Shadow and Brainy use Roblox's plain run, Echo the
  plain idle).
- **8 characters, skills version 2**, levels 1-20 (`SKILLS_V2.md`).
- **Effects** (`Effects.luau`): sneak smoke, flare swell, noise rings, growing
  vines, pound shockwave + screen shake, shield bubbles, 🔧/💡 icons, dizzy
  stars on a stunned host, caught / rescue rings, speed streaks; floating
  "+6% stamina / +5% speed" lines; the levels line (permanent ladder bonuses)
  above the map.
- **Collectibles:** a lost plushie on every floor (19, `Config.PLUSHIES`,
  `shared/Plushies.luau`), the Lobby's Plushie Book (3D cards), Plushie
  Collector badge 4046817833899589; the finder gets a 3D card on the left.
- **Loot:** each floor hides Candy Corn, a Party Shield and one of Second Wind
  / Extra Clue / Frozen Pop in random presents or search spots of any look
  (`Config.LOOT`); found items work at once (never into the bag).
- **Social:** emote wheel (G / R3; Roblox's own emotes), rumble on
  controllers / phones, escape photo (CaptureService; setting Every / Daily /
  Off saved per player), invite reward (a Party Shield + 100 points to both
  when a brand-new player joins from your invite, `Config.INVITE_REWARD`).
- **Halloween:** Candy Corn Hunt (until 1 Nov), Candy Shop (until 8 Nov),
  Muscle Mummy skin for 100 corns.
- **The look (Brent's picks, 9-10 Oct, `STYLE_UPGRADE.md`):**
  `Config.LOOK` lighting per building (Spooky darker); the **Lobby tile
  screen** (`art/ui-mockups/lobby-v2.png`): picture tiles on the left (Quick
  Play, Solo, Party, Characters, Shop, Quests, Plushies), a right bar
  (Invite, Join, Emote, Photo, Help), red number badges, a points chip;
  **our own icons** (`art/ui-icons`, 34 uploaded, `Config.UI_ICONS`);
  **posters** (12, two per building, `Config.POSTERS`, hung framed on inside
  walls); **clean menus** (`menus-v2.png`, `hud-v2.png`): Builder Sans, text
  capped, no light buttons, dark-glass panels with a cream edge, one pop-up
  at a time; in-game action tiles with pictures.
- **Objects:** an audit fixed ~40 built-from-parts objects (shark, whale,
  penguins, duck, jellyfish, starfish, carousel unicorns, sub, clown car,
  rocking horse, teddies, floating furniture...). **Every stretched "ball"
  goes through `Shapes.fix`** (block + sphere mesh) - Roblox squashes a Ball
  part round.
- **Parties:** anyone can leave (stepped off the circle), the host leaving
  closes the party, saves are handed to the game server before the trip
  (`Profile.handOff`), the game waits up to 45 s for the whole party
  (`Config.ARRIVE_WAIT`), Quick Play joins a friend's party first.
- **Money:** boosts and Skill Reset (Developer Products), 8 skins (Game
  Passes, 99 Robux), private servers. The owner wears every skin free.
- **Owner-only test tools** (live: only Bwoodmanw): Lobby -> Characters ->
  🧪 Lv 1/5/10/15/20; 🎁 Gift; 📊 Balance.

## Where things are

```
roblox/
  game.project.json   -> Party House (Rojo port 34872, servePlaceIds locked)
  lobby.project.json  -> Escape Crew / Lobby (Rojo port 34873, locked)
  src/shared/
    Config.luau       every number and id (also LOOK, UI_ICONS, UI_TEXT,
                      POSTERS, PLUSHIES, LOOT, INVITE_REWARD, ANIM,
                      PREVIEW_SCALE, STUDIO_TRY_MODEL, ARRIVE_WAIT)
    HouseMap.luau     GENERATED by tools/make_housemap.py - never edit by hand
    Shapes.luau       Shapes.fix: stretched balls -> block + sphere mesh
    Plushies.luau     plushie / teddy builder     Emotes.luau  Haptics.luau
    Profile.luau      saves (handOff / reclaim for teleports), leaderboards
    MapGen, Progress, Quests, Gamepad, ModelBounds, PreviewPose, ...
  src/game/server/
    Main.server.luau  the referee (rounds, skills, loot, plushies, parties)
    House.luau / Rooms.luau  build and dress floors (posters in Rooms)
    Fish.luau  Effects.luau  Characters.luau  Host.luau
  src/game/client/Hud.client.luau  game screens (top level 140 locals: wrap
                      new code in do ... end)
  src/lobby/server/Lobby.server.luau, LobbyScene.luau
  src/lobby/client/LobbyUi.client.luau  (top level 119 locals)
tools/  make_housemap.py, check_rooms.luau, check_ladder*.luau,
        count_locals.py, make_badge.py, make_plushie_badge.py,
        make_event_art.py, make_lobby_mockup.py, make_menu_mockup.py,
        cut_icon_sheet.py, prep_posters.py, preview_glb.py
art/ui-icons/ (34 icons)  art/posters/ (+ game/)  art/ui-mockups/
art/roblox-store/ (badges, events, maps, passes, portraits)
art/model-input/<name>/   art/models/ (Meshy .glb, incl. tinker-toon.glb)
```

Docs: `STYLE_UPGRADE.md`, `EVENTS.md`, `SKILLS_V2.md`, `CARNIVAL.md`,
`AQUARIUM.md`, `SCHOOL.md`, `SKINS.md`, `PASSES.md`, `NOTIFICATIONS.md`,
`MESHY_GUIDE.md`, `TEST_PLAN.md` (rounds 12-54, newest first),
`ROADMAP.md`, `NEXT_SESSION_PROMPT.md`.

## What Brent has in Roblox (not in the repo)

- Party House ServerStorage/Characters (characters, skins, 6 hosts),
  ServerStorage/Props, Lobby ServerStorage/LobbyProps/House.
- Developer Products, 8 skin Game Passes, 15 badges (incl. Plushie
  Collector), uploaded images (boosts, map cards, portraits, pass pictures,
  34 UI icons, 12 posters), songs, notifications, the Halloween Event page.
- **Never publish a .rbxlx over a live place** - it wipes all of the above.
  Code goes in with Rojo; publish from Studio (File -> Publish to Roblox).

## Verified

- Every change: `luau-compile --null -g2`, `luau-analyze` (no new warnings;
  unknown globals checked by name), both places build; plans 39 x 2,000
  fills + `check_rooms.luau`.
- Every id on Roblox's public API (animations, emotes, icons, posters,
  badges).
- Brent's live / Studio tests this session: Lobby, icons, posters, fish,
  plushies, previews, parties - each report fixed (see TEST_PLAN 36-54).
  **Not yet play-tested:** most of rounds 46-54 (object audit, ball shapes,
  loot, lighting, menus, party arrive-together, one-press cannon).

## Open items and decisions waiting on Brent

1. **Publish both places** (everything to the latest commit), then live-test
   the party flows (leave, host leaves, start together) and the Junk Closet
   cannon (one press of E).
2. **Tinker cartoon test** (`STYLE_UPGRADE.md` part B): `art/models/
   tinker-toon.glb` checked 10 Oct (clean, A-pose, ~5,000 triangles; a little
   orange on the back). Next: Brent imports it as **TinkerToon** into Party
   House ServerStorage/Characters (Import 3D -> Avatar Setup); Studio plays it
   for Tinker (`Config.STUDIO_TRY_MODEL`); compare photos; if better, switch
   Tinker over and remake the others one at a time.
3. **Bramble plant:** which character Brent was when it said "knows
   something" (only non-Bramble players get that line).
4. **Host balance:** from about 15 Oct read the 📊 Balance table (Glow's
   Beacon to watch). **Translation fixes** after a week of data.
5. **Thanksgiving event** (after 1 Nov): 3-4 ideas (secret seasonal floor,
   community goal), Brent picks; event page made 7+ days before it starts
   (featuring needs that). Then Christmas. Event art: `tools/make_event_art.py`.
6. **Community group bonus:** waits for Brent to create the Roblox group
   (an in-world "join the group" sign like Dandy's World's).
7. From 1 Nov: switch the store icon back to `icon-512.png`.

## Lessons (keep)

- Don't rename the start place. Teleports, invites, Game Pass purchases,
  parties and private servers only work live.
- Rojo: Lobby = 34873, Party House = 34872; locked to their place ids.
  Rojo started from Claude's shell dies after a few hours: restart it.
- **Patch scripts:** write them with the Write tool - a bash heredoc eats
  `\u{...}` and backslashes (it bit twice on 9-10 Oct); assert every anchor,
  `.tmp` + `os.replace`. Files may be CRLF after `git stash`: patch helpers
  convert anchors to the file's line endings.
- **Roblox shapes:** a Ball part is always a sphere - use `Shapes.fix` for
  eggs and ovals; a Cylinder's Y and Z are forced equal and its height is X
  (upright with `rot = UP`: size = (height, diameter, diameter)).
- **List "Unknown global" names** from luau-analyze and check none is ours
  (it caught `Config` missing in Characters.luau and `mapBox` out of scope).
- Studio compiles at debug level 2 (`-g2`); `tools/count_locals.py`.
- **Imported characters:** never move their parts by hand; make every model
  in an A-pose; keep faces clear of big hats and goggles.
- **AI pictures:** look at every one (logos, known characters, signatures);
  posters need brightening for dim walls (`tools/prep_posters.py`); for a
  batch, give Brent one ChatGPT workflow prompt in his format (memory).
- UI: TextScaled text grows to fill its box - cap it (UITextSizeConstraint);
  UIStroke borders draw outside a button, so a ScrollingFrame clips the first
  row unless rows start a few px down.
- Look at every picture and model before using it.
