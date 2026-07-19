-- Shared combat target for overlay / tracers / hitmarkers.
-- Does not require a weapon out — uses aimbot scoped target or crosshair FOV.

local settings = April.require("core.settings")
local player_state = April.require("game.player_state")
local targeting = April.require("features.combat.targeting")

local M = {}

local function valid_target(t)
    return t and player_state.is_combat_target and player_state.is_combat_target(t)
end

local function from_module(mod)
    if not mod then return nil end
    if mod.get_scoped_target then
        local t = mod.get_scoped_target()
        if valid_target(t) then return t end
    end
    if mod.get_target then
        local t = mod.get_target()
        if valid_target(t) then return t end
    end
    return nil
end

local function crosshair_prefix_fov()
    if settings.bool("april_aimbot", false) then
        return "april_aim_", settings.num("april_aim_fov", 120)
    end
    if settings.enabled("april_silent_aim") then
        return "april_silent_", settings.num("april_silent_fov", 150)
    end
    return "april_silent_", 150
end

local function crosshair_target()
    local prefix, fov = crosshair_prefix_fov()
    local sw, sh = targeting.screen_center()
    return targeting.find_target(sw * 0.5, sh * 0.5, fov, prefix)
end

function M.get()
    local ok_cam, cam = pcall(function()
        return April.require("features.combat.camera_aimbot")
    end)
    if ok_cam and cam then
        local t = from_module(cam)
        if t then return t end
    end

    local ok, aimbot = pcall(function()
        return April.require("features.combat.aimbot")
    end)
    if ok and aimbot then
        local t = from_module(aimbot)
        if t then return t end
    end

    local t = crosshair_target()
    if valid_target(t) then return t end
    return nil
end

function M.aim_point(target)
    if not target then return nil end
    local pos = target.head_position or target.position
    if not pos then return nil end
    return {
        x = pos.x or pos.X or pos[1],
        y = pos.y or pos.Y or pos[2],
        z = pos.z or pos.Z or pos[3],
    }
end

function M.health(target)
    if not target then return nil end
    return target.health
end

return M
