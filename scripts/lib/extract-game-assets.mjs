/**
 * Extract item icon asset IDs from April dump → byName map + asset ID set.
 * Sources: Items module, SkinsModule, attachment mesh textures.
 */

import fs from "fs";
import path from "path";

export const TUNG_ID = "139818999438291";

const ITEMS_CANDIDATES = [
  "dump/scripts/ReplicatedStorage.Modules.Items.ModuleScript.lua",
  "dump/scripts/ModuleScript/ReplicatedStorage.Modules.Items.ModuleScript.lua",
];

const SKINS_CANDIDATES = [
  "dump/scripts/ReplicatedStorage.Modules.SkinsModule.ModuleScript.lua",
  "dump/scripts/ModuleScript/ReplicatedStorage.Modules.SkinsModule.ModuleScript.lua",
];

export function rbxId(str) {
  if (!str) return null;
  const m = String(str).match(/(\d{5,})$/);
  return m ? m[1] : null;
}

/** Catalog/item names sometimes ship as Bruno\\'s in lua — normalize for lookups. */
export function normalizeItemName(s) {
  if (!s) return s;
  return s.replace(/\\'/g, "'").replace(/\\\\/g, "\\");
}

export function parseCatalogNames(text) {
  const byId = {};
  const re = /\[(\d+)\]\s*=\s*\{\s*name\s*=\s*"((?:[^"\\]|\\.)*)"/g;
  let m;
  while ((m = re.exec(text)) !== null) {
    byId[Number(m[1])] = normalizeItemName(m[2].replace(/\\"/g, '"'));
  }
  return byId;
}

export function parseCatalogTypes(text) {
  const byId = {};
  const re = /\[(\d+)\]\s*=\s*\{[^}]*name\s*=\s*"(?:[^"\\]|\\.)*"[^}]*type\s*=\s*"([^"]+)"/g;
  let m;
  while ((m = re.exec(text)) !== null) {
    byId[Number(m[1])] = m[2];
  }
  return byId;
}

export function collectRbxAssetIds(text) {
  const ids = new Set();
  if (!text) return ids;
  for (const m of text.matchAll(/rbxassetid:\/\/(\d+)/g)) ids.add(m[1]);
  return ids;
}

function extractBlock(text, openIdx) {
  let depth = 0;
  for (let i = openIdx; i < text.length; i++) {
    const c = text[i];
    if (c === "{") depth++;
    else if (c === "}") {
      depth--;
      if (depth === 0) return text.slice(openIdx, i + 1);
    }
  }
  return null;
}

function parseImageBlock(block) {
  const single = block.match(/Image\s*=\s*"(rbxassetid:\/\/[^"]+)"/);
  if (single) {
    const id = rbxId(single[1]);
    return id ? { defaultId: id, variants: null } : null;
  }

  const imageBlock = block.match(/Image\s*=\s*\{/);
  if (!imageBlock) return null;

  const from = block.indexOf("Image = {") + "Image = {".length;
  let depth = 1;
  let i = from;
  while (i < block.length && depth > 0) {
    const c = block[i];
    if (c === "{") depth++;
    else if (c === "}") depth--;
    i++;
  }
  const inner = block.slice(from, i - 1);
  const variants = {};
  const pairRe = /(\w+|"(?:[^"\\]|\\.)*")\s*=\s*"(rbxassetid:\/\/[^"]+)"/g;
  let p;
  while ((p = pairRe.exec(inner)) !== null) {
    let key = p[1];
    if (key.startsWith('"')) key = key.slice(1, -1);
    const id = rbxId(p[2]);
    if (id) variants[key] = id;
  }
  const def = variants.Default || variants.default;
  if (!def && Object.keys(variants).length === 0) return null;
  return { defaultId: def || Object.values(variants)[0], variants };
}

function mergeImageEntry(existing, incoming) {
  if (!existing) return { ...incoming, variants: incoming.variants ? { ...incoming.variants } : null };
  const out = { defaultId: existing.defaultId || incoming.defaultId, variants: { ...(existing.variants || {}) } };
  if (incoming.variants) {
    for (const [k, v] of Object.entries(incoming.variants)) {
      if (!out.variants[k]) out.variants[k] = v;
    }
  }
  return out;
}

function addImageEntry(byName, assetIds, name, image) {
  if (!name || !image) return;
  byName[name] = mergeImageEntry(byName[name], image);
  assetIds.add(image.defaultId);
  if (image.variants) {
    for (const vid of Object.values(image.variants)) assetIds.add(vid);
  }
}

export function parseItemsModule(text, namesById) {
  const byName = {};
  const byItemId = {};
  const assetIds = new Set();
  const blockRe = /tbl_1\[(\d+)\]\s*=\s*\{/g;
  let m;

  while ((m = blockRe.exec(text)) !== null) {
    const itemId = Number(m[1]);
    const name = normalizeItemName(namesById[itemId]);

    const openIdx = text.indexOf("{", m.index + m[0].length - 1);
    const block = extractBlock(text, openIdx);
    if (!block) continue;

    const image = parseImageBlock(block);
    if (!image) continue;

    byItemId[itemId] = mergeImageEntry(byItemId[itemId], image);
    if (name) {
      addImageEntry(byName, assetIds, name, image);
    } else {
      assetIds.add(image.defaultId);
      if (image.variants) {
        for (const vid of Object.values(image.variants)) assetIds.add(vid);
      }
    }
  }

  // ponytail: catalog id join — every named item with an Image block in Items
  for (const [idStr, rawName] of Object.entries(namesById)) {
    const name = normalizeItemName(rawName);
    const image = byItemId[Number(idStr)];
    if (name && image) addImageEntry(byName, assetIds, name, image);
  }

  return { byName, byItemId, assetIds };
}

export function parseSkinsModule(text, byName, assetIds) {
  let merged = 0;
  const re = /\{"((?:[^"\\]|\\.)*)",\s*"((?:[^"\\]|\\.)*)",\s*"(rbxassetid:\/\/[^"]+)"/g;
  let m;
  while ((m = re.exec(text)) !== null) {
    const item = normalizeItemName(m[1].replace(/\\"/g, '"'));
    const variant = normalizeItemName(m[2].replace(/\\"/g, '"'));
    const id = rbxId(m[3]);
    if (!id) continue;

    assetIds.add(id);
    const row = byName[item] || { defaultId: id, variants: {} };
    if (!row.variants) row.variants = {};
    if (variant === "Default" || variant === "default") {
      row.defaultId = id;
    } else {
      row.variants[variant] = id;
    }
    if (!row.defaultId) row.defaultId = id;
    byName[item] = row;
    merged++;
  }
  return merged;
}

export function parseAttachmentTextures(tsvPath) {
  const pick = new Map();
  if (!fs.existsSync(tsvPath)) return pick;

  for (const line of fs.readFileSync(tsvPath, "utf8").split("\n").slice(1)) {
    const parts = line.split("\t");
    const instPath = parts[1];
    if (!instPath?.includes("ReplicatedStorage.Attachments.")) continue;
    const match = instPath.match(/ReplicatedStorage\.Attachments\.([^.]+)\.([^.]+)/);
    if (!match) continue;
    const att = match[1];
    const part = match[2];
    const tex = (parts[3] || parts[2] || "").replace("rbxassetid://", "");
    if (!tex) continue;
    const score =
      part === att ? 3 : part === "Sight" || part === "Muzzle" || part === "Laser" ? 2 : 1;
    const cur = pick.get(att);
    if (!cur || score > cur.score) pick.set(att, { id: tex, score });
  }
  return pick;
}

export function mergeAttachmentTextures(byName, assetIds, tsvPath) {
  const attMap = parseAttachmentTextures(tsvPath);
  let added = 0;
  for (const [name, { id }] of attMap) {
    assetIds.add(id);
    if (!byName[name]) {
      byName[name] = { defaultId: id, variants: null };
      added++;
    } else if (!byName[name].defaultId) {
      byName[name].defaultId = id;
    }
  }
  return { added, attMap };
}

export function luaEscape(s) {
  return s.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

export function emitItemImagesLua(byName) {
  const lines = [
    "-- AUTO-GENERATED by scripts/sync-assets.mjs — do not edit by hand",
    "-- Sources: Items module, SkinsModule, attachment mesh textures",
    "",
    "local M = {}",
    "",
    "M.by_name = {",
  ];

  for (const name of Object.keys(byName).sort()) {
    const entry = byName[name];
    let chunk = `    ["${luaEscape(name)}"] = { default = "${entry.defaultId}"`;
    if (entry.variants && Object.keys(entry.variants).length > 0) {
      chunk += ", variants = {";
      for (const [k, id] of Object.entries(entry.variants)) {
        chunk += ` ["${luaEscape(k)}"] = "${id}",`;
      }
      chunk += " }";
    }
    chunk += " },";
    lines.push(chunk);
  }

  lines.push(
    "}",
    "",
    "function M.get_asset_id(name, variant)",
    "    local row = name and M.by_name[name]",
    "    if not row then return nil end",
    "    if variant and row.variants and row.variants[variant] then",
    "        return row.variants[variant]",
    "    end",
    "    return row.default",
    "end",
    "",
    "return M",
    "",
  );
  return lines.join("\n");
}

export function emitAttachmentImagesLua(attMap) {
  const names = [...attMap.entries()].sort((a, b) => a[0].localeCompare(b[0]));
  const lines = names.map(([name, v]) => `    ["${luaEscape(name)}"] = "${v.id}",`);
  return `-- Texture IDs from dump: ReplicatedStorage.Attachments (mesh_assets.tsv)
local M = {}

M.by_name = {
${lines.join("\n")}
}

function M.get_asset_id(name)
    return name and M.by_name[name]
end

return M
`;
}

function firstExisting(root, rels) {
  for (const rel of rels) {
    const p = path.join(root, rel);
    if (fs.existsSync(p)) return p;
  }
  return null;
}

export function extractAllAssets(root, catalogPath) {
  const itemsPath = firstExisting(root, ITEMS_CANDIDATES);
  if (!itemsPath) {
    throw new Error("Missing Items module dump. Run: npm run dump");
  }

  const skinsPath = firstExisting(root, SKINS_CANDIDATES);
  const meshTsv = path.join(root, "dump/catalog/mesh_assets.tsv");
  const catalogText = fs.readFileSync(catalogPath, "utf8");
  const namesById = parseCatalogNames(catalogText);
  const typesById = parseCatalogTypes(catalogText);

  const itemsText = fs.readFileSync(itemsPath, "utf8");
  const skinsText = skinsPath ? fs.readFileSync(skinsPath, "utf8") : "";
  const { byName, assetIds } = parseItemsModule(itemsText, namesById);

  let skinMerged = 0;
  if (skinsText) {
    skinMerged = parseSkinsModule(skinsText, byName, assetIds);
  }

  const { added: attAdded, attMap } = mergeAttachmentTextures(byName, assetIds, meshTsv);

  // Every catalog attachment name → mesh texture icon (12 in ReplicatedStorage.Attachments)
  let attLinked = 0;
  for (const [idStr, rawName] of Object.entries(namesById)) {
    if (typesById[Number(idStr)] !== "Attachment") continue;
    const name = normalizeItemName(rawName);
    const tex = attMap.get(name);
    if (!tex) continue;
    if (!byName[name]) {
      byName[name] = { defaultId: tex.id, variants: null };
      assetIds.add(tex.id);
      attLinked++;
    }
  }

  // Union every item/skin icon rbxassetid from dump (639 items + 489 skins, deduped)
  for (const id of collectRbxAssetIds(itemsText)) assetIds.add(id);
  for (const id of collectRbxAssetIds(skinsText)) assetIds.add(id);
  assetIds.add(TUNG_ID);

  const catalogTotal = Object.keys(namesById).length;
  let catalogWithIcon = 0;
  for (const rawName of Object.values(namesById)) {
    if (byName[normalizeItemName(rawName)]) catalogWithIcon++;
  }
  const assets = [...assetIds].sort((a, b) =>
    BigInt(a) < BigInt(b) ? -1 : BigInt(a) > BigInt(b) ? 1 : 0,
  );

  return {
    byName,
    assets,
    attMap,
    sources: { itemsPath, skinsPath, meshTsv, catalogPath },
    stats: {
      catalogTotal,
      itemNames: Object.keys(byName).length,
      catalogWithIcon,
      catalogWithoutIcon: catalogTotal - catalogWithIcon,
      assetCount: assets.length,
      skinMerged,
      attAdded,
      attLinked,
    },
  };
}
