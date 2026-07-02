local env = April.require("core.env")

local M = {}
local loaded = false
local by_name = {}

local FALLBACK = {
    ["Wood Log"] = { Type = "Resource" },
    ["Bandage"] = { Type = "Tool" },
    ["Salvaged M14"] = { Type = "Tool" },
}

function M.load()
    if loaded then return true end
    local rep = env.get_replicated_storage()
    if not rep then return false end
    local modules = env.safe_call(function() return rep:find_first_child("Modules") end)
    local items_mod = modules and env.safe_call(function() return modules:find_first_child("Items") end)
    if not items_mod then return false end
    local ok, data = pcall(function() return require(items_mod) end)
    if ok and type(data) == "table" then
        if data[1] then
            for _, entry in ipairs(data) do
                if entry.Name then by_name[entry.Name] = entry end
            end
        else
            for name, entry in pairs(data) do
                if type(entry) == "table" then
                    entry.Name = entry.Name or name
                    by_name[entry.Name] = entry
                end
            end
        end
        loaded = true
        return true
    end
    return false
end

function M.get(name)
    if not loaded then M.load() end
    return by_name[name] or FALLBACK[name]
end

function M.get_type(name)
    local item = M.get(name)
    return item and item.Type or "Unknown"
end

return M
