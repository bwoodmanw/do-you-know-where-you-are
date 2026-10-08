# Escape Crew - what to add next (7 Oct 2026)

Best-practice Roblox features and ways to make the maps feel real and
playable. Each has a recommendation: **build now** (before 29 Oct), **build
after Halloween**, or **close**. Brent decides.

## A. Must-fix (found while checking)

1. **Saves can be lost on the trip Lobby -> Party House -> Lobby.**
   `Profile.luau` saves with `SetAsync` when a player leaves, and the next
   place loads with `GetAsync` when they arrive. On a teleport the new place
   can load *before* the old place's save lands, so points, XP or boosts from
   the last game can silently go back. Fix: save with `UpdateAsync` and a
   session lock (the new server waits until the old one has released the
   player, a few seconds at most), and save right before every teleport.
   **Build now.** It is invisible when it works and painful when it does not.

## B. Roblox best practice (features)

| # | Feature | Why | Recommendation |
|---|---|---|---|
| 1 | **Badges** (first escape, each building, all 9 floors, rescue 10 friends, escape without being caught, Nightmare escape) | Badges show on the game page and players' profiles; kids chase them | Build now (made in Creator Hub, Claude wires them) |
| 2 | **Favourite prompt** after a player's first win ("Liked it? Add Escape Crew to your favourites!") | Favourites drive Roblox's recommendations | Build now |
| 3 | **Quick Play** button in the Lobby: joins an open party or starts solo on the highest unlocked floor | New players are in a game in one tap | Build now |
| 4 | **Colour-blind code**: a shape on every colour (circle, star, square...) on balloons, keypad and code bar | About 1 boy in 12 is colour-blind; the whole game is a colour code | Build now (small) |
| 5 | **Daily quests** (3 a day: "escape 2 floors", "free a friend", "find 5 keys") with points | Brings players back daily, beyond the login reward | After Halloween |
| 6 | **Play with friends bonus** (+10% points when a friend is in the party) | Encourages inviting | After Halloween |
| 7 | **Experience notifications** ("Your daily reward is ready") | Roblox's own reminder system | After Halloween |
| 8 | **Analytics funnel** (AnalyticsService: joined -> picked character -> first clue -> escaped) | Shows where new players give up | After Halloween |
| 9 | **Cosmetic skins** for characters (a Halloween Tinker, a ghost Shadow) for Robux | Better than selling power; kids love skins | After Halloween |
| 10 | **Gamepad support check** (Xbox / controller) | Roblox shows the game to console players only if it works there | After Halloween |
| 11 | **Reconnect**: a player who drops can rejoin their own game | Phones drop often | After Halloween |
| 12 | Voice chat, trading | Not right for 8+ co-op | Close |

## C. Maps: more real, more interactive, more on-theme

Today every room has its own walls, floor and set pieces (`Rooms.luau`).
What would make it feel real is that rooms **do** things and **sound** like
what they are, and that you always know where you are.

1. **Room name signs over every doorway** ("Library ->", "Boiler Room").
   Kids learn the house and can say "meet in the Kitchen". Cheap. **Build now.**
2. **Room sounds** (quiet, 3D, looped): boiler hum, conveyor clank, clock
   tick, hospital monitor beep, dripping honey, crackling fire, wind in the
   attic. The biggest realism gain for the least work. **Build now.**
3. **Particles**: steam from the boiler and pipes, dust in the attic, bubbles
   in the chocolate river, sparkles in the vault, mist over the jelly pool.
   **Build now.**
4. **Things that matter in play** (one or two per building):
   - Light switches: turn a room dark to hide better (the host sees less far
     in the dark) - Party House and Hospital. **Build now.**
   - A TV, radio or piano you can switch on: the noise lures the host there
     (like Echo's noise, for everyone, once each). **Build now.**
   - Factory conveyor belts that carry you along (faster one way, slower the
     other). **Build now.**
   - A laundry chute / dumbwaiter: a one-way shortcut between two rooms
     (like a vent). **After Halloween.**
   - The vault door: turn the wheel (hold E) to open a bonus room.
     **After Halloween.**
   - Chocolate river: wading slows you down; the bridge does not. **After Halloween.**
5. **Lighting per room**: warm lamps in the Party House, cold flickering tubes
   in the hospital, candy-coloured glow in the Gummy House, red warning lights
   in the boiler and generator rooms. **Build now** (part of room dressing).
6. **Real models** for the big set pieces (Boiler, Conveyor, Ambulance,
   VaultDoor, Fireplace): free Creator Store models dropped into Props, as in
   `FURNITURE.md`. **Brent, any time** - no code needed.
7. **Windows with a view**: moonlit windows on outer walls, the garden or
   clouds outside. **After Halloween.**

## Built 7 Oct

A1 save safety; B1 badges (waiting for ids), B2 favourite prompt, B3 Quick Play,
B4 colour pictures; C1 doorway signs, C2 room sounds, C3 effects, C4 light
switches, noisy things, conveyor belts; C5 room lighting. Still open: B5-B11,
C4 laundry chute / vault wheel / chocolate wading, C6 real models, C7 windows.

## Built 7 Oct (fourth session) - TEST_PLAN.md round 12

B10 controller support (`shared/Gamepad.luau`: button tags, panels picked
with the stick, B closes, LT run, RB skill, LB boost, D-pad clue / map / chat /
players, Y for the F prompts); B6 friends bonus (+10% of a game's points with
a Roblox friend in it); C4 chocolate wading (floor-level channels, half speed,
footbridges; the host is slowed too and walks round); B11 rejoin after a
drop (while friends are still playing); B5 daily quests (`shared/Quests.luau`,
13 kinds, 3 a day, Lobby panel); B7 daily-reward notifications (needs the
Creator Hub steps in `NOTIFICATIONS.md`); C4 laundry chute and the vault
door's bonus vault; C7 moonlit windows; B9 skins (code ready and hidden:
art, models and Game Passes in `SKINS.md`).

Still open: B8 analytics (Brent: not now), C6 real models (Brent, any time).

## Status (8 Oct)

Everything above is built except B8 analytics (parked by Brent) and C6 real
models (Brent, any time). See ROADMAP.md "Next" for what comes after.

## Suggested order for the next sessions (historical)

1. Save safety (A1).
2. Room signs, room sounds, particles, room lighting (C1, C2, C3, C5).
3. Light switches, noise lures, conveyor belts (C4).
4. Badges, favourite prompt, Quick Play, colour-blind shapes (B1-B4).
5. Publish both places before 29 Oct; after Halloween: quests, skins,
   notifications, analytics.
