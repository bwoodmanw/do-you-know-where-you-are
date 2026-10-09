# Prompt for the next session

Open the session in `C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are`
(so its `CLAUDE.md` loads), then paste:

---

We're continuing **Escape Crew**, my Roblox co-op horror-escape game for kids
(Lobby "Escape Crew" + game place "Party House", built with Rojo from
`roblox/`). Read `CLAUDE.md`, then `SESSION_HANDOFF.md` (the source of truth),
then `ROADMAP.md`, `TEST_PLAN.md` (rounds 12-54, newest first),
`STYLE_UPGRADE.md`, `EVENTS.md` and `SKILLS_V2.md`.

First, start both Rojo servers in the background (Party House
`roblox/game.project.json` on port 34872, Lobby `roblox/lobby.project.json`
on port 34873) so I can sync. Then ask me for my live test results
(screenshots and F9 errors, Client and Server tabs), which commit I last
published both places at, and fix what I found first.

Then, telling me before each:
1. Anything from my tests: the party fixes (leave, the host leaving closes
   it, starting together - the game waits for everyone), the one-press
   Confetti Cannon, the object audit and round-ball fix, random loot, the new
   lighting, the Lobby tile screen and clean menus, posters, icons, the
   carousel unicorns (TEST_PLAN 46-54).
2. **The Tinker cartoon test** (STYLE_UPGRADE part B): I import
   `art/models/tinker-toon.glb` as TinkerToon; Studio plays it for Tinker
   (`Config.STUDIO_TRY_MODEL`). Walk me through it click by click, compare my
   photos with the old Tinker, and if the new one wins, switch him over and
   give me the next character's ChatGPT prompt and Meshy steps.
3. Host balance from the 📊 Balance table (live since 8 Oct; Glow's Beacon
   is the strongest new power to watch) and translation fixes from a week of
   data.
4. **Thanksgiving event** (starts after Halloween ends 1 Nov): 3-4 ideas
   built on a secret seasonal floor and a community-wide goal - what players
   collect, the reward, how long it runs; your recommendation; wait for my
   pick. The event page must be made 7+ days before it starts. Then sketch
   Christmas the same way.
5. The community group bonus once I've made the Roblox group.

Rules: check every Luau file with `luau-compile --null -g2` (Studio's debug
level) and `luau-analyze` (list unknown globals by name - none may be ours),
keep Hud.client.luau's and LobbyUi.client.luau's top level well under 200
locals (wrap new code in `do ... end`), write patch scripts with the Write
tool (never through a bash heredoc - it eats `\u{...}` and backslashes),
assert every anchor, use `Shapes.fix` for any stretched ball part, and never
move an imported character's parts by hand (play an animation instead). New
floor plans go in `tools/make_housemap.py` and must pass 2,000 fills (run it
in the background), then `tools/check_rooms.luau`; ladder changes must pass
`tools/check_ladder.luau` and `tools/check_ladder_repeats.luau`. Look at
every picture and model before using it (logos, known characters, anything
not for kids). For any batch of pictures, give me one ChatGPT workflow
prompt in my format (standard prompt + table of picture prompts and file
names). Use American English in everything players read.

Give me numbered, click-by-click steps for anything I do in Studio or
Creator Hub, surface every gap as a build / fix / close decision with your
recommendation, and end every reply with the STATUS block.
