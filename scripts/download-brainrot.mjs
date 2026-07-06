const queries = [
  ["tralalero_tralala", "Tralalero Tralala", "784458"],
  ["brr_brr_patapim", "Brr Brr Patapim", "784320"],
  ["orangutini", "Orangutini Ananasini", "784404"],
  ["cappuccino_assassino", "Cappuccino Assassino", "784338"],
  ["lirili_larila", "Lirili Larila", "784360"],
  ["boneca_ambalabu", "Boneca Ambalabu", "784380"],
  ["bombardiro_crocodilo", "Bombardiro Crocodilo", "784400"],
  ["chimpanzini", "Chimpanzini Bananini", "784740"],
  ["ta_ta_sahur", "Ta Ta Ta Sahur", "784760"],
  ["tung_head", "Tung Tung Head", "784580"],
  ["tung_clipart", "Tung Clipart", "784500"],
  ["trippi_troppi", "Trippi Troppi", "784780"],
  ["frigo_camelo", "Frigo Camelo", "784800"],
  ["ballerina_cappuccina", "Ballerina Cappuccina", "784820"],
  ["udin_din_din", "Udin Din Din Dun", "784840"],
];

const DIRECT = [
  ["bombardiro_crocodilo", "Bombardiro Crocodilo", "https://www.pngall.com/wp-content/uploads/15/Bombardiro-Crocodilo-PNG.png"],
  ["boneca_ambalabu", "Boneca Ambalabu", "https://www.pngall.com/wp-content/uploads/15/Boneca-Ambalabu-PNG.png"],
  ["lirili_larila", "Lirili Larila", "https://www.pngall.com/wp-content/uploads/15/Lirili-Larila-PNG.png"],
];

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const OUT = path.join(ROOT, "assets", "brainrot");

async function fileFromPage(id) {
  const page = `https://www.pngmart.com/image/${id}`;
  const res = await fetch(page, { headers: { "User-Agent": "Mozilla/5.0" } });
  if (!res.ok) return null;
  const html = await res.text();
  const matches = [...html.matchAll(/https:\/\/www\.pngmart\.com\/files\/[^"'\s>]+\.png/gi)].map((m) => m[0]);
  return matches.find((u) => u.includes("/files/")) || null;
}

async function download(url, dest) {
  const res = await fetch(url, { headers: { "User-Agent": "Mozilla/5.0" }, redirect: "follow" });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  if (buf.length < 500) throw new Error(`small ${buf.length}`);
  fs.writeFileSync(dest, buf);
  return buf.length;
}

fs.mkdirSync(OUT, { recursive: true });
const manifest = [];

// Roblox tung
try {
  const q = new URLSearchParams({ assetIds: "139818999438291", returnPolicy: "PlaceHolder", size: "420x420", format: "Png" });
  const j = await (await fetch(`https://thumbnails.roblox.com/v1/assets?${q}`)).json();
  const url = j.data?.[0]?.imageUrl;
  if (url) {
    const bytes = await download(url, path.join(OUT, "tung_tung_sahur.png"));
    manifest.push({ file: "tung_tung_sahur", name: "Tung Tung Sahur" });
    console.log("roblox tung", bytes);
  }
} catch (e) {
  console.warn("roblox", e.message);
}

for (const [file, name, directUrl] of DIRECT) {
  try {
    const bytes = await download(directUrl, path.join(OUT, `${file}.png`));
    const idx = manifest.findIndex((m) => m.file === file);
    if (idx >= 0) manifest[idx] = { file, name };
    else manifest.push({ file, name });
    console.log("direct", name, bytes);
  } catch (e) {
    console.warn("direct fail", name, e.message);
  }
}

for (const [file, name, pageId] of queries) {
  if (file === "tung_tung_sahur" && manifest.find((m) => m.file === file)) continue;
  try {
    const imgUrl = await fileFromPage(pageId);
    if (!imgUrl) {
      console.warn("skip", name, pageId);
      continue;
    }
    const bytes = await download(imgUrl, path.join(OUT, `${file}.png`));
    if (!manifest.find((m) => m.file === file)) manifest.push({ file, name });
    console.log("ok", name, bytes);
  } catch (e) {
    console.warn("fail", name, e.message);
  }
  await new Promise((r) => setTimeout(r, 400));
}

fs.writeFileSync(path.join(OUT, "manifest.json"), JSON.stringify(manifest, null, 2));
console.log("total", manifest.length);
