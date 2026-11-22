# Portraits for Juliette, Gillian, Vivienne and Charlotte (21 Nov 2026)

The four girls' character buttons in the Lobby and the game showed only a
plain color tile with an emoji (Brent's photo, 21 Nov), because they have no
portraits yet. This workflow makes four square portraits laid out like the
others in `art/roblox-store/portraits/`: chest up, a glowing circle behind
the girl, and a round skill badge in the bottom-right corner.

Each portrait attaches two pictures:
1. The girl's approved full-body front, which fixes who she is.
2. Nutmeg's portrait, which fixes the layout.

The portraits are used for:
- the Lobby's character buttons, Party panel, Shop and Gift panel
  (`Config.PORTRAITS`);
- the game's character card (`Config.PORTRAITS_GAME`).

## Generate the portraits

1. Resolve the reference and output paths from `art/`. Process each row
   with a separate ImageGen call, attaching the approved front first and
   `Nutmeg.png` second.
2. Combine the full Picture Standard with the row's Picture prompt.
   Match Nutmeg's square chest-up crop, head scale, halo placement, and
   gold-rimmed badge in the bottom-right corner.
3. Check the portrait against the character's approved front for hair,
   eye color, glasses, and clothing. Check the gesture and badge against
   the row. Gillian's teal iris belongs on the viewer's left and her
   green iris on the right.
4. Save the checked square PNG to the row's output path. Create the
   destination folder if needed.

## Picture Standard and portrait prompts

```
create new workflow to create images based on the [Picture Standard], [Reference] and [Picture]. For each picture, attach every [Reference] picture listed, in that order, then save to "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\[file name]". For example, C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\roblox-store\portraits\Juliette.png. Create the folder if it does not exist.
The [Picture Standard] will be included with every picture prompt. The [Picture] prompt is added to [Picture Standard] and changes per prompt. The [Reference] and [file name] are defined per picture.
[Picture Standard] = "A square character portrait for a kids' co-op escape game for ages 8 and up. The FIRST attached picture is the character's approved full-body look: keep her face, skin tone, eye color, hair, glasses and clothes exactly the same, only in a richer, polished 3D animated-movie style with soft light, big clear eyes and a warm, happy smile. The SECOND attached picture is another character's finished portrait: copy its layout exactly - chest up, turned slightly toward the camera, the same size of head, a soft glowing circle behind the character on a dark background, and a round badge with a gold rim in the bottom-right corner - but it is a different character, so take nothing else from it (no antlers, no hood, no scarf, no bell, no mitten). No logos, brand marks, printed words, letters or numbers anywhere. Not a copy of any existing cartoon, film or game character. Bright, friendly and right for young kids. One character only, no text."
Table for each [Picture], [Reference] and [file name] combination is below:
[Picture] | [Reference] | [file name]
[PORTRAIT of Juliette, a cheerful, dramatic girl in a theater-camp turtle costume: warm light-peach skin with light freckles, bright blue eyes, long wavy strawberry-blonde hair, a soft green hood pulled up with two round cartoon turtle eyes on top (her face and hair clearly showing), a solid green short-sleeved dress, the green shoulder straps of her turtle shell, and the rounded edge of the green shell peeking over one shoulder. A big happy grin, one hand raised in a little theatrical wave. NO mask, NO bandana, NO headband. Behind her a soft glowing circle in leaf green and soft gold, like a stage spotlight, on a deep forest-green background. Badge: a green circle with a gold rim and a small simple turtle shell with a hexagon pattern inside.] | [model-input\juliette\front-toon.png, roblox-store\portraits\Nutmeg.png] | [roblox-store\portraits\Juliette.png]
[PORTRAIT of Gillian, a sporty, happy girl: warm light-peach skin, long straight blonde hair, eyes of two different colors - her right eye (on the LEFT of the picture) green-blue teal and her left eye (on the RIGHT of the picture) bright green - a periwinkle blue-purple hoodie with the hood down and two drawstrings. A big confident grin, leaning forward slightly as if about to sprint, one fist raised by her shoulder. Behind her a soft glowing circle in periwinkle and white with a few short speed streaks inside it, on a deep indigo background. Badge: a periwinkle circle with a gold rim and a small white sneaker with motion lines inside (plain, no logo, no stripes).] | [model-input\gillian\front-toon.png, roblox-store\portraits\Nutmeg.png] | [roblox-store\portraits\Gillian.png]
[PORTRAIT of Vivienne, a sweet, smiley girl: warm light-peach skin, hazel eyes (golden-brown with a hint of green), round clear-pink glasses, long straight golden honey-blonde hair with a middle part, a baby-pink zip-up jacket zipped halfway over a white tank top. A gentle, happy smile, both hands raised by her face as if cheering a friend on. Behind her a soft glowing circle in pink and warm white with a few small hearts and sparkles inside it, on a deep raspberry background. Badge: a pink circle with a gold rim and a small white megaphone inside.] | [model-input\vivienne\front-toon.png, roblox-store\portraits\Nutmeg.png] | [roblox-store\portraits\Vivienne.png]
[PORTRAIT of Charlotte, a bright, beaming girl: warm light-peach skin, bright blue eyes, round clear-pink glasses, long wavy honey-brown hair with golden-blonde tones, a sporty green crew-neck sweatshirt with white cuffs. A big happy smile (never grumpy), one hand raised flat above her eyes like a lookout scanning ahead. Behind her a soft glowing circle in gold and warm white, on a deep amber-brown background. Badge: a gold circle with a gold rim and a small simple white spyglass inside.] | [model-input\charlotte\front-toon.png, roblox-store\portraits\Nutmeg.png] | [roblox-store\portraits\Charlotte.png]
```

## After generation

1. Tell Claude when the four pictures are saved. Claude checks each one
   (it looks like its model, no look-alikes or logos, the badge is in the
   corner) and makes 512 x 512 copies (`Juliette-512.png` and so on).
2. In Studio (either place): **View** > **Asset Manager** > **Images** >
   **Bulk Import**, then pick the four `-512.png` files.
3. Right-click each image > **Copy ID to Clipboard**, and send Claude the four
   IDs. One upload serves both places. They go into `Config.PORTRAITS` and
   `Config.PORTRAITS_GAME`.
