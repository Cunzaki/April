local settings = April.require("core.settings")
local weapons = April.require("game.weapons")
local ballistic = April.require("core.ballistic")
local combat_origin = April.require("game.combat_origin")
local combat_menu = April.require("features.combat.combat_menu")
local math_util = April.require("core.math_util")
local esp_util = April.require("core.esp_util")
local player_state = April.require("game.player_state")
local cache = April.require("core.cache")
local npcs = April.require("game.npcs")
local env = April.require("core.env")

local M = {}

M.BONES = esp_util.AIM_BONES

local function w2s(x, y, z)
    return esp_util.w2s(x, y, z)
end

function M.is_npc_target(target)
    return target and target.is_npc == true
end

local function npc_enabled(entry, prefix)
    if not settings.bool(prefix .. "target_npcs", false) then
        return false
    end
    if entry.kind == "soldier" then
        return settings.bool(prefix .. "target_npc_soldiers", true)
    end
    if entry.kind == "boss" then
        return settings.bool(prefix .. "target_npc_bosses", true)
    end
    return false
end

local function read_npc_health(model)
    if not model or not env.is_valid(model) then
        return nil
    end
    local hum = env.safe_call(function()
        if model.find_first_child_of_class then
            return model:find_first_child_of_class("Humanoid")
        end
        return model:FindFirstChild("Humanoid")
    end)
    if not hum then
        return nil
    end
    local hp = hum.Health or hum.health
    if not hp or hp <= 0 then
        return nil
    end
    return hum
end

function M.is_npc_alive(entry)
    if not entry or not entry.inst or not env.is_valid(entry.inst) then
        return false
    end
    return read_npc_health(entry.inst) ~= nil
end

function M.is_aim_target(target)
    if M.is_npc_target(target) then
        return M.is_npc_alive(target)
    end
    return player_state.is_combat_target(target)
end

local function npc_head_world(entry)
    if not entry then
        return nil
    end
    if entry.lx then
        return { x = entry.lx, y = entry.ly, z = entry.lz }
    end
    local head = entry.head
    if head and env.is_valid(head) then
        local pos = head.Position or head.position
        if pos and pos.x then
            return { x = pos.x, y = pos.y, z = pos.z }
        end
    end
    return nil
end

local function npc_distance(entry, origin)
    if not origin or not entry then
        return nil
    end
    local pos = npc_head_world(entry)
    if not pos then
        return nil
    end
    return math_util.distance3(pos.x - origin.x, pos.y - origin.y, pos.z - origin.z)
end

local function passes_visibility(target, aim, origin)
    if not raycast then return true end
    if not origin or not aim then return true end

    if M.is_npc_target(target) then
        if raycast.is_visible then
            return raycast.is_visible(origin.x, origin.y, origin.z, aim.x, aim.y, aim.z)
        end
        return true
    end

    local char = target and target.character
    if char and utility and utility.is_valid(char) and raycast.is_player_visible then
        return raycast.is_player_visible(char.address)
    end

    if raycast.is_visible then
        return raycast.is_visible(origin.x, origin.y, origin.z, aim.x, aim.y, aim.z)
    end

    return true
end

function M.bone_name(prefix)
    local idx = settings.num(prefix .. "bone", 0)
    return combat_menu.bone_from_index(idx)
end

function M.target_priority_crosshair(prefix)
    local idx = settings.num(prefix .. "target_type", 0)
    return idx == 0
end

function M.passes_filters(target, prefix, aim, origin)
    if not target then return false end

    if M.is_npc_target(target) then
        if settings.bool(prefix .. "filter_health", true) and not M.is_npc_alive(target) then
            return false
        end
        if settings.bool(prefix .. "filter_visible", false) and not passes_visibility(target, aim, origin) then
            return false
        end
        return true
    end

    if settings.bool(prefix .. "filter_health", true) then
        if not player_state.passes_health_check(target) then return false end
    end

    if settings.bool(prefix .. "filter_team", true) then
        if not player_state.passes_team_check(target) then return false end
    end

    if settings.bool(prefix .. "filter_visible", false) then
        if not passes_visibility(target, aim, origin) then return false end
    end

    return true
