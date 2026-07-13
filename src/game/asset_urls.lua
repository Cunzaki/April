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

function M.mod_warning_png()
    return M.CDN_BASE .. "/mod_warning.png"
end

return M
