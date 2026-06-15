# Grow a Garden 2 — Module Documentation

**PlaceId:** `97598239454123`  
**File:** `modules/games/growagarden2.lua`

---

## Features Overview

### Farming
| Feature | Description | Remote / Method |
|---|---|---|
| **Auto Collect + Sell** | Collects all fruits then sells in one cycle | `Garden.CollectFruit` + `NPCS.SellAll` |
| **Auto Collect Only** | Collects all ripe fruits from your garden | `Garden.CollectFruit(plantId, fruitId)` |
| **Auto Sell Only** | Sells all inventory every 1 second | `NPCS.SellAll:Fire()` |
| **Auto Seed Event** | Hunts falling rainbow/gold/event seeds | Teleport + ProximityPrompt/ClickDetector |

### Shop
| Feature | Description | Remote |
|---|---|---|
| **Auto Buy Selected Seeds** | Cycles through selected seeds, buying one per tick | `SeedShop.PurchaseSeed:Fire(seedName)` |
| **Auto Buy ALL Seeds** | Fires all seed purchases every 2 seconds | `SeedShop.PurchaseSeed:Fire(seedName)` |
| **Auto Buy Selected Gear** | Cycles through selected gear | `GearShop.PurchaseGear:Fire(gearName)` |

### PvP / Steal
| Feature | Description | Remote / Method |
|---|---|---|
| **Auto Steal** | Teleports to other gardens, collects their fruits | `Garden.CollectFruit` + `Steal.BeginSteal/CompleteSteal` |
| **Auto Fling** | Pushes nearby players with velocity force | `AssemblyLinearVelocity` manipulation |
| **Anti Fling** | Detects velocity spikes, restores safe position | External module (`modules/player/antifling.lua`) |

### Visual
| Feature | Description |
|---|---|
| **Plant ESP** | BillboardGui showing plant name, mutation, growth progress, fruit count, and price |

### Player (sidebar)
| Feature | Description |
|---|---|
| Speed Hack | Walk speed + jump power override |
| Infinite Jump | Unlimited mid-air jumps |
| Anti-AFK | Prevents idle kick |
| Fly | Free flight with configurable speed + F keybind |

### Utility
| Feature | Description |
|---|---|
| Rejoin Server | Reconnects to same server |
| Server Hop | Teleports to random different server |

---

## Data Model

### Garden Structure
```
workspace
└── Gardens
    ├── Plot1
    │   ├── Visual
    │   │   └── GardenZonePart (BasePart — defines plot bounds)
    │   ├── SpawnPoint (BasePart — player spawn location)
    │   └── Plants
    │       ├── 8661400981_9c31e22b-... (Model — Apple plant)
    │       │   ├── [Attributes] PlantId, SeedName, UserId, Age, MaxAge, ...
    │       │   └── Fruits (Folder)
    │       │       ├── Model (fruit 1) — [FruitId, PlantId, Age, MaxAge, SizeMulti, ...]
    │       │       ├── Model (fruit 2)
    │       │       └── ...
    │       └── ... (more plants)
    ├── Plot2
    └── ...
```

### Plant Attributes (on plant Model)
| Attribute | Type | Description |
|---|---|---|
| `PlantId` | string (UUID) | Unique plant identifier |
| `UserId` | number | Owner's Roblox UserId |
| `SeedName` | string | Plant type (e.g., "Apple", "Corn", "Tomato") |
| `PlantType` | string | Usually "Plant" |
| `Age` | number | Current growth age |
| `MaxAge` | number | Maximum age before harvest |
| `PlantGrowthReady` | boolean | Whether plant is fully grown |
| `MaxFruits` | number | Maximum fruit capacity |
| `PlantedAt` | number | Timestamp when planted |
| `Height` | number | Plant height |
| `GrowRateMulti` | number | Growth rate multiplier |
| `LastGenerated` | number | Last generation timestamp |
| `IgnoreFruitDistance` | boolean | Whether fruit distance check is skipped |
| `playedSfx` | boolean | Whether growth sound played |
| `Mutation` | string | Optional mutation type (e.g., "Rainbow", "Golden") |

### Fruit Attributes (on fruit Model inside Fruits folder)
| Attribute | Type | Description |
|---|---|---|
| `FruitId` | string (UUID) | Unique fruit identifier |
| `PlantId` | string (UUID) | Parent plant's ID |
| `UserId` | number | Owner's UserId |
| `CorePartName` | string | Fruit type name (e.g., "Apple") |
| `Age` | number | Current fruit age |
| `MaxAge` | number | Max age (ripe when Age >= MaxAge) |
| `SizeMulti` | number | Size multiplier (affects weight/price) |
| `GrowRateMulti` | number | Growth rate multiplier |
| `LastGenerated` | number | Last generation timestamp |
| `SkipRotation` | boolean | Whether fruit rotation is skipped |
| `Mutation` | string | Optional mutation type |

---

## Remote Calls (Networking Module)

Loaded via: `require(game.ReplicatedStorage.SharedModules.Networking)`

