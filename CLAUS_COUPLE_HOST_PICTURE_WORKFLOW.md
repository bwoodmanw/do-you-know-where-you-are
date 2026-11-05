# Mr Claus and Mrs Claus host picture workflow

Create the four images in table order with the built-in image generator. Use the full Picture Standard, then the Picture, then the row-specific clarification stored in [the JSON prompt record](tools/workflows/claus-couple-host-pictures.json).

Reference and output root: `C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input`. Attach every reference in its listed order. Inspect every reference before generation. Create missing output folders, inspect and save each FRONT before generating its BACK, and attach that newly saved front as the back reference. Preserve existing artwork unless replacement is explicitly requested.

## Picture Standard

This is a host (the friendly-spooky chaser) in a kids' co-op escape game for ages 8 and up: grumpy, sneaky and silly, never gory or truly frightening. For a FRONT view one picture is attached: ANOTHER host from the same game - use it ONLY as a guide to the style, proportions and level of detail; design a completely NEW host from this prompt. For a BACK view one picture is attached: the same host seen from directly behind, same pose, every color the same as the front. Clean, simple 3D cartoon toy style: every area one smooth, flat, solid color, with no texture at all - no fabric grain, no fur strands, no stitching, no grime, no wrinkles painted on, no shading or shadows painted on, nothing see-through and nothing glowing. Simple rounded chunky shapes; small details as simple solid shapes close to the body - nothing thin or long sticking out. A big host, about twice as tall as a 10-year-old. No logos, brand marks, printed words, letters, numbers or graphics. Not like any famous character from a film, cartoon, game or advert - a new, original take on a grumpy Christmas couple. Full body standing in an A-pose: arms straight and angled down and away from the body with a clear gap between each arm and the body, hands open, legs apart, feet flat. Centered and filling the whole height, nothing cropped. Plain flat light-gray background, even soft light, no floor shadow. One character only, no text.

## Ordered pictures

| Order | Picture | Reference | File name |
|---|---|---|---|
| 1 | FRONT view of Mr Claus, the grumpy Christmas boss: a big, round, barrel-bellied man with rosy cheeks and a big bulbous red nose, a short neat frosty-white beard and bushy white eyebrows pulled into a sulky frown, small sly black eyes; a dark-red suit coat with plain white cuffs and hem (no fur texture) and big square black buttons, a wide black belt with a plain square gray buckle, a small round black sack of coal hanging at his hip, dark-red trousers, chunky black boots; a dark-red floppy cap with a white band and a round white bobble, a gray smudge of soot on the cap and one cheek; big white gloves | `host-gobbler\front-toon.png` | `host-mrclaus\front-toon.png` |
| 2 | BACK view of Mr Claus, matching the reference exactly: the back of his dark-red floppy cap with the white bobble, the back of his white hair, the dark-red coat with its white hem, the wide black belt, the coal sack at his hip, chunky black boots, white gloves | `host-mrclaus\front-toon.png` | `host-mrclaus\back-toon.png` |
| 3 | FRONT view of Mrs Claus, the sly Christmas boss: a tall, thin lady with a pointed chin, a sly sideways smirk, narrowed green eyes behind small round gold glasses, rosy cheeks, white hair pulled into a tight round bun on top of her head with a small sprig of holly in it; a long plum-and-dark-red dress down to her ankles with plain white cuffs and collar, a white apron with one big pocket, red-and-white striped stockings, pointed dark-red shoes; big white oven mitts on both hands; a long rolled-up cream paper list tucked into her apron pocket (a plain scroll shape, no writing) | `host-gobbler\front-toon.png` | `host-mrsclaus\front-toon.png` |
| 4 | BACK view of Mrs Claus, matching the reference exactly: the back of her white hair in its tight bun with the holly sprig, the back of the plum-and-dark-red dress, the white apron's bow tied at her back, red-and-white striped stockings, pointed dark-red shoes, white oven mitts | `host-mrsclaus\front-toon.png` | `host-mrsclaus\back-toon.png` |

## Reference interpretation and checks

Fronts use Gobbler for style only and face directly toward the camera. Backs use the saved front as the identity reference and show the same character directly from behind. Preserve anatomical accessory placement across the turn. Render soot marks as flat gray shapes; holly, glasses and the blank scroll stay simple and close to the body. Verify full-body A-pose, straight arms with clear body gaps, open hands or mitten shapes, separated legs, flat feet, matching colors, smooth untextured surfaces, flat light-gray background, no floor shadow, and no writing or logos.

## Results

Per-image generation status, generated source, dimensions and SHA-256 are recorded in the JSON after saving.

Completed 5 Nov 2026 using the built-in image generator. All four PNGs are 1024 x 1536, visually inspected, saved in table order at the requested paths, and verified against their generated sources with SHA-256. Each back used only its newly saved front as its reference. The JSON contains the complete final prompt for every picture.
