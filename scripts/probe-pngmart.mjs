const url = process.argv[2] || "https://www.pngmart.com/image/784458";
const res = await fetch(url, { headers: { "User-Agent": "Mozilla/5.0" } });
const t = await res.text();
const matches = [...t.matchAll(/https?:\/\/[^"'\s>]+\.png/gi)].map((m) => m[0]);
console.log("status", res.status, "len", t.length);
console.log("matches", matches.slice(0, 15));
