# April

Fallen Survival script for [Project Vector](https://project-vector-1.gitbook.io/vector-lua-engine/).

**`april.lua`** is the final script — one file, load it in Vector and you're done.

---

## Load in Vector

1. Download or clone this repo.
2. In Vector's script editor, click **Open Folder** and copy `april.lua` into your Scripts folder (or load it from anywhere).
3. **Load Script** → `april.lua` → **Execute Script**.

All options appear under the **April** tab in the Scripts panel, organized in this sidebar order:

1. **Aimbot** — targeting, FOV, smoothing, prediction, target line  
2. **Visuals** — crosshair, player ESP, hitmarkers  
3. **World** — resource nodes, plants, animals (per-type toggles + colors)  
4. **Recoil Control** — global + per-weapon overrides  
5. **Waypoints** — 5 waypoint slots  
6. **Loot** — crates, sleepers, care packages (per-type toggles)  
7. **NPCs** — soldiers, box modes, offscreen arrows  
8. **Base** — cabinets, doors, turrets, sleeping bags  
9. **Tactical Map** — minimap shell with zoom/colors  
10. **Misc** — noclip, omnisprint, spider climb, ESP text size  
11. **Config** — save/load slots, debug overlay  

Click a group name on the left to see its options on the right.

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
