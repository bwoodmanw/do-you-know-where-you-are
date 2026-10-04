# Do You Know Where You Are?

**A co-operative escape game for ages 8+: a team of up to six kids solves puzzles
room by room to reach the final safe area - and their parents - before the
creature that lives there finds them.**

Status: draft for approval, 4 Oct 2026. Nothing is built yet.

---

## 1. Concept

The parents dropped the kids off at what looked like a birthday party, a camp,
a bouncy-castle day out. It wasn't. The invitation was a trick, the bus took a
wrong turn, and the place is not what it seemed. Something lives here.

Each run is a chain of 4-5 rooms. Every room is full of clues, hiding places and
one way out. The team spreads out, taps on things, finds the pieces, uses each
character's skill, and opens the way to the next safe area - while footsteps get
louder and the creature closes in. Reach the final safe area and the parents are
waiting there: the reunion is the win.

What makes it fun:

- **Teamwork** - no one character can get through a room alone.
- **Variety** - every room is a different kind of puzzle in a different place.
- **Tension** - the creature is always coming; hiding at the right moment matters.
- **Achievement** - the team wins together, every helper is recognised, and
  effort is rewarded even in a lost run.
- **Life** - jumpscares and jokes in every room; the creature is scary *and*
  ridiculous.

Like: Roblox hide-and-escape games crossed with an escape room, played by
tapping rather than by reflexes.

The first 30 seconds: you are standing in a room with your friends. Something
glints under the bed. There is a locked door with a coloured keypad, and a
drawing on the wall. Far away, a footstep.

## 2. Audience

- **Ages 8 and up** (raised from 6+ on 4 Oct 2026: kids who play online
  hide-and-seek and mystery games expect that level of realism and tension).
  Puzzles still lead with pictures, colours and codes; short reading is fine.
  Preset phrases are spoken aloud. Giggly/Spooky stays, for younger siblings.
- **Players:** 1 (solo) or 2-6 online.
- **Devices:** Amazon Fire tablet first and tested first (Kids profile); also
  phone and PC browsers, so a friend without a Fire can join.
- **One game:** 10-15 minutes, 4-5 rooms.
- **Spook level, chosen by the host per game:**
  - **Giggly** - dim but never dark, scares are silly (the creature leaps out and
    slips on a banana), no sudden loud stingers.
  - **Spooky** - dark rooms, real jumpscares with recorded stingers, creepier
    sound. Still no blood, gore or injury, at any level.

## 3. Objective and win condition

- **Win:** the whole team (or everyone not caged) reaches the final safe area of
  the run. Reunion cut-scene, rewards for everyone.
- **A room is cleared** when its exit opens and every free player has walked
  through it. Caged players come along free - reaching a safe area frees them.
- **Caught:** the creature reaches a player who is not hidden. That player goes
  into a cage in the room and keeps watching and pointing. Teammates free them
  with a small rescue puzzle at the cage.
- **Lose the room:** every player is caged. The team retries that room from its
  start (the run is not over). After three failed tries the run ends and
  everyone keeps what they earned.

## 4. Core loop

**Inside a room** (everyone acts at the same time; nobody waits for a turn):

1. **Tap to move, double-tap to run.** Tap a spot - a desk, a cupboard, a
   vent - and your character walks there. Double-tap and it runs: twice as
   fast, but it drains your **stamina** bar. Stamina recharges while you walk
   or stand still (fastest while hidden). At zero you can only walk until it
   has refilled a quarter. Running is still tap-driven, so lag never decides
   it.
2. **Search.** Tap objects to inspect them: find items, clue fragments, codes.
   Items go into the team's shared inventory. Some objects hide a
   **short-term boost** that goes to whoever found it (section 9).
3. **Use a skill.** Each character has one skill (section 9). Every puzzle can be
   solved **two ways with two different skills**, so a team that lacks one skill
   is slowed, never stuck.
4. **Watch the clock.** The creature moves on a clock everyone can see, in steps,
   with footsteps getting louder. When it is near, **hide** (tap a hiding place)
   - it walks past hidden players.
5. **Ask for a clue** if stuck. A limited number per room; each one costs the
   asker some of **their own energy** (energy is per player). At zero energy
   you cannot ask, and you walk slower, until the next safe area refills it.
