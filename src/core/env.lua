local M = {}

function M.has_api(name)
    return _G[name] ~= nil
end

function M.require_apis(names)
    for _, name in ipairs(names) do
        if not M.has_api(name) then
            return false, name
        end
    end
    return true
end

function M.safe_call(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

-- Identity still readable on a live handle. Used when utility.is_valid false-negatives
-- (seen on Player instances and, post-update / Potassium, some workspace Folders/Models).
local function has_identity(inst)
    local ok, cn = pcall(function()
        return inst.ClassName or inst.class_name
    end)
    if ok and cn ~= nil and cn ~= "" then return true end
    local ok2, name = pcall(function()
        return inst.Name or inst.name
    end)
    return ok2 and name ~= nil and name ~= ""
end

function M.is_valid(inst)
    if not inst then return false end

    if utility and utility.is_valid then
        local ok, valid = pcall(utility.is_valid, inst)
        if ok and valid == true then
            return true
        end
        -- False-negative guard: prune_invalid + folder walks used to wipe all ESP
        -- when is_valid rejected still-usable workspace instances.
        if ok and valid == false then
            return has_identity(inst)
        end
    end

    return has_identity(inst)
end

function M.get_workspace()
    if game and game.workspace then return game.workspace end
    local via_service = M.safe_call(function()
        if game.get_service then return game.get_service("Workspace") end
        if game.GetService then return game:GetService("Workspace") end
        return nil
    end)
    if via_service then return via_service end
    return M.safe_call(function() return workspace end)
end

function M.get_local_player()
    local ep = April and April.require and April.require("core.entity_props")
    if ep and ep.get_local_player then
        local lp = ep.get_local_player()
        if lp then return lp end
    end
    if entity then
        local fn = entity.get_local_player or entity.GetLocalPlayer
        if fn then
            local ok, lp = pcall(fn)
            if ok and lp then return lp end
        end
    end
    if game then
        local lp = game.local_player or game.LocalPlayer
        if lp then return lp end
    end
    return nil
end

function M.get_replicated_storage()
    return M.safe_call(function() return game.get_service("ReplicatedStorage") end)
end

function M.get_attribute(inst, key)
    if not inst or not key then return nil end
    local ok, v = pcall(function()
        if inst.get_attribute then return inst:get_attribute(key) end
        return nil
    end)
    if ok and v ~= nil then return v end
    ok, v = pcall(function()
        if inst.GetAttribute then return inst:GetAttribute(key) end
        return nil
    end)
    if ok and v ~= nil then return v end
    return nil
end

return M
