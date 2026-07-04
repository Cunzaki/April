--[[
    Hit detection — health-drop while shooting, impact point via camera-ray vs body parts.
    (Fallen references hook VFXModule.CreateBlood for exact position; Vector uses ray pick.)
]]

local settings = April.require("core.settings")
local env = April.require("core.env")
local cache = April.require("core.cache")
local math_util = April.require("core.math_util")
local esp_util = April.require("core.esp_util")
local draw_util = April.require("core.draw_util")

local M = {}

local health_history = {}
local last_hit_at = {}
local last_shoot_tick = 0
local last_idle_sync = 0
local was_shooting = false
local fire_origin = { x = 0, y = 0, z = 0 }
local fire_origin_tick = 0
local IDLE_SYNC_MS = 800
local SHOOT_WINDOW_MS = 250
local FIRE_ORIGIN_MS = 350
local HIT_DEBOUNCE_MS = 40
local DEFAULT_AIM_FOV = 250
local DEFAULT_MAX_HIT_DIST = 450

local AIM_BONES = {
    "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart",
    "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm",
    "LeftHand", "RightHand", "LeftUpperLeg", "RightUpperLeg",
    "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot",
    "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg",
}

local function tick()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function vec3(v)
    if not v then return nil end
    local x = v.x or v.X
    local y = v.y or v.Y
    local z = v.z or v.Z
    if x == nil then return nil end
    return x, y, z
end

local function normalize(dx, dy, dz)
    local mag = math_util.distance3(dx, dy, dz)
    if mag < 0.0001 then return 0, 0, 1 end
    return dx / mag, dy / mag, dz / mag
end

local function ray_point_dist_sq(ox, oy, oz, dx, dy, dz, px, py, pz)
    local vx, vy, vz = px - ox, py - oy, pz - oz
    local t = math_util.dot(vx, vy, vz, dx, dy, dz)
    if t < 0 then return math.huge, t end
    local qx = ox + dx * t - px
    local qy = oy + dy * t - py
    local qz = oz + dz * t - pz
    return qx * qx + qy * qy + qz * qz, t
end

local function part_world_pos(inst)
    if not inst or not env.is_valid(inst) then return nil end
    return vec3(inst.Position or inst.position)
end

local function find_child_part(char, name)
    if not char then return nil end
    return env.safe_call(function()
        return char:find_first_child(name) or char:FindFirstChild(name)
    end)
end

local function collect_hit_candidates(p)
    local out = {}
    local seen = {}

    local function add(name, x, y, z)
        if not x then return end
        local key = string.format("%.1f,%.1f,%.1f", x, y, z)
        if seen[key] then return end
        seen[key] = true
        table.insert(out, { name = name or "Body", x = x, y = y, z = z })
    end

    if p.head_position then
        add("Head", vec3(p.head_position))
    end
    if p.position then
        add("Torso", vec3(p.position))
    end

    local char = p.character
    if char and env.is_valid(char) then
        for _, bone in ipairs(AIM_BONES) do
            local part = find_child_part(char, bone)
            local x, y, z = part_world_pos(part)
            if x then add(bone, x, y, z) end
        end

        local children = env.safe_call(function() return char:get_children() end) or {}
        for _, child in ipairs(children) do
            if env.is_valid(child) then
                local is_part = env.safe_call(function()
                    return child:is_a("BasePart") or child.ClassName == "Part"
                        or child.ClassName == "MeshPart"
                end)
                if is_part then
                    local n = child.Name or child.name or "Part"
                    add(n, part_world_pos(child))
                end
            end
        end
    end

    return out
end

