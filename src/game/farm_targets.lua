--[[
  Gather hit parts near the player (dump hierarchy):
  Trees: TreeX.Main (preferred) -> Main
  Nodes: NodeSpark.Main (preferred) -> Main
  Vegetation: CactusPart / Forest_Log Main|Branch

  Performance: maintains a lightweight spatial index, updated in small
  budgeted batches — never walks every tree/node on the ESP frame.
]]

local env = April.require("core.env")
local folders = April.require("game.folders")

local M = {}

-- Index entries: { model, kind, x, y, z, hit }
local index = {}
local index_n = 0

local folder_cache = {} -- key -> { folder, children, t }
local FOLDER_CACHE_MS = 2500
local INDEX_BUDGET = 48 -- models touched per index tick
local index_cursor = 1
local index_folder_i = 1
local last_index_ms = 0
local INDEX_TICK_MS = 50

local FOLDER_SPECS = {
    { key = "nodes", kind = "nodes" },
    { trees = true, kind = "trees" },
    { key = "vegetation", kind = "vegetation" },
}

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

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

local function folder_for(spec)
    if spec.trees then
        return folders.get_folder("Trees")
    end
    return folders.from_key(spec.key)
end

local function folder_children(spec)
    local key = spec.trees and "trees" or spec.key
    local now = tick_ms()
    local cached = folder_cache[key]
    if cached and cached.children and (now - cached.t) < FOLDER_CACHE_MS and env.is_valid(cached.folder) then
        return cached.children, cached.folder
    end
    local folder = folder_for(spec)
    if not env.is_valid(folder) then
        folder_cache[key] = { folder = nil, children = {}, t = now }
        return {}, nil
    end
    local children = env.safe_call(function() return folder:get_children() end) or {}
    folder_cache[key] = { folder = folder, children = children, t = now }
    return children, folder
end

local function vegetation_kind_name(name)
    if not name then return nil end
    if name:find("cactus", 1, true) then return "cactus" end
    if name:find("log", 1, true) then return "logs" end
    return nil
end

local function resolve_kind(model, spec_kind)
    if spec_kind ~= "vegetation" then return spec_kind end
    local name = (inst_name(model) or ""):lower()
    return vegetation_kind_name(name)
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

    local name = (inst_name(model) or ""):lower()
    if name:find("log", 1, true) then
        local part = main_from(model) or find_child(model, "Branch")
        if part then return part, "logs" end
    end

    if kind_hint == "nodes" or name:find("node", 1, true) then
        local part = main_from(model)
        if part then return part, "nodes" end
    end

    if kind_hint == "cactus" then
        return cactus or main_from(model), "cactus"
    end

    if kind_hint == "logs" then
        local part = main_from(model) or find_child(model, "Branch")
        if part then return part, "logs" end
    end

    local part = main_from(model)
    if part then
        return part, kind_hint or "trees"
    end
    return nil, nil
end

local function upsert_index(model, kind)
    local hit, resolved = M.hit_part_from_model(model, kind)
    kind = resolved or kind
    if not hit then return end
    local pos = part_pos(hit)
    if not pos then return end

    for i = 1, index_n do
        local e = index[i]
        if e and e.model == model then
            e.kind = kind
            e.x, e.y, e.z = pos.x, pos.y, pos.z
            e.hit = hit
            return
        end
    end

    index_n = index_n + 1
    index[index_n] = {
        model = model,
        kind = kind,
        x = pos.x,
        y = pos.y,
        z = pos.z,
        hit = hit,
    }
end

local function compact_index()
    local write = 1
    for i = 1, index_n do
        local e = index[i]
        if e and e.model and env.is_valid(e.model) and e.hit and env.is_valid(e.hit) then
            if write ~= i then
                index[write] = e
            end
            write = write + 1
        end
    end
    for i = write, index_n do
        index[i] = nil
    end
    index_n = write - 1
    if index_cursor > index_n then index_cursor = 1 end
end

-- Advance the spatial index a little each call (budgeted).
-- force=true skips the tick gate (used when near-list is empty / just enabled).
function M.tick_index(force)
    local now = tick_ms()
    if not force and (now - last_index_ms) < INDEX_TICK_MS then return end
    last_index_ms = now

    local budget = force and (INDEX_BUDGET * 3) or INDEX_BUDGET
    local started_folder = index_folder_i
    local started_cursor = index_cursor

    while budget > 0 do
        local spec = FOLDER_SPECS[index_folder_i]
        if not spec then
            index_folder_i = 1
            index_cursor = 1
            compact_index()
            break
        end

        local children = folder_children(spec)
        local n = #children
        if n == 0 or index_cursor > n then
            index_folder_i = index_folder_i + 1
            if index_folder_i > #FOLDER_SPECS then
                index_folder_i = 1
                compact_index()
            end
            index_cursor = 1
            if index_folder_i == started_folder and index_cursor == started_cursor then
                break
            end
        else
            local model = children[index_cursor]
            index_cursor = index_cursor + 1
            budget = budget - 1
            if env.is_valid(model) then
                local is_model = model.ClassName == "Model"
                    or env.safe_call(function() return model:is_a("Model") end)
                if is_model then
                    local kind = resolve_kind(model, spec.kind)
                    if kind then
                        upsert_index(model, kind)
                    end
                end
            end
        end
    end
end

local function kind_allowed(kind, allow)
    if not allow then return true end
    if not kind then return false end
    return allow[kind] == true
end

local function refresh_entry_hit(e)
    if not e or not e.model or not env.is_valid(e.model) then return false end
    local hit, kind = M.hit_part_from_model(e.model, e.kind)
    if not hit then return false end
    local pos = part_pos(hit)
    if not pos then return false end
    e.hit = hit
    e.kind = kind or e.kind
    e.x, e.y, e.z = pos.x, pos.y, pos.z
    return true
end

-- Query near list from spatial index (cheap). Refreshes hit parts for near hits only.
function M.collect_near(origin, radius, out, max_out, allow)
    out = out or {}
    max_out = max_out or 16
    if not origin or radius <= 0 then return out end

    M.tick_index()

    local limit2 = (radius + 6) * (radius + 6)
    local write = 1

    for i = 1, index_n do
        if write > max_out then break end
        local e = index[i]
        if e and kind_allowed(e.kind, allow) then
            local dx = e.x - origin.x
            local dy = e.y - origin.y
            local dz = e.z - origin.z
            if (dx * dx + dy * dy + dz * dz) <= limit2 then
                if refresh_entry_hit(e) then
                    dx = e.x - origin.x
                    dy = e.y - origin.y
                    dz = e.z - origin.z
                    if (dx * dx + dy * dy + dz * dz) <= limit2 and env.is_valid(e.hit) then
                        out[write] = e.hit
                        write = write + 1
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

function M.reset()
    index = {}
    index_n = 0
    folder_cache = {}
    index_cursor = 1
    index_folder_i = 1
    last_index_ms = 0
end

return M
