#!/usr/bin/env node
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const april = fs.readFileSync(path.join(ROOT, "april.lua"), "utf8");
const src = path.join(ROOT, "src");
const re = /-- ── ([^\n]+) ──\r?\nApril\._mods\["([^"]+)"\] = \(function\(\)\r?\n([\s\S]*?)\r?\nend\)\(\)\r?\n/g;

let m;
let n = 0;
while ((m = re.exec(april)) !== null) {
  const rel = m[1].trim();
  const body = m[3].replace(/\r\n/g, "\n");
  const out = path.join(src, rel);
  fs.mkdirSync(path.dirname(out), { recursive: true });
  fs.writeFileSync(out, body);
  n++;
}
console.log("Extracted", n, "modules to src/");
