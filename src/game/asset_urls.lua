--[[
    GitHub CDN URLs for draw.load_image (April/docs/API.md — direct HTTPS).
    Assets: https://github.com/Cunzaki/April/tree/main/assets
]]

local M = {}

M.REPO = "Cunzaki/April"
M.BRANCH = "main"

M.CDN_RAW = "https://raw.githubusercontent.com/" .. M.REPO .. "/" .. M.BRANCH .. "/assets"
M.CDN_JSdelivr = "https://cdn.jsdelivr.net/gh/" .. M.REPO .. "@" .. M.BRANCH .. "/assets"

local function digits(id)
    return id and tostring(id):match("(%d+)")
end

function M.item_png(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return M.CDN_JSdelivr .. "/items/" .. asset_id .. ".png"
end

function M.tung_png()
    return M.CDN_JSdelivr .. "/tung.png"
end

function M.urls_for_item(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return {} end
    local rel = "/items/" .. asset_id .. ".png"
    return {
        M.CDN_JSdelivr .. rel,
        M.CDN_RAW .. rel,
        "https://github.com/" .. M.REPO .. "/raw/" .. M.BRANCH .. "/assets" .. rel,
        "rbxassetid://" .. asset_id,
    }
end

function M.urls_for_tung()
    local id = "139818999438291"
    return {
        M.CDN_JSdelivr .. "/tung.png",
        M.CDN_RAW .. "/tung.png",
        "https://github.com/" .. M.REPO .. "/raw/" .. M.BRANCH .. "/assets/tung.png",
        "rbxassetid://" .. id,
    }
end

return M
