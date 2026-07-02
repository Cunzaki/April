#!/usr/bin/env node
/**
 * Builds april.lua — the single Vector-executable script.
 * Edit modules under src/, then run: node scripts/bundle.mjs
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const SRC = path.join(ROOT, "src");
const OUT = path.join(ROOT, "april.lua");

const ORDER = [
  "core/env.lua",
  "core/math_util.lua",
  "core/cache.lua",
  "core/settings.lua",
  "core/draw_util.lua",
  "core/scheduler.lua",
  "core/menu_util.lua",
  "game/folders.lua",
  "game/items.lua",
  "game/weapons.lua",
  "game/inventory.lua",
  "features/combat/aimbot.lua",
  "features/combat/recoil.lua",
  "features/visuals/player_esp.lua",
  "features/visuals/crosshair.lua",
  "features/visuals/feedback.lua",
  "features/world/world_esp.lua",
  "features/world/loot_esp.lua",
  "features/world/base_esp.lua",
  "features/world/npc_esp.lua",
  "features/movement/exploits.lua",
  "features/radar/waypoints.lua",
  "features/radar/tactical_map.lua",
  "features/utility/config.lua",
  "menu/tabs.lua",
  "app.lua",
];

const header = `--[[
    April — Fallen Survival for Project Vector
    https://github.com/Cunzaki/April

    Feature options register on Vector's top menu tabs (Aimbot, Player ESP, Crosshair, etc.)
    Built: ${new Date().toISOString()}
]]

April = {
    version = "3.0.0",
    debug = false,
    _mods = {},
    bundled = true,
}

function April.require(path)
    local mod = April._mods[path]
    if mod == nil then
        error("[April] bundled module missing: " .. path)
    end
    return mod
end

`;

const footer = `
local ok, err = pcall(function()
    local app = April.require("app")
    if not app.init() then return end

    function on_frame()
        app.on_frame()
    end

    if callbacks and callbacks.add then
        callbacks.add("on_frame", on_frame)
    elseif draw and draw.callback then
        draw.callback = on_frame
    end
end)

if not ok then
    print("[April] Fatal: " .. tostring(err))
else
    print("[April v3] Ready — " .. April.version)
end
`;

let body = "";
for (const rel of ORDER) {
  const full = path.join(SRC, rel);
  if (!fs.existsSync(full)) {
    console.error("Missing:", rel);
    process.exit(1);
  }
  const modPath = rel.replace(/\.lua$/, "").replace(/\//g, ".");
  const src = fs.readFileSync(full, "utf8");
  body += `\n-- ── ${rel} ──\n`;
  body += `April._mods["${modPath}"] = (function()\n${src}\nend)()\n`;
}

fs.writeFileSync(OUT, header + body + footer);
console.log("Built", path.relative(ROOT, OUT), `(${(fs.statSync(OUT).size / 1024).toFixed(1)} KB)`);
