# April Fallen — Agent Guide (Vector / Fallen Survival)

Read this at the start of every session.

## What this project is

**April Fallen** is a **Project Vector** external script for **Fallen Survival** (Roblox place `13800717766`).

| Artifact | Purpose |
|----------|---------|
| `src/` | Modular source (edit here) |
| `scripts/bundle.mjs` | Builds the single-file runtime (`april.lua` + `Script 1.lua`) and `load.lua` |
| `april.lua` | Full remote runtime (one file — no split chunks) |
| `load.lua` | Public one-line `utility.LoadUrl(...)` |
| `Script 1.lua` | Identical full local bundle for pre-release testing |
| `dump/` | Game dump (gitignored — local only) |
| `tools/` | GC / rbxlx utilities (local workspace) |
| `docs/API.md` | Vector Lua Engine API — read every session |
| `src/ui/` | Gamesense custom UI (wired to features via `menu_shim`) |

**Build:** `npm run build`

**Custom UI:** Main script uses the Gamesense menu only (no Vector April tabs). Toggle with **INSERT**. Feature `register_menu()` still runs but writes into `gs_state` through `ui/menu_shim.lua`. The startup intro loading screen still plays on boot.

**GitHub:** [Cunzaki/April](https://github.com/Cunzaki/April)

---

## Mandatory: read `docs/API.md` every session

Before draw, menu, entity, camera, input, or image work — read the relevant section of `docs/API.md`.

Key rules: draw only in `on_frame`, `menu.get(id)` every frame, one HTTPS URL per image, no WalkSpeed writes on Fallen.

---

## Dump (`dump/`)

Verify folder paths, instance names, remotes, and item image fields against the dump.

Regenerate after a place update:

```bash
npm run dump
# default: %LOCALAPPDATA%\Potassium\workspace\place 13800717766 Fallen Survival Large Server(1).rbxlx
```

| File | Use |
|------|-----|
| `GAME_REFERENCE.txt` | Workspace / ReplicatedStorage layout |
| `manifest.json` | PlaceVersion / executor / counts |
| `scripts/ReplicatedStorage.Modules.Items.ModuleScript.lua` | Item names + image asset IDs |
| `RE/PLACE_806_UPDATE.md` | Latest redump notes (AttackHeli, visual fix) |

---

## Version bump

After meaningful changes: bump version in `scripts/bundle.mjs`, rebuild.

## Mandatory build and release workflow

- Edit modular files under `src/`; do not hand-edit generated Lua artifacts.
- Every build must generate the complete standalone runtime at both `april.lua` and `Script 1.lua` (same contents).
- Test `Script 1.lua` before any release.
- Release artifacts (`april.lua`, `load.lua`, `Script 1.lua`, and `april_ui.lua`) must contain no Lua comments. The build scripts enforce this.
- Keep the public usage as one `utility.LoadUrl(...)` that pulls the full `april.lua` runtime (no split chunk loading).
- Do not commit or push after routine edits. Only commit and push when the user explicitly says to push.
- Before an approved push: bump the version, run the complete build, verify generated artifacts, then commit and push all required source and runtime changes together.
