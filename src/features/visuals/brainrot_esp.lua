local settings = April.require("core.settings")
local cache = April.require("core.cache")
local env = April.require("core.env")
local esp_util = April.require("core.esp_util")
local esp_scan = April.require("game.esp_scan")
local menu_util = April.require("core.menu_util")
local image_cache = April.require("core.image_cache")
local catalog = April.require("game.brainrot_catalog")

local M = {}

local P = "april_brainrot_enabled"
local P_STYLE = "april_brainrot_style"
local P_SIZE = "april_brainrot_size"

local _active_key = nil

local function labels()
    return catalog.combo_labels()
end

local function selected_entry()
    local idx = settings.combo_index(P_STYLE, labels(), 0)
    return catalog.entry_at_index(idx)
end

local function active_key()
    local entry = selected_entry()
    if not entry then return nil end
    return catalog.image_key(entry.file)
end

local function ensure_image(key, file)
    if not key or not file then return end
    image_cache.ensure(key, catalog.url(file))
end

local function draw_bounds(bounds)
    if not bounds or not bounds.valid then return false end

    local key = active_key()
    if not key then return false end

    local min_sz = settings.num(P_SIZE, 48)
    local w = math.max(min_sz, math.floor(bounds.w or min_sz))
    local h = math.max(min_sz, math.floor(bounds.h or min_sz))

    image_cache.begin_load(key)
    return image_cache.draw_fit(key, bounds.x, bounds.y, w, h)
end

local function draw_entry(entry)
    if not entry then return end
    if entry.inst and not env.is_valid(entry.inst) then return end
    if entry.entity and entry.entity.is_alive == false then return end

    local bounds = esp_util.entry_screen_bounds(entry)
    if bounds then
        draw_bounds(bounds)
        return
    end

    local lx, ly, lz
    if entry.lx then
        lx, ly, lz = entry.lx, entry.ly, entry.lz
    elseif entry.entity and entry.entity.position then
        lx, ly, lz = entry.entity.position.x, entry.entity.position.y, entry.entity.position.z
    else
        lx, ly, lz = esp_scan.entry_coords(entry)
    end

    if lx then
        draw_bounds(esp_util.point_screen_bounds(lx, ly, lz, settings.num(P_SIZE, 48)))
    end
end

local function draw_cache_list(list)
    for _, entry in ipairs(list or {}) do
        draw_entry(entry)
    end
end

local function draw_players()
    if not entity or not entity.get_players then return end

    for _, p in ipairs(entity.get_players()) do
        if p.is_local then goto continue end

        local bounds
        if p.get_bounds then
            bounds = p:get_bounds()
        end

        if bounds and bounds.valid and bounds.w > 0 and bounds.h > 0 then
            draw_bounds(bounds)
        elseif p.position then
            draw_bounds(esp_util.point_screen_bounds(
                p.position.x, p.position.y, p.position.z,
                settings.num(P_SIZE, 64)
            ))
        end

        ::continue::
    end
end

local function draw_npcs()
    for _, entry in ipairs(cache.npcs or {}) do
        if entry.entity then
            if entry.entity.is_alive == false then goto continue end
            local bounds = entry.entity.get_bounds and entry.entity:get_bounds()
            if bounds and bounds.valid then
                draw_bounds(bounds)
                goto continue
            end
        end
        draw_entry(entry)
        ::continue::
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)
    local root = menu_util.parent(P)

    menu_util.register_keybind(T, G.VISUALS, P, "Brainrot ESP", false)
    menu.add_combo(T, G.VISUALS, P_STYLE, "Character", labels(), 0, root)
    menu.add_slider_int(T, G.VISUALS, P_SIZE, "Min Box Size", 24, 160, 48, root)

    menu_util.bind_children(P, { P_STYLE, P_SIZE })
end

function M.init()
    for _, entry in ipairs(catalog.ENTRIES) do
        ensure_image(catalog.image_key(entry.file), entry.file)
    end
end

function M.update(_dt)
    if not settings.enabled(P) then
        _active_key = nil
        return
    end

    local key = active_key()
    if key ~= _active_key then
        _active_key = key
        local entry = selected_entry()
        if entry then
            ensure_image(key, entry.file)
        end
    end
end

function M.draw()
    if not settings.enabled(P) then return end

    local entry = selected_entry()
    if entry then
        ensure_image(active_key(), entry.file)
    end

    draw_cache_list(cache.world)
    draw_cache_list(cache.loot)
    draw_cache_list(cache.base)
    draw_npcs()
    draw_players()
end

return M
