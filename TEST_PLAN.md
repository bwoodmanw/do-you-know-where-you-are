# Escape Crew - test plan (updated 8 Oct 2026)

**Start with rounds 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12 (top): built 7-8 Oct, not yet play-tested.**
Studio Play builds `Config.STUDIO_MAP` (now `carnival`, the Carnival's
Midway); ask Claude for any other floor (`partyhouse`, `partyhouse_2`,
`partyhouse_3`, `partyhouse_b`, `gummy`, `gummy_2`, `gummy_3`, `hospital`,
`hospital_2`, `hospital_3`, `school`, `school_2`, `school_3`, `carnival_2`, `carnival_3`) or `Config.STUDIO_TOWER` for a
Tower Run.

Everything below was built today and has only been checked in code (it
compiles, the analyser passes, the floor plans pass 2,000 random fills). Tick
each line in Studio, then once more in the live game. Send a photo and the F9
(Developer Console) lines for anything wrong.

Studio Play cannot teleport, so the Party House builds `Config.STUDIO_MAP`
(now `gummy`) with a random host (or `Config.STUDIO_HOST`). Ask Claude to switch
either: `partyhouse`, `partyhouse_2`, `partyhouse_3`, `gummy`; host `pumpkin`,
`gummy`, `robot`.

## Round 24 (8 Oct) - the Candy Shop and Mummy Muscle
- [ ] Lobby: the banner at the bottom now says "Candy Corn Hunt: n found (m to spend) - Shop"; tap it: the Candy Shop opens (6 boosts with a candy-corn price)
- [ ] Buying with enough corns: the boost is added, "to spend" goes down, "found" does not; with too few: "You need ... (you have ...)"
- [ ] A corn-bought boost has no points refund with the - button
- [ ] Once Mummy Muscle's model is in (Claude switches it on): Characters -> Muscle shows "Mummy Muscle (n/100)"; at 100 found it can be worn (owner and Studio: always)

## Round 23 (8 Oct) - the Halloween Candy Corn Hunt (until 1 Nov)
- [ ] Every floor: 6 glowing candy corns (yellow, orange, white) bobbing on the floor, spread out, some behind the locked doors
- [ ] Walk into one: it pops, "+3 (n / 50)" for you only, your points go up
- [ ] Lobby: a banner at the bottom "Candy Corn Hunt: n / 50 found - on every floor until 1 Nov" (photo: does it cover anything?)
- [ ] At 50: "Candy Corn Collector!" for everyone, and (live, once its id is in) the badge
- [ ] After 1 Nov the corns and the banner are gone by themselves

## Round 22 (8 Oct) - the Sunken Aquarium (building 6, AQUARIUM.md) and the Anglerfish Keeper

Studio Play now builds the Aquarium's Main Hall (`aquarium`); ask for `aquarium_2` / `aquarium_3`. For his power ask for `Config.STUDIO_HOST = "anglerfish"`.
- [ ] Main Hall: Entrance Hall start; Great Tank Hall's round tank with a shark circling and fish; the Shark Tunnel's glass walls (see-through, fish) wind round; fish tanks, Touch Pools (wade slowly), Jellyfish tanks glow
- [ ] Deep Sea: Kelp Forest, Anglerfish Den and Coral Cave start dark (the light switch turns them on); Whale Skeleton Hall two storeys with whale bones; Bubble Vents bounce you up; Pipe Room "Water pipe" -> "SPLASH!" in a far room; a yellow submarine; "Up to the Rooftop Pools"
- [ ] Rooftop Pools: Sea Lion Stadium start; Pump Room whirlpool turns you; Penguin Ice (ice walls, wobbling penguins); Otter / Rock Pool wading; Splash Slide; "Down the water slide!"
- [ ] The Anglerfish Keeper: while he patrols he leaves presents (up to 3); opening one: "It was a trick present!", you glow, he comes to look; as Brainy or Glow: "Pop it - it's a fake!" (F / Y) pops it safely; they vanish after a minute
- [ ] Lobby: six building cards in a row; escaping Carnival: Big Top unlocks the Aquarium (live)

