# Prompt for the next session

Open the session in `C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are`
(so its `CLAUDE.md` loads), then paste:

---

We're continuing **Escape Crew**, my Roblox co-op horror-escape game for kids
(Lobby "Escape Crew" + game place "Party House", built with Rojo from
`roblox/`). Read `CLAUDE.md`, then `SESSION_HANDOFF.md` (the source of truth),
then `ROADMAP.md`, `TEST_PLAN.md` (rounds 12-16 at the top are what I'm
testing), `SKINS.md`, `PASSES.md` and `SCHOOL.md`.

First, start both Rojo servers in the background (Party House
`roblox/game.project.json` on port 34872, Lobby `roblox/lobby.project.json`
on port 34873) so I can sync. Then ask me for my test results (screenshots
and F9 errors, Client and Server tabs) and whether I've published both
places yet, and fix what I found first.

Then, telling me before each:
1. Anything I've sent for the Midnight School (map-card pictures to check,
   their image ids, the "Top of the Class" badge id) and for notifications
   (the message id from `NOTIFICATIONS.md`).
2. Skin follow-ups: check any new pictures or model ids I send.
3. **Building 5, with 3 floors.** Before building, give me 3-4 theme ideas
   (each with its three floors, its rooms, what makes it play differently
   and which host fits), with your recommendation, and wait for my pick.
   Build it like the Midnight School: plans in `tools/make_housemap.py`
   (each passing 2,000 fills, run in the background), its own theme and set
   pieces in House/Rooms, unlocked after building 4's floor 2, map-card
   picture prompts and a badge for its top floor.
4. Host balance from the 📊 Balance table, if the game has been live a week.

Rules from last time: check every Luau file with `luau-compile --null -g2`
(Studio's debug level), keep Hud.client.luau's top level well under 200
locals (wrap new HUD code in `do ... end`), write patch scripts with the
Write tool (never through a bash heredoc - it eats `\u{...}`), assert every
anchor (watch the tabs), and never move an imported character's parts by
hand (play an animation instead). Look at every picture and model before
using it (logos, known characters).

Give me numbered, click-by-click steps for anything I do in Studio or
Creator Hub, surface every gap as a build / fix / close decision with your
recommendation, and end every reply with the STATUS block.
