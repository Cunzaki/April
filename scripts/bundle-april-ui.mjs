#!/usr/bin/env node
/**
 * Builds "april UI.lua" — Gamesense custom UI template only.
 * No Fallen features. Safe to share as a UI starter kit.
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const SRC = path.join(ROOT, "src");
const OUT = path.join(ROOT, "april UI.lua");

const ORDER = [
  // Minimal stubs so the UI runs without the full April core/game stack.
  { path: null, mod: "core.settings", inline: SETTINGS_STUB },
  { path: null, mod: "core.menu_util", inline: MENU_UTIL_STUB },
  { path: "core/vk_names.lua", mod: "core.vk_names" },
  { path: "ui/gs_theme.lua", mod: "ui.gs_theme" },
  { path: "ui/gs_input.lua", mod: "ui.gs_input" },
  { path: "ui/gs_state.lua", mod: "ui.gs_state" },
  { path: "ui/gs_anim.lua", mod: "ui.gs_anim" },
  { path: "ui/gs_icons.lua", mod: "ui.gs_icons" },
  { path: "ui/gs_widgets.lua", mod: "ui.gs_widgets" },
  // Template catalog is exposed as ui.catalog so custom_menu needs no changes.
  { path: "ui/template_catalog.lua", mod: "ui.catalog" },
  { path: "ui/custom_menu.lua", mod: "ui.custom_menu" },
  { path: "ui/template_app.lua", mod: "ui.template_app" },
];

function SETTINGS_STUB() {
  return `-- UI-only settings bridge (reads ui.gs_state).
local M = {}

local function store()
    local ok, s = pcall(function()
        return April.require("ui.gs_state")
    end)
    if ok then return s end
    return nil
end

function M.invalidate() end

function M.get(id, default)
    local s = store()
    if s then
        local v = s.get(id, nil)
        if v ~= nil then return v end
    end
    if menu and menu.get then
        local v = menu.get(id)
        if v ~= nil then return v end
    end
    return default
end

function M.bool(id, default)
    local v = M.get(id, default)
    if v == false or v == 0 or v == "false" then return false end
    if v == true or v == 1 or v == "true" then return true end
    return default == true
end

function M.num(id, default)
    return tonumber(M.get(id, default)) or default or 0
end

function M.combo_index(id, _options, default)
    return math.floor(tonumber(M.get(id, default or 0)) or default or 0)
end

function M.multi(id, one_based_index, default)
    local values = M.get(id, nil)
    if type(values) ~= "table" then return default == true end
    local v = values[one_based_index]
    if v == nil then v = values[one_based_index - 1] end
    return v == true or v == 1
end

function M.enabled(id)
    return M.bool(id, false)
end

function M.color(id, default)
    local s = store()
    if s and s.get_color then
        return s.get_color(id, default)
    end
    return default or { 1, 1, 1, 1 }
end

return M
`;
}

function MENU_UTIL_STUB() {
  return `-- UI-only stub (full April uses this for Vector menu parent gating).
local M = {}
function M.sync_master(_id) end
function M.sync_masters() end
function M.bind_master(_id, _children) end
return M
`;
}

const header = `--[[
================================================================================
  April UI  —  Gamesense-style draw menu template for Project Vector
================================================================================

  WHAT THIS IS
    A standalone custom menu (INSERT to toggle) with tabs, groups, and widgets.
    It ships with DEMO options only — no Fallen / April game features.

  REQUIREMENTS
    Project Vector Lua with draw.* and input/utility mouse APIs.

  CONTROLS
    INSERT          toggle menu (rebind under Config -> Menu Key)
    Drag title bar  move window
    Mouse wheel / PageUp/PageDown / edge-hover  scroll columns

  HOW TO ADD YOUR FEATURES
    1. Edit the catalog module (search for "template_catalog" / "Example Aimbot").
       - Add a tab in M.TABS
       - Build groups with cb / sl / combo / multi / kb / color / btn / ...
       - Use gate = "parent_checkbox_id" for nested options
       - Use group.master = "id" to hide a whole group when off

    2. Read values every frame from ui.gs_state:

         local state = April.require("ui.gs_state")
         if state.get("demo_esp_enabled", false) then
             local range = state.get("demo_esp_range", 500)
             local col = state.get_color("demo_esp_box_color", { 1, 0.3, 0.3, 1 })
         end

    3. Optional callbacks:

         state.on_change("demo_aim_enabled", function(on) ... end)
         state.set_button("demo_misc_reload", function() ... end)

    4. Rebuild after editing src/:
         node scripts/bundle-april-ui.mjs
       Or keep editing this single file if you prefer.

  SOURCE LAYOUT (when building from repo)
    src/ui/template_catalog.lua   tabs + demo options
    src/ui/template_app.lua       init / on_frame hooks
    src/ui/custom_menu.lua        window / tabs / layout
    src/ui/gs_*.lua               theme, input, widgets, state, icons, anim

  Built: ${new Date().toISOString()}
  Version: ui-1.2.0
================================================================================
]]

April = {
    version = "ui-1.2.0",
    debug = false,
    _mods = {},
    bundled = true,
    ui_only = true,
}

function April.require(path)
    local mod = April._mods[path]
    if mod == nil then
        error("[April UI] bundled module missing: " .. tostring(path))
    end
    return mod
end

`;

const footer = `
do
    local ok, err = pcall(function()
        local app = April.require("ui.template_app")
        if not app.init() then
            print("[April UI] init failed")
            return
        end

        function on_frame()
            app.on_frame()
        end
    end)

    if not ok then
        print("[April UI] Fatal: " .. tostring(err))
    end
end
`;

let body = "";
for (const entry of ORDER) {
  let src;
  let label;
  if (entry.inline) {
    src = entry.inline();
    label = entry.mod + " (stub)";
  } else {
    const full = path.join(SRC, entry.path);
    if (!fs.existsSync(full)) {
      console.error("Missing:", entry.path);
      process.exit(1);
    }
    src = fs.readFileSync(full, "utf8");
    label = entry.path;
  }
  body += `\n-- ── ${label} ──\n`;
  body += `April._mods["${entry.mod}"] = (function()\n${src}\nend)()\n`;
}

fs.writeFileSync(OUT, header + body + footer);
console.log("Built", path.relative(ROOT, OUT), `(${(fs.statSync(OUT).size / 1024).toFixed(1)} KB)`);
