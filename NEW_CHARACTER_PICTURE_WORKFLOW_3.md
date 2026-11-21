# New characters picture workflow 3: Nova, Ember, Rosie and Sage (21 Nov 2026)

Front and back toon pictures for four new girls, based on Brent's four
character sheets. The names are working names; renaming one later only
changes its folder.

| Working name | Brent's sheet | Look |
|---|---|---|
| **Nova** | gray-and-purple armor | space knight, strawberry-blonde |
| **Ember** | bronze armor, witch hat, fire | fire witch, long blonde hair |
| **Rosie** | pink plaid and hearts | heart knight, pink glasses |
| **Sage** | silver-and-gold elf armor, grumpy | grumpy elf ranger |

The sheets are copied to `art/look-source/`. That folder is in `.gitignore`
and stays out of the repo, because the repo is public and the sheets show
real faces.

What changes from the sheets, so the characters fit the game and the 3D
models work:
- **No weapons.** There are no guns, swords, hammers, nunchucks, bows or
  daggers, because the hosts are never fought. The skills can still nod to
  them (see below).
- **Nothing glowing and no fire.** Ember's flames become flat orange
  flame-shaped patches on her armor.
- **Small hats only.** Ember's witch hat has a small brim, because big brims
  break the 3D model.
- **Toon faces.** Each face gets the hair, glasses and expression from the
  sheet, not the photo face. Sage keeps her grumpy scowl.

