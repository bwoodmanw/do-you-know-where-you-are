# Christmas thumbnail and icon image workflow

Use `tools/workflows/christmas-thumbnail-images.json` as the reusable prompt
table. It preserves the supplied Picture Standard, both Picture prompts,
reference order, target dimensions, and output filenames. The original request
is in `CHRISTMAS_THUMBNAIL_WORKFLOW.md`.

## Run

Ask Codex: "Run CHRISTMAS_THUMBNAIL_IMAGE_WORKFLOW.md."

1. Resolve `reference_root` and `output_root` relative to the project root.
   Check every reference exists and inspect each distinct reference before use.
   Create `art/roblox-store` if needed.
2. Process `assets` in table order, with one built-in image generation call
   per picture. Include `picture_standard` verbatim, followed by the row's
   `picture` verbatim in every prompt.
3. Attach every row's references in exactly the listed order. Do not sort,
   omit, deduplicate, or append earlier generated pictures. Resolve reference
   paths under `art`. The LAST attached reference controls rendering style;
   the preceding references control character identity.

   | Output | Ordered attachments |
   | --- | --- |
   | `thumbnail-christmas.png` | 1. Crumbles; 2. Nutmeg portrait; 3. Holly portrait; 4. current thumbnail |
   | `icon-christmas.png` | 1. Crumbles; 2. Nutmeg portrait; 3. Thanksgiving store icon |

4. Generate opaque PNG artwork at the row's dimensions: a 1920 x 1080 wide
   thumbnail and a 1024 x 1024 square icon. Preserve all character identities,
   including Crumbles' round eyes, chef's hat, striped scarf, peppermint
   buttons, icing, and missing shoulder bite. Nutmeg keeps her brown braids,
   brown eyes, reindeer outfit, green scarf, bell, and red mittens. Holly keeps
   her blonde hair, green eyes, peppermint hair decorations, red bows, and
   red-and-green striped outfit with white collar and holly berries.
5. Inspect each result against its Picture and the Picture Standard:
   - Thumbnail: only the exact text `ESCAPE CREW`, in snowy candy-cane letters
     across the top; Nutmeg on the left and Holly on the right running toward
     the camera; Crumbles behind them, reaching, with falling crumbs; snowy
     candy-cane toy town at night with warm windows, lights, presents, and tree.
   - Icon: Crumbles fills most of the frame, holding a red-and-white candy
     cane; Nutmeg peeks in at bottom right, grinning and reaching for it;
     snowy toy town, lit tree, warm windows, snow, and deep blue night sky.
   - Both: friendly comic expressions, readable faces at small size, polished
     3D style matching the last reference, no logos, brand marks, famous
     character look-alikes, or additional text. Do not copy the style
     references' characters, seasonal objects, portrait badges, or rings.
   Correct material defects and inspect again before saving.
6. Copy the selected outputs from the built-in generation location into:
   - `C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\roblox-store\thumbnail-christmas.png`
   - `C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\roblox-store\icon-christmas.png`
   Preserve existing outputs on reruns unless replacement is requested;
   otherwise use versioned sibling filenames and record the actual paths.
7. Verify both saved files decode as PNG and match their requested dimensions.
   If generation returns another size with the same aspect ratio, export at
   the requested size with high-quality bicubic resampling and no cropping.
   A subpixel rounding difference in the source aspect ratio is acceptable;
   record the source dimensions and export operation. For materially different
   aspect ratios, regenerate rather than stretching or cropping the artwork.
   Record the full submitted prompts, ordered absolute reference paths,
   generated source paths, saved destinations, actual dimensions, and visual
   review in `art/roblox-store/christmas-thumbnail-generation-report.json`.
8. Report the saved paths and show both finished images. This workflow ends
   with local artwork; uploading or scheduling changes to the game page is a
   separate task.

To add pictures, append rows with `picture`, `references`, `file_name`, `width`,
and `height` to the JSON table. The Picture Standard accompanies every prompt.
