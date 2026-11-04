# Christmas giftbox and thermos image workflow

Use `tools/workflows/christmas-giftbox-thermos-images.json` as the reusable
prompt table. It preserves the supplied Picture Standard, both Picture prompts,
reference order, and output filenames. This is a separate workflow from the
existing seven-picture Christmas store workflow.

## Run

Ask Codex: "Run CHRISTMAS_GIFTBOX_THERMOS_IMAGE_WORKFLOW.md."

1. Resolve `reference_root` and `output_root` relative to the project root.
   Check every reference exists and inspect each distinct reference before use.
   Create `art/roblox-store` if it does not exist.
2. Process `assets` in table order, with one built-in image generation call per
   picture. Include `picture_standard` verbatim, followed by the row's `picture`
   verbatim in every prompt. Do not substitute an earlier workflow's standard.
3. Attach every row's `references` in exactly the listed order, resolving each
   path under `reference_root`. Do not sort, omit, or deduplicate references.
   Both current rows attach only `art/roblox-store/cane-icon.png` as Image 1.
   It controls layout, ring, glow, background, and rendering style. Do not attach
   the preceding generated output or carry its subject into the next picture.
4. Generate opaque square icons. Match Image 1's ring placement and scale,
   icy blue and white glow with red accents, deep purple background, sparse
   sparkles and swooshes, and glossy rounded 3D style. Replace the candy cane
   with only the subject and accessories specified by the current Picture.
5. Inspect each result against its Picture prompt and the Picture Standard:
   - Giftbox: red present, wide gold ribbon in both directions, shiny gold bow,
     lid barely open, and a pair of curious cartoon eyes visible in the dark
     gap. Keep the hidden child playful and cheeky; do not add a visible body.
   - Thermos: red flask with a simple decorative white snowflake, detached
     cup-lid filled with hot cocoa, whipped cream, little marshmallows, two
     additional small mugs, and curling steam. The snowflake is a decorative
     shape, with no branding or emblem.
   - Both: large readable subject inside the ring, no extra scene elements,
     text, letters, numbers, logos, brand marks, emblems, or famous characters.
   Correct material defects and inspect readability at small size.
6. Copy each selected generated PNG to `output_root/file_name`:
   - `C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\roblox-store\boost-giftbox-512.png`
   - `C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\roblox-store\boost-thermos-512.png`
   Preserve existing assets on reruns unless replacement is requested; otherwise
   use a versioned sibling filename and record the actual saved path.
7. Verify each saved image decodes as PNG and is square. Record the full
   submitted prompt, ordered reference paths, generated source path, saved
   destination, actual dimensions, and visual review result in
   `art/roblox-store/christmas-giftbox-thermos-generation-report.json`.

## Output order

1. `boost-giftbox-512.png`
2. `boost-thermos-512.png`

The `-512` filenames are preserved from the request. Record actual generated
dimensions; resizing for upload is a separate production step. To add pictures,
append rows with `picture`, `references`, and `file_name` to the JSON table.
Include the shared Picture Standard in every generation prompt.
