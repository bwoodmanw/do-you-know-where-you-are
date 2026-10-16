# Thanksgiving store image workflow

The complete, reusable specifications are in
`tools/workflows/thanksgiving-store-images.json`. They preserve the supplied
Picture Standard, nine Picture prompts, reference order, and output filenames.
The original prompt table is also in `THANKSGIVING_EVENT_PICTURE_WORKFLOW.md`.

## Run

1. Resolve `reference_root` and `output_root` relative to the project root.
   Check every reference exists before generation. Create output directories.
2. Process `assets` in table order, making one image per entry with the built-in
   image generation tool. Inspect each reference before using it.
3. Attach every entry in `references` in its existing order. Do not sort, omit,
   duplicate, or reorder references, including references supplied for concept only.
4. For every call, include `picture_standard` verbatim followed by that entry's
   `picture` verbatim. Add short reference-role clarifications where needed:
   the explicitly designated candy icon controls boost framing and ring style;
   regular boost references provide the concept; turkey references control likeness.
   For the event image, the fifth reference controls rendering style only.
5. Request an opaque square image for every asset except the Harvest Barn,
   which uses a wide 16:9 composition. Preserve the event image's dark, empty
   left third. Treat the corn map's requested red X as a route marker symbol;
   leave the stopwatch face free of numerals and lettering.
6. Inspect each generated image for composition, identity, style, and the
   Picture Standard's restrictions. Correct any material defects.
7. Copy each selected generated PNG into `output_root/file_name`. Preserve
   existing assets on reruns unless replacement was explicitly requested;
   use a versioned sibling filename when necessary.
8. Verify all nine saved files decode as PNG, square assets are square, and
   the barn is approximately 16:9, matching the reference's aspect ratio.
   Record actual dimensions and saved paths in
   `art/roblox-store/thanksgiving-generation-report.json`.

## Output order

1. `icon-thanksgiving.png`
2. `feather-icon.png`
3. `maps/building-harvestbarn.png`
4. `boost-pie-512.png`
5. `boost-pietin-512.png`
6. `boost-cornmap-512.png`
7. `boost-cider-512.png`
8. `boost-turkeytrot-512.png`
9. `boost-cranpop-512.png`

The `-512` names are preserved from the request. Record the actual generated
dimensions; do not infer dimensions from a filename. Any resizing for upload
is a separate production step.

## Completed run: 16 October 2026

All nine images were generated with the built-in image generation tool, using
the listed references in order and the Picture Standard in every prompt.
Eight square PNGs are 1254 x 1254; the barn is 1672 x 941, matching the aquarium
reference. All files decoded successfully and were visually inspected.
The generation report includes the complete submitted prompts and source paths.
