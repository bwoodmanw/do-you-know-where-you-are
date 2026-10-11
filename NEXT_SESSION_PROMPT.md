# Prompt for the next session

Open the session in `C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are`
(so its `CLAUDE.md` loads), then paste:

---

We're continuing **Escape Crew**, my Roblox co-op horror-escape game for kids
(Lobby "Escape Crew" + game place "Party House", built with Rojo from
`roblox/`).

**First, turn on Remote Control for this session** (so I can drive it from
claude.ai/code on another computer while this laptop stays on), and keep
the computer awake while the session is active.

Then read `CLAUDE.md`, `SESSION_HANDOFF.md` (start with "Session 8" - the
source of truth), `TOON_WORKFLOW.md`, `SEASONAL_EVENTS.md`, `ROADMAP.md` and
`TEST_PLAN.md`. Start both Rojo servers in the background if they aren't
running (Party House `roblox/game.project.json` on 34872, Lobby
`roblox/lobby.project.json` on 34873) and `git pull` (I may have uploaded
pictures through GitHub from the other computer).

Then, telling me before each:
1. **Echo:** I re-import `art/models/echo-toon.glb` and send photos (right
   side: one headphone cup now?). If clean, give me ONE ChatGPT workflow for
   the left / right side pictures of every other character, skin and host
   (Echo's format: `ECHO_SIDE_TOON_PICTURE_WORKFLOW.md`), check them, repaint
   everything, and render.
2. **Switch-over:** walk me through importing every character, skin and host
   (Platform Avatar), the Characters cleanup, old -> CharactersOld, rename,
   Save to Roblox, ids into `Config.CHARACTER_ASSETS` (fixes the Lobby's 3D
   models). Caretaker's mop / the Robot's feet: judge at import.
3. **Yearly event dates + feathers for Robux** (decided - build), then the
   Thanksgiving build (Harvest Barn floor, Turkey Roundup, the Gobbler, Feast
   Meter, feather shop like the Candy Shop, 9 skins, badge) and the **event
   page by 24 Oct** (picture with `tools/make_event_art.py`, text in
   `EVENTS.md`).
4. My Play tests of session 8's changes (handoff list), then publish both
   places together and the live tests.
5. Host balance (📊 Balance), translation fixes, the community group bonus.

Rules: check every Luau file with `luau-compile --null -g2` and
`luau-analyze` (list unknown globals by name - none may be ours), keep
Hud.client.luau's and LobbyUi.client.luau's top level well under 200 locals
(wrap new code in `do ... end`), write patch scripts with the Write tool
(never through a bash heredoc - it mangles backslashes), assert every anchor
and check the real indentation (`sed -n | cat -A`: the Read view shows one
extra tab), keep CRLF files CRLF, use `Shapes.fix` for any stretched ball
part, and never move an imported character's parts by hand. Every model file
goes through `tools/check_toon_models.py`; when Studio and a render
disagree, ask me for an Export Selection of the part and render THAT before
changing anything. New floor plans go in `tools/make_housemap.py` (2,000
fills, background), then `tools/check_rooms.luau`; ladder changes must pass
the three `tools/check_ladder*.luau`. Look at every picture and model before
using it (logos, known characters, anything not for kids). For any batch of
pictures, give me one ChatGPT workflow prompt in my format. American English
in everything players read. The Command Bar is not an option for me.

Give me numbered, click-by-click steps for anything I do in Studio or
Creator Hub, surface every gap as a build / fix / close decision with your
recommendation, and end every reply with the STATUS block.
