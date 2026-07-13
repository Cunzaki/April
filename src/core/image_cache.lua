local asset_urls = April.require("game.asset_urls")
local debug = April.require("core.debug")

local M = {}

local keys = {}

local function url_for(asset_id_or_url)
    if type(asset_id_or_url) == "string" and asset_id_or_url:find("https://", 1, true) then
        return asset_id_or_url
    end
    return asset_urls.item_png(asset_id_or_url)
end

function M.ensure(key, asset_id_or_url)
    if keys[key] then return keys[key] end
    local url = url_for(asset_id_or_url)
    if not url then return nil end
    local asset_id = type(asset_id_or_url) == "number" and asset_id_or_url
        or (type(asset_id_or_url) == "string" and asset_id_or_url:match("^(%d+)$"))
    keys[key] = {
        url = url,
        asset_id = asset_id and tostring(asset_id) or nil,
        handle = nil,
        failed = false,
        fallback_idx = 0,
    }
    return keys[key]
end

function M.register(key, asset_id_or_url)
    return M.ensure(key, asset_id_or_url)
end

local FALLBACKS = { "roblox_thumb", "asset_delivery" }

local function fallback_url(kind, asset_id)
    if kind == "roblox_thumb" then
        return asset_urls.roblox_thumb(asset_id)
    elseif kind == "asset_delivery" then
        return asset_urls.asset_delivery(asset_id)
    end
    return nil
end

local function try_fallback(entry, key)
    while entry.fallback_idx < #FALLBACKS do
        entry.fallback_idx = entry.fallback_idx + 1
        local url = fallback_url(FALLBACKS[entry.fallback_idx], entry.asset_id)
        if url and url ~= entry.url then
            entry.url = url
            entry.handle = nil
            entry.failed = false
            return true
        end
    end
    return false
end

local function get_handle(key)
    local entry = keys[key]
    if not entry or entry.failed or not draw or not draw.load_image then
        return nil
    end

    if not entry.handle then
        entry.handle = draw.load_image(entry.url)
        return nil
    end

    if draw.image_loaded and draw.image_loaded(entry.handle) then
        return entry.handle
    end

    if draw.image_failed and draw.image_failed(entry.handle) then
        if try_fallback(entry, key) then
            return nil
        end
        debug.warn_once("img:" .. key, "load failed - " .. tostring(entry.url))
        entry.failed = true
        entry.handle = nil
        return nil
    end

    return nil
end

local function draw_image(handle, x, y, w, h, col)
    if col and type(col) == "table" then
        local r = math.floor((col[1] or 1) * 255)
        local g = math.floor((col[2] or 1) * 255)
        local b = math.floor((col[3] or 1) * 255)
        local a = math.floor((col[4] or 1) * 255)
        draw.image(handle, x, y, w, h, r, g, b, a)
    else
        draw.image(handle, x, y, w, h, 255, 255, 255, 255)
    end
end

function M.draw_fit(key, x, y, w, h, col)
    if not draw or not draw.image then return false end

    local handle = get_handle(key)
    if not handle then return false end

    w = math.max(w or 0, 8)
    h = math.max(h or 0, 8)
    draw_image(handle, x, y, w, h, col)
    return true
end

function M.state(key)
    local entry = keys[key]
    if not entry then return "none" end
    if entry.failed then return "failed" end
    if not entry.handle then return "loading" end
    if draw and draw.image_loaded and draw.image_loaded(entry.handle) then
        return "ready"
    end
    if draw and draw.image_failed and draw.image_failed(entry.handle) then
        if try_fallback(entry, key) then
            return "loading"
        end
        entry.failed = true
        entry.handle = nil
        return "failed"
    end
    return "loading"
end

function M.is_ready(key)
    return M.state(key) == "ready"
end

function M.preload(key, asset_id_or_url)
    M.ensure(key, asset_id_or_url)
    get_handle(key)
end

function M.begin_load(key)
    if not key then return end
    get_handle(key)
end

function M.draw_at_world(key, wx, wy, wz, size)
    if not draw or not draw.image or not utility or not utility.world_to_screen then
        return false
    end

    local handle = get_handle(key)
    if not handle then return false end

    local sx, sy, vis = utility.world_to_screen(wx, wy, wz)
    if not vis then return false end

    size = size or 64
    local hs = math.floor(size * 0.5)
    draw.image(handle, sx - hs, sy - hs, size, size, 255, 255, 255, 255)
    return true
end

return M
