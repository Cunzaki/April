import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const cat = fs.readFileSync(path.join(ROOT, "src/game/item_catalog.lua"), "utf8");
const img = fs.readFileSync(path.join(ROOT, "src/game/item_images.lua"), "utf8");

const names = [...cat.matchAll(/name = "([^"]+)"/g)].map((m) => m[1]);
const imgNames = new Set([...img.matchAll(/\["([^"]+)"\]/g)].map((m) => m[1]));
const missing = [...new Set(names)].filter((n) => !imgNames.has(n));

console.log("missing images:", missing);
console.log("count:", missing.length);
