import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DUMP = path.resolve(
  ROOT,
  "../dump/scripts/ReplicatedStorage.Modules.Items.ModuleScript.lua",
);
const text = fs.readFileSync(DUMP, "utf8");

const entries = [];
const re = /\{\s*\n\s*Name\s*=\s*"([^"]+)"/g;
let m;
while ((m = re.exec(text))) {
  entries.push({ id: entries.length + 1, name: m[1], start: m.index });
}

const noImage = [];
for (let i = 0; i < entries.length; i++) {
  const entry = entries[i];
  const nextStart = i + 1 < entries.length ? entries[i + 1].start : text.length;
  const chunk = text.slice(entry.start, Math.min(entry.start + 12000, nextStart));
  if (!chunk.match(/Image\s*=/)) {
    noImage.push(`${entry.id} ${entry.name}`);
  }
}

console.log("items without Image field:", noImage);
