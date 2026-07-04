local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local menu_util = April.require("core.menu_util")
local image_cache = April.require("core.image_cache")
local items = April.require("game.items")
local player_gear = April.require("game.player_gear")
local targeting = April.require("features.combat.targeting")

local M = {}

local P = "april_target_overlay"
local AIM = "april_aimbot_enabled"
local AIM_PREFIX = "april_aimbot_"

local gear_cache = {}
local GEAR_TTL = 400

M._anchor_x = nil
M._anchor_y = nil
M._last_uid = nil

local function scale()
    return math.max(0.55, settings.num(P .. "_scale", 72) / 100)
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function img_key(prefix, id)
    return prefix .. tostring(id)
end

local function ensure_item_image(name, variant)
    if not name then return nil end
    local asset_id = items.get_image_asset_id(name, variant)
    if not asset_id then return nil end
    local key = img_key("item_", asset_id)
    image_cache.ensure(key, asset_id)
    return key
end

local function get_gear(player)
    if not player then return nil end
    local uid = player.user_id or player.name or "?"
    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    local cached = gear_cache[uid]
    if cached and (now - cached.t) < GEAR_TTL then
        return cached.data
    end
    local data = player_gear.scan_player(player)
    gear_cache[uid] = { t = now, data = data }
    return data
end

local function resolve_target()
    if not settings.bool(AIM, false) then return nil end

    local aimbot = April.require("features.combat.aimbot")
    local locked = aimbot.get_target and aimbot.get_target()
    if locked and locked.is_alive then return locked end

    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num(AIM_PREFIX .. "fov", 150)
    return targeting.find_target(cx, cy, fov, AIM_PREFIX)
end

local function hp_color(ratio)
    if ratio > 0.6 then return { 0.35, 0.92, 0.45, 1 } end
    if ratio > 0.3 then return { 0.95, 0.85, 0.25, 1 } end
    return { 0.95, 0.3, 0.3, 1 }
end

local function draw_icon_slot(x, y, size, key, accent)
    local pad = 2
    draw.rect_filled(x, y, size, size, { 0.08, 0.08, 0.1, 0.9 })
    draw.rect(x, y, size, size, accent or { 0.35, 0.55, 0.95, 0.45 }, 1)
    if key then
        image_cache.draw_fit(key, x + pad, y + pad, size - pad * 2, size - pad * 2)
    end
end