## Round 21 (8 Oct) - quick chat (needs two players for the pins: Studio Test -> Clients and Servers -> 2 players)
- [ ] Say (T on a keyboard, Right on a controller): 16 phrases in 4 rows; the ones with a pin mark: Over here!, I found something!, Key found!, Help me!, Need Tinker!, Need Brainy!
- [ ] A phrase shows as a cream bubble over your head for 4 s (seen by everyone, even with chat off)
- [ ] A pin phrase: the other player sees a pin and "Name: Over here!" where you stood, through walls, for 6 s
- [ ] More than 3 phrases in 10 s: "Too many messages - wait a moment."
- [ ] Live (after publishing): a daily reward notification arrives the next day (13+ account, said yes) - needs NOTIFICATIONS.md steps 2-4 done

## Round 20 (8 Oct) - the Anglerfish Keeper's lure

He is hidden (never picked at random) until the Aquarium is built. Ask Claude to set `Config.STUDIO_HOST = "anglerfish"`.
- [ ] A glowing yellow ball on a short stalk above his forehead, softly pulsing, lighting the room round him; it stays on his head as he walks and runs
- [ ] Photo: is the stalk lined up with the stub on his head? (tell Claude to move it up / forward / back)

## Round 19 (8 Oct) - the Clown Bear's Jack-in-the-Box (CARNIVAL.md)

Ask Claude to set `Config.STUDIO_HOST = "clownbear"` (the built host in pink until HostClownBear is imported).
- [ ] At the start (before he comes out): 4 purple-and-orange boxes with a crank on Normal (3 Easy, 5 Hard, 6 Nightmare), none in the starting room or in a doorway
- [ ] Walk up to one: it springs (a clown head on a spring, a noise), "BOING! A jack-in-the-box gave ... away!", you glow pink for 3 s, and once he is out he comes to look
- [ ] It closes again after about 30 s in the same place and can spring again
- [ ] Shadow sneaking, or anyone hidden or in a vent, does not set it off
- [ ] As Tinker: "Wind it down" (F / Y, hold 2 s) removes it for good; Tinker can do several; others see no prompt
- [ ] On the Carnival he is the host about half the time ("Tonight's host: the Clown Bear")

## Round 18 (8 Oct) - the Creepy Carnival (building 5, CARNIVAL.md) and badges

Studio Play now builds the Carnival's Midway (`carnival`); ask for `carnival_2` / `carnival_3`.
- [ ] Midway: Ticket Booth start (ticket window), dark red tent walls; the Carousel turns slowly with six painted horses and bulbs - hop on and it carries you round; you can hop off
- [ ] Hall of Mirrors: a little maze of mirror walls (shiny), both doorways reachable; Popcorn Stand and Toffee Apple Stall carts, Duck Pond with bobbing ducks, Ring-Toss stall with an awning, Prize Tent prize walls
- [ ] Fortune Teller's Tent behind the first lock (glowing crystal ball "Your future: RUN!"), Main Gate way out behind the second
- [ ] Big Top (`carnival_2`): The Ring two storeys high with a balcony and red/blue circus seats; Trapeze Nets has 3 bounce pads; Cannon Deck: "Climb in!" on the human cannon -> "BOOM!" and you land in the safety net in a far room; Clown Car Garage, Costume Wagon racks, Juggler's Room, Band Stand drums, Strongman "1 TON"; "Up to the Funhouse"
- [ ] Funhouse (`carnival_3`): Spinning Room floor turns (stand on it); Slide Tower "Slide down" -> a heap of balls in a far room; Ball Pit, wavy fun mirrors, Tilted Room crooked pictures, Bumper Cars, Joke Shop, rolling barrel scenery; "Out onto the Big Wheel!"
- [ ] Lobby map screen: five building cards in one row (narrower), names readable; escaping School: Classrooms unlocks the Carnival (live)
- [ ] Badges (live only): escaping the Secret Basement no longer gives the Party House badge; Tower Run to the top gives Tower Climber (once its id is in)

## Round 17 (8 Oct) - the Caretaker's Lock-up (SCHOOL.md)

Ask Claude to set `Config.STUDIO_HOST = "caretaker"` (he is the built host in
green until his model is imported as ServerStorage/Characters/HostCaretaker).
- [ ] Let him see you and run: a gate of iron bars with crossed chains and a brass padlock appears in a doorway ahead of you (not behind you), with "Jangle jangle... the Caretaker padlocked a doorway!"
- [ ] You can't walk or jump through it; he walks straight through it
- [ ] It goes after 6 seconds
- [ ] As Tinker: "Pick the lock" (F / Y) opens it at once; other characters see no prompt
- [ ] Never on a locked door, the exit or the host's door; never on top of a kid
- [ ] On a School floor he is the host about half the time; the start message says "Tonight's host: the Caretaker"

