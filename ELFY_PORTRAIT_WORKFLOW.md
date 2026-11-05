# Elfy portrait workflow

Use the built-in image generator, one image per row in table order. Full prompt record: [JSON workflow](tools/workflows/elfy-portrait.json). Reference root: `art`; output root: `art`, both relative to this project. Attach every reference in listed order. Inspect inputs and results. Create missing folders, save each front before making its back, and preserve existing artwork unless replacement is requested.

## Picture Standard

A square character portrait for a kids' co-op escape game for ages 8 and up. The FIRST attached picture is the character's approved full-body look: keep their face, skin tone, eye color, hair and clothes exactly the same, only in a richer, polished 3D animated-movie style with soft light, big clear eyes and a warm smile. The SECOND attached picture is another character's finished portrait: copy its layout exactly - chest up, turned slightly toward the camera, the same size of head, a soft glowing circle behind the character on a dark background, and a round badge with a gold rim in the bottom-right corner - but it is a different character, so take nothing else from it (no peppermints, no bows, no sweater, no holly). No logos, brand marks, printed words, letters or numbers anywhere. Not a copy of any existing cartoon, film or game character. Bright, friendly and right for young kids. One character only, no text.

## Ordered pictures

| Order | Picture | References | File name |
|---|---|---|---|
| 1 | PORTRAIT of Elfy, a cheerful, mischievous elf boy: warm light-peach skin, bright green eyes, short tousled golden-blonde hair under a green pointed elf hat flopping to one side with a small gold bell on its tip, small pointed elf ears, a big cheeky grin, a green elf tunic with a jagged hem, a small red collar and a gold belt. One hand holding up a small wrapped present with a red bow beside his cheek, winking. Behind him a soft glowing circle in green and gold with a few small snowflakes and tiny gold bells inside it, on a deep red background. Badge: a green circle with a gold rim and a small gold wind-up key inside. | `model-input\elfy\front-toon.png`, `roblox-store\portraits\Holly.png` | `roblox-store\portraits\Elfy.png` |

## Verification

Check likeness, framing, all requested colors and accessories, no writing or logos, and consistent anatomical sides between views. Record source, saved destination, PNG dimensions and SHA-256 in the JSON after saving.
