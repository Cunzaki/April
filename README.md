# April

Fallen Survival script for [Project Vector](https://project-vector-1.gitbook.io/vector-lua-engine/).

**`april.lua`** is the final script — one file, load it in Vector and you're done.

---

## Load in Vector

1. Download or clone this repo.
2. In Vector's script editor, click **Open Folder** and copy `april.lua` into your Scripts folder (or load it from anywhere).
3. **Load Script** → `april.lua` → **Execute Script**.

All options live on **Vector's top menu bar** (horizontal tabs), not stacked in Scripts/April:

| Top tab | What's there |
|---------|----------------|
| **Aimbot** | Aimbot + Recoil Control groups |
| **Player ESP** | Player ESP settings |
| **Crosshair** | Crosshair settings |
| **Visuals** | Hitmarkers |
| **World** | Resources, Loot, NPCs, Base |
| **Features** | Waypoints, Tactical Map, Movement |
| **Settings** | Config save/load |
| **Scripts → April** | Loader info only |

Click **Player ESP** or **Crosshair** in the top bar for those settings.

Config files save to `%LOCALAPPDATA%\Project Vector\Scripts\April_Slot_1.txt`.

---

## Development

Source modules are in `src/`. After editing, rebuild the final script:

```bash
npm run build
# or: node scripts/bundle.mjs
```

Commit both `src/` changes and the updated `april.lua`.

See [docs/LEGACY_FEATURES.md](docs/LEGACY_FEATURES.md) for parity notes vs the original monolith.

---

## Repo layout

```
april.lua          ← load this in Vector (generated, do not edit by hand)
src/               ← modular source
scripts/bundle.mjs ← build script
docs/              ← notes and feature tracking
```
