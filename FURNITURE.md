# Furniture for the Party House

The game places furniture by itself: put each model in the **Party House**
place under **ServerStorage -> Props**, named exactly as below, and it appears
in its room, sized to fit, standing on the floor (or hanging from the ceiling),
solid so you walk round it, and with any scripts stripped out. Anything not
there yet is simply skipped, so add them a few at a time.

## How to add one (Roblox's free Creator Store)

1. In Studio (Party House place): **Window -> Toolbox** (or the Toolbox button).
2. Choose **Creator Store** -> **Models**, and type the search words below.
3. Pick one that looks realistic and is not huge (fewer parts is better).
   Ticks for **verified creators** and high ratings are safer choices.
4. Click it: it drops into the world. In the **Explorer**, find it under
   **Workspace**, and drag it into **ServerStorage -> Props** (create the
   **Props** folder the first time: right-click ServerStorage -> Insert Object
   -> Folder).
5. Rename it exactly as in the **Name** column. Press Play to see it placed.

Models in ServerStorage never run any code, and the game strips scripts from
them as it places them, so a free model cannot do anything sneaky.

## The list (one of each name; the game reuses it where it appears twice)

| Name (exact) | Room(s) | Search words | Notes |
|---|---|---|---|
| **Fireplace** | Parlour | victorian fireplace | the centrepiece of the Parlour |
| **Armchair** | Parlour | victorian armchair | |
| **GrandfatherClock** | Parlour | grandfather clock | tall and creepy |
| **Rug** | Parlour, Corridor | persian rug | flat; you walk on it |
| **SideTable** | Parlour | antique side table | |
| **Chandelier** | Parlour, Front Hall | chandelier candles | hangs from the ceiling |
| **Bench** | Corridor | wooden bench antique | |
| **PottedPlant** | Corridor | potted plant large | |
| **Desk** | Library | antique desk | |
| **DeskChair** | Library | wooden desk chair | |
| **Globe** | Library | antique globe | |
| **FloorLamp** | Library | floor lamp vintage | |
| **Fridge** | Kitchen | old fridge | |
| **Stove** | Kitchen | vintage stove | |
| **KitchenTable** | Kitchen | wooden kitchen table | |
| **DiningChair** | Kitchen, Front Hall | dining chair wooden | six of them in all |
| **CoatRack** | Front Hall | coat rack | |
| **Pumpkin** | Front Hall | halloween pumpkin | |
| **ArcadeMachine** | Game Room | arcade machine | |
| **BallPit** | Game Room | ball pit | |
| **PoolTable** | Game Room | pool table | |
| **BeanBag** | Game Room | bean bag | |
| **DiscoBall** | Game Room | disco ball | hangs from the ceiling |

## Signature pieces from Meshy (later)

These must match your room pictures, so they are worth making in Meshy from
crops of `art/sheets/room-party-*.png`: the **party table with the cake**, the
**wardrobe**, the **cage**, the **fireplace** (if the store has none you like).
Import them like the characters (File -> Import), skip Avatar Setup, and drop
them into ServerStorage -> Props with the name above.

## Room set pieces (every building) - optional upgrades

Every room is already dressed by `roblox/src/game/server/Rooms.luau` with
set pieces built from parts (a boiler with pipes, moving conveyor belts, a
vault door, an ambulance...). Each one is replaced by a real model if
**ServerStorage -> Props** holds a model with exactly its **Name**: same
steps as above (Toolbox -> Creator Store -> Models). These are scenery: they
are fitted into the size shown, stand on the floor, and are never solid.

| Name | Rooms | Search words | Fits in (studs, w x h x d) |
|---|---|---|---|
| Boiler | Boiler Room | old boiler, industrial boiler | 6 x 9 x 6 |
| Generator | Generator Room | generator, diesel generator | 6 x 5 x 4 |
| WaterTank | Water Tank Room | water tank, metal tank | 6 x 9 x 6 |
| Conveyor | Conveyor Hall, Factory Floor, Wrapper Room | conveyor belt | 8 x 4 x 3 |
| CandyMachine | Conveyor Hall, Taste Lab, Gumball Store, Candy Kitchen | candy machine, cotton candy machine | 4 x 7 x 4 |
| TaffyPuller | Taffy Hall | taffy machine, candy factory machine | 5 x 7 x 4 |
| GummyBear | Bear Gallery, Gummy Lobby, Ball Pit | gummy bear | 4 x 7 x 4 |
| Lollipop | Lollipop Garden, Sprinkle Room, Slide Tower | giant lollipop | 4 x 9 x 2 |
| VaultDoor | Vault Door Hall | bank vault door | 8 x 9 x 1 |
| Ambulance | Ambulance Bay | ambulance | 8 x 7 x 14 |
| XRay | X-Ray Room | x-ray machine, hospital scanner | 6 x 8 x 5 |
| WashingMachines | Laundry, Linen Room | washing machine | 8 x 4 x 3 |
| Sofa | Day Room, Quiet Room, Staff Room | sofa, couch | 7 x 4 x 3 |
| TV | Day Room, Waiting Room | old tv, retro tv | 4 x 5 x 2 |
| LiftDoors | Lift Lobby, hospital stairwells | elevator doors | 6 x 9 x 1 |
| Fireplace | Parlour, Library | fireplace | 6 x 7 x 2 |
| Arcade | Game Room | arcade machine | 3 x 7 x 3 |
| Stove | Kitchen, Candy Kitchen | stove, old stove | 6 x 6 x 3 |
| Lockers | Locker Room | lockers | 6 x 8 x 2 |
| Wardrobe | bedrooms, nurseries | wardrobe | 4 x 8 x 2 |

Check each model before keeping it: no brand logos or known characters (the
game is public). Send Claude a screenshot if unsure.
