# Nutmeg's portrait (4 Nov 2026)

One square portrait for Nutmeg, the Christmas reindeer, laid out like the
other eight (`art/roblox-store/portraits/`): chest up, a glowing circle behind
her, a round skill badge in the bottom-right corner. It is used for:

- the Lobby's character buttons and the Shop (`Config.PORTRAITS.nutmeg`,
  uploaded in the Lobby place),
- the game's character card (`Config.PORTRAITS_GAME.nutmeg`, uploaded in the
  Party House place),
- her 399 Robux Game Pass picture.

```
create new workflow to create images based on the [Picture Standard], [Reference] and [Picture]. For each picture, attach every [Reference] picture listed, in that order, then save to "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\[file name]". For example, C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\roblox-store\portraits\Nutmeg.png. Create the folder if it does not exist.
The [Picture Standard] will be included with every picture prompt. The [Picture] prompt is added to [Picture Standard] and changes per prompt. The [Reference] and [file name] are defined per picture.
[Picture Standard] = "The character is Nutmeg, a cheerful, kind girl of about 10 dressed as a reindeer, exactly as in the FIRST attached picture (her approved full-body look): warm brown skin, big brown eyes, two short dark-brown braids coming out from under the hood at the front, a light-brown reindeer hoodie with the hood UP - two short, chunky, rounded cream antlers on top of the hood and two small round brown ears on its sides - a cream patch on the front of the hoodie, a green scarf with a small round brass bell at the front, red mittens. A normal kid's nose - NO red nose. Rich, polished 3D animated-movie style, soft light, big clear eyes, a warm smile. No logos, brand marks, printed words or text anywhere. Not a copy of any existing cartoon, film or game character (not Santa's reindeer, no glowing nose). Bright, friendly and right for young kids."
Table for each [Picture], [Reference] and [file name] combination is below:
[Picture] | [Reference] | [file name]
[PORTRAIT, square: Nutmeg from the chest up, turned slightly toward the camera, smiling, her hood up with the antlers and ears showing, the green scarf and its brass bell at her chest, one red mitten raised in a small wave at the bottom edge. Behind her a soft glowing circle in warm red and gold with a few gentle snowflakes inside it, on a deep plum-purple background. In the bottom-right corner a round badge: a dark-green circle with a gold rim and a small shiny brass sleigh bell inside. Lay it out exactly like the SECOND attached picture (another character's portrait) - the same framing, size of the head, glowing circle and corner badge - but with Nutmeg.] | [model-input\nutmeg\front-toon.png, roblox-store\portraits\Bramble.png] | [roblox-store\portraits\Nutmeg.png]
```

## Reusable generation workflow

The machine-readable prompt table is `tools/workflows/nutmeg-portrait.json`.
Resolve `reference_root` and `output_root` relative to the project root.

1. For each asset in table order, concatenate `picture_standard` verbatim,
   two newlines, and that asset's `picture` verbatim.
2. Check and inspect every reference, then attach all `references` in their
   listed order without sorting or deduplicating. The first image supplies
   Nutmeg's identity; the second supplies portrait framing, head scale, circle,
   rendering style, and badge placement.
3. Use one built-in image generation call per asset with the combined prompt
   and ordered reference paths. Generate an opaque square portrait.
4. Inspect the result for likeness, both braids, hood, rounded antlers and ears,
   brown eyes, normal nose, scarf bell, waving red mitten, red/gold circle,
   snowflakes, plum background, and the bottom-right green/gold bell badge.
5. Create the destination's parent folder if needed and copy the selected PNG
   to `output_root/file_name`. On reruns, preserve existing images unless
   replacement is requested; otherwise save a versioned sibling.
6. Verify PNG format and square dimensions. Save the full submitted prompt,
   ordered references, generated source, destination, and actual dimensions to
   `art/roblox-store/portraits/nutmeg-generation-report.json`.

To add pictures, append rows with `picture`, `references`, and `file_name` to
the JSON table. Include the shared Picture Standard with every prompt.

Send Claude the picture to check (likeness to her model, no red nose, nothing
that looks like a famous reindeer, the badge in the corner) before uploading.