function M.resolve_impact_point(player)
    if not camera or not camera.get_position or not camera.get_look_vector then
        if player.head_position then
            local x, y, z = vec3(player.head_position)
            return x, y, z, "Head"
        end
        if player.position then
            local x, y, z = vec3(player.position)
            return x, y, z, "Body"
        end
        return nil
    end

    local cam = camera.get_position()
    local look = camera.get_look_vector()
    if not cam or not look then return nil end

    local ox, oy, oz = vec3(cam)
    local dx, dy, dz = normalize(vec3(look))
    if not ox then return nil end

    local best_dist = math.huge
    local best_x, best_y, best_z, best_name

    for _, c in ipairs(collect_hit_candidates(player)) do
        local dsq = ray_point_dist_sq(ox, oy, oz, dx, dy, dz, c.x, c.y, c.z)
        if dsq < best_dist then
            best_dist = dsq
            best_x, best_y, best_z, best_name = c.x, c.y, c.z, c.name
        end
    end

    if best_dist > 4 then
        if player.head_position then
            local x, y, z = vec3(player.head_position)
            if x then return x, y, z, "Head" end
        end
        return nil
    end

    return best_x, best_y, best_z, best_name
end

local function read_npc_health(npc)
    if not npc or not env.is_valid(npc.inst) then return nil end
    local hum = env.safe_call(function()
        if npc.inst.find_first_child_of_class then
            return npc.inst:find_first_child_of_class("Humanoid")
        end
        return nil
    end)
    if not hum then return nil end
    return hum.Health or hum.health
end

local function npc_impact_point(npc)
    if npc.head and env.is_valid(npc.head) then
        local x, y, z = part_world_pos(npc.head)
        if x then return x, y, z, "Head" end
    end
    local scan = April.require("game.esp_scan")
    local x, y, z = scan.label_position({ inst = npc.inst })
    if x then return x, y, z, npc.name or "NPC" end
    return nil
end

local function shooting_recently(now)
    if input and input.is_key_down and input.is_key_down(0x01) then return true end
    return (now - last_shoot_tick) < SHOOT_WINDOW_MS
end

local function shot_origin(now)
    if (now - fire_origin_tick) <= FIRE_ORIGIN_MS then
        return fire_origin.x, fire_origin.y, fire_origin.z
    end
    return tracer_origin()
end

local function tracer_origin()
    if camera and camera.get_position then
        local cam = camera.get_position()
        local x, y, z = vec3(cam)
        if x then return x, y, z end
    end
    local me = env.get_local_player()
    if me and me.head_position then
        return vec3(me.head_position)
    end
    return 0, 0, 0
end

local function player_id(p)
    return p.user_id or p.name or tostring(p)
end

local function get_mouse()
    if not utility or not utility.get_mouse_pos then return nil, nil end
    local ok, a, b = pcall(utility.get_mouse_pos)
    if not ok then return nil, nil end
    if type(a) == "table" then
        return a.x or a.X, a.y or a.Y
    end
    if type(a) == "number" then
        return a, b
    end
    return nil, nil
end

local function aim_fov_px()
    return settings.num("april_hit_aim_fov", settings.num("april_target_overlay_fov", DEFAULT_AIM_FOV))
end

local function max_hit_distance()
    return settings.num("april_hit_max_distance", DEFAULT_MAX_HIT_DIST)
end

function M.find_closest_player_to_mouse(fov_px)
    if not entity or not entity.get_players then return nil end

    fov_px = fov_px or aim_fov_px()
    local mx, my = get_mouse()
    if not mx then
        local sw, sh = draw_util.screen_size()
        mx, my = sw * 0.5, sh * 0.5
    end

    local best, best_screen = nil, fov_px

    for _, p in ipairs(entity.get_players()) do
        if p.is_local or not p.is_alive then goto continue end

        local pos = p.head_position or p.position
        if not pos then goto continue end

        local sx, sy, vis = esp_util.w2s(pos.x, pos.y, pos.z)
        if not vis then goto continue end

        local screen_dist = math_util.screen_fov_dist(sx, sy, mx, my)
        if screen_dist <= fov_px and screen_dist < best_screen then
            best_screen = screen_dist
            best = p
        end

        ::continue::
    end

    return best, best_screen
end

