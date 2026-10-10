# Core toon 3D model workflow

Use this workflow to make the seven core kid character `.glb` files from the
approved front and back toon pictures. Attach the front picture first and the
back picture second for each row.

```
create new workflow to create 3D models based on the [Model Standard], [Reference] and [Model]. For each model, attach both [Reference] pictures (the front picture and the back picture), then save the model to "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\[folder]\[file name]". For example, C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\models\brainy-toon.glb.
The [Model Standard] will be included with every model prompt. The [Model] prompt is added to [Model Standard] and changes per model. The [Reference] and [file name] are defined per model.
[Model Standard] = "Use the attached pictures to create a 3D model of the character for a Roblox game: the first picture is the FRONT, the second is the BACK. Copy both pictures exactly - the same character, shapes, colors and accessories; the back of the model must match the back picture (never guess its colors). Art style / texture style: Cartoon (stylized). Every area one flat, solid color in a single base-color (albedo) texture; PBR off - no normal, roughness, metallic or bump maps. Remove lighting / delight on - no lighting, shadows, ambient occlusion or dark creases baked into the colors. Skin on the face, neck, arms, hands and legs in the warm skin tone of the pictures (never pale gray or white). No logos, brand marks, printed words or graphics. Pose: A-pose - arms straight, angled about 45 degrees down and away from the body and not touching it, hands open with the fingers together, legs slightly apart, feet flat; left and right sides symmetrical. Front facing: the face looks straight forward toward the front picture's camera; the character stands upright with the feet at the bottom of the model. One single closed mesh with no separate floating pieces; no skeleton, no rig, no animation; no floor, stand or background. Polycount: the lower option - about 5,000 to 8,000 triangles. One 1024 x 1024 texture embedded in the file. Keep accessories close to the body (no big brims, bags or antennas sticking far out); the face clearly visible, not covered by hair, hats or goggles. Save as a .glb file."
[folder]="models"
Table for each [Model], [Reference] and [file name] combination is below:
[Model] | [Reference] | [file name]
[Brainy, a clever boy: round black glasses, red beanie with a small blue propeller, a pencil behind his ear, white lab coat over a light-blue sweater, khaki cargo pants, red sneakers.] | [model-input\brainy\front-toon.png, model-input\brainy\back-toon.png] | [brainy-toon.glb]
[Shadow, a sneaky boy: purple hoodie with the hood up, black face mask, purple fingerless gloves, black jogger pants, plain black sneakers with purple laces and no stripes.] | [model-input\shadow\front-toon.png, model-input\shadow\back-toon.png] | [shadow-toon.glb]
[Muscle, a strong, sturdy boy: spiky brown hair, yellow headband and wristbands, red T-shirt, black shorts, white socks, plain solid red high-top sneakers with white soles and white laces and no logo.] | [model-input\muscle\front-toon.png, model-input\muscle\back-toon.png] | [muscle-toon.glb]
[Glow, a girl with a light: curly hair in a bun, green headband with a short antenna and a round yellow bulb, solid lime-green raincoat, round yellow chest lamp, dark olive pants, green rain boots.] | [model-input\glow\front-toon.png, model-input\glow\back-toon.png] | [glow-toon.glb]
[Patch, a caring girl: long straight golden-blonde ponytail with a pink scrunchie, blue eyes, small forehead bandage, pink vest over a cream top, pink shoulder bag with a white heart, light-blue jeans, pink-and-cream sneakers.] | [model-input\patch\front-toon.png, model-input\patch\back-toon.png] | [patch-toon.glb]
[Echo, a girl with headphones: curly hair in a bun, brass goggles on her head, purple headphones around her neck, yellow jacket over a plain purple hoodie, small black backpack, plain purple jogger pants, purple-and-yellow sneakers.] | [model-input\echo\front-toon.png, model-input\echo\back-toon.png] | [echo-toon.glb]
[Bramble, a nature boy: crown of green leaves with a white flower, green poncho with a zigzag leaf edge, brown strap bag with acorns, brown cargo shorts, green socks, brown boots.] | [model-input\bramble\front-toon.png, model-input\bramble\back-toon.png] | [bramble-toon.glb]
```

After each model is saved, send the `.glb` to Claude for rendering and checks
before importing it into Roblox Studio.
