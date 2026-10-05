# Escape Crew - Roblox version

The experience has **two places**:

| Place (exact name) | What it is | Code |
|---|---|---|
| **Lobby** (the start place - everyone arrives here) | party up 1-6, friends only, difficulty, Giggly/Spooky, invite friends, Start | `lobby.project.json` -> `src/lobby/` |
| **Party House** | the game: a party plays in its own private server | `game.project.json` -> `src/game/` |

Both share `src/shared/` (Config, HouseMap, Places). The names matter: the
code finds each place by name.

```
roblox/
  lobby.project.json, game.project.json
  src/shared/   Config.luau (numbers, skills, icons, difficulty), HouseMap.luau, Places.luau
  src/game/     server: Main, House, Host, Effects   client: Hud
  src/lobby/    server: Lobby                       client: LobbyUi
```

## Getting the code into Studio - two ways

**A. Place files (simplest, no Rojo).** In the game folder:
`EscapeCrew-Lobby.rbxlx` and `EscapeCrew-PartyHouse.rbxlx` (Claude rebuilds
them after every change). In Studio: **File -> Open from File**, then
**File -> Publish to Roblox As...** and pick the matching place.

**B. Rojo (live sync while you work).** One Rojo per place, in PowerShell:

```
.tools\rojo.exe serve roblox\game.project.json --port 34872
.tools\rojo.exe serve roblox\lobby.project.json --port 34873
```

Then in Studio, **Plugins -> Rojo**, set the port, **Connect**.

## One-time setup: the two places

1. Open **Escape Crew** in Studio. This existing place becomes the **Lobby**.
2. **File -> Open from File** -> `EscapeCrew-Lobby.rbxlx` -> **File -> Publish
   to Roblox As...** -> choose *Escape Crew* -> its start place -> overwrite.
3. **Name the start place "Lobby":** Creator Hub (create.roblox.com) -> your
   experience -> **Places** -> the start place -> **Configure** -> Name: `Lobby`.
4. **Add the second place:** in Studio open **Window/View -> Asset Manager** ->
   **Places** -> right-click -> **Add New Place**. Name it exactly `Party House`.
5. Double-click **Party House** to open it. **File -> Open from File** ->
   `EscapeCrew-PartyHouse.rbxlx` is the alternative if publishing into it is
   easier: **Publish to Roblox As** -> *Escape Crew* -> **Party House**.
6. Test the Party House on its own in Studio with **Play** (difficulty and
   character are picked in-game there).

## What only works in the published game

Roblox only moves players between places in the real game, not in Studio:
**Start / Play solo** in the Lobby, **Back to lobby** after a round, and
**Invite friends**. Test those by playing Escape Crew from the Roblox app.
To play with friends, the experience must be **Public** (Creator Hub ->
Settings) - parties stay **Friends only** unless the leader changes it.

## Settings to set once (Game Settings in each place)

- **Security -> Enable Studio Access to API Services**: on (saves points).
- **Places -> Server size**: Party House 6; Lobby 30.
- Creator Hub -> **Maturity & Compliance questionnaire** before going public
  (expected: Mild).

## Characters

Real characters go in the **Party House** place: **ServerStorage -> Characters**
(see `MESHY_GUIDE.md`). Rojo never touches ServerStorage.

## Controls in the game

- Walk: WASD / thumbstick. Run: Shift or the Run button (uses stamina).
- **E** at things: pop balloons, open presents, hide, read, light up, ask the
  plant, shove, free friends, use the keypad. **F** at the keypad: Tinker picks
  the lock. Skill button: Shadow sneaks, Patch heals, Echo throws a noise.
- Jump or "Come out" leaves a hiding place. Caught? Use the spectate bar to
  watch your team.
- F9 opens the Developer Console (errors in red).
