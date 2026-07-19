import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const staticPath = path.join(ROOT, "src/game/mod_ids.lua");
const genPath = path.join(ROOT, "src/game/mod_ids.static.generated.lua");

const re = /\[(\d+)\]\s*=\s*"([^"]+)"/;
function parse(s) {
  const m = {};
  for (const line of s.split("\n")) {
    const mm = line.match(re);
    if (mm) m[mm[1]] = mm[2];
  }
  return m;
}

const a = parse(fs.readFileSync(staticPath, "utf8"));
const b = parse(fs.readFileSync(genPath, "utf8"));
const missingInStatic = Object.keys(b).filter((k) => !a[k]);
const missingInApi = Object.keys(a).filter((k) => !b[k]);
const roleMismatch = Object.keys(a).filter((k) => b[k] && a[k] !== b[k]);

console.log("static", Object.keys(a).length, "api", Object.keys(b).length);
console.log("missing in static", missingInStatic.length, missingInStatic.slice(0, 20));
console.log("missing in api", missingInApi.length, missingInApi.slice(0, 20));
console.log(
  "role mismatch",
  roleMismatch.length,
  roleMismatch.slice(0, 10).map((k) => `${k}:${a[k]}->${b[k]}`)
);
