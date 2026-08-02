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

local CLUSTER_MERGE_M = 50
local CLUSTER_TTL_MS = 600000
local SCAN_MS = 400
local NOTIFY_DEDUP_MS = 8000

local RAID_BOOM = {
    c4 = "Timed Explosive Charge",
    dynamitebundle = "Dynamite Bundle",
    dynamitestick = "Dynamite Stick",
    rocket = "Rocket",
    explosion = "Explosion",
    boom = "Explosion",
    grenade = "Grenade",
    shell = "Tank Shell",
    charge = "Explosive Charge",
}

local KEYWORDS = {
    "explosion", "boom", "rocket", "charge", "c4", "projectile",
    "grenade", "bomb", "shell", "dynamite",
}

M._processed = {}
M._last_scan = 0
M._last_notify = {}
M._projectiles = {}

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

local function classify_name(name)
    local lower = tostring(name or ""):lower()
    for key, label in pairs(RAID_BOOM) do
        if lower:find(key, 1, true) then
            return true, label
        end
    end
    for _, kw in ipairs(KEYWORDS) do
        if lower:find(kw, 1, true) then
            return true, name or "Explosion"
        end
    end
    return false, nil
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
        local ok, cf = pcall(function()
            if inst.GetModelCFrame then return inst:GetModelCFrame() end
            if inst.get_model_cframe then return inst:get_model_cframe() end
            return nil
        end)
        if ok and cf then
            return vec_xyz(cf.Position or cf.position or cf)
        end
    end
    return nil
end

local function process_raid(explosion_type, x, y, z)
    local now = tick_ms()
    local display = explosion_type or "Explosion"
    local ok, label = classify_name(explosion_type)
    if ok and label then display = label end

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
            last_type = display,
            last_update = now,
            items = { { x = x, y = y, z = z, type = display } },
        }
    end

    if settings.enabled(P) and settings.bool(ID_NOTIFY, true) then
        local key = string.format("%.0f:%.0f:%.0f", x, y, z)
        local prev = M._last_notify[key]
        if not prev or (now - prev) > NOTIFY_DEDUP_MS then
            M._last_notify[key] = now
            notify.warning(string.format("Raid start at %.0f, %.0f, %.0f", x, y, z), 6000)
        end
    end
end

local function name_matches(name)
    local lower = tostring(name or ""):lower()
    for _, kw in ipairs(KEYWORDS) do
        if lower:find(kw, 1, true) then
            return true
        end
    end
    return false
end

local function scan_container(container, into, now)
    if not env.is_valid(container) then return end
    local children = env.safe_call(function()
        if container.get_children then return container:get_children() end
        if container.GetChildren then return container:GetChildren() end
        return {}
    end) or {}

    for i = 1, #children do
        local child = children[i]
        if not child then goto cont end
        local cn = child.ClassName or child.class_name or ""
        local name = child.Name or child.name or ""
        local is_match = (cn == "Explosion") or name_matches(name)
        if not is_match then goto cont end

        local x, y, z = instance_pos(child)
        if not x then goto cont end

        local addr = tostring(child.Address or child.address or child)
        into[#into + 1] = {
            name = name,
            x = x, y = y, z = z,
            inst = child,
        }

        if not M._processed[addr] then
            M._processed[addr] = now
            process_raid(name, x, y, z)
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
        return
    end

    local now = tick_ms()
    if (now - M._last_scan) < SCAN_MS then return end
    M._last_scan = now

    -- Prune old processed / clusters
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
    local ws = env.get_workspace()
    if ws then
        local vfx = env.safe_call(function()
            return ws:FindFirstChild("VFX") or ws:find_first_child("VFX")
        end)
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
    local proj_col = { 1, 0.2, 0.2, 1 }
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
            draw_util.box_esp(sx - 5, sy - 5, 10, 10, proj_col, 0)
            draw_util.text_centered(sx, sy - text_size - 2, "[" .. tostring(proj.name) .. "]", proj_col, text_size)
            if mx then
                draw_util.text_centered(sx, sy + 4, string.format("[%.0fm]", dist), proj_col, text_size)
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
                string.format("Potential Raid (%d items)", cl.count or 1),
                string.format("Last: %s", tostring(cl.last_type or "Explosion")),
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