local function measure_panel(target, s)
    local gear = get_gear(target)
    local armor_list = (gear and gear.armor) or {}
    local held_name = gear and gear.held

    local show_held = settings.bool(P .. "_held", true) and held_name
    local show_armor = settings.bool(P .. "_armor", true) and #armor_list > 0

    local slot_sz = math.floor(26 * s)
    local pad = math.floor(6 * s)
    local title_fs = math.max(11, math.floor(12 * s))
    local body_fs = math.max(9, math.floor(10 * s))
    local gap = math.floor(4 * s)
    local header_h = math.floor(36 * s)

    local cols = show_armor and math.min(4, math.max(1, #armor_list)) or 0
    local armor_rows = show_armor and math.ceil(#armor_list / 4) or 0

    local content_w = math.floor(168 * s)
    if show_armor then
        content_w = math.max(content_w, cols * (slot_sz + gap) + pad)
    end

    local panel_w = content_w + pad * 2
    local panel_h = header_h + pad * 2

    if show_held then
        panel_h = panel_h + slot_sz + gap + body_fs
    end
    if show_armor then
        panel_h = panel_h + body_fs + gap + armor_rows * (slot_sz + gap)
    end

    return panel_w, panel_h, {
        s = s,
        pad = pad,
        gap = gap,
        slot_sz = slot_sz,
        title_fs = title_fs,
        body_fs = body_fs,
        show_held = show_held,
        show_armor = show_armor,
        armor_list = armor_list,
        held_name = held_name,
        cols = cols,
        armor_rows = armor_rows,
    }
end

local function compute_anchor(target, panel_w, panel_h, sw, sh)
    local gap = math.floor(14 + settings.num(P .. "_x_offset", 0))
    local y_off = settings.num(P .. "_y_offset", 0)
    local b = target.get_bounds and target:get_bounds()

    local ax, ay

    if b and b.valid and b.w > 0 and b.h > 0 then
        if (b.x + b.w + gap + panel_w) > (sw - 10) then
            ax = b.x - gap - panel_w
        else
            ax = b.x + b.w + gap
        end
        ay = b.y + b.h * 0.5 - panel_h * 0.5 + y_off
    else
        local pos = target.head_position or target.position
        if not pos then return nil, nil end
        local sx, sy, vis = esp_util.w2s(pos.x, pos.y + 1.5, pos.z)
        if not vis then return nil, nil end
        if (sx + gap + panel_w) > (sw - 10) then
            ax = sx - gap - panel_w
        else
            ax = sx + gap + 24
        end
        ay = sy - panel_h * 0.5 + y_off
    end

    ax = math.max(6, math.min(sw - panel_w - 6, ax))
    ay = math.max(6, math.min(sh - panel_h - 6, ay))

    return ax, ay
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)
    local root = menu_util.parent(AIM)

    menu_util.section(T, G.VISUALS, "Target Overlay")
    menu.add_checkbox(T, G.VISUALS, P, "Target Overlay", false, root)
    menu.add_slider_int(T, G.VISUALS, P .. "_scale", "Scale %", 55, 120, 72, menu_util.parent(P))
    menu.add_slider_int(T, G.VISUALS, P .. "_follow", "Follow Speed", 4, 24, 14, menu_util.parent(P))
    menu.add_slider_int(T, G.VISUALS, P .. "_x_offset", "Side Offset", 0, 80, 14, menu_util.parent(P))
    menu.add_slider_int(T, G.VISUALS, P .. "_y_offset", "Y Offset", -120, 120, 0, menu_util.parent(P))
    menu.add_checkbox(T, G.VISUALS, P .. "_held", "Held Item", true, menu_util.parent(P))
    menu.add_checkbox(T, G.VISUALS, P .. "_armor", "Armor Icons", true, menu_util.parent(P))
    menu.add_checkbox(T, G.VISUALS, P .. "_distance", "Distance", true, menu_util.parent(P))
    menu.add_colorpicker(T, G.VISUALS, P .. "_accent", "Accent", { 0.35, 0.72, 1, 1 }, menu_util.parent(P))
    menu.add_colorpicker(T, G.VISUALS, P .. "_name", "Name Color", { 1, 1, 1, 1 }, menu_util.parent(P))
    menu.add_colorpicker(T, G.VISUALS, P .. "_held_col", "Held Color", { 1, 0.45, 0.35, 1 }, menu_util.parent(P))
end

function M.update(dt)
    if not settings.bool(AIM, false) or not settings.bool(P, false) then
        M._anchor_x, M._anchor_y, M._last_uid = nil, nil, nil
        return
    end

    image_cache.tick_all()

    local target = resolve_target()
    if not target then
        M._anchor_x, M._anchor_y, M._last_uid = nil, nil, nil
        return
    end

    local uid = target.user_id or target.name
    if M._last_uid ~= uid then
        M._anchor_x, M._anchor_y = nil, nil
        M._last_uid = uid
    end

    local gear = get_gear(target)
    if gear then
        if gear.held then ensure_item_image(gear.held) end
        if settings.bool(P .. "_armor", true) then
            for _, piece in ipairs(gear.armor) do
                ensure_item_image(piece.name, piece.variant)
            end
        end
    end

    local sw, sh = draw_util.screen_size()
    local panel_w, panel_h = measure_panel(target, scale())
    local ax, ay = compute_anchor(target, panel_w, panel_h, sw, sh)
    if not ax then return end

    local speed = settings.num(P .. "_follow", 14)
    local t = math.min(1, dt * speed)

    if not M._anchor_x then
        M._anchor_x, M._anchor_y = ax, ay
    else
        M._anchor_x = lerp(M._anchor_x, ax, t)
        M._anchor_y = lerp(M._anchor_y, ay, t)
    end
end

function M.draw()
    if not settings.bool(AIM, false) or not settings.bool(P, false) then return end
    if not draw or not M._anchor_x then return end

    local target = resolve_target()
    if not target or not target.is_alive then return end

    local px, py = M._anchor_x, M._anchor_y
    local s = scale()
    local panel_w, panel_h, layout = measure_panel(target, s)

    local accent = settings.color(P .. "_accent", { 0.35, 0.72, 1, 1 })
    local name_col = settings.color(P .. "_name", { 1, 1, 1, 1 })
    local held_col = settings.color(P .. "_held_col", { 1, 0.45, 0.35, 1 })
    local sub_col = { 0.72, 0.76, 0.82, 1 }
    local panel_bg = { 0.04, 0.05, 0.08, 0.9 }
    local panel_edge = { accent[1], accent[2], accent[3], 0.4 }

    local pad = layout.pad
    local hp = target.health or 0
    local max_hp = target.max_health or 100
    if max_hp <= 0 then max_hp = 100 end
    local hp_ratio = math.max(0, math.min(1, hp / max_hp))
    local hp_col = hp_color(hp_ratio)

    local name = target.name or "Unknown"
    local dist_text = ""
    if settings.bool(P .. "_distance", true) then
        local me = entity and entity.get_local_player and entity.get_local_player()
        if me and me.position and target.position then
            local dx = target.position.x - me.position.x
            local dy = target.position.y - me.position.y
            local dz = target.position.z - me.position.z
            dist_text = string.format("%dm", math.floor(math.sqrt(dx * dx + dy * dy + dz * dz)))
        end
    end

    draw.rect_filled(px, py, panel_w, panel_h, panel_bg)
    draw.rect(px, py, panel_w, panel_h, panel_edge, 1)
    draw.rect_filled(px, py, panel_w, 2, accent)

    local info_x = px + pad
    local ty = py + pad
    local info_w = panel_w - pad * 2

    draw.text(info_x, ty, name, name_col, layout.title_fs)

    if dist_text ~= "" then
        local dw = select(1, draw.get_text_size(dist_text, layout.body_fs))
        draw.text(px + panel_w - pad - dw, ty + 1, dist_text, sub_col, layout.body_fs)
    end

    local hp_y = ty + layout.title_fs + 2
    local hp_text = string.format("HP %d / %d", math.ceil(hp), math.ceil(max_hp))
    draw.text(info_x, hp_y, hp_text, hp_col, layout.body_fs)

    local bar_y = hp_y + layout.body_fs + 2
    local bar_h = math.max(3, math.floor(4 * s))
    draw.rect_filled(info_x, bar_y, info_w, bar_h, { 0.15, 0.16, 0.2, 0.9 })
    if hp_ratio > 0 then
        draw.rect_filled(info_x, bar_y, info_w * hp_ratio, bar_h, hp_col)
    end

    local row_y = py + pad + math.floor(36 * s) + pad

    if layout.show_held then
        local held_key = ensure_item_image(layout.held_name)
        draw.text(px + pad, row_y, "Held", sub_col, layout.body_fs)
        draw_icon_slot(px + pad + math.floor(34 * s), row_y - 2, layout.slot_sz + 4, held_key, held_col)
        if layout.held_name then
            local label = layout.held_name
            if #label > 18 then label = label:sub(1, 16) .. ".." end
            draw.text(px + pad + math.floor(34 * s) + layout.slot_sz + 10, row_y + 4, label, held_col, layout.body_fs)
        end
        row_y = row_y + layout.slot_sz + layout.gap + layout.body_fs + 2
    end

    if layout.show_armor then
        draw.text(px + pad, row_y, "Gear", sub_col, layout.body_fs)
        row_y = row_y + layout.body_fs + layout.gap

        local grid_x = px + pad
        for i, piece in ipairs(layout.armor_list) do
            local col_i = (i - 1) % 4
            local row_i = math.floor((i - 1) / 4)
            local sx = grid_x + col_i * (layout.slot_sz + layout.gap)
            local sy = row_y + row_i * (layout.slot_sz + layout.gap)
            local key = ensure_item_image(piece.name, piece.variant)
            draw_icon_slot(sx, sy, layout.slot_sz, key, panel_edge)
        end
    end
end

return M
