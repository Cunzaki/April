#!/usr/bin/env node
/**
 * Build game/attachment_images.lua from dump/catalog/mesh_assets.tsv
 * Run: node scripts/extract-attachment-images.mjs
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const TSV = path.join(ROOT, "dump/catalog/mesh_assets.tsv");
const OUT = path.join(ROOT, "src/game/attachment_images.lua");

const pick = new Map();

for (const line of fs.readFileSync(TSV, "utf8").split("\n").slice(1)) {
  const parts = line.split("\t");
  const instPath = parts[1];
  if (!instPath?.includes("ReplicatedStorage.Attachments.")) continue;
  const m = instPath.match(/ReplicatedStorage\.Attachments\.([^.]+)\.([^.]+)/);
  if (!m) continue;
  const att = m[1];
  const part = m[2];
  const tex = (parts[3] || "").replace("rbxassetid://", "");
  if (!tex) continue;
  const score =
    part === att ? 3 : part === "Sight" || part === "Muzzle" || part === "Laser" ? 2 : 1;
  const cur = pick.get(att);
  if (!cur || score > cur.score) pick.set(att, { id: tex, score });
}

const names = [...pick.entries()].sort((a, b) => a[0].localeCompare(b[0]));
const lines = names.map(([name, v]) => `    ["${name.replace(/'/g, "\\'")}"] = "${v.id}",`);

const lua = `-- Texture IDs from dump: ReplicatedStorage.Attachments (mesh_assets.tsv)
local M = {}

M.by_name = {
${lines.join("\n")}
}

function M.get_asset_id(name)
    return name and M.by_name[name]
end

return M
`;

fs.writeFileSync(OUT, lua);
console.log(`Wrote ${OUT} (${names.length} attachments)`);
