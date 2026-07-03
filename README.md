# April

Fallen Survival script for [Project Vector](https://project-vector-1.gitbook.io/vector-lua-engine/).

**`april.lua`** is the final script — one file, load it in Vector and you're done.

---

## Load in Vector

1. Download or clone this repo.
2. In Vector's script editor, click **Open Folder** and copy `april.lua` into your Scripts folder (or load it from anywhere).
3. **Unload** any old April/Fallen script first.
4. **Load Script** → `april.lua` → **Execute Script**.

All options live under **Scripts → April** (not Vector's built-in Aimbot/Visuals tabs). The script uses `"full"` menu mode — sections appear in a **2-column grid** (left / right, then next row):

| Row | Left | Right |
|-----|------|-------|
| 1 | Aimbot | Player ESP |
| 2 | Crosshair | Hitmarkers |
| 3 | World | Recoil Control |
| 4 | Waypoints | Loot |
| 5 | NPCs | Base |
| 6 | Tactical Map | Movement |
| 7 | Config | |

Console should show: `[April] Menu groups registered: 13 (Scripts > April grid)` and `[April v3] Ready — 3.0.0`.

Config files save to `%LOCALAPPDATA%\Project Vector\Scripts\April_Slot_1.txt`.

---

## Rebuild from source

```bash
npm run build
# or: node scripts/bundle.mjs
```

Edit files in `src/`, then rebuild. Always execute the fresh `april.lua` — not an old copy like `Script 1.lua`.

---

## Source layout

```
src/
  core/       env, settings, menu_util, draw, scheduler
  game/       weapons, items, inventory
  features/   combat, visuals, world, movement, radar, utility
  menu/       tabs.lua — registration order
  app.lua     init + on_frame
```

---

## License

Use at your own risk. Not affiliated with Project Vector or Fallen Survival.
