-- Gather target index and live TreeX / NodeSpark weak-point resolution.
-- The dump proves HitMelee gives parts parented to TreeX/NodeSpark priority 3.
local env = April.require("core.env")
local folders = April.require("game.folders")

local M = {}

local CELL_SIZE = 24
local INDEX_REFRESH_MS = 900
local buckets = {}
local records = {}
local last_refresh_ms = -INDEX_REFRESH_MS

local function now_ms()
    local fn = utility and (utility.get_tick_count or utility.GetTickCount)
    if type(fn) ~= "function" then return 0 end
    local ok, value = pcall(fn)
    return ok and (tonumber(value) or 0) or 0
end

local function child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        if parent.FindFirstChild then return parent:FindFirstChild(name) end
        if parent.find_first_child then return parent:find_first_child(name) end
        return nil
    end)
end

local function children(parent)
    if not parent then return {} end
    return env.safe_call(function()
        if parent.GetChildren then return parent:GetChildren() end
        if parent.get_children then return parent:get_children() end
        return {}
    end) or {}
end

local function name_of(inst)
    return inst and (inst.Name or inst.name) or nil
end

local function read_pos(part)
    if not part or not env.is_valid(part) then return nil end
    local p = part.Position or part.position
    if not p then return nil end
    local x, y, z = p.x or p.X, p.y or p.Y, p.z or p.Z
    if x == nil or y == nil or z == nil then return nil end
    return { x = x, y = y, z = z }
end

local function horizontal_radius(part)
    if not part then return 0 end
    local size
    local ok = pcall(function() size = part.Size or part.size end)
    if not ok or not size then return 0 end
    local sx = tonumber(size.X or size.x) or 0
    local sz = tonumber(size.Z or size.z) or 0
    return math.min(12, (sx + sz) * 0.25)
end

local function d2(a, b)
    if not a or not b then return math.huge end
    local ax, ay, az = a.x or a.X, a.y or a.Y, a.z or a.Z
    local bx, by, bz = b.x or b.X, b.y or b.Y, b.z or b.Z
    if ax == nil or ay == nil or az == nil or bx == nil or by == nil or bz == nil then
        return math.huge
    end
    local dx, dy, dz = ax - bx, ay - by, az - bz
    return dx * dx + dy * dy + dz * dz
end

local function flat_d2(a, b)
    if not a or not b then return math.huge end
    local ax, az = a.x or a.X, a.z or a.Z
    local bx, bz = b.x or b.X, b.z or b.Z
    if ax == nil or az == nil or bx == nil or bz == nil then return math.huge end
    local dx, dz = ax - bx, az - bz
    return dx * dx + dz * dz
end

local function record_key(model)
    return tostring(model and (model.Address or model.address or model) or "")
end

local function bucket_key(x, z)
    return tostring(math.floor(x / CELL_SIZE)) .. ":" .. tostring(math.floor(z / CELL_SIZE))
end

function M.kind_from_name(name)
    if not name or name == "" then return nil end
    if name:find("_Node", 1, true) then return "Nodes" end
    if name:find("Desert_Tree", 1, true) or name:find("Tree_", 1, true) then return "Trees" end
    if name:find("Forest_Log", 1, true) then return "Logs" end
    if name:find("Desert_Cactus", 1, true) then return "Cactus" end
    if name == "DigPile" then return "Dig" end
    return nil
end

function M.resource_type_from_name(name)
    if not name or name == "" then return nil end
    local lower = name:lower()
    if lower:find("stone_node", 1, true) then return "Stone" end
    if lower:find("metal_node", 1, true) then return "Metal" end
    if lower:find("phosphate_node", 1, true) then return "Phosphate" end
    local kind = M.kind_from_name(name)
    if kind == "Trees" then return "Trees" end
    return kind
end

local function marker_main(model, marker_name)
    local marker = child(model, marker_name)
    if not marker or not env.is_valid(marker) then return nil end
    local main = child(marker, "Main")
    if main and env.is_valid(main) then return main end
    return nil
end

local function weak_part(model, kind)
    if kind == "Trees" then return marker_main(model, "TreeX") end
    if kind == "Nodes" then return marker_main(model, "NodeSpark") end
    return nil
end

