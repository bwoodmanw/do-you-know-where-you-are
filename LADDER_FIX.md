# Ladder fix: no wasted picks (Brent: yes to A, then B, then C)

**A built 10 Oct** (causes 1 and 2, as in the tables below; Guardian Angel's id
stays `guardian10`, its power is `twoshields`). Wasted picks: 154 -> 110, and
none is wasted every time any more; the 110 left are all cause 3 (limits) = B.

Brent spotted it on Muscle: pick **Master Builder** (recharge 20% faster) at
level 19, then **Fortress** (recharge twice as fast) at 20, and level 19 does
nothing any more. Same with **Mighty** (shove 20% faster) then **Bulldozer**
(instant shove).

`tools/check_ladder_waste.luau` now checks every character: it makes 3,000
random level-20 builds each, takes every pick away in turn and sees if
anything changes. **Today 154 picks can end up doing nothing.** Three causes:

## Cause 1 - a level-10 / level-20 power wipes out earlier picks

| Character | Power | Today | Picks it wipes out | Proposed |
|---|---|---|---|---|
| Muscle | Fortress (20) | recharge x0.5 = the limit | Quick Builder 9, Builder 11, Quick Builder 15, Master Builder 19 (always) | **Two barricades before recharging** (the original plan); recharge picks keep counting |
| Muscle | Bulldozer (20) | instant shove | "Shove X% faster" at 3, 7, 9, 11, 19 | Keep Bulldozer. The shove picks become **"Strong Hands: shove, free friends and open things X% faster"** (what they really do: one hold speed), and Mighty 19 becomes **"the host is stuck at your barricade 2 s longer"** |
| Muscle | Iron Lungs (10) | +50% stamina = the limit | every stamina pick (2, 5, 6, 12, 13, 16) | **Stamina refills twice as fast** |
| Patch | Guardian Angel (10) | recharge x0.5 = the limit | every recharge pick (3, 5, 7, 9, 11, 15, 19) | **Two shields before recharging** |
| Glow | Little Sun (20) | light = 50 | Brighter Bulb 3, Bright Beam 5, Big Lamp 7, Floodlight 9, Searchlight 11 | Light picks add up; Little Sun **adds +10 on top** |
| Echo | Super Burst (20) | burst 15% / 6 s | Bigger Burst 11, Strong Burst 15, Rush 19 | Bursts add up; Super Burst **adds +5% / +2 s** (full: 17% / 7 s) |
| Shadow | Ghost (10) | sneak 14 s | Long Sneak 3, Longer Sneak 5, Phantom 9 | Sneak picks add +2 s each; Ghost **+4 s** (full: 20 s, today 18) |
| Tinker | Rocket Boots (20) | +15% run | the run limit is +20%, so Quick Feet 4, Fast Feet 8, 14, 18 and Quick Dash 19 are wasted 80-90% of the time | **Each Toolkit use gives a 5 s rocket run, 20% faster** (Echo's burst code) |
| Brainy | Genius (10) | +3 clues | the 5-clue limit wipes Bonus Hint 3, Notebook 7, Extra Hint 11, Notes 17 half the time | Extra Hint 11 and Notes 17 become non-clue picks (the Think! arrow stays longer); full = 2 + 3 = 5 exactly |

## Cause 2 - "biggest number wins" picks

Sneak length, clone time, light reach, flare, throw distance, Echo's burst,
vines and barricade hold keep only the biggest pick, so a later one erases an
earlier one (Shadow's Long Sneak 3 is wasted 97% of the time).
**Proposed:** every one of them adds a step instead, sized so taking all of
them gives today's best number. Nobody's best build gets weaker; anyone who
mixed picks gets more.

## Cause 3 - the stacking limits swallow ordinary picks

How far one kind of bonus stacks if every pick of that kind is taken
(limit in brackets; ✗ = past it, so the last picks do nothing):

| | stamina (1.5) | run (1.2) | hold (0.5) | hide (0.65) | recharge (0.5) | clues (5) |
|---|---|---|---|---|---|---|
| Tinker | 1.47 | ✗ 1.41 | ✗ 0.28 (11 picks) | ✗ 0.57 | 0.58 | 2 |
| Shadow | 1.33 | ✗ 1.39 | 0.78 | ✗ 0.56 | ✗ 0.46 | 0 |
| Brainy | 1.47 | ✗ 1.23 | ✗ 0.42 | 0.62 | 0.51 | ✗ 7 |
| Muscle | ✗ 2.53 | ✗ 1.35 | ✗ 0.24 | 0.73 | ✗ 0.22 | 0 |
| Glow | 1.33 | 1.17 | 0.78 | ✗ 0.38 (10 picks) | 0.72 | 0 |
| Patch | 1.47 | ✗ 1.23 | ✗ 0.25 | 0.67 | ✗ 0.13 (8 picks) | 1 |
| Echo | 1.47 | 1.17 | 0.78 | ✗ 0.54 | ✗ 0.29 | 0 |
| Bramble | ✗ 2.04 | 1.17 | 0.50 | ✗ 0.46 | 0.72 | 3 |

**Proposed:** keep the limits (they stop runaway speed), shrink the steps so
a full ladder of one kind lands exactly on the limit, and where a character
has far too many of one kind (Tinker's 11 hand-speed picks, Patch's 8
recharges, Glow's 10 hide picks, Muscle's 9 hold / 7 stamina picks) swap the
extras for something different. Done when `check_ladder_waste.luau` says
**"OK: no pick is ever wasted"**.

## Saves

Pick ids stay, so every saved pick keeps working (with its new meaning).
Because some picks change, give every player **one free Skill Reset per
character** after the update (decision for Brent).
