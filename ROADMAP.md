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
  Candy Factory and Jelly Vault: next.

Later: "Tower Run" (several floors in one game).
