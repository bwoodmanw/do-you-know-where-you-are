# Clone and Harmony picture workflow

Generate one image per row in the listed order using the built-in image generation tool.
For each image, use the complete Picture Standard followed by a blank line and the
Picture prompt. If an asset has `prompt_clarification`, append it after the
Picture prompt. Attach every reference in array order. Resolve references relative
to `art` and output file names relative to `art/model-input` in this project.
Create each output parent folder if absent. Save the front PNG before generating
the corresponding back; attach that newly saved front as the back's reference.
Use an opaque background. Inspect the references and generated images.

Structured workflow: [clone-harmony-toon-pictures.json](tools/workflows/clone-harmony-toon-pictures.json).

Use the built-in image tool for each row, then copy its output into the project.
Preserve existing assets unless replacement is requested. For an unrequested
replacement use a versioned file and attach that actual new front for its back.
Check full-body A-poses, arm gaps, smooth solid-color surfaces, no text or logos,
and consistent colors, clothing and accessory placement across each pair.
Clone's jacket is teal on the left of the front image and on the right of the back image.

## Execution record

Execution record: all four outputs were generated with the built-in tool and
saved in table order, each back using only its newly saved front. Harmony's first
front had two bands and was discarded. Her selected front appended this exact
clarification to the standard and picture prompt:

> Count requirement: Exactly THREE distinct, clearly visible darker-purple wavy bands across the chest. Place all three above the hoodie pocket so none is hidden. Keep all three separate.

The other three selected images used only the standard and picture prompts.
All four saved PNGs are 1024 x 1536.

## Picture Standard

This is for a kids' co-op escape game for ages 8 and up: friendly, funny and a little spooky, never scary. For a FRONT view one picture is attached: another character from the same game - use it ONLY as a guide to the style, proportions and level of detail; design a completely NEW character from this prompt (different face, hair and clothes). For a BACK view one picture is attached: the same character seen from directly behind, same pose, every color the same as the front. Clean, simple 3D cartoon toy style: every area one smooth, flat, solid color, with no texture at all - no fabric grain, no knit, no stitching, no dirt, no folds or wrinkles painted on, no shading or shadows painted on, nothing see-through and nothing glowing. Simple rounded shapes, slightly chunky proportions, a kid about 10 years old, big clear eyes, warm skin tone (never pale or white). Small details as simple solid shapes, close to the body - nothing thin or long sticking out. No logos, brand marks, emblems, swooshes, stripes on shoes, printed words or graphics. Not like any famous character from a film, cartoon or game. Full body standing in an A-pose: arms straight and angled clearly down and away from the body with a clear gap between each arm and the body all the way down, hands open, legs slightly apart, feet flat. Centered and filling the whole height, nothing cropped. Plain flat light-gray background, even soft light, no floor shadow. One character only, no text.

## Pictures in generation order

| Picture | Reference (relative to art) | File name (relative to art/model-input) |
| --- | --- | --- |
| FRONT view of Clone, a clever, cheeky boy: warm dark-brown skin, short curly black hair, big brown eyes, a pair of round orange goggles pushed up on his forehead (resting on his hair, the strap hidden in his hair), a zip-up jacket split down the middle in two solid colors - the left half teal, the right half orange - with the zipper as one plain gray line, a plain white T-shirt showing at the neck, a chunky round gray wrist gadget on his left wrist with a plain dark screen (nothing on it, not glowing), dark gray jogger pants with NO pockets, plain white sneakers with teal soles. No armour, no helmet, no uniform. | `model-input\glow\front-toon.png` | `clone\front-toon.png` |
| BACK view of Clone, matching the reference exactly: the back of his short curly black hair with the goggles' orange lenses showing at the top of his head, the back of the jacket split in two colors (seen from behind, the teal half is on the RIGHT of the picture and the orange half on the LEFT), dark gray joggers, white sneakers with teal soles. | `model-input\clone\front-toon.png` | `clone\back-toon.png` |
| FRONT view of Harmony, a warm, musical girl: warm golden-tan skin, big dark-brown eyes, long straight black hair to her shoulder blades with straight bangs, two small solid yellow hair clips shaped like music notes on one side, a lavender hoodie with the hood down and three soft wavy bands of darker purple across the chest (plain solid shapes, like a sound wave), a small round gold music-box pendant on a short chain, a chunky black-and-white wristband shaped like a few piano keys on her right wrist, plain white leggings, lavender sneakers with white soles. NO headphones. | `model-input\glow\front-toon.png` | `harmony\front-toon.png` |
| BACK view of Harmony, matching the reference exactly: the back of her long straight black hair, the two yellow music-note clips peeking at the side, the lavender hoodie with the hood lying flat on her back, white leggings, lavender sneakers. | `model-input\harmony\front-toon.png` | `harmony\back-toon.png` |
