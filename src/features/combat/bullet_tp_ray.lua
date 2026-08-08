local combat_origin = April.require("game.combat_origin")
local manip_math = April.require("core.manip_math")

local M = {}

local GRID_STEP = 0.22
local HEAD_RADIUS = 0.55
local SCAN_CACHE_MS = 160
local SCAN_CACHE_LITE_MS = 280
local VISIBLE_BONUS = 2500
local PEEK_VISIBLE_BONUS = 1800
local MAX_HEAD_CACHE = 48

M.METHODS = {
    "Center",
    "Random Ring",
    "Random Sphere",
    "Offset Grid",
    "Camera Face",
    "Away From Cam",
    "Shuffle Valid",
    "Dense Shuffle",
    "Spam Cycle",
    "Target TP",
}

M.METHOD_SHUFFLE_VALID = 6
M.METHOD_DENSE_SHUFFLE = 7
M.METHOD_SPAM_CYCLE = 8
-- Bullet TP: scan head for best visible/near-visible point, spawn on target, aim through it.
M.METHOD_UNDER_TP = 9
M.METHOD_FEET_TP = M.METHOD_UNDER_TP

local BONE_SPAWN_Y = {
    Head = 0,
    UpperTorso = 0,
    LowerTorso = 0,
    HumanoidRootPart = 0,
    LeftUpperArm = 0,
    RightUpperArm = 0,
    LeftUpperLeg = 0,
    RightUpperLeg = 0,
}

local GRID_OFFS = {}
local SPAM_POOL = {}
local HEAD_SAMPLES = {}

