--[[ Fallen player state — Humanoid:GetAttribute("Downed") from game scripts. ]]

local env = April.require("core.env")

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

function M.passes_health_check(player)
    if not player then return false end
    if not player.is_alive then return false end
    if M.is_downed(player) then return false end
    if player.health and player.health <= 0 then return false end
    return true
end

function M.passes_team_check(player)
    if not player then return false end
    if not entity or not entity.get_local_player then return true end

    local lp = entity.get_local_player()
    if not lp then return true end
    if not lp.has_team or not player.has_team then return true end
    if not lp.team or not player.team or lp.team == "" or player.team == "" then return true end

    return lp.team ~= player.team
end

return M
