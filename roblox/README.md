# Escape Crew - Roblox version

The game's code lives here as files. **Rojo** syncs them into **Roblox Studio**
while Studio is open, so a change Claude makes appears in Studio within a
second. Brent tests with **Play** and releases with **Publish**.

```
roblox/
  default.project.json      where each folder goes inside the game
  src/shared/Config.luau    numbers, skills, phrases, asset ids
  src/shared/HouseMap.luau  the Party House layout (same as the web version)
  src/server/Main.server.luau   the referee: rounds, prompts, skills, win/lose
  src/server/House.luau     builds the house in 3D from the layout
  src/server/Host.luau      the pumpkin host and its brain
  src/client/Hud.client.luau    everything on a player's screen
```

## First-time setup (Brent)

1. **Roblox Studio** is already installed. Open it and sign in with your
   Roblox account.
2. **New** -> **Baseplate**. In the Explorer on the right, click
   **Workspace -> Baseplate** and press Delete (the house has its own floors).
3. **File -> Save to Roblox As...** and call it *Do You Know Where You Are?*
   (this creates the game on your account; it stays private until you choose).
4. Claude starts Rojo (`rojo serve`) and installs its Studio plugin.
5. In Studio: **Plugins** tab -> **Rojo** -> **Connect**. The house appears.
6. Press **Play**.

## Settings to set once (Studio -> Home -> Game Settings)

- **Security -> Enable Studio Access to API Services**: on (saves points).
- **Places -> Server size**: 6.
- **Avatar**: leave R15 (kids keep their own avatars).
- Before publishing publicly: Creator Hub -> the game -> **Maturity &
  Compliance questionnaire** (expected label: Mild).

## Controls in the game

- Walk: WASD / thumbstick. Run: Shift or the Run button (uses stamina).
- **E** at things: pop balloons, open presents, hide, read, light up, ask the
  plant, shove, free friends, use the keypad. **F** at the keypad: Tinker picks
  the lock.
- Skill button: Shadow sneaks, Patch heals, Echo throws a noise (then tap a
  spot). Other skills work by walking up to things.
- Jump or "Come out" leaves a hiding place.
