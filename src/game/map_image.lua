-- Fallen G-map texture. Vector has no image UV crop / clip API, so zoomed
-- viewports are fetched as one pre-cropped HTTPS image and drawn inside bounds.
local env = April.require("core.env")
local asset_urls = April.require("game.asset_urls")
local config_store = April.require("core.config_store")
local debug = April.require("core.debug")

local M = {}

-- Dump: TeamNavigationController uses Vector2 origin (0,0) and 12800 stud world.
M.WORLD_SIZE = 12800
M.ORIGIN_X = 0
M.ORIGIN_Z = 0
M.DEFAULT_ASSET = "121836456123484"
M.TILE_GRID = 16
M.SOURCE_PX = 700
-- Soft ocean fill behind tiles (matches Fallen map water-ish tone).
M.OCEAN = { 0.55, 0.78, 0.90, 0.55 }

local state = {
    place_id = nil,
    asset_id = nil,
    path = nil,
    png_url = nil,
    handle = nil,
    load_url = nil,
    load_idx = 0,
    load_chain = nil,
    ready = false,
    failed = false,
    fetch_started = false,
    fetch_done = false,
    last_resolve_ms = 0,
    next_retry_ms = 0,
    crops = {}, -- crop key -> async image entry
    active_crop = nil,
}

local RETRY_MS = 30000

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function place_id()
    if not game then return "0" end
    return tostring(game.place_id or game.PlaceId or 0)
end

local function find_child(parent, name)
    if not parent or not name then return nil end
    return env.safe_call(function()
        if parent.FindFirstChild then return parent:FindFirstChild(name) end
        if parent.find_first_child then return parent:find_first_child(name) end
        return parent[name]
    end)
end

local function player_inst()
    local lp = env.get_local_player()
    if not lp then return nil end
    local ep = April.require("core.entity_props")
    return ep.player_inst(lp) or lp
end

local function read_image_prop(inst)
    if not inst then return nil end
    return env.safe_call(function()
        return inst.Image or inst.image
    end)
end

local function asset_digits(value)
    if value == nil then return nil end
    return tostring(value):match("(%d+)")
end

local function resolve_map_image_inst()
    local pl = player_inst()
    local pgui = find_child(pl, "PlayerGui")
    local main = find_child(pgui, "Main")
    local map = find_child(main, "Map")
    local frame = find_child(map, "Frame")
    local map_img = find_child(frame, "Map")
    if map_img then return map_img end

    local rs = env.get_replicated_storage()
    if not rs then
        rs = env.safe_call(function()
            if game.GetService then return game:GetService("ReplicatedStorage") end
            if game.get_service then return game.get_service("ReplicatedStorage") end
            return nil
        end)
    end
    local uis = find_child(rs, "UIs")
    main = find_child(uis, "Main")
    map = find_child(main, "Map")
    frame = find_child(map, "Frame")
    return find_child(frame, "Map")
end

function M.resolve_asset_id()
    local now = tick_ms()
    if state.asset_id and (now - (state.last_resolve_ms or 0)) < 2000 then
        return state.asset_id
    end
    state.last_resolve_ms = now

    local inst = resolve_map_image_inst()
    local raw = read_image_prop(inst)
    local id = asset_digits(raw) or M.DEFAULT_ASSET
    state.asset_id = id
    return id
end

local function maps_dir()
    return config_store.get_config_path("April_maps")
end

local function ensure_dir(dir)
    if not dir or dir == "" then return false end
    local open = io and io.open
    if type(open) ~= "function" then return false end
    local probe = open(dir .. "\\.april_dir", "w")
    if probe then
        probe:close()
        if os and os.remove then pcall(os.remove, dir .. "\\.april_dir") end
        return true
    end
    if os and os.execute then
        pcall(os.execute, 'mkdir "' .. dir .. '" >nul 2>&1')
    end
    probe = open(dir .. "\\.april_dir", "w")
    if probe then
        probe:close()
        if os and os.remove then pcall(os.remove, dir .. "\\.april_dir") end
        return true
    end
    return false
end

