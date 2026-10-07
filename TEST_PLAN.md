# Escape Crew - test plan (6 Oct 2026)

Everything below was built today and has only been checked in code (it
compiles, the analyser passes, the floor plans pass 2,000 random fills). Tick
each line in Studio, then once more in the live game. Send a photo and the F9
(Developer Console) lines for anything wrong.

Studio Play cannot teleport, so the Party House builds `Config.STUDIO_MAP`
(now `gummy`) with a random host (or `Config.STUDIO_HOST`). Ask Claude to switch
either: `partyhouse`, `partyhouse_2`, `partyhouse_3`, `gummy`; host `pumpkin`,
`gummy`, `robot`.

## Fixes and 10 levels (built 7 Oct) - test these first

Lobby:
- [ ] Swings now stand by the party circles on the right with a lamp beside them; new lamps over the whole play lawn; the night is a little brighter
- [ ] Characters screen: name, level and XP bar sit below the portraits (not touching); the 3D character is bigger
- [ ] The ladder shows levels 2-10 and scrolls; levels not reached are locked; picks you made before still show ticked
- [ ] The green reset button shows the real Robux price from Creator Hub

Party House:
- [ ] Character picker: the boosts line ends with "(get them in the Lobby shop)" with the bracket showing
- [ ] Character picker: the level matches the Lobby's ladder screen (it used an old XP table before)
- [ ] Solo: choosing a character does NOT start the game; the clock and host start only after you press Play (with friends: when everyone has pressed Play, or after 2 min)
- [ ] Vents: two or more players can crawl through the same vent one after another; you can't crawl again for about 2.5 s after coming out ("Catch your breath")
- [ ] Bramble's plant has a pink flower with a yellow middle on top (no glowing orb)
- [ ] Muscle: one of the two locked doors is a doorway heaped with junk saying "Blocked!" (red on the corner map); Muscle holds E 3 s and it clears quietly; anyone else gets "Too heavy..."
- [ ] Party Popper: one search spot on the near side holds it ("found a Party Popper!"); at the blocked doorway hold F to plant it; 3-2-1 countdown, BOOM with confetti, the doorway clears and the host comes to look
- [ ] Tinker cannot pick the blocked doorway; the other locked door still works with a key or Tinker
- [ ] No secret hole any more; the Music Room cabinet is just furniture
- [ ] Lobby: the points reset button says 800
- [ ] Sound buttons (Lobby and game): a 🔊 button left of the 🎵 one; 🔊 steps 100 / 50 / 25 / Off for pops, doors, bounces, the host's breathing; 🎵 still only the music; both remembered next visit and between Lobby and game
- [ ] Studio Play now builds the Candy Factory (`Config.STUDIO_MAP = "gummy_2"`): pink candy walls, Conveyor Hall with two conveyor counters, Chocolate River and Packing Hall upstairs behind the doors, stairs up "Up to the Jelly Vault"
- [ ] Ask Claude to switch to `gummy_3` for the Jelly Vault: jelly pool (ball pit), two jelly bounce pads in the Security Room, three vents, exit to the cotton-candy clouds
- [ ] Live: escaping Bounce Hall unlocks Candy Factory; Candy Factory unlocks Jelly Vault; the Lobby map screen shows both floors with their pictures

Patch's face (Party House place, in Studio, NOT playing - press Stop first; the
"Face softening skipped" lines come from Play mode and are expected):
1. **View** tab -> **Command Bar** (a box opens at the bottom).
2. Copy this whole line, paste it in the Command Bar, press **Enter**:
   `local n=0 for _,d in ipairs(game.ServerStorage.Characters.Patch:GetDescendants()) do if d:IsA("SurfaceAppearance") and d.Parent:IsA("MeshPart") then local ok,c=pcall(function() return d.ColorMap end) if not ok or c=="" then local ok2,cc=pcall(function() return d.ColorMapContent.Uri end) c=ok2 and cc or "" end print(d.Parent:GetFullName(),"colour map:",c) if c~="" then d.Parent.TextureID=c d.Parent=nil n+=1 end end end print("Patch: softened",n,"parts")`
3. **View** tab -> **Output** (in the "Show" group; it opens a panel, usually at the bottom). Photograph the line that starts `Patch: softened`. If you can't see an Output button, send a photo of the View tab.
4. If it says `softened 1` or more: **Test** -> **Play** and photograph Patch's face close up.
   Then in Explorer, right-click **ServerStorage -> Characters -> Patch** -> **Save to Roblox...**
   and overwrite the existing Patch asset (if it only offers a new one, save it and send Claude the new id).
5. If it says `softened 0`: send the Output photo; the blotches are in the picture itself.

## Built 6 Oct late

Lobby:
- [ ] Characters screen: a portrait on every character button; the arrows under the 3D view step through characters
- [ ] Leaderboards: a round avatar picture beside every name
- [ ] Party leader taps the map button: building cards with pictures, then floor cards; a second player sees the same screen and both votes (with names) show at once; Done closes it for everyone
- [ ] Swing set: sit on either swing and it swings; two players at once
- [ ] Soccer ball: walk into it and it rolls; it comes back if it leaves the lawn

