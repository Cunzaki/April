#!/usr/bin/env node
/**
 * Build static game catalog from a repo dump/ folder for GC dump merge.
 *
 * Outputs:
 *   tools/gc_static_appendix.txt  — appended to gc_dump.txt after live dumpgc
 *   tools/gc_key_seeds.json         — all GC-relevant keys for targeted dumpgc pass
 *   tools/gc_key_seeds.lua          — Lua array for Vector loadfile
 *   tools/gc_preload_modules.lua    — modules to require before dump (loads ToolInfo/Items into heap)
 *
 * Run: node tools/build_gc_static_catalog.mjs
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DUMP_CANDIDATES = [
    path.join(ROOT, "July", "dump"),
    path.join(ROOT, "April Fallen", "dump"),
    path.join(ROOT, "June", "dump"),
    path.join(ROOT, "dump"),
];
const DUMP = DUMP_CANDIDATES.find((p) => fs.existsSync(p)) || DUMP_CANDIDATES[0];
const SCRIPTS = path.join(DUMP, "scripts");
const OUT_APPENDIX = path.join(ROOT, "tools", "gc_static_appendix.txt");
const OUT_JSON = path.join(ROOT, "tools", "gc_key_seeds.json");
const OUT_LUA_KEYS = path.join(ROOT, "tools", "gc_key_seeds.lua");
const OUT_PRELOAD = path.join(ROOT, "tools", "gc_preload_modules.lua");

const gcKeys = new Set();
const attachmentKeys = new Set();
const attributes = new Set();
const valuesRefs = new Set();
const items = new Set();
const weapons = new Set();

const KEY_PATTERNS = [
    /\b([A-Z][A-Za-z0-9_]*Mult)\b/g,
    /\b(RecoilMult|FireRateMult|GunRecoilAimMult|AimSpreadMult|HipSpreadMult|SpreadMult)\b/g,
    /\b(SpeedMult|RangeMult|SwayMult|MaxAmmoMult|GravityMult|ZoomLevel|DefaultZoomLevel)\b/g,
    /\b(Cooldown|SwingAnimSpeed|SwingSpeed|GatherMult|SparkMult|BounceMult|SoftSideMult)\b/g,
    /\b(RPM|ActualRPM|ReloadDuration|ReloadAnimSpeed|EquipAnimSpeed|BaseMaxAmmo|ExtraReloadDuration)\b/g,
    /\b(CraftSpeedMult|SmeltSpeedMult|ShredderSpeedMult|DemolishTimerMult|IgnoreGatherMult)\b/g,
    /\b(MaxStackMult|DespawnTimeMult|DecayDamageMult|ArmorPen|ArmorPenMult|HeadshotDamage|HeadshotDamageMult)\b/g,
    /\b(HideTracer|Scope|SReduction|BurstRPM|Burst|BleedMult|DamageMult|FuelMult|HoverMult|InputMult)\b/g,
    /\b(MuzzleDurability|ShatterChance|HumanoidMaxDamage|BoltAnimSpeed|AnimSpeed|AimForRecoilMult)\b/g,
    /\b(Cursed_Wood|Cursed_Metal|Cursed_Stone|Cursed_Twig|Cursed_Steel|Cursed_BenchWood|Cursed_BenchBarrel|Cursed_BenchVehicle)\b/g,
];

const GAME_KEY_FILTER =
    /Mult$|Cooldown|RPM|Damage|Reload|Spread|Recoil|Gather|Spark|Zoom|Scope|Ammo|Speed|Range|Sway|Gravity|Burst|Equip|Anim|Craft|Smelt|Armor|Headshot|Pen|Decay|Stack|Despawn|Bounce|SoftSide|Demolish|HideTracer|Tracer|Bleed|Fuel|Hover|Input|Shatter|Durability|Comfort|PowerOut|Cursed_|ActualRPM|Bolt|Swing|IgnoreGather|Shredder|MaxAmmo|DefaultZoom|Attachment|Melee|Type|Weapon|Bullet|Recoil|HumanoidMax/;

function addKey(k) {
    if (k && k.length >= 2 && k.length <= 64) gcKeys.add(k);
}

function scanText(text, opts = {}) {
    let m;
    for (const re of KEY_PATTERNS) {
        re.lastIndex = 0;
        let m;
        while ((m = re.exec(text))) addKey(m[1]);
    }

    const assign = /\n\s+([A-Z][A-Za-z0-9_]{1,48})\s*=\s*(?:-?\d|true|false|"[^"]*")/g;
    let a;
    while ((a = assign.exec(text))) {
        if (GAME_KEY_FILTER.test(a[1])) addKey(a[1]);
    }

    const attr = /GetAttribute\(\s*["']([A-Za-z0-9_]+)["']\s*\)/g;
    while ((m = attr.exec(text))) attributes.add(m[1]);

    const vals = /Values\.([A-Za-z0-9_]+)/g;
    while ((m = vals.exec(text))) {
        valuesRefs.add(m[1]);
        addKey(m[1]);
    }

    if (opts.attachmentStats) {
        const blocks = text.match(/AttachmentStats\s*=\s*\{[^}]+\}/gs) || [];
        for (const block of blocks) {
            const inner = /\n\s+([A-Za-z0-9_]+)\s*=/g;
            let innerM;
            while ((innerM = inner.exec(block))) {
                attachmentKeys.add(innerM[1]);
                addKey(innerM[1]);
            }
        }
    }
}

function isGameScript(filename) {
    if (!filename.endsWith(".lua")) return false;
    if (filename.includes("PlayerModule.")) return false;
    if (filename.includes("StarterPlayerScripts.PlayerModule")) return false;
    if (filename.includes("RelicsXYZ")) return false;
    return (
        filename.startsWith("ReplicatedStorage.") ||
        filename.startsWith("StarterPlayer.StarterCharacterScripts.") ||
        filename.startsWith("StarterPlayer.StarterPlayerScripts.") ||
        filename.startsWith("StarterGui.")
    );
}

function walkScripts(dir) {
    for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
        const p = path.join(dir, ent.name);
        if (ent.isDirectory()) walkScripts(p);
        else if (isGameScript(ent.name)) {
            try {
                scanText(fs.readFileSync(p, "utf8"), {
                    attachmentStats: ent.name.includes("Items.ModuleScript"),
                });
            } catch {
                /* skip */
            }
        }
    }
}

