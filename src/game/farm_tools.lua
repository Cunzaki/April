local bootstrap = April.require("game.bootstrap")
local env = April.require("core.env")

local M = {}

local loaded = false
local farm_tools = {}
local tool_kinds = {}

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
    Boulder = true,
    Machete = true,
    ["Saw Bat"] = true,
}

-- Dump ToolInfo ObjectDamages defaults when module table is incomplete.
local FALLBACK_KINDS = {
    ["Stone Hatchet"] = { trees = true, logs = true, cactus = true },
    ["Iron Shard Hatchet"] = { trees = true, logs = true, cactus = true },
    ["Steel Axe"] = { trees = true, logs = true, cactus = true },
    Chainsaw = { trees = true, logs = true, cactus = true },
    ["Stone Pickaxe"] = { nodes = true },
    ["Iron Shard Pickaxe"] = { nodes = true },
    ["Steel Pickaxe"] = { nodes = true },
    ["Mining Drill"] = { nodes = true },
    ["Bone Tool"] = { trees = true, nodes = true, logs = true, cactus = true },
    ["Candy Cane"] = { trees = true, nodes = true, logs = true, cactus = true },
    ["Carrot Blade"] = { trees = true, nodes = true, logs = true, cactus = true },
    Boulder = { trees = true, nodes = true, logs = true, cactus = true },
    Machete = { trees = true, logs = true, cactus = true },
    ["Saw Bat"] = { cactus = true },
}

local NAME_HINTS = {
    "hatchet", "pickaxe", "pick axe", " axe", "axe ",
    "chainsaw", "mining drill", "bone tool",
    "candy cane", "carrot blade", "boulder",
    "machete", "saw bat",
}

-- MeleeChecks reach from ToolInfo dump (RaycastUtil MouseRaycast / HitMelee).
local MELEE_RANGE = {
    ["Stone Hatchet"] = 5,
    ["Iron Shard Hatchet"] = 5,
    ["Steel Axe"] = 5.5,
    Chainsaw = 6.5,
    ["Stone Pickaxe"] = 5,
    ["Iron Shard Pickaxe"] = 5,
    ["Steel Pickaxe"] = 5.5,
    ["Mining Drill"] = 6.5,
    ["Bone Tool"] = 5,
    ["Candy Cane"] = 5,
    ["Carrot Blade"] = 5,
    Boulder = 4.5,
    Machete = 5.5,
    ["Saw Bat"] = 6.5,
}

local function inst_name(inst)
    if not inst then return nil end
    return inst.name or inst.Name
end

local function normalize(name)
    if not name or name == "" then return nil end
    return name
end

local function kinds_from_od(od)
    if type(od) ~= "table" then return nil end
    local kinds = {}
    if od.Trees ~= nil then kinds.trees = true end
    if od.Nodes ~= nil then kinds.nodes = true end
    if od.Logs ~= nil then kinds.logs = true end
    if od.Cactus ~= nil then kinds.cactus = true end
    if next(kinds) == nil then return nil end
    return kinds
end

local function entry_can_gather(entry)
    if not entry or not entry.Melee then return false end
    return kinds_from_od(entry.ObjectDamages) ~= nil
end

local function name_hint_match(name)
    local n = (name or ""):lower()
    for _, hint in ipairs(NAME_HINTS) do
        if n:find(hint, 1, true) then return true end
    end
    return false
end

local function hint_kinds(name)
    local n = (name or ""):lower()
    if n:find("pickaxe", 1, true) or n:find("mining drill", 1, true) then
        return { nodes = true }
    end
    if n:find("saw bat", 1, true) then
        return { cactus = true }
    end
    if n:find("hatchet", 1, true) or n:find("axe", 1, true) or n:find("chainsaw", 1, true)
        or n:find("machete", 1, true) then
        return { trees = true, logs = true, cactus = true }
    end
    -- Bone / candy / boulder style hybrids
    return { trees = true, nodes = true, logs = true, cactus = true }
end

function M.load()
    if loaded then return true end

    farm_tools = {}
    tool_kinds = {}
    for name in pairs(FALLBACK_GATHER_TOOLS) do
        farm_tools[name] = true
        tool_kinds[name] = FALLBACK_KINDS[name] or hint_kinds(name)
    end

    local data = bootstrap.get_module("ToolInfo")
    if type(data) == "table" then
        for name, entry in pairs(data) do
            if type(name) == "string" and entry_can_gather(entry) then
                farm_tools[name] = true
                tool_kinds[name] = kinds_from_od(entry.ObjectDamages) or FALLBACK_KINDS[name] or hint_kinds(name)
            end
        end
    end

    loaded = true
    return next(farm_tools) ~= nil
end

function M.invalidate()
    loaded = false
    farm_tools = {}
    tool_kinds = {}
end

function M.is_farm_tool_name(name)
    name = normalize(name)
    if not name then return false end
    if not loaded then M.load() end
    if farm_tools[name] then return true end
    return name_hint_match(name)
end

-- Which gather kinds this tool can damage (dump ObjectDamages).
function M.gather_kinds(tool_name)
    tool_name = normalize(tool_name)
    if not tool_name then return nil end
    if not loaded then M.load() end

    local kinds = tool_kinds[tool_name]
    if kinds then return kinds end

    local data = bootstrap.get_module("ToolInfo")
    local entry = data and data[tool_name]
    kinds = entry and kinds_from_od(entry.ObjectDamages)
    if kinds then
        tool_kinds[tool_name] = kinds
        return kinds
    end

    if FALLBACK_KINDS[tool_name] then
        return FALLBACK_KINDS[tool_name]
    end
    if name_hint_match(tool_name) then
        return hint_kinds(tool_name)
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
