-- Vector entity player fields: new API docs use PascalCase (Name, UserId, Position…).
-- Older builds exposed snake_case. Read both so ESP/targeting keep working.

local M = {}

function M.ensure_api_aliases()
    local ok, aliases = pcall(function()
        return April.require("core.api_aliases")
    end)
    if ok and aliases and aliases.apply then
        aliases.apply()
    end
end

function M.get_players()
    M.ensure_api_aliases()
    if not entity then return {} end
    local fn = entity.get_players or entity.GetPlayers
    if not fn then return {} end
    local ok, list = pcall(fn)
    if ok and type(list) == "table" then return list end
    return {}
end

function M.get_local_player()
    M.ensure_api_aliases()
    if not entity then return nil end
    local fn = entity.get_local_player or entity.GetLocalPlayer
    if not fn then return nil end
    local ok, lp = pcall(fn)
    if ok then return lp end
    return nil
end

local function raw_get(obj, key)
    if obj == nil or key == nil then return nil end
    local ok, v = pcall(function()
        return obj[key]
    end)
    if ok and v ~= nil then return v end
    return nil
end

function M.get(obj, ...)
    local n = select("#", ...)
    for i = 1, n do
        local v = raw_get(obj, select(i, ...))
        if v ~= nil then return v end
    end
    return nil
end

function M.call(obj, ...)
    if not obj then return nil end
    local n = select("#", ...)
    for i = 1, n do
        local name = select(i, ...)
        local fn = raw_get(obj, name)
        if type(fn) == "function" then
            return function(...)
                return fn(obj, ...)
            end
        end
    end
    return nil
end

function M.name(p)
    return M.get(p, "Name", "name", "DisplayName", "display_name")
end

function M.display_name(p)
    return M.get(p, "DisplayName", "display_name", "Name", "name")
end

function M.user_id(p)
    local uid = tonumber(M.get(p, "UserId", "user_id"))
    if uid and uid ~= 0 then return uid end
    -- Vector entity cache may leave UserId at 0; fall back to Player instance.
    local pl = M.player_inst(p)
    if pl then
        local ok, v = pcall(function()
            return pl.UserId or pl.user_id
        end)
        if ok then
            uid = tonumber(v)
            if uid and uid ~= 0 then return uid end
        end
    end
    return uid
end

function M.is_local(p)
    local v = M.get(p, "IsLocal", "is_local")
    return v == true
end

function M.is_alive(p)
    local v = M.get(p, "IsAlive", "is_alive")
    if v ~= nil then return v == true end
    return nil
end

function M.is_workspace_entity(p)
    local v = M.get(p, "IsWorkspaceEntity", "is_workspace_entity")
    return v == true
end

function M.health(p)
    return tonumber(M.get(p, "Health", "health"))
end

function M.max_health(p)
    return tonumber(M.get(p, "MaxHealth", "max_health"))
end

function M.team(p)
    return M.get(p, "Team", "team")
end

function M.has_team(p)
    local v = M.get(p, "HasTeam", "has_team")
    return v == true
end

function M.character(p)
    return M.get(p, "Character", "character")
end

function M.humanoid(p)
    return M.get(p, "Humanoid", "humanoid")
end

function M.player_inst(p)
    return M.get(p, "Player", "player")
end

function M.position(p)
    return M.get(p, "Position", "position")
end

function M.head_position(p)
    return M.get(p, "HeadPosition", "head_position") or M.position(p)
end

function M.velocity(p)
    return M.get(p, "Velocity", "velocity")
end

function M.tool_name(p)
    return M.get(p, "ToolName", "tool_name")
end

function M.get_bounds(p)
    local fn = M.call(p, "GetBounds", "get_bounds", "getBounds")
    if not fn then return nil end
    local ok, b = pcall(fn)
    if ok then return b end
    return nil
end

function M.get_bones_screen(p)
    local fn = M.call(p, "GetBonesScreen", "get_bones_screen", "getBonesScreen")
    if not fn then return nil end
    local ok, bones = pcall(fn)
    if ok then return bones end
    return nil
end

function M.get_bone_screen(p, bone)
    local fn = M.call(p, "GetBoneScreen", "get_bone_screen", "getBoneScreen")
    if not fn then return 0, 0, false end
    local ok, x, y, vis = pcall(fn, bone)
    if not ok then return 0, 0, false end
    return x, y, vis
end

function M.distance_to(p, origin)
    local fn = M.call(p, "DistanceTo", "distance_to", "distanceTo")
    if not fn then return nil end
    local ok, d
    if origin ~= nil then
        ok, d = pcall(fn, origin)
    else
        ok, d = pcall(fn)
    end
    if ok then return tonumber(d) end
    return nil
end

return M
