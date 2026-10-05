/* tools/make_prompts_docx.js - builds ART_PROMPTS.docx: every image prompt
   fully assembled (style block included) so each can be copied on a phone
   in one go. Source of truth is this file and ART_PROMPTS.md. */
var fs = require('fs');
var path = require('path');
var d = require('docx');

var STYLE = 'Stylised 3D game render, like a polished modern online kids\' horror-escape game (hide-and-seek / murder-mystery style), for ages 8 and up. Realistic lighting and soft shadows, detailed materials (fabric, wood, plastic, metal), slightly chunky, appealing proportions. Creepy and tense but never gory: no blood, wounds, weapons or body horror. Not blocky toy avatars. No text, letters, logos, brand names or watermark.';

var CHAR = 'Character turnaround sheet of ONE child character, about 10 years old, full body, on a plain light grey background. Top row, four views, same size and pose height: front, three-quarter front, side, back. Bottom row, four poses: running, hiding (crouched, peeking), scared (jumping back), cheering. Same outfit and colours in all eight. ';
var chars = [
  ['Tinker', 'An inventive kid in blue dungarees over an orange T-shirt, brass-rimmed workshop goggles pushed up on a blue cap worn slightly sideways, a tool belt with a small spanner and screwdriver, scuffed trainers. Curious, quick grin.'],
  ['Shadow', 'A quiet, sly kid in a dark purple hoodie with the hood up, a black cloth mask over the lower face, dark joggers and soft black sneakers, purple fingerless gloves. Moves like a cat.'],
  ['Brainy', 'A clever kid in a white lab coat over a sky-blue jumper, big round black glasses, a red beanie with a little blue propeller, a notebook and pencil behind the ear. Excitable.'],
  ['Muscle', 'A strong, kind kid in a red sports jersey with no team name, charcoal shorts, a yellow sweatband, high-top trainers, rolled-up sleeves. Confident.'],
  ['Glow', 'A gentle kid in a lime-green glow-in-the-dark raincoat, a headband with a curly antenna and a glowing bulb, a head torch around the neck, green wellies. Bright eyes.'],
  ['Patch', 'A caring kid in a pink medic-style vest over a white top, a sticking plaster on the forehead, a small first-aid satchel with a heart (no red cross), comfy trainers.'],
  ['Echo', 'A watchful kid in a yellow bomber jacket and purple trousers, big dark headphones around the neck, round goggles, a little handheld sound gadget.'],
  ['Bramble', 'An outdoorsy kid in a leaf-green poncho and brown cargo shorts, a crown of real leaves and one small flower in the hair, muddy boots, a pouch of seeds. Calm.']
];

var HOST = 'Creature turnaround sheet on a plain light grey background. Top row: front, three-quarter, side, back. Bottom row: wandering, hunting (lunging, arms reaching), stunned, a funny moment. The creature is about twice the height of a 10-year-old. ';
var hosts = [
  ['party', 'The Party Host (Halloween)', 'The Party Host. Very tall and thin, in a worn dark purple tailcoat, bow tie and white gloves, long arms. His head is a carved pumpkin mask that is melting - glossy orange drips at the chin - with triangle eyes and a jagged grin glowing candle-yellow (red when hunting). A crooked striped party hat. Funny moment: his mask has slipped sideways and he is pushing it back.'],
  ['gummy', 'The Jelly Ringmaster (Gummy theme)', 'The Jelly Ringmaster. A towering, translucent raspberry-gummy figure with light passing through it, a tiny top hat, a sparkly cane, a wide grin of sugar-crystal teeth. Wobbles and bounces, leaves a glossy sticky trail. Funny moment: stuck to the floor by his own goo.'],
  ['hospital', 'The Night Shift (Hospital theme)', 'The Night Shift. A tall, creaking robot built from an old drip stand on squeaky wheels, a flickering examination lamp for a head, long jointed arms holding a clipboard and a thermometer. Wants to "take your temperature". No needles, no blood. Funny moment: its lamp pops and it rolls into a trolley.']
];

