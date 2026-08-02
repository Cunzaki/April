local M = {}

M.CDN_BASE = "https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/assets"

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

function M.map_tile(asset_id, tx, ty)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return string.format("%s/maps/%s/tiles/%d_%d.png", M.CDN_BASE, asset_id, tx, ty)
end

function M.mod_warning_png()
    return M.CDN_BASE .. "/mod_warning.png"
end

return M
