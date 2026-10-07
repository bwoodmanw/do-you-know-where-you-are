# Prompt for the next session

Open the session in `C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are`
(so its `CLAUDE.md` loads), then paste:

---

We're continuing **Escape Crew**, my Roblox co-op horror-escape game for kids
(Lobby "Escape Crew" + game place "Party House", built with Rojo from
`roblox/`). Read `CLAUDE.md`, then `SESSION_HANDOFF.md` (the source of truth),
then `IMPROVEMENTS.md`, `ROADMAP.md` and `TEST_PLAN.md` (rounds 4-11 at the
top are what I'm testing).

First, start both Rojo servers in the background (Party House
`roblox/game.project.json` on port 34872, Lobby `roblox/lobby.project.json`
on port 34873) so I can sync. Then ask me for any test results (screenshots
and F9 errors, Client and Server tabs) and fix those first.

Then build everything still open in `IMPROVEMENTS.md` except B8 analytics,
in this order, telling me before each:
1. B10 controller / Xbox support (every button and prompt usable with a gamepad).
2. B6 play-with-friends bonus (+10% points with a friend in the party).
3. C4 chocolate river wading slows you (the bridge does not).
4. B11 rejoin your own game after a dropped connection.
5. B5 daily quests (3 a day, points as rewards, a Lobby quests panel).
6. B7 "daily reward ready" notifications (tell me the Creator Hub steps).
7. C4 laundry chute shortcut and the vault-door wheel bonus room.
8. C7 windows with a moonlit view on outer walls.
9. B9 character skins for Robux (give me the art prompts and Creator Hub
   steps first).

Rules from last time: check every Luau file with `luau-compile --null -g2`
(Studio's debug level), keep Hud.client.luau's top level well under 200
locals (wrap new HUD code in `do ... end`), and never paste Python with
`\u{...}` through a bash heredoc - write patch scripts with the Write tool.

Give me numbered, click-by-click steps for anything I do in Studio or
Creator Hub, surface every gap as a build / fix / close decision with your
recommendation, and end every reply with the STATUS block.
