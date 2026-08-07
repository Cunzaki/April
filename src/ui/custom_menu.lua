--[[
  Gamesense-style custom menu for April.
  INSERT toggles by default (rebindable in Config -> Menu).
  Scroll: mouse wheel when available, middle-button drag, or edge hover.
]]

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
        local i18n = April.require("ui.i18n")
        local label = i18n.t(tab.label or tab.title or tab.id)
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
        -- Smooth only the tab-relative position. Smoothing absolute screen
        -- coordinates makes the underline trail behind a dragged window.
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

    -- Inset pill only: no full-height accent track above the section cards.
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

    -- Guaranteed documented fallback: hold the middle mouse button and drag.
    -- Wheel rotation has no documented Vector reader, so this uses VK_MBUTTON
    -- plus GetMousePosition and works even when Roblox wheel signals are absent.
    if gin.mmb_click then
        middle_scroll = {
            key = scroll_key,
            start_y = gin.my,
            start_scroll = scroll[scroll_key],
        }
        widgets.interacted = true
        return
    end

    -- Prefer real wheel when a runtime event/getter delivers notches this frame.
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

    -- Runtime wheel events are not available on every Vector build. Preserve
    -- edge-hover as a no-click fallback alongside middle-button drag.
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
                widgets.rect(x, vis_y, w, vis_h, theme.PANEL, true, theme.CORNER)
                widgets.rect(x, vis_y, w, vis_h, theme.BORDER_SOFT, false, theme.CORNER)
                if box_top >= y - 2 and box_top < y + h then
                    widgets.rect(x + 1, box_top + 1, w - 2, theme.GROUP_HEADER_H - 2,
                        theme.alpha(theme.PANEL_ALT, 0.42), true, theme.CORNER)
                    local header_hot = gin.hover(x, box_top, w, theme.GROUP_HEADER_H)
                    local i18n = April.require("ui.i18n")
                    draw_group_title(x, box_top, w, i18n.t(group.title), entry.collapsed, header_hot)
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
    -- Aim: Aimbot left, Silent Aim + Bullet right.
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
    state.define("april_ui_russian", false)
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

    -- Fullscreen dim/snow first (no clip, behind every menu element).
    widgets.clip = nil
    local sw, sh = screen_size()
    pcall(menu_fx.draw_backdrop, sw, sh, open_progress)

    gin.set_ui_rect(x, y, w, h)

    -- Static HUD launcher, independent of the menu window.
    hud_dock.draw_floating(x + w * 0.5, math.max(8, y - 58 * (theme.SCALE or 1)), sw, sh)

    -- Flat frame: no extra highlights, accent strips, or offset shadows.
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
    local i18n = April.require("ui.i18n")
    local author_text = i18n.t("Made by Cunzaki")
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

    -- Floating popups above all sections
    widgets.draw_color_overlay()
    widgets.draw_bind_mode_overlay()
    widgets.draw_color_ctx_overlay()
    widgets.draw_tooltip_overlay()
    widgets.end_popups()

    if open then
        gin.draw_cursor()
    end
end

return M
