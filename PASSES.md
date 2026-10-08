# Game Passes for the character skins (8 Oct)

Pictures (512 x 512, made from the skin art by `tools/make_pass_icons.py`,
checked): `art/roblox-store/passes/`. `_all.png` shows all eight together.

| # | Name (type exactly) | Picture | Price | Description |
|---|---|---|---|---|
| 1 | Pumpkin Patch Tinker | `pass-tinker-pumpkin.png` | 99 | A Halloween look for Tinker: pumpkin-orange overalls, a pumpkin beanie and his trusty goggles. Looks only - Tinker's skills stay the same. Wear it from Characters in the Lobby. |
| 2 | Ghostly Shadow | `pass-ghostly-shadow.png` | 99 | Shadow as a friendly ghost: a glowing pale hoodie with wavy ghost edges. Looks only - Shadow's skills stay the same. Wear it from Characters in the Lobby. |
| 3 | Candy Glow | `pass-candy-glow.png` | 99 | Glow in candy colours: a shiny pink raincoat with sweet buttons and a lollipop light. Looks only - Glow's skills stay the same. Wear it from Characters in the Lobby. |
| 4 | Space Cadet Brainy | `pass-space-cadet-brainy.png` | 99 | Brainy ready for space: a puffy space suit, moon boots and his propeller hat. Looks only - Brainy's skills stay the same. Wear it from Characters in the Lobby. |
| 5 | Snow Day Muscle | `pass-snow-day-muscle.png` | 99 | Muscle wrapped up for snow: a red puffer jacket, a bobble hat and a candy-cane scarf. Looks only - Muscle's skills stay the same. Wear it from Characters in the Lobby. |
| 6 | Starlight Echo | `pass-starlight-echo.png` | 99 | Echo under the stars: a starry jacket, star headphones and a moon backpack. Looks only - Echo's skills stay the same. Wear it from Characters in the Lobby. |
| 7 | Autumn Leaf Bramble | `pass-autumn-leaf-bramble.png` | 99 | Bramble in autumn colours: a cape of red and golden leaves and an acorn crown. Looks only - Bramble's skills stay the same. Wear it from Characters in the Lobby. |
| 8 | Halloween Nurse Patch | `pass-halloween-nurse-patch.png` | 99 | Patch on Halloween night: black scrubs, pumpkin trainers and a pumpkin bag. Looks only - Patch's skills stay the same. Wear it from Characters in the Lobby. |

## Pass ids so far

| Skin | Pass id |
|---|---|
| Pumpkin Patch Tinker | 2019380267 (checked: 99 Robux, for sale) |

## Managed pricing: OFF (8 Oct)

Creator Hub's **Managed pricing** lets Roblox test different prices on small
groups of players and lower prices in poorer regions. We keep it **off** for
now: friends in a party would see different prices for the same skin, and the
Lobby's Skill Reset button shows the product's set price. Look again after a
month of sales.

## Steps (for each pass)

1. **create.roblox.com** -> **Creations** -> **Escape Crew**.
2. Left menu: **Monetization** -> **Passes** -> **Create a Pass**.
3. Upload the picture from the table, type the Name and Description
   exactly -> **Create Pass**.
4. Click the new pass -> **Sales** (left) -> switch **Item for Sale** on ->
   Price **99** -> leave **Managed pricing** OFF -> **Save Changes**.
5. Back on the Passes list: **...** on the pass -> **Copy Asset ID**.
6. Send me the 8 ids as "Name: id". I put each in `Config.SKINS` (`pass = id`),
   and the skins appear for sale in the live game after you publish.

If a screen looks different, send me a photo.

## Real money: Developer Exchange (DevEx)

- When a player buys a pass for 99 Robux, the experience's owner gets about
  **70%** (69 Robux); Roblox keeps the rest. These are "Earned Robux".
- **DevEx** turns Earned Robux into real money: **$0.0038 per Earned Robux**
  (30,000 Robux = **$114**). Since 5 Sept 2025, some purchases by verified
  US players aged 18+ pay **$0.0054** per Robux. Robux earned before 5 Sept
  2025 pay $0.0035.
- **To cash out:** at least **30,000 Earned Robux**; the account owner at
  least **13**; a **verified email**; a tax form (**W-9** for a US taxpayer,
  W-8 otherwise); the account in good standing.
- **How:** Creator Hub -> **Finances** -> **Cash Out** -> the Developer
  Exchange form. Payment takes about 10 business days the first time, 5 after.
- Bought Robux (not earned) cannot be cashed out. Premium players also earn
  the game "engagement payouts" (Robux for time spent in it), which count
  as Earned Robux too.

Source: create.roblox.com/docs/production/monetization/developer-exchange (8 Oct 2026).