6. **Open the exit** and walk through it into the next safe area.

**In a safe area** (between rooms, the creature cannot come in): breathe, see
who did what (cheers for the code-cracker, the rescuer, the one who hid
everyone), refill energy, visit the **safe-area stall** to spend points on
energy, a shield or power-ups for the next room (section 9), latecomers join,
then on to the next room.

**After a run:** rewards screen - points for every puzzle helped, every rescue,
every room cleared, a finishing bonus. Points buy skill upgrades and cosmetics.

## 5. Modes

### Solo (offline-capable)

The child **leads a squad of 2-3 of their own characters** and swaps between
them to use each one's skill - the same rooms and puzzles as online, no computer
teammates. The two-ways rule (section 4) means any squad can finish every room.

- In the **Kids profile**, solo works whenever the tablet has wifi.
- **With no connection at all**, solo only works from a home-screen shortcut
  made in the **adult** profile (Silk -> Add to Home screen). Tested fact from
  Playbox, 23 Aug 2026: the Kids browser refuses to open any page offline and
  never asks the service worker.
- A solo run played **while connected** is refereed by the server and can go on
  the solo leaderboard. An offline solo run earns XP and unlocks but posts no
  score.

### Online with friends (2-6)

Same rooms, one character each. See section 6.

### Pass-and-play

Not in the design. Tap-to-move is simultaneous, so sharing a tablet would need a
separate turn-taking mode.

## 6. Multiplayer model

- **The server is the referee.** One room = one Cloudflare Durable Object. It
  holds the game state, checks every move with the same `rules` code the page
  runs, runs the creature's clock, and sends the result to everyone.
- **Pace:** real time, but slow. Players act whenever they like by tapping;
  the creature moves in steps on the server's clock. A half-second of lag goes
  unnoticed. There is no dodging by reflex - that is what tablet wifi cannot do.
- **Creating a room:** the host taps Create, chooses theme and spook level, and
  gets a **three-picture-word code** (e.g. TIGER - PIZZA - ROCKET), shown big.
  About 125,000 combinations, so a stranger cannot stumble in.
- **Joining:** a friend taps Join and picks the three words from picture
  buttons - nothing typed, nothing misspelt.
- **Lobby:** each player's character and name; the host taps Start when ready.
- **Late joiners** wait in the lobby and drop in at the next safe area.
- **A dropped player:** their character automatically hides somewhere safe and
  the creature ignores it. Any teammate can use their skill so no puzzle is
  stuck. Their seat is held for 10 minutes; opening the game again rejoins it.
  Teammates see a sleeping "zzz" over the hidden character.
- **The host drops:** host duties (Start, Continue) pass to the next player.
- **Removing a player:** the host can remove a player from the lobby or a safe
  area.
- **Room life:** a room is deleted, keeping nothing, 15 minutes after its last
  player leaves, and after one hour at most.
- **Resume a run:** each tablet remembers the last safe area its team reached
  (theme, room number, seed, squad). For up to 7 days the host can tap Continue,
  which creates a fresh room with a new code starting at that safe area. The
  server keeps nothing between sessions.

## 7. Safety

The rule behind every choice here: a children's game that collects personal
information or lets strangers message children is a legal and safety problem
(COPPA in the US). Avoiding it is far easier than handling it.

- **No accounts. No email, age, birthday, location or photos - ever.**
- **No free-text chat.** Teammates communicate with:
  - **Point:** tap and hold anywhere to drop a "look here!" marker everyone sees.
  - **Emoji reactions.**
  - **Preset phrases** from a large fixed menu ("Over here!", "I found a key!",
    "Hide!", "Use your skill!", "Nice one!", plus jokes), **spoken aloud** by the
    tablet so non-readers can use them.
  - Rate-limited: a few messages per 10 seconds per player.