local function push_off(list, x, y, z)
    list[#list + 1] = { x = x, y = y, z = z }
end

do
    for y = -0.66, 0.66, GRID_STEP do
        for x = -0.66, 0.66, GRID_STEP do
            for z = -0.66, 0.66, GRID_STEP do
                push_off(GRID_OFFS, x, y, z)
            end
        end
    end

    push_off(SPAM_POOL, 0, 0, 0)

    for _, off in ipairs(GRID_OFFS) do
        SPAM_POOL[#SPAM_POOL + 1] = off
    end

    for _, r in ipairs({ 0.04, 0.12, 0.22, 0.38, 0.55, 0.72, 0.95, 1.15 }) do
        for i = 0, 35 do
            local ang = (i / 36) * math.pi * 2
            push_off(SPAM_POOL, math.cos(ang) * r, math.sin(ang * 1.7) * r * 0.35, math.sin(ang) * r)
        end
    end

    for i = 0, 63 do
        local u = ((i * 17) % 100) / 100
        local v = ((i * 41) % 100) / 100
        local ang = u * math.pi * 2
        local r = 0.08 + v * 1.05
        push_off(SPAM_POOL, math.cos(ang) * r, (v - 0.5) * 0.8, math.sin(ang) * r)
    end

    push_off(HEAD_SAMPLES, 0, 0, 0)
    for _, y in ipairs({ -0.42, -0.22, -0.08, 0.08, 0.22, 0.42 }) do
        local slice = math.sqrt(math.max(0.01, HEAD_RADIUS * HEAD_RADIUS - y * y))
        for i = 0, 27 do
            local ang = (i / 28) * math.pi * 2
            push_off(HEAD_SAMPLES, math.cos(ang) * slice, y, math.sin(ang) * slice)
        end
    end
    for i = 0, 19 do
        local u = ((i * 11) % 100) / 100
        local v = ((i * 29) % 100) / 100
        local ang = u * math.pi * 2
        local pitch = (v - 0.5) * math.pi * 0.85
        local cr = math.cos(pitch)
        push_off(HEAD_SAMPLES, math.cos(ang) * cr * HEAD_RADIUS, math.sin(pitch) * HEAD_RADIUS, math.sin(ang) * cr * HEAD_RADIUS)
    end
end

local scan = { key = nil, idx = 0, spam_idx = 0 }
local head_scan_cache = {}

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function copy_pos(p)
    if not p then return nil end
    return { x = p.x, y = p.y, z = p.z }
end

local function unit(dx, dy, dz)
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    if len < 0.001 then return 0, 0, 0, 0 end
    local inv = 1 / len
    return dx * inv, dy * inv, dz * inv, len
end

local function add_off(base, off)
    return {
        x = base.x + (off.x or 0),
        y = base.y + (off.y or 0),
        z = base.z + (off.z or 0),
    }
end

function M.target_center(hitpart, bone)
    if not hitpart then return nil end
    local c = copy_pos(hitpart)
    local yoff = BONE_SPAWN_Y[bone or "Head"] or 0
    if yoff ~= 0 then
        c.y = c.y + yoff
    end
    return c
end

local function view_dir(camera_pos, focus)
    if _G.camera and _G.camera.get_look_vector then
        local ok, lv = pcall(_G.camera.get_look_vector)
        if ok and lv then
            local lx = lv.x or lv.X
            local ly = lv.y or lv.Y
            local lz = lv.z or lv.Z
            if lx then
                return unit(lx, ly or 0, lz or 0)
            end
        end
    end
    if focus and camera_pos then
        return unit(focus.x - camera_pos.x, focus.y - camera_pos.y, focus.z - camera_pos.z)
    end
    return 0, 0, 1, 1
end

local function toward_camera(origin, camera)
    if not camera then return 0, 0, 1, 1 end
    return unit(camera.x - origin.x, camera.y - origin.y, camera.z - origin.z)
end

local function aim_through(center, from, camera)
    local ux, uy, uz, len = unit(center.x - from.x, center.y - from.y, center.z - from.z)
    local extend = len < 0.35 and 0.55 or 0.08
    if len > 0.02 then
        return {
            x = center.x + ux * extend,
            y = center.y + uy * extend,
            z = center.z + uz * extend,
        }
    end
    local lx, ly, lz = toward_camera(center, camera)
    return {
        x = center.x + lx * extend,
        y = center.y + ly * extend,
        z = center.z + lz * extend,
    }
end

local function los_clear(from, to)
    if not from or not to then return false end
    if raycast and raycast.is_visible then
        return raycast.is_visible(from.x, from.y, from.z, to.x, to.y, to.z) == true
    end
    return true
end

local function scale_off(off, scale)
    if not off then return { x = 0, y = 0, z = 0 } end
    scale = tonumber(scale) or 1
    if scale < 1 then scale = 1 end
    if scale > 4 then scale = 4 end
    return {
        x = (off.x or 0) * scale,
        y = (off.y or 0) * scale,
        z = (off.z or 0) * scale,
    }
end

local function head_sample_points(center, camera, head_scale, step)
    local pts = {}
    head_scale = tonumber(head_scale) or 1
    if head_scale < 1 then head_scale = 1 end
    if head_scale > 4 then head_scale = 4 end
    step = math.max(1, math.floor(tonumber(step) or 1))

    for i = 1, #HEAD_SAMPLES, step do
        pts[#pts + 1] = add_off(center, scale_off(HEAD_SAMPLES[i], head_scale))
    end

    if camera then
        local lx, ly, lz = toward_camera(center, camera)
        for _, d in ipairs({ 0.12, 0.28, 0.45, 0.62 }) do
            local dd = d * head_scale
            pts[#pts + 1] = {
                x = center.x + lx * dd,
                y = center.y + ly * dd,
                z = center.z + lz * dd,
            }
        end
    end

    return pts
end

local function prune_head_cache(now)
    local n = 0
    for _ in pairs(head_scan_cache) do
        n = n + 1
    end
    if n <= MAX_HEAD_CACHE then return end
    local drop_before = now - (SCAN_CACHE_LITE_MS * 3)
    for k, ent in pairs(head_scan_cache) do
        if not ent or (now - (ent.t or 0)) > drop_before then
            head_scan_cache[k] = nil
        end
    end
end

local function score_head_point(from, view_x, view_y, view_z, point, ref_eye)
    if not from or not point then return -math.huge, false end

    local dx = point.x - from.x
    local dy = point.y - from.y
    local dz = point.z - from.z
    local ux, uy, uz, dist = unit(dx, dy, dz)
    if dist < 0.02 then
        return -math.huge, false
    end

    local align = ux * view_x + uy * view_y + uz * view_z
    local visible = manip_math.is_visible_from_pos(from, point)
    local score = align * 600 - dist * 0.05

    if visible then
        score = score + VISIBLE_BONUS
    end

    if ref_eye then
        local edx = point.x - ref_eye.x
        local edy = point.y - ref_eye.y
        local edz = point.z - ref_eye.z
        local eux, euy, euz, edist = unit(edx, edy, edz)
        if edist > 0.02 then
            local eye_align = eux * view_x + euy * view_y + euz * view_z
            score = score + eye_align * 120
            if manip_math.is_visible_from_pos(ref_eye, point) then
                score = score + VISIBLE_BONUS * 0.35
            end
        end
    end

    return score, visible
end

local function scan_cache_key(camera, center, body, head_scale)
    if not center then return nil end
    local bx, by, bz = 0, 0, 0
    if body then
        bx, by, bz = body.x or 0, body.y or 0, body.z or 0
    end
    local cx, cy, cz = camera and camera.x or 0, camera and camera.y or 0, camera and camera.z or 0
    local hs = math.floor(((tonumber(head_scale) or 1) * 10) + 0.5)
    return string.format(
        "%.1f,%.1f,%.1f>%.1f,%.1f,%.1f@%.1f,%.1f,%.1f#s%d",
        cx, cy, cz, center.x, center.y, center.z, bx, by, bz, hs
    )
end

local function find_best_head_aim(head_center, camera, body, opts)
    opts = opts or {}
    if not head_center or not camera then
        return copy_pos(head_center), false, 0, 0
    end

    local head_scale = tonumber(opts.head_scale) or 1
    if head_scale < 1 then head_scale = 1 end
    if head_scale > 4 then head_scale = 4 end
    local lite = opts.lite == true
    local seed = opts.seed

    local key = scan_cache_key(camera, head_center, body, head_scale)
    local now = tick_ms()
    local ttl = lite and SCAN_CACHE_LITE_MS or SCAN_CACHE_MS
    if key and head_scan_cache[key] then
        local ent = head_scan_cache[key]
        if ent.point and (now - (ent.t or 0)) < ttl then
            return copy_pos(ent.point), ent.visible == true, ent.score or 0, ent.progress or 1
        end
    end

    -- Lite path (not firing): reuse seed / center, skip dense ray storm.
    if lite then
        local point = copy_pos(seed) or copy_pos(head_center)
        local visible = manip_math.is_visible_from_pos(camera, point)
        if key then
            head_scan_cache[key] = {
                point = copy_pos(point),
                visible = visible,
                score = visible and VISIBLE_BONUS or 0,
                progress = 1,
                t = now,
            }
            prune_head_cache(now)
        end
        return point, visible, 0, 1
    end

    local view_x, view_y, view_z = view_dir(camera, head_center)
    -- LOD: denser samples near, skip every other far away.
    local dx = (head_center.x or 0) - (camera.x or 0)
    local dy = (head_center.y or 0) - (camera.y or 0)
    local dz = (head_center.z or 0) - (camera.z or 0)
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    local step = (dist > 180) and 3 or ((dist > 90) and 2 or 1)
    local samples = head_sample_points(head_center, camera, head_scale, step)
    if seed then
        samples[#samples + 1] = copy_pos(seed)
    end
    local total = #samples
    if total < 1 then
        return copy_pos(head_center), false, 0, 0
    end

    local best_point = copy_pos(seed) or copy_pos(head_center)
    local best_score = -math.huge
    local best_visible = false
    local checked = 0

    local peek_origins = {}
    peek_origins[#peek_origins + 1] = camera
    local cam_visible = manip_math.is_visible_from_pos(camera, head_center)
    -- Only pay for peek search when camera LOS is blocked.
    if body and not cam_visible then
        peek_origins[#peek_origins + 1] = body
        local peek = manip_math.search_peek_at_radius(body, head_center, 1, 22)
        if peek then
            peek_origins[#peek_origins + 1] = peek
        end
    elseif body then
        peek_origins[#peek_origins + 1] = body
    end

    for si, point in ipairs(samples) do
        checked = si
        local score = -math.huge
        local visible = false

        for _, origin in ipairs(peek_origins) do
            local s, vis = score_head_point(origin, view_x, view_y, view_z, point, camera)
            if origin ~= camera and vis then
                s = s + PEEK_VISIBLE_BONUS
            end
            if s > score then
                score = s
                visible = vis or visible
            end
        end

        if score > best_score then
            best_score = score
            best_point = copy_pos(point)
            best_visible = visible
        end
    end

    local progress = total > 0 and (checked / total) or 1
    if key then
        head_scan_cache[key] = {
            point = copy_pos(best_point),
            visible = best_visible,
            score = best_score,
            progress = progress,
            t = now,
        }
        prune_head_cache(now)
    end

    return best_point, best_visible, best_score, progress
end

local function next_spam_offset()
    if scan.spam_idx < 1 or scan.spam_idx > #SPAM_POOL then
        scan.spam_idx = 1
    end
    local off = SPAM_POOL[scan.spam_idx]
    scan.spam_idx = scan.spam_idx + 1
    if scan.spam_idx > #SPAM_POOL then
        scan.spam_idx = 1
    end
    return off
end

local function scan_key(center, method_idx)
    return string.format("%d|%.2f,%.2f,%.2f", method_idx, center.x, center.y, center.z)
end

local function next_grid_offset(center, method_idx)
    local key = scan_key(center, method_idx)
    if scan.key ~= key then
        scan.key = key
        scan.idx = 1
    end
    local off = GRID_OFFS[scan.idx] or GRID_OFFS[1]
    scan.idx = scan.idx + 1
    if scan.idx > #GRID_OFFS then scan.idx = 1 end
    return off
end

local function rand_unit()
    local u = math.random() * 2 - 1
    local v = math.random() * 2 - 1
    local s = u * u + v * v
    while s >= 1 or s < 0.0001 do
        u = math.random() * 2 - 1
        v = math.random() * 2 - 1
        s = u * u + v * v
    end
    local w = math.sqrt((1 - s) / s)
    return u * w, v * w, math.sqrt(1 - s)
end

local function origin_center(center, _camera)
    return copy_pos(center)
end

local function origin_random_ring(center, _camera)
    local ang = math.random() * math.pi * 2
    local r = 0.18 + math.random() * 0.55
    return {
        x = center.x + math.cos(ang) * r,
        y = center.y + (math.random() - 0.5) * 0.35,
        z = center.z + math.sin(ang) * r,
    }
end

local function origin_random_sphere(center, _camera)
    local ux, uy, uz = rand_unit()
    local r = 0.12 + math.random() * 0.65
    return {
        x = center.x + ux * r,
        y = center.y + uy * r,
        z = center.z + uz * r,
    }
end

local function origin_offset_grid(center, camera, method_idx)
    return add_off(center, next_grid_offset(center, method_idx))
end

local function origin_camera_face(center, camera)
    local lx, ly, lz = toward_camera(center, camera)
    local d = 0.22 + math.random() * 0.75
    return {
        x = center.x + lx * d,
        y = center.y + ly * d,
        z = center.z + lz * d,
    }
end

local function origin_away_from_cam(center, camera)
    local lx, ly, lz = toward_camera(center, camera)
    local d = 0.22 + math.random() * 0.75
    return {
        x = center.x - lx * d,
        y = center.y - ly * d + (math.random() - 0.5) * 0.25,
        z = center.z - lz * d,
    }
end

local function origin_shuffle_valid(center, camera, tries)
    tries = tries or 14
    local best = copy_pos(center)
    for _ = 1, tries do
        local cand = origin_random_sphere(center, camera)
        if los_clear(cand, center) then
            return cand
        end
    end
    return best
end

local function aim_spam_cycle(center, camera, head_scale)
    head_scale = tonumber(head_scale) or 1
    if head_scale < 1 then head_scale = 1 end
    if head_scale > 4 then head_scale = 4 end
    local cycle = scan.spam_idx
    local off = scale_off(next_spam_offset(), head_scale)
    local origin = add_off(center, off)

    if cycle % 4 == 0 and camera then
        local lx, ly, lz = toward_camera(center, camera)
        local depth = (0.15 + ((cycle * 13) % 80) / 100) * head_scale
        origin = {
            x = center.x - lx * depth + (off.x or 0) * 0.35,
            y = center.y - ly * depth + (off.y or 0) * 0.35,
            z = center.z - lz * depth + (off.z or 0) * 0.35,
        }
    end

    return origin
end

local function origin_spam_cycle(center, camera, _method_idx)
    return aim_spam_cycle(center, camera, 1)
end

local function origin_under_tp(_center, _camera, _method_idx)
    return nil
end

local ORIGIN_FN = {
    origin_center,
    origin_random_ring,
    origin_random_sphere,
    origin_offset_grid,
    origin_camera_face,
    origin_away_from_cam,
    origin_shuffle_valid,
    function(c, cam) return origin_shuffle_valid(c, cam, 28) end,
    origin_spam_cycle,
    origin_under_tp,
}

local function resolve_target_tp(spawn, hitpart, camera, muzzle, body, opts)
    opts = opts or {}
    local head_scale = tonumber(opts.head_scale) or 1
    local best_aim, scan_visible, _score, scan_progress = find_best_head_aim(spawn, camera, body, {
        head_scale = head_scale,
        lite = opts.lite == true,
        seed = opts.seed,
    })
    local aim_point = copy_pos(best_aim) or copy_pos(hitpart)
    -- Origins cycle around head center (scaled with Hitbox Override); aim through scanned best point.
    local origin = aim_spam_cycle(spawn, camera, head_scale)
    local aim = aim_through(aim_point, origin, camera)

    return {
        origin = origin,
        aim = aim,
        hitpart = copy_pos(aim_point),
        method = "Target TP",
        tp_path = M.build_path(origin, aim_point, muzzle),
        tp_scan_visible = scan_visible,
        tp_scan_progress = scan_progress,
        head_scale = head_scale,
    }
end

function M.hitpart_aim(hit, bone)
    return M.target_center(hit, bone)
end

function M.resolve(opts)
    opts = opts or {}
    local camera = opts.camera or combat_origin.get_camera_origin()
    local hitpart = opts.hitpart
    if not hitpart or not camera then return nil end

    local method_idx = math.floor(tonumber(opts.method) or M.METHOD_UNDER_TP)
    if method_idx < 0 then method_idx = 0 end
    if method_idx >= #M.METHODS then method_idx = M.METHOD_UNDER_TP end

    local spawn = M.target_center(hitpart, opts.bone) or copy_pos(hitpart)
    if not spawn then return nil end

    local muzzle = opts.muzzle or combat_origin.get_muzzle_origin() or camera
    local body = opts.body

    if method_idx == M.METHOD_UNDER_TP then
        return resolve_target_tp(spawn, hitpart, camera, muzzle, body, opts)
    end

    local pick = ORIGIN_FN[method_idx + 1] or origin_spam_cycle
    local origin = pick(spawn, camera, method_idx)
    if not origin then return nil end

    local aim_point
    local head_scale = tonumber(opts.head_scale) or 1
    if method_idx == M.METHOD_SPAM_CYCLE then
        origin = aim_spam_cycle(spawn, camera, head_scale)
        aim_point = copy_pos(hitpart)
    else
        aim_point = copy_pos(hitpart)
    end

    local aim = aim_through(aim_point, origin, camera)

    return {
        origin = origin,
        aim = aim,
        hitpart = copy_pos(hitpart),
        method = M.METHODS[method_idx + 1],
        tp_path = M.build_path(origin, aim_point, muzzle),
    }
end

function M.build_under_path(origin, aim, muzzle, surface_y)
    local out = {}
    if muzzle then out[#out + 1] = copy_pos(muzzle) end
    if surface_y and origin then
        out[#out + 1] = { x = origin.x, y = surface_y, z = origin.z }
    end
    if origin then out[#out + 1] = copy_pos(origin) end
    if aim then out[#out + 1] = copy_pos(aim) end
    return out
end

function M.build_path(tp_origin, center, muzzle)
    if not tp_origin or not center then return {} end
    local out = {}
    if muzzle then out[#out + 1] = copy_pos(muzzle) end
    out[#out + 1] = copy_pos(tp_origin)
    out[#out + 1] = copy_pos(center)
    return out
end

function M.clear_scan_cache()
    head_scan_cache = {}
end

return M
