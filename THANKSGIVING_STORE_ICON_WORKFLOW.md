# Thanksgiving store icon workflow

Use `tools/workflows/thanksgiving-store-icon.json` as the reusable prompt table.
It preserves the supplied Picture Standard, Picture, reference order, and filename.
This icon is separate from the Thanksgiving event illustration.

## Run

1. Resolve `reference_root` and `output_root` relative to the project root.
   Check every reference exists and inspect it. Create the output folder if needed.
2. Process `assets` in table order, using one built-in image generation call
   per picture. Include `picture_standard` verbatim, followed by the row's
   `picture` verbatim in every prompt.
3. Attach every row's `references` in the listed order. Do not sort or omit them.
   Here, image 1 controls the Gobbler's likeness; image 2 controls the baby
   turkey's likeness; image 3 controls rendering style only. Do not copy the
   Halloween characters or props into this Thanksgiving scene.
4. Generate an opaque square store icon. Inspect character likeness, the large
   faces, funny grumpy expression, single golden feather, simple composition,
   orange sunset, purple edges, barn roof, and safe margins for rounded corners.
   Check readability at small size and the Picture Standard's restrictions.
   Correct material defects before saving.
5. Copy the selected generated PNG to `output_root/file_name`:
   `art/roblox-store/icon-thanksgiving-store.png`. Preserve existing assets on
   reruns unless replacement is requested; otherwise use a versioned sibling.
6. Verify the saved file decodes as PNG and is square. Record the full submitted
   prompt, ordered references, source, destination, and actual dimensions in
   `art/roblox-store/thanksgiving-store-icon-generation-report.json`.

For additional rows, append objects with `picture`, `references`, and `file_name`
to `assets`. The shared Picture Standard must accompany every row's prompt.
