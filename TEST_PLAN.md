# Escape Crew - test plan (updated 10 Oct 2026)

**Rounds 61 down to 12 (top): built 7-10 Oct. Rounds 36-45 partly tested by Brent (fixes made); 46-54 not yet play-tested.**
Studio Play builds `Config.STUDIO_MAP` (now `aquarium`, the Aquarium's
Main Hall); ask Claude for any other floor (`partyhouse`, `partyhouse_2`,
`partyhouse_3`, `partyhouse_b`, `gummy`, `gummy_2`, `gummy_3`, `hospital`,
`hospital_2`, `hospital_3`, `school`, `school_2`, `school_3`, `carnival`, `carnival_2`, `carnival_3`, `aquarium_2`, `aquarium_3`) or `Config.STUDIO_TOWER` for a
Tower Run.

Everything below was built today and has only been checked in code (it
compiles, the analyser passes, the floor plans pass 2,000 random fills). Tick
each line in Studio, then once more in the live game. Send a photo and the F9
(Developer Console) lines for anything wrong.

Studio Play cannot teleport, so the Party House builds `Config.STUDIO_MAP`
(now `gummy`) with a random host (or `Config.STUDIO_HOST`). Ask Claude to switch
either: `partyhouse`, `partyhouse_2`, `partyhouse_3`, `gummy`; host `pumpkin`,
`gummy`, `robot`.

## Round 61 (10 Oct) - Brainy's propeller; descriptions one line per button
- [ ] BrainyToon (once imported): a blue two-blade propeller on a steel stem on top of the beanie, spinning, in the game (you and a friend both see it turn) and on the Lobby Characters screen once BrainyToon is saved to Roblox; not floating above or sunk into the beanie (photo) - if it is, tell Claude (one number, Config.PROPELLER_LIFT)
- [ ] The old Brainy has no second propeller
- [ ] Characters screen: each description ends with its button on its own line (Toolkit:, Sneak:, Think!:, Barricade:, Flare:, Shield:, Noise:, Vines:); the Skills / Skins pictures sit left of the words, not on them (photo)

## Round 60 (10 Oct) - Characters screen layout
- [ ] The description sits under the level bar, wide, in bigger text; the 3D character on the left is taller
- [ ] Below it two shorter buttons that look different: Skills blue with the character's skill picture (orange when upgrades wait), Skins magenta with the worn skin's picture (the portrait when Plain) (photo)
- [ ] Wear a skin: the Skins button shows that skin's picture

## Round 59 (10 Oct) - sounds: pickups are collected or eaten, not popped
- [ ] Halloween candy corn on the floor: a bright "ding" (collected), no balloon pop
- [ ] A key or a Popper found: the same ding
- [ ] A lost plushie: a toy squeak and the ding (it was a jail-cell door)
- [ ] Candy Corn - from the bag, a present or the candy button: a crunchy munch (eaten); Second Wind: a gulp
- [ ] A Party Shield blocks a grab: a shield thump (not a balloon); the stunned host's stars: a comic bonk
- [ ] Light switch: a click (not the lock-pick sound); laundry basket landing: a bounce only
- [ ] Still popping (on purpose): real balloons, a trick present popped, the Confetti Cannon

## Round 58 (10 Oct) - Characters screen: Skins and Skills windows; owner buttons
- [ ] Lobby -> Characters: the character in 3D, the portraits, the level bar, and two big buttons: "⚡ Skills" (orange with "n upgrades to choose!" when some are waiting, else "Level n") and "✨ Skins" ("Wearing: ...") - no ladder or skin row on the screen itself (photo)
- [ ] Skills: a window over the screen titled "⚡ <name>'s skills · Level n", the whole ladder (scrolls to Lv 20), the reset buttons at the bottom (FREE while the free reset is unused); X closes it back to the screen (photo)
- [ ] Skins: picture tiles - Plain (the portrait) and each skin with its Game Pass picture (Muscle Mummy its corn icon), name, and "✅ Wearing" / "Tap to wear" / "Buy" with a Robux coin / "100 candy corns"; tapping one you own wears it (the tile turns green, the 3D model changes); X closes (photo)
- [ ] Controller: B closes the open window first, then the screen
- [ ] Owner only: 📊 Balance and 🎁 Gift sit in a row just above the Candy Corn banner, not on top of it (photo)

