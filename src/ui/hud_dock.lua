-- Top-shell HUD controls. These are first-class panel toggles rather than
-- gameplay settings buried in Misc.
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

-- Static top-center launcher, independent of the menu window position.
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

-- Draws right-aligned compact chips. Returns the left edge occupied by the dock.
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
    -- begin_frame blocks controls underneath this popup. Temporarily release
    -- that guard while drawing the popup's own controls.
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
