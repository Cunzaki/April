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

Runtime URLs: `https://raw.githubusercontent.com/cunzaki/April/main/assets/items/{id}.png`

## Tung ESP

Decal asset [139818999438291](https://create.roblox.com/store/asset/139818999438291/tung-tung-tung-sahur) → `assets/tung.png`

## After game updates

Re-dump Items module → re-run `npm run assets` → commit new/changed PNGs.
