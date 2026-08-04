#!/usr/bin/env node
/**
 * Builds the remote chunk loader plus a full local Vector test bundle.
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
  "core/api_aliases.lua",
  "core/entity_props.lua",
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
  "features/combat/active_target.lua",
  "features/combat/silent_resolve.lua",
  "features/combat/bullet_hud.lua",
  "features/combat/camera_aimbot.lua",
  "features/combat/body_peek.lua",
  "features/combat/aimbot.lua",
  "features/combat/perfect_farm.lua",
  "features/utility/autofarm.lua",
  "features/combat/gun_mods.lua",
  "features/utility/mod_checker.lua",
  "features/utility/event_status.lua",
  "features/visuals/player_esp.lua",
  "features/visuals/target_overlay.lua",
  "features/visuals/target_visuals.lua",
  "features/visuals/crosshair.lua",
  "features/world/world_esp.lua",
  "features/world/loot_esp.lua",
  "features/world/base_esp.lua",
  "features/world/npc_esp.lua",
  "features/world/raid_esp.lua",
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

const VERSION = "4.0.68";

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
    -- Set true only while hunting native crashes (writes dense STEP breadcrumbs).
    crash_trace = false,
    -- Targeted file trace for Autofarm native-crash diagnosis.
    autofarm_trace = true,
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
-- Install custom UI menu backend before any register_menu() calls.
do
    local dbg = April.require("core.debug")
    dbg.begin_session("bundle_boot")
    dbg.step("boot.menu_shim")
    April.require("ui.menu_shim").install()
    dbg.step("boot.register_all")
    April.require("menu.tabs").register_all()
    dbg.step_done("boot.register_all")
end

April._init_ok = false

local ok, err = pcall(function()
    local debug = April.require("core.debug")
    local caps = April.require("core.capabilities")
    local app = April.require("app")

    debug.step("boot.app.init")
    if not app.init() then
        debug.error_once("init", "app.init() returned false - features disabled")
        return
    end
    debug.step_done("boot.app.init")

    debug.step("boot.api_aliases")
    April.require("core.api_aliases").apply()
    debug.step("boot.movement_ctrl.install")
    April.require("core.movement_ctrl").install()
    debug.step("boot.fling.install")
    April.require("features.movement.fling").install()
    debug.step("boot.anti_aim.install")
    April.require("features.movement.anti_aim").install()
    debug.step("boot.fake_duck.install")
    April.require("features.movement.fake_duck").install()

    April._init_ok = true
    print("[April] v" .. tostring(April.version) .. " - custom UI (INSERT to toggle)")

    debug.step("boot.caps.probe")
    local c = caps.probe()
    if c.fallen_gc then
        local gc = April.require("game.gc_weapon_mods")
        debug.step("boot.gc.probe_on_load")
        gc.probe_on_load()
    end

    debug.step("boot.register_frame_hook")
    if not debug.register_frame_hook(function()
        app.on_frame()
    end) then
        debug.error_once("init", "Failed to register on_frame")
    end
end)

if not ok then
    print("[April] Fatal: " .. tostring(err))
    pcall(function()
        local debug = April.require("core.debug")
        debug.file("FATAL " .. tostring(err))
    end)
    if debug and debug.traceback then print(debug.traceback(err)) end
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

function buildModuleBody(files) {
  let body = "";
  for (const rel of files) {
    const full = path.join(SRC, rel);
    if (!fs.existsSync(full)) {
      console.error("Missing:", rel);
      process.exit(1);
    }
    const modPath = rel.replace(/\.lua$/, "").replace(/\//g, ".");
    const stripIndent = rel === "features/utility/autofarm.lua"
      || rel === "ui/custom_menu.lua"
      || rel === "ui/catalog.lua";
    const src = compactLuaSource(fs.readFileSync(full, "utf8"), stripIndent);
    body += `\nApril._mods["${modPath}"] = (function()\n${src}\nend)()\n`;
  }
  return body;
}

function through(file) {
  const index = ORDER.indexOf(file);
  if (index < 0) throw new Error(`Unknown chunk boundary: ${file}`);
  return index + 1;
}

const coreEnd = through("core/debug.lua");
const servicesEnd = through("core/config_store.lua");
const gameEnd = through("game/toolinfo_weapon_mods.lua");
const featuresEnd = through("features/utility/config.lua");
const CHUNKS = [
  { name: "Core", file: "01-core.lua", files: ORDER.slice(0, coreEnd) },
  { name: "Services", file: "02-services.lua", files: ORDER.slice(coreEnd, servicesEnd) },
  { name: "Game Data", file: "03-game.lua", files: ORDER.slice(servicesEnd, gameEnd) },
  { name: "Features", file: "04-features.lua", files: ORDER.slice(gameEnd, featuresEnd) },
  { name: "Interface", file: "05-interface.lua", files: ORDER.slice(featuresEnd) },
];

const fullBody = buildModuleBody(ORDER);
const fullBundle = header + fullBody + footer;
fs.writeFileSync(SCRIPT1_OUT, fullBundle);
const bundleBytes = Buffer.byteLength(fullBundle);
const MAX_VECTOR_BUNDLE_BYTES = 1_050_000;
if (bundleBytes > MAX_VECTOR_BUNDLE_BYTES) {
  console.error(
    `Bundle is ${bundleBytes} bytes; keep it below ${MAX_VECTOR_BUNDLE_BYTES} for Vector LoadUrl safety.`,
  );
  process.exit(1);
}
console.log("Built", path.relative(ROOT, SCRIPT1_OUT), `(${(bundleBytes / 1024).toFixed(1)} KB full local bundle)`);

const CHUNK_DIR = path.join(ROOT, "chunks");
fs.mkdirSync(CHUNK_DIR, { recursive: true });
for (const old of fs.readdirSync(CHUNK_DIR)) {
  if (old.endsWith(".lua")) fs.unlinkSync(path.join(CHUNK_DIR, old));
}
for (let i = 0; i < CHUNKS.length; i++) {
  const chunk = CHUNKS[i];
  const chunkFooter = i === CHUNKS.length - 1 ? footer : "";
  const contents = buildModuleBody(chunk.files) + chunkFooter;
  fs.writeFileSync(path.join(CHUNK_DIR, chunk.file), contents);
  console.log("Built", `chunks/${chunk.file}`, `(${(Buffer.byteLength(contents) / 1024).toFixed(1)} KB)`);
}

const remoteBase = "https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/chunks";
const remoteLoader = `${header}
April.bundled = false
April.load_status = {
${CHUNKS.map((chunk) => `    { name = "${chunk.name}", state = "pending" },`).join("\n")}
}

local chunks = {
${CHUNKS.map((chunk) => `    "${remoteBase}/${chunk.file}?v=${VERSION}",`).join("\n")}
}

for index = 1, #chunks do
    local status = April.load_status[index]
    status.state = "loading"
    local ok, err = utility.LoadUrl(chunks[index])
    if not ok then
        status.state = "failed"
        status.error = tostring(err)
        error("[April] Failed to load " .. status.name .. ": " .. tostring(err))
    end
    status.state = "loaded"
end
`;
fs.writeFileSync(OUT, remoteLoader);
console.log("Built", path.relative(ROOT, OUT), `(${(Buffer.byteLength(remoteLoader) / 1024).toFixed(1)} KB remote loader)`);

// load.lua mirrors the small release loader, avoiding an unnecessary nested
// LoadUrl when users execute the local loader file directly.
fs.writeFileSync(LOAD_OUT, remoteLoader);
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
