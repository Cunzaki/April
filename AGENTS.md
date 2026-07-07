# April Fallen — Agent Guide (Vector / Fallen Survival)

This file is the **source of truth for AI agents** working on **April Fallen** (v3). Read it at the start of every session.

## What this project is

**April Fallen** is a **Project Vector** external script for **Fallen Survival** (Roblox place `13800717766`). It runs in Vector's Lua VM against the live game process — not inside Roblox Studio.

| Artifact | Purpose |
|----------|---------|
| `April Fallen/src/` | Modular source (edit here) |
| `April Fallen/scripts/bundle.mjs` | Bundles `src/` → `april.lua` |
| `April Fallen/Script 1.lua` | Vector load file (sync from `april.lua` after build) |
| `April Fallen/references/legacy/` | Previous monoliths & modular loaders — reference only |
| `April Fallen/references/dump/` | Game instance/module dumps — **verify paths & asset IDs here** |

**Build:** `node April Fallen/scripts/bundle.mjs` then copy `april.lua` → `Script 1.lua`.

---

## Mandatory: read `April Fallen/docs/API.md` every session

**Before any draw, menu, entity, camera, input, image, or memory work — open and read the relevant section of `April Fallen/docs/API.md`.** Do not rely on memory alone; the API has non-obvious rules that break features if ignored.

### API rules agents must follow

| Topic | Rule (from API.md) |
|-------|---------------------|
| Drawing | All `draw.*` calls only inside `on_frame` |
| Menu | `menu.get(id)` every frame — never cache toggle state |
| Images | `handle = draw.load_image(url)` once; call `draw.image(handle, x,y,w,h, 255,255,255,255)` **every frame** (no-ops until uploaded) |
| Image URLs | **One direct HTTPS URL** per image (API example: `raw.githubusercontent.com/.../icon.png`) |
| No fallbacks | **Do not add fallback URLs, APIs, or code paths unless API.md documents them** |
| Player ESP | `p:get_bounds()` for boxes; `p.head_position` for world labels |
| Fallen AC | **Do not write `WalkSpeed`** — use velocity/root movement |
| Menu | Unique `id` per control **and** unique `label` text within the same tab+group (Vector ties visibility to labels) |

When adding or fixing visuals, **re-read the Images section** in API.md and use the on_frame pattern: load once, skip the load frame, then call `draw.image` every frame (no `image_loaded` gate).

---

## Image assets (GitHub CDN)

Item icons are hosted on GitHub and loaded with **one** HTTPS URL per API.md:

`https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/assets/items/{assetId}.png`

No alternate CDNs or `rbxassetid://` fallbacks in runtime code.

**Regenerate after dump updates:**
```bash
npm run extract-images    # dump → item_images.lua + manifest
npm run download-assets   # Roblox Thumbnails API → PNG files
# commit assets/ to GitHub, then npm run build
```

Asset IDs come from `references/dump/scripts/ReplicatedStorage.Modules.Items.ModuleScript.lua` (`Image = "rbxassetid://..."` or `Image = { Default = ... }`).

---

## Mandatory: `April Fallen/references/dump/`

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

**Images:** `asset_urls.item_png(id)` → `image_cache.ensure(key, url)` → load on first draw, `draw.image` every frame after.

**No fallbacks:** Only use APIs and patterns documented in `April Fallen/docs/API.md`. Do not invent alternate URLs, hooks, or fallbacks.

---

## Implementation rules

1. Edit `src/`, rebuild, sync `Script 1.lua`.
2. **Check API.md** before implementing draw/menu/image behavior.
3. New item icons: extract from dump → download PNG → push to GitHub → rebuild.
4. Minimize scope; match existing module style.
5. Avoid WalkSpeed writes on Fallen.
6. **Menu labels:** never reuse the same display label in one tab+group (e.g. don't have two "Distance" checkboxes in Visuals — use "ESP Distance" vs "Overlay Distance").

---

## Version bump

After meaningful changes: bump version in `scripts/bundle.mjs`, rebuild, sync `Script 1.lua`.
