# Christmas skins for every character (draft, 5 Nov 2026)

One Christmas skin for each of the 13 characters. It is the same kid, with
the same face, hair and body, in a Christmas outfit. Recommended price, like
Thanksgiving: **150 candy canes** in the Christmas Shop during the event, or
a **99-Robux Game Pass** at any time.

Elfy gets no skin: he is the limited Christmas character and is already
dressed for it.

| # | Skin | Character | Folder (art/model-input) | Model name |
|---|---|---|---|---|
| 1 | Ice Skater Patch | patch | skater-patch | PatchSkater |
| 2 | Gingerbread Brainy | brainy | gingerbread-brainy | BrainyGingerbread |
| 3 | Silent Night Shadow | shadow | silentnight-shadow | ShadowSilentNight |
| 4 | Twinkle Lights Glow | glow | twinkle-glow | GlowTwinkle |
| 5 | Toy Maker Tinker | tinker | toymaker-tinker | TinkerToymaker |
| 6 | Holiday Sweater Muscle | muscle | sweater-muscle | MuscleSweater |
| 7 | Jingle Bell Echo | echo | jinglebell-echo | EchoJingle |
| 8 | Evergreen Bramble | bramble | evergreen-bramble | BrambleEvergreen |
| 9 | Snowflake Nutmeg | nutmeg | snowflake-nutmeg | NutmegSnowflake |
| 10 | First Snow Cloud | cloud | snow-cloud | CloudSnow |
| 11 | Sugar Plum Holly | holly | sugarplum-holly | HollySugarplum |
| 12 | Nutcracker Clone | clone | nutcracker-clone | CloneNutcracker |
| 13 | Carol Singer Harmony | harmony | carol-harmony | HarmonyCarol |

Holly and Nutmeg already wear red and green, so their skins go another way:
sugar-plum purple for Holly, snowy white for Nutmeg.

Steps:
1. These pictures.
2. The 3D models: Stable Fast 3D, painting and the checker, done here.
3. Brent imports each model into Studio, runs Avatar Setup and saves it to
   Roblox.
4. Brent sends the model IDs, and makes the Game Passes from the pass
   pictures.
5. I add them to `Config.SKINS`.

There are 26 pictures, so they are in two workflows. Run them in table order,
FRONT then BACK for each character. Each BACK attaches only the FRONT saved
just before it.

## Workflow A: the first eight characters (16 pictures)