function parseItems() {
    const p = path.join(SCRIPTS, "ReplicatedStorage.Modules.Items.ModuleScript.lua");
    if (!fs.existsSync(p)) return;
    const text = fs.readFileSync(p, "utf8");
    scanText(text, { attachmentStats: true });
    const nameRe = /Name\s*=\s*"([^"]+)"/g;
    let m;
    while ((m = nameRe.exec(text))) items.add(m[1]);
}

function parseToolInfo() {
    const p = path.join(SCRIPTS, "ReplicatedStorage.Modules.ToolInfo.ModuleScript.lua");
    if (!fs.existsSync(p)) return;
    const text = fs.readFileSync(p, "utf8");
    scanText(text);
    const quoted = /\["([^"]+)"\]\s*=\s*\{/g;
    let m;
    while ((m = quoted.exec(text))) weapons.add(m[1]);
    const bare = /\n    ([A-Z][A-Za-z0-9 ]+) = \{\n        Offsets/g;
    while ((m = bare.exec(text))) weapons.add(m[1]);
}

function readLines(file) {
    const p = path.join(DUMP, file);
    if (!fs.existsSync(p)) return [];
    return fs.readFileSync(p, "utf8").split(/\r?\n/).filter(Boolean);
}

function parseRemotes() {
    const out = [];
    for (const line of readLines("remotes.txt")) {
        const parts = line.split("\t");
        if (parts.length < 2) continue;
        const [kind, remotePath] = parts;
        if (!/^[\x20-\x7E]+$/.test(remotePath)) continue;
        if (remotePath.includes("ReplicatedStorage.Remotes.") && remotePath.length > 80) continue;
        out.push(`${kind}\t${remotePath}`);
    }
    return out;
}

function parseModules() {
    const game = [];
    for (const line of readLines("modules.txt")) {
        const modPath = line.split("\t")[0] || "";
        if (modPath.startsWith("ReplicatedStorage.Modules.")) game.push(modPath);
        else if (modPath.startsWith("ReplicatedStorage.CharacterScripts.")) game.push(modPath);
    }
    return game;
}

function preloadPaths(modules) {
    const seen = new Set();
    const paths = [];
    for (const full of modules) {
        if (!full.startsWith("ReplicatedStorage.Modules.")) continue;
        const rel = full.replace("ReplicatedStorage.Modules.", "");
        const top = rel.split(".")[0];
        if (!seen.has(top)) {
            seen.add(top);
            paths.push(top);
        }
        if (rel.includes(".")) paths.push(rel);
    }
    return [...new Set(paths)].sort();
}

