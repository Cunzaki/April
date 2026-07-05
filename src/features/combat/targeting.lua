local settings = April.require("core.settings")
local weapons = April.require("game.weapons")
local math_util = April.require("core.math_util")
local esp_util = April.require("core.esp_util")
local player_state = April.require("game.player_state")

local M = {}

M.BONES = esp_util.AIM_BONES

local function w2s(x, y, z)
    return esp_util.w2s(x, y, z)
end

function M.bone_name(prefix)
    local idx = settings.num(prefix .. "bone", 0)
    return M.BONES[(idx or 0) + 1] or "Head"
end

function M.weapon_stats()
    local stats = weapons.get_weapon_stats()
    if stats then return stats end
    return { speed = 950, gravity = 35, name = "Unknown" }
end

function M.bone_world(target, bone)
    if not target or not target.is_alive then return nil end
    if bone == "Closest" then return nil end

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

    if target.get_bone_screen then
        local _, _, vis = target:get_bone_screen(bone)
        if not vis then return nil end
    end

    if bone == "Head" and target.head_position then
        local pos = target.head_position
        return { x = pos.x, y = pos.y, z = pos.z }
    end
    if target.position then
        local pos = target.position
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
        return target.velocity.x or 0, target.velocity.y or 0, target.velocity.z or 0
    end

    if target.character then
        local env = April.require("core.env")
        local root = env.safe_call(function()
            return target.character:find_first_child("HumanoidRootPart")
                or target.character:FindFirstChild("HumanoidRootPart")
        end)
        if root then
            local vel = root.Velocity or root.velocity
            if vel and vel.x then
                return vel.x, vel.y, vel.z
            end
            local assembly = root.AssemblyLinearVelocity
            if assembly and assembly.x then
                return assembly.x, assembly.y, assembly.z
            end
        end
    end

    return 0, 0, 0
end

function M.predict_point(origin, point, target)
    local ox, oy, oz = origin.x, origin.y, origin.z
    local px, py, pz = point.x, point.y, point.z

    local stats = M.weapon_stats()
    local speed = math.max(stats.speed or 950, 1)
    local drop_g = weapons.drop_gravity(stats.gravity)

    local vx, vy, vz = target_velocity(target)

    local dx = px - ox
    local dy = py - oy
    local dz = pz - oz
    local dist = math_util.distance3(dx, dy, dz)
    local time_to_hit = dist / speed

    for _ = 1, 3 do
        local ax = px + vx * time_to_hit
        local ay = py + vy * time_to_hit
        local az = pz + vz * time_to_hit

        dx = ax - ox
        dy = ay - oy
        dz = az - oz
        dist = math_util.distance3(dx, dy, dz)
        time_to_hit = dist / speed
    end

    local ax = px + vx * time_to_hit
    local ay = py + vy * time_to_hit
    local az = pz + vz * time_to_hit

    local horiz_dx = ax - ox
    local horiz_dz = az - oz
    local horiz = math.sqrt(horiz_dx * horiz_dx + horiz_dz * horiz_dz)
    local t_drop = horiz / speed
    ay = ay + 0.5 * drop_g * t_drop * t_drop

    return { x = ax, y = ay, z = az }
end

function M.get_aim_point(target, prefix, bone, origin, cx, cy)
    bone = bone or M.bone_name(prefix)
    local base
    if bone == "Closest" then
        base = M.closest_bone_world(target, cx, cy)
    else
        base = M.bone_world(target, bone)
    end
    if not base then return nil end

    if not origin and camera and camera.get_position then
        origin = camera.get_position()
    end
    if not origin then return base end

    return M.predict_point(origin, base, target)
end

function M.is_target_valid(target, prefix, cx, cy, fov_px)
    if not player_state.is_combat_target(target) then return false, nil end

    local cam = camera and camera.get_position and camera.get_position()
    local aim = M.get_aim_point(target, prefix, nil, cam, cx, cy)
    if not aim then return false, nil end

    if settings.bool(prefix .. "visible", false) and raycast and raycast.is_visible and cam then
        if not raycast.is_visible(cam.x, cam.y, cam.z, aim.x, aim.y, aim.z) then
            return false, nil
        end
    end

    local sx, sy, on_screen = w2s(aim.x, aim.y, aim.z)
    if not on_screen then return false, nil end

    local fov_dist = math_util.screen_fov_dist(sx, sy, cx, cy)
    if fov_dist > fov_px then return false, nil end

    return true, aim
end

function M.find_target(cx, cy, fov_px, prefix)
    if not entity or not entity.get_players then return nil end

    local bone = M.bone_name(prefix)
    local use_fov = settings.num(prefix .. "priority", 1) == 1
    local best, best_score = nil, use_fov and fov_px or math.huge
    local cam = camera and camera.get_position and camera.get_position()

    for _, p in ipairs(entity.get_players()) do
        if not player_state.is_combat_target(p) then goto continue end

        local aim
        if bone == "Closest" then
            aim = M.get_aim_point(p, prefix, "Closest", cam, cx, cy)
        else
            aim = M.get_aim_point(p, prefix, bone, cam, cx, cy)
        end
        if not aim then goto continue end

        if settings.bool(prefix .. "visible", false) and raycast and raycast.is_visible and cam then
            if not raycast.is_visible(cam.x, cam.y, cam.z, aim.x, aim.y, aim.z) then
                goto continue
            end
        end

        local sx, sy, on_screen = w2s(aim.x, aim.y, aim.z)
        if not on_screen then goto continue end

        local fov_dist = math_util.screen_fov_dist(sx, sy, cx, cy)
        if fov_dist > fov_px then goto continue end

        local score = use_fov and fov_dist or (p.distance_to and cam and p:distance_to(cam) or fov_dist)
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
