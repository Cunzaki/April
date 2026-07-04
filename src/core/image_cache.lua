--[[ Async image loader — April/docs/API.md: load_image in on_frame, wait for image_loaded. ]]

local asset_urls = April.require("game.asset_urls")

local M = {}

local entries = {}

function M.urls_for_tung()
    return asset_urls.urls_for_tung()
end

local function urls_for(asset_id_or_urls)
    if type(asset_id_or_urls) == "table" then
        return asset_id_or_urls
    end
    if type(asset_id_or_urls) == "string" then
        local id = asset_id_or_urls:match("(%d+)")
        if asset_id_or_urls:find("http", 1, true) and not id then
            return { asset_id_or_urls }
        end
        if id then
            return asset_urls.urls_for_item(id)
        end
    end
    return asset_urls.urls_for_item(asset_id_or_urls)
end

function M.register(key, asset_id_or_urls)
    if entries[key] then return entries[key] end
    entries[key] = {
        urls = urls_for(asset_id_or_urls),
        url_index = 1,
        handle = nil,
        failed = false,
    }
    return entries[key]
end

function M.ensure(key, asset_id_or_urls)
    if not entries[key] then
        M.register(key, asset_id_or_urls)
    end
    return entries[key]
end

function M.tick(key)
    local entry = entries[key]
    if not entry or entry.failed or not draw or not draw.load_image then return end

    local url = entry.urls[entry.url_index]
    if not url then
        entry.failed = true
        return
    end

    if not entry.handle then
        entry.handle = draw.load_image(url)
        return
    end

    if draw.image_loaded and draw.image_loaded(entry.handle) then
        return
    end

    if draw.image_failed and draw.image_failed(entry.handle) then
        if draw.free_image then
            pcall(function() draw.free_image(entry.handle) end)
        end
        entry.handle = nil
        entry.url_index = entry.url_index + 1
        if entry.url_index > #entry.urls then
            entry.failed = true
        end
    end
end

function M.tick_all()
    for key, _ in pairs(entries) do
        M.tick(key)
    end
end

function M.ready(key)
    local entry = entries[key]
    if not entry or not entry.handle then return false end
    return draw and draw.image_loaded and draw.image_loaded(entry.handle)
end

function M.handle(key)
    local entry = entries[key]
    return entry and entry.handle
end

function M.draw_fit(key, x, y, w, h, col)
    M.tick(key)
    if not M.ready(key) or not draw.image then return false end

    local handle = M.handle(key)
    local iw, ih = draw.image_size(handle)
    if not iw or iw <= 0 or not ih or ih <= 0 then return false end

    w = math.max(w or 0, 8)
    h = math.max(h or 0, 8)

    local dw = w
    local dh = math.floor(w * ih / iw)
    if dh < h then
        dh = h
        dw = math.floor(h * iw / ih)
    end

    local dx = x + (w - dw) * 0.5
    local dy = y + (h - dh) * 0.5

    if col then
        draw.image(handle, dx, dy, dw, dh, col)
    else
        draw.image(handle, dx, dy, dw, dh)
    end
    return true
end

function M.draw_at_world(key, wx, wy, wz, display_w)
    M.tick(key)
    if not M.ready(key) then return false end

    local sx, sy, vis
    if draw and draw.world_to_screen then
        sx, sy, vis = draw.world_to_screen(wx, wy, wz)
    elseif utility and utility.world_to_screen then
        sx, sy, vis = utility.world_to_screen(wx, wy, wz)
    end
    if not vis then return false end

    local handle = M.handle(key)
    local iw, ih = draw.image_size(handle)
    if not iw or iw <= 0 or not ih or ih <= 0 then return false end

    display_w = display_w or 64
    local dh = math.floor(display_w * ih / iw)

    draw.image(handle, sx - display_w * 0.5, sy - dh, display_w, dh)
    return true
end

return M
