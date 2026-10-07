# Prompt for the next session

Open the session in `C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are`
(so its `CLAUDE.md` loads), then paste:

---

We're continuing **Escape Crew**, my Roblox co-op horror-escape game for kids
(Lobby "Escape Crew" + game place "Party House", built with Rojo from
`roblox/`). Read `CLAUDE.md`, then `SESSION_HANDOFF.md` (the source of truth:
where everything is, what's verified, open decisions), then `ROADMAP.md`
and `TEST_PLAN.md` (the "This round" section is what I'm testing now).

First, start both Rojo servers in the background (Party House
`roblox/game.project.json` on port 34872, Lobby `roblox/lobby.project.json`
on port 34873) so I can sync. Then ask me for my test results from the
"This round" checklist (screenshots and F9 errors) and fix those first.

Then, in order, asking me before each:
1. 10 levels per character (XP and smaller bonuses as proposed in the
   handoff - show me the table first).
2. Muscle's blocked passage + Party Popper (I still need to decide).
3. Gummy floors 2 and 3 (Candy Factory, Jelly Vault), then the Hospital.
4. Halloween polish for live by 29 Oct: first-game tutorial, host balance,
   dressed rooms.

Give me numbered, click-by-click steps for anything I do in Studio or
Creator Hub, surface every gap as a build / fix / close decision with your
recommendation, and end every reply with the STATUS block.
