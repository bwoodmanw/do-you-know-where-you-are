# Prompt for the next session

Open the session in `C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are`
(so its `CLAUDE.md` loads), then paste:

---

We're continuing **Escape Crew**, my Roblox co-op horror-escape game for kids
(Lobby "Escape Crew" + game place "Party House", built with Rojo from
`roblox/`). Read `CLAUDE.md`, then `SESSION_HANDOFF.md` (the source of truth -
especially "The toon model upgrade"), then `TOON_WORKFLOW.md`, `ROADMAP.md`,
`TEST_PLAN.md` (rounds 12-61, newest first) and `LADDER_FIX.md`.

First, start both Rojo servers in the background (Party House
`roblox/game.project.json` on port 34872, Lobby `roblox/lobby.project.json`
on port 34873) so I can sync, and check whether the host models
(`art/models/host*-toon.glb`) are there yet - if so, render each one (front,
back, side) and run `tools/check_toon_models.py` on everything.

Then, telling me before each:
1. **Finish the toon model switch-over, Patch first.** I re-import
   `art/models/patch-toon.glb` (the files after commit 3c59e29 keep their
   normals) -> Avatar Setup -> PatchToon, and send photos in Avatar Setup and
   in the game (Studio plays the plain character: `Config.STUDIO_NO_SKINS`).
   If her face and legs are clean, walk me through re-importing every
   character and skin, the Characters cleanup (leftover plain imports ->
   CharactersRaw), the switch-over (old -> CharactersOld, rename, Save to
   Roblox) and put each id into `Config.CHARACTER_ASSETS`. If anything is
   still wrong, find the cause before asking me to re-import again - check
   the model file first (render it, run the checker) and use Studio's Output
   lines ([Characters], [Faces]).
2. **The hosts:** check my workflow 2 models, import them (HostToon,
   HostGummyToon, ...), test in Studio; the Robot has wheels - if Avatar Setup
   won't rig him, give me the choice.
3. When all switch-overs are done: publish both places together, then my
   live tests (TEST_PLAN 46-61, including the ladder A/B/C, the Skills /
   Skins windows, sounds, the free reset).
4. Host balance from the 📊 Balance table and translation fixes (from about
   15 Oct).
5. **Thanksgiving event** (starts after Halloween ends 1 Nov): 3-4 ideas built
   on a secret seasonal floor and a community-wide goal; your recommendation;
   wait for my pick. The event page must be made 7+ days before it starts.
   Then sketch Christmas the same way.
6. The community group bonus once I've made the Roblox group.

Rules: check every Luau file with `luau-compile --null -g2` and
`luau-analyze` (list unknown globals by name - none may be ours), keep
Hud.client.luau's and LobbyUi.client.luau's top level well under 200 locals
(wrap new code in `do ... end`), write patch scripts with the Write tool
(never through a bash heredoc or backticks in `python -c`), assert every
anchor, use `Shapes.fix` for any stretched ball part, and never move an
imported character's parts by hand. Every model file goes through
`tools/check_toon_models.py` (normals, texture, facing forward, sharp face).
New floor plans go in `tools/make_housemap.py` (2,000 fills, background),
then `tools/check_rooms.luau`; ladder changes must pass the three
`tools/check_ladder*.luau`. Look at every picture and model before using it
(logos, known characters, anything not for kids). For any batch of
pictures, give me one ChatGPT workflow prompt in my format. American English
in everything players read.

Give me numbered, click-by-click steps for anything I do in Studio or
Creator Hub, surface every gap as a build / fix / close decision with your
recommendation, and end every reply with the STATUS block.