local function proxy_part(model, kind)
    if kind == "Cactus" then return child(model, "CactusPart") end
    if kind == "Dig" then return child(model, "Dirt") end
    if kind == "Logs" then return child(model, "Main") or child(model, "Branch") end
    return child(model, "Main")
end

local function aim_part(model, kind)
    if kind == "Trees" or kind == "Nodes" then
        local mark = weak_part(model, kind)
        return mark or proxy_part(model, kind), mark ~= nil
    end
    local part = proxy_part(model, kind)
    return part, part ~= nil
end

local function depleted(model)
    if not model or not env.is_valid(model) then return true end
    local destroyed = env.get_attribute(model, "Destroyed")
    if destroyed == true or destroyed == 1 then return true end
    local health = tonumber(env.get_attribute(model, "Health"))
    return health ~= nil and health <= 0
end

local function health_snapshot(model)
    if not model then return nil, nil, nil end
    return tonumber(env.get_attribute(model, "Health")),
        tonumber(env.get_attribute(model, "MaxHealth")),
        tonumber(env.get_attribute(model, "State"))
end

local function kind_allowed(caps, kind)
    if not kind then return false end
    if not caps then return kind == "Trees" or kind == "Nodes" end
    if kind == "Dig" then return caps.Dig == true or caps.Shovel == true end
    return caps[kind] == true
end

local function record_allowed(record, caps, opts)
    if not record or not kind_allowed(caps, record.kind) then return false end
    opts = opts or {}
    if opts.allowed and opts.allowed[record.resource_type] ~= true then return false end
    if opts.skip_keys and opts.skip_keys[record.key] then return false end
    return true
end