```
create new workflow to create images based on the [Picture Standard], [Reference] and [Picture]. For each picture, attach the [Reference] picture listed, then save to "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input\[file name]". For example, C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input\skater-patch\front-toon.png. The [Reference] is in "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input\[Reference]". Create the folder if it does not exist.
The [Picture Standard] will be included with every picture prompt. The [Picture] prompt is added to [Picture Standard] and changes per prompt. The [Reference] and [file name] are defined per picture. Make the rows in order: each BACK row uses the FRONT picture saved just before it.
[Picture Standard] = "This is a Christmas outfit for a character in a kids' co-op escape game for ages 8 and up: festive, cozy and fun, never scary. For a FRONT view the attached picture is this SAME character's approved look: keep the face, skin tone, eyes, hair, body shape and proportions exactly the same, with a friendly happy expression - change ONLY the clothes and accessories as described. For a BACK view the attached picture is the new outfit from the front: show the same character from directly behind, same pose, every color the same as the front. Clean, simple 3D cartoon toy style exactly like the attached picture: every area one smooth, flat, solid color, with no texture at all - no fabric grain, no knit, no fluffy fur strands, no stitching, no sparkles or glitter, no folds or wrinkles painted on, no shading or shadows painted on, nothing see-through and nothing glowing (lights are solid bright colors). Small details as simple solid shapes, close to the body - nothing thin or long sticking out (no strings, no straps hanging loose, no scarf ends flying). No logos, brand marks, emblems, swooshes, stripes on shoes, printed words, letters, numbers or graphics. Not like any famous character from a film, cartoon, ballet production or game. Full body standing in an A-pose: arms straight and angled clearly down and away from the body with a clear gap between each arm and the body all the way down, hands open, legs slightly apart, feet flat. Centered and filling the whole height, nothing cropped. Plain flat light-gray background, even soft light, no floor shadow. One character only, no text."
Table for each [Picture], [Reference] and [file name] combination is below:
[Picture] | [Reference] | [file name]
[FRONT view of Ice Skater Patch: her same long golden-blonde hair in a high ponytail, the small bandage on her forehead and blue eyes; round white earmuffs; a short puffy icy-blue skating jacket with a smooth solid white collar and white cuffs; a short icy-blue skating skirt; plain white tights; white ice-skating boots, each with one short, chunky solid silver blade underneath, close to the boot] | [patch\front-toon.png] | [skater-patch\front-toon.png]
[BACK view of Ice Skater Patch, matching the reference exactly: the back of her blonde ponytail, the white earmuffs at both sides, the back of the icy-blue jacket with its white collar, the icy-blue skirt, white tights, white skating boots with their silver blades] | [skater-patch\front-toon.png] | [skater-patch\back-toon.png]
[FRONT view of Gingerbread Brainy: his same messy brown hair and round black glasses, his propeller cap now red and white with a red propeller; a gingerbread-brown lab coat with a wavy white icing-style trim along the hem and cuffs (one solid white wavy band, close to the coat) and three round red-and-white peppermint buttons; a cream shirt; tan trousers with NO pockets; red sneakers with white soles] | [brainy\front-toon.png] | [gingerbread-brainy\front-toon.png]
[BACK view of Gingerbread Brainy, matching the reference exactly: the back of his messy brown hair and the red-and-white propeller cap, the back of the gingerbread-brown lab coat with the white wavy trim along its hem and cuffs, tan trousers, red sneakers with white soles] | [gingerbread-brainy\front-toon.png] | [gingerbread-brainy\back-toon.png]
[FRONT view of Silent Night Shadow: his same black hair, purple eyes and plain face mask, the mask now midnight navy; a midnight-navy hoodie with the hood up, a smooth solid white band round the edge of the hood and a small round white pom-pom on top of the hood; silver-gray fingerless gloves; midnight-navy jogger pants with NO pockets; plain navy sneakers with white soles] | [shadow\front-toon.png] | [silentnight-shadow\front-toon.png]
[BACK view of Silent Night Shadow, matching the reference exactly: the back of the midnight-navy hood with its white edge band and the white pom-pom on top, the back of the navy hoodie, silver-gray gloves, navy joggers, navy sneakers with white soles] | [silentnight-shadow\front-toon.png] | [silentnight-shadow\back-toon.png]
[FRONT view of Twinkle Lights Glow: her same curly brown hair in a bun and green eyes, her headband with its little antenna, the round bulb now solid red; a forest-green raincoat with a chunky string of big round solid light bulbs (red, gold and blue, not glowing) wrapped once diagonally across her chest like a sash, close to the coat; a cream scarf wrapped snugly at her neck (ends tucked in); plain dark-green jogger pants with NO pockets; red rain boots] | [glow\front-toon.png] | [twinkle-glow\front-toon.png]
[BACK view of Twinkle Lights Glow, matching the reference exactly: the back of her curly bun and the headband with the red bulb, the cream scarf at her neck, the back of the forest-green raincoat with the string of red, gold and blue bulbs crossing it diagonally, dark-green joggers, red rain boots] | [twinkle-glow\front-toon.png] | [twinkle-glow\back-toon.png]
[FRONT view of Toy Maker Tinker: his same brown hair, round goggles on his head and his cap worn backwards, the cap now green with a red brim; bright red overalls over a green long-sleeve shirt; a brown tool belt with a small wooden toy hammer and a small toy wrench tucked in, close to the belt; red-and-white candy-striped socks showing above plain brown work boots] | [tinker\front-toon.png] | [toymaker-tinker\front-toon.png]
[BACK view of Toy Maker Tinker, matching the reference exactly: the back of his green backwards cap (the red brim at the back), his goggles, brown hair, the back of the red overalls with straps crossing his green shirt, the tool belt, red-and-white striped socks, brown boots] | [toymaker-tinker\front-toon.png] | [toymaker-tinker\back-toon.png]
[FRONT view of Holiday Sweater Muscle: his same spiky brown hair, his headband now red; a big bright-red holiday sweater (smooth, no knit texture) with one wide green band across the chest and a row of solid white zigzags along that band; green-and-white wristbands; dark-green sports shorts; white socks with red tops; plain red sneakers with white soles] | [muscle\front-toon.png] | [sweater-muscle\front-toon.png]
[BACK view of Holiday Sweater Muscle, matching the reference exactly: the back of his spiky brown hair and red headband, the back of the red sweater with the green band and white zigzags going all the way round, dark-green shorts, white socks with red tops, red sneakers] | [sweater-muscle\front-toon.png] | [sweater-muscle\back-toon.png]
[FRONT view of Jingle Bell Echo: her same curly brown hair and eyes, the goggles on her head now red with gold rims, and one small round gold bell on each side of them; a short puffy red jacket with a smooth solid white collar and cuffs, open over a green hoodie; green jogger pants with NO pockets; plain white sneakers with red soles] | [echo\front-toon.png] | [jinglebell-echo\front-toon.png]
[BACK view of Jingle Bell Echo, matching the reference exactly: the back of her curly brown hair with the red goggles and the two gold bells at the sides, the back of the red jacket with its white collar, the green hood lying flat, green joggers, white sneakers with red soles] | [jinglebell-echo\front-toon.png] | [jinglebell-echo\back-toon.png]
[FRONT view of Evergreen Bramble: his same messy brown hair and face, his leaf crown now made of a few solid holly leaves with small round red berries; a dark-green poncho shaped in three layered pointed tiers like a little pine tree (smooth solid shapes, no needles), with a few small round red and gold ornaments on it; his same small satchel; brown shorts; dark-green socks; brown boots] | [bramble\front-toon.png] | [evergreen-bramble\front-toon.png]
[BACK view of Evergreen Bramble, matching the reference exactly: the back of his messy brown hair with the holly crown, the back of the pine-tree poncho in three pointed tiers with its red and gold ornaments, the satchel strap, brown shorts, dark-green socks, brown boots] | [evergreen-bramble\front-toon.png] | [evergreen-bramble\back-toon.png]
```

