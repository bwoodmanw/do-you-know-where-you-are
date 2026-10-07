# Character skins (B9) - art prompts and Creator Hub steps

The code is in and hidden: a skin appears in the Lobby's **Characters** screen
only once its Game Pass id is in `Config.SKINS` (`roblox/src/shared/Config.luau`).
In Studio every skin can be tried for free (`Config.SKINS_FREE_IN_STUDIO`).

How it works: a skin is a whole different 3D model of the same kid. The player
buys it once (a Game Pass), picks it under the character's skill ladder
(Characters -> the skin buttons), and from the next game their character uses
that model. Skins change looks only, never skills.

| Skin | Character | Model name (ServerStorage/Characters) | Suggested price |
|---|---|---|---|
| Pumpkin Patch Tinker | Tinker | `TinkerPumpkin` | 99 Robux |
| Ghostly Shadow | Shadow | `ShadowGhost` | 99 Robux |
| Candy Glow | Glow | `GlowCandy` | 99 Robux |
| Night Nurse Patch | Patch | `PatchNurse` | 99 Robux |

## 1. Make the art (same tool as the characters)

Attach the character's existing front picture from `art/model-input/<name>/a-pose-front.png`
as the reference image so the face, hair and body stay the same, then use the
prompt. Every prompt ends with the same pose/background line the originals used.

**Pumpkin Patch Tinker**
> The same boy as the reference picture, same face, freckles and messy brown hair. Halloween outfit: pumpkin-orange denim overalls with a green leaf-shaped patch on one knee, a dark green long-sleeved top, a soft orange knitted beanie with a short green stem on top, his brass goggles pushed up on the beanie, a brown tool belt with a small wrench and a little toy pumpkin hanging from it, green high-top trainers. Friendly smile. Stylised 3D animated-film look, full body, standing in an A-pose facing the camera, plain light grey background, soft even lighting, no text, no logos.

**Ghostly Shadow**
> The same child as the reference picture, same purple eyes and dark hair. Ghost costume: a loose pale lavender-white hoodie with soft wavy ragged hem and sleeve ends like a friendly ghost, a faint glow at the edges, the hood up, a grey cloth face mask, light grey cargo trousers, white trainers with lavender laces, fingerless grey gloves. Mysterious but friendly. Stylised 3D animated-film look, full body, standing in an A-pose facing the camera, plain light grey background, soft even lighting, no text, no logos.

**Candy Glow**
> The same girl as the reference picture, same curly brown hair bun, freckles and green eyes. Candy outfit: a see-through glowing raincoat in candy pink with small sweet-shaped buttons, a striped mint and white jumper, lilac trousers, glossy pink wellington boots, her glowing headband antenna now ends in a little glowing lollipop, a round candy-shaped lamp on her chest. Cheerful. Stylised 3D animated-film look, full body, standing in an A-pose facing the camera, plain light grey background, soft even lighting, no text, no logos.

**Night Nurse Patch**
> The same girl as the reference picture, same curly brown ponytail, plaster on her forehead and freckles. Night-time nurse outfit: a mint green nurse's tunic with a small pink heart on the pocket (no cross symbol), a navy cardigan over it, a little torch on a lanyard, navy trousers, white trainers with pink hearts, her pink first-aid shoulder bag. Kind and brave. Stylised 3D animated-film look, full body, standing in an A-pose facing the camera, plain light grey background, soft even lighting, no text, no logos.

(No red cross on Patch: the Red Cross emblem is protected and Roblox removes it.)

Save each as `art/model-input/<skin>/a-pose-front.png` (for example
`art/model-input/tinker-pumpkin/a-pose-front.png`) and tell me: I look at
every picture before it is used (resemblance to known characters, logos).

## 2. Make the 3D model (as in MESHY_GUIDE.md)

1. Meshy: Image to 3D with the front picture, the same settings as the
   characters (see `MESHY_GUIDE.md`), download the .glb.
2. Studio, **Party House** place: **Avatar** tab -> **Import 3D** -> choose the
   .glb -> Import -> **Avatar Setup** as for the characters.
3. In the **Explorer**, drag the model into **ServerStorage -> Characters** and
   rename it exactly as in the table (for example `TinkerPumpkin`).
4. Right-click it -> **Save to Roblox** -> copy the asset id and send it to me
   (it goes in `Config.CHARACTER_ASSETS` so the Lobby can show it in 3D).
5. If the face looks blotchy: **Plugins** tab -> **Escape Crew** -> **Soften
   Patch** with the model selected (Studio stopped).

## 3. Make the Game Pass (Creator Hub)

For each skin:
1. Go to **create.roblox.com** -> **Creations** -> **Escape Crew**.
2. In the left menu: **Monetization** -> **Passes** -> **Create a Pass**.
3. Upload a 512 x 512 picture (I can make it from the portrait once the art
   exists), Name: the skin's name (e.g. `Pumpkin Patch Tinker`), Description:
   `A Halloween look for Tinker. Looks only - skills stay the same.` ->
   **Create Pass**.
4. Click the new pass -> **Sales** (left) -> switch **Item for Sale** on ->
   Price **99** -> **Save Changes**.
5. Copy the pass id: on the Passes list, the **...** on the pass -> **Copy
   Asset ID**. Send it to me; it goes in `Config.SKINS` as `pass = <id>`.

If a screen looks different from these steps, send me a photo of it.

## 4. Test

- Studio, Lobby place, Play: Characters -> Tinker: a row "Skins: Plain,
  Pumpkin Patch Tinker" under the ladder (free in Studio). Choose it.
- Studio, Party House place, Play: choose Tinker - the pumpkin Tinker model.
- Live (after publishing): the skin button says "(R$)" and opens Roblox's
  purchase window; after buying it says it is yours and is worn next game.
