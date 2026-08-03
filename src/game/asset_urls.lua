local M = {}

M.CDN_BASE = "https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/assets"
-- jsDelivr mirrors the same assets and is more reliable for LoadImage tile fetches.
M.JSDELIVR_BASE = "https://cdn.jsdelivr.net/gh/Cunzaki/April@main/assets"

local function digits(id)
    return id and tostring(id):match("(%d+)")
end

function M.rbx_asset(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return "rbxassetid://" .. asset_id
end

function M.roblox_asset_http(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return "http://www.roblox.com/asset/?id=" .. asset_id
end

function M.roblox_thumb(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return string.format(
        "https://www.roblox.com/Thumbs/Asset.ashx?width=420&height=420&assetId=%s",
        asset_id
    )
end

-- Direct PNG thumbnail (Vector LoadImage can decode this; assetdelivery cannot).
function M.roblox_thumb_hq(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return string.format(
        "https://www.roblox.com/Thumbs/Asset.ashx?width=700&height=700&assetId=%s",
        asset_id
    )
end

function M.roblox_thumbnails_api(asset_id, size)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    size = size or "700x700"
    return string.format(
        "https://thumbnails.roblox.com/v1/assets?assetIds=%s&size=%s&format=Png&isCircular=false",
        asset_id,
        size
    )
end

function M.asset_delivery(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return string.format("https://assetdelivery.roblox.com/v1/asset/?id=%s", asset_id)
end

function M.item_png(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return M.CDN_BASE .. "/items/" .. asset_id .. ".png"
end

function M.map_png(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return M.CDN_BASE .. "/maps/" .. asset_id .. ".png"
end

-- Vector's draw API has no UV crop or clip rect. wsrv returns one already-cropped
-- PNG, allowing the radar to draw a zoomed viewport as a single bounded image.
function M.map_crop_urls(asset_id, cx, cy, cw, ch, out_w, out_h)
    asset_id = digits(asset_id)
    if not asset_id then return {} end

    local source = string.format(
        "raw.githubusercontent.com/Cunzaki/April/refs/heads/main/assets/maps/%s.png",
        asset_id
    )
    local query = string.format(
        "?url=%s&cx=%d&cy=%d&cw=%d&ch=%d&precrop&w=%d&h=%d&fit=fill&output=png",
        source,
        math.floor(cx), math.floor(cy),
        math.floor(cw), math.floor(ch),
        math.floor(out_w), math.floor(out_h)
    )
    return {
        "https://wsrv.nl/" .. query,
        "https://images.weserv.nl/" .. query,
    }
end

function M.map_tile(asset_id, tx, ty)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return string.format("%s/maps/%s/tiles/%d_%d.png", M.CDN_BASE, asset_id, tx, ty)
end

function M.map_tile_jsdelivr(asset_id, tx, ty)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return string.format("%s/maps/%s/tiles/%d_%d.png", M.JSDELIVR_BASE, asset_id, tx, ty)
end

-- Preferred order for Vector LoadImage (jsDelivr first — raw GitHub often 404s tiles).
function M.map_tile_urls(asset_id, tx, ty)
    local list = {}
    local a = M.map_tile_jsdelivr(asset_id, tx, ty)
    local b = M.map_tile(asset_id, tx, ty)
    if a then list[#list + 1] = a end
    if b and b ~= a then list[#list + 1] = b end
    return list
end

function M.mod_warning_png()
    return M.CDN_BASE .. "/mod_warning.png"
end

function M.author_profile_png()
    return M.CDN_BASE .. "/cunzaki.png"
end

return M
