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

## Part 2 - In Roblox Studio: make it a Roblox character (about 5 minutes each)

1. Open the **Escape Crew** place in Studio.
2. **File -> Import 3D** (or the **Import 3D** button) -> choose `host.fbx`.
3. In the importer:
   - **Rig type: R15** if it asks.
   - Check the preview faces you. If the character faces away, set
     **World Forward** to the opposite direction (Roblox wants the front facing
     -Z).
   - Press **Import**.
4. With the imported model selected, open **Avatar** tab -> **Avatar Setup**
   (or right-click the model -> **Avatar Setup**). Let it run: it adds the R15
   skeleton, skinning, face animation and splits the body into Roblox parts.
5. In the Avatar Setup preview, try a **walk** or **run** animation. If arms or
   legs bend wrongly, tell Claude what you see - a different pose (T instead of
   A) in Meshy usually fixes it.
6. **Finish / Add to Workspace.**
7. **Put it where the game will find it:**
   - In the Explorer, find **ServerStorage**. Right-click -> **Insert Object** ->
     **Folder**, and name the folder exactly **Characters**.
   - Drag the finished model into **ServerStorage -> Characters**.
   - Rename it exactly: **Host**, **Tinker**, **Shadow**, **Brainy**, **Muscle**,
     **Glow**, **Patch**, **Echo** or **Bramble**.
8. **File -> Save to Roblox** (Rojo never touches ServerStorage, so your
   models are safe).
9. Tell Claude which ones are in. Claude switches the game to use them: kids
   play as the chosen character instead of their avatar, and the pumpkin host
   becomes your model.

---

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
