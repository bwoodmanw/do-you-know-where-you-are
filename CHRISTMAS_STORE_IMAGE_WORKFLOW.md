# Christmas store image workflow

Use `tools/workflows/christmas-store-images.json` as the reusable prompt table.
It preserves the supplied Picture Standard, seven Picture prompts, reference
order (including duplicates), and output filenames. The original request is in
`CHRISTMAS_PICTURE_WORKFLOW.md`.

## Run

1. Resolve `reference_root` and `output_root` relative to the project root.
   Check every reference exists and inspect each distinct reference before use.
   Create the output folder if needed.
2. Process `assets` in table order, using one built-in image generation call
   per picture. Include `picture_standard` verbatim, followed by the row's
   `picture` verbatim in every prompt.
3. Attach every row's `references` in the listed order. Do not sort, omit, or
   deduplicate them: the gingerbread row intentionally attaches the candy corn
   image twice. Image 1 controls layout, ring, glow, and rendering style; change
   the ring palette to icy blue and white with a touch of red. Image 2, when
   present, supplies the regular boost concept only.
4. Generate opaque square icons. Preserve the first reference's ring placement
   and scale, deep purple background, sparse sparkles and swooshes, polished
   rounded 3D style, and large readable subject. Include only the subject and
   accessories specified by that row. Treat the map's red X as a route marker
   symbol. Leave the stopwatch face free of letters and numerals, and the
   snowman's mitten print free of logos or emblems.
5. Inspect each image for the specified details and Picture Standard restrictions.
   Correct material defects before saving. Check readability at small size.
6. Copy the selected generated PNG to `output_root/file_name`, namely
   `C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\roblox-store\[file name]`.
   On reruns preserve existing assets unless replacement is requested; otherwise
   use a versioned sibling filename.
7. Verify every saved image decodes as PNG and is square. Record the full
   submitted prompt, ordered references (including duplicates), generated source,
   saved destination, and actual dimensions in
   `art/roblox-store/christmas-generation-report.json`.

## Output order

1. `cane-icon.png`
2. `boost-gingerbread-512.png`
3. `boost-snowman-512.png`
4. `boost-elfmap-512.png`
5. `boost-cocoa-512.png`
6. `boost-sled-512.png`
7. `boost-snowball-512.png`

The `-512` filenames are preserved from the request. Record actual dimensions;
resizing for upload is a separate production step. To add pictures, append rows
with `picture`, `references`, and `file_name` to the JSON table. The shared
Picture Standard must accompany every prompt.
