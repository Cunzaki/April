April._mods["ui.gs_theme"] = (function()
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
    M.BG_INNER = mix_rgb(p.bg, p.panel, 0.28, math.min(1, panel_alpha + 0.08))
    M.PANEL = rgb(p.panel, panel_alpha)
    M.PANEL_ALT = mix_rgb(p.panel, p.raised, 0.35, math.min(1, panel_alpha + 0.06))
    M.PANEL_RAISED = rgb(p.raised, math.min(1, panel_alpha + 0.12))
    M.OVERLAY = mix_rgb(p.panel, p.raised, 0.50, math.min(1, panel_alpha + 0.17))
    M.SHADOW = { 0, 0, 0, 0 }
    M.SHADOW_DEEP = { 0, 0, 0, 0 }
    M.GLASS_HIGHLIGHT = { 1, 1, 1, 0 }
    M.BORDER = { 0.34, 0.35, 0.42, 0.36 * border_alpha }
    M.BORDER_SOFT = { 0.28, 0.29, 0.36, 0.24 * border_alpha }
    M.BORDER_HOT = mix_rgb(p.raised, p.accent, 0.55, 0.72 * border_alpha)
    M.SIDEBAR = mix_rgb(p.bg, p.panel, 0.18, math.min(1, window_alpha + 0.02))
    M.SIDEBAR_ACTIVE = mix_rgb(p.panel, p.accent, 0.20, math.min(1, panel_alpha + 0.08))
    M.HEADER_BG = mix_rgb(p.bg, p.panel, 0.12, math.min(1, window_alpha + 0.03))
    M.NAV_BG = mix_rgb(p.bg, p.panel, 0.26, math.min(1, panel_alpha + 0.02))
    M.NAV_IDLE = mix_rgb(p.bg, p.panel, 0.50, math.min(1, panel_alpha + 0.06))
    M.NAV_HOVER = mix_rgb(p.panel, p.raised, 0.48, math.min(1, panel_alpha + 0.08))
    M.NAV_ACTIVE = mix_rgb(p.panel, p.accent, 0.16, math.min(1, panel_alpha + 0.10))
    M.NAV_INDICATOR = rgb(p.accent, 1)
    M.DOCK_BG = mix_rgb(p.bg, p.panel, 0.44, math.min(1, panel_alpha + 0.08))
    M.DOCK_HOVER = mix_rgb(p.panel, p.raised, 0.66, math.min(1, panel_alpha + 0.12))
    M.DOCK_ACTIVE = mix_rgb(p.panel, p.accent, 0.22, math.min(1, panel_alpha + 0.14))
    M.DOCK_BORDER = mix_rgb(p.raised, p.accent, 0.18, 0.56 * border_alpha)
    M.DOCK_BADGE = rgb(p.accent, 1)
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
    M.FONT_BRAND = scaled(15, scale)
    M.WINDOW_W = scaled(820, scale)
    M.WINDOW_H = scaled(560, scale)
    M.TITLEBAR_H = scaled(30 * density_mul, scale)
    M.NAV_H = scaled(42 * density_mul, scale)
    M.NAVBAR_H = M.NAV_H
    M.NAV_ITEM_H = scaled(34 * density_mul, scale)
    M.NAV_ITEM_MIN_W = scaled(78, scale)
    M.NAV_ITEM_GAP = scaled(4, scale)
    M.NAV_GAP = M.NAV_ITEM_GAP
    M.NAV_PAD_X = scaled(12, scale)
    M.NAV_ICON_GAP = scaled(7, scale)
    M.NAV_INDICATOR_H = scaled(2, scale)
    M.DOCK_H = scaled(30 * density_mul, scale)
    M.DOCK_ITEM_W = scaled(30, scale)
    M.DOCK_ITEM_H = scaled(26 * density_mul, scale)
    M.DOCK_ITEM_GAP = scaled(4, scale)
    M.DOCK_PAD = scaled(4, scale)
    M.DOCK_ICON_SIZE = scaled(16, scale)
    M.DOCK_GAP = M.DOCK_ITEM_GAP
    M.DOCK_CHIP_H = M.DOCK_ITEM_H
    M.DOCK_PAD_X = scaled(10, scale)
    M.DOCK_POPUP_W = scaled(270, scale)
    M.DOCK_POPUP_H = scaled(250 * density_mul, scale)
    M.HEADER_H = M.TITLEBAR_H + M.NAV_H
    M.CONTENT_PAD = scaled(12, scale)
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
    M.SWITCH_W = scaled(29, scale)
    M.SWITCH_H = scaled(15, scale)
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
        "SLIDER_BG", "BUTTON", "BUTTON_HOVER", "HOVER", "FOCUS", "HEADER_BG",
        "NAV_BG", "NAV_IDLE", "NAV_HOVER", "NAV_ACTIVE", "NAV_INDICATOR", "DOCK_BG",
        "DOCK_HOVER", "DOCK_ACTIVE", "DOCK_BORDER", "DOCK_BADGE",
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

April._mods["ui.gs_input"] = (function()
local M = {}
local prev_keys = {}
local frame_keys = {}
local frame_pressed = {}
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
M.wheel_source = nil
M._wheel_accum = 0
M._scroll_ready = false
M._scroll_hook_tries = 0
M._event_scroll_ready = false
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
    if M._api_readers and #M._api_readers > 0 then return M._api_readers end
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
    if connect_signal(uis.InputChanged or uis.input_changed, handle) then
        return true
    end
    return connect_signal(uis.InputBegan or uis.input_began, handle)
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
    M._scroll_hook_tries = (M._scroll_hook_tries or 0) + 1
    if M._scroll_hook_tries > 120 then
        M._scroll_ready = true
        return
    end
    local ok_uis = try_hook_uis()
    local ok_mouse = not ok_uis and try_hook_player_mouse() or false
    M._event_scroll_ready = ok_uis or ok_mouse
    local readers = collect_api_readers()
    if M._event_scroll_ready or #readers > 0 then
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
    vk = tonumber(vk) or 0
    if frame_keys[vk] ~= nil then return frame_keys[vk] end
    local down = false
    if input and input.is_key_down then
        local ok, value = pcall(input.is_key_down, vk)
        down = ok and value == true
    end
    frame_keys[vk] = down
    return down
end
function M.key_pressed(vk)
    vk = tonumber(vk) or 0
    if frame_pressed[vk] ~= nil then return frame_pressed[vk] end
    local down = M.key_down(vk)
    local was = prev_keys[vk] == true
    prev_keys[vk] = down
    local pressed = down and not was
    frame_pressed[vk] = pressed
    return pressed
end
function M.begin_frame()
    frame_keys = {}
    frame_pressed = {}
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
    if not M._event_scroll_ready then
        poll_api_readers()
    end
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

April._mods["ui.gs_state"] = (function()
local M = {}
M.values = {}
M.defaults = {}
M.colors = {}
M.keys = {}
M.callbacks = {}
M.menu_callback = {}
M.buttons = {}
M.visible = {}
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
local function normalize_vk(vk)
    vk = tonumber(vk)
    if not vk then return 0 end
    vk = math.floor(vk)
    if vk < 1 or vk > 0xFE then return 0 end
    return vk
end
function M.get_key(id)
    return normalize_vk(M.keys[id])
end
function M.set_key(id, vk)
    if id == nil then return end
    M.keys[id] = normalize_vk(vk)
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

April._mods["ui.gs_anim"] = (function()
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
function M.navbar_indicator(id, target_x, target_w, rate)
    local key = tostring(id or "primary")
    local speed = M.motion_rate(rate or 18)
    local x = M.smooth("navbar:x:" .. key, target_x, speed)
    local w = M.smooth("navbar:w:" .. key, target_w, speed)
    return x, w
end
function M.dock_transition(id, active, hovered)
    local key = tostring(id)
    local active_t = M.transition("dock:active:" .. key, active, M.motion_rate(20))
    local hover_t = M.transition("dock:hover:" .. key, hovered, M.motion_rate(15))
    return active_t, hover_t
end
function M.dock_color(id, active, hovered)
    local active_t, hover_t = M.dock_transition(id, active, hovered)
    local col = M.mix(theme.DOCK_BG or theme.BUTTON, theme.DOCK_HOVER or theme.BUTTON_HOVER,
        M.ease_out_cubic(hover_t))
    col = M.mix(col, theme.DOCK_ACTIVE or theme.SIDEBAR_ACTIVE, M.ease_out_cubic(active_t))
    return col, active_t, hover_t
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
function M.draw_navbar_indicator(x, y, w, h)
    if not M.anim_target_enabled(M.TARGET_SIDEBAR) then
        M.draw_flat(x, y, w, h, M.STYLE_SIDEBAR, M.COL_SIDEBAR, M.TARGET_SIDEBAR)
        return
    end
    M.draw_bar_h(x, y, w, h, M.phase() * 0.07, M.STYLE_SIDEBAR, M.COL_SIDEBAR, M.TARGET_SIDEBAR)
end
M.draw_nav_indicator = M.draw_navbar_indicator
function M.tab_icon_color()
    local base = M.element_color(M.TARGET_SIDEBAR, M.COL_SIDEBAR)
    if not M.anim_target_enabled(M.TARGET_SIDEBAR) then
        return base
    end
    return M.accent_at_mode(M.resolve_mode(M.STYLE_SIDEBAR), base, M.phase() * 0.03,
        (base[4] or 1) * (theme.GLOBAL_ALPHA or 1))
end
function M.title_color()
    local base = M.element_color(M.TARGET_TITLE, M.COL_TITLE)
    if not M.anim_target_enabled(M.TARGET_TITLE) then
        return base
    end
    return M.accent_at_mode(M.resolve_mode(M.STYLE_TITLE), base, M.phase() * 0.08,
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
    local dim = settings().num("april_ui_overlay_strength", 70)
    if not settings().bool("april_ui_menu_overlay", true) then
        dim = 0
    end
    dim = clamp(dim, 0, 100) * 0.004
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

April._mods["ui.tooltips"] = (function()
local esp_maps = April.require("game.esp_maps")
local M = {}
M.ALLOW_TYPES = {
    checkbox = true,
    keybind = true,
    aim_key = true,
    hotkey = true,
    button = true,
    multi = true,
    combo = true,
    input = true,
    slider = true,
}
M.SKIP_IDS = {
    april_aim_draw_fov = true,
    april_aim_fov_style = true,
    april_aim_target_line = true,
    april_silent_draw_fov = true,
    april_silent_fov_style = true,
    april_silent_target_line = true,
    april_silent_manip_status = true,
    april_silent_manip_peek_vis = true,
    april_desync_visualizer = true,
    april_keybinds_active_only = true,
    april_keybinds_show_unbound = true,
    april_keybinds_show_mode = true,
    april_wp_dist = true,
    april_wp_beacon = true,
    april_wp_draw = true,
    april_ui_show_cursor_dot = true,
    april_ui_custom_colors = true,
    april_ui_custom_anim = true,
    april_ui_reduce_motion = true,
    april_ui_menu_fade = true,
    april_ui_per_element = true,
    april_ui_menu_overlay = true,
    april_ui_snow = true,
    april_fakeduck_spam = true,
}
M.BY_ID = {
    april_aimbot = "Smooth camera aim assist on your current target.",
    april_aim_key = "Hold or toggle this key to activate aimbot.",
    april_silent_aim = "Redirects shots to your locked target without moving the camera.",
    april_bullet_enabled = "Master toggle for advanced bullet routing (hitscan, bullet TP, silent manip). Bind Always / Hold / Toggle from the key chip.",
    april_silent_hitscan = "Registers hits instantly on your locked target. Server may reject invalid shots.",
    april_silent_bullet_tp = "Scans the head for the closest visible point to your crosshair (manip-style math), spawns the ray on the target, and shoots through that point. Cycles offsets every frame.",
    april_silent_bullet_manip = "Finds a shootable angle around cover. Server may reject invalid shots.",
    april_silent_manip_extend = "Searches farther from your body when no close peek is found.",
    april_bullet_body_peek = "Moves you to the peek with desync for server-valid shots. Can cause invalids or kicks.",
    april_thick_bullet = "Expands a chosen body part hitbox on other players (client-side) and fades it. Helps local hit tests; the server can still reject shots that only clip the inflated shell.",
    april_thick_bullet_part = "Which body part to resize on other players.",
    april_thick_bullet_mult = "How large the selected part becomes (1x = normal size, up to 4x).",
    april_aim_targets = "Choose whether aimbot targets players, NPCs, or both.",
    april_aim_filters = "Filters which targets aimbot will consider.",
    april_aim_options = "Extra aimbot behavior options.",
    april_aim_auto_pred = "Leads moving targets using weapon bullet speed and drop. Off = aim the bone only. Also skips prediction when you are not holding a gun.",
    april_aim_smooth = "Higher values move the camera slower toward the target.",
    april_aim_smooth_type = "How smoothing accelerates: Linear, Ease Out, Ease In-Out, Exponential, or Adaptive.",
    april_aim_humanize = "Adds light drift and overshoot so mouse aim feels less robotic.",
    april_aim_humanize_str = "How strong humanize drift and overshoot are.",
    april_aim_whitelist_ids = "Comma-separated Roblox user IDs that Aimbot must ignore. Enable Whitelist inside Filters first. You can also middle-click the current player target to add or remove them.",
    april_silent_targets = "Choose whether silent aim targets players, NPCs, or both.",
    april_silent_filters = "Filters which targets silent aim will consider.",
    april_silent_options = "Extra silent aim behavior options.",
    april_silent_whitelist_ids = "Comma-separated Roblox user IDs that Silent Aim must ignore. Enable Whitelist inside Filters first. You can also middle-click the current player target to add or remove them.",
    april_player_enabled = "Shows boxes and info on other players.",
    april_ui_player_elements = "Choose which info to show on player ESP.",
    april_player_show_held = "Shows the item a player is holding (same read path as Target Gear).",
    april_player_esp_filters = "Filter which players appear on ESP.",
    april_player_esp_flags = "Show status flags (downed, SZ, staff, revive, movement state, VIP, cheater).",
    april_target_overlay = "Shows held weapon and gear for the player closest to your crosshair.",
    april_target_overlay_fov = "Independent FOV (pixels from crosshair) used only by Target Gear Overlay.",
    april_target_overlay_max_dist = "Maximum world distance (studs) for Target Gear Overlay selection.",
    april_crosshair_enabled = "Draws a custom crosshair on screen.",
    april_crosshair_follow = "Moves the crosshair toward your active combat target.",
    april_ui_crosshair_motion = "Adds spin or pulse animation to the crosshair.",
    april_ui_crosshair_options = "Extra crosshair drawing options.",
    april_world_enabled = "Highlights harvestable resources and animals in the world.",
    april_loot_enabled = "Highlights crates, bags, and other loot in the world.",
    april_base_enabled = "Highlights base parts like doors, turrets, and storage.",
    april_npc_enabled = "Highlights NPC soldiers, bosses, helis, and BTR.",
    april_ui_npc_types = "Choose which NPC types appear on ESP.",
    april_ui_npc_elements = "Choose which info to show on NPC ESP.",
    april_npc_btr = "Shows the BTR event vehicle on NPC ESP.",
    april_raid_enabled = "Marks explosion clusters as potential raids.",
    april_raid_notifications = "Toast when a raid explosion is detected.",
    april_world_boxes = "Draws 3D boxes around visible resources.",
    april_world_show_name = "Shows names on resource ESP.",
    april_world_show_distance = "Shows distance on resource ESP.",
    april_loot_boxes = "Draws 3D boxes around visible loot.",
    april_loot_show_name = "Shows names on loot ESP.",
    april_loot_show_distance = "Shows distance on loot ESP.",
    april_base_boxes = "Draws 3D boxes around visible base parts.",
    april_base_show_name = "Shows names on base ESP.",
    april_base_show_distance = "Shows distance on base ESP.",
    april_npc_soldier = "Shows military Soldier NPCs on ESP.",
    april_npc_bruno = "Shows Bruno boss NPCs on ESP.",
    april_npc_boris = "Shows Boris boss NPCs on ESP.",
    april_npc_brutus = "Shows Brutus boss NPCs on ESP.",
    april_npc_attack_heli = "Shows the Attack Heli event NPC on ESP.",
    april_npc_btr = "Shows the BTR event vehicle on ESP.",
    april_npc_diver_dave = "Shows the Diver Dave vendor NPC on ESP.",
    april_npc_pilot_pete = "Shows the Pilot Pete vendor NPC on ESP.",
    april_gunmods_enabled = "Applies weapon stat changes globally to your held gun.",
    april_gm_recoil = "Lowers recoil. Works on any gun — no attachment required.",
    april_gm_spread = "Tightens aim and hip spread. Sights (Holo, ACOG, scopes) also add spread mults that this stacks with.",
    april_gm_sway = "Removes scope sway while aiming. Only affects guns with a scope or sight equipped.",
    april_gm_fire_rate = "Boosts RPM via FireRateMult. Usually needs Muzzle Boost on the gun — without it the game often ignores fire-rate mults.",
    april_gm_speed = "Boosts bullet speed via SpeedMult on live weapon tables. Not an attachment stat — Swift Heavy Ammo also adds speed; equip a gun before enabling.",
    april_gm_range = "Extends max range via RangeMult. Silencer and Compensator reduce range; this patches whatever range mults exist on your gun.",
    april_gm_double_tap = "Forces a 2-round burst on your held gun. Patches ToolInfo directly — does not use GC mults.",
    april_fly_enabled = "Camera-relative HRP velocity fly (WASD + Space/Ctrl). Built-in duck (HipHeight 0.01) and jump state while airborne — does not toggle Fake Duck. Never changes WalkSpeed or JumpPower.",
    april_fly_noclip = "Disables collision on your key character parts while flying. Collision is restored when you land or turn Fly off.",
    april_spider_enabled = "Climbs upward while you press into a nearby wall. It pulses the jump state only after multi-height wall checks, reducing wall snap-back.",
    april_bhop_enabled = "Auto-jumps while you hold Space on the ground for smoother bunny hops.",
    april_antifling_enabled = "Makes other players' character parts non-collidable on your client. Their original collision values are restored when disabled.",
    april_desync_enabled = "Desyncs your network position from where you appear.",
    april_antiaim_enabled = "Spoofs your look direction to other players.",
    april_fakeduck_enabled = "Rapidly ducks your hitbox height.",
    april_fling_enabled = "Launches nearby entities upward.",
    april_autofarm = "Automatically turns and runs to selected resources, verifies the live weak point is visible and centered, then swings using the equipped compatible tool. Vector must be the foreground window because movement and clicks use OS input.",
    april_autofarm_resources = "Select every resource type Autofarm may visit. Your held tool must support that type: axes for trees, pickaxes for nodes, or a compatible hybrid tool.",
    april_autofarm_search_range = "Maximum distance in studs used when searching for the next resource. Larger ranges cover more area but can produce longer direct routes.",
    april_autofarm_debug_path = "Draws a tracer to the exact TreeX or NodeSpark point plus the current state, distance, and held tool.",
    april_farm_helper = "Manual alternative to Autofarm. It redirects your held melee swings to the nearest compatible weak point, but you move and hold attack yourself.",
    april_anti_afk = "Prevents idle kick by simulating activity.",
    april_mod_checker_enabled = "Alerts you when staff or mods join the server.",
    april_keybinds_enabled = "Shows an on-screen list of your keybinds.",
    april_event_status_enabled = "Shows live timed crates, event NPCs, and bosses. BTR tracks the 13-minute loot-fire cooldown after destroy (raids use Raid ESP only).",
    april_event_status_active_only = "Hides inactive event rows from the event status panel.",
    april_map_enabled = "Shows a draggable tactical minimap overlay.",
    april_ui_radar_layers = "Choose what appears on the tactical map.",
    april_map_opacity = "Panel and map transparency for the tactical radar overlay.",
    april_waypoints_enabled = "Place and navigate to saved world waypoints.",
    april_world_chams = "GPU mesh chams on selected resource types (in-range only).",
    april_world_chams_mode = "Fill, Wireframe, Fill Glow, or Wireframe Glow.",
    april_world_chams_color = "Glow preset color (Fill Glow / Wireframe Glow only).",
    april_loot_chams = "GPU mesh chams on selected loot types (in-range only).",
    april_loot_chams_mode = "Fill, Wireframe, Fill Glow, or Wireframe Glow.",
    april_loot_chams_color = "Glow preset color (Fill Glow / Wireframe Glow only).",
    april_base_chams = "GPU mesh chams on selected base structures (in-range only).",
    april_base_chams_mode = "Fill, Wireframe, Fill Glow, or Wireframe Glow.",
    april_base_chams_color = "Glow preset color (Fill Glow / Wireframe Glow only).",
    april_base_xray_enabled = "Wireframe mesh chams on structural walls/floors/foundations (Detail meshes). ApplyChams only — no Material/Texture/Transparency writes, no new instances. Skips Base ESP targets (doors, boxes, turrets, cabinets).",
    april_base_xray_range = "Only structural pieces within this distance get wireframe chams.",
    april_ui_startup_intro = "Plays the April.lua intro whenever the script executes. Save it in your autoload profile.",
    april_ui_menu_key = "Key used to open and close this menu.",
    april_ui_menu_overlay = "Darkens the whole screen behind the menu with a smooth fade. Does not cover menu controls.",
    april_ui_snow = "Soft falling snow behind the menu. Hidden when Reduce Motion is on.",
    april_anime_baddie_enabled = "Shows a draggable transparent anime announcer that reacts to local survival events. Draw-only: it creates no Roblox instances and writes nothing to Workspace.",
    april_anime_baddie_character = "Selects the announcer. More characters can be added through the character registry.",
    april_anime_baddie_personality = "Mixed alternates between teasing and supportive lines; Roasty and Supportive lock the tone.",
    april_anime_baddie_events = "Choose which read-only local state transitions can trigger dialogue: survival, combat status, nearby threats, and world events.",
    april_anime_baddie_scale = "Changes the waist-up character size.",
    april_anime_baddie_opacity = "Changes character transparency. The speech bubble stays nearly opaque for readability.",
    april_anime_baddie_duration = "How long each speech bubble remains visible.",
    april_anime_baddie_cooldown = "Minimum delay between non-urgent comments. Death, downed, drowning, and combat can interrupt.",
    april_anime_baddie_stay = "Keeps the character visible between comments. Disable for event-only popups.",
    april_anime_baddie_preview = "Plays a random greeting so you can test appearance and dialogue.",
    april_anime_baddie_reset = "Moves the announcer back to the lower-left corner.",
    april_cfg_autoload = "Loads your saved profile automatically on inject.",
    april_aim_whitelist_clear = "Clears the aim whitelist player list.",
    april_silent_whitelist_clear = "Clears the silent aim whitelist player list.",
    april_map_reset_position = "Moves the tactical map back to its default spot.",
    april_wp_set = "Saves your current position to the active waypoint slot.",
    april_wp_clear = "Clears the active waypoint slot.",
    april_wp_clear_all = "Clears every saved waypoint.",
    april_cfg_save = "Saves your settings to the active config slot.",
    april_cfg_load = "Loads settings from the active config slot.",
    april_cfg_delete = "Deletes the active config slot.",
    april_reload_modules = "Reloads game module offsets and caches.",
}
local FILTER_TIPS = {
    "Rejects dead or zero-health targets. Leave this on unless you specifically need stale targets.",
    "Only selects targets with a clear line of sight. Turning it off allows locking through walls, but shots may still be blocked.",
    "Ignores players on your team. This applies to players only, not NPC types.",
    "Ignores players protected by a safezone so the aim system does not lock onto targets you cannot damage.",
    "Skips whitelisted players. Enter comma-separated Roblox user IDs below, or middle-click the current player target to toggle them. Aimbot and Silent Aim keep separate lists.",
    "Ignores downed players and looks for a target that is still standing.",
}
local TARGET_TIPS = {
    "Targets other players that pass the selected Filters.",
    "Targets standard Soldier NPCs.",
    "Targets the Bruno boss NPC.",
    "Targets the Boris boss NPC.",
    "Targets the Brutus boss NPC.",
    "Targets the Attack Helicopter NPC.",
    "Targets the BTR armored vehicle NPC.",
    "Targets the Diver Dave NPC.",
    "Targets the Pilot Pete NPC.",
}
local HITBOX_TIPS = {
    "Aims at the head for the highest usual damage.",
    "Aims at the torso for a larger, steadier target.",
    "Aims at the target's left arm.",
    "Aims at the target's right arm.",
    "Aims at the target's left leg.",
    "Aims at the target's right leg.",
    "Automatically uses the valid body part closest to your crosshair.",
}
local TARGET_TYPE_TIPS = {
    "Prefers the valid target closest to the center of your screen.",
    "Prefers the valid target closest to your character in world distance.",
}
local STICKY_TIPS = {
    "Keeps the current valid target instead of constantly switching to a slightly better one. The lock is released when that target becomes invalid.",
}
local SMOOTH_TIPS = {
    "Moves toward the target at a consistent smoothing rate.",
    "Moves faster while far away and settles softly near the target.",
    "Uses a gradual acceleration and deceleration curve.",
    "Uses an exponential curve for a responsive but smooth correction.",
    "Automatically moves faster on large misses and slows down for small corrections.",
}
M.OPTION_TIPS = {
    april_aim_target_type = TARGET_TYPE_TIPS,
    april_silent_target_type = TARGET_TYPE_TIPS,
    april_aim_bone = HITBOX_TIPS,
    april_silent_bone = HITBOX_TIPS,
    april_aim_targets = TARGET_TIPS,
    april_silent_targets = TARGET_TIPS,
    april_aim_filters = FILTER_TIPS,
    april_silent_filters = FILTER_TIPS,
    april_aim_options = STICKY_TIPS,
    april_silent_options = STICKY_TIPS,
    april_aim_smooth_type = SMOOTH_TIPS,
    april_crosshair_source = {
        "Uses the first enabled combat system with a valid target.",
        "Follows Silent Aim's current target.",
        "Follows the regular camera Aimbot's current target.",
    },
    april_autofarm_resources = {
        "Allows Autofarm to harvest tree models. Equip an axe, hatchet, chainsaw, or compatible hybrid tool.",
        "Allows Autofarm to mine Stone_Node models. Equip a pickaxe, mining drill, or compatible hybrid tool.",
        "Allows Autofarm to mine Metal_Node models. Equip a pickaxe, mining drill, or compatible hybrid tool.",
        "Allows Autofarm to mine Phosphate_Node models. Equip a pickaxe, mining drill, or compatible hybrid tool.",
    },
}
M.OPTION_BY_LABEL = {
    ["Outline"] = "Draws only the outside edge.",
    ["Filled Circle"] = "Draws a translucent filled circle with an outline.",
    ["Team Check"] = FILTER_TIPS[3],
    ["Skip Safezone"] = FILTER_TIPS[4],
    ["Skip Downed"] = FILTER_TIPS[6],
    ["Visible Only"] = FILTER_TIPS[2],
    ["Health Check"] = FILTER_TIPS[1],
    ["Whitelist"] = FILTER_TIPS[5],
    ["Sticky Target"] = STICKY_TIPS[1],
    ["None"] = "Disables this visual or selection.",
    ["Health Bar"] = "Shows the target's current health as a bar.",
    ["Skeleton"] = "Draws lines between the target's body joints.",
    ["Name"] = "Shows the target's display name.",
    ["Clan Tag"] = "Shows the target's clan tag when available.",
    ["Held Item"] = "Shows the item or weapon the target currently has equipped.",
    ["Distance"] = "Shows how far away the target is.",
    ["Downed"] = "Shows when a player is knocked down.",
    ["Safezone"] = "Shows when a player is protected by a safezone.",
    ["Staff"] = "Shows the staff/moderator status detected for a player.",
    ["Reviving"] = "Shows when a player is reviving someone.",
    ["Movement"] = "Shows useful movement-state information.",
    ["VIP"] = "Shows the player's VIP status when available.",
    ["Spin"] = "Continuously rotates the visual while enabled.",
    ["Pulse Size"] = "Smoothly grows and shrinks the visual.",
    ["Center Dot"] = "Adds a small dot at the exact screen center.",
    ["Rainbow"] = "Cycles the visual through rainbow colors.",
}
local function register_esp_toggles(list, scope)
    for _, t in ipairs(list or {}) do
        if t.id and not M.BY_ID[t.id] then
            M.BY_ID[t.id] = "Highlights " .. t.label .. " on " .. scope .. "."
        end
        if t.ring_id and not M.BY_ID[t.ring_id] then
            M.BY_ID[t.ring_id] = "Shows a range ring around nearby " .. t.label .. "."
        end
    end
end
register_esp_toggles(esp_maps.WORLD_TOGGLES, "resource ESP")
register_esp_toggles(esp_maps.LOOT_TOGGLES, "loot ESP")
register_esp_toggles(esp_maps.BASE_TOGGLES, "base ESP")
local function clean_label(label)
    label = tostring(label or "")
    label = label:gsub("^Enable ", "")
    return label
end
local function fallback_tip(item)
    local label = clean_label(item.label)
    if label == "" then return nil end
    if item.type == "button" then
        return label .. "."
    end
    if item.type == "aim_key" or item.type == "hotkey" then
        return "Keybind for " .. label:lower() .. "."
    end
    if item.type == "keybind" then
        return "Toggle " .. label:lower() .. "."
    end
    if item.type == "checkbox" or item.type == "multi" then
        return "Enables " .. label:lower() .. "."
    end
    return nil
end
function M.should_tooltip(item)
    if not item or not item.id then return false end
    if not M.ALLOW_TYPES[item.type] then return false end
    if M.SKIP_IDS[item.id] then return false end
    return true
end
function M.for_item(item)
    if not M.should_tooltip(item) then return nil end
    local tip = nil
    if item.tip and item.tip ~= "" then
        tip = item.tip
    elseif item.id and M.BY_ID[item.id] then
        tip = M.BY_ID[item.id]
    else
        tip = fallback_tip(item)
    end
    if not tip then return nil end
    if item.type == "keybind" then
        return tip .. " Left-click the key chip to bind (Mouse 1 works after you release); right-click it for Always, Hold, or Toggle. Hold mode also requires the feature switch enabled. Escape, Backspace, or Delete clears the bind."
    end
    if item.type == "aim_key" then
        return tip .. " Left-click the key chip to bind (Mouse 1 works after you release); right-click it for Always, Hold, or Toggle. Escape, Backspace, or Delete clears the bind."
    end
    if item.type == "hotkey" then
        return tip .. " Left-click the key chip to bind (Mouse 1 works after you release). Escape, Backspace, or Delete clears the bind."
    end
    return tip
end
function M.for_option(id, index, label)
    local by_id = M.OPTION_TIPS[id]
    local tip = by_id and by_id[index] or nil
    if tip then return tip end
    return M.OPTION_BY_LABEL[tostring(label or "")]
end
return M
end)()

April._mods["ui.menu_shim"] = (function()
local state = April.require("ui.gs_state")
local M = {}
M.installed = false
M._real = nil
local function as_bool_default(default)
    return default == true
end
local shim = {}
function shim.add_tab() end
function shim.add_group() end
function shim.add_separator() end
function shim.add_label() end
function shim.add_checkbox(_T, _G, id, _label, default, opts)
    state.define(id, as_bool_default(default))
    opts = opts or {}
    if opts.colorpicker then
        state.define_color(id, opts.colorpicker)
    end
    if opts.key and opts.key ~= 0 then
        if state.get_key(id) == 0 then
            state.set_key(id, opts.key)
        end
    end
end
function shim.add_slider_int(_T, _G, id, _label, _min, _max, default, _opts)
    state.define(id, tonumber(default) or 0)
end
function shim.add_slider_float(_T, _G, id, _label, _min, _max, default, _fmt, _opts)
    state.define(id, tonumber(default) or 0)
end
function shim.add_combo(_T, _G, id, _label, _options, default, _opts)
    state.define(id, tonumber(default) or 0)
end
function shim.add_multicombo(_T, _G, id, _label, options, defaults, _opts)
    local def = {}
    local n = type(options) == "table" and #options or 0
    for i = 1, n do
        def[i] = defaults and defaults[i] == true
    end
    state.define(id, def)
end
function shim.add_colorpicker(_T, _G, id, _label, default, _opts)
    state.define_color(id, default or { 1, 1, 1, 1 })
    state.define(id, default or { 1, 1, 1, 1 })
end
function shim.add_input(_T, _G, id, _label, default)
    state.define(id, default or "")
end
function shim.add_button(_T, _G, id, _label, callback)
    if type(callback) == "function" then
        state.set_button(id, callback)
    end
end
function shim.add_hotkey(_T, _G, id, _label, default_vk, opts)
    opts = opts or {}
    if default_vk and default_vk ~= 0 and state.get_key(id) == 0 then
        state.set_key(id, default_vk)
    end
    local mode_id = id .. "_mode"
    state.define(mode_id, opts.default_mode or opts.mode_default or 1)
end
function shim.get(id)
    return state.get(id, nil)
end
function shim.set(id, value)
    state.set(id, value)
end
function shim.get_color(id)
    return state.get_color(id, nil)
end
function shim.set_color(id, color)
    state.set_color(id, color)
end
function shim.get_key(id)
    return state.get_key(id)
end
function shim.set_key(id, vk)
    state.set_key(id, vk)
end
function shim.set_callback(id, fn)
    state.set_menu_callback(id, fn)
end
function shim.set_visible(id, show)
    state.set_visible(id, show)
end
local aliases = {
    AddTab = "add_tab",
    AddGroup = "add_group",
    AddSeparator = "add_separator",
    AddLabel = "add_label",
    AddCheckbox = "add_checkbox",
    AddSliderInt = "add_slider_int",
    AddSliderFloat = "add_slider_float",
    AddCombo = "add_combo",
    AddMulticombo = "add_multicombo",
    AddColorpicker = "add_colorpicker",
    AddInput = "add_input",
    AddButton = "add_button",
    AddHotkey = "add_hotkey",
    Get = "get",
    Set = "set",
    GetColor = "get_color",
    SetColor = "set_color",
    GetKey = "get_key",
    SetKey = "set_key",
    SetCallback = "set_callback",
    SetVisible = "set_visible",
    addTab = "add_tab",
    addGroup = "add_group",
    addCheckbox = "add_checkbox",
    addSliderInt = "add_slider_int",
    addSliderFloat = "add_slider_float",
    addCombo = "add_combo",
    addMulticombo = "add_multicombo",
    addColorpicker = "add_colorpicker",
    addInput = "add_input",
    addButton = "add_button",
    addHotkey = "add_hotkey",
    getColor = "get_color",
    setColor = "set_color",
    getKey = "get_key",
    setKey = "set_key",
    setCallback = "set_callback",
    setVisible = "set_visible",
}
for alias, real in pairs(aliases) do
    shim[alias] = shim[real]
end
function M.install()
    if M.installed then return true end
    M._real = menu
    April._vector_menu = M._real
    April.custom_ui = true
    menu = shim
    M.installed = true
    return true
end
function M.api()
    return shim
end
return M
end)()

April._mods["ui.gs_icons"] = (function()
local theme = April.require("ui.gs_theme")
local M = {}
local function line(x1, y1, x2, y2, col, t)
    if draw and draw.line then
        draw.line(x1, y1, x2, y2, col, t or 1.5)
    end
end
local function circle(x, y, r, col, filled, segs)
    if not draw then return end
    segs = segs or 24
    if filled and draw.circle_filled then
        draw.circle_filled(x, y, r, col, segs)
    elseif draw.circle then
        draw.circle(x, y, r, col, segs, 1.5)
    end
end
local function rect(x, y, w, h, col, filled, rounding)
    if not draw then return end
    if filled then
        draw.rect_filled(x, y, w, h, col, rounding or 0)
    else
        draw.rect(x, y, w, h, col, rounding or 0, 1.5)
    end
end
local function path(points, col, closed, t)
    if not draw then return end
    if closed and draw.poly_closed then
        draw.poly_closed(points, col, t or 1.5)
        return
    elseif draw.poly then
        draw.poly(points, col, t or 1.5)
    else
        for i = 1, #points - 1 do
            line(points[i][1], points[i][2], points[i + 1][1], points[i + 1][2], col, t)
        end
    end
    if closed and #points > 2 then
        line(points[#points][1], points[#points][2], points[1][1], points[1][2], col, t)
    end
end
local function ellipse_arc(cx, cy, rx, ry, a0, a1, col, steps)
    steps = steps or 12
    local pts = {}
    for i = 0, steps do
        local t = a0 + (a1 - a0) * (i / steps)
        pts[#pts + 1] = { cx + math.cos(t) * rx, cy + math.sin(t) * ry }
    end
    path(pts, col, false, 1.5)
end
function M.draw(name, cx, cy, col)
    col = col or theme.TEXT
    if name == "aim" then
        circle(cx, cy, 5.5, col, false)
        circle(cx, cy, 1.3, col, true, 10)
        line(cx - 9, cy, cx - 5.5, cy, col)
        line(cx + 5.5, cy, cx + 9, cy, col)
        line(cx, cy - 9, cx, cy - 5.5, col)
        line(cx, cy + 5.5, cx, cy + 9, col)
    elseif name == "visuals" then
        ellipse_arc(cx, cy, 8.5, 4.8, math.pi, math.pi * 2, col)
        ellipse_arc(cx, cy, 8.5, 4.8, 0, math.pi, col)
        circle(cx, cy, 2.5, col, false, 18)
        circle(cx, cy, 1.0, col, true, 10)
    elseif name == "world" then
        circle(cx, cy, 7.5, col, false)
        ellipse_arc(cx, cy, 7.3, 2.7, 0, math.pi * 2, col, 16)
        ellipse_arc(cx, cy, 3.2, 7.3, 0, math.pi * 2, col, 16)
    elseif name == "guns" then
        path({
            { cx - 8, cy - 3 }, { cx + 3, cy - 3 },
            { cx + 8, cy }, { cx + 3, cy + 3 },
            { cx - 8, cy + 3 },
        }, col, true, 1.5)
        line(cx - 5, cy - 3, cx - 5, cy + 3, col, 1.3)
        line(cx - 8, cy - 1.5, cx - 8, cy + 1.5, col, 1.5)
    elseif name == "misc" then
        line(cx - 8, cy - 5, cx + 8, cy - 5, col)
        line(cx - 8, cy, cx + 8, cy, col)
        line(cx - 8, cy + 5, cx + 8, cy + 5, col)
        circle(cx - 3, cy - 5, 2, col, false, 14)
        circle(cx + 4, cy, 2, col, false, 14)
        circle(cx - 1, cy + 5, 2, col, false, 14)
    elseif name == "radar" then
        circle(cx, cy, 7.5, col, false)
        ellipse_arc(cx, cy, 4.5, 4.5, -math.pi * 0.45, math.pi * 0.22, col, 8)
        line(cx, cy, cx + 6.2, cy - 4.2, col)
        circle(cx + 3.7, cy + 2.6, 1.1, col, true, 8)
        circle(cx, cy, 1.1, col, true, 8)
    elseif name == "config" then
        circle(cx, cy, 5.7, col, false)
        circle(cx, cy, 2.2, col, false, 16)
        for i = 0, 7 do
            local a = i * math.pi * 0.25
            line(
                cx + math.cos(a) * 6.1, cy + math.sin(a) * 6.1,
                cx + math.cos(a) * 8.2, cy + math.sin(a) * 8.2,
                col, 1.8
            )
        end
    elseif name == "keybinds" then
        rect(cx - 8, cy - 6, 16, 12, col, false, 2)
        for row = 0, 1 do
            for column = 0, 3 do
                circle(cx - 5.5 + column * 3.6, cy - 3 + row * 3.4, 0.65, col, true, 6)
            end
        end
        line(cx - 4, cy + 4, cx + 4, cy + 4, col, 1.2)
    elseif name == "staff" then
        circle(cx, cy - 4.5, 3, col, false, 18)
        ellipse_arc(cx, cy + 6, 6.5, 5.5, math.pi, math.pi * 2, col, 12)
        line(cx - 6.5, cy + 6, cx - 6.5, cy + 3.5, col)
        line(cx + 6.5, cy + 6, cx + 6.5, cy + 3.5, col)
        line(cx + 5.2, cy - 6.8, cx + 7.8, cy - 4.2, col, 1.3)
        line(cx + 7.8, cy - 4.2, cx + 5.2, cy - 1.6, col, 1.3)
    elseif name == "events" then
        circle(cx, cy, 7.5, col, false, 22)
        line(cx, cy, cx, cy - 4.5, col, 1.5)
        line(cx, cy, cx + 4, cy + 2.5, col, 1.5)
        circle(cx, cy, 1.1, col, true, 8)
    elseif name == "map" then
        path({
            { cx - 8, cy - 6 }, { cx - 3, cy - 8 }, { cx + 3, cy - 6 },
            { cx + 8, cy - 8 }, { cx + 8, cy + 6 }, { cx + 3, cy + 8 },
            { cx - 3, cy + 6 }, { cx - 8, cy + 8 },
        }, col, true)
        line(cx - 3, cy - 8, cx - 3, cy + 6, col, 1.2)
        line(cx + 3, cy - 6, cx + 3, cy + 8, col, 1.2)
    elseif name == "waifu" then
        circle(cx - 1.0, cy - 2.8, 3.3, col, false, 18)
        path({
            { cx - 4.0, cy - 3.6 },
            { cx - 3.2, cy - 6.4 },
            { cx - 0.8, cy - 7.4 },
            { cx + 1.8, cy - 6.6 },
            { cx + 2.6, cy - 3.8 },
        }, col, false, 1.5)
        path({
            { cx - 4.0, cy - 2.6 },
            { cx - 5.6, cy + 0.4 },
            { cx - 5.4, cy + 3.2 },
        }, col, false, 1.45)
        path({
            { cx + 2.4, cy - 2.4 },
            { cx + 4.2, cy + 0.6 },
            { cx + 4.0, cy + 3.0 },
        }, col, false, 1.45)
        ellipse_arc(cx - 1.0, cy + 7.8, 6.2, 5.0, math.pi * 1.12, math.pi * 1.88, col, 10)
        rect(cx + 3.6, cy - 8.2, 5.4, 4.0, col, false, 1.6)
        line(cx + 4.6, cy - 4.2, cx + 3.8, cy - 2.6, col, 1.3)
        line(cx + 3.8, cy - 2.6, cx + 5.8, cy - 4.2, col, 1.3)
    elseif name == "settings" then
        line(cx - 8, cy - 5, cx + 8, cy - 5, col)
        line(cx - 8, cy, cx + 8, cy, col)
        line(cx - 8, cy + 5, cx + 8, cy + 5, col)
        circle(cx + 3, cy - 5, 2, col, false, 14)
        circle(cx - 3, cy, 2, col, false, 14)
        circle(cx + 1, cy + 5, 2, col, false, 14)
    else
        circle(cx, cy, 4, col, false)
    end
end
return M
end)()

April._mods["ui.gs_widgets"] = (function()
local theme = April.require("ui.gs_theme")
local input = April.require("ui.gs_input")
local state = April.require("ui.gs_state")
local anim = April.require("ui.gs_anim")
local ui_theme = April.require("core.ui_theme")
local tooltips = April.require("ui.tooltips")
local M = {}
M.active_slider = nil
M.active_slider_input = nil
M.active_input = nil
M.open_combo = nil
M.open_multi = nil
M.open_color = nil
M.listening_key = nil
M.listen_wait_lmb_up = false
M.drag_offset_x = 0
M.drag_offset_y = 0
M.dragging_window = false
M.clip = nil
M.popup_used_click = false
M.interacted = false
M._hue_cache = {}
M._list_scroll = {}
M._list_middle_drag = nil
M.LIST_MAX_VISIBLE = 8
M.wheel_consumed = false
M.block_under = false
M._color_anchor = nil
M._color_hit = nil
M.open_bind_mode = nil
M._bind_mode_anchor = nil
M._bind_mode_hit = nil
M._active_input_rect = nil
M._active_slider_input_rect = nil
M._slider_input_meta = {}
M._slider_edit_text = {}
M._input_repeat_at = 0
M._input_repeat_vk = nil
M.TIP_DELAY_MS = 450
M.TIP_FADE_MS = 180
M._tip_candidate = nil
M._tip_hover_id = nil
M._tip_hover_ms = 0
local LISTEN_SKIP = {
    [0x10] = true,
    [0x11] = true,
    [0x12] = true,
}
local function begin_key_listen(id)
    M.listening_key = id
    M.listen_wait_lmb_up = true
end
local function end_key_listen()
    M.listening_key = nil
    M.listen_wait_lmb_up = false
end
local function listen_skip_vk(vk)
    return LISTEN_SKIP[vk] == true
end
local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end
local function text_w(str, size)
    local fn = draw and (draw.get_text_size or draw.GetTextSize)
    if fn then
        local w = fn(str, size or theme.FONT)
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
    M._tip_candidate = nil
    if not input.mmb then M._list_middle_drag = nil end
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
local function apply_list_wheel_scroll(id, count, max_vis, list_x, list_y, list_w, list_h)
    max_vis = max_vis or M.LIST_MAX_VISIBLE
    local max_off = math.max(0, count - max_vis)
    if max_off <= 0 then return end
    local off = M._list_scroll[id] or 0
    local drag = M._list_middle_drag
    if drag and drag.id == id then
        if input.mmb then
            local raw_rows = (drag.start_y - input.my) / 18
            local rows = raw_rows >= 0 and math.floor(raw_rows) or math.ceil(raw_rows)
            off = drag.start_off + rows
            M.wheel_consumed = true
            M.interacted = true
        else
            M._list_middle_drag = nil
            drag = nil
        end
    end
    if not input.hover(list_x, list_y, list_w, list_h) and not (drag and drag.id == id) then
        return
    end
    if input.mmb_click and not M._list_middle_drag then
        M._list_middle_drag = {
            id = id,
            start_y = input.my,
            start_off = off,
        }
        M.wheel_consumed = true
        M.interacted = true
    end
    if not M.wheel_consumed then
        if input.wheel ~= 0 then
            off = off - input.wheel
            M.wheel_consumed = true
        elseif input.my < list_y + LIST_SCROLL_EDGE then
            off = off - 1
        elseif input.my > list_y + list_h - LIST_SCROLL_EDGE then
            off = off + 1
        end
    end
    if off < 0 then off = 0 end
    if off > max_off then off = max_off end
    M._list_scroll[id] = off
end
local function frame_dt()
    if utility and utility.get_delta_time then
        local dt = utility.get_delta_time()
        if dt and dt > 0 and dt < 0.25 then return dt end
    end
    return 0.016
end
function M.register_tooltip_hover(id, tip, x, y, w, h)
    if not id or not tip or tip == "" then return end
    if M.block_under then return end
    if not in_clip(y, h) then return end
    if input.hover(x, y, w, h) then
        M._tip_candidate = { id = id, tip = tip, x = x, y = y, w = w, h = h }
    end
end
function M.end_tooltip_frame()
    local c = M._tip_candidate
    if c and c.id == M._tip_hover_id then
        M._tip_hover_ms = M._tip_hover_ms + frame_dt() * 1000
    else
        M._tip_hover_id = c and c.id or nil
        M._tip_hover_ms = 0
    end
    M._tip_active = c
end
local function wrap_tip_lines(text, max_w, fs)
    text = tostring(text or "")
    local lines = {}
    local line = ""
    for word in text:gmatch("%S+") do
        local test = line == "" and word or (line .. " " .. word)
        if text_w(test, fs) > max_w and line ~= "" then
            lines[#lines + 1] = line
            line = word
        else
            line = test
        end
    end
    if line ~= "" then
        lines[#lines + 1] = line
    end
    return #lines > 0 and lines or { text }
end
function M.draw_tooltip_overlay()
    if M.block_under or M.open_color or M.open_bind_mode then
        return
    end
    if not M._tip_active or M._tip_hover_ms < M.TIP_DELAY_MS then
        return
    end
    local fade = math.min(1, (M._tip_hover_ms - M.TIP_DELAY_MS) / M.TIP_FADE_MS)
    fade = fade * fade * (3 - 2 * fade)
    if fade <= 0.01 then return end
    local anchor = M._tip_active
    local fs = 11
    local pad = 8
    local max_line_w = 228
    local lines = wrap_tip_lines(anchor.tip, max_line_w, fs)
    local tw = 0
    for i = 1, #lines do
        tw = math.max(tw, text_w(lines[i], fs))
    end
    local box_w = math.min(260, tw + pad * 2)
    local box_h = #lines * 13 + pad * 2
    local tx = anchor.x + anchor.w * 0.5 - box_w * 0.5
    local ty = anchor.y + anchor.h + 6
    local sw, sh = 1920, 1080
    if draw and draw.get_screen_size then
        sw, sh = draw.get_screen_size()
    end
    tx = math.max(8, math.min(tx, sw - box_w - 8))
    if ty + box_h > sh - 8 then
        ty = anchor.y - box_h - 6
    end
    ty = math.max(8, ty)
    local bg = theme.alpha(ui_theme.PANEL, 0.96 * fade)
    local border = theme.alpha(ui_theme.BORDER, 0.55 * fade)
    local accent = theme.alpha(ui_theme.CYAN, fade)
    M.rect(tx, ty, box_w, box_h, bg, true, theme.CORNER_SMALL)
    M.rect(tx, ty, box_w, box_h, border, false, theme.CORNER_SMALL)
    M.rect(tx + 1, ty + 1, box_w - 2, 2, accent, true)
    for i = 1, #lines do
        local col = theme.alpha(i == 1 and ui_theme.TEXT or ui_theme.TEXT_MUTED, fade)
        M.text(tx + pad, ty + pad + (i - 1) * 13, lines[i], col, fs)
    end
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
    local sw, sh = 1920, 1080
    if draw and draw.get_screen_size then
        sw, sh = draw.get_screen_size()
    end
    if px < 4 then px = 4 end
    if py < 4 then py = 4 end
    if px + pw > sw - 4 then px = sw - pw - 4 end
    if py + ph > sh - 4 then py = sh - ph - 4 end
    M._color_hit = { x = px, y = py, w = pw, h = ph }
    M.draw_color_picker(px, py, pw, ph, id, col)
    if input.hover(px, py, pw, ph) then
        if input.lmb or input.lmb_click or input.rmb or input.rmb_click then
            mark_interacted()
        end
    end
end
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
    M.rect(px, py, pw, ph, theme.OVERLAY, true, theme.CORNER_SMALL)
    M.rect(px, py, pw, ph, theme.BORDER_SOFT, false, theme.CORNER_SMALL)
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
    local fill = draw.rect_filled or draw.RectFilled
    local outline = draw.rect or draw.Rect
    if filled and fill then
        fill(x, y, w, h, col, rounding or 0)
    elseif not filled and outline then
        outline(x, y, w, h, col, rounding or 0, 1)
    end
end
function M.text(x, y, str, col, size)
    local fn = draw and (draw.text or draw.Text)
    if fn then
        fn(x, y, tostring(str), col, size or theme.FONT)
    end
end
function M.rainbow_bar(x, y, w, h)
    anim.draw_title_bar(x, y, w, h)
end
function M.group_box(x, y, w, h, title)
    local c = M.clip
    if c then
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
local LISTEN_SIDE_MODS = { 0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5 }
local LISTEN_VKS = {}
for i = 1, #LISTEN_SIDE_MODS do
    LISTEN_VKS[#LISTEN_VKS + 1] = LISTEN_SIDE_MODS[i]
end
local SIDE_MOD_SET = {
    [0xA0] = true, [0xA1] = true, [0xA2] = true,
    [0xA3] = true, [0xA4] = true, [0xA5] = true,
}
for vk = 0x01, 0xFE do
    if not SIDE_MOD_SET[vk] then
        LISTEN_VKS[#LISTEN_VKS + 1] = vk
    end
end
local function assign_listen_key(vk)
    local id = M.listening_key
    state.set_key(id, vk)
    local mode_id = id .. "_mode"
    local mode = state.get(mode_id, nil)
    if mode ~= nil and tonumber(mode) == 0 then
        state.set(mode_id, 2)
    end
    end_key_listen()
end
local MODIFIER_PAIRS = {
    { generic = 0x10, left = 0xA0, right = 0xA1 },
    { generic = 0x11, left = 0xA2, right = 0xA3 },
    { generic = 0x12, left = 0xA4, right = 0xA5 },
}
local function try_capture_modifier()
    for i = 1, #MODIFIER_PAIRS do
        local p = MODIFIER_PAIRS[i]
        local l_down = input.key_down(p.left)
        local r_down = input.key_down(p.right)
        local g_down = input.key_down(p.generic)
        if l_down or r_down or g_down then
            local edge = input.key_pressed(p.left)
                or input.key_pressed(p.right)
                or input.key_pressed(p.generic)
            if edge then
                if l_down and not r_down then
                    assign_listen_key(p.left)
                    return true
                end
                if r_down and not l_down then
                    assign_listen_key(p.right)
                    return true
                end
                if l_down then
                    assign_listen_key(p.left)
                    return true
                end
                if r_down then
                    assign_listen_key(p.right)
                    return true
                end
                assign_listen_key(p.generic)
                return true
            end
        end
    end
    return false
end
function M.tick_key_listen()
    if not M.listening_key then
        M.listen_wait_lmb_up = false
        return
    end
    if input.key_pressed(0x1B)
        or input.key_pressed(0x08)
        or input.key_pressed(0x2E)
    then
        state.set_key(M.listening_key, 0)
        end_key_listen()
        return
    end
    if M.listen_wait_lmb_up then
        if not (input.lmb or input.key_down(0x01)) then
            M.listen_wait_lmb_up = false
        else
            if try_capture_modifier() then
                return
            end
            for i = 1, #LISTEN_VKS do
                local vk = LISTEN_VKS[i]
                if vk ~= 0x01 and not listen_skip_vk(vk) and input.key_pressed(vk) then
                    assign_listen_key(vk)
                    return
                end
            end
            return
        end
    end
    if try_capture_modifier() then
        return
    end
    for i = 1, #LISTEN_VKS do
        local vk = LISTEN_VKS[i]
        if not listen_skip_vk(vk) and input.key_pressed(vk) then
            assign_listen_key(vk)
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
    end_key_listen()
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
    end_key_listen()
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
    local switch_w = theme.SWITCH_W or 28
    local switch_h = theme.SWITCH_H or 14
    local bx = x + 4
    local by = y + (h - switch_h) * 0.5
    local active_t = anim.transition("check-state:" .. tostring(id), active, anim.motion_rate(22))
    local track = anim.mix(theme.CHECK_OFF, anim.checkbox_fill(), active_t * 0.72)
    M.rect(bx, by, switch_w, switch_h, track, true, switch_h * 0.5)
    M.rect(bx, by, switch_w, switch_h,
        active and theme.alpha(theme.FOCUS, 0.88) or theme.BORDER_SOFT, false, switch_h * 0.5)
    local knob = math.max(8, switch_h - 4)
    local knob_x = bx + 2 + (switch_w - knob - 4) * active_t
    M.rect(knob_x, by + 2, knob, knob,
        anim.mix(theme.TEXT_DIM, theme.TEXT_ACTIVE, active_t), true, knob * 0.5)
    local label_w = w - switch_w - 38
    M.text(bx + switch_w + 8, y + 4, fit_text(label, label_w, theme.FONT),
        on and theme.TEXT_ACTIVE or theme.TEXT, theme.FONT)
    local has_color = not opts.hide_color and (opts.color or state.colors[id])
    local swatch_clicked = false
    if has_color then
        local col = state.get_color(id, opts.color or { 1, 1, 1, 1 })
        local cx = x + w - 18
        local swatch_y = y + (h - 12) * 0.5
        M.rect(cx, swatch_y, 12, 12, col, true, 4)
        M.rect(cx, swatch_y, 12, 12, theme.BORDER, false, 4)
        if ui_clicked(cx - 2, swatch_y - 2, 16, 16) then
            swatch_clicked = true
            mark_interacted()
            local hh = rgb_to_hsv(col[1] or 1, col[2] or 1, col[3] or 1)
            M._hue_cache[id] = hh
            open_color_popup(id, x, y, w)
        elseif M.open_color == id then
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
    local arrow_col = open and theme.TEXT_ACTIVE or theme.TEXT_DIM
    local line = draw and (draw.line or draw.Line)
    if line then
        local ax = bx + bw - 12
        local ay = by + bh * 0.5
        if open then
            line(ax - 3, ay + 2, ax, ay - 1, arrow_col, 1.3)
            line(ax, ay - 1, ax + 3, ay + 2, arrow_col, 1.3)
        else
            line(ax - 3, ay - 1, ax, ay + 2, arrow_col, 1.3)
            line(ax, ay + 2, ax + 3, ay - 1, arrow_col, 1.3)
        end
    end
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
        apply_list_wheel_scroll(id, n, M.LIST_MAX_VISIBLE, bx, list_y, bw, list_h)
        off = list_scroll_for(id, n, M.LIST_MAX_VISIBLE)
        M.rect(bx, by + bh, bw, list_h, theme.OVERLAY, true, theme.CORNER_SMALL)
        M.rect(bx, by + bh, bw, list_h, theme.BORDER_SOFT, false, theme.CORNER_SMALL)
        for row = 0, vis - 1 do
            local i = off + row + 1
            local opt = options[i]
            if not opt then break end
            local iy = by + bh + row * 18
            local option_hovered = input.hover(bx, iy, bw, 18)
            if option_hovered then
                M.rect(bx + 2, iy + 1, bw - 4, 16, theme.HOVER, true, theme.CORNER_SMALL)
                local tip = tooltips.for_option(id, i, opt)
                M.register_tooltip_hover(tostring(id) .. ":option:" .. tostring(i), tip, bx, iy, bw, 18)
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
        apply_list_wheel_scroll(id, n, M.LIST_MAX_VISIBLE, bx, list_y, bw, list_h)
        off = list_scroll_for(id, n, M.LIST_MAX_VISIBLE)
        M.rect(bx, by + bh, bw, list_h, theme.OVERLAY, true, theme.CORNER_SMALL)
        M.rect(bx, by + bh, bw, list_h, theme.BORDER_SOFT, false, theme.CORNER_SMALL)
        for row = 0, vis - 1 do
            local i = off + row + 1
            local opt = options[i]
            if not opt then break end
            local iy = by + bh + row * 18
            local on = vals[i] == true
            local option_hovered = input.hover(bx, iy, bw, 18)
            if option_hovered then
                M.rect(bx + 2, iy + 1, bw - 4, 16, theme.HOVER, true, theme.CORNER_SMALL)
                local tip = tooltips.for_option(id, i, opt)
                M.register_tooltip_hover(tostring(id) .. ":option:" .. tostring(i), tip, bx, iy, bw, 18)
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
    M.rect(x, y, w, h,
        anim.interactive_fill("button:" .. tostring(id), theme.BUTTON, hovered, pressed),
        true, theme.CORNER)
    M.rect(x, y, w, h, hovered and theme.FOCUS or theme.BORDER_SOFT, false, theme.CORNER)
    local shown = fit_text(label, w - 16, theme.FONT_SMALL)
    local tw = text_w(shown, theme.FONT_SMALL)
    M.text(x + (w - tw) * 0.5, y + 6, shown, theme.TEXT_ACTIVE, theme.FONT_SMALL)
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
    M.rect(x + 8, y + 9, w - 16, 1, { 0.82, 0.84, 0.90, 0.07 }, true)
    return h
end
function M.keybind(x, y, w, id, label, default_on, opts)
    opts = opts or {}
    if id and not state.is_visible(id) then return 0 end
    state.define(id, default_on == true)
    local mode_id = id .. "_mode"
    local hide_id = id .. "_hide_kb"
    state.define(mode_id, 0)
    state.define(hide_id, false)
    local h = theme.ROW_H
    if not in_clip(y, h) then return h end
    local chip_w = 56
    local cw = w - chip_w - 6
    local used = M.checkbox(x, y, cw, id, label, {
        default = default_on,
        hide_color = opts.hide_color,
    })
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
        end_key_listen()
        open_bind_mode_popup(id, kx, ky, chip_w)
    elseif ui_clicked(kx, ky, chip_w, 16) then
        mark_interacted()
        M.open_bind_mode = nil
        M._bind_mode_hit = nil
        if listening then
            end_key_listen()
        else
            begin_key_listen(id)
        end
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
        end_key_listen()
        open_bind_mode_popup(key_id, kx, ky, chip_w)
    elseif ui_clicked(kx, ky, chip_w, 16) then
        mark_interacted()
        M.open_bind_mode = nil
        M._bind_mode_hit = nil
        if listening then
            end_key_listen()
        else
            begin_key_listen(key_id)
        end
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
        if listening then
            end_key_listen()
        else
            begin_key_listen(id)
        end
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
    local hx, hy, hw, hh = sx + sq + 8, sy, 14, sq
    for i = 0, 23 do
        local t = i / 23
        local r, g, b = hsv_to_rgb(t, 1, 1)
        M.rect(hx, hy + i * (hh / 24), hw, hh / 24 + 0.5, { r, g, b, 1 }, true)
    end
    M.rect(hx, hy, hw, hh, theme.BORDER, false, theme.CORNER_SMALL)
    local ax, ay, aw, ah = sx, sy + sq + 8, sq + 22, 10
    M.rect(ax, ay, aw, ah, { 0.15, 0.15, 0.15, 1 }, true)
    M.rect(ax, ay, aw * clamp(alpha, 0, 1), ah, { col[1], col[2], col[3], 1 }, true)
    M.rect(ax, ay, aw, ah, theme.BORDER, false, theme.CORNER_SMALL)
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
    local h = 0
    if t == "checkbox" then
        h = M.checkbox(x, y, w, item.id, item.label, item)
    elseif t == "keybind" then
        h = M.keybind(x, y, w, item.id, item.label, item.default, item)
    elseif t == "aim_key" then
        h = M.aim_key_row(x, y, w, item.id, item.mode_id, item.label)
    elseif t == "hotkey" then
        h = M.hotkey_row(x, y, w, item.id, item.label, item.default)
    elseif t == "slider" then
        h = M.slider(x, y, w, item.id, item.label, item.min, item.max, item.default, item)
    elseif t == "combo" then
        h = M.combo(x, y, w, item.id, item.label, item.options, item.default)
    elseif t == "multi" then
        h = M.multi(x, y, w, item.id, item.label, item.options, item.defaults, item)
    elseif t == "button" then
        h = M.button(x + 4, y, w - 8, item.id, item.label)
    elseif t == "label" then
        h = M.label(x, y, w, item.label, item.dim)
    elseif t == "separator" then
        h = M.separator(x, y, w)
    elseif t == "color" then
        h = M.color_row(x, y, w, item.id, item.label, item.default)
    elseif t == "input" then
        h = M.input_row(x, y, w, item.id, item.label, item.default)
    end
    local tip = tooltips.for_item(item)
    if tip and item.id and h > 0 then
        M.register_tooltip_hover(item.id, tip, x, y, w, h)
    end
    return h
end
return M
end)()

April._mods["ui.catalog"] = (function()
local maps = April.require("game.esp_maps")
local combat_menu = April.require("ui.combat_labels")
local gpu_chams = April.require("core.gpu_chams")
local M = {}
local function cb(id, label, default, color, gate, extra)
local item = { type = "checkbox", id = id, label = label, default = default == true, color = color, gate = gate }
if type(extra) == "table" then
for k, v in pairs(extra) do item[k] = v end
end
return item
end
local function kb(id, label, default, gate, extra)
local item = { type = "keybind", id = id, label = label, default = default == true, gate = gate }
if type(extra) == "table" then
for k, v in pairs(extra) do item[k] = v end
end
return item
end
local function sl(id, label, minv, maxv, default, float, gate, extra)
local item = {
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
if type(extra) == "table" then
for k, v in pairs(extra) do
item[k] = v
end
end
return item
end
local function combo(id, label, options, default, gate, extra)
local item = { type = "combo", id = id, label = label, options = options, default = default or 0, gate = gate }
if type(extra) == "table" then
for k, v in pairs(extra) do
item[k] = v
end
end
return item
end
local function multi(id, label, options, defaults, gate, extra)
local item = { type = "multi", id = id, label = label, options = options, defaults = defaults, gate = gate }
if type(extra) == "table" then
for k, v in pairs(extra) do item[k] = v end
end
return item
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
local function color(id, label_text, default, gate, override_idx)
return {
type = "color",
id = id,
label = label_text,
default = default,
gate = gate,
color_override_idx = override_idx,
}
end
local function input(id, label_text, default, gate)
return { type = "input", id = id, label = label_text, default = default or "", gate = gate }
end
local function ak(key_id, label, gate)
return { type = "aim_key", id = key_id, mode_id = key_id .. "_mode", label = label, gate = gate }
end
local function hk(id, label, gate, default_vk)
return { type = "hotkey", id = id, label = label, gate = gate, default = default_vk or 0x2D }
end
local function from_toggles(list, gate)
local out = {}
for _, t in ipairs(list) do
out[#out + 1] = cb(t.id, t.label, false, t.color, gate)
if t.ring_id then
out[#out + 1] = cb(t.ring_id, t.label .. " Range Ring", false, nil, gate)
end
end
return out
end
local function append(dst, src)
for _, v in ipairs(src) do
dst[#dst + 1] = v
end
end
local function toggle_labels(list)
local labels = {}
for i, t in ipairs(list) do
labels[i] = t.label
end
return labels
end
local function mesh_chams_block(prefix, toggle_list, master)
local chams_id = prefix .. "_chams"
local mode_id = prefix .. "_chams_mode"
local color_id = prefix .. "_chams_color"
return {
sep(master),
label("Mesh Chams (GPU)", false, master),
multi(chams_id, "Cham Types", toggle_labels(toggle_list), {}, master),
combo(mode_id, "Chams Mode", gpu_chams.MODE_LABELS, 0, master),
combo(color_id, "Glow Preset", gpu_chams.COLOR_LABELS, 0, master, {
gate_any_combo = {
{ mode_id, { 2, 3 } },
},
}),
}
end
M.TABS = {
{ id = "aim", icon = "aim", title = "Aimbot", label = "Aim" },
{ id = "visuals", icon = "visuals", title = "Visuals", label = "Visuals" },
{ id = "world", icon = "world", title = "World", label = "World" },
{ id = "guns", icon = "guns", title = "Gun Mods", label = "Guns" },
{ id = "misc", icon = "misc", title = "Misc", label = "Misc" },
{ id = "radar", icon = "radar", title = "Radar", label = "Radar" },
{ id = "config", icon = "config", title = "Config", label = "Config" },
}
local function build_aim()
local regular = {
title = "Aimbot",
master = "april_aimbot",
items = {
cb("april_aimbot", "Enable Aimbot", false, nil, nil, { hide_color = true }),
ak("april_aim_key", "Aim Key"),
sep(),
combo("april_aim_target_type", "Target Type", { "Crosshair", "Distance" }, 0),
combo("april_aim_bone", "Hitbox", combat_menu.SILENT_BONES, 0),
multi("april_aim_targets", "Aim At", combat_menu.AIM_AT_OPTIONS, combat_menu.AIM_AT_DEFAULTS),
multi("april_aim_filters", "Filters", {
"Health Check", "Visible Only", "Team Check",
"Skip Safezone", "Whitelist", "Skip Downed",
}, { true, false, true, true, false, true }),
input("april_aim_whitelist_ids", "Whitelist IDs", ""),
btn("april_aim_whitelist_clear", "Clear Whitelist"),
sl("april_aim_max_dist", "Max Distance (m)", 50, 2000, 500),
sep(),
multi("april_aim_options", "Options", { "Sticky Target" }, { false }),
cb("april_aim_auto_pred", "Auto Prediction", true),
sl("april_aim_smooth", "Smoothness", 1, 25, 10),
combo("april_aim_smooth_type", "Smooth Type", {
"Linear", "Ease Out", "Ease In-Out", "Exponential", "Adaptive",
}, 0),
cb("april_aim_humanize", "Humanize", false),
sl("april_aim_humanize_str", "Humanize Strength", 1, 100, 35, false, "april_aim_humanize"),
sl("april_aim_fov", "FOV Radius (px)", 5, 600, 120),
sep(),
cb("april_aim_draw_fov", "FOV Circle", false, { 0.2, 1, 0.45, 1 }),
combo("april_aim_fov_style", "FOV Style", { "Outline", "Filled Circle" }, 1, "april_aim_draw_fov"),
cb("april_aim_target_line", "Target Line", false, { 0.2, 1, 0.45, 1 }),
},
}
local silent = {
title = "Silent Aim",
master = "april_silent_aim",
items = {
kb("april_silent_aim", "Enable Silent Aim", false, nil, { hide_color = true }),
sep(),
combo("april_silent_target_type", "Target Type", { "Crosshair", "Distance" }, 0),
combo("april_silent_bone", "Hitbox", combat_menu.SILENT_BONES, 0),
multi("april_silent_targets", "Aim At", combat_menu.AIM_AT_OPTIONS, combat_menu.AIM_AT_DEFAULTS),
multi("april_silent_filters", "Filters", {
"Health Check", "Visible Only", "Team Check",
"Skip Safezone", "Whitelist", "Skip Downed",
}, { true, false, true, true, false, true }),
input("april_silent_whitelist_ids", "Whitelist IDs", ""),
btn("april_silent_whitelist_clear", "Clear Whitelist"),
sl("april_silent_max_dist", "Max Distance (m)", 50, 2000, 500),
sep(),
multi("april_silent_options", "Options", { "Sticky Target" }, { false }),
sl("april_silent_hit_chance", "Hit Chance %", 1, 100, 100),
sl("april_silent_fov", "FOV Radius (px)", 5, 600, 150),
sep(),
cb("april_silent_draw_fov", "FOV Circle", false, { 0.55, 0.2, 1, 1 }),
combo("april_silent_fov_style", "FOV Style", { "Outline", "Filled Circle" }, 1, "april_silent_draw_fov"),
cb("april_silent_target_line", "Snapline", false, { 1, 0.25, 0.25, 1 }),
},
}
local bullet = {
title = "Bullet",
master = "april_bullet_enabled",
items = {
kb("april_bullet_enabled", "Enable Bullet", false),
sep(),
cb("april_silent_hitscan", "Hitscan", false),
sep(),
cb("april_silent_bullet_tp", "Bullet TP", false),
sep("april_silent_bullet_tp"),
cb("april_silent_bullet_manip", "Silent Bullet Manip", false),
sl("april_silent_manip_dist", "Manip Distance", 0.1, 1, 1, true, "april_silent_bullet_manip"),
cb("april_silent_manip_extend", "Extend", false, nil, "april_silent_bullet_manip"),
sl("april_silent_manip_extend_dist", "Extend Distance", 1, 7, 7, true, "april_silent_manip_extend"),
cb("april_bullet_body_peek", "Body Peek (desync)", false, nil, "april_silent_bullet_manip"),
sep("april_bullet_enabled"),
cb("april_thick_bullet", "Hitbox Override", false),
combo("april_thick_bullet_part", "Override Part", {
"Head", "Torso", "HumanoidRootPart", "Left Arm", "Right Arm", "Left Leg", "Right Leg",
}, 0, "april_thick_bullet"),
sl("april_thick_bullet_mult", "Override Size", 1, 4, 2, true, "april_thick_bullet"),
sep("april_bullet_enabled"),
cb("april_silent_manip_status", "Status HUD", false, nil, "april_bullet_enabled"),
cb("april_silent_manip_peek_vis", "Peek Visual", false, nil, "april_bullet_enabled"),
},
}
return { regular, silent, bullet }
end
local function build_visuals()
local left = {
title = "Player ESP",
master = "april_player_enabled",
items = {
kb("april_player_enabled", "Player ESP", false, nil, { hide_color = true }),
combo("april_player_box_mode", "Player Box", { "None", "2D", "Corner" }, 1),
multi("april_ui_player_elements", "Displayed Elements", {
"Health Bar", "Skeleton", "Name", "Clan Tag", "Held Item", "Distance",
}, { true, false, true, true, false, true }, nil, {
sync_ids = {
"april_player_health", "april_player_skeleton", "april_player_show_name",
"april_player_clan_tag", "april_player_show_held", "april_player_show_distance",
},
}),
multi("april_player_esp_filters", "ESP Filters", {
"Team Check", "Skip Safezone", "Skip Downed",
}, { true, false, false }),
multi("april_player_esp_flags", "ESP Flags", {
"Downed", "Safezone", "Staff", "Reviving", "Movement", "VIP", "Cheater",
}, { true, true, true, true, false, true, true }),
sl("april_player_range", "Player Range", 50, 2000, 500),
},
}
local gear = {
title = "Target Gear",
master = "april_target_overlay",
items = {
kb("april_target_overlay", "Target Gear Overlay", false),
sl("april_target_overlay_fov", "Gear FOV", 5, 500, 100, false, "april_target_overlay"),
sl("april_target_overlay_max_dist", "Max Distance", 50, 2000, 500, false, "april_target_overlay"),
sl("april_target_overlay_gear_size", "Gear Icon Size", 32, 64, 48, false, "april_target_overlay"),
sl("april_target_overlay_top", "Top Offset", 48, 160, 88, false, "april_target_overlay"),
},
}
local target_vis = {
title = "Crosshair",
items = {
cb("april_crosshair_enabled", "Custom Crosshair", false),
combo("april_crosshair_type", "Style", {
"Cross", "Circle", "Dot", "T-Shape", "Diamond", "Plus", "Brackets", "X",
}, 0, "april_crosshair_enabled"),
cb("april_crosshair_follow", "Follow Target", false, nil, "april_crosshair_enabled"),
combo("april_crosshair_source", "Target From", { "Auto", "Silent Aim", "Aimbot" }, 0, "april_crosshair_follow"),
sl("april_crosshair_follow_smooth", "Follow Smoothness", 4, 40, 18, false, "april_crosshair_follow"),
multi("april_ui_crosshair_motion", "Motion", { "Spin", "Pulse Size" }, { false, false }, "april_crosshair_enabled", {
sync_ids = { "april_crosshair_spin", "april_crosshair_pulse" },
}),
sl("april_crosshair_spin_speed", "Spin Speed", 1, 100, 35, false, "april_crosshair_spin"),
sl("april_crosshair_pulse_speed", "Pulse Speed", 1, 100, 40, false, "april_crosshair_pulse"),
multi("april_ui_crosshair_options", "Options", {
"Center Dot", "Outline", "Rainbow",
}, { false, true, false }, "april_crosshair_enabled", {
sync_ids = {
"april_crosshair_dot", "april_crosshair_outline", "april_crosshair_rainbow",
},
}),
color("april_crosshair_color", "Crosshair Color", { 0, 1, 0, 1 }, "april_crosshair_enabled"),
color("april_crosshair_dot", "Center Dot Color", { 1, 1, 1, 1 }, "april_crosshair_dot"),
sl("april_crosshair_rainbow_speed", "Rainbow Speed", 1, 100, 10, false, "april_crosshair_rainbow"),
sl("april_crosshair_size", "Size", 1, 50, 10, false, "april_crosshair_enabled"),
sl("april_crosshair_gap", "Gap", 0, 20, 5, false, "april_crosshair_enabled"),
sl("april_crosshair_thickness", "Thickness", 1, 10, 2, false, "april_crosshair_enabled"),
},
}
local colors = {
title = "Player Colors",
master = "april_player_enabled",
items = {
color("april_player_box_color", "Box", { 1, 0.35, 0.35, 1 }),
color("april_player_skeleton", "Skeleton", { 1, 1, 1, 0.92 }),
color("april_player_show_name", "Name", { 1, 0.35, 0.35, 1 }),
color("april_player_clan_tag", "Clan Tag", { 0.84, 0.31, 0.80, 1 }),
color("april_player_show_held", "Held Item", { 0.95, 0.9, 0.55, 0.95 }),
color("april_player_show_distance", "Distance", { 0.82, 0.84, 0.88, 0.92 }),
sep(),
color("april_player_flag_downed", "Downed", { 1, 0.35, 0.35, 1 }),
color("april_player_flag_safezone", "Safezone", { 0.35, 0.85, 1, 1 }),
color("april_player_flag_staff", "Staff", { 1, 0.33, 0.33, 1 }),
color("april_player_flag_reviving", "Reviving", { 0.45, 1, 0.55, 1 }),
color("april_player_flag_movement", "Movement", { 0.75, 0.85, 1, 1 }),
color("april_player_flag_vip", "VIP", { 1, 0.82, 0.2, 1 }),
color("april_player_flag_cheater", "Cheater", { 1, 0.05, 0.05, 1 }),
},
}
return { left, gear, target_vis, colors }
end
local function build_world()
local resources = {
title = "Resources",
master = "april_world_enabled",
items = {
kb("april_world_enabled", "Resource ESP", false),
},
}
append(resources.items, from_toggles(maps.WORLD_TOGGLES))
append(resources.items, {
cb("april_world_boxes", "Resource 3D Boxes", false),
cb("april_world_show_name", "Resource Show Name", true),
cb("april_world_show_distance", "Resource Show Distance", true),
sl("april_world_range", "Resource Range", 50, 2000, 500),
})
append(resources.items, mesh_chams_block("april_world", maps.WORLD_TOGGLES, "april_world_enabled"))
local loot = {
title = "Loot",
master = "april_loot_enabled",
items = {
kb("april_loot_enabled", "Loot ESP", false),
},
}
append(loot.items, from_toggles(maps.LOOT_TOGGLES))
append(loot.items, {
cb("april_loot_boxes", "Loot 3D Boxes", false),
cb("april_loot_show_name", "Loot Show Name", true),
cb("april_loot_show_distance", "Loot Show Distance", true),
sl("april_loot_range", "Loot Range", 50, 2000, 300),
})
append(loot.items, mesh_chams_block("april_loot", maps.LOOT_TOGGLES, "april_loot_enabled"))
local bases = {
title = "Bases",
master = "april_base_enabled",
items = {
kb("april_base_enabled", "Base ESP", false),
},
}
append(bases.items, from_toggles(maps.BASE_TOGGLES))
append(bases.items, {
cb("april_base_boxes", "Base 3D Boxes", false),
cb("april_base_show_name", "Base Show Name", true),
cb("april_base_show_distance", "Base Show Distance", false),
sl("april_base_range", "Base Range", 50, 500, 150),
})
append(bases.items, mesh_chams_block("april_base", maps.BASE_TOGGLES, "april_base_enabled"))
local base_xray = {
title = "Base Xray",
master = "april_base_xray_enabled",
items = {
kb("april_base_xray_enabled", "Base Xray", false),
sl("april_base_xray_range", "Xray Range", 40, 500, 180),
},
}
local npcs = {
title = "NPCs",
master = "april_npc_enabled",
items = {
kb("april_npc_enabled", "NPC ESP", false, nil, { hide_color = true }),
multi("april_ui_npc_types", "NPC Types", {
"Soldier", "Bruno", "Boris", "Brutus", "Attack Heli", "BTR", "Diver Dave", "Pilot Pete",
}, { false, false, false, false, false, false, false, false }, nil, {
sync_ids = {
"april_npc_soldier", "april_npc_bruno", "april_npc_boris", "april_npc_brutus",
"april_npc_attack_heli", "april_npc_btr", "april_npc_diver_dave", "april_npc_pilot_pete",
},
}),
combo("april_npc_box_mode", "NPC Box", { "None", "2D", "Corner" }, 1),
multi("april_ui_npc_elements", "Displayed Elements", {
"Health Bar", "Name", "Distance",
}, { true, true, true }, nil, {
sync_ids = {
"april_npc_health", "april_npc_show_name", "april_npc_show_distance",
},
}),
sl("april_npc_range", "NPC Range", 50, 2000, 500),
},
}
local npc_colors = {
title = "NPC Colors",
master = "april_npc_enabled",
items = {
color("april_npc_soldier", "Soldier", { 1, 0.3, 0.3, 1 }),
color("april_npc_bruno", "Bruno", { 1, 0.65, 0.2, 1 }),
color("april_npc_boris", "Boris", { 0.78, 0.42, 1, 1 }),
color("april_npc_brutus", "Brutus", { 1, 0.3, 0.48, 1 }),
color("april_npc_attack_heli", "Attack Heli", { 0.85, 0.2, 0.25, 1 }),
color("april_npc_btr", "BTR", { 0.95, 0.25, 0.15, 1 }),
color("april_npc_diver_dave", "Diver Dave", { 0.2, 0.75, 1, 1 }),
color("april_npc_pilot_pete", "Pilot Pete", { 0.35, 1, 0.65, 1 }),
color("april_npc_show_name", "Name", { 1, 0.3, 0.3, 1 }),
color("april_npc_show_distance", "Distance", { 0.82, 0.84, 0.88, 0.92 }),
},
}
local raids = {
title = "Raids",
master = "april_raid_enabled",
items = {
kb("april_raid_enabled", "Raid ESP", false, nil, { color = { 1, 0.5, 0, 1 } }),
cb("april_raid_notifications", "Raid Notifications", true),
sl("april_raid_range", "Raid ESP Range", 50, 5000, 1000),
},
}
return { resources, loot, npcs, npc_colors, raids, bases, base_xray }
end
local function build_guns()
return {
{
title = "Gun Mods",
master = "april_gunmods_enabled",
items = {
kb("april_gunmods_enabled", "Enable Gun Mods", false),
sep(),
cb("april_gm_recoil", "No Recoil", false),
sl("april_gm_recoil_pct", "Recoil Reduction %", 0, 100, 100, false, "april_gm_recoil"),
sep(),
cb("april_gm_spread", "No Spread", false),
sl("april_gm_spread_pct", "Spread Reduction %", 0, 100, 100, false, "april_gm_spread"),
sep(),
cb("april_gm_sway", "No Sway", false),
sep(),
cb("april_gm_fire_rate", "Fire Rate", false),
sl("april_gm_fire_rate_mult", "Fire Rate Multiplier", 1, 3, 1.5, true, "april_gm_fire_rate"),
sep(),
cb("april_gm_speed", "Bullet Speed", false),
sl("april_gm_speed_mult", "Speed Mult", 1, 100, 100, false, "april_gm_speed"),
sep(),
cb("april_gm_range", "Gun Range", false),
sl("april_gm_range_mult", "Range Mult", 1, 20, 10, false, "april_gm_range"),
sep(),
cb("april_gm_double_tap", "Double Tap", false),
},
},
}
end
local function build_misc()
return {
{
title = "Movement",
items = {
kb("april_fly_enabled", "Fly", false),
sl("april_fly_speed", "Fly Speed", 1, 20, 5, false, "april_fly_enabled"),
cb("april_fly_noclip", "Fly Noclip", true, nil, "april_fly_enabled"),
sep(),
kb("april_spider_enabled", "Spider", false),
sl("april_spider_speed", "Spider Speed", 18, 30, 18, false, "april_spider_enabled"),
sep(),
kb("april_bhop_enabled", "Bunny Hop", false),
sep(),
kb("april_desync_enabled", "Desync", false),
cb("april_desync_visualizer", "Desync Visualize", false, { 0.2, 0.85, 1, 0.9 }, "april_desync_enabled"),
sep(),
kb("april_antiaim_enabled", "Anti-Aim", false),
combo("april_antiaim_yaw_mode", "Yaw Mode", { "None", "Backwards", "Spin", "Jitter", "Random Jitter", "Sideways Left", "Sideways Right", "Manual" }, 1, "april_antiaim_enabled"),
sl("april_antiaim_yaw_manual", "Manual Yaw", -180, 180, 90, false, "april_antiaim_enabled", {
gate_combo = "april_antiaim_yaw_mode",
gate_combo_value = 7,
}),
sl("april_antiaim_spin_speed", "Spin Speed", 30, 720, 180, false, "april_antiaim_enabled", {
gate_combo = "april_antiaim_yaw_mode",
gate_combo_value = 2,
}),
sl("april_antiaim_jitter_step", "Jitter Step", 15, 180, 90, false, "april_antiaim_enabled", {
gate_any_combo = {
{ "april_antiaim_yaw_mode", { 3, 4 } },
},
}),
sl("april_antiaim_jitter_ms", "Jitter Interval (ms)", 40, 500, 120, false, "april_antiaim_enabled", {
gate_any_combo = {
{ "april_antiaim_yaw_mode", { 3, 4 } },
},
}),
kb("april_fakeduck_enabled", "Fake Duck", false),
sl("april_fakeduck_height", "Duck Height", 0.01, 1.5, 1.1, true, "april_fakeduck_enabled"),
cb("april_fakeduck_spam", "Spam Height", false, nil, "april_fakeduck_enabled"),
combo("april_fakeduck_spam_mode", "Spam Mode", { "Alternating", "Random" }, 0, "april_fakeduck_spam"),
sl("april_fakeduck_spam_min", "Spam Min", 0.01, 1.5, 0.01, true, "april_fakeduck_spam"),
sl("april_fakeduck_spam_max", "Spam Max", 0.01, 1.5, 1.5, true, "april_fakeduck_spam"),
sl("april_fakeduck_spam_ms", "Spam Interval (ms)", 20, 400, 80, false, "april_fakeduck_spam"),
sep(),
kb("april_fling_enabled", "Fling", false),
sl("april_fling_fov", "Fling FOV", 5, 600, 150, false, "april_fling_enabled"),
sl("april_fling_duration", "Fling Duration", 2, 10, 2, false, "april_fling_enabled"),
},
},
{
title = "Utility",
items = {
kb("april_autofarm", "Autofarm", false),
multi("april_autofarm_resources", "Farm Resources", {
"Trees", "Stone", "Metal", "Phosphate",
}, { true, true, true, true }, "april_autofarm"),
sl("april_autofarm_search_range", "Search Range", 50, 2000, 500, false, "april_autofarm"),
cb("april_autofarm_debug_path", "Debug Target Path", false, nil, "april_autofarm"),
sep(),
kb("april_farm_helper", "Manual Farm Helper", false),
sl("april_farm_radius", "Farm Range (studs)", 1, 10, 7, false, "april_farm_helper"),
sep(),
cb("april_anti_afk", "Anti AFK", false),
kb("april_antifling_enabled", "Anti Fling", false),
label("HUD panels are managed from the top dock."),
},
},
}
end
local function build_radar()
return {
{
title = "Tactical Map",
master = "april_map_enabled",
items = {
kb("april_map_enabled", "Tactical Map", false),
multi("april_ui_radar_layers", "Visible Layers", {
"Players", "NPCs", "Loot", "Resources", "Base Parts", "Waypoints", "Raids", "Labels",
}, { true, false, true, true, false, true, false, false }, nil, {
sync_ids = {
"april_map_show_players", "april_map_show_npcs", "april_map_show_loot",
"april_map_show_world", "april_map_show_base", "april_map_show_waypoints",
"april_map_show_raids", "april_map_labels",
},
}),
color("april_map_player_col", "Radar Players Color", { 1, 0.25, 0.25, 1 }),
color("april_map_npc_col", "Radar NPCs Color", { 1, 0.55, 0.15, 1 }),
color("april_map_loot_col", "Radar Loot Color", { 1, 0.85, 0.35, 1 }),
color("april_map_world_col", "Radar Resources Color", { 0.35, 0.9, 0.35, 1 }),
color("april_map_base_col", "Radar Base Color", { 0.55, 0.55, 1, 1 }),
color("april_map_wp_col", "Radar Waypoints Color", { 0.3, 0.9, 1, 1 }),
color("april_map_raid_col", "Radar Raids Color", { 1, 0.5, 0, 1 }),
sl("april_map_zoom", "Radar Zoom Level", 0.05, 5, 1, true),
sl("april_map_size", "Radar Size", 140, 420, 250),
sl("april_map_opacity", "Radar Opacity", 15, 100, 100),
sl("april_map_icon_scale", "Radar Blip Size", 2, 6, 3),
btn("april_map_reset_position", "Reset Radar Position"),
},
},
{
title = "Waypoints",
master = "april_waypoints_enabled",
items = {
kb("april_waypoints_enabled", "Waypoints", false),
cb("april_wp_dist", "Waypoint Show Distance", false),
cb("april_wp_beacon", "Beacon Pillar", false),
sl("april_wp_beacon_h", "Beacon Height", 20, 200, 90, false, "april_wp_beacon"),
cb("april_wp_draw", "Draw Markers", false, { 0.2, 1, 0.8, 1 }),
sl("april_wp_slot", "Waypoint Active Slot", 1, 5, 1),
btn("april_wp_set", "Set Active Waypoint"),
btn("april_wp_clear", "Clear Active Waypoint"),
btn("april_wp_clear_all", "Clear All Waypoints"),
},
},
}
end
local function build_config()
local modes = { "Static", "Rainbow", "Pulse", "Wave", "Flow" }
local elem_modes = { "Default", "Static", "Rainbow", "Pulse", "Wave", "Flow" }
local COL = "april_ui_custom_colors"
local ANM = "april_ui_custom_anim"
local ELS = "april_ui_per_element"
local OVL = "april_ui_menu_overlay"
local SNOW = "april_ui_snow"
local appearance = {
title = "Appearance",
items = {
label("Look", true),
hk("april_ui_menu_key", "Menu Toggle Key"),
combo("april_ui_theme_preset", "Theme Preset", {
"Violet Glass", "Midnight Blue", "Graphite", "Emerald Glass",
}, 0),
sep(),
sl("april_ui_window_opacity", "Window Opacity %", 45, 100, 86),
sl("april_ui_panel_opacity", "Panel Opacity %", 35, 100, 72),
sl("april_ui_border_strength", "Border Strength %", 10, 100, 58),
combo("april_ui_corner_style", "Corners", { "Sharp", "Soft", "Rounded" }, 2),
sl("april_ui_scale", "UI Scale %", 80, 125, 100),
combo("april_ui_density", "Density", { "Compact", "Balanced", "Comfortable" }, 1),
cb("april_ui_show_cursor_dot", "Cursor Dot", true),
sep(),
label("Backdrop", true),
cb("april_ui_menu_overlay", "Menu Overlay", true),
sl("april_ui_overlay_strength", "Overlay Strength", 5, 100, 70, false, OVL),
sep(),
label("Snow", true),
cb("april_ui_snow", "Enable Snow", false),
sl("april_ui_snow_amount", "Amount", 10, 140, 50, false, SNOW),
sl("april_ui_snow_speed", "Speed", 1, 100, 40, false, SNOW),
sl("april_ui_snow_size", "Size", 1, 8, 3, false, SNOW),
sl("april_ui_snow_opacity", "Opacity", 10, 100, 55, false, SNOW),
},
}
local motion = {
title = "Motion",
items = {
label("Basics", true),
cb("april_ui_startup_intro", "Startup Animation", true),
combo("april_ui_motion_profile", "Motion Profile", {
"Subtle", "Balanced", "Expressive",
}, 1),
cb("april_ui_reduce_motion", "Reduce Motion", false),
sep(),
label("Advanced", true),
cb("april_ui_custom_anim", "Advanced Animation", false),
combo("april_ui_accent_anim", "Accent Style", modes, 1, ANM),
sl("april_ui_anim_speed", "Accent Speed", 1, 100, 40, false, ANM),
cb("april_ui_menu_fade", "Ambient Fade Pulse", false, nil, ANM),
multi("april_ui_anim_targets", "Animate", {
"Title Bar", "Section Tops", "Sliders", "Scrollbars", "Navbar", "Switches", "Hover", "Overlay Panels",
}, { true, true, true, true, true, true, true, true }, ANM),
cb("april_ui_per_element", "Per-Element Styles", false, nil, ANM),
sep(ANM),
{ type = "combo", id = "april_ui_style_title", label = "Title Bar", options = elem_modes, default = 0, gate = ANM, gate2 = ELS },
{ type = "combo", id = "april_ui_style_section", label = "Section Tops", options = elem_modes, default = 0, gate = ANM, gate2 = ELS },
{ type = "combo", id = "april_ui_style_slider", label = "Sliders", options = elem_modes, default = 0, gate = ANM, gate2 = ELS },
{ type = "combo", id = "april_ui_style_scroll", label = "Scrollbars", options = elem_modes, default = 0, gate = ANM, gate2 = ELS },
{ type = "combo", id = "april_ui_style_sidebar", label = "Navbar", options = elem_modes, default = 0, gate = ANM, gate2 = ELS },
{ type = "combo", id = "april_ui_style_checkbox", label = "Switches", options = elem_modes, default = 0, gate = ANM, gate2 = ELS },
{ type = "combo", id = "april_ui_style_overlay", label = "Overlay Panels", options = elem_modes, default = 0, gate = ANM, gate2 = ELS },
},
}
local accent = {
title = "Accent Colors",
items = {
label("Accent", true),
cb("april_ui_custom_colors", "Custom Colors", false),
color("april_ui_accent", "Main Accent", { 0.78, 0.20, 0.92, 1 }, COL),
sep(COL),
label("Overrides", true, COL),
multi("april_ui_color_overrides", "Override For", {
"Title Bar", "Section Tops", "Sliders", "Scrollbars", "Navbar", "Switches", "Overlay Panels",
}, {}, COL),
color("april_ui_col_title", "Title Bar", { 0.78, 0.20, 0.92, 1 }, COL, 1),
color("april_ui_col_section", "Section Tops", { 0.78, 0.20, 0.92, 1 }, COL, 2),
color("april_ui_col_slider", "Sliders", { 0.78, 0.20, 0.92, 1 }, COL, 3),
color("april_ui_col_scroll", "Scrollbars", { 0.78, 0.20, 0.92, 1 }, COL, 4),
color("april_ui_col_sidebar", "Navbar", { 0.78, 0.20, 0.92, 1 }, COL, 5),
color("april_ui_col_checkbox", "Switches", { 0.78, 0.20, 0.92, 1 }, COL, 6),
color("april_ui_col_overlay", "Overlay Panels", { 0.78, 0.20, 0.92, 1 }, COL, 7),
},
}
local anime_baddie = {
title = "Anime Baddie",
master = "april_anime_baddie_enabled",
items = {
cb("april_anime_baddie_enabled", "Anime Baddie", false),
label("Also toggled from the top dock.", true),
combo("april_anime_baddie_character", "Character", { "April" }, 0,
"april_anime_baddie_enabled"),
combo("april_anime_baddie_personality", "Personality", {
"Mixed", "Roasty", "Supportive",
}, 0, "april_anime_baddie_enabled"),
multi("april_anime_baddie_events", "React To", {
"Death / Respawn", "Downed / Revived", "Low Health", "Safe Zone",
"Combat / Bleed", "Survival Needs", "Nearby Threats", "World Events",
}, { true, true, true, true, true, true, true, true }, "april_anime_baddie_enabled"),
sep("april_anime_baddie_enabled"),
sl("april_anime_baddie_scale", "Scale", 60, 150, 100, false,
"april_anime_baddie_enabled"),
sl("april_anime_baddie_opacity", "Opacity", 30, 100, 100, false,
"april_anime_baddie_enabled"),
sl("april_anime_baddie_duration", "Bubble Duration", 2, 10, 5, false,
"april_anime_baddie_enabled"),
sl("april_anime_baddie_cooldown", "Chatter Cooldown", 2, 30, 8, false,
"april_anime_baddie_enabled"),
cb("april_anime_baddie_stay", "Stay Visible", true, nil,
"april_anime_baddie_enabled"),
sep("april_anime_baddie_enabled"),
btn("april_anime_baddie_preview", "Preview Line", "april_anime_baddie_enabled"),
btn("april_anime_baddie_reset", "Reset Position", "april_anime_baddie_enabled"),
},
}
local config_group = {
title = "Config",
items = {
label("Profiles", true),
input("april_cfg_profile_name", "Profile Name", "Default"),
sl("april_cfg_slot", "Active Slot (1-5)", 1, 5, 1),
btn("april_cfg_save", "Save to Active Slot"),
btn("april_cfg_load", "Load Active Slot"),
btn("april_cfg_delete", "Delete Active Slot"),
sep(),
label("Autoload", true),
cb("april_cfg_autoload", "Autoload on Start", false),
input("april_cfg_autoload_profile", "Autoload Profile Name", "", "april_cfg_autoload"),
sl("april_cfg_autoload_slot", "Autoload Slot", 1, 5, 1, false, "april_cfg_autoload"),
sep(),
label("Extras", true),
sl("april_esp_text_size", "ESP Text Size", 8, 24, 13),
btn("april_reload_modules", "Reload Game Modules"),
},
}
return { appearance, motion, accent, anime_baddie, config_group }
end
function M.groups_for(tab_id)
if tab_id == "aim" then return build_aim() end
if tab_id == "visuals" then return build_visuals() end
if tab_id == "world" then return build_world() end
if tab_id == "guns" then return build_guns() end
if tab_id == "misc" then return build_misc() end
if tab_id == "radar" then return build_radar() end
if tab_id == "config" then return build_config() end
return {}
end
return M
end)()

April._mods["ui.hud_dock"] = (function()
local theme = April.require("ui.gs_theme")
local input = April.require("ui.gs_input")
local widgets = April.require("ui.gs_widgets")
local anim = April.require("ui.gs_anim")
local icons = April.require("ui.gs_icons")
local state = April.require("ui.gs_state")
local M = {}
local open_settings = false
local popup_rect = nil
local dock_rect = nil
local settings_opened_this_frame = false
local visible_settings = {}
local PANELS = {
    { id = "april_keybinds_enabled", icon = "keybinds", label = "Binds" },
    { id = "april_mod_checker_enabled", icon = "staff", label = "Staff" },
    { id = "april_event_status_enabled", icon = "events", label = "Events" },
    { id = "april_map_enabled", icon = "map", label = "Map" },
    { id = "april_anime_baddie_enabled", icon = "waifu", label = "April" },
}
local BIND_SETTINGS = {
    { type = "label", label = "KEYBINDS", dim = true },
    { type = "checkbox", id = "april_keybinds_active_only", label = "Only active binds", default = false },
    { type = "checkbox", id = "april_keybinds_show_unbound", label = "Show unbound", default = true },
    { type = "checkbox", id = "april_keybinds_show_mode", label = "Show bind mode", default = true },
}
local STAFF_SETTINGS = {
    { type = "label", label = "STAFF", dim = true },
    {
        type = "slider", id = "april_mod_checker_interval", label = "Scan interval",
        min = 1000, max = 10000, default = 2500,
    },
}
local MAP_SETTINGS = {
    { type = "label", label = "MAP", dim = true },
    { type = "button", id = "april_map_reset_position", label = "Reset map position" },
}
local EVENT_SETTINGS = {
    { type = "label", label = "EVENTS", dim = true },
    { type = "checkbox", id = "april_event_status_active_only", label = "Only active events", default = false },
}
local function build_visible_settings()
    local out = {}
    local function append_group(group)
        if #out > 0 then out[#out + 1] = { type = "separator" } end
        for _, item in ipairs(group) do out[#out + 1] = item end
    end
    local binds = state.get("april_keybinds_enabled", false) == true
    local staff = state.get("april_mod_checker_enabled", false) == true
    local events = state.get("april_event_status_enabled", false) == true
    local map = state.get("april_map_enabled", false) == true
    state.set_visible("april_keybinds_active_only", binds)
    state.set_visible("april_keybinds_show_unbound", binds)
    state.set_visible("april_keybinds_show_mode", binds)
    state.set_visible("april_mod_checker_interval", staff)
    state.set_visible("april_event_status_active_only", events)
    state.set_visible("april_map_reset_position", map)
    if binds then append_group(BIND_SETTINGS) end
    if staff then append_group(STAFF_SETTINGS) end
    if events then append_group(EVENT_SETTINGS) end
    if map then append_group(MAP_SETTINGS) end
    if #out == 0 then
        out[1] = {
            type = "label",
            label = "Enable Binds, Staff, Events, Map, or April above.",
            dim = true,
        }
    end
    return out
end
local function settings_height(items)
    local h = 44
    for i, item in ipairs(items) do
        h = h + widgets.estimate_height(item)
        if i < #items then h = h + theme.ITEM_GAP end
    end
    return h + 8
end
local function text_width(text, size)
    local fn = draw and (draw.get_text_size or draw.GetTextSize)
    if fn then
        local ok, w = pcall(fn, text, size)
        if ok and type(w) == "number" then return w end
    end
    return #tostring(text or "") * 7
end
function M.init()
    state.define("april_keybinds_enabled", false)
    state.define("april_mod_checker_enabled", false)
    state.define("april_event_status_enabled", false)
    state.define("april_event_status_active_only", false)
    state.define("april_map_enabled", false)
    state.define("april_anime_baddie_enabled", false)
end
function M.begin_frame()
    if open_settings and popup_rect
        and input.hover(popup_rect.x, popup_rect.y, popup_rect.w, popup_rect.h)
    then
        widgets.block_under = true
    end
end
function M.draw_floating(_default_x, _default_y, sw, _sh)
    settings_opened_this_frame = false
    local scale = theme.SCALE or 1
    local bar_h = math.max(42, math.floor(46 * scale))
    local item = math.max(32, math.floor(36 * scale))
    local gap = math.max(4, math.floor(5 * scale))
    local pad = math.max(6, math.floor(7 * scale))
    local count = #PANELS + 1
    local bar_w = pad * 2 + count * item + (count - 1) * gap
    local x = math.floor((sw - bar_w) * 0.5)
    local y = math.max(8, math.floor(10 * scale))
    dock_rect = { x = x, y = y, w = bar_w, h = bar_h }
    widgets.rect(x, y, bar_w, bar_h, theme.alpha(theme.NAV_BG, 0.97), true, theme.CORNER)
    widgets.rect(x, y, bar_w, bar_h, theme.BORDER, false, theme.CORNER)
    local cursor_x = x + pad
    local iy = y + math.floor((bar_h - item) * 0.5)
    for _, panel in ipairs(PANELS) do
        local active = state.get(panel.id, false) == true
        local hot = input.hover(cursor_x, iy, item, item)
        local active_t, hover_t = anim.dock_transition(panel.id, active, hot)
        local fill = anim.mix(theme.DOCK_BG, theme.DOCK_HOVER, hover_t)
        fill = anim.mix(fill, theme.DOCK_ACTIVE, active_t)
        if active or hot then
            widgets.rect(cursor_x, iy, item, item, fill, true, theme.CORNER_SMALL)
        end
        if active then
            widgets.rect(cursor_x + 7, iy + item - 3, item - 14, 2,
                theme.alpha(theme.ACCENT, 0.92), true, 1)
        end
        local col = active and theme.TEXT_ACTIVE or anim.mix(theme.TEXT_DIM, theme.TEXT, hover_t)
        icons.draw(panel.icon, cursor_x + item * 0.5, iy + item * 0.5, col)
        if input.clicked(cursor_x, iy, item, item) and not widgets.block_under then
            state.set(panel.id, not active)
            widgets.interacted = true
        end
        if hot then
            local label_w = text_width(panel.label, theme.FONT_CAPTION)
            local tx = cursor_x + (item - label_w) * 0.5
            widgets.rect(tx - 5, y + bar_h + 5, label_w + 10, 18,
                theme.OVERLAY, true, theme.CORNER_SMALL)
            widgets.text(tx, y + bar_h + 7, panel.label, theme.TEXT_ACTIVE, theme.FONT_CAPTION)
        end
        cursor_x = cursor_x + item + gap
    end
    local hot = input.hover(cursor_x, iy, item, item)
    local active_t, hover_t = anim.dock_transition("settings", open_settings, hot)
    local fill = anim.mix(theme.DOCK_BG, theme.DOCK_HOVER, hover_t)
    fill = anim.mix(fill, theme.DOCK_ACTIVE, active_t)
    if open_settings or hot then
        widgets.rect(cursor_x, iy, item, item, fill, true, theme.CORNER_SMALL)
    end
    icons.draw("settings", cursor_x + item * 0.5, iy + item * 0.5,
        open_settings and theme.TEXT_ACTIVE or anim.mix(theme.TEXT_DIM, theme.TEXT, hover_t))
    if input.clicked(cursor_x, iy, item, item) and not widgets.block_under then
        settings_opened_this_frame = not open_settings
        open_settings = not open_settings
        widgets.open_combo = nil
        widgets.open_multi = nil
        widgets.open_color = nil
        widgets.open_bind_mode = nil
        widgets.interacted = true
    end
    visible_settings = build_visible_settings()
    popup_rect = {
        x = math.min(x + bar_w - (theme.DOCK_POPUP_W or 270), sw - (theme.DOCK_POPUP_W or 270) - 6),
        y = y + bar_h + 9,
        w = theme.DOCK_POPUP_W or 270,
        h = settings_height(visible_settings),
    }
    return dock_rect
end
function M.rect()
    return dock_rect
end
function M.draw(x, y, w, h)
    local gap = theme.DOCK_GAP or 6
    local chip_h = theme.DOCK_CHIP_H or math.max(22, h - 8)
    local icon_w = chip_h
    local settings_w = chip_h
    local widths = {}
    local total = settings_w
    for i, panel in ipairs(PANELS) do
        local label_w = text_width(panel.label, theme.FONT_CAPTION)
        widths[i] = icon_w + label_w + (theme.DOCK_PAD_X or 10)
        total = total + widths[i] + gap
    end
    local cursor_x = x + w - total
    local chip_y = y + math.floor((h - chip_h) * 0.5)
    local dock_left = cursor_x
    for i, panel in ipairs(PANELS) do
        local chip_w = widths[i]
        local active = state.get(panel.id, false) == true
        local hot = input.hover(cursor_x, chip_y, chip_w, chip_h)
        local t = anim.transition("hud-dock:" .. panel.id, active or hot, anim.motion_rate(18))
        local bg = active
            and theme.alpha(theme.NAV_ACTIVE or theme.SIDEBAR_ACTIVE, 0.70 + t * 0.18)
            or theme.alpha(theme.NAV_IDLE or theme.BUTTON, 0.44 + t * 0.28)
        widgets.rect(cursor_x, chip_y, chip_w, chip_h, bg, true, theme.CORNER_SMALL)
        widgets.rect(cursor_x, chip_y, chip_w, chip_h,
            active and theme.alpha(theme.ACCENT, 0.62) or theme.BORDER_SOFT, false, theme.CORNER_SMALL)
        local icon_col = active and theme.TEXT_ACTIVE
            or anim.mix(theme.TEXT_DIM, theme.TEXT_ACTIVE, t)
        icons.draw(panel.icon, cursor_x + icon_w * 0.5, chip_y + chip_h * 0.5, icon_col, 0.76)
        widgets.text(cursor_x + icon_w - 1, chip_y + math.floor((chip_h - theme.FONT_CAPTION) * 0.5) - 1,
            panel.label, icon_col, theme.FONT_CAPTION)
        if input.clicked(cursor_x, chip_y, chip_w, chip_h) and not widgets.block_under then
            state.set(panel.id, not active)
            widgets.interacted = true
        end
        cursor_x = cursor_x + chip_w + gap
    end
    local hot = input.hover(cursor_x, chip_y, settings_w, chip_h)
    local t = anim.transition("hud-dock:settings", open_settings or hot, anim.motion_rate(18))
    widgets.rect(cursor_x, chip_y, settings_w, chip_h,
        theme.alpha(theme.NAV_IDLE or theme.BUTTON, 0.48 + t * 0.30), true, theme.CORNER_SMALL)
    widgets.rect(cursor_x, chip_y, settings_w, chip_h,
        open_settings and theme.alpha(theme.ACCENT, 0.72) or theme.BORDER_SOFT, false, theme.CORNER_SMALL)
    icons.draw("settings", cursor_x + settings_w * 0.5, chip_y + chip_h * 0.5,
        anim.mix(theme.TEXT_DIM, theme.TEXT_ACTIVE, t), 0.76)
    if input.clicked(cursor_x, chip_y, settings_w, chip_h) and not widgets.block_under then
        open_settings = not open_settings
        widgets.open_combo = nil
        widgets.open_multi = nil
        widgets.open_color = nil
        widgets.open_bind_mode = nil
        widgets.interacted = true
    end
    popup_rect = {
        x = x + w - (theme.DOCK_POPUP_W or 270),
        y = y + h + 7,
        w = theme.DOCK_POPUP_W or 270,
        h = theme.DOCK_POPUP_H or 250,
    }
    return dock_left
end
function M.draw_overlay()
    if not open_settings or not popup_rect then return end
    local r = popup_rect
    local underlay_blocked = widgets.block_under
    widgets.block_under = false
    widgets.rect(r.x, r.y, r.w, r.h, theme.OVERLAY, true, theme.CORNER)
    widgets.rect(r.x, r.y, r.w, r.h, theme.BORDER_SOFT, false, theme.CORNER)
    widgets.text(r.x + 12, r.y + 10, "HUD SETTINGS", theme.TEXT_ACTIVE, theme.FONT_TITLE)
    widgets.text(r.x + r.w - 22, r.y + 9, "x", theme.TEXT_DIM, theme.FONT_TITLE)
    if input.clicked(r.x + r.w - 30, r.y + 3, 28, 25) then
        open_settings = false
        widgets.interacted = true
        widgets.block_under = underlay_blocked
        return
    end
    local iy = r.y + 38
    local ix = r.x + 10
    local iw = r.w - 20
    for _, item in ipairs(visible_settings) do
        local used = widgets.draw_item(item, ix, iy, iw)
        iy = iy + math.max(used or 0, widgets.estimate_height(item)) + theme.ITEM_GAP
    end
    if input.lmb_click and not settings_opened_this_frame
        and not input.hover(r.x, r.y, r.w, r.h)
        and not (dock_rect and input.hover(dock_rect.x, dock_rect.y, dock_rect.w, dock_rect.h))
    then
        open_settings = false
    end
    widgets.block_under = underlay_blocked
end
return M
end)()

April._mods["ui.menu_fx"] = (function()
local state = April.require("ui.gs_state")
local widgets = April.require("ui.gs_widgets")
local anim = April.require("ui.gs_anim")
local settings = April.require("core.settings")
local M = {}
local flakes = {}
local flake_count = 0
local last_now = nil
local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end
local function screen_size()
    local w, h
    if draw then
        local fn = draw.get_screen_size or draw.GetScreenSize
        if fn then
            local ok, a, b = pcall(fn)
            if ok then w, h = a, b end
        end
    end
    if (not w or not h or w <= 0 or h <= 0) and utility then
        local fn = utility.get_screen_size or utility.GetScreenSize
        if fn then
            local ok, a, b = pcall(fn)
            if ok then w, h = a, b end
        end
    end
    w = math.floor(tonumber(w) or 0)
    h = math.floor(tonumber(h) or 0)
    if w <= 0 then w = 1920 end
    if h <= 0 then h = 1080 end
    return w, h
end
local function rebuild(count, sw, sh)
    flakes = {}
    flake_count = count
    for i = 1, count do
        flakes[i] = {
            x = math.random() * sw,
            y = math.random() * sh,
            size = 1.2 + math.random() * 2.4,
            speed = 0.35 + math.random() * 1.15,
            drift = (math.random() - 0.5) * 0.55,
            phase = math.random() * 6.28318,
            wobble = 0.6 + math.random() * 1.4,
        }
    end
end
local function dt()
    local now = anim.now()
    local d = 0.016
    if last_now then d = clamp(now - last_now, 0, 0.05) end
    last_now = now
    return d
end
local function fill_rect(x, y, w, h, col)
    if not draw or w <= 0 or h <= 0 then return end
    local fill = draw.rect_filled or draw.RectFilled or draw.filled_rect
    if not fill then return end
    pcall(fill, x, y, w, h, col, 0)
end
function M.draw_overlay(sw, sh, open_progress)
    if not settings.bool("april_ui_menu_overlay", true) then return end
    local strength = clamp(settings.num("april_ui_overlay_strength", 70), 0, 100)
    if strength <= 0 then
        strength = 70
    end
    local t = open_progress or 0
    if anim.ease_out_cubic then
        t = anim.ease_out_cubic(t)
    end
    t = clamp(t, 0, 1)
    if t < 0.01 then return end
    local a = (strength / 100) * 0.88 * t
    if a < 0.02 then return end
    widgets.clip = nil
    sw = math.floor(tonumber(sw) or 0)
    sh = math.floor(tonumber(sh) or 0)
    if sw <= 0 or sh <= 0 then
        sw, sh = screen_size()
    end
    fill_rect(-1, -1, sw + 2, sh + 2, { 0, 0, 0, a })
end
function M.draw_snow(sw, sh, open_progress)
    if not settings.bool("april_ui_snow", false) or anim.reduce_motion() then return end
    local fade = anim.ease_out_cubic and anim.ease_out_cubic(open_progress or 0) or (open_progress or 0)
    if fade < 0.02 then return end
    sw = math.floor(tonumber(sw) or 0)
    sh = math.floor(tonumber(sh) or 0)
    if sw <= 0 or sh <= 0 then
        sw, sh = screen_size()
    end
    local amount = math.floor(clamp(settings.num("april_ui_snow_amount", 50), 10, 140) + 0.5)
    local speed_mul = clamp(settings.num("april_ui_snow_speed", 40), 1, 100) / 40
    local opacity = clamp(settings.num("april_ui_snow_opacity", 55), 10, 100) / 100
    local size_mul = clamp(settings.num("april_ui_snow_size", 3), 1, 8) / 3
    if flake_count ~= amount or #flakes == 0 then rebuild(amount, sw, sh) end
    widgets.clip = nil
    local step = dt()
    local fall = 38 * speed_mul * step
    local alpha = opacity * fade * 0.9
    for i = 1, #flakes do
        local f = flakes[i]
        f.phase = f.phase + step * f.wobble
        f.y = f.y + fall * f.speed
        f.x = f.x + math.sin(f.phase) * f.drift * 18 * step * speed_mul
        if f.y > sh + 6 then
            f.y = -6 - math.random() * 24
            f.x = math.random() * sw
        elseif f.x < -8 then
            f.x = sw + 4
        elseif f.x > sw + 8 then
            f.x = -4
        end
        local s = math.max(1, f.size * size_mul)
        local a = alpha * (0.55 + 0.45 * ((math.sin(f.phase * 0.7) + 1) * 0.5))
        fill_rect(f.x, f.y, s, s, { 0.92, 0.95, 1.0, a })
    end
end
function M.draw_backdrop(sw, sh, open_progress)
    if (not sw or not sh or sw <= 0 or sh <= 0) then
        sw, sh = screen_size()
    end
    M.draw_overlay(sw, sh, open_progress)
    M.draw_snow(sw, sh, open_progress)
end
return M
end)()

April._mods["ui.startup_intro"] = (function()
local theme = April.require("ui.gs_theme")
local anim = April.require("ui.gs_anim")
local settings = April.require("core.settings")
local image_cache = April.require("core.image_cache")
local asset_urls = April.require("game.asset_urls")
local M = {}
local DURATION = 4.35
local MENU_REVEAL_AT = 3.72
local TEXT_EXIT_AT = 3.12
local PROFILE_KEY = "startup_author_profile"
local active = false
local started_at = 0
local function clamp01(value)
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end
local function ease_out_cubic(value)
    local t = clamp01(value)
    local q = 1 - t
    return 1 - q * q * q
end
local function now()
    if utility and utility.get_time then return utility.get_time() end
    if utility and utility.get_tick_count then return utility.get_tick_count() * 0.001 end
    return 0
end
local function screen_size()
    local fn = draw and (draw.get_screen_size or draw.GetScreenSize)
    if fn then
        local ok, width, height = pcall(fn)
        if ok and width and height then return width, height end
    end
    return 1920, 1080
end
local function text_width(text, size)
    local fn = draw and (draw.get_text_size or draw.GetTextSize)
    if fn then
        local ok, width = pcall(fn, text, size)
        if ok and type(width) == "number" then return width end
    end
    return #tostring(text or "") * size * 0.56
end
local function draw_wave(text, center_x, y, size, alpha, phase_offset, amplitude)
    if alpha <= 0 or not draw then return end
    local draw_text = draw.text or draw.Text
    if not draw_text then return end
    local total_width = text_width(text, size)
    local cursor_x = center_x - total_width * 0.5
    local phase = now() * 4.0 + (phase_offset or 0)
    local accent = anim.title_color()
    amplitude = amplitude or 2
    for index = 1, #text do
        local char = text:sub(index, index)
        local wave = math.sin(phase + (index - 1) * 0.68)
        local mix = 0.12 + (wave + 1) * 0.12
        local color = anim.mix(accent, theme.TEXT_ACTIVE, mix)
        color = { color[1], color[2], color[3], alpha * (color[4] or 1) }
        draw_text(cursor_x, y + wave * amplitude, char, color, size)
        cursor_x = cursor_x + text_width(char, size)
    end
end
local function draw_module_status(center_x, y, elapsed, alpha)
    if alpha <= 0 or not April or type(April.load_status) ~= "table" then return end
    local draw_text = draw and (draw.text or draw.Text)
    local line = draw and (draw.line or draw.Line)
    if not draw_text or not line then return end
    local accent = anim.title_color()
    local size = math.max(12, math.floor(13 * (theme.SCALE or 1)))
    local heading = "Loading modules"
    local heading_size = math.max(11, size - 1)
    draw_text(center_x - text_width(heading, heading_size) * 0.5, y, heading,
        { theme.TEXT_ACTIVE[1], theme.TEXT_ACTIVE[2], theme.TEXT_ACTIVE[3], alpha * 0.48 },
        heading_size)
    local rows_y = y + 21
    for index, status in ipairs(April.load_status) do
        local appear_at = 0.92 + (index - 1) * 0.24
        local appear = ease_out_cubic((elapsed - appear_at) / 0.22)
        if appear > 0 then
            local loaded = status.state == "loaded"
            local failed = status.state == "failed"
            local checked = loaded and ease_out_cubic((elapsed - appear_at - 0.13) / 0.20) or 0
            local label = loaded and tostring(status.name)
                or failed and ("Failed: " .. tostring(status.name))
                or ("Loading " .. tostring(status.name) .. "...")
            local label_width = text_width(label, size)
            local row_alpha = alpha * appear
            local icon_x = center_x - (label_width + 24) * 0.5
            local icon_y = rows_y + (index - 1) * 19 + 7
            local text_color = failed and { 1, 0.28, 0.28, row_alpha }
                or { theme.TEXT_ACTIVE[1], theme.TEXT_ACTIVE[2], theme.TEXT_ACTIVE[3], row_alpha * 0.82 }
            if failed then
                line(icon_x, icon_y - 4, icon_x + 8, icon_y + 4, text_color, 1.5)
                line(icon_x + 8, icon_y - 4, icon_x, icon_y + 4, text_color, 1.5)
            elseif checked > 0 then
                local check_color = {
                    accent[1], accent[2], accent[3], row_alpha * checked,
                }
                line(icon_x, icon_y, icon_x + 3 * checked, icon_y + 4 * checked, check_color, 1.7)
                line(icon_x + 3, icon_y + 4, icon_x + 10 * checked, icon_y - 5 * checked, check_color, 1.7)
            else
                local pulse = 0.35 + (math.sin(now() * 5 + index) + 1) * 0.22
                line(icon_x, icon_y, icon_x + 7, icon_y,
                    { accent[1], accent[2], accent[3], row_alpha * pulse }, 1.7)
            end
            draw_text(icon_x + 18, rows_y + (index - 1) * 19, label, text_color, size)
        end
    end
end
function M.init()
    active = settings.bool("april_ui_startup_intro", true)
    if active then
        image_cache.ensure(PROFILE_KEY, asset_urls.author_profile_png())
    end
    started_at = now()
    return active
end
function M.cancel()
    active = false
end
function M.is_active()
    return active
end
function M.should_reveal_menu()
    return active and (now() - started_at) >= MENU_REVEAL_AT
end
function M.draw()
    if not active or not draw then return false end
    local elapsed = math.max(0, now() - started_at)
    if elapsed >= DURATION then
        active = false
        return false
    end
    theme.sync()
    anim.sync_theme()
    local width, height = screen_size()
    local black_alpha
    if elapsed < 0.22 then
        black_alpha = ease_out_cubic(elapsed / 0.22)
    elseif elapsed < MENU_REVEAL_AT then
        black_alpha = 1
    else
        black_alpha = 1 - ease_out_cubic((elapsed - MENU_REVEAL_AT) / (DURATION - MENU_REVEAL_AT))
    end
    local fill = draw.rect_filled or draw.RectFilled
    if fill then fill(-1, -1, width + 2, height + 2, { 0, 0, 0, black_alpha }, 0) end
    local title_t = ease_out_cubic((elapsed - 0.16) / 0.62)
    local author_t = ease_out_cubic((elapsed - 0.58) / 0.52)
    local profile_t = ease_out_cubic((elapsed - 0.86) / 0.72)
    local text_out = 1 - ease_out_cubic((elapsed - TEXT_EXIT_AT) / 0.20)
    local profile_out = 1 - ease_out_cubic((elapsed - (MENU_REVEAL_AT - 0.18)) / 0.26)
    local title_alpha = title_t * text_out * black_alpha
    local author_alpha = author_t * text_out * black_alpha
    local profile_alpha = profile_t * profile_out * black_alpha
    local center_x = width * 0.5
    local center_y = height * 0.5
    local title_x = center_x - (1 - title_t) * math.min(160, width * 0.15)
    local author_x = center_x + (1 - author_t) * math.min(125, width * 0.12)
    local title_size = math.max(40, math.floor(54 * (theme.SCALE or 1)))
    local author_size = math.max(15, math.floor(18 * (theme.SCALE or 1)))
    draw_wave("April.lua", title_x, center_y - 38, title_size, title_alpha, 0, 1.35)
    draw_wave("Made by Cunzaki", author_x, center_y + 22, author_size, author_alpha, 1.7, 0.8)
    draw_module_status(center_x, center_y + 62, elapsed, author_alpha)
    if profile_alpha > 0.01 then
        local final_w = math.max(230, math.min(420, math.floor(math.min(width, height) * 0.50)))
        local profile_w = final_w
        local profile_h = math.floor(profile_w * 399 / 375)
        local profile_x = width - profile_w * 0.76 + (1 - profile_t) * 94
        local profile_y = height - profile_h * 0.80 + (1 - profile_t) * 74
        image_cache.draw_fit(
            PROFILE_KEY,
            profile_x,
            profile_y,
            profile_w,
            profile_h,
            { 1, 1, 1, profile_alpha }
        )
    end
    local line = draw.line or draw.Line
    if line and author_alpha > 0 then
        local line_t = ease_out_cubic((elapsed - 0.82) / 0.44) * text_out
        local half = 76 * line_t
        local accent = anim.title_color()
        line(center_x - half, center_y + 46, center_x + half, center_y + 46,
            { accent[1], accent[2], accent[3], author_alpha * 0.58 }, 1)
    end
    return true
end
return M
end)()

April._mods["ui.custom_menu"] = (function()
local theme = April.require("ui.gs_theme")
local gin = April.require("ui.gs_input")
local widgets = April.require("ui.gs_widgets")
local anim = April.require("ui.gs_anim")
local icons = April.require("ui.gs_icons")
local catalog = April.require("ui.catalog")
local state = April.require("ui.gs_state")
local hud_dock = April.require("ui.hud_dock")
local menu_fx = April.require("ui.menu_fx")
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
local settled_closed = false
local tab_index = 1
local win_x, win_y = 80, 80
local scroll = { left = 0, right = 0 }
local scroll_visual = { left = 0, right = 0 }
local middle_scroll = nil
local collapsed_groups = {}
local last_menu_rect = nil
local SCROLL_EDGE = 36
local SCROLL_SPEED = 5
local WHEEL_STEP = 48
local PAGE_STEP = 90
local MIDDLE_DRAG_SCALE = 1.35
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
local function text_width(text, size)
local fn = draw and (draw.get_text_size or draw.GetTextSize)
if fn then
local ok, width = pcall(fn, text, size)
if ok and type(width) == "number" then return width end
end
return #tostring(text or "") * math.max(5, (size or 12) * 0.55)
end
local function draw_wave_text(wordmark, x, y, size, phase_offset, alpha)
local cursor_x = x
local phase = anim.now() * 3.4 + (phase_offset or 0)
local accent = anim.title_color()
alpha = alpha or 1
for i = 1, #wordmark do
local char = wordmark:sub(i, i)
local wave = math.sin(phase + (i - 1) * 0.72)
local col = anim.mix(accent, theme.TEXT_ACTIVE, 0.10 + (wave + 1) * 0.10)
col = { col[1], col[2], col[3], (col[4] or 1) * alpha }
widgets.text(cursor_x, y + wave * 1.5, char, col, size)
cursor_x = cursor_x + text_width(char, size)
end
return cursor_x
end
local function draw_brand(x, y)
draw_wave_text("April.lua", x, y, theme.FONT_BRAND or 15)
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
local function draw_top_navbar(x, y, w, h)
widgets.rect(x, y, w, h, theme.NAV_BG or theme.SIDEBAR, true, 0)
widgets.rect(x, y + h - 1, w, 1, theme.BORDER_SOFT, true)
local tabs = catalog.TABS
local gap = theme.NAV_GAP or 5
local pad = theme.NAV_PAD_X or 10
local available = w - pad * 2 - gap * (#tabs - 1)
local tab_w = math.floor(available / #tabs)
local cursor_x = x + pad
local active_x, active_w = cursor_x + 8, tab_w - 16
for i, tab in ipairs(tabs) do
local active = i == tab_index
local hot = gin.hover(cursor_x, y + 5, tab_w, h - 10)
local emphasis = anim.transition("tab:" .. tab.id, active or hot, anim.motion_rate(16))
local tab_y = y + 5
local tab_h = h - 10
if active then
active_x, active_w = cursor_x + 8, tab_w - 16
widgets.rect(cursor_x, tab_y, tab_w, tab_h,
theme.alpha(theme.NAV_ACTIVE or theme.SIDEBAR_ACTIVE, 0.48 + emphasis * 0.28),
true, theme.CORNER_SMALL)
elseif emphasis > 0.01 then
widgets.rect(cursor_x, tab_y, tab_w, tab_h,
theme.alpha(theme.HOVER, emphasis * 0.55), true, theme.CORNER_SMALL)
end
local col = active and anim.tab_icon_color() or anim.mix(theme.TEXT_DIM, theme.TEXT, emphasis * 0.45)
local label = tab.label or tab.title or tab.id
local icon_x = cursor_x + 16
local cy = y + h * 0.5
icons.draw(tab.icon or tab.id, icon_x, cy, col, 0.72)
widgets.text(cursor_x + 29, cy - math.floor(theme.FONT_CAPTION * 0.5) - 1,
label, col, theme.FONT_CAPTION)
if gin.clicked(cursor_x, tab_y, tab_w, tab_h) and not widgets.block_under then
tab_index = i
scroll.left = 0
scroll.right = 0
scroll_visual.left = 0
scroll_visual.right = 0
anim.clear_tab_progress(tab.id)
widgets.open_combo = nil
widgets.open_multi = nil
end
cursor_x = cursor_x + tab_w + gap
end
if anim.navbar_indicator then
local local_x = active_x - x
local_x, active_w = anim.navbar_indicator("primary", local_x, active_w, 20)
active_x = x + local_x
end
if anim.draw_nav_indicator then
anim.draw_nav_indicator(active_x, y + h - 3, active_w, 2)
else
anim.draw_section_top(active_x, y + h - 3, active_w)
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
widgets.rect(x + 1, y, 2, h, theme.alpha(theme.SLIDER_BG, 0.28), true, 1)
anim.draw_scroll_thumb(x, thumb_y, 3, thumb_h)
end
local function handle_column_scroll(x, y, w, h, scroll_key, content_h)
local max_scroll = clamp_scroll(scroll_key, content_h, h)
if max_scroll <= 0 then
if middle_scroll and middle_scroll.key == scroll_key then middle_scroll = nil end
return
end
local hot = gin.hover(x, y, w + 14, h)
if middle_scroll and middle_scroll.key == scroll_key then
if gin.mmb then
scroll[scroll_key] = middle_scroll.start_scroll
+ (middle_scroll.start_y - gin.my) * MIDDLE_DRAG_SCALE
clamp_scroll(scroll_key, content_h, h)
widgets.interacted = true
return
end
middle_scroll = nil
end
if not hot then return end
if gin.mmb_click then
middle_scroll = {
key = scroll_key,
start_y = gin.my,
start_scroll = scroll[scroll_key],
}
widgets.interacted = true
return
end
if gin.wheel ~= 0 and not widgets.wheel_consumed then
scroll[scroll_key] = scroll[scroll_key] - gin.wheel * WHEEL_STEP
clamp_scroll(scroll_key, content_h, h)
widgets.wheel_consumed = true
return
end
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
widgets.rect(x + 5, box_top + 4, w - 10, theme.GROUP_HEADER_H - 8,
theme.alpha(theme.HOVER, hover * 0.45), true, theme.CORNER_SMALL)
end
widgets.text(x + 14, box_top + 8, title, theme.TEXT_ACTIVE, theme.FONT_TITLE)
local cx = x + w - 16
local cy = box_top + theme.GROUP_HEADER_H * 0.5
local line = draw and (draw.line or draw.Line)
if line then
local col = hot and theme.TEXT_ACTIVE or theme.TEXT_DIM
line(cx - 3, cy, cx + 3, cy, col, 1.2)
if collapsed then line(cx, cy - 3, cx, cy + 3, col, 1.2) end
end
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
widgets.rect(x, vis_y, w, vis_h, theme.PANEL, true, theme.CORNER)
widgets.rect(x, vis_y, w, vis_h, theme.BORDER_SOFT, false, theme.CORNER)
if box_top >= y - 2 and box_top < y + h then
widgets.rect(x + 1, box_top + 1, w - 2, theme.GROUP_HEADER_H - 2,
theme.alpha(theme.PANEL_ALT, 0.42), true, theme.CORNER)
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
if tab_id == "aim" and #groups >= 3 then
return { groups[1] }, { groups[2], groups[3] }
end
if tab_id == "config" and #groups >= 5 then
return { groups[1], groups[2], groups[3], groups[4] }, { groups[5] }
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
state.define("april_ui_menu_overlay", true)
state.define("april_ui_overlay_strength", 70)
state.define("april_ui_snow", false)
state.define("april_ui_snow_amount", 50)
state.define("april_ui_snow_speed", 40)
state.define("april_ui_snow_size", 3)
state.define("april_ui_snow_opacity", 55)
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
hud_dock.init()
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
function M.contains_point(px, py)
if not open or not last_menu_rect then return false end
local r = last_menu_rect
return px >= r.x and py >= r.y and px <= r.x + r.w and py <= r.y + r.h
end
function M.draw()
if not draw then return end
gin.begin_frame()
if gin.key_pressed(menu_toggle_vk()) and not widgets.listening_key
and not widgets.active_input and not widgets.active_slider_input then
open = not open
if open then settled_closed = false end
gin.set_menu_open(open)
end
if not open and settled_closed then
if gin._menu_open or gin._game_cursor_hidden then
gin.set_menu_open(false)
end
return
end
anim.sync_theme()
widgets.begin_popups()
hud_dock.begin_frame()
widgets.tick_key_listen()
widgets.tick_slider_input()
widgets.tick_text_input()
local open_progress = anim.menu_open_progress(open)
if not open and open_progress <= 0.015 then
settled_closed = true
if gin._menu_open or gin._game_cursor_hidden then
gin.set_menu_open(false)
end
return
end
settled_closed = false
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
last_menu_rect = { x = x, y = y, w = w, h = h }
widgets.clip = nil
local sw, sh = screen_size()
pcall(menu_fx.draw_backdrop, sw, sh, open_progress)
gin.set_ui_rect(x, y, w, h)
hud_dock.draw_floating(x + w * 0.5, math.max(8, y - 58 * (theme.SCALE or 1)), sw, sh)
local fade = anim.menu_fade()
local panel_bg = anim.panel_bg()
local glass_alpha = math.min(panel_bg[4] or 1, (theme.PANEL_ALPHA or 0.72) + 0.04)
widgets.rect(x, y, w, h, theme.alpha(panel_bg, glass_alpha * fade), true, theme.CORNER)
widgets.rect(x, y, w, h, theme.BORDER_SOFT, false, theme.CORNER)
local title_h = theme.TITLEBAR_H or math.max(34, math.floor(34 * (theme.SCALE or 1)))
widgets.rect(x + 1, y + 3, w - 2, title_h, theme.BG_INNER, true, 0)
widgets.rect(x + 1, y + title_h + 3, w - 2, 1, theme.BORDER_SOFT, true)
local tab = catalog.TABS[tab_index]
draw_brand(x + 14, y + 9)
local version_text = "v" .. tostring(April.version or "")
widgets.text(x + w - 14 - text_width(version_text, theme.FONT_CAPTION), y + 5,
version_text, theme.TEXT_DIM, theme.FONT_CAPTION)
local author_text = "Made by Cunzaki"
local author_size = math.max(8, (theme.FONT_CAPTION or 11) - 2)
draw_wave_text(
author_text,
x + w - 14 - text_width(author_text, author_size),
y + 18,
author_size,
1.8,
0.88
)
if gin.lmb_click and gin.hover(x, y, w, title_h + 5)
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
local nav_h = theme.NAVBAR_H or math.max(42, math.floor(42 * (theme.SCALE or 1)))
local nav_y = y + title_h + 4
draw_top_navbar(x + 1, nav_y, w - 2, nav_h)
local body_y = nav_y + nav_h + 7
local body_h = h - title_h - nav_h - 15
local content_x = x + 12
local content_w = w - 24
local col_w = math.floor((content_w - 16) * 0.5)
local groups = catalog.groups_for(tab and tab.id or "aim")
local left_groups, right_groups = split_groups(groups, tab and tab.id or "aim")
local tab_progress = anim.tab_progress(tab and tab.id or "aim")
local tab_shift = math.floor((1 - tab_progress) * 8 * (theme.SCALE or 1))
draw_group_column(left_groups, content_x + tab_shift, body_y + 2, col_w, body_h - 4, "left")
draw_group_column(right_groups, content_x + col_w + 12 + tab_shift, body_y + 2, col_w, body_h - 4, "right")
widgets.end_tooltip_frame()
hud_dock.draw_overlay()
widgets.draw_color_overlay()
widgets.draw_bind_mode_overlay()
widgets.draw_tooltip_overlay()
widgets.end_popups()
if open then
gin.draw_cursor()
end
end
return M
end)()

April._mods["menu.tabs"] = (function()
local menu_util = April.require("core.menu_util")
local debug = April.require("core.debug")
local bootstrap = April.require("game.bootstrap")
local cache = April.require("core.cache")
local npcs = April.require("game.npcs")
local player_state = April.require("game.player_state")
local weapons = April.require("game.weapons")
local runservice = April.require("core.runservice")
local incremental_scan = April.require("core.incremental_scan")
local M = {}
M.features = {}
M._menu_registered = false
M.FEATURE_ORDER = {
    "features.combat.camera_aimbot",
    "features.combat.aimbot",
    "features.combat.body_peek",
    "features.combat.thick_bullet",
    "features.combat.gun_mods",
    "features.visuals.target_overlay",
    "features.visuals.target_visuals",
    "features.visuals.player_esp",
    "features.world.world_esp",
    "features.world.loot_esp",
    "features.world.npc_esp",
    "features.world.raid_esp",
    "features.world.base_esp",
    "features.world.base_xray",
    "features.radar.tactical_map",
    "features.radar.waypoints",
    "features.movement.exploits",
    "features.movement.bhop",
    "features.movement.desync",
    "features.movement.anti_aim",
    "features.movement.fake_duck",
    "features.movement.fling",
    "features.movement.anti_fling",
    "features.combat.perfect_farm",
    "features.utility.autofarm",
    "features.utility.mod_checker",
    "features.utility.event_status",
    "features.utility.anti_afk",
    "features.utility.keybind_viewer",
    "features.utility.anime_announcer",
    "features.utility.config",
}
function M.register_all()
    if M._menu_registered then return end
    menu_util.ensure_groups()
    M.features = {}
    local registered = 0
    for _, path in ipairs(M.FEATURE_ORDER) do
        local feat = April.require(path)
        table.insert(M.features, feat)
        if feat.register_menu then
            local ok = pcall(feat.register_menu)
            if ok then
                registered = registered + 1
            end
        end
    end
    M._menu_registered = true
    pcall(function()
        local mod = April.require("features.utility.mod_checker")
        if mod.init then mod.init() end
    end)
end
function M.setup_scans()
    local settings = April.require("core.settings")
    local cache = April.require("core.cache")
    local iscan = April.require("core.incremental_scan")
    local world_esp = April.require("features.world.world_esp")
    local loot_esp = April.require("features.world.loot_esp")
    local base_esp = April.require("features.world.base_esp")
    iscan.configure({ budget_ms = 6, items_per_step = 18 })
    local SCAN_MS = cache.WORKSPACE_SCAN_MS or 1000
    local DROPS_SCAN_MS = cache.DROPS_SCAN_MS or 3500
    local function map_on(layer)
        return function()
            if not settings.enabled("april_map_enabled") then return false end
            return settings.enabled("april_map_show_" .. layer)
        end
    end
    iscan.register("world", SCAN_MS, function()
        return settings.enabled("april_world_enabled") or map_on("world")()
    end, world_esp.begin_static_scan, world_esp.step_static_scan, world_esp.complete_static_scan, 0)
    iscan.register("world_dynamic", SCAN_MS, function()
        if not settings.enabled("april_world_enabled") then return false end
        return settings.enabled("april_deer")
            or settings.enabled("april_boar")
            or settings.enabled("april_wolf")
    end, world_esp.begin_dynamic_scan, world_esp.step_dynamic_scan, world_esp.complete_dynamic_scan, 120)
    iscan.register("loot", SCAN_MS, function()
        return settings.enabled("april_loot_enabled") or map_on("loot")()
    end, loot_esp.begin_static_scan, loot_esp.step_static_scan, loot_esp.complete_static_scan, 240)
    iscan.register("loot_drops", DROPS_SCAN_MS, function()
        if settings.enabled("april_loot_enabled") then
            return settings.enabled("april_dropped_item")
        end
        return map_on("loot")()
    end, loot_esp.begin_drops_scan, loot_esp.step_drops_scan, loot_esp.complete_drops_scan, 360)
    iscan.register("base", SCAN_MS, function()
        return settings.enabled("april_base_enabled") or map_on("base")()
    end, base_esp.begin_static_scan, base_esp.step_static_scan, base_esp.complete_static_scan, 480)
end
function M.update(dt)
    cache.refresh_entities()
    npcs.refresh_cache(cache.workspace_entities)
    player_state.tick(cache.players)
    bootstrap.tick()
    weapons.tick()
    runservice.dispatch(dt)
    incremental_scan.tick()
    for i, feat in ipairs(M.features) do
        if feat.update then
            local name = M.FEATURE_ORDER[i] or ("#" .. i)
            debug.guard_fast("update:" .. name, feat.update, dt)
        end
    end
end
function M.draw()
    for i, feat in ipairs(M.features) do
        if feat.draw then
            local name = M.FEATURE_ORDER[i] or ("#" .. i)
            debug.guard_fast("draw:" .. name, feat.draw)
        end
    end
end
function M.init()
    local env = April.require("core.env")
    local ok = env.require_apis({ "draw", "utility", "entity", "game" })
    if not ok then
        return false
    end
    pcall(function()
        April.require("ui.menu_shim").install()
    end)
    M.register_all()
    M.setup_scans()
    M.setup_player_hooks()
    pcall(function()
        April.require("features.utility.config").try_autoload()
    end)
    return true
end
function M.setup_player_hooks()
    local mod = April.require("features.utility.mod_checker")
    _G.on_player_added = function(p)
        debug.guard_fast("on_player_added", mod.on_player_added, p)
    end
    _G.on_player_removed = function(p)
        debug.guard_fast("on_player_removed", mod.on_player_removed, p)
    end
end
return M
end)()

April._mods["app"] = (function()
local tabs = April.require("menu.tabs")
local debug = April.require("core.debug")
local notify = April.require("core.notify")
local custom_menu = April.require("ui.custom_menu")
local startup_intro = April.require("ui.startup_intro")
local api_aliases = April.require("core.api_aliases")
local feature_bind = April.require("core.feature_bind")
local aim_key = April.require("core.aim_key")
local overlay_theme = April.require("core.overlay_theme")
local M = {}
local initialized = false
local alias_refresh_elapsed = 0
function M.init()
    if initialized then return true end
    pcall(function()
        April.require("core.entity_props").ensure_api_aliases()
    end)
    initialized = tabs.init()
    if initialized then
        pcall(custom_menu.init)
        pcall(startup_intro.init)
    end
    return initialized
end
function M.on_frame()
    if not initialized then return end
    debug.tick_frame()
    pcall(feature_bind.tick)
    pcall(aim_key.tick, "april_aim_key", "april_aim_key_mode")
    if startup_intro.is_active() then
        if startup_intro.should_reveal_menu() then
            debug.guard_fast("custom_menu.draw:intro", custom_menu.draw)
        end
        local ok = pcall(startup_intro.draw)
        if ok then
            return
        end
        startup_intro.cancel()
    end
    local dt = 0.016
    if utility and utility.get_delta_time then
        local ok, v = pcall(utility.get_delta_time)
        if ok and type(v) == "number" then dt = v end
    end
    alias_refresh_elapsed = alias_refresh_elapsed + dt
    if alias_refresh_elapsed >= 2 then
        alias_refresh_elapsed = 0
        pcall(api_aliases.apply)
    end
    debug.guard_fast("tabs.update", tabs.update, dt)
    debug.guard_fast("overlay_theme.sync", overlay_theme.sync)
    debug.guard_fast("tabs.draw", tabs.draw)
    debug.guard_fast("notify.draw", notify.draw)
    debug.guard_fast("custom_menu.draw", custom_menu.draw)
end
return M
end)()

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
