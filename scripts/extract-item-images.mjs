#!/usr/bin/env node
/** Thin wrapper — use npm run sync-assets for full extract + prune + download. */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import {
  TUNG_ID,
  extractAllAssets,
  emitItemImagesLua,
  emitAttachmentImagesLua,
} from "./lib/extract-game-assets.mjs";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const OUT_LUA = path.join(ROOT, "src/game/item_images.lua");
const ATT_LUA = path.join(ROOT, "src/game/attachment_images.lua");
const MANIFEST = path.join(ROOT, "assets/manifest.json");
const CATALOG = path.join(ROOT, "src/game/item_catalog.lua");

const data = extractAllAssets(ROOT, CATALOG);

fs.mkdirSync(path.dirname(OUT_LUA), { recursive: true });
fs.writeFileSync(OUT_LUA, emitItemImagesLua(data.byName));
fs.writeFileSync(ATT_LUA, emitAttachmentImagesLua(data.attMap));
fs.writeFileSync(
  MANIFEST,
  JSON.stringify(
    {
      generated: new Date().toISOString(),
      sources: data.sources,
      tung: TUNG_ID,
      itemCount: data.stats.itemNames,
      assetCount: data.assets.length,
      assets: data.assets,
    },
    null,
    2,
  ) + "\n",
);

console.log(
  `item_images.lua: ${data.stats.itemNames} items, ${data.stats.assetCount} asset IDs (+ tung)`,
);
console.log(`  skins merged: ${data.stats.skinMerged}, attachments: ${data.stats.attAdded}`);
console.log("Run npm run sync-assets to prune stale PNGs and download missing.");
