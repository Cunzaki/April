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
const LOAD_OUT = path.join(ROOT, "load.lua");
const SCRIPT1_OUT = path.join(ROOT, "Script 1.lua");

const ORDER = [
  "core/env.lua",
  "core/math_util.lua",
  "core/text_util.lua",
  "core/cache.lua",
  "core/capabilities.lua",
  "core/debug.lua",
  "game/mod_ids.lua",
  "game/mod_group.lua",
  "core/settings.lua",
  "core/feature_bind.lua",
  "core/aim_key.lua",
  "core/draw_util.lua",
  "core/vk_names.lua",
  "core/panel_drag.lua",
  "core/ui_theme.lua",
  "core/overlay_theme.lua",
  "core/notify.lua",
  "game/asset_urls.lua",
  "core/image_cache.lua",
  "core/esp_util.lua",
  "core/gpu_chams.lua",
  "core/incremental_scan.lua",
  "core/menu_util.lua",
  "core/ballistic.lua",
  "core/silent_ray.lua",
  "core/fflag_mem.lua",
  "core/manip_math.lua",
  "core/desync_vis.lua",
  "core/angle_util.lua",
  "core/cframe_move.lua",
  "core/runservice.lua",
  "core/misc_gate.lua",
  "core/movement_ctrl.lua",
  "core/config_store.lua",
  "game/module_scan.lua",
  "game/bootstrap.lua",
  "game/folders.lua",
  "game/item_images.lua",
  "game/attachment_images.lua",
  "game/item_catalog.lua",
  "game/items.lua",
  "game/weapons.lua",
  "game/gc_weapon_mods.lua",
  "game/gun_mod_profiles.lua",
  "game/combat_stats.lua",
  "game/combat_origin.lua",
  "game/team_state.lua",
  "game/player_state.lua",
  "game/farm_tools.lua",
  "game/farm_targets.lua",
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
  "features/combat/active_target.lua",
  "features/combat/silent_resolve.lua",
  "features/combat/bullet_hud.lua",
  "features/combat/camera_aimbot.lua",
  "features/combat/body_peek.lua",
  "features/combat/aimbot.lua",
  "features/combat/ragebot.lua",
  "features/combat/perfect_farm.lua",
  "features/combat/gun_mods.lua",
  "features/utility/mod_checker.lua",
  "features/visuals/player_esp.lua",
  "features/visuals/target_overlay.lua",
  "features/visuals/target_visuals.lua",
  "features/visuals/crosshair.lua",
  "features/world/world_esp.lua",
  "features/world/loot_esp.lua",
  "features/world/base_esp.lua",
  "features/world/npc_esp.lua",
  "features/movement/exploits.lua",
  "features/movement/fling.lua",
  "features/movement/desync.lua",
  "features/movement/anti_aim.lua",
  "features/movement/fake_duck.lua",
  "features/radar/waypoints.lua",
  "features/radar/tactical_map.lua",
  "features/utility/keybind_viewer.lua",
  "features/utility/anti_afk.lua",
  "features/utility/config.lua",
  "ui/gs_theme.lua",
  "ui/gs_input.lua",
  "ui/gs_state.lua",
  "ui/gs_anim.lua",
  "game/esp_maps.lua",
  "ui/tooltips.lua",
  "ui/menu_shim.lua",
  "ui/combat_labels.lua",
  "ui/gs_icons.lua",
  "ui/gs_widgets.lua",
  "ui/catalog.lua",
  "ui/custom_menu.lua",
  "menu/tabs.lua",
  "app.lua",
];

const VERSION = "3.96.4";

const header = `--[[
    April Fallen — Fallen Survival for Project Vector
    https://github.com/Cunzaki/April
    Built: ${new Date().toISOString()}
    UI: custom Gamesense menu (INSERT) — Vector menu tabs disabled
]]

April = {
    version = "${VERSION}",
    debug = false,
    _mods = {},
    bundled = true,
    custom_ui = true,
}

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
-- Install custom UI menu backend before any register_menu() calls.
do
    April.require("ui.menu_shim").install()
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
    April.require("features.movement.anti_aim").install()
    April.require("features.movement.fake_duck").install()

    April._init_ok = true
    print("[April] v" .. tostring(April.version) .. " — custom UI (INSERT to toggle)")

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

// Full bundle copies for Vector script slots (do NOT use CDN loader until GitHub is updated).
const SCRIPT2_OUT = path.join(ROOT, "Script 2.lua");
fs.writeFileSync(SCRIPT2_OUT, header + body + footer);
console.log("Built", path.relative(ROOT, SCRIPT2_OUT), "(full bundle — paste into Vector Script 2)");

const loader = `-- April LOCAL loader — paste into Vector Script 1/2.
-- Loads the built april.lua from disk (not GitHub CDN).

local path = [[${path.join(ROOT, "april.lua").replace(/\\/g, "\\\\")}]]
local f = io.open(path, "r")
if not f then
    print("[April] missing local file: " .. path)
    print("[April] Run npm run build, or paste april.lua into this script slot")
    return
end
local src = f:read("*a")
f:close()
if not src or #src < 1000 then
    print("[April] local april.lua empty/corrupt")
    return
end
local fn, err = loadstring(src)
if not fn then
    print("[April] compile failed: " .. tostring(err))
    return
end
local ok, run_err = pcall(fn)
if not ok then
    print("[April] run failed: " .. tostring(run_err))
end
`;

fs.writeFileSync(LOAD_OUT, loader);
fs.writeFileSync(SCRIPT1_OUT, loader);
console.log("Built", path.relative(ROOT, LOAD_OUT));
console.log("Built", path.relative(ROOT, SCRIPT1_OUT), "(local-disk loader)");
