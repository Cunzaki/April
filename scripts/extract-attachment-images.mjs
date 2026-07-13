#!/usr/bin/env node
/**
 * Build game/attachment_images.lua from dump/catalog/mesh_assets.tsv
 * Run: node scripts/extract-attachment-images.mjs
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { parseAttachmentMeshes, emitAttachmentImagesLua } from "./lib/extract-game-assets.mjs";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const TSV = path.join(ROOT, "dump/catalog/mesh_assets.tsv");
const OUT = path.join(ROOT, "src/game/attachment_images.lua");

const attMap = parseAttachmentMeshes(TSV);
fs.writeFileSync(OUT, emitAttachmentImagesLua(attMap));
console.log(`Wrote ${OUT} (${attMap.size} attachments)`);