```
create new workflow to create images based on the [Picture Standard], [Reference] and [Picture]. For each picture, attach every [Reference] picture listed, in that order, then save to "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input\[file name]". For example, C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input\nova\front-toon.png. Create the folder if it does not exist.
The [Picture Standard] will be included with every picture prompt. The [Picture] prompt is added to [Picture Standard] and changes per prompt. The [Reference] and [file name] are defined per picture. Make the pictures in the order of the table: each back view uses the front view made just before it as its reference.
[Picture Standard] = "This is for a kids' co-op escape game for ages 8 and up: friendly, funny and a little spooky, never scary. For a FRONT view two pictures are attached. The FIRST is another character from the same game: use it ONLY as a guide to the style, proportions and level of detail. The SECOND is a photo-style character sheet: use it ONLY as a guide to this character's hair, glasses, expression, outfit colors and outfit shapes. Redraw her completely in the first picture's cartoon style - do not copy the photo's face, realism, lighting or texture. Leave out every weapon on the sheet (no guns, swords, hammers, nunchucks, bows, arrows or daggers) and every flame or glow. For a BACK view one picture is attached: the same character seen from directly behind, same pose, every color the same as the front. Clean, simple 3D cartoon toy style: every area one smooth, flat, solid color, with no texture at all - no fabric grain, no knit, no stitching, no dirt, no scratches, no folds or wrinkles painted on, no shading or shadows painted on, nothing see-through and nothing glowing. Simple rounded shapes, slightly chunky proportions, a girl about 10 years old, big clear eyes, warm skin tone (never pale or white). Armor is a few big smooth rounded plates, not many small pieces. Small details as simple solid shapes, close to the body - nothing thin or long sticking out, nothing in her hands. No logos, brand marks, emblems, printed words or graphics. Not like any famous character from a film, cartoon or game. Full body standing in an A-pose: arms straight and angled clearly down and away from the body with a clear gap between each arm and the body all the way down, hands open and empty, legs slightly apart, feet flat. Centered and filling the whole height, nothing cropped. Plain flat light-gray background, even soft light, no floor shadow. One character only, no text."
Table for each [Picture], [Reference] and [file name] combination is below:
[Picture] | [Reference] | [file name]
[FRONT view of Nova, a brave, cheerful space knight girl with a big friendly grin: warm light-peach skin, long wavy strawberry-blonde hair loose past her shoulders, big blue-gray eyes. A sleek dark-charcoal gray suit of rounded armor: a smooth gray chest plate with one simple hexagon shape in the middle, round gray shoulder pads with a solid purple panel on each, gray forearm guards with a purple stripe, a black belt with a plain square gray buckle, black fitted pants, rounded gray knee pads with a purple hexagon on each, chunky gray boots with black soles, black gloves. A black high collar at her neck. No helmet, no holsters, no weapons.] | [model-input\glow\front-toon.png, look-source\nova.webp] | [nova\front-toon.png]
[BACK view of Nova, matching the reference exactly: the back of her long wavy strawberry-blonde hair down over her shoulders, the back of the gray armor with purple panels on the shoulder pads, black belt, black pants, gray boots.] | [model-input\nova\front-toon.png] | [nova\back-toon.png]
[FRONT view of Ember, a fiery, happy fire-witch girl with a big grin: warm light-peach skin, long straight blonde hair loose past her shoulders, big blue-gray eyes. A small dark-brown pointed witch hat with a SMALL brim close to her head and a solid orange band with a simple gold flame shape. Rounded bronze armor: a bronze chest plate with one simple solid orange flame shape in the middle, bronze shoulder pads, bronze forearm guards, a brown leather tunic skirt to her knees with a solid orange flame shape on the front panel, a brown belt with a round gold buckle, dark-brown pants, bronze shin guards with small orange flame shapes, chunky brown boots. Fingerless dark-brown gloves, hands open and empty. The flames are flat solid orange shapes, NOT real fire and NOT glowing. No sword, no staff, no fire in her hands.] | [model-input\glow\front-toon.png, look-source\ember.webp] | [ember\front-toon.png]
[BACK view of Ember, matching the reference exactly: the back of the small brown witch hat with its orange band, her long straight blonde hair down her back, the bronze armor, the brown tunic skirt with a solid orange flame shape on the back panel, brown boots. No sword on her back.] | [model-input\ember\front-toon.png] | [ember\back-toon.png]
[FRONT view of Rosie, a sweet, smiley heart-knight girl: warm light-peach skin, long straight light-brown hair past her shoulders with a middle part, big hazel eyes, round clear-pink glasses. A raspberry-red buttoned jacket with a light-pink sailor-style collar and a small gold heart at the neck, rounded light-pink shoulder pads, light-pink forearm guards, a raspberry belt with a square gold buckle, a short pink-and-raspberry plaid skirt over raspberry pants (the plaid as a few big simple squares), rounded light-pink knee pads with a small heart on each, light-pink lace-up boots with a small raspberry heart on each. No hammer, no nunchucks.] | [model-input\glow\front-toon.png, look-source\rosie.webp] | [rosie\front-toon.png]
[BACK view of Rosie, matching the reference exactly: the back of her long straight light-brown hair, the light-pink sailor collar lying flat on her back, the raspberry jacket, pink shoulder pads, the plaid skirt, raspberry pants, light-pink boots.] | [model-input\rosie\front-toon.png] | [rosie\back-toon.png]
[FRONT view of Sage, a grumpy little elf-ranger girl with a funny scowl (frowning eyebrows, pouting mouth - grumpy and cute, not angry or mean): warm light-peach skin, long wavy light-brown hair past her shoulders, big hazel eyes, round thin gold glasses, a simple gold leaf-shaped circlet across the top of her head. Rounded silver armor with gold trim: a silver chest plate with one simple gold leaf shape, rounded silver shoulder pads, silver forearm guards, a brown belt with a round gold buckle, a dark-green tunic skirt to her knees with a simple gold border, dark-green pants, silver shin guards, silver boots. No bow, no quiver, no daggers.] | [model-input\glow\front-toon.png, look-source\sage.webp] | [sage\front-toon.png]
[BACK view of Sage, matching the reference exactly: the back of her long wavy light-brown hair with the gold circlet around the back of her head, the silver armor with gold trim, the dark-green tunic skirt with its gold border, dark-green pants, silver boots. No quiver.] | [model-input\sage\front-toon.png] | [sage\back-toon.png]
```

Send Claude the 8 pictures to check (look-alikes, logos, arms clear of the
body, no weapons) before making the models with Stable Fast 3D.

## Still to decide (Brent)

- **Names:** Nova, Ember, Rosie and Sage are recommendations.
- **Skills:** each girl needs a skill no current kid has. Design them
  together after the pictures pass. Avoid overlaps:
  - Glow already reveals secrets.
  - Muscle already shoves heavy things.
  - The Freeze boost already stops the host.
- **Free or paid:** whether each new girl is free or unlocked with points.
