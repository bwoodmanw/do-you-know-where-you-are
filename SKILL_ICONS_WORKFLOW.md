# Skill pictures for the five new characters (4 Nov)

The original 8 characters' skill buttons show a picture (`art/ui-icons/skill-*.png`).
Nutmeg, Cloud, Holly, Clone and Harmony have none yet, so their buttons show
their portrait for now. Once these five are uploaded, their IDs go in
`Config.UI_ICONS` as `["skill-nutmeg"]` and so on, and the button switches over
by itself.

## Paste into ChatGPT

```
create new workflow to create images based on the [Picture Standard] and [Picture]. For each picture, save to "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\[folder]\[file name]". For example, C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\ui-icons\skill-nutmeg.png.
The [Picture Standard] will be included with every picture prompt. The [Picture] prompt is added to [Picture Standard] and changes per prompt. The [file name] will be defined per picture.
[Picture Standard] = "A single button icon for a kids' co-op escape game for ages 8 and up, in exactly the same style as the game's other skill icons (a crossed wrench and screwdriver, a pair of headphones): one bold, chunky object in a glossy cartoon style with soft bright highlights, a thick dark-purple outline around the whole shape, rich purple and warm orange-gold accents, centered and filling most of the square. Fully transparent background - a PNG with no backdrop, no circle, no frame, no shadow box. It must still read clearly when shrunk to 60 pixels, so keep it simple with big shapes. No logos, brand marks, words, letters or numbers. Not taken from any existing game, film or cartoon. Square, 1024 x 1024."
[folder]="ui-icons"
Table for each [Picture] and [file name] combination is below:
[Picture] | [file name]
[Sleigh Dash: a round golden jingle bell with a small red ribbon bow on top, tilted forward as if rushing ahead, with three orange speed streaks swooshing out behind it] | [skill-nutmeg.png]
[Fog: a big puffy cloud, white with pale-blue shading, with soft curls of mist spilling out from underneath it] | [skill-cloud.png]
[Peppermints: three red-and-white swirl peppermint candies, all the same size, lying in a slanted row from bottom-left to top-right and overlapping a little, the middle one in a clear cellophane wrapper twisted at both ends - not one big circle with two smaller circles on top] | [skill-holly.png]
[Copycat: two matching simple person shapes standing side by side, the left one teal and the right one orange, with a curved two-way arrow looping over their heads between them] | [skill-clone.png]
[Lullaby: two joined musical eighth notes in glossy purple, with a small golden crescent moon and a tiny twinkling star beside them, soft and sleepy] | [skill-harmony.png]
```

## Reusable generation workflow

Structured prompt table: [new-character-skill-icons.json](tools/workflows/new-character-skill-icons.json).
Resolve `output_root` relative to this project; save each asset under
`output_root/folder/file_name`.

1. Process the five assets in table order. For each, concatenate
   `picture_standard` verbatim, two newlines, and `picture` verbatim.
2. Use one built-in image generation call per asset with
   `transparent_background: true`. No reference images are specified or
   attached. The existing Tinker and Echo skill icons can be inspected
   separately when assessing the requested style match.
3. Inspect each result: glossy chunky shapes, thick dark-purple outline,
   required object counts and colors, no text, logos, backdrop or frame.
   For Copycat, teal is on the viewer's left and orange on the right, with
   a curved two-way arrow over both heads.
4. Create `art/ui-icons` if absent. Save each selected PNG to its listed
   filename. Preserve existing assets on reruns unless replacement is
   requested; otherwise save a versioned sibling and record its actual path.
5. Ensure each delivery is exactly 1024 x 1024. If the generator returns a
   larger square image, resample to the requested dimensions while preserving
   its alpha channel. Keep the unmodified generated source for provenance.
6. Verify PNG decoding, dimensions and actual transparency. Inspect the
   icons at 60 pixels on light and dark backgrounds for readability.
7. Record full prompts, generated sources, destinations, actual dimensions,
   transparency checks and any resampling in
   `art/ui-icons/new-character-skill-icons-generation-report.json`.

To add icons, append `picture` and `file_name` entries to `assets`; include
the shared Picture Standard with every generated icon.

## Execution record (4 Nov 2026)

All five icons were generated with the built-in image tool, using the full
Picture Standard and each Picture prompt without prompt changes or attached
references. The selected generated sources were 1254 x 1254 and were
resampled to the requested 1024 x 1024 with alpha preserved.

Saved in `art/ui-icons/`:

- `skill-nutmeg.png`: golden jingle bell, red bow, three orange speed streaks.
- `skill-cloud.png`: white/pale-blue cloud with curling mist below.
- `skill-holly.png`: three equal-size peppermint candies in a diagonal row, with the middle candy wrapped.
- `skill-clone.png`: matching teal/orange person shapes and two-way arrow.
- `skill-harmony.png`: joined purple eighth notes, gold crescent and star.

All five decode as RGBA PNGs with transparent background areas. Each was
visually checked at full size and at 60 pixels against light and dark
backgrounds. No Roblox upload or configuration change was performed.

Holly's icon was regenerated with the revised prompt above: three equal-size
candies overlapping slightly in a row from bottom-left to top-right, with
only the middle candy in clear cellophane twisted at both ends. The updated
transparent 1024 x 1024 PNG replaces `skill-holly.png`. The generation report
records the revised prompt and source and retains the superseded record.

## Then

1. Send the five pictures back to be checked (style match, no look-alikes or logos).
2. Upload each one to Roblox as an image (Creator Hub > Creations > Development Items > Images, or Studio's Asset Manager > Bulk Import).
3. Send the five IDs. They go in `Config.UI_ICONS`.

## Checked (4 Nov)

Nutmeg, Cloud, Clone and Harmony are good to upload. **Holly's needs redoing:**
one big round candy with two smaller round ones at its top left and top right
reads as a famous cartoon mouse's ears and head. The new row (replaces the
Holly row):

[Peppermints: three red-and-white swirl peppermint candies, all the same size, lying in a slanted row from bottom-left to top-right and overlapping a little, the middle one in a clear cellophane wrapper twisted at both ends - not one big circle with two smaller circles on top] | [skill-holly.png]
