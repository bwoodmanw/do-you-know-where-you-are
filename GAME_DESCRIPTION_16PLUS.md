# Game description for older players + the Weekly Speedrun Challenge (22 Nov 2026)

Brent asked (21 Nov) for free ways to get players aged 16+ to notice Escape
Crew. This is pieces 1 and 2 of that plan: a game page that leads with
challenge, and a weekly speedrun with a badge.

## 1. The game description (challenge first)

Paste into **Creator Hub > Creations > Escape Crew > Configure > Basic Info >
Description**. Roblox allows 1,000 characters; both versions are under that.
No emoji, American English, the words people search for (co-op, escape,
speedrun, survive, hide and seek).

### A. Now until November 30 (replaces the Thanksgiving one)

```
Can your crew escape before the host catches you? 1 to 6 players, co-op escape and survival.

THE CHALLENGE
- 4 difficulties up to NIGHTMARE: shorter timer, longer codes, a host that sees farther and peeks into hiding spots
- WEEKLY SPEEDRUN: a new floor every week. Beat the par time on Hard or Nightmare for bonus points and the Speedrunner badge
- The Fastest Escapes board resets every week. Can you take the top spot?
- 18 floors in 6 buildings, plus a secret basement

BUILD YOUR CREW
- 18 characters, each with a skill and two power picks at levels 10 and 20
- Juke through the host, throw a turtle shell, hide your crew in fog, copy a friend's skill
- Free caught friends from the cage. Nobody gets left behind

HOW TO ESCAPE
- Pop clue balloons to crack the door code (some are tricks)
- Search, sneak, hide and crawl through vents
- Out of stamina? Hope your crew has your back

THANKSGIVING: the Harvest Barn and the Turkey Roundup, until November 30.
```

### B. From December 1 (swap the last line only)

Same text, with the last line replaced by:

```
CHRISTMAS: Candy Cane Lane, Claus Manor and the Candy Cane Hunt, until January 1.
```

"18 characters" counts the 8 starters and the 10 newer ones (Nutmeg, Cloud,
Holly, Clone, Harmony, Elfy and the four girls). Raise it when more arrive.

## 2. The Weekly Speedrun Challenge (built 22 Nov)

What players see:

- **Lobby:** a yellow strip along the bottom of the *Fastest escapes this
  week* board: `Weekly Speedrun: <floor> / Hard under 3:30 or Nightmare under
  3:00`. The board shows 5 rows now (was 6) to make room.
- **In the game,** 6 seconds after a game on that floor starts: "Weekly
  Speedrun floor! Escape in under 3:30 for +100 points and the Speedrunner
  badge." (On Easy or Normal it says to play it on Hard or Nightmare.)
- **Results screen,** on your own line:
  - every escape: your best time on that floor and difficulty: "First best
    time: 3:12", "New best! 14 s faster", "Tied your best!" or "9 s off your
    best (2:58)";
  - beat the challenge: "Speedrun Challenge beaten! +100" (once a week; after
    that "Speedrun beaten again");
  - escaped the challenge floor but too slow: "Speedrun par 3:30 - so close!"

The rules (in `Config.SPEEDRUN` and `roblox/src/shared/Speedrun.luau`):

- One floor a week from the 18 year-round floors (not the Secret Basement or
  season floors), in a mixed-up order so one building's floors don't come
  three weeks running.
- The week changes at the same moment as the fastest board: **Wednesday
  7 PM Eastern** (Thursday 00:00 UTC).
- Par: **Hard 3:30, Nightmare 3:00**, about two thirds of each timer. The time
  is the one on the results screen (from when the characters are chosen). Not
  Tower Runs.
- +100 points once a week per player; the badge every time (Roblox gives a
  badge only once anyway).

The next weeks:

| Week starts (Wed 7 PM Eastern) | Floor |
|---|---|
| Nov 18 (now) | Gummy: Candy Factory |
| Nov 25 | School: Clock Tower |
| Dec 2 | Party House: Ground |
| Dec 9 | Hospital: Wards |
| Dec 16 | Carnival: The Funhouse |
| Dec 23 | Gummy: Bounce Hall |

### The badge (Brent makes it, then sends me the ID)

Picture: any 512 x 512 picture; a lightning bolt over a stopwatch fits. I can
make one with the badge-picture tool if you want.

- **Name:** Speedrunner
- **Description:** Beat the Weekly Speedrun Challenge: escape the week's
  floor on Hard or Nightmare within the par time.

Until the ID is in `Config.BADGES.speedrun`, the points and the messages work
and no badge is given.

## 3. The Event page (Creator Hub > Events), optional

A Roblox Event shows on the game page with a **Notify me** button. One event
a week is a lot of upkeep; one event for a whole season of speedruns is
easier:

- **Title:** Speedrun Season
- **Subtitle:** A new floor to race every week
- **Description:**
  Think you're fast? Every week one floor of Escape Crew becomes the Speedrun
  floor. Escape it on Hard or Nightmare within the par time to earn bonus
  points and the Speedrunner badge, then climb the Fastest Escapes board
  before it resets. New floor every Wednesday at 7 PM Eastern. Bring your
  fastest crew!
- **Starts:** the day you create it. **Ends:** January 31.
- **Category:** Competition (or the closest one Creator Hub offers). **Start Place:** Escape Crew. **Privacy:** Public.
- **Submit for Featuring:** on (it needs to be created at least a week before
  it starts to be considered).
- **Picture:** 1920 x 1080; I can make it with `tools/make_event_art.py` once
  the badge picture exists.
