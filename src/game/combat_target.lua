-- Shared combat target: silent-aim lock only (gear FOV fallback lives in target_overlay).

local M = {}

function M.get()
    local ok_cam, cam = pcall(function()
        return April.require("features.combat.camera_aimbot")
    end)
    if ok_cam and cam and cam.get_target then
        local t = cam.get_target()
        if t then
            local player_state = April.require("game.player_state")
            if not player_state or not player_state.is_combat_target or player_state.is_combat_target(t) then
                return t
            end
        end
    end

    local ok, aimbot = pcall(function()
        return April.require("features.combat.aimbot")
    end)
    if not ok or not aimbot or not aimbot.get_target then return nil end

    local t = aimbot.get_target()
    if not t then return nil end

    local player_state = April.require("game.player_state")
    if player_state and player_state.is_combat_target and not player_state.is_combat_target(t) then
        return nil
    end
    return t
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
