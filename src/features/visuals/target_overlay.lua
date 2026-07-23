local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local menu_util = April.require("core.menu_util")
local image_cache = April.require("core.image_cache")
local items = April.require("game.items")
local player_gear = April.require("game.player_gear")
local player_state = April.require("game.player_state")
local active_target = April.require("features.combat.active_target")
local text_util = April.require("core.text_util")
local theme = April.require("core.ui_theme")
local overlay_theme = April.require("core.overlay_theme")

local M = {}

local P = "april_target_overlay"
local GEAR_SLOTS = 7
local GEAR_TTL = 500
local TARGET_POLL_MS = 120
local MAX_ATTACHMENTS = 5

local gear_cache = {}
local last_poll_ms = 0

M._target = nil
M._layout = nil

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

    return nil
end

local function find_overlay_target()
    local target = active_target.get_target(nil, active_target.SOURCE_GEAR)
    if target then return target end
    return nil
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

local function pack_attachments(list)
    local packed = {}
    for i = 1, math.min(#(list or {}), MAX_ATTACHMENTS) do
        packed[#packed + 1] = list[i]
    end
    return packed
end

local function build_layout(gear, gear_sz)
    local held = gear and gear.held
    local packed = pack_gear(gear and gear.armor)
    local attachments = pack_attachments(gear and gear.attachments)
    local held_sz = math.floor(gear_sz * 1.28)
    local att_sz = math.floor(gear_sz * 0.78)
    local gap = 5
    local att_gap = 4
    local row_w = GEAR_SLOTS * gear_sz + (GEAR_SLOTS - 1) * gap
    local att_row_w = #attachments > 0 and (#attachments * att_sz + (#attachments - 1) * att_gap) or 0
    local held_row_w = held_sz + (#attachments > 0 and (10 + att_row_w) or 0)
    local panel_w = math.max(row_w, held_row_w)

    local layout = {
        held = held,
        attachments = attachments,
        packed = packed,
        filled = #packed,
        gear_sz = gear_sz,
        held_sz = held_sz,
        att_sz = att_sz,
        gap = gap,
        att_gap = att_gap,
        row_w = row_w,
        held_row_w = held_row_w,
        panel_w = panel_w,
        row_gap = 8,
        name_fs = 11,
        held_key = nil,
        att_keys = {},
        gear_keys = {},
    }

    layout.held_key = held and resolve_image_key(held) or nil
    for i = 1, layout.filled do
        layout.gear_keys[i] = resolve_image_key(packed[i])
        local key = layout.gear_keys[i]
        if key then image_cache.begin_load(key) end
    end
    for i = 1, #attachments do
        layout.att_keys[i] = resolve_image_key(attachments[i])
        local key = layout.att_keys[i]
        if key then image_cache.begin_load(key) end
    end
    if layout.held_key then
        image_cache.begin_load(layout.held_key)
    end

    return layout
end

local function held_piece(held)
    if not held then return nil end
    if type(held) == "table" then
        if held.name and player_gear.is_empty_held_name and player_gear.is_empty_held_name(held.name) then
            return nil
        end
        return held
    end
    if player_gear.is_empty_held_name and player_gear.is_empty_held_name(held) then
        return nil
    end
    return { name = held }
end

local function split_words(text)
    local words = {}
    for word in text:gmatch("%S+") do
        words[#words + 1] = word
    end
    return words
end

local function wrap_words(words, max_w, fs)
    local lines = {}
    local i = 1
    while i <= #words do
        local line = words[i]
        local j = i + 1
        while j <= #words do
            local try = line .. " " .. words[j]
            if select(1, draw.get_text_size(try, fs)) <= max_w then
                line = try
                j = j + 1
            else
                break
            end
        end
        lines[#lines + 1] = line
        i = j
    end
    return lines
end

local function words_fit(words, fs, max_w)
    for _, word in ipairs(words) do
        if select(1, draw.get_text_size(word, fs)) > max_w then
            return false
        end
    end
    return true
end

local function slot_label(piece)
    if type(piece) ~= "table" then return nil end
    local name = piece.name
    if not name or name == "" then return nil end

    name = text_util.sanitize(name)
    local base, slash_var = name:match("^([^/]+)/(.+)$")
    if base and slash_var then
        return base .. " " .. slash_var
    end

    local variant = piece.variant
    if variant and variant ~= "" and variant ~= "Default" then
        return name .. " " .. text_util.sanitize(variant)
    end
    return name
end

local function draw_fitted_label(x, y, size, text)
    if not draw or not draw.text or not draw.get_text_size then return end

    text = text_util.sanitize(text)
    if text == "" then return end

    local pad = 4
    local inner = size - pad * 2
    local words = split_words(text)
    if #words == 0 then return end

    local max_fs = math.max(8, math.floor(size * 0.26))
    local min_fs = 6
    local chosen_fs, chosen_lines

    for fs = max_fs, min_fs, -1 do
        if words_fit(words, fs, inner) then
            local lines = wrap_words(words, inner, fs)
            local line_h = fs + 1
            if #lines * line_h <= inner then
                chosen_fs = fs
                chosen_lines = lines
                break
            end
        end
    end

    if not chosen_lines then
        chosen_fs = min_fs
        chosen_lines = wrap_words(words, inner, min_fs)
    end

    local line_h = chosen_fs + 1
    local total_h = #chosen_lines * line_h
    local ty = y + pad + (inner - total_h) * 0.5

    for i, line in ipairs(chosen_lines) do
        local tw = select(1, draw.get_text_size(line, chosen_fs))
        draw.text(
            x + size * 0.5 - tw * 0.5,
            ty + (i - 1) * line_h,
            line,
            theme.TEXT_MUTED,
            chosen_fs
        )
    end
end

local function draw_slot(x, y, size, key, piece, style)
    local pad = 3
    local bg = overlay_theme.slot()
    local edge = overlay_theme.border()

    if style == "held" then
        bg = overlay_theme.slot("held")
        edge = theme.alpha(overlay_theme.accent(), 0.88)
    elseif style == "attachment" then
        bg = theme.alpha(overlay_theme.slot(), 0.82)
    elseif style == "empty" then
        bg = overlay_theme.slot("empty")
        edge = theme.alpha(theme.BORDER, 0.28)
    end

    draw.rect_filled(x, y, size, size, bg, 0)
    if draw.rect then
        draw.rect(x, y, size, size, edge, 0, style == "held" and 1.5 or 1)
    end
    if style == "held" and draw.rect_filled then
        draw.rect_filled(x + 1, y + 1, size - 2, 2, overlay_theme.accent(), 0)
    end

    if not piece then return end

    if key and image_cache.draw_fit(key, x + pad, y + pad, size - pad * 2, size - pad * 2) then
        return
    end
    if key and image_cache.state(key) ~= "failed" then
        return
    end

    local label = slot_label(piece)
    if label then
        draw_fitted_label(x, y, size, label)
    end
end

local function same_target(a, b)
    if a == b then return true end
    if not a or not b then return false end
    local aid = a.user_id or a.name
    local bid = b.user_id or b.name
    return aid and bid and aid == bid
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)

    menu_util.section(T, G.VISUALS, "Target Gear")
    menu_util.register_keybind(T, G.VISUALS, P, "Target Gear Overlay", false)

    local root = menu_util.parent(P)
    menu.add_combo(T, G.VISUALS, "april_target_gear_source", "Target From",
        active_target.SOURCE_NAMES, 0, root)
    menu.add_slider_int(T, G.VISUALS, P .. "_gear_size", "Gear Icon Size", 32, 64, 48, root)
    menu.add_slider_int(T, G.VISUALS, P .. "_top", "Top Offset", 48, 160, 88, root)

    menu_util.bind_children(P, {
        "april_target_gear_source", P .. "_gear_size", P .. "_top",
    })
end

function M.refresh_target()
    if not settings.enabled(P) then
        M._target = nil
        M._layout = nil
        return
    end

    local gear_sz = settings.num(P .. "_gear_size", 48)

    local target = find_overlay_target()

    if not target or not player_state.is_combat_target(target) then
        M._target = nil
        M._layout = nil
        return
    end

    local target_changed = not same_target(M._target, target)
    local uid = target.user_id or target.name or "?"
    local cached = gear_cache[uid]
    local gear_stale = not cached or (tick_ms() - cached.t) >= GEAR_TTL

    M._target = target

    if target_changed or not M._layout or gear_stale then
        M._layout = build_layout(get_gear(target), gear_sz)
    end
end

function M.update(_dt)
    if not settings.enabled(P) then
        M._target = nil
        M._layout = nil
        return
    end

    local now = tick_ms()
    if now - last_poll_ms < TARGET_POLL_MS then return end
    last_poll_ms = now

    M.refresh_target()
end

function M.draw()
    if not settings.enabled(P) then return end
    if not draw or not draw.text or not draw.rect_filled then return end

    overlay_theme.sync()
    local target = M._target
    local layout = M._layout
    if not target or not layout then return end

    local sw, _ = draw_util.screen_size()
    local top = settings.num(P .. "_top", 88)
    local cx = sw * 0.5

    local name = text_util.sanitize(target.display_name or target.name or "Unknown")
    local content_w = math.max(layout.held_row_w, layout.row_w)
    local panel_w = math.max(220, content_w + 18)
    local panel_h = 24 + 8 + layout.held_sz + layout.row_gap + layout.gear_sz + 9
    if not held_piece(layout.held) and layout.filled == 0 then
        panel_h = panel_h + 16
    end
    local panel_x = cx - panel_w * 0.5
    overlay_theme.draw_panel(panel_x, top, panel_w, panel_h, "TARGET LOADOUT", { title_center = true })

    local max_name_w = panel_w - 114
    local header_name = name
    while #header_name > 1 and select(1, draw.get_text_size(header_name, 10)) > max_name_w do
        header_name = header_name:sub(1, -2)
    end
    if header_name ~= name then header_name = header_name .. ".." end
    local nw = select(1, draw.get_text_size(header_name, 10))
    draw.text(panel_x + panel_w - nw - 8, top + 7, header_name, overlay_theme.accent(), 10)

    local y = top + 32
    local held = held_piece(layout.held)
    local row_x = cx - layout.held_row_w * 0.5

    draw_slot(row_x, y, layout.held_sz, layout.held_key, held, held and "held" or "empty")

    if #layout.attachments > 0 then
        local ax = row_x + layout.held_sz + 10
        for i = 1, #layout.attachments do
            local sx = ax + (i - 1) * (layout.att_sz + layout.att_gap)
            draw_slot(sx, y + (layout.held_sz - layout.att_sz) * 0.5, layout.att_sz, layout.att_keys[i], layout.attachments[i], "attachment")
        end
    end

    y = y + layout.held_sz + layout.row_gap

    local start_x = cx - layout.row_w * 0.5
    for i = 1, GEAR_SLOTS do
        local piece = i <= layout.filled and layout.packed[i] or nil
        local sx = start_x + (i - 1) * (layout.gear_sz + layout.gap)
        draw_slot(sx, y, layout.gear_sz, layout.gear_keys[i], piece, piece and "gear" or "empty")
    end

    if not held and layout.filled == 0 then
        local hint = "No gear detected"
        local hw = select(1, draw.get_text_size(hint, 10))
        draw.text(cx - hw * 0.5, y + layout.gear_sz + 6, hint, theme.TEXT_DIM, 10)
    end
end

return M
