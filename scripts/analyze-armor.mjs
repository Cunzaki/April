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
  entries.push({ id: entries.length + 1, name: m[1] });
}

const byName = Object.fromEntries(entries.map((e) => [e.name, e.id]));
const armorItems = [];
const attrMap = {};

const chunkRe = /\{\s*\n\s*Name\s*=\s*"([^"]+)"([\s\S]*?)\n    \},/g;
while ((m = chunkRe.exec(text))) {
  const name = m[1];
  const chunk = m[2];
  const type = chunk.match(/Type\s*=\s*"([^"]+)"/)?.[1];
  const attr = chunk.match(/Attribute\s*=\s*"([^"]+)"/)?.[1];
  if (type === "Armor" || chunk.includes("ArmorType")) {
    const id = byName[name];
    armorItems.push({ id, name, attr });
  }
  if (attr) attrMap[attr] = name;
}

console.log("Armor items:", armorItems.length);
console.log("Missing from legacy map sample:");
const legacy = fs.readFileSync(path.join(ROOT, "April/src/game/armor_map.lua"), "utf8");
for (const a of armorItems) {
  const key = `Armor_${a.id}`;
  if (!legacy.includes(`["${key}"]`) && !legacy.includes(`['${key}']`)) {
    console.log("  MISSING", key, "->", a.name);
  }
}

// weapons/guns count
let guns = 0, tools = 0;
for (const e of entries) {
  const idx = text.indexOf(`Name = "${e.name}"`);
  const chunk = text.slice(idx, idx + 2000);
  if (chunk.includes('Type = "Gun"')) guns++;
  if (chunk.includes('Type = "Tool"')) tools++;
}
console.log("Guns:", guns, "Tools:", tools, "Total:", entries.length);
