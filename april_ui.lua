--[[
    April Fallen — Custom UI demo (Gamesense placeholder)
    Standalone: does NOT load april.lua features or Vector menu tabs.
    Toggle: INSERT
    Built: 2026-07-17T22:24:19.597Z
]]

April = {
    version = "ui-0.1.0",
    debug = false,
    _mods = {},
    bundled = true,
    ui_only = true,
}

function April.require(path)
    local mod = April._mods[path]
    if mod == nil then
        error("[April UI] bundled module missing: " .. path)
    end
    return mod
end


-- ── game/esp_maps.lua ──
April._mods["game.esp_maps"] = (function()
local M = {}

M.NODE_MAP = {
    ["Stone_Node"] = "april_stone_node",
    ["Metal_Node"] = "april_metal_node",
    ["Phosphate_Node"] = "april_phosphate_node",
}

M.NODE_LABELS = {
    ["Stone_Node"] = "Stone Node",
    ["Metal_Node"] = "Metal Node",
    ["Phosphate_Node"] = "Phosphate Node",
}

M.NODE_FOLDERS = { "nodes" }

M.PLANT_MAP = {
    ["Corn Plant"] = "april_corn_plant",
    ["Tomato Plant"] = "april_tomato_plant",
    ["Pumpkin Plant"] = "april_pumpkin_plant",
    ["Lemon Plant"] = "april_lemon_plant",
    ["Raspberry Plant"] = "april_raspberry_plant",
    ["Blueberry Plant"] = "april_blueberry_plant",
    ["Wool Plant"] = "april_wool_plant",
}

M.PLANT_LABELS = {
    ["Corn Plant"] = "Corn Plant",
    ["Tomato Plant"] = "Tomato Plant",
    ["Pumpkin Plant"] = "Pumpkin Plant",
    ["Lemon Plant"] = "Lemon Plant",
    ["Raspberry Plant"] = "Raspberry Plant",
    ["Blueberry Plant"] = "Blueberry Plant",
    ["Wool Plant"] = "Wool Plant",
}

M.PLANT_FOLDERS = { "plants" }

M.ANIMAL_MAP = {
    ["PREFAB_ANIMAL_DEER"] = "april_deer",
    ["PREFAB_ANIMAL_WILDBOAR"] = "april_boar",
    ["PREFAB_ANIMAL_WOLF"] = "april_wolf",
    ["Deer"] = "april_deer",
    ["Wild Boar"] = "april_boar",
    ["WildBoar"] = "april_boar",
    ["Boar"] = "april_boar",
    ["Wolf"] = "april_wolf",
}

M.ANIMAL_LABELS = {
    ["PREFAB_ANIMAL_DEER"] = "Deer",
    ["PREFAB_ANIMAL_WILDBOAR"] = "Wild Boar",
    ["PREFAB_ANIMAL_WOLF"] = "Wolf",
    ["Deer"] = "Deer",
    ["Wild Boar"] = "Wild Boar",
    ["WildBoar"] = "Wild Boar",
    ["Boar"] = "Boar",
    ["Wolf"] = "Wolf",
}

M.ANIMAL_FOLDERS = { "animals" }

M.WORLD_TOGGLES = {
    { id = "april_stone_node", label = "Stone Node", color = { 0.5, 0.5, 0.5, 1 } },
    { id = "april_metal_node", label = "Metal Node", color = { 0.7, 0.5, 0.3, 1 } },
    { id = "april_phosphate_node", label = "Phosphate Node", color = { 0.2, 0.8, 0.2, 1 } },
    { id = "april_corn_plant", label = "Corn Plant", color = { 1, 0.9, 0.3, 1 } },
    { id = "april_tomato_plant", label = "Tomato Plant", color = { 1, 0.4, 0.3, 1 } },
    { id = "april_pumpkin_plant", label = "Pumpkin Plant", color = { 1, 0.5, 0.1, 1 } },
    { id = "april_lemon_plant", label = "Lemon Plant", color = { 1, 0.95, 0.2, 1 } },
    { id = "april_raspberry_plant", label = "Raspberry Plant", color = { 0.9, 0.2, 0.4, 1 } },
    { id = "april_blueberry_plant", label = "Blueberry Plant", color = { 0.3, 0.4, 0.9, 1 } },
    { id = "april_wool_plant", label = "Wool Plant", color = { 0.85, 0.85, 0.9, 1 } },
    { id = "april_deer", label = "Deer", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_boar", label = "Wild Boar", color = { 0.4, 0.3, 0.2, 1 } },
    { id = "april_wolf", label = "Wolf", color = { 0.5, 0.5, 0.5, 1 } },
}

M.LOOT_MAP = {
    ["Wooden Crate"] = "april_wooden_crate",
    ["Locked Wooden Crate"] = "april_wooden_crate",
    ["Locked Metal Crate"] = "april_metal_crate",
    ["Locked Steel Crate"] = "april_steel_crate",
    ["Food Crate"] = "april_food_crate",
    ["Timed Crate"] = "april_timed_crate",
    ["Care Package"] = "april_care_package",
    ["BTR Crate"] = "april_btr_crate",
    ["Body Bag"] = "april_body_bag",
    ["Sleeper"] = "april_sleeper",
    ["Trash Can"] = "april_trash_can",
    ["Oil Barrel"] = "april_oil_barrel",
    ["Small Egg"] = "april_small_egg",
    ["Medium Egg"] = "april_medium_egg",
    ["Large Egg"] = "april_large_egg",
    ["Small Gift"] = "april_small_egg",
    ["Medium Gift"] = "april_medium_egg",
    ["Large Gift"] = "april_large_egg",
    ["Wooden Boat"] = "april_wooden_boat",
    ["Military Boat"] = "april_military_boat",
    ["Salvaged Flycopter"] = "april_flycopter",
}

M.LOOT_TOGGLES = {
    { id = "april_dropped_item", label = "Dropped Items", color = { 1, 0.8, 0, 1 } },
    { id = "april_wooden_crate", label = "Wooden Crate", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_metal_crate", label = "Metal Crate", color = { 0.5, 0.5, 0.6, 1 } },
    { id = "april_steel_crate", label = "Steel Crate", color = { 0.7, 0.7, 0.8, 1 } },
    { id = "april_food_crate", label = "Food Crate", color = { 0.2, 0.8, 0.2, 1 } },
    { id = "april_timed_crate", label = "Timed Crate", color = { 1, 0.5, 0, 1 } },
    { id = "april_care_package", label = "Care Package", color = { 1, 0.2, 0.2, 1 } },
    { id = "april_btr_crate", label = "BTR Crate", color = { 0.8, 0.15, 0.15, 1 } },
    { id = "april_body_bag", label = "Body Bag", color = { 0.3, 0.3, 0.3, 1 } },
    { id = "april_sleeper", label = "Sleepers", color = { 0.8, 0.4, 0.8, 1 } },
    { id = "april_trash_can", label = "Trash Can", color = { 0.45, 0.45, 0.45, 1 } },
    { id = "april_oil_barrel", label = "Oil Barrel", color = { 0.2, 0.2, 0.2, 1 } },
    { id = "april_small_egg", label = "Small Egg / Gift", color = { 0.95, 0.85, 0.5, 1 } },
    { id = "april_medium_egg", label = "Medium Egg / Gift", color = { 0.9, 0.7, 0.4, 1 } },
    { id = "april_large_egg", label = "Large Egg / Gift", color = { 0.85, 0.55, 0.3, 1 } },
    { id = "april_wooden_boat", label = "Wooden Boat", color = { 0.55, 0.35, 0.15, 1 } },
    { id = "april_military_boat", label = "Military Boat", color = { 0.35, 0.45, 0.35, 1 } },
    { id = "april_flycopter", label = "Salvaged Flycopter", color = { 0.6, 0.6, 0.65, 1 } },
}

M.LOOT_SCAN_FOLDERS = { "loners", "vegetation", "military", "events", "monuments" }

M.BASE_MAP = {
    ["Base Cabinet"] = "april_base_cabinet",
    ["Storage Cabinet"] = "april_storage_cabinet",
    ["Cabinet"] = "april_base_cabinet",
    ["Large Cabinet"] = "april_storage_cabinet",
    ["Small Storage Box"] = "april_small_box",
    ["Large Storage Box"] = "april_large_box",
    ["Small Box"] = "april_small_box",
    ["Large Box"] = "april_large_box",
    ["Wooden Door"] = "april_wooden_door",
    ["Wooden Double Door"] = "april_wooden_double_door",
    ["Salvaged Metal Door"] = "april_salvaged_door",
    ["Metal Door"] = "april_metal_door",
    ["Metal Double Door"] = "april_metal_double_door",
    ["Steel Door"] = "april_steel_door",
    ["Steel Double Door"] = "april_steel_double_door",
    ["Trap Door"] = "april_trap_door",
    ["Triangle Trap Door"] = "april_triangle_trap_door",
    ["Garage Door"] = "april_garage_door",
    ["Sleeping Bag"] = "april_sleeping_bag",
    ["Shotgun Turret"] = "april_shotgun_turret",
    ["Auto Turret"] = "april_auto_turret",
    ["Small Battery"] = "april_small_battery",
    ["Medium Battery"] = "april_medium_battery",
    ["Large Battery"] = "april_large_battery",
    ["Solar Panel"] = "april_solar_panel",
    ["Windmill"] = "april_windmill",
}

M.BASE_SKIP_AREAS = {
    Loners = true,
    VMs = true,
    BTRMonumentPaths = true,
    Benches = true,
    Wires = true,
    Ragdolls = true,
    Fire = true,
}

M.BASE_TOGGLES = {
    { id = "april_base_cabinet", label = "Base Cabinet", color = { 1, 0.8, 0, 1 } },
    { id = "april_storage_cabinet", label = "Storage Cabinet", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_small_box", label = "Small Storage Box", color = { 0.55, 0.35, 0.15, 1 } },
    { id = "april_large_box", label = "Large Storage Box", color = { 0.45, 0.3, 0.12, 1 } },
    { id = "april_sleeping_bag", label = "Sleeping Bag", color = { 0.8, 0.2, 0.2, 1 } },
    { id = "april_auto_turret", label = "Auto Turret", color = { 1, 0.2, 0.2, 1 }, ring_id = "april_auto_turret_ring" },
    { id = "april_shotgun_turret", label = "Shotgun Turret", color = { 1, 0.35, 0.2, 1 }, ring_id = "april_shotgun_turret_ring" },
    { id = "april_wooden_door", label = "Wooden Door", color = { 0.5, 0.3, 0.1, 1 } },
    { id = "april_wooden_double_door", label = "Wooden Double Door", color = { 0.55, 0.32, 0.12, 1 } },
    { id = "april_metal_door", label = "Metal Door", color = { 0.5, 0.5, 0.6, 1 } },
    { id = "april_salvaged_door", label = "Salvaged Metal Door", color = { 0.55, 0.52, 0.48, 1 } },
    { id = "april_metal_double_door", label = "Metal Double Door", color = { 0.52, 0.52, 0.58, 1 } },
    { id = "april_steel_door", label = "Steel Door", color = { 0.65, 0.65, 0.72, 1 } },
    { id = "april_steel_double_door", label = "Steel Double Door", color = { 0.62, 0.62, 0.7, 1 } },
    { id = "april_garage_door", label = "Garage Door", color = { 0.4, 0.4, 0.42, 1 } },
    { id = "april_trap_door", label = "Trap Door", color = { 0.48, 0.38, 0.22, 1 } },
    { id = "april_triangle_trap_door", label = "Triangle Trap Door", color = { 0.46, 0.36, 0.2, 1 } },
    { id = "april_small_battery", label = "Small Battery", color = { 0.2, 0.75, 0.35, 1 } },
    { id = "april_medium_battery", label = "Medium Battery", color = { 0.15, 0.65, 0.3, 1 } },
    { id = "april_large_battery", label = "Large Battery", color = { 0.1, 0.55, 0.25, 1 } },
    { id = "april_solar_panel", label = "Solar Panel", color = { 0.2, 0.4, 0.85, 1 } },
    { id = "april_windmill", label = "Windmill", color = { 0.75, 0.85, 0.95, 1 } },
}

function M.toggle_color(list, toggle_id, fallback)
    for _, t in ipairs(list or {}) do
        if t.id == toggle_id then
            return t.color
        end
    end
    return fallback or { 1, 1, 1, 1 }
end

function M.turret_ring_toggle(toggle_id)
    for _, t in ipairs(M.BASE_TOGGLES) do
        if t.id == toggle_id then
            return t.ring_id
        end
    end
    return nil
end

return M

end)()

-- ── ui/combat_labels.lua ──
April._mods["ui.combat_labels"] = (function()
-- Label lists shared by the custom UI catalog (no feature / menu deps).
local M = {}

M.TP_METHODS = {
    "Center",
    "Random Ring",
    "Random Sphere",
    "Offset Grid",
    "Camera Face",
    "Away From Cam",
    "Shuffle Valid",
    "Dense Shuffle",
}

M.SILENT_BONES = {
    "Head",
    "Torso",
    "Left Arm",
    "Right Arm",
    "Left Leg",
    "Right Leg",
    "Closest",
}

return M

end)()

-- ── ui/gs_theme.lua ──
April._mods["ui.gs_theme"] = (function()
-- Gamesense-style palette for the custom April UI (draw API only).
local M = {}

M.BG = { 0.07, 0.07, 0.07, 0.98 }
M.BG_INNER = { 0.09, 0.09, 0.09, 1 }
M.PANEL = { 0.10, 0.10, 0.10, 1 }
M.PANEL_ALT = { 0.11, 0.11, 0.11, 1 }
M.BORDER = { 0.28, 0.28, 0.28, 1 }
M.BORDER_SOFT = { 0.20, 0.20, 0.20, 1 }
M.SIDEBAR = { 0.08, 0.08, 0.08, 1 }
M.SIDEBAR_ACTIVE = { 0.12, 0.12, 0.12, 1 }

M.TEXT = { 0.78, 0.78, 0.78, 1 }
M.TEXT_DIM = { 0.45, 0.45, 0.45, 1 }
M.TEXT_ACTIVE = { 0.92, 0.92, 0.92, 1 }
M.TEXT_TITLE = { 0.72, 0.72, 0.72, 1 }

-- Accent matches the reference (purple / magenta)
M.ACCENT = { 0.75, 0.15, 0.83, 1 }
M.ACCENT_DIM = { 0.45, 0.10, 0.50, 1 }
M.CHECK_OFF = { 0.18, 0.18, 0.18, 1 }
M.SLIDER_BG = { 0.16, 0.16, 0.16, 1 }
M.BUTTON = { 0.16, 0.16, 0.16, 1 }
M.BUTTON_HOVER = { 0.22, 0.22, 0.22, 1 }
M.HOVER = { 0.14, 0.14, 0.14, 1 }

M.RAINBOW = {
    { 0.20, 0.90, 0.95, 1 },
    { 0.55, 0.35, 0.95, 1 },
    { 0.95, 0.85, 0.20, 1 },
    { 0.95, 0.35, 0.55, 1 },
    { 0.35, 0.95, 0.45, 1 },
}

M.FONT = 13
M.FONT_SMALL = 12
M.FONT_TITLE = 12

M.WINDOW_W = 760
M.WINDOW_H = 520
M.SIDEBAR_W = 52
M.TAB_H = 46
M.GROUP_PAD = 10
M.ROW_H = 22
M.CHECK_SIZE = 12
M.SLIDER_H = 8

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

return M

end)()

-- ── ui/gs_input.lua ──
April._mods["ui.gs_input"] = (function()
-- Edge-triggered mouse / key helpers for the custom UI (no menu API).
local M = {}

local prev_keys = {}
local prev_lmb = false
local prev_rmb = false

M.mx = 0
M.my = 0
M.lmb = false
M.rmb = false
M.lmb_click = false
M.rmb_click = false
M.lmb_release = false

function M.mouse()
    if utility and utility.get_mouse_pos then
        local x, y = utility.get_mouse_pos()
        if x and y then
            return x, y
        end
    end
    if input and input.get_screen_center then
        return input.get_screen_center()
    end
    return 0, 0
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
    M.mx, M.my = M.mouse()
    M.lmb = M.key_down(0x01)
    M.rmb = M.key_down(0x02)
    M.lmb_click = M.lmb and not prev_lmb
    M.rmb_click = M.rmb and not prev_rmb
    M.lmb_release = (not M.lmb) and prev_lmb
    prev_lmb = M.lmb
    prev_rmb = M.rmb
end

function M.hover(x, y, w, h)
    return M.mx >= x and M.my >= y and M.mx <= x + w and M.my <= y + h
end

function M.clicked(x, y, w, h)
    return M.lmb_click and M.hover(x, y, w, h)
end

return M

end)()

-- ── ui/gs_state.lua ──
April._mods["ui.gs_state"] = (function()
-- Placeholder state store for the custom UI.
-- Intentionally NOT wired to menu.get / settings — demo values only.
local M = {}

M.values = {}
M.defaults = {}

function M.define(id, default)
    if M.defaults[id] == nil then
        M.defaults[id] = default
    end
    if M.values[id] == nil then
        if type(default) == "table" then
            local copy = {}
            for k, v in pairs(default) do
                copy[k] = v
            end
            M.values[id] = copy
        else
            M.values[id] = default
        end
    end
end

function M.get(id, fallback)
    local v = M.values[id]
    if v == nil then
        return fallback
    end
    return v
end

function M.set(id, value)
    M.values[id] = value
end

function M.toggle(id)
    M.values[id] = not M.get(id, false)
    return M.values[id]
end

function M.reset(id)
    local d = M.defaults[id]
    if d == nil then return end
    if type(d) == "table" then
        local copy = {}
        for k, v in pairs(d) do
            copy[k] = v
        end
        M.values[id] = copy
    else
        M.values[id] = d
    end
end

return M

end)()

-- ── ui/gs_widgets.lua ──
April._mods["ui.gs_widgets"] = (function()
-- Primitive Gamesense-style widgets drawn with the Vector draw API.
local theme = April.require("ui.gs_theme")
local input = April.require("ui.gs_input")
local state = April.require("ui.gs_state")

local M = {}

M.active_slider = nil
M.open_combo = nil
M.open_multi = nil
M.drag_offset_x = 0
M.drag_offset_y = 0
M.dragging_window = false

local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

local function text_w(str, size)
    if draw and draw.get_text_size then
        local w = draw.get_text_size(str, size or theme.FONT)
        if type(w) == "number" then return w end
        if type(w) == "table" then return w[1] or 0 end
    end
    return #(str or "") * 7
end

function M.rect(x, y, w, h, col, filled)
    if not draw then return end
    if filled then
        draw.rect_filled(x, y, w, h, col, 0)
    else
        draw.rect(x, y, w, h, col, 0, 1)
    end
end

function M.text(x, y, str, col, size)
    if draw and draw.text then
        draw.text(x, y, str, col, size or theme.FONT)
    end
end

function M.rainbow_bar(x, y, w, h)
    local segs = 48
    local sw = w / segs
    local t0 = (utility and utility.get_time and utility.get_time() or 0) * 0.15
    for i = 0, segs - 1 do
        local c = theme.rainbow_at(t0 + i / segs)
        M.rect(x + i * sw, y, sw + 0.5, h, c, true)
    end
end

function M.group_box(x, y, w, h, title)
    M.rect(x, y, w, h, theme.PANEL, true)
    M.rect(x, y, w, h, theme.BORDER, false)

    local label = " " .. title .. " "
    local tw = text_w(label, theme.FONT_TITLE)
    local tx = x + 10
    M.rect(tx, y - 1, tw, 3, theme.PANEL, true)
    M.text(tx, y - 7, label, theme.TEXT_TITLE, theme.FONT_TITLE)
end

function M.checkbox(x, y, w, id, label, opts)
    opts = opts or {}
    state.define(id, opts.default == true)
    local on = state.get(id, false)
    local h = theme.ROW_H
    local hovered = input.hover(x, y, w, h)

    if hovered then
        M.rect(x, y, w, h, theme.HOVER, true)
    end

    local bx = x + 4
    local by = y + (h - theme.CHECK_SIZE) * 0.5
    M.rect(bx, by, theme.CHECK_SIZE, theme.CHECK_SIZE, theme.CHECK_OFF, true)
    M.rect(bx, by, theme.CHECK_SIZE, theme.CHECK_SIZE, theme.BORDER_SOFT, false)
    if on then
        M.rect(bx + 2, by + 2, theme.CHECK_SIZE - 4, theme.CHECK_SIZE - 4, theme.ACCENT, true)
    end

    local col = on and theme.TEXT_ACTIVE or theme.TEXT
    M.text(bx + theme.CHECK_SIZE + 8, y + 3, label, col, theme.FONT)

    if opts.color then
        local cx = x + w - 18
        M.rect(cx, by, 12, 12, opts.color, true)
        M.rect(cx, by, 12, 12, theme.BORDER, false)
    end

    if input.clicked(x, y, w, h) then
        state.toggle(id)
        if opts.on_change then opts.on_change(state.get(id)) end
    end

    return h
end

function M.slider(x, y, w, id, label, minv, maxv, default, opts)
    opts = opts or {}
    local is_float = opts.float == true
    state.define(id, default)
    local val = tonumber(state.get(id, default)) or default
    local h = theme.ROW_H + 10
    local hovered = input.hover(x, y, w, h)

    if hovered then
        M.rect(x, y, w, h, theme.HOVER, true)
    end

    local fmt = opts.fmt or (is_float and "%.2f" or "%d")
    local shown = string.format(fmt, val)
    M.text(x + 4, y + 2, label, theme.TEXT, theme.FONT)
    local vw = text_w(shown, theme.FONT_SMALL)
    M.text(x + w - vw - 6, y + 2, shown, theme.TEXT_DIM, theme.FONT_SMALL)

    local sx = x + 4
    local sy = y + 16
    local sw = w - 8
    M.rect(sx, sy, sw, theme.SLIDER_H, theme.SLIDER_BG, true)

    local t = 0
    if maxv > minv then
        t = clamp((val - minv) / (maxv - minv), 0, 1)
    end
    if t > 0 then
        M.rect(sx, sy, sw * t, theme.SLIDER_H, theme.ACCENT, true)
    end
    M.rect(sx, sy, sw, theme.SLIDER_H, theme.BORDER_SOFT, false)

    local hot = input.hover(sx, sy - 4, sw, theme.SLIDER_H + 8)
    if (input.lmb_click and hot) or (input.lmb and M.active_slider == id) then
        M.active_slider = id
        local nt = clamp((input.mx - sx) / sw, 0, 1)
        local nv = minv + (maxv - minv) * nt
        if not is_float then
            nv = math.floor(nv + 0.5)
        end
        state.set(id, nv)
    elseif M.active_slider == id and not input.lmb then
        M.active_slider = nil
    end

    return h
end

function M.combo(x, y, w, id, label, options, default_idx)
    state.define(id, default_idx or 0)
    local idx = tonumber(state.get(id, default_idx or 0)) or 0
    local h = theme.ROW_H + 18
    local open = M.open_combo == id

    M.text(x + 4, y + 1, label, theme.TEXT, theme.FONT)

    local bx = x + 4
    local by = y + 14
    local bw = w - 8
    local bh = 18
    local hovered = input.hover(bx, by, bw, bh)
    M.rect(bx, by, bw, bh, hovered and theme.BUTTON_HOVER or theme.BUTTON, true)
    M.rect(bx, by, bw, bh, theme.BORDER_SOFT, false)

    local cur = options[idx + 1] or options[1] or "—"
    M.text(bx + 6, by + 2, tostring(cur), theme.TEXT_ACTIVE, theme.FONT_SMALL)
    M.text(bx + bw - 14, by + 2, "v", theme.TEXT_DIM, theme.FONT_SMALL)

    if input.clicked(bx, by, bw, bh) then
        if open then
            M.open_combo = nil
        else
            M.open_combo = id
            M.open_multi = nil
        end
    end

    local used = h
    if open then
        local list_h = #options * 18
        M.rect(bx, by + bh, bw, list_h, theme.BG_INNER, true)
        M.rect(bx, by + bh, bw, list_h, theme.BORDER, false)
        for i, opt in ipairs(options) do
            local iy = by + bh + (i - 1) * 18
            local ihov = input.hover(bx, iy, bw, 18)
            if ihov then
                M.rect(bx, iy, bw, 18, theme.HOVER, true)
            end
            local col = (i - 1 == idx) and theme.ACCENT or theme.TEXT
            M.text(bx + 6, iy + 2, tostring(opt), col, theme.FONT_SMALL)
            if input.clicked(bx, iy, bw, 18) then
                state.set(id, i - 1)
                M.open_combo = nil
            end
        end
        used = h + list_h
    end
    return used
end

function M.multi(x, y, w, id, label, options, defaults)
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

    local h = theme.ROW_H + 18
    local open = M.open_multi == id
    M.text(x + 4, y + 1, label, theme.TEXT, theme.FONT)

    local bx = x + 4
    local by = y + 14
    local bw = w - 8
    local bh = 18
    local hovered = input.hover(bx, by, bw, bh)
    M.rect(bx, by, bw, bh, hovered and theme.BUTTON_HOVER or theme.BUTTON, true)
    M.rect(bx, by, bw, bh, theme.BORDER_SOFT, false)

    local parts = {}
    for i, opt in ipairs(options) do
        if vals[i] then parts[#parts + 1] = opt end
    end
    local summary = (#parts > 0) and table.concat(parts, ", ") or "None"
    if #summary > 28 then summary = summary:sub(1, 26) .. ".." end
    M.text(bx + 6, by + 2, summary, theme.TEXT_ACTIVE, theme.FONT_SMALL)

    if input.clicked(bx, by, bw, bh) then
        if open then
            M.open_multi = nil
        else
            M.open_multi = id
            M.open_combo = nil
        end
    end

    local used = h
    if open then
        local list_h = #options * 18
        M.rect(bx, by + bh, bw, list_h, theme.BG_INNER, true)
        M.rect(bx, by + bh, bw, list_h, theme.BORDER, false)
        for i, opt in ipairs(options) do
            local iy = by + bh + (i - 1) * 18
            local on = vals[i] == true
            local cx = bx + 4
            local cy = iy + 3
            M.rect(cx, cy, 12, 12, theme.CHECK_OFF, true)
            if on then
                M.rect(cx + 2, cy + 2, 8, 8, theme.ACCENT, true)
            end
            M.text(cx + 18, iy + 2, tostring(opt), on and theme.TEXT_ACTIVE or theme.TEXT, theme.FONT_SMALL)
            if input.clicked(bx, iy, bw, 18) then
                vals[i] = not on
                state.set(id, vals)
            end
        end
        used = h + list_h
    end
    return used
end

function M.button(x, y, w, id, label, opts)
    opts = opts or {}
    local h = 22
    local hovered = input.hover(x, y, w, h)
    M.rect(x, y, w, h, hovered and theme.BUTTON_HOVER or theme.BUTTON, true)
    M.rect(x, y, w, h, theme.BORDER_SOFT, false)
    local tw = text_w(label, theme.FONT_SMALL)
    M.text(x + (w - tw) * 0.5, y + 4, label, theme.TEXT_ACTIVE, theme.FONT_SMALL)

    if input.clicked(x, y, w, h) then
        state.set(id .. "_pulse", true)
        if opts.on_click then opts.on_click() end
    end
    return h + 2
end

function M.label(x, y, w, text, dim)
    M.text(x + 4, y + 3, text, dim and theme.TEXT_DIM or theme.TEXT_TITLE, theme.FONT_SMALL)
    return theme.ROW_H - 2
end

function M.separator(x, y, w)
    M.rect(x + 4, y + 8, w - 8, 1, theme.BORDER_SOFT, true)
    return 14
end

function M.keybind(x, y, w, id, label, default_on)
    -- Placeholder: checkbox + fake keychip (not wired to utility.on_key yet)
    local h = M.checkbox(x, y, w - 56, id, label, { default = default_on })
    local kx = x + w - 52
    local ky = y + 3
    M.rect(kx, ky, 48, 16, theme.BUTTON, true)
    M.rect(kx, ky, 48, 16, theme.BORDER_SOFT, false)
    M.text(kx + 8, ky + 1, "[none]", theme.TEXT_DIM, theme.FONT_SMALL)
    return h
end

function M.color_row(x, y, w, id, label, default_col)
    state.define(id, default_col or { 1, 1, 1, 1 })
    local col = state.get(id, default_col)
    local h = theme.ROW_H
    M.text(x + 4, y + 3, label, theme.TEXT, theme.FONT)
    local cx = x + w - 18
    M.rect(cx, y + 4, 12, 12, col, true)
    M.rect(cx, y + 4, 12, 12, theme.BORDER, false)
    return h
end

function M.input_row(x, y, w, id, label, default)
    state.define(id, default or "")
    local val = tostring(state.get(id, default or ""))
    local h = theme.ROW_H + 18
    M.text(x + 4, y + 1, label, theme.TEXT, theme.FONT)
    local bx = x + 4
    local by = y + 14
    local bw = w - 8
    M.rect(bx, by, bw, 18, theme.BUTTON, true)
    M.rect(bx, by, bw, 18, theme.BORDER_SOFT, false)
    local shown = val ~= "" and val or "…"
    M.text(bx + 6, by + 2, shown, theme.TEXT_DIM, theme.FONT_SMALL)
    return h
end

function M.draw_item(item, x, y, w)
    local t = item.type
    if t == "checkbox" then
        return M.checkbox(x, y, w, item.id, item.label, item)
    elseif t == "keybind" then
        return M.keybind(x, y, w, item.id, item.label, item.default)
    elseif t == "slider" then
        return M.slider(x, y, w, item.id, item.label, item.min, item.max, item.default, item)
    elseif t == "combo" then
        return M.combo(x, y, w, item.id, item.label, item.options, item.default)
    elseif t == "multi" then
        return M.multi(x, y, w, item.id, item.label, item.options, item.defaults)
    elseif t == "button" then
        return M.button(x, y, w - 8, item.id, item.label, item)
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

-- ── ui/catalog.lua ──
April._mods["ui.catalog"] = (function()
--[[
  Placeholder catalog mirroring every menu control from src/features/*.
  Used only by the custom Gamesense UI — not registered with Vector menu.*.
]]

local maps = April.require("game.esp_maps")
local combat_menu = April.require("ui.combat_labels")

local M = {}

local function cb(id, label, default, color)
    return { type = "checkbox", id = id, label = label, default = default == true, color = color }
end

local function kb(id, label, default)
    return { type = "keybind", id = id, label = label, default = default == true }
end

local function sl(id, label, minv, maxv, default, float)
    return {
        type = "slider",
        id = id,
        label = label,
        min = minv,
        max = maxv,
        default = default,
        float = float == true,
        fmt = float and "%.2f" or "%d",
    }
end

local function combo(id, label, options, default)
    return { type = "combo", id = id, label = label, options = options, default = default or 0 }
end

local function multi(id, label, options, defaults)
    return { type = "multi", id = id, label = label, options = options, defaults = defaults }
end

local function btn(id, label)
    return { type = "button", id = id, label = label }
end

local function sep()
    return { type = "separator" }
end

local function label(text, dim)
    return { type = "label", label = text, dim = dim }
end

local function color(id, label_text, default)
    return { type = "color", id = id, label = label_text, default = default }
end

local function input(id, label_text, default)
    return { type = "input", id = id, label = label_text, default = default or "" }
end

local function from_toggles(list)
    local out = {}
    for _, t in ipairs(list) do
        out[#out + 1] = cb(t.id, t.label, false, t.color)
        if t.ring_id then
            out[#out + 1] = cb(t.ring_id, t.label .. " Range Ring", false)
        end
    end
    return out
end

local function append(dst, src)
    for _, v in ipairs(src) do
        dst[#dst + 1] = v
    end
end

-- Sidebar tabs (Gamesense-style icon letters)
M.TABS = {
    { id = "aim", glyph = "A", title = "Aimbot" },
    { id = "visuals", glyph = "V", title = "Visuals" },
    { id = "world", glyph = "W", title = "World" },
    { id = "guns", glyph = "G", title = "Gun Mods" },
    { id = "misc", glyph = "M", title = "Misc" },
    { id = "radar", glyph = "R", title = "Radar" },
    { id = "config", glyph = "C", title = "Config" },
}

local function build_aim()
    local left = {
        title = "Silent Aim",
        items = {
            label("features/combat/aimbot.lua", true),
            kb("april_silent_aim", "Enable Silent Aim", false),
            sep(),
            label("Targeting", false),
            combo("april_silent_target_type", "Target Type", { "Crosshair", "Distance" }, 0),
            combo("april_silent_bone", "Hitbox", combat_menu.SILENT_BONES, 0),
            multi("april_silent_targets", "Aim At", {
                "Players", "NPCs", "NPC Soldiers", "NPC Bosses",
            }, { true, false, true, true }),
            multi("april_silent_filters", "Filters", {
                "Health Check", "Visible Only", "Team Check",
                "Skip Safezone", "Whitelist", "Skip Downed",
            }, { true, false, true, true, false, true }),
            input("april_silent_whitelist_ids", "Whitelist IDs", ""),
            btn("april_silent_whitelist_clear", "Clear Whitelist"),
            sl("april_silent_max_dist", "Max Distance (m)", 50, 2000, 500),
        },
    }

    local right = {
        title = "Aim / Bullet",
        items = {
            label("Aim", false),
            multi("april_silent_options", "Options", { "Sticky Target" }, { false }),
            sl("april_silent_hit_chance", "Hit Chance %", 1, 100, 100),
            sl("april_silent_fov", "FOV Radius (px)", 20, 600, 150),
            cb("april_silent_hitscan", "Hitscan", false),
            sep(),
            label("Bullet TP", false),
            cb("april_silent_bullet_tp", "Bullet TP", false),
            combo("april_silent_tp_method", "TP Method", combat_menu.TP_METHODS, 0),
            cb("april_silent_tp_ray_vis", "Visualize Ray Path", false, { 0.95, 0.45, 1, 0.9 }),
            sep(),
            label("Bullet Manip", false),
            cb("april_silent_bullet_manip", "Silent Bullet Manip", false),
            sl("april_silent_manip_dist", "Manip Distance", 0.1, 1, 1, true),
            cb("april_silent_manip_extend", "Extend", false),
            sl("april_silent_manip_extend_dist", "Extra Scan Distance", 1, 7, 7, true),
            cb("april_silent_manip_status", "Manip Status Bar", false),
            cb("april_silent_manip_peek_vis", "Manip Peek Visual", false),
            sep(),
            label("Visuals", false),
            cb("april_silent_draw_fov", "FOV Circle", false, { 0.55, 0.2, 1, 1 }),
            combo("april_silent_fov_style", "FOV Style", { "Outline", "Filled Circle" }, 1),
            cb("april_silent_target_line", "Target Line", false, { 1, 0.25, 0.25, 1 }),
        },
    }
    return { left, right }
end

local function build_visuals()
    local left = {
        title = "Player ESP",
        items = {
            label("features/visuals/player_esp.lua", true),
            kb("april_player_enabled", "Player ESP", false),
            combo("april_player_box_mode", "Player Box", { "None", "2D", "Corner" }, 1),
            cb("april_player_health", "Player Health Bar", true),
            cb("april_player_skeleton", "Player Skeleton", false, { 1, 1, 1, 0.92 }),
            cb("april_player_offscreen", "Player Offscreen Arrows", false, { 1, 0.35, 0.35, 1 }),
            cb("april_player_show_name", "Player Name", true),
            cb("april_player_clan_tag", "Player Clan Tag", true),
            cb("april_player_clan_color", "Player Color By Clan", false),
            cb("april_player_show_distance", "Player Distance", true),
            cb("april_player_show_weapon", "Player Weapon", false),
            cb("april_player_health_text", "Player Health Text", false),
            multi("april_player_esp_filters", "ESP Filters", {
                "Team Check", "Skip Safezone", "Skip Downed",
            }, { true, true, true }),
            multi("april_player_esp_flags", "ESP Flags", {
                "Downed", "Safezone", "VIP", "Staff", "Reviving",
            }, { true, true, true, true, true }),
            cb("april_player_chams", "Player Engine Chams", false),
            combo("april_player_chams_mode", "Player Chams Mode", { "Flat", "Fresnel", "Glow" }, 0),
            color("april_player_chams_color", "Player Chams Color", { 1, 0.35, 0.35, 1 }),
            sl("april_player_range", "Player Range", 50, 2000, 500),
        },
    }

    local right = {
        title = "Overlays",
        items = {
            label("Target Overlay", false),
            kb("april_target_overlay", "Target Overlay", false),
            sl("april_target_overlay_gear_size", "Gear Icon Size", 32, 64, 48),
            sl("april_target_overlay_top", "Top Offset", 48, 160, 88),
            sep(),
            label("Crosshair", false),
            cb("april_crosshair_enabled", "Custom Crosshair", false),
            cb("april_crosshair_color", "Crosshair Color", true, { 0, 1, 0, 1 }),
            cb("april_crosshair_dot", "Center Dot", false, { 1, 1, 1, 1 }),
            cb("april_crosshair_outline", "Crosshair Outline", true, { 0, 0, 0, 1 }),
            cb("april_crosshair_rainbow", "Rainbow Crosshair", false),
            sl("april_crosshair_rainbow_speed", "Rainbow Speed", 1, 100, 10),
            sl("april_crosshair_size", "Crosshair Size", 1, 50, 10),
            sl("april_crosshair_gap", "Crosshair Gap", 0, 20, 5),
            sl("april_crosshair_thickness", "Crosshair Thickness", 1, 10, 2),
            sep(),
            label("Hitmarkers", false),
            cb("april_hitmarkers", "Hitmarkers", false, { 1, 1, 1, 1 }),
            cb("april_hitmarkers_head", "Headshot Color", true, { 1, 0.2, 0.2, 1 }),
            sl("april_hitmarkers_size", "Hitmarker Size", 4, 28, 10),
            sl("april_hitmarkers_gap", "Hitmarker Gap", 0, 12, 3),
            sl("april_hitmarkers_life", "Hitmarker Life (ms)", 80, 800, 280),
            sl("april_hitmarkers_thick", "Hitmarker Thickness", 1, 4, 2),
            sep(),
            label("Bullet Tracers", false),
            cb("april_bullet_tracers", "Bullet Tracers", false, { 1, 0.85, 0.2, 1 }),
            color("april_bullet_tracers_color2", "Tracer Glow", { 1, 0.4, 0.1, 0.6 }),
            sl("april_bullet_tracers_thick", "Tracer Thickness", 1, 6, 2),
            sl("april_bullet_tracers_life", "Tracer Life (ms)", 100, 1500, 450),
        },
    }
    return { left, right }
end

local function build_world()
    local resources = {
        title = "Resources",
        items = {
            label("features/world/world_esp.lua", true),
            kb("april_world_enabled", "Resource ESP", false),
        },
    }
    append(resources.items, from_toggles(maps.WORLD_TOGGLES))
    append(resources.items, {
        cb("april_world_boxes", "Resource 3D Boxes", false),
        cb("april_world_show_name", "Resource Show Name", true),
        cb("april_world_show_distance", "Resource Show Distance", true),
        sl("april_world_range", "Resource Range", 50, 2000, 500),
        multi("april_world_chams", "Resource Chams", (function()
            local labels = {}
            for i, t in ipairs(maps.WORLD_TOGGLES) do labels[i] = t.label end
            return labels
        end)(), {}),
        combo("april_world_chams_mode", "Resource Chams Mode", { "Flat", "Fresnel", "Glow" }, 0),
        color("april_world_chams_color", "Resource Chams Color", { 0.4, 1, 0.4, 1 }),
    })

    local loot = {
        title = "Loot",
        items = {
            label("features/world/loot_esp.lua", true),
            kb("april_loot_enabled", "Loot ESP", false),
        },
    }
    append(loot.items, from_toggles(maps.LOOT_TOGGLES))
    append(loot.items, {
        cb("april_loot_boxes", "Loot 3D Boxes", false),
        cb("april_loot_show_name", "Loot Show Name", true),
        cb("april_loot_show_distance", "Loot Show Distance", true),
        sl("april_loot_range", "Loot Range", 50, 2000, 300),
        multi("april_loot_chams", "Loot Chams", (function()
            local labels = {}
            for i, t in ipairs(maps.LOOT_TOGGLES) do labels[i] = t.label end
            return labels
        end)(), {}),
        combo("april_loot_chams_mode", "Loot Chams Mode", { "Flat", "Fresnel", "Glow" }, 0),
        color("april_loot_chams_color", "Loot Chams Color", { 1, 0.85, 0.35, 1 }),
    })

    local bases = {
        title = "Bases",
        items = {
            label("features/world/base_esp.lua", true),
            kb("april_base_enabled", "Base ESP", false),
        },
    }
    append(bases.items, from_toggles(maps.BASE_TOGGLES))
    append(bases.items, {
        cb("april_base_boxes", "Base 3D Boxes", false),
        cb("april_base_show_name", "Base Show Name", true),
        cb("april_base_show_distance", "Base Show Distance", false),
        sl("april_base_range", "Base Range", 50, 500, 150),
        multi("april_base_chams", "Base Chams", (function()
            local labels = {}
            for i, t in ipairs(maps.BASE_TOGGLES) do labels[i] = t.label end
            return labels
        end)(), {}),
        combo("april_base_chams_mode", "Base Chams Mode", { "Flat", "Fresnel", "Glow" }, 0),
        color("april_base_chams_color", "Base Chams Color", { 0.55, 0.55, 1, 1 }),
    })

    local npcs = {
        title = "NPCs",
        items = {
            label("features/world/npc_esp.lua", true),
            kb("april_npc_enabled", "NPC ESP", false),
            cb("april_npc_soldiers", "Soldiers", false, { 1, 0.3, 0.3, 1 }),
            cb("april_npc_bosses", "Bosses (Bruno / Boris / Brutus)", false, { 1, 0.5, 0.1, 1 }),
            cb("april_npc_health", "NPC Health Bar", false),
            cb("april_npc_skeleton", "NPC Skeleton", false, { 1, 1, 1, 0.85 }),
            cb("april_npc_offscreen", "NPC Offscreen Arrows", false, { 1, 0.3, 0.3, 1 }),
            cb("april_npc_show_name", "NPC Show Name", true),
            cb("april_npc_show_distance", "NPC Show Distance", true),
            sl("april_npc_range", "NPC Range", 50, 2000, 500),
        },
    }

    -- Two columns: left resources+npcs, right loot+bases (user scrolls each)
    return { resources, loot, npcs, bases }
end

local function build_guns()
    return {
        {
            title = "Gun Mods",
            items = {
                label("features/combat/gun_mods.lua", true),
                kb("april_gunmods_enabled", "Enable Gun Mods", false),
                sep(),
                label("Apply", false),
                input("april_gm_held_weapon", "Held Weapon", "—"),
                combo("april_gm_mode", "Apply Mode", { "Profile Based", "Global" }, 0),
                combo("april_gm_weapon_select", "Edit Weapon", { "—", "AK", "M4", "MP5" }, 0),
                sep(),
                label("Modifiers", false),
                cb("april_gm_recoil", "No Recoil", false),
                sl("april_gm_recoil_pct", "Recoil Reduction %", 0, 100, 100),
                cb("april_gm_spread", "No Spread", false),
                sl("april_gm_spread_pct", "Spread Reduction %", 0, 100, 100),
                cb("april_gm_sway", "No Sway", false),
                cb("april_gm_fire_rate", "Fire Rate", false),
                sl("april_gm_fire_rate_mult", "Fire Rate Multiplier", 1, 3, 1.5, true),
                cb("april_gm_speed", "Bullet Speed", false),
                sl("april_gm_speed_mult", "Speed Mult", 1, 100, 100),
                cb("april_gm_range", "Gun Range", false),
                sl("april_gm_range_mult", "Range Mult", 1, 20, 10),
                cb("april_gm_double_tap", "Double Tap", false),
            },
        },
        {
            title = "Profiles",
            items = {
                btn("april_gm_save", "Save Profile"),
                btn("april_gm_clear", "Clear Saved Profile"),
                sep(),
                label("Placeholder — not wired to GC yet", true),
            },
        },
    }
end

local function build_misc()
    return {
        {
            title = "Movement",
            items = {
                label("features/movement/exploits.lua", true),
                kb("april_noclip_enabled", "Fly", false),
                sl("april_noclip_speed", "Fly Speed", 1, 20, 1),
                kb("april_slowfall_enabled", "Slowfall", false),
                sl("april_slowfall_speed", "Fall Speed", 1, 50, 5),
                sep(),
                label("features/movement/desync.lua", true),
                kb("april_desync_enabled", "Desync", false),
                cb("april_desync_autosend", "Desync Auto Send", false),
                sl("april_desync_autosend_len", "Desync Send Threshold", 0, 1, 0.3, true),
                cb("april_desync_visualizer", "Desync Visualize", false, { 0.2, 0.85, 1, 0.9 }),
                sep(),
                label("features/movement/fling.lua", true),
                kb("april_fling_enabled", "Fling", false),
                sl("april_fling_fov", "Fling FOV", 20, 600, 150),
                sl("april_fling_duration", "Fling Duration", 2, 10, 2),
            },
        },
        {
            title = "Utility",
            items = {
                label("features/combat/perfect_farm.lua", true),
                kb("april_farm_helper", "Farm Helper", false),
                cb("april_farm_silent", "Silent Farm", false),
                sl("april_farm_radius", "Farm Range (studs)", 1, 15, 5),
                sl("april_farm_smooth", "Camera Smoothness", 1, 30, 8),
                sep(),
                label("features/movement/bullet_manip.lua", true),
                kb("april_bullet_manip_enabled", "Bullet Manip (misc)", false),
                sl("april_bullet_manip_range", "Bullet Target Range", 50, 500, 250),
                sl("april_bullet_manip_speed", "Bullet Peek Speed", 4, 40, 18),
                cb("april_bullet_manip_debug", "Bullet Debug Overlay", false),
                cb("april_bullet_manip_console", "Bullet Debug Console", false),
                cb("april_bullet_manip_vis", "Bullet Visualizer", false),
                sl("april_bullet_manip_vis_size", "Bullet Vis Size", 0.5, 4, 1.2, true),
                cb("april_bullet_manip_vis_link", "Bullet Show Link Line", false),
                cb("april_bullet_manip_vis_labels", "Bullet Show Labels", false),
                cb("april_bullet_manip_vis_peek", "Bullet Show Peek Point", false),
                sep(),
                label("features/utility/*", true),
                cb("april_anti_afk", "Anti AFK", false),
                cb("april_mod_checker_enabled", "Mod Checker", false),
                sl("april_mod_checker_interval", "Scan Interval (ms)", 1000, 10000, 2500),
                sl("april_mod_checker_x", "Mod Panel Pos X", 0, 1920, 1600),
                sl("april_mod_checker_y", "Mod Panel Pos Y", 0, 1080, 72),
                sl("april_mod_checker_w", "Mod Panel Width", 180, 420, 260),
                sep(),
                cb("april_keybinds_enabled", "Keybind Viewer", false),
                cb("april_keybinds_active_only", "Only Show Active", false),
                cb("april_keybinds_show_unbound", "Show Unbound", true),
                cb("april_keybinds_show_mode", "Show Bind Mode", true),
                sl("april_keybinds_x", "Keybinds Pos X", 0, 1920, 16),
                sl("april_keybinds_y", "Keybinds Pos Y", 0, 1080, 280),
                sl("april_keybinds_w", "Keybinds Width", 160, 480, 260),
            },
        },
    }
end

local function build_radar()
    return {
        {
            title = "Tactical Map",
            items = {
                label("features/radar/tactical_map.lua", true),
                kb("april_map_enabled", "Tactical Map", false),
                cb("april_map_show_players", "Radar Show Players", true),
                cb("april_map_show_npcs", "Radar Show NPCs", false),
                cb("april_map_show_loot", "Radar Show Loot", true),
                cb("april_map_show_world", "Radar Show Resources", true),
                cb("april_map_show_base", "Radar Show Base Parts", false),
                cb("april_map_show_waypoints", "Radar Show Waypoints", true),
                cb("april_map_labels", "Radar Show Labels", false),
                color("april_map_bg", "Radar Background", { 0.05, 0.05, 0.07, 0.85 }),
                color("april_map_grid", "Radar Grid", { 0.25, 0.25, 0.3, 0.5 }),
                color("april_map_player_col", "Radar Players Color", { 1, 0.25, 0.25, 1 }),
                color("april_map_npc_col", "Radar NPCs Color", { 1, 0.55, 0.15, 1 }),
                color("april_map_loot_col", "Radar Loot Color", { 1, 0.85, 0.35, 1 }),
                color("april_map_world_col", "Radar Resources Color", { 0.35, 0.9, 0.35, 1 }),
                color("april_map_base_col", "Radar Base Color", { 0.55, 0.55, 1, 1 }),
                color("april_map_wp_col", "Radar Waypoints Color", { 0.3, 0.9, 1, 1 }),
                color("april_map_local", "Radar You Color", { 0.3, 0.9, 1, 1 }),
                sl("april_map_zoom", "Radar Zoom Level", 0.05, 5, 1, true),
                sl("april_map_size", "Radar Size", 140, 420, 240),
                sl("april_map_icon_scale", "Radar Blip Size", 2, 6, 3),
            },
        },
        {
            title = "Waypoints",
            items = {
                label("features/radar/waypoints.lua", true),
                kb("april_waypoints_enabled", "Waypoints", false),
                cb("april_wp_dist", "Waypoint Show Distance", false),
                cb("april_wp_beacon", "Beacon Pillar", false),
                sl("april_wp_beacon_h", "Beacon Height", 20, 200, 90),
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
    return {
        {
            title = "Settings",
            items = {
                label("Custom UI (placeholder)", true),
                label("Menu key: INSERT", false),
                color("april_ui_accent", "Menu color", { 0.75, 0.15, 0.83, 1 }),
                cb("april_ui_placeholder_note", "Demo values only (not wired)", true),
                sep(),
                label("features/utility/config.lua", true),
                input("april_cfg_profile_name", "Profile Name", "Default"),
                sl("april_cfg_slot", "Active Slot (1-5)", 1, 5, 1),
                btn("april_cfg_save", "Save to Active Slot"),
                btn("april_cfg_load", "Load Active Slot"),
                btn("april_cfg_delete", "Delete Active Slot"),
                cb("april_cfg_autoload", "Autoload on Start", false),
                input("april_cfg_autoload_profile", "Autoload Profile Name", ""),
                sl("april_cfg_autoload_slot", "Autoload Slot", 1, 5, 1),
                sl("april_esp_text_size", "ESP Text Size", 8, 24, 13),
                btn("april_reload_modules", "Reload Game Modules"),
            },
        },
        {
            title = "Other",
            items = {
                combo("april_ui_cfg_preset", "Config Preset", { "Rage", "Legit", "Visuals", "Default" }, 0),
                btn("april_ui_load_cfg", "Load config"),
                btn("april_ui_save_cfg", "Save config"),
                btn("april_ui_reset_cfg", "Reset config"),
                btn("april_ui_import", "Import from clipboard"),
                btn("april_ui_export", "Export to clipboard"),
                btn("april_ui_reset_layout", "Reset menu layout"),
                btn("april_ui_unload", "Unload (placeholder)"),
                sep(),
                label("Vector built-in menu still loads.", true),
                label("This UI is draw/input only.", true),
            },
        },
    }
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

-- ── ui/custom_menu.lua ──
April._mods["ui.custom_menu"] = (function()
--[[
  Gamesense-style custom menu for April.

  - Drawn entirely with draw.* + input/utility mouse
  - Does NOT call menu.add_* / menu.get
  - Placeholder controls for every feature in catalog.lua
  - Toggle with INSERT (0x2D). Drag title bar to move.
]]

local theme = April.require("ui.gs_theme")
local gin = April.require("ui.gs_input")
local widgets = April.require("ui.gs_widgets")
local catalog = April.require("ui.catalog")
local state = April.require("ui.gs_state")

local M = {}

local TOGGLE_VK = 0x2D -- INSERT
local open = true
local tab_index = 1
local win_x, win_y = 80, 80
local scroll = { left = 0, right = 0 }
local scroll_drag = nil -- "left" | "right"

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

local function content_height(items, col_w)
    local h = 0
    for _, item in ipairs(items) do
        -- approximate; open dropdowns add extra in draw pass
        if item.type == "slider" or item.type == "combo" or item.type == "multi" or item.type == "input" then
            h = h + theme.ROW_H + 18
        elseif item.type == "separator" then
            h = h + 14
        elseif item.type == "button" then
            h = h + 24
        else
            h = h + theme.ROW_H
        end
    end
    return h + 8
end

local function draw_sidebar(x, y, h)
    widgets.rect(x, y, theme.SIDEBAR_W, h, theme.SIDEBAR, true)
    widgets.rect(x + theme.SIDEBAR_W - 1, y, 1, h, theme.BORDER_SOFT, true)

    for i, tab in ipairs(catalog.TABS) do
        local ty = y + 8 + (i - 1) * theme.TAB_H
        local active = i == tab_index
        if active then
            widgets.rect(x, ty, theme.SIDEBAR_W - 1, theme.TAB_H - 4, theme.SIDEBAR_ACTIVE, true)
            widgets.rect(x, ty, 2, theme.TAB_H - 4, theme.ACCENT, true)
        elseif gin.hover(x, ty, theme.SIDEBAR_W, theme.TAB_H - 4) then
            widgets.rect(x, ty, theme.SIDEBAR_W - 1, theme.TAB_H - 4, theme.HOVER, true)
        end

        local col = active and theme.ACCENT or theme.TEXT_DIM
        local tw = 8
        if draw and draw.get_text_size then
            local a = draw.get_text_size(tab.glyph, 16)
            if type(a) == "number" then tw = a end
        end
        widgets.text(x + (theme.SIDEBAR_W - tw) * 0.5 - 2, ty + 12, tab.glyph, col, 16)

        if gin.clicked(x, ty, theme.SIDEBAR_W, theme.TAB_H - 4) then
            tab_index = i
            scroll.left = 0
            scroll.right = 0
            widgets.open_combo = nil
            widgets.open_multi = nil
        end
    end
end

local function draw_scrollbar(x, y, h, content_h, scroll_key)
    if content_h <= h then
        scroll[scroll_key] = 0
        return
    end
    local track_h = h
    local thumb_h = math.max(24, track_h * (h / content_h))
    local max_scroll = content_h - h
    local t = scroll[scroll_key] / max_scroll
    local thumb_y = y + t * (track_h - thumb_h)

    widgets.rect(x, y, 4, track_h, theme.SLIDER_BG, true)
    widgets.rect(x, thumb_y, 4, thumb_h, theme.ACCENT_DIM, true)

    if gin.lmb_click and gin.hover(x - 2, y, 10, track_h) then
        scroll_drag = scroll_key
    end
    if scroll_drag == scroll_key and gin.lmb then
        local rel = (gin.my - y - thumb_h * 0.5) / math.max(1, track_h - thumb_h)
        if rel < 0 then rel = 0 end
        if rel > 1 then rel = 1 end
        scroll[scroll_key] = rel * max_scroll
    elseif scroll_drag == scroll_key and not gin.lmb then
        scroll_drag = nil
    end

end

local function handle_page_scroll(content_x, body_y, col_w, body_h)
    local left_hot = gin.hover(content_x, body_y, col_w + 8, body_h)
    local right_hot = gin.hover(content_x + col_w + 12, body_y, col_w + 8, body_h)
    if gin.key_pressed(0x21) then -- Page Up
        local key = right_hot and not left_hot and "right" or "left"
        scroll[key] = math.max(0, scroll[key] - 80)
    elseif gin.key_pressed(0x22) then -- Page Down
        local key = right_hot and not left_hot and "right" or "left"
        scroll[key] = scroll[key] + 80
    end
end

local function draw_group_column(groups, x, y, w, h, scroll_key)
    local pad = theme.GROUP_PAD
    local gy = y + pad - scroll[scroll_key]
    local total = 0

    for _, group in ipairs(groups) do
        local items = group.items or {}
        local inner_h = content_height(items, w - pad * 2)
        local box_h = math.min(inner_h + 18, math.max(80, #items * 14 + 40))
        -- Use measured height from a first pass-ish: grow with items
        box_h = inner_h + 22

        if gy + box_h > y and gy < y + h then
            widgets.group_box(x, gy, w, box_h, group.title)
            local iy = gy + 14
            local ix = x + 4
            local iw = w - 12
            for _, item in ipairs(items) do
                if iy + 4 > y and iy < y + h then
                    local used = widgets.draw_item(item, ix, iy, iw)
                    iy = iy + used
                else
                    -- still advance layout for scroll height consistency
                    local used = 0
                    if item.type == "slider" or item.type == "combo" or item.type == "multi" or item.type == "input" then
                        used = theme.ROW_H + 18
                    elseif item.type == "separator" then
                        used = 14
                    elseif item.type == "button" then
                        used = 24
                    else
                        used = theme.ROW_H
                    end
                    iy = iy + used
                end
            end
        end

        total = total + box_h + pad
        gy = gy + box_h + pad
    end

    draw_scrollbar(x + w + 2, y, h, total, scroll_key)
end

local function split_groups(groups)
    -- Alternate into two columns for world (4 groups) etc.
    local left, right = {}, {}
    for i, g in ipairs(groups) do
        if i % 2 == 1 then
            left[#left + 1] = g
        else
            right[#right + 1] = g
        end
    end
    -- Prefer explicit pairs when exactly 2
    if #groups == 2 then
        return { groups[1] }, { groups[2] }
    end
    return left, right
end

function M.init()
    state.define("april_ui_accent", theme.ACCENT)
    -- Center window once
    local sw, sh = screen_size()
    win_x = math.floor((sw - theme.WINDOW_W) * 0.5)
    win_y = math.floor((sh - theme.WINDOW_H) * 0.35)
end

function M.is_open()
    return open
end

function M.draw()
    if not draw then return end

    gin.begin_frame()

    if gin.key_pressed(TOGGLE_VK) then
        open = not open
    end

    if not open then
        -- tiny hint
        widgets.text(8, 8, "April UI [INSERT]", theme.TEXT_DIM, theme.FONT_SMALL)
        return
    end

    clamp_window()

    local x, y = win_x, win_y
    local w, h = theme.WINDOW_W, theme.WINDOW_H

    -- Outer frame
    widgets.rect(x, y, w, h, theme.BG, true)
    widgets.rect(x, y, w, h, theme.BORDER, false)
    widgets.rainbow_bar(x + 1, y + 1, w - 2, 2)

    -- Title / drag bar
    local title_h = 22
    widgets.rect(x + 1, y + 3, w - 2, title_h, theme.BG_INNER, true)
    local tab = catalog.TABS[tab_index]
    local title = "april  |  " .. (tab and tab.title or "") .. "  (placeholder)"
    widgets.text(x + 10, y + 7, title, theme.TEXT_TITLE, theme.FONT_TITLE)

    if gin.lmb_click and gin.hover(x, y, w - theme.SIDEBAR_W, title_h + 4) and not widgets.active_slider then
        widgets.dragging_window = true
        widgets.drag_offset_x = gin.mx - win_x
        widgets.drag_offset_y = gin.my - win_y
    end
    if widgets.dragging_window then
        if gin.lmb then
            win_x = gin.mx - widgets.drag_offset_x
            win_y = gin.my - widgets.drag_offset_y
            clamp_window()
        else
            widgets.dragging_window = false
        end
    end

    local body_y = y + title_h + 4
    local body_h = h - title_h - 6

    draw_sidebar(x + 1, body_y, body_h)

    local content_x = x + theme.SIDEBAR_W + 8
    local content_w = w - theme.SIDEBAR_W - 24
    local col_w = math.floor((content_w - 16) * 0.5)
    local groups = catalog.groups_for(tab and tab.id or "aim")
    local left_groups, right_groups = split_groups(groups)

    handle_page_scroll(content_x, body_y + 4, col_w, body_h - 8)
    draw_group_column(left_groups, content_x, body_y + 4, col_w, body_h - 8, "left")
    draw_group_column(right_groups, content_x + col_w + 12, body_y + 4, col_w, body_h - 8, "right")

    -- Footer
    widgets.text(x + theme.SIDEBAR_W + 10, y + h - 16,
        "draw API only · not wired to features · PgUp/PgDn scroll",
        theme.TEXT_DIM, 11)
end

return M

end)()

-- ── ui/standalone_app.lua ──
April._mods["ui.standalone_app"] = (function()
-- Entry for the Gamesense UI demo only (no features, no Vector menu registration).
local custom_menu = April.require("ui.custom_menu")

local M = {}

function M.init()
    if not draw then
        print("[April UI] draw API missing")
        return false
    end
    if not (utility and utility.get_mouse_pos) and not (input and input.is_key_down) then
        print("[April UI] input/utility mouse APIs missing — UI may not be interactive")
    end
    custom_menu.init()
    print("[April UI] Gamesense placeholder ready — INSERT to toggle")
    return true
end

function M.on_frame()
    custom_menu.draw()
end

return M

end)()

do
    local ok, err = pcall(function()
        local app = April.require("ui.standalone_app")
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
