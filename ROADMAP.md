# Escape Crew roadmap (agreed 6 Oct 2026)

Brent approved this plan as written; build in order, asking before each step.

## Step 1 - economy, Pumpkin's throw, crawl spaces (built 6 Oct)
- Skill-ladder choices are permanent; reset one character's ladder for
  500 points or 49 Robux (Developer Product `reset`).
- Slower levels: XP for levels 2-5 = 300 / 800 / 1,600 / 3,000; points per
  game x0.67 (`Config.POINT_SCALE`).
- Energy removed: clues cost points earned in that game (10 / 20 / 30, Brainy
  half). Patch's skill: a Party Shield for the nearest friend (herself when
  alone) and stamina back; she holds everything twice as fast. The Energy
  Drink boost is now Second Wind (full stamina).
- Hosts chase a little faster than kids walk (13 / 14 / 15.5 / 17 by
  difficulty; kids walk 12, run 20). Footprint and heartbeat cues off; the
  host's breathing stays.
- Pumpkin throws a pumpkin (slow arc, 12-45 studs, knocks down 2 s, cooldown
  20 / 15 / 12 / 9 s by difficulty).
- Crawl vents: 2 per floor plan, between rooms of the same zone; 1.6 s
  crawl, host cannot follow or see, 10 s per vent.
- Lobby: comic-shop cashier shopkeeper, a drive-in car facing the boards,
  trampoline, kick ball, giant pumpkin, bell.

## Step 2 - buildings of floors (built 6 Oct)
- A building is a stack of floors; one game = one floor; escaping a floor
  unlocks the next. Party House: Ground, Bedrooms, Attic (+ secret Basement
  later). Lobby votes building + floor. Boards per building and floor, plus
  "highest floor reached".
- Floor 2 (Bedrooms) with stairwell exit and a loft half-level in one plan;
  the corner map follows the level you are on.
- Built as: `Progress.MAPS` entries carry building + floor
  (`partyhouse`, `partyhouse_2`, `partyhouse_3` coming soon, `gummy`,
  `hospital`); `Progress.unlocksAfter`; `HouseMap` is floor -> plans
  (Bedrooms plans `bed_a` + mirror `bed_b`); the Gallery is a tall room
  (ceiling 24) with a loft 7 studs up and a ramp; upper floors exit into a
  stairwell landing; Studio Play builds `Config.STUDIO_MAP`; Lobby board
  "Most floors escaped"; Frozen Pop boost (freezes the host 10 s).

