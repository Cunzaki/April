local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local menu_util = April.require("core.menu_util")
local image_cache = April.require("core.image_cache")
local items = April.require("game.items")
local player_gear = April.require("game.player_gear")
local player_state = April.require("game.player_state")
local math_util = April.require("core.math_util")

local M = {}

local P = "april_target_overlay"
local GEAR_SLOTS = 7

local gear_cache = {}
local GEAR_TTL = 150

M._target = nil
M._layout = nil

local SLOT_BG = { 0.14, 0.14, 0.16, 0.72 }
local HELD_BG = { 0.2, 0.2, 0.22, 0.85 }
local EMPTY_BG = { 0.08, 0.08, 0.1, 0.55 }
local EMPTY_EDGE = { 1, 1, 1, 0.12 }
local ROUND = 5

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function img_key(prefix, id)
    return prefix .. tostring(id)
end

local function resolve_image_key(piece)
    if not piece then return nil end

    if type(piece) == "table" and piece.asset_id then
        local key = img_key("item_", piece.asset_id)
        image_cache.ensure(key, piece.asset_id)
        return key
    end

    if type(piece) == "table" and piece.name then
        local resolved = items.resolve_item_label(
            piece.variant and (piece.name .. "/" .. piece.variant) or piece.name
        )
        if resolved and resolved.asset_id then
            local key = img_key("item_", resolved.asset_id)
            image_cache.ensure(key, resolved.asset_id)
            return key
        end
        local asset_id = items.get_image_asset_id(piece.name, piece.variant)
        if asset_id then
            local key = img_key("item_", asset_id)
            image_cache.ensure(key, asset_id)
            return key
        end
    end

    if type(piece) == "string" then
        local resolved = items.resolve_item_label(piece)
        if resolved and resolved.asset_id then
            local key = img_key("item_", resolved.asset_id)
            image_cache.ensure(key, resolved.asset_id)
            return key
        end
    end

    return nil
end

local function preload_layout_images(layout)
    if not layout then return end
    if layout.held then
        local key = resolve_image_key(layout.held)
        if key then image_cache.begin_load(key) end
    end
    for i = 1, layout.filled or 0 do
        local piece = layout.packed[i]
        local key = resolve_image_key(piece)
        if key then image_cache.begin_load(key) end
    end
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

local function crosshair_center()
    local sw, sh = draw_util.screen_size()
    return sw * 0.5, sh * 0.5
end

local function find_crosshair_target(fov_px)
    if not entity or not entity.get_players then return nil end

    local cx, cy = crosshair_center()
    local best, best_dist = nil, fov_px

    for _, p in ipairs(entity.get_players()) do
        if not player_state.is_combat_target(p) then goto continue end

        local pos = p.head_position or p.position
        if not pos then goto continue end

        local px = pos.x or pos[1]
        local py = pos.y or pos[2]
        local pz = pos.z or pos[3]
        if not px then goto continue end

        local sx, sy, vis = esp_util.w2s(px, py, pz)
        if not vis then goto continue end

        local dist = math_util.screen_fov_dist(sx, sy, cx, cy)
        if dist <= fov_px and dist < best_dist then
            best_dist = dist
            best = p
        end

        ::continue::
    end

    return best
end

local function armor_sort_key(piece)
    local n = (piece.name or ""):lower()
    if n:find("helmet", 1, true) or n:find("head", 1, true) or n:find("cap", 1, true)
        or n:find("wrap", 1, true) or n:find("balaclava", 1, true) or n:find("hood", 1, true) then
        return 1
    end
    if n:find("chest", 1, true) or n:find("plate", 1, true) or n:find("shirt", 1, true)
        or n:find("jacket", 1, true) or n:find("hoodie", 1, true) or n:find("vest", 1, true)
        or n:find("suit", 1, true) or n:find("torso", 1, true) then
        return 2
    end
    if n:find("legging", 1, true) or n:find("pants", 1, true) or n:find("shorts", 1, true) then
        return 3
    end
    if n:find("glove", 1, true) or n:find("handwrap", 1, true) then
        return 4
    end
    if n:find("boot", 1, true) or n:find("footwrap", 1, true) or n:find("shoe", 1, true) then
        return 5
    end
    if n:find("backpack", 1, true) or n:find("bag", 1, true) then
        return 6
    end
    return 7
end