var ROOM = 'Isometric three-quarter view from above of one room in a game level, like a diorama with the near walls cut away so you can see in. Realistic lighting and materials. No people or creatures. ';
var rooms = [
  ['Party House (Halloween) - in the game now', [
    ['room-party-parlour.png', 'Parlour', 'A Victorian parlour: plum carpet, tall dark wardrobe, squashy purple sofa, fireplace with a carved pumpkin, a framed party invitation on the back wall, one white balloon with a number 2 on it.', 'candlelight, cosy but wrong'],
    ['room-party-corridor.png', 'Corridor', 'A long wooden corridor ending in a huge front door with a four-colour keypad, old portraits on the walls, a blue wrapped present on the floor.', 'cold moonlight through a fanlight'],
    ['room-party-library.png', 'Library', 'Two long rows of bookshelves, green carpet, a curtained reading nook, a large leafy potted plant in the corner, faint glow-paint scribbles on the back wall.', 'one green banker\'s lamp'],
    ['room-party-kitchen.png', 'Kitchen', 'Black-and-white tiled floor, a long counter of party food, a pantry cupboard, a small dark door in the side wall with two red eyes inside, a white balloon numbered 1, a red present.', 'the glow of an open fridge'],
    ['room-party-hall.png', 'Front Hall', 'The front hall: wooden floor, a long party table with a white cloth, orange scalloped trim and a birthday cake, a metal cage with a cushion in the corner, a red velvet curtain.', 'flickering chandelier'],
    ['room-party-gameroom.png', 'Game Room', 'Purple carpet, a big wooden cabinet against the side wall, a large cardboard box, a white balloon numbered 3, board games, a ball pit, a disco ball.', 'disco-ball sparkles in the dark'],
    ['room-party-garden.png', 'Garden (safe area)', 'The safe area: the back garden at night with fairy lights and a gate, a welcoming bench.', 'warm and safe']
  ]],
  ['Gummy Bounce House (next theme)', [
    ['room-gummy-lobby.png', 'Lobby', 'A bouncy-castle lobby made of jelly, candy-stripe walls, giant gummy statues (not any brand).', 'bright and sugary'],
    ['room-gummy-pit.png', 'Gumdrop Pit', 'A giant pit of gumdrops with hiding gaps underneath.', 'bright and sugary'],
    ['room-gummy-slide.png', 'Sprinkle Slide', 'A rainbow sprinkle slide tower with platforms and glowing sparkle-power pads.', 'bright with glowing pads'],
    ['room-gummy-vault.png', 'Caramel Vault', 'A caramel vault with a wobbling jelly door and colour switches.', 'warm amber glow'],
    ['room-gummy-safe.png', 'Candyfloss Cloud (safe area)', 'Safe area: a floating cloud of candyfloss above the castle.', 'soft pink sunset']
  ]],
  ['Abandoned Hospital (later theme)', [
    ['room-hospital-waiting.png', 'Waiting Room', 'A dusty waiting room: tipped chairs, a reception desk with a bell, a fish tank with one cheerful fish.', 'flickering strip lights'],
    ['room-hospital-ward.png', 'Ward', 'A ward of empty beds with curtains to hide behind, wheeled trolleys.', 'dim blue night lights'],
    ['room-hospital-xray.png', 'X-ray Room', 'An X-ray room with a glowing lightbox showing a cartoon skeleton dancing.', 'the lightbox glow only'],
    ['room-hospital-pharmacy.png', 'Pharmacy', 'Tall shelves of coloured bottles (no pills or needles), a locked hatch.', 'green exit-sign glow'],
    ['room-hospital-boiler.png', 'Boiler Room', 'A basement boiler room: pipes, steam, a big red lever.', 'orange furnace glow'],
    ['room-hospital-safe.png', 'Ambulance Bay (safe area)', 'Safe area: an ambulance bay at dawn, a waiting family car.', 'warm dawn light']
  ]]
];

