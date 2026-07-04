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
const limitIdx = args.indexOf("--limit");
const limit = limitIdx >= 0 ? parseInt(args[limitIdx + 1], 10) : Infinity;

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

async function resolveThumbnails(ids) {
  const q = new URLSearchParams({
    assetIds: ids.join(","),
    returnPolicy: "PlaceHolder",
    size: "420x420",
    format: "Png",
  });
  const res = await fetch(`${THUMB_API}?${q}`, {
    headers: { "User-Agent": "April-Asset-Sync/1.0" },
  });
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

async function saveAsset(id, cdnUrl, dest) {
  if (fs.existsSync(dest)) {
    const st = fs.statSync(dest);
    if (st.size > 100) return { id, skipped: true, bytes: st.size };
  }
  const bytes = await downloadUrl(cdnUrl, dest);
  return { id, skipped: false, bytes };
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
  if (Number.isFinite(limit)) ids = ids.slice(0, limit);

  let saved = 0;
  let skipped = 0;
  let failed = 0;

  for (let i = 0; i < ids.length; i += BATCH) {
    const batch = ids.slice(i, i + BATCH);
    let map;
    try {
      map = await resolveThumbnails(batch);
    } catch (e) {
      console.warn(`Batch ${i / BATCH + 1} API fail:`, e.message);
      failed += batch.length;
      await sleep(DELAY_MS);
      continue;
    }

    for (const id of batch) {
      const dest = path.join(ITEMS_DIR, `${id}.png`);
      const url = map.get(id);
      if (!url) {
        failed++;
        continue;
      }
      try {
        const r = await saveAsset(id, url, dest);
        if (r.skipped) skipped++;
        else saved++;
      } catch {
        failed++;
      }
    }

    console.log(`Batch ${Math.floor(i / BATCH) + 1}/${Math.ceil(ids.length / BATCH)} — saved ${saved}, skip ${skipped}, fail ${failed}`);
    await sleep(DELAY_MS);
  }

  console.log(`Done: ${saved} saved, ${skipped} skipped, ${failed} failed (${ids.length} total)`);
  console.log("Push assets/ to https://github.com/cunzaki/April — script uses raw CDN URLs.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
