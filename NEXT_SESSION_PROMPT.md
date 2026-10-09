# Prompt for the next session

Open the session in `C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are`
(so its `CLAUDE.md` loads), then paste:

---

We're continuing **Escape Crew**, my Roblox co-op horror-escape game for kids
(Lobby "Escape Crew" + game place "Party House", built with Rojo from
`roblox/`). Read `CLAUDE.md`, then `SESSION_HANDOFF.md` (the source of truth),
then `ROADMAP.md`, `TEST_PLAN.md` (rounds 12-35, newest first), `SKILLS_V2.md`,
`CARNIVAL.md`, `AQUARIUM.md` and `SKINS.md`.

First, start both Rojo servers in the background (Party House
`roblox/game.project.json` on port 34872, Lobby `roblox/lobby.project.json`
on port 34873) so I can sync. Then ask me for my live test results
(screenshots and F9 errors, Client and Server tabs) and whether I've
published both places since the last session, and fix what I found first.

Then, telling me before each:
1. Anything from my live tests: the new hosts' powers (Lock-up,
   Jack-in-the-Box, Fake Treasure), skills version 2 (every button, levels
   10 and 20 - I test them with the 🧪 Lv buttons), the camera, the map,
   the countdown and Frenzy, the Candy Shop and Muscle Mummy.
2. Host balance from the 📊 Balance table, if the game has been live a week
   (Glow's Beacon is the strongest new power to watch).
3. **Thanksgiving event** (it starts after Halloween ends on 1 Nov): give me
   3-4 ideas built on what I liked - a secret seasonal floor and a
   community-wide goal everyone works towards - with what players collect,
   the reward, and how long it runs; your recommendation; wait for my pick.
   Then sketch the Christmas event the same way.
4. Ideas still on the list: the collectibles book (a hidden plushie on
   every floor), the community group bonus, translation fixes after a week
   of data. Tell me if any is worth doing before the events.

Rules: check every Luau file with `luau-compile --null -g2` (Studio's debug
level), keep Hud.client.luau's top level well under 200 locals (wrap new HUD
code in `do ... end`), write patch scripts with the Write tool (never through
a bash heredoc - it eats `\u{...}` and backslashes), assert every anchor,
and never move an imported character's parts by hand (play an animation
instead). New floor plans go in `tools/make_housemap.py` and must pass 2,000
fills (run it in the background), then `tools/check_rooms.luau`; ladder
changes must pass `tools/check_ladder.luau` and
`tools/check_ladder_repeats.luau`. Look at every picture and model before
using it (logos, known characters, anything not for kids). Use American
English in everything players read.

Give me numbered, click-by-click steps for anything I do in Studio or
Creator Hub, surface every gap as a build / fix / close decision with your
recommendation, and end every reply with the STATUS block.
