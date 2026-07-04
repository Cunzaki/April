local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local menu_util = April.require("core.menu_util")
local image_cache = April.require("core.image_cache")
local asset_urls = April.require("game.asset_urls")

local M = {}
local P = "april_esp_enabled"
local TUNG_KEY = "tung"

local BOX_LABELS = { "None", "2D", "Corner", "Tung" }

local function box_mode()
    return settings.combo_index("april_esp_box_mode", BOX_LABELS, 0)
end

local function is_tung_mode()
    return box_mode() == 3
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)
    local root = menu_util.parent(P)

    menu.add_label(T, G.VISUALS, "Player ESP")
    menu.add_checkbox(T, G.VISUALS, P, "Player ESP", false, { key = 0 })
    menu.add_combo(T, G.VISUALS, "april_esp_box_mode", "Box Mode", { "None", "2D", "Corner", "Tung" }, 0, root)
    menu.add_checkbox(T, G.VISUALS, "april_esp_name", "Name", false, menu_util.parent(P, { colorpicker = { 1, 1, 1, 1 } }))
    menu.add_checkbox(T, G.VISUALS, "april_esp_health", "Health Bar", false, root)
    menu.add_checkbox(T, G.VISUALS, "april_esp_distance", "Distance", false, menu_util.parent(P, { colorpicker = { 0.7, 0.7, 0.7, 1 } }))
    menu.add_checkbox(T, G.VISUALS, "april_esp_skeleton", "Skeleton", false, menu_util.parent(P, { colorpicker = { 1, 1, 1, 0.85 } }))
    menu.add_checkbox(T, G.VISUALS, "april_esp_offscreen", "Offscreen Arrows", false, menu_util.parent(P, { colorpicker = { 0.3, 1, 0.5, 1 } }))
    menu.add_colorpicker(T, G.VISUALS, "april_esp_box_color", "Box Color", { 0.3, 1, 0.5, 1 }, root)
    menu.add_slider_int(T, G.VISUALS, "april_esp_max_dist", "Max Distance", 50, 5000, 1000, root)
end

function M.scan()
    cache.players = {}
    if not entity or not entity.get_players then return end
    for _, p in ipairs(entity.get_players()) do
        if p.is_valid and not p.is_local then
            table.insert(cache.players, p)
        end
    end
    cache.stats.last_player_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.get_players()
    if entity and entity.get_players then
        return entity.get_players()
    end
    return cache.players
end

function M.init()
    image_cache.ensure(TUNG_KEY, asset_urls.tung_png())
end

function M.update(_dt)
    -- images load lazily on first draw call (Vector upload pattern)
end

local function draw_tung(p, b)
    if b and b.valid and b.w > 0 and b.h > 0 then
        if image_cache.draw_fit(TUNG_KEY, b.x, b.y, b.w, b.h) then
            return
        end
    end

    local pos = p.head_position or p.position
    if not pos then return end

    local display_w = 72
    if b and b.valid and b.w > 0 then
        display_w = math.max(48, math.floor(b.w))
    end

    image_cache.draw_at_world(
        TUNG_KEY,
        pos.x,
        pos.y + 1,
        pos.z,
        display_w
    )
end

function M.draw()
    if not settings.bool(P, false) then return end

    local max_dist = settings.num("april_esp_max_dist", 1000)
    local col = settings.color("april_esp_box_color", { 0.3, 1, 0.5, 1 })
    local mode = box_mode()
    local tung = mode == 3
    local me = entity and entity.get_local_player and entity.get_local_player()
    local text_size = esp_util.text_size()
    local sw, sh = draw_util.screen_size()
    local cx, cy = sw * 0.5, sh * 0.5

    for _, p in ipairs(M.get_players()) do
        if p.is_local or not p.is_alive then goto continue end
        if me and me.position and p.position then
            local dx = p.position.x - me.position.x
            local dy = p.position.y - me.position.y
            local dz = p.position.z - me.position.z
            local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
            if dist > max_dist then goto continue end
        end

        local b = p:get_bounds()
        if not b or not b.valid then
            if tung and p.head_position then
                draw_tung(p, nil)
            elseif settings.bool("april_esp_offscreen", false) and p.head_position then
                local hx, hy, hvis = esp_util.w2s(p.head_position.x, p.head_position.y, p.head_position.z)
                if not hvis then
                    local ac = settings.color("april_esp_offscreen", { 0.3, 1, 0.5, 1 })
                    esp_util.draw_offscreen_arrow(cx, cy, hx ~= 0 and hx or cx, hy ~= 0 and hy or cy, ac, 12)
                end
            end
            goto continue
        end

        if tung then
            draw_tung(p, b)
        elseif mode == 1 then
            draw_util.box_esp(b.x, b.y, b.w, b.h, col, 0)
        elseif mode == 2 then
            draw_util.box_esp(b.x, b.y, b.w, b.h, col, 1)
        end

        if settings.bool("april_esp_health", false) then
            draw_util.health_bar(b.x - 4, b.y, b.h, p.health, p.max_health)
        end

        if settings.bool("april_esp_skeleton", false) then
            local sk_col = settings.color("april_esp_skeleton", { 1, 1, 1, 0.85 })
            esp_util.draw_player_skeleton(p, sk_col, 1.5)
        end

        local label = ""
        if settings.bool("april_esp_name", false) then label = p.name or "?" end
        if settings.bool("april_esp_distance", false) and me and p.distance_to then
            local d = math.floor(p:distance_to(me.position))
            label = label .. (label ~= "" and " " or "") .. "[" .. d .. "m]"
        end
        if label ~= "" then
            local nc = settings.color("april_esp_name", { 1, 1, 1, 1 })
            draw_util.text_centered(b.x + b.w * 0.5, b.y - 14, label, nc, text_size)
        end

        ::continue::
    end
end

return M