Party House:
- [ ] Character picker shows the portrait in the info panel
- [ ] Active boosts row (above the bag): Shield shows "ON" after a present gives one; Candy counts down; Frozen Pop counts down 10 s
- [ ] Patch: a friend standing near her gets "+50% stamina" (not more than once every 10 s); her Shield button still works
- [ ] Freeing a friend takes 3.5 s; Patch takes about 1.75 s
- [ ] Empty search spot: bats fly out, or tissue paper floats down, or confetti, with a matching message; an empty present drops tissue paper
- [ ] Hiding places have a monkey 🙈 above them and say Fits 1, 2 or 3 (wardrobes 3); every two joined rooms have one between them
- [ ] Party clutter in the middle of rooms, not solid: cake (Blow out the candles; they relight after 40 s), jack-in-the-box (pops and the host comes to look), pile of presents (Shake: tissue paper), chair with balloons
- [ ] Patch's face: F9 shows "Face softening skipped for Patch..." if the in-game fix cannot run - then do the Studio fix

## Lobby (Escape Crew place, Rojo port 34873)
- [ ] House model in place, facing the lawn; no glowing boxes in front of it
- [ ] A host face in a window every 18-40 s, lined up with a window (exact: add Parts named PeekSpot on the windows)
- [ ] Daily reward pop-up on the first visit of the day; next day = day 2; a missed day = day 1
- [ ] Cannot walk round the side or back of the house
- [ ] Shopkeeper: glasses, cap, grin; waves
- [ ] Drive-in car: sit, faces the leaderboards
- [ ] Trampoline bounces you; kick ball rolls and comes back; pumpkin giggles; bell rings
- [ ] 5 leaderboards readable
- [ ] Music plays; music button steps 100 / 50 / 25 / Off and is remembered next visit
- [ ] Shop: 6 boosts with pictures, + buys, - sells back, Take / Taking, R$ buttons
- [ ] Characters screen: every character in 3D (drag to turn), locked upgrades, Reset
- [ ] Invite list: players in this Lobby (one tap, pop-up Join for them) and friends online (Roblox invite)
- [ ] Party circle on the lawn: members stand round it; sign shows x / y and status; others can Join party at it
- [ ] Party panel: floor buttons (Ground, Bedrooms, Attic, Bounce Hall; others "coming soon")
- [ ] Live only: Start takes the party to the chosen floor

## Party House place (Rojo port 34872), each floor
- [ ] Nobody starts as Tinker; the banner waits for everyone to choose; the timer and host start only then (or after 2 min, undecided players get a random character)
- [ ] Picking a character works until the host comes out; then Change is hidden
- [ ] Every imported character looks right; faces smooth, no flickering shadows
- [ ] The corner map draws this floor; N toggles it; Loft / Ground switches on loft floors
- [ ] Locked doors: key found in a search spot (gold key floats up) or Tinker picks it
- [ ] Opened things open: lids, drawers, coats, vases, presents
- [ ] Trick balloons pop with nothing inside; real ones show a colour
- [ ] Hiding spots say Fits 1 / 2 / 3 and keep to it
- [ ] Vents: Crawl takes you to the next room; the host cannot follow
- [ ] Clues cost 10 / 20 / 30 points from this game; the points line counts up
- [ ] The host walks faster than you walk, slower than you run
- [ ] Caught: close-up of the host's face (the right way round), then the cage
- [ ] Boosts in the bag: Candy, Second Wind, Extra Clue, Frozen Pop work when tapped
- [ ] Music and the music button
- [ ] Players button: list of everyone with character, state and points; closes with X
- [ ] Lobby button asks first; live it takes you back to the Lobby (Studio says it only works live)

Per floor:
- [ ] Ground: garden exit; Muscle's hole in the Music Room
- [ ] Bedrooms: Gallery loft and ramp (ramp the right way round); stairwell exit
- [ ] Attic: rafters, 3 vents, "Out onto the roof!" exit
- [ ] Bounce Hall: candy colours, ball pit, slide-tower loft, bounce pads, cloud exit

Per host:
- [ ] Pumpkin: winds up and throws a glowing pumpkin with a trail you can dodge; a hit knocks you down 2 s (F9 in Studio: "[host] throwing a pumpkin")
- [ ] Gummy Bear Man: puddles stick you 3 s; never more than 4; never by doors
- [ ] Robot: his room goes dark for 8 s as soon as you are in the same room; his eyes glow red

## Live game (after publishing both places)
- [ ] Lobby -> chosen floor -> results -> Play again / Back to lobby
- [ ] Escaping a floor unlocks the next one (and Bedrooms unlocks Bounce Hall)
- [ ] Robux purchases arrive (try the cheapest)
