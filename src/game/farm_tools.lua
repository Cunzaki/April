--[[ Gather / farm tool detection for Farm Helper (NodeSpark / TreeX). ]]

local bootstrap = April.require("game.bootstrap")
local env = April.require("core.env")

local M = {}

local loaded = false
local farm_tools = {}

-- Fallback when ToolInfo is unavailable (Melee + Trees or Nodes in dump ToolInfo).
local FALLBACK_GATHER_TOOLS = {
    ["Stone Hatchet"] = true,
    ["Iron Shard Hatchet"] = true,
    ["Steel Axe"] = true,
    Chainsaw = true,
    ["Stone Pickaxe"] = true,
    ["Iron Shard Pickaxe"] = true,
    ["Steel Pickaxe"] = true,
    ["Mining Drill"] = true,
    ["Bone Tool"] = true,
    ["Candy Cane"] = true,
    ["Carrot Blade"] = true,
    ["Halloween Scythe"] = true,
    Boulder = true,
}

local NAME_HINTS = {
    "hatchet", "pickaxe", "pick axe", " axe", "axe ",
    "chainsaw", "mining drill", "bone tool",
    "candy cane", "carrot blade", "halloween scythe", "boulder",
}

local function inst_name(inst)
    if not inst then return nil end
    return inst.name or inst.Name
end

local function entry_can_gather(entry)
    if not entry or not entry.Melee then return false end
    local od = entry.ObjectDamages
    if not od then return false end
    return od.Trees ~= nil or od.Nodes ~= nil
end

local function normalize(name)
    if not name or name == "" then return nil end
    return name
end

local function name_hint_match(name)
    local n = (name or ""):lower()
    for _, hint in ipairs(NAME_HINTS) do
        if n:find(hint, 1, true) then return true end
    end
    return false
end

function M.load()
    if loaded then return true end

    farm_tools = {}
    for name in pairs(FALLBACK_GATHER_TOOLS) do
        farm_tools[name] = true
    end

    local data = bootstrap.get_module("ToolInfo")
    if type(data) == "table" then
        for name, entry in pairs(data) do
            if type(name) == "string" and entry_can_gather(entry) then
                farm_tools[name] = true
            end
        end
    end

    loaded = true
    return next(farm_tools) ~= nil
end

function M.invalidate()
    loaded = false
    farm_tools = {}
end

function M.is_farm_tool_name(name)
    name = normalize(name)
    if not name then return false end
    if not loaded then M.load() end
    if farm_tools[name] then return true end
    return name_hint_match(name)
end

local function pick_farm_name(name)
    if M.is_farm_tool_name(name) then return name end
    return nil
end

local function scan_children(list)
    if not list then return nil end
    for _, child in ipairs(list) do
        local hit = pick_farm_name(inst_name(child))
        if hit then return hit end
    end
    return nil
end

function M.get_held_farm_tool_name()
    if not loaded then M.load() end

    local lp = env.get_local_player()
    if not lp then return nil end

    local char = lp.character
    if char and env.is_valid(char) then
        local hit = scan_children(env.safe_call(function() return char:get_children() end))
        if hit then return hit end
    end

    local ws = env.get_workspace()
    if ws then
        local vms = env.safe_call(function() return ws:find_first_child("Viewmodels") end)
            or env.safe_call(function() return ws:FindFirstChild("Viewmodels") end)
        if vms then
            for _, vm in ipairs(env.safe_call(function() return vms:get_children() end) or {}) do
                if inst_name(vm) == "Viewmodel" then
                    local hit = scan_children(env.safe_call(function() return vm:get_children() end))
                    if hit then return hit end
                end
            end
        end
    end

    return pick_farm_name(lp.tool_name)
end

function M.holding_farm_tool()
    return M.get_held_farm_tool_name() ~= nil
end

function M.all_names()
    if not loaded then M.load() end
    local out = {}
    for name in pairs(farm_tools) do
        out[#out + 1] = name
    end
    table.sort(out)
    return out
end

return M