function section(title, lines) {
    return [
        "",
        "--- " + title + " (" + lines.length + ") ---",
        ...lines,
        "",
    ];
}

function main() {
    walkScripts(SCRIPTS);
    parseItems();
    parseToolInfo();

    const remotes = parseRemotes();
    const modules = parseModules();
    const preload = preloadPaths(modules);
    const bindables = readLines("bindables.txt").map((l) => l.split("\t").slice(0, 2).join("\t"));

    const workspaceFolders = [
        "workspace.Drops",
        "workspace.Bases",
        "workspace.Animals",
        "workspace.Plants",
        "workspace.Vegetation",
        "workspace.Military",
        "workspace.Events",
        "workspace.Monuments",
        "workspace.Nodes",
        "workspace.Bases.Loners",
    ];

    for (const v of valuesRefs) addKey(v);
    const allKeys = [...gcKeys].sort();

    const appendix = [
        "================================================================================",
        "STATIC APPENDIX — dump/ (tools/build_gc_static_catalog.mjs)",
        "Generated: " + new Date().toISOString(),
        "Purpose: static defs not guaranteed in live GC heap — merge with dumpgc output",
        "================================================================================",
        ...section(
            "GC KEY SEEDS",
            allKeys.map((k) => `[seed   ] ${k} = (static/dump)`)
        ),
        ...section(
            "ATTACHMENT STAT KEYS (Items.AttachmentStats)",
            [...attachmentKeys].sort().map((k) => `[attach ] ${k}`)
        ),
        ...section(
            "VALUES REFERENCES (ReplicatedStorage.Values.*)",
            [...valuesRefs].sort().map((v) => `[values ] ${v}`)
        ),
        ...section(
            "ATTRIBUTES (GetAttribute from game scripts)",
            [...attributes].sort().map((a) => `[attr   ] ${a}`)
        ),
        ...section(
            "WEAPONS / TOOLS (ToolInfo)",
            [...weapons].sort().map((w) => `[weapon ] ${w}`)
        ),
        ...section(
            "ITEMS (Items module Name field)",
            [...items].sort().map((i) => `[item   ] ${i}`)
        ),
        ...section(
            "REMOTES (readable paths only — obfuscated Remotes.* excluded)",
            remotes.map((r) => `[remote ] ${r}`)
        ),
        ...section(
            "BINDABLES",
            bindables.map((b) => `[bind   ] ${b}`)
        ),
        ...section(
            "MODULES (game ReplicatedStorage)",
            modules.map((m) => `[module ] ${m}`)
        ),
        ...section(
            "WORKSPACE SCAN FOLDERS",
            workspaceFolders.map((f) => `[folder ] ${f}`)
        ),
        ...section(
            "PRELOAD BEFORE dumpgc (require into heap)",
            preload.map((m) => `[preload] ReplicatedStorage.Modules.${m}`)
        ),
    ];

    fs.writeFileSync(OUT_APPENDIX, appendix.join("\n"));

    fs.writeFileSync(
        OUT_JSON,
        JSON.stringify(
            {
                generated: new Date().toISOString(),
                count: allKeys.length,
                attachmentStats: [...attachmentKeys].sort(),
                weapons: [...weapons].sort(),
                items: [...items].sort(),
                keys: allKeys,
            },
            null,
            2
        )
    );

    const luaKeyLines = allKeys.map((k) => `    "${k}",`).join("\n");
    fs.writeFileSync(
        OUT_LUA_KEYS,
        `-- AUTO-GENERATED by tools/build_gc_static_catalog.mjs\nreturn {\n${luaKeyLines}\n}\n`
    );

    const luaPreload = preload.map((m) => `    "${m}",`).join("\n");
    fs.writeFileSync(
        OUT_PRELOAD,
        `-- AUTO-GENERATED by tools/build_gc_static_catalog.mjs\nreturn {\n${luaPreload}\n}\n`
    );

    console.log("Catalog built:");
    console.log("  keys:", allKeys.length);
    console.log("  weapons:", weapons.size);
    console.log("  items:", items.size);
    console.log("  remotes:", remotes.length);
    console.log("  appendix:", OUT_APPENDIX);
}

main();
