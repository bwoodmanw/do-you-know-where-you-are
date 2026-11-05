# Elfy skill icon image workflow

Reusable prompt table: [elfy-skill-icon.json](tools/workflows/elfy-skill-icon.json).
Resolve `output_root` relative to this project and save each picture under
`output_root/folder/file_name`.

## Picture Standard

A single button icon for a kids' co-op escape game for ages 8 and up, in exactly the same style as the game's other skill icons (a crossed wrench and screwdriver, a pair of headphones): one bold, chunky object in a glossy cartoon style with soft bright highlights, a thick dark-purple outline around the whole shape, rich purple and warm orange-gold accents, centered and filling most of the square. Fully transparent background - a PNG with no backdrop, no circle, no frame, no shadow box. It must still read clearly when shrunk to 60 pixels, so keep it simple with big shapes. No logos, brand marks, words, letters or numbers. Not taken from any existing game, film or cartoon. Square, 1024 x 1024.

## Pictures

| Picture | File name |
|---|---|
| Wind-up Toy: a small round wind-up toy drummer soldier in red and gold with a big gold wind-up key in its back, marching to the right, with two small curved motion lines and a tiny gold bell beside it | skill-elfy.png |

## Run

1. Read the JSON table. For each asset in order, concatenate `picture_standard`
   verbatim, two newlines, and the row's `picture` verbatim. Include the full
   Picture Standard with every picture, including future rows.
2. Use one built-in image generation call per row with
   `transparent_background: true`. No reference attachments are required.
   Existing `art/ui-icons/skill-tinker.png` and `skill-echo.png` can be
   inspected to assess the style match.
3. Inspect the output for the round red-and-gold toy drummer soldier, a large
   gold wind-up key on its back, a rightward marching pose, exactly two small
   curved motion lines, and a tiny gold bell. Check the glossy chunky shapes,
   thick dark-purple outline, and absence of text, logos, backdrop or frame.
4. Create the destination directory if needed and copy the selected PNG to
   `C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\ui-icons\skill-elfy.png`.
   On reruns preserve existing artwork unless replacement is requested;
   otherwise use a versioned sibling and record the actual destination.
5. Verify that the saved PNG decodes, is exactly 1024 x 1024, and has actual
   transparent background pixels. If the generator returns a larger square,
   resample to 1024 x 1024 while preserving alpha and keep the generated source.
   Inspect at 60 pixels against both light and dark backgrounds.
6. Record the full submitted prompt, generated source, saved destination,
   dimensions, transparency verification and any resizing in
   `art/ui-icons/elfy-skill-icon-generation-report.json`.

To add pictures, append `picture` and `file_name` rows to the JSON `assets`
array. Change `folder` for a different destination under `art`.

## Execution record (5 Nov 2026)

Generated `art/ui-icons/skill-elfy.png` with the built-in image tool using
the Picture Standard plus Picture verbatim. The 1254 x 1254 generated source
was resampled to 1024 x 1024 with alpha preserved. The saved PNG passed
dimension and transparency checks and was visually checked at 60 pixels
against light and dark backgrounds. The full submitted prompt and source
are recorded in `art/ui-icons/elfy-skill-icon-generation-report.json`.
