#!/usr/bin/env node
/**
 * Full asset sync from game dump:
 *   1. Extract all item/attachment icon IDs (Items + Skins + mesh attachments)
 *   2. Regenerate item_images.lua, attachment_images.lua, manifest.json
 *   3. Delete stale PNGs not in manifest
 *   4. Download missing PNGs via Roblox Thumbnails API (rate-limit safe)
 *
 * Run: npm run sync-assets
 * Flags:
 *   --extract-only   regenerate lua/manifest + prune, skip download
 *   --no-prune       keep orphan PNGs on disk
 *   --dry-run        print actions without writing/deleting/downloading
 *   --fast           larger batches, shorter delays (default)
 *   --slow           smaller batches, longer delays (429 recovery)
 */

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
const ITEMS_DIR = path.join(ROOT, "assets/items");
const MANIFEST = path.join(ROOT, "assets/manifest.json");
const OUT_LUA = path.join(ROOT, "src/game/item_images.lua");
const ATT_LUA = path.join(ROOT, "src/game/attachment_images.lua");
const TUNG_PATH = path.join(ROOT, "assets/tung.png");
const CATALOG = path.join(ROOT, "src/game/item_catalog.lua");

const THUMB_API = "https://thumbnails.roblox.com/v1/assets";
const UA = "April-Asset-Sync/2.0";

const args = process.argv.slice(2);
const extractOnly = args.includes("--extract-only");
const noPrune = args.includes("--no-prune");
const dryRun = args.includes("--dry-run");
const slowMode = args.includes("--slow");

const BATCH = slowMode ? 10 : 100;
const BATCH_DELAY_MS = slowMode ? 1200 : 220;
const DL_CONCURRENCY = slowMode ? 2 : 8;
const RETRY_429_MS = slowMode ? 10000 : 4000;
const MAX_RETRIES = 6;

async function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function poolMap(items, limit, fn) {
  const results = new Array(items.length);
  let i = 0;
  async function worker() {
    while (i < items.length) {
      const idx = i++;
      results[idx] = await fn(items[idx], idx);
    }
  }
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, worker));
  return results;
}

async function resolveThumbnails(ids) {
  const q = new URLSearchParams({
    assetIds: ids.join(","),
    returnPolicy: "PlaceHolder",
    size: "420x420",
    format: "Png",
  });

  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    const res = await fetch(`${THUMB_API}?${q}`, { headers: { "User-Agent": UA } });

    if (res.status === 429) {
      const wait = RETRY_429_MS * attempt;
      console.warn(`  429 rate limit — wait ${wait}ms (${attempt}/${MAX_RETRIES})`);
      await sleep(wait);
      continue;
    }

    if (!res.ok) throw new Error(`Thumbnails API HTTP ${res.status}`);
    const json = await res.json();
    const out = new Map();
    const rows = json.data || [];
    for (const row of rows) {
      const id = row?.targetId != null ? String(row.targetId) : null;
      if (id && row?.imageUrl && row.state === "Completed") {
        out.set(id, row.imageUrl);
      }
    }
    return out;
  }

  throw new Error("Thumbnails API 429 (retries exhausted)");
}

async function downloadUrl(url, dest) {
  const res = await fetch(url, { headers: { "User-Agent": UA }, redirect: "follow" });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  if (buf.length < 80) throw new Error(`too small (${buf.length}b)`);
  if (!dryRun) fs.writeFileSync(dest, buf);
  return buf.length;
}

async function tryAssetDelivery(id, dest) {
  const url = `https://assetdelivery.roblox.com/v1/asset/?id=${id}`;
  try {
    return await downloadUrl(url, dest);
  } catch {
    return null;
  }
}

function listOnDisk() {
  if (!fs.existsSync(ITEMS_DIR)) return new Set();
  return new Set(
    fs
      .readdirSync(ITEMS_DIR)
      .filter((f) => f.endsWith(".png"))
      .map((f) => f.replace(/\.png$/, "")),
  );
}

function pruneStale(wantIds) {
  const want = new Set(wantIds.map(String));
  const onDisk = listOnDisk();
  const removed = [];

  for (const id of onDisk) {
    if (!want.has(id)) {
      const p = path.join(ITEMS_DIR, `${id}.png`);
      if (!dryRun) fs.unlinkSync(p);
      removed.push(id);
    }
  }
  return removed;
}

