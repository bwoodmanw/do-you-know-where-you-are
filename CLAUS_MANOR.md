# Claus Manor - the Christmas present hunt (design, 5 Nov 2026)

Brent's brief (5 Nov): a second Christmas map with several floors. The hosts
are the evil Mr and Mrs Claus. On each floor the crew must find all the
presents in time, like the Turkey Roundup. Some presents are decoys: an elf
pops out and runs away making noise, which brings the Clauses. Mr Claus
throws coal (slowed about 2 s), and Mrs Claus needs an ability too. The
presents open the exit door (no key, no code). Presents also earn Elfy, a
limited-edition character who can only be won by playing: a boy elf with
blonde hair and green eyes, with his own skill tree.

"Evil" stays kid-friendly: grumpy, sneaky and silly, never frightening. The
same rule applies to every host.

## The building

**Claus Manor**: a secret Christmas building, like Candy Cane Lane. It is
only open during the event (Dec 1 - Jan 1) and has its own card on the map
screen. It has **3 floors**, played in order; the next floor opens once the
one before is escaped, as in the other buildings.

| Floor | Name | Host | Presents (real + decoys) |
|---|---|---|---|
| 1 | The Toy Workshop | Mr Claus | 6 + 3 |
| 2 | The Cookie Kitchen | Mrs Claus | 8 + 4 |
| 3 | The Sleigh Loft | **both** Clauses | 10 + 5 |

The Sleigh Loft has reindeer standing in their stalls (Brent, 5 Nov) and a
big red sleigh piled with presents.

Recommended split: one Claus on each of floors 1 and 2, and both together on
the top floor. Kids learn each Claus's trick on its own floor before facing
them together. Two hosts at once is new for the game, so only floor 3 needs
it.

## The present hunt (every floor)

- Presents sit on free floor spots round the floor, spread apart, as the
  turkeys are. Every present looks the same: a wrapped box with a bow.
- **Hold to open** (about 1.5 s; hold-speed perks count). A **real present**
  pops with confetti, counts toward the floor's total ("4 of 8 presents"),
  gives points, and adds one to your Elfy count.
- A **decoy** springs open and a **Toy Elf** jumps out. He runs away round
  the floor jingling his bells for 8 s, and every jingle tells both Clauses
  where he is. **Tag him** (run into him) to stop the noise. He tips his hat,
  then vanishes in a puff of snow, and you get a few points.
- Once every real present is open, the big door swings open (as the barn
  doors do for the turkeys). There are **no keys, locks or code** on these
  floors: the hunt is the whole puzzle. Clues, boosts and characters' skills
  work as usual.
- The round timer is the normal one. If it runs out, the crew loses, as on
  any floor.

## The hosts

| | Mr Claus | Mrs Claus |
|---|---|---|
| Look | A big, grumpy, round man in a dark-red suit with black boots, a frosty-white beard, a soot-smudged cap, a sack of coal on his belt, and a scowl | A tall, sly lady in a plum-and-red dress with a white apron, small round glasses, a tight white bun, oven mitts, and a long rolled-up list |
| Skill | **Lump of Coal**: throws coal in a slow arc you can see coming, like the Pumpkin's throw. A kid it hits is **slowed for 2 s**. Hiding and crawling dodge it | **Naughty List**: when she spots a kid, she writes them on her list. For **6 s** both Clauses know where that kid is and head there. Hiding (a closet, a present, a vent, Cloud's fog, a sneak skill) takes you off the list at once |
| Floors | 1 and 3 | 2 and 3 |

Both Clauses hear the Toy Elves' jingles and any other noise. Kids' skills
that stop or slow "the host" work on whichever Claus is nearest.

## The Toy Elf (the decoy): yes, a new little character

A separate **knee-high wind-up toy elf** (a big winding key in his back, rosy
cheeks, a pointed hat with a bell), **not** Elfy. If the decoy looked like
Elfy, players who earned Elfy would see "their" character as the thing that
gets them caught. He needs a front and a back picture and a 3D model (made
like the runaway turkey). He isn't a playable character.

## Elfy - limited edition, won only by playing

- **How to get him:** open **150 real presents** in Claus Manor during
  Christmas 2026. Only presents you open yourself count; there's no party
  share, which keeps him rare. A counter shows "Elfy: 87 / 150".
- He can't be bought (no Game Pass, no candy canes). After Jan 1 he can't be
  earned until the event returns. You can still gift him as the owner.
- A full run of the building is 24 real presents across 3 floors, so
  150 is about 6-7 full runs, or more in a big party where friends open some
  of the presents. That's a real challenge spread over a month, and a kid who
  plays the event can still do it.
- **Look:** a boy of about 10, blonde hair, green eyes, pointed ears, a green
  elf tunic with a gold belt, red-and-white striped leggings, curly-toed
  green shoes and a green pointed hat with a small gold bell.

### Elfy's skills

- **Elf Hands** (always on): opens drawers, boxes, presents and hiding spots
  **25% faster**.
- **Wind-up Toy** (button, 35 s recharge): sets down a little wind-up toy
  soldier that marches off jingling for 6 s. The host goes after the noise,
  the way he follows Echo's Sound Wave.
- Levels 3-19: the usual small perks (recharge, stamina, hold speed, free
  clue, sight, a starting Party Shield), with Christmas names.
- **Level 10**, pick one:
  - **Marching Band**: the toy marches 3 s longer and twice as loud (heard
    from twice as far).
  - **Wrapped Up** (Brent, 5 Nov - replaces Gift Sense, which only worked on
    one map): as he sets the toy down, Elfy hides inside a present for 5 s
    and the host walks past.
- **Level 20**, pick one:
  - **Toy Parade**: a button, once a game: three toys march off in three
    directions at once.
  - **Workshop Rush**: a button, once a game: for 10 s Elfy and friends near
    him open and hold everything twice as fast.

## The pictures needed

See `CLAUS_MANOR_PICTURE_WORKFLOW.md`:
- Front and back pictures for 3D models: Mr Claus, Mrs Claus, the Toy Elf and
  Elfy.
- Elfy's portrait and his skill button picture.
- The Claus Manor building card and its 3 floor cards.

## The build (after the pictures; code can start now)

1. Floor plans: 3 floors in `tools/make_housemap.py`, with a new `claus`
   theme (workshop, kitchen and loft furniture). No locks or keys; every
   door is open.
2. The present hunt in Main: presents, decoys, Toy Elves, the door, and the
   Elfy counter in the profile.
3. Mr Claus's coal and Mrs Claus's Naughty List, using the Pumpkin's throw
   and the host's alert.
4. A second host on floor 3, stepped alongside the first. Catching, alerts
   and kids' stuns work on both.
5. Elfy: Config, his skills, Progress levels, the reward and the Lobby
   counter.
6. The map screen card and the season gate, as for Candy Cane Lane.
7. Then the Christmas skins for every character (a separate workflow).
