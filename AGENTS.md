# April Fallen — Agent Guide (Vector / Fallen Survival)

Read this at the start of every session.

## What this project is

**April Fallen** is a **Project Vector** external script for **Fallen Survival** (Roblox place `13800717766`).

| Artifact | Purpose |
|----------|---------|
| `src/` | Modular source (edit here) |
| `scripts/bundle.mjs` | Bundles `src/` → `april.lua` |
| `load.lua` | Local-first loader, then GitHub URL |
| `dump/` | Game dump (gitignored — local only) |
| `tools/` | GC / rbxlx utilities (local workspace) |
| `docs/API.md` | Vector Lua Engine API — read every session |
| `src/ui/` | Gamesense custom UI (wired to features via `menu_shim`) |

**Build:** `npm run build`

**Custom UI:** Main script uses the Gamesense menu only (no Vector April tabs). Toggle with **INSERT**. Feature `register_menu()` still runs but writes into `gs_state` through `ui/menu_shim.lua`.

**GitHub:** [Cunzaki/April](https://github.com/Cunzaki/April)

---

## Mandatory: read `docs/API.md` every session

Before draw, menu, entity, camera, input, or image work — read the relevant section of `docs/API.md`.

Key rules: draw only in `on_frame`, `menu.get(id)` every frame, one HTTPS URL per image, no WalkSpeed writes on Fallen.

---

## Dump (`dump/`)

Verify folder paths, instance names, remotes, and item image fields against the dump.

| File | Use |
|------|-----|
| `GAME_REFERENCE.txt` | Workspace / ReplicatedStorage layout |
| `scripts/ReplicatedStorage.Modules.Items.ModuleScript.lua` | Item names + image asset IDs |

---

## Version bump

After meaningful changes: bump version in `scripts/bundle.mjs`, rebuild.