function M.cache_path(pid, asset_id)
    pid = tostring(pid or place_id())
    asset_id = tostring(asset_id or M.resolve_asset_id() or M.DEFAULT_ASSET)
    local dir = maps_dir()
    ensure_dir(dir)
    return dir .. "\\" .. pid .. "_" .. asset_id .. ".png"
end

local function tiles_dir(asset_id)
    asset_id = tostring(asset_id or M.resolve_asset_id() or M.DEFAULT_ASSET)
    local dir = maps_dir() .. "\\tiles\\" .. asset_id
    ensure_dir(maps_dir())
    ensure_dir(maps_dir() .. "\\tiles")
    ensure_dir(dir)
    return dir
end

local function http_get(url)
    if not utility or not url then return nil end
    local fn = utility.HttpGet or utility.http_get
    if not fn then return nil end
    local ok, body = pcall(fn, url)
    if not ok then return nil end
    if type(body) == "string" and #body > 64 then
        return body
    end
    return nil
end

local function is_png(body)
    return type(body) == "string"
        and #body >= 8
        and body:byte(1) == 0x89
        and body:byte(2) == 0x50
        and body:byte(3) == 0x4E
        and body:byte(4) == 0x47
end

local function is_jpeg(body)
    return type(body) == "string"
        and #body >= 3
        and body:byte(1) == 0xFF
        and body:byte(2) == 0xD8
        and body:byte(3) == 0xFF
end

local function is_image_bytes(body)
    return is_png(body) or is_jpeg(body)
end

local function file_is_image(path)
    local f = io and io.open and io.open(path, "rb")
    if not f then return false end
    local head = f:read(16) or ""
    f:close()
    return is_image_bytes(head)
end

local function file_exists(path)
    return path and file_is_image(path)
end

local function write_bytes(path, body)
    if not path or not is_image_bytes(body) then return false end
    local f = io.open(path, "wb")
    if not f then return false end
    f:write(body)
    f:close()
    return file_is_image(path)
end

local function parse_thumbnail_image_url(json)
    if type(json) ~= "string" then return nil end
    local completed = json:match('"state"%s*:%s*"Completed".-"imageUrl"%s*:%s*"(https://[^"]+)"')
    if completed then return completed end
    return json:match('"imageUrl"%s*:%s*"(https://[^"]+)"')
end

local function is_https(url)
    return type(url) == "string" and url:find("^https://") ~= nil
end

local function is_usable_load_url(url)
    if not is_https(url) then return false end
    -- Vector LoadImage cannot decode ashx / assetdelivery / local paths.
    if url:find("Thumbs/Asset.ashx", 1, true) then return false end
    if url:find("assetdelivery", 1, true) then return false end
    if url:find("roblox.com/asset", 1, true) then return false end
    return true
end

local function resolve_png_url(asset_id)
    local sizes = { "700x700", "512x512", "420x420" }
    for i = 1, #sizes do
        local api = asset_urls.roblox_thumbnails_api(asset_id, sizes[i])
        local body = http_get(api)
        local url = parse_thumbnail_image_url(body)
        if is_usable_load_url(url) then
            return url
        end
    end
    -- map_png CDN only if pushed; ashx is NOT usable for LoadImage.
    return asset_urls.map_png(asset_id)
end

local function download_to(path, asset_id)
    local png_url = resolve_png_url(asset_id)
    state.png_url = png_url

    -- Prefer the resolved CDN PNG first (HttpGet follows redirects; LoadImage needs the real CDN URL).
    local candidates = {
        png_url,
        asset_urls.map_png(asset_id),
        asset_urls.roblox_thumb_hq(asset_id),
        asset_urls.roblox_thumb(asset_id),
    }

    for i = 1, #candidates do
        local url = candidates[i]
        if url then
            local body = http_get(url)
            if body and is_image_bytes(body) and write_bytes(path, body) then
                -- Keep the resolved CDN URL for LoadImage even if ashx was used to fetch bytes.
                if is_usable_load_url(url) then
                    state.png_url = url
                elseif is_usable_load_url(png_url) then
                    state.png_url = png_url
                else
                    state.png_url = url
                end
                return true, state.png_url
            end
        end
    end
    return false, png_url
end

