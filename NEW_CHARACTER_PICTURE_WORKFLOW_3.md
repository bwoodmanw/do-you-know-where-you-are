# New characters picture workflow 3: Juliette, Gillian, Vivienne and Charlotte (21 Nov 2026)

Front and back toon pictures for four new girls. Brent sent four character
sheets and chose the names and outfits:

| Name | Sheet (faces and hair only) | Outfit (Brent, 21 Nov) |
|---|---|---|
| **Juliette** | strawberry-blonde, gray-purple armor sheet | all black (leggings, shirt, shoes) plus a theater-camp turtle costume |
| **Gillian** | blonde, fire-witch sheet | pink patterned leggings, blue-purple hoodie, chunky running sneakers; one eye green, one green-blue |
| **Vivienne** | light-brown hair, pink glasses, heart-knight sheet | black leggings, white tank top, baby-pink jacket half zipped, brown sheepskin-style boots |
| **Charlotte** | light-brown wavy hair, glasses, elf sheet | black skirt, sporty green sweatshirt, gold high-top sneakers; a big smile (not grumpy) |

The sheets are copied to `art/look-source/`. That folder is in `.gitignore`
and stays out of the repo, because the repo is public and the sheets show
real faces. Only the face, hair, glasses and eyes are taken from a sheet.
The armor, hats and weapons are all left out.

Brands Brent named are described without the brand (no logos or signature
marks), because the game is public:
- Gillian's sneakers: chunky cushioned running shoes, with no swoosh, side
  stripe or checkerboard.
- Vivienne's boots: plain sheepskin-style pull-on boots, with no label.
- Charlotte's shoes: canvas high-tops, with no star patch.

Juliette's turtle costume also has no mask, bandana or headband, so she
can't be read as a famous cartoon turtle.