local function pack_gear(armor_list)
    local sorted = {}
    for _, piece in ipairs(armor_list or {}) do
        table.insert(sorted, piece)
    end
    table.sort(sorted, function(a, b)
        return armor_sort_key(a) < armor_sort_key(b)
    end)

    local packed = {}
    for _, piece in ipairs(sorted) do
        table.insert(packed, piece)
        if #packed >= GEAR_SLOTS then break end
    end
    return packed
end

local function build_layout(gear, gear_sz)
    local held = gear and gear.held
    local packed = pack_gear(gear and gear.armor)
    local held_sz = math.floor(gear_sz * 1.28)
    local gap = 5
    local row_w = GEAR_SLOTS * gear_sz + (GEAR_SLOTS - 1) * gap

    return {
        held = held,
        packed = packed,
        filled = #packed,
        gear_sz = gear_sz,
        held_sz = held_sz,
        gap = gap,
        row_w = row_w,
        row_gap = 8,
        name_fs = 11,
    }
end

local function held_piece(held)
    if not held then return nil end
    if type(held) == "table" then return held end
    return { name = held }
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
    if style == "empty" and draw.rect then
        draw.rect(x, y, size, size, EMPTY_EDGE, ROUND, 1)
    end

    if not piece then return end

    if key then
        image_cache.begin_load(key)
        if image_cache.draw_fit(key, x + pad, y + pad, size - pad * 2, size - pad * 2) then
            return
        end
        local st = image_cache.state(key)
        if st == "loading" or st == "none" then
            return
        end
    end

    local label = "?"
    if type(piece) == "table" and piece.name and piece.name ~= "" then
        label = piece.name:sub(1, 1):upper()
    end

    local fs = math.max(10, math.floor(size * 0.34))
    local tw = select(1, draw.get_text_size(label, fs))
    draw.text(
        x + size * 0.5 - tw * 0.5,
        y + size * 0.5 - fs * 0.45,
        label,
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
    menu.add_slider_int(T, G.VISUALS, P .. "_top", "Top Offset", 48, 160, 88, menu_util.parent(P))

    menu_util.bind_master(P, { P .. "_fov", P .. "_gear_size", P .. "_top" })
end

function M.refresh_target()
    if not settings.enabled(P) then
        M._target = nil
        M._layout = nil
        return
    end

    local fov = settings.num(P .. "_fov", 150)
    local gear_sz = settings.num(P .. "_gear_size", 48)
    local target = find_crosshair_target(fov)

    if target and player_state.is_combat_target(target) then
        M._target = target
        M._layout = build_layout(get_gear(target), gear_sz)
        preload_layout_images(M._layout)
    else
        M._target = nil
        M._layout = nil
    end
end

function M.update(_dt)
    M.refresh_target()
end

function M.draw()
    if not settings.enabled(P) then return end
    if not draw or not draw.text or not draw.rect_filled then return end

    M.refresh_target()

    local target = M._target
    local layout = M._layout
    if not target or not layout then return end

    local sw, _ = draw_util.screen_size()
    local top = settings.num(P .. "_top", 88)
    local cx = sw * 0.5

    local name = target.display_name or target.name or "Unknown"
    local nw = select(1, draw.get_text_size(name, layout.name_fs))
    draw.text(cx - nw * 0.5, top, name, { 1, 1, 1, 1 }, layout.name_fs)

    local y = top + layout.name_fs + 6

    local held = held_piece(layout.held)
    local held_key = held and resolve_image_key(held) or nil
    draw_slot(cx - layout.held_sz * 0.5, y, layout.held_sz, held_key, held, held and "held" or "empty")
    y = y + layout.held_sz + layout.row_gap

    local start_x = cx - layout.row_w * 0.5
    for i = 1, GEAR_SLOTS do
        local piece = i <= layout.filled and layout.packed[i] or nil
        local key = piece and resolve_image_key(piece) or nil
        local sx = start_x + (i - 1) * (layout.gear_sz + layout.gap)
        draw_slot(sx, y, layout.gear_sz, key, piece, piece and "gear" or "empty")
    end

    if not held and layout.filled == 0 then
        local hint = "No gear detected"
        local hw = select(1, draw.get_text_size(hint, 10))
        draw.text(cx - hw * 0.5, y + layout.gear_sz + 6, hint, { 0.55, 0.55, 0.58, 0.85 }, 10)
    end
end

return M
