# New characters revision: Juliette, Vivienne and Charlotte (21 Nov 2026)

Brent's changes after the first pictures from
[NEW_CHARACTER_PICTURE_WORKFLOW_3.md](NEW_CHARACTER_PICTURE_WORKFLOW_3.md).
Gillian is approved as she is.

| Who | Changes |
|---|---|
| Juliette | Green dress instead of the black shirt and leggings; no turtle belly plate; blue eyes. The hood and the shell on her back stay. |
| Vivienne | Based on her first picture: hair more blonde, black flare pants, lower brown booties, hazel eyes |
| Charlotte | Hair slightly more blonde, blue eyes |

The first pictures are kept as `front-toon-v1.png` and `back-toon-v1.png` in
each folder. Each front revision attaches its v1 front, and each back
attaches the new front made just before it. The new pictures replace
`front-toon.png` and `back-toon.png`.

## Run the revision

1. Follow the rows in order. Resolve references from `art/` and output
   filenames from `art/model-input/`.
2. Attach the row's reference in ImageGen. Combine the full Picture
   Standard and the row's Picture prompt. Generate one character at
   full height in the specified view.
3. Check the requested changes against the reference, including pose,
   framing, face, and clothing details. Save the PNG to the output path,
   replacing the existing file. Keep the `-v1.png` source copies.
4. Attach the newly saved front PNG as the sole reference for that
   character's back view. Check that both views agree before moving to
   the next character.

## Picture Standard and ordered prompts

```
create new workflow to create images based on the [Picture Standard], [Reference] and [Picture]. For each picture, attach every [Reference] picture listed, in that order, then save to "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input\[file name]", replacing the file if it exists. For example, C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input\juliette\front-toon.png.
The [Picture Standard] will be included with every picture prompt. The [Picture] prompt is added to [Picture Standard] and changes per prompt. The [Reference] and [file name] are defined per picture. Make the pictures in the order of the table: each back view uses the front view made just before it as its reference.
[Picture Standard] = "This is a revision of a character for a kids' co-op escape game for ages 8 and up. One picture is attached. For a FRONT view it is this character's current front picture: redraw the SAME character in exactly the same style, pose, proportions, framing, face shape, smile and size, and change ONLY what this prompt lists - everything not listed stays exactly as it is. For a BACK view it is the new front picture: the same character seen from directly behind, same pose, every color the same as the front. Clean, simple 3D cartoon toy style: every area one smooth, flat, solid color, with no texture at all - no fabric grain, no knit, no stitching, no folds or wrinkles painted on, no shading or shadows painted on, nothing see-through and nothing glowing. Warm skin tone (never pale or white). No logos, brand marks, printed words or graphics. Full body standing in an A-pose: arms straight and angled clearly down and away from the body with a clear gap between each arm and the body all the way down, hands open and empty, legs slightly apart, feet flat. Centered and filling the whole height, nothing cropped. Plain flat light-gray background, even soft light, no floor shadow. One character only, no text."
Table for each [Picture], [Reference] and [file name] combination is below:
[Picture] | [Reference] | [file name]
[FRONT view of Juliette. Changes: 1) she now wears a solid green short-sleeved dress to just above the knee, instead of the black shirt and black leggings - her arms and legs below the dress show her warm skin; 2) REMOVE the yellow turtle belly plate completely - nothing on her front except the green dress and the two green shoulder straps of the shell; 3) her eyes are bright blue. Keep the green turtle hood with the two cartoon eyes on top, her long wavy strawberry-blonde hair, the edge of the green shell at her sides, and the black flat shoes.] | [model-input\juliette\front-toon-v1.png] | [juliette\front-toon.png]
[BACK view of Juliette, matching the reference exactly: the green hood with the two cartoon turtle eyes on top, her strawberry-blonde hair below the hood, the big rounded green turtle shell on her back with large darker-green hexagon shapes and a lighter-green rim, the green shoulder straps, the green dress showing below the shell, bare legs, black flat shoes.] | [model-input\juliette\front-toon.png] | [juliette\back-toon.png]
[FRONT view of Vivienne. Changes: 1) her hair is more blonde - a light golden honey-blonde instead of brown, same long straight style with the middle part; 2) her eyes are hazel - a warm light golden-brown with a soft hint of green; 3) instead of leggings she wears black flare pants - fitted to the knee, then widening into a flare at the bottom that falls over the top of her shoes; 4) instead of the tall boots she wears low brown ankle booties, sheepskin-style, just covering the ankle, with a thin fuzzy cream edge at the top, plain with NO label or logo. Keep the round clear-pink glasses, the gentle smile, the baby-pink zip-up jacket zipped halfway and the white tank top.] | [model-input\vivienne\front-toon-v1.png] | [vivienne\front-toon.png]
[BACK view of Vivienne, matching the reference exactly: the back of her long straight golden honey-blonde hair, the baby-pink jacket, the black flare pants falling over the low brown ankle booties.] | [model-input\vivienne\front-toon.png] | [vivienne\back-toon.png]
[FRONT view of Charlotte. Changes: 1) her hair is slightly more blonde - a light honey-brown with golden-blonde tones, a little lighter than now, same long wavy style; 2) her eyes are bright blue. Keep everything else exactly the same: the big happy smile, the round clear-pink glasses, the green sweatshirt with white cuffs and waistband, the black skirt and the gold high-top sneakers.] | [model-input\charlotte\front-toon-v1.png] | [charlotte\front-toon.png]
[BACK view of Charlotte, matching the reference exactly: the back of her long wavy honey-blonde hair, the green sweatshirt with white cuffs and waistband, the black skirt, the gold high-tops.] | [model-input\charlotte\front-toon.png] | [charlotte\back-toon.png]
```

Send Claude the 6 new pictures to check before making the models.