## Round 57 (10 Oct) - ladder fix C: one free reset per character
- [ ] Lobby -> Characters, a character with picks: the reset button is green and says "Reset upgrades: FREE"; the Robux reset button is hidden
- [ ] Press it: "The upgrades changed, so this reset was free - choose again!", no points taken, the picks are cleared
- [ ] Same character again: the button is back to 800 points (and Robux shows); another character still says FREE
- [ ] A character with no picks: no FREE (nothing to reset)

## Round 56 (10 Oct) - ladder fix B: no pick swallowed by a limit
- [ ] Characters screen, each character at Lv 20 (the 🧪 tool): the new pick names and numbers show (e.g. Tinker "Spare Parts +1 free clue" at 15, Shadow "Light Feet 6% more stamina" at 5, Glow "Flicker" at 7, Bramble "Bark Skin" at 19); nothing overlaps or is cut off
- [ ] The levels line above the map shows the new totals (no "run faster" from a character's own pick)

## Round 55 (9-10 Oct) - TinkerToon, tiles, wall tanks, ladder fix A
- [ ] Play as Tinker (you, Studio and live): the new cartoon Tinker, with the robot walk; a broken test model would play the old Tinker and say why in F9
- [ ] Action tiles: words on one line under the picture ("Clue 10 (3)", "Toolkit (R)" not cut off)
- [ ] Aquarium: the fish tanks and jelly tanks on the walls are solid (you can't walk into them)
- [ ] Characters screen (use the Lv 20 tool): Shadow's sneak picks say "+2 s longer", Glow's light "+4 studs", Echo's throw "studs further", Bramble's vines "+2 s"; Muscle's shove picks say "Shove, free friends and search"
- [ ] Muscle Fortress (Lv 20): barricade, then "One more barricade to build!", a second barricade, then the recharge
- [ ] Muscle Iron Lungs (Lv 10): after running out, stamina fills about twice as fast as before
- [ ] Patch Guardian Angel (Lv 10): two shields before the recharge ("One more shield to give!")
- [ ] Tinker Rocket Boots (Lv 20): after pressing Toolkit you run faster for 5 s (gold streak, "Rocket Boots! Run!")
- [ ] Brainy Long Think / Deep Think (Lv 11 / 17): the Think! arrow stays 20 s / 25 s
- [ ] Echo Double Throw still gives two noises

## Round 54 (10 Oct) - the party arrives together; one press plants the cannon
- [ ] Live, a party of 2-3: whoever arrives first waits on the character screen until everyone is in (at most 45 s), then the game starts with all of you - nobody sent to the garden
- [ ] Junk Closet / blocked passage: one tap of E (no holding) plants the Confetti Cannon, 3-2-1, BOOM; pressing again while it counts says it's already planted

## Round 53 (10 Oct) - parties, the Junk Closet, carousel unicorns
Parties (live, 2-3 accounts):
- [ ] Anyone presses Leave while standing on the circle: they step off it and are out (not pulled back in); the others stay
- [ ] The host presses Leave: the party closes for everyone ("<host> left, so the party closed")
- [ ] Start a party after picking a map: much shorter wait before the trip; everyone arrives in the same game
- [ ] Friends press Quick Play: they join a friend's open party rather than each starting alone
In the game:
- [ ] Junk Closet / blocked passage: nobody can walk through the junk; Plant Confetti Cannon is on E (Y on a controller); with a cannon it counts 3-2-1 and blasts it open; the present inside then opens
- [ ] Carousel: unicorns - rounded body, arched neck, head with muzzle, ears, eyes, golden horn, golden mane and tail, saddle, golden hooves; still bobbing as it turns (photo)

## Round 52 (10 Oct) - the clean menu look (art/ui-mockups/menus-v2.png, hud-v2.png)
Lobby:
- [ ] Every pop-up (Invite, Shop, Characters, Quests, Plushies, Help, Candy Shop, map screen): dark glass with a cream border; words in a clean bold font, orange titles in the rounded font; nothing huge - text stays a normal size
- [ ] No cream buttons left (they are plum with a thin cream edge); the main action green
- [ ] Only one pop-up open at a time: opening Emote closes Invite, and so on
- [ ] The emote picker opens beside the right bar, its tiles plum with a cream edge (emoji until the icons are in)
- [ ] The points chip sits above Quick Play and never covers anything (phone too); Gift (owner only) is beside Balance at the bottom
In the game:
- [ ] Action buttons are taller tiles: picture (or emoji for now) above one word; the skill tile follows your character; the boosts row and items row sit above them, nothing overlapping (computer and phone photos)
- [ ] Top bar, stamina panel, map, Say panel, character picker, keypad, results: dark glass with a cream edge
- [ ] Once the 22 new icon ids are in: Run, Say, Clue, Change, Look, Emote and the skill tile show pictures, and the emote picker too

## Round 51 (10 Oct) - stretched shapes now really stretched (Roblox squashed every egg shape into a round ball)
- [ ] The great tank shark is one long fish: body, snout, fins, crescent tail all joined (photo)
- [ ] Fish bodies are oval, plushies have proper heads and bodies, gummy bears (Bear Gallery, Gummy puddles) are real bear shapes, penguins, duck, jellyfish, starfish arms, coral, candy corns, rocking horse, the clown car / sub, the Lobby pumpkins - all as drawn, nothing floating apart
- [ ] Fixed cylinders: IV stand base, crystal ball table, trophies, the big bell's rim, the valve wheel, the water bottle, the boiler pot are flat / upright as meant
- [ ] Posters a third bigger (5 x 7 studs)

## Round 50 (9 Oct) - posters and tile icons
- [ ] Every floor: up to 4 framed posters high on inside walls (never the outside walls with windows, never over furniture against the wall, not beside the invitation or painted wall), the building's own two (photo of a few)
- [ ] Lobby tiles show their own pictures (lightning, flashlight, balloons, Brainy-like face, shop bag, scroll, teddy, envelope, door, hand, camera, question mark)

## Round 49 (9 Oct) - the new Lobby screen (art/ui-mockups/lobby-v2.png)
- [ ] Left: "ESCAPE CREW", a big green Quick Play tile, then Solo, Party, Characters, Shop, Quests, Plushies tiles (emoji for now) - each does what its old button did
- [ ] Right: Invite, Join, Emote, Photo (shows Daily / Every escape / Off; tap cycles), Help; Join opens the friends' parties list beside it and shows a red number when there are parties to join
- [ ] Quests shows a red number of quests still to do; points in a chip at the top left (no "points" word)
- [ ] The music / sound buttons top right are not covered; the candy banner still at the bottom
- [ ] Phone: the tiles shrink to fit; nothing off screen (photo)
- [ ] In a party: the tiles and bar hide, your party panel shows; leaving brings them back
- [ ] Controller: Up selects Quick Play; you can move round the tiles

## Round 48 (9 Oct) - the look: lighting and color
- [ ] Every building: brighter, cleaner, more colorful than before (less haze); each has its own light (Party House warm, Gummy pink, Hospital cool green, School paper-warm, Carnival warm red, Aquarium blue); lamps and neon softly glow (photos of two or three floors)
- [ ] Spooky game: clearly darker than Giggly
- [ ] Robot blackout / dark rooms still go dark, and come back to the floor's own light
- [ ] Lobby: richer colors and a soft glow on lamps and pumpkins (photo)
- [ ] Too bright / too dark / too colorful anywhere? Tell Claude: every number is in Config.LOOK

## Round 47 (9 Oct) - items hide anywhere
- [ ] Each floor hides 3 items: Candy Corn, a Party Shield, and one of Second Wind / Extra Clue / Frozen Pop - in random presents AND search spots (drawers, crates, cake boxes, coats, toy boxes, vases, laundry, chests); the rest are empty (play a few games: items turn up in different kinds of things)
- [ ] Finding one works at once: "<name> found a Frozen Pop - the host is frozen for 10 seconds!" etc.; keys and Confetti Cannons still turn up as before
- [ ] The bag's tap boosts (from the Lobby shop) still work the same

## Round 46 (9 Oct) - the object audit (photos please)
Group 1: Lobby cars on their wheels; swing set legs an A; the great tank's shark (snout, fins, crescent tail, eyes, gills); the Whale Skeleton Hall (spine on posts, arching ribs, skull, flukes); the duck pond duck (head, beak, eyes bob together); starfish with five arms; jellyfish with tentacles, inside their tank; penguins (head, face, beak, flippers, feet, waddle as one); the Gummy Bear Man's puddle bears (faces) fade when it melts
Group 2: the rocking horse; the submarine; the clown car; carnival stalls (posts, two prize teddies); bumper cars; coral; Tinker's wind-up mouse (ears, eyes, tail); bats from empty spots have wings; drum stands, radio desk legs, chair legs and backs, the crib, the curtain stand, candelabra arms, the bell's hanger, the water-tank pipe, the doll shelf on the wall, the safety net's legs, the party chair and its balloon strings, the Lobby gate balloon strings; teddies on the prize wall / in the crib / on shelves; Bramble's snapper (mouth and teeth after the stem grows), vines sink to the floor
Group 3: the rolling barrel rolls; carousel horses bob; kelp sways from the rock; bathtubs have water and taps; monitors on stands; easels with legs; Lobby jack-o'-lanterns have glowing faces and stems; the giant pumpkin grows upward when poked

## Round 45 (9 Oct) - Ghostly Shadow size, the scare on every host (after publishing)
- [ ] Characters: Ghostly Shadow now 15% bigger in the preview (Config.PREVIEW_SCALE) - the same size as plain Shadow? (photo; tell Claude a number if not)
- [ ] Spooky game with the Gummy Bear Man (and each other host): a roar and his face rushes at you when he comes out - never only a black flash

## Round 44 (9 Oct) - real fish, bigger plushies, the found card, preview sizes (3rd try)
- [ ] Aquarium Shark Tunnel (and every fish tank): little fish with round bodies, a fanned tail, a top fin and eyes (orange ones are white-striped clownfish), swimming end to end and turning round - no loose blocks (photo)
- [ ] A plushie in the game is about knee-to-waist high, its animal easy to tell (photo)
- [ ] Picking it up: a card slides in on the LEFT with the plushie turning in 3D, "You found ...!" and "n of 19 in your Plushie Book", for 5 s; nothing floats over your head; others get the usual message
- [ ] Characters: Shadow and Ghostly Shadow the same size (now measured shoulders to feet)

## Round 43 (9 Oct) - plushies you can see, runs, the intro scare, preview sizes again
- [ ] Studio Play: Output prints "[Plushie] <name> is in the <room>", and 6 s in a message says the same; go there: a small fabric animal on the floor with a stronger sparkle and a soft glow (photo)
- [ ] Lobby -> Plushies: each card shows its plushie in 3D, gently turning; ones you haven't found are a black shape with ❓ (photo)
- [ ] Shadow and Brainy run with Roblox's plain run (arms pumping), the rest with their pack's; walk / idle unchanged - watch each character and host run and tell Claude any that look odd (Config.ANIM.plainRun takes a character or host id)
- [ ] Spooky game (leader picks 👻 Spooky): when the host comes out, a roar and his face rushes at you - try each host (Config.STUDIO_HOST = "pumpkin", "gummy", "robot", "caretaker", "clownbear", "anglerfish"); never a plain black screen
- [ ] Characters: Shadow and Ghostly Shadow the same size (measured on the body only now)

## Round 42 (9 Oct) - Lobby buttons, preview sizes
- [ ] Lobby: "😄 Emote (G)" and "📸 Photo: Daily" are a row in the left menu under How to play; nothing sits on the sound / music buttons top right; the menu's buttons all fit (photo)
- [ ] Characters (Lobby and the game's select): Shadow and Ghostly Shadow (and every other skin) are about the same size on screen

## Round 41 (9 Oct) - invite reward (live only: needs a second account that has never played)
- [ ] Lobby -> Invite friends: Roblox's invite shows "Come and escape with me! New players who join from my invite get a Party Shield - and so do I."
- [ ] A brand-new account joins from the invite: it sees "Welcome! You came with a friend's invite - here's a Party Shield and 100 points!"; you (in the Lobby) see "<name> joined from your invite! ..." and your Party Shields go up by 1
- [ ] If you had left before they arrived: on your next Lobby visit the same message comes and the shield is added
- [ ] An account that has played before gets nothing (no farming); at most 10 friends reward you

## Round 40 (9 Oct) - the escape photo (best tried live; Studio may not take pictures)
- [ ] Escape: about 2 s after you land in the garden your character cheers, the camera swings round in front of you, the buttons vanish for a blink, then a card "📸 Escape photo!" shows the picture with Save / Share / No thanks
- [ ] Save: Roblox asks to save it to your captures (photo of the prompt); Share: Roblox's share screen; No thanks closes it; it closes itself after 25 s
- [ ] The camera goes back to normal after the picture (spectating still works)
- [ ] The card has "📸 Photos: Once a day (tap to change)": tap cycles Every escape / Once a day / Off; the Lobby has "📸 Escape photo: ..." beside Emote doing the same (it stays after leaving and coming back)
- [ ] Once a day (the default): only the first escape of the day takes a photo; Every escape: each one; Off: none
- [ ] Plushie Collector badge (id 4046817833899589) at 19 plushies

## Round 39 (9 Oct) - emotes and rumble
- [ ] Game: "😄 Emote (G)" with the action buttons; Lobby: "😄 Emote (G)" top right under your points. G, the button, or the right-stick click opens 8 choices: Wave, Point, Cheer, Laugh, Dance 1-3, Stop
- [ ] Each plays on your character (the imported ones too) and the other player sees it (2-player test); walking or jumping stops a dance; Stop stops it
- [ ] Controller: a rumble when you are caught (strong), spotted (light), hit by a pumpkin, near a Ground Pound, and at FRENZY
- [ ] Phone: a short buzz at the same moments if your phone allows it (tell Claude if nothing happens - Roblox doesn't vibrate every phone)

## Round 38 (9 Oct) - the Plushie Book (collectibles)
- [ ] Every floor: one small fabric plushie sits on the floor somewhere outside the starting room (a faint sparkle); a different animal per floor (Config.PLUSHIES)
- [ ] Walk up to it: a pop of sparkles, its animal over your head, "+25", and for everyone "<you> found Sprinkles the Party Bunny! (1 / 19 ...)"; a second visit says "already in your Plushie Book"; a friend can still find it after you
- [ ] Lobby: the Quests button is half width, with "🧸 Plushies" beside it; the book shows 19 cards - found ones with the animal and name, the rest "❓ Lost somewhere in <floor>"; "n of 19 found"; Close (photo; also on a phone)
- [ ] Live, once its id is in: finding all 19 gives the Plushie Collector badge

## Round 37 (9 Oct) - effects, level bonuses, animation packs, American room names, gummy bears
Effects (everyone sees them):
- [ ] Shadow's Sneak: purple smoke trails him while it lasts
- [ ] Glow's Flare: a ball of light swells out from her; sparkles round her while it lasts
- [ ] Echo's noise: a white, then gold, then purple ring spread out where it lands
- [ ] Bramble's Vines grow up out of the floor one stem after another (leaf burst), and sink away at the end
- [ ] Muscle's Ground Pound: two dusty rings and the screen shakes for players nearby
- [ ] Patch: a green ring as she hands out shields; anyone with a Party Shield has a shimmering blue bubble round them (gone when hidden / in a vent); when it saves you: POP, a blue ring, and the host sees stars
- [ ] Tinker's Toolkit: a 🔧 pops up over his head; Brainy's Think!: a 💡
- [ ] A host stunned by a skill (Ground Pound, Dazzle, Sound Wave, Snapper): three yellow stars circle his head while he is stunned
- [ ] Caught: a red ring slams out; freed: a gold ring round the cage
- [ ] Any speed burst: a golden streak behind the runner
Levels line:
- [ ] Computer: under the building name, light blue "⬆ Your levels: 🏃 run +10%  💚 stamina +20% ..." (or "No level bonuses yet") - try 🧪 Lv 1 / 10 / 20 and compare (photo)
- [ ] Phone: the building name and the levels line take turns every 5 s; the map still fits on screen (photo)
Animation packs (Config.ANIM - ask Claude to swap any):
- [ ] Kids: Tinker robot, Shadow ninja, Brainy mage, Muscle superhero, Glow bubbly, Patch cartoony, Echo stylish, Bramble toy; Muscle Mummy zombie. Walk, run, stand still, jump - each looks like its own (video or photos)
- [ ] Hosts: Pumpkin zombie, Gummy Bear Man werewolf, Robot robot, Caretaker elder, Clown Bear toy, Anglerfish Keeper levitation; they stand in an idle pose when still (not frozen)
- [ ] Nobody's legs sink into the floor or float with the new packs (photo if they do)
- [ ] Lobby -> Characters and the game's character select: each 3D preview stands in its own pack's idle; Echo and Starlight Echo stand in the plain idle with arms at her sides (in previews and in the game) (Shadow ninja, Muscle superhero, Muscle Mummy zombie...) and still turns when you drag it; no preview squashed or stretched (photo of two or three)
Names and bears:
- [ ] Rooms say Parlor, Elevator Lobby, Cafeteria (Hospital), Storage Room (Attic), Coal Room (Basement), Sugar Room (Candy Factory), Lab Storage, Medicine Closet, Staff Lounge (Hospital), Teachers' Lounge (School)
- [ ] Gummy Bounce House, Bear Gallery: three big gummy bears (face, ears, belly) on white stands, facing into the room (photo)

## Round 36 (9 Oct) - Brent's first live-test fixes
- [ ] Echo with Sound Wave (level 20): throw a noise close to the host - he is stunned 1 s, then still walks to the noise (and ignores kids on the way, as a normal noise)
- [ ] Caught: in the cage you can walk slowly round inside it (no jumping); slipping out puts you back in; freeing still works
- [ ] Map on a floor with a loft (Gummy Bounce Hall's Slide Tower, Party House Bedrooms' Gallery, Carnival, Aquarium Main Hall): "⬆ Loft" sits at the foot of the stairs, not on any room name (photo)
- [ ] A non-Bramble at the big plant: with a Bramble in the crew, "bring <name> here!"; without one, "nobody in your crew is Bramble. Pop the balloons"
- [ ] Glow's Flare / Beacon, Echo's burst, Patch's Group Hug, a Second Wind boost: a line floats up over the boost row ("💚 +6% stamina", "⚡ +5% speed for 3 s"); the ⚡ slot shows "+5%" above its seconds - for every player who gets it

## Round 35 (8 Oct) - skill and boost timers
- [ ] Each skill's button counts down while it works (orange), then the recharge (gray): Shadow "Sneaking 14s", Glow "Flare 8s", Bramble "Vines 6s", Echo "Burst 3s", Muscle "Barricade 10s", Brainy "Thinking 15s"; Tinker "Toolkit ready!" until the next pick; Patch goes straight to the recharge
- [ ] A speed burst (Echo, Glow's Flare, Beacon) shows a lightning slot in the boost row with its seconds, and the extra speed stops when it reaches 0

## Round 34 (8 Oct) - map icons, Skeleton Key, Shadow's recharge
- [ ] Map: a padlock on locked doors, a roadwork sign on junk doorways (both gone when open), chains on the cage, a door on the exit; on the Classrooms floor "Loft" sits bottom-right of the Library, not over its name
- [ ] Tinker with Skeleton Key (level 10): the first lock you pick opens every other locked door ("Skeleton Key opened n more doors!")
- [ ] Shadow: the Sneak message says the real length; the recharge counts down only after the sneak ends (the button shows Sneaking, then the recharge)

## Round 33 (8 Oct) - swings, Frenzy, (R)
- [ ] Lobby swings: you sit facing the way the swing goes (not sideways)
- [ ] At 0:00: a big red shaking "TIME'S UP! The host knows where you are - get out!" in the middle for about 4 s; every light in the building (lamps, tanks, bulbs, windows) goes dim and red; Glow's own bulb stays
- [ ] The skill button shows "(R)" all the time on a computer, also while sneaking and while recharging

## Round 32 (8 Oct) - camera at walls, no repeated skills, the countdown, the host and blocked doorways
- [ ] Back up against a wall (or a big table by a wall): the camera stops in front of the wall - never black, never the next room; shelves and tables in the way fade
- [ ] Ladders: no two choices do the same thing (Tinker / Muscle 15, Glow 11 and 15, Patch 10, Shadow 15 and 19, Bramble 15 and 20 changed)
- [ ] Timer: at 1:00 it flashes yellow/red and grows for 2 s; from 0:30 it is bigger and shakes; from 0:10 a big red number counts down in the middle; at 0:00 "FRENZY"
- [ ] The host stuck at a blocked (junk) doorway or a locked door no longer ends up on the other side
- [ ] The skill button keeps "(R)" after it recharges

## Round 31 (8 Oct) - Glow's Flare lifts the team, vines, the Shark Tunnel, your own name tag
- [ ] Glow presses Flare: for the 8 s it lasts, she and any friend who comes within 16 studs get +6% stamina and run 5% faster for 3 s (once each); friends see "Glow's Flare!"
- [ ] Glow's ladder 11-19: the lift grows (20-28 studs, 8-10% stamina, longer Flare; still 5% faster for 3 s). Level 20 Beacon: everyone on the floor, wherever they are, gets +25% stamina and 5% faster for 5 s the moment she flares, and shows through walls
- [ ] Echo: after a noise only Echo runs 5% faster for 3 s (as before)
- [ ] Bramble's vines slow the host a little more than before
- [ ] Aquarium Main Hall, Shark Tunnel: the glass walls show water with sand, weed, big bright fish and a blue glow (not empty)
- [ ] Your own skill tag ("Shadow" etc.) no longer floats over your head for you (others still see it)

## Round 30 (8 Oct) - fixes: Toolkit, map, pop-ups, level buttons
- [ ] Tinker: stand at a lock (or the Store Room), press Toolkit, then F: it opens at once (the prompt's ring is gone)
- [ ] Muscle level 20 Bulldozer: shoving junk is instant
- [ ] Opening a crate / present that gives Candy Corn: the pop-up in the middle shows the candy-corn picture (no peppermint); other boosts show their pictures
- [ ] Computer: the map is bigger, in the bottom-left corner; above it: stamina, points, and the room you're in in big orange letters (it changes as you walk into a room); room names in the map are readable; closing the map (N) moves the bars down to the Map button
- [ ] Phone / tablet: bars at the top left, the bigger map under them
- [ ] Lobby -> Characters -> Lv buttons: "Setting ... to level n..." then "Test: ... is now level n" (or a message saying why not) - send a photo if not

## Round 29 (8 Oct) - test levels, American English
- [ ] Lobby -> Characters (only you): bottom left "Lv 1 5 10 15 20"; tap one: "Test: <character> is now level n"; the ladder opens to that level; pick the level-10 / level-20 powers and try them in a game
- [ ] Text says color / colors / gray / Junk Closet; rooms: Lost and Found, Principal's Office (School), Candy Apple Stall (Carnival), Restrooms (School), Deep Sea Elevator (Aquarium)

## Round 28 (8 Oct) - skills version 2 (SKILLS_V2.md)
Camera:
- [ ] Squeeze between a bookshelf and a wall: walls and furniture in the way fade out; you see the gap in front of you (no black screen, no next room)
Buttons (R on a computer):
- [ ] Tinker "Toolkit": then a lock / keypad picks instantly; used up after one pick
- [ ] Brainy "Think!": the next thing to do lights up blue and the team gets the hint (free)
- [ ] Bramble "Vines": standing in or next to a doorway, vines grow across it for 6 s; the host is slow through them, kids are not; away from doorways: "Stand in or next to a doorway"
- [ ] Echo: after a noise, 5% faster for 3 s
Levels (set XP in Studio or ask Claude for a test profile):
- [ ] Characters (Lobby): the ladder scrolls to level 20; level 10 and 20 rows show the big powers; XP needed for 20 is 78,500
- [ ] Level-10 powers: Tinker Wind-up Mouse / Skeleton Key; Shadow Clone; Muscle Ground Pound (no crate near); Glow Night Light / Dazzle; Patch Group Hug; Echo Double Throw / Echo Map; Bramble Snapper / Hide in the Leaves
- [ ] Level-20 powers: Master Tinker (2 colours); Night Walker / Double Clone; Photographic Memory / Big Brain; Beacon; Guardian / Medic Run; Sound Wave / Super Burst; Overgrowth
- [ ] Guard rails: a skill stun is at most 2 s (1 s on Nightmare); a second skill stun within 8 s does nothing

## Round 27 (8 Oct) - shop rows, Equip, Flare, R key, names
- [ ] Boost Shop: every row's buttons sit inside the purple row: Have n, price, green +, red -, Robux, Equip
- [ ] Equip: tap once = Equipped, again (if you have 2) = x2, again = back to Equip; "Next game: ..." lists both; in the game two Party Shields save you twice, two Head Starts give 20 s, two tap boosts are both in your bag
- [ ] Characters (Lobby): the name in orange above the 3D model; the line on the right starts "Level n"
- [ ] In a game the skill button shows "(R)" on a computer; R uses the skill (Echo: R then click where to throw)
- [ ] Glow: the skill button is "Flare (R)": her light reaches much further for 8 s, recharges in 30 s
- [ ] Character select in a game: Brainy / Glow / Bramble name this floor's real room for the invitation / painted wall / plant

## Round 26 (8 Oct) - fixes after the first publish
- [ ] Candy corns in a game look like candy corn: a rounded yellow base, an orange band, a white tip, bobbing and glowing
- [ ] Picking one up: the candy-corn picture pops up with "n candy corns", and the message says "Candy corn found! n so far (+3 points)" (n goes up by 1, points by 3)
- [ ] End of a level with 2+ players: one presses Back to lobby -> only they go; the others who press nothing stay and play again (or go up if someone chose Next floor)
- [ ] Lobby: the Boost Shop's green buttons, the skin chips for sale and Reset upgrades show the Robux icon, not "R$" (photo - if the icon is missing, tell Claude)

## Round 25 (8 Oct) - the Candy Shop rebuilt, gifts
- [ ] The banner at the bottom has the candy-corn picture (no peppermint); tap it: a big Candy Shop like the Boost Shop - each boost's picture, what it does, "You have n", an orange "Buy 9" button with the candy-corn picture; a Muscle Mummy skin row (its picture once uploaded); Close
- [ ] Muscle Mummy: "Yours!" after buying, and the Buy button goes
- [ ] You (the owner) see "Gift" bottom-left: every player in the Lobby with +25 / +100 corns and +500 / +2000 points; the player gets "A gift from ..."; gifted corns add to "to spend" but not to the badge count
- [ ] In a game, picking up a corn says "(pumpkin) Candy corn! +3 (n / 50)"

## Round 24 (8 Oct) - the Candy Shop and Mummy Muscle
- [ ] Lobby: the banner at the bottom shows your candy corns to spend; tap it: the Candy Shop opens - 6 boosts (Second Wind 8, Candy Corn 9, Extra Clue 12, Head Start 15, Party Shield 18, Frozen Pop 23) and, once his model is in, Mummy Muscle 100
- [ ] Buying a boost: it is added and your corns to spend go down; with too few: "You need ... (you have ...)"; a corn-bought boost has no points refund with the - button
- [ ] Mummy Muscle: with 100 on hand, buying him takes 100 corns, "is yours!", he is worn next game and shows "yours!" in the shop and in Characters -> Muscle; with fewer: "You need 100 ..."
- [ ] The Candy Corn Collector badge still comes at 50 found, however many were spent

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