```
create new workflow to create images based on the [Picture Standard], [Reference] and [Picture]. For each picture, attach every [Reference] picture listed, in that order, then save to "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input\[file name]". For example, C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input\juliette\front-toon.png. Create the folder if it does not exist.
The [Picture Standard] will be included with every picture prompt. The [Picture] prompt is added to [Picture Standard] and changes per prompt. The [Reference] and [file name] are defined per picture. Make the pictures in the order of the table: each back view uses the front view made just before it as its reference.
[Picture Standard] = "This is for a kids' co-op escape game for ages 8 and up: friendly, funny and a little spooky, never scary. For a FRONT view two pictures are attached. The FIRST is another character from the same game: use it ONLY as a guide to the style, proportions and level of detail. The SECOND is a photo-style character sheet of the girl this character is based on: use it ONLY as a guide to her hair (color, length and style), eye color and glasses. IGNORE everything she wears on the sheet - no armor, no hats, no circlets, no weapons, no flames - she wears ONLY the outfit written in this prompt. Redraw her completely in the first picture's cartoon style - do not copy the photo's realism, lighting or texture. A happy, positive face with a warm smile. For a BACK view one picture is attached: the same character seen from directly behind, same pose, every color the same as the front. Clean, simple 3D cartoon toy style: every area one smooth, flat, solid color, with no texture at all - no fabric grain, no knit, no stitching, no dirt, no folds or wrinkles painted on, no shading or shadows painted on, nothing see-through and nothing glowing. Patterns only as a few big simple solid shapes. Simple rounded shapes, slightly chunky proportions, a girl about 10 years old, big clear eyes, warm skin tone (never pale or white). Small details as simple solid shapes, close to the body - nothing thin or long sticking out, nothing in her hands. No logos, brand marks, emblems, swooshes, stripes on shoes, printed words or graphics. Not like any famous character from a film, cartoon or game. Full body standing in an A-pose: arms straight and angled clearly down and away from the body with a clear gap between each arm and the body all the way down, hands open and empty, legs slightly apart, feet flat. Centered and filling the whole height, nothing cropped. Plain flat light-gray background, even soft light, no floor shadow. One character only, no text."
Table for each [Picture], [Reference] and [file name] combination is below:
[Picture] | [Reference] | [file name]
[FRONT view of Juliette, a cheerful, dramatic girl dressed for a theater-camp show as a turtle, with a big happy grin: warm light-peach skin, long wavy strawberry-blonde hair loose past her shoulders, big blue-gray eyes. A plain black long-sleeve shirt, plain black leggings, plain black flat shoes. Over them a simple handmade-looking turtle costume: a soft green hood with two round cartoon turtle eyes on top, pulled up with her face and hair clearly showing, a smooth rounded light-yellow belly plate on her front with a few simple darker lines, and the edge of a green shell showing at her sides, held on by two green shoulder straps. NO mask, NO bandana, NO headband, NO weapons, NOT a ninja.] | [model-input\glow\front-toon.png, look-source\juliette.webp] | [juliette\front-toon.png]
[BACK view of Juliette, matching the reference exactly: the green hood with the two cartoon turtle eyes on top, her strawberry-blonde hair showing below the hood, a big rounded green turtle shell on her back (close to her body, not sticking far out) with a simple pattern of large darker-green hexagon shapes and a lighter-green rim, the green shoulder straps, black leggings and black shoes.] | [model-input\juliette\front-toon.png] | [juliette\back-toon.png]
[FRONT view of Gillian, a sporty, happy girl with a big grin: warm light-peach skin, long straight blonde hair loose past her shoulders. Her eyes are two different colors: her LEFT eye (on the right of the picture) is bright green and her RIGHT eye (on the left of the picture) is green-blue teal. A blue-purple periwinkle hoodie with the hood down and a front pocket. Pink leggings with a simple pattern of big darker-pink leopard-style spots as solid shapes. Chunky modern running sneakers: white uppers with a lavender toe and heel and a thick, cushioned, rounded white sole, plain sides with NO logo, NO swoosh, NO stripes and NO checkerboard.] | [model-input\glow\front-toon.png, look-source\gillian.webp] | [gillian\front-toon.png]
[BACK view of Gillian, matching the reference exactly: the back of her long straight blonde hair, the periwinkle hoodie with the hood lying flat on her back, the pink leggings with the darker-pink spots, the white-and-lavender chunky sneakers.] | [model-input\gillian\front-toon.png] | [gillian\back-toon.png]
[FRONT view of Vivienne, a sweet, smiley girl: warm light-peach skin, long straight light-brown hair past her shoulders with a middle part, big hazel eyes, round clear-pink glasses. A plain white tank top under a light baby-pink zip-up jacket, zipped about halfway up (the white tank showing at the top, the zipper as one plain line). Plain black leggings. Brown pull-on sheepskin-style winter boots to mid-calf with a short fuzzy cream cuff at the top, plain with NO label or logo.] | [model-input\glow\front-toon.png, look-source\vivienne.webp] | [vivienne\front-toon.png]
[BACK view of Vivienne, matching the reference exactly: the back of her long straight light-brown hair, the baby-pink jacket, black leggings, the brown boots with cream cuffs.] | [model-input\vivienne\front-toon.png] | [vivienne\back-toon.png]
[FRONT view of Charlotte, a bright, beaming girl with a big happy smile and cheerful eyes (positive, friendly, never grumpy): warm light-peach skin, long wavy light-brown hair past her shoulders, big hazel eyes, round clear-pink glasses. A sporty green crew-neck sweatshirt with plain white cuffs and waistband. A plain black skirt to just above the knee. Shiny gold canvas high-top sneakers with white rubber soles, a white toe cap and white laces, plain with NO star patch and NO logo.] | [model-input\glow\front-toon.png, look-source\charlotte.webp] | [charlotte\front-toon.png]
[BACK view of Charlotte, matching the reference exactly: the back of her long wavy light-brown hair, the green sweatshirt, the black skirt, the gold high-tops with white soles.] | [model-input\charlotte\front-toon.png] | [charlotte\back-toon.png]
```

Send Claude the 8 pictures to check (look-alikes, logos, arms clear of the
body, Gillian's eye colors) before making the models with Stable Fast 3D.

## Still to decide (Brent)

- **Skills:** each girl needs a skill no current kid has. Design them
  together after the pictures pass. Avoid overlaps:
  - Glow already reveals secrets.
  - Muscle already shoves heavy things.
  - The Freeze boost already stops the host.
- **Free or paid:** whether each girl is free or unlocked with points.
