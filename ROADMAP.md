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

## Step 2 - buildings of floors
- A building is a stack of floors; one game = one floor; escaping a floor
  unlocks the next. Party House: Ground, Bedrooms, Attic (+ secret Basement
  later). Lobby votes building + floor. Boards per building and floor, plus
  "highest floor reached".
- Floor 2 (Bedrooms) with stairwell exit and a loft half-level in one plan;
  the corner map follows the level you are on.

## Step 3 - the host roster
- A random host each floor (50% the building's own): Pumpkin (throw),
  Gummy Bear Man (gummy puddles: stuck 3 s, max 4, melt after 40 s, never
  near doors), Robot (blackout of his room 8 s, cooldown 30 s). Models
  imported as ServerStorage/Characters/Host, HostGummy, HostRobot.
- Then Floor 3 (Attic).

## Step 4 - Gummy Bounce House (building 2)
- Bounce Hall, Candy Factory, Jelly Vault; unlocks after Party House floor 2.

Later: "Tower Run" (several floors in one game).
