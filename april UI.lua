--[[
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

  Built: 2026-07-22T15:23:36.749Z
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


-- ── core.settings (stub) ──
April._mods["core.settings"] = (function()
-- UI-only settings bridge (reads ui.gs_state).
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

end)()

-- ── core.menu_util (stub) ──
April._mods["core.menu_util"] = (function()
-- UI-only stub (full April uses this for Vector menu parent gating).
local M = {}
function M.sync_master(_id) end
function M.sync_masters() end
function M.bind_master(_id, _children) end
return M

end)()

-- ── core/vk_names.lua ──
April._mods["core.vk_names"] = (function()
-- Shared VK -> label map (matches custom UI keybind chips).
local M = {}

M.NAMES = {
    [0x01] = "M1", [0x02] = "M2", [0x04] = "M3",
    [0x08] = "BS", [0x09] = "TAB", [0x0D] = "ENT",
    [0x10] = "SHI", [0x11] = "CTL", [0x12] = "ALT",
    [0x14] = "CAP", [0x1B] = "ESC", [0x20] = "SPC",
    [0x25] = "LEFT", [0x26] = "UP", [0x27] = "RIGHT", [0x28] = "DOWN",
    [0x2D] = "INS", [0x2E] = "DEL",
    [0x30] = "0", [0x31] = "1", [0x32] = "2", [0x33] = "3", [0x34] = "4",
    [0x35] = "5", [0x36] = "6", [0x37] = "7", [0x38] = "8", [0x39] = "9",
    [0x41] = "A", [0x42] = "B", [0x43] = "C", [0x44] = "D", [0x45] = "E",
    [0x46] = "F", [0x47] = "G", [0x48] = "H", [0x49] = "I", [0x4A] = "J",
    [0x4B] = "K", [0x4C] = "L", [0x4D] = "M", [0x4E] = "N", [0x4F] = "O",
    [0x50] = "P", [0x51] = "Q", [0x52] = "R", [0x53] = "S", [0x54] = "T",
    [0x55] = "U", [0x56] = "V", [0x57] = "W", [0x58] = "X", [0x59] = "Y",
    [0x5A] = "Z",
    [0x70] = "F1", [0x71] = "F2", [0x72] = "F3", [0x73] = "F4",
    [0x74] = "F5", [0x75] = "F6", [0x76] = "F7", [0x77] = "F8",
    [0x78] = "F9", [0x79] = "F10", [0x7A] = "F11", [0x7B] = "F12",
}

function M.label(vk)
    vk = tonumber(vk) or 0
    if vk <= 0 then return "none" end
    return M.NAMES[vk] or string.format("%02X", vk)
end

function M.chip(vk)
    return "[" .. M.label(vk) .. "]"
end

return M

end)()

-- ── ui/gs_theme.lua ──
April._mods["ui.gs_theme"] = (function()
-- Runtime dark-glass palette for April's draw-only UI.
-- Vector exposes alpha + rounded primitives, but no backdrop blur or custom fonts.
local M = {}

M.PRESET_NAMES = { "Violet Glass", "Midnight Blue", "Graphite", "Emerald Glass" }
M.DENSITY_NAMES = { "Compact", "Balanced", "Comfortable" }
M.CORNER_NAMES = { "Sharp", "Soft", "Rounded" }

local PRESETS = {
    {
        bg = { 0.030, 0.032, 0.045 }, panel = { 0.070, 0.065, 0.095 },
        raised = { 0.105, 0.090, 0.135 }, accent = { 0.78, 0.20, 0.92 },
    },
    {
        bg = { 0.025, 0.040, 0.060 }, panel = { 0.055, 0.085, 0.120 },
        raised = { 0.075, 0.120, 0.165 }, accent = { 0.20, 0.68, 1.00 },
    },
    {
        bg = { 0.035, 0.037, 0.043 }, panel = { 0.075, 0.078, 0.088 },
        raised = { 0.115, 0.118, 0.130 }, accent = { 0.73, 0.76, 0.84 },
    },
    {
        bg = { 0.020, 0.045, 0.040 }, panel = { 0.045, 0.095, 0.080 },
        raised = { 0.065, 0.135, 0.110 }, accent = { 0.20, 0.92, 0.62 },
    },
}

local function clamp(v, a, b)
    v = tonumber(v) or a
    if v < a then return a end
    if v > b then return b end
    return v
end

local function rgb(c, alpha)
    return { c[1], c[2], c[3], alpha == nil and 1 or alpha }
end

local function mix_rgb(a, b, t, alpha)
    return {
        a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
        a[3] + (b[3] - a[3]) * t,
        alpha == nil and 1 or alpha,
    }
end

local function setting(id, fallback)
    local ok, value = pcall(function()
        return April.require("core.settings").get(id, fallback)
    end)
    if ok and value ~= nil then return value end
    return fallback
end

local function scaled(v, scale)
    return math.max(1, math.floor(v * scale + 0.5))
end

M.RAINBOW = {
    { 0.20, 0.90, 0.95, 1 },
    { 0.55, 0.35, 0.95, 1 },
    { 0.95, 0.85, 0.20, 1 },
    { 0.95, 0.35, 0.55, 1 },
    { 0.35, 0.95, 0.45, 1 },
}

function M.sync()
    local preset_idx = math.floor(clamp(setting("april_ui_theme_preset", 0), 0, #PRESETS - 1)) + 1
    local p = PRESETS[preset_idx] or PRESETS[1]
    local scale = clamp(setting("april_ui_scale", 100), 80, 125) * 0.01
    local density = math.floor(clamp(setting("april_ui_density", 1), 0, 2))
    local density_mul = ({ 0.88, 1.0, 1.12 })[density + 1]
    local window_alpha = clamp(setting("april_ui_window_opacity", 86), 45, 100) * 0.01
    local panel_alpha = clamp(setting("april_ui_panel_opacity", 72), 35, 100) * 0.01
    local border_alpha = clamp(setting("april_ui_border_strength", 58), 10, 100) * 0.01
    local corner_style = math.floor(clamp(setting("april_ui_corner_style", 2), 0, 2))
    local corner_base = ({ 2, 6, 10 })[corner_style + 1]

    M.SCALE = scale
    M.DENSITY = density
    M.GLOBAL_ALPHA = 1
    M.WINDOW_ALPHA = window_alpha
    M.PANEL_ALPHA = panel_alpha
    M.PRESET_ACCENT = rgb(p.accent, 1)

    M.BG = rgb(p.bg, window_alpha)
    M.BG_INNER = mix_rgb(p.bg, p.panel, 0.28, math.min(1, window_alpha + 0.04))
    M.PANEL = rgb(p.panel, panel_alpha)
    M.PANEL_ALT = mix_rgb(p.panel, p.raised, 0.35, math.min(1, panel_alpha + 0.06))
    M.PANEL_RAISED = rgb(p.raised, math.min(1, panel_alpha + 0.12))
    M.OVERLAY = mix_rgb(p.panel, p.raised, 0.50, math.min(1, panel_alpha + 0.17))
    M.SHADOW = { 0, 0, 0, 0.32 * window_alpha }
    M.SHADOW_DEEP = { 0, 0, 0, 0.20 * window_alpha }
    M.GLASS_HIGHLIGHT = { 1, 1, 1, 0.045 * border_alpha }
    M.BORDER = { 0.34, 0.35, 0.42, 0.60 * border_alpha }
    M.BORDER_SOFT = { 0.28, 0.29, 0.36, 0.40 * border_alpha }
    M.BORDER_HOT = mix_rgb(p.raised, p.accent, 0.55, 0.72 * border_alpha)
    M.SIDEBAR = mix_rgb(p.bg, p.panel, 0.18, math.min(1, window_alpha + 0.02))
    M.SIDEBAR_ACTIVE = mix_rgb(p.panel, p.accent, 0.20, math.min(1, panel_alpha + 0.08))

    M.TEXT = { 0.78, 0.80, 0.87, 1 }
    M.TEXT_DIM = { 0.47, 0.49, 0.57, 1 }
    M.TEXT_ACTIVE = { 0.96, 0.97, 1.00, 1 }
    M.TEXT_TITLE = { 0.84, 0.86, 0.92, 1 }

    M.ACCENT = M.ACCENT or rgb(p.accent, 1)
    M.ACCENT_DIM = mix_rgb(p.bg, p.accent, 0.42, 0.85)
    M.CHECK_OFF = mix_rgb(p.bg, p.panel, 0.55, math.min(1, panel_alpha + 0.10))
    M.SLIDER_BG = mix_rgb(p.bg, p.panel, 0.62, math.min(1, panel_alpha + 0.06))
    M.BUTTON = mix_rgb(p.bg, p.panel, 0.72, math.min(1, panel_alpha + 0.10))
    M.BUTTON_HOVER = mix_rgb(p.panel, p.raised, 0.68, math.min(1, panel_alpha + 0.14))
    M.HOVER = mix_rgb(p.panel, p.raised, 0.48, 0.68)
    M.FOCUS = rgb(p.accent, 0.72)

    M.FONT = scaled(13, scale)
    M.FONT_SMALL = scaled(12, scale)
    M.FONT_TITLE = scaled(12, scale)
    M.FONT_CAPTION = scaled(11, scale)

    M.WINDOW_W = scaled(820, scale)
    M.WINDOW_H = scaled(560, scale)
    M.SIDEBAR_W = scaled(58, scale)
    M.TAB_H = scaled(48 * density_mul, scale)
    M.GROUP_PAD = scaled(12, scale)
    M.GROUP_GAP = scaled(12 * density_mul, scale)
    M.GROUP_HEADER_H = scaled(30 * density_mul, scale)
    M.ROW_H = scaled(26 * density_mul, scale)
    M.ITEM_GAP = scaled(8 * density_mul, scale)
    M.LABEL_H = scaled(16 * density_mul, scale)
    M.LABEL_GAP = scaled(8 * density_mul, scale)
    M.CTRL_H = scaled(20 * density_mul, scale)
    M.CTRL_PAD = scaled(4, scale)
    M.CHECK_SIZE = scaled(13, scale)
    M.SLIDER_H = scaled(6, scale)
    M.STACKED_ROW_H = M.LABEL_H + M.LABEL_GAP + M.CTRL_H + M.CTRL_PAD
    M.SLIDER_ROW_H = M.LABEL_H + M.LABEL_GAP + M.SLIDER_H + scaled(10, scale) + M.CTRL_PAD
    M.CORNER = scaled(corner_base, scale)
    M.CORNER_SMALL = math.max(2, scaled(corner_base * 0.60, scale))
end

function M.alpha(col, a)
    return { col[1], col[2], col[3], a }
end

function M.lerp_color(a, b, t)
    return {
        a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
        a[3] + (b[3] - a[3]) * t,
        a[4] + (b[4] - a[4]) * t,
    }
end

function M.rainbow_at(t)
    local n = #M.RAINBOW
    local x = (t % 1) * n
    local i = math.floor(x) + 1
    local j = (i % n) + 1
    local f = x - math.floor(x)
    return M.lerp_color(M.RAINBOW[i], M.RAINBOW[j], f)
end

function M.apply_global_alpha(a)
    a = clamp(a, 0, 1)
    M.GLOBAL_ALPHA = a
    local keys = {
        "BG", "BG_INNER", "PANEL", "PANEL_ALT", "PANEL_RAISED", "OVERLAY",
        "SHADOW", "SHADOW_DEEP", "GLASS_HIGHLIGHT", "BORDER", "BORDER_SOFT",
        "BORDER_HOT", "SIDEBAR", "SIDEBAR_ACTIVE", "TEXT", "TEXT_DIM",
        "TEXT_ACTIVE", "TEXT_TITLE", "ACCENT", "ACCENT_DIM", "CHECK_OFF",
        "SLIDER_BG", "BUTTON", "BUTTON_HOVER", "HOVER", "FOCUS",
    }
    for _, key in ipairs(keys) do
        local c = M[key]
        if c then
            M[key] = { c[1], c[2], c[3], (c[4] or 1) * a }
        end
    end
end

M.sync()

return M

end)()

-- ── ui/gs_input.lua ──
April._mods["ui.gs_input"] = (function()
-- Mouse / key helpers. Raw cursor only - no windowed offset correction.
--
-- Wheel: Vector docs only expose utility.mouse_scroll() (inject). There is no
-- documented reader. We probe every known path and accumulate into M.wheel;
-- if none work, the menu keeps edge-hover scroll as fallback.

local M = {}

local prev_keys = {}
local prev_lmb = false
local prev_rmb = false
local prev_mmb = false

M.mx = 0
M.my = 0
M.raw_mx = 0
M.raw_my = 0
M.lmb = false
M.rmb = false
M.mmb = false
M.lmb_click = false
M.rmb_click = false
M.mmb_click = false
M.lmb_release = false
M.wheel = 0
M.wheel_source = nil -- "api" | "uis" | "mouse" | nil
M._wheel_accum = 0
M._scroll_ready = false
M._scroll_hook_tries = 0
M._api_readers = nil
M._game_cursor_hidden = false
M._menu_open = false
M.ui_x, M.ui_y, M.ui_w, M.ui_h = 0, 0, 0, 0

function M.set_ui_rect(x, y, w, h)
    M.ui_x, M.ui_y, M.ui_w, M.ui_h = x, y, w, h
end

function M.set_menu_open(open)
    M._menu_open = open == true
    M.set_game_cursor_visible(not M._menu_open)
end

local function pcall_get_service(name)
    local svc = nil
    if not game then return nil end
    pcall(function()
        if game.GetService then svc = game:GetService(name) end
    end)
    if not svc then
        pcall(function()
            if game.get_service then svc = game:get_service(name) end
        end)
    end
    return svc
end

local function on_wheel(dir, source)
    dir = tonumber(dir) or 0
    if dir == 0 then return end
    -- Normalize to ±1 notches (UIS Position.Z is often ±1).
    if dir > 0 then dir = 1 elseif dir < 0 then dir = -1 end
    M._wheel_accum = (M._wheel_accum or 0) + dir
    if source then M.wheel_source = source end
end

local function connect_signal(signal, fn)
    if not signal then return false end
    local connect = signal.Connect or signal.connect
    if type(connect) ~= "function" then return false end
    local ok = pcall(function()
        connect(signal, fn)
    end)
    return ok == true
end

local function collect_api_readers()
    if M._api_readers then return M._api_readers end
    local readers = {}
    local skip = {
        mouse_scroll = true,
        MouseScroll = true,
        mouseScroll = true,
    }
    local function scan(tbl, label)
        if type(tbl) ~= "table" then return end
        for k, v in pairs(tbl) do
            if type(v) == "function" and type(k) == "string" then
                local name = k:lower()
                if (name:find("wheel", 1, true) or name:find("scroll", 1, true))
                    and not skip[k]
                    and not name:find("set", 1, true)
                    and not name:find("mouse_scroll", 1, true)
                then
                    readers[#readers + 1] = { fn = v, label = label .. "." .. k }
                end
            end
        end
    end
    pcall(scan, input, "input")
    pcall(scan, utility, "utility")
    M._api_readers = readers
    return readers
end

local function poll_api_readers()
    local readers = collect_api_readers()
    for i = 1, #readers do
        local ok, a, b = pcall(readers[i].fn)
        if ok then
            local v = tonumber(a)
            if (not v or v == 0) and b ~= nil then v = tonumber(b) end
            if v and v ~= 0 then
                on_wheel(v, "api")
                return
            end
        end
    end
end

local function try_hook_uis()
    local uis = pcall_get_service("UserInputService")
    if not uis then return false end

    local function handle(input_obj, _game_processed)
        if not input_obj then return end
        local type_name = nil
        pcall(function()
            local t = input_obj.UserInputType or input_obj.user_input_type
            if type(t) == "userdata" or type(t) == "table" then
                type_name = tostring(t.Name or t.name or t)
            else
                type_name = tostring(t)
            end
        end)
        if not type_name then return end
        local lower = type_name:lower()
        if not lower:find("mousewheel", 1, true) and lower ~= "mousewheel" then
            return
        end
        local z = 0
        pcall(function()
            local pos = input_obj.Position or input_obj.position
            if pos then z = pos.Z or pos.z or 0 end
        end)
        if z == 0 then
            pcall(function()
                z = input_obj.Delta and (input_obj.Delta.Z or input_obj.Delta.z) or 0
            end)
        end
        if z == 0 then z = 1 end
        on_wheel(z, "uis")
    end

    local hooked = false
    if connect_signal(uis.InputChanged or uis.input_changed, handle) then
        hooked = true
    end
    if connect_signal(uis.InputBegan or uis.input_began, handle) then
        hooked = true
    end
    return hooked
end

local function try_hook_player_mouse()
    local lp = nil
    pcall(function()
        if entity and entity.get_local_player then
            lp = entity.get_local_player()
        end
    end)
    if not lp then
        pcall(function()
            lp = game and (game.LocalPlayer or game.local_player)
        end)
    end
    if not lp then return false end

    local mouse = nil
    pcall(function()
        if lp.GetMouse then mouse = lp:GetMouse()
        elseif lp.get_mouse then mouse = lp:get_mouse()
        else mouse = lp.Mouse or lp.mouse
        end
    end)
    if not mouse then return false end

    local hooked = false
    if connect_signal(mouse.WheelForward or mouse.wheel_forward, function()
        on_wheel(1, "mouse")
    end) then
        hooked = true
    end
    if connect_signal(mouse.WheelBackward or mouse.wheel_backward, function()
        on_wheel(-1, "mouse")
    end) then
        hooked = true
    end
    return hooked
end

local function ensure_scroll_hooks()
    if M._scroll_ready then return end
    -- Retry a few frames - LocalPlayer / services may not exist at load.
    M._scroll_hook_tries = (M._scroll_hook_tries or 0) + 1
    if M._scroll_hook_tries > 120 then
        M._scroll_ready = true
        return
    end

    local ok_uis = try_hook_uis()
    local ok_mouse = try_hook_player_mouse()
    collect_api_readers()
    if ok_uis or ok_mouse or M._scroll_hook_tries >= 30 then
        M._scroll_ready = true
    end
end

function M.set_game_cursor_visible(visible)
    local sg = pcall_get_service("StarterGui")
    if sg then
        pcall(function()
            if sg.SetCore then sg:SetCore("MouseIconEnabled", visible) end
        end)
        pcall(function()
            if sg.set_core then sg:set_core("MouseIconEnabled", visible) end
        end)
    end

    local uis = pcall_get_service("UserInputService")
    if uis then
        pcall(function() uis.MouseIconEnabled = visible end)
        pcall(function() uis.mouse_icon_enabled = visible end)
    end

    pcall(function()
        local lp = game and game.local_player
        if not lp then return end
        local mouse = lp.GetMouse and lp:GetMouse() or (lp.get_mouse and lp:get_mouse())
        if not mouse then return end
        if not visible then
            mouse.Icon = "rbxassetid://0"
            if mouse.icon ~= nil then mouse.icon = "rbxassetid://0" end
        else
            mouse.Icon = ""
        end
    end)

    M._game_cursor_hidden = not visible
end

function M.mouse()
    return M.mx, M.my
end

function M.key_down(vk)
    return input and input.is_key_down and input.is_key_down(vk) or false
end

function M.key_pressed(vk)
    local down = M.key_down(vk)
    local was = prev_keys[vk] == true
    prev_keys[vk] = down
    return down and not was
end

function M.begin_frame()
    ensure_scroll_hooks()

    local amx, amy = 0, 0
    if utility and utility.get_mouse_pos then
        amx, amy = utility.get_mouse_pos()
    elseif input and input.get_mouse_pos then
        amx, amy = input.get_mouse_pos()
    elseif input and input.get_mouse_position then
        amx, amy = input.get_mouse_position()
    end
    amx = tonumber(amx) or 0
    amy = tonumber(amy) or 0
    M.raw_mx, M.raw_my = amx, amy
    M.mx, M.my = amx, amy

    M.lmb = M.key_down(0x01)
    M.rmb = M.key_down(0x02)
    M.mmb = M.key_down(0x04)
    M.lmb_click = M.lmb and not prev_lmb
    M.rmb_click = M.rmb and not prev_rmb
    M.mmb_click = M.mmb and not prev_mmb
    M.lmb_release = (not M.lmb) and prev_lmb
    prev_lmb = M.lmb
    prev_rmb = M.rmb
    prev_mmb = M.mmb

    -- Poll any getter-style APIs each frame, then drain event accumulators.
    poll_api_readers()
    M.wheel = M._wheel_accum or 0
    M._wheel_accum = 0
end

function M.hover(x, y, w, h)
    return M.mx >= x and M.my >= y and M.mx <= x + w and M.my <= y + h
end

function M.clicked(x, y, w, h)
    return M.lmb_click and M.hover(x, y, w, h)
end

function M.draw_cursor()
    if not draw then return end
    local show = true
    pcall(function()
        show = April.require("core.settings").bool("april_ui_show_cursor_dot", true)
    end)
    if not show then return end
    local x, y = M.mx, M.my
    local theme = April.require("ui.gs_theme")
    local anim = April.require("ui.gs_anim")
    local col = theme.ACCENT or { 0.75, 0.15, 0.83, 1 }
    local press = anim.transition("cursor:press", M.lmb, anim.motion_rate(26))
    local inner = 3.5 + press * 1.5
    if draw.circle_filled then
        draw.circle_filled(x, y, inner, col, 14)
    end
    if draw.circle then
        draw.circle(x, y, 5.5 + press, theme.TEXT_ACTIVE, 16, 1.2)
    end
end

return M

end)()

-- ── ui/gs_state.lua ──
April._mods["ui.gs_state"] = (function()
-- Shared settings store for the custom UI (backs menu shim + settings reads).
local M = {}

M.values = {}
M.defaults = {}
M.colors = {}
M.keys = {}
M.callbacks = {}
M.menu_callback = {} -- id -> single fn (menu.set_callback replaces)
M.buttons = {}
M.visible = {} -- id -> bool (parent gating); nil means visible

local function copy_table(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do
        out[k] = v
    end
    return out
end

function M.define(id, default)
    if id == nil then return end
    if M.defaults[id] == nil then
        M.defaults[id] = copy_table(default)
    end
    if M.values[id] == nil then
        M.values[id] = copy_table(default)
    end
end

function M.get(id, fallback)
    local v = M.values[id]
    if v == nil then
        return fallback
    end
    return v
end

local function fire_change(id, value)
    local menu_cb = M.menu_callback[id]
    if menu_cb then
        pcall(menu_cb, value)
    end
    local cbs = M.callbacks[id]
    if cbs then
        for i = 1, #cbs do
            pcall(cbs[i], value)
        end
    end
end

function M.set(id, value)
    if id == nil then return end
    M.values[id] = value
    fire_change(id, value)
end

function M.toggle(id)
    local v = not M.get(id, false)
    M.set(id, v)
    return v
end

function M.define_color(id, color)
    if id == nil then return end
    if M.colors[id] == nil then
        M.colors[id] = copy_table(color or { 1, 1, 1, 1 })
    end
end

function M.get_color(id, fallback)
    return M.colors[id] or fallback or { 1, 1, 1, 1 }
end

function M.set_color(id, color)
    if id == nil or type(color) ~= "table" then return end
    M.colors[id] = copy_table(color)
    fire_change(id, color)
end

function M.get_key(id)
    return tonumber(M.keys[id]) or 0
end

function M.set_key(id, vk)
    if id == nil then return end
    M.keys[id] = tonumber(vk) or 0
end

function M.on_change(id, fn)
    if not id or not fn then return end
    M.callbacks[id] = M.callbacks[id] or {}
    M.callbacks[id][#M.callbacks[id] + 1] = fn
end

function M.set_menu_callback(id, fn)
    if id then
        M.menu_callback[id] = fn
    end
end

function M.set_button(id, fn)
    if id then
        M.buttons[id] = fn
    end
end

function M.fire_button(id)
    local fn = M.buttons[id]
    if fn then
        pcall(fn)
        return true
    end
    return false
end

function M.set_visible(id, show)
    if id then
        M.visible[id] = show and true or false
    end
end

function M.is_visible(id)
    local v = M.visible[id]
    if v == nil then return true end
    return v
end

function M.reset(id)
    local d = M.defaults[id]
    if d == nil then return end
    M.set(id, copy_table(d))
end

return M

end)()

-- ── ui/gs_anim.lua ──
April._mods["ui.gs_anim"] = (function()
-- Animated accent bars + per-element theme sync for the custom UI.
local theme = April.require("ui.gs_theme")

local M = {}

M.MODES = { "Static", "Rainbow", "Pulse", "Wave", "Flow" }
M.MODES_UI = { "Default", "Static", "Rainbow", "Pulse", "Wave", "Flow" }

M.TARGET_TITLE = 1
M.TARGET_SECTION = 2
M.TARGET_SLIDER = 3
M.TARGET_SCROLL = 4
M.TARGET_SIDEBAR = 5
M.TARGET_CHECKBOX = 6
M.TARGET_HOVER = 7
M.TARGET_OVERLAY = 8

M.STYLE_TITLE = "april_ui_style_title"
M.STYLE_SECTION = "april_ui_style_section"
M.STYLE_SLIDER = "april_ui_style_slider"
M.STYLE_SCROLL = "april_ui_style_scroll"
M.STYLE_SIDEBAR = "april_ui_style_sidebar"
M.STYLE_CHECKBOX = "april_ui_style_checkbox"
M.STYLE_OVERLAY = "april_ui_style_overlay"

M.COL_TITLE = "april_ui_col_title"
M.COL_SECTION = "april_ui_col_section"
M.COL_SLIDER = "april_ui_col_slider"
M.COL_SCROLL = "april_ui_col_scroll"
M.COL_SIDEBAR = "april_ui_col_sidebar"
M.COL_CHECKBOX = "april_ui_col_checkbox"
M.COL_OVERLAY = "april_ui_col_overlay"

local transitions = {}

local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

function M.lerp(a, b, t)
    t = clamp(t or 0, 0, 1)
    return a + (b - a) * t
end

function M.ease_out_cubic(t)
    t = clamp(t or 0, 0, 1)
    local q = 1 - t
    return 1 - q * q * q
end

-- Persistent transition value for hover/active UI elements.
function M.transition(id, target, rate)
    if M.reduce_motion() then
        transitions[id] = { value = target and 1 or 0, at = M.now() }
        return target and 1 or 0
    end
    local now = M.now()
    local entry = transitions[id]
    if not entry then
        entry = { value = target and 1 or 0, at = now }
        transitions[id] = entry
        return entry.value
    end
    local dt = math.min(math.max(now - (entry.at or now), 0), 0.1)
    entry.at = now
    local goal = target and 1 or 0
    local speed = rate or 12
    local alpha = 1 - math.exp(-speed * dt)
    entry.value = M.lerp(entry.value or 0, goal, alpha)
    return entry.value
end

-- Numeric exponential smoothing for scroll positions and other continuous values.
function M.smooth(id, target, rate)
    if M.reduce_motion() then
        transitions[id] = { value = target, at = M.now() }
        return target
    end
    local now = M.now()
    local entry = transitions[id]
    if not entry then
        entry = { value = target, at = now }
        transitions[id] = entry
        return target
    end
    local dt = math.min(math.max(now - (entry.at or now), 0), 0.1)
    entry.at = now
    local alpha = 1 - math.exp(-(rate or 14) * dt)
    entry.value = M.lerp(entry.value or target, target, alpha)
    return entry.value
end

function M.mix(a, b, t)
    return theme.lerp_color(a, b, clamp(t or 0, 0, 1))
end

local function settings()
    return April.require("core.settings")
end

local function hsv_to_rgb(h, s, v)
    h = (h % 1) * 6
    local i = math.floor(h)
    local f = h - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    if i == 0 then return v, t, p end
    if i == 1 then return q, v, p end
    if i == 2 then return p, v, t end
    if i == 3 then return p, q, v end
    if i == 4 then return t, p, v end
    return v, p, q
end

function M.now()
    if utility and utility.get_time then
        return utility.get_time()
    end
    return 0
end

function M.speed()
    local n = settings().num("april_ui_anim_speed", 40)
    return clamp(n, 1, 100) * 0.028
end

function M.reduce_motion()
    return settings().bool("april_ui_reduce_motion", false)
end

function M.motion_profile()
    return clamp(math.floor(settings().num("april_ui_motion_profile", 1) + 0.5), 0, 2)
end

function M.motion_rate(base)
    if M.reduce_motion() then return 1000 end
    local mul = ({ 0.72, 1.0, 1.28 })[M.motion_profile() + 1]
    return (base or 12) * mul
end

function M.phase()
    return M.now() * M.speed()
end

function M.colors_enabled()
    return settings().bool("april_ui_custom_colors", false)
end

function M.anim_enabled()
    return settings().bool("april_ui_custom_anim", false)
end

function M.global_mode()
    local n = tonumber(settings().get("april_ui_accent_anim", 1)) or 1
    return clamp(math.floor(n + 0.5), 0, #M.MODES - 1)
end

function M.resolve_mode(style_id)
    if not M.anim_enabled() then
        return 0
    end
    local pick = settings().combo_index(style_id, M.MODES_UI, 0)
    if pick == 0 then
        return M.global_mode()
    end
    return pick - 1
end

function M.base_accent()
    if not M.colors_enabled() then
        return theme.PRESET_ACCENT or { 0.78, 0.20, 0.92, 1 }
    end
    return settings().color("april_ui_accent", theme.PRESET_ACCENT or { 0.78, 0.20, 0.92, 1 })
end

function M.color_override_enabled(target_index)
    if not M.colors_enabled() then
        return false
    end
    return settings().multi("april_ui_color_overrides", target_index, false)
end

function M.element_color(target_index, color_id)
    if M.color_override_enabled(target_index) then
        return settings().color(color_id, M.base_accent())
    end
    return M.base_accent()
end

function M.anim_target_enabled(target_index)
    if not M.anim_enabled() then
        return false
    end
    return settings().multi("april_ui_anim_targets", target_index, true)
end

function M.sync_theme()
    theme.sync()
    local col = M.base_accent()
    theme.ACCENT = { col[1], col[2], col[3], col[4] or 1 }
    local pulse = 0.62 + 0.38 * math.sin(M.phase() * 2.2)
    theme.ACCENT_DIM = {
        col[1] * pulse * 0.55,
        col[2] * pulse * 0.55,
        col[3] * pulse * 0.55,
        1,
    }
end

function M.accent_at_mode(mode, base, t, alpha)
    alpha = alpha or 1
    local phase = M.phase()
    t = (t or 0) % 1

    if mode == 0 then
        return { base[1], base[2], base[3], alpha }
    end
    if mode == 1 then
        local hue = (t + phase * 0.14) % 1
        local r, g, b = hsv_to_rgb(hue, 1, 1)
        return { r, g, b, alpha }
    end
    if mode == 2 then
        local p = 0.5 + 0.5 * math.sin(phase * 2.4 + t * 6.28318)
        return { base[1] * p, base[2] * p, base[3] * p, alpha }
    end
    if mode == 3 then
        local w = 0.45 + 0.55 * math.sin((t * 10 - phase * 2.8) * 6.28318)
        return {
            base[1] * (0.55 + 0.45 * w),
            base[2] * (0.55 + 0.45 * w),
            base[3] * (0.55 + 0.45 * w),
            alpha,
        }
    end
    local sweep_h = (t + phase * 0.18) % 1
    local sr, sg, sb = hsv_to_rgb(sweep_h, 1, 1)
    local mix = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 6.28318 + phase * 1.6))
    local c = theme.lerp_color(base, { sr, sg, sb, 1 }, mix)
    return { c[1], c[2], c[3], alpha }
end

function M.accent_at(t, alpha)
    return M.accent_at_mode(M.global_mode(), M.base_accent(), t, alpha)
end

local function widget_clip()
    local clip = nil
    pcall(function()
        clip = April.require("ui.gs_widgets").clip
    end)
    return clip
end

function M.rect(x, y, w, h, col, filled)
    if not draw then return end
    local c = widget_clip()
    if c then
        local x2, y2 = x + w, y + h
        local cx, cy = c.x, c.y
        local cx2, cy2 = c.x + c.w, c.y + c.h
        if x2 <= cx or y2 <= cy or x >= cx2 or y >= cy2 then return end
        if x < cx then w = w - (cx - x); x = cx end
        if y < cy then h = h - (cy - y); y = cy end
        if x + w > cx2 then w = cx2 - x end
        if y + h > cy2 then h = cy2 - y end
        if w <= 0 or h <= 0 then return end
    end
    if filled then
        draw.rect_filled(x, y, w, h, col, 0)
    else
        draw.rect(x, y, w, h, col, 0, 1)
    end
end

function M.draw_bar_h(x, y, w, h, scroll_t, style_id, color_id, color_target)
    if w <= 0 or h <= 0 then return end
    scroll_t = scroll_t or 0
    local base = M.element_color(color_target, color_id)
    local alpha = (base[4] or 1) * (theme.GLOBAL_ALPHA or 1)
    local mode = M.resolve_mode(style_id)
    if mode == 0 then
        M.rect(x, y, w, h, theme.alpha(base, alpha), true)
        return
    end
    local segs = math.min(64, math.max(12, math.floor(w / 8)))
    local sw = w / segs
    for i = 0, segs - 1 do
        local t = (i / segs + scroll_t) % 1
        M.rect(x + i * sw, y, sw + 0.75, h, M.accent_at_mode(mode, base, t, alpha), true)
    end
end

function M.draw_bar_v(x, y, w, h, scroll_t, style_id, color_id, color_target)
    if w <= 0 or h <= 0 then return end
    scroll_t = scroll_t or 0
    local base = M.element_color(color_target, color_id)
    local alpha = (base[4] or 1) * (theme.GLOBAL_ALPHA or 1)
    local mode = M.resolve_mode(style_id)
    if mode == 0 then
        M.rect(x, y, w, h, theme.alpha(base, alpha), true)
        return
    end
    local segs = math.min(48, math.max(8, math.floor(h / 8)))
    local sh = h / segs
    for i = 0, segs - 1 do
        local t = (i / segs + scroll_t) % 1
        M.rect(x, y + i * sh, w, sh + 0.75, M.accent_at_mode(mode, base, t, alpha), true)
    end
end

function M.draw_flat(x, y, w, h, style_id, color_id, color_target)
    local base = M.element_color(color_target, color_id)
    M.rect(x, y, w, h, theme.alpha(base, (base[4] or 1) * (theme.GLOBAL_ALPHA or 1)), true)
end

function M.section_scroll()
    return M.phase() * 0.09
end

function M.draw_section_top(x, y, w)
    if not M.anim_target_enabled(M.TARGET_SECTION) then
        M.draw_flat(x, y, w, 2, M.STYLE_SECTION, M.COL_SECTION, M.TARGET_SECTION)
        return
    end
    M.draw_bar_h(x, y, w, 2, M.section_scroll(), M.STYLE_SECTION, M.COL_SECTION, M.TARGET_SECTION)
end

function M.draw_title_bar(x, y, w, h)
    if not M.anim_target_enabled(M.TARGET_TITLE) then
        M.draw_flat(x, y, w, h, M.STYLE_TITLE, M.COL_TITLE, M.TARGET_TITLE)
        return
    end
    M.draw_bar_h(x, y, w, h, M.phase() * 0.12, M.STYLE_TITLE, M.COL_TITLE, M.TARGET_TITLE)
end

function M.draw_slider_fill(x, y, w, h)
    if not M.anim_target_enabled(M.TARGET_SLIDER) then
        M.draw_flat(x, y, w, h, M.STYLE_SLIDER, M.COL_SLIDER, M.TARGET_SLIDER)
        return
    end
    M.draw_bar_h(x, y, w, h, M.phase() * 0.06, M.STYLE_SLIDER, M.COL_SLIDER, M.TARGET_SLIDER)
end

function M.draw_scroll_thumb(x, y, w, h)
    if not M.anim_target_enabled(M.TARGET_SCROLL) then
        M.draw_flat(x, y, w, h, M.STYLE_SCROLL, M.COL_SCROLL, M.TARGET_SCROLL)
        return
    end
    M.draw_bar_v(x, y, w, h, M.phase() * 0.05, M.STYLE_SCROLL, M.COL_SCROLL, M.TARGET_SCROLL)
end

function M.draw_tab_indicator(x, y, w, h)
    if not M.anim_target_enabled(M.TARGET_SIDEBAR) then
        M.draw_flat(x, y, w, h, M.STYLE_SIDEBAR, M.COL_SIDEBAR, M.TARGET_SIDEBAR)
        return
    end
    M.draw_bar_v(x, y, w, h, M.phase() * 0.07, M.STYLE_SIDEBAR, M.COL_SIDEBAR, M.TARGET_SIDEBAR)
end

function M.tab_icon_color()
    local base = M.element_color(M.TARGET_SIDEBAR, M.COL_SIDEBAR)
    if not M.anim_target_enabled(M.TARGET_SIDEBAR) then
        return base
    end
    return M.accent_at_mode(M.resolve_mode(M.STYLE_SIDEBAR), base, M.phase() * 0.03,
        (base[4] or 1) * (theme.GLOBAL_ALPHA or 1))
end

function M.hover_tint(base, hot)
    if not hot then return base end
    if not M.anim_target_enabled(M.TARGET_HOVER) then
        return base
    end
    local pulse = 0.88 + 0.12 * math.sin(M.phase() * 6)
    return {
        base[1] * pulse,
        base[2] * pulse,
        base[3] * pulse,
        base[4] or 1,
    }
end

function M.interactive_fill(id, base, hover, active)
    local h = M.transition("hover:" .. tostring(id), hover, M.motion_rate(15))
    local a = M.transition("active:" .. tostring(id), active, M.motion_rate(20))
    local col = M.mix(base, hover and theme.BUTTON_HOVER or theme.HOVER, M.ease_out_cubic(h))
    return M.mix(col, M.element_color(M.TARGET_CHECKBOX, M.COL_CHECKBOX), a * 0.16)
end

function M.checkbox_fill()
    local base = M.element_color(M.TARGET_CHECKBOX, M.COL_CHECKBOX)
    if not M.anim_target_enabled(M.TARGET_CHECKBOX) then
        return base
    end
    return M.accent_at_mode(M.resolve_mode(M.STYLE_CHECKBOX), base, M.phase() * 0.04,
        (base[4] or 1) * (theme.GLOBAL_ALPHA or 1))
end

function M.menu_fade()
    if M.reduce_motion() then return 1 end
    if not settings().bool("april_ui_menu_fade", false) then return 1 end
    return clamp(0.93 + math.sin(M.now() * 1.5) * 0.035, 0.88, 0.98)
end

function M.panel_bg()
    if not M.colors_enabled() then
        return theme.BG
    end
    local dim = settings().num("april_ui_bg_dim", 0)
    dim = clamp(dim, 0, 40) * 0.01
    local bg = theme.BG
    return {
        bg[1] - dim * 0.04,
        bg[2] - dim * 0.04,
        bg[3] - dim * 0.04,
        bg[4] or 1,
    }
end

function M.menu_open_progress(want_open)
    return M.transition("menu:open", want_open, M.motion_rate(15))
end

function M.tab_progress(tab_id)
    return M.transition("tab-content:" .. tostring(tab_id), true, M.motion_rate(18))
end

function M.clear_tab_progress(tab_id)
    transitions["tab-content:" .. tostring(tab_id)] = { value = 0, at = M.now() }
end

return M

end)()

-- ── ui/gs_icons.lua ──
April._mods["ui.gs_icons"] = (function()
-- Vector-drawn sidebar icons (sharper Gamesense-style glyphs).
local theme = April.require("ui.gs_theme")

local M = {}

local function line(x1, y1, x2, y2, col, t)
    if draw and draw.line then
        draw.line(x1, y1, x2, y2, col, t or 1.6)
    end
end

local function circle(x, y, r, col, filled, segs)
    if not draw then return end
    segs = segs or 20
    if filled and draw.circle_filled then
        draw.circle_filled(x, y, r, col, segs)
    elseif draw.circle then
        draw.circle(x, y, r, col, segs, 1.6)
    end
end

local function rect(x, y, w, h, col, filled)
    if not draw then return end
    if filled then
        draw.rect_filled(x, y, w, h, col, 0)
    else
        draw.rect(x, y, w, h, col, 0, 1.5)
    end
end

local function poly(points, col, t)
    if draw and draw.poly then
        draw.poly(points, col, t or 1.5)
    else
        for i = 1, #points - 1 do
            line(points[i][1], points[i][2], points[i + 1][1], points[i + 1][2], col, t)
        end
    end
end

local function ellipse_arc(cx, cy, rx, ry, a0, a1, col, steps)
    steps = steps or 10
    local pts = {}
    for i = 0, steps do
        local t = a0 + (a1 - a0) * (i / steps)
        pts[#pts + 1] = { cx + math.cos(t) * rx, cy + math.sin(t) * ry }
    end
    poly(pts, col, 1.5)
end

function M.draw(name, cx, cy, col)
    col = col or theme.TEXT

    if name == "aim" then
        -- Crosshair with outer brackets
        circle(cx, cy, 5.5, col, false, 22)
        circle(cx, cy, 1.4, col, true, 10)
        line(cx - 9, cy, cx - 4, cy, col, 1.7)
        line(cx + 4, cy, cx + 9, cy, col, 1.7)
        line(cx, cy - 9, cx, cy - 4, col, 1.7)
        line(cx, cy + 4, cx, cy + 9, col, 1.7)
        -- corner ticks
        line(cx - 8, cy - 8, cx - 5, cy - 8, col, 1.3)
        line(cx - 8, cy - 8, cx - 8, cy - 5, col, 1.3)
        line(cx + 8, cy - 8, cx + 5, cy - 8, col, 1.3)
        line(cx + 8, cy - 8, cx + 8, cy - 5, col, 1.3)
        line(cx - 8, cy + 8, cx - 5, cy + 8, col, 1.3)
        line(cx - 8, cy + 8, cx - 8, cy + 5, col, 1.3)
        line(cx + 8, cy + 8, cx + 5, cy + 8, col, 1.3)
        line(cx + 8, cy + 8, cx + 8, cy + 5, col, 1.3)

    elseif name == "visuals" then
        -- Eye
        ellipse_arc(cx, cy, 8, 4.5, math.pi, math.pi * 2, col, 12)
        ellipse_arc(cx, cy, 8, 4.5, 0, math.pi, col, 12)
        circle(cx, cy, 2.8, col, false, 14)
        circle(cx + 0.6, cy - 0.4, 1.1, col, true, 8)

    elseif name == "world" then
        -- Globe with meridians
        circle(cx, cy, 7, col, false, 24)
        -- latitude
        ellipse_arc(cx, cy, 7, 2.8, 0, math.pi * 2, col, 16)
        -- longitude
        ellipse_arc(cx, cy, 2.8, 7, 0, math.pi * 2, col, 16)
        line(cx, cy - 7, cx, cy + 7, col, 1.2)

    elseif name == "guns" then
        -- Side-view rifle silhouette
        -- barrel
        rect(cx - 2, cy - 2.5, 10, 2.2, col, true)
        -- receiver
        rect(cx - 7, cy - 3.2, 7, 4.2, col, true)
        -- stock
        poly({
            { cx - 7, cy - 2.5 },
            { cx - 11, cy - 3.5 },
            { cx - 11, cy + 2.5 },
            { cx - 7, cy + 1.2 },
        }, col, 1.6)
        line(cx - 7, cy - 2.5, cx - 11, cy - 3.5, col, 1.6)
        line(cx - 11, cy - 3.5, cx - 11, cy + 2.5, col, 1.6)
        line(cx - 11, cy + 2.5, cx - 7, cy + 1.2, col, 1.6)
        -- mag
        rect(cx - 4.5, cy + 1, 2.4, 4, col, true)
        -- front sight
        line(cx + 6, cy - 2.5, cx + 6, cy - 5, col, 1.4)

    elseif name == "misc" then
        -- Three control sliders
        for i = 0, 2 do
            local yy = cy - 6 + i * 6
            line(cx - 7, yy, cx + 7, yy, col, 1.4)
            local knob = ({ -3, 3, 0 })[i + 1]
            circle(cx + knob, yy, 2.2, col, true, 10)
            circle(cx + knob, yy, 2.2, col, false, 10)
        end

    elseif name == "radar" then
        -- Radar dish + sweep
        circle(cx, cy, 7.5, col, false, 24)
        circle(cx, cy, 4.5, col, false, 18)
        circle(cx, cy, 1.5, col, true, 10)
        line(cx, cy, cx + 6.5, cy - 3.5, col, 1.8)
        -- blip
        circle(cx + 3.5, cy + 2.5, 1.3, col, true, 8)
        -- north tick
        line(cx, cy - 7.5, cx, cy - 9.5, col, 1.5)

    elseif name == "config" then
        -- Gear
        local teeth = 8
        for i = 0, teeth - 1 do
            local a = (i / teeth) * math.pi * 2
            local c, s = math.cos(a), math.sin(a)
            local x1, y1 = cx + c * 3.2, cy + s * 3.2
            local x2, y2 = cx + c * 7.2, cy + s * 7.2
            local px, py = -s * 1.5, c * 1.5
            poly({
                { x1 + px, y1 + py },
                { x2 + px * 0.7, y2 + py * 0.7 },
                { x2 - px * 0.7, y2 - py * 0.7 },
                { x1 - px, y1 - py },
                { x1 + px, y1 + py },
            }, col, 1.35)
        end
        circle(cx, cy, 3.8, col, false, 16)
        circle(cx, cy, 1.8, col, true, 10)

    else
        circle(cx, cy, 4, col, false)
    end
end

return M

end)()

-- ── ui/gs_widgets.lua ──
April._mods["ui.gs_widgets"] = (function()
-- Gamesense-style widgets (draw API) backed by ui.gs_state.
local theme = April.require("ui.gs_theme")
local input = April.require("ui.gs_input")
local state = April.require("ui.gs_state")
local anim = April.require("ui.gs_anim")

local M = {}

M.active_slider = nil
M.active_slider_input = nil
M.active_input = nil
M.open_combo = nil
M.open_multi = nil
M.open_color = nil
M.listening_key = nil
M.drag_offset_x = 0
M.drag_offset_y = 0
M.dragging_window = false
M.clip = nil -- { x, y, w, h }
M.popup_used_click = false -- set when a popup consumes this frame's click
M.interacted = false -- any widget captured LMB this frame
M._hue_cache = {} -- id -> hue 0..1 for color picker
M._list_scroll = {} -- id -> first visible option index (0-based)
M.LIST_MAX_VISIBLE = 8
M.wheel_consumed = false -- set when a dropdown/list eats the wheel this frame
M.block_under = false -- true while pointer is over a floating popup (prior frame rect)
-- Floating color picker (drawn after the menu so it doesn't expand sections)
M._color_anchor = nil -- { id, x, y, w }
M._color_hit = nil -- { x, y, w, h } last drawn picker rect
M.open_bind_mode = nil -- keybind id whose Always/Hold/Toggle menu is open
M._bind_mode_anchor = nil -- { id, x, y, w }
M._bind_mode_hit = nil
M._active_input_rect = nil -- { x, y, w, h } for click-outside blur
M._active_slider_input_rect = nil
M._slider_input_meta = {} -- id -> { min, max, float, fmt }
M._slider_edit_text = {} -- id -> string while editing
M._input_repeat_at = 0
M._input_repeat_vk = nil

local LISTEN_SKIP = {
    [0x01] = true, -- LMB used for UI
}

local function listen_skip_vk(vk)
    if LISTEN_SKIP[vk] then return true end
    local menu_vk = state.get_key("april_ui_menu_key")
    if not menu_vk or menu_vk == 0 then menu_vk = 0x2D end
    return vk == menu_vk
end

local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

local function text_w(str, size)
    if draw and draw.get_text_size then
        local w = draw.get_text_size(str, size or theme.FONT)
        if type(w) == "number" then return w end
    end
    return #(tostring(str or "")) * 7
end

local function fit_text(str, max_w, size)
    str = tostring(str or "")
    if max_w <= 0 or text_w(str, size) <= max_w then return str end
    local suffix = "..."
    while #str > 0 and text_w(str .. suffix, size) > max_w do
        str = str:sub(1, -2)
    end
    return str .. suffix
end

local function in_clip(y, h)
    local c = M.clip
    if not c then return true end
    return y >= c.y and y + h <= c.y + c.h
end

local function stacked_metrics(y)
    local label_y = y + 3
    local ctrl_y = y + theme.LABEL_H + theme.LABEL_GAP
    return label_y, ctrl_y, theme.CTRL_H, theme.STACKED_ROW_H
end

local function interactive(x, y, w, h)
    if M.block_under then return false end
    if not in_clip(y, h) then return false end
    local c = M.clip
    if c and not input.hover(c.x, c.y, c.w, c.h) then
        return false
    end
    return true
end

local function ui_clicked(x, y, w, h)
    if M.block_under then return false end
    return input.clicked(x, y, w, h)
end

local function ui_rmb_clicked(x, y, w, h)
    if M.block_under then return false end
    return input.rmb_click and input.hover(x, y, w, h)
end

local function rgb_to_hsv(r, g, b)
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local d = max - min
    local h = 0
    if d > 1e-6 then
        if max == r then
            h = ((g - b) / d) % 6
        elseif max == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        h = h / 6
        if h < 0 then h = h + 1 end
    end
    local s = max <= 1e-6 and 0 or (d / max)
    return h, s, max
end

local function hsv_to_rgb(h, s, v)
    h = (h % 1) * 6
    local i = math.floor(h)
    local f = h - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    if i == 0 then return v, t, p end
    if i == 1 then return q, v, p end
    if i == 2 then return p, v, t end
    if i == 3 then return p, q, v end
    if i == 4 then return t, p, v end
    return v, p, q
end

function M.begin_popups()
    M.popup_used_click = false
    M.interacted = false
    M.wheel_consumed = false
    M._color_anchor = nil
    M._bind_mode_anchor = nil
    M._active_input_rect = nil
    M._active_slider_input_rect = nil

    -- Block underlay widgets when the cursor is over last frame's popup rect
    M.block_under = false
    if M.open_color and M._color_hit then
        local r = M._color_hit
        if input.hover(r.x, r.y, r.w, r.h) then
            M.block_under = true
            if input.lmb or input.lmb_click or input.rmb or input.rmb_click then
                M.interacted = true
                M.popup_used_click = true
            end
        end
    end
    if M.open_bind_mode and M._bind_mode_hit then
        local r = M._bind_mode_hit
        if input.hover(r.x, r.y, r.w, r.h) then
            M.block_under = true
            if input.lmb or input.lmb_click or input.rmb or input.rmb_click then
                M.interacted = true
                M.popup_used_click = true
            end
        end
    end
end

local function mark_interacted()
    M.interacted = true
    M.popup_used_click = true
end

local function open_color_popup(id, anchor_x, anchor_y, row_w)
    if M.open_color == id then
        M.open_color = nil
        M._color_anchor = nil
        M._color_hit = nil
    else
        M.open_color = id
        M.open_combo = nil
        M.open_multi = nil
        M.open_bind_mode = nil
        M._bind_mode_hit = nil
        M._color_anchor = { id = id, x = anchor_x, y = anchor_y, w = row_w or 160 }
    end
end

local function open_bind_mode_popup(id, anchor_x, anchor_y, chip_w)
    if M.open_bind_mode == id then
        M.open_bind_mode = nil
        M._bind_mode_anchor = nil
        M._bind_mode_hit = nil
    else
        M.open_bind_mode = id
        M.open_combo = nil
        M.open_multi = nil
        M.open_color = nil
        M._color_hit = nil
        M._bind_mode_anchor = { id = id, x = anchor_x, y = anchor_y, w = chip_w or 56 }
    end
end

local function list_scroll_for(id, count, max_vis)
    max_vis = max_vis or M.LIST_MAX_VISIBLE
    local max_off = math.max(0, count - max_vis)
    local off = M._list_scroll[id] or 0
    if off < 0 then off = 0 end
    if off > max_off then off = max_off end
    M._list_scroll[id] = off
    return off, max_off, math.min(count, max_vis)
end

local LIST_SCROLL_EDGE = 22

local function apply_list_edge_scroll(id, count, max_vis, list_x, list_y, list_w, list_h)
    max_vis = max_vis or M.LIST_MAX_VISIBLE
    local max_off = math.max(0, count - max_vis)
    if max_off <= 0 then return end
    if not input.hover(list_x, list_y, list_w, list_h) then return end

    local off = M._list_scroll[id] or 0
    if input.wheel ~= 0 and not M.wheel_consumed then
        off = off - input.wheel
        M.wheel_consumed = true
    elseif input.my < list_y + LIST_SCROLL_EDGE then
        off = off - 1
    elseif input.my > list_y + list_h - LIST_SCROLL_EDGE then
        off = off + 1
    end
    if off < 0 then off = 0 end
    if off > max_off then off = max_off end
    M._list_scroll[id] = off
end

function M.end_popups()
    if input.lmb_click and M.active_slider_input and M._active_slider_input_rect then
        local r = M._active_slider_input_rect
        if not input.hover(r.x, r.y, r.w, r.h) then
            M.commit_slider_input()
        end
    end

    if input.lmb_click and M.active_input and M._active_input_rect then
        local r = M._active_input_rect
        if not input.hover(r.x, r.y, r.w, r.h) then
            M.active_input = nil
        end
    end

    if (input.lmb_click or input.rmb_click) and not M.popup_used_click then
        if M.open_combo or M.open_multi or M.open_color or M.open_bind_mode then
            M.open_combo = nil
            M.open_multi = nil
            M.open_color = nil
            M.open_bind_mode = nil
            M._color_anchor = nil
            M._color_hit = nil
            M._bind_mode_anchor = nil
            M._bind_mode_hit = nil
        end
    end
end

--- Draw floating color picker on top of the whole menu (call after columns).
function M.draw_color_overlay()
    if not M.open_color then
        M._color_hit = nil
        return
    end
    local id = M.open_color
    local col = state.get_color(id, { 1, 1, 1, 1 })
    local pw, ph = 168, 138
    local ax = M._color_anchor
    local px, py
    if ax and ax.id == id then
        px = ax.x + (ax.w or 160) - pw
        py = ax.y + theme.ROW_H + 2
    else
        px = input.mx + 12
        py = input.my + 12
    end
    -- Keep on screen
    local sw, sh = 1920, 1080
    if draw and draw.get_screen_size then
        sw, sh = draw.get_screen_size()
    end
    if px < 4 then px = 4 end
    if py < 4 then py = 4 end
    if px + pw > sw - 4 then px = sw - pw - 4 end
    if py + ph > sh - 4 then py = sh - ph - 4 end

    M._color_hit = { x = px, y = py, w = pw, h = ph }

    -- Soft shadow / backdrop
    M.rect(px + 6, py + 8, pw, ph, theme.SHADOW_DEEP, true, theme.CORNER)
    M.rect(px + 3, py + 4, pw, ph, theme.SHADOW, true, theme.CORNER)
    M.draw_color_picker(px, py, pw, ph, id, col)

    if input.hover(px, py, pw, ph) then
        if input.lmb or input.lmb_click or input.rmb or input.rmb_click then
            mark_interacted()
        end
    end
end

--- Right-click keybind settings card.
function M.draw_bind_mode_overlay()
    if not M.open_bind_mode then
        M._bind_mode_hit = nil
        return
    end
    local id = M.open_bind_mode
    local modes = { "Always", "Hold", "Toggle" }
    local mode_id = id .. "_mode"
    local cur = tonumber(state.get(mode_id, 2)) or 2

    local feature_bind = nil
    pcall(function()
        feature_bind = April.require("core.feature_bind")
    end)
    local show_hide = feature_bind and feature_bind.is_registered(id)
    local hide_id = show_hide and feature_bind.hide_key_id(id) or nil
    local hidden = show_hide and state.get(hide_id, false) == true

    local pw = show_hide and 190 or 112
    local header_h = 24
    local row_h = 22
    local footer_h = show_hide and 32 or 0
    local ph = header_h + #modes * row_h + footer_h + 5
    local ax = M._bind_mode_anchor
    local px, py
    if ax and ax.id == id then
        px = ax.x + (ax.w or 56) - pw
        py = ax.y + 18
    else
        px = input.mx
        py = input.my + 8
    end
    local sw, sh = 1920, 1080
    if draw and draw.get_screen_size then
        sw, sh = draw.get_screen_size()
    end
    if px < 4 then px = 4 end
    if py < 4 then py = 4 end
    if px + pw > sw - 4 then px = sw - pw - 4 end
    if py + ph > sh - 4 then py = sh - ph - 4 end

    M._bind_mode_hit = { x = px, y = py, w = pw, h = ph }

    M.rect(px + 4, py + 5, pw, ph, theme.SHADOW, true, theme.CORNER_SMALL)
    M.rect(px, py, pw, ph, theme.OVERLAY, true, theme.CORNER_SMALL)
    M.rect(px, py, pw, ph, theme.BORDER_HOT, false, theme.CORNER_SMALL)
    anim.draw_title_bar(px + 1, py, pw - 2, 2)

    M.text(px + 9, py + 6, "KEYBIND SETTINGS", theme.TEXT_TITLE, theme.FONT_CAPTION)
    M.rect(px + 8, py + header_h - 1, pw - 16, 1, theme.BORDER_SOFT, true)

    for i, name in ipairs(modes) do
        local iy = py + header_h + (i - 1) * row_h
        local selected = (cur == i - 1)
        if input.hover(px, iy, pw, row_h) then
            M.rect(px + 5, iy + 2, pw - 10, row_h - 4, theme.HOVER, true, theme.CORNER_SMALL)
        end
        if selected then
            M.rect(px + 5, iy + 2, pw - 10, row_h - 4,
                theme.alpha(theme.FOCUS, 0.18), true, theme.CORNER_SMALL)
            anim.draw_tab_indicator(px + 5, iy + 5, 2, row_h - 10)
        end
        local dot_x = px + pw - 15
        local dot_y = iy + math.floor(row_h * 0.5)
        M.text(px + 13, iy + 4, name, selected and theme.TEXT_ACTIVE or theme.TEXT, theme.FONT_SMALL)
        if draw and draw.circle then
            draw.circle(dot_x, dot_y, 4, selected and theme.FOCUS or theme.BORDER, 12, 1)
        end
        if selected and draw and draw.circle_filled then
            draw.circle_filled(dot_x, dot_y, 2, anim.checkbox_fill(), 10)
        end
        if input.clicked(px, iy, pw, row_h) then
            mark_interacted()
            state.set(mode_id, i - 1)
            M.open_bind_mode = nil
            M._bind_mode_hit = nil
        end
    end

    if show_hide then
        state.define(hide_id, false)
        local footer_y = py + header_h + #modes * row_h
        M.rect(px + 8, footer_y, pw - 16, 1, theme.BORDER_SOFT, true)
        local hide_y = footer_y + 3
        local hide_h = footer_h - 4
        if input.hover(px, hide_y, pw, hide_h) then
            M.rect(px + 5, hide_y + 2, pw - 10, hide_h - 4, theme.HOVER, true, theme.CORNER_SMALL)
        end
        local box = theme.CHECK_SIZE
        local bx = px + 11
        local by = hide_y + math.floor((hide_h - box) * 0.5)
        M.rect(bx, by, box, box, theme.CHECK_OFF, true, theme.CORNER_SMALL)
        M.rect(bx, by, box, box, hidden and theme.FOCUS or theme.BORDER_SOFT, false, theme.CORNER_SMALL)
        if hidden then
            M.rect(bx + 2, by + 2, box - 4, box - 4, anim.checkbox_fill(), true, theme.CORNER_SMALL)
        end
        M.text(bx + box + 8, hide_y + 7, "Hide from keybind list",
            hidden and theme.TEXT_ACTIVE or theme.TEXT, theme.FONT_SMALL)
        if input.clicked(px, hide_y, pw, hide_h) then
            mark_interacted()
            state.set(hide_id, not hidden)
        end
    end

    if input.hover(px, py, pw, ph) and (input.lmb_click or input.rmb_click) then
        mark_interacted()
    end
end

function M.vk_name(vk)
    return April.require("core.vk_names").label(vk)
end

function M.rect(x, y, w, h, col, filled, rounding)
    if not draw then return end
    local c = M.clip
    if c then
        local x2 = x + w
        local y2 = y + h
        local cx = c.x
        local cy = c.y
        local cx2 = c.x + c.w
        local cy2 = c.y + c.h
        if x2 <= cx or y2 <= cy or x >= cx2 or y >= cy2 then return end
        if x < cx then
            w = w - (cx - x)
            x = cx
        end
        if y < cy then
            h = h - (cy - y)
            y = cy
        end
        if x + w > cx2 then w = cx2 - x end
        if y + h > cy2 then h = cy2 - y end
        if w <= 0 or h <= 0 then return end
    end
    if filled then
        draw.rect_filled(x, y, w, h, col, rounding or 0)
    else
        draw.rect(x, y, w, h, col, rounding or 0, 1)
    end
end

function M.text(x, y, str, col, size)
    if draw and draw.text then
        draw.text(x, y, tostring(str), col, size or theme.FONT)
    end
end

function M.rainbow_bar(x, y, w, h)
    anim.draw_title_bar(x, y, w, h)
end

function M.group_box(x, y, w, h, title)
    local c = M.clip
    if c then
        -- Only paint the portion inside the clip rect
        local top = math.max(y, c.y)
        local bot = math.min(y + h, c.y + c.h)
        if bot <= top then return end
        M.rect(x, top, w, bot - top, theme.PANEL, true)
        M.rect(x, top, w, bot - top, theme.BORDER, false)
        if y >= c.y - 2 and y < c.y + c.h then
            M.text(x + 12, y + 5, title, theme.TEXT_ACTIVE, theme.FONT_TITLE)
        end
        return
    end
    M.rect(x, y, w, h, theme.PANEL, true)
    M.rect(x, y, w, h, theme.BORDER, false)
    M.text(x + 12, y + 5, title, theme.TEXT_ACTIVE, theme.FONT_TITLE)
end

local LISTEN_VKS = {
    0x02, 0x04, 0x05, 0x06, 0x08, 0x09, 0x0D, 0x10, 0x11, 0x12, 0x14, 0x1B, 0x20,
    0x25, 0x26, 0x27, 0x28, 0x2E,
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
    0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D,
    0x4E, 0x4F, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A,
    0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x7B,
    0xBA, 0xBB, 0xBC, 0xBD, 0xBE, 0xBF, 0xC0,
}

function M.tick_key_listen()
    if not M.listening_key then return end
    if input.key_pressed(0x1B) then
        M.listening_key = nil
        return
    end
    for i = 1, #LISTEN_VKS do
        local vk = LISTEN_VKS[i]
        if not listen_skip_vk(vk) and input.key_pressed(vk) then
            state.set_key(M.listening_key, vk)
            M.listening_key = nil
            return
        end
    end
end

local INPUT_VKS = {
    0x20,
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
    0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D,
    0x4E, 0x4F, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A,
    0xBA, 0xBB, 0xBC, 0xBD, 0xBE, 0xBF, 0xC0, 0xDB, 0xDC, 0xDD, 0xDE,
}

local INPUT_SHIFT = {
    [0x30] = ")", [0x31] = "!", [0x32] = "@", [0x33] = "#", [0x34] = "$",
    [0x35] = "%", [0x36] = "^", [0x37] = "&", [0x38] = "*", [0x39] = "(",
    [0xBA] = ":", [0xBB] = "+", [0xBC] = "<", [0xBD] = "_", [0xBE] = ">",
    [0xBF] = "?", [0xC0] = "~", [0xDB] = "{", [0xDC] = "|", [0xDD] = "}",
    [0xDE] = "\"",
}

local INPUT_PLAIN = {
    [0x20] = " ",
    [0x30] = "0", [0x31] = "1", [0x32] = "2", [0x33] = "3", [0x34] = "4",
    [0x35] = "5", [0x36] = "6", [0x37] = "7", [0x38] = "8", [0x39] = "9",
    [0xBA] = ";", [0xBB] = "=", [0xBC] = ",", [0xBD] = "-", [0xBE] = ".",
    [0xBF] = "/", [0xC0] = "`", [0xDB] = "[", [0xDC] = "\\", [0xDD] = "]",
    [0xDE] = "'",
}

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function vk_to_char(vk)
    local shift = input.key_down(0x10)
    if vk >= 0x41 and vk <= 0x5A then
        local ch = string.char(vk)
        return shift and ch or string.lower(ch)
    end
    if shift then
        return INPUT_SHIFT[vk] or INPUT_PLAIN[vk]
    end
    return INPUT_PLAIN[vk]
end

local function input_key_repeat(vk)
    if input.key_pressed(vk) then
        M._input_repeat_vk = vk
        M._input_repeat_at = tick_ms() + 400
        return true
    end
    if M._input_repeat_vk ~= vk or not input.key_down(vk) then
        return false
    end
    local now = tick_ms()
    if now >= M._input_repeat_at then
        M._input_repeat_at = now + 35
        return true
    end
    return false
end

local function focus_input(id)
    M.active_input = id
    M.active_slider_input = nil
    M.open_combo = nil
    M.open_multi = nil
    M.open_color = nil
    M.open_bind_mode = nil
    M.listening_key = nil
    M._input_repeat_vk = nil
end

local SLIDER_INPUT_VKS = {
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
    0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69,
    0xBD, 0x6D, 0xBE, 0x6E,
}

local function slider_vk_to_char(vk)
    if vk >= 0x30 and vk <= 0x39 then
        return string.char(vk)
    end
    if vk >= 0x60 and vk <= 0x69 then
        return string.char(vk - 0x30)
    end
    if vk == 0xBD or vk == 0x6D then return "-" end
    if vk == 0xBE or vk == 0x6E then return "." end
    return nil
end

local function slider_char_allowed(text, ch, is_float, minv)
    if ch:match("%d") then return true end
    if ch == "-" and minv < 0 and text == "" then return true end
    if is_float and ch == "." and not text:find(".", 1, true) then return true end
    return false
end

local function parse_slider_text(text, meta)
    if not meta then return nil end
    text = tostring(text or ""):match("^%s*(.-)%s*$") or ""
    if text == "" or text == "-" or text == "." or text == "-." then return nil end
    local n = tonumber(text)
    if not n then return nil end
    if not meta.float then
        n = math.floor(n + 0.5)
    end
    return clamp(n, meta.min, meta.max)
end

function M.commit_slider_input()
    local id = M.active_slider_input
    if not id then return end
    local meta = M._slider_input_meta[id]
    local n = parse_slider_text(M._slider_edit_text[id], meta)
    if n ~= nil then
        state.set(id, n)
    end
    M.active_slider_input = nil
    M._active_slider_input_rect = nil
    M._input_repeat_vk = nil
end

function M.cancel_slider_input()
    M.active_slider_input = nil
    M._active_slider_input_rect = nil
    M._input_repeat_vk = nil
end

function M.begin_slider_input(id, minv, maxv, is_float, val, fmt)
    M.active_slider_input = id
    M.active_slider = nil
    M.active_input = nil
    M.open_combo = nil
    M.open_multi = nil
    M.open_color = nil
    M.open_bind_mode = nil
    M.listening_key = nil
    M._input_repeat_vk = nil
    fmt = fmt or (is_float and "%.2f" or "%d")
    M._slider_input_meta[id] = {
        min = minv,
        max = maxv,
        float = is_float == true,
        fmt = fmt,
    }
    M._slider_edit_text[id] = string.format(fmt, val)
end

function M.tick_slider_input()
    if not M.active_slider_input or M.listening_key then return end
    if input.key_down(0x11) or input.key_down(0x12) then return end

    local id = M.active_slider_input
    local meta = M._slider_input_meta[id]
    if not meta then
        M.cancel_slider_input()
        return
    end

    local val = tostring(M._slider_edit_text[id] or "")

    if input.key_pressed(0x1B) then
        M.cancel_slider_input()
        return
    end

    if input.key_pressed(0x0D) then
        M.commit_slider_input()
        return
    end

    if input_key_repeat(0x08) or input_key_repeat(0x2E) then
        if #val > 0 then
            M._slider_edit_text[id] = val:sub(1, -2)
        end
        return
    end

    for i = 1, #SLIDER_INPUT_VKS do
        local vk = SLIDER_INPUT_VKS[i]
        if input_key_repeat(vk) then
            local ch = slider_vk_to_char(vk)
            if ch and slider_char_allowed(val, ch, meta.float, meta.min) then
                M._slider_edit_text[id] = val .. ch
            end
            M._input_repeat_vk = nil
            return
        end
    end
end

function M.tick_text_input()
    if not M.active_input or M.listening_key then return end
    if input.key_down(0x11) or input.key_down(0x12) then return end

    local id = M.active_input
    local val = tostring(state.get(id, ""))

    if input.key_pressed(0x1B) or input.key_pressed(0x0D) then
        M.active_input = nil
        M._input_repeat_vk = nil
        return
    end

    if input_key_repeat(0x08) then
        if #val > 0 then
            state.set(id, val:sub(1, -2))
        end
        return
    end

    if input_key_repeat(0x2E) then
        if #val > 0 then
            state.set(id, val:sub(1, -2))
        end
        return
    end

    for i = 1, #INPUT_VKS do
        local vk = INPUT_VKS[i]
        if input.key_pressed(vk) then
            local ch = vk_to_char(vk)
            if ch then
                state.set(id, val .. ch)
            end
            M._input_repeat_vk = nil
            return
        end
    end
end

function M.checkbox(x, y, w, id, label, opts)
    opts = opts or {}
    if id and not state.is_visible(id) then
        return 0
    end
    state.define(id, opts.default == true)
    if opts.color then
        state.define_color(id, opts.color)
    end
    local on = state.get(id, false)
    local h = theme.ROW_H
    if not in_clip(y, h) then return h end

    local hovered = input.hover(x, y, w, h)
    local active = on == true
    local hover_fill = anim.transition("check-hover:" .. tostring(id), hovered, 16)
    if hover_fill > 0.01 then
        M.rect(x, y + 1, w, h - 2, theme.alpha(theme.HOVER, hover_fill), true, theme.CORNER_SMALL)
    end

    local bx = x + 4
    local by = y + (h - theme.CHECK_SIZE) * 0.5
    local active_t = anim.transition("check-state:" .. tostring(id), active, anim.motion_rate(22))
    M.rect(bx + 1, by + 2, theme.CHECK_SIZE, theme.CHECK_SIZE, theme.SHADOW, true, theme.CORNER_SMALL)
    M.rect(bx, by, theme.CHECK_SIZE, theme.CHECK_SIZE, theme.CHECK_OFF, true, theme.CORNER_SMALL)
    M.rect(bx, by, theme.CHECK_SIZE, theme.CHECK_SIZE,
        active and theme.FOCUS or theme.BORDER_SOFT, false, theme.CORNER_SMALL)
    if active_t > 0.01 then
        local inset = 2 + (1 - active_t) * (theme.CHECK_SIZE * 0.35)
        local inner = theme.CHECK_SIZE - inset * 2
        if inner > 1 then
            M.rect(bx + inset, by + inset, inner, inner, theme.alpha(anim.checkbox_fill(), active_t), true, theme.CORNER_SMALL)
        end
    end

    local label_w = w - theme.CHECK_SIZE - 38
    M.text(bx + theme.CHECK_SIZE + 8, y + 4, fit_text(label, label_w, theme.FONT),
        on and theme.TEXT_ACTIVE or theme.TEXT, theme.FONT)

    local has_color = opts.color or state.colors[id]
    local swatch_clicked = false
    if has_color then
        local col = state.get_color(id, opts.color or { 1, 1, 1, 1 })
        local cx = x + w - 18
        M.rect(cx, by, 12, 12, col, true, 2)
        M.rect(cx, by, 12, 12, theme.BORDER, false, 2)
        if ui_clicked(cx - 2, by - 2, 16, 16) then
            swatch_clicked = true
            mark_interacted()
            local hh = rgb_to_hsv(col[1] or 1, col[2] or 1, col[3] or 1)
            M._hue_cache[id] = hh
            open_color_popup(id, x, y, w)
        elseif M.open_color == id then
            -- Keep anchor updated while open so overlay tracks scroll
            M._color_anchor = { id = id, x = x, y = y, w = w }
        end
    end

    if not swatch_clicked and interactive(x, y, w, h) and ui_clicked(x, y, w - (has_color and 22 or 0), h) then
        mark_interacted()
        state.toggle(id)
        pcall(function()
            April.require("core.menu_util").sync_master(id)
        end)
    end
    return h
end

function M.slider(x, y, w, id, label, minv, maxv, default, opts)
    opts = opts or {}
    if id and not state.is_visible(id) then return 0 end
    local is_float = opts.float == true
    state.define(id, default)
    local val = tonumber(state.get(id, default)) or default
    local h = theme.SLIDER_ROW_H
    if not in_clip(y, h) then return h end

    local editing = M.active_slider_input == id
    if editing then
        M._active_slider_input_rect = { x = x, y = y, w = w, h = h }
    end

    local hovered = input.hover(x, y, w, h)
    local hover_fill = anim.transition("slider-hover:" .. tostring(id), hovered, 16)
    if hover_fill > 0.01 then
        M.rect(x, y + 1, w, h - 2, theme.alpha(theme.HOVER, hover_fill), true, theme.CORNER_SMALL)
    end

    local fmt = opts.fmt or (is_float and "%.2f" or "%d")
    local shown
    if editing then
        shown = tostring(M._slider_edit_text[id] or "")
    else
        shown = string.format(fmt, val)
    end
    local vw = text_w(shown ~= "" and shown or "0", theme.FONT_SMALL)
    local value_x = x + w - vw - 6
    M.text(x + 4, y + 3, fit_text(label, w - vw - 22, theme.FONT), theme.TEXT, theme.FONT)
    if editing then
        M.rect(value_x - 4, y + 1, vw + 8, theme.LABEL_H + 2, theme.alpha(theme.FOCUS, 0.22), true, theme.CORNER_SMALL)
        M.rect(value_x - 4, y + 1, vw + 8, theme.LABEL_H + 2, theme.FOCUS, false, theme.CORNER_SMALL)
    end
    M.text(value_x, y + 3, shown, editing and theme.TEXT_ACTIVE or theme.TEXT_DIM, theme.FONT_SMALL)
    if editing then
        local now = tick_ms()
        if math.floor(now / 500) % 2 == 0 then
            M.rect(value_x + vw + 1, y + 4, 1, theme.LABEL_H - 2, theme.TEXT_ACTIVE, true)
        end
    end

    local sx = x + 4
    local sy = y + theme.LABEL_H + theme.LABEL_GAP + 4
    local sw = w - 8
    M.rect(sx, sy, sw, theme.SLIDER_H, theme.SLIDER_BG, true, theme.SLIDER_H * 0.5)
    local t = 0
    if maxv > minv then
        t = clamp((val - minv) / (maxv - minv), 0, 1)
    end
    if t > 0 then
        anim.draw_slider_fill(sx, sy, math.max(2, sw * t), theme.SLIDER_H)
    end
    M.rect(sx, sy, sw, theme.SLIDER_H, theme.BORDER_SOFT, false, theme.SLIDER_H * 0.5)
    local thumb_x = sx + sw * t
    local drag_t = anim.transition("slider-active:" .. tostring(id), M.active_slider == id, anim.motion_rate(24))
    local thumb_w = 6 + drag_t * 2
    M.rect(thumb_x - thumb_w * 0.5 + 1, sy - 1, thumb_w, theme.SLIDER_H + 4,
        theme.SHADOW, true, thumb_w * 0.5)
    M.rect(thumb_x - thumb_w * 0.5, sy - 2, thumb_w, theme.SLIDER_H + 4,
        anim.mix(anim.checkbox_fill(), theme.TEXT_ACTIVE, drag_t), true, thumb_w * 0.5)

    local hot = input.hover(sx, sy - 4, sw, theme.SLIDER_H + 8)
    if interactive(x, y, w, h) and ui_rmb_clicked(x, y, w, h) then
        mark_interacted()
        M.begin_slider_input(id, minv, maxv, is_float, val, fmt)
    elseif not editing and interactive(x, y, w, h)
        and ((input.lmb_click and hot) or (input.lmb and M.active_slider == id)) then
        M.active_slider = id
        mark_interacted()
        local nt = clamp((input.mx - sx) / sw, 0, 1)
        local nv = minv + (maxv - minv) * nt
        if not is_float then nv = math.floor(nv + 0.5) end
        state.set(id, nv)
    elseif M.active_slider == id and not input.lmb then
        M.active_slider = nil
    end
    return h
end

function M.combo(x, y, w, id, label, options, default_idx)
    if id and not state.is_visible(id) then return 0 end
    state.define(id, default_idx or 0)
    local idx = tonumber(state.get(id, default_idx or 0)) or 0
    local label_y, ctrl_y, ctrl_h, h = stacked_metrics(y)
    local open = M.open_combo == id
    if not in_clip(y, h) and not open then return h end

    M.text(x + 4, label_y, fit_text(label, w - 8, theme.FONT), theme.TEXT, theme.FONT)
    local bx, by, bw, bh = x + 4, ctrl_y, w - 8, ctrl_h
    local hovered = input.hover(bx, by, bw, bh)
    local fill = anim.interactive_fill("combo:" .. tostring(id), theme.BUTTON, hovered, open)
    M.rect(bx, by, bw, bh, fill, true, theme.CORNER_SMALL)
    M.rect(bx, by, bw, bh, open and theme.FOCUS or theme.BORDER_SOFT, false, theme.CORNER_SMALL)
    local cur = options[idx + 1] or options[1] or "-"
    M.text(bx + 6, by + math.floor((bh - 12) * 0.5),
        fit_text(cur, bw - 28, theme.FONT_SMALL), theme.TEXT_ACTIVE, theme.FONT_SMALL)
    M.text(bx + bw - 13, by + math.floor((bh - 12) * 0.5), open and "^" or "v", open and theme.TEXT_ACTIVE or theme.TEXT_DIM, theme.FONT_SMALL)

    -- Header toggles open/closed (do not require clip hover - fixes "can't close")
    if ui_clicked(bx, by, bw, bh) then
        mark_interacted()
        if open then
            M.open_combo = nil
        else
            M.open_combo = id
            M.open_multi = nil
            M.open_color = nil
            M.open_bind_mode = nil
            M._list_scroll[id] = 0
        end
        open = M.open_combo == id
    end

    if open then
        local n = #options
        local off, max_off, vis = list_scroll_for(id, n, M.LIST_MAX_VISIBLE)
        local list_h = vis * 18
        local list_y = by + bh
        apply_list_edge_scroll(id, n, M.LIST_MAX_VISIBLE, bx, list_y, bw, list_h)
        off = list_scroll_for(id, n, M.LIST_MAX_VISIBLE)

        M.rect(bx + 2, by + bh + 2, bw, list_h, theme.SHADOW, true, theme.CORNER_SMALL)
        M.rect(bx, by + bh, bw, list_h, theme.OVERLAY, true, theme.CORNER_SMALL)
        M.rect(bx, by + bh, bw, list_h, theme.BORDER_HOT, false, theme.CORNER_SMALL)
        for row = 0, vis - 1 do
            local i = off + row + 1
            local opt = options[i]
            if not opt then break end
            local iy = by + bh + row * 18
            if input.hover(bx, iy, bw, 18) then
                M.rect(bx + 2, iy + 1, bw - 4, 16, theme.HOVER, true, theme.CORNER_SMALL)
            end
            if i - 1 == idx then
                M.rect(bx + 3, iy + 4, 2, 10, anim.checkbox_fill(), true, 1)
            end
            M.text(bx + 10, iy + 2, fit_text(opt, bw - 20, theme.FONT_SMALL),
                (i - 1 == idx) and theme.TEXT_ACTIVE or theme.TEXT, theme.FONT_SMALL)
            if ui_clicked(bx, iy, bw, 18) then
                mark_interacted()
                state.set(id, i - 1)
                M.open_combo = nil
            end
        end
        if max_off > 0 then
            local thumb_h = math.max(10, list_h * (vis / n))
            local ty = by + bh + (list_h - thumb_h) * (off / math.max(1, max_off))
            M.rect(bx + bw - 4, by + bh, 3, list_h, theme.SLIDER_BG, true)
            anim.draw_scroll_thumb(bx + bw - 4, ty, 3, thumb_h)
        end
        if input.hover(bx, by, bw, bh + list_h) and input.lmb_click and not M.block_under then
            mark_interacted()
        end
        return h + list_h
    end
    return h
end

function M.multi(x, y, w, id, label, options, defaults, opts)
    opts = opts or {}
    if id and not state.is_visible(id) then return 0 end
    defaults = defaults or {}
    local def = {}
    for i = 1, #options do
        def[i] = defaults[i] == true
    end
    state.define(id, def)
    local vals = state.get(id, def)
    if type(vals) ~= "table" then
        vals = def
        state.set(id, vals)
    end
    if type(opts.sync_ids) == "table" then
        for i, alias_id in ipairs(opts.sync_ids) do
            vals[i] = state.get(alias_id, def[i]) == true
        end
        -- Derived UI summary; source feature IDs remain authoritative.
        state.values[id] = vals
    end

    local h = theme.STACKED_ROW_H
    local open = M.open_multi == id
    if not in_clip(y, h) and not open then return h end

    local label_y, ctrl_y, ctrl_h = stacked_metrics(y)
    M.text(x + 4, label_y, fit_text(label, w - 8, theme.FONT), theme.TEXT, theme.FONT)
    local bx, by, bw, bh = x + 4, ctrl_y, w - 8, ctrl_h
    local hovered = input.hover(bx, by, bw, bh)
    local fill = anim.interactive_fill("multi:" .. tostring(id), theme.BUTTON, hovered, open)
    M.rect(bx, by, bw, bh, fill, true, theme.CORNER_SMALL)
    M.rect(bx, by, bw, bh, open and theme.FOCUS or theme.BORDER_SOFT, false, theme.CORNER_SMALL)

    local parts = {}
    for i, opt in ipairs(options) do
        if vals[i] then parts[#parts + 1] = opt end
    end
    local summary = (#parts > 0) and table.concat(parts, ", ") or "None"
    summary = fit_text(summary, bw - 20, theme.FONT_SMALL)
    M.text(bx + 6, by + math.floor((bh - 12) * 0.5), summary, theme.TEXT_ACTIVE, theme.FONT_SMALL)

    if ui_clicked(bx, by, bw, bh) then
        mark_interacted()
        if open then
            M.open_multi = nil
        else
            M.open_multi = id
            M.open_combo = nil
            M.open_color = nil
            M.open_bind_mode = nil
            M._list_scroll[id] = 0
        end
        open = M.open_multi == id
    end

    if open then
        local n = #options
        local off, max_off, vis = list_scroll_for(id, n, M.LIST_MAX_VISIBLE)
        local list_h = vis * 18
        local list_y = by + bh
        apply_list_edge_scroll(id, n, M.LIST_MAX_VISIBLE, bx, list_y, bw, list_h)
        off = list_scroll_for(id, n, M.LIST_MAX_VISIBLE)

        M.rect(bx + 2, by + bh + 2, bw, list_h, theme.SHADOW, true, theme.CORNER_SMALL)
        M.rect(bx, by + bh, bw, list_h, theme.OVERLAY, true, theme.CORNER_SMALL)
        M.rect(bx, by + bh, bw, list_h, theme.BORDER_HOT, false, theme.CORNER_SMALL)
        for row = 0, vis - 1 do
            local i = off + row + 1
            local opt = options[i]
            if not opt then break end
            local iy = by + bh + row * 18
            local on = vals[i] == true
            if input.hover(bx, iy, bw, 18) then
                M.rect(bx + 2, iy + 1, bw - 4, 16, theme.HOVER, true, theme.CORNER_SMALL)
            end
            M.rect(bx + 5, iy + 3, 12, 12, theme.CHECK_OFF, true, 2)
            if on then
                M.rect(bx + 7, iy + 5, 8, 8, anim.checkbox_fill(), true, 2)
            end
            M.text(bx + 24, iy + 2, fit_text(opt, bw - 32, theme.FONT_SMALL),
                on and theme.TEXT_ACTIVE or theme.TEXT, theme.FONT_SMALL)
            if ui_clicked(bx, iy, bw, 18) then
                mark_interacted()
                vals[i] = not on
                state.set(id, vals)
                local alias_id = opts.sync_ids and opts.sync_ids[i]
                if alias_id then
                    state.set(alias_id, vals[i])
                end
            end
        end
        if max_off > 0 then
            local thumb_h = math.max(10, list_h * (vis / n))
            local ty = by + bh + (list_h - thumb_h) * (off / math.max(1, max_off))
            M.rect(bx + bw - 4, by + bh, 3, list_h, theme.SLIDER_BG, true)
            anim.draw_scroll_thumb(bx + bw - 4, ty, 3, thumb_h)
        end
        if input.hover(bx, by, bw, bh + list_h) and input.lmb_click and not M.block_under then
            mark_interacted()
        end
        return h + list_h
    end
    return h
end

function M.button(x, y, w, id, label)
    if id and not state.is_visible(id) then return 0 end
    local h = 24
    if not in_clip(y, h) then return h end
    local hovered = input.hover(x, y, w, h)
    local pressed = hovered and input.lmb
    local press_t = anim.transition("button-press:" .. tostring(id), pressed, anim.motion_rate(28))
    local oy = press_t * 1.5
    M.rect(x + 2, y + 3, w, h, theme.SHADOW, true, theme.CORNER_SMALL)
    M.rect(x, y + oy, w, h,
        anim.interactive_fill("button:" .. tostring(id), theme.BUTTON, hovered, pressed),
        true, theme.CORNER_SMALL)
    M.rect(x, y + oy, w, h, hovered and theme.BORDER_HOT or theme.BORDER_SOFT, false, theme.CORNER_SMALL)
    local shown = fit_text(label, w - 16, theme.FONT_SMALL)
    local tw = text_w(shown, theme.FONT_SMALL)
    M.text(x + (w - tw) * 0.5, y + 6 + oy, shown, theme.TEXT_ACTIVE, theme.FONT_SMALL)
    if interactive(x, y, w, h) and ui_clicked(x, y, w, h) then
        mark_interacted()
        state.fire_button(id)
    end
    return h
end

function M.label(x, y, w, text, dim)
    local h = theme.ROW_H - 4
    if not in_clip(y, h) then return h end
    M.text(x + 4, y + 3, text, dim and theme.TEXT_DIM or theme.TEXT_TITLE, theme.FONT_SMALL)
    return h
end

function M.separator(x, y, w)
    local h = 18
    if not in_clip(y, h) then return h end
    M.rect(x + 5, y + 9, w - 10, 1, theme.BORDER_SOFT, true)
    return h
end

function M.keybind(x, y, w, id, label, default_on)
    if id and not state.is_visible(id) then return 0 end
    state.define(id, default_on == true)
    local mode_id = id .. "_mode"
    local hide_id = id .. "_hide_kb"
    state.define(mode_id, 2) -- default Toggle (Always=0, Hold=1, Toggle=2)
    state.define(hide_id, false)

    local h = theme.ROW_H
    if not in_clip(y, h) then return h end

    -- checkbox portion (leave room for key chip; mode is RMB popup)
    local chip_w = 56
    local cw = w - chip_w - 6
    local used = M.checkbox(x, y, cw, id, label, { default = default_on })

    -- key chip: LMB bind, RMB mode (Always / Hold / Toggle)
    local kx = x + w - chip_w
    local ky = y + 3
    local listening = M.listening_key == id
    local vk = state.get_key(id)
    local klabel = listening and "..." or ("[" .. M.vk_name(vk) .. "]")
    local mode_open = M.open_bind_mode == id
    M.rect(kx, ky, chip_w, 16, (listening or mode_open) and theme.ACCENT_DIM or theme.BUTTON, true, 8)
    M.rect(kx, ky, chip_w, 16, (listening or mode_open) and theme.FOCUS or theme.BORDER_SOFT, false, 8)
    local tw = text_w(klabel, theme.FONT_SMALL)
    M.text(kx + (chip_w - tw) * 0.5, ky + 1, klabel, theme.TEXT_ACTIVE, theme.FONT_SMALL)

    if ui_rmb_clicked(kx, ky, chip_w, 16) then
        mark_interacted()
        M.listening_key = nil
        open_bind_mode_popup(id, kx, ky, chip_w)
    elseif ui_clicked(kx, ky, chip_w, 16) then
        mark_interacted()
        M.open_bind_mode = nil
        M._bind_mode_hit = nil
        M.listening_key = listening and nil or id
    elseif mode_open then
        M._bind_mode_anchor = { id = id, x = kx, y = ky, w = chip_w }
    end

    return used
end

function M.aim_key_row(x, y, w, key_id, mode_id, label)
    if key_id and not state.is_visible(key_id) then return 0 end
    mode_id = mode_id or (key_id .. "_mode")
    state.define(mode_id, 1)

    local h = theme.ROW_H
    if not in_clip(y, h) then return h end

    local chip_w = 56
    M.text(x + 4, y + 3, fit_text(label, w - chip_w - 12, theme.FONT), theme.TEXT, theme.FONT)

    local kx = x + w - chip_w
    local ky = y + 3
    local listening = M.listening_key == key_id
    local vk = state.get_key(key_id)
    local klabel = listening and "..." or ("[" .. M.vk_name(vk) .. "]")
    local mode_open = M.open_bind_mode == key_id
    M.rect(kx, ky, chip_w, 16, (listening or mode_open) and theme.ACCENT_DIM or theme.BUTTON, true, 8)
    M.rect(kx, ky, chip_w, 16, (listening or mode_open) and theme.FOCUS or theme.BORDER_SOFT, false, 8)
    local tw = text_w(klabel, theme.FONT_SMALL)
    M.text(kx + (chip_w - tw) * 0.5, ky + 1, klabel, theme.TEXT_ACTIVE, theme.FONT_SMALL)

    if ui_rmb_clicked(kx, ky, chip_w, 16) then
        mark_interacted()
        M.listening_key = nil
        open_bind_mode_popup(key_id, kx, ky, chip_w)
    elseif ui_clicked(kx, ky, chip_w, 16) then
        mark_interacted()
        M.open_bind_mode = nil
        M._bind_mode_hit = nil
        M.listening_key = listening and nil or key_id
    elseif mode_open then
        M._bind_mode_anchor = { id = key_id, x = kx, y = ky, w = chip_w }
    end

    return h
end

function M.hotkey_row(x, y, w, id, label, default_vk)
    if id and not state.is_visible(id) then return 0 end
    if state.get_key(id) == 0 and default_vk and default_vk ~= 0 then
        state.set_key(id, default_vk)
    end

    local h = theme.ROW_H
    if not in_clip(y, h) then return h end

    local chip_w = 56
    M.text(x + 4, y + 4, fit_text(label, w - chip_w - 12, theme.FONT), theme.TEXT, theme.FONT)

    local kx = x + w - chip_w
    local ky = y + 4
    local listening = M.listening_key == id
    local vk = state.get_key(id)
    local klabel = listening and "..." or ("[" .. M.vk_name(vk) .. "]")
    M.rect(kx, ky, chip_w, 18, listening and theme.ACCENT_DIM or theme.BUTTON, true, 8)
    M.rect(kx, ky, chip_w, 18, listening and theme.FOCUS or theme.BORDER_SOFT, false, 8)
    local tw = text_w(klabel, theme.FONT_SMALL)
    M.text(kx + (chip_w - tw) * 0.5, ky + 3, klabel, theme.TEXT_ACTIVE, theme.FONT_SMALL)

    if ui_clicked(kx, ky, chip_w, 18) then
        mark_interacted()
        M.open_bind_mode = nil
        M._bind_mode_hit = nil
        M.listening_key = listening and nil or id
    end

    return h
end

function M.color_row(x, y, w, id, label, default_col)
    if id and not state.is_visible(id) then return 0 end
    state.define_color(id, default_col or { 1, 1, 1, 1 })
    local col = state.get_color(id, default_col)
    local h = theme.ROW_H
    if not in_clip(y, h) then return h end

    M.text(x + 4, y + 3, fit_text(label, w - 32, theme.FONT), theme.TEXT, theme.FONT)
    local cx = x + w - 18
    M.rect(cx, y + 4, 12, 12, col, true, 3)
    M.rect(cx, y + 4, 12, 12, theme.BORDER, false, 3)

    if ui_clicked(cx - 2, y + 2, 16, 16) then
        mark_interacted()
        M._hue_cache[id] = select(1, rgb_to_hsv(col[1] or 1, col[2] or 1, col[3] or 1))
        open_color_popup(id, x, y, w)
    elseif M.open_color == id then
        M._color_anchor = { id = id, x = x, y = y, w = w }
    end
    return h
end

function M.draw_color_picker(px, py, pw, ph, id, col)
    M.rect(px, py, pw, ph, theme.OVERLAY, true, theme.CORNER)
    M.rect(px, py, pw, ph, theme.BORDER_HOT, false, theme.CORNER)

    local hue = M._hue_cache[id]
    if not hue then
        hue = select(1, rgb_to_hsv(col[1] or 1, col[2] or 1, col[3] or 1))
        M._hue_cache[id] = hue
    end
    local _, sat, val = rgb_to_hsv(col[1] or 1, col[2] or 1, col[3] or 1)
    local alpha = col[4] or 1

    local sq = 96
    local sx, sy = px + 8, py + 8
    -- Saturation / value square (sampled grid)
    local steps = 8
    local cell = sq / steps
    for iy = 0, steps - 1 do
        for ix = 0, steps - 1 do
            local s = ix / (steps - 1)
            local v = 1 - iy / (steps - 1)
            local r, g, b = hsv_to_rgb(hue, s, v)
            M.rect(sx + ix * cell, sy + iy * cell, cell + 0.5, cell + 0.5, { r, g, b, 1 }, true)
        end
    end
    M.rect(sx, sy, sq, sq, theme.BORDER, false, theme.CORNER_SMALL)

    -- Hue bar
    local hx, hy, hw, hh = sx + sq + 8, sy, 14, sq
    for i = 0, 23 do
        local t = i / 23
        local r, g, b = hsv_to_rgb(t, 1, 1)
        M.rect(hx, hy + i * (hh / 24), hw, hh / 24 + 0.5, { r, g, b, 1 }, true)
    end
    M.rect(hx, hy, hw, hh, theme.BORDER, false, theme.CORNER_SMALL)

    -- Alpha bar
    local ax, ay, aw, ah = sx, sy + sq + 8, sq + 22, 10
    M.rect(ax, ay, aw, ah, { 0.15, 0.15, 0.15, 1 }, true)
    M.rect(ax, ay, aw * clamp(alpha, 0, 1), ah, { col[1], col[2], col[3], 1 }, true)
    M.rect(ax, ay, aw, ah, theme.BORDER, false, theme.CORNER_SMALL)

    -- Preview
    local prx = ax + aw + 6
    M.rect(prx, ay - 2, 18, 14, { col[1], col[2], col[3], alpha }, true)
    M.rect(prx, ay - 2, 18, 14, theme.BORDER, false)

    local function apply(s, v, a, new_hue)
        if new_hue then
            M._hue_cache[id] = new_hue
            hue = new_hue
        end
        local r, g, b = hsv_to_rgb(hue, s, v)
        state.set_color(id, { r, g, b, a })
        if id == "april_ui_accent" then
            anim.sync_theme()
        end
    end

    if input.lmb and input.hover(sx, sy, sq, sq) then
        M.popup_used_click = true
        local ns = clamp((input.mx - sx) / sq, 0, 1)
        local nv = clamp(1 - (input.my - sy) / sq, 0, 1)
        apply(ns, nv, alpha, nil)
    elseif input.lmb and input.hover(hx, hy, hw, hh) then
        M.popup_used_click = true
        local nh = clamp((input.my - hy) / hh, 0, 1)
        apply(sat, val, alpha, nh)
    elseif input.lmb and input.hover(ax, ay, aw, ah) then
        M.popup_used_click = true
        local na = clamp((input.mx - ax) / aw, 0, 1)
        apply(sat, val, na, nil)
    end

    if input.hover(px, py, pw, ph) and input.lmb_click then
        M.popup_used_click = true
    end

    -- Cursor marks
    local mx = sx + sat * sq
    local my = sy + (1 - val) * sq
    M.rect(mx - 2, my - 2, 4, 4, { 1, 1, 1, 1 }, false)
    M.rect(hx - 1, hy + hue * hh - 1, hw + 2, 3, { 1, 1, 1, 1 }, false)
end

function M.input_row(x, y, w, id, label, default)
    if id and not state.is_visible(id) then return 0 end
    state.define(id, default or "")
    local val = tostring(state.get(id, default or ""))
    local label_y, ctrl_y, ctrl_h, h = stacked_metrics(y)
    if not in_clip(y, h) then return h end
    M.text(x + 4, label_y, fit_text(label, w - 8, theme.FONT), theme.TEXT, theme.FONT)
    local bx, by, bw, bh = x + 4, ctrl_y, w - 8, ctrl_h
    local focused = M.active_input == id
    local hot = input.hover(bx, by, bw, bh)
    if focused then
        M._active_input_rect = { x = bx, y = by, w = bw, h = bh }
    end
    M.rect(bx, by, bw, bh, anim.interactive_fill("input:" .. tostring(id), theme.BUTTON, hot, focused), true, theme.CORNER_SMALL)
    M.rect(bx, by, bw, bh, focused and theme.FOCUS or (hot and theme.BORDER_HOT or theme.BORDER_SOFT), false, theme.CORNER_SMALL)

    local shown = val
    local text_x = bx + 6
    local max_w = bw - 12
    local text_y = by + math.floor((bh - 12) * 0.5)
    if shown == "" then
        M.text(text_x, text_y, "...", theme.TEXT_DIM, theme.FONT_SMALL)
    else
        while #shown > 0 and text_w(shown, theme.FONT_SMALL) > max_w do
            shown = shown:sub(2)
        end
        M.text(text_x, text_y, shown, focused and theme.TEXT_ACTIVE or theme.TEXT, theme.FONT_SMALL)
    end

    if focused then
        local caret_x = text_x + text_w(shown ~= "" and shown or "", theme.FONT_SMALL)
        local now = tick_ms()
        if math.floor(now / 500) % 2 == 0 then
            M.rect(caret_x, by + math.floor((bh - 10) * 0.5), 1, 10, theme.TEXT_ACTIVE, true)
        end
    end

    if interactive(bx, by, bw, bh) and ui_clicked(bx, by, bw, bh) then
        mark_interacted()
        focus_input(id)
    end
    return h
end

function M.estimate_height(item)
    local t = item.type
    local extra = 0
    -- Color pickers overlay - they do not expand layout height
    if item.id and M.open_combo == item.id and item.options then
        extra = math.min(#item.options, M.LIST_MAX_VISIBLE) * 18
    elseif item.id and M.open_multi == item.id and item.options then
        extra = math.min(#item.options, M.LIST_MAX_VISIBLE) * 18
    end
    if t == "slider" then
        return theme.SLIDER_ROW_H + extra
    elseif t == "combo" or t == "multi" or t == "input" then
        return theme.STACKED_ROW_H + extra
    elseif t == "separator" then
        return 18
    elseif t == "button" then
        return 24
    elseif t == "label" then
        return theme.ROW_H - 4
    elseif t == "color" then
        return theme.ROW_H
    elseif t == "checkbox" or t == "keybind" or t == "aim_key" or t == "hotkey" then
        return theme.ROW_H
    end
    return theme.ROW_H + extra
end

function M.draw_item(item, x, y, w)
    local t = item.type
    if t == "checkbox" then
        return M.checkbox(x, y, w, item.id, item.label, item)
    elseif t == "keybind" then
        return M.keybind(x, y, w, item.id, item.label, item.default)
    elseif t == "aim_key" then
        return M.aim_key_row(x, y, w, item.id, item.mode_id, item.label)
    elseif t == "hotkey" then
        return M.hotkey_row(x, y, w, item.id, item.label, item.default)
    elseif t == "slider" then
        return M.slider(x, y, w, item.id, item.label, item.min, item.max, item.default, item)
    elseif t == "combo" then
        return M.combo(x, y, w, item.id, item.label, item.options, item.default)
    elseif t == "multi" then
        return M.multi(x, y, w, item.id, item.label, item.options, item.defaults, item)
    elseif t == "button" then
        return M.button(x + 4, y, w - 8, item.id, item.label)
    elseif t == "label" then
        return M.label(x, y, w, item.label, item.dim)
    elseif t == "separator" then
        return M.separator(x, y, w)
    elseif t == "color" then
        return M.color_row(x, y, w, item.id, item.label, item.default)
    elseif t == "input" then
        return M.input_row(x, y, w, item.id, item.label, item.default)
    end
    return 0
end

return M

end)()

-- ── ui/template_catalog.lua ──
April._mods["ui.catalog"] = (function()
--[[
  April UI — template catalog (no game features).

  HOW TO USE
  ----------
  1. Edit M.TABS to add/remove sidebar tabs (id + icon + title).
     Icon names: aim, visuals, world, guns, misc, radar, config
  2. Implement build_<tab>() that returns an array of "groups".
  3. Wire the tab in M.groups_for().
  4. Read live values from ui.gs_state (see standalone_app examples).

  ITEM HELPERS
  ------------
  cb(id, label, default, color?, gate?)     checkbox (+ optional color swatch)
  kb(id, label, default, gate?)             checkbox with keybind chip
  hk(id, label, gate?, default_vk?)         hotkey only
  ak(key_id, label, gate?)                  aim-key (key + mode combo)
  sl(id, label, min, max, default, float?, gate?)
  combo(id, label, options, default, gate?)
  multi(id, label, options, defaults, gate?)
  color(id, label, default, gate?)
  input(id, label, default, gate?)
  btn(id, label, gate?)
  sep(gate?)                                thin separator
  label(text, dim?, gate?)                  static text

  GATING
  ------
  gate = "parent_id"  -> item only shows while that checkbox is ON
  group.master = "id" -> whole group (except the master row) hides when off
]]

local M = {}

local function cb(id, label, default, color, gate)
    return { type = "checkbox", id = id, label = label, default = default == true, color = color, gate = gate }
end

local function kb(id, label, default, gate)
    return { type = "keybind", id = id, label = label, default = default == true, gate = gate }
end

local function sl(id, label, minv, maxv, default, float, gate)
    return {
        type = "slider",
        id = id,
        label = label,
        min = minv,
        max = maxv,
        default = default,
        float = float == true,
        fmt = float and "%.2f" or "%d",
        gate = gate,
    }
end

local function combo(id, label, options, default, gate)
    return { type = "combo", id = id, label = label, options = options, default = default or 0, gate = gate }
end

local function multi(id, label, options, defaults, gate)
    return { type = "multi", id = id, label = label, options = options, defaults = defaults, gate = gate }
end

local function btn(id, label, gate)
    return { type = "button", id = id, label = label, gate = gate }
end

local function sep(gate)
    return { type = "separator", gate = gate }
end

local function label(text, dim, gate)
    return { type = "label", label = text, dim = dim, gate = gate }
end

local function color(id, label_text, default, gate)
    return { type = "color", id = id, label = label_text, default = default, gate = gate }
end

local function input(id, label_text, default, gate)
    return { type = "input", id = id, label = label_text, default = default or "", gate = gate }
end

local function hk(id, label, gate, default_vk)
    return { type = "hotkey", id = id, label = label, gate = gate, default = default_vk or 0x2D }
end

local function ak(key_id, label, gate)
    return { type = "aim_key", id = key_id, mode_id = key_id .. "_mode", label = label, gate = gate }
end

-- Sidebar tabs (icon must exist in ui.gs_icons).
M.TABS = {
    { id = "aim", icon = "aim", title = "Aimbot" },
    { id = "visuals", icon = "visuals", title = "Visuals" },
    { id = "world", icon = "world", title = "World" },
    { id = "misc", icon = "misc", title = "Misc" },
    { id = "config", icon = "config", title = "Config" },
}

local function build_aim()
    return {
        {
            title = "Example Aimbot",
            master = "demo_aim_enabled",
            items = {
                cb("demo_aim_enabled", "Enable Aimbot", false),
                ak("demo_aim_key", "Aim Key"),
                sep(),
                label("Targeting", false),
                combo("demo_aim_priority", "Priority", { "Crosshair", "Distance" }, 0),
                combo("demo_aim_hitbox", "Hitbox", { "Head", "Chest", "Closest" }, 0),
                multi("demo_aim_filters", "Filters", { "Visible", "Knocked", "Team" }, { true, false, true }),
                sep(),
                sl("demo_aim_fov", "FOV", 10, 360, 90),
                sl("demo_aim_smooth", "Smooth", 1, 25, 8),
                cb("demo_aim_draw_fov", "Draw FOV", false, { 0.2, 1, 0.45, 1 }),
            },
        },
        {
            title = "Silent Aim (example)",
            master = "demo_silent_enabled",
            items = {
                cb("demo_silent_enabled", "Enable Silent", false),
                sl("demo_silent_hitchance", "Hit Chance", 1, 100, 100, false, "demo_silent_enabled"),
                cb("demo_silent_wallbang", "Ignore Walls", false, nil, "demo_silent_enabled"),
            },
        },
    }
end

local function build_visuals()
    return {
        {
            title = "Player ESP (example)",
            master = "demo_esp_enabled",
            items = {
                kb("demo_esp_enabled", "Player ESP", false),
                combo("demo_esp_box", "Box", { "None", "2D", "Corner" }, 1, "demo_esp_enabled"),
                cb("demo_esp_health", "Health Bar", true, nil, "demo_esp_enabled"),
                cb("demo_esp_name", "Name", true, { 1, 0.35, 0.35, 1 }, "demo_esp_enabled"),
                cb("demo_esp_distance", "Distance", true, nil, "demo_esp_enabled"),
                sl("demo_esp_range", "Range", 50, 2000, 500, false, "demo_esp_enabled"),
            },
        },
        {
            title = "Colors",
            items = {
                label("Standalone color pickers", true),
                color("demo_esp_box_color", "Box Color", { 1, 0.3, 0.3, 1 }),
                color("demo_esp_skel_color", "Skeleton Color", { 1, 1, 1, 0.9 }),
            },
        },
    }
end

local function build_world()
    return {
        {
            title = "World ESP (example)",
            master = "demo_world_enabled",
            items = {
                kb("demo_world_enabled", "World ESP", false),
                cb("demo_world_crates", "Crates", false, { 1, 0.85, 0.2, 1 }, "demo_world_enabled"),
                cb("demo_world_vehicles", "Vehicles", false, { 0.3, 0.8, 1, 1 }, "demo_world_enabled"),
                sl("demo_world_range", "Range", 50, 2000, 800, false, "demo_world_enabled"),
            },
        },
    }
end

local function build_misc()
    return {
        {
            title = "Movement (example)",
            items = {
                kb("demo_speed_enabled", "Speed Hack", false),
                sl("demo_speed_amount", "Speed Amount", 1, 10, 2, true, "demo_speed_enabled"),
                kb("demo_fly_enabled", "Fly", false),
            },
        },
        {
            title = "Actions",
            items = {
                label("Buttons fire callbacks via gs_state.on / set_button", true),
                btn("demo_misc_reload", "Reload Script"),
                btn("demo_misc_panic", "Panic Disable"),
                input("demo_misc_note", "Note", "hello"),
            },
        },
    }
end

local function build_config()
    return {
        {
            title = "Appearance",
            items = {
                hk("april_ui_menu_key", "Menu Key", nil, 0x2D),
                sep(),
                combo("april_ui_theme_preset", "Theme Preset", {
                    "Violet Glass", "Midnight Blue", "Graphite", "Emerald Glass",
                }, 0),
                sl("april_ui_window_opacity", "Window Opacity %", 45, 100, 86),
                sl("april_ui_panel_opacity", "Panel Opacity %", 35, 100, 72),
                sl("april_ui_border_strength", "Border Strength %", 10, 100, 58),
                combo("april_ui_corner_style", "Control Corners", { "Sharp", "Soft", "Rounded" }, 2),
                sl("april_ui_scale", "UI Scale %", 80, 125, 100),
                combo("april_ui_density", "Density", { "Compact", "Balanced", "Comfortable" }, 1),
                sl("april_ui_bg_dim", "Backdrop Dim", 0, 40, 0),
                cb("april_ui_show_cursor_dot", "Show Cursor Dot", true),
            },
        },
        {
            title = "Motion & Accent",
            items = {
                combo("april_ui_motion_profile", "Motion Profile", {
                    "Subtle", "Balanced", "Expressive",
                }, 1),
                cb("april_ui_reduce_motion", "Reduce Motion", false),
                cb("april_ui_custom_anim", "Animated Accents", false),
                combo("april_ui_accent_anim", "Accent Style", {
                    "Static", "Rainbow", "Pulse", "Wave", "Flow",
                }, 1, "april_ui_custom_anim"),
                sl("april_ui_anim_speed", "Accent Speed", 1, 100, 40, false, "april_ui_custom_anim"),
                sep(),
                cb("april_ui_custom_colors", "Custom Accent", false),
                color("april_ui_accent", "Accent Color", { 0.78, 0.20, 0.92, 1 }, "april_ui_custom_colors"),
                sep(),
                label("Replace this tab with save/load if you want configs.", true),
                btn("demo_config_reset", "Reset Demo Values"),
            },
        },
    }
end

function M.groups_for(tab_id)
    if tab_id == "aim" then return build_aim() end
    if tab_id == "visuals" then return build_visuals() end
    if tab_id == "world" then return build_world() end
    if tab_id == "misc" then return build_misc() end
    if tab_id == "config" then return build_config() end
    return {}
end

return M

end)()

-- ── ui/custom_menu.lua ──
April._mods["ui.custom_menu"] = (function()
--[[
  Gamesense-style custom menu for April.
  INSERT toggles by default (rebindable in Config -> Menu).
  Scroll: mouse wheel when Vector exposes a reader; else edge-hover (top/bottom of column).
]]

local theme = April.require("ui.gs_theme")
local gin = April.require("ui.gs_input")
local widgets = April.require("ui.gs_widgets")
local anim = April.require("ui.gs_anim")
local icons = April.require("ui.gs_icons")
local catalog = April.require("ui.catalog")
local state = April.require("ui.gs_state")

local M = {}

local TOGGLE_VK_DEFAULT = 0x2D

local function menu_toggle_vk()
    local vk = state.get_key("april_ui_menu_key")
    if not vk or vk == 0 then
        vk = TOGGLE_VK_DEFAULT
    end
    return vk
end
local open = true
local tab_index = 1
local win_x, win_y = 80, 80
local scroll = { left = 0, right = 0 }
local scroll_visual = { left = 0, right = 0 }
local collapsed_groups = {}

local SCROLL_EDGE = 36
local SCROLL_SPEED = 5
local WHEEL_STEP = 48
local PAGE_STEP = 90
local VK_PRIOR, VK_NEXT = 0x21, 0x22

local function screen_size()
    if draw and draw.get_screen_size then
        return draw.get_screen_size()
    end
    if utility and utility.get_screen_size then
        return utility.get_screen_size()
    end
    return 1920, 1080
end

local function clamp_window()
    local sw, sh = screen_size()
    win_x = math.max(0, math.min(win_x, sw - theme.WINDOW_W))
    win_y = math.max(0, math.min(win_y, sh - 40))
end

local function master_on(id)
    if not id then return true end
    return state.get(id, false) == true
end

local function combo_value(id)
    if not id then return nil end
    local v = state.get(id)
    if v == nil and menu and menu.get then
        v = menu.get(id)
    end
    return tonumber(v)
end

local function color_override_on(idx)
    if not idx then return true end
    local t = state.get("april_ui_color_overrides")
    if type(t) ~= "table" then return false end
    local v = t[idx]
    if v == nil and idx >= 1 then
        v = t[idx - 1]
    end
    return v == true or v == 1
end

local function item_visible(item, group)
    if group and group.master then
        if item.id == group.master then
            return true
        end
        if not master_on(group.master) then
            return false
        end
    end
    if item.gate and not master_on(item.gate) then
        return false
    end
    if item.gate2 and not master_on(item.gate2) then
        return false
    end
    if item.gate_combo then
        local cur = combo_value(item.gate_combo)
        local want = tonumber(item.gate_combo_value) or 0
        if cur ~= want then
            return false
        end
    end
    -- Show if ANY (combo_id, value) pair matches. pair = { id, value } or { id, {v1,v2} }
    if item.gate_any_combo then
        local ok = false
        for _, pair in ipairs(item.gate_any_combo) do
            local cid = pair[1] or pair.id
            local want = pair[2] or pair.value
            local cur = combo_value(cid)
            if type(want) == "table" then
                for _, w in ipairs(want) do
                    if cur == w then ok = true; break end
                end
            elseif cur == want then
                ok = true
            end
            if ok then break end
        end
        if not ok then return false end
    end
    if item.color_override_idx and not color_override_on(item.color_override_idx) then
        return false
    end
    if item.id and not state.is_visible(item.id) then
        return false
    end
    return true
end

local function content_height(items, group)
    local h = 0
    local count = 0
    for _, item in ipairs(items) do
        if item_visible(item, group) then
            h = h + widgets.estimate_height(item)
            count = count + 1
        end
    end
    if count > 1 then
        h = h + (count - 1) * theme.ITEM_GAP
    end
    return h + 20
end

local function group_visible(group)
    local items = group.items or {}
    for _, item in ipairs(items) do
        if item_visible(item, group) then
            return true
        end
    end
    return false
end

local function draw_sidebar(x, y, h)
    widgets.rect(x, y, theme.SIDEBAR_W, h, theme.SIDEBAR, true)
    widgets.rect(x + 1, y + 1, theme.SIDEBAR_W - 2, 1, theme.GLASS_HIGHLIGHT, true)
    widgets.rect(x + theme.SIDEBAR_W - 1, y, 1, h, theme.BORDER_SOFT, true)
    widgets.rect(x + theme.SIDEBAR_W - 2, y + 8, 1, h - 16, { 0, 0, 0, 0.26 }, true)

    local tabs = catalog.TABS
    local count = #tabs
    local total_h = count * theme.TAB_H
    local start_y = y + math.max(0, (h - total_h) * 0.5)

    for i, tab in ipairs(tabs) do
        local ty = start_y + (i - 1) * theme.TAB_H
        local active = i == tab_index
        local hot = gin.hover(x + 4, ty + 2, theme.SIDEBAR_W - 9, theme.TAB_H - 8)
        local emphasis = anim.transition("tab:" .. tab.id, active or hot, 14)
        if active then
            anim.draw_tab_indicator(x + 1, ty + 8, 2, theme.TAB_H - 16)
            widgets.rect(x + 8, ty + 5, theme.SIDEBAR_W - 16, theme.TAB_H - 10,
                theme.alpha(theme.SIDEBAR_ACTIVE, 0.42 + emphasis * 0.30), true, theme.CORNER)
        elseif emphasis > 0.01 then
            -- Hover is intentionally limited to a small icon halo; active tabs
            -- use only the icon and left indicator, not a filled selection tile.
            widgets.rect(x + theme.SIDEBAR_W * 0.5 - 14, ty + theme.TAB_H * 0.5 - 14, 28, 28,
                theme.alpha(theme.HOVER, emphasis * 0.45), true, theme.CORNER)
        end

        local col = active and anim.tab_icon_color() or anim.mix(theme.TEXT_DIM, theme.TEXT, emphasis * 0.45)
        local cx = x + theme.SIDEBAR_W * 0.5
        local cy = ty + theme.TAB_H * 0.5
        icons.draw(tab.icon or tab.id, cx, cy, col)

        if gin.clicked(x, ty, theme.SIDEBAR_W, theme.TAB_H) then
            tab_index = i
            scroll.left = 0
            scroll.right = 0
            scroll_visual.left = 0
            scroll_visual.right = 0
            anim.clear_tab_progress(tab.id)
            widgets.open_combo = nil
            widgets.open_multi = nil
        end
    end
end

local function clamp_scroll(key, content_h, view_h)
    local max_scroll = math.max(0, content_h - view_h)
    if scroll[key] < 0 then scroll[key] = 0 end
    if scroll[key] > max_scroll then scroll[key] = max_scroll end
    return max_scroll
end

local function draw_scrollbar(x, y, h, content_h, scroll_key, view_h)
    view_h = view_h or h
    local max_scroll = clamp_scroll(scroll_key, content_h, view_h)
    if max_scroll <= 0 then
        scroll[scroll_key] = 0
        return
    end

    local thumb_h = math.max(28, math.min(68, h * (view_h / content_h)))
    local visual = scroll_visual[scroll_key] or scroll[scroll_key]
    visual = math.max(0, math.min(max_scroll, visual))
    local t = visual / max_scroll
    local thumb_y = y + t * (h - thumb_h)

    -- Inset pill only: no full-height accent track above the section cards.
    widgets.rect(x + 1, y, 2, h, theme.alpha(theme.SLIDER_BG, 0.28), true, 1)
    anim.draw_scroll_thumb(x, thumb_y, 3, thumb_h)
end

local function handle_column_scroll(x, y, w, h, scroll_key, content_h)
    local max_scroll = clamp_scroll(scroll_key, content_h, h)
    if max_scroll <= 0 then return end

    local hot = gin.hover(x, y, w + 14, h)
    if not hot and scroll_key == "left" then
        hot = gin.hover(gin.ui_x, y, theme.SIDEBAR_W + 8, h)
    end
    if not hot then return end

    -- Prefer real wheel when any probe delivers notches this frame.
    -- Open dropdowns consume the wheel first (see gs_widgets).
    if gin.wheel ~= 0 and not widgets.wheel_consumed then
        scroll[scroll_key] = scroll[scroll_key] - gin.wheel * WHEEL_STEP
        clamp_scroll(scroll_key, content_h, h)
        widgets.wheel_consumed = true
        return
    end

    -- Page Up / Page Down while hovering a column (documented IsKeyDown path).
    if gin.key_pressed(VK_PRIOR) then
        scroll[scroll_key] = scroll[scroll_key] - PAGE_STEP
        clamp_scroll(scroll_key, content_h, h)
        return
    end
    if gin.key_pressed(VK_NEXT) then
        scroll[scroll_key] = scroll[scroll_key] + PAGE_STEP
        clamp_scroll(scroll_key, content_h, h)
        return
    end

    -- Fallback: edge hover (only when wheel isn't available / not moving).
    if gin.my < y + SCROLL_EDGE then
        scroll[scroll_key] = scroll[scroll_key] - SCROLL_SPEED
        clamp_scroll(scroll_key, content_h, h)
    elseif gin.my > y + h - SCROLL_EDGE then
        scroll[scroll_key] = scroll[scroll_key] + SCROLL_SPEED
        clamp_scroll(scroll_key, content_h, h)
    end
end

local function draw_group_title(x, box_top, w, title, collapsed, hot)
    local hover = anim.transition("group-header:" .. tostring(title), hot, anim.motion_rate(16))
    if hover > 0.01 then
        widgets.rect(x + 3, box_top + 3, w - 6, theme.GROUP_HEADER_H - 6,
            theme.alpha(theme.HOVER, hover * 0.55), true, 0)
    end
    widgets.text(x + 12, box_top + 7, title, theme.TEXT_ACTIVE, theme.FONT_TITLE)
    widgets.text(x + w - 18, box_top + 7, collapsed and "+" or "-",
        hot and theme.TEXT_ACTIVE or theme.TEXT_DIM, theme.FONT_TITLE)
end

local function draw_group_column(groups, x, y, w, h, scroll_key)
    local pad = theme.GROUP_PAD
    local visible_groups = {}
    for _, group in ipairs(groups) do
        if group_visible(group) then
            local collapse_key = scroll_key .. ":" .. tostring(group.title)
            local collapsed = collapsed_groups[collapse_key] == true
            local expanded = anim.transition(
                "group-expand:" .. collapse_key,
                not collapsed,
                anim.motion_rate(18)
            )
            if collapsed and expanded < 0.02 then expanded = 0 end
            if not collapsed and expanded > 0.98 then expanded = 1 end
            local full_h = content_height(group.items or {}, group)
            visible_groups[#visible_groups + 1] = {
                group = group,
                key = collapse_key,
                collapsed = collapsed,
                expanded = expanded,
                full_h = full_h,
                -- Exactly zero when collapsed: prevents a second bottom strip
                -- from showing beneath the closed section header.
                inner_h = full_h * expanded,
            }
        end
    end

    local total = 0
    for _, entry in ipairs(visible_groups) do
        total = total + entry.inner_h + theme.GROUP_HEADER_H + theme.GROUP_GAP
    end

    clamp_scroll(scroll_key, total, h)

    scroll_visual[scroll_key] = anim.smooth(
        "column-scroll:" .. scroll_key,
        scroll[scroll_key],
        anim.motion_rate(18)
    )
    local gy = y + pad - scroll_visual[scroll_key]
    widgets.clip = { x = x, y = y, w = w, h = h }

    for _, entry in ipairs(visible_groups) do
        local group = entry.group
        local items = group.items or {}
        local inner_h = entry.inner_h
        local box_h = inner_h + theme.GROUP_HEADER_H

        local box_top = gy
        local box_bot = gy + box_h
        if box_bot > y and box_top < y + h then
            local vis_y = math.max(box_top, y)
            local vis_b = math.min(box_bot, y + h)
            local vis_h = vis_b - vis_y
            if vis_h > 1 then
                -- Vector already shadows primitives. Extra offset panels caused the
                -- stacked transparent borders visible on the right/bottom edges.
                widgets.rect(x, vis_y, w, vis_h, theme.PANEL, true, 0)
                widgets.rect(x, vis_y, w, vis_h, theme.BORDER_SOFT, false, 0)
                widgets.rect(x + 1, vis_y + 1, w - 2, 1, theme.GLASS_HIGHLIGHT, true)
                if box_top >= y - 2 and box_top < y + h then
                    widgets.rect(x + 1, box_top + 1, w - 2, theme.GROUP_HEADER_H - 2,
                        theme.PANEL_ALT, true, 0)
                    anim.draw_section_top(x + 1, box_top, w - 2)
                    local header_hot = gin.hover(x, box_top, w, theme.GROUP_HEADER_H)
                    draw_group_title(x, box_top, w, group.title, entry.collapsed, header_hot)
                    if gin.clicked(x, box_top, w, theme.GROUP_HEADER_H)
                        and not widgets.block_under
                        and not widgets.open_combo and not widgets.open_multi
                        and not widgets.open_color and not widgets.open_bind_mode
                    then
                        collapsed_groups[entry.key] = not entry.collapsed
                    end
                end
            end

            local iy = gy + theme.GROUP_HEADER_H + 6
            local ix = x + 7
            local iw = w - 16
            local reveal_bottom = gy + theme.GROUP_HEADER_H + inner_h
            for _, item in ipairs(items) do
                if item_visible(item, group) then
                    local est = widgets.estimate_height(item)
                    if iy >= y and iy + est <= y + h and iy + est <= reveal_bottom then
                        local used = widgets.draw_item(item, ix, iy, iw)
                        if used < 1 then used = est end
                        iy = iy + used + theme.ITEM_GAP
                    else
                        iy = iy + est + theme.ITEM_GAP
                    end
                end
            end
        end

        gy = gy + box_h + theme.GROUP_GAP
    end

    widgets.clip = nil
    handle_column_scroll(x, y, w, h, scroll_key, total)
    draw_scrollbar(x + w - 5, y + pad, h - pad * 2, total, scroll_key, h)
end

local function split_groups(groups, tab_id)
    -- Aim: left = Aimbot + Ragebot, right = Silent + Bullet
    if tab_id == "aim" and #groups >= 4 then
        return { groups[1], groups[2] }, { groups[3], groups[4] }
    end
    if tab_id == "aim" and #groups >= 3 then
        return { groups[1] }, { groups[2], groups[3] }
    end
    if tab_id == "config" and #groups >= 4 then
        return { groups[1], groups[2], groups[3] }, { groups[4] }
    end
    if tab_id == "config" and #groups >= 2 then
        return { groups[1] }, { groups[2] }
    end
    if #groups == 2 then
        return { groups[1] }, { groups[2] }
    end
    local left, right = {}, {}
    for i, g in ipairs(groups) do
        if i % 2 == 1 then
            left[#left + 1] = g
        else
            right[#right + 1] = g
        end
    end
    return left, right
end

function M.init()
    state.define("april_ui_theme_preset", 0)
    state.define("april_ui_window_opacity", 86)
    state.define("april_ui_panel_opacity", 72)
    state.define("april_ui_border_strength", 58)
    state.define("april_ui_corner_style", 2)
    state.define("april_ui_scale", 100)
    state.define("april_ui_density", 1)
    state.define("april_ui_motion_profile", 1)
    state.define("april_ui_reduce_motion", false)
    state.define("april_ui_custom_colors", false)
    state.define("april_ui_custom_anim", false)
    state.define("april_ui_per_element", false)
    state.define("april_ui_show_cursor_dot", true)
    state.define("april_ui_accent", theme.ACCENT)
    state.define("april_ui_accent_anim", 1)
    state.define("april_ui_anim_speed", 40)
    state.define("april_ui_bg_dim", 0)
    state.define("april_ui_menu_fade", false)
    state.define("april_ui_anim_targets", {
        true, true, true, true, true, true, true, true,
    })
    state.define("april_ui_color_overrides", {})
    state.define("april_ui_style_title", 0)
    state.define("april_ui_style_section", 0)
    state.define("april_ui_style_slider", 0)
    state.define("april_ui_style_scroll", 0)
    state.define("april_ui_style_sidebar", 0)
    state.define("april_ui_style_checkbox", 0)
    state.define("april_ui_style_overlay", 0)
    state.define_color("april_ui_col_title", theme.ACCENT)
    state.define_color("april_ui_col_section", theme.ACCENT)
    state.define_color("april_ui_col_slider", theme.ACCENT)
    state.define_color("april_ui_col_scroll", theme.ACCENT)
    state.define_color("april_ui_col_sidebar", theme.ACCENT)
    state.define_color("april_ui_col_checkbox", theme.ACCENT)
    state.define_color("april_ui_col_overlay", theme.ACCENT)
    if state.get_key("april_ui_menu_key") == 0 then
        state.set_key("april_ui_menu_key", TOGGLE_VK_DEFAULT)
    end
    local sw, sh = screen_size()
    theme.sync()
    local default_x = math.floor((sw - theme.WINDOW_W) * 0.5)
    local default_y = math.floor((sh - theme.WINDOW_H) * 0.3)
    state.define("april_ui_window_x", default_x)
    state.define("april_ui_window_y", default_y)
    win_x = tonumber(state.get("april_ui_window_x", default_x)) or default_x
    win_y = tonumber(state.get("april_ui_window_y", default_y)) or default_y
    clamp_window()
end

function M.is_open()
    return open
end

function M.draw()
    if not draw then return end

    gin.begin_frame()
    anim.sync_theme()
    widgets.begin_popups()

    if gin.key_pressed(menu_toggle_vk()) and not widgets.listening_key
        and not widgets.active_input and not widgets.active_slider_input then
        open = not open
        gin.set_menu_open(open)
    end

    widgets.tick_key_listen()
    widgets.tick_slider_input()
    widgets.tick_text_input()

    local open_progress = anim.menu_open_progress(open)
    if not open and open_progress <= 0.015 then
        if gin._menu_open or gin._game_cursor_hidden then
            gin.set_menu_open(false)
        end
        return
    end
    if not open then
        widgets.block_under = true
    end

    gin.set_menu_open(open)
    theme.apply_global_alpha(open_progress)
    if not widgets.dragging_window then
        win_x = tonumber(state.get("april_ui_window_x", win_x)) or win_x
        win_y = tonumber(state.get("april_ui_window_y", win_y)) or win_y
    end
    clamp_window()

    local x = win_x
    local y = win_y + math.floor((1 - open_progress) * 10 * (theme.SCALE or 1))
    local w, h = theme.WINDOW_W, theme.WINDOW_H
    gin.set_ui_rect(x, y, w, h)

    -- Faux glass: backdrop dim + layered translucent depth (Vector has no blur API).
    local sw, sh = screen_size()
    local backdrop = math.max(0, math.min(40, tonumber(state.get("april_ui_bg_dim", 0)) or 0))
    if backdrop > 0 then
        widgets.rect(0, 0, sw, sh, { 0, 0, 0, backdrop * 0.008 * open_progress }, true)
    end

    -- Frame
    local fade = anim.menu_fade()
    local panel_bg = anim.panel_bg()
    -- A single glass surface avoids doubled translucent borders. Vector adds its
    -- own primitive shadow pass, so manual full-window shadows are unnecessary.
    widgets.rect(x, y, w, h, theme.alpha(panel_bg, (panel_bg[4] or 1) * fade), true, 0)
    widgets.rect(x, y, w, h, theme.BORDER, false, 0)
    widgets.rect(x + 1, y + 1, w - 2, 1, theme.GLASS_HIGHLIGHT, true)
    widgets.rect(x + 1, y + 1, w - 2, 1, theme.BORDER_HOT, true)
    anim.draw_title_bar(x + 1, y + 1, w - 2, 2)

    local title_h = math.max(28, math.floor(28 * (theme.SCALE or 1)))
    widgets.rect(x + 1, y + 3, w - 2, title_h, theme.BG_INNER, true, 0)
    widgets.rect(x + 1, y + title_h + 3, w - 2, 1, theme.BORDER_SOFT, true)
    local tab = catalog.TABS[tab_index]
    widgets.text(x + 12, y + 10, "APRIL", theme.TEXT_ACTIVE, theme.FONT_TITLE)
    widgets.text(x + 55, y + 10, "/  " .. (tab and tab.title or ""), theme.TEXT_TITLE, theme.FONT_TITLE)

    if gin.lmb_click and gin.hover(x, y, w - theme.SIDEBAR_W, title_h + 5)
        and not widgets.active_slider and not widgets.active_slider_input and not widgets.listening_key
        and not widgets.active_input
        and not widgets.block_under
        and not widgets.open_combo and not widgets.open_multi and not widgets.open_color
        and not widgets.open_bind_mode then
        widgets.dragging_window = true
        widgets.drag_offset_x = gin.mx - win_x
        widgets.drag_offset_y = gin.my - win_y
    end
    if widgets.dragging_window then
        if gin.lmb then
            win_x = gin.mx - widgets.drag_offset_x
            win_y = gin.my - widgets.drag_offset_y
            clamp_window()
            state.set("april_ui_window_x", math.floor(win_x))
            state.set("april_ui_window_y", math.floor(win_y))
        else
            widgets.dragging_window = false
        end
    end

    local body_y = y + title_h + 6
    local body_h = h - title_h - 10

    draw_sidebar(x + 1, body_y, body_h)

    local content_x = x + theme.SIDEBAR_W + 12
    local content_w = w - theme.SIDEBAR_W - 30
    local col_w = math.floor((content_w - 16) * 0.5)
    local groups = catalog.groups_for(tab and tab.id or "aim")
    local left_groups, right_groups = split_groups(groups, tab and tab.id or "aim")
    local tab_progress = anim.tab_progress(tab and tab.id or "aim")
    local tab_shift = math.floor((1 - tab_progress) * 8 * (theme.SCALE or 1))

    draw_group_column(left_groups, content_x + tab_shift, body_y + 2, col_w, body_h - 4, "left")
    draw_group_column(right_groups, content_x + col_w + 12 + tab_shift, body_y + 2, col_w, body_h - 4, "right")

    -- Floating popups above all sections
    widgets.draw_color_overlay()
    widgets.draw_bind_mode_overlay()
    widgets.end_popups()

    if open then
        gin.draw_cursor()
    end
end

return M

end)()

-- ── ui/template_app.lua ──
April._mods["ui.template_app"] = (function()
--[[
  April UI template entry.

  This file boots the Gamesense draw menu with the TEMPLATE catalog only.
  There are no game features here — copy groups from template_catalog.lua
  and hook gs_state reads in on_frame() (examples below).
]]

local custom_menu = April.require("ui.custom_menu")
local state = April.require("ui.gs_state")

local M = {}

local function wire_demo_callbacks()
    -- Buttons: catalog type "button" calls state.fire_button(id).
    state.set_button("demo_misc_reload", function()
        print("[April UI] demo_misc_reload clicked")
    end)
    state.set_button("demo_misc_panic", function()
        state.set("demo_aim_enabled", false)
        state.set("demo_silent_enabled", false)
        state.set("demo_esp_enabled", false)
        state.set("demo_world_enabled", false)
        state.set("demo_speed_enabled", false)
        state.set("demo_fly_enabled", false)
        print("[April UI] panic — demo masters cleared")
    end)
    state.set_button("demo_config_reset", function()
        for id, def in pairs(state.defaults) do
            if type(id) == "string" and id:sub(1, 5) == "demo_" then
                state.set(id, def)
            end
        end
        print("[April UI] demo values reset to defaults")
    end)

    -- Optional: react when a checkbox changes.
    state.on_change("demo_aim_enabled", function(on)
        print("[April UI] aim enabled =", on and "true" or "false")
    end)
end

function M.init()
    if not draw then
        print("[April UI] draw API missing — cannot render menu")
        return false
    end
    if not (utility and utility.get_mouse_pos) and not (input and input.is_key_down) then
        print("[April UI] mouse APIs missing — UI may not be interactive")
    end

    custom_menu.init()
    wire_demo_callbacks()

    print("[April UI] template ready — INSERT toggles the menu")
    print("[April UI] edit template_catalog.lua (bundled as ui.catalog) then rebuild:")
    print("[April UI]   node scripts/bundle-april-ui.mjs")
    return true
end

function M.on_frame()
    custom_menu.draw()

    -- Example feature tick (replace with your logic):
    -- if state.get("demo_esp_enabled", false) then
    --     local range = state.get("demo_esp_range", 500)
    --     local col = state.get_color("demo_esp_box_color", { 1, 0.3, 0.3, 1 })
    --     ...
    -- end
end

return M

end)()

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
