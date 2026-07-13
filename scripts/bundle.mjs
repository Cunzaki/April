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
  "core/text_util.lua",
  "core/cache.lua",
  "core/capabilities.lua",
  "core/debug.lua",
  "game/mod_ids.lua",
  "core/settings.lua",
  "core/feature_bind.lua",
  "core/draw_util.lua",
  "core/ui_theme.lua",
  "core/notify.lua",
  "game/asset_urls.lua",
  "core/image_cache.lua",
  "core/esp_util.lua",
  "core/gpu_chams.lua",
  "core/scheduler.lua",
  "core/incremental_scan.lua",
  "core/menu_util.lua",
  "core/ballistic.lua",
  "core/silent_ray.lua",
  "core/fflag_mem.lua",
  "core/manip_math.lua",
  "core/desync_vis.lua",
  "core/packet_desync.lua",
  "core/cframe_move.lua",
  "core/runservice.lua",
  "core/misc_gate.lua",
  "core/movement_ctrl.lua",
  "core/config_store.lua",
  "core/memory_string.lua",
  "game/module_scan.lua",
  "game/bootstrap.lua",
  "game/folders.lua",
  "game/item_images.lua",
  "game/item_catalog.lua",
  "game/items.lua",
  "game/armor_map.lua",
  "game/weapons.lua",
  "game/gc_weapon_mods.lua",
  "game/weapon_profile_store.lua",
  "game/gun_mod_profiles.lua",
  "game/combat_stats.lua",
  "game/combat_origin.lua",
  "game/team_state.lua",
  "game/player_state.lua",
  "game/combat_target.lua",
  "game/farm_tools.lua",
  "game/inventory.lua",
  "game/player_gear.lua",
  "game/npcs.lua",
  "game/turret_stats.lua",
  "game/esp_maps.lua",
  "game/esp_scan.lua",
  "game/toolinfo_weapon_mods.lua",
  "features/combat/silent_whitelist.lua",
  "features/combat/bullet_tp_ray.lua",
  "features/combat/combat_menu.lua",
  "features/combat/targeting.lua",
  "features/combat/silent_resolve.lua",
  "features/combat/aimbot.lua",
  "features/combat/perfect_farm.lua",
  "features/combat/gun_mods.lua",
  "features/utility/mod_checker.lua",
  "features/visuals/player_esp.lua",
  "features/visuals/target_overlay.lua",
  "features/visuals/crosshair.lua",
  "features/visuals/bullet_tracers.lua",
  "features/visuals/hitmarkers.lua",
  "features/world/world_esp.lua",
  "features/world/loot_esp.lua",
  "features/world/base_esp.lua",
  "features/world/npc_esp.lua",
  "features/movement/exploits.lua",
  "features/movement/fling.lua",
  "features/movement/desync.lua",
  "features/radar/waypoints.lua",
  "features/radar/tactical_map.lua",
  "features/utility/keybind_viewer.lua",
  "features/utility/anti_afk.lua",
  "features/utility/config.lua",
  "menu/tabs.lua",
  "app.lua",
];

const header = `--[[
    April Fallen — Fallen Survival for Project Vector
    https://github.com/Cunzaki/April
    Built: ${new Date().toISOString()}
]]

April = {
    version = "3.73.4",
    debug = false,
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
-- Vector requires menu registration from the script main chunk (not nested init).
do
    April.require("menu.tabs").register_all()
end

April._init_ok = false

local ok, err = pcall(function()
    local debug = April.require("core.debug")
    local caps = April.require("core.capabilities")
    local app = April.require("app")

    if not app.init() then
        debug.error_once("init", "app.init() returned false — features disabled")
        return
    end

    April.require("core.movement_ctrl").install()
    April.require("features.movement.fling").install()

    April._init_ok = true

    local c = caps.probe()
    if c.fallen_gc then
        local gc = April.require("game.gc_weapon_mods")
        gc.probe_on_load()
    end

    if not debug.register_frame_hook(function()
        app.on_frame()
    end) then
        debug.error_once("init", "Failed to register on_frame")
    end
end)

if not ok then
    print("[April] Fatal: " .. tostring(err))
    if debug and debug.traceback then print(debug.traceback(err)) end
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
