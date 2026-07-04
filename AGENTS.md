# April — Agent Guide (Vector / Fallen Survival)

This file is the **source of truth for AI agents** working on April v3. Read it at the start of every session.

## What this project is

**April** is a **Project Vector** external script for **Fallen Survival** (Roblox place `13800717766`). It runs in Vector's Lua VM against the live game process — not inside Roblox Studio.

| Artifact | Purpose |
|----------|---------|
| `April/src/` | Modular source (edit here) |
| `April/scripts/bundle.mjs` | Bundles `src/` → `April/april.lua` |
| `April/Script 1.lua` | Vector load file (sync from `april.lua` after build) |
| `fallen_legacy.lua` | Previous monolith — reference for behavior & features |
| `April/references/dump/` | Game instance/module dumps — **verify paths & asset IDs here** |

**Build:** `node April/scripts/bundle.mjs` then copy `april.lua` → `Script 1.lua`.

---

## Mandatory: read `April/docs/API.md` every session

**Before any draw, menu, entity, camera, input, image, or memory work — open and read the relevant section of `April/docs/API.md`.** Do not rely on memory alone; the API has non-obvious rules that break features if ignored.

### API rules agents must follow

| Topic | Rule (from API.md) |
|-------|---------------------|
| Drawing | All `draw.*` calls only inside `on_frame` |
| Menu | `menu.get(id)` every frame — never cache toggle state |
| Images | `draw.load_image(url)` is async; only `draw.image` after `draw.image_loaded` |
| Image URLs | **Prefer direct HTTPS** (`raw.githubusercontent.com/...`). `rbxassetid://` is fallback only |
| Image init | Call `draw.load_image` from `on_frame` (via `image_cache.tick`), not at script load |
| Player ESP | `p:get_bounds()` for boxes; `p.head_position` for world labels |
| Fallen AC | **Do not write `WalkSpeed`** — use velocity/root movement |
| Gun mods | `refreshgc` / `getgc` / `applygc` only |

When adding or fixing visuals, **re-read the Images section** in API.md (`draw.load_image`, `draw.image_loaded`, `draw.image_failed`).

---

## Image assets (GitHub CDN)

Roblox `rbxassetid://` and thumbnail URLs often **fail inside Vector**. April hosts item/decal PNGs on GitHub and loads them via HTTPS.

| Path | Purpose |
|------|---------|
| `assets/manifest.json` | All asset IDs from dump (+ tung) |
| `assets/items/{id}.png` | Item icons (420×420) |
| `assets/tung.png` | Tung ESP decal [139818999438291](https://create.roblox.com/store/asset/139818999438291/tung-tung-tung-sahur) |
| `src/game/item_images.lua` | Generated `Name → assetId` map from dump |
| `src/game/asset_urls.lua` | CDN base URL + URL builders |
| `src/core/image_cache.lua` | Lazy load in `on_frame`, GitHub URL first |

**Regenerate after dump updates:**
```bash
npm run extract-images    # dump → item_images.lua + manifest
npm run download-assets   # Roblox Thumbnails API → PNG files
# commit assets/ to GitHub, then npm run build
```

Asset IDs come from `references/dump/scripts/ReplicatedStorage.Modules.Items.ModuleScript.lua` (`Image = "rbxassetid://..."` or `Image = { Default = ... }`).

---

## Mandatory: `April/references/dump/`

Verify folder paths, instance names, remotes, and **item Image fields** against the dump — not guesses.

| File | Use |
|------|-----|
| `GAME_REFERENCE.txt` | Workspace / ReplicatedStorage layout |
| `instances.jsonl` | Search ESP targets by name/path |
| `scripts/ReplicatedStorage.Modules.Items.ModuleScript.lua` | Item names + image asset IDs |
| `modules.txt` + `scripts/` | ToolInfo, controllers |

---

## Architecture (v3)

```
app.lua          → on_frame hook, dt
menu/tabs.lua    → feature order, scheduler, image_cache.tick_all
src/core/        → settings, env, draw_util, image_cache
src/game/        → asset_urls, item_images, items, weapons, armor_map
src/features/    → combat, visuals, world, movement, radar, utility
```

**Images:** `image_cache.ensure(key, url)` → `tick_all()` each frame → `draw_fit` only when `ready`.

**Bundle order:** `game/asset_urls.lua` and `game/item_images.lua` must load before `core/image_cache.lua` and `game/items.lua`.

---

## Implementation rules

1. Edit `src/`, rebuild, sync `Script 1.lua`.
2. **Check API.md** before implementing draw/menu/image behavior.
3. New item icons: extract from dump → download PNG → push to GitHub → rebuild.
4. Minimize scope; match existing module style.
5. Avoid WalkSpeed writes on Fallen.

---

## Version bump

After meaningful changes: bump version in `scripts/bundle.mjs`, rebuild, sync `Script 1.lua`.
