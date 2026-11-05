# Claus Manor map picture workflow

Reusable prompt set: `tools/workflows/claus-manor-map-pictures.json`.

Use built-in image generation, one picture per call, in the order below. Every full prompt includes the supplied Picture Standard followed by its Picture. Attach only that row's references, in the listed order. Inspect references before generation and results before saving.

Reference and output folder: `C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\roblox-store\maps`. Create it if missing. Save each PNG with its exact file name below; preserve existing assets unless replacement is authorized.

## Picture Standard

This is for a kids' co-op escape game for ages 8 and up: friendly, funny, cozy and a little spooky, never scary. Rich, polished 3D animated-movie style (soft light, glossy rounded shapes), in exactly the same style, angle, framing and lighting as the attached picture (another place in the game). A WIDE 16:9 picture. No people, no characters, no creatures. No text, no letters, no numbers, no logos or brand marks. Nothing that looks like a famous place or character from a film, cartoon or game.

## Ordered pictures

| Order | Picture | References in attachment order | File name |
|---|---|---|---|
| 1 | Claus Manor, the grumpy Clauses' big house at the North Pole, seen from a little above and to the side: a tall, crooked, three-story dark-red brick-and-timber manor half buried in deep snow, a steep snowy roof with a big crooked chimney puffing dark smoke, a lit-up workshop window full of toys on the ground floor, a warm kitchen window on the middle floor, a big round loft window at the top with a sleigh's runners just visible inside, icicles along every edge, piles of wrapped presents by the front door, a little sign-less lamp post, a lump of coal in the snow by the path, snowy pine trees, a deep blue night sky with falling snow and a faint green northern light | `building-candycanelane.png` | `building-clausmanor.png` |
| 2 | The Toy Workshop, the ground floor of Claus Manor, seen from above into the cut-away room: long wooden workbenches covered in half-built toys (wooden trains, teddy bears, rocking horses, drums), shelves of paint pots, a conveyor belt of wrapped presents, a coal scuttle by a big black iron stove, stacks of wrapped presents in the corners, warm lamp light and a little spooky shadow in the corners | `floor-frostpeak-hall.png` | `floor-clausmanor-workshop.png` |
| 3 | The Cookie Kitchen, the middle floor of Claus Manor, seen from above into the cut-away room: a big old-fashioned kitchen with a huge brick oven glowing orange, long tables with trays of iced cookies and gingerbread, tall jars of candy, rolling pins and mixing bowls, a pantry door ajar, a cuckoo clock without numbers, wrapped presents tucked under the tables, warm light and a little spooky shadow in the corners | `floor-frostpeak-rooms.png` | `floor-clausmanor-kitchen.png` |
| 4 | The Sleigh Loft, the top floor of Claus Manor, seen from above into the cut-away attic: big roof beams with icicles, a big red sleigh piled with wrapped presents in the middle, harness bells hanging on the walls, sacks of toys, a ladder, a big round window with moonlight and snow blowing in, old lanterns glowing, a little spooky still cozy | `floor-frostpeak-belltower.png` | `floor-clausmanor-loft.png` |

## Validation

Check a wide 16:9 composition, the requested scene and reference style, and no text, people, characters or living creatures. Teddy bears and rocking horses are inanimate workshop toys. The kitchen clock has no numbers or bird, and gingerbread has no faces. Record generated source, saved path, dimensions and SHA-256 in the JSON after each successful save.

## Run status

Generation in progress.