- **Names are typed, with guards** (Brent's decision; see Risks):
  - one word, letters only, 2-10 characters - no spaces (so no surnames or
    school names) and no digits (so no ages or birthdates);
  - filtered for swearing and common evasions;
  - **suggestions and a Randomise button shown first**;
  - the same rule everywhere - in rooms and on leaderboards.
- **Leaderboards** show names, so they get extra guards:
  - a **report button** on every entry hides the name immediately (shown as the
    character only) until Brent reviews it;
  - **weekly boards** that reset; nothing older is kept;
  - only server-refereed runs count.
- **No public lobby, no matchmaking, no friend lists.** You only play with
  people who have your code.
- **No ads, no real-money purchases.** The shop spends earned points only.
- **What the server stores:** live room state (deleted with the room);
  leaderboard entries (name, character look, score, week; deleted at week
  end); the report queue. Nothing that identifies a child or a device.

## 8. Art and sound

**View: 2.5D (decided 4 Oct 2026, after the first 2D room was built).** Brent
wanted Roblox-style 3D with expansive environments. True 3D was weighed and set
aside for v1: a tilted, looking-down-at-an-angle view with depth, shadows and
tall objects, a camera that follows the selected character, and **maps several
screens big** with many connected rooms. The rules stay on a tile grid, so
everything built for the flat room carries over; only the drawing and camera
change. Target tablet: Fire HD 10 / Max 11 (Brent's answer), so real 3D could be
revisited later with a test scene on the tablet first.

- **Characters are drawn in code** from layered parts - body shape and colour,
  eyes, mouth, hair/hat, outfit, accessory, a trail or sparkle effect. Highly
  customisable for almost no download size. Every part must be rendered to PNG
  and looked at before it ships (Playbox lesson: pixel counts pass while the
  shape is wrong).
- **Room backgrounds and creatures are AI-generated image files** in the repo,
  loaded only when a room starts and cached for offline play in the asset
  cache. Our own drawings can replace any of them later - an image is just a
  file a room points at.
- **How the AI art gets made:** this build session cannot generate images.
  Claude writes the exact prompts (`ART_PROMPTS.md`: style, size, palette, what
  must and must not appear); Brent runs them in an image tool and drops the
  files into `art/`; Claude slices, sizes and wires them in, then renders the
  room and looks at it. Until a file arrives, the room uses a placeholder drawn
  in code, so nothing waits on art.
- **Themes span a range:** bright and silly (Gummy Bounce House: jelly floors,
  sparkle powers) to grim and creepy (the Hospital: abandoned, flickering,
  post-apocalyptic) - each with its own creature.
- **Public repo = public website:** no recognisable characters from films,
  cartoons, anime or games, even AI-generated ones.
- **Sound is synthesised first** (Web Audio): footsteps, heartbeat, music,
  effects. **Plus a handful of short recorded stingers** - jumpscares and laughs
  - cached with the room art. Free-to-use sounds only, licences recorded in the
  repo.
- **Humour is designed in:** every creature has a silly side (it sneezes,
  trips, gets distracted by a balloon), every room has at least one joke object.

**Art direction (4 Oct 2026): realistic, stylised 3D**, like popular online
hide-and-seek and mystery games. Brent makes the sheets in ChatGPT's image
maker from `ART_PROMPTS.md`. Characters and customisation parts are design
guides that the game's own drawing is rebuilt to match; hosts, jumpscares,
room pictures and floor/wall textures go in directly. The character creator
is built once the parts sheets arrive. The playable world stays 2.5D: real
3D remains a later option, tested on the Fire HD 10 first.

## 9. Characters, progression and saving

### Starting characters (all eight available from the start)

Eight, so a full room of six still lets every child be different (decided
4 Oct 2026). More characters unlock later with points.

| Character | Skill |
|---|---|
| **Tinker** | Picks locks, repairs broken things (doors, lifts, fuse boxes) |
| **Shadow** | Hides better; can sneak past the creature for a moment |
| **Brainy** | Spots patterns, cracks codes, sees an extra hint in clues |
| **Muscle** | Moves heavy objects, holds a door shut against the creature |
| **Glow** | Lights dark rooms, reveals invisible clues (UV writing, footprints) |

### The three added on 4 Oct (built and tested)

Playable from the start, like the first five:

| Character | Skill |
|---|---|
| **Patch** | Frees caged teammates twice as fast; Heal gives energy and stamina back to everyone close by (recharges) |
| **Echo** | Hears the host from further away (danger meter, host always on the minimap); Throw noise sends the host to look somewhere else, even mid-chase (recharges) |
| **Bramble** | Talks to plants: the library plant whispers the door code (vines and animals in later rooms) |

### Skill trees

Each character's skill levels up along a short tree with a choice at each tier
(e.g. Tinker: *faster picking* or *pick two locks at once*). Higher tiers make
puzzles easier as rooms get harder. Proposed: 3 tiers, 2 choices each.

### Points and rewards

Earned for effort and teamwork, not just wins: each puzzle you helped solve,
each rescue, each room cleared, a run-finishing bonus. A lost run still earns.

### Three bars per player

- **Stamina** - spent by running, recharges on its own within seconds.
- **Energy** - spent on clues, refilled at each safe area.
- **Shield** (optional, from boosts or the stall) - saves you from one capture:
  the creature grabs you, the shield pops with a silly noise, you run free.
  There are no hearts or damage; being caught always means the cage.

### Boosts found in rooms (last one room)

Hidden in objects, one per room or two in bigger rooms. Halloween examples:
**Candy Corn** (stamina never drains for 20 s), **Glow Stick** (lights the room
for everyone for 30 s), **Party Popper** (startles the creature back a few
steps), **Balloon Decoy** (the creature chases it instead of you), **Mint**
(refills energy).

### Safe-area stall (between rooms)

A small stall in every safe area. Spend points on: energy refill, a shield,
one boost of your choice, an extra clue for the team. Prices rise slightly
through a run so points are not all spent in room 1. In a team game every
child spends their own points; anything bought can be given to a teammate.

### Shop (outside runs)

Cosmetics only (outfits, hats, colours, trails, emotes), bought with earned
points. No real money, ever.

### Saving

- One save per tablet, `localStorage` (keys prefixed `dykwya.`), every access in
  try/catch, `navigator.storage.persist()` requested.
- Everything carries everywhere: XP, skill levels, unlocks, cosmetics earned
  solo count online and vice versa. It is co-operative, so a stronger character
  only helps the team.
- Saved after every room, so leaving early never loses progress.
- **Limit:** a child's characters live on that tablet. There is no account, so
  they do not follow the child to another device, and clearing the browser data
  loses them.

## 10. Scope

### Release order (Brent chose Option A, 4 Oct)

Something Halloween goes live **this week** and grows every week, rather than
waiting for the whole edition:

1. **Halloween solo room - this week.** One room of *The Party at the End of
   the Lane*, solo squad of up to 3, the 5 characters, walk/run/stamina,
   hiding, the creature clock, cage, clue-for-energy, Giggly/Spooky. Runs on
   the tablet with no server. Placeholder art drawn in code until the AI art
   arrives.
2. **The online spike - in parallel**, as soon as the Cloudflare account
   exists (section 12).
3. **Weekly additions** until the full Halloween edition below.

### Halloween edition - complete by 29 Oct 2026

Theme: **The Party at the End of the Lane.** The kids were dropped at a
birthday party in the house at the end of the lane. It is a haunted house, and
the host - a tall figure in a melting pumpkin mask - has been waiting for
guests. Silly side: the mask keeps sliding off, and he cannot resist a balloon.

- The **Halloween theme**: 4-5 rooms, the pumpkin-mask host, both spook
  levels.
- The 5 starting characters with basic customisation (colour, eyes, hat,
  outfit).
- Solo squad play and online 2-6 with three-word room codes.
- Point, emoji and spoken preset phrases.
- Cage and rescue; clue-for-energy; hiding; the creature clock.
- Running with stamina; boosts found in rooms; the safe-area stall.
- Typed names with the guards in section 7.
- XP and points **earned and saved from day one**, so nothing is lost when the
  full v1 arrives.
- Offline solo, the Check screen, home-screen shortcut.
- A short reunion ending.

Not in it: leaderboards, shop, skill trees, unlockable characters, run resume,
the two v1 themes. All follow in v1.

### v1 - November 2026

Everything in the Halloween edition, plus:

- Two themes: **Gummy Bounce House** (bright) and **the Hospital** (creepy),
  each 4-5 rooms with its own creature.
- 8-10 puzzle types, each solvable two ways.
- Skill trees; the first characters to unlock with points (beyond the starting eight).
- Cosmetics shop with earned points.
- Team and solo leaderboards, weekly, with reporting.
- Resume from the last safe area (7 days).
- Recorded jumpscare stingers.

### Later

- A new theme every few weeks.
- Seasonal events (Halloween returns every October; winter next).
- More unlockable characters, more puzzle types.
- The reunion cut-scene grows richer over time.

### Never

Accounts; real-money purchases; ads; a public lobby or matchmaking with
strangers; free-text chat; collecting any personal information; gore.

## 11. Architecture

Adapted from Playbox (Aug-Oct 2026), plus a server.

### Hosting

- **One Cloudflare Worker serves the page, the art and the game connection from
  one address** (`/` for the page, `/ws` for the socket, `/art/...` for room
  images). One room = one Durable Object; leaderboards in Durable Object SQLite
  storage.
- **One allowlist entry** at parents.amazon.com covers everything.
- **Address: a free `workers.dev` one for now.** Cloudflare's free addresses
  have two parts: `<worker-name>.<account-subdomain>.workers.dev`. Brent picks
  the account subdomain once when setting up (e.g. `wherearewe`), so the game
  would be `https://play.wherearewe.workers.dev/` - a bare
  `wherearewe.workers.dev` is not possible. A custom domain can come later; it
  would mean a new allowlist entry and a fresh home-screen shortcut.
- The address must end in `/` (an unslashed address redirects, which fails
  offline).
- **Cost, checked 4 Oct 2026** against Cloudflare's pricing pages: Durable
  Objects run on the Workers Free plan with SQLite storage; free limits are
  100,000 requests/day, 13,000 GB-s of compute/day and 5 GB of storage;
  incoming WebSocket messages count 20:1; static asset requests are free and
  unlimited. The tightest limit is compute while a room's creature clock runs -
  estimated at **about 100 full 15-minute games a day free**. Over the limit,
  rooms fail for the rest of the day (no surprise bill). The paid plan is $5 a
  month. The spike measures real usage.
- **Brent creates the Cloudflare account and signs in**; deploys run from this
  machine with Cloudflare's `wrangler` tool.

### The page

- **One self-contained `index.html`**: inline CSS and JS, no CDN, no web fonts.
  Characters drawn in code on a canvas; room art loaded lazily from the same
  site, never at page load.
- **ES5-style JavaScript**: `var`, `function`; no arrow functions, classes,
  optional chaining or template literals (older Silk).
- Pointer Events with `setPointerCapture`; tested at 1024x600 and 600x1024.
- **Service worker**: a versioned shell cache and a separate unversioned asset
  cache (a code change never re-downloads the art); shell is
  stale-while-revalidate, so **an update reaches a tablet one launch late**;
  `?fresh=1` empties everything; registered on `load`.
- **`<link rel="manifest">` in the markup**; icons generated with Pillow.
- **The Check screen**, built early: a tick or cross for each of - service
  worker active, storage persisted, shell and art cached, WebSocket opens,
  round-trip time, speech synthesis available, audio unlocked, version, and the
  exact URL - with the one action that follows from any cross. Brent
  photographs it from the tablet.

### The game code

- **`rules`** - pure and deterministic: `init(config)`,
  `legalMoves(state, player)`, `apply(state, move)` returning a new state,
  `tick(state)` for the creature clock, `isOver(state)`. No DOM, no timers, no
  randomness except a seeded generator carried in the state. Tap-to-move paths
  are computed here on the room's walk grid. The same file runs in the page and
  in the Durable Object.
- **`creature`** - the creature's behaviour (patrol, listen, hunt, get
  distracted), built on `rules` and called from `tick`. There are no computer
  teammates; this is the only AI.
- **`transport`** - `{ send(move), onState(fn) }`:
  - `local`: solo, no network; the page runs `tick` on its own clock.
  - `online`: a WebSocket to the room; the server runs `tick`.
  - The game screen never knows which it has - that is what makes solo-offline
    and online one game.
- **Rooms as data**: each room is a data object (walk grid, hiding spots,
  objects, puzzle, two solution paths, creature route, art file) so new themes
  are mostly data plus art.
- **Sharing code between page and server**: `rules.js`, `creature.js` and the
  room data are written once, ES5-style; a small build script inlines them into
  `index.html` and the Worker imports the same files.

## 12. Risks and how the spike tests each one

The spike is a bare page plus a Worker and Durable Object on one address: two
devices join a room with a code and see each other's taps move a dot, and a
fake "creature" dot steps on the server clock. Plus a Check screen.

| # | Risk | How the spike tests it |
|---|---|---|
| 1 | **The Kids browser blocks the WebSocket** - the one thing that would sink online play | Open the spike from the Kids profile on the Fire (address allowlisted); the Check screen shows "WebSocket opens" tick/cross. Brent photographs it. If it is a cross: stop, bring the options before building anything else. |
| 2 | Same-origin `/ws` behaves differently from the page under the Kids browser | Covered by 1 - the socket is on the page's own address by design. |
| 3 | Offline solo fails when the page comes from a Worker rather than GitHub Pages (service worker scope, trailing slash, redirects) | Adult-profile home-screen shortcut; load once on wifi; aeroplane mode; reopen. The Check screen shows shell cached / service worker active. |
| 4 | Tablets drop off wifi and lose their seat | Turn wifi off on one tablet for 10 s, then on: it must rejoin the same seat, and the other device sees "zzz" then the dot return. |
| 5 | Lag makes tap-to-move feel broken | The Check screen shows round-trip time; tap on one device and watch the other. Target under 300 ms on home wifi. |
| 6 | The Fire tablet can't draw six animated characters plus a creature smoothly | The spike draws six placeholder layered characters at 1024x600; the Check screen shows frames per second. |
| 7 | Spoken preset phrases don't work in the Kids browser | Check screen: "speech synthesis available" and a Speak test button. If missing: recorded phrase audio instead (bigger download). |
| 8 | Free-tier compute runs out sooner than estimated | Run one 15-minute spike room with the clock ticking, read compute used in the Cloudflare dashboard, multiply. |
| 9 | Typed names leak real identities (residual risk accepted by Brent) | Not a spike item. Mitigated by the one-word/letters-only rule, filter, report-to-hide and weekly reset. Brent reviews reports. |
| 10 | **Halloween deadline** - four weeks for spike, rules, online, one theme, characters, tablet testing | Plan below; a weekly check against it. If the spike fails risk 1, Halloween ships solo-only and says so. |
| 11 | AI art arrives late or looks like a known character | Placeholders drawn in code mean nothing waits on art; every image is checked for resemblance before it is committed to the public repo. |
| 12 | The solo room goes live before the spike proves online play | Solo needs no server, so nothing in it depends on the spike. The `transport` split means the same room later plays online unchanged. |
| 13 | Scope - v1 is several games' worth | The Halloween edition and v1 lists in section 10 are the contract; additions go to "Later". |

### Halloween plan

- **Week 1 (5-11 Oct):** `rules`, `creature` and the `local` transport; the
  first Halloween room playable solo and **live**; Check screen and service
  worker from the first deploy. In parallel: Brent creates the Cloudflare
  account; spike deployed; tablet tests for risks 1-8. Art prompts delivered.
- **Week 2 (12-18 Oct):** `online` transport, rooms, codes, lobby, rejoin;
  rooms 2-3.
- **Week 3 (19-25 Oct):** rooms 4-5, characters and customisation, phrases,
  boosts, the safe-area stall, AI art wired in.
- **Week 4 (26-30 Oct):** Check screen polish, service worker, manifest, icons,
  sound, tablet testing with real kids. **Live by 29 Oct** so the
  one-launch-late update has reached tablets by the 31st.

## 13. Decisions and open questions

Decided 4 Oct 2026: Halloween theme *The Party at the End of the Lane*;
unlockables Patch, Echo and Bramble (renamed from Sprout, a Roblox name); AI
art with our own art possible later; energy per player; running with stamina;
boosts in rooms; a safe-area stall; free `workers.dev` address; public repo;
Option A release order.

Still open (none blocks this week):

1. **Who reviews reported names**, and how: proposed - a simple admin page
   behind a secret link that only Brent has. Needed for v1 leaderboards.
2. **The Cloudflare account subdomain** - Brent picks it at sign-up (e.g.
   `wherearewe`).
3. **The other three unlockable names** are also checked against existing
   game characters before they ship.
