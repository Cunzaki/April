local settings = April.require("core.settings")
local cache = April.require("core.cache")
local esp_util = April.require("core.esp_util")
local player_state = April.require("game.player_state")
local menu_util = April.require("core.menu_util")
local image_cache = April.require("core.image_cache")
local asset_urls = April.require("game.asset_urls")

local M = {}
local P = "april_tung_esp_enabled"
local TUNG_KEY = "tung"

local function draw_tung_box(x, y, w, h)
    w = math.max(12, math.floor(w or 12))
    h = math.max(12, math.floor(h or 12))
    image_cache.begin_load(TUNG_KEY)
    return image_cache.draw_fit(TUNG_KEY, x, y, w, h)
end

function M.register_menu()
end

function M.scan()
    cache.players = {}
    if not entity or not entity.get_players then return end
    for _, p in ipairs(entity.get_players()) do
        if p.is_valid and not p.is_local and player_state.is_combat_target(p) then
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

function M.update(_dt) end

function M.draw()
    if not settings.enabled(P) then return end

    local max_dist = settings.num("april_tung_esp_max_dist", 1000)
    local me = entity and entity.get_local_player and entity.get_local_player()

    for _, p in ipairs(M.get_players()) do
        if p.is_local or not player_state.is_combat_target(p) then goto continue end

        if me and me.position and p.position then
            local dx = p.position.x - me.position.x
            local dy = p.position.y - me.position.y
            local dz = p.position.z - me.position.z
            local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
            if dist > max_dist then goto continue end
        end

        local b = p:get_bounds()
        if b and b.valid and b.w > 0 and b.h > 0 then
            draw_tung_box(b.x, b.y, b.w, b.h)
        end

        ::continue::
    end
end

return M