end

function M.within_max_distance(target, origin, prefix)
    local max_d = settings.num(prefix .. "max_dist", 500)
    if max_d <= 0 or not origin then return true end

    if M.is_npc_target(target) then
        local dist = npc_distance(target, origin)
        return dist == nil or dist <= max_d
    end

    local dist = target.distance_to and target:distance_to(origin) or nil
    if not dist and target.position and origin then
        local pos = target.position
        dist = math_util.distance3((pos.x or 0) - origin.x, (pos.y or 0) - origin.y, (pos.z or 0) - origin.z)
    end

    return dist == nil or dist <= max_d
end

function M.bone_world(target, bone)
    if not target then return nil end

    if M.is_npc_target(target) then
        return npc_head_world(target)
    end

    if not target.is_alive then return nil end
    if bone == "Closest" then return nil end

    if bone == "Head" and target.head_position then
        local pos = target.head_position
        return { x = pos.x, y = pos.y, z = pos.z }
    end

    if target.character then
        local part = env.safe_call(function()
            return target.character:find_first_child(bone) or target.character:FindFirstChild(bone)
        end)
        if part and env.is_valid(part) then
            local ppos = part.Position or part.position
            if ppos and ppos.x then
                return { x = ppos.x, y = ppos.y, z = ppos.z }
            end
        end
    end

    if target.position then
        local pos = target.position
        if bone == "Head" then
            return nil
        end
        return { x = pos.x, y = pos.y, z = pos.z }
    end
    return nil
end

function M.closest_bone_world(target, cx, cy)
    cx = cx or 0
    cy = cy or 0
    if M.is_npc_target(target) then
        return npc_head_world(target)
    end
    if target and target.get_bones_screen then
        local ok, bones = pcall(function()
            return target:get_bones_screen()
        end)
        if ok and type(bones) == "table" then
            local best_name, best_dist = nil, math.huge
            for name, entry in pairs(bones) do
                if type(entry) == "table" and type(name) == "string" and name ~= "Closest" then
                    local bx = entry.x or entry[1]
                    local by = entry.y or entry[2]
                    if type(bx) == "number" and type(by) == "number" then
                        local d = math_util.screen_fov_dist(bx, by, cx, cy)
                        if d < best_dist then
                            best_dist = d
                            best_name = name
                        end
                    end
                end
            end
            if best_name then
                local world = M.bone_world(target, best_name)
                if world then return world end
            end
        end
    end
    return M.bone_world(target, "Head")
end

local function target_velocity(target)
    if M.is_npc_target(target) and target.inst and env.is_valid(target.inst) then
        local root = env.safe_call(function()
            return target.inst:find_first_child("HumanoidRootPart")
                or target.inst:FindFirstChild("HumanoidRootPart")
        end)
        if root and env.is_valid(root) then
            local vel = root.AssemblyLinearVelocity or root.Velocity or root.velocity
            if vel and vel.x then
                return {
                    x = vel.x,
                    y = math.max(-100, math.min(100, vel.y or 0)),
                    z = vel.z,
                }
            end
        end
        return { x = 0, y = 0, z = 0 }
    end

    if target.velocity then
        local v = target.velocity
        if v.x ~= nil then
            return {
                x = v.x,
                y = math.max(-100, math.min(100, v.y or 0)),
                z = v.z,
            }
        end
    end

    if target.character then
        local root = env.safe_call(function()
            return target.character:find_first_child("HumanoidRootPart")
                or target.character:FindFirstChild("HumanoidRootPart")
        end)
        if root and env.is_valid(root) then
            local vel = root.AssemblyLinearVelocity or root.Velocity or root.velocity
            if vel and vel.x then
                return {
                    x = vel.x,
                    y = math.max(-100, math.min(100, vel.y or 0)),
                    z = vel.z,
                }
            end
        end
    end

    return { x = 0, y = 0, z = 0 }
end

function M.predict_point(origin, point, target, weapon_name)
    if not origin or not point then return point end
    local vel = target_velocity(target)
    weapon_name = weapon_name or weapons.cached_held_ranged()
    return ballistic.predict_for_weapon(origin, point, vel, weapon_name)
end

