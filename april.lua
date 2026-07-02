--[[
    April — Fallen Survival for Project Vector
    https://github.com/Cunzaki/April

    This is the final bundled script. Load or execute this file in Vector.
    Source modules live in src/ — rebuild with: node scripts/bundle.mjs
    Built: 2026-07-02T06:13:17.026Z
]]

if menu and menu.add_tab then
    menu.add_tab("April", "A", "full")
end

April = {
    version = "3.0.0",
    TAB = "April",
    debug = false,
    _mods = {},
    bundled = true,
}

function April.require(path)
    local mod = April._mods[path]
    if mod == nil then
        error("[April] bundled module missing: " .. path)
    end
    return mod
end


-- ── core/env.lua ──
April._mods["core.env"] = (function()
local M = {}

function M.has_api(name)
    return _G[name] ~= nil
end

function M.require_apis(names)
    for _, name in ipairs(names) do
        if not M.has_api(name) then
            return false, name
        end
    end
    return true
end

function M.safe_call(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

function M.is_valid(inst)
    if not inst or not utility then return false end
    return utility.is_valid(inst)
end

function M.get_workspace()
    if game and game.workspace then return game.workspace end
    return M.safe_call(function() return workspace end)
end

function M.get_local_player()
    if entity and entity.get_local_player then
        return entity.get_local_player()
    end
    if game and game.local_player then return game.local_player end
    return nil
end

function M.get_replicated_storage()
    return M.safe_call(function() return game.get_service("ReplicatedStorage") end)
end

return M

end)()

-- ── core/math_util.lua ──
April._mods["core.math_util"] = (function()
local M = {}

function M.clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

function M.distance3(dx, dy, dz)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function M.distance2(dx, dy)
    return math.sqrt(dx * dx + dy * dy)
end

function M.dot(ax, ay, az, bx, by, bz)
    return ax * bx + ay * by + az * bz
end

function M.screen_fov_dist(sx, sy, cx, cy)
    local dx, dy = sx - cx, sy - cy
    return math.sqrt(dx * dx + dy * dy)
end

function M.vec3_str(v)
    if not v or v.x == nil then return "?" end
    return string.format("%.0f, %.0f, %.0f", v.x, v.y, v.z)
end

return M

end)()

-- ── core/cache.lua ──
April._mods["core.cache"] = (function()
local M = {}

M.players = {}
M.world = {}
M.loot = {}
M.base = {}
M.npcs = {}
M.waypoints = {}
M.stats = {
    last_player_scan = 0,
    last_world_scan = 0,
    last_loot_scan = 0,
    last_base_scan = 0,
    last_npc_scan = 0,
}

function M.clear_bucket(bucket)
    for k in pairs(bucket) do bucket[k] = nil end
end

return M

end)()

-- ── core/settings.lua ──
April._mods["core.settings"] = (function()
local M = {}

local values = {}
local read_count = 0

function M.invalidate()
    values = {}
end

function M.get(id, default)
    if values[id] == nil then
        if menu and menu.get then
            local v = menu.get(id)
            if v ~= nil then values[id] = v else values[id] = default end
        else
            values[id] = default
        end
    end
    read_count = read_count + 1
    return values[id]
end

function M.bool(id, default)
    local v = M.get(id, default)
    return v == true or v == 1
end

function M.num(id, default)
    return tonumber(M.get(id, default)) or default or 0
end

function M.str(id, default)
    local v = M.get(id, default)
    if v == nil then return default or "" end
    return tostring(v)
end

function M.color(id, default)
    if menu and menu.get_color then
        local c = menu.get_color(id)
        if c then
            values[id] = c
            return c
        end
    end
    return default or { 1, 1, 1, 1 }
end

function M.on_change(id, fn)
    if menu and menu.set_callback then
        menu.set_callback(id, function(new_val)
            values[id] = new_val
            if fn then fn(new_val) end
        end)
    end
end

function M.flush()
    values = {}
end

function M.mark_dirty()
    values = {}
end

function M.stats()
    return { reads = read_count }
end

return M

end)()

-- ── core/draw_util.lua ──
April._mods["core.draw_util"] = (function()
local math_util = April.require("core.math_util")

local M = {}

function M.white(r, g, b, a)
    return { r or 1, g or 1, b or 1, a or 1 }
end

function M.text_centered(x, y, text, col, size)
    if not draw or not draw.text or not draw.get_text_size then return end
    local tw, th = draw.get_text_size(text, size or 14)
    draw.text(x - tw * 0.5, y, text, col, size or 14)
end

function M.text_outlined(x, y, text, col, size)
    if not draw or not draw.text then return end
    draw.text(x, y, text, col, size or 14)
end

function M.box_esp(x, y, w, h, col, style)
    if not draw or not draw.box then return end
    draw.box(x, y, w, h, col, 0, style or 0)
end

function M.health_bar(x, y, h, hp, max_hp)
    if not draw or not draw.health_bar then return end
    draw.health_bar(x, y, h, hp, max_hp)
end

function M.line(x1, y1, x2, y2, col, thick)
    if not draw or not draw.line then return end
    draw.line(x1, y1, x2, y2, col, thick or 1)
end

function M.circle(x, y, r, col, filled)
    if not draw then return end
    if filled and draw.circle_filled then
        draw.circle_filled(x, y, r, col, 24)
    elseif draw.circle then
        draw.circle(x, y, r, col, 24, 1)
    end
end

function M.screen_size()
    if draw and draw.get_screen_size then
        return draw.get_screen_size()
    end
    if utility and utility.get_screen_size then
        return utility.get_screen_size()
    end
    return 1920, 1080
end

function M.world_label(inst, text, col, max_dist)
    if not utility or not utility.world_to_screen then return end
    local env = April.require("core.env")
    if not env.is_valid(inst) then return end
    local pos = inst.Position
    if not pos or pos.x == nil then return end

    local me = env.get_local_player()
    if me and me.position and max_dist then
        local dx = pos.x - me.position.x
        local dy = pos.y - me.position.y
        local dz = pos.z - me.position.z
        local dist = math_util.distance3(dx, dy, dz)
        if dist > max_dist then return end
        text = string.format("%s [%dm]", text, math.floor(dist))
    end

    local sx, sy, vis = utility.world_to_screen(pos.x, pos.y, pos.z)
    if vis then
        M.text_centered(sx, sy, text, col, 13)
    end
end

return M

end)()

-- ── core/scheduler.lua ──
April._mods["core.scheduler"] = (function()
local cache = April.require("core.cache")

local M = {}
local jobs = {}
local threads = {}

function M.register(id, interval_ms, fn)
    jobs[id] = {
        id = id,
        interval = interval_ms,
        fn = fn,
        last = 0,
        thread_id = nil,
        running = false,
    }
end

function M.start_all()
    if not thread or not thread.create then return end
    for id, job in pairs(jobs) do
        if not job.thread_id then
            job.running = true
            job.thread_id = thread.create(function()
                local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
                if now - job.last < job.interval then return end
                job.last = now
                local ok, err = pcall(job.fn)
                if not ok and April.debug then
                    print("[April] scan error " .. id .. ": " .. tostring(err))
                end
            end, job.interval)
            threads[id] = job.thread_id
        end
    end
end

function M.stop_all()
    if not thread then return end
    for id, tid in pairs(threads) do
        if thread.is_running and thread.is_running(tid) then
            thread.stop(tid)
        end
        if jobs[id] then
            jobs[id].thread_id = nil
            jobs[id].running = false
        end
    end
    threads = {}
end

function M.tick_fallback()
    if thread and thread.create then return end
    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    for _, job in pairs(jobs) do
        if now - job.last >= job.interval then
            job.last = now
            pcall(job.fn)
        end
    end
end

return M

end)()

-- ── core/menu_util.lua ──
April._mods["core.menu_util"] = (function()
--[[
    Vector binds per-script menu UI to a single tab registered with mode "full".
    All April menu elements must use April.TAB as their tab name.
]]

local M = {}

M.TAB = "April"
M._registered = false

function M.ensure_tab()
    if M._registered then return end
    if menu and menu.add_tab then
        menu.add_tab(M.TAB, "A", "full")
    end
    M._registered = true
end

function M.group(name)
    M.ensure_tab()
    menu.add_group(M.TAB, name)
end

return M

end)()

-- ── game/folders.lua ──
April._mods["game.folders"] = (function()
local env = April.require("core.env")

local M = {}

M.PATHS = {
    drops = { "Drops" },
    bases = { "Bases" },
    animals = { "Animals" },
    plants = { "Plants" },
    vegetation = { "Vegetation" },
    military = { "Military" },
    events = { "Events" },
    monuments = { "Monuments" },
    nodes = { "Nodes" },
    loners = { "Bases", "Loners" },
}

function M.get_folder(...)
    local ws = env.get_workspace()
    if not ws then return nil end
    local cur = ws
    for _, name in ipairs({ ... }) do
        if not cur then return nil end
        cur = env.safe_call(function() return cur:find_first_child(name) end)
        if not env.is_valid(cur) then return nil end
    end
    return cur
end

function M.scan_children(folder, class_filter, max_count)
    local out = {}
    if not env.is_valid(folder) then return out end
    local children = env.safe_call(function() return folder:get_children() end) or {}
    for _, child in ipairs(children) do
        if #out >= (max_count or 500) then break end
        if env.is_valid(child) then
            if not class_filter or child.ClassName == class_filter or env.safe_call(function() return child:is_a(class_filter) end) then
                table.insert(out, child)
            end
        end
    end
    return out
end

function M.scan_descendants(folder, name_filters, max_count)
    local out = {}
    if not env.is_valid(folder) then return out end
    local desc = env.safe_call(function() return folder:get_descendants() end) or {}
    for _, inst in ipairs(desc) do
        if #out >= (max_count or 800) then break end
        if env.is_valid(inst) then
            local n = inst.Name or ""
            for _, pattern in ipairs(name_filters or {}) do
                if n:find(pattern, 1, true) then
                    table.insert(out, inst)
                    break
                end
            end
        end
    end
    return out
end

function M.iter_workspace_folders(keys, fn, max_per)
    for _, key in ipairs(keys) do
        local path = M.PATHS[key]
        if path then
            local folder = M.get_folder(unpack(path))
            if folder then fn(key, folder, max_per) end
        end
    end
end

return M

end)()

-- ── game/items.lua ──
April._mods["game.items"] = (function()
local env = April.require("core.env")

local M = {}
local loaded = false
local by_name = {}

local FALLBACK = {
    ["Wood Log"] = { Type = "Resource" },
    ["Bandage"] = { Type = "Tool" },
    ["Salvaged M14"] = { Type = "Tool" },
}

function M.load()
    if loaded then return true end
    local rep = env.get_replicated_storage()
    if not rep then return false end
    local modules = env.safe_call(function() return rep:find_first_child("Modules") end)
    local items_mod = modules and env.safe_call(function() return modules:find_first_child("Items") end)
    if not items_mod then return false end
    local ok, data = pcall(function() return require(items_mod) end)
    if ok and type(data) == "table" then
        if data[1] then
            for _, entry in ipairs(data) do
                if entry.Name then by_name[entry.Name] = entry end
            end
        else
            for name, entry in pairs(data) do
                if type(entry) == "table" then
                    entry.Name = entry.Name or name
                    by_name[entry.Name] = entry
                end
            end
        end
        loaded = true
        return true
    end
    return false
end

function M.get(name)
    if not loaded then M.load() end
    return by_name[name] or FALLBACK[name]
end

function M.get_type(name)
    local item = M.get(name)
    return item and item.Type or "Unknown"
end

return M

end)()

-- ── game/weapons.lua ──
April._mods["game.weapons"] = (function()
local env = April.require("core.env")

local M = {}
local loaded = false
local weapons = {}

local FALLBACK = {
    ["Salvaged M14"] = {
        Weapon = { RPM = 370, Auto = false },
        Bullet = { Speed = 2100, Gravity = 0.55, MaxRange = 1100 },
    },
}

function M.load()
    if loaded then return true end
    local rep = env.get_replicated_storage()
    if not rep then return false end
    local modules = env.safe_call(function() return rep:find_first_child("Modules") end)
    local tool_mod = modules and env.safe_call(function() return modules:find_first_child("ToolInfo") end)
    if not tool_mod then return false end
    local ok, data = pcall(function() return require(tool_mod) end)
    if ok and type(data) == "table" then
        weapons = data
        loaded = true
        return true
    end
    return false
end

function M.get(weapon_name)
    if not loaded then M.load() end
    return weapons[weapon_name] or FALLBACK[weapon_name]
end

function M.bullet_speed(weapon_name)
    local w = M.get(weapon_name)
    if w and w.Bullet and w.Bullet.Speed then return w.Bullet.Speed end
    return 1000
end

function M.bullet_gravity(weapon_name)
    local w = M.get(weapon_name)
    if w and w.Bullet and w.Bullet.Gravity then return w.Bullet.Gravity end
    return 0.5
end

return M

end)()

-- ── game/inventory.lua ──
April._mods["game.inventory"] = (function()
local env = April.require("core.env")
local items = April.require("game.items")

local M = {}

function M.get_local_inventory()
    local lp = env.get_local_player()
    if not lp or not lp.character then return nil end
    local char = lp.character
    if not env.is_valid(char) then return nil end
    local ic = env.safe_call(function() return char:find_first_child("InventoryController") end)
    if not ic then return nil end
    local fetch = env.safe_call(function() return ic:find_first_child("Fetch") end)
    if not fetch or not fetch.Invoke then return nil end
    local ok, inv, toolbar, armor = pcall(function() return fetch:Invoke() end)
    if not ok or not inv then return nil end
    return { inventory = inv, toolbar = toolbar, armor = armor }
end

function M.resolve_item_name(id)
    if type(id) ~= "number" then return tostring(id) end
    local rep = env.get_replicated_storage()
    if not rep then return "Item#" .. id end
    local modules = env.safe_call(function() return rep:find_first_child("Modules") end)
    local items_mod = modules and env.safe_call(function() return modules:find_first_child("Items") end)
    if items_mod then
        local ok, data = pcall(function() return require(items_mod) end)
        if ok and data and data[id] and data[id].Name then
            return data[id].Name
        end
    end
    return "Item#" .. id
end

function M.get_held_tool_name()
    local lp = env.get_local_player()
    if not lp then return nil end
    if lp.tool_name and lp.tool_name ~= "" then return lp.tool_name end
    local char = lp.character
    if not char or not env.is_valid(char) then return nil end
    for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
        if child.ClassName == "Tool" then return child.Name end
    end
    return nil
end

return M

end)()

-- ── features/combat/aimbot.lua ──
April._mods["features.combat.aimbot"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local env = April.require("core.env")
local draw_util = April.require("core.draw_util")
local math_util = April.require("core.math_util")

local M = {}
local locked_target = nil
local BONES = { "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart" }

function M.register_menu()
    menu.add_group(April.TAB, "Aimbot")
    menu.add_checkbox(April.TAB, "Aimbot", "april_aimbot_enabled", "Enable Aimbot", false)
    menu.add_hotkey(April.TAB, "Aimbot", "april_aimbot_key", "Aim Key", 0x02)
    menu.add_slider_int(April.TAB, "Aimbot", "april_aimbot_fov", "FOV", 10, 600, 120)
    menu.add_combo(April.TAB, "Aimbot", "april_aimbot_bone", "Bone", { "Head", "UpperTorso", "LowerTorso" }, 0)
    menu.add_checkbox(April.TAB, "Aimbot", "april_aimbot_sticky", "Sticky Aim", true)
    menu.add_checkbox(April.TAB, "Aimbot", "april_aimbot_visible", "Visibility Check", true)
    menu.add_checkbox(April.TAB, "Aimbot", "april_aimbot_draw_fov", "Draw FOV", true)
    menu.add_colorpicker(April.TAB, "Aimbot", "april_aimbot_fov_color", "FOV Color", { 1, 1, 1, 0.35 })
end

local function get_bone_name()
    local idx = settings.num("april_aimbot_bone", 0)
    return BONES[(idx or 0) + 1] or "Head"
end

local function key_active()
    local vk = settings.num("april_aimbot_key", 0x02)
    if input and input.is_key_down then return input.is_key_down(vk) end
    return false
end

local function find_target(cx, cy, fov)
    if not entity or not entity.get_players then return nil end
    local bone = get_bone_name()
    local best, best_dist = nil, fov
    for _, p in ipairs(entity.get_players()) do
        if p.is_local or not p.is_alive then goto continue end
        local sx, sy, vis = p:get_bone_screen(bone)
        if not vis then goto continue end
        if settings.bool("april_aimbot_visible", true) and raycast and raycast.is_visible then
            local cam = camera and camera.get_position and camera.get_position()
            local head = p.head_position
            if cam and head and not raycast.is_visible(cam.x, cam.y, cam.z, head.x, head.y, head.z) then
                goto continue
            end
        end
        local d = math_util.screen_fov_dist(sx, sy, cx, cy)
        if d < best_dist then
            best_dist = d
            best = p
        end
        ::continue::
    end
    return best
end

function M.update(dt)
    if not settings.bool("april_aimbot_enabled", false) then
        locked_target = nil
        return
    end
    if not key_active() then
        if not settings.bool("april_aimbot_sticky", true) then locked_target = nil end
        return
    end

    local sw, sh = draw_util.screen_size()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num("april_aimbot_fov", 120)

    if settings.bool("april_aimbot_sticky", true) and locked_target and locked_target.is_alive then
        -- keep lock
    else
        locked_target = find_target(cx, cy, fov)
    end

    if locked_target and camera and camera.look_at then
        local bone = get_bone_name()
        local sx, sy, vis = locked_target:get_bone_screen(bone)
        if vis then
            local pos = locked_target.head_position or locked_target.position
            if pos then
                camera.look_at(pos.x, pos.y, pos.z, 8)
            end
        end
    end
end

function M.draw()
    if not settings.bool("april_aimbot_draw_fov", true) then return end
    local sw, sh = draw_util.screen_size()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num("april_aimbot_fov", 120)
    local col = settings.color("april_aimbot_fov_color", { 1, 1, 1, 0.35 })
    draw_util.circle(cx, cy, fov, col, false)

    if locked_target and locked_target.is_alive then
        local b = locked_target:get_bounds()
        if b and b.valid then
            draw_util.box_esp(b.x, b.y, b.w, b.h, { 1, 0.2, 0.2, 1 }, 1)
        end
    end
end

return M

end)()

-- ── features/combat/recoil.lua ──
April._mods["features.combat.recoil"] = (function()
local settings = April.require("core.settings")

local M = {}

function M.register_menu()
    menu.add_group(April.TAB, "Recoil")
    menu.add_checkbox(April.TAB, "Recoil", "april_recoil_enabled", "Enable Recoil Control", false)
    menu.add_slider_float(April.TAB, "Recoil", "april_recoil_strength", "Strength", 0, 5, 1.0, "%.1f")
end

function M.update(dt)
    if not settings.bool("april_recoil_enabled", false) then return end
    if not input or not input.is_key_down or not input.move_mouse then return end
    if not input.is_key_down(0x01) or not input.is_key_down(0x02) then return end
    local strength = settings.num("april_recoil_strength", 1.0)
    input.move_mouse(0, strength * 2)
end

function M.draw() end

return M

end)()

-- ── features/visuals/player_esp.lua ──
April._mods["features.visuals.player_esp"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")

local M = {}

function M.register_menu()
    menu.add_group(April.TAB, "Players")
    menu.add_checkbox(April.TAB, "Players", "april_esp_enabled", "Player ESP", true)
    menu.add_checkbox(April.TAB, "Players", "april_esp_name", "Name", true)
    menu.add_checkbox(April.TAB, "Players", "april_esp_health", "Health Bar", true)
    menu.add_checkbox(April.TAB, "Players", "april_esp_distance", "Distance", true)
    menu.add_slider_int(April.TAB, "Players", "april_esp_max_dist", "Max Distance", 50, 2000, 800)
    menu.add_colorpicker(April.TAB, "Players", "april_esp_color", "ESP Color", { 0.3, 1, 0.5, 1 })
end

function M.scan()
    cache.players = {}
    if not entity or not entity.get_players then return end
    for _, p in ipairs(entity.get_players()) do
        if p.is_valid then table.insert(cache.players, p) end
    end
    cache.stats.last_player_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_esp_enabled", true) then return end
    local max_dist = settings.num("april_esp_max_dist", 800)
    local col = settings.color("april_esp_color", { 0.3, 1, 0.5, 1 })
    local me = entity and entity.get_local_player and entity.get_local_player()

    for _, p in ipairs(cache.players) do
        if p.is_local or not p.is_alive then goto continue end
        if me and me.position and p.position then
            local dx = p.position.x - me.position.x
            local dy = p.position.y - me.position.y
            local dz = p.position.z - me.position.z
            local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
            if dist > max_dist then goto continue end
        end

        local b = p:get_bounds()
        if not b or not b.valid then goto continue end

        draw_util.box_esp(b.x, b.y, b.w, b.h, col, 0)

        if settings.bool("april_esp_health", true) then
            draw_util.health_bar(b.x - 4, b.y, b.h, p.health, p.max_health)
        end

        local label = ""
        if settings.bool("april_esp_name", true) then label = p.name or "?" end
        if settings.bool("april_esp_distance", true) and me and p.distance_to then
            local d = math.floor(p:distance_to(me.position))
            label = label .. (label ~= "" and " " or "") .. "[" .. d .. "m]"
        end
        if label ~= "" then
            draw_util.text_centered(b.x + b.w * 0.5, b.y - 14, label, { 1, 1, 1, 1 }, 13)
        end

        ::continue::
    end
end

return M

end)()

-- ── features/visuals/crosshair.lua ──
April._mods["features.visuals.crosshair"] = (function()
local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")

local M = {}

function M.register_menu()
    menu.add_group(April.TAB, "Crosshair")
    menu.add_checkbox(April.TAB, "Crosshair", "april_crosshair_enabled", "Crosshair", true)
    menu.add_slider_int(April.TAB, "Crosshair", "april_crosshair_size", "Size", 2, 40, 8)
    menu.add_slider_int(April.TAB, "Crosshair", "april_crosshair_gap", "Gap", 0, 20, 4)
    menu.add_colorpicker(April.TAB, "Crosshair", "april_crosshair_color", "Color", { 1, 1, 1, 1 })
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_crosshair_enabled", true) then return end
    local sw, sh = draw_util.screen_size()
    local cx, cy = sw * 0.5, sh * 0.5
    local size = settings.num("april_crosshair_size", 8)
    local gap = settings.num("april_crosshair_gap", 4)
    local col = settings.color("april_crosshair_color", { 1, 1, 1, 1 })

    draw_util.line(cx - gap - size, cy, cx - gap, cy, col, 1)
    draw_util.line(cx + gap, cy, cx + gap + size, cy, col, 1)
    draw_util.line(cx, cy - gap - size, cx, cy - gap, col, 1)
    draw_util.line(cx, cy + gap, cx, cy + gap + size, col, 1)
end

return M

end)()

-- ── features/visuals/feedback.lua ──
April._mods["features.visuals.feedback"] = (function()
local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")

local M = {}
local last_hit_time = 0

function M.register_menu()
    menu.add_group(April.TAB, "Feedback")
    menu.add_checkbox(April.TAB, "Feedback", "april_hitmarker_enabled", "Hitmarkers", true)
    menu.add_colorpicker(April.TAB, "Feedback", "april_hitmarker_color", "Hit Color", { 1, 0.3, 0.3, 1 })
end

function M.notify_hit()
    last_hit_time = utility and utility.get_time and utility.get_time() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_hitmarker_enabled", true) then return end
    local now = utility and utility.get_time and utility.get_time() or 0
    if now - last_hit_time > 0.35 then return end

    local sw, sh = draw_util.screen_size()
    local cx, cy = sw * 0.5, sh * 0.5
    local col = settings.color("april_hitmarker_color", { 1, 0.3, 0.3, 1 })
    local s = 8
    draw_util.line(cx - s, cy - s, cx - 3, cy - 3, col, 2)
    draw_util.line(cx + s, cy - s, cx + 3, cy - 3, col, 2)
    draw_util.line(cx - s, cy + s, cx - 3, cy + 3, col, 2)
    draw_util.line(cx + s, cy + s, cx + 3, cy + 3, col, 2)
end

return M

end)()

-- ── features/world/world_esp.lua ──
April._mods["features.world.world_esp"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local folders = April.require("game.folders")
local draw_util = April.require("core.draw_util")
local env = April.require("core.env")

local M = {}

local RESOURCE_NAMES = {
    "Stone", "Metal", "Phosphate", "Hemp", "Corn", "Pumpkin", "Wheat",
    "Deer", "Boar", "Wolf", "Node",
}

function M.register_menu()
    menu.add_group(April.TAB, "Resources")
    menu.add_checkbox(April.TAB, "Resources", "april_world_enabled", "Resource ESP", true)
    menu.add_slider_int(April.TAB, "Resources", "april_world_range", "Range", 50, 1500, 400)
    menu.add_colorpicker(April.TAB, "Resources", "april_world_color", "Color", { 0.8, 0.8, 0.2, 1 })
end

function M.scan()
    cache.world = {}
    local max = 300
    folders.iter_workspace_folders({ "drops", "plants", "vegetation", "nodes", "animals" }, function(key, folder)
        local children = folders.scan_descendants(folder, RESOURCE_NAMES, max)
        for _, inst in ipairs(children) do
            table.insert(cache.world, {
                inst = inst,
                name = inst.Name,
                class = inst.ClassName,
                category = key,
            })
        end
        local direct = folders.scan_children(folder, nil, 80)
        for _, inst in ipairs(direct) do
            table.insert(cache.world, {
                inst = inst,
                name = inst.Name,
                class = inst.ClassName,
                category = key,
            })
        end
    end)
    cache.stats.last_world_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_world_enabled", true) then return end
    local range = settings.num("april_world_range", 400)
    local col = settings.color("april_world_color", { 0.8, 0.8, 0.2, 1 })
    for _, entry in ipairs(cache.world) do
        if env.is_valid(entry.inst) then
            local label = entry.name or entry.class
            draw_util.world_label(entry.inst, label, col, range)
        end
    end
end

return M

end)()

-- ── features/world/loot_esp.lua ──
April._mods["features.world.loot_esp"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local folders = April.require("game.folders")
local draw_util = April.require("core.draw_util")
local env = April.require("core.env")

local M = {}

local LOOT_PATTERNS = {
    "Crate", "Barrel", "Egg", "Care", "Boat", "Flycopter", "Loner", "Loot",
}

function M.register_menu()
    menu.add_group(April.TAB, "Loot")
    menu.add_checkbox(April.TAB, "Loot", "april_loot_enabled", "Loot ESP", true)
    menu.add_slider_int(April.TAB, "Loot", "april_loot_range", "Range", 50, 2000, 600)
    menu.add_colorpicker(April.TAB, "Loot", "april_loot_color", "Color", { 1, 0.6, 0.2, 1 })
end

function M.scan()
    cache.loot = {}
    folders.iter_workspace_folders({ "loners", "military", "events" }, function(key, folder)
        local found = folders.scan_descendants(folder, LOOT_PATTERNS, 400)
        for _, inst in ipairs(found) do
            table.insert(cache.loot, { inst = inst, name = inst.Name, category = key })
        end
    end)
    cache.stats.last_loot_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_loot_enabled", true) then return end
    local range = settings.num("april_loot_range", 600)
    local col = settings.color("april_loot_color", { 1, 0.6, 0.2, 1 })
    for _, entry in ipairs(cache.loot) do
        if env.is_valid(entry.inst) then
            draw_util.world_label(entry.inst, entry.name or "Loot", col, range)
        end
    end
end

return M

end)()

-- ── features/world/base_esp.lua ──
April._mods["features.world.base_esp"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local folders = April.require("game.folders")
local draw_util = April.require("core.draw_util")
local env = April.require("core.env")

local M = {}

local BASE_PATTERNS = {
    "Cabinet", "Door", "Turret", "Battery", "Solar", "Windmill", "Sleeping", "Box",
}

function M.register_menu()
    menu.add_group(April.TAB, "Base")
    menu.add_checkbox(April.TAB, "Base", "april_base_enabled", "Base ESP", true)
    menu.add_slider_int(April.TAB, "Base", "april_base_range", "Range", 50, 2000, 800)
    menu.add_colorpicker(April.TAB, "Base", "april_base_color", "Color", { 0.4, 0.7, 1, 1 })
end

function M.scan()
    cache.base = {}
    folders.iter_workspace_folders({ "bases" }, function(key, folder)
        local found = folders.scan_descendants(folder, BASE_PATTERNS, 500)
        for _, inst in ipairs(found) do
            table.insert(cache.base, { inst = inst, name = inst.Name })
        end
    end)
    cache.stats.last_base_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_base_enabled", true) then return end
    local range = settings.num("april_base_range", 800)
    local col = settings.color("april_base_color", { 0.4, 0.7, 1, 1 })
    for _, entry in ipairs(cache.base) do
        if env.is_valid(entry.inst) then
            draw_util.world_label(entry.inst, entry.name or "Base", col, range)
        end
    end
end

return M

end)()

-- ── features/world/npc_esp.lua ──
April._mods["features.world.npc_esp"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local folders = April.require("game.folders")
local draw_util = April.require("core.draw_util")
local env = April.require("core.env")

local M = {}

local NPC_PATTERNS = {
    "Soldier", "Bruno", "Boris", "Brutus", "BTR", "NPC", "Zombie",
}

function M.register_menu()
    menu.add_group(April.TAB, "NPCs")
    menu.add_checkbox(April.TAB, "NPCs", "april_npc_enabled", "NPC ESP", true)
    menu.add_slider_int(April.TAB, "NPCs", "april_npc_range", "Range", 50, 2000, 1000)
    menu.add_colorpicker(April.TAB, "NPCs", "april_npc_color", "Color", { 1, 0.2, 0.2, 1 })
end

function M.scan()
    cache.npcs = {}
    folders.iter_workspace_folders({ "military", "events", "animals" }, function(key, folder)
        local found = folders.scan_descendants(folder, NPC_PATTERNS, 200)
        for _, inst in ipairs(found) do
            local hum = env.safe_call(function() return inst:find_first_child_of_class("Humanoid") end)
            if hum or inst.ClassName == "Model" then
                table.insert(cache.npcs, { inst = inst, name = inst.Name, category = key })
            end
        end
    end)

    if entity and entity.get_players then
        for _, p in ipairs(entity.get_players()) do
            if p.is_workspace_entity then
                table.insert(cache.npcs, {
                    entity = p,
                    name = p.name,
                    category = "workspace_entity",
                })
            end
        end
    end
    cache.stats.last_npc_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_npc_enabled", true) then return end
    local range = settings.num("april_npc_range", 1000)
    local col = settings.color("april_npc_color", { 1, 0.2, 0.2, 1 })

    for _, entry in ipairs(cache.npcs) do
        if entry.entity then
            local p = entry.entity
            if p.is_alive then
                local b = p:get_bounds()
                if b and b.valid then
                    draw_util.box_esp(b.x, b.y, b.w, b.h, col, 1)
                    draw_util.text_centered(b.x + b.w * 0.5, b.y - 12, entry.name or "NPC", { 1, 1, 1, 1 }, 12)
                end
            end
        elseif env.is_valid(entry.inst) then
            draw_util.world_label(entry.inst, entry.name or "NPC", col, range)
        end
    end
end

return M

end)()

-- ── features/movement/exploits.lua ──
April._mods["features.movement.exploits"] = (function()
local settings = April.require("core.settings")
local env = April.require("core.env")
local math_util = April.require("core.math_util")

local M = {}
local sprint_speed = 24

function M.register_menu()
    menu.add_group(April.TAB, "Exploits")
    menu.add_checkbox(April.TAB, "Exploits", "april_noclip_enabled", "Noclip", false)
    menu.add_hotkey(April.TAB, "Exploits", "april_noclip_key", "Noclip Key", 0x12)
    menu.add_checkbox(April.TAB, "Exploits", "april_omnisprint_enabled", "Omnisprint", false)
    menu.add_slider_int(April.TAB, "Exploits", "april_omnisprint_speed", "Sprint Speed", 16, 80, 32)
end

local function noclip_active()
    if not settings.bool("april_noclip_enabled", false) then return false end
    local vk = settings.num("april_noclip_key", 0x12)
    return input and input.is_key_down and input.is_key_down(vk)
end

function M.update(dt)
    local lp = env.get_local_player()
    if not lp or not lp.character then return end
    local char = lp.character
    if not env.is_valid(char) then return end

    if noclip_active() then
        for _, p in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
            if p.ClassName == "MeshPart" or p.ClassName == "Part" then
                if _G.part and part.set_can_collide then
                    part.set_can_collide(p, false)
                else
                    p.CanCollide = false
                end
            end
        end
        if lp.humanoid and env.is_valid(lp.humanoid) then
            lp.state = 6
        end
    end

    if settings.bool("april_omnisprint_enabled", false) and camera and camera.get_look_vector then
        local look = camera.get_look_vector()
        local right = camera.get_look_vector and look
        if not look or not lp.position then return end
        local speed = settings.num("april_omnisprint_speed", 32) * (dt or 0.016)
        local dx, dz = 0, 0
        if input.is_key_down(0x57) then dx = dx + look.x * speed; dz = dz + look.z * speed end
        if input.is_key_down(0x53) then dx = dx - look.x * speed; dz = dz - look.z * speed end
        if input.is_key_down(0x41) then dx = dx - look.z * speed; dz = dz + look.x * speed end
        if input.is_key_down(0x44) then dx = dx + look.z * speed; dz = dz - look.x * speed end
        if dx ~= 0 or dz ~= 0 then
            local pos = lp.position
            lp.position = Vector3.new(pos.x + dx, pos.y, pos.z + dz)
        end
    end
end

function M.draw() end

return M

end)()

-- ── features/radar/waypoints.lua ──
April._mods["features.radar.waypoints"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")
local env = April.require("core.env")

local M = {}

function M.register_menu()
    menu.add_group(April.TAB, "Waypoints")
    menu.add_button(April.TAB, "Waypoints", "april_wp_set", "Set Waypoint 1", function()
        local lp = env.get_local_player()
        if lp and lp.position then
            cache.waypoints[1] = { name = "Waypoint 1", pos = { x = lp.position.x, y = lp.position.y, z = lp.position.z } }
            print("[April] Waypoint 1 set")
        end
    end)
    menu.add_button(April.TAB, "Waypoints", "april_wp_clear", "Clear Waypoint 1", function()
        cache.waypoints[1] = nil
        print("[April] Waypoint 1 cleared")
    end)
    menu.add_checkbox(April.TAB, "Waypoints", "april_wp_draw", "Draw Waypoints", true)
    menu.add_colorpicker(April.TAB, "Waypoints", "april_wp_color", "Color", { 0.2, 1, 0.8, 1 })
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_wp_draw", true) then return end
    if not utility or not utility.world_to_screen then return end
    local col = settings.color("april_wp_color", { 0.2, 1, 0.8, 1 })
    local sw, sh = draw_util.screen_size()

    for i, wp in pairs(cache.waypoints) do
        if wp and wp.pos then
            local sx, sy, vis = utility.world_to_screen(wp.pos.x, wp.pos.y, wp.pos.z)
            if vis then
                draw_util.circle(sx, sy, 6, col, true)
                draw_util.text_centered(sx, sy - 16, wp.name or ("WP" .. i), col, 12)
                draw_util.line(sw * 0.5, sh, sx, sy, { col[1], col[2], col[3], 0.25 }, 1)
            end
        end
    end
end

return M

end)()

-- ── features/radar/tactical_map.lua ──
April._mods["features.radar.tactical_map"] = (function()
local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local math_util = April.require("core.math_util")
local env = April.require("core.env")

local M = {}

function M.register_menu()
    menu.add_group(April.TAB, "Map")
    menu.add_checkbox(April.TAB, "Map", "april_map_enabled", "Minimap Shell", false)
    menu.add_slider_int(April.TAB, "Map", "april_map_size", "Size", 120, 500, 220)
    menu.add_hotkey(April.TAB, "Map", "april_map_key", "Toggle Key", 0x28)
end

local function map_open()
    if not settings.bool("april_map_enabled", false) then return false end
    local vk = settings.num("april_map_key", 0x28)
    return input and input.is_key_down and input.is_key_down(vk)
end

function M.update(dt) end

function M.draw()
    if not map_open() then return end
    local size = settings.num("april_map_size", 220)
    local sw, sh = draw_util.screen_size()
    local x, y = sw - size - 20, 20

    if draw and draw.rect then
        draw.rect(x, y, size, size, { 0.1, 0.1, 0.1, 0.85 }, 4, 1)
    end
    if draw and draw.rect_filled then
        draw.rect_filled(x + 2, y + 2, size - 4, size - 4, { 0.05, 0.12, 0.08, 0.9 }, 2)
    end

    local cx, cy = x + size * 0.5, y + size * 0.5
    draw_util.circle(cx, cy, 4, { 0.2, 1, 0.4, 1 }, true)
    draw_util.text_centered(x + size * 0.5, y + size - 14, "Tactical Map (WIP)", { 1, 1, 1, 0.7 }, 11)

    if entity and entity.get_players then
        for _, p in ipairs(entity.get_players()) do
            if not p.is_local and p.is_alive and p.position then
                local lp = env.get_local_player()
                if lp and lp.position then
                    local dx = (p.position.x - lp.position.x) * 0.15
                    local dz = (p.position.z - lp.position.z) * 0.15
                    local px = math_util.clamp(cx + dx, x + 6, x + size - 6)
                    local py = math_util.clamp(cy + dz, y + 6, y + size - 6)
                    draw_util.circle(px, py, 3, { 1, 0.3, 0.3, 1 }, true)
                end
            end
        end
    end
end

return M

end)()

-- ── features/utility/config.lua ──
April._mods["features.utility.config"] = (function()
local settings = April.require("core.settings")

local M = {}
local CONFIG_KEYS = {
    "april_aimbot_enabled", "april_aimbot_fov", "april_esp_enabled",
    "april_world_enabled", "april_loot_enabled", "april_noclip_enabled",
}

function M.get_config_path(name)
    local base = os.getenv and os.getenv("LOCALAPPDATA") or ""
    if base == "" then return name end
    return base .. "\\Project Vector\\Scripts\\" .. name
end

function M.save_slot(slot)
    slot = slot or 1
    local lines = {}
    for _, id in ipairs(CONFIG_KEYS) do
        local v = menu.get(id)
        table.insert(lines, id .. "=" .. tostring(v))
    end
    local path = M.get_config_path("April_Slot_" .. slot .. ".txt")
    local f = io.open(path, "w")
    if not f then return false end
    f:write(table.concat(lines, "\n"))
    f:close()
    print("[April] Config saved slot " .. slot)
    return true
end

function M.load_slot(slot)
    slot = slot or 1
    local path = M.get_config_path("April_Slot_" .. slot .. ".txt")
    local f = io.open(path, "r")
    if not f then return false end
    for line in f:lines() do
        local id, val = line:match("^([^=]+)=(.+)$")
        if id and val then
            if val == "true" then menu.set(id, true)
            elseif val == "false" then menu.set(id, false)
            else
                local n = tonumber(val)
                menu.set(id, n or val)
            end
            April.require("core.settings").invalidate()
        end
    end
    f:close()
    print("[April] Config loaded slot " .. slot)
    return true
end

function M.register_menu()
    menu.add_group(April.TAB, "Config")
    menu.add_label(April.TAB, "Config", "April v3 — modular rewrite")
    menu.add_button(April.TAB, "Config", "april_cfg_save", "Save Slot 1", function()
        M.save_slot(1)
    end)
    menu.add_button(April.TAB, "Config", "april_cfg_load", "Load Slot 1", function()
        M.load_slot(1)
    end)
    menu.add_group(April.TAB, "Debug")
    menu.add_checkbox(April.TAB, "Debug", "april_debug_overlay", "Debug Overlay", false)
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_debug_overlay", false) then return end
    if not draw or not draw.text then return end
    local cache = April.require("core.cache")
    local y = 40
    draw.text(10, y, "April v3 " .. (April.version or "?"), { 0.4, 1, 0.6, 1 }, 14)
    y = y + 16
    draw.text(10, y, "Players: " .. #cache.players, { 1, 1, 1, 0.9 }, 12)
    y = y + 14
    draw.text(10, y, "World: " .. #cache.world .. " Loot: " .. #cache.loot, { 1, 1, 1, 0.9 }, 12)
    y = y + 14
    local st = settings.stats()
    draw.text(10, y, "Settings reads: " .. (st.reads or 0), { 1, 1, 1, 0.9 }, 12)
end

return M

end)()

-- ── menu/tabs.lua ──
April._mods["menu.tabs"] = (function()
local M = {}

M.features = {}

function M.register_all()
    local menu_util = April.require("core.menu_util")
    April.TAB = menu_util.TAB
    menu_util.ensure_tab()

    M.features = {
        April.require("features.combat.aimbot"),
        April.require("features.combat.recoil"),
        April.require("features.visuals.player_esp"),
        April.require("features.visuals.crosshair"),
        April.require("features.visuals.feedback"),
        April.require("features.world.world_esp"),
        April.require("features.world.loot_esp"),
        April.require("features.world.base_esp"),
        April.require("features.world.npc_esp"),
        April.require("features.movement.exploits"),
        April.require("features.radar.waypoints"),
        April.require("features.radar.tactical_map"),
        April.require("features.utility.config"),
    }

    local registered = 0
    for i, feat in ipairs(M.features) do
        local ok, err = pcall(function()
            if feat.register_menu then
                feat.register_menu()
                registered = registered + 1
            end
        end)
        if not ok then
            print("[April] menu register failed (#" .. i .. "): " .. tostring(err))
        end
    end
    print("[April] Menu groups registered: " .. registered)
end

function M.setup_scans()
    local scheduler = April.require("core.scheduler")
    local player_esp = April.require("features.visuals.player_esp")
    local world_esp = April.require("features.world.world_esp")
    local loot_esp = April.require("features.world.loot_esp")
    local base_esp = April.require("features.world.base_esp")
    local npc_esp = April.require("features.world.npc_esp")

    scheduler.register("players", 250, function() player_esp.scan() end)
    scheduler.register("world", 1500, function() world_esp.scan() end)
    scheduler.register("loot", 2000, function() loot_esp.scan() end)
    scheduler.register("base", 1000, function() base_esp.scan() end)
    scheduler.register("npcs", 750, function() npc_esp.scan() end)
    scheduler.start_all()

    player_esp.scan()
    world_esp.scan()
    loot_esp.scan()
    base_esp.scan()
    npc_esp.scan()
end

function M.load_game_data()
    April.require("game.items").load()
    April.require("game.weapons").load()
end

function M.update(dt)
    local scheduler = April.require("core.scheduler")
    scheduler.tick_fallback()
    for _, feat in ipairs(M.features) do
        if feat.update then pcall(feat.update, dt) end
    end
end

function M.draw()
    for _, feat in ipairs(M.features) do
        if feat.draw then pcall(feat.draw) end
    end
end

function M.init()
    local env = April.require("core.env")
    local ok, missing = env.require_apis({ "menu", "draw", "utility", "entity", "game" })
    if not ok then
        print("[April v3] Missing API: " .. tostring(missing))
        return false
    end

    M.register_all()
    M.load_game_data()
    M.setup_scans()
    print("[April v3] Loaded — " .. April.version)
    return true
end

return M

end)()

-- ── app.lua ──
April._mods["app"] = (function()
local tabs = April.require("menu.tabs")

local M = {}
local initialized = false
local last_frame = 0

function M.init()
    if initialized then return true end
    initialized = tabs.init()
    return initialized
end

function M.on_frame()
    if not initialized then return end
    local dt = 0.016
    if utility and utility.get_delta_time then
        dt = utility.get_delta_time()
    end
    tabs.update(dt)
    tabs.draw()
end

return M

end)()

local ok, err = pcall(function()
    local app = April.require("app")
    if not app.init() then return end

    function on_frame()
        app.on_frame()
    end

    if callbacks and callbacks.add then
        callbacks.add("on_frame", on_frame)
    elseif draw and draw.callback then
        draw.callback = on_frame
    end
end)

if not ok then
    print("[April] Fatal: " .. tostring(err))
else
    print("[April v3] Ready — " .. April.version)
end
