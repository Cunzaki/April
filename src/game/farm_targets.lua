--[[
  Gather hit parts near the player - dump hierarchy:
  Nodes: NodeSpark.Main | Trees: TreeX.Main | Plants: Main+Item | Cactus: CactusPart
]]

local env = April.require("core.env")
local folders = April.require("game.folders")

local M = {}

local function find_child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        return parent:find_first_child(name) or parent:FindFirstChild(name)
    end)
end

local function part_pos(part)
    if not part or not env.is_valid(part) then return nil end
    local p = part.Position or part.position
    if not p or p.x == nil then return nil end
    return p
end

local function dist2(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return dx * dx + dy * dy + dz * dz
end

local function main_from(container)
    if not container or not env.is_valid(container) then return nil end
    local main = env.safe_call(function() return container.PrimaryPart end)
    if main and env.is_valid(main) then return main end
    return find_child(container, "Main")
end

function M.hit_part_from_model(model)
    if not env.is_valid(model) then return nil end

    local spark = find_child(model, "NodeSpark")
    if spark and env.is_valid(spark) then
        return main_from(spark)
    end

    local tree_x = find_child(model, "TreeX")
    if tree_x and env.is_valid(tree_x) then
        return main_from(tree_x)
    end

    if find_child(model, "Item") then
        return main_from(model)
    end

    return find_child(model, "CactusPart")
end

local FOLDER_SPECS = {
    { key = "nodes", max = 120 },
    { key = "plants", max = 80 },
    { trees = true, max = 120 },
}

local function folder_for(spec)
    if spec.trees then
        return folders.get_folder("Trees")
    end
    return folders.from_key(spec.key)
end

-- Only return harvest parts within range of origin (avoids scanning the whole map into RAM).
function M.collect_near(origin, radius, out, max_out)
    out = out or {}
    max_out = max_out or 32
    if not origin or radius <= 0 then return out end

    local limit2 = (radius + 8) * (radius + 8)

    for s = 1, #FOLDER_SPECS do
        if #out >= max_out then break end
        local spec = FOLDER_SPECS[s]
        local folder = folder_for(spec)
        if env.is_valid(folder) then
            for _, model in ipairs(folders.scan_children(folder, "Model", spec.max)) do
                if #out >= max_out then break end
                local part = M.hit_part_from_model(model)
                local pos = part_pos(part)
                if pos and dist2(pos, origin) <= limit2 then
                    out[#out + 1] = part
                end
            end
        end
    end

    return out
end

return M
