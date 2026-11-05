# Skill pictures for the five new characters (4 Nov)

The original 8 characters' skill buttons show a picture (`art/ui-icons/skill-*.png`).
Nutmeg, Cloud, Holly, Clone and Harmony have none yet, so their buttons show
their portrait for now. Once these five are uploaded, their IDs go in
`Config.UI_ICONS` as `["skill-nutmeg"]` and so on, and the button switches over
by itself.

## Paste into ChatGPT

```
create new workflow to create images based on the [Picture Standard] and [Picture]. For each picture, save to "C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\[folder]\[file name]". For example, C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are\art\ui-icons\skill-nutmeg.png.
The [Picture Standard] will be included with every picture prompt. The [Picture] prompt is added to [Picture Standard] and changes per prompt. The [file name] will be defined per picture.
[Picture Standard] = "A single button icon for a kids' co-op escape game for ages 8 and up, in exactly the same style as the game's other skill icons (a crossed wrench and screwdriver, a pair of headphones): one bold, chunky object in a glossy cartoon style with soft bright highlights, a thick dark-purple outline around the whole shape, rich purple and warm orange-gold accents, centered and filling most of the square. Fully transparent background - a PNG with no backdrop, no circle, no frame, no shadow box. It must still read clearly when shrunk to 60 pixels, so keep it simple with big shapes. No logos, brand marks, words, letters or numbers. Not taken from any existing game, film or cartoon. Square, 1024 x 1024."
[folder]="ui-icons"
Table for each [Picture] and [file name] combination is below:
[Picture] | [file name]
[Sleigh Dash: a round golden jingle bell with a small red ribbon bow on top, tilted forward as if rushing ahead, with three orange speed streaks swooshing out behind it] | [skill-nutmeg.png]
[Fog: a big puffy cloud, white with pale-blue shading, with soft curls of mist spilling out from underneath it] | [skill-cloud.png]
[Peppermints: three round red-and-white swirl peppermint candies, one big in front and two smaller ones tucked behind it] | [skill-holly.png]
[Copycat: two matching simple person shapes standing side by side, the left one teal and the right one orange, with a curved two-way arrow looping over their heads between them] | [skill-clone.png]
[Lullaby: two joined musical eighth notes in glossy purple, with a small golden crescent moon and a tiny twinkling star beside them, soft and sleepy] | [skill-harmony.png]
```

## Then

1. Send the five pictures back to be checked (style match, no look-alikes or logos).
2. Upload each one to Roblox as an image (Creator Hub > Creations > Development Items > Images, or Studio's Asset Manager > Bulk Import).
3. Send the five IDs. They go in `Config.UI_ICONS`.
