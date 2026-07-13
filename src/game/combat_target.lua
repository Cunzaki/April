-- Shared combat target: silent-aim lock first, then optional crosshair FOV fallback.

local settings = April.require("core.settings")
local player_state = April.require("game.player_state")
local esp_util = April.require("core.esp_util")
local math_util = April.require("core.math_util")
local draw_util = April.require("core.draw_util")

local M = {}

local OVERLAY_FOV_ID = "april_target_overlay_fov"
local FALLBACK_ID = "april_target_overlay_fallback_fov"

local function crosshair_center()
    local sw, sh = draw_util.screen_size()
    return sw * 0.5, sh * 0.5
end

local function find_crosshair_target(fov_px)
    if not entity or not entity.get_players then return nil end

    local cx, cy = crosshair_center()
    local best, best_dist = nil, fov_px

    for _, p in ipairs(entity.get_players()) do
        if not player_state.is_combat_target(p) then goto continue end

        local pos = p.head_position or p.position
        if not pos then goto continue end

        local px = pos.x or pos[1]
        local py = pos.y or pos[2]
        local pz = pos.z or pos[3]
        if not px then goto continue end

        local sx, sy, vis = esp_util.w2s(px, py, pz)
        if not vis then goto continue end

        local dist = math_util.screen_fov_dist(sx, sy, cx, cy)
        if dist <= fov_px and dist < best_dist then
            best_dist = dist
            best = p
        end

        ::continue::
    end

    return best
end

function M.get()
    local ok, aimbot = pcall(function()
        return April.require("features.combat.aimbot")
    end)
    if ok and aimbot and aimbot.get_target then
        local locked = aimbot.get_target()
        if locked and player_state.is_combat_target(locked) then
            return locked
        end
    end

    if settings.bool(FALLBACK_ID, true) then
        return find_crosshair_target(settings.num(OVERLAY_FOV_ID, 150))
    end

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
