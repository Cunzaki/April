-- Raid ESP: detect structure-raiding explosives from dump VFX / ToolInfo.
-- Timed Charge (SoundName "C4"), Dynamite Bundle, and source-confirmed player
-- Rockets are raid signals. The shared "Rocket" explosion sound is insufficient:
-- HeliRocket uses it too, so tracer history disambiguates the source.
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
-- Auto-clear raid ESP / radar markers after 30 minutes without new signals.
local CLUSTER_TTL_MS = 30 * 60 * 1000
local SCAN_MS = 350
local ROCKET_TRACE_SCAN_MS = 50
local ROCKET_TRACE_TTL_MS = 2500
local ROCKET_TRACE_MATCH_M = 45
local NOTIFY_DEDUP_MS = 10000

-- Dump: ReplicatedStorage.VFX.Explosion sound names + ToolInfo SoundName values.
-- Only these create / refresh a raid cluster.
local RAID_SOUNDS = {
    c4 = { label = "Timed Charge", weight = 3 },
    dynamitebundle = { label = "Dynamite Bundle", weight = 2 },
}
local ROCKET_SIGNAL = { label = "Rocket", weight = 2 }

-- Dump ToolInfo / VFX: combat / PvE noise that previously false-flagged raids.
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

-- In-flight / sticky raid projectiles worth drawing (not auto-clustered alone).
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

    -- ExplosionPart / VFX clone often expose CFrame.
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

-- Resolve dump SoundName from a VFX instance (ExplosionPart child sound, or
-- Explosion clone with the matching Sound playing).
local function raid_signal_from_inst(inst, rocket_source)
    if not inst then return nil end
    local name = inst.Name or inst.name or ""
    local key = norm_name(name)

    if IGNORE_NAMES[key] and not RAID_SOUNDS[key] then
        -- Still inspect children for a playing raid sound (Explosion template).
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

    -- Notify only on real raid charge weight (C4 / bundle / rocket), not weak noise.
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
            -- Bare Explosion instances without a raid sound are ignored (Heli / generic).
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
        -- Only shallow workspace roots (Timed Charge sticks, etc.) — not full tree.
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
