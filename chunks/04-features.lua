April._mods["ui.combat_labels"] = (function()
local M = {}
M.SILENT_BONES = {
    "Head",
    "Torso",
    "Left Arm",
    "Right Arm",
    "Left Leg",
    "Right Leg",
    "Closest",
}
M.AIM_AT_OPTIONS = {
    "Players",
    "Soldier",
    "Bruno",
    "Boris",
    "Brutus",
    "Attack Heli",
    "BTR",
    "Diver Dave",
    "Pilot Pete",
}
M.AIM_AT_DEFAULTS = { true, false, false, false, false, false, false, false, false }
return M
end)()

April._mods["features.combat.silent_whitelist"] = (function()
local settings = April.require("core.settings")
local notify = April.require("core.notify")
local ep = April.require("core.entity_props")
local M = {}
local FILTER_WHITELIST_IDX = 5
local MMB = 0x04
local DEFAULT_PREFIX = "april_silent_"
local was_down = {}
local cache = {}
local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end
local function norm_prefix(prefix)
    return prefix or DEFAULT_PREFIX
end
local function ids_key(prefix)
    return norm_prefix(prefix) .. "whitelist_ids"
end
local function filters_key(prefix)
    return norm_prefix(prefix) .. "filters"
end
local function parse_ids(raw)
    local set = {}
    if type(raw) ~= "string" or raw == "" then return set end
    for part in raw:gmatch("[^,]+") do
        local id = tonumber((part:match("^%s*(.-)%s*$")))
        if id and id > 0 then
            set[id] = true
        end
    end
    return set
end
local function serialize_ids(set)
    local list = {}
    for id in pairs(set) do
        list[#list + 1] = id
    end
    table.sort(list)
    local parts = {}
    for i = 1, #list do
        parts[i] = tostring(list[i])
    end
    return table.concat(parts, ",")
end
local function read_set(prefix)
    local p = norm_prefix(prefix)
    local now = tick_ms()
    local c = cache[p]
    if c and c.t == now then return c.set end
    local raw = ""
    local key = ids_key(p)
    if menu and menu.get then
        local ok, v = pcall(menu.get, key)
        if ok and type(v) == "string" then raw = v end
    end
    if raw == "" then
        raw = tostring(settings.get(key) or "")
    end
    local set = parse_ids(raw)
    cache[p] = { t = now, set = set }
    return set
end
local function write_set(prefix, set)
    local p = norm_prefix(prefix)
    cache[p] = { t = tick_ms(), set = set }
    local s = serialize_ids(set)
    local key = ids_key(p)
    if menu and menu.set then
        pcall(menu.set, key, s)
    end
end
function M.count(prefix)
    local n = 0
    for _ in pairs(read_set(prefix)) do
        n = n + 1
    end
    return n
end
function M.is_whitelisted(player, prefix)
    if not player then return false end
    local uid = ep.user_id(player)
    if not uid or uid == 0 then return false end
    return read_set(prefix)[uid] == true
end
function M.toggle_player(player, prefix)
    if not player or player.is_local then return false, nil end
    local uid = ep.user_id(player)
    if not uid or uid == 0 then return false, nil end
    local set = read_set(prefix)
    local name = player.display_name or player.name or tostring(uid)
    local added
    if set[uid] then
        set[uid] = nil
        added = false
        notify.warning("WL - " .. name, 2500)
    else
        set[uid] = true
        added = true
        notify.success("WL + " .. name, 2500)
    end
    write_set(prefix, set)
    return true, added
end
function M.clear(prefix)
    write_set(prefix, {})
    notify.warning("Whitelist cleared", 2000)
end
function M.enabled(prefix)
    return settings.multi(filters_key(prefix), FILTER_WHITELIST_IDX, false)
end
function M.should_skip(player, prefix)
    if not M.enabled(prefix) then return false end
    return M.is_whitelisted(player, prefix)
end
function M.tick(current_target, prefix)
    prefix = norm_prefix(prefix)
    if not M.enabled(prefix) then
        was_down[prefix] = false
        return
    end
    local down = input and input.is_key_down and input.is_key_down(MMB) == true
    local pressed = down and not was_down[prefix]
    was_down[prefix] = down
    if not pressed then return end
    if not current_target then return end
    if current_target.is_npc or current_target._npc then return end
    M.toggle_player(current_target, prefix)
end
return M
end)()

April._mods["features.combat.bullet_tp_ray"] = (function()
local combat_origin = April.require("game.combat_origin")
local manip_math = April.require("core.manip_math")
local M = {}
local GRID_STEP = 0.22
local HEAD_RADIUS = 0.55
local SCAN_CACHE_MS = 160
local VISIBLE_BONUS = 2500
local PEEK_VISIBLE_BONUS = 1800
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
local function head_sample_points(center, camera)
    local pts = {}
    for _, off in ipairs(HEAD_SAMPLES) do
        pts[#pts + 1] = add_off(center, off)
    end
    if camera then
        local lx, ly, lz = toward_camera(center, camera)
        for _, d in ipairs({ 0.12, 0.28, 0.45, 0.62 }) do
            pts[#pts + 1] = {
                x = center.x + lx * d,
                y = center.y + ly * d,
                z = center.z + lz * d,
            }
        end
    end
    return pts
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
local function scan_cache_key(camera, center, body)
    if not center then return nil end
    local bx, by, bz = 0, 0, 0
    if body then
        bx, by, bz = body.x or 0, body.y or 0, body.z or 0
    end
    local cx, cy, cz = camera and camera.x or 0, camera and camera.y or 0, camera and camera.z or 0
    return string.format(
        "%.1f,%.1f,%.1f>%.1f,%.1f,%.1f@%.1f,%.1f,%.1f",
        cx, cy, cz, center.x, center.y, center.z, bx, by, bz
    )
end
local function find_best_head_aim(head_center, camera, body)
    if not head_center or not camera then
        return copy_pos(head_center), false, 0, 0
    end
    local key = scan_cache_key(camera, head_center, body)
    local now = tick_ms()
    if key and head_scan_cache[key] then
        local ent = head_scan_cache[key]
        if ent.point and (now - (ent.t or 0)) < SCAN_CACHE_MS then
            return copy_pos(ent.point), ent.visible == true, ent.score or 0, ent.progress or 1
        end
    end
    local view_x, view_y, view_z = view_dir(camera, head_center)
    local samples = head_sample_points(head_center, camera)
    local total = #samples
    if total < 1 then
        return copy_pos(head_center), false, 0, 0
    end
    local best_point = copy_pos(head_center)
    local best_score = -math.huge
    local best_visible = false
    local checked = 0
    local peek_origins = {}
    if body then
        peek_origins[#peek_origins + 1] = body
        local peek = manip_math.search_peek_at_radius(body, head_center, 1, 22)
        if peek then
            peek_origins[#peek_origins + 1] = peek
        end
    end
    peek_origins[#peek_origins + 1] = camera
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
local function aim_spam_cycle(center, camera)
    local cycle = scan.spam_idx
    local off = next_spam_offset()
    local origin = add_off(center, off)
    if cycle % 4 == 0 and camera then
        local lx, ly, lz = toward_camera(center, camera)
        local depth = 0.15 + ((cycle * 13) % 80) / 100
        origin = {
            x = center.x - lx * depth + (off.x or 0) * 0.35,
            y = center.y - ly * depth + (off.y or 0) * 0.35,
            z = center.z - lz * depth + (off.z or 0) * 0.35,
        }
    end
    return origin
end
local function origin_spam_cycle(center, camera, _method_idx)
    return aim_spam_cycle(center, camera)
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
local function resolve_target_tp(spawn, hitpart, camera, muzzle, body)
    local best_aim, scan_visible, _score, scan_progress = find_best_head_aim(spawn, camera, body)
    local aim_point = copy_pos(best_aim) or copy_pos(hitpart)
    local origin = aim_spam_cycle(spawn, camera)
    local aim = aim_through(aim_point, origin, camera)
    return {
        origin = origin,
        aim = aim,
        hitpart = copy_pos(aim_point),
        method = "Target TP",
        tp_path = M.build_path(origin, aim_point, muzzle),
        tp_scan_visible = scan_visible,
        tp_scan_progress = scan_progress,
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
        return resolve_target_tp(spawn, hitpart, camera, muzzle, body)
    end
    local pick = ORIGIN_FN[method_idx + 1] or origin_spam_cycle
    local origin = pick(spawn, camera, method_idx)
    if not origin then return nil end
    local aim_point
    if method_idx == M.METHOD_SPAM_CYCLE then
        origin = aim_spam_cycle(spawn, camera)
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
end)()

April._mods["features.combat.combat_menu"] = (function()
local menu_util = April.require("core.menu_util")
local settings = April.require("core.settings")
local combat_labels = April.require("ui.combat_labels")
local M = {}
M.SILENT_BONES = {
    "Head",
    "Torso",
    "Left Arm",
    "Right Arm",
    "Left Leg",
    "Right Leg",
    "Closest",
}
M.BONE_MAP = {
    ["Head"] = "Head",
    ["Torso"] = "UpperTorso",
    ["Left Arm"] = "LeftUpperArm",
    ["Right Arm"] = "RightUpperArm",
    ["Left Leg"] = "LeftUpperLeg",
    ["Right Leg"] = "RightUpperLeg",
    ["Closest"] = "Closest",
}
M.FILTER_HEALTH = 1
M.FILTER_VISIBLE = 2
M.FILTER_TEAM = 3
M.FILTER_SAFEZONE = 4
M.FILTER_WHITELIST = 5
M.FILTER_SKIP_DOWNED = 6
M.TARGET_PLAYERS = 1
M.AIM_AT_OPTIONS = combat_labels.AIM_AT_OPTIONS
M.AIM_AT_DEFAULTS = combat_labels.AIM_AT_DEFAULTS
M.AIM_AT_KIND_INDEX = {
    soldier = 2,
    bruno = 3,
    boris = 4,
    brutus = 5,
    heli = 6,
    btr = 7,
    diver_dave = 8,
    pilot_pete = 9,
}
M.OPT_STICKY = 1
function M.bone_from_index(idx)
    local label = M.SILENT_BONES[(idx or 0) + 1] or "Head"
    return M.BONE_MAP[label] or label
end
function M.downed_mode_from_filters(prefix)
    local filters = (prefix or "april_silent_") .. "filters"
    if settings.multi(filters, M.FILTER_SKIP_DOWNED, true) then
        return 0
    end
    return 1
end
local function targets_table_len(t)
    if type(t) ~= "table" then return 0 end
    local max_i = 0
    for k in pairs(t) do
        local n = tonumber(k)
        if n and n > max_i then max_i = n end
    end
    return max_i
end
function M.expand_legacy_targets(prefix)
    local id = (prefix or "april_silent_") .. "targets"
    local t = settings.get(id)
    if targets_table_len(t) > 2 then return end
    local players = settings.multi(id, 1, true)
    local npcs = settings.multi(id, 2, false)
    local expanded = { players }
    for i = 2, #M.AIM_AT_OPTIONS do
        expanded[i] = npcs
    end
    if menu and menu.set then
        pcall(menu.set, id, expanded)
    end
    pcall(function()
        April.require("ui.gs_state").set(id, expanded)
    end)
end
function M.players_enabled(prefix)
    M.expand_legacy_targets(prefix)
    return settings.multi((prefix or "april_silent_") .. "targets", M.TARGET_PLAYERS, true)
end
function M.npc_kind_enabled(kind, prefix)
    if not kind then return false end
    M.expand_legacy_targets(prefix)
    local idx = M.AIM_AT_KIND_INDEX[kind]
    if not idx then return false end
    return settings.multi((prefix or "april_silent_") .. "targets", idx, false)
end
function M.any_npc_enabled(prefix)
    M.expand_legacy_targets(prefix)
    for _, idx in pairs(M.AIM_AT_KIND_INDEX) do
        if settings.multi((prefix or "april_silent_") .. "targets", idx, false) then
            return true
        end
    end
    return false
end
function M.register_silent_aim(T, G, prefix, parent_id, opts)
    opts = opts or {}
    local p = prefix
    M.expand_legacy_targets(p)
    menu_util.section(T, G, "Targeting")
    menu.add_combo(T, G, p .. "target_type", "Target Type", { "Crosshair", "Distance" }, 0,
        { parent = parent_id })
    menu.add_combo(T, G, p .. "bone", "Hitbox", M.SILENT_BONES, 0, { parent = parent_id })
    menu.add_multicombo(T, G, p .. "targets", "Aim At", M.AIM_AT_OPTIONS, M.AIM_AT_DEFAULTS,
        { parent = parent_id })
    if menu and menu.set and targets_table_len(settings.get(p .. "targets")) <= 2 then
        pcall(menu.set, p .. "targets", {
            true, false, false, false, false, false, false, false, false,
        })
    end
    menu.add_multicombo(T, G, p .. "filters", "Filters", {
        "Health Check",
        "Visible Only",
        "Team Check",
        "Skip Safezone",
        "Whitelist",
        "Skip Downed",
    }, { false, false, false, false, false, false }, { parent = parent_id })
    if menu and menu.set then
        pcall(menu.set, p .. "filters", { true, false, true, true, false, true })
    end
    menu.add_input(T, G, p .. "whitelist_ids", "Whitelist IDs", "")
    menu.add_button(T, G, p .. "whitelist_clear", "Clear Whitelist", function()
        local wl = April.require("features.combat.silent_whitelist")
        if wl and wl.clear then wl.clear(p) end
    end)
    menu.add_slider_int(T, G, p .. "max_dist", "Max Distance (m)", 50, 2000, 500, { parent = parent_id })
    menu_util.section(T, G, "Aim")
    menu.add_multicombo(T, G, p .. "options", "Options", {
        "Sticky Target",
    }, { false }, { parent = parent_id })
    menu.add_slider_int(T, G, p .. "hit_chance", "Hit Chance %", 1, 100, 100, { parent = parent_id })
    menu.add_slider_int(T, G, p .. "fov", "FOV Radius (px)", 5, 600, opts.fov_default or 150, { parent = parent_id })
    menu_util.section(T, G, "Visuals")
    menu.add_checkbox(T, G, p .. "draw_fov", "FOV Circle", false,
        menu_util.parent(parent_id, { colorpicker = opts.fov_color or { 0.55, 0.2, 1, 1 } }))
    menu.add_combo(T, G, p .. "fov_style", "FOV Style", { "Outline", "Filled Circle" }, 1,
        menu_util.parent(p .. "draw_fov"))
    menu.add_checkbox(T, G, p .. "target_line", "Target Line", false,
        menu_util.parent(parent_id, { colorpicker = opts.line_color or { 1, 0.25, 0.25, 1 } }))
end
function M.register_bullet(T, G, prefix, parent_id)
    local p = prefix
    menu.add_checkbox(T, G, p .. "hitscan", "Hitscan", false, { parent = parent_id })
    menu.add_checkbox(T, G, p .. "bullet_tp", "Bullet TP", false, { parent = parent_id })
    local manip_root = menu_util.parent(p .. "bullet_manip")
    menu.add_checkbox(T, G, p .. "bullet_manip", "Silent Bullet Manip", false, { parent = parent_id })
    menu.add_slider_float(T, G, p .. "manip_dist", "Manip Distance", 0.1, 1, 1, "%.2f", manip_root)
    menu.add_checkbox(T, G, p .. "manip_extend", "Extend", false, manip_root)
    menu.add_slider_float(T, G, p .. "manip_extend_dist", "Extend Distance", 1, 7, 7, "%.1f",
        menu_util.parent(p .. "manip_extend"))
    menu.add_checkbox(T, G, "april_bullet_body_peek", "Body Peek (desync)", false, manip_root)
    local vis_root = menu_util.parent(parent_id)
    menu.add_checkbox(T, G, p .. "manip_status", "Status HUD", false, vis_root)
    menu.add_checkbox(T, G, p .. "manip_peek_vis", "Peek Visual", false, vis_root)
end
function M.register_aimbot(T, G, prefix, parent_id, opts)
    opts = opts or {}
    local p = prefix
    M.expand_legacy_targets(p)
    menu_util.section(T, G, "Targeting")
    menu.add_combo(T, G, p .. "target_type", "Target Type", { "Crosshair", "Distance" }, 0,
        { parent = parent_id })
    menu.add_combo(T, G, p .. "bone", "Hitbox", M.SILENT_BONES, 0, { parent = parent_id })
    menu.add_multicombo(T, G, p .. "targets", "Aim At", M.AIM_AT_OPTIONS, M.AIM_AT_DEFAULTS,
        { parent = parent_id })
    if menu and menu.set and targets_table_len(settings.get(p .. "targets")) <= 2 then
        pcall(menu.set, p .. "targets", {
            true, false, false, false, false, false, false, false, false,
        })
    end
    menu.add_multicombo(T, G, p .. "filters", "Filters", {
        "Health Check",
        "Visible Only",
        "Team Check",
        "Skip Safezone",
        "Whitelist",
        "Skip Downed",
    }, { false, false, false, false, false, false }, { parent = parent_id })
    if menu and menu.set then
        pcall(menu.set, p .. "filters", { true, false, true, true, false, true })
    end
    menu.add_input(T, G, p .. "whitelist_ids", "Whitelist IDs", "")
    menu.add_button(T, G, p .. "whitelist_clear", "Clear Whitelist", function()
        local wl = April.require("features.combat.silent_whitelist")
        if wl and wl.clear then wl.clear(p) end
    end)
    menu.add_slider_int(T, G, p .. "max_dist", "Max Distance (m)", 50, 2000, 500, { parent = parent_id })
    menu_util.section(T, G, "Aim")
    menu.add_multicombo(T, G, p .. "options", "Options", {
        "Sticky Target",
    }, { false }, { parent = parent_id })
    menu.add_slider_int(T, G, p .. "smooth", "Smoothness", 1, 25, 10, { parent = parent_id })
    menu.add_combo(T, G, p .. "smooth_type", "Smooth Type", {
        "Linear",
        "Ease Out",
        "Ease In-Out",
        "Exponential",
        "Adaptive",
    }, 0, { parent = parent_id })
    menu.add_checkbox(T, G, p .. "humanize", "Humanize", false, { parent = parent_id })
    menu.add_slider_int(T, G, p .. "humanize_str", "Humanize Strength", 1, 100, 35,
        menu_util.parent(p .. "humanize"))
    menu.add_slider_int(T, G, p .. "fov", "FOV Radius (px)", 5, 600, opts.fov_default or 120, { parent = parent_id })
    menu_util.section(T, G, "Visuals")
    menu.add_checkbox(T, G, p .. "draw_fov", "FOV Circle", false,
        menu_util.parent(parent_id, { colorpicker = opts.fov_color or { 0.2, 1, 0.45, 1 } }))
    menu.add_combo(T, G, p .. "fov_style", "FOV Style", { "Outline", "Filled Circle" }, 1,
        menu_util.parent(p .. "draw_fov"))
    menu.add_checkbox(T, G, p .. "target_line", "Target Line", false,
        menu_util.parent(parent_id, { colorpicker = opts.line_color or { 0.2, 1, 0.45, 1 } }))
end
return M
end)()

April._mods["features.combat.targeting"] = (function()
local settings = April.require("core.settings")
local weapons = April.require("game.weapons")
local ballistic = April.require("core.ballistic")
local combat_origin = April.require("game.combat_origin")
local combat_menu = April.require("features.combat.combat_menu")
local math_util = April.require("core.math_util")
local esp_util = April.require("core.esp_util")
local ep = April.require("core.entity_props")
local player_state = April.require("game.player_state")
local npcs = April.require("game.npcs")
local silent_whitelist = April.require("features.combat.silent_whitelist")
local cache = April.require("core.cache")
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
    if not entry then return false end
    local kind = entry.kind or npcs.kind(entry.name or entry.raw_name)
    return combat_menu.npc_kind_enabled(kind, prefix)
end
local function same_npc_inst(a, b)
    if not a or not b then return false end
    if a == b then return true end
    local aa = a.Address or a.address
    local ba = b.Address or b.address
    return aa ~= nil and aa == ba
end
function M.is_npc_alive(entry)
    if not entry then return false end
    if entry.entity then
        if entry.entity.IsAlive == false or entry.entity.is_alive == false then return false end
        local hp = tonumber(entry.entity.Health or entry.entity.health)
        return hp == nil or hp > 0
    end
    if not entry.inst or not env.is_valid(entry.inst) then return false end
    local health = April.require("game.npcs").read_health(entry.inst, entry.humanoid)
    return health ~= nil
end
function M.is_aim_target(target)
    if M.is_npc_target(target) then
        return M.is_npc_alive(target)
    end
    return player_state.is_combat_target(target)
end
local function npc_aim_world(entry, cx, cy)
    if not entry then
        return nil
    end
    local kind = entry.kind or npcs.kind(entry.name or entry.raw_name)
    if kind == "heli" then
        local heli = npcs.heli_aim_world(entry, true, cx, cy)
        if heli then
            entry.lx, entry.ly, entry.lz = heli.x, heli.y, heli.z
            return heli
        end
    end
    if entry.entity then
        local x, y, z = esp_util.vec3_pos(
            entry.entity.HeadPosition or entry.entity.head_position
                or entry.entity.Position or entry.entity.position
        )
        if x then
            entry.lx, entry.ly, entry.lz = x, y, z
            return { x = x, y = y, z = z }
        end
    end
    local head = entry.head
    if (not head or not env.is_valid(head)) and entry.inst and env.is_valid(entry.inst) then
        head = env.safe_call(function()
            return entry.inst:find_first_child("Head") or entry.inst:FindFirstChild("Head")
        end)
        if head then
            entry.head = head
        end
    end
    if head and env.is_valid(head) then
        local pos = head.Position or head.position
        if pos and pos.x then
            entry.lx, entry.ly, entry.lz = pos.x, pos.y, pos.z
            return { x = pos.x, y = pos.y, z = pos.z }
        end
    end
    if entry.root and env.is_valid(entry.root) then
        local x, y, z = esp_util.vec3_pos(entry.root.Position or entry.root.position)
        if x then
            entry.lx, entry.ly, entry.lz = x, y, z
            return { x = x, y = y, z = z }
        end
    end
    if entry.lx then
        return { x = entry.lx, y = entry.ly, z = entry.lz }
    end
    return nil
end
local function npc_head_world(entry)
    return npc_aim_world(entry, nil, nil)
end
function M.refresh_npc_target(target)
    if not M.is_npc_target(target) or (not target.entity and not target.inst) then
        return nil
    end
    if not target.entity and not env.is_valid(target.inst) then
        return nil
    end
    local found = nil
    if cache.npcs then
        for _, entry in ipairs(cache.npcs) do
            if (target.entity and entry.entity == target.entity)
                or (entry.inst and target.inst and same_npc_inst(entry.inst, target.inst)) then
                found = entry
                break
            end
        end
    end
    if found then
        target.entity = found.entity
        target.inst = found.inst
        target.head = found.head
        target.root = found.root or found.anchor
        target.name = found.name or target.name
        target.kind = found.kind or target.kind
        target.lx = found.lx
        target.ly = found.ly
        target.lz = found.lz
    end
    if not M.is_npc_alive(target) then
        return nil
    end
    if not npc_aim_world(target, nil, nil) then
        return nil
    end
    return target
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
local WOODEN_BOW_AIM_Y_NUDGE = -0.22
local function is_wooden_bow(weapon_name)
    if not weapon_name then return false end
    local n = weapon_name:lower()
    return n:find("wooden bow", 1, true) ~= nil
end
function M.uses_bow_torso_aim(prefix)
    return type(prefix) == "string" and prefix:sub(1, 10) == "april_aim_"
end
function M.effective_aim_bone(bone, weapon_name)
    bone = bone or "Head"
    if bone == "Head" and weapons.is_bow_weapon_name(weapon_name) then
        return "UpperTorso"
    end
    return bone
end
function M.bow_aim_nudge(point, weapon_name)
    if not point or not is_wooden_bow(weapon_name) then
        return point
    end
    return {
        x = point.x,
        y = point.y + WOODEN_BOW_AIM_Y_NUDGE,
        z = point.z,
    }
end
function M.target_priority_crosshair(prefix)
    local idx = settings.num(prefix .. "target_type", 0)
    return idx == 0
end
function M.passes_filters(target, prefix, aim, origin, opts)
    if not target then return false end
    opts = opts or {}
    if M.is_npc_target(target) then
        if settings.multi(prefix .. "filters", 1, true) and not M.is_npc_alive(target) then
            return false
        end
        if settings.multi(prefix .. "filters", 2, false) and not passes_visibility(target, aim, origin) then
            return false
        end
        return true
    end
    if not opts.ignore_whitelist and silent_whitelist.should_skip(target, prefix) then
        return false
    end
    if settings.multi(prefix .. "filters", 1, true) then
        if not player_state.passes_health_check(target) then return false end
    end
    if not player_state.passes_downed_check(target, combat_menu.downed_mode_from_filters(prefix)) then
        return false
    end
    if settings.multi(prefix .. "filters", 3, true) then
        if not player_state.passes_team_check(target) then return false end
    end
    if settings.multi(prefix .. "filters", 4, true) then
        if not player_state.passes_safezone_check(target, true) then return false end
    end
    if not opts.ignore_visible and settings.multi(prefix .. "filters", 2, false) then
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
    local dist = ep.distance_to(target, origin)
    if not dist and origin then
        local pos = ep.position(target)
        if pos then
            local px, py, pz = esp_util.vec3_pos(pos)
            if px then
                dist = math_util.distance3(px - origin.x, py - origin.y, pz - origin.z)
            end
        end
    end
    return dist == nil or dist <= max_d
end
function M.bone_world(target, bone, cx, cy)
    if not target then return nil end
    if M.is_npc_target(target) then
        if not M.refresh_npc_target(target) then
            return nil
        end
        return npc_aim_world(target, cx, cy)
    end
    if ep.is_alive(target) == false then return nil end
    if bone == "Closest" then return nil end
    local head_pos = ep.head_position(target)
    if bone == "Head" and head_pos then
        local x, y, z = esp_util.vec3_pos(head_pos)
        if x then return { x = x, y = y, z = z } end
    end
    local char = ep.character(target)
    if char then
        local part = env.safe_call(function()
            return char:find_first_child(bone) or char:FindFirstChild(bone)
        end)
        if part and env.is_valid(part) then
            local x, y, z = esp_util.vec3_pos(part.Position or part.position)
            if x then return { x = x, y = y, z = z } end
        end
    end
    local root_pos = ep.position(target)
    if root_pos then
        if bone == "Head" then
            return nil
        end
        local x, y, z = esp_util.vec3_pos(root_pos)
        if x then return { x = x, y = y, z = z } end
    end
    return nil
end
function M.closest_bone_world(target, cx, cy)
    cx = cx or 0
    cy = cy or 0
    if M.is_npc_target(target) then
        return npc_aim_world(target, cx, cy)
    end
    if target then
        local bones = ep.get_bones_screen(target)
        if type(bones) == "table" then
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
    if M.is_npc_target(target) and target.entity then
        local vel = target.entity.Velocity or target.entity.velocity
        local vx, vy, vz = esp_util.vec3_pos(vel)
        if vx then
            return {
                x = vx,
                y = math.max(-100, math.min(100, vy or 0)),
                z = vz,
            }
        end
    end
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
    return M.bone_world(target, bone, cx, cy)
end
function M.get_aim_point(target, prefix, bone, origin, cx, cy, use_prediction)
    bone = bone or M.bone_name(prefix)
    local weapon = weapons.cached_held_ranged()
    if M.uses_bow_torso_aim(prefix) then
        bone = M.effective_aim_bone(bone, weapon)
    end
    local base = M.resolve_bone_world(target, bone, cx, cy)
    if not base then return nil end
    if M.uses_bow_torso_aim(prefix) then
        base = M.bow_aim_nudge(base, weapon)
    end
    if use_prediction == false then
        return base
    end
    origin = origin or combat_origin.get_fire_origin()
    if not origin then return base end
    return M.predict_point(origin, base, target, weapon)
end
function M.is_target_valid(target, prefix, cx, cy, fov_px, opts)
    opts = opts or {}
    if M.is_npc_target(target) then
        target = M.refresh_npc_target(target)
        if not target then return false end
    end
    if not M.is_aim_target(target) then return false end
    local origin = combat_origin.get_camera_origin() or combat_origin.get_fire_origin()
    if not M.within_max_distance(target, origin, prefix) then return false end
    local bone = M.bone_name(prefix)
    if bone == "Closest" then bone = "Head" end
    if M.uses_bow_torso_aim(prefix) then
        bone = M.effective_aim_bone(bone, weapons.cached_held_ranged())
    end
    local base = M.resolve_bone_world(target, bone, cx, cy)
    if not base then return false end
    if not M.passes_filters(target, prefix, base, origin, opts) then return false end
    if opts.ignore_fov then
        return true
    end
    local sx, sy, on_screen = w2s(base.x, base.y, base.z)
    if not on_screen then return false end
    local fov_dist = math_util.screen_fov_dist(sx, sy, cx, cy)
    return fov_dist <= fov_px
end
local function consider_target(target, prefix, screen_bone, use_fov, fov_px, origin, filter_visible, cx, cy, best, best_score, opts)
    opts = opts or {}
    if not M.within_max_distance(target, origin, prefix) then
        return best, best_score
    end
    local base = M.bone_world(target, screen_bone, cx, cy)
    if not base then
        return best, best_score
    end
    if filter_visible and not passes_visibility(target, base, origin) then
        return best, best_score
    end
    if not M.passes_filters(target, prefix, base, origin, opts) then
        return best, best_score
    end
    local sx, sy, on_screen = w2s(base.x, base.y, base.z)
    local fov_dist = math.huge
    if on_screen then
        fov_dist = math_util.screen_fov_dist(sx, sy, cx, cy)
    end
    if not opts.ignore_fov then
        if not on_screen then
            return best, best_score
        end
        if fov_dist > fov_px then
            return best, best_score
        end
    elseif not on_screen and use_fov then
        fov_dist = 1e6
    end
    local score
    if M.is_npc_target(target) then
        score = use_fov and fov_dist or (npc_distance(target, origin) or fov_dist)
    else
        score = use_fov and fov_dist or (origin and (ep.distance_to(target, origin) or fov_dist) or fov_dist)
    end
    if score < best_score then
        return target, score
    end
    return best, best_score
end
function M.find_target(cx, cy, fov_px, prefix, opts)
    opts = opts or {}
    local bone = M.bone_name(prefix)
    local screen_bone = bone == "Closest" and "Head" or bone
    if M.uses_bow_torso_aim(prefix) then
        screen_bone = M.effective_aim_bone(screen_bone, weapons.cached_held_ranged())
    end
    local use_fov = opts.force_crosshair_priority or M.target_priority_crosshair(prefix)
    local best, best_score = nil, use_fov and math.huge or math.huge
    local origin = combat_origin.get_camera_origin() or combat_origin.get_fire_origin()
    local filter_visible = not opts.ignore_visible and settings.multi(prefix .. "filters", 2, false)
    local target_players = combat_menu.players_enabled(prefix)
    local target_npcs = not opts.players_only and combat_menu.any_npc_enabled(prefix)
    if target_players then
        for _, p in ipairs(cache.players) do
            if player_state.is_combat_target(p) then
                best, best_score = consider_target(
                    p, prefix, screen_bone, use_fov, fov_px, origin, filter_visible, cx, cy, best, best_score, opts
                )
            end
        end
    end
    if target_npcs and cache.npcs then
        for _, entry in ipairs(cache.npcs) do
            if npc_enabled(entry, prefix) and M.is_npc_alive(entry) then
                local npc_target = {
                    is_npc = true,
                    entity = entry.entity,
                    inst = entry.inst,
                    head = entry.head,
                    root = entry.root,
                    name = entry.name,
                    kind = entry.kind,
                    lx = entry.lx,
                    ly = entry.ly,
                    lz = entry.lz,
                }
                best, best_score = consider_target(
                    npc_target, prefix, screen_bone, use_fov, fov_px, origin, filter_visible, cx, cy, best, best_score, opts
                )
            end
        end
    end
    return best
end
function M.screen_center()
    local w, h = April.require("core.draw_util").screen_size()
    return w, h
end
return M
end)()

April._mods["features.combat.active_target"] = (function()
local settings = April.require("core.settings")
local targeting = April.require("features.combat.targeting")
local combat_origin = April.require("game.combat_origin")
local esp_util = April.require("core.esp_util")
local M = {}
M.SOURCE_NAMES = { "Auto", "Silent Aim", "Aimbot" }
M.SOURCE_CROSSHAIR = "april_crosshair_source"
local MODULES = {
    { id = "april_silent_aim", path = "features.combat.aimbot", prefix = "april_silent_" },
    { id = "april_aimbot", path = "features.combat.camera_aimbot", prefix = "april_aim_" },
}
local function load_mod(entry)
    local ok, mod = pcall(function()
        return April.require(entry.path)
    end)
    if ok then return mod end
    return nil
end
function M.source_index(source_id)
    source_id = source_id or M.SOURCE_CROSSHAIR
    return math.floor(settings.num(source_id, 0) or 0)
end
function M.resolve_source_index(source_id)
    local idx = M.source_index(source_id)
    if idx >= 1 and idx <= #MODULES then
        if settings.enabled(MODULES[idx].id) then
            return idx
        end
        return nil
    end
    for i = 1, #MODULES do
        if settings.enabled(MODULES[i].id) then
            return i
        end
    end
    return nil
end
function M.get_entry(source_idx, source_id)
    source_idx = source_idx or M.resolve_source_index(source_id)
    if not source_idx then return nil end
    return MODULES[source_idx]
end
function M.get_target(source_idx, source_id)
    local entry = M.get_entry(source_idx, source_id)
    if not entry then return nil, nil end
    local mod = load_mod(entry)
    if not mod then return nil, entry.prefix end
    if mod.get_target then
        local t = mod.get_target()
        if t then return t, entry.prefix end
    end
    if mod.get_scoped_target then
        local t = mod.get_scoped_target()
        if t then return t, entry.prefix end
    end
    return nil, entry.prefix
end
function M.get_aim_world(source_idx, cx, cy, source_id)
    local target, prefix = M.get_target(source_idx, source_id)
    if not target or not prefix then return nil, target, prefix end
    local sw, sh = targeting.screen_center()
    cx = cx or sw * 0.5
    cy = cy or sh * 0.5
    local origin = combat_origin.get_camera_origin() or combat_origin.get_fire_origin()
    local aim = targeting.get_aim_point(target, prefix, nil, origin, cx, cy, false)
    return aim, target, prefix
end
function M.get_aim_screen(source_idx, cx, cy, source_id)
    local aim, target, prefix = M.get_aim_world(source_idx, cx, cy, source_id)
    if not aim then return nil, target, prefix end
    local sx, sy, vis = esp_util.w2s(aim.x, aim.y, aim.z)
    if not vis then return nil, target, prefix end
    return { x = sx, y = sy }, target, prefix
end
return M
end)()

April._mods["features.combat.silent_resolve"] = (function()
local settings = April.require("core.settings")
local combat_origin = April.require("game.combat_origin")
local silent_ray = April.require("core.silent_ray")
local manip_math = April.require("core.manip_math")
local targeting = April.require("features.combat.targeting")
local bullet_tp_ray = April.require("features.combat.bullet_tp_ray")
local weapons = April.require("game.weapons")
local ballistic = April.require("core.ballistic")
local M = {}
local OFF_INFO = {
    state = "off",
    manip_state = "off",
    peek = nil,
    radius = 1,
    hitscan_on = false,
    tp_on = false,
    manip_on = false,
}
local BULLET_PREFIX = "april_silent_"
function M.bullet_enabled()
    return settings.bool("april_bullet_enabled", false)
end
local function bullet_flag(name, default)
    if not M.bullet_enabled() then
        return false
    end
    return settings.bool(BULLET_PREFIX .. name, default == true)
end
local function fire_origin(camera)
    return combat_origin.get_muzzle_origin() or camera
end
local function feature_flags()
    return {
        hitscan_on = bullet_flag("hitscan", false),
        tp_on = bullet_flag("bullet_tp", false),
        manip_on = bullet_flag("bullet_manip", false),
    }
end
local function merge_info(base, manip_extra, flags)
    local info = base or {}
    flags = flags or feature_flags()
    info.hitscan_on = flags.hitscan_on
    info.tp_on = flags.tp_on
    info.manip_on = flags.manip_on
    if manip_extra then
        info.manip_state = manip_extra.state or "off"
        info.peek = manip_extra.peek or info.peek
        info.radius = manip_extra.radius or info.radius
        info.base_radius = manip_extra.base_radius
        info.extend_active = manip_extra.extend_active
        info.scan_progress = manip_extra.scan_progress or info.scan_progress
        info.body_peek = manip_extra.body_peek
    else
        info.manip_state = info.manip_state or "off"
    end
    return info
end
local function body_peek_mod()
    local ok, mod = pcall(function()
        return April.require("features.combat.body_peek")
    end)
    if ok then return mod end
    return nil
end
local function resolve_manip(body, hitpart, muzzle, target)
    local extra = {
        state = "off",
        peek = nil,
        radius = 0,
        base_radius = 0,
        extend_active = false,
        scan_progress = 0,
        body_peek = false,
    }
    if not bullet_flag("bullet_manip", false) or not body then
        return nil, extra
    end
    local base_r = manip_math.clamp_radius(settings.num(BULLET_PREFIX .. "manip_dist", 1))
    local extend_on = settings.bool(BULLET_PREFIX .. "manip_extend", false)
    local ext_extra = extend_on
        and manip_math.clamp_extend_extra(settings.num(BULLET_PREFIX .. "manip_extend_dist", 7))
        or 0
    local ev = manip_math.evaluate_manipulation(body, hitpart, {
        base_radius = base_r,
        extend = extend_on,
        extend_extra = ext_extra,
    })
    extra.state = ev.state
    extra.peek = ev.peek
    extra.radius = ev.radius or base_r
    extra.base_radius = base_r
    extra.extend_active = ev.extend_active == true
    extra.scan_progress = ev.scan_progress or 0
    local max_r = extend_on and (base_r + ext_extra) or base_r
    local body_peek = body_peek_mod()
    local use_body_peek = settings.bool("april_bullet_body_peek", false) and body_peek
    if ev.state == "ready" and ev.peek then
        local peek = ev.peek
        if use_body_peek and body_peek.ensure_peek then
            local moved = body_peek.ensure_peek(peek, hitpart, target, max_r)
            if moved then
                extra.body_peek = true
                peek = moved
            end
        end
        return manip_math.peek_track_origin(peek, muzzle, body), extra
    end
    if ev.state == "blocked" and use_body_peek and body_peek.try_peek then
        local peek = body_peek.try_peek(body, hitpart, max_r, target)
        if peek then
            extra.state = "ready"
            extra.peek = peek
            extra.body_peek = true
            extra.scan_progress = 1
            local track = manip_math.peek_track_origin(peek, muzzle, body)
            return track, extra
        end
    end
    return nil, extra
end
local function apply_drop_aim(origin, hitpart, weapon, state, manip_extra, flags)
    local muzzle = origin or combat_origin.get_muzzle_origin()
    local curve = ballistic.curve_for_weapon(muzzle, hitpart, weapon, 24)
    local info = merge_info({
        state = state or "curve",
        peek = nil,
        radius = manip_extra and manip_extra.radius or 0,
        use_curve = true,
        weapon = weapon,
        hitpart = hitpart,
        curve_path = curve and curve.path or nil,
        launch_dir = curve and curve.launch_dir or nil,
    }, manip_extra, flags)
    return muzzle, hitpart, info
end
local function apply_ray_aim(origin, aim, hitpart, weapon, state, manip_extra, meta, flags)
    meta = meta or {}
    local info = merge_info({
        state = state,
        peek = manip_extra and manip_extra.peek or nil,
        radius = manip_extra and manip_extra.radius or 0,
        use_curve = false,
        weapon = weapon,
        hitpart = hitpart,
        tp_path = meta.tp_path,
        tp_method = meta.method,
        tp_scan_visible = meta.tp_scan_visible,
        tp_scan_progress = meta.tp_scan_progress,
    }, manip_extra, flags)
    return origin, aim, info
end
function M.resolve_track(target, prefix, cx, cy)
    if not target then return nil, nil, OFF_INFO end
    local camera = silent_ray.get_camera_origin()
    if not camera then return nil, nil, OFF_INFO end
    local flags = feature_flags()
    local weapon = weapons.cached_held_ranged() or weapons.get_held_ranged_weapon_name()
    local bone = targeting.bone_name(prefix)
    local hitpart = targeting.resolve_bone_world(target, bone, cx, cy)
    if not hitpart then return nil, nil, OFF_INFO end
    local muzzle = fire_origin(camera)
    local body = combat_origin.get_server_origin()
    local manip_fire, manip_extra = resolve_manip(body, hitpart, muzzle, target)
    local fire = manip_fire or muzzle
    local hitscan_on = flags.hitscan_on
    local tp_on = flags.tp_on
    if tp_on then
        local head = targeting.resolve_bone_world(target, "Head", cx, cy) or hitpart
        local tp = bullet_tp_ray.resolve({
            method = bullet_tp_ray.METHOD_UNDER_TP,
            camera = camera,
            hitpart = head,
            bone = "Head",
            muzzle = muzzle,
            body = body,
        })
        if tp and tp.origin and tp.aim then
            local path = tp.tp_path or bullet_tp_ray.build_path(tp.origin, tp.aim, muzzle)
            if manip_extra.peek and manip_fire then
                path = bullet_tp_ray.build_path(manip_fire, head, muzzle) or path
            end
            return apply_ray_aim(tp.origin, tp.aim, tp.hitpart or head, weapon, "tp", manip_extra, {
                tp_path = path,
                method = tp.method,
                tp_scan_visible = tp.tp_scan_visible,
                tp_scan_progress = tp.tp_scan_progress,
            }, flags)
        end
    end
    if manip_extra.state == "ready" and manip_fire then
        return apply_ray_aim(manip_fire, hitpart, hitpart, weapon, "ready", manip_extra, {
            tp_path = bullet_tp_ray.build_path(manip_fire, hitpart, muzzle),
            method = "Manip",
        }, flags)
    end
    if hitscan_on then
        return apply_ray_aim(muzzle or fire, hitpart, hitpart, weapon, "hitscan", manip_extra, nil, flags)
    end
    if manip_extra.state == "direct" then
        return apply_drop_aim(muzzle, hitpart, weapon, "direct", manip_extra, flags)
    end
    return apply_drop_aim(muzzle, hitpart, weapon, "curve", manip_extra, flags)
end
function M.any_bullet_feature()
    return bullet_flag("hitscan", false)
        or bullet_flag("bullet_tp", false)
        or bullet_flag("bullet_manip", false)
end
function M.bypass_visibility()
    return bullet_flag("bullet_tp", false) or bullet_flag("hitscan", false)
end
return M
end)()

April._mods["features.combat.bullet_hud"] = (function()
local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local theme = April.require("core.ui_theme")
local overlay_theme = April.require("core.overlay_theme")
local desync_vis = April.require("core.desync_vis")
local combat_origin = April.require("game.combat_origin")
local manip_math = April.require("core.manip_math")
local M = {}
local PREFIX = "april_silent_"
local P_BULLET = "april_bullet_enabled"
local scan_anim = 0
local FIRE_LABELS = {
    tp = "Bullet TP",
    hitscan = "Hitscan",
    ready = "Manip Peek",
    direct = "Clear LOS",
    curve = "Ballistic",
    blocked = "Blocked",
    scanning = "Scanning",
    off = "Idle",
}
local MANIP_LABELS = {
    direct = "Clear LOS",
    ready = "Peek Ready",
    scanning = "Scanning",
    blocked = "No Peek",
    off = "Off",
}
local function bullet_flag(name, default)
    if not settings.bool(P_BULLET, false) then
        return false
    end
    return settings.bool(PREFIX .. name, default == true)
end
function M.update(dt)
    scan_anim = scan_anim + (dt or 0.016) * 0.85
    if scan_anim > 1 then scan_anim = scan_anim - 1 end
end
local function row_color(active, ok, warn)
    if active and ok then return theme.GREEN end
    if active and warn then return theme.ORANGE end
    if active then return theme.RED end
    return overlay_theme.text_muted()
end
local function draw_status_panel(cx, cy, fov, info)
    if not settings.bool(PREFIX .. "manip_status", false) then return end
    if not info then return end
    overlay_theme.sync()
    local hitscan_on = info.hitscan_on == true
    local tp_on = info.tp_on == true
    local manip_on = info.manip_on == true
    if not hitscan_on and not tp_on and not manip_on then return end
    local manip_state = info.manip_state or "off"
    local fire_mode = info.state or "off"
    local fire_label = FIRE_LABELS[fire_mode] or fire_mode
    local manip_label = MANIP_LABELS[manip_state] or manip_state
    local pad_x, pad_y = 10, 6
    local row_h = 14
    local bar_h = 5
    local title = "BULLET STATUS"
    local title_w = theme.text_w(title, 11)
    local w1 = theme.text_w("Hitscan", 10) + theme.text_w("ON", 10) + 24
    local w2 = theme.text_w("Bullet TP", 10) + theme.text_w("ON", 10) + 24
    local w3 = theme.text_w("Manip", 10) + theme.text_w(manip_label, 10) + 24
    local w4 = theme.text_w("Fire", 10) + theme.text_w(fire_label, 10) + 24
    local panel_w = math.max(title_w, w1, w2, w3, w4) + pad_x * 2 + 8
    panel_w = math.max(panel_w, 168)
    local rows = 4
    local has_bar = manip_on and (manip_state == "scanning" or manip_state == "ready" or manip_state == "direct")
    local panel_h = 22 + rows * row_h + pad_y + (has_bar and (bar_h + 6) or 0)
    local x = cx - panel_w * 0.5
    local y = cy + fov + 10
    overlay_theme.draw_panel(x, y, panel_w, panel_h, title)
    local tx = x + pad_x
    local ry = y + 24
    local function draw_row(label, value, col)
        draw_util.text(tx, ry, label, overlay_theme.text_muted(), 10)
        local vw = theme.text_w(value, 10)
        draw_util.text(x + panel_w - pad_x - vw, ry, value, col, 10)
        ry = ry + row_h
    end
    draw_row("Hitscan", hitscan_on and "ON" or "OFF", row_color(hitscan_on, true, false))
    draw_row("Bullet TP", tp_on and "ON" or "OFF", row_color(tp_on, true, false))
    local manip_ok = manip_state == "ready" or manip_state == "direct"
    local manip_warn = manip_state == "scanning"
    draw_row("Manip", manip_on and manip_label or "OFF",
        row_color(manip_on, manip_ok, manip_warn))
    local fire_col = theme.CYAN
    if fire_mode == "tp" then
        fire_col = { 0.82, 0.5, 1, 1 }
    elseif fire_mode == "hitscan" then
        fire_col = theme.CYAN
    elseif fire_mode == "ready" or fire_mode == "direct" then
        fire_col = theme.GREEN
    elseif fire_mode == "scanning" or fire_mode == "blocked" then
        fire_col = theme.ORANGE
    end
    draw_row("Fire", fire_label, fire_col)
    if has_bar then
        local bar_w = panel_w - pad_x * 2
        local bar_x = x + pad_x
        local bar_y = ry + 2
        local ready = manip_state == "ready" or manip_state == "direct"
        local prog
        if ready then
            prog = 1
        elseif manip_state == "scanning" then
            prog = 0.25 + scan_anim * 0.65
        else
            prog = math.max(0, math.min(1, info.scan_progress or 0))
        end
        local bg = theme.alpha(overlay_theme.panel_bg(), 0.95)
        local border = overlay_theme.border(0.5)
        local fill = ready and theme.GREEN or theme.alpha(overlay_theme.accent(), 0.9)
        if draw and draw.rect_filled then
            draw.rect_filled(bar_x, bar_y, bar_w, bar_h, bg, 0)
            if prog > 0.01 then
                draw.rect_filled(bar_x, bar_y, bar_w * prog, bar_h, fill, 0)
            end
            if draw.rect then
                draw.rect(bar_x, bar_y, bar_w, bar_h, border, 0, 1)
            end
        end
    end
end
local function draw_peek_visual(info, track)
    if not settings.bool(PREFIX .. "manip_peek_vis", false) then return end
    if not info or not info.peek then return end
    if info.manip_state ~= "ready" and info.manip_state ~= "direct" and not info.body_peek then return end
    local body = combat_origin.get_server_origin()
    if not body then return end
    local peek = info.peek
    local col_peek = { 1, 0.85, 0.2, 0.95 }
    local eye_y = peek.y + manip_math.eye_offset_y()
    desync_vis.draw_cross(peek.x, eye_y, peek.z, 0.85, col_peek, 2)
    desync_vis.draw_link(body, peek, { col_peek[1], col_peek[2], col_peek[3], 0.35 }, 1)
    local aim = info.hitpart or (track and track.aim)
    local ray_from = manip_math.peek_track_origin(peek, track and track.origin, body)
    if ray_from and aim then
        desync_vis.draw_link(ray_from, aim, { 1, 0.45, 0.2, 0.55 }, 1.5)
        desync_vis.draw_cross(ray_from.x, ray_from.y, ray_from.z, 0.4, col_peek, 2)
    end
end
function M.draw(cx, cy, fov, track)
    if not settings.bool(P_BULLET, false) then return end
    if not draw then return end
    local info = track and track.manip
    if not info then return end
    local show_hud = settings.bool(PREFIX .. "manip_status", false)
    local show_peek = settings.bool(PREFIX .. "manip_peek_vis", false)
    if not show_hud and not show_peek then return end
    draw_peek_visual(info, track)
    draw_status_panel(cx, cy, fov, info)
end
return M
end)()

April._mods["features.combat.camera_aimbot"] = (function()
local settings = April.require("core.settings")
local targeting = April.require("features.combat.targeting")
local weapons = April.require("game.weapons")
local combat_origin = April.require("game.combat_origin")
local draw_util = April.require("core.draw_util")
local menu_util = April.require("core.menu_util")
local combat_menu = April.require("features.combat.combat_menu")
local silent_whitelist = April.require("features.combat.silent_whitelist")
local aim_key = April.require("core.aim_key")
local theme = April.require("core.ui_theme")
local M = {}
local locked_target = nil
local PREFIX = "april_aim_"
local P_MASTER = "april_aimbot"
local P_AIM_KEY = "april_aim_key"
local P_AIM_KEY_MODE = "april_aim_key_mode"
local TARGET_SCAN_MS = 33
local cached_aim = nil
local smoothed_aim = nil
local last_target_scan = 0
local human_phase = 0
local human_drift = { x = 0, y = 0, z = 0 }
local overshoot = { x = 0, y = 0, z = 0 }
local SMOOTH_LINEAR = 0
local SMOOTH_EASE_OUT = 1
local SMOOTH_EASE_IN_OUT = 2
local SMOOTH_EXPONENTIAL = 3
local SMOOTH_ADAPTIVE = 4
local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end
local function w2s(x, y, z)
    if draw and draw.world_to_screen then
        return draw.world_to_screen(x, y, z)
    end
    if utility and utility.world_to_screen then
        return utility.world_to_screen(x, y, z)
    end
    return 0, 0, false
end
local function holding_weapon()
    if weapons.holding_ranged_weapon() then return true end
    if weapons.get_held_ranged_weapon_name() then return true end
    local lp = entity and entity.get_local_player and entity.get_local_player()
    if lp and lp.tool_name and lp.tool_name ~= "" then
        return weapons.is_ranged_weapon_name(lp.tool_name)
    end
    return false
end
local function enabled()
    return settings.bool(P_MASTER, false)
end
local function aiming()
    if not enabled() then return false end
    return aim_key.active(P_AIM_KEY, P_AIM_KEY_MODE)
end
local function aim_dist(a, b)
    if not a or not b then return 0 end
    local dx = (a.x or 0) - (b.x or 0)
    local dy = (a.y or 0) - (b.y or 0)
    local dz = (a.z or 0) - (b.z or 0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end
local function base_smooth_alpha()
    local n = settings.num(PREFIX .. "smooth", 10)
    n = math.max(1, math.min(25, n))
    return math.max(0.08, math.min(0.95, 1.25 / n))
end
local function smooth_alpha(prev, nxt)
    local base = base_smooth_alpha()
    local style = math.floor(tonumber(settings.num(PREFIX .. "smooth_type", 0)) or 0)
    if style == SMOOTH_LINEAR then
        return base
    end
    local t = math.min(1, aim_dist(prev, nxt) / 8)
    if style == SMOOTH_EASE_OUT then
        return math.max(0.05, math.min(0.98, base * (0.45 + 0.95 * t)))
    elseif style == SMOOTH_EASE_IN_OUT then
        local u = t * t * (3 - 2 * t)
        return math.max(0.05, math.min(0.98, base * (0.5 + 0.85 * u)))
    elseif style == SMOOTH_EXPONENTIAL then
        return math.max(0.05, math.min(0.99, 1 - ((1 - base) ^ (1 + t * 1.6))))
    elseif style == SMOOTH_ADAPTIVE then
        return math.max(0.04, math.min(0.98, base * (0.32 + 1.45 * t)))
    end
    return base
end
local function reset_humanize()
    human_phase = 0
    human_drift.x, human_drift.y, human_drift.z = 0, 0, 0
    overshoot.x, overshoot.y, overshoot.z = 0, 0, 0
end
local function apply_humanize(aim, prev)
    if not aim or not settings.bool(PREFIX .. "humanize", false) then
        return aim
    end
    local str = math.max(0, math.min(100, settings.num(PREFIX .. "humanize_str", 35))) / 100
    if str <= 0 then return aim end
    human_phase = human_phase + (0.035 + str * 0.04)
    local amp = 0.05 + str * 0.28
    local target_drift = {
        x = math.sin(human_phase * 1.7) * amp,
        y = math.cos(human_phase * 1.25) * amp * 0.55,
        z = math.sin(human_phase * 2.05 + 0.7) * amp * 0.4,
    }
    local da = 0.12 + str * 0.1
    human_drift.x = human_drift.x + (target_drift.x - human_drift.x) * da
    human_drift.y = human_drift.y + (target_drift.y - human_drift.y) * da
    human_drift.z = human_drift.z + (target_drift.z - human_drift.z) * da
    if prev then
        local dx = (aim.x - prev.x) * (0.08 + str * 0.18)
        local dy = (aim.y - prev.y) * (0.08 + str * 0.18)
        local dz = (aim.z - prev.z) * (0.08 + str * 0.18)
        overshoot.x = overshoot.x * 0.78 + dx
        overshoot.y = overshoot.y * 0.78 + dy
        overshoot.z = overshoot.z * 0.78 + dz
    else
        overshoot.x = overshoot.x * 0.7
        overshoot.y = overshoot.y * 0.7
        overshoot.z = overshoot.z * 0.7
    end
    return {
        x = aim.x + human_drift.x + overshoot.x,
        y = aim.y + human_drift.y + overshoot.y,
        z = aim.z + human_drift.z + overshoot.z,
    }
end
local function blend_aim(prev, nxt)
    if not nxt then return prev end
    local target = apply_humanize(nxt, prev)
    if not prev then return { x = target.x, y = target.y, z = target.z } end
    local a = smooth_alpha(prev, target)
    return {
        x = prev.x + (target.x - prev.x) * a,
        y = prev.y + (target.y - prev.y) * a,
        z = prev.z + (target.z - prev.z) * a,
    }
end
local function update_target(cx, cy, fov)
    local sticky = settings.multi(PREFIX .. "options", combat_menu.OPT_STICKY, false)
    local now = tick_ms()
    if locked_target and targeting.is_npc_target(locked_target) then
        locked_target = targeting.refresh_npc_target(locked_target)
    end
    if locked_target and not targeting.is_target_valid(locked_target, PREFIX, cx, cy, fov) then
        locked_target = nil
        smoothed_aim = nil
        reset_humanize()
    end
    if locked_target and sticky then
        return
    end
    if sticky and now - last_target_scan < TARGET_SCAN_MS then
        return
    end
    last_target_scan = now
    locked_target = targeting.find_target(cx, cy, fov, PREFIX)
end
local function resolve_aim_point(target, cx, cy)
    local predict_origin = combat_origin.get_muzzle_origin()
        or combat_origin.get_fire_origin()
        or combat_origin.get_camera_origin()
    return targeting.get_aim_point(target, PREFIX, nil, predict_origin, cx, cy, true)
end
function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.SILENT_AIM)
    menu.add_checkbox(T, G, P_MASTER, "Enable Aimbot", false)
    menu.add_combo(T, G, P_AIM_KEY_MODE, "Aim Key Mode", { "Always", "Hold", "Toggle" }, 1,
        { parent = P_MASTER })
    if menu.add_hotkey then
        menu.add_hotkey(T, G, P_AIM_KEY, "Aim Key", 0, { parent = P_MASTER, default_mode = 1 })
    end
    if menu and menu.set_visible then
        pcall(menu.set_visible, P_AIM_KEY_MODE, false)
    end
    combat_menu.register_aimbot(T, G.SILENT_AIM, PREFIX, P_MASTER, {
        fov_default = 120,
        fov_color = theme.GREEN or { 0.2, 1, 0.45, 1 },
        line_color = { 0.2, 1, 0.45, 1 },
    })
    menu_util.bind_children(P_MASTER, {
        P_AIM_KEY, P_AIM_KEY_MODE,
        PREFIX .. "target_type", PREFIX .. "bone",
        PREFIX .. "filters",
        PREFIX .. "whitelist_ids", PREFIX .. "whitelist_clear",
        PREFIX .. "targets", PREFIX .. "options",
        PREFIX .. "smooth", PREFIX .. "smooth_type",
        PREFIX .. "humanize", PREFIX .. "humanize_str",
        PREFIX .. "draw_fov", PREFIX .. "fov_style", PREFIX .. "target_line",
        PREFIX .. "max_dist", PREFIX .. "fov",
    })
    menu_util.bind_children(PREFIX .. "humanize", {
        PREFIX .. "humanize_str",
    })
    menu_util.bind_children(PREFIX .. "draw_fov", {
        PREFIX .. "fov_style",
    })
end
function M.update(_dt)
    cached_aim = nil
    if not enabled() then
        locked_target = nil
        smoothed_aim = nil
        reset_humanize()
        return
    end
    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num(PREFIX .. "fov", 120)
    update_target(cx, cy, fov)
    if holding_weapon() then
        combat_origin.sync_weapon(weapons.cached_held_ranged() or weapons.get_held_ranged_weapon_name())
        local wl_target = locked_target
        if not wl_target or not targeting.is_aim_target(wl_target) then
            wl_target = targeting.find_target(cx, cy, fov, PREFIX, { ignore_whitelist = true })
        end
        silent_whitelist.tick(wl_target, PREFIX)
    end
    if not locked_target or not targeting.is_aim_target(locked_target) then
        smoothed_aim = nil
        reset_humanize()
        return
    end
    local aim = resolve_aim_point(locked_target, cx, cy)
    if not aim then
        smoothed_aim = nil
        reset_humanize()
        return
    end
    if aiming() and holding_weapon() then
        smoothed_aim = blend_aim(smoothed_aim, aim)
        cached_aim = smoothed_aim
        if camera and camera.look_at then
            local smooth_frames = math.max(1, math.floor(settings.num(PREFIX .. "smooth", 10)))
            local style = math.floor(tonumber(settings.num(PREFIX .. "smooth_type", 0)) or 0)
            if style == SMOOTH_ADAPTIVE or style == SMOOTH_EXPONENTIAL then
                smooth_frames = math.max(1, math.floor(smooth_frames * 0.75))
            end
            pcall(camera.look_at, smoothed_aim.x, smoothed_aim.y, smoothed_aim.z, smooth_frames)
        end
    else
        smoothed_aim = nil
        reset_humanize()
        cached_aim = aim
    end
end
function M.get_target()
    return locked_target
end
function M.get_scoped_target()
    if locked_target then return locked_target end
    if not enabled() then return nil end
    local sw, sh = targeting.screen_center()
    local fov = settings.num(PREFIX .. "fov", 120)
    return targeting.find_target(sw * 0.5, sh * 0.5, fov, PREFIX)
end
function M.draw()
    if not enabled() then return end
    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num(PREFIX .. "fov", 120)
    if settings.bool(PREFIX .. "draw_fov", false) then
        local col = settings.color(PREFIX .. "draw_fov", { 0.2, 1, 0.45, 1 })
        local filled = settings.num(PREFIX .. "fov_style", 1) == 1
        if filled and draw and draw.circle_filled then
            local fill = settings.color(PREFIX .. "draw_fov", { 0.2, 1, 0.45, 0.12 })
            local c = { fill[1], fill[2], fill[3], (fill[4] or 1) * 0.25 }
            draw.circle_filled(cx, cy, fov, c, 64)
        end
        if draw and draw.circle then
            draw.circle(cx, cy, fov, col, 64, 1)
        else
            draw_util.circle(cx, cy, fov, col, false)
        end
    end
    if locked_target and settings.bool(PREFIX .. "target_line", false) then
        local aim = cached_aim or smoothed_aim or resolve_aim_point(locked_target, cx, cy)
        if aim then
            local tx, ty, vis = w2s(aim.x, aim.y, aim.z)
            if vis then
                local col = settings.color(PREFIX .. "target_line", { 0.2, 1, 0.45, 1 })
                draw_util.line(cx, cy, tx, ty, col, 1.5)
            end
        end
    end
end
return M
end)()

April._mods["features.combat.body_peek"] = (function()
local settings = April.require("core.settings")
local env = April.require("core.env")
local cframe_move = April.require("core.cframe_move")
local manip_math = April.require("core.manip_math")
local misc_gate = April.require("core.misc_gate")
local targeting = April.require("features.combat.targeting")
local M = {}
local MAX_OFFSET = 7
local SAME_PEEK_EPS = 0.35
local TICK_TIMEOUT_MS = 180
local active = false
local peek_pos = nil
local ctx = nil
local last_tick_ms = 0
local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end
local function desync_mod()
    local ok, mod = pcall(function()
        return April.require("features.movement.desync")
    end)
    if ok then return mod end
    return nil
end
local function hrp()
    local lp = env.get_local_player()
    local char = lp and lp.character
    if not char or not env.is_valid(char) then return nil end
    return cframe_move.find_part(char, "HumanoidRootPart")
end
local function same_pos(a, b)
    if not a or not b then return false end
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return (dx * dx + dy * dy + dz * dz) <= SAME_PEEK_EPS * SAME_PEEK_EPS
end
local function clamp_peek_to_body(peek, cur, max_radius)
    local max_y = manip_math.max_y_offset and manip_math.max_y_offset() or 2.5
    local dy = peek.y - cur.y
    if dy > max_y then
        peek.y = cur.y + max_y
    elseif dy < -max_y then
        peek.y = cur.y - max_y
    end
    local dx = peek.x - cur.x
    dy = peek.y - cur.y
    local dz = peek.z - cur.z
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    max_radius = math.min(MAX_OFFSET, tonumber(max_radius) or 1)
    if dist < 0.05 or dist > max_radius + 0.5 then
        return nil
    end
    return peek
end
function M.enabled()
    return settings.bool("april_bullet_enabled", false)
        and settings.bool("april_silent_bullet_manip", false)
        and settings.bool("april_bullet_body_peek", false)
end
function M.is_active()
    return active
end
function M.get_peek_pos()
    return peek_pos
end
function M.release()
    if not active then return end
    local desync = desync_mod()
    if desync and desync.peek_end then
        pcall(desync.peek_end)
    end
    active = false
    peek_pos = nil
    ctx = nil
end
local function begin_desync()
    local desync = desync_mod()
    if desync and desync.peek_begin then
        pcall(desync.peek_begin)
    end
end
local function move_to_peek(peek, target, hitpart)
    local root = hrp()
    if not root then return nil end
    local cur = cframe_move.read_pos(root)
    if not cur then return nil end
    if not manip_math.is_visible_from_pos(peek, hitpart) then
        return nil
    end
    if not same_pos(cur, peek) then
        begin_desync()
        cframe_move.set_position_only(root, peek.x, peek.y, peek.z)
    elseif not active then
        begin_desync()
    end
    peek_pos = { x = peek.x, y = peek.y, z = peek.z }
    ctx = { target = target, hitpart = hitpart }
    active = true
    last_tick_ms = tick_ms()
    return peek_pos
end
function M.ensure_peek(peek, hitpart, target, max_radius)
    if not M.enabled() then return nil end
    if not misc_gate.movement_allowed() then return nil end
    if not peek or not hitpart then return nil end
    local root = hrp()
    if not root then return nil end
    local cur = cframe_move.read_pos(root)
    if not cur then return nil end
    peek = clamp_peek_to_body({ x = peek.x, y = peek.y, z = peek.z }, cur, max_radius)
    if not peek then return nil end
    if active and peek_pos and same_pos(peek_pos, peek) then
        ctx = { target = target, hitpart = hitpart }
        last_tick_ms = tick_ms()
        return peek_pos
    end
    return move_to_peek(peek, target, hitpart)
end
function M.try_peek(body, hitpart, max_radius, target)
    if not M.enabled() then return nil end
    if not misc_gate.movement_allowed() then return nil end
    if not body or not hitpart then return nil end
    max_radius = math.min(MAX_OFFSET, tonumber(max_radius) or 1)
    if max_radius < 0.15 then return nil end
    local root = hrp()
    if not root then return nil end
    local cur = cframe_move.read_pos(root)
    if not cur then return nil end
    local peek = manip_math.find_manipulation_position(body, hitpart, {
        base_radius = math.min(1, max_radius),
        extend = max_radius > 1.05,
        extend_extra = math.max(0, max_radius - 1),
    })
    if not peek then return nil end
    peek = clamp_peek_to_body(peek, cur, max_radius)
    if not peek then return nil end
    return M.ensure_peek(peek, hitpart, target, max_radius)
end
local function target_alive(target)
    if not target then return false end
    if targeting.is_npc_target(target) then
        target = targeting.refresh_npc_target(target)
        return target ~= nil and targeting.is_aim_target(target)
    end
    return targeting.is_aim_target(target)
end
function M.tick(target, hitpart)
    last_tick_ms = tick_ms()
    if not active then return end
    if not M.enabled() then
        M.release()
        return
    end
    if hitpart then
        if ctx then ctx.hitpart = hitpart end
    end
    if target then
        if ctx then ctx.target = target end
    end
    if not ctx or not peek_pos or not ctx.hitpart then
        M.release()
        return
    end
    if not target_alive(ctx.target) then
        M.release()
        return
    end
    if not manip_math.is_visible_from_pos(peek_pos, ctx.hitpart) then
        M.release()
        return
    end
end
function M.update(_dt)
    if not active then return end
    if tick_ms() - last_tick_ms > TICK_TIMEOUT_MS then
        M.release()
    end
end
function M.register_menu()
end
function M.draw()
end
return M
end)()

April._mods["features.combat.aimbot"] = (function()
local settings = April.require("core.settings")
local targeting = April.require("features.combat.targeting")
local weapons = April.require("game.weapons")
local combat_origin = April.require("game.combat_origin")
local draw_util = April.require("core.draw_util")
local menu_util = April.require("core.menu_util")
local combat_menu = April.require("features.combat.combat_menu")
local silent_ray = April.require("core.silent_ray")
local silent_resolve = April.require("features.combat.silent_resolve")
local silent_whitelist = April.require("features.combat.silent_whitelist")
local bullet_hud = April.require("features.combat.bullet_hud")
local body_peek = April.require("features.combat.body_peek")
local theme = April.require("core.ui_theme")
local ep = April.require("core.entity_props")
local M = {}
local locked_target = nil
local PREFIX = "april_silent_"
local P_MASTER = "april_silent_aim"
local SHOOT_VK = 0x01
local TARGET_SCAN_MS = 33
local cached_track = { origin = nil, aim = nil, manip = { state = "off" }, tracking = false }
local last_target_scan = 0
local fire_was_down = false
local shot_allowed = true
local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end
local function w2s(x, y, z)
    if draw and draw.world_to_screen then
        return draw.world_to_screen(x, y, z)
    end
    if utility and utility.world_to_screen then
        return utility.world_to_screen(x, y, z)
    end
    return 0, 0, false
end
local function holding_weapon()
    if weapons.holding_ranged_weapon() then return true end
    if weapons.get_held_ranged_weapon_name() then return true end
    local lp = ep.get_local_player()
    local tool = lp and ep.tool_name(lp)
    if tool and tool ~= "" then
        return weapons.is_ranged_weapon_name(tool)
    end
    return false
end
local P_BULLET = "april_bullet_enabled"
function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.SILENT_AIM)
    menu_util.register_keybind(T, G.SILENT_AIM, P_MASTER, "Enable Silent Aim", false)
    combat_menu.register_silent_aim(T, G.SILENT_AIM, PREFIX, P_MASTER, {
        fov_default = 150,
        fov_color = theme.CYAN,
        line_color = theme.RED,
    })
    menu.add_checkbox(T, G.SILENT_AIM, P_BULLET, "Enable Bullet", false)
    combat_menu.register_bullet(T, G.SILENT_AIM, PREFIX, P_BULLET)
    menu_util.bind_children(P_MASTER, {
        PREFIX .. "target_type", PREFIX .. "bone",
        PREFIX .. "filters",
        PREFIX .. "whitelist_ids", PREFIX .. "whitelist_clear",
        PREFIX .. "targets", PREFIX .. "options",
        PREFIX .. "draw_fov", PREFIX .. "fov_style", PREFIX .. "target_line",
        PREFIX .. "hit_chance", PREFIX .. "max_dist", PREFIX .. "fov",
    })
    menu_util.bind_children(P_BULLET, {
        PREFIX .. "hitscan",
        PREFIX .. "bullet_tp",
        PREFIX .. "bullet_manip", PREFIX .. "manip_dist", PREFIX .. "manip_extend", PREFIX .. "manip_extend_dist",
        "april_bullet_body_peek",
        PREFIX .. "manip_status", PREFIX .. "manip_peek_vis",
    })
    menu_util.bind_children(PREFIX .. "bullet_manip", {
        PREFIX .. "manip_dist", PREFIX .. "manip_extend", PREFIX .. "manip_extend_dist",
        "april_bullet_body_peek",
    })
    menu_util.bind_children(PREFIX .. "manip_extend", {
        PREFIX .. "manip_extend_dist",
    })
    menu_util.bind_children(PREFIX .. "draw_fov", {
        PREFIX .. "fov_style",
    })
end
local function silent_active()
    return settings.enabled(P_MASTER) and silent_ray.available()
end
local function bullet_track_active()
    return settings.bool(P_BULLET, false)
        and silent_resolve.any_bullet_feature()
        and silent_ray.available()
end
local function active()
    return silent_active() or bullet_track_active()
end
local function update_target(cx, cy, fov, find_opts)
    local sticky = settings.multi(PREFIX .. "options", 1, false)
    local now = tick_ms()
    find_opts = find_opts or {}
    if locked_target and targeting.is_npc_target(locked_target) then
        locked_target = targeting.refresh_npc_target(locked_target)
    end
    if locked_target and not targeting.is_target_valid(locked_target, PREFIX, cx, cy, fov, find_opts) then
        locked_target = nil
    end
    if locked_target and sticky then
        return
    end
    if sticky and now - last_target_scan < TARGET_SCAN_MS then
        return
    end
    last_target_scan = now
    locked_target = targeting.find_target(cx, cy, fov, PREFIX, find_opts)
end
function M.update(dt)
    bullet_hud.update(dt)
    cached_track.origin = nil
    cached_track.aim = nil
    cached_track.manip = { state = "off" }
    cached_track.tracking = false
    if not active() then
        locked_target = nil
        fire_was_down = false
        shot_allowed = true
        silent_ray.stop()
        body_peek.tick(nil, nil)
        return
    end
    if not silent_ray.ensure_hook() then
        return
    end
    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local use_silent_fov = silent_active()
    local fov = use_silent_fov and settings.num(PREFIX .. "fov", 150) or 99999
    local find_opts = use_silent_fov and {} or { ignore_fov = true }
    if silent_resolve.bypass_visibility() then
        find_opts.ignore_visible = true
    end
    if not holding_weapon() then
        silent_ray.stop()
        if use_silent_fov then
            update_target(cx, cy, fov, find_opts)
        end
        return
    end
    combat_origin.sync_weapon(weapons.cached_held_ranged() or weapons.get_held_ranged_weapon_name())
    update_target(cx, cy, fov, find_opts)
    local wl_target = locked_target
    if not wl_target or not targeting.is_aim_target(wl_target) then
        wl_target = targeting.find_target(cx, cy, fov, PREFIX, {
            ignore_whitelist = true,
            ignore_fov = find_opts.ignore_fov,
            ignore_visible = find_opts.ignore_visible,
        })
    end
    silent_whitelist.tick(wl_target, PREFIX)
    if not locked_target or not targeting.is_aim_target(locked_target) then
        silent_ray.stop()
        body_peek.tick(nil, nil)
        return
    end
    local key_down = input and (input.is_key_down or input.IsKeyDown)
    local firing = key_down and key_down(SHOOT_VK) == true
    if use_silent_fov then
        if firing and not fire_was_down then
            local hit_chance = settings.num(PREFIX .. "hit_chance", 100)
            if hit_chance >= 100 then
                shot_allowed = true
            else
                local roll = math.random(1, 100)
                shot_allowed = roll <= hit_chance
            end
        elseif not firing then
            shot_allowed = true
        end
        fire_was_down = firing and true or false
        if not shot_allowed then
            silent_ray.stop()
            return
        end
    else
        shot_allowed = true
        fire_was_down = false
    end
    local ok_resolve, origin, aim, manip_info = pcall(silent_resolve.resolve_track, locked_target, PREFIX, cx, cy)
    if not ok_resolve or not aim or not origin then
        silent_ray.stop()
        if manip_info then
            cached_track.manip = manip_info
        end
        return
    end
    cached_track.origin = origin
    cached_track.aim = aim
    cached_track.manip = manip_info or { state = "off" }
    local info = cached_track.manip
    local hit = info.hitpart or aim
    local track_aim = aim
    local ok_set = false
    local ok_track = false
    if use_silent_fov then
        if info.use_curve and silent_ray.track_curve then
            ok_track = silent_ray.track_curve(
                origin, hit, info.weapon, SHOOT_VK, hit
            ) == true
            ok_set = silent_ray.last_ok() == true
            if not info.curve_path and silent_ray.last_curve then
                local curve = silent_ray.last_curve()
                if curve and curve.path then
                    info.curve_path = curve.path
                end
            end
        else
            ok_set = silent_ray.set_target(origin, track_aim, hit) == true
            ok_track = silent_ray.track(origin, track_aim, SHOOT_VK, hit) == true
        end
    else
        ok_set = silent_ray.set_target(origin, track_aim, hit) == true
        ok_track = ok_set
    end
    cached_track.aim = track_aim
    cached_track.tracking = ok_set or ok_track
    body_peek.tick(locked_target, hit)
end
function M.get_target()
    return locked_target
end
function M.get_scoped_target()
    if locked_target then return locked_target end
    if not settings.enabled(P_MASTER) then return nil end
    local sw, sh = targeting.screen_center()
    local fov = settings.num(PREFIX .. "fov", 150)
    return targeting.find_target(sw * 0.5, sh * 0.5, fov, PREFIX)
end
local function snapline_aim_point(cx, cy)
    if cached_track.aim then
        return cached_track.aim
    end
    if not locked_target then
        return nil
    end
    local origin = combat_origin.get_camera_origin() or combat_origin.get_fire_origin()
    return targeting.get_aim_point(locked_target, PREFIX, nil, origin, cx, cy, false)
end
function M.draw()
    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num(PREFIX .. "fov", 150)
    if silent_active() and settings.bool(PREFIX .. "draw_fov", false) then
        local col = settings.color(PREFIX .. "draw_fov", { 0.4, 0.9, 1, 1 })
        local filled = settings.num(PREFIX .. "fov_style", 1) == 1
        if filled and draw and draw.circle_filled then
            local fill = settings.color(PREFIX .. "draw_fov", { 0.4, 0.9, 1, 0.12 })
            local c = { fill[1], fill[2], fill[3], (fill[4] or 1) * 0.25 }
            draw.circle_filled(cx, cy, fov, c, 64)
        end
        if draw and draw.circle then
            draw.circle(cx, cy, fov, col, 64, 1)
        else
            draw_util.circle(cx, cy, fov, col, false)
        end
    end
    if settings.bool(P_BULLET, false) then
        bullet_hud.draw(cx, cy, fov, cached_track)
    end
    if silent_active() and locked_target and settings.bool(PREFIX .. "target_line", false) then
        local col = settings.color(PREFIX .. "target_line", { 1, 0.25, 0.25, 1 })
        local aim = snapline_aim_point(cx, cy)
        if aim then
            local tx, ty, vis = w2s(aim.x, aim.y, aim.z)
            if vis then
                local a = col[4] or 1
                draw_util.line(cx, cy, tx, ty, { 0, 0, 0, a * 0.9 }, 3)
                draw_util.line(cx, cy, tx, ty, col, 1.5)
            end
        end
    end
end
return M
end)()

April._mods["features.combat.perfect_farm"] = (function()
local settings = April.require("core.settings")
local env = April.require("core.env")
local farm_tools = April.require("game.farm_tools")
local farm_targets = April.require("game.farm_targets")
local menu_util = April.require("core.menu_util")
local silent_ray = April.require("core.silent_ray")
local M = {}
local P = "april_farm_helper"
local P_RADIUS = "april_farm_radius"
local SHOOT_VK = 0x01
local TARGET_SCAN_MS = 75
local TOOL_CACHE_MS = 150
local SWITCH_MARGIN = 0.35
local locked_target = nil
local locked_tool = nil
local next_target_scan = 0
local cached_tool = nil
local cached_tool_until = 0
local was_enabled = false
M._tracking = false
local function now_ms()
    local fn = utility and (utility.get_tick_count or utility.GetTickCount)
    if type(fn) ~= "function" then return 0 end
    local ok, value = pcall(fn)
    return ok and (tonumber(value) or 0) or 0
end
local function held_tool()
    local now = now_ms()
    if now < cached_tool_until then return cached_tool end
    farm_tools.load()
    cached_tool = farm_tools.get_held_farm_tool_name()
    cached_tool_until = now + TOOL_CACHE_MS
    return cached_tool
end
local function position_of(value)
    if not value then return nil end
    local x, y, z = value.x or value.X, value.y or value.Y, value.z or value.Z
    if x == nil or y == nil or z == nil then return nil end
    return { x = x, y = y, z = z }
end
local function body_origin()
    local player = env.get_local_player()
    local direct = player and position_of(player.position or player.Position)
    if direct then return direct end
    local character = player and (player.character or player.Character)
    if character and env.is_valid(character) then
        local root = env.safe_call(function()
            if character.FindFirstChild then
                return character:FindFirstChild("HumanoidRootPart")
            end
            if character.find_first_child then
                return character:find_first_child("HumanoidRootPart")
            end
        end)
        if root and env.is_valid(root) then
            local pos = position_of(root.Position or root.position)
            if pos then return pos end
        end
    end
    return silent_ray.get_camera_origin()
end
local function radius_for(tool_name)
    local configured = settings.num(P_RADIUS, 7)
    if configured <= 0 then return 0 end
    return math.min(configured, farm_tools.melee_range(tool_name))
end
local function tool_caps(tool_name)
    return farm_tools.tool_caps(tool_name)
        or { Trees = true, Nodes = true, Logs = true, Cactus = true }
end
local function stop_tracking()
    if M._tracking then silent_ray.stop() end
    M._tracking = false
end
local function clear_lock(invalidate_index, reset_tool_cache)
    locked_target = nil
    locked_tool = nil
    next_target_scan = 0
    if reset_tool_cache then
        cached_tool = nil
        cached_tool_until = 0
    end
    stop_tracking()
    if invalidate_index then farm_targets.invalidate() end
end
local function in_range(target, origin, radius)
    if not target or not target.pos or not origin then return false end
    return farm_targets.distance2(target.pos, origin) <= radius * radius
end
local function choose_target(origin, radius, caps)
    local candidate = farm_targets.find_target(origin, radius, caps)
    local current = farm_targets.resolve(locked_target)
    if current and not in_range(current, origin, radius) then
        current = nil
    end
    if not candidate then return current end
    if not current or candidate.model == current.model or candidate.key == current.key then
        return candidate
    end
    local current_d = math.sqrt(farm_targets.distance2(current.pos, origin))
    local candidate_d = math.sqrt(farm_targets.distance2(candidate.pos, origin))
    if candidate_d + SWITCH_MARGIN < current_d then
        return candidate
    end
    return current
end
function M.register_menu()
    local G = menu_util.G
    local T = menu_util.group(G.MISC)
    local root = menu_util.parent(P)
    menu_util.section(T, G.MISC, "Farm")
    menu_util.register_keybind(T, G.MISC, P, "Farm Helper", false)
    menu.add_slider_int(T, G.MISC, P_RADIUS, "Farm Range (studs)", 1, 10, 7, root)
    menu_util.bind_children(P, { P_RADIUS })
end
function M.update(_dt)
    if settings.enabled("april_autofarm") then
        if was_enabled then clear_lock(true, true) end
        was_enabled = false
        return
    end
    if not settings.enabled(P) then
        if was_enabled then clear_lock(true, true) end
        was_enabled = false
        return
    end
    was_enabled = true
    local tool_name = held_tool()
    if not tool_name then
        clear_lock(false)
        return
    end
    if locked_tool and locked_tool ~= tool_name then
        locked_target = nil
        next_target_scan = 0
        stop_tracking()
    end
    locked_tool = tool_name
    if not silent_ray.available() then
        clear_lock(false)
        return
    end
    local origin = body_origin()
    local camera_origin = silent_ray.get_camera_origin()
    local radius = radius_for(tool_name)
    if not origin or not camera_origin or radius <= 0 then
        clear_lock(false)
        return
    end
    locked_target = farm_targets.resolve(locked_target)
    local now = now_ms()
    if now >= next_target_scan or not locked_target then
        next_target_scan = now + TARGET_SCAN_MS
        locked_target = choose_target(origin, radius, tool_caps(tool_name))
    end
    if not locked_target or not in_range(locked_target, origin, radius) then
        locked_target = nil
        stop_tracking()
        return
    end
    M._tracking = silent_ray.track(
        camera_origin,
        locked_target.pos,
        SHOOT_VK,
        locked_target.pos
    ) == true
    if not M._tracking then silent_ray.stop() end
end
function M.get_target()
    return locked_target
end
return M
end)()

April._mods["features.utility.autofarm"] = (function()
local settings = April.require("core.settings")
local env = April.require("core.env")
local farm_tools = April.require("game.farm_tools")
local farm_targets = April.require("game.farm_targets")
local silent_ray = April.require("core.silent_ray")
local menu_util = April.require("core.menu_util")
local esp_util = April.require("core.esp_util")
local draw_util = April.require("core.draw_util")
local theme = April.require("core.ui_theme")
local debug_log = April.require("core.debug")
local M = {}
local P = "april_autofarm"
local P_RESOURCES = P .. "_resources"
local P_SEARCH = P .. "_search_range"
local P_DEBUG = P .. "_debug_path"
local VK = {
LMB = 0x01,
SHIFT = 0x10,
SPACE = 0x20,
W = 0x57,
A = 0x41,
C = 0x43,
D = 0x44,
}
local SCAN_MS = 250
local TOOL_MS = 150
local MOVE_SAMPLE_MS = 900
local RECOVER_MS = 650
local SKIP_MS = 10000
local NO_PROGRESS_MS = 20000
local AIM_DOT = { approach = 0.78, body = 0.90, weak = 0.96 }
local PHASE = {
IDLE = "Idle",
SCAN = "Scan",
APPROACH = "Approach",
PRIME = "Prime",
HARVEST = "Harvest",
RECOVER = "Recover",
DONE = "Done",
}
local phase = PHASE.IDLE
local phase_reason = nil
local target = nil
local target_tool = nil
local held_tool = nil
local tool_until = 0
local next_scan = 0
local next_swing = 0
local skipped = {}
local injected = {}
local custom_menu_ref = nil
local active_aim = nil
local distance = nil
local target_started = false
local harvest_confirmed = false
local body_only = false
local weak_retry_at = 0
local recover_attempts = 0
local recover_until = 0
local recover_side = VK.A
local move_sample_at = 0
local move_sample_pos = nil
local align_since = 0
local last_progress_at = 0
local last_health = nil
local last_state = nil
local last_weak_key = nil
local last_weak_pos = nil
local weak_mode_since = 0
local weak_swings = 0
local total_swings = 0
local input_failures = 0
local input_failure_at = 0
local was_enabled = false
local function event(message)
debug_log.force_event(tostring(message))
end
local function set_phase(next_phase, reason)
if phase ~= next_phase or phase_reason ~= reason then
phase = next_phase
phase_reason = reason
event("phase=" .. tostring(next_phase) .. " reason=" .. tostring(reason or "none"))
end
end
local function now_ms()
local fn = utility and (utility.get_tick_count or utility.GetTickCount)
if type(fn) ~= "function" then return 0 end
local ok, value = pcall(fn)
return ok and (tonumber(value) or 0) or 0
end
local function xyz(value)
if not value then return nil end
local x, y, z = value.x or value.X, value.y or value.Y, value.z or value.Z
if x == nil or y == nil or z == nil then return nil end
return { x = x, y = y, z = z }
end
local function body_origin()
local player = env.get_local_player()
local direct = player and xyz(player.Position or player.position)
if direct then return direct end
local character = player and (player.Character or player.character)
if not character or not env.is_valid(character) then return nil end
local root = env.safe_call(function()
if character.FindFirstChild then return character:FindFirstChild("HumanoidRootPart") end
if character.find_first_child then return character:find_first_child("HumanoidRootPart") end
end)
return root and xyz(root.Position or root.position) or nil
end
local function flat_distance(a, b)
if not a or not b then return math.huge end
local dx, dz = a.x - b.x, a.z - b.z
return math.sqrt(dx * dx + dz * dz)
end
local function distance3(a, b)
if not a or not b then return math.huge end
local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
return math.sqrt(dx * dx + dy * dy + dz * dz)
end
local function part_surface_distance3(point, part, center)
if not point or not center then return math.huge end
local size
if part then
pcall(function() size = part.Size or part.size end)
end
size = xyz(size)
if not size then return distance3(point, center) end
local dx = math.max(0, math.abs(point.x - center.x) - size.x * 0.5)
local dy = math.max(0, math.abs(point.y - center.y) - size.y * 0.5)
local dz = math.max(0, math.abs(point.z - center.z) - size.z * 0.5)
return math.sqrt(dx * dx + dy * dy + dz * dz)
end
local function movement_api(name, pascal)
return utility and (utility[name] or utility[pascal]) or nil
end
local function set_key(vk, down)
if injected[vk] == down then return true end
local fn = down and movement_api("key_down", "KeyDown") or movement_api("key_up", "KeyUp")
if type(fn) ~= "function" then return false end
local ok = pcall(fn, vk)
if ok then injected[vk] = down end
return ok
end
local function release_movement_keys()
set_key(VK.SHIFT, false)
set_key(VK.SPACE, false)
set_key(VK.W, false)
set_key(VK.A, false)
set_key(VK.D, false)
end
local function release_keys()
release_movement_keys()
set_key(VK.C, false)
end
local function has_injected_key()
return injected[VK.SHIFT] == true or injected[VK.SPACE] == true
or injected[VK.W] == true or injected[VK.A] == true
or injected[VK.C] == true or injected[VK.D] == true
end
local function stop_silent()
silent_ray.stop()
end
local function track_silent_farm(camera_pos, aim_pos)
local set_ok = silent_ray.set_target(camera_pos, aim_pos, aim_pos)
local track_ok = silent_ray.track(camera_pos, aim_pos, VK.LMB, aim_pos)
return set_ok or track_ok
end
local function reset_lock()
target = nil
target_tool = nil
active_aim = nil
distance = nil
target_started = false
harvest_confirmed = false
body_only = false
weak_retry_at = 0
recover_attempts = 0
recover_until = 0
move_sample_at = 0
move_sample_pos = nil
align_since = 0
last_progress_at = 0
last_health = nil
last_state = nil
last_weak_key = nil
last_weak_pos = nil
weak_mode_since = 0
weak_swings = 0
total_swings = 0
input_failures = 0
input_failure_at = 0
next_swing = 0
release_keys()
stop_silent()
end
local function cleanup(reason)
reset_lock()
set_phase(PHASE.IDLE, reason)
end
local function ensure_idle(reason)
if target or phase ~= PHASE.IDLE or has_injected_key() then
cleanup(reason)
else
set_phase(PHASE.IDLE, reason)
end
end
local function finish_target(now, reason, should_skip)
local key = target and target.key
if should_skip == "permanent" and key then
skipped[key] = math.huge
elseif should_skip and key then
skipped[key] = now + SKIP_MS
end
event("target_done reason=" .. tostring(reason) .. " key=" .. tostring(key))
reset_lock()
set_phase(PHASE.DONE, reason)
end
local function menu_open()
return custom_menu_ref and custom_menu_ref.is_open and custom_menu_ref.is_open() == true
end
local function selected_resources()
return {
Trees = settings.multi(P_RESOURCES, 1, true),
Stone = settings.multi(P_RESOURCES, 2, true),
Metal = settings.multi(P_RESOURCES, 3, true),
Phosphate = settings.multi(P_RESOURCES, 4, true),
}
end
local function any_selected(allowed)
return allowed.Trees or allowed.Stone or allowed.Metal or allowed.Phosphate
end
local function current_tool(now)
if now < tool_until then return held_tool end
farm_tools.load()
held_tool = farm_tools.get_held_farm_tool_name()
tool_until = now + TOOL_MS
return held_tool
end
local function clean_skips(now)
for key, expires in pairs(skipped) do
if now >= expires then skipped[key] = nil end
end
end
local function acquire(now, origin, tool_name, allowed)
if now < next_scan then return nil end
next_scan = now + SCAN_MS
clean_skips(now)
return farm_targets.find_target(
origin,
math.max(25, settings.num(P_SEARCH, 500)),
farm_tools.tool_caps(tool_name),
{ allowed = allowed, skip_keys = skipped, check_visibility = false }
)
end
local function lock_target(record, now, origin, tool_name, reason)
release_keys()
stop_silent()
target = record
target_tool = tool_name
active_aim = nil
distance = nil
target_started = false
harvest_confirmed = false
body_only = false
weak_retry_at = 0
record.autofarm_locked_at = now
record.autofarm_settle_until = 0
record.autofarm_heading_x = nil
record.autofarm_heading_z = nil
record.autofarm_range_penalty = 0
record.autofarm_body_retries = 0
record.autofarm_prime_attempts = 0
record.autofarm_prime_swing_at = 0
recover_attempts = 0
recover_until = 0
align_since = 0
last_health = record.health
last_state = record.resource_state
last_weak_key = record.weak_key
last_weak_pos = record.weak_pos
last_progress_at = now
weak_mode_since = 0
weak_swings = 0
total_swings = 0
input_failures = 0
input_failure_at = 0
next_swing = 0
move_sample_at, move_sample_pos = now, origin
event("target_lock key=" .. tostring(record.key)
.. " resource=" .. tostring(record.resource_type)
.. " reason=" .. tostring(reason))
set_phase(PHASE.APPROACH, reason)
end
local function look_at(point, smooth)
local fn = camera and (camera.look_at or camera.LookAt)
if type(fn) ~= "function" or not point then return false end
return pcall(fn, point.x, point.y, point.z, smooth or 1)
end
local function alignment(camera_pos, point)
local fn = camera and (camera.get_look_vector or camera.GetLookVector)
if type(fn) ~= "function" then return 0 end
local ok, look = pcall(fn)
look = ok and xyz(look) or nil
if not look then return 0 end
local dx, dy, dz = point.x - camera_pos.x, point.y - camera_pos.y, point.z - camera_pos.z
local len = math.sqrt(dx * dx + dy * dy + dz * dz)
local llen = math.sqrt(look.x * look.x + look.y * look.y + look.z * look.z)
if len < 0.001 or llen < 0.001 then return 0 end
return (look.x * dx + look.y * dy + look.z * dz) / (len * llen)
end
local function body_aim(record, camera_pos)
local center = record and record.body_pos
local part = record and record.body_part
if not center then return nil end
local point = { x = center.x, y = center.y, z = center.z }
if (record.kind == "Trees" or record.kind == "Nodes") and camera_pos then
local size = part and (part.Size or part.size)
local sy = size and tonumber(size.Y or size.y) or 0
if sy > 0 then
local low = center.y - sy * 0.5 + 0.2
local high = center.y + sy * 0.5 - 0.2
point.y = math.max(low, math.min(high, camera_pos.y))
elseif record.kind == "Trees" then
point.y = camera_pos.y
end
end
return point
end
local function navigation_aim(record, camera_pos)
local body = record and record.body_pos
if not body then return nil end
if record.kind == "Trees" then
return { x = body.x, y = camera_pos.y, z = body.z }
end
return { x = body.x, y = body.y, z = body.z }
end
local function stable_node_aim(record, point, camera_pos, clamp_pitch)
if not record or not point or not camera_pos then return point end
local dx, dz = point.x - camera_pos.x, point.z - camera_pos.z
local horizontal = math.sqrt(dx * dx + dz * dz)
if horizontal > 0.75 then
record.autofarm_heading_x = dx / horizontal
record.autofarm_heading_z = dz / horizontal
end
local hx = record.autofarm_heading_x or 0
local hz = record.autofarm_heading_z or 1
local view_distance = math.max(horizontal, 2.5)
local y = camera_pos.y
if clamp_pitch then
y = math.max(point.y, camera_pos.y - view_distance * 1.25)
end
return {
x = camera_pos.x + hx * view_distance,
y = y,
z = camera_pos.z + hz * view_distance,
}
end
local function approach_aim(record, camera_pos)
if not body_only and record and record.weak_pos then
if record.kind == "Nodes" and camera_pos then
return stable_node_aim(record, record.weak_pos, camera_pos, false)
end
return record.weak_pos
end
return navigation_aim(record, camera_pos)
end
local function click_left()
local fn = movement_api("mouse_click", "MouseClick")
return type(fn) == "function" and pcall(fn, "left") or false
end
local function record_progress(now, reason)
harvest_confirmed = true
last_progress_at = now
weak_mode_since = now
weak_swings = 0
if target then
target.autofarm_range_penalty = 0
target.autofarm_body_retries = 0
target.autofarm_prime_attempts = 0
end
event("progress=" .. tostring(reason) .. " health=" .. tostring(target and target.health))
end
local function position_changed(a, b)
return a and b and distance3(a, b) > 0.08
end
local function refresh_progress(now)
if not target then return end
local health = target.health
if health and last_health and health < last_health - 0.0001 then
record_progress(now, "health")
elseif last_health == nil and health ~= nil then
last_health = health
end
if target.resource_state and last_state and target.resource_state ~= last_state then
record_progress(now, "state")
end
if target.weak_key and not last_weak_key and target_started then
record_progress(now, "marker_spawn")
elseif target.weak_key and last_weak_key
and target.weak_key ~= last_weak_key and target_started
then
record_progress(now, "marker_replace")
elseif target.weak_key and target.weak_key == last_weak_key
and position_changed(target.weak_pos, last_weak_pos)
then
record_progress(now, "marker_move")
end
last_health = health or last_health
last_state = target.resource_state or last_state
last_weak_key = target.weak_key
last_weak_pos = target.weak_pos and {
x = target.weak_pos.x, y = target.weak_pos.y, z = target.weak_pos.z,
} or nil
end
local function begin_recovery(now, reason)
recover_attempts = recover_attempts + 1
local limit = harvest_confirmed and 5 or 3
if recover_attempts > limit then
if target_started then
body_only = true
weak_retry_at = now + 2500
recover_attempts = 0
release_movement_keys()
stop_silent()
set_phase(PHASE.HARVEST, "recovery_body_fallback")
else
finish_target(now, "recovery_exhausted", true)
end
return
end
body_only = target_started
if body_only then weak_retry_at = now + 2500 end
recover_side = recover_attempts % 2 == 1 and VK.A or VK.D
recover_until = now + RECOVER_MS
stop_silent()
set_key(VK.W, true)
set_key(VK.A, recover_side == VK.A)
set_key(VK.D, recover_side == VK.D)
set_phase(PHASE.RECOVER, reason)
end
local function update_movement_progress(now, origin)
if move_sample_at == 0 then
move_sample_at, move_sample_pos = now, origin
return
end
if now - move_sample_at < MOVE_SAMPLE_MS then return end
local moved = flat_distance(origin, move_sample_pos)
move_sample_at, move_sample_pos = now, origin
if moved < 0.35 then begin_recovery(now, "stuck") end
end
local function live_tool_matches(tool_name)
return farm_tools.get_held_farm_tool_name() == tool_name
end
local function swing(now, tool_name, weak)
if now < next_swing then return nil end
if not live_tool_matches(tool_name) then
tool_until = 0
finish_target(now, "tool_changed", false)
return false
end
if click_left() then
input_failures = 0
input_failure_at = 0
target_started = true
total_swings = total_swings + 1
if weak then weak_swings = weak_swings + 1 end
next_swing = now + math.floor(farm_tools.swing_cooldown(tool_name) * 1000 + 60)
event(string.format(
"swing=%d mode=%s resource=%s dist=%.2f",
total_swings, weak and "weak" or "body",
tostring(target and target.resource_type), distance or -1
))
return true
else
input_failures = input_failures + 1
if input_failure_at == 0 then input_failure_at = now end
next_swing = now + 500
event("swing_failed=input count=" .. tostring(input_failures))
if input_failures >= 3 or now - input_failure_at >= 3000 then
input_failures = 0
input_failure_at = now
next_swing = now + 1000
end
return false
end
end
local function update_impl()
local enabled = settings.enabled(P)
if not enabled then
if was_enabled or has_injected_key() then cleanup("disabled") end
was_enabled = false
return
end
was_enabled = true
if menu_open() then
ensure_idle("menu_open")
return
end
if phase == PHASE.IDLE and has_injected_key() then
release_keys()
if has_injected_key() then return end
end
local now = now_ms()
local origin = body_origin()
if not origin then
ensure_idle("no_character")
return
end
local tool_name = current_tool(now)
if not tool_name then
ensure_idle("no_tool")
return
end
local allowed = selected_resources()
if not any_selected(allowed) then
ensure_idle("no_resource_types")
return
end
if phase == PHASE.IDLE or phase == PHASE.DONE then
set_phase(PHASE.SCAN, "ready")
end
if phase == PHASE.SCAN then
stop_silent()
local candidate = acquire(now, origin, tool_name, allowed)
if not candidate then return end
lock_target(candidate, now, origin, tool_name, "target_locked")
end
if target_tool ~= tool_name then
finish_target(now, "tool_changed", false)
return
end
target = farm_targets.resolve(target)
if not target then
farm_targets.invalidate()
finish_target(now, "depleted_or_removed", false)
return
end
refresh_progress(now)
if target.weak_pos and (not body_only or now >= weak_retry_at) then
body_only = false
weak_retry_at = 0
end
if phase == PHASE.PRIME and target_started and harvest_confirmed then
set_phase(PHASE.HARVEST, "prime_confirmed")
end
if (target.autofarm_locked_at or 0) > 0
and now - target.autofarm_locked_at >= 120000
then
finish_target(now, "target_timeout", "permanent")
return
end
if phase == PHASE.APPROACH and not target_started then
local candidate = acquire(now, origin, tool_name, allowed)
if candidate and candidate.key ~= target.key then
local current_d = math.sqrt(farm_targets.surface_distance2(target, origin))
local candidate_d = math.sqrt(farm_targets.surface_distance2(candidate, origin))
if candidate_d + 0.15 < current_d then
lock_target(candidate, now, origin, tool_name, "closer_target")
end
end
end
local range = farm_tools.melee_range(tool_name)
local body_surface_distance = math.sqrt(farm_targets.surface_distance2(target, origin))
local should_crouch = target.kind == "Nodes"
and (target_started or body_surface_distance <= range + 4)
set_key(VK.C, should_crouch)
local should_jump = (phase == PHASE.APPROACH or phase == PHASE.RECOVER)
and target.body_pos ~= nil
and target.body_pos.y > origin.y + 1.5
set_key(VK.SPACE, should_jump)
local camera_pos = silent_ray.get_camera_origin()
if not camera_pos then
cleanup("no_camera")
return
end
local pursuing_weak = not body_only and target.weak_pos ~= nil
local boulder = tool_name == "Boulder"
local ray_budget = math.max(2, range - 0.55)
local range_penalty = tonumber(target.autofarm_range_penalty) or 0
local initial_close = harvest_confirmed and 0 or 0.3
local enter_range
local exit_range
if pursuing_weak then
if boulder then
enter_range = math.max(1.25, range - 0.2 - range_penalty - initial_close)
exit_range = enter_range + 0.4
distance = distance3(camera_pos, target.weak_pos)
else
enter_range = math.max(1.25, ray_budget - range_penalty - initial_close)
exit_range = enter_range + 0.45
distance = distance3(camera_pos, target.weak_pos)
end
else
local range_aim = body_aim(target, camera_pos)
enter_range = math.max(1.25, ray_budget - range_penalty - initial_close)
exit_range = enter_range + 0.45
distance = part_surface_distance3(camera_pos, target.body_part, range_aim)
end
if phase == PHASE.RECOVER then
stop_silent()
active_aim = approach_aim(target, camera_pos)
look_at(active_aim, 3)
if now < recover_until then return end
release_movement_keys()
move_sample_at, move_sample_pos = now, origin
set_phase(PHASE.APPROACH, "recovery_complete")
end
if phase == PHASE.APPROACH then
stop_silent()
set_key(VK.SHIFT, true)
active_aim = approach_aim(target, camera_pos)
if distance <= enter_range then
release_movement_keys()
stop_silent()
align_since = 0
target.autofarm_settle_until = target.kind == "Nodes" and now + 300 or now
set_phase(target_started and target.weak_pos and PHASE.HARVEST or PHASE.PRIME, "in_range")
return
else
if not look_at(active_aim, 3) then
begin_recovery(now, "approach_look_failed")
return
end
if alignment(camera_pos, active_aim) >= AIM_DOT.approach then
align_since = 0
set_key(VK.A, false)
set_key(VK.D, false)
if not set_key(VK.W, true) then
finish_target(now, "movement_api_unavailable", true)
return
end
update_movement_progress(now, origin)
else
set_key(VK.W, false)
if align_since == 0 then align_since = now end
if now - align_since > 1500 then
align_since = 0
begin_recovery(now, "approach_alignment")
end
end
return
end
end
if phase == PHASE.PRIME then
if now < (target.autofarm_settle_until or 0) then return end
if target_started and not target.weak_pos
and (target.autofarm_prime_swing_at or 0) > 0
then
if now - target.autofarm_prime_swing_at < 350 then
return
end
target.autofarm_prime_swing_at = 0
target.autofarm_range_penalty = math.min(
math.max(0, range - 1.25),
(tonumber(target.autofarm_range_penalty) or 0) + 0.3
)
stop_silent()
move_sample_at, move_sample_pos = now, origin
set_phase(PHASE.APPROACH, "prime_no_marker_close")
return
end
local prime_weak = target.weak_pos ~= nil
active_aim = prime_weak and target.weak_pos or body_aim(target, camera_pos)
local prime_view = prime_weak and target.kind == "Nodes"
and stable_node_aim(target, active_aim, camera_pos, true) or active_aim
release_movement_keys()
if not look_at(prime_view, 1) then
begin_recovery(now, "prime_look_failed")
return
end
if alignment(camera_pos, prime_view) < (prime_weak and AIM_DOT.weak or AIM_DOT.body) then
if align_since == 0 then align_since = now end
if now - align_since > 1200 then
align_since = 0
begin_recovery(now, "prime_alignment")
end
return
end
align_since = 0
if not track_silent_farm(camera_pos, active_aim) then
finish_target(now, "silent_unavailable", true)
return
end
if now >= next_swing then
local clicked = swing(now, tool_name, prime_weak)
if clicked and target then
weak_mode_since = now
if prime_weak then
set_phase(PHASE.HARVEST, "weak_primed")
else
local attempts = (tonumber(target.autofarm_prime_attempts) or 0) + 1
target.autofarm_prime_attempts = attempts
target.autofarm_prime_swing_at = now
if attempts >= 2 then
target.autofarm_prime_attempts = 0
target.autofarm_range_penalty = math.min(
math.max(0, range - 1.25),
(tonumber(target.autofarm_range_penalty) or 0) + 0.3
)
stop_silent()
move_sample_at, move_sample_pos = now, origin
set_phase(PHASE.APPROACH, "prime_unconfirmed_close")
else
set_phase(PHASE.PRIME, "body_prime_wait")
end
end
end
end
return
end
if phase ~= PHASE.HARVEST then return end
if now < (target.autofarm_settle_until or 0) then return end
if distance > exit_range then
release_movement_keys()
stop_silent()
move_sample_at, move_sample_pos = now, origin
set_phase(PHASE.APPROACH, "outside_range")
return
end
if total_swings >= 8 and now - last_progress_at > NO_PROGRESS_MS then
body_only = target.weak_pos == nil
weak_retry_at = now + 2500
weak_swings = 0
weak_mode_since = now
last_progress_at = now
end
if body_only and target.weak_pos and now >= weak_retry_at then
body_only = false
weak_swings = 0
weak_mode_since = now
end
local use_weak = not body_only and target.weak_pos ~= nil
if not use_weak and total_swings >= 2
and now - last_progress_at > (boulder and 2400 or 4000)
then
local retries = (tonumber(target.autofarm_body_retries) or 0) + 1
target.autofarm_body_retries = retries
if retries >= 4 then
finish_target(now, "body_no_progress", true)
return
end
local step = boulder and 0.55 or 0.35
target.autofarm_range_penalty = math.min(
math.max(0, range - 1.25),
(tonumber(target.autofarm_range_penalty) or 0) + step
)
last_progress_at = now
stop_silent()
move_sample_at, move_sample_pos = now, origin
set_phase(PHASE.APPROACH, "body_no_progress_close")
return
end
local weak_fail_swings = boulder and 3 or 2
local weak_fail_ms = boulder and 4000 or 2500
if use_weak and weak_swings >= weak_fail_swings
and now - weak_mode_since > weak_fail_ms
then
weak_swings = 0
weak_mode_since = now
begin_recovery(now, "weak_no_progress")
return
end
active_aim = use_weak and target.weak_pos or body_aim(target, camera_pos)
local view_aim = use_weak and target.kind == "Nodes"
and stable_node_aim(target, active_aim, camera_pos, true) or active_aim
release_movement_keys()
if not look_at(view_aim, 1) then
stop_silent()
if use_weak then
begin_recovery(now, "weak_look_failed")
else
begin_recovery(now, "body_look_failed")
end
return
end
local required_dot = use_weak and AIM_DOT.weak or AIM_DOT.body
if alignment(camera_pos, view_aim) < required_dot then
stop_silent()
if align_since == 0 then align_since = now end
if use_weak and now - align_since > 1200 then
align_since = 0
begin_recovery(now, "weak_alignment")
elseif not use_weak and now - align_since > 1200 then
align_since = 0
begin_recovery(now, "body_alignment")
end
return
end
align_since = 0
if not track_silent_farm(camera_pos, active_aim) then
finish_target(now, "silent_unavailable", true)
return
end
swing(now, tool_name, use_weak)
end
function M.register_menu()
pcall(function() custom_menu_ref = April.require("ui.custom_menu") end)
local G = menu_util.G
local T = menu_util.group(G.MISC)
local root = menu_util.parent(P)
menu_util.section(T, G.MISC, "Autofarm")
menu_util.register_keybind(T, G.MISC, P, "Autofarm", false)
menu.add_multicombo(T, G.MISC, P_RESOURCES, "Farm Resources", {
"Trees", "Stone", "Metal", "Phosphate",
}, { true, true, true, true }, root)
menu.add_slider_int(T, G.MISC, P_SEARCH, "Search Range", 50, 2000, 500, root)
menu.add_checkbox(T, G.MISC, P_DEBUG, "Debug Target Path", false, root)
menu_util.bind_children(P, { P_RESOURCES, P_SEARCH, P_DEBUG })
end
function M.update()
local ok, err = pcall(update_impl)
if ok then return end
event("ERROR " .. tostring(err))
cleanup("lua_error")
error(err)
end
function M.draw()
if not settings.bool(P_DEBUG, false) or not settings.enabled(P) then return end
local sw, sh = draw_util.screen_size()
local col = theme.CYAN or { 0.25, 0.9, 1, 1 }
if active_aim then
local tx, ty, on_screen = esp_util.w2s(active_aim.x, active_aim.y, active_aim.z)
if on_screen then
draw_util.snapline(tx, ty, col, 1.5, sw, sh)
draw_util.circle(tx, ty, 7, col, false)
end
end
local text = tostring(phase)
if phase_reason then text = text .. " (" .. tostring(phase_reason) .. ")" end
if target then text = text .. " | " .. tostring(target.resource_type) end
if body_only then text = text .. " | body fallback" end
if distance then text = text .. string.format(" | %.1f studs", distance) end
if held_tool then text = text .. " | " .. tostring(held_tool) end
draw_util.text_centered(sw * 0.5, sh - 72, text, col, 12)
end
function M.get_target()
return target
end
function M.is_active()
return settings.enabled(P)
end
return M
end)()

April._mods["features.combat.gun_mods"] = (function()
local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local profiles = April.require("game.gun_mod_profiles")
local gc = April.require("game.gc_weapon_mods")
local toolinfo_mods = April.require("game.toolinfo_weapon_mods")
local env = April.require("core.env")
local notify = April.require("core.notify")
local M = {}
local P = "april_gunmods_enabled"
local REJOIN_GC_DELAY_MS = 25000
local RETRY_MS = 1200
local RETRY_MAX_MS = 15000
local MIN_SCHEDULE_MS = 450
local STARTUP_DELAY_MS = 3500
M._apply_dirty = false
M._force_apply = false
M._defer_until = 0
M._retry_until = 0
M._session_id = nil
M._was_in_match = false
M._gc_redo_at = 0
M._notify_next = false
M._last_held_apply = nil
M._had_applied_mods = false
M._last_applied_keys = nil
M._toolinfo_dirty = false
M._boot_ms = nil
local MODIFIER_TOGGLES = {
    "april_gm_recoil",
    "april_gm_spread",
    "april_gm_sway",
    "april_gm_fire_rate",
    "april_gm_speed",
    "april_gm_range",
    "april_gm_double_tap",
}
local function tick_ms()
    if M._boot_ms == nil then
        M._boot_ms = utility and utility.get_tick_count and utility.get_tick_count() or 0
    end
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end
local function in_match()
    return env.get_local_player() ~= nil
end
local function session_id()
    if not game then return "none" end
    local pid = game.place_id or 0
    local gid = game.game_id or 0
    local ws = game.workspace
    local ws_addr = (ws and (ws.Address or ws.address)) or 0
    return pid .. ":" .. gid .. ":" .. ws_addr
end
local function startup_ready()
    local now = tick_ms()
    return M._boot_ms and (now - M._boot_ms) >= STARTUP_DELAY_MS
end
local function can_apply_now()
    if not settings.enabled(P) then return false end
    if not startup_ready() then return false end
    if not gc.available() then return false end
    if gc.cooldown_remaining_ms() > 0 then return false end
    if not in_match() then return false end
    if not profiles.held_weapon_name() then return false end
    return true
end
local function schedule_apply(delay_ms)
    if not settings.enabled(P) then return end
    M._apply_dirty = true
    M._force_apply = true
    local now = tick_ms()
    local wait = math.max(MIN_SCHEDULE_MS, delay_ms or 500)
    local until_ms = now + wait
    if until_ms > M._defer_until then
        M._defer_until = until_ms
    end
    if M._retry_until <= now then
        M._retry_until = now + RETRY_MAX_MS
    end
end
local function clear_apply_state()
    M._apply_dirty = false
    M._force_apply = false
    M._defer_until = 0
    M._retry_until = 0
    M._gc_redo_at = 0
    M._last_held_apply = nil
    M._had_applied_mods = false
    M._last_applied_keys = nil
    M._toolinfo_dirty = false
end
local function build_clear_payload()
    local keys = M._last_applied_keys
    if not keys or not next(keys) then
        return nil
    end
    local out = {}
    for k in pairs(keys) do
        out[k] = 0
    end
    return out
end
local function remember_applied(mods)
    local keys = {}
    if type(mods) == "table" then
        for k in pairs(mods) do
            keys[k] = true
        end
    end
    M._last_applied_keys = keys
end
local function schedule_session_gc_refresh()
    if not settings.enabled(P) then return end
    M._apply_dirty = true
    M._force_apply = true
    M._gc_redo_at = tick_ms() + REJOIN_GC_DELAY_MS
    M._retry_until = tick_ms() + RETRY_MAX_MS
    M._defer_until = tick_ms() + REJOIN_GC_DELAY_MS
    toolinfo_mods.invalidate()
end
local function clear_all_mods()
    pcall(function()
        local clear = build_clear_payload()
        if clear then gc.apply_weapon(clear) end
    end)
    pcall(toolinfo_mods.reset)
    M._had_applied_mods = false
    M._last_applied_keys = nil
end
function M.schedule_apply(delay_ms)
    schedule_apply(delay_ms)
end
function M.on_session_changed()
    schedule_session_gc_refresh()
end
function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.GUN_MODS)
    local root = menu_util.parent(P)
    menu_util.register_keybind(T, G.GUN_MODS, P, "Enable Gun Mods", false)
    menu_util.section(T, G.GUN_MODS, "Modifiers")
    menu.add_checkbox(T, G.GUN_MODS, "april_gm_recoil", "No Recoil", false, root)
    menu.add_slider_int(T, G.GUN_MODS, "april_gm_recoil_pct", "Recoil Reduction %", 0, 100, 100,
        menu_util.parent("april_gm_recoil"))
    menu.add_checkbox(T, G.GUN_MODS, "april_gm_spread", "No Spread", false, root)
    menu.add_slider_int(T, G.GUN_MODS, "april_gm_spread_pct", "Spread Reduction %", 0, 100, 100,
        menu_util.parent("april_gm_spread"))
    menu.add_checkbox(T, G.GUN_MODS, "april_gm_sway", "No Sway", false, root)
    menu.add_checkbox(T, G.GUN_MODS, "april_gm_fire_rate", "Fire Rate", false, root)
    menu.add_slider_float(T, G.GUN_MODS, "april_gm_fire_rate_mult", "Fire Rate Multiplier", 1.0, 3.0, 1.5, "%.2f",
        menu_util.parent("april_gm_fire_rate"))
    menu.add_checkbox(T, G.GUN_MODS, "april_gm_speed", "Bullet Speed", false, root)
    menu.add_slider_int(T, G.GUN_MODS, "april_gm_speed_mult", "Speed Mult", 1, 100, 100,
        menu_util.parent("april_gm_speed"))
    menu.add_checkbox(T, G.GUN_MODS, "april_gm_range", "Gun Range", false, root)
    menu.add_slider_int(T, G.GUN_MODS, "april_gm_range_mult", "Range Mult", 1, 20, 10,
        menu_util.parent("april_gm_range"))
    menu.add_checkbox(T, G.GUN_MODS, "april_gm_double_tap", "Double Tap", false, root)
    menu_util.bind_children(P, {
        "april_gm_recoil", "april_gm_recoil_pct",
        "april_gm_spread", "april_gm_spread_pct",
        "april_gm_sway",
        "april_gm_fire_rate", "april_gm_fire_rate_mult",
        "april_gm_speed", "april_gm_speed_mult",
        "april_gm_range", "april_gm_range_mult",
        "april_gm_double_tap",
    })
    menu_util.bind_children("april_gm_recoil", { "april_gm_recoil_pct" })
    menu_util.bind_children("april_gm_spread", { "april_gm_spread_pct" })
    menu_util.bind_children("april_gm_fire_rate", { "april_gm_fire_rate_mult" })
    menu_util.bind_children("april_gm_speed", { "april_gm_speed_mult" })
    menu_util.bind_children("april_gm_range", { "april_gm_range_mult" })
    settings.on_change(P, function()
        if settings.enabled(P) then
            M._notify_next = true
            schedule_apply(800)
        else
            clear_apply_state()
            M.reset_mods()
        end
    end)
    for _, id in ipairs(MODIFIER_TOGGLES) do
        settings.on_change(id, function()
            if settings.enabled(P) then
                M._notify_next = true
                schedule_apply(500)
            end
        end)
    end
    local slider_ids = {
        "april_gm_recoil_pct", "april_gm_spread_pct",
        "april_gm_fire_rate_mult", "april_gm_speed_mult", "april_gm_range_mult",
    }
    for _, id in ipairs(slider_ids) do
        settings.on_change(id, function()
            if settings.enabled(P) then
                schedule_apply(1000)
            end
        end)
    end
end
function M.reset_mods()
    pcall(toolinfo_mods.reset)
    if not gc.available() then
        notify.info("Gun mods disabled", 3000)
        return true
    end
    local mods = build_clear_payload()
    if not mods then
        M._had_applied_mods = false
        notify.info("Gun mods cleared", 3000)
        return true
    end
    local ok, count, msg = gc.apply_weapon(mods)
    if ok then
        M._had_applied_mods = false
        M._last_applied_keys = nil
        notify.info("Gun mods reset (" .. tostring(count) .. " nodes)", 3500)
    else
        notify.warning("Gun mods reset: " .. tostring(msg or "failed"), 4000)
    end
    return ok
end
function M.try_apply(silent)
    if not settings.enabled(P) then
        return false
    end
    local held = profiles.held_weapon_name()
    local needs_gc = M._apply_dirty or M._force_apply
    local needs_ti = M._toolinfo_dirty
    if not needs_gc and not needs_ti then
        if M._had_applied_mods and not in_match() then
            clear_all_mods()
        end
        return M._had_applied_mods
    end
    if needs_gc and not can_apply_now() then
        if M._had_applied_mods and not in_match() then
            clear_all_mods()
        end
        return false
    end
    if not held then
        if M._had_applied_mods and needs_gc then
            clear_all_mods()
        end
        if needs_gc then
            M._apply_dirty = false
            M._force_apply = false
        end
        M._toolinfo_dirty = false
        return false
    end
    if not profiles.should_apply_for_held(held) then
        if M._had_applied_mods and needs_gc then
            clear_all_mods()
        end
        if needs_gc then
            M._apply_dirty = false
            M._force_apply = false
        end
        M._toolinfo_dirty = false
        return false
    end
    local mods = profiles.build_mods_for_apply(held)
    local ti_opts, ti_weapon = profiles.build_toolinfo_for_apply(held)
    local has_gc = mods and next(mods)
    local has_ti = ti_opts and ti_opts.double_tap == true
    if not has_gc and not has_ti then
        if M._had_applied_mods then
            clear_all_mods()
        end
        M._apply_dirty = false
        M._force_apply = false
        M._toolinfo_dirty = false
        return false
    end
    local ok_gc, count, msg = true, 0, nil
    if has_gc and needs_gc then
        ok_gc, count, msg = gc.apply_weapon(mods)
        if ok_gc then
            remember_applied(mods)
            M._apply_dirty = false
            M._force_apply = false
            M._retry_until = 0
        end
    elseif has_gc and M._had_applied_mods then
        ok_gc = true
    elseif needs_gc and not has_gc then
        local clear = build_clear_payload()
        if clear then
            pcall(gc.apply_weapon, clear)
        end
        M._last_applied_keys = nil
        M._apply_dirty = false
        M._force_apply = false
    end
    local ok_ti = true
    local ti_count, ti_msg
    if has_ti and (needs_ti or needs_gc) then
        ok_ti, ti_count, ti_msg = toolinfo_mods.apply(ti_opts, ti_weapon or held)
        M._toolinfo_dirty = false
    elseif needs_ti and not has_ti then
        pcall(toolinfo_mods.reset)
        M._toolinfo_dirty = false
    elseif needs_gc and not has_ti then
        pcall(toolinfo_mods.reset)
    end
    local ok = (not has_gc or not needs_gc or ok_gc) and (not needs_ti or not has_ti or ok_ti)
    if ok and (needs_gc or needs_ti) then
        if has_gc and (needs_gc or M._had_applied_mods) then
            M._had_applied_mods = true
        end
        if needs_gc and (M._notify_next or not silent) then
            M._notify_next = false
            local parts = {}
            if has_gc and needs_gc then
                parts[#parts + 1] = tostring(msg or (tostring(count) .. " nodes"))
            end
            if has_ti and ti_count and ti_count > 0 then
                parts[#parts + 1] = tostring(ti_msg or (tostring(ti_count) .. " burst"))
            end
            if #parts > 0 then
                notify.success("Gun mods applied: " .. table.concat(parts, ", "), 3500)
            end
        end
    elseif needs_gc then
        M._apply_dirty = true
        M._force_apply = true
        M._defer_until = tick_ms() + RETRY_MS
        if gc.cooldown_remaining_ms() > 0 then
            M._apply_dirty = false
            M._force_apply = false
        end
    end
    return ok
end
function M.tick_session()
    local sid = session_id()
    local match = in_match()
    if M._session_id == nil then
        M._session_id = sid
        M._was_in_match = match
        return
    end
    if sid ~= M._session_id then
        M._session_id = sid
        M.on_session_changed()
    elseif not M._was_in_match and match then
        M.on_session_changed()
    end
    M._was_in_match = match
end
function M.on_weapon_equip_changed(held)
    if held == M._last_held_apply then return end
    M._last_held_apply = held
    if settings.enabled(P) then
        M._toolinfo_dirty = true
    end
end
function M.update(_dt)
    M.tick_session()
    if not settings.enabled(P) then return end
    local held = profiles.held_weapon_name()
    if held ~= M._last_held_apply then
        M.on_weapon_equip_changed(held)
    end
    local now = tick_ms()
    if M._gc_redo_at > 0 and now >= M._gc_redo_at then
        M._gc_redo_at = 0
        if in_match() then
            pcall(gc.refresh_cache)
            toolinfo_mods.invalidate()
            M._apply_dirty = true
            M._force_apply = true
            M._defer_until = now + 800
            M._retry_until = now + RETRY_MAX_MS
            notify.info("Re-applying gun mods after session change...", 2500)
        end
    end
    if not M._apply_dirty and not M._toolinfo_dirty then return end
    if M._apply_dirty and now < M._defer_until then return end
    if M._apply_dirty and not can_apply_now() then return end
    if M._retry_until > 0 and now > M._retry_until and M._apply_dirty then
        M._apply_dirty = false
        M._force_apply = false
        notify.warning("Gun mods: equip a gun in match, then toggle a mod option", 5000)
        return
    end
    M.try_apply(true)
end
function M.on_weapon_changed(name)
    M.on_weapon_equip_changed(name)
end
function M.on_modules_ready()
    toolinfo_mods.invalidate()
    if settings.enabled(P) then
        M._toolinfo_dirty = true
        if not M._had_applied_mods then
            schedule_apply(1200)
        end
    end
end
function M.draw() end
return M
end)()

April._mods["features.utility.mod_checker"] = (function()
local settings = April.require("core.settings")
local notify = April.require("core.notify")
local mod_ids = April.require("game.mod_ids")
local menu_util = April.require("core.menu_util")
local draw_util = April.require("core.draw_util")
local env = April.require("core.env")
local esp_util = April.require("core.esp_util")
local theme = April.require("core.ui_theme")
local panel_drag = April.require("core.panel_drag")
local overlay_theme = April.require("core.overlay_theme")
local ep = April.require("core.entity_props")
local M = {}
local P = "april_mod_checker_enabled"
local X_ID = "april_mod_checker_x"
local Y_ID = "april_mod_checker_y"
local PANEL_W = 282
local HEAD_OFFSET = 3.5
local TITLE_H = 30
local SCAN_MS = 2500
local META_REFRESH_MS = 1000
local LOOKUP_BUDGET = 2
local seen = {}
local active = {}
local panel_rows = {}
local last_scan = -1
local last_meta_refresh = 0
M._session = nil
M._was_enabled = false
M._group_started = false
local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end
local function session_id()
    if not game then return "none" end
    local pid = game.place_id or 0
    local ws = game.workspace
    local ws_addr = (ws and (ws.Address or ws.address)) or 0
    local job = (game.job_id or game.JobId or "")
    return tostring(pid) .. ":" .. tostring(ws_addr) .. ":" .. tostring(job)
end
local function player_uid(p)
    local uid = ep.user_id(p)
    if uid and uid ~= 0 then return uid end
    return p.name or p.display_name
end
function M.reset_state()
    seen = {}
    active = {}
    panel_rows = {}
    last_scan = -1
    last_meta_refresh = 0
end
function M.on_session_changed()
    M.reset_state()
    mod_ids.reset_session()
    M._group_started = false
end
function M.tick_session()
    local sid = session_id()
    if M._session == nil then
        M._session = sid
        last_scan = -1
        return
    end
    if sid ~= M._session then
        M._session = sid
        M.on_session_changed()
    end
end
local function player_label(p)
    if not p then return "Unknown" end
    if p.display_name and p.display_name ~= "" then return p.display_name end
    return p.name or "Unknown"
end
local function format_duration(ms)
    ms = math.max(0, ms or 0)
    local sec = math.floor(ms / 1000)
    if sec < 60 then return sec .. "s" end
    local min = math.floor(sec / 60)
    sec = sec % 60
    if min < 60 then return string.format("%dm %02ds", min, sec) end
    local hr = math.floor(min / 60)
    min = min % 60
    return string.format("%dh %02dm", hr, min)
end
local function head_world_pos(p)
    if p.head_position then
        local hp = p.head_position
        if type(hp) == "table" then
            if hp.x then return hp.x, hp.y + HEAD_OFFSET, hp.z end
            return hp[1], (hp[2] or 0) + HEAD_OFFSET, hp[3]
        end
    end
    if p.position then
        local pos = p.position
        return pos.x, pos.y + HEAD_OFFSET + 1.5, pos.z
    end
    return nil
end
function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)
    menu_util.section(T, G.MISC, "Utility")
    menu.add_checkbox(T, G.MISC, P, "Mod Checker", false)
    menu_util.section(T, G.MISC, "Mod Checker Scan")
    menu.add_slider_int(T, G.MISC, "april_mod_checker_interval", "Scan Interval (ms)", 1000, 10000, 2500, root)
    menu_util.bind_master(P, { "april_mod_checker_interval" })
end
function M.init()
    M.on_session_changed()
    M._session = session_id()
    M._group_started = false
end
function M.track_player(p, role)
    local uid = player_uid(p)
    if not uid or uid == "" then return end
    local now = tick_ms()
    if not active[uid] then
        active[uid] = {
            uid = uid,
            label = player_label(p),
            username = p.name or "?",
            role = role,
            first_seen = now,
            player = p,
        }
    else
        local entry = active[uid]
        entry.label = player_label(p)
        entry.username = p.name or entry.username
        entry.role = role
        entry.player = p
    end
end
function M.check_player(p, lookup_budget)
    if not settings.enabled(P) then return lookup_budget end
    if not p or p.is_local then return lookup_budget end
    local role = mod_ids.role_for_player(p, {
        queue_lookup = true,
        mark_unknown = false,
        live_lookup = true,
    })
    if not role then return lookup_budget end
    local uid = player_uid(p)
    if not uid or uid == "" then return lookup_budget end
    M.track_player(p, role)
    if seen[uid] then return lookup_budget end
    seen[uid] = true
    notify.warning(string.format("%s: %s (%s)", mod_ids.short_label(role), player_label(p), p.name or "?"), 6000)
    return lookup_budget
end
local function rebuild_panel_rows(now)
    local rows = {}
    local me = env.get_local_player()
    for uid, entry in pairs(active) do
        local p = entry.player
        local dist = nil
        if p and me and me.position and p.position then
            local dx = p.position.x - me.position.x
            local dy = p.position.y - me.position.y
            local dz = p.position.z - me.position.z
            dist = math.floor(math.sqrt(dx * dx + dy * dy + dz * dz))
        end
        local meta = format_duration(now - (entry.first_seen or now))
        if dist then
            meta = meta .. "  |  " .. dist .. "m"
        end
        rows[#rows + 1] = {
            name = entry.label or entry.username or "Unknown",
            role = mod_ids.short_label(entry.role),
            meta = meta,
            first_seen = entry.first_seen or now,
            accent = theme.role_accent(entry.role),
        }
    end
    table.sort(rows, function(a, b)
        return (a.first_seen or 0) < (b.first_seen or 0)
    end)
    panel_rows = rows
end
local function player_body_alive(p)
    if not p or p.is_local then return false end
    if p.is_alive == false then return false end
    local char = p.character
    if not char or not env.is_valid(char) then return false end
    local hum = p.humanoid
    if hum ~= nil and not env.is_valid(hum) then return false end
    if p.health ~= nil and p.health <= 0 then return false end
    return true
end
function M.reconcile_active(players)
    local present = {}
    for _, p in ipairs(players) do
        if p.is_local then goto continue end
        local role = mod_ids.role_for_player(p, { live_lookup = true })
        if not role then goto continue end
        local uid = player_uid(p)
        if not uid or uid == "" then goto continue end
        present[uid] = true
        if player_body_alive(p) then
            M.track_player(p, role)
        elseif active[uid] then
            active[uid].player = nil
            active[uid].role = role
        else
            M.track_player(p, role)
            if active[uid] then active[uid].player = nil end
        end
        ::continue::
    end
    for uid in pairs(active) do
        if not present[uid] then
            active[uid] = nil
            seen[uid] = nil
        end
    end
end
function M.scan_all()
    if not settings.enabled(P) then return end
    local players = April.require("core.cache").players
    local lookup_budget = LOOKUP_BUDGET
    M.reconcile_active(players)
    for _, p in ipairs(players) do
        lookup_budget = M.check_player(p, lookup_budget)
    end
    rebuild_panel_rows(tick_ms())
    last_meta_refresh = tick_ms()
end
function M.on_player_added(p)
    M.check_player(p, LOOKUP_BUDGET)
    rebuild_panel_rows(tick_ms())
end
function M.on_player_removed(p)
    if not p then return end
    local uid = player_uid(p)
    if uid and uid ~= "" then
        seen[uid] = nil
        active[uid] = nil
        mod_ids.invalidate_player(p)
        rebuild_panel_rows(tick_ms())
    end
end
function M.staff_role(player)
    if not player then return nil end
    local uid = player_uid(player)
    if uid and active[uid] then
        return active[uid].role
    end
    return mod_ids.role_for_player(player, { live_lookup = true })
end
function M.is_staff(player)
    return M.staff_role(player) ~= nil
end
function M.update(_dt)
    M.tick_session()
    if not settings.enabled(P) then
        if M._was_enabled then
            M.reset_state()
            mod_ids.stop("mod_checker_disabled")
            M._group_started = false
        end
        M._was_enabled = false
        return
    end
    M._was_enabled = true
    if not M._group_started then
        M._group_started = mod_ids.ensure_started() == true
    end
    local now = tick_ms()
    local interval = settings.num("april_mod_checker_interval", SCAN_MS)
    if last_scan < 0 or (now - last_scan) >= interval then
        last_scan = now
        M.scan_all()
    end
end
function M.draw_mod_markers()
    if not settings.enabled(P) then return end
    for uid, entry in pairs(active) do
        local p = entry.player
        if not player_body_alive(p) then
            if p and (p.is_alive == false or not p.character or not env.is_valid(p.character)) then
                entry.player = nil
            end
            goto continue
        end
        local wx, wy, wz = head_world_pos(p)
        if not wx then goto continue end
        local sx, sy, vis = esp_util.w2s(wx, wy, wz)
        if not vis then goto continue end
        theme.draw_staff_badge(sx, sy, entry.role)
        ::continue::
    end
end
local function draw_staff_panel(x, y, width, rows)
    if not draw or not draw.text then return end
    overlay_theme.sync()
    local pad = 12
    local row_h = 38
    local count = math.max(#rows, 1)
    local height = TITLE_H + count * row_h + 6
    local title = "STAFF IN LOBBY"
    if #rows > 1 then
        title = title .. " (" .. #rows .. ")"
    end
    overlay_theme.draw_panel(x, y, width, height, title)
    local ry = y + TITLE_H + 5
    if #rows == 0 then
        draw.text(x + pad, ry + 2, "No staff detected", theme.TEXT_MUTED, 11)
        return height
    end
    local max_name = math.max(10, math.floor((width - pad * 2 - 12) / 7))
    for i = 1, #rows do
        local row = rows[i]
        local row_accent = row.accent or theme.role_accent(row.role)
        local name = row.name or "?"
        if #name > max_name then name = name:sub(1, math.max(1, max_name - 2)) .. ".." end
        draw.text(x + pad, ry + 1, name, theme.TEXT, 12)
        local role = row.role or "Staff"
        if #role > max_name then role = role:sub(1, math.max(1, max_name - 2)) .. ".." end
        local role_w = theme.text_w(role, 10)
        draw.text(x + width - pad - role_w, ry + 2, role, row_accent, 10)
        if row.meta and row.meta ~= "" then
            draw.text(x + pad, ry + 18, row.meta, theme.TEXT_MUTED, 10)
        end
        ry = ry + row_h
    end
    return height
end
function M.draw()
    M.draw_mod_markers()
    if not settings.enabled(P) then return end
    local now = tick_ms()
    if now - last_meta_refresh >= META_REFRESH_MS then
        rebuild_panel_rows(now)
        last_meta_refresh = now
    end
    local sw, sh = draw_util.screen_size()
    local row_h = 38
    local count = math.max(#panel_rows, 1)
    local height = TITLE_H + count * row_h + 6
    local x, y = panel_drag.update(
        "mod_checker",
        X_ID, Y_ID,
        PANEL_W, TITLE_H,
        sw, sh,
        sw - PANEL_W - 16, 72
    )
    x, y = panel_drag.clamp(x, y, PANEL_W, height, sw, sh)
    draw_staff_panel(x, y, PANEL_W, panel_rows)
end
return M
end)()

April._mods["features.utility.event_status"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local env = April.require("core.env")
local folders = April.require("game.folders")
local menu_util = April.require("core.menu_util")
local draw_util = April.require("core.draw_util")
local panel_drag = April.require("core.panel_drag")
local overlay_theme = April.require("core.overlay_theme")
local theme = April.require("core.ui_theme")
local M = {}
local P = "april_event_status_enabled"
local X_ID = "april_event_status_x"
local Y_ID = "april_event_status_y"
local PANEL_W = 314
local TITLE_H = 30
local ROW_H = 36
local REFRESH_MS = 1000
local DEFINITIONS = {
    { id = "timed_crate", label = "Timed Crate", color = { 0.42, 0.95, 0.48, 1 } },
    { id = "btr", label = "BTR", color = { 0.95, 0.25, 0.15, 1 } },
    { id = "attack_heli", label = "Attack Heli", color = { 0.95, 0.48, 0.18, 1 } },
    { id = "bruno", label = "Bruno", color = { 0.95, 0.66, 0.20, 1 } },
    { id = "boris", label = "Boris", color = { 0.78, 0.42, 1.00, 1 } },
    { id = "brutus", label = "Brutus", color = { 1.00, 0.30, 0.48, 1 } },
}
local rows = {}
local first_seen = {}
local last_refresh = -REFRESH_MS
local session_token = nil
local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end
local function session_id()
    if not game then return "none" end
    local pid = game.place_id or game.PlaceId or 0
    local ws = game.workspace
    local ws_addr = (ws and (ws.Address or ws.address)) or 0
    local job = (game.job_id or game.JobId or "")
    return tostring(pid) .. ":" .. tostring(ws_addr) .. ":" .. tostring(job)
end
local function reset_session_state()
    rows = {}
    first_seen = {}
    last_refresh = -REFRESH_MS
end
local function tick_session()
    local sid = session_id()
    if session_token == nil then
        session_token = sid
        return
    end
    if sid ~= session_token then
        session_token = sid
        reset_session_state()
    end
end
local function find_child(parent, name)
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
local function format_elapsed(ms)
    local seconds = math.max(0, math.floor((ms or 0) / 1000))
    local minutes = math.floor(seconds / 60)
    seconds = seconds % 60
    if minutes < 60 then return string.format("%02d:%02d", minutes, seconds) end
    local hours = math.floor(minutes / 60)
    minutes = minutes % 60
    return string.format("%dh %02dm", hours, minutes)
end
local function crate_timer(model)
    local timer = find_child(model, "Timer")
    local holder = find_child(timer, "GuiHolder")
    local label = find_child(holder, "Label")
    local text_label = find_child(label, "TextLabel")
    local value = text_label and env.safe_call(function()
        return text_label.Text or text_label.text
    end)
    if value ~= nil and tostring(value) ~= "" then return tostring(value) end
    return nil
end
local function timed_crates()
    local bucket = find_child(folders.from_key("loners"), "Timed Crate")
    local count, timer = 0, nil
    for _, model in ipairs(children(bucket)) do
        if (model.Name or model.name) == "Timed Crate" then
            count = count + 1
            timer = timer or crate_timer(model)
        end
    end
    return count, timer
end
local function npc_event_state()
    local state = {}
    for _, entry in ipairs(cache.npcs or {}) do
        local id = entry and entry.kind
        if id == "heli" then id = "attack_heli" end
        if id == "btr" or id == "attack_heli" or id == "bruno"
            or id == "boris" or id == "brutus"
        then
            local item = state[id] or { count = 0 }
            item.count = item.count + 1
            item.location = item.location or entry.location
            if entry.entity then
                item.hp = tonumber(entry.entity.Health or entry.entity.health) or item.hp
                item.max_hp = tonumber(entry.entity.MaxHealth or entry.entity.max_health) or item.max_hp
            elseif entry.inst then
                local health = April.require("game.npcs").read_health(entry.inst, entry.humanoid)
                if health then
                    item.hp = health.hp or item.hp
                    item.max_hp = health.max_hp or item.max_hp
                end
            end
            if id == "btr" and entry.inst then
                item.destroyed = env.get_attribute(entry.inst, "Destroyed") == true
            end
            state[id] = item
        end
    end
    return state
end
local function rebuild_rows(now)
    local active = npc_event_state()
    local crate_count, crate_time = timed_crates()
    if crate_count > 0 then
        active.timed_crate = { count = crate_count, timer = crate_time }
    end
    local active_only = settings.bool("april_event_status_active_only", false)
    local next_rows = {}
    for _, definition in ipairs(DEFINITIONS) do
        local item = active[definition.id]
        local is_active = item ~= nil and (item.count or 0) > 0
        if is_active then
            first_seen[definition.id] = first_seen[definition.id] or now
        else
            first_seen[definition.id] = nil
        end
        if is_active or not active_only then
            local status = is_active and "ACTIVE" or "INACTIVE"
            if definition.id == "timed_crate" and is_active then status = "AVAILABLE" end
            if item and item.destroyed then status = "DESTROYED" end
            local elapsed = is_active and format_elapsed(now - (first_seen[definition.id] or now)) or "--:--"
            local meta = elapsed
            if item and item.timer then
                meta = item.timer
            elseif item and item.hp and item.max_hp and item.max_hp > 0 then
                meta = string.format(
                    "%d / %d HP  |  %s",
                    math.floor(item.hp + 0.5),
                    math.floor(item.max_hp + 0.5),
                    elapsed
                )
            end
            if item and item.location then
                meta = tostring(item.location) .. "  |  " .. meta
            end
            if item and (item.count or 0) > 1 then
                meta = tostring(item.count) .. " active  |  " .. meta
            end
            next_rows[#next_rows + 1] = {
                label = definition.label,
                color = definition.color,
                active = is_active,
                status = status,
                meta = meta,
            }
        end
    end
    rows = next_rows
end
function M.register_menu()
    local G = menu_util.G
    local T = menu_util.group(G.MISC)
    local root = menu_util.parent(P)
    menu.add_checkbox(T, G.MISC, P, "Event Status", false)
    menu.add_checkbox(T, G.MISC, "april_event_status_active_only", "Only Show Active Events", false, root)
    menu_util.bind_master(P, { "april_event_status_active_only" })
end
function M.update(_dt)
    tick_session()
    if not settings.enabled(P) then return end
    local now = tick_ms()
    if now - last_refresh < REFRESH_MS then return end
    last_refresh = now
    rebuild_rows(now)
end
function M.draw()
    tick_session()
    if not settings.enabled(P) then return end
    if not draw or not draw.text then return end
    overlay_theme.sync()
    local sw, sh = draw_util.screen_size()
    local count = math.max(#rows, 1)
    local height = TITLE_H + count * ROW_H + 8
    local x, y = panel_drag.update(
        "event_status", X_ID, Y_ID,
        PANEL_W, TITLE_H, sw, sh,
        sw - PANEL_W - 16, 300
    )
    x, y = panel_drag.clamp(x, y, PANEL_W, height, sw, sh)
    overlay_theme.draw_panel(x, y, PANEL_W, height, "EVENT STATUS")
    local ry = y + TITLE_H + 5
    if #rows == 0 then
        draw_util.text(x + 12, ry + 4, "No active events", theme.TEXT_MUTED, 11)
        return
    end
    for _, row in ipairs(rows) do
        local col = row.active and row.color or theme.TEXT_DIM
        if draw.circle_filled then
            draw.circle_filled(x + 16, ry + 8, 3, col, 12)
        end
        draw_util.text(x + 26, ry + 1, row.label, row.active and theme.TEXT or theme.TEXT_MUTED, 11)
        local meta = tostring(row.meta or "")
        if #meta > 42 then meta = meta:sub(1, 40) .. ".." end
        draw_util.text(x + 26, ry + 17, meta, theme.TEXT_MUTED, 10)
        local status_w = theme.text_w(row.status, 9)
        draw_util.text(x + PANEL_W - 12 - status_w, ry + 2, row.status, col, 9)
        ry = ry + ROW_H
    end
end
return M
end)()

April._mods["features.visuals.player_esp"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local menu_util = April.require("core.menu_util")
local text_util = April.require("core.text_util")
local player_state = April.require("game.player_state")
local player_gear = April.require("game.player_gear")
local mod_checker = April.require("features.utility.mod_checker")
local mod_ids = April.require("game.mod_ids")
local M = {}
local P = "april_player_enabled"
local FILTERS = "april_player_esp_filters"
local FLAGS = "april_player_esp_flags"
local ID_HEALTH = "april_player_health"
local ID_SKELETON = "april_player_skeleton"
local ID_NAME = "april_player_show_name"
local ID_DIST = "april_player_show_distance"
local ID_HELD = "april_player_show_held"
local ID_CLAN = "april_player_clan_tag"
local ID_BOX = "april_player_box_mode"
local ID_BOX_COLOR = "april_player_box_color"
local ID_RANGE = "april_player_range"
local ID_FLAG_DOWN = "april_player_flag_downed"
local ID_FLAG_SZ = "april_player_flag_safezone"
local ID_FLAG_STAFF = "april_player_flag_staff"
local ID_FLAG_REVIVE = "april_player_flag_reviving"
local ID_FLAG_MOVE = "april_player_flag_movement"
local ID_FLAG_VIP = "april_player_flag_vip"
local F_TEAM, F_SAFEZONE, F_SKIP_DOWNED = 1, 2, 3
local FL_DOWNED, FL_SAFEZONE, FL_STAFF, FL_REVIVING = 1, 2, 3, 4
local FL_MOVEMENT, FL_VIP = 5, 6
local DEFAULT_BOX = { 1, 0.35, 0.35, 1 }
local DEFAULT_TEXT = { 1, 0.35, 0.35, 1 }
local DEFAULT_CLAN = { 0.84, 0.31, 0.80, 1 }
local DEFAULT_MUTED = { 0.82, 0.84, 0.88, 0.92 }
local DEFAULT_HELD = { 0.95, 0.9, 0.55, 0.95 }
local DEFAULT_FLAG = {
    DOWN = { 1, 0.35, 0.35, 1 },
    SZ = { 0.35, 0.85, 1, 1 },
    STAFF = { 1, 0.33, 0.33, 1 },
    REVIVE = { 0.45, 1, 0.55, 1 },
    MOVE = { 0.75, 0.85, 1, 1 },
    VIP = { 1, 0.82, 0.2, 1 },
}
local function set_multi_defaults(id, values)
    if menu and menu.set then
        pcall(menu.set, id, values)
    end
end
local function migrate_flags_table()
    if not menu or not menu.get or not menu.set then return end
    local ok, cur = pcall(menu.get, FLAGS)
    if not ok or type(cur) ~= "table" then return end
    local n = 0
    for i = 1, 16 do
        if cur[i] ~= nil then n = i end
    end
    if n <= 4 then
        pcall(menu.set, FLAGS, {
            cur[1] == true, cur[2] == true, cur[3] == true, cur[4] == true,
            false, false,
        })
    elseif n >= 8 then
        local move = cur[5] == true or cur[6] == true or cur[7] == true
        pcall(menu.set, FLAGS, {
            cur[1] == true, cur[2] == true, cur[3] == true, cur[4] == true,
            move, cur[8] == true,
        })
    elseif n ~= 6 then
        pcall(menu.set, FLAGS, {
            cur[1] == true, cur[2] == true, cur[3] == true, cur[4] == true,
            cur[5] == true, cur[6] == true,
        })
    end
end
function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)
    menu_util.section(T, G.VISUALS, "Player ESP")
    menu_util.register_keybind(T, G.VISUALS, P, "Player ESP", false)
    menu.add_combo(T, G.VISUALS, ID_BOX, "Player Box", { "None", "2D", "Corner" }, 1, { parent = P })
    menu.add_colorpicker(T, G.VISUALS, ID_BOX_COLOR, "Player Box Color", DEFAULT_BOX, { parent = P })
    menu.add_checkbox(T, G.VISUALS, ID_HEALTH, "Player Health Bar", true, { parent = P })
    menu.add_checkbox(T, G.VISUALS, ID_SKELETON, "Player Skeleton", false,
        menu_util.parent(P, { colorpicker = { 1, 1, 1, 0.92 } }))
    menu.add_checkbox(T, G.VISUALS, ID_NAME, "Player Name", true,
        menu_util.parent(P, { colorpicker = DEFAULT_TEXT }))
    menu.add_checkbox(T, G.VISUALS, ID_CLAN, "Player Clan Tag", true,
        menu_util.parent(P, { colorpicker = DEFAULT_CLAN }))
    menu.add_checkbox(T, G.VISUALS, ID_HELD, "Held Item", false,
        menu_util.parent(P, { colorpicker = DEFAULT_HELD }))
    menu.add_checkbox(T, G.VISUALS, ID_DIST, "Player Distance", true,
        menu_util.parent(P, { colorpicker = DEFAULT_MUTED }))
    menu.add_multicombo(T, G.VISUALS, FILTERS, "ESP Filters", {
        "Team Check", "Skip Safezone", "Skip Downed",
    }, { false, false, false }, { parent = P })
    set_multi_defaults(FILTERS, { true, false, false })
    menu.add_multicombo(T, G.VISUALS, FLAGS, "ESP Flags", {
        "Downed", "Safezone", "Staff", "Reviving", "Movement", "VIP",
    }, { false, false, false, false, false, false }, { parent = P })
    set_multi_defaults(FLAGS, { true, true, true, true, false, true })
    menu.add_colorpicker(T, G.VISUALS, ID_FLAG_DOWN, "Flag Downed Color", DEFAULT_FLAG.DOWN, { parent = P })
    menu.add_colorpicker(T, G.VISUALS, ID_FLAG_SZ, "Flag Safezone Color", DEFAULT_FLAG.SZ, { parent = P })
    menu.add_colorpicker(T, G.VISUALS, ID_FLAG_STAFF, "Flag Staff Color", DEFAULT_FLAG.STAFF, { parent = P })
    menu.add_colorpicker(T, G.VISUALS, ID_FLAG_REVIVE, "Flag Reviving Color", DEFAULT_FLAG.REVIVE, { parent = P })
    menu.add_colorpicker(T, G.VISUALS, ID_FLAG_MOVE, "Flag Movement Color", DEFAULT_FLAG.MOVE, { parent = P })
    menu.add_colorpicker(T, G.VISUALS, ID_FLAG_VIP, "Flag VIP Color", DEFAULT_FLAG.VIP, { parent = P })
    menu.add_slider_int(T, G.VISUALS, ID_RANGE, "Player Range", 50, 2000, 500, { parent = P })
    menu_util.gap(T, G.VISUALS)
    menu_util.bind_children(P, {
        ID_BOX, ID_BOX_COLOR, ID_HEALTH, ID_SKELETON,
        ID_NAME, ID_CLAN, ID_HELD, ID_DIST,
        FILTERS, FLAGS,
        ID_FLAG_DOWN, ID_FLAG_SZ, ID_FLAG_STAFF, ID_FLAG_REVIVE,
        ID_FLAG_MOVE, ID_FLAG_VIP,
        ID_RANGE,
    })
end
local function held_label(player)
    local name = player_gear.held_name(player)
    if not name or player_gear.is_empty_held_name(name) then return nil end
    local base = name:match("^([^/]+)") or name
    base = text_util.sanitize(base)
    if base == "" then return nil end
    return base
end
local function horizontal_speed(p)
    local vel = p.Velocity or p.velocity
    if not vel then return 0 end
    local x = tonumber(vel.X or vel.x)
    local z = tonumber(vel.Z or vel.z)
    if not x or not z then return 0 end
    return math.sqrt(x * x + z * z)
end
local function movement_label(p)
    local speed = horizontal_speed(p)
    if speed < 1.0 then return "IDLE" end
    if speed > 15.0 then return "SPRINTING" end
    return "WALKING"
end
local function native_bounds(player)
    local fn = player and (player.GetBounds or player.get_bounds)
    if not fn then return nil end
    return fn(player)
end
local function native_bones(player)
    local fn = player and (player.GetBonesScreen or player.get_bones_screen)
    if not fn then return nil end
    return fn(player)
end
local function emit_side_tag(x, y, ts, row, text, col)
    draw_util.text(x, y + row * (ts + 1), text, col, ts)
    return row + 1
end
local function draw_side_tags(p, snap, show_clan, clan_menu_col, flag_cols, flags, x, y, ts)
    local row = 0
    if show_clan and snap and snap.clan_tag then
        local cc = snap.clan_color
        row = emit_side_tag(x, y, ts, row, "[" .. snap.clan_tag .. "]", (cc and cc[1]) and cc or clan_menu_col)
    end
    if flags[FL_SAFEZONE] and snap and snap.safezone then
        row = emit_side_tag(x, y, ts, row, "[SZ]", flag_cols.sz)
    end
    if flags[FL_DOWNED] and snap and snap.downed then
        row = emit_side_tag(x, y, ts, row, "[DOWN]", flag_cols.down)
    end
    if flags[FL_STAFF] then
        if snap and snap.staff then
            row = emit_side_tag(x, y, ts, row, "[" .. snap.staff .. "]", flag_cols.staff)
        else
            local role = mod_checker.staff_role(p)
            if role then
                row = emit_side_tag(x, y, ts, row, "[" .. mod_ids.short_label(role) .. "]", flag_cols.staff)
            end
        end
    end
    if flags[FL_REVIVING] and snap and snap.reviving then
        row = emit_side_tag(x, y, ts, row, "[REVIVE]", flag_cols.revive)
    end
    if flags[FL_VIP] and snap and snap.vip then
        row = emit_side_tag(x, y, ts, row, "[VIP]", flag_cols.vip)
    end
    if flags[FL_MOVEMENT] then
        emit_side_tag(x, y, ts, row, "[" .. movement_label(p) .. "]", flag_cols.move)
    end
end
function M.draw()
    if not M._flags_migrated then
        M._flags_migrated = true
        migrate_flags_table()
    end
    if not settings.enabled(P) then return end
    local players = cache.players
    if type(players) ~= "table" or #players == 0 then return end
    local range = settings.num(ID_RANGE, 500)
    local range_sq = range * range
    local box_mode = settings.num(ID_BOX, 1)
    local show_health = settings.bool(ID_HEALTH, true)
    local show_skel = settings.bool(ID_SKELETON, false)
    local show_name = settings.bool(ID_NAME, true)
    local show_clan = settings.bool(ID_CLAN, true)
    local show_held = settings.bool(ID_HELD, false)
    local show_dist = settings.bool(ID_DIST, true)
    local filter_team = settings.multi(FILTERS, F_TEAM, true)
    local filter_sz = settings.multi(FILTERS, F_SAFEZONE, false)
    local skip_downed = settings.multi(FILTERS, F_SKIP_DOWNED, false)
    local flags = {
        [FL_DOWNED] = settings.multi(FLAGS, FL_DOWNED, false),
        [FL_SAFEZONE] = settings.multi(FLAGS, FL_SAFEZONE, false),
        [FL_STAFF] = settings.multi(FLAGS, FL_STAFF, false),
        [FL_REVIVING] = settings.multi(FLAGS, FL_REVIVING, false),
        [FL_MOVEMENT] = settings.multi(FLAGS, FL_MOVEMENT, false),
        [FL_VIP] = settings.multi(FLAGS, FL_VIP, false),
    }
    local need_snap = show_clan or filter_sz or skip_downed
        or flags[FL_DOWNED] or flags[FL_SAFEZONE]
        or flags[FL_STAFF] or flags[FL_REVIVING] or flags[FL_VIP]
    local need_side = need_snap or flags[FL_MOVEMENT]
    local skel_col = settings.color(ID_SKELETON, { 1, 1, 1, 0.92 })
    local name_col = settings.color(ID_NAME, DEFAULT_TEXT)
    local clan_menu_col = settings.color(ID_CLAN, DEFAULT_CLAN)
    local held_col = settings.color(ID_HELD, DEFAULT_HELD)
    local dist_col = settings.color(ID_DIST, DEFAULT_MUTED)
    local box_col = settings.color(ID_BOX_COLOR, DEFAULT_BOX)
    local flag_cols = {
        down = settings.color(ID_FLAG_DOWN, DEFAULT_FLAG.DOWN),
        sz = settings.color(ID_FLAG_SZ, DEFAULT_FLAG.SZ),
        staff = settings.color(ID_FLAG_STAFF, DEFAULT_FLAG.STAFF),
        revive = settings.color(ID_FLAG_REVIVE, DEFAULT_FLAG.REVIVE),
        move = settings.color(ID_FLAG_MOVE, DEFAULT_FLAG.MOVE),
        vip = settings.color(ID_FLAG_VIP, DEFAULT_FLAG.VIP),
    }
    local base_ts = esp_util.text_size()
    local me = cache.local_player
    local mx, my, mz = nil, nil, nil
    if me then
        mx, my, mz = esp_util.vec3_pos(me.Position or me.position or me.HeadPosition or me.head_position)
    end
    for i = 1, #players do
        local p = players[i]
        if not p then goto continue end
        if p.IsAlive == false or p.is_alive == false then goto continue end
        local pname = p.Name or p.name or p.DisplayName or p.display_name
        local hx, hy, hz = esp_util.vec3_pos(
            p.HeadPosition or p.head_position or p.Position or p.position
        )
        if not hx then goto continue end
        local dist = 0
        if mx then
            local dx, dy, dz = hx - mx, hy - my, hz - mz
            local dist_sq = dx * dx + dy * dy + dz * dz
            if dist_sq > range_sq then goto continue end
            dist = math.sqrt(dist_sq)
        end
        if filter_team and not player_state.passes_team_check(p) then goto continue end
        local snap = nil
        if need_snap then
            snap = player_state.esp_state(p)
            if skip_downed and snap and snap.downed then goto continue end
            if filter_sz and snap and snap.safezone then goto continue end
        end
        local bounds = native_bounds(p)
        if not esp_util.bounds_usable(bounds) then goto continue end
        if show_skel then
            local bones = native_bones(p)
            if bones then
                esp_util.draw_skeleton_bones(bones, skel_col, 1)
            end
        end
        local ts = base_ts
        if dist > 200 then ts = math.max(9, ts - 1) end
        if dist > 400 then ts = math.max(8, ts - 1) end
        local cx = bounds.x + bounds.w * 0.5
        if show_name then
            draw_util.text_centered(cx, bounds.y - ts - 5, pname or "?", name_col, ts)
        end
        if need_side then
            draw_side_tags(
                p, snap, show_clan, clan_menu_col, flag_cols, flags,
                bounds.x + bounds.w + 4, bounds.y, ts
            )
        end
        if box_mode == 1 then
            draw_util.box_esp(bounds.x, bounds.y, bounds.w, bounds.h, box_col, 0)
        elseif box_mode == 2 then
            draw_util.box_esp(bounds.x, bounds.y, bounds.w, bounds.h, box_col, 1)
        end
        if show_health then
            draw_util.health_bar_on_box(bounds, p.Health or p.health, p.MaxHealth or p.max_health)
        end
        local below_y = bounds.y + bounds.h + 3
        if show_held then
            local held = held_label(p)
            if held then
                draw_util.text_centered(cx, below_y, held, held_col, ts)
                below_y = below_y + ts + 2
            end
        end
        if show_dist then
            draw_util.text_centered(
                cx,
                below_y,
                string.format("%dm", math.floor(dist + 0.5)),
                dist_col,
                ts
            )
        end
        ::continue::
    end
end
return M
end)()

April._mods["features.visuals.target_overlay"] = (function()
local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local menu_util = April.require("core.menu_util")
local image_cache = April.require("core.image_cache")
local items = April.require("game.items")
local player_gear = April.require("game.player_gear")
local player_state = April.require("game.player_state")
local text_util = April.require("core.text_util")
local theme = April.require("core.ui_theme")
local overlay_theme = April.require("core.overlay_theme")
local ep = April.require("core.entity_props")
local esp_util = April.require("core.esp_util")
local math_util = April.require("core.math_util")
local cache = April.require("core.cache")
local M = {}
local P = "april_target_overlay"
local P_FOV = P .. "_fov"
local P_DIST = P .. "_max_dist"
local GEAR_SLOTS = 7
local GEAR_TTL = 500
local TARGET_POLL_MS = 120
local MAX_ATTACHMENTS = 5
local DEFAULT_FOV = 100
local DEFAULT_MAX_DIST = 500
local gear_cache = {}
local last_poll_ms = 0
M._target = nil
M._layout = nil
local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end
local function img_key(prefix, id)
    return prefix .. tostring(id)
end
local function resolve_image_key(piece)
    if not piece then return nil end
    if type(piece) == "table" and piece.asset_id then
        local key = img_key("item_", piece.asset_id)
        image_cache.ensure(key, piece.asset_id)
        return key
    end
    if type(piece) == "table" and piece.name then
        local resolved = items.resolve_item_label(
            piece.variant and (piece.name .. "/" .. piece.variant) or piece.name
        )
        if resolved and resolved.asset_id then
            local key = img_key("item_", resolved.asset_id)
            image_cache.ensure(key, resolved.asset_id)
            return key
        end
        local asset_id = items.get_image_asset_id(piece.name, piece.variant)
        if asset_id then
            local key = img_key("item_", asset_id)
            image_cache.ensure(key, asset_id)
            return key
        end
    end
    return nil
end
local function local_origin()
    local me = cache.local_player
    if not me then return nil end
    return esp_util.vec3_pos(
        me.Position or me.position or me.HeadPosition or me.head_position
    )
end
local function find_overlay_target()
    local fov = settings.num(P_FOV, DEFAULT_FOV)
    local max_dist = settings.num(P_DIST, DEFAULT_MAX_DIST)
    if fov <= 0 or max_dist <= 0 then return nil end
    local ox, oy, oz = local_origin()
    local sw, sh = draw_util.screen_size()
    local cx, cy = sw * 0.5, sh * 0.5
    local best, best_d = nil, fov
    local max_dist_sq = max_dist * max_dist
    for _, player in ipairs(cache.players or {}) do
        if player_state.is_combat_target(player) then
            local hx, hy, hz = esp_util.vec3_pos(ep.head_position(player) or ep.position(player))
            if hx then
                if ox then
                    local dx, dy, dz = hx - ox, hy - oy, hz - oz
                    if dx * dx + dy * dy + dz * dz > max_dist_sq then
                        goto continue
                    end
                end
                local sx, sy, on_screen = esp_util.w2s(hx, hy, hz)
                if on_screen then
                    local dist = math_util.screen_fov_dist(sx, sy, cx, cy)
                    if dist <= fov and dist < best_d then
                        best, best_d = player, dist
                    end
                end
            end
        end
        ::continue::
    end
    return best
end
local function player_key(player)
    if not player then return "?" end
    local uid = ep.user_id(player)
    if uid and uid ~= 0 then return uid end
    return player.name or player.display_name or "?"
end
local function get_gear(player)
    if not player then return nil end
    local uid = player_key(player)
    local now = tick_ms()
    local cached = gear_cache[uid]
    if cached and (now - cached.t) < GEAR_TTL then
        return cached.data
    end
    local data = player_gear.scan_player(player)
    gear_cache[uid] = { t = now, data = data }
    return data
end
local function armor_sort_key(piece)
    local n = (piece.name or ""):lower()
    if n:find("helmet", 1, true) or n:find("head", 1, true) or n:find("cap", 1, true)
        or n:find("wrap", 1, true) or n:find("balaclava", 1, true) or n:find("hood", 1, true) then
        return 1
    end
    if n:find("chest", 1, true) or n:find("plate", 1, true) or n:find("shirt", 1, true)
        or n:find("jacket", 1, true) or n:find("hoodie", 1, true) or n:find("vest", 1, true)
        or n:find("suit", 1, true) or n:find("torso", 1, true) then
        return 2
    end
    if n:find("legging", 1, true) or n:find("pants", 1, true) or n:find("shorts", 1, true) then
        return 3
    end
    if n:find("glove", 1, true) or n:find("handwrap", 1, true) then
        return 4
    end
    if n:find("boot", 1, true) or n:find("footwrap", 1, true) or n:find("shoe", 1, true) then
        return 5
    end
    if n:find("backpack", 1, true) or n:find("bag", 1, true) then
        return 6
    end
    return 7
end
local function pack_gear(armor_list)
    local sorted = {}
    for _, piece in ipairs(armor_list or {}) do
        table.insert(sorted, piece)
    end
    table.sort(sorted, function(a, b)
        return armor_sort_key(a) < armor_sort_key(b)
    end)
    local packed = {}
    for _, piece in ipairs(sorted) do
        table.insert(packed, piece)
        if #packed >= GEAR_SLOTS then break end
    end
    return packed
end
local function pack_attachments(list)
    local packed = {}
    for i = 1, math.min(#(list or {}), MAX_ATTACHMENTS) do
        packed[#packed + 1] = list[i]
    end
    return packed
end
local function build_layout(gear, gear_sz)
    local held = gear and gear.held
    local packed = pack_gear(gear and gear.armor)
    local attachments = pack_attachments(gear and gear.attachments)
    local held_sz = math.floor(gear_sz * 1.28)
    local att_sz = math.floor(gear_sz * 0.78)
    local gap = 5
    local att_gap = 4
    local row_w = GEAR_SLOTS * gear_sz + (GEAR_SLOTS - 1) * gap
    local att_row_w = #attachments > 0 and (#attachments * att_sz + (#attachments - 1) * att_gap) or 0
    local held_row_w = held_sz + (#attachments > 0 and (10 + att_row_w) or 0)
    local panel_w = math.max(row_w, held_row_w)
    local layout = {
        held = held,
        attachments = attachments,
        packed = packed,
        filled = #packed,
        gear_sz = gear_sz,
        held_sz = held_sz,
        att_sz = att_sz,
        gap = gap,
        att_gap = att_gap,
        row_w = row_w,
        held_row_w = held_row_w,
        panel_w = panel_w,
        row_gap = 8,
        name_fs = 11,
        held_key = nil,
        att_keys = {},
        gear_keys = {},
    }
    layout.held_key = held and resolve_image_key(held) or nil
    for i = 1, layout.filled do
        layout.gear_keys[i] = resolve_image_key(packed[i])
        local key = layout.gear_keys[i]
        if key then image_cache.begin_load(key) end
    end
    for i = 1, #attachments do
        layout.att_keys[i] = resolve_image_key(attachments[i])
        local key = layout.att_keys[i]
        if key then image_cache.begin_load(key) end
    end
    if layout.held_key then
        image_cache.begin_load(layout.held_key)
    end
    return layout
end
local function held_piece(held)
    if not held then return nil end
    if type(held) == "table" then
        if held.name and player_gear.is_empty_held_name and player_gear.is_empty_held_name(held.name) then
            return nil
        end
        return held
    end
    if player_gear.is_empty_held_name and player_gear.is_empty_held_name(held) then
        return nil
    end
    return { name = held }
end
local function split_words(text)
    local words = {}
    for word in text:gmatch("%S+") do
        words[#words + 1] = word
    end
    return words
end
local function wrap_words(words, max_w, fs)
    local lines = {}
    local i = 1
    while i <= #words do
        local line = words[i]
        local j = i + 1
        while j <= #words do
            local try = line .. " " .. words[j]
            if select(1, draw.get_text_size(try, fs)) <= max_w then
                line = try
                j = j + 1
            else
                break
            end
        end
        lines[#lines + 1] = line
        i = j
    end
    return lines
end
local function words_fit(words, fs, max_w)
    for _, word in ipairs(words) do
        if select(1, draw.get_text_size(word, fs)) > max_w then
            return false
        end
    end
    return true
end
local function slot_label(piece)
    if type(piece) ~= "table" then return nil end
    local name = piece.name
    if not name or name == "" then return nil end
    name = text_util.sanitize(name)
    local base, slash_var = name:match("^([^/]+)/(.+)$")
    if base and slash_var then
        return base .. " " .. slash_var
    end
    local variant = piece.variant
    if variant and variant ~= "" and variant ~= "Default" then
        return name .. " " .. text_util.sanitize(variant)
    end
    return name
end
local function draw_fitted_label(x, y, size, text)
    if not draw or not draw.text or not draw.get_text_size then return end
    text = text_util.sanitize(text)
    if text == "" then return end
    local pad = 4
    local inner = size - pad * 2
    local words = split_words(text)
    if #words == 0 then return end
    local max_fs = math.max(8, math.floor(size * 0.26))
    local min_fs = 6
    local chosen_fs, chosen_lines
    for fs = max_fs, min_fs, -1 do
        if words_fit(words, fs, inner) then
            local lines = wrap_words(words, inner, fs)
            local line_h = fs + 1
            if #lines * line_h <= inner then
                chosen_fs = fs
                chosen_lines = lines
                break
            end
        end
    end
    if not chosen_lines then
        chosen_fs = min_fs
        chosen_lines = wrap_words(words, inner, min_fs)
    end
    local line_h = chosen_fs + 1
    local total_h = #chosen_lines * line_h
    local ty = y + pad + (inner - total_h) * 0.5
    for i, line in ipairs(chosen_lines) do
        local tw = select(1, draw.get_text_size(line, chosen_fs))
        draw.text(
            x + size * 0.5 - tw * 0.5,
            ty + (i - 1) * line_h,
            line,
            theme.TEXT_MUTED,
            chosen_fs
        )
    end
end
local function draw_slot(x, y, size, key, piece, style)
    local pad = 3
    local bg = overlay_theme.slot()
    local edge = overlay_theme.border()
    if style == "held" then
        bg = overlay_theme.slot("held")
        edge = theme.alpha(overlay_theme.accent(), 0.88)
    elseif style == "attachment" then
        bg = theme.alpha(overlay_theme.slot(), 0.82)
    elseif style == "empty" then
        bg = overlay_theme.slot("empty")
        edge = theme.alpha(theme.BORDER, 0.28)
    end
    draw.rect_filled(x, y, size, size, bg, 0)
    if draw.rect then
        draw.rect(x, y, size, size, edge, 0, style == "held" and 1.5 or 1)
    end
    if style == "held" and draw.rect_filled then
        draw.rect_filled(x + 1, y + 1, size - 2, 2, overlay_theme.accent(), 0)
    end
    if not piece then return end
    if key and image_cache.draw_fit(key, x + pad, y + pad, size - pad * 2, size - pad * 2) then
        return
    end
    if key and image_cache.state(key) ~= "failed" then
        return
    end
    local label = slot_label(piece)
    if label then
        draw_fitted_label(x, y, size, label)
    end
end
local function same_target(a, b)
    if a == b then return true end
    if not a or not b then return false end
    local aid = player_key(a)
    local bid = player_key(b)
    return aid and bid and aid == bid
end
function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)
    menu_util.section(T, G.VISUALS, "Target Gear")
    menu_util.register_keybind(T, G.VISUALS, P, "Target Gear Overlay", false)
    local root = menu_util.parent(P)
    menu.add_slider_int(T, G.VISUALS, P_FOV, "Gear FOV", 5, 500, DEFAULT_FOV, root)
    menu.add_slider_int(T, G.VISUALS, P_DIST, "Max Distance", 50, 2000, DEFAULT_MAX_DIST, root)
    menu.add_slider_int(T, G.VISUALS, P .. "_gear_size", "Gear Icon Size", 32, 64, 48, root)
    menu.add_slider_int(T, G.VISUALS, P .. "_top", "Top Offset", 48, 160, 88, root)
    menu_util.bind_children(P, {
        P_FOV, P_DIST, P .. "_gear_size", P .. "_top",
    })
end
function M.refresh_target()
    if not settings.enabled(P) then
        M._target = nil
        M._layout = nil
        return
    end
    local gear_sz = settings.num(P .. "_gear_size", 48)
    local target = find_overlay_target()
    if not target or not player_state.is_combat_target(target) then
        M._target = nil
        M._layout = nil
        return
    end
    local target_changed = not same_target(M._target, target)
    local uid = player_key(target)
    local cached = gear_cache[uid]
    local gear_stale = not cached or (tick_ms() - cached.t) >= GEAR_TTL
    M._target = target
    if target_changed or not M._layout or gear_stale then
        M._layout = build_layout(get_gear(target), gear_sz)
    end
end
function M.update(_dt)
    if not settings.enabled(P) then
        M._target = nil
        M._layout = nil
        return
    end
    local now = tick_ms()
    if now - last_poll_ms < TARGET_POLL_MS then return end
    last_poll_ms = now
    M.refresh_target()
end
function M.draw()
    if not settings.enabled(P) then return end
    if not draw or not draw.text or not draw.rect_filled then return end
    overlay_theme.sync()
    local target = M._target
    local layout = M._layout
    if not target or not layout then return end
    local sw, _ = draw_util.screen_size()
    local top = settings.num(P .. "_top", 88)
    local cx = sw * 0.5
    local name = text_util.sanitize(target.display_name or target.name or "Unknown")
    local content_w = math.max(layout.held_row_w, layout.row_w)
    local panel_w = math.max(220, content_w + 18)
    local panel_h = 24 + 8 + layout.held_sz + layout.row_gap + layout.gear_sz + 9
    if not held_piece(layout.held) and layout.filled == 0 then
        panel_h = panel_h + 16
    end
    local panel_x = cx - panel_w * 0.5
    overlay_theme.draw_panel(panel_x, top, panel_w, panel_h, "TARGET LOADOUT", { title_center = true })
    local max_name_w = panel_w - 114
    local header_name = name
    while #header_name > 1 and select(1, draw.get_text_size(header_name, 10)) > max_name_w do
        header_name = header_name:sub(1, -2)
    end
    if header_name ~= name then header_name = header_name .. ".." end
    local nw = select(1, draw.get_text_size(header_name, 10))
    draw.text(panel_x + panel_w - nw - 8, top + 7, header_name, overlay_theme.accent(), 10)
    local y = top + 32
    local held = held_piece(layout.held)
    local row_x = cx - layout.held_row_w * 0.5
    draw_slot(row_x, y, layout.held_sz, layout.held_key, held, held and "held" or "empty")
    if #layout.attachments > 0 then
        local ax = row_x + layout.held_sz + 10
        for i = 1, #layout.attachments do
            local sx = ax + (i - 1) * (layout.att_sz + layout.att_gap)
            draw_slot(sx, y + (layout.held_sz - layout.att_sz) * 0.5, layout.att_sz, layout.att_keys[i], layout.attachments[i], "attachment")
        end
    end
    y = y + layout.held_sz + layout.row_gap
    local start_x = cx - layout.row_w * 0.5
    for i = 1, GEAR_SLOTS do
        local piece = i <= layout.filled and layout.packed[i] or nil
        local sx = start_x + (i - 1) * (layout.gear_sz + layout.gap)
        draw_slot(sx, y, layout.gear_sz, layout.gear_keys[i], piece, piece and "gear" or "empty")
    end
    if not held and layout.filled == 0 then
        local hint = "No gear detected"
        local hw = select(1, draw.get_text_size(hint, 10))
        draw.text(cx - hw * 0.5, y + layout.gear_sz + 6, hint, theme.TEXT_DIM, 10)
    end
end
return M
end)()

April._mods["features.visuals.target_visuals"] = (function()
local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local menu_util = April.require("core.menu_util")
local active_target = April.require("features.combat.active_target")
local overlay_theme = April.require("core.overlay_theme")
local M = {}
local P = "april_crosshair_enabled"
local CROSS_STYLES = { "Cross", "Circle", "Dot", "T-Shape", "Diamond", "Plus", "Brackets", "X" }
local follow = { x = nil, y = nil, ready = false }
local function tick_s()
    return (utility and utility.get_tick_count and utility.get_tick_count() or 0) * 0.001
end
local function screen_center()
    local sw, sh = draw_util.screen_size()
    return sw * 0.5, sh * 0.5
end
local function lerp(a, b, t)
    return a + (b - a) * t
end
local function follow_alpha(dt)
    dt = dt or (1 / 60)
    local rate = settings.num("april_crosshair_follow_smooth", 18) * 0.045
    return 1 - math.exp(-rate * dt * 60)
end
local function crosshair_color()
    if settings.bool("april_crosshair_rainbow", false) then
        local t = tick_s()
        local speed = settings.num("april_crosshair_rainbow_speed", 10) * 0.1
        return {
            (math.sin(t * speed) + 1) * 0.5,
            (math.sin(t * speed + 2) + 1) * 0.5,
            (math.sin(t * speed + 4) + 1) * 0.5,
            1,
        }
    end
    return settings.color("april_crosshair_color", { 0, 1, 0, 1 })
end
local function motion_scale(base_size)
    if not settings.bool("april_crosshair_pulse", false) then
        return base_size
    end
    local speed = settings.num("april_crosshair_pulse_speed", 40) * 0.05
    local wave = 0.82 + 0.18 * math.sin(tick_s() * speed * 3.2)
    return base_size * wave
end
local function spin_angle()
    if not settings.bool("april_crosshair_spin", false) then
        return 0
    end
    local speed = settings.num("april_crosshair_spin_speed", 35) * 0.04
    return tick_s() * speed * 6.283
end
local function rot_point(cx, cy, x, y, angle)
    local dx, dy = x - cx, y - cy
    local c, s = math.cos(angle), math.sin(angle)
    return cx + dx * c - dy * s, cy + dx * s + dy * c
end
local function draw_line(x1, y1, x2, y2, col, thick, outline)
    if outline and settings.bool("april_crosshair_outline", true) then
        local oc = settings.color("april_crosshair_outline", { 0, 0, 0, 1 })
        local oa = { oc[1], oc[2], oc[3], (col[4] or 1) * (oc[4] or 1) }
        draw_util.line(x1, y1, x2, y2, oa, (thick or 1) + 1.5)
    end
    draw_util.line(x1, y1, x2, y2, col, thick or 1)
end
local function draw_spoke(cx, cy, angle, inner, outer, col, thick, outline)
    local x1, y1 = rot_point(cx, cy, cx, cy - inner, angle)
    local x2, y2 = rot_point(cx, cy, cx, cy - outer, angle)
    draw_line(x1, y1, x2, y2, col, thick, outline)
end
local function draw_cross(cx, cy, size, gap, thick, col, outline, spin)
    spin = spin or 0
    for i = 0, 3 do
        local a = spin + i * 1.5707963
        draw_spoke(cx, cy, a, gap, gap + size, col, thick, outline)
    end
end
local function draw_plus(cx, cy, size, thick, col, outline, spin)
    spin = spin or 0
    for i = 0, 3 do
        local a = spin + i * 1.5707963
        draw_spoke(cx, cy, a, 0, size, col, thick, outline)
    end
end
local function draw_x(cx, cy, size, thick, col, outline, spin)
    spin = spin or 0
    for _, base in ipairs({ 0.785398, 2.35619 }) do
        draw_spoke(cx, cy, spin + base, 0, size, col, thick, outline)
    end
end
local function draw_brackets(cx, cy, size, thick, col, outline)
    local w = size * 0.55
    local h = size
    draw_line(cx - w, cy - h, cx - w * 0.35, cy - h, col, thick, outline)
    draw_line(cx - w, cy - h, cx - w, cy - h * 0.35, col, thick, outline)
    draw_line(cx - w, cy + h, cx - w * 0.35, cy + h, col, thick, outline)
    draw_line(cx - w, cy + h, cx - w, cy + h * 0.35, col, thick, outline)
    draw_line(cx + w, cy - h, cx + w * 0.35, cy - h, col, thick, outline)
    draw_line(cx + w, cy - h, cx + w, cy - h * 0.35, col, thick, outline)
    draw_line(cx + w, cy + h, cx + w * 0.35, cy + h, col, thick, outline)
    draw_line(cx + w, cy + h, cx + w, cy + h * 0.35, col, thick, outline)
end
local function draw_diamond(cx, cy, size, col)
    if draw and draw.line then
        draw.line(cx, cy - size, cx + size, cy, col, 2)
        draw.line(cx + size, cy, cx, cy + size, col, 2)
        draw.line(cx, cy + size, cx - size, cy, col, 2)
        draw.line(cx - size, cy, cx, cy - size, col, 2)
    else
        draw_util.line(cx, cy - size, cx + size, cy, col, 2)
        draw_util.line(cx + size, cy, cx, cy + size, col, 2)
        draw_util.line(cx, cy + size, cx - size, cy, col, 2)
        draw_util.line(cx - size, cy, cx, cy - size, col, 2)
    end
end
local function draw_crosshair(cx, cy)
    local size = motion_scale(settings.num("april_crosshair_size", 10))
    local gap = settings.num("april_crosshair_gap", 5)
    local thick = settings.num("april_crosshair_thickness", 2)
    local col = crosshair_color()
    local outline = settings.bool("april_crosshair_outline", true)
    local kind = math.floor(settings.num("april_crosshair_type", 0) or 0)
    local spin = spin_angle()
    if kind == 1 then
        draw_util.circle(cx, cy, size, col, false)
    elseif kind == 2 then
        draw_util.circle(cx, cy, size * 0.5, col, true)
    elseif kind == 3 then
        draw_line(cx - size, cy - size * 0.45, cx + size, cy - size * 0.45, col, thick, outline)
        draw_line(cx, cy - size * 0.45, cx, cy + size, col, thick, outline)
    elseif kind == 4 then
        draw_diamond(cx, cy, size * 0.75, col)
    elseif kind == 5 then
        draw_plus(cx, cy, size, thick, col, outline, spin)
    elseif kind == 6 then
        draw_brackets(cx, cy, size, thick, col, outline)
    elseif kind == 7 then
        draw_x(cx, cy, size, thick, col, outline, spin)
    else
        draw_cross(cx, cy, size, gap, thick, col, outline, spin)
    end
    if settings.bool("april_crosshair_dot", false) then
        local dc = settings.color("april_crosshair_dot", { 1, 1, 1, 1 })
        draw_util.circle(cx, cy, math.max(1.5, thick), dc, true)
    end
end
function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)
    local root = menu_util.parent(P)
    menu_util.section(T, G.VISUALS, "Crosshair")
    menu.add_checkbox(T, G.VISUALS, P, "Custom Crosshair", false)
    menu.add_combo(T, G.VISUALS, "april_crosshair_type", "Crosshair Style", CROSS_STYLES, 0, root)
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_follow", "Follow Target", false, root)
    menu.add_combo(T, G.VISUALS, active_target.SOURCE_CROSSHAIR, "Target From",
        active_target.SOURCE_NAMES, 0, menu_util.parent("april_crosshair_follow"))
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_follow_smooth", "Follow Smoothness", 4, 40, 18,
        menu_util.parent("april_crosshair_follow"))
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_spin", "Spin", false, root)
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_spin_speed", "Spin Speed", 1, 100, 35,
        menu_util.parent("april_crosshair_spin"))
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_pulse", "Pulse Size", false, root)
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_pulse_speed", "Pulse Speed", 1, 100, 40,
        menu_util.parent("april_crosshair_pulse"))
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_color", "Crosshair Color", true,
        menu_util.parent(P, { colorpicker = { 0, 1, 0, 1 } }))
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_dot", "Center Dot", false,
        menu_util.parent(P, { colorpicker = { 1, 1, 1, 1 } }))
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_outline", "Outline", true,
        menu_util.parent(P, { colorpicker = { 0, 0, 0, 1 } }))
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_rainbow", "Rainbow", false, root)
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_rainbow_speed", "Rainbow Speed", 1, 100, 10,
        menu_util.parent("april_crosshair_rainbow"))
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_size", "Size", 1, 50, 10, root)
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_gap", "Gap", 0, 20, 5, root)
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_thickness", "Thickness", 1, 10, 2, root)
    menu_util.bind_children(P, {
        "april_crosshair_type", "april_crosshair_follow", "april_crosshair_spin", "april_crosshair_pulse",
        "april_crosshair_color", "april_crosshair_dot", "april_crosshair_outline",
        "april_crosshair_rainbow", "april_crosshair_rainbow_speed",
        "april_crosshair_size", "april_crosshair_gap", "april_crosshair_thickness",
    })
    menu_util.bind_children("april_crosshair_follow", {
        active_target.SOURCE_CROSSHAIR, "april_crosshair_follow_smooth",
    })
    menu_util.bind_children("april_crosshair_spin", { "april_crosshair_spin_speed" })
    menu_util.bind_children("april_crosshair_pulse", { "april_crosshair_pulse_speed" })
    menu_util.bind_children("april_crosshair_rainbow", { "april_crosshair_rainbow_speed" })
end
function M.update(dt)
    local cx, cy = screen_center()
    if not follow.ready then
        follow.x, follow.y = cx, cy
        follow.ready = true
    end
    local goal_x, goal_y = cx, cy
    if settings.bool("april_crosshair_follow", false) then
        local pt = active_target.get_aim_screen(nil, follow.x, follow.y, active_target.SOURCE_CROSSHAIR)
        if pt then
            goal_x, goal_y = pt.x, pt.y
        end
    end
    local alpha = follow_alpha(dt)
    follow.x = lerp(follow.x, goal_x, alpha)
    follow.y = lerp(follow.y, goal_y, alpha)
end
function M.draw()
    overlay_theme.sync()
    local cx, cy = screen_center()
    if settings.bool("april_crosshair_follow", false) and follow.ready then
        cx, cy = follow.x, follow.y
    end
    if settings.enabled(P) then
        draw_crosshair(cx, cy)
    end
end
return M
end)()

April._mods["features.visuals.crosshair"] = (function()
return April.require("features.visuals.target_visuals")
end)()

April._mods["features.world.world_esp"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local maps = April.require("game.esp_maps")
local esp_scan = April.require("game.esp_scan")
local gpu_chams = April.require("core.gpu_chams")
local M = {}
local P = "april_world_enabled"
local CHAMS_ID = "april_world_chams"
local CHAMS_MODE = "april_world_chams_mode"
local CHAMS_COLOR = "april_world_chams_color"
local function world_chams_labels()
    local labels = {}
    for i, t in ipairs(maps.WORLD_TOGGLES) do
        labels[i] = t.label
    end
    return labels
end
local function world_chams_index_for(toggle_id)
    for i, t in ipairs(maps.WORLD_TOGGLES) do
        if t.id == toggle_id then return i end
    end
    return nil
end
local function world_chams_active()
    if not gpu_chams.available() then return false end
    if not settings.enabled(P) then return false end
    for i = 1, #maps.WORLD_TOGGLES do
        if gpu_chams.multicombo_selected(CHAMS_ID, i) then
            return true
        end
    end
    return false
end
local function collect_world_chams(applied)
    local me = env.get_local_player()
    local me_pos = me and me.position
    if not me_pos then return end
    local range = settings.num("april_world_range", 500)
    local range_sq = range * range
    for _, entry in ipairs(cache.world) do
        if not env.is_valid(entry.inst) then goto continue end
        local idx = world_chams_index_for(entry.toggle_id)
        if not idx or not gpu_chams.multicombo_selected(CHAMS_ID, idx) then goto continue end
        if not settings.enabled(entry.toggle_id) then goto continue end
        local lx, ly, lz = esp_scan.entry_coords(entry)
        if not lx then goto continue end
        local dx = lx - me_pos.x
        local dy = ly - me_pos.y
        local dz = lz - me_pos.z
        if (dx * dx + dy * dy + dz * dz) > range_sq then goto continue end
        gpu_chams.cham_entry_part(entry, applied)
        ::continue::
    end
end
M._static = {}
M._dynamic = {}
local function rebuild_cache()
    cache.world = {}
    for _, entry in ipairs(M._static) do
        table.insert(cache.world, entry)
    end
    for _, entry in ipairs(M._dynamic) do
        table.insert(cache.world, entry)
    end
end
local function refresh_dynamic_positions(list)
    if not list or #list == 0 then return end
    for _, entry in ipairs(list) do
        if entry and env.is_valid(entry.inst) then
            esp_scan.refresh_entry_position(entry)
        end
    end
end
function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    menu_util.section(T, G.WORLD, "Resources")
    menu_util.register_keybind(T, G.WORLD, P, "Resource ESP", false)
    for _, t in ipairs(maps.WORLD_TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
    end
    menu.add_checkbox(T, G.WORLD, "april_world_boxes", "Resource 3D Boxes", false, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_world_show_name", "Resource Show Name", true, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_world_show_distance", "Resource Show Distance", true, { parent = P })
    menu_util.gap(T, G.WORLD)
    menu.add_slider_int(T, G.WORLD, "april_world_range", "Resource Range", 50, 2000, 500, { parent = P })
    local child_ids = { "april_world_boxes", "april_world_show_name", "april_world_show_distance", "april_world_range" }
    local toggle_ids = {}
    for _, t in ipairs(maps.WORLD_TOGGLES) do
        child_ids[#child_ids + 1] = t.id
        toggle_ids[#toggle_ids + 1] = t.id
    end
    local chams_ids = {}
    if gpu_chams.available() then
        menu_util.section(T, G.WORLD, "Resource Mesh Chams")
        chams_ids = gpu_chams.wire_esp_chams({
            tab = T,
            group = G.WORLD,
            parent = P,
            chams_id = CHAMS_ID,
            mode_id = CHAMS_MODE,
            color_id = CHAMS_COLOR,
            labels = world_chams_labels(),
            owner_id = "world",
            master_id = P,
            is_active = world_chams_active,
            collect = collect_world_chams,
            rescan_ms = 900,
            toggle_ids = toggle_ids,
        })
    end
    for _, id in ipairs(chams_ids) do
        child_ids[#child_ids + 1] = id
    end
    menu_util.bind_children(P, child_ids)
end
function M.begin_static_scan()
    return {
        phase = 1,
        node_state = esp_scan.create_folder_scan(maps.NODE_FOLDERS, maps.NODE_MAP, maps.NODE_LABELS, false),
        plant_state = esp_scan.create_folder_scan(maps.PLANT_FOLDERS, maps.PLANT_MAP, maps.PLANT_LABELS, false),
        out = {},
    }
end
function M.step_static_scan(state, batch)
    if state.phase == 1 then
        local done = esp_scan.folder_scan_step(state.node_state, batch)
        if done then
            state.phase = 2
        end
        return false
    end
    local done = esp_scan.folder_scan_step(state.plant_state, batch)
    if done then
        state.out = {}
        for _, entry in ipairs(state.node_state.out) do
            table.insert(state.out, entry)
        end
        for _, entry in ipairs(state.plant_state.out) do
            table.insert(state.out, entry)
        end
    end
    return done
end
function M.complete_static_scan(state)
    M._static = esp_scan.merge_entries(M._static, state.out)
    rebuild_cache()
    cache.stats.last_world_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end
function M.begin_dynamic_scan()
    return esp_scan.create_folder_scan(maps.ANIMAL_FOLDERS, maps.ANIMAL_MAP, maps.ANIMAL_LABELS, true)
end
function M.step_dynamic_scan(state, batch)
    return esp_scan.folder_scan_step(state, batch)
end
function M.complete_dynamic_scan(state)
    M._dynamic = esp_scan.merge_entries(M._dynamic, state.out)
    rebuild_cache()
end
function M.update(_dt)
    local world_on = settings.enabled(P)
    if world_on then
        if cache.should_prune() then
            cache.prune_invalid(M._static)
            cache.prune_invalid(M._dynamic)
            rebuild_cache()
        end
        if cache.should_refresh_positions() then
            if #M._dynamic > 0 then
                refresh_dynamic_positions(M._dynamic)
            end
        end
    end
    if gpu_chams.available() then
        local owner = gpu_chams.get_owner("world")
        if world_chams_active() or (owner and (owner.was_active or next(owner.applied))) then
            gpu_chams.sync_owner("world")
        end
    end
end
function M.draw()
    if not settings.enabled(P) then return end
    local range = settings.num("april_world_range", 500)
    local range_sq = range * range
    local draw_boxes = settings.enabled("april_world_boxes")
    local show_name = settings.bool("april_world_show_name", true)
    local show_dist = settings.bool("april_world_show_distance", true)
    local me = env.get_local_player()
    local me_pos = me and me.position
    local text_size = esp_util.text_size()
    for _, entry in ipairs(cache.world) do
        if not settings.enabled(entry.toggle_id) then goto continue end
        if not env.is_valid(entry.inst) then goto continue end
        local lx, ly, lz = esp_scan.entry_coords(entry)
        if not lx then goto continue end
        local dist_sq = 0
        if me_pos then
            local dx = lx - me_pos.x
            local dy = ly - me_pos.y
            local dz = lz - me_pos.z
            dist_sq = dx * dx + dy * dy + dz * dz
            if dist_sq > range_sq then goto continue end
        end
        local col = settings.color(entry.toggle_id, maps.toggle_color(maps.WORLD_TOGGLES, entry.toggle_id))
        if draw_boxes then
            esp_util.draw_entry_boxes(entry, col, 1)
        end
        if show_name or show_dist then
            local sx, sy, vis = esp_util.w2s(lx, ly, lz)
            if vis then
                local label = show_name and (entry.name or "?") or ""
                if show_dist and me_pos then
                    local dist_text = string.format("%dm", math.floor(math.sqrt(dist_sq)))
                    if label ~= "" then
                        label = label .. " [" .. dist_text .. "]"
                    else
                        label = dist_text
                    end
                end
                if label ~= "" then
                    draw_util.text_centered(sx, sy, label, col, text_size)
                end
            end
        end
        ::continue::
    end
end
return M
end)()

April._mods["features.world.loot_esp"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local folders = April.require("game.folders")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local maps = April.require("game.esp_maps")
local esp_scan = April.require("game.esp_scan")
local gpu_chams = April.require("core.gpu_chams")
local M = {}
local P = "april_loot_enabled"
local CHAMS_ID = "april_loot_chams"
local CHAMS_MODE = "april_loot_chams_mode"
local CHAMS_COLOR = "april_loot_chams_color"
M._static = {}
M._drops = {}
local UNLIMITED_RANGE = {
    april_timed_crate = true,
    april_care_package = true,
    april_btr_crate = true,
}
local function loot_chams_labels()
    local labels = {}
    for i, t in ipairs(maps.LOOT_TOGGLES) do
        labels[i] = t.label
    end
    return labels
end
local function loot_chams_index_for(toggle_id)
    for i, t in ipairs(maps.LOOT_TOGGLES) do
        if t.id == toggle_id then return i end
    end
    return nil
end
local function loot_chams_active()
    if not gpu_chams.available() then return false end
    if not settings.enabled(P) then return false end
    for i = 1, #maps.LOOT_TOGGLES do
        if gpu_chams.multicombo_selected(CHAMS_ID, i) then
            return true
        end
    end
    return false
end
local function collect_loot_chams(applied)
    local me = env.get_local_player()
    local me_pos = me and me.position
    if not me_pos then return end
    local range = settings.num("april_loot_range", 300)
    local range_sq = range * range
    for _, entry in ipairs(cache.loot) do
        if not env.is_valid(entry.inst) then goto continue end
        local idx = loot_chams_index_for(entry.toggle_id)
        if not idx or not gpu_chams.multicombo_selected(CHAMS_ID, idx) then goto continue end
        if not settings.enabled(entry.toggle_id) then goto continue end
        local lx, ly, lz = esp_scan.entry_coords(entry)
        if not lx then goto continue end
        if not UNLIMITED_RANGE[entry.toggle_id] then
            local dx = lx - me_pos.x
            local dy = ly - me_pos.y
            local dz = lz - me_pos.z
            if (dx * dx + dy * dy + dz * dz) > range_sq then goto continue end
        end
        gpu_chams.cham_entry_part(entry, applied)
        ::continue::
    end
end
local STATIC_SOURCES = {
    { kind = "root", key = "loners" },
    { kind = "root", key = "vegetation" },
    { kind = "root", key = "events" },
    { kind = "nested", key = "military" },
    { kind = "nested", key = "monuments" },
}
local function rebuild_cache()
    cache.loot = {}
    for _, entry in ipairs(M._static) do
        table.insert(cache.loot, entry)
    end
    for _, entry in ipairs(M._drops) do
        table.insert(cache.loot, entry)
    end
end
local function refresh_dynamic_positions(list)
    if not list or #list == 0 then return end
    for _, entry in ipairs(list) do
        if entry and env.is_valid(entry.inst) then
            esp_scan.refresh_entry_position(entry)
        end
    end
end
local function loot_display_name(model, base_name)
    if base_name == "Sleeper" then
        local label = env.safe_call(function()
            local desc = model:get_descendants()
            for _, d in ipairs(desc or {}) do
                if (d.ClassName or d.class_name) == "TextLabel" then
                    local text = d.Text or d.text
                    if text and text ~= "" then return text .. " (Sleeper)" end
                end
            end
            return nil
        end)
        if label then return label end
    elseif base_name == "Timed Crate" then
        local extra = env.safe_call(function()
            local desc = model:get_descendants()
            for _, d in ipairs(desc or {}) do
                if (d.ClassName or d.class_name) == "TextLabel" then
                    local text = d.Text or d.text
                    if text and text ~= "" then return text end
                end
            end
            return nil
        end)
        if extra then return base_name .. " (" .. extra .. ")" end
    end
    return base_name
end
local function append_loot_model(out, model, base_name, toggle_id, dynamic)
    if not env.is_valid(model) then return end
    local display = loot_display_name(model, base_name)
    table.insert(out, esp_scan.make_entry(model, display, toggle_id, { dynamic = dynamic }))
end
local function collect_loot_container(container, type_name, toggle_id, out, dynamic)
    if not env.is_valid(container) then return end
    local cn = container.ClassName or container.class_name
    if cn == "Model" then
        append_loot_model(out, container, type_name, toggle_id, dynamic)
        return
    end
    local subs = env.safe_call(function() return container:get_children() end) or {}
    for _, model in ipairs(subs) do
        append_loot_model(out, model, type_name, toggle_id, dynamic)
    end
end
function M.begin_static_scan()
    return {
        si = 1,
        phase = "top",
        ci = 1,
        sub_ci = 1,
        children = nil,
        subs = nil,
        current = nil,
        out = {},
    }
end
function M.step_static_scan(state, batch)
    local processed = 0
    while processed < batch do
        if state.si > #STATIC_SOURCES then
            return true
        end
        local source = STATIC_SOURCES[state.si]
        if not state.children then
            state.phase = "top"
            state.ci = 1
            state.sub_ci = 1
            state.subs = nil
            state.current = nil
            state.children = env.safe_call(function()
                local folder = folders.from_key(source.key)
                if not env.is_valid(folder) then return {} end
                return folder:get_children()
            end) or {}
        end
        if state.ci > #state.children then
            state.si = state.si + 1
            state.children = nil
            goto continue
        end
        local child = state.children[state.ci]
        if state.phase == "top" then
            if not env.is_valid(child) then
                state.ci = state.ci + 1
                processed = processed + 1
                goto continue
            end
            local name = child.Name or child.name
            local toggle_id = name and maps.LOOT_MAP[name]
            if toggle_id then
                collect_loot_container(child, name, toggle_id, state.out, false)
                state.ci = state.ci + 1
                processed = processed + 1
            elseif source.kind == "nested" then
                state.current = child
                state.subs = env.safe_call(function() return child:get_children() end) or {}
                state.sub_ci = 1
                state.phase = "nested"
            else
                state.ci = state.ci + 1
                processed = processed + 1
            end
        else
            if not state.subs or state.sub_ci > #state.subs then
                state.phase = "top"
                state.ci = state.ci + 1
                state.current = nil
                state.subs = nil
                goto continue
            end
            local sub = state.subs[state.sub_ci]
            state.sub_ci = state.sub_ci + 1
            processed = processed + 1
            if not env.is_valid(sub) then goto continue end
            local sub_name = sub.Name or sub.name
            local sub_tid = sub_name and maps.LOOT_MAP[sub_name]
            if sub_tid then
                collect_loot_container(sub, sub_name, sub_tid, state.out, false)
            end
        end
        ::continue::
    end
    return false
end
function M.complete_static_scan(state)
    M._static = esp_scan.merge_entries(M._static, state.out)
    rebuild_cache()
    cache.stats.last_loot_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end
function M.begin_drops_scan()
    return { ci = 1, children = nil, out = {} }
end
function M.step_drops_scan(state, batch)
    if not state.children then
        state.children = env.safe_call(function()
            local drops = folders.from_key("drops")
            if not env.is_valid(drops) then return {} end
            return drops:get_children()
        end) or {}
        state.ci = 1
    end
    local processed = 0
    while processed < batch and state.ci <= #state.children do
        local model = state.children[state.ci]
        state.ci = state.ci + 1
        processed = processed + 1
        if not env.is_valid(model) then goto continue end
        local name = model.Name or model.name
        if name and name ~= "" then
            append_loot_model(state.out, model, name, "april_dropped_item", true)
        end
        ::continue::
    end
    return state.ci > #state.children
end
function M.complete_drops_scan(state)
    M._drops = esp_scan.merge_entries(M._drops, state.out)
    rebuild_cache()
end
function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    menu_util.section(T, G.WORLD, "Loot")
    menu_util.register_keybind(T, G.WORLD, P, "Loot ESP", false)
    for _, t in ipairs(maps.LOOT_TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
    end
    menu.add_checkbox(T, G.WORLD, "april_loot_boxes", "Loot 3D Boxes", false, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_loot_show_name", "Loot Show Name", true, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_loot_show_distance", "Loot Show Distance", true, { parent = P })
    menu_util.gap(T, G.WORLD)
    menu.add_slider_int(T, G.WORLD, "april_loot_range", "Loot Range", 50, 2000, 300, { parent = P })
    local child_ids = { "april_loot_boxes", "april_loot_show_name", "april_loot_show_distance", "april_loot_range" }
    local toggle_ids = {}
    for _, t in ipairs(maps.LOOT_TOGGLES) do
        child_ids[#child_ids + 1] = t.id
        toggle_ids[#toggle_ids + 1] = t.id
    end
    local chams_ids = {}
    if gpu_chams.available() then
        menu_util.section(T, G.WORLD, "Loot Mesh Chams")
        chams_ids = gpu_chams.wire_esp_chams({
            tab = T,
            group = G.WORLD,
            parent = P,
            chams_id = CHAMS_ID,
            mode_id = CHAMS_MODE,
            color_id = CHAMS_COLOR,
            labels = loot_chams_labels(),
            owner_id = "loot",
            master_id = P,
            is_active = loot_chams_active,
            collect = collect_loot_chams,
            rescan_ms = 1200,
            toggle_ids = toggle_ids,
        })
    end
    for _, id in ipairs(chams_ids) do
        child_ids[#child_ids + 1] = id
    end
    menu_util.bind_children(P, child_ids)
end
function M.update(_dt)
    local map_loot = settings.enabled("april_map_enabled") and settings.enabled("april_map_show_loot")
    local loot_on = settings.enabled(P)
    if loot_on or map_loot then
        if cache.should_prune() then
            cache.prune_invalid(M._static)
            cache.prune_invalid(M._drops)
            rebuild_cache()
        end
        if cache.should_refresh_positions() then
            if #M._drops > 0 then
                refresh_dynamic_positions(M._drops)
            end
        end
    end
    if gpu_chams.available() then
        local owner = gpu_chams.get_owner("loot")
        if loot_chams_active() or (owner and (owner.was_active or next(owner.applied))) then
            gpu_chams.sync_owner("loot")
        end
    end
end
function M.draw()
    if not settings.enabled(P) then return end
    local range = settings.num("april_loot_range", 300)
    local range_sq = range * range
    local draw_boxes = settings.enabled("april_loot_boxes")
    local show_name = settings.bool("april_loot_show_name", true)
    local show_dist = settings.bool("april_loot_show_distance", true)
    local me = env.get_local_player()
    local me_pos = me and me.position
    local text_size = esp_util.text_size()
    for _, entry in ipairs(cache.loot) do
        if not settings.enabled(entry.toggle_id) then goto continue end
        if not env.is_valid(entry.inst) then goto continue end
        local lx, ly, lz = esp_scan.entry_coords(entry)
        if not lx then goto continue end
        local dist_sq = 0
        if me_pos then
            local dx = lx - me_pos.x
            local dy = ly - me_pos.y
            local dz = lz - me_pos.z
            dist_sq = dx * dx + dy * dy + dz * dz
            if not UNLIMITED_RANGE[entry.toggle_id] and dist_sq > range_sq then goto continue end
        end
        local col = settings.color(entry.toggle_id, maps.toggle_color(maps.LOOT_TOGGLES, entry.toggle_id))
        if draw_boxes then
            esp_util.draw_entry_boxes(entry, col, 1)
        end
        if show_name or show_dist then
            local sx, sy, vis = esp_util.w2s(lx, ly, lz)
            if vis then
                local label = show_name and (entry.name or "Loot") or ""
                if show_dist and me_pos then
                    local dist_text = string.format("%dm", math.floor(math.sqrt(dist_sq)))
                    if label ~= "" then
                        label = label .. " [" .. dist_text .. "]"
                    else
                        label = dist_text
                    end
                end
                if label ~= "" then
                    draw_util.text_centered(sx, sy, label, col, text_size)
                end
            end
        end
        ::continue::
    end
end
return M
end)()

April._mods["features.world.base_esp"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local folders = April.require("game.folders")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local maps = April.require("game.esp_maps")
local turret_stats = April.require("game.turret_stats")
local desync_vis = April.require("core.desync_vis")
local esp_scan = April.require("game.esp_scan")
local gpu_chams = April.require("core.gpu_chams")
local M = {}
local P = "april_base_enabled"
local CHAMS_ID = "april_base_chams"
local CHAMS_MODE = "april_base_chams_mode"
local CHAMS_COLOR = "april_base_chams_color"
M._static = {}
local function base_chams_labels()
    local labels = {}
    for i, t in ipairs(maps.BASE_TOGGLES) do
        labels[i] = t.label
    end
    return labels
end
local function base_chams_index_for(toggle_id)
    for i, t in ipairs(maps.BASE_TOGGLES) do
        if t.id == toggle_id then return i end
    end
    return nil
end
local function base_chams_active()
    if not gpu_chams.available() then return false end
    if not settings.enabled(P) then return false end
    for i = 1, #maps.BASE_TOGGLES do
        if gpu_chams.multicombo_selected(CHAMS_ID, i) then
            return true
        end
    end
    return false
end
local function collect_base_chams(applied)
    local me = env.get_local_player()
    local me_pos = me and me.position
    if not me_pos then return end
    local range = settings.num("april_base_range", 150)
    local range_sq = range * range
    for _, entry in ipairs(cache.base) do
        if not env.is_valid(entry.inst) then goto continue end
        local idx = base_chams_index_for(entry.toggle_id)
        if not idx or not gpu_chams.multicombo_selected(CHAMS_ID, idx) then goto continue end
        if not settings.enabled(entry.toggle_id) then goto continue end
        local lx, ly, lz = esp_scan.entry_coords(entry)
        if not lx then goto continue end
        local dx = lx - me_pos.x
        local dy = ly - me_pos.y
        local dz = lz - me_pos.z
        if (dx * dx + dy * dy + dz * dz) > range_sq then goto continue end
        gpu_chams.cham_entry_part(entry, applied)
        ::continue::
    end
end
local function rebuild_cache()
    cache.base = {}
    for _, entry in ipairs(M._static) do
        table.insert(cache.base, entry)
    end
end
local function append_base_model(out, model, type_name, toggle_id)
    if not env.is_valid(model) then return end
    if not esp_scan.find_main_part(model) and not esp_scan.is_part(model) then return end
    table.insert(out, esp_scan.make_entry(model, type_name, toggle_id, { dynamic = false }))
end
local function collect_base_container(container, type_name, toggle_id, out)
    if not env.is_valid(container) then return end
    if type_name == "Sleeping Bag" then
        local bag = env.safe_call(function()
            return container:find_first_child("SleepingBag")
                or container:FindFirstChild("SleepingBag")
                or container:find_first_child("Sleeping_Bag")
                or container:FindFirstChild("Sleeping_Bag")
        end)
        if bag and env.is_valid(bag) then
            append_base_model(out, bag, type_name, toggle_id)
            return
        end
    end
    local cn = container.ClassName or container.class_name
    if cn == "Model" or esp_scan.is_part(container) then
        append_base_model(out, container, type_name, toggle_id)
        return
    end
    local subs = env.safe_call(function() return container:get_children() end) or {}
    for _, model in ipairs(subs) do
        local mc = model.ClassName or model.class_name
        if mc == "Model" or esp_scan.is_part(model) or esp_scan.find_main_part(model) then
            append_base_model(out, model, type_name, toggle_id)
        end
    end
end
function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    menu_util.section(T, G.WORLD, "Bases")
    menu_util.register_keybind(T, G.WORLD, P, "Base ESP", false)
    for _, t in ipairs(maps.BASE_TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
        if t.ring_id then
            menu.add_checkbox(T, G.WORLD, t.ring_id, t.label .. " Range Ring", false, { parent = t.id })
        end
    end
    menu.add_checkbox(T, G.WORLD, "april_base_boxes", "Base 3D Boxes", false, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_base_show_name", "Base Show Name", true, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_base_show_distance", "Base Show Distance", false, { parent = P })
    menu_util.gap(T, G.WORLD)
    menu.add_slider_int(T, G.WORLD, "april_base_range", "Base Range", 50, 500, 150, { parent = P })
    local child_ids = { "april_base_boxes", "april_base_show_name", "april_base_show_distance", "april_base_range" }
    local toggle_ids = {}
    for _, t in ipairs(maps.BASE_TOGGLES) do
        child_ids[#child_ids + 1] = t.id
        toggle_ids[#toggle_ids + 1] = t.id
        if t.ring_id then
            child_ids[#child_ids + 1] = t.ring_id
        end
    end
    local chams_ids = {}
    if gpu_chams.available() then
        menu_util.section(T, G.WORLD, "Base Mesh Chams")
        chams_ids = gpu_chams.wire_esp_chams({
            tab = T,
            group = G.WORLD,
            parent = P,
            chams_id = CHAMS_ID,
            mode_id = CHAMS_MODE,
            color_id = CHAMS_COLOR,
            labels = base_chams_labels(),
            owner_id = "base",
            master_id = P,
            is_active = base_chams_active,
            collect = collect_base_chams,
            rescan_ms = 900,
            toggle_ids = toggle_ids,
        })
    end
    for _, id in ipairs(chams_ids) do
        child_ids[#child_ids + 1] = id
    end
    menu_util.bind_children(P, child_ids)
end
function M.begin_static_scan()
    return {
        ai = 1,
        phase = "top",
        ci = 1,
        sub_ci = 1,
        areas = nil,
        children = nil,
        subs = nil,
        out = {},
    }
end
function M.step_static_scan(state, batch)
    if not state.areas then
        state.areas = env.safe_call(function()
            local bases = folders.from_key("bases")
            if not env.is_valid(bases) then return {} end
            return bases:get_children()
        end) or {}
        state.ai = 1
    end
    local processed = 0
    while processed < batch do
        if state.ai > #state.areas then
            return true
        end
        local area = state.areas[state.ai]
        if not state.children then
            if not env.is_valid(area) then
                state.ai = state.ai + 1
                processed = processed + 1
                goto continue
            end
            local area_name = area.Name or area.name or ""
            if maps.BASE_SKIP_AREAS[area_name] then
                state.ai = state.ai + 1
                processed = processed + 1
                goto continue
            end
            state.phase = "top"
            state.ci = 1
            state.sub_ci = 1
            state.subs = nil
            if maps.BASE_MAP[area_name] then
                state.children = { area }
            else
                state.children = env.safe_call(function() return area:get_children() end) or {}
            end
        end
        if state.ci > #state.children then
            state.ai = state.ai + 1
            state.children = nil
            state.subs = nil
            goto continue
        end
        local child = state.children[state.ci]
        if state.phase == "top" then
            if not env.is_valid(child) then
                state.ci = state.ci + 1
                processed = processed + 1
                goto continue
            end
            local name = child.Name or child.name
            local toggle_id = name and maps.BASE_MAP[name]
            if toggle_id then
                state.subs = env.safe_call(function()
                    local cn = child.ClassName or child.class_name
                    if cn == "Model" or esp_scan.is_part(child) then
                        return { child }
                    end
                    if name == "Sleeping Bag" then
                        local bag = child:find_first_child("SleepingBag")
                            or child:FindFirstChild("SleepingBag")
                            or child:find_first_child("Sleeping_Bag")
                            or child:FindFirstChild("Sleeping_Bag")
                        if bag then return { bag } end
                    end
                    return child:get_children()
                end) or {}
                state.sub_ci = 1
                state.phase = "models"
                state._type_name = name
                state._toggle_id = toggle_id
            else
                state.ci = state.ci + 1
                processed = processed + 1
            end
        else
            if not state.subs or state.sub_ci > #state.subs then
                state.phase = "top"
                state.ci = state.ci + 1
                state.subs = nil
                state._type_name = nil
                state._toggle_id = nil
                goto continue
            end
            local model = state.subs[state.sub_ci]
            state.sub_ci = state.sub_ci + 1
            processed = processed + 1
            if env.is_valid(model) then
                append_base_model(state.out, model, state._type_name, state._toggle_id)
            end
        end
        ::continue::
    end
    return false
end
function M.complete_static_scan(state)
    M._static = esp_scan.merge_entries(M._static, state.out)
    rebuild_cache()
    cache.stats.last_base_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end
function M.update(_dt)
    local map_base = settings.enabled("april_map_enabled") and settings.enabled("april_map_show_base")
    local base_on = settings.enabled(P)
    if base_on or map_base then
        if cache.should_prune() then
            cache.prune_invalid(M._static)
            rebuild_cache()
        end
    end
    if gpu_chams.available() then
        local owner = gpu_chams.get_owner("base")
        if base_chams_active() or (owner and (owner.was_active or next(owner.applied))) then
            gpu_chams.sync_owner("base")
        end
    end
end
function M.draw()
    if not settings.enabled(P) then return end
    local range = settings.num("april_base_range", 150)
    local range_sq = range * range
    local draw_boxes = settings.enabled("april_base_boxes")
    local show_name = settings.bool("april_base_show_name", true)
    local show_dist = settings.bool("april_base_show_distance", false)
    local me = env.get_local_player()
    local me_pos = me and me.position
    local text_size = esp_util.text_size()
    for _, entry in ipairs(cache.base) do
        if not settings.enabled(entry.toggle_id) then goto continue end
        if not env.is_valid(entry.inst) then goto continue end
        local lx, ly, lz = esp_scan.entry_coords(entry)
        if not lx then goto continue end
        local dist_sq = 0
        if me_pos then
            local dx = lx - me_pos.x
            local dy = ly - me_pos.y
            local dz = lz - me_pos.z
            dist_sq = dx * dx + dy * dy + dz * dz
            if dist_sq > range_sq then goto continue end
        end
        local col = settings.color(entry.toggle_id, maps.toggle_color(maps.BASE_TOGGLES, entry.toggle_id))
        if draw_boxes then
            esp_util.draw_entry_boxes(entry, col, 1)
        end
        local ring_id = maps.turret_ring_toggle(entry.toggle_id)
        if ring_id and settings.enabled(ring_id) then
            local activation = turret_stats.activation_range(entry.name)
            if activation then
                desync_vis.draw_sphere_ring(lx, ly, lz, activation, { col[1], col[2], col[3], 0.35 }, 1.5)
            end
        end
        if show_name or show_dist then
            local sx, sy, vis = esp_util.w2s(lx, ly, lz)
            if vis then
                local label = show_name and (entry.name or "Base") or ""
                if show_dist and me_pos then
                    local dist_text = string.format("%dm", math.floor(math.sqrt(dist_sq)))
                    if label ~= "" then
                        label = label .. " [" .. dist_text .. "]"
                    else
                        label = dist_text
                    end
                end
                if label ~= "" then
                    draw_util.text_centered(sx, sy, label, col, text_size)
                end
            end
        end
        ::continue::
    end
end
return M
end)()

April._mods["features.world.npc_esp"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local npcs = April.require("game.npcs")
local M = {}
local P = "april_npc_enabled"
local HP_TTL_MS = 250
local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end
local function migrate_legacy_types()
    if M._legacy_migrated then return end
    M._legacy_migrated = true
    if not menu or not menu.set then return end
    if settings.bool("april_npc_soldiers", false) then
        menu.set("april_npc_soldier", true)
        if menu.set_color then
            menu.set_color("april_npc_soldier", settings.color("april_npc_soldiers", { 1, 0.3, 0.3, 1 }))
        end
    end
    if settings.bool("april_npc_bosses", false) then
        local color = settings.color("april_npc_bosses", { 1, 0.5, 0.1, 1 })
        for _, id in ipairs({ "april_npc_bruno", "april_npc_boris", "april_npc_brutus" }) do
            menu.set(id, true)
            if menu.set_color then menu.set_color(id, color) end
        end
    end
    if settings.bool("april_npc_heli", false) then
        menu.set("april_npc_attack_heli", true)
        if menu.set_color then
            menu.set_color("april_npc_attack_heli", settings.color("april_npc_heli", { 0.85, 0.2, 0.25, 1 }))
        end
    end
end
function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    local root = menu_util.parent(P)
    menu_util.section(T, G.WORLD, "NPCs")
    menu_util.register_keybind(T, G.WORLD, P, "NPC ESP", false)
    menu.add_checkbox(T, G.WORLD, "april_npc_soldier", "Soldier", false, menu_util.parent(P, { colorpicker = { 1, 0.3, 0.3, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_bruno", "Bruno", false, menu_util.parent(P, { colorpicker = { 1, 0.65, 0.2, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_boris", "Boris", false, menu_util.parent(P, { colorpicker = { 0.78, 0.42, 1, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_brutus", "Brutus", false, menu_util.parent(P, { colorpicker = { 1, 0.3, 0.48, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_attack_heli", "Attack Heli", false, menu_util.parent(P, { colorpicker = { 0.85, 0.2, 0.25, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_btr", "BTR", false, menu_util.parent(P, { colorpicker = { 0.95, 0.25, 0.15, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_diver_dave", "Diver Dave", false, menu_util.parent(P, { colorpicker = { 0.2, 0.75, 1, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_pilot_pete", "Pilot Pete", false, menu_util.parent(P, { colorpicker = { 0.35, 1, 0.65, 1 } }))
    menu.add_combo(T, G.WORLD, "april_npc_box_mode", "NPC Box", { "None", "2D", "Corner" }, 1, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_health", "NPC Health Bar", true, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_show_name", "NPC Show Name", true,
        menu_util.parent(P, { colorpicker = { 1, 0.3, 0.3, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_show_distance", "NPC Show Distance", true,
        menu_util.parent(P, { colorpicker = { 0.82, 0.84, 0.88, 0.92 } }))
    menu_util.gap(T, G.WORLD)
    menu.add_slider_int(T, G.WORLD, "april_npc_range", "NPC Range", 50, 2000, 500, root)
    menu_util.bind_children(P, {
        "april_npc_soldier", "april_npc_bruno", "april_npc_boris", "april_npc_brutus",
        "april_npc_attack_heli", "april_npc_btr", "april_npc_diver_dave", "april_npc_pilot_pete",
        "april_npc_box_mode", "april_npc_health",
        "april_npc_show_name", "april_npc_show_distance",
        "april_npc_range",
    })
end
local function entity_bounds(player)
    if not player then return nil end
    local fn = player.GetBounds or player.get_bounds
    if not fn then return nil end
    return fn(player)
end
local function event_health(entry)
    local now = tick_ms()
    if entry.hp_t and now - entry.hp_t < HP_TTL_MS then
        return entry.hp, entry.max_hp
    end
    local health = npcs.read_health(entry.inst, entry.humanoid)
    entry.hp_t = now
    entry.hp = health and health.hp or nil
    entry.max_hp = health and (health.max_hp or health.hp) or nil
    return entry.hp, entry.max_hp
end
local function event_bounds(entry, dist)
    if not entry.root or not env.is_valid(entry.root) then return nil end
    local x, y, z = esp_util.vec3_pos(entry.root.Position or entry.root.position)
    if not x then return nil end
    entry.lx, entry.ly, entry.lz = x, y, z
    local vehicle = entry.vehicle == true
    return esp_util.head_body_screen_bounds(x, y, z, {
        dist = dist,
        body_h = vehicle and 8.0 or 5.0,
        width_mul = vehicle and 1.15 or 0.52,
        top_pad = vehicle and 2.0 or 0.35,
        bot_pad = vehicle and 2.0 or 0.15,
    })
end
function M.draw()
    migrate_legacy_types()
    if not settings.enabled(P) then return end
    local list = cache.npcs
    if not list or #list == 0 then return end
    local range = settings.num("april_npc_range", 500)
    local range_sq = range * range
    local box_mode = settings.num("april_npc_box_mode", 1)
    local show_health = settings.bool("april_npc_health", true)
    local show_name = settings.bool("april_npc_show_name", true)
    local show_dist = settings.bool("april_npc_show_distance", true)
    local enabled = {
        soldier = settings.bool("april_npc_soldier", false),
        bruno = settings.bool("april_npc_bruno", false),
        boris = settings.bool("april_npc_boris", false),
        brutus = settings.bool("april_npc_brutus", false),
        heli = settings.bool("april_npc_attack_heli", false),
        btr = settings.bool("april_npc_btr", false),
        diver_dave = settings.bool("april_npc_diver_dave", false),
        pilot_pete = settings.bool("april_npc_pilot_pete", false),
    }
    if not (enabled.soldier or enabled.bruno or enabled.boris or enabled.brutus
        or enabled.heli or enabled.btr or enabled.diver_dave or enabled.pilot_pete)
    then
        return
    end
    local colors = {
        soldier = settings.color("april_npc_soldier", { 1, 0.3, 0.3, 1 }),
        bruno = settings.color("april_npc_bruno", { 1, 0.65, 0.2, 1 }),
        boris = settings.color("april_npc_boris", { 0.78, 0.42, 1, 1 }),
        brutus = settings.color("april_npc_brutus", { 1, 0.3, 0.48, 1 }),
        heli = settings.color("april_npc_attack_heli", { 0.85, 0.2, 0.25, 1 }),
        btr = settings.color("april_npc_btr", { 0.95, 0.25, 0.15, 1 }),
        diver_dave = settings.color("april_npc_diver_dave", { 0.2, 0.75, 1, 1 }),
        pilot_pete = settings.color("april_npc_pilot_pete", { 0.35, 1, 0.65, 1 }),
    }
    local col_name = settings.color("april_npc_show_name", { 1, 0.3, 0.3, 1 })
    local col_dist = settings.color("april_npc_show_distance", { 0.82, 0.84, 0.88, 0.92 })
    local text_size = esp_util.text_size()
    local me = cache.local_player or env.get_local_player()
    local mx, my, mz = nil, nil, nil
    if me then
        mx, my, mz = esp_util.vec3_pos(me.Position or me.position)
    end
    for i = 1, #list do
        local entry = list[i]
        if not entry then goto continue end
        if not enabled[entry.kind] then goto continue end
        local col = colors[entry.kind] or colors.soldier
        local player = entry.entity
        if player and (player.IsAlive == false or player.is_alive == false) then goto continue end
        if not player and (not entry.inst or not env.is_valid(entry.inst)) then goto continue end
        local lx, ly, lz
        if player then
            lx, ly, lz = esp_util.vec3_pos(
                player.HeadPosition or player.head_position or player.Position or player.position
            )
            if lx then entry.lx, entry.ly, entry.lz = lx, ly, lz end
        else
            lx, ly, lz = entry.lx, entry.ly, entry.lz
        end
        if not lx then goto continue end
        local dist = 0
        if mx then
            local dx = lx - mx
            local dy = ly - my
            local dz = lz - mz
            local dist_sq = dx * dx + dy * dy + dz * dz
            if dist_sq > range_sq then goto continue end
            dist = math.sqrt(dist_sq)
        end
        local bounds = player and entity_bounds(player) or event_bounds(entry, dist)
        if not esp_util.bounds_usable(bounds) then goto continue end
        local ts = text_size
        if dist > 200 then ts = math.max(9, ts - 1) end
        if dist > 400 then ts = math.max(8, ts - 1) end
        local cx = bounds.x + bounds.w * 0.5
        local label = entry.name or "NPC"
        if show_name then
            draw_util.text_centered(cx, bounds.y - ts - 5, label, col_name, ts)
        end
        if box_mode == 1 then
            draw_util.box_esp(bounds.x, bounds.y, bounds.w, bounds.h, col, 0)
        elseif box_mode == 2 then
            draw_util.box_esp(bounds.x, bounds.y, bounds.w, bounds.h, col, 1)
        end
        if show_health then
            local hp, max_hp
            if player then
                hp = tonumber(player.Health or player.health)
                max_hp = tonumber(player.MaxHealth or player.max_health)
            else
                hp, max_hp = event_health(entry)
            end
            if hp and max_hp then
                draw_util.health_bar_on_box(bounds, hp, max_hp)
            end
        end
        if show_dist and mx then
            draw_util.text_centered(
                cx,
                bounds.y + bounds.h + 3,
                string.format("%dm", math.floor(dist + 0.5)),
                col_dist,
                ts
            )
        end
        ::continue::
    end
end
return M
end)()

April._mods["features.world.raid_esp"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local env = April.require("core.env")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local menu_util = April.require("core.menu_util")
local notify = April.require("core.notify")
local M = {}
local P = "april_raid_enabled"
local ID_NOTIFY = "april_raid_notifications"
local ID_RANGE = "april_raid_range"
local CLUSTER_MERGE_M = 40
local CLUSTER_TTL_MS = 30 * 60 * 1000
local SCAN_MS = 350
local ROCKET_TRACE_SCAN_MS = 50
local ROCKET_TRACE_TTL_MS = 2500
local ROCKET_TRACE_MATCH_M = 45
local NOTIFY_DEDUP_MS = 10000
local RAID_SOUNDS = {
    c4 = { label = "Timed Charge", weight = 3 },
    dynamitebundle = { label = "Dynamite Bundle", weight = 2 },
}
local ROCKET_SIGNAL = { label = "Rocket", weight = 2 }
local IGNORE_NAMES = {
    helirocket = true,
    helicrashing = true,
    militarygrenade = true,
    landmine = true,
    dynamitestick = true,
    explosioneffect = true,
    explosionpart = true,
    explosion = true,
    projectile = true,
    boom = true,
    grenade = true,
    shell = true,
    charge = true,
    bomb = true,
}
local RAID_PROJECTILE = {
    ["timed charge"] = "Timed Charge",
    timedcharge = "Timed Charge",
    c4 = "Timed Charge",
    ["dynamite bundle"] = "Dynamite Bundle",
    dynamitebundle = "Dynamite Bundle",
}
M._processed = {}
M._last_scan = 0
M._last_trace_scan = 0
M._last_notify = {}
M._projectiles = {}
M._rocket_traces = {}
cache.raids = cache.raids or {}
local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end
local function vec_xyz(v)
    if not v then return nil end
    local x = v.X or v.x
    local y = v.Y or v.y
    local z = v.Z or v.z
    if x and y and z then return x, y, z end
    return nil
end
local function dist3(ax, ay, az, bx, by, bz)
    local dx, dy, dz = ax - bx, ay - by, az - bz
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end
local function norm_name(name)
    return tostring(name or ""):lower():gsub("[%s_%-]", "")
end
local function children_of(inst)
    if not inst then return {} end
    return env.safe_call(function()
        if inst.GetChildren then return inst:GetChildren() end
        if inst.get_children then return inst:get_children() end
        return {}
    end) or {}
end
local function instance_pos(inst)
    if not inst then return nil end
    local cn = inst.ClassName or inst.class_name or ""
    local pos = inst.Position or inst.position
    local x, y, z = vec_xyz(pos)
    if x then return x, y, z end
    if cn == "Model" or cn == "model" then
        local primary = inst.PrimaryPart or inst.primary_part
        x, y, z = vec_xyz(primary and (primary.Position or primary.position))
        if x then return x, y, z end
    end
    local ok, cf = pcall(function()
        return inst.CFrame or inst.cframe
    end)
    if ok and cf then
        return vec_xyz(cf.Position or cf.position or cf)
    end
    return nil
end
local function rocket_trace_kind(name)
    local key = norm_name(name)
    if key:find("helirocket", 1, true) then return "heli" end
    if key:find("rocket", 1, true) then return "player" end
    return nil
end
local function update_rocket_traces(vfx, now)
    if not vfx then return end
    for _, child in ipairs(children_of(vfx)) do
        local kind = rocket_trace_kind(child and (child.Name or child.name))
        if kind then
            local x, y, z = instance_pos(child)
            if x then
                local addr = tostring(child.Address or child.address or child)
                M._rocket_traces[addr] = {
                    kind = kind,
                    x = x, y = y, z = z,
                    updated = now,
                }
            end
        end
    end
    for addr, trace in pairs(M._rocket_traces) do
        if not trace or now - (trace.updated or 0) > ROCKET_TRACE_TTL_MS then
            M._rocket_traces[addr] = nil
        end
    end
end
local function rocket_source_near(x, y, z, now)
    local best_kind, best_dist = nil, ROCKET_TRACE_MATCH_M
    for _, trace in pairs(M._rocket_traces) do
        if trace and now - (trace.updated or 0) <= ROCKET_TRACE_TTL_MS then
            local dist = dist3(x, y, z, trace.x, trace.y, trace.z)
            if dist < best_dist or (dist == best_dist and trace.kind == "heli") then
                best_kind, best_dist = trace.kind, dist
            end
        end
    end
    return best_kind
end
local function sound_is_playing(snd)
    if not snd then return false end
    local playing = snd.IsPlaying or snd.is_playing or snd.Playing or snd.playing
    if playing == true then return true end
    local ok, v = pcall(function()
        if snd.IsPlaying ~= nil then return snd.IsPlaying end
        if snd.Playing ~= nil then return snd.Playing end
        return nil
    end)
    return ok and v == true
end
local function raid_signal_from_inst(inst, rocket_source)
    if not inst then return nil end
    local name = inst.Name or inst.name or ""
    local key = norm_name(name)
    if IGNORE_NAMES[key] and not RAID_SOUNDS[key] then
    elseif RAID_SOUNDS[key] then
        return RAID_SOUNDS[key].label, RAID_SOUNDS[key].weight, key
    end
    local best_label, best_weight, best_key = nil, 0, nil
    for _, child in ipairs(children_of(inst)) do
        local cn = child.ClassName or child.class_name or ""
        if cn == "Sound" or cn == "sound" then
            local skey = norm_name(child.Name or child.name)
            local info = RAID_SOUNDS[skey]
            if skey == "rocket" and rocket_source == "player" then
                info = ROCKET_SIGNAL
            end
            if info and (sound_is_playing(child) or key == "explosionpart") then
                if info.weight > best_weight then
                    best_label, best_weight, best_key = info.label, info.weight, skey
                end
            end
        end
    end
    if best_label then
        return best_label, best_weight, best_key
    end
    return nil
end
local function classify_projectile(name)
    local raw = tostring(name or ""):lower()
    local key = norm_name(name)
    if IGNORE_NAMES[key] then return nil end
    if key:find("helirocket", 1, true) or key:find("helicrash", 1, true) then
        return nil
    end
    return RAID_PROJECTILE[raw] or RAID_PROJECTILE[key]
end
local function process_raid(display, x, y, z, weight)
    local now = tick_ms()
    weight = weight or 1
    local raids = cache.raids
    local best, best_d = nil, CLUSTER_MERGE_M
    for _, cl in ipairs(raids) do
        local d = dist3(x, y, z, cl.x, cl.y, cl.z)
        if d < best_d then
            best, best_d = cl, d
        end
    end
    if best then
        best.count = (best.count or 1) + 1
        best.weight = (best.weight or 1) + weight
        best.sum_x = (best.sum_x or best.x) + x
        best.sum_y = (best.sum_y or best.y) + y
        best.sum_z = (best.sum_z or best.z) + z
        best.x = best.sum_x / best.count
        best.y = best.sum_y / best.count
        best.z = best.sum_z / best.count
        best.last_type = display
        best.last_update = now
        best.items = best.items or {}
        best.items[#best.items + 1] = { x = x, y = y, z = z, type = display }
    else
        raids[#raids + 1] = {
            x = x, y = y, z = z,
            sum_x = x, sum_y = y, sum_z = z,
            count = 1,
            weight = weight,
            last_type = display,
            last_update = now,
            items = { { x = x, y = y, z = z, type = display } },
        }
    end
    if settings.enabled(P) and settings.bool(ID_NOTIFY, true) and weight >= 2 then
        local key = string.format("%.0f:%.0f:%.0f", x * 0.1, y * 0.1, z * 0.1)
        local prev = M._last_notify[key]
        if not prev or (now - prev) > NOTIFY_DEDUP_MS then
            M._last_notify[key] = now
            notify.warning(string.format("Raid: %s at %.0f, %.0f, %.0f", display, x, y, z), 6000)
        end
    end
end
local function scan_container(container, into, now)
    if not env.is_valid(container) then return end
    for _, child in ipairs(children_of(container)) do
        if not child then goto cont end
        local name = child.Name or child.name or ""
        local cn = child.ClassName or child.class_name or ""
        local x, y, z = instance_pos(child)
        if not x then goto cont end
        local addr = tostring(child.Address or child.address or child)
        local rocket_source = rocket_source_near(x, y, z, now)
        local label, weight = raid_signal_from_inst(child, rocket_source)
        local proj_label = classify_projectile(name)
        if label then
            into[#into + 1] = {
                name = label,
                x = x, y = y, z = z,
                inst = child,
                raid = true,
            }
            if not M._processed[addr] then
                M._processed[addr] = now
                process_raid(label, x, y, z, weight)
            end
        elseif proj_label then
            into[#into + 1] = {
                name = proj_label,
                x = x, y = y, z = z,
                inst = child,
                raid = false,
            }
        elseif cn == "Explosion" and not IGNORE_NAMES[norm_name(name)] then
        end
        ::cont::
    end
end
function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    local root = menu_util.parent(P)
    menu_util.section(T, G.WORLD, "Raids")
    menu_util.register_keybind(T, G.WORLD, P, "Raid ESP", false, { colorpicker = { 1, 0.5, 0, 1 } })
    menu.add_checkbox(T, G.WORLD, ID_NOTIFY, "Raid Notifications", true, root)
    menu.add_slider_int(T, G.WORLD, ID_RANGE, "Raid ESP Range", 50, 5000, 1000, root)
    menu_util.bind_children(P, { ID_NOTIFY, ID_RANGE })
end
function M.update(_dt)
    local esp_on = settings.enabled(P)
    local map_on = settings.enabled("april_map_enabled") and settings.bool("april_map_show_raids", false)
    if not esp_on and not map_on then
        M._projectiles = {}
        M._rocket_traces = {}
        return
    end
    local now = tick_ms()
    local scan_due = (now - M._last_scan) >= SCAN_MS
    local trace_due = (now - M._last_trace_scan) >= ROCKET_TRACE_SCAN_MS
    if not scan_due and not trace_due then return end
    local ws = env.get_workspace()
    local vfx = nil
    if ws then
        vfx = env.safe_call(function()
            return ws:FindFirstChild("VFX") or ws:find_first_child("VFX")
        end)
    end
    if trace_due then
        M._last_trace_scan = now
        update_rocket_traces(vfx, now)
    end
    if not scan_due then return end
    M._last_scan = now
    for addr, t in pairs(M._processed) do
        if (now - t) > 30000 then
            M._processed[addr] = nil
        end
    end
    for i = #cache.raids, 1, -1 do
        local cl = cache.raids[i]
        if not cl or (now - (cl.last_update or 0)) > CLUSTER_TTL_MS then
            table.remove(cache.raids, i)
        end
    end
    local projectiles = {}
    if ws then
        if vfx then
            scan_container(vfx, projectiles, now)
        end
        scan_container(ws, projectiles, now)
    end
    M._projectiles = projectiles
end
function M.draw()
    if not settings.enabled(P) then return end
    local range = settings.num(ID_RANGE, 1000)
    local range_sq = range * range
    local col = settings.color(P, { 1, 0.5, 0, 1 })
    local proj_col = { 1, 0.35, 0.15, 1 }
    local text_size = esp_util.text_size()
    local me = env.get_local_player()
    local mx, my, mz = nil, nil, nil
    if me then
        mx, my, mz = esp_util.vec3_pos(me.Position or me.position or me.HeadPosition or me.head_position)
    end
    local now = tick_ms()
    for i = 1, #M._projectiles do
        local proj = M._projectiles[i]
        if not proj then goto pcont end
        local dist_sq = 0
        if mx then
            local dx, dy, dz = proj.x - mx, proj.y - my, proj.z - mz
            dist_sq = dx * dx + dy * dy + dz * dz
            if dist_sq > range_sq then goto pcont end
        end
        local sx, sy, vis = esp_util.w2s(proj.x, proj.y, proj.z)
        if vis then
            local dist = math.sqrt(dist_sq)
            local c = proj.raid and col or proj_col
            draw_util.box_esp(sx - 5, sy - 5, 10, 10, c, 0)
            draw_util.text_centered(sx, sy - text_size - 2, "[" .. tostring(proj.name) .. "]", c, text_size)
            if mx then
                draw_util.text_centered(sx, sy + 4, string.format("[%.0fm]", dist), c, text_size)
            end
        end
        ::pcont::
    end
    for i = 1, #cache.raids do
        local cl = cache.raids[i]
        if not cl then goto rcont end
        local dist_sq = 0
        if mx then
            local dx, dy, dz = cl.x - mx, cl.y - my, cl.z - mz
            dist_sq = dx * dx + dy * dy + dz * dz
            if dist_sq > range_sq then goto rcont end
        end
        local sx, sy, vis = esp_util.w2s(cl.x, cl.y, cl.z)
        if vis then
            local dist = math.sqrt(dist_sq)
            local age = math.floor((now - (cl.last_update or now)) / 1000)
            local lines = {
                string.format("Raid (%d)", cl.count or 1),
                string.format("Last: %s", tostring(cl.last_type or "Explosive")),
                string.format("Updated %ds ago", age),
            }
            if mx then
                lines[#lines + 1] = string.format("[%.0fm]", dist)
            end
            local total_h = #lines * (text_size + 2)
            local start_y = sy - total_h * 0.5
            for li = 1, #lines do
                draw_util.text_centered(sx, start_y + (li - 1) * (text_size + 2), lines[li], col, text_size)
            end
        end
        ::rcont::
    end
end
return M
end)()

April._mods["features.movement.exploits"] = (function()
local menu_util = April.require("core.menu_util")
local M = {}
function M.register_menu()
    local G = menu_util.G
    local T = menu_util.group(G.MISC)
    menu_util.section(T, G.MISC, "Movement")
    menu_util.register_keybind(T, G.MISC, "april_spider_enabled", "Spider", false)
    menu.add_slider_int(
        T,
        G.MISC,
        "april_spider_speed",
        "Spider Speed",
        18,
        30,
        18,
        menu_util.parent("april_spider_enabled")
    )
    menu_util.bind_children("april_spider_enabled", { "april_spider_speed" })
end
function M.update(_dt) end
function M.draw() end
return M
end)()

April._mods["features.movement.fling"] = (function()
local settings = April.require("core.settings")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local move = April.require("core.cframe_move")
local math_util = April.require("core.math_util")
local esp_util = April.require("core.esp_util")
local player_state = April.require("game.player_state")
local misc_gate = April.require("core.misc_gate")
local M = {}
local P = "april_fling_enabled"
local P_FOV = "april_fling_fov"
local P_DURATION = "april_fling_duration"
local MAX_DIST = 300.0
local FAR_RANGE = 40.0
local SPIN_Y_START = 48000.0
local SPIN_Y_MAX = 70000.0
local SPIN_RAMP_SEC = 0.35
local BASE_PREDICT = 0.05
local MAX_SNAP_PASSES = 10
local FLING_HIT_PARTS = { "HumanoidRootPart" }
local function fling_duration()
    return settings.num(P_DURATION, 2)
end
local STATE_IDLE = 0
local STATE_APPROACH = 1
local STATE_FLING = 2
local STATE_RETURN = 3
local RETURN_TICKS = 15
local MAX_ATTACH_DRIFT = 6.0
local _installed = false
local state = STATE_IDLE
local fling_t0 = 0
local approach_left = 0
local return_left = 0
local start_range = 0
local saved_pos = nil
local target_root = nil
local target_player = nil
local last_attach = nil
local function now()
    if utility and utility.get_time then return utility.get_time() end
    return os.clock()
end
local function screen_center()
    if input and input.get_screen_center then
        local cx, cy = input.get_screen_center()
        if cx and cy then return cx, cy end
    end
    if draw and draw.get_screen_size then
        local w, h = draw.get_screen_size()
        return w * 0.5, h * 0.5
    end
    return 960, 540
end
local function get_character(lp)
    if lp and lp.character then return lp.character end
    if game and game.local_player and game.local_player.character then
        return game.local_player.character
    end
    return nil
end
local function get_root(lp)
    local char = get_character(lp)
    if not char then return nil end
    return env.safe_call(function()
        if char.find_first_child then return char:find_first_child("HumanoidRootPart") end
        return char:FindFirstChild("HumanoidRootPart")
    end)
end
local function get_humanoid(lp)
    if lp and lp.humanoid and env.is_valid(lp.humanoid) then
        return lp.humanoid
    end
    local char = get_character(lp)
    if not char then return nil end
    return env.safe_call(function()
        if char.find_first_child_of_class then return char:find_first_child_of_class("Humanoid") end
        return char:FindFirstChildOfClass("Humanoid")
    end)
end
local function player_root(p)
    if not p or not p.character then return nil end
    local char = p.character
    return env.safe_call(function()
        if char.find_first_child then return char:find_first_child("HumanoidRootPart") end
        return char:FindFirstChild("HumanoidRootPart")
    end)
end
local function refresh_target_root()
    if not target_player then return false end
    local root = player_root(target_player)
    if root and env.is_valid(root) then
        target_root = root
        return true
    end
    return target_root ~= nil and env.is_valid(target_root)
end
local function target_still_valid()
    if not target_player then return false end
    if target_player.character and env.is_valid(target_player.character) then
        return true
    end
    if target_player.position then
        return true
    end
    return refresh_target_root()
end
local function player_aim_pos(p)
    if p.position then
        return p.position.x, p.position.y, p.position.z
    end
    if p.head_position then
        local h = p.head_position
        return h.x, h.y, h.z
    end
    local root = player_root(p)
    if root then
        local pos = move.read_pos(root)
        if pos then
            return pos.x, pos.y, pos.z
        end
    end
    return nil
end
local function world_dist_to_player(p, from)
    if not p or not from then return math.huge end
    if p.distance_to then
        return p:distance_to(from)
    end
    local ax, ay, az = player_aim_pos(p)
    if not ax or not from.x then return math.huge end
    return math_util.distance3(ax - from.x, ay - from.y, az - from.z)
end
local function find_target(fov_px)
    local cx, cy = screen_center()
    local cam = camera and camera.get_position and camera.get_position()
    local best, best_dist = nil, fov_px
    for _, p in ipairs(April.require("core.cache").players) do
        if not player_state.is_combat_target(p) then goto continue end
        if cam and world_dist_to_player(p, cam) > MAX_DIST then goto continue end
        local ax, ay, az = player_aim_pos(p)
        if not ax then goto continue end
        local sx, sy, on_screen = esp_util.w2s(ax, ay, az)
        if not on_screen then goto continue end
        local fov_dist = math_util.screen_fov_dist(sx, sy, cx, cy)
        if fov_dist > fov_px or fov_dist >= best_dist then goto continue end
        local root = player_root(p)
        if not root or not env.is_valid(root) then goto continue end
        best_dist = fov_dist
        best = p
        ::continue::
    end
    if not best then return nil, nil end
    return best, player_root(best)
end
local function read_part_velocity(inst)
    if not inst then return 0, 0, 0 end
    local vel = inst.Velocity or inst.velocity
    if vel then
        return vel.x or vel.X or 0, vel.y or vel.Y or 0, vel.z or vel.Z or 0
    end
    local assembly = inst.AssemblyLinearVelocity
    if assembly then
        return assembly.x or assembly.X or 0, assembly.y or assembly.Y or 0, assembly.z or assembly.Z or 0
    end
    return 0, 0, 0
end
local function read_target_velocity(tgt_root, far_lock)
    local ex, ey, ez = 0, 0, 0
    local px, py, pz = 0, 0, 0
    local has_entity = false
    local has_part = false
    if target_player and target_player.velocity then
        local v = target_player.velocity
        ex, ey, ez = v.x or 0, v.y or 0, v.z or 0
        has_entity = true
    end
    if tgt_root and env.is_valid(tgt_root) then
        px, py, pz = read_part_velocity(tgt_root)
        has_part = true
    end
    if far_lock and has_entity then
        return ex, ey, ez
    end
    if has_entity and has_part then
        local entity_speed = math_util.distance3(ex, ey, ez)
        local part_speed = math_util.distance3(px, py, pz)
        if part_speed > entity_speed then
            return px, py, pz
        end
        return ex, ey, ez
    end
    if has_entity then return ex, ey, ez end
    if has_part then return px, py, pz end
    return 0, 0, 0
end
local function read_attach_pos_raw(tgt_root)
    local entity_x, entity_y, entity_z
    local has_entity = false
    if target_player and target_player.position then
        local p = target_player.position
        entity_x, entity_y, entity_z = p.x, p.y, p.z
        has_entity = true
    end
    local part_x, part_y, part_z
    local has_part = false
    if tgt_root and env.is_valid(tgt_root) then
        local tpos = move.read_pos(tgt_root)
        if tpos then
            part_x, part_y, part_z = tpos.x, tpos.y, tpos.z
            has_part = true
        end
    end
    if has_entity and has_part then
        local spread = math_util.distance3(part_x - entity_x, part_y - entity_y, part_z - entity_z)
        if spread > FAR_RANGE or start_range > FAR_RANGE or spread > 8 then
            return entity_x, entity_y, entity_z
        end
        return part_x, part_y, part_z
    end
    if has_entity then return entity_x, entity_y, entity_z end
    if has_part then return part_x, part_y, part_z end
    if last_attach then
        return last_attach.x, last_attach.y, last_attach.z
    end
    return nil
end
local function read_attach_pos(tgt_root, lpos)
    local tx, ty, tz = read_attach_pos_raw(tgt_root)
    if not tx then return nil end
    local far_lock = start_range > FAR_RANGE
    if lpos then
        local live_range = math_util.distance3(tx - lpos.x, ty - lpos.y, tz - lpos.z)
        if live_range > FAR_RANGE then
            far_lock = true
        end
    end
    local vx, vy, vz = read_target_velocity(tgt_root, far_lock)
    local horiz_speed = math_util.distance3(vx, 0, vz)
    local predict = BASE_PREDICT + horiz_speed * 0.003
    if far_lock then
        predict = predict + 0.02
    end
    tx = tx + vx * predict
    ty = ty + vy * predict * 0.12
    tz = tz + vz * predict
    last_attach = { x = tx, y = ty, z = tz }
    return tx, ty, tz
end
local function snap_passes(range, drift)
    local base = 4
    if range > 220 then base = 10
    elseif range > 150 then base = 8
    elseif range > 100 then base = 7
    elseif range > 60 then base = 6
    elseif range > 30 then base = 5
    end
    if drift > 12 then base = base + 3
    elseif drift > 6 then base = base + 2
    elseif drift > 2 then base = base + 1
    end
    return math.min(MAX_SNAP_PASSES, base)
end
local function approach_ticks_for(dist)
    if dist <= FAR_RANGE then return 0 end
    return math.min(12, math.floor(dist / 22) + 3)
end
local function set_fling_collision(char, active)
    if not char then return end
    for _, inst in ipairs(move.iter_parts(char)) do
        move.set_part_collide(inst, false)
    end
    if not active then
        move.set_character_noclip(char, nil, false)
        return
    end
    for i = 1, #FLING_HIT_PARTS do
        local hit = move.find_part(char, FLING_HIT_PARTS[i])
        if hit and move.is_base_part(hit) then
            move.set_part_collide(hit, true)
        end
    end
end
local function prep_fling(char, root, hum)
    set_fling_collision(char, true)
    move.humanoid_suspend(hum)
    pcall(function() hum.platform_stand = true end)
    pcall(function() hum.sit = false end)
    move.humanoid_state(hum, 13)
end
local function release_fling(char, root, hum)
    if root then
        move.zero_part(root)
    end
    move.zero_character(char, root)
    set_fling_collision(char, false)
    if hum then
        pcall(function() hum.platform_stand = false end)
        pcall(function() hum.sit = false end)
        pcall(function() hum.auto_rotate = true end)
        pcall(function() hum.evaluate_state_machine = true end)
        move.humanoid_running(hum)
    end
end
local function write_pos(inst, x, y, z)
    if not inst then return end
    if part and part.set_position then
        pcall(part.set_position, inst, x, y, z)
    else
        pcall(function() inst.Position = Vector3.new(x, y, z) end)
    end
end
local function zero_linear(char, root)
    if root then
        move.set_velocity(root, 0, 0, 0)
    end
    for _, inst in ipairs(move.iter_parts(char)) do
        move.set_velocity(inst, 0, 0, 0)
    end
end
local function lock_at(root, char, x, y, z, passes)
    passes = passes or 3
    for _ = 1, passes do
        write_pos(root, x, y, z)
    end
    zero_linear(char, root)
end
local function clear_session()
    state = STATE_IDLE
    fling_t0 = 0
    approach_left = 0
    return_left = 0
    start_range = 0
    saved_pos = nil
    target_root = nil
    target_player = nil
    last_attach = nil
end
local function pin_to_target(root, tgt_root, from_pos)
    local lpos = move.read_pos(root)
    local tx, ty, tz = read_attach_pos(tgt_root, lpos)
    if not tx then return false end
    local drift = 0
    local range = start_range
    if lpos then
        drift = math_util.distance3(tx - lpos.x, ty - lpos.y, tz - lpos.z)
        range = math.max(range, drift)
    elseif from_pos then
        drift = math_util.distance3(tx - from_pos.x, ty - from_pos.y, tz - from_pos.z)
        range = math.max(range, drift)
    end
    local passes = snap_passes(range, drift)
    for _ = 1, passes do
        write_pos(root, tx, ty, tz)
    end
    zero_linear(nil, root)
    return true, tx, ty, tz
end
local function spin_strength(elapsed)
    local t = math.min(1, elapsed / SPIN_RAMP_SEC)
    return SPIN_Y_START + (SPIN_Y_MAX - SPIN_Y_START) * t
end
local function apply_spin(root, elapsed)
    if not root then return end
    move.set_velocity(root, 0, 0, 0)
    if part and part.set_angular_velocity then
        pcall(part.set_angular_velocity, root, 0, spin_strength(elapsed), 0)
    end
end
local function begin_return(root, char, hum)
    state = STATE_RETURN
    return_left = RETURN_TICKS
    target_root = nil
    target_player = nil
    last_attach = nil
    set_fling_collision(char, false)
    if root and part and part.set_angular_velocity then
        pcall(part.set_angular_velocity, root, 0, 0, 0)
    end
    move.zero_character(char, root)
    if hum then
        pcall(function() hum.platform_stand = true end)
        move.humanoid_suspend(hum)
    end
end
local function finish_fling(root, char, hum)
    if saved_pos and root then
        lock_at(root, char, saved_pos.x, saved_pos.y, saved_pos.z, 6)
        move.zero_part(root)
    end
    release_fling(char, root, hum)
    clear_session()
end
local function stop_fling(root, char, hum)
    begin_return(root, char, hum)
end
local function tick_return(root, char, hum)
    if not saved_pos or not root then
        finish_fling(root, char, hum)
        return
    end
    lock_at(root, char, saved_pos.x, saved_pos.y, saved_pos.z, 4)
    move.zero_character(char, root)
    local pos = move.read_pos(root)
    local settled = pos and math_util.distance3(
        pos.x - saved_pos.x, pos.y - saved_pos.y, pos.z - saved_pos.z
    ) < 1.5
    return_left = return_left - 1
    if settled or return_left <= 0 then
        finish_fling(root, char, hum)
    end
end
local function begin_fling(root, char, hum, tgt_player, tgt_root)
    local pos = move.read_pos(root)
    if not pos then return false end
    target_player = tgt_player
    target_root = tgt_root
    last_attach = nil
    local raw_x, raw_y, raw_z = read_attach_pos_raw(tgt_root)
    if not raw_x then return false end
    start_range = math_util.distance3(raw_x - pos.x, raw_y - pos.y, raw_z - pos.z)
    local tx, ty, tz = read_attach_pos(tgt_root, pos)
    if not tx then return false end
    saved_pos = { x = pos.x, y = pos.y, z = pos.z }
    fling_t0 = now()
    approach_left = approach_ticks_for(start_range)
    if approach_left > 0 then
        state = STATE_APPROACH
    else
        state = STATE_FLING
    end
    prep_fling(char, root, hum)
    pin_to_target(root, tgt_root, pos)
    if state == STATE_FLING then
        apply_spin(root, 0)
    end
    return true
end
local function tick_approach(root, char, hum)
    prep_fling(char, root, hum)
    if not pin_to_target(root, target_root, nil) then
        stop_fling(root, char, hum)
        return
    end
    approach_left = approach_left - 1
    if approach_left <= 0 then
        state = STATE_FLING
        apply_spin(root, now() - fling_t0)
    end
end
local function tick_fling(root, char, hum)
    local elapsed = now() - fling_t0
    if elapsed >= fling_duration() then
        stop_fling(root, char, hum)
        return
    end
    if not target_still_valid() then
        stop_fling(root, char, hum)
        return
    end
    refresh_target_root()
    prep_fling(char, root, hum)
    local ok, tx, ty, tz = pin_to_target(root, target_root, nil)
    if not ok then
        stop_fling(root, char, hum)
        return
    end
    apply_spin(root, elapsed)
    lock_at(root, char, tx, ty, tz, 3)
    local pos = move.read_pos(root)
    if pos and math_util.distance3(pos.x - tx, pos.y - ty, pos.z - tz) > MAX_ATTACH_DRIFT then
        lock_at(root, char, tx, ty, tz, 5)
    end
end
local function tick_active(root, char, hum)
    if state == STATE_APPROACH then
        tick_approach(root, char, hum)
        return
    end
    if state == STATE_RETURN then
        tick_return(root, char, hum)
        return
    end
    tick_fling(root, char, hum)
end
local function try_trigger()
    if state ~= STATE_IDLE then return end
    if not settings.enabled(P) then return end
    local lp = env.get_local_player()
    if not lp then return end
    local char = get_character(lp)
    local root = get_root(lp)
    local hum = get_humanoid(lp)
    if not char or not root or not hum then return end
    local fov = settings.num(P_FOV, 150)
    local tgt_player, tgt_root = find_target(fov)
    if not tgt_root then return end
    begin_fling(root, char, hum, tgt_player, tgt_root)
end
local was_enabled = false
local function poll_enable()
    local on = settings.enabled(P)
    if on and not was_enabled then
        try_trigger()
    end
    was_enabled = on
end
local function tick(_dt)
    if state == STATE_IDLE then
        if not misc_gate.movement_allowed() then
            was_enabled = settings.enabled(P)
            return
        end
        poll_enable()
        return
    end
    if state ~= STATE_RETURN and not misc_gate.movement_allowed() then
        return
    end
    local lp = env.get_local_player()
    if not lp then
        if state == STATE_RETURN and saved_pos then
            return_left = RETURN_TICKS
        else
            clear_session()
        end
        return
    end
    local char = get_character(lp)
    local root = get_root(lp)
    local hum = get_humanoid(lp)
    if not char or not root or not hum then
        stop_fling(root, char, hum)
        return
    end
    tick_active(root, char, hum)
end
function M.is_active()
    return state == STATE_APPROACH or state == STATE_FLING or state == STATE_RETURN
end
function M.register_menu()
    local G = menu_util.G
    local T = menu_util.group(G.MISC)
    local root = menu_util.parent(P)
    menu_util.section(T, G.MISC, "Combat")
    menu_util.register_keybind(T, G.MISC, P, "Fling", false)
    menu.add_slider_int(T, G.MISC, P_FOV, "Fling FOV", 5, 600, 150, root)
    menu.add_slider_int(T, G.MISC, P_DURATION, "Fling Duration", 2, 10, 2, root)
    menu_util.bind_children(P, { P_FOV, P_DURATION })
end
function M.install()
    if _installed then return end
    _installed = true
    local runservice = April.require("core.runservice")
    runservice.on_sim(function(dt)
        tick(dt)
    end)
end
function M.update(_dt) end
function M.draw() end
return M
end)()

April._mods["features.movement.desync"] = (function()
local settings = April.require("core.settings")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local fflag_mem = April.require("core.fflag_mem")
local desync_vis = April.require("core.desync_vis")
local esp_util = April.require("core.esp_util")
local draw_util = April.require("core.draw_util")
local misc_gate = April.require("core.misc_gate")
local M = {}
local P = "april_desync_enabled"
local P_VIS = "april_desync_visualizer"
local RANGE_RADIUS = 8
local LOOP_MS = 30
local last_tick = 0
local last_flag_apply = 0
local old_phys, old_send = nil, nil
local was_active = false
local anchor_pos = nil
local peek_hold = false
local function now()
    if utility and utility.get_time then return utility.get_time() end
    return os.clock()
end
local function get_root()
    local lp = env.get_local_player()
    if not lp then return nil end
    local char = lp.character or (game and game.local_player and game.local_player.character)
    if not char then return nil end
    return env.safe_call(function()
        if char.find_first_child then return char:find_first_child("HumanoidRootPart") end
        return char:FindFirstChild("HumanoidRootPart")
    end)
end
local function capture_pos(root)
    if not root then return nil end
    local pos = root.Position or root.position
    if not pos then return nil end
    return {
        x = pos.X or pos.x or 0,
        y = pos.Y or pos.y or 0,
        z = pos.Z or pos.z or 0,
    }
end
local function dist_from_anchor(pos)
    if not anchor_pos or not pos then return 0 end
    local dx = pos.x - anchor_pos.x
    local dy = pos.y - anchor_pos.y
    local dz = pos.z - anchor_pos.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end
local function apply_rates(physics_rate, sender_rate)
    local phys = tonumber(physics_rate) or 0
    local send = tonumber(sender_rate) or 60
    local bw = phys == 0 and 0 or 38760
    fflag_mem.set_int("S2PhysicsSenderRate", phys)
    fflag_mem.set_int("PhysicsSenderMaxBandwidthBps", bw)
    fflag_mem.set_int("DataSenderRate", send)
end
local function restore_rates()
    fflag_mem.reset_defaults()
    old_phys, old_send = nil, nil
    last_flag_apply = 0
end
local function active()
    return settings.enabled(P)
end
function M.peek_begin()
    if peek_hold then return end
    peek_hold = true
    pcall(fflag_mem.refresh)
    if not active() then
        apply_rates(0, 60)
        old_phys, old_send = 0, 60
        last_flag_apply = now()
    end
end
function M.peek_end()
    if not peek_hold then return end
    peek_hold = false
    if not active() then
        restore_rates()
        anchor_pos = nil
        was_active = false
    end
end
function M.peek_held()
    return peek_hold
end
local function disable_desync()
    if menu and menu.set then
        pcall(menu.set, P, false)
    end
end
local function compute_rates(_t)
    return 0, 60
end
local function draw_center_dot(wx, wy, wz, col)
    local sx, sy, vis = esp_util.w2s(wx, wy, wz)
    if vis then
        draw_util.circle(sx, sy, 5, col, true)
        draw_util.circle(sx, sy, 5, { 0, 0, 0, col[4] or 1 }, false)
    end
end
local function draw_visualizer()
    if not anchor_pos then return end
    local col = settings.color(P_VIS, { 0.2, 0.85, 1, 0.9 })
    local ring_col = { col[1], col[2], col[3], 0.55 }
    desync_vis.draw_sphere_ring(anchor_pos.x, anchor_pos.y, anchor_pos.z, RANGE_RADIUS, ring_col, 2)
    if settings.bool(P_VIS, false) then
        draw_center_dot(anchor_pos.x, anchor_pos.y, anchor_pos.z, col)
    end
end
function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)
    menu_util.section(T, G.MISC, "Network")
    menu_util.register_keybind(T, G.MISC, P, "Desync", false)
    menu.add_checkbox(T, G.MISC, P_VIS, "Desync Visualize", false, menu_util.parent(P, {
        colorpicker = { 0.2, 0.85, 1, 0.9 },
    }))
    menu_util.bind_children(P, { P_VIS })
end
function M.update(_dt)
    if not misc_gate.movement_allowed() then return end
    local user_on = active()
    local held = peek_hold
    local on = user_on or held
    local t = now()
    if was_active and not on then
        restore_rates()
        anchor_pos = nil
    end
    if user_on and not was_active then
        pcall(fflag_mem.refresh)
        local root = get_root()
        anchor_pos = capture_pos(root)
    end
    was_active = on
    if not on then return end
    if (t - last_tick) * 1000 < LOOP_MS then return end
    last_tick = t
    local phys, send = compute_rates(t)
    local root = get_root()
    if user_on and root and anchor_pos then
        local pos = capture_pos(root)
        if pos and dist_from_anchor(pos) > RANGE_RADIUS then
            restore_rates()
            anchor_pos = nil
            was_active = false
            disable_desync()
            return
        end
    end
    if phys ~= old_phys or send ~= old_send or (t - last_flag_apply) > 0.35 then
        apply_rates(phys, send)
        old_phys, old_send = phys, send
        last_flag_apply = t
    end
end
function M.draw()
    if not misc_gate.movement_allowed() then return end
    if not active() and not peek_hold then return end
    draw_visualizer()
end
return M
end)()

April._mods["features.movement.anti_aim"] = (function()
local settings = April.require("core.settings")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local move = April.require("core.cframe_move")
local misc_gate = April.require("core.misc_gate")
local angle_util = April.require("core.angle_util")
local M = {}
local P = "april_antiaim_enabled"
local P_YAW = "april_antiaim_yaw_mode"
local P_YAW_MANUAL = "april_antiaim_yaw_manual"
local P_SPIN = "april_antiaim_spin_speed"
local P_JITTER = "april_antiaim_jitter_step"
local P_JITTER_MS = "april_antiaim_jitter_ms"
local YAW_LABELS = {
    "None", "Backwards", "Spin", "Jitter", "Random Jitter",
    "Sideways Left", "Sideways Right", "Manual",
}
local YAW_MANUAL_IDX = 7
local YAW_SPIN, YAW_JITTER, YAW_RAND = 2, 3, 4
local YAW_GAIN = 22
local YAW_AV_MAX = 40
local YAW_SNAP_EPS = 0.02
local SHOOT_VK = 0x01
local state = {
    fake_yaw = 0,
    yaw_jitter_idx = 0,
    jitter_t = 0,
    random_yaw = 0,
    spin_yaw = 0,
    was_active = false,
    was_firing = false,
}
M.YAW_LABELS = YAW_LABELS
local function active()
    return settings.enabled(P)
end
local function find_child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        if parent.FindFirstChild then return parent:FindFirstChild(name) end
        if parent.find_first_child then return parent:find_first_child(name) end
        return nil
    end)
end
local function get_character(lp)
    if not lp then lp = env.get_local_player() end
    if lp then
        local char = lp.Character or lp.character
        if char then return char end
    end
    local rp = game and (game.LocalPlayer or game.local_player)
    if rp then return rp.Character or rp.character end
    return nil
end
local function get_humanoid(lp)
    if lp then
        local hum = lp.Humanoid or lp.humanoid
        if hum then return hum end
    end
    local char = get_character(lp)
    return char and (move.find_part(char, "Humanoid") or find_child(char, "Humanoid"))
end
local function get_root(lp)
    local char = get_character(lp)
    if not char then return nil end
    return move.find_part(char, "HumanoidRootPart")
        or find_child(char, "HumanoidRootPart")
        or env.safe_call(function() return char.PrimaryPart or char.primary_part end)
end
local function get_attr(inst, name)
    if not inst then return nil end
    return env.safe_call(function()
        if inst.GetAttribute then return inst:GetAttribute(name) end
        if inst.get_attribute then return inst:get_attribute(name) end
        return nil
    end)
end
local function is_firing(char)
    if input and input.is_key_down and input.is_key_down(SHOOT_VK) then
        return true
    end
    local vm = char and find_child(char, "ViewmodelController")
    if vm then
        if get_attr(vm, "Using") == true then return true end
    end
    return false
end
local function compute_fake_yaw(real_yaw, dt)
    local mode = settings.combo_index(P_YAW, YAW_LABELS, 0)
    if mode == 0 then return nil end
    dt = dt or 0.016
    if mode == 1 then return angle_util.normalize_yaw(real_yaw + math.pi) end
    if mode == 2 then
        state.spin_yaw = angle_util.normalize_yaw(state.spin_yaw + math.rad(settings.num(P_SPIN, 180)) * dt)
        return angle_util.normalize_yaw(real_yaw + state.spin_yaw)
    end
    if mode == 3 then
        local step = math.max(15, settings.num(P_JITTER, 90))
        return angle_util.normalize_yaw(real_yaw + math.rad(state.yaw_jitter_idx * step))
    end
    if mode == 4 then return angle_util.normalize_yaw(real_yaw + state.random_yaw) end
    if mode == 5 then return angle_util.normalize_yaw(real_yaw + math.pi * 0.5) end
    if mode == 6 then return angle_util.normalize_yaw(real_yaw - math.pi * 0.5) end
    return angle_util.normalize_yaw(real_yaw + math.rad(settings.num(P_YAW_MANUAL, 90)))
end
local function advance_jitter(dt)
    local yaw_m = settings.combo_index(P_YAW, YAW_LABELS, 0)
    if yaw_m ~= YAW_JITTER and yaw_m ~= YAW_RAND then return end
    local interval = math.max(0.04, settings.num(P_JITTER_MS, 120) / 1000)
    state.jitter_t = state.jitter_t + dt
    if state.jitter_t < interval then return end
    state.jitter_t = 0
    local step = math.max(15, settings.num(P_JITTER, 90))
    if yaw_m == YAW_JITTER then
        state.yaw_jitter_idx = (state.yaw_jitter_idx + 1) % math.max(1, math.floor(360 / step))
    end
    if yaw_m == YAW_RAND then
        state.random_yaw = math.random() * math.pi * 2
    end
end
local function disable_auto_rotate(lp, hum)
    if lp then pcall(function() lp.AutoRotate = false end) end
    if hum then
        pcall(function() hum.AutoRotate = false end)
        pcall(function() hum.auto_rotate = false end)
    end
end
local function restore_auto_rotate(lp, hum)
    if lp then pcall(function() lp.AutoRotate = true end) end
    if hum then
        pcall(function() hum.AutoRotate = true end)
        pcall(function() hum.auto_rotate = true end)
    end
end
local function write_yaw(char, root, yaw)
    if yaw == nil or not root or not CFrame then return end
    local pos = move.read_pos(root)
    if not pos then return end
    local cf = CFrame.new(pos.x, pos.y, pos.z) * CFrame.Angles(0, yaw, 0)
    pcall(function() root.CFrame = cf end)
    if char then
        pcall(function()
            if char.PivotTo then char:PivotTo(cf) end
        end)
    end
end
local function steer_yaw(root, body_yaw, target_yaw)
    if target_yaw == nil or not root then return end
    local mode = settings.combo_index(P_YAW, YAW_LABELS, 0)
    if mode == YAW_SPIN then
        move.set_angular_velocity(root, 0, math.rad(settings.num(P_SPIN, 180)), 0)
        return
    end
    local diff = angle_util.yaw_delta(body_yaw, target_yaw)
    if math.abs(diff) < YAW_SNAP_EPS then
        move.set_angular_velocity(root, 0, 0, 0)
        return
    end
    local av = diff * YAW_GAIN
    if av > YAW_AV_MAX then av = YAW_AV_MAX elseif av < -YAW_AV_MAX then av = -YAW_AV_MAX end
    move.set_angular_velocity(root, 0, av, 0)
end
local function face_camera(lp, char, root, hum)
    local yaw = angle_util.camera_yaw()
    write_yaw(char, root, yaw)
    if root then move.set_angular_velocity(root, 0, 0, 0) end
    restore_auto_rotate(lp, hum)
end
local function tick_aa(dt)
    local lp = env.get_local_player()
    local char = get_character(lp)
    local root = get_root(lp)
    local hum = get_humanoid(lp)
    if not root then return end
    disable_auto_rotate(lp, hum)
    advance_jitter(dt)
    local real_yaw = angle_util.camera_yaw()
    local fake_yaw = compute_fake_yaw(real_yaw, dt)
    if fake_yaw == nil then
        move.set_angular_velocity(root, 0, 0, 0)
        return
    end
    state.fake_yaw = fake_yaw
    local body_yaw = angle_util.body_yaw(lp, root)
    write_yaw(char, root, fake_yaw)
    steer_yaw(root, body_yaw, fake_yaw)
end
local function sync_option_visibility()
    if not menu or not menu.set_visible then return end
    local on = active()
    local yaw_m = settings.combo_index(P_YAW, YAW_LABELS, 0)
    pcall(menu.set_visible, P_YAW_MANUAL, on and yaw_m == YAW_MANUAL_IDX)
    pcall(menu.set_visible, P_SPIN, on and yaw_m == YAW_SPIN)
    pcall(menu.set_visible, P_JITTER, on and (yaw_m == YAW_JITTER or yaw_m == YAW_RAND))
    pcall(menu.set_visible, P_JITTER_MS, on and (yaw_m == YAW_JITTER or yaw_m == YAW_RAND))
end
function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)
    menu_util.section(T, G.MISC, "Movement")
    menu_util.register_keybind(T, G.MISC, P, "Anti-Aim", false)
    menu.add_combo(T, G.MISC, P_YAW, "Yaw Mode", YAW_LABELS, 1, root)
    menu.add_slider_int(T, G.MISC, P_YAW_MANUAL, "Manual Yaw", -180, 180, 90,
        menu_util.parent(P_YAW, { parent_value = YAW_MANUAL_IDX }))
    menu.add_slider_int(T, G.MISC, P_SPIN, "Spin Speed", 30, 720, 180, root)
    menu.add_slider_int(T, G.MISC, P_JITTER, "Jitter Step", 15, 180, 90, root)
    menu.add_slider_int(T, G.MISC, P_JITTER_MS, "Jitter Interval (ms)", 40, 500, 120, root)
    menu_util.bind_children(P, {
        P_YAW, P_YAW_MANUAL, P_SPIN, P_JITTER, P_JITTER_MS,
    })
    if menu and menu.set_callback then
        pcall(menu.set_callback, P, sync_option_visibility)
        pcall(menu.set_callback, P_YAW, sync_option_visibility)
    end
    sync_option_visibility()
end
function M.install() end
function M.update(dt)
    sync_option_visibility()
    dt = dt or 0.016
    local lp = env.get_local_player()
    local char = get_character(lp)
    local root = get_root(lp)
    local hum = get_humanoid(lp)
    local on = active() and misc_gate.movement_allowed()
    local firing = on and is_firing(char)
    if state.was_active and (not on or firing) then
        if root then move.set_angular_velocity(root, 0, 0, 0) end
        if firing and on then
            face_camera(lp, char, root, hum)
        else
            restore_auto_rotate(lp, hum)
            state.spin_yaw = 0
            state.jitter_t = 0
        end
    end
    if state.was_firing and on and not firing then
        disable_auto_rotate(lp, hum)
    end
    state.was_active = on and not firing
    state.was_firing = firing
    if not on or firing then return end
    if settings.combo_index(P_YAW, YAW_LABELS, 0) == 0 then return end
    tick_aa(dt)
end
function M.draw() end
return M
end)()

April._mods["features.movement.fake_duck"] = (function()
local settings = April.require("core.settings")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local move = April.require("core.cframe_move")
local misc_gate = April.require("core.misc_gate")
local runservice = April.require("core.runservice")
local M = {}
local P = "april_fakeduck_enabled"
local P_HEIGHT = "april_fakeduck_height"
local P_SPAM = "april_fakeduck_spam"
local P_SPAM_MIN = "april_fakeduck_spam_min"
local P_SPAM_MAX = "april_fakeduck_spam_max"
local P_SPAM_MS = "april_fakeduck_spam_ms"
local P_SPAM_MODE = "april_fakeduck_spam_mode"
local SPAM_MODES = { "Alternating", "Random" }
local DEFAULT_DUCK_HIP = 1.1
local STAND_HIP = 1.6
local HIP_MIN = 0.01
local HIP_MAX = 1.5
local SPEED_WALK = 11
local SPEED_SPRINT = 18
local SPEED_AIM_MUL = 0.8
local SPEED_SLOW_MUL = 0.3
local MOVE_EPS = 0.05
local state = {
    was_active = false,
    hooks_installed = false,
    state_ctrl = nil,
    viewmodel = nil,
    root = nil,
    hum = nil,
    spam_t = 0,
    spam_hi = false,
    spam_val = DEFAULT_DUCK_HIP,
}
local function active()
    return settings.enabled(P)
end
local function clamp_hip(h)
    h = tonumber(h) or DEFAULT_DUCK_HIP
    if h > HIP_MAX then h = HIP_MAX end
    if h < HIP_MIN then h = HIP_MIN end
    return h
end
local function find_child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        if parent.FindFirstChild then return parent:FindFirstChild(name) end
        if parent.find_first_child then return parent:find_first_child(name) end
        return nil
    end)
end
local function get_character(lp)
    if not lp then lp = env.get_local_player() end
    if lp then
        local char = lp.Character or lp.character
        if char then return char end
    end
    local rp = game and (game.LocalPlayer or game.local_player)
    if rp then return rp.Character or rp.character end
    return nil
end
local function get_attr(inst, name)
    if not inst then return nil end
    return env.safe_call(function()
        if inst.GetAttribute then return inst:GetAttribute(name) end
        if inst.get_attribute then return inst:get_attribute(name) end
        return nil
    end)
end
local function set_attr(inst, name, value)
    if not inst then return end
    pcall(function()
        if inst.SetAttribute then
            inst:SetAttribute(name, value)
        elseif inst.set_attribute then
            inst:set_attribute(name, value)
        end
    end)
end
local function set_hip_height(hum, value)
    if not hum then return end
    pcall(function() hum.HipHeight = value end)
end
local function static_duck_hip()
    return clamp_hip(settings.num(P_HEIGHT, DEFAULT_DUCK_HIP))
end
local function spam_range()
    local lo = clamp_hip(settings.num(P_SPAM_MIN, HIP_MIN))
    local hi = clamp_hip(settings.num(P_SPAM_MAX, HIP_MAX))
    if lo > hi then
        lo, hi = hi, lo
    end
    return lo, hi
end
local function duck_hip(dt)
    if not settings.bool(P_SPAM, false) then
        state.spam_t = 0
        return static_duck_hip()
    end
    local lo, hi = spam_range()
    local interval = math.max(0.02, settings.num(P_SPAM_MS, 80) / 1000)
    local mode = settings.combo_index(P_SPAM_MODE, SPAM_MODES, 0)
    state.spam_t = (state.spam_t or 0) + (dt or 0.016)
    if state.spam_t >= interval then
        state.spam_t = 0
        if mode == 1 then
            state.spam_val = lo + math.random() * (hi - lo)
        else
            state.spam_hi = not state.spam_hi
            state.spam_val = state.spam_hi and hi or lo
        end
    end
    return clamp_hip(state.spam_val or lo)
end
local function set_root_size(root, crouch, hip)
    if not root or not Vector3 then return end
    local y = 2.5
    if crouch then
        hip = hip or DEFAULT_DUCK_HIP
        y = 2.1 - (DEFAULT_DUCK_HIP - hip) * 0.35
        if y < 1.4 then y = 1.4 end
        if y > 2.4 then y = 2.4 end
    end
    pcall(function()
        root.Size = Vector3.new(2, y, 2)
    end)
end
local function resolve_parts()
    local lp = env.get_local_player()
    local char = get_character(lp)
    if not char then
        state.state_ctrl, state.viewmodel, state.root, state.hum = nil, nil, nil, nil
        return false
    end
    state.state_ctrl = find_child(char, "StateController")
    state.viewmodel = find_child(char, "ViewmodelController")
    state.root = move.find_part(char, "HumanoidRootPart") or find_child(char, "HumanoidRootPart")
    state.hum = (lp and (lp.Humanoid or lp.humanoid))
        or move.find_part(char, "Humanoid")
        or find_child(char, "Humanoid")
    return state.root ~= nil
end
local function desired_speed()
    local sc = state.state_ctrl
    local vm = state.viewmodel
    local hum = state.hum
    local sprint = get_attr(sc, "IsSprint") == true
    local aiming = get_attr(vm, "Aiming") == true
    local slowed = false
    if hum then
        local dc = get_attr(hum, "DamageConnections")
        slowed = type(dc) == "number" and dc > 0
    end
    if get_attr(hum, "Downed") == true then return 0 end
    local base = sprint and SPEED_SPRINT or SPEED_WALK
    if aiming then base = base * SPEED_AIM_MUL end
    if slowed then base = base * SPEED_SLOW_MUL end
    return base
end
local function boost_velocity(root, target)
    if not root or not target or target <= 0 then return end
    local mx, mz = move.read_flat_input()
    local vx, vy, vz = move.read_velocity(root)
    local input_mag = math.sqrt(mx * mx + mz * mz)
    if input_mag >= MOVE_EPS then
        move.set_velocity(root, mx * target, vy, mz * target)
        return
    end
    local hmag = math.sqrt(vx * vx + vz * vz)
    if hmag < 1.0 then return end
    if hmag >= target * 0.95 then return end
    local s = target / hmag
    move.set_velocity(root, vx * s, vy, vz * s)
end
local function apply_duck(dt)
    if not resolve_parts() then return end
    if state.state_ctrl then
        set_attr(state.state_ctrl, "IsCrouch", true)
    end
    local hip = duck_hip(dt)
    set_hip_height(state.hum, hip)
    set_root_size(state.root, true, hip)
    boost_velocity(state.root, desired_speed())
end
local function restore_duck()
    resolve_parts()
    if state.state_ctrl then
        set_attr(state.state_ctrl, "IsCrouch", false)
    end
    set_hip_height(state.hum, STAND_HIP)
    set_root_size(state.root, false)
    state.spam_t = 0
    state.spam_hi = false
end
local function on_sim(dt)
    if not misc_gate.movement_allowed() then return end
    local on = active()
    if state.was_active and not on then
        restore_duck()
    end
    state.was_active = on
    if not on then return end
    apply_duck(dt or 0.016)
end
local function ensure_hooks()
    if state.hooks_installed then return end
    state.hooks_installed = true
    runservice.on_sim(on_sim)
end
function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)
    local spam_root = menu_util.parent(P_SPAM)
    menu_util.section(T, G.MISC, "Movement")
    menu_util.register_keybind(T, G.MISC, P, "Fake Duck", false)
    menu.add_slider_float(T, G.MISC, P_HEIGHT, "Duck Height", HIP_MIN, HIP_MAX, DEFAULT_DUCK_HIP, "%.2f", root)
    menu.add_checkbox(T, G.MISC, P_SPAM, "Spam Height", false, root)
    menu.add_combo(T, G.MISC, P_SPAM_MODE, "Spam Mode", SPAM_MODES, 0, spam_root)
    menu.add_slider_float(T, G.MISC, P_SPAM_MIN, "Spam Min", HIP_MIN, HIP_MAX, HIP_MIN, "%.2f", spam_root)
    menu.add_slider_float(T, G.MISC, P_SPAM_MAX, "Spam Max", HIP_MIN, HIP_MAX, HIP_MAX, "%.2f", spam_root)
    menu.add_slider_int(T, G.MISC, P_SPAM_MS, "Spam Interval (ms)", 20, 400, 80, spam_root)
    menu_util.bind_children(P, {
        P_HEIGHT, P_SPAM, P_SPAM_MODE, P_SPAM_MIN, P_SPAM_MAX, P_SPAM_MS,
    })
    menu_util.bind_children(P_SPAM, {
        P_SPAM_MODE, P_SPAM_MIN, P_SPAM_MAX, P_SPAM_MS,
    })
end
function M.install()
    ensure_hooks()
end
function M.update(dt)
    ensure_hooks()
    if not runservice.uses_heartbeat() and misc_gate.movement_allowed() then
        on_sim(dt)
    elseif state.was_active and not active() then
        restore_duck()
        state.was_active = false
    end
end
function M.draw() end
return M
end)()

April._mods["features.radar.waypoints"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local M = {}
local P = "april_waypoints_enabled"
function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.RADAR)
    local root = menu_util.parent(P)
    menu_util.section(T, G.RADAR, "Waypoints")
    menu_util.register_keybind(T, G.RADAR, P, "Enable Waypoints", false)
    menu.add_checkbox(T, G.RADAR, "april_wp_dist", "Waypoint Show Distance", false, root)
    menu.add_checkbox(T, G.RADAR, "april_wp_beacon", "Beacon Pillar", false, root)
    menu.add_slider_int(T, G.RADAR, "april_wp_beacon_h", "Beacon Height", 20, 200, 90, menu_util.parent("april_wp_beacon"))
    menu.add_checkbox(T, G.RADAR, "april_wp_draw", "Draw Markers", false, menu_util.parent(P, { colorpicker = { 0.2, 1, 0.8, 1 } }))
    menu.add_slider_int(T, G.RADAR, "april_wp_slot", "Waypoint Active Slot", 1, 5, 1, root)
    menu_util.button(T, G.RADAR, "april_wp_set", "Set Active Waypoint", function()
        local slot = settings.num("april_wp_slot", 1)
        local lp = env.get_local_player()
        if lp and lp.position then
            cache.waypoints[slot] = {
                name = "Waypoint " .. slot,
                pos = { x = lp.position.x, y = lp.position.y, z = lp.position.z },
            }
        end
    end, P)
    menu_util.button(T, G.RADAR, "april_wp_clear", "Clear Active Waypoint", function()
        local slot = settings.num("april_wp_slot", 1)
        cache.waypoints[slot] = nil
    end, P)
    menu_util.button(T, G.RADAR, "april_wp_clear_all", "Clear All Waypoints", function()
        cache.waypoints = {}
    end, P)
    menu_util.bind_children(P, {
        "april_wp_dist", "april_wp_beacon", "april_wp_beacon_h", "april_wp_draw",
        "april_wp_slot", "april_wp_set", "april_wp_clear", "april_wp_clear_all",
    })
end
function M.update(dt) end
function M.draw()
    if not settings.enabled(P) then return end
    if not settings.bool("april_wp_draw", false) and not settings.bool("april_wp_beacon", false) then return end
    local col = settings.color("april_wp_draw", { 0.2, 1, 0.8, 1 })
    local beacon_h = settings.num("april_wp_beacon_h", 90)
    local me = env.get_local_player()
    for i, wp in pairs(cache.waypoints) do
        if wp and wp.pos then
            local wx, wy, wz = wp.pos.x, wp.pos.y, wp.pos.z
            if settings.bool("april_wp_beacon", false) then
                esp_util.draw_vertical_beacon(wx, wy, wz, col, { height = beacon_h })
            end
            local sx, sy, vis = esp_util.w2s(wx, wy, wz)
            if not vis then goto continue end
            local label = wp.name or ("WP" .. tostring(i))
            if settings.bool("april_wp_dist", false) and me and me.position then
                local dx = wx - me.position.x
                local dy = wy - me.position.y
                local dz = wz - me.position.z
                label = label .. string.format(" [%.0fm]", math.sqrt(dx * dx + dy * dy + dz * dz))
            end
            if settings.bool("april_wp_draw", false) then
                draw_util.text_centered(sx, sy - 18, label, col, esp_util.text_size())
            end
            ::continue::
        end
    end
end
return M
end)()

April._mods["features.radar.tactical_map"] = (function()
local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local cache = April.require("core.cache")
local env = April.require("core.env")
local ep = April.require("core.entity_props")
local player_state = April.require("game.player_state")
local menu_util = April.require("core.menu_util")
local esp_scan = April.require("game.esp_scan")
local theme = April.require("core.ui_theme")
local overlay_theme = April.require("core.overlay_theme")
local panel_drag = April.require("core.panel_drag")
local map_image = April.require("game.map_image")
local math_util = April.require("core.math_util")
local npcs = April.require("game.npcs")
local M = {}
local P = "april_map_enabled"
local X_ID = "april_map_x"
local Y_ID = "april_map_y"
local TITLE_H = 24
local BASE_VISIBLE_STUDS = 3200
local SIZE_MULT = {
    player = 1.65,
    boss = 1.55,
    raid = 1.35,
    waypoint = 1.2,
    npc = 1.1,
    loot = 0.95,
    world = 0.85,
    base = 0.9,
    self = 1.7,
}
local function position_xyz(pos)
    if not pos then return nil, nil, nil end
    return pos.x or pos.X, pos.y or pos.Y, pos.z or pos.Z
end
local function ensure_draw_api()
    pcall(function()
        April.require("core.api_aliases").apply()
    end)
end
local function atan2(y, x)
    if math_util and type(math_util.atan2) == "function" then
        return math_util.atan2(y, x)
    end
    y, x = y or 0, x or 0
    if type(math.atan2) == "function" then
        return math.atan2(y, x)
    end
    local ok, result = pcall(math.atan, y, x)
    if ok and type(result) == "number" then
        return result
    end
    return 0
end
local function call_api(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c = pcall(fn, ...)
    if ok then return a, b, c end
    return nil
end
local function camera_fn(snake, pascal)
    if not camera then return nil end
    local fn = camera[snake] or camera[pascal]
    if type(fn) == "function" then return fn end
    return nil
end
local function get_facing_angle()
    local lv = call_api(camera_fn("get_look_vector", "GetLookVector"))
    if lv then
        local lx = lv.x or lv.X or 0
        local lz = lv.z or lv.Z or 0
        if math.abs(lx) > 0.001 or math.abs(lz) > 0.001 then
            return atan2(lx, -lz)
        end
    end
    local a = call_api(camera_fn("get_angles", "GetAngles"))
    if a then
        local deg = a.Y or a.y
        if deg then return math.rad(deg) end
    end
    return 0
end
local function get_camera_yaw()
    local a = call_api(camera_fn("get_angles", "GetAngles"))
    if a then
        local deg = a.Y or a.y
        if deg then return math.rad(deg) end
    end
    local util_angles = utility and (utility.get_camera_angles or utility.GetCameraAngles)
    if type(util_angles) == "function" then
        local ok, _, yaw = pcall(util_angles)
        if ok and yaw then return math.rad(yaw) end
    end
    local lv = call_api(camera_fn("get_look_vector", "GetLookVector"))
    if lv then
        local lx, lz = lv.x or lv.X or 0, lv.z or lv.Z or 0
        if math.abs(lx) > 0.001 or math.abs(lz) > 0.001 then
            return atan2(lx, lz)
        end
    end
    return 0
end
local function get_view_origin()
    local cx, cy, cz = nil, nil, nil
    local pos = call_api(camera_fn("get_position", "GetPosition"))
    if pos and (pos.x or pos.X) then
        cx = pos.x or pos.X
        cy = pos.y or pos.Y
        cz = pos.z or pos.Z
    end
    local lp = cache.local_player or env.get_local_player()
    local px, py, pz = nil, nil, nil
    if lp then
        px, py, pz = position_xyz(ep.position(lp))
    end
    if not cx then cx, cy, cz = px, py, pz end
    return cx or 0, cy or 0, cz or 0, px, py, pz
end
local function map_basis(yaw)
    local fx, fz = math.sin(yaw), math.cos(yaw)
    local rx, rz = -math.cos(yaw), math.sin(yaw)
    return fx, fz, rx, rz
end
local function world_to_map_yaw(wx, wz, view_x, view_z, map_cx, map_cy, zoom, yaw)
    local wdx = wx - view_x
    local wdz = wz - view_z
    local fx, fz, rx, rz = map_basis(yaw)
    local local_fwd = wdx * fx + wdz * fz
    local local_right = wdx * rx + wdz * rz
    return map_cx + local_right * zoom, map_cy - local_fwd * zoom
end
local function world_to_map_north(wx, wz, view)
    if view.vp and view.map_rect then
        local su, sv = map_image.world_to_viewport(wx, wz, view.vp)
        if not su or not sv then return nil, nil end
        local r = view.map_rect
        return r.x + su * r.w, r.y + sv * r.h
    end
    local u, v = map_image.world_to_uv(wx, wz)
    return view.img_x + u * view.img_size, view.img_y + v * view.img_size
end
local function clamp_to_disc(mx, my, cx, cy, radius)
    local dx, dy = mx - cx, my - cy
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist <= radius or dist < 0.001 then
        return mx, my, false
    end
    local s = radius / dist
    return cx + dx * s, cy + dy * s, true
end
local function in_map_rect(mx, my, view, margin)
    local r = view.map_rect
    if not r then return true end
    margin = margin or 2
    return mx >= r.x - margin and my >= r.y - margin
        and mx <= r.x + r.w + margin and my <= r.y + r.h + margin
end
local function entry_world_xz(entry)
    if not entry then return nil, nil end
    local lx, _, lz = esp_scan.entry_coords(entry)
    if lx and lz then return lx, lz end
    if entry.lx and entry.lz then return entry.lx, entry.lz end
    if entry.pos then return entry.pos.x, entry.pos.z end
    local inst = entry.inst
    if inst and env.is_valid(inst) then
        local pos = inst.Position or inst.position
        if pos and pos.x then return pos.x, pos.z end
    end
    return nil, nil
end
local function short_label(text)
    if text == nil then return "" end
    text = tostring(text)
    if text == "" then return "" end
    text = text:gsub("%s*%(Sleeper%)", "")
    if #text > 10 then
        return text:sub(1, 9) .. ".."
    end
    return text
end
local function blip_scale(base, kind)
    local mult = SIZE_MULT[kind or "npc"] or 1
    return math.max(2, (base or 3) * mult)
end
local function label_font_for_scale(scale)
    return math.max(8, math.min(16, math.floor((scale or 3) * 2.1 + 1.5)))
end
local function draw_radar_label(lx, ly, text, col, x, y, w, h, fs)
    if not text or text == "" or not draw then return end
    fs = fs or 9
    local tw = theme.text_w(text, fs)
    local th = fs + 2
    lx = lx - tw * 0.5
    ly = ly + math.max(4, fs * 0.45)
    if lx < x + 4 then lx = x + 4 end
    if lx + tw > x + w - 4 then lx = x + w - 4 - tw end
    if ly + th > y + h - 4 then ly = ly - th - 8 end
    if ly < y + 4 then return end
    draw_util.text(lx, ly, text, col, fs)
end
local function draw_fn(snake, pascal)
    if not draw then return nil end
    local fn = draw[snake] or draw[pascal]
    if type(fn) == "function" then return fn end
    return nil
end
local function draw_blip(mx, my, scale, col, clamped, shape)
    if type(col) ~= "table" then col = theme.CYAN end
    local alpha = clamped and 0.72 or 1
    local c = { col[1] or 1, col[2] or 1, col[3] or 1, (col[4] or 1) * alpha }
    local r = math.max(2, scale - (clamped and 1 or 0))
    local edge = theme.alpha(theme.PANEL_DEEP, math.min(0.42, c[4] * 0.42))
    shape = shape or "circle"
    local rect_f = draw_fn("rect_filled", "RectFilled")
    local poly = draw_fn("poly_filled", "PolyFilled")
    local circ_f = draw_fn("circle_filled", "CircleFilled")
    if shape == "square" and rect_f then
        pcall(rect_f, mx - r - 1, my - r - 1, (r + 1) * 2, (r + 1) * 2, edge, 0)
        pcall(rect_f, mx - r, my - r, r * 2, r * 2, c, 0)
    elseif shape == "diamond" and poly then
        pcall(poly, {
            { mx, my - r - 1 }, { mx + r + 1, my },
            { mx, my + r + 1 }, { mx - r - 1, my },
        }, edge)
        pcall(poly, {
            { mx, my - r }, { mx + r, my },
            { mx, my + r }, { mx - r, my },
        }, c)
    elseif shape == "waypoint" and circ_f then
        pcall(circ_f, mx, my, r + 2, edge, 12)
        pcall(circ_f, mx, my, r + 1, c, 12)
        pcall(circ_f, mx, my, math.max(1, r - 1), theme.PANEL_DEEP, 10)
    elseif circ_f then
        pcall(circ_f, mx, my, r + 1, edge, 10)
        pcall(circ_f, mx, my, r, c, 10)
    else
        draw_util.circle(mx, my, r, c, true)
    end
end
local function project_blip(wx, wz, view)
    if view.mode == "north" then
        return world_to_map_north(wx, wz, view)
    end
    return world_to_map_yaw(wx, wz, view.view_x, view.view_z, view.cx, view.cy, view.zoom, view.yaw)
end
local function draw_map_item(wx, wz, col, label, shape, view, scale, layout, size_kind)
    if not wx or not wz then return end
    local mx, my = project_blip(wx, wz, view)
    if not mx or not my then return end
    local clamped = false
    if view.mode == "north" and view.map_rect then
        if not in_map_rect(mx, my, view, 0) then
            mx, my, clamped = clamp_to_disc(mx, my, layout.cx, layout.cy, layout.radius)
            if not in_map_rect(mx, my, view, 4) then
                return
            end
        end
    else
        mx, my, clamped = clamp_to_disc(mx, my, layout.cx, layout.cy, layout.radius)
    end
    local size = blip_scale(scale, size_kind)
    draw_blip(mx, my, size, col, clamped, shape)
    if settings.bool("april_map_labels", false) and not clamped then
        draw_radar_label(
            mx, my, short_label(label), col,
            layout.x, layout.y, layout.w, layout.h,
            label_font_for_scale(size)
        )
    end
end
local function draw_radar_frame(layout, bg, _grid, zoom, _north_up)
    local x, y, w, h = layout.x, layout.y, layout.w, layout.h
    overlay_theme.draw_panel(x, y, w, h, "RADAR")
    local rect_f = draw_fn("rect_filled", "RectFilled")
    if rect_f then
        pcall(rect_f, x + 7, y + TITLE_H + 3, w - 14, h - TITLE_H - 10,
            theme.alpha(bg or theme.PANEL_DEEP, 0.36), 7)
    end
    local zoom_text = string.format("x%.2f", tonumber(zoom) or 1)
    local zoom_w = theme.text_w(zoom_text, 9)
    draw_util.text(x + w - zoom_w - 11, y + 8, zoom_text, theme.TEXT_DIM, 9)
end
local function draw_facing_arrow(mx, my, col, scale, ang)
    if type(col) ~= "table" then col = theme.CYAN end
    local r = (scale or 3) + 2
    ang = ang or 0
    local function pt(dist, offset)
        local a = ang + (offset or 0)
        return mx + math.sin(a) * dist, my - math.cos(a) * dist
    end
    local tx, ty = pt(r + 2, 0)
    local lx, ly = pt(r * 0.85, 2.4)
    local rx, ry = pt(r * 0.85, -2.4)
    local bx, by = pt(r * 0.25, math.pi)
    local poly = draw_fn("poly_filled", "PolyFilled")
    if poly then
        local ok = pcall(poly, {
            { tx, ty }, { lx, ly }, { bx, by }, { rx, ry },
        }, col)
        if ok then
            local circle = draw_fn("circle", "Circle")
            if circle then
                pcall(circle, mx, my, r + 3, theme.alpha(col, 0.28), 20, 1)
            end
            return
        end
    end
    local line = draw_fn("line", "Line")
    if line then
        pcall(line, tx, ty, lx, ly, col, 2)
        pcall(line, lx, ly, bx, by, col, 2)
        pcall(line, bx, by, rx, ry, col, 2)
        pcall(line, rx, ry, tx, ty, col, 2)
    else
        local circ_f = draw_fn("circle_filled", "CircleFilled")
        if circ_f then
            pcall(circ_f, mx, my, r, col, 12)
        end
    end
end
local function build_north_view(cx, cy, radius, zoom, body_x, body_z, map_rect)
    local visible = BASE_VISIBLE_STUDS / math.max(zoom, 0.05)
    local span = math.max(map_rect.w or 0, map_rect.h or 0, (radius or 0) * 2)
    local pixels_per_stud = span / visible
    local world = map_image.world_size()
    local img_size = world * pixels_per_stud
    local pu, pv = map_image.world_to_uv(body_x or 0, body_z or 0)
    return {
        mode = "north",
        centered = true,
        cx = cx,
        cy = cy,
        zoom = zoom,
        img_size = img_size,
        img_x = cx - pu * img_size,
        img_y = cy - pv * img_size,
        view_x = body_x or 0,
        view_z = body_z or 0,
        yaw = 0,
        map_rect = map_rect,
        vp = nil,
    }
end
local function build_yaw_view(cx, cy, zoom, yaw, view_x, view_z)
    return {
        mode = "yaw",
        cx = cx,
        cy = cy,
        zoom = zoom,
        yaw = yaw,
        view_x = view_x,
        view_z = view_z,
    }
end
local function attach_map_texture(view)
    if not view or not view.map_rect then
        return false
    end
    local ok, mode = pcall(map_image.draw_centered, view, view.map_rect, 0.92)
    if not ok or not mode then
        return false
    end
    if mode == "crop" then
        view.texture_mode = "crop"
    else
        view.vp = { u0 = 0, v0 = 0, u1 = 1, v1 = 1, ready = true }
        view.texture_mode = "fit"
    end
    return true
end
local function cover_map_overflow(layout, map_rect, zoom, _north_up)
    local rect_f = draw_fn("rect_filled", "RectFilled")
    if not rect_f then return end
    local x, y, w, h = layout.x, layout.y, layout.w, layout.h
    local fill = overlay_theme.panel_bg()
    local title_h = math.max(TITLE_H + 3, map_rect.y - y)
    pcall(rect_f, x, y, w, title_h, fill, 0)
    local left_w = math.max(0, map_rect.x - x)
    local right_x = map_rect.x + map_rect.w
    local right_w = math.max(0, x + w - right_x)
    local bottom_y = map_rect.y + map_rect.h
    local bottom_h = math.max(0, y + h - bottom_y)
    if left_w > 0 then
        pcall(rect_f, x, map_rect.y, left_w, map_rect.h + bottom_h, fill, 0)
    end
    if right_w > 0 then
        pcall(rect_f, right_x, map_rect.y, right_w, map_rect.h + bottom_h, fill, 0)
    end
    if bottom_h > 0 then
        pcall(rect_f, map_rect.x, bottom_y, map_rect.w, bottom_h, fill, 0)
    end
    draw_util.text(x + 12, y + 8, "RADAR", overlay_theme.text(), 11)
    local zoom_text = string.format("x%.2f", tonumber(zoom) or 1)
    local zoom_w = theme.text_w(zoom_text, 9)
    draw_util.text(x + w - zoom_w - 11, y + 8, zoom_text, theme.TEXT_DIM, 9)
end
function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.RADAR)
    local root = menu_util.parent(P)
    menu_util.section(T, G.RADAR, "Tactical Map")
    menu_util.register_keybind(T, G.RADAR, P, "Enable Radar", false, { key = 0x28 })
    menu.add_checkbox(T, G.RADAR, "april_map_show_players", "Radar Show Players", true, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_npcs", "Radar Show NPCs", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_loot", "Radar Show Loot", true, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_world", "Radar Show Resources", true, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_base", "Radar Show Base Parts", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_waypoints", "Radar Show Waypoints", true, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_raids", "Radar Show Raids", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_labels", "Radar Show Labels", false, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_player_col", "Radar Players Color", theme.RED, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_npc_col", "Radar NPCs Color", theme.ORANGE, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_loot_col", "Radar Loot Color", { 1, 0.85, 0.35, 1 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_world_col", "Radar Resources Color", theme.GREEN, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_base_col", "Radar Base Color", { 0.55, 0.55, 1, 1 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_wp_col", "Radar Waypoints Color", theme.CYAN, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_raid_col", "Radar Raids Color", { 1, 0.5, 0, 1 }, root)
    menu_util.gap(T, G.RADAR)
    menu.add_slider_int(T, G.RADAR, "april_map_zoom", "Radar Zoom Level", 0.05, 5.0, 1.0, "%.2f", root)
    menu.add_slider_int(T, G.RADAR, "april_map_size", "Radar Size", 140, 420, 250, root)
    menu.add_slider_int(T, G.RADAR, "april_map_icon_scale", "Radar Blip Size", 2, 6, 3, root)
    menu_util.button(T, G.RADAR, "april_map_reset_position", "Reset Radar Position", function()
        local sw = select(1, draw_util.screen_size())
        local size = settings.num("april_map_size", 250)
        local rx, ry = sw - size - 16, 16
        if menu and menu.set then
            pcall(menu.set, X_ID, rx)
            pcall(menu.set, Y_ID, ry)
        end
        pcall(function()
            local state = April.require("ui.gs_state")
            state.set(X_ID, rx)
            state.set(Y_ID, ry)
        end)
    end)
    menu_util.bind_children(P, {
        "april_map_show_players", "april_map_show_npcs", "april_map_show_loot",
        "april_map_show_world", "april_map_show_base", "april_map_show_waypoints",
        "april_map_show_raids", "april_map_labels",
        "april_map_player_col", "april_map_npc_col",
        "april_map_loot_col", "april_map_world_col", "april_map_base_col",
        "april_map_wp_col", "april_map_raid_col",
        "april_map_zoom", "april_map_size", "april_map_icon_scale", "april_map_reset_position",
    })
end
function M.draw()
    if not settings.enabled(P) then return end
    if not draw then return end
    local debug = April.require("core.debug")
    debug.guard("radar:draw", M.draw_inner)
end
function M.draw_inner()
    ensure_draw_api()
    overlay_theme.sync()
    local sw, sh = draw_util.screen_size()
    local size = settings.num("april_map_size", 250)
    local default_x, default_y = sw - size - 16, 16
    local x, y = panel_drag.update(
        "tactical_radar", X_ID, Y_ID, size, TITLE_H, sw, sh, default_x, default_y
    )
    x, y = panel_drag.clamp(x, y, size, size, sw, sh, X_ID, Y_ID)
    local w, h = size, size
    local body = {
        x = x + 7,
        y = y + TITLE_H + 3,
        w = w - 14,
        h = h - TITLE_H - 10,
    }
    local map_span = math.max(32, math.min(body.w, body.h))
    local map_rect = {
        x = body.x + (body.w - map_span) * 0.5,
        y = body.y + (body.h - map_span) * 0.5,
        w = map_span,
        h = map_span,
    }
    local cx = map_rect.x + map_rect.w * 0.5
    local cy = map_rect.y + map_rect.h * 0.5
    local radius = math.min(map_rect.w, map_rect.h) * 0.5 - 4
    local zoom = settings.num("april_map_zoom", 1.0)
    local scale = settings.num("april_map_icon_scale", 3)
    local layout = {
        x = x, y = y, w = w, h = h, cx = cx, cy = cy,
        radius = radius, label_radius = math.max(24, radius - 28), scale = scale,
    }
    local bg = theme.MAP_BG or theme.PANEL_DEEP
    local grid = theme.MAP_GRID or theme.BORDER
    local cam_x, _, cam_z, body_x, _, body_z = get_view_origin()
    local yaw = get_camera_yaw()
    local facing = get_facing_angle()
    local view_x, view_z = body_x or cam_x, body_z or cam_z
    local north_up = false
    local view
    map_image.ensure()
    if map_image.ready() then
        north_up = true
        view = build_north_view(cx, cy, radius, zoom, view_x, view_z, map_rect)
    end
    if not view then
        view = build_yaw_view(cx, cy, zoom, yaw, view_x, view_z)
    end
    draw_radar_frame(layout, bg, grid, zoom, north_up)
    if north_up then
        attach_map_texture(view)
        if view.texture_mode then
            cover_map_overflow(layout, map_rect, zoom, true)
        end
    end
    if settings.bool("april_map_show_world", false) then
        local col = settings.color("april_map_world_col", theme.GREEN)
        for _, item in ipairs(cache.world or {}) do
            if env.is_valid(item.inst) then
                local wx, wz = entry_world_xz(item)
                if wx then
                    draw_map_item(wx, wz, col, item.name, "diamond", view, scale, layout, "world")
                end
            end
        end
    end
    if settings.bool("april_map_show_loot", false) then
        local col = settings.color("april_map_loot_col", { 1, 0.85, 0.35, 1 })
        for _, item in ipairs(cache.loot or {}) do
            if env.is_valid(item.inst) then
                local wx, wz = entry_world_xz(item)
                if wx then
                    draw_map_item(wx, wz, col, item.name, "square", view, scale, layout, "loot")
                end
            end
        end
    end
    if settings.bool("april_map_show_base", false) then
        local col = settings.color("april_map_base_col", { 0.55, 0.55, 1, 1 })
        for _, item in ipairs(cache.base or {}) do
            if env.is_valid(item.inst) then
                local wx, wz = entry_world_xz(item)
                if wx then
                    draw_map_item(wx, wz, col, item.name, "diamond", view, scale, layout, "base")
                end
            end
        end
    end
    if settings.bool("april_map_show_npcs", false) then
        local col = settings.color("april_map_npc_col", theme.ORANGE)
        for _, entry in ipairs(cache.npcs or {}) do
            if env.is_valid(entry.inst) then
                local wx, wz = entry_world_xz(entry)
                if wx then
                    local kind = entry.kind or npcs.kind(entry.name)
                    local size_kind = npcs.is_boss_kind(kind) and "boss" or "npc"
                    draw_map_item(wx, wz, col, entry.name, "circle", view, scale, layout, size_kind)
                end
            end
        end
    end
    if settings.bool("april_map_show_waypoints", false) then
        local col = settings.color("april_map_wp_col", theme.CYAN)
        for i, wp in pairs(cache.waypoints or {}) do
            if wp and wp.pos then
                draw_map_item(wp.pos.x, wp.pos.z, col, wp.name or ("WP" .. i), "waypoint", view, scale, layout, "waypoint")
            end
        end
    end
    if settings.bool("april_map_show_raids", false) then
        local col = settings.color("april_map_raid_col", { 1, 0.5, 0, 1 })
        for _, raid in ipairs(cache.raids or {}) do
            if raid and raid.x and raid.z then
                local label = "Raid"
                if raid.count and raid.count > 1 then
                    label = string.format("Raid (%d)", raid.count)
                end
                draw_map_item(raid.x, raid.z, col, label, "diamond", view, scale, layout, "raid")
            end
        end
    end
    if settings.bool("april_map_show_players", false) then
        local col = settings.color("april_map_player_col", theme.RED)
        for _, p in ipairs(cache.players or {}) do
            local px, _, pz = position_xyz(ep.position(p))
            if player_state.is_combat_target(p) and px and pz then
                local label = ep.display_name(p) or ep.name(p)
                draw_map_item(px, pz, col, label, "circle", view, scale, layout, "player")
            end
        end
    end
    local arrow_x, arrow_y = cx, cy
    if north_up and view_x and view_z then
        local ax, ay = world_to_map_north(view_x, view_z, view)
        if ax and ay then
            arrow_x, arrow_y = ax, ay
        end
    end
    local arrow_ang = north_up and facing or 0
    draw_facing_arrow(arrow_x, arrow_y, overlay_theme.accent(), blip_scale(scale, "self"), arrow_ang)
end
return M
end)()

April._mods["features.utility.keybind_viewer"] = (function()
local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local draw_util = April.require("core.draw_util")
local theme = April.require("core.ui_theme")
local feature_bind = April.require("core.feature_bind")
local vk_names = April.require("core.vk_names")
local panel_drag = April.require("core.panel_drag")
local overlay_theme = April.require("core.overlay_theme")
local M = {}
local P = "april_keybinds_enabled"
local X_ID = "april_keybinds_x"
local Y_ID = "april_keybinds_y"
local PANEL_W = 282
local TITLE_H = 30
local function strip_enable_prefix(label)
    if type(label) ~= "string" then return tostring(label or "?") end
    label = label:gsub("^Enable%s+", "")
    return label
end
local function collect_rows()
    local rows = {}
    local only_active = settings.bool("april_keybinds_active_only", false)
    local show_unbound = settings.bool("april_keybinds_show_unbound", true)
    local show_mode = settings.bool("april_keybinds_show_mode", true)
    for _, entry in ipairs(feature_bind.list_entries()) do
        local id = entry.id
        local key = feature_bind.get_key(id)
        local active = feature_bind.active(id)
        if key <= 0 and not show_unbound then
            goto continue
        end
        if only_active and not active then
            goto continue
        end
        if feature_bind.is_hidden_from_list(id) then
            goto continue
        end
        rows[#rows + 1] = {
            id = id,
            label = strip_enable_prefix(entry.label or id),
            key = vk_names.chip(key),
            mode = feature_bind.mode_name(id),
            active = active,
            show_mode = show_mode,
        }
        ::continue::
    end
    table.sort(rows, function(a, b)
        if a.active ~= b.active then return a.active end
        return a.label < b.label
    end)
    return rows
end
function M.register_menu()
    local G = menu_util.G
    local T = menu_util.group(G.MISC)
    local root = menu_util.parent(P)
    menu.add_checkbox(T, G.MISC, P, "Keybind Viewer", false)
    menu_util.section(T, G.MISC, "Keybinds Display")
    menu.add_checkbox(T, G.MISC, "april_keybinds_active_only", "Only Show Active", false, root)
    menu.add_checkbox(T, G.MISC, "april_keybinds_show_unbound", "Show Unbound", true, root)
    menu.add_checkbox(T, G.MISC, "april_keybinds_show_mode", "Show Bind Mode", true, root)
    menu_util.bind_children(P, {
        "april_keybinds_active_only", "april_keybinds_show_unbound", "april_keybinds_show_mode",
    })
end
function M.update(_dt) end
function M.draw()
    if not settings.enabled(P) then return end
    if not draw or not draw.text then return end
    overlay_theme.sync()
    local accent = overlay_theme.accent()
    local sw, sh = draw_util.screen_size()
    local rows = collect_rows()
    local pad = 12
    local row_h = 22
    local count = math.max(#rows, 1)
    local height = TITLE_H + count * row_h + 12
    local x, y = panel_drag.update(
        "keybind_viewer",
        X_ID, Y_ID,
        PANEL_W, TITLE_H,
        sw, sh,
        16, 280
    )
    x, y = panel_drag.clamp(x, y, PANEL_W, height, sw, sh)
    overlay_theme.draw_panel(x, y, PANEL_W, height, "KEYBINDS")
    local ry = y + TITLE_H + 4
    if #rows == 0 then
        draw_util.text(x + pad, ry, "No binds", theme.TEXT_MUTED, 11)
        return
    end
    local max_label = math.max(8, math.floor((PANEL_W - pad * 2) * 0.55 / 7))
    for i = 1, #rows do
        local row = rows[i]
        local name_col = row.active and theme.TEXT or theme.TEXT_MUTED
        local key_col = row.active and accent or theme.TEXT_DIM
        local label = row.label
        if #label > max_label then label = label:sub(1, math.max(1, max_label - 2)) .. ".." end
        draw_util.text(x + pad, ry + 3, label, name_col, 11)
        local right = row.key
        if row.show_mode then
            right = right .. " - " .. row.mode
        end
        local tw = theme.text_w(right, 10)
        draw_util.text(x + PANEL_W - pad - tw, ry + 3, right, key_col, 10)
        ry = ry + row_h
    end
end
return M
end)()

April._mods["features.utility.anti_afk"] = (function()
local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local M = {}
local P = "april_anti_afk"
local INTERVAL_MS = 14 * 60 * 1000
M._last_nudge = 0
local function now_ms()
    if utility and utility.get_tick_count then
        return utility.get_tick_count()
    end
    return math.floor(os.clock() * 1000)
end
local function nudge()
    if input and input.move_mouse then
        pcall(input.move_mouse, 1, 0)
        pcall(input.move_mouse, -1, 0)
        return true
    end
    if utility and utility.key_press then
        pcall(utility.key_press, 0x20)
        return true
    end
    if utility and utility.mouse_click then
        return false
    end
    return false
end
function M.register_menu()
    local G = menu_util.G
    local T = menu_util.group(G.MISC)
    menu.add_checkbox(T, G.MISC, P, "Anti AFK", false)
end
function M.update(_dt)
    if not settings.bool(P, false) then
        M._last_nudge = 0
        return
    end
    local now = now_ms()
    if M._last_nudge == 0 then
        M._last_nudge = now
        return
    end
    if (now - M._last_nudge) < INTERVAL_MS then
        return
    end
    M._last_nudge = now
    nudge()
end
function M.draw() end
return M
end)()

April._mods["features.utility.config"] = (function()
local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local store = April.require("core.config_store")
local notify = April.require("core.notify")
local M = {}
local function active_slot()
    local slot = settings.num("april_cfg_slot", 1)
    if slot < store.SLOT_MIN then slot = store.SLOT_MIN end
    if slot > store.SLOT_MAX then slot = store.SLOT_MAX end
    return slot
end
local function profile_label()
    return settings.str("april_cfg_profile_name", "Default")
end
function M.get_config_path(name)
    return store.get_config_path(name)
end
function M.save_slot(slot)
    slot = slot or active_slot()
    if store.save_slot(slot) then
        store.save_meta()
        notify.success(string.format('Saved "%s" -> Slot %d', profile_label(), slot), 3500)
        return true
    end
    notify.error("Failed to save config", 3500)
    return false
end
function M.load_slot(slot)
    slot = slot or active_slot()
    if store.load_slot(slot) then
        store.save_meta()
        notify.success(string.format('Loaded "%s" from Slot %d', profile_label(), slot), 3500)
        return true
    end
    notify.error(string.format("Slot %d is empty or unreadable", slot), 3500)
    return false
end
function M.delete_slot(slot)
    slot = slot or active_slot()
    if store.delete_slot(slot) then
        store.save_meta()
        notify.warning(string.format("Deleted Slot %d", slot), 3500)
        return true
    end
    notify.error(string.format("Could not delete Slot %d", slot), 3500)
    return false
end
function M.try_autoload()
    return store.try_autoload()
end
function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.CONFIG)
    menu.add_checkbox(T, G.CONFIG, "april_ui_startup_intro", "Startup Animation", true)
    menu_util.input(T, G.CONFIG, "april_cfg_profile_name", "Profile Name", "Default")
    menu.add_slider_int(T, G.CONFIG, "april_cfg_slot", "Active Slot (1-5)", store.SLOT_MIN, store.SLOT_MAX, 1)
    menu_util.button(T, G.CONFIG, "april_cfg_save", "Save to Active Slot", function()
        M.save_slot(active_slot())
    end)
    menu_util.button(T, G.CONFIG, "april_cfg_load", "Load Active Slot", function()
        M.load_slot(active_slot())
    end)
    menu_util.button(T, G.CONFIG, "april_cfg_delete", "Delete Active Slot", function()
        M.delete_slot(active_slot())
    end)
    menu_util.gap(T, G.CONFIG)
    menu.add_checkbox(T, G.CONFIG, "april_cfg_autoload", "Autoload on Start", false)
    menu_util.input(T, G.CONFIG, "april_cfg_autoload_profile", "Autoload Profile Name", "")
    menu.add_slider_int(
        T, G.CONFIG, "april_cfg_autoload_slot", "Autoload Slot (fallback)",
        store.SLOT_MIN, store.SLOT_MAX, 1,
        menu_util.parent("april_cfg_autoload")
    )
    menu_util.gap(T, G.CONFIG)
    menu.add_slider_int(T, G.CONFIG, "april_esp_text_size", "ESP Text Size", 8, 24, 13)
    menu.add_button(T, G.CONFIG, "april_reload_modules", "Reload Game Modules", function()
        April.require("game.bootstrap").force_reload()
        notify.info("Reloading game modules...", 2500)
    end)
    settings.on_change("april_cfg_autoload", function()
        store.save_meta()
    end)
    settings.on_change("april_cfg_autoload_slot", function() store.save_meta() end)
    settings.on_change("april_cfg_autoload_profile", function() store.save_meta() end)
    settings.on_change("april_cfg_slot", function() store.save_meta() end)
    settings.on_change("april_cfg_profile_name", function() store.save_meta() end)
    menu_util.bind_master("april_cfg_autoload", { "april_cfg_autoload_profile", "april_cfg_autoload_slot" })
end
function M.update(_dt) end
function M.draw() end
return M
end)()