## Round 16 (8 Oct) - Midnight School (building 4, SCHOOL.md)

Studio Play now builds the School's Ground Floor (`school`); ask for `school_2` / `school_3`.
- [ ] Ground Floor: Assembly Hall start (rows of chairs, trophy cabinet), the Long Hallway across the middle (lockers), Head's Office behind the first lock (filing cabinets, globe, chalkboard), Front Lobby way out behind the second; Cafeteria, Kitchen, Music Room (drums), Art Room (easels), Lost Property, Staff Room
- [ ] Green walls, cream ceilings, warm lamps; wooden tables on metal legs and pairs of little desks with blue chairs (none can be walked through); school pictures on the walls
- [ ] Classrooms (`school_2`): the two-storey Library with a balcony and ramp; classrooms with a chalkboard (something chalked on it) and rows of desks; Science Lab behind the first lock; Upper Stairs and "Up to the Clock Tower"
- [ ] Clock Tower (`school_3`): Exam Hall start, Bell Room (ring the big bell - the host comes), Observatory telescope, Old Classroom behind the first lock, Clock Tower way out "Out onto the tower roof!"
- [ ] Lobby map screen: four building cards in a row (the School's is plain until its picture exists); escaping Hospital: Wards unlocks the School (live)
- [ ] Tower Run works in the School

## Round 15 (8 Oct) - Tower Run

To try it in Studio, ask Claude to set `Config.STUDIO_TOWER = true` (Studio
then starts a Tower Run from floor 1 of STUDIO_MAP's building).
- [ ] Lobby map screen (leader): "🗼 Tower Run: off" beside Done; tapping it turns it ON (blue) once the leader has reached the building's top floor, otherwise "Tower Run opens once you have reached ..."; the party panel's map button adds "· 🗼 Tower Run"
- [ ] Start: the game begins on floor 1 of that building whatever floor was voted; the top bar shows "🗼 1/3 · ..."; the timer is 2.5 times a normal floor's
- [ ] Clearing floor 1 (or 2): "🗼 Floor cleared! Up to the ... - keep going, the clock is still running!", 4 s later the next floor is built; nobody picks a character again; the same host comes out after 8 s; points this game carry on; the timer keeps counting down
- [ ] Caught on floor 2 or 3: results "Tower Run: caught on floor N"
- [ ] Reaching the top: results "Tower Run: you reached the top! (+25%)", everyone's points this game +25%; no "Next floor" button
- [ ] Play again after a Tower Run: starts again from floor 1
- [ ] Studio Play builds STUDIO_MAP even when it has no teleport data (it used to fall back to the Ground floor)

## Round 14 (8 Oct) - Basement, weekly quests, clue log

Studio Play now builds the **Secret Basement** (`partyhouse_b`).
- [ ] Basement: Cellar Entrance (start, bottom middle), Boiler Room (boiler and pipes, red warning light), Coal Store, Workshop, Laundry (with the laundry chute), Old Storage, Wine Cellar (behind the first locked door), Cellar Stairs (the way out, behind the second, "Up the cellar steps and out!") and Pumpkin Cellar; brick pillars; drips and dust; no windows
- [ ] Lobby map screen: the Party House shows four floor cards (Ground, Bedrooms, Attic, Secret Basement) side by side; the Basement is locked until the Attic is escaped (live), then opens
- [ ] Escaping the Basement: no "Next floor" button; it does not count for the "all floors" badge
- [ ] Lobby -> Daily quests: three daily rows and three weekly rows ("Weekly quests", each with points and a boost icon, "New on Monday (in Nd Nh)"); finishing one in a game says "Weekly quest done: ... and a Frozen Pop" and the boost is in the shop bag
- [ ] Clue log: after the first clue a "📜 Clues (1)" button; it opens every clue this game, newest first; a Mastermind route opens it by itself, one step a line; it empties when a new game starts
- [ ] (8 Oct: the arms-down change was undone - it shrank the arms; T-posed models stand in their T-pose)

## Round 13 (7 Oct, late) - fixes from Brent's play test

- [ ] Caught while crawling through a vent or the laundry chute (the host only catches you there in a frenzy): you appear in the cage, everyone can see you, friends can free you
- [ ] Anyone caged always stays in the cage (if something moves them out, they are put straight back)
- [ ] Characters with "one code colour" on their ladder (Tinker, Brainy, Glow 3; Bramble 5): one colour shows on the code bar when the clock starts, on every floor and in the first game too (it used to come from the character you played LAST game); only ONE colour a game however many players have it; none on Nightmare
- [ ] Ladder "+1 clue" upgrades: when the clock starts "+N free clues from your upgrades"; the Clue button says "Clue FREE" and no points are taken until those are used
- [ ] Lobby: the host's face (or shadow) keeps peeking in a window every 18 to 40 seconds for as long as the server runs; F9 Server never shows "Lobby peek failed" (if it does, photo please)
- [ ] Skins in Studio: Lobby -> Characters -> Tinker -> Skins row -> Pumpkin Patch Tinker: the 3D view shows the pumpkin outfit (and Shadow -> Ghostly Shadow)
- [ ] Muscle (new model id): plain trainers, in the Lobby Characters screen and in the game; Echo (new id): the remade face

Brainy's new ladder (BRAINY_LADDER.md) - give a test Brainy the XP in Studio or play up to the level:
- [ ] Characters -> Brainy: levels 3, 5, 7, 9, 10 show the new choices; a level where an old choice was taken (Code Sense, Clever, Focus, Big Brain, Speed Reader) can be chosen again
- [ ] Trick Spotter (3): when the clock starts, the trick balloons go grey, see-through and droop; "Brainy spotted the trick balloons"
- [ ] Two-Step Clue (5): a clue lights two things (green, then yellow) and says "Then: ..."
- [ ] Key Finder (7): a key on the corner map in each room that hides a key or a Confetti Cannon (once you have been in the room); it goes once it is found
- [ ] Long Read (9): the invitation's Read prompt appears from twice as far
- [ ] Mastermind (10): "+1 free clue" at the start; the first clue says "Mastermind route: 1) ... 2) ... 3) ... 4) type the code on the keypad in the ..."; later clues are normal

## Round 12 (7 Oct, fourth session) - the rest of IMPROVEMENTS.md - test these first

Studio Play builds the Candy Factory (`gummy_2`). For the vault ask for
`gummy_3`; for the laundry chute `partyhouse_2`, `hospital` or `hospital_2`.

Controller (B10) - plug an Xbox / PlayStation controller into the PC, or in
Studio **Test** tab -> **Device** -> an Xbox; tags like "RB" appear on buttons
only while you use the controller:
- [ ] Character picker: the Choose button is picked (white outline); LB / RB step through characters; the right stick turns the model; the left stick moves between buttons, A presses; B closes it (= ready)
- [ ] In the game: LT (hold) runs, clicking the left stick keeps running; RB uses the skill (Echo throws at the middle of the screen); LB uses the first boost; D-pad Up = clue (before the start: I'm ready), Left = map, Right = chat phrases, Down = players list; A comes out of hiding
- [ ] Prompts: X for E prompts, **Y** for Tinker's pick / the keypad pick / planting a Confetti Cannon (never two prompts on one button)
- [ ] Keypad: the first colour is picked, A presses, B closes; results: Play again (or Next floor) is picked
- [ ] Caught: LB / RB switch who you watch
- [ ] Lobby: D-pad Up jumps into the menu (Quick Play); LT runs; Shop, Characters (LB / RB, right stick), How to play, Daily quests, map screen, invite list, daily reward: the first button is picked, B closes
- [ ] The Look (M) button is gone when there is no keyboard

Friends bonus (B6):
- [ ] Two accounts that are Roblox friends in one game: under the stamina bar "👫 +10%"; results show "👫 +N friend bonus" (live only - Studio test players are not friends)
- [ ] Lobby party panel: "👫 Play with a Roblox friend: +10% points!"

Chocolate river (C4) - Candy Factory:
- [ ] The two chocolate channels are at floor level now (low caramel banks, marshmallows bobbing); walking in the chocolate is half speed and says "Wading through chocolate"
- [ ] A wooden footbridge (with ramps and rails) across the middle of each channel: full speed on it
- [ ] The host walks round the chocolate when he can, and is slow in it too

Rejoin (B11) - live only, needs two players:
- [ ] Two players in a game; one closes Roblox mid-game (or switches off Wi-Fi), opens Escape Crew again: in the Lobby "You dropped out of ... Go back in?" -> Rejoin: back in the same game with the same character (caged if they were caged, in the garden if they had escaped), "... is back in the game!"
- [ ] "No thanks" makes it go away; leaving on purpose (Lobby button, Back to lobby) never offers it

Daily quests (B5):
- [ ] Lobby menu: "📜 Daily quests 0/3" opens three quests with bars and points and "New quests in Xh Ym"
- [ ] In a game, finishing one: a 📜 pop-up "Quest done! +N" and the message; back in the Lobby the bar is full and ✅
- [ ] The next day (UTC) three new quests

Notifications (B7): see `NOTIFICATIONS.md` (Creator Hub first; live only)
- [ ] After pressing Yay! on the daily reward (13+ account): Roblox asks about notifications; the next day "Your Escape Crew daily reward is ready"

Laundry chute and vault (C4):
- [ ] Bedrooms (Linen Room), Hospital Ground (Laundry), Wards (Linen Room): a steel hatch "LAUNDRY CHUTE" on a wall; hold E "Slide down": you vanish, "Wheee!", and land in a laundry basket in a far room (Kids' Bedroom / X-Ray Room / Children's Ward); one way; the host can't follow
- [ ] Jelly Vault, Vault Door Hall: a giant round gold door with a wheel and "VAULT" sign in the outer wall; hold E 4 s: the wheel spins, CREAK (the host comes to look), the door swings open; inside a little steel vault with a chest and gold; "Grab the treasure": +25 to 50 points each and a free clue for the team

Windows (C7):
- [ ] One or two windows on the outside walls of most rooms: a night sky with stars, the moon (a bat on it), black hills and trees (candy-pink sky and clouds in the Gummy House, town lights at the hospital), a pale moonbeam into the room
- [ ] Windows never cover a picture, a shelf, a set piece or a doorway; none in vault, boiler, generator, store or locker rooms

Skins (B9): see `SKINS.md` - free to try in Studio once a model is in ServerStorage/Characters; hidden live until its Game Pass id is in Config
- [ ] Lobby (Studio): Characters -> Tinker: a Skins row (Plain, Pumpkin Patch Tinker); choose it; Party House: Tinker uses the TinkerPumpkin model; the picker's 3D view shows it too
- [ ] Daily quests never include "Play a game with a friend"

Earlier: F9 showed "The experience doesn't have access permission to use asset id 11490522280" (not from our code - see the finder in the session notes).

## Hospital, Halloween and fixes (built 7 Oct, evening)

Round 11 (7 Oct) - the improvements list:
- [ ] Saves: play a game, go back to the Lobby, play again - points, XP and boosts always carry over (the next place may wait a second or two)
- [ ] A sign over every doorway naming the room beyond (on both sides)
- [ ] Room sounds (quiet; the 🔊 button controls them): boiler/generator hum, factory clatter, fireplace crackle, clock ticking, attic wind, hospital beeps and buzz, bubbling chocolate and jelly, dripping in bathrooms and the archive
- [ ] Effects: steam (boiler, generator, laundry), dust (attic and storage), bubbles (chocolate), sparkles (vault, gold), mist (jelly pool); room light colours; a slow red warning light in boiler and generator rooms
- [ ] Light switch on a wall of each Party House / Hospital room: "Lights off" makes the room dark on your screen and the host sees you less far; when the host walks in he switches it back on
- [ ] Noisy things: switch on a TV, radio, drums or arcade machine - a sound plays and the host comes to look (40 s before it works again)
- [ ] Candy Factory: stand on a conveyor belt in the Conveyor Hall / Factory Floor / Wrapper Room and it carries you along
- [ ] Colour pictures: red heart, blue drop, yellow star, green clover on balloons, the code bar, the keypad buttons and the painted wall
- [ ] Lobby: green "Quick Play" at the top of the menu - joins an open party, or starts a solo game on your next unbeaten floor (live only)
- [ ] First ever escape: a few seconds after the results, Roblox asks "add to favourites?"
- [ ] Badges (after they are made in Creator Hub and their ids added): awarded at the results

Round 10 (7 Oct):
- [ ] Team items above the active boosts (gold border): a key icon with the door's name for each key found (gone once that door opens), and a confetti icon with x N for the team's Confetti Cannons (stays through a cage)
- [ ] Lobby: hold Shift (or the Run button on a phone) to run, no stamina limit
- [ ] Lobby party panel: the map button says just "Tap to choose a map" (others: "The leader chooses a map")
- [ ] Jelly Pool: the pool is wobbling jelly (no balls); every other jelly tile bounces you up; four jelly cubes round the room
- [ ] Sticky Archive: honey-coloured walls, three filing cabinets with an ARCHIVE sign, paper stacks, honey dripping down a wall
- [ ] Gummy Bear Man's puddles: a sticky heap of little gummy bears on the goo (still sticks you 3 s)
- [ ] Every room: a floor that matches its walls (concrete in boiler rooms, steel plate in factories and labs, wood in halls, carpet in parlours and bedrooms...) and two to four set pieces

Round 9 (7 Oct):
- [ ] After Play again OR Next floor (door / button): the character picker opens again with your last character ready; Change works; the game waits for everyone's Play
- [ ] Results appear at the end of every game (they could fail after the Next floor change - fixed)
- [ ] Ground floors with a floor above (Party House Ground, Bounce Hall, Hospital Ground): stairs, a landing and a glowing door in the garden / clouds, sign "Up to the Bedrooms" / "Up to the Candy Factory" / "Up to the Wards"; candy-pink steps in the Gummy House, grey concrete at the Hospital
- [ ] Every floor's sign names the floor above; top floors (Attic, Jelly Vault, Labs) keep their own sign and the door says you made it

Round 8 (7 Oct):
- [ ] Chocolate River: the two long benches are now chocolate river channels with caramel banks and marshmallows bobbing along; a chocolate waterfall on a wall
- [ ] Upper floors' way out: the glowing door no longer flickers; a big orange sign "Up to ..." with "Step through when the game ends"
- [ ] Walking into the door during the game: "Wait here for your crew! When the game ends, step through to go up together."
- [ ] After a win: a green "Next floor: <name>" button on the results; stepping through the door also chooses it; if most of those staying choose it, the next floor is built (a tie goes up)
- [ ] Lobby: no Windows button (Config.WINDOW_SETUP = false); the faces stay where you clicked them

Round 7 (7 Oct) - rooms that look like their names (Rooms.luau):
- [ ] Every room has its own walls: brick (boiler, generator, water tank, docks, ambulance bay), steel (conveyor, factory, labs, X-ray, vault, lift), tiles (kitchens, bathrooms, laundry, canteen, pharmacy), wallpaper colours (parlour red, library green, bedrooms blue, nurseries pastel...), wood panelling in halls and attic rooms
- [ ] Set pieces: Boiler Room boiler with a glowing furnace and pipes; Conveyor Hall two moving conveyor belts (sweets ride along) and a candy machine; Chocolate River a chocolate river and waterfall; Vault Door Hall a giant round vault door; Ambulance Bay an ambulance with flashing lights; X-Ray Room the machine and a glowing x-ray; wards curtains and drip stands; Waiting Room rows of chairs and a TV; Parlour/Library a fireplace that flickers; Game Room arcade machines; Clock Room clocks with swinging pendulums; gummy bear statues, lollipops, wobbling jelly cubes, gold gumdrops in the candy rooms
- [ ] Nothing new blocks a doorway, hiding place, search spot or the start
- [ ] F9: no "Room dressing: ... failed" lines

Round 6 (7 Oct):
- [ ] Bonus present: everyone in the game gets their own +20 to +60 points (pop-up shows the exact number), sometimes plus a free clue or a Shield for the opener
- [ ] Every room: a little spider going up and down on a thread, orange/purple lights along the top of a wall; every third room a floating ghost
- [ ] Lobby: orange/purple lights strung across the lane, hay bales with pumpkins by the gate, friendly tombstones (BOO!), a ghost drifting over the lawn, a light purple haze

Round 5 (7 Oct):
- [ ] Studio Play builds Hospital: Wards (`hospital_2`): Ward A/B and Children's Ward with beds, Linen Room towels, Medicine Store, stairs "Up to the Labs"; ask for `hospital_3` (Labs: Science Lab benches, Plant Lab planters, Generator Room tanks, "Out onto the helipad!")
- [ ] Lobby map screen: Hospital shows 3 floors (Wards and Labs use the Hospital picture for now)
- [ ] Rooms say what they are: bathrooms have a toilet, sink and mirror; Clock Room grandfather clocks; Boiler / Generator / Water Tank rooms tanks and pipes; storage rooms stacked crates; plant rooms potted plants; offices a desk and lamp; halls and landings a long runner
- [ ] Shelves: Records/Office/Study/Archive files, Locker Room lockers, Linen towels, Children's Ward toys
- [ ] Muscle's crates: arrows and a big arm painted on every side, "Barricade crate - Muscle" over it; Muscle's prompt says "Move Barricade"
- [ ] Bonus clues are FREE: from a present, the Extra Clue boost or a ladder upgrade the Clue button says "Clue FREE" and no points are taken
- [ ] Lobby menu: smaller text, more space between buttons; Balance and Windows buttons sit to the right of the menu, not on it
- [ ] How to play: scrolls, covers leader/Ready, balloons, keys, blocked doors and Poppers, store rooms, hiding (Space), vents, Barricade, Echo/Shadow/Patch, cage, clues, boosts, levels, 9 floors
- [ ] Window faces (owner, live or Studio with API access): 🪟 Windows -> click the middle of each window -> Save -> Test: the host peeks in each, in turn
- [ ] Soften Patch (Studio STOPPED): a small "Soften Patch" window says "Done! Softened N parts"; while playing it says "Press Stop first"

Round 4 (7 Oct):
- [ ] Top of the screen: the timer/code bar stops before 🔊 and 🎵; Players and Lobby sit under 🎵; the song name sits under Lobby (nothing overlaps)
- [ ] Lobby: Friends' parties box starts below the points and sound buttons
- [ ] The host never stays pressed into a wall (after 4 s he pops back onto the floor)
- [ ] Play again: closing the picker with X counts as ready; while waiting, an "I'm ready!" button under the banner
- [ ] Only the party leader can change Difficulty and Giggly/Spooky ("The party leader picks these" for others)
- [ ] Confetti Cannons: "Team Confetti Cannons: N" above your bars; any Popper opens any blocked doorway; it stays after a cage
- [ ] Shelves match the room: pantry/kitchen food, bathroom towels, nursery toys, store boxes, library books; no rug in pantry/bathroom

Round 3 (7 Oct):
- [ ] Lobby house sits on grass (ground now continues under it) and is 6 studs nearer the lawn
- [ ] Window faces: on the windows, on the house's surface (not floating in front of the porch)
- [ ] Studio, Party House place, stopped: Plugins tab -> Escape Crew -> Soften Patch; Output says "softened N parts"; Play: Patch's face smooth

Round 2 (7 Oct, late):
- [ ] Lobby house level: front no longer lifted (`LOBBY_HOUSE_TILT` 5 degrees, sink 0.5); no face above the roof
- [ ] Lobby (owner only): a 📊 Balance button bottom-left opens the host-balance table (Refresh, Close); it fills as games finish
- [ ] Characters screen: the whole description fits (text shrinks to fit)
- [ ] Gummy floors: candy-jar shelves (no bookshelves), sweet conveyor belts, chocolate vats, gumball machines, marshmallow beds, frosted tables, candy-coloured bunting
- [ ] Hospital: medicine cabinets, green reception counter, steel tables, beds with rails
- [ ] Muscle at a 💪 crate: a "Barricade" prompt (E) - works like the button, shows the recharge
- [ ] Jack-in-the-box: wind the crank, the lid flips, Jack pops up on a spring - collar, grinning face, jester hat with bells
- [ ] Caught close-up and the scare: the host's whole face on screen (aimed lower)

Studio Play now builds the Hospital (`Config.STUDIO_MAP = "hospital"`).

Lobby:
- [ ] The house sits on the ground (no gap under the porch); if still off, say up or down and roughly how much
- [ ] Faces in the windows line up (upper right no longer above, lower left no longer to the side)
- [ ] Cars: two on the left lined up facing the house; three on the right facing the leaderboards (outer two angled in), the yellow one furthest back
- [ ] Round the edge: an iron fence, bare and leafy trees, glowing jack-o'-lanterns (no bare walls)

Party House / any floor:
- [ ] Echo runs smoothly (no shaking); every character's feet on the floor
- [ ] Echo's noise: throw it behind the host while he chases you - he turns and goes to it for about 5 s
- [ ] Prompts: Tinker sees only "Pick the lock" at locked doors, everyone else only "Unlock"; Muscle sees only "Shove" at blocked doors, everyone else only "Plant Confetti Cannon" (without one: "You need a Confetti Cannon..."); Tinker's "Pick the keypad" sits below "Use keypad"
- [ ] Halloween: orange / purple / black bunting, two paper bats turning slowly in each room
- [ ] First game (an account with 0 or 1 games): a "Tip 1 of 6" card on the left; tips move on as you pop a balloon, meet a locked door, the host comes out, someone is caught, the code is known; Next and X work

Hospital:
- [ ] Pale green walls, white / mint / grey floors, a flickering strip light in each room, no party flags or rugs
- [ ] Reception (start) at the bottom, the Main Corridor across the middle, Pharmacy behind the first door, Ambulance Bay (exit) behind the second
- [ ] Wheelchairs you can Spin; a Store Room and a Junk Cupboard
- [ ] Live: escaping Candy Factory unlocks the Hospital

## Fixes and 10 levels (built 7 Oct)

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
- [ ] Confetti Cannon: one search spot on the near side holds it ("found a Confetti Cannon!"); at the blocked doorway hold F to plant it; 3-2-1 countdown, BOOM with confetti, the doorway clears and the host comes to look
- [ ] Tinker cannot pick the blocked doorway; the other locked door still works with a key or Tinker
- [ ] No secret hole any more; the Music Room cabinet is just furniture
- [ ] Lobby: the points reset button says 800
- [ ] Sound buttons (Lobby and game): a 🔊 button left of the 🎵 one; 🔊 steps 100 / 50 / 25 / Off for pops, doors, bounces, the host's breathing; 🎵 still only the music; both remembered next visit and between Lobby and game
- [ ] Studio Play now builds the Candy Factory (`Config.STUDIO_MAP = "gummy_2"`): pink candy walls, Conveyor Hall with two conveyor counters, Chocolate River and Packing Hall upstairs behind the doors, stairs up "Up to the Jelly Vault"
- [ ] Ask Claude to switch to `gummy_3` for the Jelly Vault: jelly pool (ball pit), two jelly bounce pads in the Security Room, three vents, exit to the cotton-candy clouds
- [ ] Store rooms (every floor): two small rooms in corners of the first rooms - a "Store Room door" (locked: Tinker picks it, or its key from a search spot) and a "Junk Cupboard" (blocked: Muscle shoves it, or its own Confetti Cannon). A gold present inside each: Open = 30 points plus a clue, a Shield or 30 more
- [ ] Muscle's Barricade button: next to a 💪 crate (6 beside doorways, plus the junk he shoves aside) it slides into the doorway; friends walk straight through it; the host stops and smashes it ("CRASH!") for 4 s, then it slides home; recharges 25 s; with no crate near: "No 💪 crate close by"
- [ ] Tinker: hold F at the big door's keypad (6 s) - "colour N is ..." once per game; others get "Only Tinker can pick a keypad"
- [ ] Live: escaping Bounce Hall unlocks Candy Factory; Candy Factory unlocks Jelly Vault; the Lobby map screen shows both floors with their pictures

Patch's face (Party House place, in Studio, NOT playing - press Stop first; the
"Face softening skipped" lines come from Play mode and are expected):
1. The Command Bar is the small code box at the bottom of the 3D view (newer Studio:
   Script tab or Window menu -> Command Bar). It is a little editor: Enter only adds a line.
2. Copy this whole line, paste it in the Command Bar, then click **Run** (the play
   arrow at its right) - not Enter:
   `local n=0 for _,d in ipairs(game.ServerStorage.Characters.Patch:GetDescendants()) do if d:IsA("SurfaceAppearance") and d.Parent:IsA("MeshPart") then local ok,c=pcall(function() return d.ColorMap end) if not ok or c=="" then local ok2,cc=pcall(function() return d.ColorMapContent.Uri end) c=ok2 and cc or "" end print(d.Parent:GetFullName(),"colour map:",c) if c~="" then d.Parent.TextureID=c d.Parent=nil n+=1 end end end print("Patch: softened",n,"parts")`
3. Output panel (bottom right): clear the search box (it must be empty, not "output"), keep All Messages / All Contexts. Photograph the line that starts `Patch: softened`.
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
