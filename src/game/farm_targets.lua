--[[
  Gather hit parts near the player (dump hierarchy):
  Trees: TreeX.Main (preferred) -> Main
  Nodes: NodeSpark.Main (preferred) -> Main
  Plants: Main + Item
  Vegetation: CactusPart / Forest_Log Main|Branch
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

local function inst_name(inst)
    if not inst then return nil end
    return inst.Name or inst.name
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

local function rough_pos(model)
    local main = main_from(model) or find_child(model, "Main")
    local pos = part_pos(main)
    if pos then return pos, main end

    local cactus = find_child(model, "CactusPart")
    pos = part_pos(cactus)
    if pos then return pos, cactus end

    local branch = find_child(model, "Branch")
    return part_pos(branch), branch
end

-- Preferred melee hit part for a model (TreeX / NodeSpark when present).
function M.hit_part_from_model(model, kind_hint)
    if not env.is_valid(model) then return nil, nil end

    local spark = find_child(model, "NodeSpark")
    if spark and env.is_valid(spark) then
        local part = main_from(spark)
        if part then return part, "nodes" end
    end

    local tree_x = find_child(model, "TreeX")
    if tree_x and env.is_valid(tree_x) then
        local part = main_from(tree_x)
        if part then return part, "trees" end
    end

    local cactus = find_child(model, "CactusPart")
    if cactus and env.is_valid(cactus) then
        return cactus, "cactus"
    end

    if find_child(model, "Item") then
        local part = main_from(model)
        if part then return part, "plants" end
    end

    local name = (inst_name(model) or ""):lower()
    if name:find("log", 1, true) or name:find("forest_log", 1, true) then
        local part = main_from(model) or find_child(model, "Branch")
        if part then return part, "logs" end
    end

    if name:find("node", 1, true) or kind_hint == "nodes" then
        local part = main_from(model)
        if part then return part, "nodes" end
    end

    if name:find("tree", 1, true) or name:find("desert_tree", 1, true) or kind_hint == "trees" then
        local part = main_from(model)
        if part then return part, "trees" end
    end

    if kind_hint == "cactus" then
        return cactus or main_from(model), "cactus"
    end

    if kind_hint == "logs" then
        local part = main_from(model) or find_child(model, "Branch")
        if part then return part, "logs" end
    end

    if kind_hint == "plants" then
        local part = main_from(model)
        if part then return part, "plants" end
    end

    -- Last resort: model Main (covers odd Desert/Tree variants).
    local part = main_from(model)
    if part then
        return part, kind_hint or "trees"
    end
    return nil, nil
end

local FOLDER_SPECS = {
    { key = "nodes", kind = "nodes" },
    { trees = true, kind = "trees" },
    { key = "plants", kind = "plants" },
    { key = "vegetation", kind = "vegetation" },
}

local function folder_for(spec)
    if spec.trees then
        return folders.get_folder("Trees")
    end
    return folders.from_key(spec.key)
end

local function vegetation_kind(model)
    local name = (inst_name(model) or ""):lower()
    if name:find("cactus", 1, true) or find_child(model, "CactusPart") then
        return "cactus"
    end
    if name:find("log", 1, true) then
        return "logs"
    end
    -- Bushes / ferns / DigPile / boulders are not standard gather melee targets.
    return nil
end

local function kind_allowed(kind, allow)
    if not allow then return true end
    if not kind then return false end
    return allow[kind] == true
end

-- Scan every child in gather folders; keep only parts within range.
-- `allow` optional: { trees=true, nodes=true, logs=true, cactus=true, plants=true }
-- Returns list of BaseParts (hit parts).
function M.collect_near(origin, radius, out, max_out, allow)
    out = out or {}
    max_out = max_out or 48
    if not origin or radius <= 0 then return out end

    -- Pad so we don't drop borderline targets while locked / moving.
    local limit2 = (radius + 10) * (radius + 10)
    local write = 1

    for s = 1, #FOLDER_SPECS do
        if write > max_out then break end
        local spec = FOLDER_SPECS[s]
        local folder = folder_for(spec)
        if env.is_valid(folder) then
            local children = env.safe_call(function() return folder:get_children() end) or {}
            for i = 1, #children do
                if write > max_out then break end
                local model = children[i]
                if env.is_valid(model) then
                    local is_model = model.ClassName == "Model"
                        or env.safe_call(function() return model:is_a("Model") end)
                    if is_model then
                        local kind = spec.kind
                        if kind == "vegetation" then
                            kind = vegetation_kind(model)
                        end

                        if kind and kind_allowed(kind, allow) then
                            local rough, rough_part = rough_pos(model)
                            if rough and dist2(rough, origin) <= limit2 then
                                local part = select(1, M.hit_part_from_model(model, kind))
                                if not part then part = rough_part end
                                local pos = part_pos(part)
                                if pos and dist2(pos, origin) <= limit2 then
                                    out[write] = part
                                    write = write + 1
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    for i = write, #out do
        out[i] = nil
    end
    return out
end

return M
