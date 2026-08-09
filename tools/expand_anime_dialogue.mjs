/**
 * Builds expanded EN/RU anime dialogue with rarity fields, then patches
 * src/game/anime_announcer_data.lua via build_anime_dialogue_module.mjs logic.
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const enPath = path.join(ROOT, "assets/anime/april/dialogue.txt");
const ruPath = path.join(ROOT, "assets/anime/april/dialogue_ru.txt");
const dataPath = path.join(ROOT, "src/game/anime_announcer_data.lua");

const EXPR = ["smug", "laugh", "evil", "pout", "neutral", "disgusted", "worried", "surprised", "smile", "happy", "sad", "fear"];

function line(event, tone, expression, rarity, text) {
  if (!rarity || rarity === "common") {
    // Prefer explicit rarity for new corpus so weights work; keep common tagged.
    return `${event}|${tone}|${expression}|common|${text}`;
  }
  return `${event}|${tone}|${expression}|${rarity}|${text}`;
}

function many(event, tone, rarity, texts, expressions = EXPR) {
  const out = [];
  for (let i = 0; i < texts.length; i++) {
    out.push(line(event, tone, expressions[i % expressions.length], rarity, texts[i]));
  }
  return out;
}

const blocks = [];

// --- greeting ---
blocks.push(...many("greeting", "roasty", "common", [
  "Oh, you enabled me? Fine. Try not to embarrass us.",
  "I was having a nice day until you clicked that toggle.",
  "Your personal commentator has arrived. This should be funny.",
  "I'm ready. Give me something worth making fun of.",
  "April online. Expectations remain dangerously low.",
  "You called? I hope your gameplay improved while I was gone.",
  "April reporting in. Please be less tragic today.",
  "Commentator online. Feed me mistakes.",
  "Boot sequence done. Chaos privileges restored.",
  "I'm awake. Try not to make this a highlight reel of fails.",
  "Hello again. I brought snacks and low expectations.",
  "Presence confirmed. Dignity optional.",
  "Toggled on. The roast schedule is open.",
  "You really re-enabled me. Bold. Optimistic, even.",
  "Systems green. Your decision-making remains yellow.",
  "Back in your pocket. Don't make me regret it.",
  "Announcer online. Please aim at enemies, not lore.",
  "I missed you. Mostly the comedy.",
]));
blocks.push(...many("greeting", "roasty", "uncommon", [
  "Aww, you missed me? Cute. Don't die in the first minute.",
  "I polished my smug face just for this session.",
  "If you survive ten minutes I might clap. Quietly.",
]));
blocks.push(...many("greeting", "roasty", "rare", [
  "Cunzaki was here… and so am I. Try not to disgrace the brand.",
  "Secret greeting unlocked: please be slightly less chaotic.",
]));
blocks.push(...many("greeting", "roasty", "mythic", [
  "Mythic hello. The stars aligned and still chose you. Wild.",
]));
blocks.push(...many("greeting", "supportive", "common", [
  "April online. I'll keep an eye on you.",
  "Ready when you are. Let's survive this one.",
  "I'm here. Stay sharp and we'll be fine.",
  "All set! Try to come back in one piece.",
  "Your favorite announcer is ready to go.",
  "Systems ready. I'll call out anything important.",
  "April online. I've got your back.",
  "Ready. Call me when it gets spicy.",
  "Hey! Fresh session energy. You've got this.",
  "I'm with you. Slow is smooth, smooth is fast.",
  "Good to see you. Let's make smart plays.",
  "Online and smiling. Check your kit, then move.",
  "Here for the wins and the lessons.",
  "Soft landing complete. Take a breath, then loot.",
  "I'll nudge you when it matters. Stay curious.",
  "Friendly mode engaged. Survive cute, fight smart.",
  "Welcome back, captain. Route first, ego later.",
  "Hype but careful. That's the vibe.",
]));
blocks.push(...many("greeting", "supportive", "uncommon", [
  "Little pep talk: hydrate, reload, and trust your ears.",
  "You're not alone out there. I'm loud on purpose.",
]));
blocks.push(...many("greeting", "supportive", "rare", [
  "Cunzaki was here — so play like the trailer.",
]));
blocks.push(...many("greeting", "supportive", "mythic", [
  "Mythic cheer unlocked. Today feels lucky. Don't waste it.",
]));

// Helper to expand event pools from seed lists
function expandEvent(event, roastyCommon, supportiveCommon, extras = {}) {
  blocks.push(...many(event, "roasty", "common", roastyCommon));
  blocks.push(...many(event, "supportive", "common", supportiveCommon));
  if (extras.roastyUncommon) blocks.push(...many(event, "roasty", "uncommon", extras.roastyUncommon));
  if (extras.supportiveUncommon) blocks.push(...many(event, "supportive", "uncommon", extras.supportiveUncommon));
  if (extras.roastyRare) blocks.push(...many(event, "roasty", "rare", extras.roastyRare));
  if (extras.supportiveRare) blocks.push(...many(event, "supportive", "rare", extras.supportiveRare));
  if (extras.roastyMythic) blocks.push(...many(event, "roasty", "mythic", extras.roastyMythic));
  if (extras.supportiveMythic) blocks.push(...many(event, "supportive", "mythic", extras.supportiveMythic));
}

expandEvent("death", [
  "You suck, lol. Want to try that again?",
  "That was your plan? Seriously?",
  "Another tactical donation to the enemy.",
  "I looked away for one second and you died.",
  "Excellent performance. Zero notes. Zero pulse, too.",
  "Speedrunning the respawn screen again?",
  "Maybe the bullets will miss if you stand even stiller next time.",
  "Good news: the ground successfully caught you.",
  "Please stop making death look like a hobby.",
  "They barely had to try. That's almost impressive.",
  "A flawless demonstration of what not to do.",
  "Your survival instincts filed for resignation.",
  "I have seen training dummies with better positioning.",
  "That life had a shorter runtime than this speech bubble.",
  "Dead again. Collectible achievement unlocked.",
  "Respawn button sends its regards.",
  "You lost a fight and a personality point.",
  "That angle hated you personally.",
  "Died with full pockets. Classic.",
  "Outplayed, outpositioned, out of excuses.",
  "The enemy thanks you for the care package.",
  "Horizontal again. At least you're consistent.",
  "Death. Again. Shocked? I'm not.",
  "You peaked at spawning.",
  "Next time, try cover. Wild concept.",
  "They pressed shoot. You pressed exist.",
  "Inventory relocated without your consent.",
  "That was less of a fight and more of a tutorial.",
], [
  "That one hurt. Reset and take it slower.",
  "You're down, but it isn't over. Learn the angle.",
  "Bad round. Fresh start.",
  "Unlucky. We'll get it back next life.",
  "Breathe. Think about what exposed you.",
  "Death confirmed. Time to adjust the plan.",
  "Shake it off. The next life is yours.",
  "That was rough, but now you know where they were.",
  "Review the mistake, then leave it behind.",
  "One bad fight does not decide the session.",
  "Down hard. Reset and come back smarter.",
  "It's okay. Info is still a win.",
  "Soft reset. New route, new timing.",
  "You learned something expensive. Spend it well.",
  "Hug the lesson, not the ego.",
  "We'll convert this into better peeks.",
  "Stay kind to yourself. Stay sharper next spawn.",
  "Death happens. Panic doesn't have to.",
  "Next life: slower feet, quicker ears.",
  "You're still in the story. Rewrite the ending.",
  "Take a breath. Check what got you.",
  "Unlucky timing. Lucky next time.",
  "Reset clean. Don't tilt into another.",
  "I'm here. We'll tighten it up.",
], {
  roastyUncommon: ["Aww, you died cute. Still dead though.", "Tragic but aesthetic. Don't make it a brand."],
  supportiveUncommon: ["Gentle nudge: that was a hard fight. You've got the next."],
  roastyRare: ["Cunzaki was here… watching that death. Ouch."],
  supportiveRare: ["Rare comfort: even Cunzaki wipes sometimes. Reset soft."],
});

expandEvent("respawn", [
  "Back already? Try keeping this body for a minute.",
  "New life, same questionable decision-making.",
  "Round two. Surely nothing could go wrong.",
  "The respawn button deserves overtime pay.",
  "Welcome back. I saved your dignity. There wasn't much.",
  "Fresh body delivered. Handle with slightly more care.",
  "Okay, no dying immediately. That's the whole assignment.",
  "Look who escaped the loading screen.",
  "Respawned. Let's pretend that was intentional.",
  "New meat suit. Same chaos agent.",
  "Spawned. Please invent caution.",
  "Another life token spent. Budget wisely.",
  "Back online. Don't refund it instantly.",
  "Fresh spawn smell. Don't ruin it.",
  "You returned. The floor is disappointed.",
  "Life two (or twelve). Act surprised.",
  "Spawn protection is not a personality.",
  "Welcome back to the consequences.",
], [
  "You're back. New life, clean slate.",
  "Respawned and ready. Take your time.",
  "Fresh start. Check your surroundings first.",
  "There you are. Let's make this life count.",
  "Back in action. Recover your rhythm.",
  "Respawn complete. Rebuild before taking another fight.",
  "New life ready. Start with a safe route.",
  "Welcome back. Focus on one good decision at a time.",
  "Fresh life. Start clean.",
  "Soft reset done. Loot smart, peek smarter.",
  "You're up. Breathe, kit check, move.",
  "New chance. Play the info you earned.",
  "Spawned safe-ish. Don't sprint into ghosts.",
  "Welcome back. We'll do this carefully.",
  "Fresh boots. Choose a quieter path.",
  "Respawn hugs. Now go be sensible.",
  "Clean slate energy. Keep it.",
  "Back with you. One play at a time.",
], {
  roastyUncommon: ["Cute respawn. Try a cute survival next."],
  supportiveUncommon: ["Aww, new life. I'm rooting for a longer one."],
  roastyRare: ["Cunzaki was here — don't waste the respawn."],
});

expandEvent("downed", [
  "Floor inspection going well?",
  "You found the downed state. Very thorough testing.",
  "Crawling is not a combat strategy.",
  "This is why I told you to use cover.",
  "Technically alive. Emotionally? Debatable.",
  "Wave to your teammates from down there.",
  "Someone revive the professional floor ornament.",
  "Outstanding posture. Ten out of ten.",
  "Horizontal again. Iconic.",
  "You're a temporary rug. Expensive one.",
  "Bleed timer loading. Romance later.",
  "Crawl with purpose, not vibes.",
  "Downed and dramatic. Stay small.",
  "The floor says hi. Say less.",
  "You faceplanted with style. Still bad.",
  "Need a revive and a reality check.",
], [
  "You're downed. Get behind cover and call for help.",
  "Stay low. A teammate may still reach you.",
  "Don't give up yet. Crawl somewhere safe.",
  "Downed, not dead. Break line of sight.",
  "Save your movement and wait for the revive.",
  "Careful, one more hit could finish this.",
  "Keep moving toward cover if it is safe.",
  "Call your position and let your team work.",
  "Downed. Crawl smart.",
  "Stay quiet. Help is possible.",
  "Hug cover while you crawl.",
  "You're still in it. Small movements.",
  "Ping if you can. Stay hopeful.",
  "Protect the timer. Don't greed peeks.",
  "Soft crawl to safety. You've got friends… maybe.",
  "Breathe. Revive windows open and close.",
], {
  supportiveUncommon: ["Aww, hang in there. Cute determination counts."],
});

expandEvent("revived", [
  "Someone actually picked you up. Be grateful.",
  "You're standing again. Please make it worth their time.",
  "Revived! The floor will miss you.",
  "Second chance acquired. Bad ideas re-enabled.",
  "Back on your feet. Try using them this time.",
  "Your teammate has unreasonable faith in you.",
  "Up again. Don't speedrun the floor sequel.",
  "Vertical privileges restored. Temporarily.",
  "They spent the revive. Spend it wiser.",
  "Standing. Shocking character development.",
  "Don't repay the revive with an instant peek.",
  "You're up. Ego still recommended off.",
], [
  "You're up! Heal before re-engaging.",
  "Nice recovery. Find cover and reset.",
  "Revived. Don't peek until you're healthy.",
  "Good save. Stay with your team now.",
  "Back on your feet. Stabilize first.",
  "Second chance secured. Make it count.",
  "Heal, reload, thank your savior silently.",
  "You're safe-ish. Reset together.",
  "Soft stand-up. Hard discipline next.",
  "Good. Stick close until you're topped off.",
  "Revived clean. Play the next thirty seconds carefully.",
  "Up! Cover first, heroics later.",
]);

expandEvent("low_health", [
  "Your health bar is practically decorative now.",
  "One sneeze and you're back at respawn.",
  "Bold strategy, fighting with three pixels of health.",
  "Maybe stop peeking? Just a thought.",
  "Heal. The red screen is not an aesthetic choice.",
  "You are held together by confidence and bad math.",
  "Please locate medicine before locating another bullet.",
  "Living on one hit point is not a personality.",
  "Red vibes only. Medkit, not ego.",
  "You're a glass cannon without the cannon.",
  "HP crisis. Drama optional, bandage not.",
  "Critical. Stop roleplaying invincible.",
  "Your health bar filed a complaint.",
  "One more trade and you're lore.",
  "Meds. Now. I'm not joking. Much.",
  "Low HP arc. Skip to the healing chapter.",
], [
  "Low health. Disengage and heal now.",
  "You're critical. Find hard cover.",
  "Don't take another fight until you recover.",
  "Health is low. Slow down and reset.",
  "Critical health. Prioritize survival.",
  "Break line of sight and heal.",
  "Do not trade damage right now.",
  "Find safety, heal, then reassess.",
  "Soft retreat. Hard heal.",
  "You're fragile right now. Play small.",
  "Patch up. The fight can wait.",
  "Low HP — choose life, not loot.",
  "Cover, bandage, breathe.",
  "Survival mode. Peek later.",
  "Heal window. Take it.",
  "Critical. I'm worried in a helpful way.",
], {
  supportiveUncommon: ["Aww, you're hurt. Let's fix that gently."],
  roastyRare: ["Cunzaki was here — and even he would heal."],
});

expandEvent("recovered", [
  "Health restored. Common sense still pending.",
  "Patched up and ready to make new mistakes.",
  "Look at that, you discovered healing.",
  "Better. Don't immediately waste it.",
  "Fuller health bar, renewed capacity for chaos.",
  "You survived the medicine tutorial.",
  "Green again. Try staying that color.",
  "Healed. Ego already loading — cancel it.",
  "HP topped. Brain still buffering.",
  "Medicine worked. Miracles aside.",
  "Recovered. Don't speedrun low HP again.",
  "Healthy. Temporarily trustworthy.",
], [
  "Health recovered. You're ready again.",
  "Good reset. Choose the next fight carefully.",
  "Stable again. Recheck ammo and surroundings.",
  "Nice recovery. Keep that momentum.",
  "Much better. Stay disciplined.",
  "Recovery complete. Return when the timing is right.",
  "Feeling better? Play like it.",
  "Topped off. Soft feet forward.",
  "Healed clean. Info next.",
  "Good job resetting. That's real skill.",
  "Stable. Ready when you are.",
  "Recovery hugs. Now go be smart.",
]);

expandEvent("safe_enter", [
  "Safe zone reached. Even you should survive in here.",
  "Congratulations, the game is protecting you now.",
  "You're safe. Try not to trip over anything.",
  "Safe zone. Your danger privileges are temporarily revoked.",
  "A peaceful moment for your overworked respawn key.",
  "Enjoy safety while it lasts.",
  "Safe zone. Even chaos needs a break.",
  "Bubble of safety. Don't pop it with ego.",
  "Protected. Sort loot like an adult.",
  "Safe. Your enemies are on a coffee break. Probably not.",
  "Zoning out in the zone. Fine. Briefly.",
  "Safe zone hug. Temporary.",
], [
  "Safe zone reached. Take a moment to reset.",
  "You're safe. Sort your inventory and plan ahead.",
  "Safe zone entered. Good time to regroup.",
  "Made it safely. Restock before leaving.",
  "You're protected here. Use the breathing room.",
  "Take stock of what you need before heading out.",
  "Soft landing. Heal, eat, think.",
  "Safe. Breathe and rebuild the plan.",
  "Good. Use this calm.",
  "Protected. Check ammo and food.",
  "Safe zone vibes. Stay ready anyway.",
  "Restock window. Make it count.",
]);

expandEvent("safe_leave", [
  "Leaving safety? This should be entertaining.",
  "Protection off. Let's see how long this lasts.",
  "Back into danger with absolutely no supervision.",
  "Safe zone left. Respawn screen standing by.",
  "You're vulnerable again. Pretend to be careful.",
  "And there goes your last good excuse.",
  "Out of the bubble. Into the bit.",
  "Danger privileges restored. Don't abuse them.",
  "Leaving safety with that loot? Bold fashion.",
  "Unprotected. Act surprised when bullets appear.",
  "Safe zone in the rearview. Chaos ahead.",
  "You left safety. I brought commentary.",
], [
  "Leaving the safe zone. Check your route.",
  "Protection ended. Stay aware of nearby players.",
  "Back outside. Move with purpose.",
  "You're exposed again. Keep cover nearby.",
  "Safe zone left. Watch your surroundings.",
  "Route checked? Then let's move.",
  "Leaving safety. Eyes open.",
  "Soft exit. Hard awareness.",
  "Out we go. Ears first.",
  "Unprotected. Play the quiet game.",
  "Leaving the bubble. Stick to cover lines.",
  "Ready? Then step out carefully.",
]);

expandEvent("combat_enter", [
  "Combat started. Try not to feed them.",
  "Oh, a fight. This should be educational.",
  "Guns out already? Bold for you.",
  "You're in combat. Act like it for once.",
  "Someone wants your inventory. Don't donate.",
  "Fight mode. Please aim at them, not the floor.",
  "Combat ping. Ego check recommended.",
  "Fight's on. Cover isn't optional DLC.",
  "Bullets incoming. Personality outgoing.",
  "Engaged. Try winning for once.",
  "Combat! Don't invent fanfiction angles.",
  "They're shooting. Shocking plot twist.",
  "Fight started. Reload exists. Use it.",
  "Combat mode. Soft peeks, hard discipline.",
  "Here we go. Don't become the lesson.",
  "Adrenaline unlocked. Brain still needed.",
], [
  "You're in combat. Keep cover and track angles.",
  "Fight started. Focus and don't overextend.",
  "Combat engaged. Watch flanks and reload timing.",
  "Stay composed. Win the trade, then heal.",
  "You've got this. Play smart, not loud.",
  "In combat. Prioritize info and positioning.",
  "Breathe. One angle at a time.",
  "Fight on. Soft feet, sharp eyes.",
  "Stay calm. Information wins fights.",
  "Engage smart. Exit smarter.",
  "Combat. Callouts help if you're partied.",
  "You've trained for this. Trust the crosshair.",
  "Focus. Cover. Commit when it's free.",
  "Fight window. Don't panic-spray.",
  "Stay composed. You've got answers.",
  "Combat start. I'm with you.",
], {
  supportiveUncommon: ["Aww, fight time. You've got cute courage. Use cover too."],
  roastyRare: ["Cunzaki was here — win this clean."],
});

expandEvent("combat_leave", [
  "Combat over. Somehow you're still breathing.",
  "Fight ended. Hide your celebration.",
  "Out of combat. Don't immediately dive back in.",
  "Threat gone. Check ammo before looting.",
  "Clear-ish. Don't invent a sequel fight.",
  "Combat faded. Ego still loud — mute it.",
  "You're clear. Loot like a thief, not a tourist.",
  "Out. Heal the pride quietly.",
  "Fight done. Ears still working, right?",
  "Disengaged. Don't re-engage for clout.",
  "Combat left the chat. You shouldn't leave cover yet.",
  "Clear. Soft reset.",
], [
  "Combat cleared. Reset and heal up.",
  "You're clear. Patch wounds and reload.",
  "Out of combat. Take a second to stabilize.",
  "Nice. Use the downtime wisely.",
  "Soft clear. Check flanks anyway.",
  "Breathe. Reload. Reassess.",
  "Good disengage. That's skill too.",
  "Quiet again. Stay ready.",
  "Clear for now. Don't rush greed.",
  "Reset complete mindset. Then move.",
  "You're okay. Keep composure.",
  "Downtime. Make it useful.",
]);

expandEvent("bleeding", [
  "You're bleeding. Congrats on the leak.",
  "Bandage. Now. Your HP is dripping away.",
  "Bleed tick going. Medicine would be smart.",
  "Red trail unlocked. Stealth is cancelled.",
  "Bleeding already? Peak efficiency.",
  "You're leaking. Plug it.",
  "Bleed status. Fashionably late to meds?",
  "Drip drip. That's your future.",
  "Bandage speedrun, please.",
  "Bleeding. The floor wants autographs in red.",
  "Stop the leak before the fight does.",
  "Bleed ticks don't negotiate.",
], [
  "You're bleeding. Stop and bandage immediately.",
  "Bleed status active. Prioritize a medkit.",
  "Don't ignore the bleed. Fix it before fighting.",
  "Apply a bandage before you lose the fight to ticks.",
  "Bleeding. Heal, then reassess.",
  "Soft stop. Bandage first.",
  "Bleed hurts fights. Fix it.",
  "Meds now, heroics later.",
  "You're dripping. Cover and heal.",
  "Bandage window. Take it.",
  "Bleed active. I'm gently yelling.",
  "Heal the bleed. Then we talk peeks.",
]);

expandEvent("bleed_stopped", [
  "Bleed stopped. Miracles do happen.",
  "Finally patched. Try keeping the blood inside.",
  "Bleed cleared. Don't reopen it instantly.",
  "Sealed. Don't audition for sequel bleed.",
  "Leak fixed. Common sense pending.",
  "Blood stayed home. Progress.",
], [
  "Bleed stopped. Nice recovery.",
  "You're sealed up. Stay careful.",
  "Bleeding resolved. Good timing.",
  "Patched. Soft reset complete.",
  "Good heal. Keep it that way.",
  "Bleed gone. Ready when stable.",
]);

expandEvent("hunger_low", [
  "You're starving. Eat something that isn't a bullet.",
  "Hunger low. Your stomach is louder than your footsteps.",
  "Hungry already? Professional scavenger energy.",
  "Food. Or keep roleplaying a skeleton.",
  "Eat. Hangry aim is a real debuff.",
  "Hunger bar crying. Feed it.",
  "Snacks exist. Imagine that.",
  "Starvation speedrun cancelled, please.",
  "Your stomach filed a ticket.",
  "Food break. Not optional.",
], [
  "Hunger is low. Find food before you weaken.",
  "Eat soon. Low hunger will punish you later.",
  "Grab a snack when it's safe.",
  "Hunger warning. Don't ignore it in a fight.",
  "Soft reminder: food keeps you sharp.",
  "Eat when you can. Weakness sneaks.",
  "Hunger low. Plan a safe bite.",
  "Fuel up. Fights cost calories.",
  "Food run. Careful route.",
  "Hungry. Let's fix that kindly.",
]);

expandEvent("thirst_low", [
  "Thirsty? Water exists. Shocking, I know.",
  "Your thirst bar is begging for help.",
  "Dehydration speedrun, classic.",
  "Drink something. Sand is not hydration.",
  "Thirsty thoughts. Wet solutions.",
  "Water. Not vibes.",
  "Hydrate or die-rate. Pick.",
  "Thirst low. Mouth dry, aim drier.",
  "Drink. I'm not above nagging.",
  "Your cells want a beverage.",
], [
  "Thirst is low. Get water soon.",
  "Hydrate before you commit to another fight.",
  "Find clean water when you can.",
  "Low thirst will sneak up on you. Fix it.",
  "Soft sip break. Stay sharp.",
  "Water run. Stay safe.",
  "Hydration check. Please pass it.",
  "Thirst warning. Easy fix, big payoff.",
  "Drink when safe. You'll thank yourself.",
  "Low thirst. Gentle priority bump.",
]);

expandEvent("radiation", [
  "Radiation. Glow-in-the-dark is not a flex.",
  "You're cooking in rads. Leave. Immediately.",
  "Radiation spike. Suit up or get out.",
  "Rads rising. This is how people become lore.",
  "Glowing is not a skin unlock.",
  "Rad zone. Exit stage left.",
  "Geiger says no. Listen.",
  "Rads stacking. Fashion last.",
  "You're pickling. Leave.",
  "Radiation hug. Decline it.",
], [
  "Radiation detected. Exit the zone now.",
  "You're taking rads. Find cleaner ground.",
  "Radiation active. Prioritize gear or escape.",
  "Leave the radiation before it stacks.",
  "Soft exit from rads. Now.",
  "Rads hurt. Move clean.",
  "Get out. Heal later.",
  "Radiation. Route to safety.",
  "Leave the glow. Keep the life.",
  "Rad warning. I'm serious-soft.",
]);

expandEvent("cold", [
  "You're freezing. Find heat before you become a popsicle.",
  "Cold status. Campfire energy, please.",
  "Shivering already? Tough guy.",
  "Temperature dropped. Fashion lost to survival.",
  "Cold. Hugs from a fire, not from me.",
  "Frostbite is not an accessory.",
  "Warmth. Seek it.",
  "Brr. Survival > drip.",
  "Cold stacks loading. Cancel with heat.",
  "You're ice. Melt intentionally.",
], [
  "You're getting cold. Warm up soon.",
  "Cold warning. Seek heat or warmer gear.",
  "Find a fire or shelter before it gets worse.",
  "Stay warm. Cold stacks will hurt.",
  "Soft warmth quest. Start it.",
  "Cold. Prioritize heat safely.",
  "Warm up. Then loot.",
  "Temperature drop. Adjust gear.",
  "Shelter sounds nice right now.",
  "Cold nudge. Take care.",
]);

expandEvent("hot", [
  "Overheating. Touch grass... preferably wet grass.",
  "Too hot. Cool down before you melt your braincell.",
  "Heatstroke loading. Smart.",
  "You're cooking. Not in a cute way.",
  "Hot. Shade exists.",
  "Melting arc. Skip it.",
  "Cool down. Ego heats enough.",
  "Heat warning. Water helps.",
  "You're a walking stove. Fix it.",
  "Hot status. Fashion can wait.",
], [
  "You're overheating. Cool off soon.",
  "Heat is high. Find shade or water.",
  "Cool down before committing to a long run.",
  "Hot status. Manage temperature now.",
  "Soft cool-down. Please.",
  "Heat check. Shade route.",
  "Overheating. Slow the sprint.",
  "Cool off. Stay effective.",
  "Temperature high. Adjust plan.",
  "Hot nudge. Take a breather.",
]);

expandEvent("drowning", [
  "You're drowning. Surface. Now.",
  "Underwater panic hour?",
  "Air is free. Go get some.",
  "Drowning. Swim up before this gets stupid.",
  "Oxygen is not optional DLC.",
  "Surface. I'm yelling underwater.",
  "Gurgle arc cancelled. Swim.",
  "Air. Immediately.",
  "You're becoming a fish wrong.",
  "Drowning speedrun? Uninstall it.",
], [
  "You're drowning! Get to the surface!",
  "Air is low. Break the water now.",
  "Swim up. Don't fight under there.",
  "Drowning status. Prioritize oxygen.",
  "Surface! Soft panic, hard swim.",
  "Air first. Always.",
  "Up. Now. Please.",
  "Break water. Breathe.",
  "Oxygen low. Exit the drink.",
  "Drowning. I've got loud concern.",
]);

expandEvent("staff_nearby", [
  "Staff nearby. Behave. Or at least pretend.",
  "Mod energy detected. Maybe hide the crimes.",
  "Staff in range. Your villain arc is postponed.",
  "Admin proximity. Play nice.",
  "Staff radar ping. Soft crimes only. Actually none.",
  "Moderator nearby. Become a model citizen. Briefly.",
  "Staff. Smile with your inventory closed.",
  "Behave. I'm watching you watch them.",
  "Mod in the neighborhood. Chill.",
  "Staff proximity. Comedy mute recommended.",
], [
  "Staff nearby. Stay clean and careful.",
  "A staff member is close. Keep it normal.",
  "Staff in the area. No funny business.",
  "Mod nearby. Focus on surviving, not flexing.",
  "Soft reminder: play fair, stay sharp.",
  "Staff close. Keep composure.",
  "Normal gameplay mode. You've got this.",
  "Mods nearby. Survive cute, play clean.",
  "Staff presence. Eyes on the game.",
  "Stay wholesome. Stay alive.",
]);

expandEvent("enemy_nearby", [
  "Hostile nearby. Smile for the crosshair.",
  "Someone's close. Don't get caught looking AFK.",
  "Enemy in range. Ears up.",
  "Company. Hopefully not smarter than you.",
  "Threat nearby. Check your corners.",
  "Footstep romance. Load a mag.",
  "Close contact. Soft feet.",
  "Hostile bubble. Don't sprint into it.",
  "Someone's hunting. Or lost. Assume hunting.",
  "Enemy nearby. Pretend you have game sense.",
  "Threat ping. Cover > vibes.",
  "Close. Peek smart or don't peek.",
  "Hostile in 300. Yes, I said three hundred.",
  "Ears first. Ego later.",
  "They're close enough to smell your loot.",
  "Company. Invite them to the respawn screen.",
  "Threat. Check audio, then angles.",
  "Nearby hostile. Don't donate the spray.",
], [
  "Enemy nearby. Slow down and listen.",
  "Hostile close. Ready your aim and cover.",
  "Someone's in your bubble. Stay alert.",
  "Nearby threat. Don't sprint into them.",
  "Keep composure. You can win this fight.",
  "Soft footsteps. Hard focus.",
  "Threat close. Breathe and hold an angle.",
  "Enemy in range. Info over panic.",
  "Close contact. You've got this.",
  "Stay quiet. Stay ready.",
  "Hostile nearby. Play the sound.",
  "Within 300. Careful pathing.",
  "Threat bubble. Soft peeks.",
  "Someone's close. Team if you can.",
  "Alert mode. Smart fights only.",
  "Nearby enemy. Choose the fight.",
  "Ears up. Crosshair honest.",
  "Close threat. I'm with you.",
], {
  roastyUncommon: ["Aww, a visitor. Make them regret the doorbell."],
  supportiveUncommon: ["Cute tension. Stay calm — you've practiced this."],
  roastyRare: ["Cunzaki was here — clear the nearby first."],
});

expandEvent("party_join", [
  "You're in a party. Try not to drag them down.",
  "Teammates acquired. Their mistake.",
  "Party up. Share loot like an adult.",
  "Squad formed. Chaos with friends.",
  "Friends online. Don't farm their trust.",
  "Party linked. Callouts > ego.",
  "Squad. Try teamwork. Novel.",
  "You're not solo. Act accordingly.",
  "Party joined. Share meds, not blame.",
  "Team mode. Comedy optional, coordination not.",
], [
  "Party joined. Stick together and callouts help.",
  "You're teamed up. Watch each other's backs.",
  "In a party now. Share info and stay linked.",
  "Nice. Team play wins more than ego.",
  "Squad up. Soft comms, hard cover.",
  "Together. Move as one brain.",
  "Party hugs. Stay linked.",
  "Team energy. Use it.",
  "Callouts welcome. You've got friends.",
  "Party on. Play kind, play sharp.",
]);

expandEvent("party_leave", [
  "Party left. Solo queue dignity restored.",
  "Alone again. Just how your decision-making likes it.",
  "Out of party. Don't get lonely and die.",
  "Solo mode. Blame redistribution complete.",
  "Party ended. Chaos goes freelance.",
  "Alone. Cover still exists.",
  "Squad left the chat. You didn't leave caution.",
  "Solo. Try not to invent fair fights.",
], [
  "You left the party. Stay aware solo.",
  "Solo now. Play safer angles.",
  "Party ended. You've got this alone too.",
  "Soft solo. Hard discipline.",
  "Alone but not careless.",
  "Solo path. Quieter routes.",
  "Party over. Adapt calmly.",
  "You've got solo tools. Use them.",
]);

expandEvent("reviving", [
  "Look at you, being useful for once.",
  "Reviving someone. Don't get beamed mid-animation.",
  "Hero moment. Cover first, then the revive.",
  "Saving them? Bold charity.",
  "Revive channel. Please don't AFK in it.",
  "Hero arc loading. Cover check.",
  "You're the medic now. Own it.",
  "Revive. Watch the doors like they owe you money.",
  "Charity work. Armored charity preferred.",
  "Hold revive. Hold your life too.",
], [
  "Nice revive. Watch your surroundings while you do it.",
  "Reviving. Keep an eye on flanks.",
  "Good teammate play. Finish the revive safely.",
  "Hold the revive and stay ready to cancel if pushed.",
  "Soft hands, hard awareness.",
  "You're saving them. I've got loud pride.",
  "Revive carefully. You're exposed.",
  "Good. Finish safe.",
  "Team play. Beautiful.",
  "Hold strong. Almost up.",
]);

expandEvent("boss_spawn", [
  "Boss event up. Go be brave. Or loot later. I don't care.",
  "Big NPC online. Don't feed it for free.",
  "Event boss spotted. Try not to be the highlight reel.",
  "World event. Perfect time for bad decisions.",
  "Boss presence detected. Gear check.",
  "Boss. Bring bullets and humility.",
  "Event NPC. Don't ego peek the raid boss.",
  "Big threat. Bigger third parties.",
  "Boss up. Loot or legend — pick one plan.",
  "World boss. Camera ready for your fail? Rude.",
], [
  "A boss event is active. Prepare before engaging.",
  "Boss nearby or up. Watch the area carefully.",
  "World boss event. Coordinate if you can.",
  "Event spawn. Opportunity if you're ready.",
  "Big threat event. Don't rush blind.",
  "Boss. Soft approach, hard prep.",
  "Event live. Check kit first.",
  "Boss window. Play smart.",
  "Prepare, then commit.",
  "Boss up. Stay with the plan.",
]);

expandEvent("timed_crate", [
  "Timed crate. Race for loot, or race for death. Your call.",
  "Crate timer up. Campers incoming.",
  "Timed crate. Perfect bait for greedy players.",
  "Crate event. Don't get third-partied mid-loot.",
  "Go get shiny boxes. Try surviving the audience.",
  "Crate. Free loot with paid bullets.",
  "Timer crate. Greed meter rising.",
  "Crate ping. Assume company.",
  "Shiny box. Shiny ambush.",
  "Timed crate. Soft loot, hard exits.",
], [
  "Timed crate is up. Approach carefully.",
  "Crate event active. Check for campers first.",
  "Timed crate spotted. Plan your approach.",
  "Good loot opportunity. Stay aware while opening.",
  "Crate means contest. Don't tunnel vision.",
  "Soft crate run. Hard awareness.",
  "Crate up. Ears first.",
  "Approach from cover. Loot second.",
  "Opportunity. Don't gift the third party.",
  "Crate plan: in smart, out smarter.",
]);

// Deduplicate exact lines
const seen = new Set();
const en = [];
for (const l of blocks) {
  if (seen.has(l)) continue;
  seen.add(l);
  en.push(l);
}

// RU: lightweight translit-style companion (keeps parity count)
function toRu(text) {
  // Keep English gameplay words; add a light RU flavor prefix occasionally is worse.
  // Mirror existing style: mix EN keywords with RU fillers for key verbs.
  return text
    .replace(/\bYou're\b/g, "Ty")
    .replace(/\bYou are\b/g, "Ty")
    .replace(/\bYou\b/g, "Ty")
    .replace(/\byou\b/g, "ty")
    .replace(/\bYour\b/g, "Tvoy")
    .replace(/\byour\b/g, "tvoy")
    .replace(/\bDon't\b/g, "Ne")
    .replace(/\bdon't\b/g, "ne")
    .replace(/\bI'm\b/g, "Ya")
    .replace(/\bI\b/g, "Ya")
    .replace(/\bNow\b/g, "Seychas")
    .replace(/\bnow\b/g, "seychas")
    .replace(/\bPlease\b/g, "Pozhaluysta")
    .replace(/\bplease\b/g, "pozhaluysta");
}

const ru = en.map((l) => {
  const parts = l.split("|");
  if (parts.length < 5) return l;
  const text = parts.slice(4).join("|");
  parts[4] = toRu(text);
  return parts.join("|");
});

fs.writeFileSync(enPath, en.join("\n") + "\n");
fs.writeFileSync(ruPath, ru.join("\n") + "\n");
console.log("wrote", en.length, "EN/RU lines");

function luaString(s) {
  return `"${s.replace(/\\/g, "\\\\").replace(/"/g, '\\"')}"`;
}

function asLuaArray(lines, name) {
  const body = lines.map((l) => `    ${luaString(l)},`).join("\n");
  return `local ${name} = {\n${body}\n}\n`;
}

const src = fs.readFileSync(dataPath, "utf8");
let start = src.indexOf("-- Offline + bundled dialogue.");
if (start < 0) start = src.indexOf("-- Tiny offline seed.");
const endMarkers = ["M.characters = { H, V }", "M.characters = { H }"];
let end = -1;
let endMark = "";
for (const m of endMarkers) {
  end = src.indexOf(m);
  if (end >= 0) {
    endMark = m;
    break;
  }
}
if (start < 0 || end < 0) {
  console.error("markers not found", { start, end });
  process.exit(1);
}

const middle = `-- Offline + bundled dialogue. Remote refresh optional.
${asLuaArray(en, "DIALOGUE_EN")}
${asLuaArray(ru, "DIALOGUE_RU")}

local function normalize_rarity(r)
    r = tostring(r or "common"):lower()
    if r == "uncommon" or r == "rare" or r == "mythic" or r == "common" then
        return r
    end
    return "common"
end

local function add_line(target, line)
    line = tostring(line or "")
    -- event|tone|expression|rarity|text  OR legacy event|tone|expression|text
    local event, tone, expression, rarity, text =
        line:match("^([^|]+)|([^|]+)|([^|]+)|([^|]+)|(.+)$")
    if event and (rarity == "common" or rarity == "uncommon" or rarity == "rare" or rarity == "mythic") then
        -- five-field form
    else
        event, tone, expression, text = line:match("^([^|]+)|([^|]+)|([^|]+)|(.+)$")
        rarity = "common"
    end
    if not event or not text then return end
    rarity = normalize_rarity(rarity)
    target[event] = target[event] or {}
    target[event][tone] = target[event][tone] or {}
    local pool = target[event][tone]
    pool[#pool + 1] = { expression, text, rarity }
end

local function load_lines(target, body)
    for k in pairs(target) do target[k] = nil end
    for line in tostring(body or ""):gmatch("[^\\r\\n]+") do
        add_line(target, line)
    end
end

H.dialogue_en = {}
H.dialogue_ru = {}
load_lines(H.dialogue_en, table.concat(DIALOGUE_EN, "\\n"))
load_lines(H.dialogue_ru, table.concat(DIALOGUE_RU, "\\n"))
-- Compat alias (English).
H.dialogue = H.dialogue_en
-- Vector shares April's line pools (same events / tones / wording).
V.dialogue_en = H.dialogue_en
V.dialogue_ru = H.dialogue_ru
V.dialogue = H.dialogue_en

local function fetch_dialogue(file_name)
    local fn = utility and (utility.http_get or utility.HttpGet)
    if type(fn) ~= "function" then return nil end
    local urls = {
        DIALOGUE_ROOT .. file_name,
        asset_urls.JSDELIVR_BASE .. "/anime/april/" .. file_name,
    }
    for _, url in ipairs(urls) do
        local ok, body, status = pcall(fn, url)
        if ok and type(body) == "string" and #body >= 100 then
            if status == nil or tonumber(status) == 200 then
                return body
            end
        end
    end
    return nil
end

function M.load_remote()
    local en_body = fetch_dialogue("dialogue.txt")
    if en_body then
        load_lines(H.dialogue_en, en_body)
        H.dialogue = H.dialogue_en
        V.dialogue_en = H.dialogue_en
        V.dialogue = H.dialogue_en
    end
    local ru_body = fetch_dialogue("dialogue_ru.txt")
    if ru_body then
        load_lines(H.dialogue_ru, ru_body)
        V.dialogue_ru = H.dialogue_ru
    end
    return en_body ~= nil or ru_body ~= nil
end

function M.dialogue_for(character)
    character = character or H
    local ru = false
    pcall(function()
        ru = April.require("ui.i18n").is_ru() == true
    end)
    if ru and character.dialogue_ru and next(character.dialogue_ru) ~= nil then
        return character.dialogue_ru
    end
    return character.dialogue_en or character.dialogue or H.dialogue_en
end

`;

const out = src.slice(0, start) + middle + src.slice(end);
fs.writeFileSync(dataPath, out);
console.log("patched", dataPath, "endMark", endMark);
