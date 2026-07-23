local bootstrap = April.require("game.bootstrap")
local env = April.require("core.env")

local M = {}

local loaded = false
local farm_tools = {}
local tool_caps = {} -- name -> { Trees=, Nodes=, Logs=, Cactus=, Dig= }

-- Dump ToolInfo ObjectDamages gather tools (fallback if ToolInfo missing).
local FALLBACK_GATHER_TOOLS = {
    ["Stone Hatchet"] = { Trees = true, Logs = true, Cactus = true },
    ["Iron Shard Hatchet"] = { Trees = true, Logs = true, Cactus = true },
    ["Steel Axe"] = { Trees = true, Logs = true, Cactus = true },
    Chainsaw = { Trees = true, Logs = true, Cactus = true },
    Machete = { Trees = true, Logs = true, Cactus = true },
    ["Saw Bat"] = { Cactus = true },
    ["Stone Pickaxe"] = { Nodes = true },
    ["Iron Shard Pickaxe"] = { Nodes = true },
    ["Steel Pickaxe"] = { Nodes = true },
    ["Mining Drill"] = { Nodes = true },
    ["Bone Tool"] = { Trees = true, Nodes = true, Logs = true, Cactus = true },
    ["Candy Cane"] = { Trees = true, Nodes = true, Logs = true, Cactus = true },
    ["Carrot Blade"] = { Trees = true, Nodes = true, Logs = true, Cactus = true },
    Boulder = { Trees = true, Nodes = true, Logs = true, Cactus = true },
    ["Steel Shovel"] = { Dig = true, Shovel = true },
    ["Salvaged Shovel"] = { Dig = true, Shovel = true },
    ["ez shovel"] = { Dig = true, Shovel = true },
}

local NAME_HINTS = {
    "hatchet", "pickaxe", "pick axe", " axe", "axe ",
    "chainsaw", "mining drill", "bone tool",
    "candy cane", "carrot blade", "boulder", "machete",
    "saw bat", "shovel",
}

-- MeleeChecks reach from ToolInfo dump (RaycastUtil MouseRaycast / HitMelee).
local MELEE_RANGE = {
    ["Stone Hatchet"] = 5,
    ["Iron Shard Hatchet"] = 5,
    ["Steel Axe"] = 5.5,
    Chainsaw = 6.5,
    Machete = 5.5,
    ["Saw Bat"] = 5,
    ["Stone Pickaxe"] = 5,
    ["Iron Shard Pickaxe"] = 5,
    ["Steel Pickaxe"] = 5.5,
    ["Mining Drill"] = 6.5,
    ["Bone Tool"] = 5,
    ["Candy Cane"] = 5,
    ["Carrot Blade"] = 5,
    Boulder = 4.5,
    ["Steel Shovel"] = 5,
    ["Salvaged Shovel"] = 5,
    ["ez shovel"] = 5,
}

local function inst_name(inst)
    if not inst then return nil end
    return inst.name or inst.Name
end

local function normalize(name)
    if not name or name == "" then return nil end
    return name
end

local function caps_from_object_damages(od)
    if type(od) ~= "table" then return nil end
    local caps = {}
    if od.Trees ~= nil then caps.Trees = true end
    if od.Nodes ~= nil then caps.Nodes = true end
    if od.Logs ~= nil then caps.Logs = true end
    if od.Cactus ~= nil then caps.Cactus = true end
    if next(caps) == nil then return nil end
    return caps
end

local function entry_can_gather(entry)
    if not entry or not entry.Melee then return false end
    return caps_from_object_damages(entry.ObjectDamages) ~= nil
end

local function name_hint_match(name)
    local n = (name or ""):lower()
    for _, hint in ipairs(NAME_HINTS) do
        if n:find(hint, 1, true) then return true end
    end
    return false
end

local function hint_caps(name)
    local n = (name or ""):lower()
    if n:find("shovel", 1, true) then
        return { Dig = true, Shovel = true }
    end
    if n:find("pickaxe", 1, true) or n:find("pick axe", 1, true) or n:find("mining drill", 1, true) then
        return { Nodes = true }
    end
    if n:find("saw bat", 1, true) then
        return { Cactus = true }
    end
    if n:find("hatchet", 1, true) or n:find("axe", 1, true) or n:find("chainsaw", 1, true)
        or n:find("machete", 1, true) then
        return { Trees = true, Logs = true, Cactus = true }
    end
    -- hybrid / unknown gather melee
    return { Trees = true, Nodes = true, Logs = true, Cactus = true }
end

function M.load()
    if loaded then return true end

    farm_tools = {}
    tool_caps = {}

    for name, caps in pairs(FALLBACK_GATHER_TOOLS) do
        farm_tools[name] = true
        tool_caps[name] = caps
    end

    local data = bootstrap.get_module("ToolInfo")
    if type(data) == "table" then
        for name, entry in pairs(data) do
            if type(name) == "string" and entry_can_gather(entry) then
                farm_tools[name] = true
                local caps = caps_from_object_damages(entry.ObjectDamages)
                if caps then
                    tool_caps[name] = caps
                end
            end
        end
    end

    loaded = true
    return next(farm_tools) ~= nil
end

function M.invalidate()
    loaded = false
    farm_tools = {}
    tool_caps = {}
end

function M.is_farm_tool_name(name)
    name = normalize(name)
    if not name then return false end
    if not loaded then M.load() end
    if farm_tools[name] then return true end
    return name_hint_match(name)
end

function M.tool_caps(tool_name)
    tool_name = normalize(tool_name)
    if not tool_name then return nil end
    if not loaded then M.load() end
    local caps = tool_caps[tool_name]
    if caps then return caps end
    if name_hint_match(tool_name) then
        return hint_caps(tool_name)
    end
    return nil
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

    -- Cheap path first (entity tool_name).
    local from_lp = pick_farm_name(lp.tool_name)
    if from_lp then return from_lp end

    local char = lp.character
    if char and env.is_valid(char) then
        local hit = scan_children(env.safe_call(function() return char:get_children() end))
        if hit then return hit end
    end

    -- Viewmodel fallback (some tools only show here).
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

    return nil
end

function M.holding_farm_tool()
    return M.get_held_farm_tool_name() ~= nil
end

local function box_reach(box)
    if not box then return nil end
    local sz = box.Size or box.size
    if sz then
        local r = sz.X or sz.x
        if r and r > 0 then return r end
    end
    local mag = box.Magnitude
    if type(mag) == "number" and mag > 0 then
        return mag
    end
    return nil
end

function M.melee_range(tool_name)
    tool_name = normalize(tool_name)
    if not tool_name then return 5 end

    local cached = MELEE_RANGE[tool_name]
    if cached then return cached end

    local data = bootstrap.get_module("ToolInfo")
    local entry = data and data[tool_name]
    local checks = entry and entry.Melee and entry.Melee.MeleeChecks
    if type(checks) == "table" then
        local best = 0
        for i = 1, #checks do
            local row = checks[i]
            local reach = row and box_reach(row[2])
            if reach and reach > best then
                best = reach
            end
        end
        if best > 0 then
            return best
        end
    end

    return 5
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
