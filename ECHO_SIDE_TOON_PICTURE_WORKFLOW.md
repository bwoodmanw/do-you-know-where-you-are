# Echo side toon picture workflow

Use this workflow to create the left and right side toon pictures for Echo
from the approved front and back toon pictures. Attach the front picture first
and the back picture second for each row.

```
create new workflow to create images based on the [Picture Standard], [Reference] and [Picture]. For each picture, attach every [Reference] picture listed, in that order, then save to "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input\[file name]". For example, C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\model-input\echo\left-toon.png. Create the folder if it does not exist.
The [Picture Standard] will be included with every picture prompt. The [Picture] prompt is added to [Picture Standard] and changes per prompt. The [Reference] and [file name] are defined per picture.
[Picture Standard] = "Two pictures are attached: the FRONT and the BACK view of the same character. Make a SIDE view of exactly this character: the same face, hair, hairstyle, clothes, colors and accessories, the same clean 3D cartoon toy style - every area one smooth, flat, solid color, no texture, no shading or shadows painted on, nothing see-through or glowing. Same A-pose: arms straight and angled down and away from the body, hands open, legs slightly apart, feet flat. A true side view (a profile): the camera is exactly level with the character and exactly at its side, not turned toward the front or back at all. Same size and height as the front view, centered, filling the whole height, nothing cropped. ONE plain flat light-gray background over the whole picture (no bands, no gradient), even soft light, no floor shadow. One character only, no text, no logos."
Table for each [Picture], [Reference] and [file name] combination is below:
[Picture] | [Reference] | [file name]
[LEFT SIDE view of Echo: seen from Echo's own LEFT side, so she is looking toward the LEFT edge of the picture. Show the left side of her curly brown hair and bun, the goggle strap, her left ear with the purple headphone around her neck, the left side of the yellow jacket and its sleeve, the small black backpack's strap and edge at her back, the left side of her purple joggers and purple-and-yellow sneakers.] | [model-input\echo\front-toon.png, model-input\echo\back-toon.png] | [echo\left-toon.png]
[RIGHT SIDE view of Echo: seen from Echo's own RIGHT side, so she is looking toward the RIGHT edge of the picture. Show the right side of her curly brown hair and bun, the goggle strap, her right ear with the purple headphone around her neck, the right side of the yellow jacket and its sleeve, the small black backpack's strap and edge at her back, the right side of her purple joggers and purple-and-yellow sneakers.] | [model-input\echo\front-toon.png, model-input\echo\back-toon.png] | [echo\right-toon.png]
```

Send Claude the two side pictures to check before using them for model input.
