--[[
  Gamesense-style custom menu for April.
  INSERT toggles. Scroll by dragging the scrollbar or click-dragging a column.
]]

local theme = April.require("ui.gs_theme")
local gin = April.require("ui.gs_input")
local widgets = April.require("ui.gs_widgets")
local anim = April.require("ui.gs_anim")
local icons = April.require("ui.gs_icons")
local catalog = April.require("ui.catalog")
local state = April.require("ui.gs_state")

local M = {}

local TOGGLE_VK = 0x2D
local open = true
local tab_index = 1
local win_x, win_y = 80, 80
local scroll = { left = 0, right = 0 }
local scroll_drag = nil
local panel_drag = nil -- { key, last_y }

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

local function draw_scrollbar(x, y, h, content_h, scroll_key)
    local max_scroll = clamp_scroll(scroll_key, content_h, h)
    if max_scroll <= 0 then
        scroll[scroll_key] = 0
        return
    end

    local thumb_h = math.max(34, h * (h / content_h))
    local t = scroll[scroll_key] / max_scroll
    local thumb_y = y + t * (h - thumb_h)

    widgets.rect(x, y, 4, h, { 0, 0, 0, 0.26 }, true)
    widgets.rect(x + 1, y + 1, 2, h - 2, theme.SLIDER_BG, true)
    anim.draw_scroll_thumb(x, thumb_y, 4, thumb_h)

    if gin.lmb_click and gin.hover(x - 4, y, 14, h) then
        scroll_drag = scroll_key
    end
    if scroll_drag == scroll_key and gin.lmb then
        local rel = (gin.my - y - thumb_h * 0.5) / math.max(1, h - thumb_h)
        rel = math.max(0, math.min(1, rel))
        scroll[scroll_key] = rel * max_scroll
    elseif scroll_drag == scroll_key and not gin.lmb then
        scroll_drag = nil
    end
end

local function handle_column_scroll(x, y, w, h, scroll_key, content_h)
    local max_scroll = clamp_scroll(scroll_key, content_h, h)
    if max_scroll <= 0 then return end

    local hot = gin.hover(x, y, w + 14, h)
    if not hot then
        if panel_drag and panel_drag.key == scroll_key then
            if not gin.lmb and not gin.mmb and not gin.rmb then
                panel_drag = nil
            end
        end
        return
    end

    -- Mouse wheel (dropdowns set widgets.wheel_consumed while open + hovered)
    if gin.wheel ~= 0 and not widgets.wheel_consumed then
        scroll[scroll_key] = scroll[scroll_key] - gin.wheel * 48
        clamp_scroll(scroll_key, content_h, h)
        widgets.wheel_consumed = true
    end

    -- Drag-to-scroll: LMB on empty space, RMB anywhere in column, or MMB
    local can_lmb_drag = gin.lmb_click and not widgets.interacted
        and not widgets.block_under
        and not widgets.active_slider and not widgets.active_input
        and not widgets.open_combo
        and not widgets.open_multi and not widgets.open_color
        and not widgets.open_bind_mode
        and not scroll_drag
    local can_rmb_drag = gin.rmb_click and not widgets.interacted
        and not widgets.block_under
        and not widgets.open_bind_mode
        and not widgets.listening_key
    if can_lmb_drag or gin.mmb_click or can_rmb_drag then
        panel_drag = {
            key = scroll_key,
            last_y = gin.my,
            btn = gin.mmb_click and "mmb" or (can_rmb_drag and "rmb" or "lmb"),
        }
    end
    if panel_drag and panel_drag.key == scroll_key then
        local held = (panel_drag.btn == "lmb" and gin.lmb)
            or (panel_drag.btn == "rmb" and gin.rmb)
            or (panel_drag.btn == "mmb" and gin.mmb)
        if held then
            local dy = gin.my - panel_drag.last_y
            scroll[scroll_key] = scroll[scroll_key] - dy
            panel_drag.last_y = gin.my
            clamp_scroll(scroll_key, content_h, h)
        else
            panel_drag = nil
        end
    end
end

local function draw_group_title(x, box_top, title)
    widgets.text(x + 12, box_top + 7, title, theme.TEXT_ACTIVE, theme.FONT_TITLE)
end

