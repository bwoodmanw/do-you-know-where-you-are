# Holly picture workflow (4 Nov 2026)

Front and back toon pictures for **Holly** (a girl, Christmas, free), in the
same style as Cloud, Nutmeg, Clone and Harmony. The front attaches Glow's
approved front picture only as a style guide; the back attaches the front
made just before it. Her long hair stays loose (no pigtails) so she looks
like nobody from a holiday film.

```
create new workflow to create images based on the [Picture Standard], [Reference] and [Picture]. For each picture, attach every [Reference] picture listed, in that order, then save to "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input\[file name]". For example, C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input\holly\front-toon.png. Create the folder if it does not exist.
The [Picture Standard] will be included with every picture prompt. The [Picture] prompt is added to [Picture Standard] and changes per prompt. The [Reference] and [file name] are defined per picture. Make the pictures in the order of the table: each back view uses the front view made just before it as its reference.
[Picture Standard] = "This is for a kids' co-op escape game for ages 8 and up: friendly, funny and a little spooky, never scary. For a FRONT view one picture is attached: another character from the same game - use it ONLY as a guide to the style, proportions and level of detail; design a completely NEW character from this prompt (different face, hair and clothes). For a BACK view one picture is attached: the same character seen from directly behind, same pose, every color the same as the front. Clean, simple 3D cartoon toy style: every area one smooth, flat, solid color, with no texture at all - no fabric grain, no knit, no stitching, no dirt, no folds or wrinkles painted on, no shading or shadows painted on, nothing see-through and nothing glowing. Simple rounded shapes, slightly chunky proportions, a kid about 10 years old, big clear eyes, warm skin tone (never pale or white). Small details as simple solid shapes, close to the body - nothing thin or long sticking out. No logos, brand marks, emblems, swooshes, stripes on shoes, printed words or graphics. Not like any famous character from a film, cartoon or game. Full body standing in an A-pose: arms straight and angled clearly down and away from the body with a clear gap between each arm and the body all the way down, hands open, legs slightly apart, feet flat. Centered and filling the whole height, nothing cropped. Plain flat light-gray background, even soft light, no floor shadow. One character only, no text."
Table for each [Picture], [Reference] and [file name] combination is below:
[Picture] | [Reference] | [file name]
[FRONT view of Holly, a cheerful, kind girl: warm light-peach skin, bright green eyes, long straight golden-blonde hair worn loose down past her shoulders (NOT in pigtails or bunches), two small round peppermint-candy bows in her hair - round red-and-white swirl candies with little red bows, one on each side - a red-and-green horizontally striped long-sleeve shirt (wide, even, solid stripes), a tiny sprig of two green holly leaves and three red berries on the collar, a white skirt to just above the knee, plain green leggings, red ankle boots. Soft and round everywhere, nothing sharp.] | [model-input\glow\front-toon.png] | [holly\front-toon.png]
[BACK view of Holly, matching the reference exactly: the back of her long loose golden-blonde hair with the two peppermint-candy bows on its sides, the back of the red-and-green striped shirt (the same stripes going round), the white skirt, green leggings, red ankle boots.] | [model-input\holly\front-toon.png] | [holly\back-toon.png]
```

Send Claude the 2 pictures to check (look-alikes, logos, arms clear of the
body) before making the model.

## Generated outputs (4 Nov 2026)

- Front: `art/model-input/holly/front-toon.png`, generated with Glow's front as its sole style reference.
- Back: `art/model-input/holly/back-toon.png`, generated afterward with the saved Holly front as its sole reference.
- Both outputs: 1024 x 1536 PNG, using the built-in image generator.
- Reusable ordered workflow and exact final prompts: `art/model-input/holly/workflow.json`. Each prompt includes the full Picture Standard and the corresponding Picture row, with explicit single-view instructions. The front also clarifies hair placement for arm clearance and simple solid-red boot soles; the back preserves those boot colors.
