local settings = April.require("core.settings")
local weapons = April.require("game.weapons")
local ballistic = April.require("core.ballistic")
local combat_origin = April.require("game.combat_origin")
local combat_menu = April.require("features.combat.combat_menu")
local math_util = April.require("core.math_util")
local esp_util = April.require("core.esp_util")
local player_state = April.require("game.player_state")

local M = {}

M.BONES = esp_util.AIM_BONES

local function w2s(x, y, z)
    return esp_util.w2s(x, y, z)
end

local function passes_visibility(target, aim, origin)
    if not raycast then return true end
    if not origin or not aim then return true end

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

    local dist = target.distance_to and target:distance_to(origin) or nil
    if not dist and target.position and origin then
        local pos = target.position
        dist = math_util.distance3((pos.x or 0) - origin.x, (pos.y or 0) - origin.y, (pos.z or 0) - origin.z)
    end

    return dist == nil or dist <= max_d
end

function M.bone_world(target, bone)
    if not target or not target.is_alive then return nil end
    if bone == "Closest" then return nil end

    if bone == "Head" and target.head_position then
        local pos = target.head_position
        return { x = pos.x, y = pos.y, z = pos.z }
    end

    if target.character then
        local env = April.require("core.env")
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
    if target.get_bones_screen then
        local bones = target:get_bones_screen()
        if bones then
            local best_name, best_dist = nil, math.huge
            for name, entry in pairs(bones) do
                local bx = entry.x or entry[1]
                local by = entry.y or entry[2]
                if bx and by then
                    local d = math_util.screen_fov_dist(bx, by, cx, cy)
                    if d < best_dist then
                        best_dist = d
                        best_name = name
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
        local env = April.require("core.env")
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
    if not player_state.is_combat_target(target) then return false end

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

function M.find_target(cx, cy, fov_px, prefix)
    if not entity or not entity.get_players then return nil end

    local bone = M.bone_name(prefix)
    local screen_bone = bone == "Closest" and "Head" or bone
    local use_fov = M.target_priority_crosshair(prefix)
    local best, best_score = nil, use_fov and fov_px or math.huge
    local origin = combat_origin.get_camera_origin() or combat_origin.get_fire_origin()
    local filter_visible = settings.bool(prefix .. "filter_visible", false)

    for _, p in ipairs(entity.get_players()) do
        if not player_state.is_combat_target(p) then goto continue end
        if not M.within_max_distance(p, origin, prefix) then goto continue end

        local base = M.bone_world(p, screen_bone)
        if not base then goto continue end

        if filter_visible and not passes_visibility(p, base, origin) then goto continue end
        if not M.passes_filters(p, prefix, base, origin) then goto continue end

        local sx, sy, on_screen = w2s(base.x, base.y, base.z)
        if not on_screen then goto continue end

        local fov_dist = math_util.screen_fov_dist(sx, sy, cx, cy)
        if fov_dist > fov_px then goto continue end

        local score = use_fov and fov_dist or (p.distance_to and origin and p:distance_to(origin) or fov_dist)
        if score < best_score then
            best_score = score
            best = p
        end
        ::continue::
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