| Category | Remote | Type | Arguments | Usage |
|---|---|---|---|---|
| `Garden` | `CollectFruit` | RemoteEvent | `(plantId: string, fruitId: string)` | Collect a specific fruit. Empty `fruitId` = collect all |
| `NPCS` | `SellAll` | RemoteEvent | `()` | Sell entire inventory |
| `SeedShop` | `PurchaseSeed` | RemoteEvent | `(seedName: string)` | Buy a seed by name |
| `GearShop` | `PurchaseGear` | RemoteEvent | `(gearName: string)` | Buy gear by name |
| `Steal` | `BeginSteal` | RemoteEvent | `(plant: Model)` | Initiate steal on foreign plant |
| `Steal` | `CompleteSteal` | RemoteEvent | `(plant: Model)` | Complete steal on foreign plant |
| `Steal` | `CancelSteal` | RemoteEvent | — | Cancel ongoing steal |

### Remote Call Pattern
```lua
-- Collect fruit (own garden)
net.Garden.CollectFruit:Fire(plantId, fruitId)

-- Collect all fruits from a plant
net.Garden.CollectFruit:Fire(plantId, "")

-- Steal from other garden (requires teleport + plant Model)
net.Steal.BeginSteal:Fire(plantModel)
net.Steal.CompleteSteal:Fire(plantModel)
```

---

## Architecture

### Module Pattern
```lua
local GAG = {}
GAG.Name = "Grow a Garden 2"
GAG.PlaceIds = { 97598239454123 }
GAG.Enabled = false

function GAG:Init()        -- Load Networking module, seed/gear names
function GAG:Enable()      -- Set Enabled = true
function GAG:Disable()     -- Reset all states, disconnect all connections
function GAG:WireUI(tab, extras)  -- Build UI toggles/buttons/sliders

return GAG
```

### Connection Management
Each feature uses a named connection key in the `connections` table:
```lua
connections.collect    -- Auto Collect
connections.sell       -- Auto Sell
connections.buy        -- Auto Buy Seed
connections.buyall     -- Auto Buy All
connections.buygear    -- Auto Buy Gear
connections.steal      -- Auto Steal
connections.fling      -- Auto Fling
connections.seedevent  -- Auto Seed Event (scanner)
connections.seedwatcher -- Auto Seed Event (ChildAdded watcher)
connections.priceesp   -- Plant ESP
```

### Plot Detection
1. **Primary:** Match plot name against `lp.Name` or `lp.UserId`
2. **Fallback:** Find closest plot by `GardenZonePart` distance
3. **Caching:** Owner plot is cached after first detection (`cachedOwnerPlot`)

### Garden Bounds (for steal exclusion)
- Detects closest `GardenZonePart` and stores `{minX, maxX, minZ, maxZ}` with 20-stud padding
- `isInGarden(pos)` checks if position falls within own garden bounds
- Used by Auto Steal to skip own garden plants

---

## UI Layout

```
┌─ Farming ─────────────────────────────┐
│  [Toggle] Auto Collect + Sell         │
│  [Toggle] Auto Collect Only           │
│  [Toggle] Auto Sell Only              │
│  [Toggle] Auto Seed Event             │
├─ Shop ────────────────────────────────┤
│  [Dropdown] Select Seeds (Multi)      │
│  [Toggle] Auto Buy Selected Seeds     │
│  [Toggle] Auto Buy ALL Seeds          │
│  [Dropdown] Select Gear (Multi)       │
│  [Toggle] Auto Buy Selected Gear      │
├─ PvP / Steal ─────────────────────────┤
│  [Toggle] Auto Steal (Other Gardens)  │
│  [Toggle] Auto Fling (Push Players)   │
│  [Slider] Fling Radius (5-50)         │
│  [Toggle] Anti Fling                  │
├─ Visual ──────────────────────────────┤
│  [Toggle] Plant ESP (Labels + Info)   │
├─ Player Sidebar ──────────────────────┤
│  Movement: Speed, Jump, InfJump, AFK  │
│  Flight: Fly toggle, Speed, F keybind │
├─ Utility ─────────────────────────────┤
│  [Button] Rejoin Server               │
│  [Button] Server Hop                  │
└───────────────────────────────────────┘
```

---

## Known Limitations

| Issue | Detail |
|---|---|
| **Dropdown single-item** | WindUI bug: dropdown list doesn't auto-close when only 1 item remains. Report to WindUI maintainer |
| **Garden Lock** | No lock/toggle remote exists in the Networking module — cannot automate |
| **Steal conditions** | Stealing may require specific game states (nighttime, blood moon) |
| **Plot ownership** | Fallback uses closest plot — may target wrong plot if player is far from own garden |
| **Seed names** | Dynamically loaded from `ReplicatedStorage.Assets.Plants` — may change with game updates |
| **Gear names** | Loaded from `WateringCans`, `Sprinklers` folders + hardcoded tool list |
| **Fruit prices** | Price lookup attempts multiple sources; may not find prices if game stores them differently |

---

## Changelog

| Date | Change |
|---|---|
| Latest | Added fruit price display in ESP (looks up from plant assets, cached for performance) |
| Recent | Added Auto Collect+Sell combined mode, cached plot detection, cleaned UI layout |
| Previous | Fixed FruitId resolution (reads from `plant.Fruits` folder, not plant model) |
| Previous | Added Auto Steal with 3-method approach (remote + prompt + steal remotes) |
| Previous | Added Auto Fling (velocity push), Anti Fling, Infinite Jump, Anti-AFK |
| Previous | Added Plant ESP with SeedName + Mutation + growth display |
| Previous | Added Auto Seed Event for rainbow/gold falling seeds |
| Previous | Initial: Auto Sell, Auto Buy Seed, Auto Buy Gear |