local function draw_group_column(groups, x, y, w, h, scroll_key)
    local pad = theme.GROUP_PAD
    local visible_groups = {}
    for _, group in ipairs(groups) do
        if group_visible(group) then
            visible_groups[#visible_groups + 1] = group
        end
    end

    local total = 0
    for _, group in ipairs(visible_groups) do
        total = total + content_height(group.items or {}, group) + theme.GROUP_HEADER_H + theme.GROUP_GAP
    end

    clamp_scroll(scroll_key, total, h)

    local gy = y + pad - scroll[scroll_key]
    widgets.clip = { x = x, y = y, w = w, h = h }

    for _, group in ipairs(visible_groups) do
        local items = group.items or {}
        local inner_h = content_height(items, group)
        local box_h = inner_h + theme.GROUP_HEADER_H

        local box_top = gy
        local box_bot = gy + box_h
        if box_bot > y and box_top < y + h then
            local vis_y = math.max(box_top, y)
            local vis_b = math.min(box_bot, y + h)
            local vis_h = vis_b - vis_y
            if vis_h > 1 then
                widgets.rect(x + 2, vis_y + 2, w, vis_h, theme.SHADOW, true)
                widgets.rect(x, vis_y, w, vis_h, theme.PANEL, true)
                widgets.rect(x, vis_y, w, vis_h, theme.BORDER_SOFT, false)
                if box_top >= y - 2 and box_top < y + h then
                    widgets.rect(x + 1, box_top + 2, w - 2, theme.GROUP_HEADER_H - 3, theme.PANEL_ALT, true)
                    anim.draw_section_top(x + 1, box_top, w - 2)
                    draw_group_title(x, box_top, group.title)
                end
            end

            local iy = gy + theme.GROUP_HEADER_H + 6
            local ix = x + 7
            local iw = w - 16
            for _, item in ipairs(items) do
                if item_visible(item, group) then
                    local est = widgets.estimate_height(item)
                    if iy >= y and iy + est <= y + h then
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
    -- Wheel after widgets so open dropdowns can consume it first
    handle_column_scroll(x, y, w, h, scroll_key, total)
    draw_scrollbar(x + w + 2, y, h, total, scroll_key)
end

local function split_groups(groups, tab_id)
    if tab_id == "aim" and #groups >= 3 then
        return { groups[1] }, { groups[2], groups[3] }
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
    local sw, sh = screen_size()
    win_x = math.floor((sw - theme.WINDOW_W) * 0.5)
    win_y = math.floor((sh - theme.WINDOW_H) * 0.3)
end

function M.is_open()
    return open
end

function M.draw()
    if not draw then return end

    gin.begin_frame()
    anim.sync_theme()
    widgets.begin_popups()
    widgets.tick_key_listen()
    widgets.tick_text_input()

    if gin.key_pressed(TOGGLE_VK) and not widgets.listening_key and not widgets.active_input then
        open = not open
        gin.set_menu_open(open)
    end

    if not open then
        if gin._menu_open or gin._game_cursor_hidden then
            gin.set_menu_open(false)
        end
        return
    end

    gin.set_menu_open(true)
    clamp_window()

    local x, y = win_x, win_y
    local w, h = theme.WINDOW_W, theme.WINDOW_H
    gin.set_ui_rect(x, y, w, h)

    -- Frame
    local fade = anim.menu_fade()
    widgets.rect(x, y, w, h, theme.alpha(anim.panel_bg(), fade), true)
    widgets.rect(x, y, w, h, theme.BORDER, false)
    widgets.rect(x + 1, y + 1, w - 2, 1, theme.BORDER_HOT, true)
    anim.draw_title_bar(x + 1, y + 1, w - 2, 2)

    local title_h = 28
    widgets.rect(x + 1, y + 3, w - 2, title_h, theme.BG_INNER, true)
    widgets.rect(x + 1, y + title_h + 3, w - 2, 1, theme.BORDER_SOFT, true)
    local tab = catalog.TABS[tab_index]
    widgets.text(x + 12, y + 10, "APRIL", theme.TEXT_ACTIVE, theme.FONT_TITLE)
    widgets.text(x + 55, y + 10, "/  " .. (tab and tab.title or ""), theme.TEXT_TITLE, theme.FONT_TITLE)

    if gin.lmb_click and gin.hover(x, y, w - theme.SIDEBAR_W, title_h + 5)
        and not widgets.active_slider and not widgets.listening_key
        and not widgets.active_input
        and not widgets.block_under
        and not widgets.open_combo and not widgets.open_multi and not widgets.open_color
        and not widgets.open_bind_mode
        and not scroll_drag and not panel_drag then
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

    local body_y = y + title_h + 6
    local body_h = h - title_h - 10

    draw_sidebar(x + 1, body_y, body_h)

    local content_x = x + theme.SIDEBAR_W + 12
    local content_w = w - theme.SIDEBAR_W - 30
    local col_w = math.floor((content_w - 16) * 0.5)
    local groups = catalog.groups_for(tab and tab.id or "aim")
    local left_groups, right_groups = split_groups(groups, tab and tab.id or "aim")

    draw_group_column(left_groups, content_x, body_y + 2, col_w, body_h - 4, "left")
    draw_group_column(right_groups, content_x + col_w + 12, body_y + 2, col_w, body_h - 4, "right")

    -- Floating popups above all sections
    widgets.draw_color_overlay()
    widgets.draw_bind_mode_overlay()
    widgets.end_popups()

    gin.draw_cursor()
end

return M