var TEX = 'Seamless tileable texture, viewed straight from above, evenly lit, no shadows, no objects: ';
var textures = [
  ['tex-wood.png', 'old honey-coloured wooden floorboards'],
  ['tex-darkwood.png', 'dark worn wooden corridor boards'],
  ['tex-carpet-plum.png', 'faded plum Victorian carpet with a subtle pattern'],
  ['tex-carpet-green.png', 'worn green library carpet'],
  ['tex-carpet-purple.png', 'purple games-room carpet with a faint star pattern'],
  ['tex-tiles.png', 'black-and-white checker kitchen tiles, slightly grimy'],
  ['tex-wallpaper.png', 'peeling Victorian party wallpaper, dark purple stripes with small orange balloons']
];

var parts = [
  ['eyes', 'eyes', 'round, sleepy, starry, wink, narrow and sly, huge and sparkly, cat-like, glowing, worried, determined, tired with bags, one eyebrow raised, laughing shut, wide with fright, two different colours, freckled under-eye'],
  ['eyebrows', 'eyebrows', 'none, thin, bushy, angry, worried, raised, unibrow, zigzag, thick straight, curly, slit, scar notch, arched, flat, tiny, sparkly'],
  ['mouths', 'mouth', 'smile, big toothy grin, O, tongue out, gap tooth, braces, cheeky smirk, nervous, laughing, whistling, frown, determined line, cat mouth, buck teeth, lollipop in mouth, face mask'],
  ['noses', 'nose', 'small button, round, pointed, freckled, wide, upturned, long, sunburnt, plaster on nose, clown red, whiskers drawn on, narrow, hooked, tiny, star sticker, snub'],
  ['hair', 'hair or headwear', 'short spiky, curly afro, two puffs, long braids, bob, mohawk, beanie, baseball cap, bucket hat, wizard hat, bunny ears, cat ears, bandana, top hat, flower crown, hood up'],
  ['tops', 'top', 'striped tee, hoodie, dungarees, lab coat, superhero cape, raincoat, Halloween-pumpkin jumper, tank top, plain sports jersey, pyjamas, ninja wrap, sequin jacket, denim jacket, puffer coat, knitted cardigan, explorer shirt'],
  ['bottoms', 'bottoms', 'shorts, skirt, tutu, jeans, joggers, cargo shorts, leggings, dungaree legs, kilt-style skirt, pyjama bottoms, swim shorts, ripped jeans, snow trousers, karate trousers, tracksuit, overall shorts'],
  ['shoes', 'shoes', 'trainers, wellies, slippers, roller skates, flippers, cowboy boots, ballet shoes, rocket boots, flip-flops, hiking boots, light-up trainers, socks only, clogs, football boots (no logos), sandals, bunny slippers'],
  ['extras', 'accessory', 'backpack, scarf, cape, small wings, tail, round glasses, eyepatch, medal, bow tie, necklace, wand, umbrella, balloon on a string, pet mouse on the shoulder, torch, skateboard']
];

// ---- document building ----
var kids = [];
function p(text, opts) { return new d.Paragraph(Object.assign({ children: [new d.TextRun({ text: text, size: 24 })], spacing: { after: 120 } }, opts || {})); }
function runs(list) { return new d.Paragraph({ children: list.map(function (r) { return new d.TextRun(Object.assign({ size: 24 }, r)); }), spacing: { after: 120 } }); }
function h1(t) { kids.push(new d.Paragraph({ text: t, heading: d.HeadingLevel.HEADING_1, pageBreakBefore: kids.length > 0 })); }
function h2(t) { kids.push(new d.Paragraph({ text: t, heading: d.HeadingLevel.HEADING_2, spacing: { before: 240, after: 80 } })); }
var count = 0;
function prompt(title, file, size, text) {
  count++;
  h2(count + '. ' + title);
  kids.push(runs([{ text: 'Save as: ', bold: true }, { text: 'art/sheets/' + file }]));
  kids.push(runs([{ text: 'Size: ', bold: true }, { text: size }]));
  kids.push(new d.Paragraph({
    children: [new d.TextRun({ text: STYLE + ' ' + text, size: 24, font: 'Arial' })],
    shading: { type: d.ShadingType.CLEAR, color: 'auto', fill: 'F1ECF8' },
    border: { left: { style: d.BorderStyle.SINGLE, size: 18, color: '8A6BD1', space: 8 } },
    spacing: { before: 60, after: 200 }
  }));
}

