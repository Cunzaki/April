# April

Fallen Survival script for [Project Vector](https://project-vector-1.gitbook.io/vector-lua-engine/).

**`april.lua`** is the final script — one file, load it in Vector and you're done.

---

## Load in Vector

1. Download or clone this repo.
2. In Vector's script editor, click **Open Folder** and copy `april.lua` into your Scripts folder (or load it from anywhere).
3. **Load Script** → `april.lua` → **Execute Script**.

You should see `[April v3] Ready — 3.0.0` in the console. Open the **April** tab under Scripts for all options.

---

## What's inside

| Group | Features |
|-------|----------|
| Aimbot / Recoil | Aim assist, recoil control |
| Players / Crosshair / Feedback | ESP, crosshair, hitmarkers |
| Resources / Loot / Base / NPCs | World ESP |
| Exploits | Noclip, omnisprint |
| Waypoints / Map | Radar tools |
| Config / Debug | Save/load settings |

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