async function downloadAssets(assetIds) {
  fs.mkdirSync(ITEMS_DIR, { recursive: true });
  const onDisk = listOnDisk();
  const missing = assetIds.filter((id) => !onDisk.has(String(id)));

  console.log(`\nDownload: ${missing.length} missing / ${assetIds.length} in manifest`);

  // Tung
  if (!onDisk.has(TUNG_ID) || !fs.existsSync(TUNG_PATH)) {
    try {
      const map = await resolveThumbnails([TUNG_ID]);
      const url = map.get(TUNG_ID);
      if (url) {
        const bytes = await downloadUrl(url, TUNG_PATH);
        console.log(`  tung.png ${dryRun ? "would save" : "saved"} (${bytes}b)`);
      }
    } catch (e) {
      console.warn("  tung failed:", e.message);
    }
    await sleep(BATCH_DELAY_MS);
  }

  let saved = 0;
  let failed = 0;
  const stillMissing = [];

  for (let i = 0; i < missing.length; i += BATCH) {
    const batch = missing.slice(i, i + BATCH);
    const batchNum = Math.floor(i / BATCH) + 1;
    const batchTotal = Math.ceil(missing.length / BATCH);

    let map;
    try {
      map = await resolveThumbnails(batch);
    } catch (e) {
      console.warn(`Batch ${batchNum}/${batchTotal} API error:`, e.message);
      stillMissing.push(...batch);
      failed += batch.length;
      await sleep(BATCH_DELAY_MS);
      continue;
    }

    await poolMap(batch, DL_CONCURRENCY, async (id) => {
      const dest = path.join(ITEMS_DIR, `${id}.png`);
      const url = map.get(String(id));
      if (!url) {
        const bytes = await tryAssetDelivery(id, dest);
        if (bytes) {
          saved++;
          return;
        }
        stillMissing.push(id);
        failed++;
        return;
      }
      try {
        const bytes = await downloadUrl(url, dest);
        saved++;
        if (slowMode) console.log(`  ${id}.png (${bytes}b)`);
      } catch (e) {
        stillMissing.push(id);
        failed++;
        if (slowMode) console.warn(`  fail ${id}:`, e.message);
      }
    });
    console.log(`Batch ${batchNum}/${batchTotal} — saved ${saved}, failed ${failed}`);
    if (i + BATCH < missing.length) await sleep(BATCH_DELAY_MS);
  }

  // ponytail: one slow retry pass for stubborn IDs
  if (stillMissing.length > 0) {
    console.log(`\nRetrying ${stillMissing.length} individually...`);
    for (const id of stillMissing) {
      const dest = path.join(ITEMS_DIR, `${id}.png`);
      if (fs.existsSync(dest) && fs.statSync(dest).size > 80) continue;
      try {
        const map = await resolveThumbnails([id]);
        const url = map.get(String(id));
        if (!url) {
          console.warn(`  no thumbnail: ${id}`);
          const bytes = await tryAssetDelivery(id, dest);
          if (bytes) {
            saved++;
            failed = Math.max(0, failed - 1);
            console.log(`  ${id}.png via assetdelivery (${bytes}b)`);
          }
          continue;
        }
        const bytes = await downloadUrl(url, dest);
        saved++;
        failed = Math.max(0, failed - 1);
        console.log(`  ${id}.png (${bytes}b)`);
      } catch (e) {
        console.warn(`  fail ${id}:`, e.message);
      }
      await sleep(slowMode ? 2500 : 600);
    }
  }

  const remain = assetIds.filter((id) => {
    const p = path.join(ITEMS_DIR, `${id}.png`);
    return !fs.existsSync(p) || fs.statSync(p).size < 80;
  }).length;

  console.log(`\nDownload done: ${saved} saved, ${failed} failed, ${remain} still missing`);
  return { saved, failed, remain };
}

function writeOutputs(data) {
  const manifest = {
    generated: new Date().toISOString(),
    sources: data.sources,
    tung: TUNG_ID,
    itemCount: data.stats.itemNames,
    assetCount: data.assets.length,
    assets: data.assets,
  };

  if (!dryRun) {
    fs.mkdirSync(path.dirname(OUT_LUA), { recursive: true });
    fs.mkdirSync(ITEMS_DIR, { recursive: true });
    fs.writeFileSync(OUT_LUA, emitItemImagesLua(data.byName));
    fs.writeFileSync(ATT_LUA, emitAttachmentImagesLua(data.attMap));
    fs.writeFileSync(MANIFEST, JSON.stringify(manifest, null, 2) + "\n");
  }

  return manifest;
}

async function main() {
  if (!fs.existsSync(CATALOG)) {
    console.error("Missing", CATALOG);
    process.exit(1);
  }

  console.log(dryRun ? "DRY RUN — no writes/deletes/downloads\n" : "Syncing assets from dump...\n");

  const data = extractAllAssets(ROOT, CATALOG);
  const { stats } = data;

  console.log("Extract:");
  console.log(`  catalog:     ${stats.catalogTotal} items`);
  console.log(`  with icons:  ${stats.catalogWithIcon} named in item_images`);
  console.log(`  no icon:     ${stats.catalogWithoutIcon} (no Image in Items dump — resources/ammo/etc.)`);
  console.log(`  by_name:     ${stats.itemNames} entries (incl. skin-only variants)`);
  console.log(`  asset IDs:   ${stats.assetCount}`);
  console.log(`  skin rows:   ${stats.skinMerged}`);
  console.log(`  attachments: ${stats.attAdded} mesh + ${stats.attLinked} catalog-linked`);
  console.log(`  prefabs:     ${stats.prefabAdded} from Benches/VMs/Armors (${stats.prefabSources} sources)`);

  const manifest = writeOutputs(data);
  console.log(`\nWrote ${dryRun ? "(dry-run) " : ""}item_images.lua, attachment_images.lua, manifest.json`);

  if (!noPrune) {
    const removed = pruneStale(manifest.assets);
    console.log(`\nPrune: ${removed.length} stale PNGs ${dryRun ? "would be " : ""}removed`);
    if (removed.length > 0 && (slowMode || removed.length <= 30)) {
      for (const id of removed.slice(0, 30)) console.log(`  - ${id}.png`);
      if (removed.length > 30) console.log(`  ... and ${removed.length - 30} more`);
    }
  }

  if (!extractOnly) {
    await downloadAssets(manifest.assets);
  }

  const onDisk = listOnDisk().size;
  console.log(`\nOn disk: ${onDisk} PNGs | manifest: ${manifest.assetCount}`);
  if (!dryRun) console.log("Push assets/ to GitHub — April loads raw CDN URLs.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
