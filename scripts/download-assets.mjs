#!/usr/bin/env node
/**
 * Download item/decal PNGs via Roblox Thumbnails API v1 → assets/items/{id}.png
 * These files must be committed to GitHub — April loads them via raw.githubusercontent.com
 * (see April/docs/API.md draw.load_image — HTTPS URLs).
 *
 * Run: npm run extract-images && npm run download-assets
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const MANIFEST = path.join(ROOT, "assets/manifest.json");
const ITEMS_DIR = path.join(ROOT, "assets/items");
const TUNG_PATH = path.join(ROOT, "assets/tung.png");

const THUMB_API = "https://thumbnails.roblox.com/v1/assets";
const BATCH = 50;
const DELAY_MS = 250;

const args = process.argv.slice(2);
const tungOnly = args.includes("--tung-only");
const slowMode = args.includes("--slow");
const missingOnly = args.includes("--missing-only");
const limitIdx = args.indexOf("--limit");
const limit = limitIdx >= 0 ? parseInt(args[limitIdx + 1], 10) : Infinity;

const SLOW_BATCH = 5;
const SLOW_DELAY_MS = 1500;
const SLOW_429_WAIT_MS = 8000;
const SLOW_MAX_RETRIES = 5;

async function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function downloadUrl(url, dest) {
  const res = await fetch(url, {
    headers: { "User-Agent": "April-Asset-Sync/1.0" },
    redirect: "follow",
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  if (buf.length < 100) throw new Error(`too small (${buf.length}b)`);
  fs.writeFileSync(dest, buf);
  return buf.length;
}

async function resolveThumbnails(ids, retries = SLOW_MAX_RETRIES) {
  const q = new URLSearchParams({
    assetIds: ids.join(","),
    returnPolicy: "PlaceHolder",
    size: "420x420",
    format: "Png",
  });

  for (let attempt = 1; attempt <= retries; attempt++) {
    const res = await fetch(`${THUMB_API}?${q}`, {
      headers: { "User-Agent": "April-Asset-Sync/1.0" },
    });

    if (res.status === 429) {
      const wait = slowMode ? SLOW_429_WAIT_MS * attempt : DELAY_MS * 4;
      console.warn(`  429 rate limit — waiting ${wait}ms (attempt ${attempt}/${retries})`);
      await sleep(wait);
      continue;
    }

    if (!res.ok) throw new Error(`Thumbnails API HTTP ${res.status}`);
    const json = await res.json();
    const out = new Map();
    const rows = json.data || [];
    for (let i = 0; i < rows.length; i++) {
      const row = rows[i];
      const id = ids[i];
      if (id && row.imageUrl && row.state === "Completed") {
        out.set(String(id), row.imageUrl);
      }
    }
    return out;
  }

  throw new Error("Thumbnails API HTTP 429 (retries exhausted)");
}

async function saveAsset(id, cdnUrl, dest) {
  if (fs.existsSync(dest)) {
    const st = fs.statSync(dest);
    if (st.size > 100) return { id, skipped: true, bytes: st.size };
  }
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      const bytes = await downloadUrl(cdnUrl, dest);
      return { id, skipped: false, bytes };
    } catch (e) {
      if (attempt < 3) await sleep(slowMode ? 2000 : 500);
      else throw e;
    }
  }
}

function listMissing(manifest) {
  const have = new Set(
    fs
      .readdirSync(ITEMS_DIR)
      .filter((f) => f.endsWith(".png"))
      .map((f) => f.replace(".png", "")),
  );
  return (manifest.assets || []).map(String).filter((id) => !have.has(id));
}

async function main() {
  if (!fs.existsSync(MANIFEST)) {
    console.error("Run: node scripts/extract-item-images.mjs");
    process.exit(1);
  }

  const manifest = JSON.parse(fs.readFileSync(MANIFEST, "utf8"));
  fs.mkdirSync(ITEMS_DIR, { recursive: true });

  const tungId = manifest.tung || "139818999438291";
  console.log("Tung → assets/tung.png");
  try {
    const map = await resolveThumbnails([tungId]);
    const url = map.get(tungId);
    if (!url) throw new Error("no thumbnail URL");
    const r = await saveAsset(tungId, url, TUNG_PATH);
    console.log(`  ${r.skipped ? "exists" : "saved"} (${r.bytes} bytes)`);
  } catch (e) {
    console.error("  failed:", e.message);
  }

  if (tungOnly) return;

  let ids = (manifest.assets || []).map(String);
  if (missingOnly) {
    ids = listMissing(manifest);
    console.log(`Missing-only mode: ${ids.length} assets to fetch`);
  }
  if (Number.isFinite(limit)) ids = ids.slice(0, limit);

  const batchSize = slowMode ? SLOW_BATCH : BATCH;
  const delayMs = slowMode ? SLOW_DELAY_MS : DELAY_MS;

  let saved = 0;
  let skipped = 0;
  let failed = 0;
  const stillMissing = [];

  for (let i = 0; i < ids.length; i += batchSize) {
    const batch = ids.slice(i, i + batchSize);
    let map;
    try {
      map = await resolveThumbnails(batch);
    } catch (e) {
      console.warn(`Batch ${Math.floor(i / batchSize) + 1} API fail:`, e.message);
      stillMissing.push(...batch);
      failed += batch.length;
      await sleep(delayMs);
      continue;
    }

    for (const id of batch) {
      const dest = path.join(ITEMS_DIR, `${id}.png`);
      const url = map.get(id);
      if (!url) {
        stillMissing.push(id);
        failed++;
        continue;
      }
      try {
        const r = await saveAsset(id, url, dest);
        if (r.skipped) skipped++;
        else {
          saved++;
          if (slowMode) console.log(`  saved ${id}.png (${r.bytes} bytes)`);
        }
      } catch (e) {
        stillMissing.push(id);
        failed++;
        if (slowMode) console.warn(`  fail ${id}:`, e.message);
      }
      if (slowMode) await sleep(400);
    }

    const batchNum = Math.floor(i / batchSize) + 1;
    const batchTotal = Math.ceil(ids.length / batchSize);
    console.log(`Batch ${batchNum}/${batchTotal} — saved ${saved}, skip ${skipped}, fail ${failed}`);
    await sleep(delayMs);
  }

  if (slowMode && stillMissing.length > 0) {
    console.log(`\nRetrying ${stillMissing.length} individually (slow)...`);
    for (const id of stillMissing) {
      const dest = path.join(ITEMS_DIR, `${id}.png`);
      if (fs.existsSync(dest) && fs.statSync(dest).size > 100) continue;
      try {
        const map = await resolveThumbnails([id]);
        const url = map.get(id);
        if (!url) {
          console.warn(`  no thumb: ${id}`);
          continue;
        }
        const r = await saveAsset(id, url, dest);
        if (!r.skipped) {
          saved++;
          failed = Math.max(0, failed - 1);
          console.log(`  saved ${id}.png (${r.bytes} bytes)`);
        }
      } catch (e) {
        console.warn(`  fail ${id}:`, e.message);
      }
      await sleep(2500);
    }
  }

  const remaining = listMissing(manifest).length;
  console.log(`Done: ${saved} saved, ${skipped} skipped, ${failed} failed (${ids.length} targeted)`);
  console.log(`Remaining on disk: ${remaining} missing of ${manifest.assets.length}`);
  console.log("Push assets/ to https://github.com/cunzaki/April — script uses raw CDN URLs.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