local function to_file_url(path)
    if not path then return nil end
    local normalized = path:gsub("\\", "/")
    if normalized:match("^[A-Za-z]:") then
        return "file:///" .. normalized
    end
    return "file://" .. normalized
end

local function build_load_chain(path, asset_id, png_url)
    local chain = {}
    local seen = {}

    local function add(url)
        if not is_usable_load_url(url) or seen[url] then return end
        seen[url] = true
        chain[#chain + 1] = url
    end

    -- Prefer live Roblox CDN PNG (proven to work with Vector LoadImage).
    add(png_url)
    add(resolve_png_url(asset_id))
    add(asset_urls.map_png(asset_id))
    return chain
end

local function invalidate_handle()
    if state.handle and draw and draw.free_image then
        pcall(draw.free_image, state.handle)
    end
    state.handle = nil
    state.ready = false
    state.failed = false
    state.load_idx = 0
    state.load_chain = nil
    state.load_url = nil
end

local function invalidate_crops()
    if draw and draw.free_image then
        for _, crop in pairs(state.crops) do
            if crop and crop.handle then
                pcall(draw.free_image, crop.handle)
            end
        end
    end
    state.crops = {}
    state.active_crop = nil
end

function M.invalidate()
    invalidate_handle()
    invalidate_crops()
    state.fetch_started = false
    state.fetch_done = false
    state.next_retry_ms = 0
    state.path = nil
    state.png_url = nil
    state.asset_id = nil
    state.place_id = nil
end

local function begin_load(path, asset_id, png_url)
    invalidate_handle()
    state.path = path
    state.asset_id = asset_id
    state.png_url = png_url or state.png_url
    state.load_chain = build_load_chain(path, asset_id, state.png_url)
    state.load_idx = 1
    state.failed = false
    state.ready = false
end

local function advance_load()
    if not draw or not draw.load_image then
        state.failed = true
        state.next_retry_ms = tick_ms() + RETRY_MS
        return nil
    end
    local chain = state.load_chain
    if not chain or state.load_idx > #chain then
        state.failed = true
        state.handle = nil
        state.next_retry_ms = tick_ms() + RETRY_MS
        return nil
    end

    local url = chain[state.load_idx]
    state.load_url = url
    local ok, handle = pcall(draw.load_image, url)
    if not ok or not handle then
        state.load_idx = state.load_idx + 1
        return advance_load()
    end
    state.handle = handle
    return handle
end

local function tick_load()
    if state.failed then return nil end
    if not state.load_chain then return nil end

    if not state.handle then
        return advance_load()
    end

    if draw.image_failed and draw.image_failed(state.handle) then
        debug.warn_once("map_img:" .. tostring(state.load_url), "map load failed - " .. tostring(state.load_url))
        state.load_idx = state.load_idx + 1
        state.handle = nil
        return advance_load()
    end

    state.ready = true
    return state.handle
end

function M.ensure()
    local pid = place_id()
    local asset_id = M.resolve_asset_id()
    if state.place_id and state.place_id ~= pid then
        M.invalidate()
    end
    if state.asset_id and state.asset_id ~= asset_id and state.fetch_done then
        M.invalidate()
    end

    state.place_id = pid
    state.asset_id = asset_id
    local path = M.cache_path(pid, asset_id)
    state.path = path

    if path and not file_is_image(path) then
        pcall(os.remove, path)
    end

    -- After a hard failure, retry the whole fetch/load every 30s.
    if state.failed then
        local now = tick_ms()
        if now < (state.next_retry_ms or 0) then
            return nil
        end
        state.next_retry_ms = now + RETRY_MS
        invalidate_handle()
        state.fetch_started = false
        state.fetch_done = false
        state.failed = false
        state.load_chain = nil
        debug.warn_once("map_img:retry", "retrying world map load")
    end

    if not state.fetch_started then
        state.fetch_started = true
        if file_exists(path) then
            state.fetch_done = true
            state.png_url = resolve_png_url(asset_id)
            begin_load(path, asset_id, state.png_url)
        else
            local ok, png_url = download_to(path, asset_id)
            state.fetch_done = true
            state.png_url = png_url
            if ok then
                begin_load(path, asset_id, png_url)
            else
                begin_load(nil, asset_id, png_url)
            end
        end
    elseif state.fetch_done and not state.load_chain and not state.failed then
        begin_load(file_exists(path) and path or nil, asset_id, state.png_url or resolve_png_url(asset_id))
    end

    local handle = tick_load()
    if state.ready then
        state.next_retry_ms = 0
    end
    return handle
end

function M.handle()
    return M.ensure()
end

function M.ready()
    M.ensure()
    return state.ready == true and state.handle ~= nil and not state.failed
end

function M.failed()
    M.ensure()
    return state.failed == true
end

function M.world_size()
    return M.WORLD_SIZE
end

function M.origin()
    return M.ORIGIN_X, M.ORIGIN_Z
end

function M.world_to_uv(wx, wz)
    local ox, oz = M.origin()
    local size = M.world_size()
    local u = 0.5 + ((wx or 0) - ox) / size
    local v = 0.5 + ((wz or 0) - oz) / size
    return u, v
end

function M.uv_to_viewport(u, v, vp)
    if not vp then return nil, nil end
    local du = (vp.u1 - vp.u0)
    local dv = (vp.v1 - vp.v0)
    if du < 1e-6 or dv < 1e-6 then return nil, nil end
    return (u - vp.u0) / du, (v - vp.v0) / dv
end

function M.world_to_viewport(wx, wz, vp)
    local u, v = M.world_to_uv(wx, wz)
    return M.uv_to_viewport(u, v, vp)
end

local function image_is_loaded(handle)
    if not handle or not draw then return false end
    local loaded = draw.image_loaded or draw.ImageLoaded
    if loaded then
        local ok, yes = pcall(loaded, handle)
        return ok and yes == true
    end
    -- If the API lacks ImageLoaded, assume ready once we have a handle.
    return true
end

local function image_has_failed(handle)
    if not handle or not draw then return false end
    local failed = draw.image_failed or draw.ImageFailed
    if not failed then return false end
    local ok, yes = pcall(failed, handle)
    return ok and yes == true
end

local function image_draw(handle, x, y, w, h, alpha)
    if not handle or not draw then return false end
    local image_fn = draw.image or draw.Image
    if not image_fn then return false end
    local a = math.floor(math.max(0, math.min(1, alpha or 1)) * 255)
    return pcall(image_fn, handle, x, y, w, h, 255, 255, 255, a)
end

local function draw_fit(map_rect, alpha)
    if not (M.ready() and state.handle) then return false end
    if image_has_failed(state.handle) then return false end
    return image_draw(state.handle, map_rect.x, map_rect.y, map_rect.w, map_rect.h, alpha)
end

local MAX_CROP_HANDLES = 12

local function crop_key(spec)
    return table.concat({
        spec.asset_id, spec.cx, spec.cy, spec.cw, spec.ch, spec.out_w, spec.out_h,
    }, ":")
end

local function crop_spec(view, map_rect)
    local img_size = tonumber(view and view.img_size) or 0
    if img_size <= 0 then return nil end

    local src = M.SOURCE_PX
    local cw = math.max(1, math.min(src, math.floor(src * map_rect.w / img_size + 0.5)))
    local ch = math.max(1, math.min(src, math.floor(src * map_rect.h / img_size + 0.5)))
    if cw >= src and ch >= src then return nil end

    local pu, pv = M.world_to_uv(view.view_x or 0, view.view_z or 0)
    local cx = math.floor(pu * src - cw * 0.5 + 0.5)
    local cy = math.floor(pv * src - ch * 0.5 + 0.5)
    cx = math.max(0, math.min(src - cw, cx))
    cy = math.max(0, math.min(src - ch, cy))

    local spec = {
        asset_id = tostring(state.asset_id or M.DEFAULT_ASSET),
        cx = cx, cy = cy, cw = cw, ch = ch,
        out_w = math.max(32, math.floor(map_rect.w + 0.5)),
        out_h = math.max(32, math.floor(map_rect.h + 0.5)),
        vp = {
            u0 = cx / src,
            v0 = cy / src,
            u1 = (cx + cw) / src,
            v1 = (cy + ch) / src,
            ready = true,
        },
    }
    spec.key = crop_key(spec)
    return spec
end

local function free_crop(entry)
    if entry and entry.handle and draw and draw.free_image then
        pcall(draw.free_image, entry.handle)
    end
    if state.active_crop == entry then state.active_crop = nil end
end

local function prune_crops()
    local count = 0
    for _ in pairs(state.crops) do count = count + 1 end
    while count > MAX_CROP_HANDLES do
        local oldest_key, oldest
        for key, entry in pairs(state.crops) do
            if entry ~= state.active_crop
                and (not oldest or (entry.last_used or 0) < (oldest.last_used or 0))
            then
                oldest_key, oldest = key, entry
            end
        end
        if not oldest_key then break end
        free_crop(oldest)
        state.crops[oldest_key] = nil
        count = count - 1
    end
end

local function ensure_crop(spec)
    if not spec or not draw then return nil end
    local load_fn = draw.load_image or draw.LoadImage
    if not load_fn then return nil end

    local entry = state.crops[spec.key]
    if not entry then
        local urls = asset_urls.map_crop_urls(
            spec.asset_id, spec.cx, spec.cy, spec.cw, spec.ch, spec.out_w, spec.out_h
        )
        entry = {
            key = spec.key,
            urls = urls,
            idx = 1,
            vp = spec.vp,
            last_used = tick_ms(),
        }
        state.crops[spec.key] = entry
        prune_crops()
        -- prune_crops may evict this just-created request only if every older
        -- entry is active; in that rare case, recreate it on the next frame.
        if state.crops[spec.key] ~= entry then return nil end
    end
    entry.last_used = tick_ms()

    if entry.handle then
        if image_has_failed(entry.handle) then
            free_crop(entry)
            entry.handle = nil
        elseif image_is_loaded(entry.handle) then
            entry.ready = true
            state.active_crop = entry
            prune_crops()
            return entry
        else
            return nil
        end
    end

    while entry.idx <= #(entry.urls or {}) do
        local url = entry.urls[entry.idx]
        entry.idx = entry.idx + 1
        local ok, handle = pcall(load_fn, url)
        if ok and handle then
            entry.handle = handle
            entry.url = url
            if image_is_loaded(handle) then
                entry.ready = true
                state.active_crop = entry
                prune_crops()
                return entry
            end
            return nil
        end
    end
    entry.failed = true
    prune_crops()
    return nil
end

local function draw_crop(entry, map_rect, alpha)
    if not entry or not entry.handle or not image_is_loaded(entry.handle) then
        return false
    end
    return image_draw(entry.handle, map_rect.x, map_rect.y, map_rect.w, map_rect.h, alpha)
end

-- Draw one image exactly inside map_rect. Zoomed images are cropped remotely
-- because Vector exposes neither a clip rect nor Image UV coordinates.
function M.draw_centered(view, map_rect, alpha)
    if not view or not map_rect then
        return nil
    end
    M.ensure()
    alpha = alpha or 0.92

    if draw and (draw.rect_filled or draw.RectFilled) then
        local rf = draw.rect_filled or draw.RectFilled
        pcall(rf, map_rect.x, map_rect.y, map_rect.w, map_rect.h, M.OCEAN, 0)
    end

    local spec = crop_spec(view, map_rect)
    if spec then
        local wanted = ensure_crop(spec)
        if wanted and draw_crop(wanted, map_rect, alpha) then
            view.vp = wanted.vp
            return "crop"
        end

        -- Keep the previous crop visible and keep blips aligned while the new
        -- request loads. The desired handle is polled every frame automatically.
        local active = state.active_crop
        if active and draw_crop(active, map_rect, alpha) then
            active.last_used = tick_ms()
            view.vp = active.vp
            return "crop"
        end
    end

    if draw_fit(map_rect, alpha) then
        view.vp = { u0 = 0, v0 = 0, u1 = 1, v1 = 1, ready = true }
        return "fit"
    end

    return nil
end

function M.draw(x, y, w, h, alpha)
    local handle = M.handle()
    if not handle then return false end
    return image_draw(handle, x, y, w, h, alpha)
end

return M
