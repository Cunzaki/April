const terms = ["Bombardiro Crocodilo", "Boneca Ambalabu", "Brr Brr Patapim", "Lirili Larila", "Orangutini Ananasini", "Cappuccino Assassino"];
for (const term of terms) {
  const url = `https://www.pngmart.com/?s=${encodeURIComponent(term)}`;
  const res = await fetch(url, { headers: { "User-Agent": "Mozilla/5.0" } });
  const html = await res.text();
  const ids = [...html.matchAll(/\/image\/(\d+)/g)].map((m) => m[1]).slice(0, 5);
  console.log(term, ids);
  await new Promise((r) => setTimeout(r, 500));
}
