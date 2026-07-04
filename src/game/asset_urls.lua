--[[
    GitHub CDN URLs for draw.load_image (April/docs/API.md — HTTPS required).
    Assets live in repo assets/ — run: node scripts/download-assets.mjs
]]

local M = {}

-- Bump branch/path if you fork; must match raw GitHub path after push.
M.CDN_BASE = "https://raw.githubusercontent.com/cunzaki/April/main/assets"

function M.item_png(asset_id)
    asset_id = asset_id and tostring(asset_id):match("(%d+)")
    if not asset_id then return nil end
    return M.CDN_BASE .. "/items/" .. asset_id .. ".png"
end

function M.tung_png()
    return M.CDN_BASE .. "/tung.png"
end

function M.urls_for_item(asset_id)
    local png = M.item_png(asset_id)
    if not png then return {} end
    asset_id = tostring(asset_id):match("(%d+)")
    return {
        png,
        "rbxassetid://" .. asset_id,
        "https://www.roblox.com/asset/?id=" .. asset_id,
    }
end

function M.urls_for_tung()
    local id = "139818999438291"
    return {
        M.tung_png(),
        "rbxassetid://" .. id,
        "https://www.roblox.com/asset/?id=" .. id,
    }
end

function M.urls_for_avatar(user_id)
    user_id = tostring(user_id):match("(%d+)") or tostring(user_id)
    return {
        "https://www.roblox.com/headshot-thumbnail/image?userId=" .. user_id .. "&size=150x150&format=Png",
        "https://www.roblox.com/headshot-thumbnail/image?userId=" .. user_id .. "&width=150&height=150&format=png",
    }
end

return M
