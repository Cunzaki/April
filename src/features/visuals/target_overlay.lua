local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local menu_util = April.require("core.menu_util")
local image_cache = April.require("core.image_cache")
local items = April.require("game.items")
local player_gear = April.require("game.player_gear")
local math_util = April.require("core.math_util")

local M = {}

local P = "april_target_overlay"
local GEAR_SLOTS = 7

local gear_cache = {}
local GEAR_TTL = 1000
local TARGET_TTL = 150

M._target = nil
M._target_at = 0
M._layout = nil

local SLOT_BG = { 0.14, 0.14, 0.16, 0.72 }
local HELD_BG = { 0.2, 0.2, 0.22, 0.85 }
local EMPTY_BG = { 0.1, 0.1, 0.12, 0.65 }
local EMPTY_EDGE = { 1, 1, 1, 0.28 }
local EMPTY_INNER = { 1, 1, 1, 0.06 }
local ROUND = 5

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
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
    local now = tick_ms()
    local cached = gear_cache[uid]
    if cached and (now - cached.t) < GEAR_TTL then
        return cached.data
    end
    local data = player_gear.scan_player(player)
    gear_cache[uid] = { t = now, data = data }
    return data
end

local function get_mouse()
    if not utility or not utility.get_mouse_pos then return nil, nil end
    local ok, a, b = pcall(utility.get_mouse_pos)
    if not ok then return nil, nil end
    if type(a) == "table" then
        return a.x or a.X, a.y or a.Y
    end
    if type(a) == "number" then
        return a, b
    end
    return nil, nil
end

local function find_mouse_target(fov_px)
    if not entity or not entity.get_players then return nil end

    local mx, my = get_mouse()
    if not mx then
        local sw, sh = draw_util.screen_size()
        mx, my = sw * 0.5, sh * 0.5
    end

    local best, best_dist = nil, fov_px

    for _, p in ipairs(entity.get_players()) do
        if p.is_local or not p.is_alive then goto continue end

        local pos = p.head_position or p.position
        if not pos then goto continue end

        local sx, sy, vis = esp_util.w2s(pos.x, pos.y, pos.z)
        if not vis then goto continue end

        local dist = math_util.screen_fov_dist(sx, sy, mx, my)
        if dist <= fov_px and dist < best_dist then
            best_dist = dist
            best = p
        end

        ::continue::
    end

    return best
end

local function bottom_offset()
    local bottom = settings.num(P .. "_bottom", -1)
    if bottom >= 0 then return bottom end
    return settings.num(P .. "_top", 140)
end

local function build_layout(gear, gear_sz)
    local held = gear and gear.held
    local packed = gear and gear.slots or {}
    local filled = #packed

    local held_sz = math.floor(gear_sz * 1.28)
    local gap = 5
    local row_w = GEAR_SLOTS * gear_sz + (GEAR_SLOTS - 1) * gap
    local block_h = held_sz + 8 + gear_sz

    return {
        held = held,
        packed = packed,
        filled = filled,
        gear_sz = gear_sz,
        held_sz = held_sz,
        gap = gap,
        row_w = row_w,
        row_gap = 8,
        name_fs = 11,
        block_h = block_h,
    }
end

local function draw_slot(x, y, size, key, piece, style)
    local pad = 3
    local bg = SLOT_BG
    if style == "held" then
        bg = HELD_BG
    elseif style == "empty" then
        bg = EMPTY_BG
    end

    draw.rect_filled(x, y, size, size, bg, ROUND)
    if style == "empty" then
        if draw.rect then
            draw.rect(x, y, size, size, EMPTY_EDGE, ROUND, 1)
        end
        local inset = math.max(4, math.floor(size * 0.22))
        draw.rect_filled(
            x + inset, y + inset,
            size - inset * 2, size - inset * 2,
            EMPTY_INNER, ROUND - 2
        )
    end

    if not piece then return end

    if key then
        image_cache.begin_load(key)
        if image_cache.draw_fit(key, x + pad, y + pad, size - pad * 2, size - pad * 2) then
            return
        end
    end

    local fs = math.max(10, math.floor(size * 0.34))
    local tw = select(1, draw.get_text_size("?", fs))
    draw.text(
        x + size * 0.5 - tw * 0.5,
        y + size * 0.5 - fs * 0.45,
        "?",
        { 0.55, 0.55, 0.58, 0.85 },
        fs
    )
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)

    menu_util.section(T, G.VISUALS, "Target Gear")
    menu.add_checkbox(T, G.VISUALS, P, "Target Gear", false)
    menu.add_slider_int(T, G.VISUALS, P .. "_fov", "Target FOV", 40, 400, 150, menu_util.parent(P))
    menu.add_slider_int(T, G.VISUALS, P .. "_gear_size", "Gear Icon Size", 32, 64, 48, menu_util.parent(P))
    menu.add_slider_int(T, G.VISUALS, P .. "_bottom", "Bottom Offset", 80, 320, 140, menu_util.parent(P))
end

function M.update(_dt)
    if not settings.bool(P, false) then
        M._target = nil
        M._layout = nil
        return
    end

    local now = tick_ms()
    if now - M._target_at < TARGET_TTL then return end
    M._target_at = now

    local fov = settings.num(P .. "_fov", 150)
    local target = find_mouse_target(fov)
    if target and target.is_alive then
        M._target = target
        M._layout = build_layout(get_gear(target), settings.num(P .. "_gear_size", 48))
    else
        M._target = nil
        M._layout = nil
    end
end

function M.draw()
    if not settings.bool(P, false) then return end
    if not draw or not draw.text or not draw.rect_filled then return end

    local target = M._target
    local layout = M._layout
    if not target or not layout then return end

    if layout.held then ensure_item_image(layout.held) end
    for i = 1, layout.filled do
        local piece = layout.packed[i]
        if piece then
            ensure_item_image(piece.name, piece.variant)
        end
    end

    local sw, sh = draw_util.screen_size()
    local cx = sw * 0.5
    local bottom = bottom_offset()

    local gear_y = sh - bottom - layout.gear_sz
    local held_y = gear_y - layout.row_gap - layout.held_sz
    local name_y = held_y - 6 - layout.name_fs

    local name = target.name or "Unknown"
    local nw = select(1, draw.get_text_size(name, layout.name_fs))
    draw.text(cx - nw * 0.5, name_y, name, { 1, 1, 1, 1 }, layout.name_fs)

    local held_key = layout.held and ensure_item_image(layout.held) or nil
    draw_slot(cx - layout.held_sz * 0.5, held_y, layout.held_sz, held_key, layout.held, layout.held and "held" or "empty")

    local start_x = cx - layout.row_w * 0.5
    for i = 1, GEAR_SLOTS do
        local piece = i <= filled and packed[i] or nil
        local key = piece and ensure_item_image(piece.name, piece.variant) or nil
        local sx = start_x + (i - 1) * (layout.gear_sz + layout.gap)
        draw_slot(sx, gear_y, layout.gear_sz, key, piece, piece and "gear" or "empty")
    end
end

return M