local function add_record(model, parent)
    if not model or not env.is_valid(model) then return end
    local kind = M.kind_from_name(name_of(model))
    if not kind then return end
    local proxy = proxy_part(model, kind)
    local pos = read_pos(proxy)
    if not pos then return end
    local record = {
        model = model,
        kind = kind,
        resource_type = M.resource_type_from_name(name_of(model)),
        proxy = proxy,
        base_pos = pos,
        body_radius = horizontal_radius(proxy),
        key = record_key(model),
        parent_key = record_key(parent),
    }
    records[#records + 1] = record
    local key = bucket_key(pos.x, pos.z)
    buckets[key] = buckets[key] or {}
    buckets[key][#buckets[key] + 1] = record
end

local function resource_folders()
    local out = {}
    local nodes = folders.from_key("nodes")
    local trees = folders.get_folder("Trees")
    local vegetation = folders.from_key("vegetation")
    if nodes then out[#out + 1] = nodes end
    if trees then out[#out + 1] = trees end
    if vegetation then out[#out + 1] = vegetation end
    return out
end

function M.refresh_index(force)
    local now = now_ms()
    if not force and now - last_refresh_ms < INDEX_REFRESH_MS then return false end
    last_refresh_ms = now
    buckets = {}
    records = {}
    local seen = {}
    for _, folder in ipairs(resource_folders()) do
        if folder and not seen[folder] then
            seen[folder] = true
            for _, model in ipairs(children(folder)) do
                add_record(model, folder)
            end
        end
    end
    return true
end

function M.invalidate()
    buckets = {}
    records = {}
    last_refresh_ms = -INDEX_REFRESH_MS
end

function M.hit_part(model, kind)
    if not model or depleted(model) then return nil, false end
    kind = kind or M.kind_from_name(name_of(model))
    return aim_part(model, kind)
end

function M.is_depleted(model)
    return depleted(model)
end

function M.health(model)
    return health_snapshot(model)
end

function M.resolve(record)
    if not record or depleted(record.model) then return nil end
    local current_parent = record.model.Parent or record.model.parent
    if not current_parent or record_key(current_parent) ~= record.parent_key then
        return nil
    end
    local body = record.proxy
    if not body or not env.is_valid(body) then
        body = proxy_part(record.model, record.kind)
        record.proxy = body
    end
    local body_pos = read_pos(body)
    if not body_pos then return nil end
    local weak = weak_part(record.model, record.kind)
    local weak_pos = read_pos(weak)
    local health, max_health, resource_state = health_snapshot(record.model)
    record.body_part = body
    record.body_pos = body_pos
    record.body_radius = horizontal_radius(body)
    record.base_pos = body_pos
    record.weak_part = weak_pos and weak or nil
    record.weak_pos = weak_pos
    record.weak_key = weak_pos and record_key(weak) or nil
    record.health = health
    record.max_health = max_health
    record.resource_state = resource_state
    -- Compatibility for Manual Farm Helper and legacy callers.
    record.part = record.weak_part or body
    record.pos = record.weak_pos or body_pos
    record.weak = record.weak_part ~= nil
    return record
end

local function visible(origin, pos)
    if not origin or not pos or not raycast then return nil end
    local ready_fn = raycast.is_ready or raycast.IsReady
    if type(ready_fn) == "function" then
        local ok, ready = pcall(ready_fn)
        if ok and ready == false then return nil end
    end
    local fn = raycast.is_visible or raycast.IsVisible
    if type(fn) ~= "function" then return nil end
    local ox, oy, oz = origin.x or origin.X, origin.y or origin.Y, origin.z or origin.Z
    if ox == nil or oy == nil or oz == nil then return nil end
    local ok, clear = pcall(fn, ox, oy, oz, pos.x, pos.y, pos.z)
    if not ok then return nil end
    return clear == true
end

local function better(candidate, candidate_d2, best, best_d2)
    if not best then return true end
    if candidate_d2 < best_d2 - 1e-6 then return true end
    if math.abs(candidate_d2 - best_d2) <= 1e-6 then
        return tostring(candidate.key) < tostring(best.key)
    end
    return false
end

function M.find_target(origin, radius, tool_caps, opts)
    if not origin or not radius or radius <= 0 then return nil end
    opts = opts or {}
    M.refresh_index(false)
    local ox, oz = origin.x or origin.X, origin.z or origin.Z
    if ox == nil or oz == nil then return nil end

    local limit2 = radius * radius
    local span = math.max(1, math.ceil(radius / CELL_SIZE) + 1)
    local cell_x = math.floor(ox / CELL_SIZE)
    local cell_z = math.floor(oz / CELL_SIZE)
    local best_visible, best_visible_d2 = nil, limit2
    local best_any, best_any_d2 = nil, limit2
    local visited = {}

    local function consider(record)
        if not visited[record.key] and record_allowed(record, tool_caps, opts) then
            visited[record.key] = true
            local resolved = M.resolve(record)
            if resolved then
                local center_d2 = flat_d2(resolved.base_pos or resolved.pos, origin)
                local surface = math.max(0, math.sqrt(center_d2) - (resolved.body_radius or 0))
                local dist = surface * surface
                if dist <= limit2 then
                    if better(resolved, dist, best_any, best_any_d2) then
                        best_any, best_any_d2 = resolved, dist
                    end
                    if opts.check_visibility ~= false
                        and visible(origin, resolved.pos) ~= false
                        and better(resolved, dist, best_visible, best_visible_d2)
                    then
                        best_visible, best_visible_d2 = resolved, dist
                    end
                end
            end
        end
    end

    if span > 16 then
        -- For very large ranges, populated buckets are much cheaper than
        -- probing tens of thousands of empty grid coordinates.
        for _, list in pairs(buckets) do
            for _, record in ipairs(list) do consider(record) end
        end
    else
        for x = cell_x - span, cell_x + span do
            for z = cell_z - span, cell_z + span do
                local list = buckets[tostring(x) .. ":" .. tostring(z)]
                for _, record in ipairs(list or {}) do consider(record) end
            end
        end
    end

    local best = best_visible or best_any
    if best then
        best.distance2 = best == best_visible and best_visible_d2 or best_any_d2
    end
    return best
end

-- Legacy helpers retained for internal callers/config compatibility.
function M.find_nearest(origin, radius, tool_caps)
    local record = M.find_target(origin, radius, tool_caps)
    return record and record.part or nil
end

function M.collect_near(origin, radius, out, _max_out, tool_caps)
    out = out or {}
    local part = M.find_nearest(origin, radius, tool_caps)
    if part then out[1] = part end
    return out
end

function M.distance2(pos, origin)
    return d2(pos, origin)
end

function M.surface_distance2(record, origin)
    if not record or not origin then return math.huge end
    local center = record.body_pos or record.base_pos or record.pos
    local center_d2 = flat_d2(center, origin)
    local surface = math.max(0, math.sqrt(center_d2) - (record.body_radius or 0))
    return surface * surface
end

return M
