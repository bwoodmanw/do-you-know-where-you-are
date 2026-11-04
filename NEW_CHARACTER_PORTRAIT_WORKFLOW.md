# Portraits for Cloud, Holly, Clone and Harmony (4 Nov 2026)

Four square portraits laid out like the other nine in
`art/roblox-store/portraits/`: chest up, a glowing circle behind the
character, and a round skill badge in the bottom-right corner. Each one
attaches two pictures: the character's approved full-body front first (it
fixes who they are), then Nutmeg's portrait (it fixes the layout).

The portraits are used for:
- the Lobby's character buttons, Party panel and Shop (`Config.PORTRAITS`);
- the game's character card (`Config.PORTRAITS_GAME`).

These four are free, so none of them has a Game Pass picture.

```
create new workflow to create images based on the [Picture Standard], [Reference] and [Picture]. For each picture, attach every [Reference] picture listed, in that order, then save to "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\[file name]". For example, C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\roblox-store\portraits\Cloud.png. Create the folder if it does not exist.
The [Picture Standard] will be included with every picture prompt. The [Picture] prompt is added to [Picture Standard] and changes per prompt. The [Reference] and [file name] are defined per picture.
[Picture Standard] = "A square character portrait for a kids' co-op escape game for ages 8 and up. The FIRST attached picture is the character's approved full-body look: keep their face, skin tone, eye color, hair and clothes exactly the same, only in a richer, polished 3D animated-movie style with soft light, big clear eyes and a warm smile. The SECOND attached picture is another character's finished portrait: copy its layout exactly - chest up, turned slightly toward the camera, the same size of head, a soft glowing circle behind the character on a dark background, and a round badge with a gold rim in the bottom-right corner - but it is a different character, so take nothing else from it (no antlers, no hood, no scarf, no bell, no mitten). No logos, brand marks, printed words, letters or numbers anywhere. Not a copy of any existing cartoon, film or game character. Bright, friendly and right for young kids. One character only, no text."
Table for each [Picture], [Reference] and [file name] combination is below:
[Picture] | [Reference] | [file name]
[PORTRAIT of Cloud, a cheerful, dreamy girl: warm light-brown skin, light-blue eyes, an almost-white chin-length rounded bob with a faint pale-blue tint and a soft side-swept fringe, eyebrows the same almost-white as her hair, a sunny-yellow raincoat with big round white buttons and the hood down, the white straps of her backpack on her shoulders. One hand raised beside her face with a small puff of soft white cloud floating just above her open palm. Behind her a soft glowing circle in pale sky-blue and white with a few small fluffy clouds inside it, on a deep navy-blue background. Badge: a sky-blue circle with a gold rim and a small fluffy white cloud inside.] | [model-input\cloud\front-toon.png, roblox-store\portraits\Nutmeg.png] | [roblox-store\portraits\Cloud.png]
[PORTRAIT of Holly, a cheerful, kind girl: warm light-peach skin, bright green eyes, long straight golden-blonde hair worn loose over her shoulders (not in pigtails), a round red-and-white peppermint candy with a little red bow on each side of her head, a red-and-green striped sweater with a round white collar, a small sprig of two holly leaves and three red berries at the collar. One hand holding up a round red-and-white peppermint candy beside her cheek, smiling. Behind her a soft glowing circle in red and white with a few small peppermint swirls and snowflakes inside it, on a deep pine-green background. Badge: a red circle with a gold rim and two green holly leaves with three red berries inside.] | [model-input\holly\front-toon.png, roblox-store\portraits\Nutmeg.png] | [roblox-store\portraits\Holly.png]
[PORTRAIT of Clone, a clever, cheeky boy: warm brown skin with a few freckles on his cheeks, big brown eyes, short curly black hair, round orange goggles with dark lenses pushed up on his forehead, a zip-up jacket split down the middle - teal on his right side (the left of the picture) and orange on his left side - with a plain gray zipper and a white T-shirt at the neck, a chunky round gray wrist gadget with a plain dark screen on his left wrist. A sly, friendly grin, one hand raised in a small wave showing the wrist gadget. Behind him a soft glowing circle that is half teal and half orange, on a deep charcoal-gray background, with a faint see-through outline of his own shape beside him like a friendly copy. Badge: a teal circle with a gold rim and two simple matching person shapes side by side inside, one teal and one orange.] | [model-input\clone\front-toon.png, roblox-store\portraits\Nutmeg.png] | [roblox-store\portraits\Clone.png]
[PORTRAIT of Harmony, a warm, musical girl: warm golden-tan skin, big dark-brown eyes, long straight black hair past her shoulders with straight bangs, two small yellow music-note hair clips on one side, a lavender hoodie with the hood down and three wavy darker-purple bands across the chest, a small round gold music-box pendant on a short gold chain, a black-and-white piano-key wristband on her right wrist. Eyes softly smiling as she hums, one hand raised near her shoulder with a few small gold music notes floating up from it. Behind her a soft glowing circle in lavender and gold with a few small floating music notes inside it, on a deep purple background. NO headphones. Badge: a purple circle with a gold rim and a small gold music box inside.] | [model-input\harmony\front-toon.png, roblox-store\portraits\Nutmeg.png] | [roblox-store\portraits\Harmony.png]
```

## After ChatGPT makes them

1. Tell Claude when the four pictures are saved. Claude checks each one
   (it looks like its model, no look-alikes or logos, the badge is in the
   corner) and makes 512 x 512 copies (`Cloud-512.png` and so on), the
   same way as `Nutmeg-512.png`.
2. In Studio (either place): **View** > **Asset Manager** > **Images** >
   **Bulk Import** > pick the four `-512.png` files.
3. Right-click each image > **Copy ID to Clipboard**, and send Claude the
   four IDs. One upload serves both places, as with Nutmeg's and Patch's
   portraits. They go into `Config.PORTRAITS` and `Config.PORTRAITS_GAME`.
