# Escape Crew - instructions for the builder (Claude)

**Read `SESSION_HANDOFF.md` first.** It is the source of truth for what Escape
Crew is, where everything lives, what has been verified, and what is next.

Escape Crew is a Roblox experience (Lobby + Party House) built with Rojo from
the code in `roblox/`. The older web version (`src/`, `public/`, Cloudflare) is
parked. This folder is unrelated to Parallax or Playbox - ignore their rules.

## Working rules

- **Check every Luau change before handing it over:**
  `.tools/luau-compile.exe --null -g2 <file>` (syntax, at Studio's debug level:
  without `-g2` it misses "Out of local registers", which broke the whole HUD on
  7 Oct - keep Hud.client.luau's top level well under 200 locals, wrap new
  sections in `do ... end`) and
  `.tools/luau-analyze.exe <file>` (ignore "Unknown global" for Roblox
  built-ins such as game, workspace, Instance, Enum, task, warn, typeof).
- **Patch scripts are atomic:** assert every anchor, write each file once at
  the end (`.tmp` then `os.replace`). Write them with the Write tool - a bash
  heredoc eats backslashes, so `\u{...}` escapes and `\n` arrive mangled.
- **Floor plans:** edit `tools/make_housemap.py` (never HouseMap.luau) and
  run it in the background - its 2,000-fill check per plan takes minutes;
  then `.tools/luau.exe tools/check_rooms.luau`.
- **Imported (skinned) characters:** never move their parts by hand to
  re-pose them (it squashes them); play an animation instead.
- **Rebuild the place files after code changes:**
  `.tools/rojo.exe build roblox/game.project.json -o EscapeCrew-PartyHouse.rbxlx`
  and the same for `lobby.project.json` -> `EscapeCrew-Lobby.rbxlx`.
- **Brent gets code into Roblox with Rojo, never by publishing a .rbxlx over
  a live place.** A .rbxlx replaces the whole place and would wipe the
  imported characters (ServerStorage/Characters) and furniture
  (ServerStorage/Props). Rojo only touches the folders in the project files.
- **Nothing runs in Roblox from here.** Say plainly what was checked (compiles,
  analyser, a render) and what only Brent's Play test can show. Ask for photos
  and F9 (Developer Console) errors.
- **Look at every picture or model before using it** (Read the image; render
  a .glb with `python tools/preview_glb.py <file> <out.png>`). Check AI art for
  resemblance to known characters and brand logos - the game is public.
- **Instructions for Brent are numbered, click by click,** with the exact menu
  names. Studio's menus move between versions; when a screen differs, ask for
  a photo rather than guessing.
- Commit and push after each piece of work. Commit messages end with the
  Co-Authored-By line from the session's attribution reminder.

## How Brent likes to work

- End every response with a STATUS block: live build, what landed, what was
  verified, what is next, whether anything is running.
- Deliver as chat text plus markdown in the repo. Word (.docx) only when he
  asks for something to read on his phone.
- Surface every gap or deliberate omission as a decision with an explicit
  build / fix / close ask, with a recommendation.
- He tests in Studio and in the Roblox app and sends screenshots. Make sure
  what he photographs answers the question.
