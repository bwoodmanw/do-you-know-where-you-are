# Making the Escape Crew characters in 3D (Meshy -> Roblox)

Turns each character sheet into a real 3D character that kids play as in
Roblox. Do the **host first** (one model), test it in the game, then the 7 kids.
Tinker waits for its sheet.

**What you need:** a Meshy account (meshy.ai - the paid plan, about $20 a
month; check the plan's licence lets you use models in your own game and keeps
them private), Roblox Studio, and the pictures in `art/model-input/`:

```
art/model-input/
  host/     1-front.png  2-three-quarter.png  3-side.png  4-back.png
  shadow/   brainy/  muscle/  glow/  patch/  echo/  bramble/   (same four each)
```

Meshy's menus change names now and then. If a setting below is not where this
says, look under **Advanced** or **Settings** in the same panel.

---

## Part 0 - A big, sharp picture first (fixes soft faces)

Meshy cannot add detail that is not in the picture. Glow's inputs were only
about 485 x 821 pixels, so her face came out soft. For each character, make one
large front picture in ChatGPT (**portrait / tall**), attaching the character's
sheet from `art/sheets/`:

> Use the attached character sheet as the exact reference. One single
> full-body image of this same character, front view, standing in an A-pose
> (arms angled down and away from the body, legs slightly apart), centred and
> filling the whole height of the image, plain flat light-grey background,
> even soft studio lighting with no strong shadows, very sharp and detailed
> face with clear eyes, same stylised 3D render style, same outfit and colours.
> No text, no other characters.

Save it as `art/model-input/<name>/front-hd.png` and give Meshy that one
picture first (add side and back views only if the back comes out wrong).
In Meshy choose the **highest texture quality** offered and **PBR on**.

## Part 1 - In Meshy: make the model (about 5 minutes each)

1. Sign in at **meshy.ai** -> **Workspace** -> **Image to 3D**.
2. **Upload the pictures.** If it offers **Multi-image** (several views of one
   object), upload all four from the character's folder: front, three-quarter,
   side, back. If it only takes one, use **1-front.png**.
3. **Settings before you press Generate:**

   | Setting | Choose | Why |
   |---|---|---|
   | AI model | the newest one offered (e.g. Meshy 6) | best quality |
   | **Pose** | **A-Pose** (or T-Pose) | Roblox needs arms away from the body to rig it |
   | **Topology** | **Triangle** | Roblox counts triangles |
   | **Target polycount** | **10,000** | Roblox's limit for a whole character is 10,742 triangles |
   | Symmetry | **On / Auto** | cleaner left and right sides |
   | Texture | **On** (with PBR if offered) | Roblox needs at least one texture |

4. Press **Generate**. Look at it from all sides (drag to spin it):
   - Does it look like the sheet? Is the face right? Are there holes or blobs?
   - If not, **Regenerate** (another try costs credits) rather than fixing by hand.
5. **Do NOT use Auto-Rig, Rigging or Animate.** Roblox does the rigging itself,
   and Meshy's skeleton is not the one Roblox needs. It saves credits too.
6. If the polycount came out higher than 10,000: use **Remesh** with
   **Target polycount 10,000** and **Triangle** topology.
7. **Download** -> format **FBX** (or **GLB** if FBX is not offered), with
   **textures included**. Save it as e.g. `host.fbx`, and put it in
   `art/models/` in the game folder (create the folder).

---

## Part 2 - In Roblox Studio: make it a Roblox character (how Glow was done)

1. Open the **Party House** place (the window title must say Party House):
   **File -> Open from Roblox -> Escape Crew -> Party House**, or Creator Hub
   -> Escape Crew -> Places -> **...** next to Party House -> **Edit in Studio**.
2. **File -> Import** -> choose the `.glb` from `art/models/`.
3. In the 3D Importer: **Rig Type: No Rig** (if it can be changed - Avatar
   Setup adds the skeleton). If the preview shows the back, change **World
   Forward** until the face looks at you. **Add to Workspace: on** -> **Import**.
4. Select the model in the **Explorer** -> **Avatar** tab -> **Avatar Setup**
   (if there is no Avatar tab, search "Avatar Setup" in Studio's search box).
   If it asks what it is, choose **Body**. Let it run; preview a walk.
5. It may report **"4 Warnings"** about the dynamic head (frown, eyes,
   mouth). Those only matter for selling on the Avatar Marketplace - click
   **OK** and ignore them. ("Model resized to ...%" is fine too.)
6. Finish so the character is added to the Workspace. In the Explorer, the
   **right** copy contains **Humanoid, HumanoidRootPart, Head, UpperTorso...**
   (about 15 parts). **Delete** the original imported copy (a single mesh).
7. **ServerStorage -> Characters** (create the folder once: right-click
   ServerStorage -> Insert Object -> Folder -> name it `Characters`). Drag the
   finished character in and rename it exactly: `Host`, `Tinker`, `Shadow`,
   `Brainy`, `Muscle`, `Glow`, `Patch`, `Echo` or `Bramble`.
8. **File -> Publish to Roblox.** Test with **Play**: pick the character (or
   wait for the host) and check it walks and runs. **F9** shows errors.

Never publish a `.rbxlx` file over the Party House after this - it would wipe
ServerStorage. Code updates go in with Rojo (`roblox/README.md`).

## Order of work

| Step | Who | What |
|---|---|---|
| 1 | Brent | **Host** in Meshy, then into Studio as ServerStorage/Characters/Host |
| 2 | Claude | Game uses the host model (scaled to twice a kid's height) |
| 3 | Brent | One kid (e.g. **Brainy**) |
| 4 | Claude | Kids play as their character; test walking, running, hiding, the cage |
| 5 | Brent | The other 5 kids, then Tinker once its sheet exists |
| 6 | Claude | Wardrobe shop and customisation on top of these characters |

## If something goes wrong

- **Too many triangles** in Avatar Setup -> Remesh in Meshy to 8,000 and try again.
- **Arms fused to the body** -> regenerate in Meshy with **T-Pose**.
- **Character is tiny or huge** -> fine; the game scales it.
- **Looks nothing like the sheet** -> try front picture only, or a different
  Meshy model version.


## Part 5 - Show a character in the Lobby (Save to Roblox)

The Lobby cannot see the Party House's ServerStorage, so each finished
character is saved to Roblox once and both places load it by its id
(`Config.CHARACTER_ASSETS`, loaded by `shared/CharacterAssets.luau`).

1. In Studio, in the **Party House**, open **ServerStorage -> Characters**.
2. Right-click the character (e.g. **Glow**) -> **Save to Roblox...**
3. Choose **Create new asset**. Name: `Escape Crew - Glow`. Leave
   **Distribute on Creator Store** off. Creator: **Bwoodmanw**. Click **Save**.
4. Get its id: **Toolbox -> Inventory -> My Models**, right-click the model ->
   **Copy Asset ID** (or the number in its Creator Hub page address).
5. Send the ids to Claude (one per character, and the Host).

The Lobby's Characters screen then shows it in 3D (drag to turn), and the
Party House uses it for any character not imported there.
