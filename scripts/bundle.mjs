#!/usr/bin/env node
/**
 * Builds the single-file April runtime (april.lua + Script 1.lua) and load.lua.
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { stripLuaComments } from "./lua-strip.mjs";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const SRC = path.join(ROOT, "src");
const OUT = path.join(ROOT, "april.lua");
const LOAD_OUT = path.join(ROOT, "load.lua");
const SCRIPT1_OUT = path.join(ROOT, "Script 1.lua");

const ORDER = [
  "core/env.lua",
  "core/api_aliases.lua",
  "core/entity_props.lua",
  "core/math_util.lua",
  "core/text_util.lua",
  "core/cache.lua",
  "core/capabilities.lua",
  "core/debug.lua",
  "game/mod_ids.lua",
  "game/mod_group.lua",
  "game/cheater_detect.lua",
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
  "core/spider_ctrl.lua",
  "core/config_store.lua",
  "game/module_scan.lua",
  "game/bootstrap.lua",
  "game/folders.lua",
  "game/esp_maps.lua",
  "game/esp_scan.lua",
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
  "game/anime_announcer_data.lua",
  "game/farm_tools.lua",
  "game/farm_targets.lua",
  "game/inventory.lua",
  "game/player_gear.lua",
  "game/npcs.lua",
  "game/map_image.lua",
  "game/turret_stats.lua",
  "game/toolinfo_weapon_mods.lua",
  "ui/combat_labels.lua",
  "features/combat/silent_whitelist.lua",
  "features/combat/bullet_tp_ray.lua",
  "features/combat/combat_menu.lua",
  "features/combat/targeting.lua",
  "features/combat/ug_resolver.lua",
  "features/combat/active_target.lua",
  "features/combat/silent_resolve.lua",
  "features/combat/bullet_hud.lua",
  "features/combat/camera_aimbot.lua",
  "features/combat/body_peek.lua",
  "features/combat/thick_bullet.lua",
  "features/combat/aimbot.lua",
  "features/combat/fov_flags.lua",
  "features/combat/perfect_farm.lua",
  "features/utility/autofarm.lua",
  "features/combat/gun_mods.lua",
  "features/visuals/bullet_tracers.lua",
  "features/utility/mod_checker.lua",
  "features/utility/event_status.lua",
  "features/visuals/player_esp.lua",
  "features/visuals/target_overlay.lua",
  "features/visuals/target_visuals.lua",
  "features/visuals/crosshair.lua",
  "features/world/world_esp.lua",
  "features/world/loot_esp.lua",
  "features/world/base_esp.lua",
  "features/world/base_xray.lua",
  "features/world/npc_esp.lua",
  "features/world/raid_esp.lua",
  "features/movement/exploits.lua",
  "features/movement/bhop.lua",
  "features/movement/fling.lua",
  "features/movement/desync.lua",
  "features/movement/anti_aim.lua",
  "features/movement/fake_duck.lua",
  "features/movement/anti_fling.lua",
  "features/radar/waypoints.lua",
  "features/radar/tactical_map.lua",
  "features/utility/keybind_viewer.lua",
  "features/utility/anti_afk.lua",
  "features/utility/anime_announcer.lua",
  "features/utility/config.lua",
  "ui/gs_theme.lua",
  "ui/gs_input.lua",
  "ui/gs_state.lua",
  "ui/gs_anim.lua",
  "ui/i18n.lua",
  "ui/tooltips.lua",
  "ui/menu_shim.lua",
  "ui/gs_icons.lua",
  "ui/gs_widgets.lua",
  "ui/catalog.lua",
  "ui/hud_dock.lua",
  "ui/menu_fx.lua",
  "ui/startup_intro.lua",
  "ui/custom_menu.lua",
  "menu/tabs.lua",
  "app.lua",
];

const VERSION = "4.1.73";

const header = `--[[
    April Fallen - Fallen Survival for Project Vector
    https://github.com/Cunzaki/April
    Built: ${new Date().toISOString()}
    UI: custom Gamesense menu (INSERT) - Vector menu tabs disabled
]]

April = {
    version = "${VERSION}",
    debug = false,
    crash_logging = false,
    crash_trace = false,
    autofarm_trace = false,
    _mods = {},
    load_status = {
        { name = "Core", state = "loaded" },
        { name = "Services", state = "loaded" },
        { name = "Game Data", state = "loaded" },
        { name = "Features", state = "loaded" },
        { name = "Interface", state = "loaded" },
    },
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
        return
    end

    April.require("core.api_aliases").apply()
    April.require("core.movement_ctrl").install()
    April.require("core.spider_ctrl").install()
    April.require("features.movement.fling").install()
    April.require("features.movement.anti_aim").install()
    April.require("features.movement.anti_fling").install()
    April.require("features.world.base_xray").install()
    April.require("features.movement.fake_duck").install()

    April._init_ok = true

    local c = caps.probe()
    if c.fallen_gc then
        April.require("game.gc_weapon_mods").probe_on_load()
    end

    debug.register_frame_hook(function()
        app.on_frame()
    end)
end)

if not ok then
    print("[April] Fatal: " .. tostring(err))
end
`;

// Keep the release bundle comfortably below Vector's remote LoadUrl parser
// limit. Source files remain readable; generated bundles omit comments/blanks.
// Large UI/autofarm modules also drop indentation (Lua is not indentation-sensitive).
function compactLuaSource(source, stripIndent = false) {
  const out = [];
  let inBlockComment = false;

  for (const line of source.split(/\r?\n/)) {
    const trimmed = line.trim();

    if (inBlockComment) {
      if (trimmed.includes("]]")) inBlockComment = false;
      continue;
    }

    if (trimmed.startsWith("--[[")) {
      if (!trimmed.includes("]]")) inBlockComment = true;
      continue;
    }
    if (trimmed.startsWith("--") || trimmed === "") continue;
    out.push(stripIndent ? line.trimStart() : line);
  }

  return out.join("\n");
}

function buildModuleBody(files, fullBundle = false) {
  let body = "";
  for (const rel of files) {
    const full = path.join(SRC, rel);
    if (!fs.existsSync(full)) {
      console.error("Missing:", rel);
      process.exit(1);
    }
    const modPath = rel.replace(/\.lua$/, "").replace(/\//g, ".");
    const stripIndent = rel === "features/utility/autofarm.lua"
      || rel === "features/utility/anime_announcer.lua"
      || rel === "game/anime_announcer_data.lua"
      || (fullBundle && rel === "features/utility/config.lua")
      || (fullBundle && rel === "features/utility/mod_checker.lua")
      || (fullBundle && rel === "features/utility/event_status.lua")
      || (fullBundle && rel === "features/visuals/player_esp.lua")
      || (fullBundle && rel === "features/world/loot_esp.lua")
      || (fullBundle && rel === "features/world/world_esp.lua")
      || (fullBundle && rel === "features/radar/tactical_map.lua")
      || (fullBundle && rel === "game/player_state.lua")
      || (fullBundle && rel === "core/cache.lua")
      || (fullBundle && rel === "core/image_cache.lua")
      || (fullBundle && rel === "core/overlay_theme.lua")
      || (fullBundle && rel === "core/panel_drag.lua")
      || (fullBundle && rel === "core/manip_math.lua")
      || (fullBundle && rel === "core/desync_vis.lua")
      || (fullBundle && rel === "features/combat/silent_resolve.lua")
      || (fullBundle && rel === "features/combat/bullet_hud.lua")
      || (fullBundle && rel === "features/combat/body_peek.lua")
      || (fullBundle && rel === "features/combat/aimbot.lua")
      || (fullBundle && rel === "features/combat/thick_bullet.lua")
      || (fullBundle && rel === "features/combat/camera_aimbot.lua")
      || (fullBundle && rel === "features/combat/targeting.lua")
      || (fullBundle && rel === "features/movement/bhop.lua")
      || (fullBundle && rel === "features/movement/desync.lua")
      || (fullBundle && rel === "features/movement/anti_aim.lua")
      || (fullBundle && rel === "features/movement/fake_duck.lua")
      || (fullBundle && rel === "features/movement/fling.lua")
      || (fullBundle && rel === "game/map_image.lua")
      || (fullBundle && rel === "ui/gs_widgets.lua")
      || (fullBundle && rel === "ui/tooltips.lua")
      || (fullBundle && rel === "ui/hud_dock.lua")
      || (fullBundle && rel === "ui/gs_icons.lua")
      || (fullBundle && rel === "ui/gs_anim.lua")
      || (fullBundle && rel === "ui/gs_input.lua")
      || (fullBundle && rel === "ui/gs_state.lua")
      || rel === "ui/custom_menu.lua"
      || rel === "ui/catalog.lua";
    const src = compactLuaSource(fs.readFileSync(full, "utf8"), stripIndent);
    body += `\nApril._mods["${modPath}"] = (function()\n${src}\nend)()\n`;
  }
  return body;
}

// Single-file runtime: april.lua (remote) and Script 1.lua (local test) are identical.
const fullBody = buildModuleBody(ORDER, true);
const fullBundle = stripLuaComments(header + fullBody + footer);
const bundleBytes = Buffer.byteLength(fullBundle);
fs.writeFileSync(OUT, fullBundle);
fs.writeFileSync(SCRIPT1_OUT, fullBundle);
console.log("Built", path.relative(ROOT, OUT), `(${(bundleBytes / 1024).toFixed(1)} KB single-file runtime)`);
console.log("Built", path.relative(ROOT, SCRIPT1_OUT), `(${(bundleBytes / 1024).toFixed(1)} KB local test copy)`);

// Remove legacy split chunks so they are never loaded by mistake.
const CHUNK_DIR = path.join(ROOT, "chunks");
if (fs.existsSync(CHUNK_DIR)) {
  for (const old of fs.readdirSync(CHUNK_DIR)) {
    if (old.endsWith(".lua")) fs.unlinkSync(path.join(CHUNK_DIR, old));
  }
  console.log("Cleared chunks/ (split loading retired)");
}

// Public one-liner: static april.lua URL (no version query — load.lua never needs updating).
const loader = `utility.LoadUrl("https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/april.lua")\n`;
fs.writeFileSync(LOAD_OUT, loader);
console.log("Built", path.relative(ROOT, LOAD_OUT));

// Do not keep a duplicate full-bundle Script 2.lua around.
const SCRIPT2_OUT = path.join(ROOT, "Script 2.lua");
if (fs.existsSync(SCRIPT2_OUT)) {
  fs.unlinkSync(SCRIPT2_OUT);
  console.log("Removed Script 2.lua");
}

// Copy map tile atlas into Vector Scripts so radar can LoadImage local tiles.
function copyMapTilesToVector() {
  const assetId = "121836456123484";
  const srcTiles = path.join(ROOT, "assets", "maps", assetId, "tiles");
  if (!fs.existsSync(srcTiles)) {
    console.warn("No map tiles at", srcTiles);
    return;
  }
  const localApp = process.env.LOCALAPPDATA;
  if (!localApp) {
    console.warn("LOCALAPPDATA unset; skipped map tile install");
    return;
  }
  const dest = path.join(localApp, "Project Vector", "Scripts", "April_maps", "tiles", assetId);
  fs.mkdirSync(dest, { recursive: true });
  let n = 0;
  for (const name of fs.readdirSync(srcTiles)) {
    if (!name.endsWith(".png")) continue;
    fs.copyFileSync(path.join(srcTiles, name), path.join(dest, name));
    n++;
  }
  const fullSrc = path.join(ROOT, "assets", "maps", assetId + ".png");
  if (fs.existsSync(fullSrc)) {
    const mapsDir = path.join(localApp, "Project Vector", "Scripts", "April_maps");
    fs.mkdirSync(mapsDir, { recursive: true });
    fs.copyFileSync(fullSrc, path.join(mapsDir, assetId + ".png"));
  }
  console.log(`Installed ${n} map tiles -> ${dest}`);
}
copyMapTilesToVector();
