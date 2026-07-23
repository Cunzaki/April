--[[
  Gather targeting — TreeX / NodeSpark preferred, Main fallback.

  Perf: distance-gate on cheap Main/CactusPart first. Never resolve TreeX /
  NodeSpark for models outside tool range.
]]

local env = April.require("core.env")
local folders = April.require("game.folders")

local M = {}

local function child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        return parent:find_first_child(name) or parent:FindFirstChild(name)
    end)
end

local function name_of(inst)
    return inst and (inst.Name or inst.name) or nil
end

local function read_pos(part)
    if not part or not env.is_valid(part) then return nil end
    local p = part.Position or part.position
    if not p or p.x == nil then return nil end
    return p
end

local function d2(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return dx * dx + dy * dy + dz * dz
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

local function marker_main(model, marker_name)
    local marker = child(model, marker_name)
    if not marker or not env.is_valid(marker) then return nil end
    return child(marker, "Main")
end

-- Cheap proxy part used only for distance gate (no TreeX/NodeSpark walk).
local function proxy_part(model, kind)
    if kind == "Cactus" then return child(model, "CactusPart") end
    if kind == "Dig" then return child(model, "Dirt") end
    if kind == "Logs" then return child(model, "Main") or child(model, "Branch") end
    return child(model, "Main")
end

-- Aim part once model is known in-range.
local function aim_part(model, kind)
    if kind == "Trees" then
        return marker_main(model, "TreeX") or child(model, "Main"), true
    end
    if kind == "Nodes" then
        local spark = marker_main(model, "NodeSpark")
        if spark then return spark, true end
        return child(model, "Main"), false
    end
    if kind == "Cactus" then
        local p = child(model, "CactusPart")
        return p, p ~= nil
    end
    if kind == "Dig" then
        local p = child(model, "Dirt")
        return p, p ~= nil
    end
    if kind == "Logs" then
        local p = child(model, "Main") or child(model, "Branch")
        return p, p ~= nil
    end
    return child(model, "Main"), false
end

function M.hit_part(model, kind)
    if not env.is_valid(model) then return nil, false end
    kind = kind or M.kind_from_name(name_of(model))
    local part, is_mark = aim_part(model, kind)
    if kind == "Trees" then
        is_mark = part ~= nil and child(model, "TreeX") ~= nil
    elseif kind == "Nodes" then
        is_mark = part ~= nil and child(model, "NodeSpark") ~= nil
    end
    return part, is_mark
end

local function folder_children(folder)
    if not env.is_valid(folder) then return nil end
    return env.safe_call(function() return folder:get_children() end)
end

local function folders_for_caps(caps)
    local list = {}
    local want_nodes = not caps or caps.Nodes
    local want_trees = not caps or caps.Trees
    local want_veg = caps and (caps.Logs or caps.Cactus or caps.Dig)

    if want_nodes then list[#list + 1] = folders.from_key("nodes") end
    if want_trees then list[#list + 1] = folders.get_folder("Trees") end
    if want_veg then list[#list + 1] = folders.from_key("vegetation") end
    return list
end

local function kind_allowed(caps, kind)
    if not kind then return false end
    if not caps then
        return kind == "Trees" or kind == "Nodes"
    end
    if kind == "Dig" then
        return caps.Dig == true or caps.Shovel == true
    end
    return caps[kind] == true
end

--[[
  Nearest in-range aim point.
  1) Gate on proxy Main distance (cheap)
  2) Only then resolve TreeX / NodeSpark
  3) Early-out if a close marker is found
]]
function M.find_nearest(origin, radius, tool_caps)
    if not origin or not radius or radius <= 0 then return nil end

    local limit2 = radius * radius
    local early2 = (radius * 0.45) * (radius * 0.45)
    local best_mark, best_mark_d2 = nil, limit2
    local best_plain, best_plain_d2 = nil, limit2
    local seen = {}

    local folder_list = folders_for_caps(tool_caps)
    for fi = 1, #folder_list do
        local folder = folder_list[fi]
        if folder and not seen[folder] then
            seen[folder] = true
            local children = folder_children(folder)
            if children then
                for i = 1, #children do
                    local model = children[i]
                    if env.is_valid(model) then
                        local kind = M.kind_from_name(name_of(model))
                        if kind_allowed(tool_caps, kind) then
                            local proxy = proxy_part(model, kind)
                            local ppos = read_pos(proxy)
                            if ppos and d2(ppos, origin) <= limit2 then
                                local part, is_mark = aim_part(model, kind)
                                -- Trees: aim_part returns mark|main; detect marker properly
                                if kind == "Trees" then
                                    local mark = marker_main(model, "TreeX")
                                    if mark then
                                        part, is_mark = mark, true
                                    else
                                        part, is_mark = child(model, "Main"), false
                                    end
                                elseif kind == "Nodes" then
                                    local mark = marker_main(model, "NodeSpark")
                                    if mark then
                                        part, is_mark = mark, true
                                    else
                                        part, is_mark = child(model, "Main"), false
                                    end
                                end

                                local pos = read_pos(part)
                                if pos then
                                    local dist = d2(pos, origin)
                                    if dist <= limit2 then
                                        if is_mark then
                                            if dist < best_mark_d2 then
                                                best_mark_d2 = dist
                                                best_mark = part
                                                if dist <= early2 then
                                                    return best_mark
                                                end
                                            end
                                        elseif dist < best_plain_d2 then
                                            best_plain_d2 = dist
                                            best_plain = part
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return best_mark or best_plain
end

function M.collect_near(origin, radius, out, _max_out, tool_caps)
    out = out or {}
    local part = M.find_nearest(origin, radius, tool_caps)
    if part then out[1] = part end
    return out
end

return M
