# Christmas host picture workflow

Create Crumbles and Frostfoot in table order, using the built-in image generator, one picture per row. The complete prompt set is saved in `tools/workflows/christmas-host-images.json`.

Reference and output root: `C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input`.

Attach every reference listed for a row. Each front uses Gobbler only for style, proportions and detail. Each back attaches only its newly saved front. Inspect and save each result before advancing. Create missing output folders. Preserve existing artwork unless replacement is explicitly requested.

## Picture Standard

This is a host (the friendly-spooky chaser) in a kids' co-op escape game for ages 8 and up: spooky and silly, never gory or truly frightening. For a FRONT view one picture is attached: ANOTHER host from the same game - use it ONLY as a guide to the style, proportions and level of detail; design a completely NEW host from this prompt. For a BACK view one picture is attached: the same host seen from directly behind, same pose, every color the same as the front. Clean, simple 3D cartoon toy style: every area one smooth, flat, solid color, with no texture at all - no fur strands, no crumbs, no cracks painted on, no grime, no wrinkles painted on, no shading or shadows painted on, nothing see-through and nothing glowing (glowing parts become solid bright colors). Simple rounded chunky shapes; small details as simple solid shapes close to the body - nothing thin or long sticking out. A big host, about twice as tall as a 10-year-old. No logos, brand marks, printed words, letters, numbers or graphics. Not like any famous character from a film, cartoon or game. Full body standing in an A-pose: arms straight and angled down and away from the body with a clear gap between each arm and the body, hands open, legs apart, feet flat. Centered and filling the whole height, nothing cropped. Plain flat light-gray background, even soft light, no floor shadow. One character only, no text.

## Ordered pictures

| Order | Picture | Reference | File name |
|---|---|---|---|
| 1 | FRONT view of Crumbles the Gingerbread Giant: a tall, chunky, grumpy gingerbread cookie giant with a warm golden-brown cookie body and big round mitten-like hands and feet; one round bite missing from the top of his left shoulder (a smooth curved notch, nothing crumbly); a grumpy face with thick wavy white icing eyebrows pulled into a frown, small round black candy eyes, a crooked white icing frown, round rosy-pink cheeks; white icing zigzags round his wrists and ankles; three round red-and-white peppermint-swirl candies down his chest as buttons; a short red-and-green striped scarf wrapped snugly round his neck (ends tucked in); a small white baker's cap tilted on his head | `host-gobbler\front-toon.png` | `host-crumbles\front-toon.png` |
| 2 | BACK view of Crumbles the Gingerbread Giant, matching the reference exactly: the back of his golden-brown cookie head with the baker's cap, the bite notch at the top of his left shoulder (on the RIGHT of the picture seen from behind), the scarf round his neck, plain golden-brown cookie back, white icing zigzags round his wrists and ankles | `host-crumbles\front-toon.png` | `host-crumbles\back-toon.png` |
| 3 | FRONT view of Frostfoot the Yeti: a big, round-shouldered, friendly-spooky snow beast covered in shaggy fur drawn as big smooth solid tufts - snowy white with pale lavender tips; a round dark navy-blue face with big round yellow eyes, a wide goofy grin with a small underbite and two short rounded white tusks pointing up; small round ears; long arms with big dark navy-blue hands; huge flat dark navy-blue feet; a chunky teal-and-orange knitted scarf wrapped snugly round his neck (ends tucked in); a small round ice-blue pom-pom hat perched on top of his head. No horns, no claws | `host-gobbler\front-toon.png` | `host-yeti\front-toon.png` |
| 4 | BACK view of Frostfoot the Yeti, matching the reference exactly: the back of his shaggy white-and-lavender fur in big smooth tufts, the small pom-pom hat, the teal-and-orange scarf round his neck, long arms, huge flat dark navy-blue feet | `host-yeti\front-toon.png` | `host-yeti\back-toon.png` |

## Prompt construction

Every saved `prompt` contains the entire Picture Standard and the exact Picture row, plus a view-specific instruction identifying the reference role. Render a single full-body view on an opaque flat light-gray background. Fur, knit and cookie surfaces stay smooth and untextured; lavender tuft tips, icing, peppermint swirls and scarf stripes use solid colors.

The supplied Crumbles rows place the notch on image RIGHT in both views. The workflow retains that explicit placement.

## Results

Generation status, source path, dimensions and SHA-256 are recorded per picture in the JSON workflow after each asset is saved.

Completed 5 Nov 2026 with the built-in image generator. All four PNGs are 1024 x 1536, visually checked and saved at the table paths. Each saved file was verified against its generated source using SHA-256. Crumbles' front was refined to use small black candy eyes, rounded mitten hands and a scarf with its ends tucked inside before generating the back.