function M.resolve_bone_world(target, bone, cx, cy)
    bone = bone or "Head"
    if bone == "Closest" then
        return M.closest_bone_world(target, cx, cy)
    end
    return M.bone_world(target, bone)
end

function M.get_aim_point(target, prefix, bone, origin, cx, cy, use_prediction)
    bone = bone or M.bone_name(prefix)
    local base = M.resolve_bone_world(target, bone, cx, cy)
    if not base then return nil end

    if use_prediction == false then
        return base
    end

    origin = origin or combat_origin.get_fire_origin()
    if not origin then return base end

    return M.predict_point(origin, base, target, weapons.cached_held_ranged())
end

function M.is_target_valid(target, prefix, cx, cy, fov_px)
    if not M.is_aim_target(target) then return false end

    local origin = combat_origin.get_camera_origin() or combat_origin.get_fire_origin()
    if not M.within_max_distance(target, origin, prefix) then return false end

    local bone = M.bone_name(prefix)
    local base = M.resolve_bone_world(target, bone == "Closest" and "Head" or bone, cx, cy)
    if not base then return false end

    if not M.passes_filters(target, prefix, base, origin) then return false end

    local sx, sy, on_screen = w2s(base.x, base.y, base.z)
    if not on_screen then return false end

    local fov_dist = math_util.screen_fov_dist(sx, sy, cx, cy)
    return fov_dist <= fov_px
end

local function consider_target(target, prefix, screen_bone, use_fov, fov_px, origin, filter_visible, cx, cy, best, best_score)
    if not M.within_max_distance(target, origin, prefix) then
        return best, best_score
    end

    local base = M.bone_world(target, screen_bone)
    if not base then
        return best, best_score
    end

    if filter_visible and not passes_visibility(target, base, origin) then
        return best, best_score
    end
    if not M.passes_filters(target, prefix, base, origin) then
        return best, best_score
    end

    local sx, sy, on_screen = w2s(base.x, base.y, base.z)
    if not on_screen then
        return best, best_score
    end

    local fov_dist = math_util.screen_fov_dist(sx, sy, cx, cy)
    if fov_dist > fov_px then
        return best, best_score
    end

    local score
    if M.is_npc_target(target) then
        score = use_fov and fov_dist or (npc_distance(target, origin) or fov_dist)
    else
        score = use_fov and fov_dist or (target.distance_to and origin and target:distance_to(origin) or fov_dist)
    end

    if score < best_score then
        return target, score
    end
    return best, best_score
end

function M.find_target(cx, cy, fov_px, prefix)
    local bone = M.bone_name(prefix)
    local screen_bone = bone == "Closest" and "Head" or bone
    local use_fov = M.target_priority_crosshair(prefix)
    local best, best_score = nil, use_fov and fov_px or math.huge
    local origin = combat_origin.get_camera_origin() or combat_origin.get_fire_origin()
    local filter_visible = settings.bool(prefix .. "filter_visible", false)
    local target_players = settings.bool(prefix .. "target_players", true)
    local target_npcs = settings.bool(prefix .. "target_npcs", false)

    if target_players and entity and entity.get_players then
        for _, p in ipairs(entity.get_players()) do
            if player_state.is_combat_target(p) then
                best, best_score = consider_target(
                    p, prefix, screen_bone, use_fov, fov_px, origin, filter_visible, cx, cy, best, best_score
                )
            end
        end
    end

    if target_npcs and cache.npcs then
        for _, entry in ipairs(cache.npcs) do
            if npc_enabled(entry, prefix) and M.is_npc_alive(entry) then
                local npc_target = {
                    is_npc = true,
                    inst = entry.inst,
                    head = entry.head,
                    name = entry.name,
                    kind = entry.kind,
                    lx = entry.lx,
                    ly = entry.ly,
                    lz = entry.lz,
                }
                best, best_score = consider_target(
                    npc_target, prefix, screen_bone, use_fov, fov_px, origin, filter_visible, cx, cy, best, best_score
                )
            end
        end
    end

    return best
end

function M.screen_center()
    if draw and draw.get_screen_size then
        return draw.get_screen_size()
    end
    return 1920, 1080
end

return M
