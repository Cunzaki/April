#!/usr/bin/env node
/**
 * Builds april.lua — the single Vector-executable script.
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
  "core/debug.lua",
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
    Built: ${new Date().toISOString()}
]]

April = {
    version = "3.0.0",
    debug = true,
    _mods = {},
    bundled = true,
}

-- Required first: Scripts > April uses "full" mode (2-column group grid)
if menu and menu.add_tab then
    menu.add_tab("April", "A", "full")
end
April._menu_tab_ready = true

function April.require(path)
    local mod = April._mods[path]
    if mod == nil then
        error("[April] bundled module missing: " .. path)
    end
    return mod
end

`;

const footer = `
April._init_ok = false

local ok, err = pcall(function()
    local debug = April.require("core.debug")
    local app = April.require("app")

    if not app.init() then
        debug.error_once("init", "app.init() returned false — features disabled")
        return
    end

    April._init_ok = true

    if not debug.register_frame_hook(function()
        app.on_frame()
    end) then
        debug.error_once("init", "Failed to register on_frame")
    end
end)

if not ok then
    print("[April] Fatal: " .. tostring(err))
    if debug and debug.traceback then print(debug.traceback(err)) end
elseif April._init_ok then
    print("[April v3] Ready — " .. April.version .. " (debug on, watch console for errors)")
else
    print("[April v3] Init failed — check console above")
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