## Workflow B: the five newer characters (10 pictures)

```
create new workflow to create images based on the [Picture Standard], [Reference] and [Picture]. For each picture, attach the [Reference] picture listed, then save to "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input\[file name]". For example, C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input\snowflake-nutmeg\front-toon.png. The [Reference] is in "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input\[Reference]". Create the folder if it does not exist.
The [Picture Standard] will be included with every picture prompt. The [Picture] prompt is added to [Picture Standard] and changes per prompt. The [Reference] and [file name] are defined per picture. Make the rows in order: each BACK row uses the FRONT picture saved just before it.
[Picture Standard] = "This is a Christmas outfit for a character in a kids' co-op escape game for ages 8 and up: festive, cozy and fun, never scary. For a FRONT view the attached picture is this SAME character's approved look: keep the face, skin tone, eyes, hair, body shape and proportions exactly the same, with a friendly happy expression - change ONLY the clothes and accessories as described. For a BACK view the attached picture is the new outfit from the front: show the same character from directly behind, same pose, every color the same as the front. Clean, simple 3D cartoon toy style exactly like the attached picture: every area one smooth, flat, solid color, with no texture at all - no fabric grain, no knit, no fluffy fur strands, no stitching, no sparkles or glitter, no folds or wrinkles painted on, no shading or shadows painted on, nothing see-through and nothing glowing (lights are solid bright colors). Small details as simple solid shapes, close to the body - nothing thin or long sticking out (no strings, no straps hanging loose, no scarf ends flying). No logos, brand marks, emblems, swooshes, stripes on shoes, printed words, letters, numbers or graphics. Not like any famous character from a film, cartoon, ballet production or game. Full body standing in an A-pose: arms straight and angled clearly down and away from the body with a clear gap between each arm and the body all the way down, hands open, legs slightly apart, feet flat. Centered and filling the whole height, nothing cropped. Plain flat light-gray background, even soft light, no floor shadow. One character only, no text."
Table for each [Picture], [Reference] and [file name] combination is below:
[Picture] | [Reference] | [file name]
[FRONT view of Snowflake Nutmeg: the same reindeer girl with her same face, brown braids, and her hoodie's same antlers and ears, but the reindeer hoodie is now snowy white with a pale ice-blue belly patch; her bell is now silver; an ice-blue scarf wrapped snugly at her neck (ends tucked in); pale ice-blue mittens; light-gray leggings; white boots with ice-blue tops] | [nutmeg\front-toon.png] | [snowflake-nutmeg\front-toon.png]
[BACK view of Snowflake Nutmeg, matching the reference exactly: the back of the snowy-white reindeer hood with its antlers and ears, her brown braids, the ice-blue scarf, the back of the white hoodie, ice-blue mittens, light-gray leggings, white boots with ice-blue tops] | [snowflake-nutmeg\front-toon.png] | [snowflake-nutmeg\back-toon.png]
[FRONT view of First Snow Cloud: her same almost-white chin-length bob with its faint pale-blue tint, plus a round pale-blue pom-pom beanie on top; a puffy ice-blue snow jacket (a clearly stronger blue than her hair) with the hood down and big round white buttons, the same shape as her yellow raincoat; pale-blue mittens; white snow pants; chunky silver-blue snow boots] | [cloud\front-toon.png] | [snow-cloud\front-toon.png]
[BACK view of First Snow Cloud, matching the reference exactly: the back of her almost-white bob under the pale-blue pom-pom beanie, the back of the ice-blue snow jacket with the hood lying flat, pale-blue mittens, white snow pants, silver-blue snow boots] | [snow-cloud\front-toon.png] | [snow-cloud\back-toon.png]
[FRONT view of Sugar Plum Holly: her same long straight golden-blonde hair, but her peppermint hair bows become two round plum-purple bows; a plum-purple party dress with a short puffy skirt (one solid shape, not see-through, no net layers) and a wide pink sash at the waist; a small solid pink star-shaped clip at the collar; pink tights; plum-purple shoes] | [holly\front-toon.png] | [sugarplum-holly\front-toon.png]
[BACK view of Sugar Plum Holly, matching the reference exactly: the back of her long golden-blonde hair with the plum-purple bows at both sides, the back of the plum-purple dress with the pink sash tied in a small flat bow, pink tights, plum-purple shoes] | [sugarplum-holly\front-toon.png] | [sugarplum-holly\back-toon.png]
[FRONT view of Nutcracker Clone: his same short curly black hair and his same round goggles pushed up on his forehead, now with gold rims; a smart toy-soldier jacket split down the middle - the left half bright red, the right half royal blue - with a row of round gold buttons and small flat gold shoulder pads close to the shoulders; a white belt; his same chunky round wrist gadget, now gold with a plain dark screen; black trousers with NO pockets; shiny black boots] | [clone\front-toon.png] | [nutcracker-clone\front-toon.png]
[BACK view of Nutcracker Clone, matching the reference exactly: the back of his curly black hair with the gold-rimmed goggles, the back of the toy-soldier jacket (seen from behind, the red half is on the RIGHT of the picture and the royal-blue half on the LEFT), gold shoulder pads, white belt, black trousers, black boots] | [nutcracker-clone\front-toon.png] | [nutcracker-clone\back-toon.png]
[FRONT view of Carol Singer Harmony: her same long straight black hair with bangs, the music-note hair clips now solid gold; a small round red beret; a knee-length deep-green winter coat with a smooth solid white collar, cuffs and hem and round gold buttons; a short red scarf wrapped snugly at her neck (ends tucked in); her same small round gold music-box pendant; plain white tights; red boots. NO headphones, NO earmuffs] | [harmony\front-toon.png] | [carol-harmony\front-toon.png]
[BACK view of Carol Singer Harmony, matching the reference exactly: the back of her long straight black hair under the red beret, the gold note clips at the side, the red scarf, the back of the deep-green coat with its white collar and hem, white tights, red boots] | [carol-harmony\front-toon.png] | [carol-harmony\back-toon.png]
```

## Then

1. Tell me when a workflow is saved. I check each pair: same kid as the
   original, a happy face, no look-alikes or logos, nothing thin sticking
   out. Then I make the 3D models and check them for blotchy hair and stray
   colors.
2. The pass pictures and Game Passes come after the models are approved.
   The skins must be live by Dec 1.
