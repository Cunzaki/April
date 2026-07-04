--[[
    One HTTPS URL per asset — April/docs/API.md Images section.
    API example: draw.load_image("https://raw.githubusercontent.com/user/repo/main/icon.png")
    Assets: https://github.com/Cunzaki/April/tree/main/assets
]]

local M = {}

M.CDN_BASE = "https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/assets"

local function digits(id)
    return id and tostring(id):match("(%d+)")
end

function M.item_png(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return M.CDN_BASE .. "/items/" .. asset_id .. ".png"
end

function M.tung_png()
    return M.CDN_BASE .. "/tung.png"
end

return M
