#!/usr/bin/env node
/** Union catalog rows from a previous dump into the current dump (new wins on path conflict). */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const primary = path.resolve(process.argv[2] || path.join(ROOT, "dump"));
const secondary = path.resolve(process.argv[3] || path.join(ROOT, "dump-prev"));

function readTsv(file) {
  if (!fs.existsSync(file)) return { header: null, rows: new Map() };
  const lines = fs.readFileSync(file, "utf8").split("\n").filter(Boolean);
  const header = lines[0];
  const rows = new Map();
  for (const line of lines.slice(1)) {
    const key = line.split("\t")[1] || line;
    rows.set(key, line);
  }
  return { header, rows };
}

function mergeTsv(rel, keyCol = 1) {
  const a = path.join(primary, rel);
  const b = path.join(secondary, rel);
  const cur = readTsv(a);
  const old = readTsv(b);
  if (!cur.header && !old.header) return { added: 0, total: 0 };
  const header = cur.header || old.header;
  const merged = new Map(old.rows);
  for (const [k, v] of cur.rows) merged.set(k, v);
  let added = 0;
  for (const k of old.rows.keys()) {
    if (!cur.rows.has(k)) added++;
  }
  const out = [header, ...[...merged.values()].sort()];
  fs.writeFileSync(a, out.join("\n") + "\n");
  return { added, total: merged.size };
}

function mergeIdList(rel) {
  const a = path.join(primary, rel);
  const b = path.join(secondary, rel);
  const ids = new Set();
  for (const file of [a, b]) {
    if (!fs.existsSync(file)) continue;
    for (const line of fs.readFileSync(file, "utf8").split("\n").slice(1)) {
      const id = line.trim().split("\t").pop();
      if (id && /^\d+$/.test(id)) ids.add(id);
    }
  }
  if (!ids.size) return 0;
  const header = fs.existsSync(a)
    ? fs.readFileSync(a, "utf8").split("\n")[0]
    : "assetId";
  fs.writeFileSync(
    a,
    [header, ...[...ids].sort((x, y) => (BigInt(x) < BigInt(y) ? -1 : 1))].join("\n") + "\n",
  );
  return ids.size;
}

function main() {
  if (!fs.existsSync(primary)) {
    console.error(`Missing primary dump: ${primary}`);
    process.exit(1);
  }
  if (!fs.existsSync(secondary)) {
    console.log(`No secondary dump at ${secondary} — skip merge`);
    return;
  }

  const mesh = mergeTsv("catalog/mesh_assets.tsv");
  const img = mergeTsv("catalog/image_assets.tsv");
  const assets = mergeIdList("catalog/assets/all_ids.tsv");
  fs.copyFileSync(
    path.join(primary, "catalog/assets/all_ids.tsv"),
    path.join(primary, "catalog/assets.tsv"),
  );

  console.log(`Merged ${secondary} → ${primary}`);
  console.log(`  mesh_assets: +${mesh.added} rows (${mesh.total} total)`);
  console.log(`  image_assets: +${img.added} rows (${img.total} total)`);
  console.log(`  asset ids: ${assets} unique`);
}

main();