local function player_distance(p)
    local me = env.get_local_player()
    if not me or not me.position or not p.position then return 0 end
    local ax, ay, az = vec3(me.position)
    local bx, by, bz = vec3(p.position)
    if not ax or not bx then return 0 end
    return math_util.distance3(bx - ax, by - ay, bz - az)
end

local function is_plausible_player_hit(p, aim_player)
    if not p or not aim_player or p ~= aim_player then return false end

    local dist = player_distance(p)
    if dist <= 0 or dist > max_hit_distance() then return false end

    local hx, hy, hz, part = M.resolve_impact_point(p)
    if not hx then return false end

    return true, dist, hx, hy, hz, part
end

function M.sync_baselines()
    if entity and entity.get_players then
        for _, p in ipairs(entity.get_players()) do
            if not p.is_local and p.is_alive then
                local id = p.user_id or p.name or tostring(p)
                health_history[id] = p.health
            end
        end
    end
    for _, npc in ipairs(cache.npcs or {}) do
        local id = "npc:" .. (npc.name or "") .. ":" .. tostring(npc.inst)
        health_history[id] = read_npc_health(npc)
    end
end

function M.track(callback)
    local now = tick()
    local shooting = input and input.is_key_down and input.is_key_down(0x01)

    if shooting then
        last_shoot_tick = now
        if not was_shooting then
            M.sync_baselines()
            fire_origin.x, fire_origin.y, fire_origin.z = tracer_origin()
            fire_origin_tick = now
        end
    end
    was_shooting = shooting == true

    if not shooting_recently(now) then
        if now - last_idle_sync >= IDLE_SYNC_MS then
            last_idle_sync = now
            M.sync_baselines()
        end
        return
    end

    local ox, oy, oz = shot_origin(now)
    local aim_player = M.find_closest_player_to_mouse()
    local aim_id = aim_player and player_id(aim_player)

    if entity and entity.get_players then
        for _, p in ipairs(entity.get_players()) do
            if p.is_local or not p.is_alive then goto next_player end
            local id = player_id(p)
            local cur = p.health
            local last = health_history[id]
            if id == aim_id
                and type(last) == "number"
                and type(cur) == "number"
                and cur < last
                and cur >= 0
            then
                local ok, dist, hx, hy, hz, part = is_plausible_player_hit(p, aim_player)
                if ok and (now - (last_hit_at[id] or 0)) >= HIT_DEBOUNCE_MS then
                    last_hit_at[id] = now
                    callback({
                        target_id = id,
                        name = p.display_name or p.name or "Player",
                        damage = last - cur,
                        health = cur,
                        max_health = p.max_health,
                        distance = dist,
                        part = part or "Body",
                        is_player = true,
                        ox = ox, oy = oy, oz = oz,
                        hx = hx, hy = hy, hz = hz,
                        time = now,
                    })
                end
            end
            health_history[id] = cur
            ::next_player::
        end
    end

    for _, npc in ipairs(cache.npcs or {}) do
        local id = "npc:" .. (npc.name or "") .. ":" .. tostring(npc.inst)
        local cur = read_npc_health(npc)
        local last = health_history[id]
        if type(last) == "number" and type(cur) == "number" and cur < last and cur >= 0 then
            local damage = last - cur
            local hx, hy, hz, part = npc_impact_point(npc)
            if hx and (now - (last_hit_at[id] or 0)) >= HIT_DEBOUNCE_MS then
                last_hit_at[id] = now
                callback({
                    target_id = id,
                    name = npc.name or "NPC",
                    damage = damage,
                    health = cur,
                    distance = 0,
                    part = part or "Body",
                    is_player = false,
                    ox = ox, oy = oy, oz = oz,
                    hx = hx, hy = hy, hz = hz,
                    time = now,
                })
            end
        end
        health_history[id] = cur
    end
end

function M.enabled()
    return settings.enabled("april_bullet_tracer_enabled")
        or settings.enabled("april_hitmarker_enabled")
        or settings.enabled("april_hit_notify_enabled")
end

return M