h1('Image prompts - Do You Know Where You Are?');
kids.push(p('Every prompt below is complete: copy the whole shaded box into ChatGPT image creation. It already includes the style instructions.'));
kids.push(p('To fix one detail, reply in the same chat (for example "same character, brass goggles") rather than starting a new chat - it keeps the character consistent.'));
kids.push(p('Sizes: Wide = 1536 x 1024, Square = 1024 x 1024. If ChatGPT asks, choose landscape for Wide.'));
kids.push(p('Save each image with the filename shown, then put the files in the game folder under art/sheets (or send them to Claude) and say which arrived.'));
kids.push(p('Public website: if an image looks like a character from a film, show, toy or game (Roblox avatars, Minecraft, Among Us, Five Nights at Freddy\'s, Pokemon, branded sweets) - make it again. No logos or text in images.'));
kids.push(p('How they are used: characters and customisation sheets are design guides (the game is redrawn to match); hosts, jumpscares, rooms and textures go into the game directly.'));

h1('Characters (8)');
chars.forEach(function (c) { prompt(c[0], 'char-' + c[0].toLowerCase() + '.png', 'Wide (1536 x 1024)', CHAR + c[1]); });

h1('Hosts and jumpscares (3 themes)');
hosts.forEach(function (h) {
  prompt(h[1] + ' - turnaround', 'host-' + h[0] + '.png', 'Wide (1536 x 1024)', HOST + h[2]);
  prompt(h[1] + ' - jumpscare', 'host-' + h[0] + '-scare.png', 'Wide (1536 x 1024)',
    'Extreme close-up of ' + h[2].split('.')[0] + ' lunging out of total darkness toward the viewer, only the face and hands lit from below, dramatic. Startling, not gory. Full description: ' + h[2]);
});

h1('Rooms');
rooms.forEach(function (t) {
  kids.push(p(t[0], { children: [new d.TextRun({ text: t[0], bold: true, size: 26, color: '5B3B8A' })] }));
  t[1].forEach(function (r) { prompt(r[1], r[0], 'Wide (1536 x 1024)', ROOM + r[2] + ' Lighting: ' + r[3] + '.'); });
});

h1('Floor and wall textures (7)');
textures.forEach(function (x) { prompt(x[0].replace('tex-', '').replace('.png', ''), x[0], 'Square (1024 x 1024)', TEX + x[1] + '. It must tile with no visible seam.'); });

h1('Customisation sheets (9)');
parts.forEach(function (x) {
  prompt(x[1].charAt(0).toUpperCase() + x[1].slice(1), 'parts-' + x[0] + '.png', 'Square (1024 x 1024)',
    'Character-creator sheet: a 4 x 4 grid of sixteen equal squares on a plain light grey background. In every square the SAME plain 10-year-old mannequin-style character (grey T-shirt, grey shorts, neutral face), same pose, same size, same position. Only one thing changes from square to square: the ' + x[1] + '. The sixteen options, one per square: ' + x[2] + '.');
});

var doc = new d.Document({
  styles: {
    default: { document: { run: { font: 'Arial', size: 24 } } },
    paragraphStyles: [
      { id: 'Heading1', name: 'Heading 1', basedOn: 'Normal', next: 'Normal', quickFormat: true, run: { size: 34, bold: true, color: 'D9600B' }, paragraph: { spacing: { after: 160 }, outlineLevel: 0 } },
      { id: 'Heading2', name: 'Heading 2', basedOn: 'Normal', next: 'Normal', quickFormat: true, run: { size: 28, bold: true, color: '1A1026' }, paragraph: { outlineLevel: 1 } }
    ]
  },
  sections: [{ properties: { page: { size: { width: 12240, height: 15840 }, margin: { top: 1080, bottom: 1080, left: 1080, right: 1080 } } }, children: kids }]
});
d.Packer.toBuffer(doc).then(function (buf) {
  var out = path.join(__dirname, '..', 'ART_PROMPTS.docx');
  fs.writeFileSync(out, buf);
  console.log('wrote ART_PROMPTS.docx with ' + count + ' prompts');
});