## Step 3 - the host roster (built 6 Oct)
- A random host each floor (50% the building's own): Pumpkin (throw),
  Gummy Bear Man (gummy puddles: stuck 3 s, max 4, melt after 40 s, never
  near doors), Robot (blackout of his room 8 s, cooldown 30 s). Models
  imported as ServerStorage/Characters/Host, HostGummy, HostRobot.
- Then Floor 3 (Attic).
- Built as: `Config.HOSTS` / `Config.BUILDING_HOST` / `Config.HOST_SKILLS`;
  Host:spawn loads `Characters.host(model)` (a built host in the host's
  colour until imported); gummy puddles and blackout live in Main
  (`round.hostGummy`, `round.hostBlackout`), the client darkens Lighting
  while you stand in the blacked-out room. Attic plans `attic_a` + mirror
  (3 vents, rafters, "Out onto the roof!"). Lobby: realistic house model
  slot (ServerStorage/LobbyProps/House), invisible fence at z -88, the
  host's face or shadow in a window every 18-40 s.

## Step 4 - Gummy Bounce House (building 2) - floor 1 built 6 Oct
- Bounce Hall, Candy Factory, Jelly Vault; unlocks after Party House floor 2.
- Built: Bounce Hall (plans gum_a + mirror): candy theme (pink walls, mint /
  lilac / caramel / pink-tile floors, candy pictures, gumdrops), gumdrop ball
  pit, Slide Tower with a loft, Bounce Room with 3 bounce pads, exit to the
  cotton-candy clouds. HouseMap is now building -> floor -> plans.
- Built 7 Oct (untested): floor 2 Candy Factory (plans fac_a + mirror: Conveyor
  Hall and Factory Floor across the middle, Chocolate River + Wrapper Room
  behind the first door, Packing Hall + Taste Lab behind the second, stairs
  "Up to the Jelly Vault"); floor 3 Jelly Vault (vault_a + mirror: 3 x 3,
  jelly pool, jelly bounce pads, 3 vents, clouds exit). Both `ready`.
  The generator no longer has the old hole and cabinet.

Later: "Tower Run" (several floors in one game).

## Round of 6 Oct (late) - built, untested
Shared map screen with votes and pictures; portraits (Lobby and game);
leaderboard avatars; swing set and soccer ball; active-boost timers;
Patch's breather aura (+50% stamina near her, 10 s per friend) and 3.5 s
cage freeing (Patch half); bats / tissue / confetti from empty finds; hides
marked and in every pair of joined rooms (1-3 players); interactive party
clutter (cake candles, jack-in-the-box, gift pile).

## 10 levels per character (built 7 Oct, Brent's yes) - untested
XP for levels 2-10: 300 / 800 / 1,600 / 3,000 / 4,800 / 7,000 / 9,600 /
12,600 / 16,000. Even levels (2, 4, 6, 8) are the same for everyone; odd
levels (3, 5, 7, 9) and 10 are the character's own. Bonuses are about half
the old size; level 10 holds the old big level-5 upgrades. Caps
(`Progress.CAPS`): run +20%, stamina +50%, hold times at most twice as fast,
host sight at least 65%, recharge at most twice as fast, 5 clues per player.
Saved picks at levels 2-5 keep their ids (their numbers shrank). Every number
is in `roblox/src/shared/Progress.luau`.

| Lvl | Everyone / Tinker | Shadow | Brainy | Muscle |
|---|---|---|---|---|
| 2 | +10% stamina / hold 8% faster | | | |
| 3 | hold 15% / one code colour | sneak 8 s / recharge 20% | +1 clue / one code colour | shove 20% / Shield |
| 4 | run 5% / host sees 10% less | | | |
| 5 | hold 15% / Shield | sneak 10 s / run 5% | +1 clue / hold 20% | run 5% / stamina 15% |
| 6 | +10% stamina / hold 8% faster | | | |
| 7 | hold 15% / +1 clue | sight 10% / recharge 20% | +1 clue / hold 15% | shove 20% / stamina 15% |
| 8 | run 5% / host sees 10% less | | | |
| 9 | hold 20% / sight 15% | sneak 12 s / run 8% | +2 clues / hold 20% | shove 30% / run 8% |
| 10 | Master Hands x2 / run 15% | Ghost 14 s / Blur run 15% | Genius +3 / Speed Reader x2 | Titan x2 / Iron Lungs +50% |

| Lvl | Glow | Patch | Echo | Bramble |
|---|---|---|---|---|
| 3 | light 28 / one code colour | shield all nearby / recharge 15% | throw 85 / recharge 15% | ask 20% / stamina 10% |
| 5 | light 32 / sight 10% | recharge 20% / free 20% | sight 10% / recharge 20% | sight 10% / one code colour |
| 7 | light 38 / sight 10% | recharge 15% / free 20% | throw 95 / sight 10% | ask 20% / stamina 15% |
| 9 | light 44 / sight 15% | recharge 25% / free 30% | throw 110 / recharge 25% | sight 15% / +1 clue |
| 10 | Little Sun 50 / Dazzle 30% | Guardian Angel x2 / Field Medic x2 | Radar Ears 30% / Echo Storm x2 | Camouflage 35% / Plant Friend x2 |

(Patch's "shield all nearby" stays at level 3 where players already took it.)

## Muscle's blocked passage (built 7 Oct, Brent's yes) - untested
Each game one of the two locked doors (random) is a doorway heaped with
party junk instead. Muscle holds E 3 s and shoves it clear (quiet, 25
points). Without Muscle, the Confetti Cannon hidden in a search spot on the
near side (where that door's key would be) is planted with F: 3 s fuse,
BOOM, confetti, the host comes to look (15 points). Tinker can't pick it.
The secret hole is gone (plain wall; the cabinet is furniture). The plan
data in `make_housemap.py` still lists hole + cabinet; harmless.
Also 7 Oct: game-sounds volume button beside the music one (SoundService/
GameSounds, `shared/Sfx.luau`, saved as settings.sfx); points reset 800; vents take any number of players, each
waits `Config.VENT_REUSE` (2.5 s) before crawling again; the game starts
only when everyone presses Play.

## Tinker / Muscle balance (built 7 Oct, Brent's yes) - untested
- Store rooms: `add_closets` in the generator carves two 3 x 3 rooms into
  corners of zone-1 rooms on every plan (furniture there removed; host patrol
  points moved out): B1 "Store Room door" locked (Tinker / key), B2 "Junk
  Cupboard" blocked (Muscle / its own Confetti Cannon). Off the way out. A
  present inside: 30 points + a clue, a Shield or 30 more.
- Muscle's Barricade (skill button, 25 s): 6 crates marked 💪 beside inner
  doorways each game, plus the junk he shoves aside. The nearest crate in 16
  studs slides into its doorway for 10 s; kids walk through; the host is
  stuck 4 s smashing it, then it slides home (`Config.BARRICADE`). Ladder:
  Sturdy Barricade (+2 s) at 7, Quick Builder (recharge 25% faster) at 9.
- Tinker: no limit on picking (main door and Store Room); once a game holds F
  6 s at the big door's keypad to learn one colour.

## Hospital floor 1 and Halloween polish (built 7 Oct evening) - untested
- Abandoned Hospital, Ground Floor (plans hosp_a + mirror, theme "hospital":
  pale green walls, white/mint/grey floors, flickering strip lights, no flags
  or rugs, wheelchairs to spin, medical pictures). Unlocked by escaping the
  Candy Factory. Host: the Robot half the time.
- Halloween (`Config.HALLOWEEN`): orange/purple/black bunting, two paper bats
  per room. First-game coach (`Config.COACH_GAMES` = 2): six tips moved on by
  what happens in the game.
- Lobby: fence, trees, jack-o'-lanterns round the edge; drive-in of three
  cars; house sunk 2 studs (`Config.LOBBY_HOUSE_SINK`); windows re-measured.
- Fixes: Echo's noise holds the host 5 s (`Config.ECHO_LURE`); prompts per
  character; characters' hip height from their model (Echo's shaking run).

## Fourth session (7-8 Oct) - built, mostly untested (TEST_PLAN rounds 12-16)
- Everything in IMPROVEMENTS.md except B8 analytics: controller support,
  friends bonus, chocolate wading, rejoin after a drop, daily quests,
  notifications (off until Creator Hub steps), laundry chute, vault door,
  moonlit windows, character skins.
- Play-test fixes: caught in a vent/chute lands in the cage; ladder bonuses
  match the character played; Lobby window peeks never stop; leaderboard
  counts daily rewards.
- Code-colour upgrades: one colour a game, none on Nightmare.
- Brainy's new ladder (`BRAINY_LADDER.md`); clue log (every clue this game).
- Weekly quests (3 a week, points + a boost).
- **The secret Basement** (Party House floor 0, unlocked by the Attic).
- **Tower Run** (one game climbs a building's 3 floors).
- **Building 4: the Midnight School** (Ground Floor, Classrooms, Clock Tower;
  `SCHOOL.md`).
- **8 skins on sale** as Game Passes (`SKINS.md`, `PASSES.md`).
- 8 Oct (later): School map cards and the Caretaker host (Lock-up);
  **Building 5: the Creepy Carnival** (Midway, Big Top, Funhouse;
  `CARNIVAL.md`) and the Clown Bear host (Jack-in-the-Box); badges Top of
  the Class, Hero of the Crew, Untouchable, Nightmare Escaper, Tower
  Climber; the Anglerfish Keeper's model and lure (hidden until building 6).

- 8 Oct (later still): quick chat upgrade (own bubbles, pins, T), the
  daily-reward notification id; **Building 6: the Sunken Aquarium**
  (`AQUARIUM.md`) with the Anglerfish Keeper (Fake Treasure); the
  **Halloween Candy Corn Hunt** until 1 Nov.

- 8-9 Oct (end of session 5): skills version 2 (a button for everyone,
  levels to 20, level-10/20 powers, guard rails; `SKILLS_V2.md`), Candy Shop
  and Muscle Mummy, owner test tools, American English, Invisicam camera
  that stops at walls, bigger map with icons, countdown and Frenzy
  effects, private servers / translation / notifications live, all 14
  badges in. Both places published 8 Oct (late).

- 9 Oct (session 6): live-test fixes (Sound Wave keeps the lure, moving in
  the cage, Loft label, plant message, boost pop-ups); **effects step 1**
  (sneak smoke, flare swell, noise rings, growing vines, pound shockwave and
  shake, shield bubbles, 🔧 / 💡 icons, dizzy stars on a stunned host, caught
  / rescue rings, speed streaks); the **levels line** (permanent ladder
  bonuses on screen); **animation packs step 2** (Roblox's own packs per
  kid and host, `Config.ANIM`); American room names; real gummy bears.

## Effects and animation (Brent's yes, 9 Oct)
1. Built: skill and host effects in code (`Effects.luau`: ring, swell, aura,
   stars, icon, shield).
2. Built: Roblox animation packs per character and host (`Config.ANIM`).
3. Closed for now: our own skill animations recorded in Studio's Animation
   Editor (an Echo throw, a Muscle pound) - needs Brent's time in Studio.

## Next
1. Brent: publish both places once more; play-test live (TEST_PLAN 12-37).
2. Host balance per difficulty from the 📊 Balance table after a week live.
3. Thanksgiving event (after Halloween ends 1 Nov), then Christmas: a
   secret seasonal floor and / or a community-wide goal (Brent's picks).
4. Ideas: collectibles book, community group bonus, translation fixes.
5. Later: B8 analytics, subscriptions (parked).

## Ideas from top Roblox adventure / horror games (8 Oct, Brent to pick)
Already have: spectating when caught, game invites, Quick Play, daily and
weekly quests, login rewards, badges, leaderboards, controller support,
colour-blind code pictures, a tutorial coach, rejoin.
1. (Brent doing, 8 Oct) **Private servers** (Creator Hub setting, no code: the Lobby already
   reserves a server per party) - families and classes play together; a
   little income.
2. (Brent doing, 8 Oct) **Automatic translation** (Creator Hub -> Localization; some built-up
   text in code may need small changes) - most Roblox players are not
   English speakers.
3. (built 8 Oct: it existed as Say; now own bubbles, pins, T) **Quick-chat wheel** - "Over here!", "Hide!", "Need Tinker!", "Key
   found!" as bubbles over your head; works for kids whose chat is off.
4. (built 8 Oct) **Halloween event** until 1 Nov - a candy-corn hunt on every floor for
   a limited reward (a badge or a free skin colour).
5. **Collectibles book** - one hidden "lost plushie" per floor (16), a book
   in the Lobby, a badge for all; exploring and replaying.
6. **Community group bonus** - join the Escape Crew group for +10% points;
   the group gets update posts (needs a Roblox group).
7. Not recommended: a paid "escape the cage" revive (pay-to-win for kids;
   friends already rescue you).
