--[[
    Vector on_frame pattern (stable v3.65-3.69):
      handle = draw.load_image(url) once
      draw.image(handle, x, y, w, h, 255, 255, 255, 255) every frame - no-ops until ready
    Do NOT gate on draw.image_loaded; that breaks gear icons on Vector.
]]

local asset_urls = April.require("game.asset_urls")
local debug = April.require("core.debug")

local M = {}

local keys = {}
local RETRY_MS = 5000
local MAX_ENTRIES = 384
local key_count = 0

local function tick_ms()
    local fn = utility and (utility.get_tick_count or utility.GetTickCount)
    if type(fn) ~= "function" then return 0 end
    local ok, value = pcall(fn)
    return ok and (tonumber(value) or 0) or 0
end

local function url_for(asset_id_or_url)
    if type(asset_id_or_url) == "string" then
        if asset_id_or_url:find("https://", 1, true)
            or asset_id_or_url:find("http://", 1, true)
            or asset_id_or_url:find("rbxassetid://", 1, true) then
            return asset_id_or_url
        end
    end
    return asset_urls.item_png(asset_id_or_url)
end

local function asset_digits(asset_id_or_url)
    if asset_id_or_url == nil then return nil end
    if type(asset_id_or_url) == "number" then return tostring(asset_id_or_url) end
    return tostring(asset_id_or_url):match("(%d+)$") or tostring(asset_id_or_url):match("^(%d+)$")
end

local function is_pinned(key)
    return key == "startup_author_profile"
        or tostring(key):find("^anime_baddie:") ~= nil
end

local function free_handle(entry)
    if not entry or not entry.handle then return end
    local fn = draw and (draw.free_image or draw.FreeImage)
    if type(fn) == "function" then pcall(fn, entry.handle) end
    entry.handle = nil
end

local function evict_cold()
    while key_count >= MAX_ENTRIES do
        local oldest_key, oldest_at = nil, math.huge
        for key, entry in pairs(keys) do
            if not is_pinned(key) and (entry.last_used or 0) < oldest_at then
                oldest_key = key
                oldest_at = entry.last_used or 0
            end
        end
        if not oldest_key then return end
        free_handle(keys[oldest_key])
        keys[oldest_key] = nil
        key_count = key_count - 1
    end
end

function M.ensure(key, asset_id_or_url)
    if keys[key] then
        keys[key].last_used = tick_ms()
        return keys[key]
    end

    local urls = nil
    local url = nil
    local asset_src = asset_id_or_url

    if type(asset_id_or_url) == "table" then
        urls = asset_id_or_url
        url = urls[1]
        asset_src = nil
    else
        url = url_for(asset_id_or_url)
    end
    if not url then return nil end

    evict_cold()
    keys[key] = {
        url = url,
        urls = urls,
        url_idx = 1,
        asset_id = asset_digits(asset_src),
        handle = nil,
        failed = false,
        retry_at = 0,
        fallback = false,
        last_used = tick_ms(),
    }
    key_count = key_count + 1
    return keys[key]
end

function M.register(key, asset_id_or_url)
    return M.ensure(key, asset_id_or_url)
end

local function try_fallback(entry)
    if entry.urls then
        local idx = (entry.url_idx or 1) + 1
        local next_url = entry.urls[idx]
        if not next_url then return false end
        entry.url_idx = idx
        entry.url = next_url
        free_handle(entry)
        entry.failed = false
        return true
    end

    if not entry.asset_id then return false end
    entry.fallback_idx = (entry.fallback_idx or 0) + 1
    local chain = {
        asset_urls.roblox_thumb(entry.asset_id),
        asset_urls.asset_delivery(entry.asset_id),
    }
    local fb = chain[entry.fallback_idx]
    if not fb or fb == entry.url then return false end
    entry.url = fb
    free_handle(entry)
    entry.failed = false
    return true
end

local function image_failed(handle)
    if not handle or not draw then return false end
    local fn = draw.image_failed or draw.ImageFailed
    if not fn then return false end
    local ok, yes = pcall(fn, handle)
    return ok and yes == true
end

local function get_handle(key)
    local entry = keys[key]
    if not entry or not draw or not draw.load_image then
        return nil
    end
    entry.last_used = tick_ms()
    if entry.failed then
        if tick_ms() < (entry.retry_at or 0) then return nil end
        entry.failed = false
        free_handle(entry)
        entry.url_idx = 1
        if entry.urls then entry.url = entry.urls[1] end
    end

    if not entry.handle then
        local ok, handle = pcall(draw.load_image, entry.url)
        if ok and handle then
            entry.handle = handle
        else
            if try_fallback(entry) then return nil end
            debug.warn_once("img:" .. key, "load failed - " .. tostring(entry.url))
            entry.failed = true
            entry.retry_at = tick_ms() + RETRY_MS
            return nil
        end
    end

    if image_failed(entry.handle) then
        if try_fallback(entry) then
            return nil
        end
        debug.warn_once("img:" .. key, "load failed - " .. entry.url)
        entry.failed = true
        entry.retry_at = tick_ms() + RETRY_MS
        free_handle(entry)
        return nil
    end

    return entry.handle
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
    if entry.failed then
        if tick_ms() >= (entry.retry_at or 0) then
            entry.failed = false
            free_handle(entry)
            entry.url_idx = 1
            if entry.urls then entry.url = entry.urls[1] end
            return "loading"
        end
        return "failed"
    end
    if not entry.handle then return "loading" end
    if image_failed(entry.handle) then
        if try_fallback(entry) then
            return "loading"
        end
        entry.failed = true
        entry.retry_at = tick_ms() + RETRY_MS
        free_handle(entry)
        return "failed"
    end
    return "ready"
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
