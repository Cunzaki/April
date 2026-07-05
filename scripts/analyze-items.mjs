import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const ITEMS = path.join(ROOT, "dump/scripts/ReplicatedStorage.Modules.Items.ModuleScript.lua");
const text = fs.readFileSync(ITEMS, "utf8");

const entries = [];
const re = /\{\s*\n\s*Name\s*=\s*"([^"]+)"/g;
let m;
while ((m = re.exec(text))) {
  entries.push({ idx: entries.length + 1, name: m[1] });
}

console.log("Total items:", entries.length);
for (const x of entries) {
  if (x.idx >= 145 && x.idx <= 155) console.log(x.idx, x.name);
}
for (const x of entries) {
  if (x.name === "Military Helmet" || x.name === "Military Chestplate") console.log("FOUND", x.idx, x.name);
}

// Parse Attribute fields
const attrMap = {};
const chunkRe = /\{\s*\n\s*Name\s*=\s*"([^"]+)"([\s\S]*?)\n    \},/g;
while ((m = chunkRe.exec(text))) {
  const name = m[1];
  const chunk = m[2];
  const attr = chunk.match(/Attribute\s*=\s*"([^"]+)"/);
  if (attr) attrMap[attr[1]] = name;
}
console.log("Attributes:", Object.keys(attrMap).length);
console.log("Sample attrs:", Object.entries(attrMap).slice(0, 10));
