# Elfy portrait workflow

Use the built-in image generator, one image per row in table order. Full prompt record: [JSON workflow](tools/workflows/elfy-portrait.json). Reference root: `art`; output root: `art`, both relative to this project. Attach every reference in listed order. Inspect inputs and results. Create missing folders and preserve existing artwork unless replacement is requested.

For every row, submit the complete Picture Standard verbatim, followed by two newlines and that row's Picture verbatim. Resolve reference paths under `art` without sorting or deduplicating. The first reference supplies Elfy's identity; the second supplies the portrait layout only. Generate an opaque square portrait. Copy the selected PNG to `art/[file name]`, creating its parent folder first. To add pictures, append rows with `picture`, `references`, and `file_name` to the JSON table and derive each `prompt` the same way.

## Picture Standard

A square character portrait for a kids' co-op escape game for ages 8 and up. The FIRST attached picture is the character's approved full-body look: keep their face, skin tone, eye color, hair and clothes exactly the same, only in a richer, polished 3D animated-movie style with soft light, big clear eyes and a warm smile. The SECOND attached picture is another character's finished portrait: copy its layout exactly - chest up, turned slightly toward the camera, the same size of head, a soft glowing circle behind the character on a dark background, and a round badge with a gold rim in the bottom-right corner - but it is a different character, so take nothing else from it (no peppermints, no bows, no sweater, no holly). No logos, brand marks, printed words, letters or numbers anywhere. Not a copy of any existing cartoon, film or game character. Bright, friendly and right for young kids. One character only, no text.

## Ordered pictures

| Order | Picture | References | File name |
|---|---|---|---|
| 1 | PORTRAIT of Elfy, a cheerful, mischievous elf boy: warm light-peach skin, bright green eyes, short tousled golden-blonde hair under a green pointed elf hat flopping to one side with a small gold bell on its tip, small pointed elf ears, a big cheeky grin, a green elf tunic with a jagged hem, a small red collar and a gold belt. One hand holding up a small wrapped present with a red bow beside his cheek, winking. Behind him a soft glowing circle in green and gold with a few small snowflakes and tiny gold bells inside it, on a deep red background. Badge: a green circle with a gold rim and a small gold wind-up key inside. | `model-input\elfy\front-toon.png`, `roblox-store\portraits\Holly.png` | `roblox-store\portraits\Elfy.png` |

## Verification

Check likeness, chest-up framing, the wink, raised present with a red bow, green/gold glowing circle, snowflakes and bells, deep red background, bottom-right green/gold wind-up-key badge, and no writing or logos. Record source, saved destination, PNG dimensions and SHA-256 in the JSON after saving.
