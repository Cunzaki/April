# April image assets

PNG files hosted on GitHub for `draw.load_image` (Vector requires **HTTPS** URLs — see `docs/API.md`).

## Workflow

1. **Extract** asset IDs from the game dump:
   ```bash
   npm run extract-images
   ```
   Generates `src/game/item_images.lua` and `assets/manifest.json`.

2. **Download** PNGs from Roblox Thumbnails API:
   ```bash
   npm run download-assets
   ```
   Writes `assets/items/{assetId}.png` and `assets/tung.png`.

3. **Commit & push** `assets/` to GitHub (`main` branch).

4. **Rebuild** the script:
   ```bash
   npm run build
   ```

Runtime URLs: `https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/assets/items/{id}.png`

Do **not** use `github.com/.../blob/main/...` — that is the web viewer, not a direct image URL.

## Brainrot ESP

Transparent brainrot character PNGs → `assets/brainrot/{name}.png`

```bash
node scripts/download-brainrot.mjs
```

Runtime URL: `https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/assets/brainrot/tung_tung_sahur.png`

## Anime announcer

Waist-up transparent announcer expressions live under `assets/anime/{character}/`.
The runtime fetches both PNG expressions and `dialogue.txt` from GitHub over HTTPS.

Runtime URL: `https://cdn.jsdelivr.net/gh/Cunzaki/April@<release>/assets/anime/april/normal.png`

Each character folder includes its source/license note. Hiyori is licensed for use
and modification inside games, but must not be redistributed as a standalone asset
pack. The in-app announcer is named April.

## Tung ESP

Decal asset [139818999438291](https://create.roblox.com/store/asset/139818999438291/tung-tung-tung-sahur) → `assets/tung.png`

## Mod Checker

Shield warning icon for in-world mod markers → `assets/mod_warning.png`

Runtime URL: `https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/assets/mod_warning.png`

## After game updates

Re-dump Items module → re-run `npm run assets` → commit new/changed PNGs.
