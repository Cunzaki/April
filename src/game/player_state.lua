local env = April.require("core.env")
local team_state = April.require("game.team_state")

local M = {}

function M.is_downed(player)
    if not player then return false end

    local hum = player.humanoid
    if not hum and player.character then
        hum = env.safe_call(function()
            if player.character.FindFirstChildOfClass then
                return player.character:FindFirstChildOfClass("Humanoid")
            end
            return player.character:FindFirstChild("Humanoid")
        end)
    end
    if not hum then return false end

    local down = env.safe_call(function()
        if hum.GetAttribute then
            return hum:GetAttribute("Downed")
        end
        if hum.get_attribute then
            return hum:get_attribute("Downed")
        end
        return nil
    end)

    return down == true
end

function M.is_combat_target(player)
    if not player or player.is_local then return false end
    if not player.is_alive then return false end
    return true
end

-- Alive + HP > 0. Does NOT include downed (use passes_downed_check).
function M.passes_health_check(player)
    if not player then return false end
    if not player.is_alive then return false end
    if player.health and player.health <= 0 then return false end
    return true
end

-- idx: 0 = Skip Downed, 1 = Allow Downed, 2 = Only Downed
function M.passes_downed_check(player, mode_idx)
    if not player then return false end
    mode_idx = tonumber(mode_idx) or 0
    local downed = M.is_downed(player)

    if mode_idx == 1 then
        return true
    end
    if mode_idx == 2 then
        return downed
    end
    -- Skip downed (default)
    return not downed
end

function M.passes_team_check(player)
    if not player then return false end
    -- Official party (TeamNavigationController) + Roblox Team (arena).
    -- Skip allies; everyone else is fair game. Solo / no team → allow.
    return not team_state.is_teammate(player)
end

return M
