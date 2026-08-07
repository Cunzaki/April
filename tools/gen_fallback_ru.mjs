import fs from "fs";

const enFb = [
  "greeting|roasty|smug|Oh, you enabled me? Try not to embarrass us.",
  "greeting|supportive|smile|April online. I'll keep an eye on you.",
  "death|roasty|laugh|You suck, lol. Want to try that again?",
  "death|supportive|sad|That one hurt. Reset and take it slower.",
  "respawn|roasty|smug|Back already? Try keeping this body for a minute.",
  "respawn|supportive|happy|You're back. New life, clean slate.",
  "downed|roasty|laugh|Floor inspection going well?",
  "downed|supportive|worried|You're downed. Get behind cover and call for help.",
  "revived|roasty|smug|Someone actually picked you up. Be grateful.",
  "revived|supportive|happy|You're up! Heal before re-engaging.",
  "low_health|roasty|pout|One sneeze and you're back at respawn.",
  "low_health|supportive|worried|Low health. Disengage and heal now.",
  "recovered|roasty|smug|Health restored. Common sense still pending.",
  "recovered|supportive|happy|Health recovered. You're ready again.",
  "safe_enter|roasty|smug|Safe zone reached. Even you should survive in here.",
  "safe_enter|supportive|happy|Safe zone reached. Take a moment to reset.",
  "safe_leave|roasty|evil|Leaving safety? This should be entertaining.",
  "safe_leave|supportive|worried|Leaving the safe zone. Check your route.",
  "combat_enter|roasty|evil|Combat started. Try not to feed them.",
  "combat_enter|supportive|worried|You're in combat. Keep cover and track angles.",
  "combat_leave|roasty|smug|Combat over. Somehow you're still breathing.",
  "combat_leave|supportive|happy|Combat cleared. Reset and heal up.",
  "bleeding|roasty|disgusted|You're bleeding. Congrats on the leak.",
  "bleeding|supportive|worried|You're bleeding. Stop and bandage immediately.",
  "bleed_stopped|supportive|happy|Bleed stopped. Nice recovery.",
  "hunger_low|roasty|pout|You're starving. Eat something that isn't a bullet.",
  "hunger_low|supportive|worried|Hunger is low. Find food before you weaken.",
  "thirst_low|roasty|pout|Thirsty? Water exists. Shocking, I know.",
  "thirst_low|supportive|worried|Thirst is low. Get water soon.",
  "radiation|roasty|fear|Radiation. Glow-in-the-dark is not a flex.",
  "radiation|supportive|fear|Radiation detected. Exit the zone now.",
  "cold|supportive|worried|You're getting cold. Warm up soon.",
  "hot|supportive|worried|You're overheating. Cool off soon.",
  "drowning|roasty|fear|You're drowning. Surface. Now.",
  "drowning|supportive|fear|You're drowning! Get to the surface!",
  "staff_nearby|roasty|surprised|Staff nearby. Behave. Or at least pretend.",
  "staff_nearby|supportive|worried|Staff nearby. Stay clean and careful.",
  "enemy_nearby|roasty|evil|Hostile nearby. Smile for the crosshair.",
  "enemy_nearby|supportive|worried|Enemy nearby. Slow down and listen.",
  "party_join|supportive|happy|Party joined. Stick together and callouts help.",
  "party_leave|supportive|neutral|You left the party. Stay aware solo.",
  "reviving|roasty|smug|Look at you, being useful for once.",
  "reviving|supportive|smile|Nice revive. Watch your surroundings while you do it.",
  "boss_spawn|roasty|evil|Boss event up. Go be brave. Or loot later.",
  "boss_spawn|supportive|surprised|A boss event is active. Prepare before engaging.",
  "timed_crate|roasty|smug|Timed crate. Race for loot, or race for death.",
  "timed_crate|supportive|happy|Timed crate is up. Approach carefully.",
];

const ruLines = fs.readFileSync("assets/anime/april/dialogue_ru.txt", "utf8").trim().split(/\r?\n/);
const byKey = new Map();
for (const line of ruLines) {
  const parts = line.split("|");
  if (parts.length < 4) continue;
  const key = parts.slice(0, 3).join("|");
  if (!byKey.has(key)) byKey.set(key, line);
}

const out = [];
for (const line of enFb) {
  const parts = line.split("|");
  const key = parts.slice(0, 3).join("|");
  const hit = byKey.get(key);
  out.push(hit || line);
}
fs.writeFileSync("tools/fallback_ru_lines.txt", out.map((l) => `    "${l.replace(/\\/g, "\\\\").replace(/"/g, '\\"')}",`).join("\n"));
console.log("wrote", out.length, "fallback ru lines");
