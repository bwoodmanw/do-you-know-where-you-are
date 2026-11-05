# Elfy's friendlier face and the Toy Elf's back (5 Nov 2026)

Checked 5 Nov:
- **Elfy front:** right outfit, hair, eyes and ears, but his lowered eyebrows
  and smirk look sly (Brent: "a bit evil"). Redo the FRONT only, with a warm,
  welcoming smile. The old picture is kept as
  `art/model-input/elfy/front-toon-v1-frowny.png`.
- **Elfy back:** good, keep it. The bell is on the correct side from behind.
- **Toy Elf front:** good, and clearly a different character from Elfy.
- **Toy Elf back:** missing. Make it from the saved front.

Run row 1, then row 2. Paste into ChatGPT:

```
create new workflow to create images based on the [Picture Standard], [Reference] and [Picture]. For each picture, attach the [Reference] picture listed, then save to "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input\[file name]". For example, C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input\elfy\front-toon.png. The [Reference] is in "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input\[Reference]".
The [Picture Standard] will be included with every picture prompt. The [Picture] prompt is added to [Picture Standard] and changes per prompt. The [Reference] and [file name] are defined per picture. Make the rows in order.
[Picture Standard] = "This is for a kids' co-op escape game for ages 8 and up: friendly and fun, never scary. The attached picture is this SAME character: keep the exact same art style, proportions, pose, outfit and every color, and change ONLY what the prompt asks. Clean, simple 3D cartoon toy style: every area one smooth, flat, solid color, with no texture at all - no fabric grain, no stitching, no folds or wrinkles painted on, no shading or shadows painted on, nothing see-through and nothing glowing. Small details as simple solid shapes, close to the body. No logos, brand marks, printed words or graphics. Not like any famous character from a film, cartoon or game. Full body standing in an A-pose: arms straight and angled clearly down and away from the body with a clear gap between each arm and the body all the way down, hands open, legs slightly apart, feet flat. Centered and filling the whole height, nothing cropped. Plain flat light-gray background, even soft light, no floor shadow. One character only, no text."
Table for each [Picture], [Reference] and [file name] combination is below:
[Picture] | [Reference] | [file name]
[FRONT view of Elfy, exactly the same boy elf in the same outfit and pose, with ONLY his face changed to look warm, kind and welcoming: soft relaxed eyebrows raised a little in a happy, friendly arch (NOT lowered, NOT angled down toward the nose, no frown), big round bright green eyes looking straight ahead, a wide open happy smile showing a few top teeth, round rosy cheeks - the look of a cheerful kid saying "Hi, come play!", never sly, sneaky or smirking. Same golden-blonde hair, pointed ears, green hat with the gold bell flopping to the same side, green tunic, gold belt, red collar, red-and-white striped leggings and curled green shoes] | [elfy\front-toon-v1-frowny.png] | [elfy\front-toon.png]
[BACK view of the Toy Elf, matching the reference exactly, seen from directly behind in the same pose: the back of its round head with short brown hair under the red hat, the red hat with its white band, white bobble and gold bell flopping to the same side, the backs of its pointed ears, the big gold wind-up key sticking straight out of the middle of its back (both round loops of the key showing), the round red-and-green tunic with its green jagged collar and brown belt, green sleeves, round white hands, stubby green legs and round black boots. No face showing] | [toy-elf\front-toon.png] | [toy-elf\back-toon.png]
```

When both are saved, tell me. I'll check them, then make both 3D models.
After that, run Elfy's portrait and skill-button workflows
(`CLAUS_MANOR_PICTURE_WORKFLOW.md`, workflows 4 and 5). They use his new
front.
