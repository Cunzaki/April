local debug = April.require("core.debug")

local M = {}
local keys = {}

function M.ensure(key, url)
    if not key or not url or url == "" then return nil end

    local entry = keys[key]
    if not entry then
        keys[key] = { url = url, handle = nil, failed = false }
        return keys[key]
    end

    if entry.url ~= url then
        entry.url = url
        entry.handle = nil
        entry.failed = false
    end
    return entry
end

function M.register(key, url)
    return M.ensure(key, url)
end

local function tick(entry)
    if not entry or entry.failed or not draw or not draw.load_image then
        return nil
    end

    if entry.handle and draw.image_loaded and draw.image_loaded(entry.handle) then
        return entry.handle
    end

    if entry.handle and draw.image_failed and draw.image_failed(entry.handle) then
        debug.warn_once("img:" .. tostring(entry.url), "load failed")
        entry.failed = true
        entry.handle = nil
        return nil
    end

    -- API.md: safe to call load_image every frame; same URL is deduplicated
    entry.handle = draw.load_image(entry.url)
    if entry.handle and draw.image_loaded and draw.image_loaded(entry.handle) then
        return entry.handle
    end
    return nil
end

function M.state(key)
    local entry = keys[key]
    if not entry then return "none" end
    if entry.failed then return "failed" end
    tick(entry)
    if entry.failed then return "failed" end
    if entry.handle and draw.image_loaded and draw.image_loaded(entry.handle) then
        return "ready"
    end
    return "loading"
end

function M.is_ready(key)
    return M.state(key) == "ready"
end

function M.begin_load(key)
    local entry = keys[key]
    if entry then tick(entry) end
end

function M.preload(key, url)
    M.ensure(key, url)
    M.begin_load(key)
end

function M.draw_fit(key, x, y, w, h)
    if not draw or not draw.image then return false end

    local entry = keys[key]
    if not entry or entry.failed then return false end

    local handle = tick(entry)
    if not handle then return false end

    w = math.max(w or 0, 8)
    h = math.max(h or 0, 8)
    -- API.md April pattern: 0-255 RGBA integer color args
    draw.image(handle, x, y, w, h, 255, 255, 255, 255)
    return true
end

function M.draw_at_world(key, wx, wy, wz, size)
    if not draw or not draw.image or not utility or not utility.world_to_screen then
        return false
    end

    local entry = keys[key]
    if not entry or entry.failed then return false end

    local handle = tick(entry)
    if not handle then return false end

    local sx, sy, vis = utility.world_to_screen(wx, wy, wz)
    if not vis then return false end

    size = size or 64
    local hs = math.floor(size * 0.5)
    draw.image(handle, sx - hs, sy - hs, size, size, 255, 255, 255, 255)
    return true
end

return M
