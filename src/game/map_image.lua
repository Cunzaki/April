-- Fallen G-map texture: resolve live Image, cache PNG, draw via tile atlas
-- (Vector has no Image UV crop / clip API — tiles keep the map inside the radar).
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
    tiles = {}, -- ["i_j"] = { handle=, url=, failed= }
    tiles_tried = {},
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

local function invalidate_tiles()
    if draw and draw.free_image then
        for _, tile in pairs(state.tiles) do
            if tile and tile.handle then
                pcall(draw.free_image, tile.handle)
            end
        end
    end
    state.tiles = {}
    state.tiles_tried = {}
end

function M.invalidate()
    invalidate_handle()
    invalidate_tiles()
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

local function tile_key(i, j)
    return tostring(i) .. "_" .. tostring(j)
end

local function tile_candidates(asset_id, i, j)
    local list = {}
    -- Vector LoadImage only accepts HTTPS — skip local/file tile paths.
    local cdn = asset_urls.map_tile(asset_id, i, j)
    if is_usable_load_url(cdn) then
        list[#list + 1] = cdn
    end
    return list
end

local function ensure_tile(i, j)
    local asset_id = state.asset_id or M.DEFAULT_ASSET
    local key = tile_key(i, j)
    local tile = state.tiles[key]
    if tile and tile.handle then
        if draw.image_failed and draw.image_failed(tile.handle) then
            tile.failed = true
            tile.handle = nil
        else
            return tile.handle
        end
    end
    if tile and tile.failed then return nil end
    if not draw or not draw.load_image then return nil end

    tile = tile or { idx = 1, urls = tile_candidates(asset_id, i, j) }
    state.tiles[key] = tile
    tile.urls = tile.urls or tile_candidates(asset_id, i, j)
    tile.idx = tile.idx or 1

    while tile.idx <= #tile.urls do
        local url = tile.urls[tile.idx]
        tile.idx = tile.idx + 1
        local ok, handle = pcall(draw.load_image, url)
        if ok and handle then
            tile.handle = handle
            tile.url = url
            return handle
        end
    end

    tile.failed = true
    return nil
end

local function image_draw(handle, x, y, w, h, alpha)
    if not handle or not draw then return false end
    local image_fn = draw.image or draw.Image
    if not image_fn then return false end
    local a = math.floor(math.max(0, math.min(1, alpha or 1)) * 255)
    return pcall(image_fn, handle, x, y, w, h, 255, 255, 255, a)
end

-- Draw the world map inside map_rect using the full HTTPS texture (fit).
-- Vector LoadImage only accepts certain HTTPS URLs (tr.rbxcdn.com), not local files.
-- Player/blip UVs use fit mode so geography stays correct inside the radar.
function M.draw_centered(view, map_rect, alpha)
    if not view or not map_rect then
        return nil
    end
    M.ensure()
    alpha = alpha or 0.92

    if draw and draw.rect_filled then
        pcall(draw.rect_filled, map_rect.x, map_rect.y, map_rect.w, map_rect.h, M.OCEAN, 0)
    end

    if M.ready() and state.handle then
        if draw.image_failed and draw.image_failed(state.handle) then
            return nil
        end
        if image_draw(state.handle, map_rect.x, map_rect.y, map_rect.w, map_rect.h, alpha) then
            return "fit"
        end
    end

    return nil
end

function M.draw(x, y, w, h, alpha)
    local handle = M.handle()
    if not handle then return false end
    return image_draw(handle, x, y, w, h, alpha)
end

return M
