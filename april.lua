--[[
    April — Fallen Survival for Project Vector
    https://github.com/Cunzaki/April

    Feature options register on Vector's top menu tabs (Aimbot, Player ESP, Crosshair, etc.)
    Built: 2026-07-02T06:32:11.065Z
]]

April = {
    version = "3.0.0",
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
    April registers each feature on its own Vector top-level tab (horizontal bar:
    AIMBOT, VISUALS, WORLD, etc.) instead of stacking everything under Scripts/April.

    Scripts/April "full" tab is only a loader marker — options live on feature tabs.
]]

local M = {}

M.SCRIPT_TAB = "April"
M.SCRIPT_GROUP = "Info"

-- Each slot = one top-level tab in Vector's main menu bar
M.SLOTS = {
    aimbot     = { tab = "Aimbot",      icon = "A", group = "April" },
    recoil     = { tab = "Aimbot",      icon = "A", group = "Recoil Control" },
    player_esp = { tab = "Player ESP",  icon = "P", group = "April" },
    crosshair  = { tab = "Crosshair",   icon = "C", group = "April" },
    hitmarkers = { tab = "Visuals",     icon = "V", group = "Hitmarkers" },
    world      = { tab = "World",       icon = "W", group = "Resources" },
    loot       = { tab = "World",       icon = "W", group = "Loot" },
    npcs       = { tab = "World",       icon = "W", group = "NPCs" },
    base       = { tab = "World",       icon = "W", group = "Base" },
    waypoints  = { tab = "Features",    icon = "F", group = "Waypoints" },
    map        = { tab = "Features",    icon = "F", group = "Tactical Map" },
    misc       = { tab = "Features",    icon = "F", group = "Movement" },
    config     = { tab = "Settings",    icon = "S", group = "April Config" },
}

M._tabs = {}
M._groups = {}
M._script_ready = false

function M.ensure_script_marker()
    if M._script_ready then return end
    if menu and menu.add_tab then
        menu.add_tab(M.SCRIPT_TAB, "A", "full")
        menu.add_group(M.SCRIPT_TAB, M.SCRIPT_GROUP)
        menu.add_label(M.SCRIPT_TAB, M.SCRIPT_GROUP, "April v3 loaded — use the top tabs above.")
        menu.add_label(M.SCRIPT_TAB, M.SCRIPT_GROUP, "Aimbot | Player ESP | Crosshair | World | Features | Settings")
    end
    M._script_ready = true
end

function M.bind(slot)
    M.ensure_script_marker()
    local s = M.SLOTS[slot]
    if not s then error("[April] unknown menu slot: " .. tostring(slot)) end

    if not M._tabs[s.tab] and menu and menu.add_tab then
        menu.add_tab(s.tab, s.icon)
        M._tabs[s.tab] = true
    end

    local gkey = s.tab .. "\0" .. s.group
    if not M._groups[gkey] and menu and menu.add_group then
        menu.add_group(s.tab, s.group)
        M._groups[gkey] = true
    end

    return s.tab, s.group
end

-- Legacy aliases
M.G = {
    AIMBOT = "aimbot",
    RECOIL = "recoil",
    VISUALS = "hitmarkers",
    WORLD = "world",
    LOOT = "loot",
    NPCS = "npcs",
    BASE = "base",
    WAYPOINTS = "waypoints",
    MAP = "map",
    MISC = "misc",
    CONFIG = "config",
}

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
local toolinfo = {}
local recoil_weapons = {}
local originals = {}
local patched = {}

local FALLBACK_STATS = {
    ["Salvaged M14"] = { speed = 850, gravity = 18 },
    ["Salvaged AK47"] = { speed = 800, gravity = 15 },
    ["Military M4A1"] = { speed = 950, gravity = 18 },
    ["Military MP7"] = { speed = 750, gravity = 15 },
    ["Military PKM"] = { speed = 850, gravity = 18 },
    ["Bruno's M4A1"] = { speed = 1000, gravity = 18 },
    ["Salvaged Pump Action"] = { speed = 550, gravity = 15 },
    ["Salvaged Skorpion"] = { speed = 650, gravity = 12 },
    ["Salvaged SMG"] = { speed = 700, gravity = 12 },
    ["Salvaged AK74u"] = { speed = 750, gravity = 15 },
    ["Salvaged AK4"] = { speed = 800, gravity = 15 },
    ["Military Barrett"] = { speed = 1500, gravity = 25 },
    ["Military Barret"] = { speed = 1500, gravity = 25 },
    ["Crossbow"] = { speed = 400, gravity = 35 },
    ["Wooden Bow"] = { speed = 300, gravity = 40 },
}

function M.slug(name)
    return "april_rc_" .. (name or ""):gsub("[^%w]", "_")
end

function M.load()
    if loaded then return true end
    local rep = env.get_replicated_storage()
    if not rep then return false end
    local modules = env.safe_call(function() return rep:find_first_child("Modules") end)
    local tool_mod = modules and env.safe_call(function() return modules:find_first_child("ToolInfo") end)
    if not tool_mod then return false end
    local ok, data = pcall(function() return require(tool_mod) end)
    if not ok or type(data) ~= "table" then return false end

    toolinfo = data
    recoil_weapons = {}
    for name, entry in pairs(data) do
        if type(entry) == "table" and entry.Recoil and entry.Recoil.Camera then
            table.insert(recoil_weapons, name)
        end
    end
    table.sort(recoil_weapons)
    loaded = true
    return true
end

function M.get(name)
    if not loaded then M.load() end
    return toolinfo[name]
end

function M.recoil_weapon_names()
    if not loaded then M.load() end
    return recoil_weapons
end

function M.get_held_weapon_name()
    local lp = env.get_local_player()
    if not lp then return nil end

    local char = lp.character
    if char and env.is_valid(char) then
        for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
            if child and toolinfo[child.Name] and toolinfo[child.Name].Recoil then
                return child.Name
            end
            if child and child.ClassName == "Tool" and toolinfo[child.Name] then
                return child.Name
            end
        end
    end

    local ws = env.get_workspace()
    if ws then
        local vms = env.safe_call(function() return ws:find_first_child("Viewmodels") end)
        if vms then
            for _, vm in ipairs(env.safe_call(function() return vms:get_children() end) or {}) do
                if vm and vm.Name == "Viewmodel" then
                    for _, item in ipairs(env.safe_call(function() return vm:get_children() end) or {}) do
                        if item and item.ClassName == "Model" and toolinfo[item.Name] then
                            return item.Name
                        end
                    end
                end
            end
        end
    end

    if lp.tool_name and lp.tool_name ~= "" and toolinfo[lp.tool_name] then
        return lp.tool_name
    end
    return nil
end

function M.get_weapon_stats(name)
    name = name or M.get_held_weapon_name()
    if not name then return nil end

    local entry = M.get(name)
    if entry and entry.Bullet then
        return {
            speed = entry.Bullet.Speed or 1000,
            gravity = entry.Bullet.Gravity or 35,
            name = name,
        }
    end

    local fb = FALLBACK_STATS[name]
    if fb then
        return { speed = fb.speed, gravity = fb.gravity, name = name }
    end
    return { speed = 1000, gravity = 35, name = name }
end

local function copy_shake(shake)
    if not shake then return nil end
    local out = {}
    for k, v in pairs(shake) do out[k] = v end
    return out
end

local function scale_range(r, scale)
    if type(r) == "table" and r[1] and r[2] then
        return { r[1] * scale, r[2] * scale }
    end
    if type(r) == "number" then return r * scale end
    return r
end

local function store_original(name, entry)
    if originals[name] then return end
    local cam = entry.Recoil.Camera
    originals[name] = {
        RecoilStart = cam.RecoilStart,
        RecoilFinish = cam.RecoilFinish,
        Shake = copy_shake(cam.Shake),
        ScreenShake = entry.Shake and {
            sx = entry.Shake.Strength and (entry.Shake.Strength.x or entry.Shake.Strength.X),
            sy = entry.Shake.Strength and (entry.Shake.Strength.y or entry.Shake.Strength.Y),
            sz = entry.Shake.Strength and (entry.Shake.Strength.z or entry.Shake.Strength.Z),
            Speed = entry.Shake.Speed,
        } or nil,
        VM = entry.Recoil.VM and {
            Pos = entry.Recoil.VM.Pos and {
                X = entry.Recoil.VM.Pos.X,
                Y = entry.Recoil.VM.Pos.Y,
                Z = entry.Recoil.VM.Pos.Z,
            } or nil,
            Rot = entry.Recoil.VM.Rot and {
                X = entry.Recoil.VM.Rot.X,
                Y = entry.Recoil.VM.Rot.Y,
                Z = entry.Recoil.VM.Rot.Z,
            } or nil,
        } or nil,
    }
end

function M.restore_recoil(name)
    local entry = toolinfo[name]
    local orig = originals[name]
    if not entry or not orig or not entry.Recoil then return end
    local cam = entry.Recoil.Camera
    cam.RecoilStart = orig.RecoilStart
    cam.RecoilFinish = orig.RecoilFinish
    cam.Shake = copy_shake(orig.Shake)
    if orig.ScreenShake and entry.Shake and orig.ScreenShake.sx then
        if Vector3 then
            entry.Shake.Strength = Vector3.new(orig.ScreenShake.sx, orig.ScreenShake.sy, orig.ScreenShake.sz)
        end
        entry.Shake.Speed = orig.ScreenShake.Speed
    end
    if orig.VM and entry.Recoil.VM then
        if orig.VM.Pos and entry.Recoil.VM.Pos then
            entry.Recoil.VM.Pos.X = orig.VM.Pos.X
            entry.Recoil.VM.Pos.Y = orig.VM.Pos.Y
            entry.Recoil.VM.Pos.Z = orig.VM.Pos.Z
        end
        if orig.VM.Rot and entry.Recoil.VM.Rot then
            entry.Recoil.VM.Rot.X = orig.VM.Rot.X
            entry.Recoil.VM.Rot.Y = orig.VM.Rot.Y
            entry.Recoil.VM.Rot.Z = orig.VM.Rot.Z
        end
    end
    patched[name] = nil
end

-- reduction_percent: 0 = stock recoil, 100 = no recoil (client ToolInfo only — server spread unchanged)
function M.set_recoil_reduction(name, reduction_percent)
    if not loaded then M.load() end
    local entry = toolinfo[name]
    if not entry or not entry.Recoil or not entry.Recoil.Camera then return false end

    reduction_percent = math.max(0, math.min(100, reduction_percent or 0))
    if reduction_percent <= 0 then
        M.restore_recoil(name)
        return true
    end

    store_original(name, entry)
    local scale = 1 - (reduction_percent / 100)
    local cam = entry.Recoil.Camera
    local orig = originals[name]

    cam.RecoilStart = function(...)
        local pitch, yaw = orig.RecoilStart(...)
        return (pitch or 0) * scale, (yaw or 0) * scale
    end
    cam.RecoilFinish = function(...)
        local pitch, yaw = orig.RecoilFinish(...)
        return (pitch or 0) * scale, (yaw or 0) * scale
    end

    if cam.Shake and orig.Shake then
        cam.Shake = {
            X = scale_range(orig.Shake.X, scale),
            Y = scale_range(orig.Shake.Y, scale),
        }
    end

    if entry.Shake and orig.ScreenShake and orig.ScreenShake.Strength then
        local s = orig.ScreenShake.Strength
        local sx = s.x or s.X or 0
        local sy = s.y or s.Y or 0
        local sz = s.z or s.Z or 0
        if Vector3 then
            entry.Shake.Strength = Vector3.new(sx * scale, sy * scale, sz * scale)
        end
    end

    if entry.Recoil.VM and orig.VM then
        local vm = entry.Recoil.VM
        if vm.Pos and orig.VM.Pos then
            if type(vm.Pos.X) == "number" then vm.Pos.X = (orig.VM.Pos.X or 0) * scale end
            if type(vm.Pos.Y) == "number" then vm.Pos.Y = (orig.VM.Pos.Y or 0) * scale end
            if type(vm.Pos.Z) == "number" then vm.Pos.Z = (orig.VM.Pos.Z or 0) * scale end
        end
        if vm.Rot and orig.VM.Rot then
            vm.Rot.Y = (type(orig.VM.Rot.Y) == "number" and orig.VM.Rot.Y or 0) * scale
            vm.Rot.X = scale_range(orig.VM.Rot.X, scale)
            vm.Rot.Z = scale_range(orig.VM.Rot.Z, scale)
        end
    end

    patched[name] = reduction_percent
    return true
end

function M.apply_all_recoil_from_menu()
    if not menu or not menu.get then return end
    for _, name in ipairs(recoil_weapons) do
        local id = M.slug(name)
        local val = menu.get(id)
        if val == nil then val = 0 end
        M.set_recoil_reduction(name, tonumber(val) or 0)
    end
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
local weapons = April.require("game.weapons")
local env = April.require("core.env")
local draw_util = April.require("core.draw_util")
local math_util = April.require("core.math_util")
local menu_util = April.require("core.menu_util")

local M = {}
local locked_target = nil
local BONES = { "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart" }
local P = "april_aimbot_enabled"

local function screen_center()
    if draw and draw.get_screen_size then
        return draw.get_screen_size()
    end
    return draw_util.screen_size()
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

local function aim_key_down()
    if not menu or not menu.get_key then return false end
    local vk = menu.get_key(P)
    if vk and vk > 0 and input and input.is_key_down then
        return input.is_key_down(vk)
    end
    if input and input.is_key_down then
        return input.is_key_down(0x02)
    end
    return false
end

local function get_bone_name()
    local idx = settings.num("april_aimbot_bone", 0)
    return BONES[(idx or 0) + 1] or "Head"
end

local function get_aim_point(target, bone)
    if not target or not target.is_alive then return nil end
    local sx, sy, vis = target:get_bone_screen(bone)
    if not vis then return nil end

    local pos = target.head_position or target.position
    if not pos then return nil end

    local ax, ay, az = pos.x, pos.y, pos.z

    if settings.bool("april_aimbot_prediction", true) and target.velocity then
        local cam = camera and camera.get_position and camera.get_position()
        if cam then
            local stats = weapons.get_weapon_stats()
            if settings.bool("april_aimbot_auto_weapon", true) then
                stats = weapons.get_weapon_stats()
            end
            if not stats or not settings.bool("april_aimbot_auto_weapon", true) then
                stats = {
                    speed = settings.num("april_aimbot_bullet_speed", 1000),
                    gravity = settings.num("april_aimbot_gravity", 35),
                }
            end
            local speed = (stats and stats.speed) or 1000
            local dx = ax - cam.x
            local dy = ay - cam.y
            local dz = az - cam.z
            local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
            local t = dist / math.max(speed, 1)
            local lead = settings.num("april_aimbot_lead_scale", 1.0)
            ax = ax + target.velocity.x * t * lead
            ay = ay + target.velocity.y * t * lead
            az = az + target.velocity.z * t * lead
        end
    end

    if settings.bool("april_aimbot_drop_prediction", false) then
        local stats = weapons.get_weapon_stats()
        local grav = (stats and stats.gravity) or settings.num("april_aimbot_gravity", 35)
        local cam = camera and camera.get_position and camera.get_position()
        if cam and stats then
            local dist = math_util.distance3(ax - cam.x, ay - cam.y, az - cam.z)
            local t = dist / math.max(stats.speed, 1)
            ay = ay + 0.5 * grav * t * t
        end
    end

    return { x = ax, y = ay, z = az }
end

local function find_target(cx, cy, fov_px)
    if not entity or not entity.get_players then return nil end
    if not settings.bool("april_aimbot_players", true) then return nil end

    local bone = get_bone_name()
    local use_fov_priority = settings.num("april_aimbot_priority", 1) == 1
    local best, best_score = nil, use_fov_priority and fov_px or math.huge
    local cam = camera and camera.get_position and camera.get_position()

    for _, p in ipairs(entity.get_players()) do
        if p.is_local or not p.is_alive then goto continue end
        local aim = get_aim_point(p, bone)
        if not aim then goto continue end

        if settings.bool("april_aimbot_visible", true) and raycast and raycast.is_visible and cam then
            if not raycast.is_visible(cam.x, cam.y, cam.z, aim.x, aim.y, aim.z) then
                goto continue
            end
        end

        local sx, sy, on_screen = w2s(aim.x, aim.y, aim.z)
        if not on_screen then goto continue end

        local fov_dist = math_util.screen_fov_dist(sx, sy, cx, cy)
        if fov_dist > fov_px then goto continue end

        local score = use_fov_priority and fov_dist or (p.distance_to and cam and p:distance_to(cam) or fov_dist)
        if score < best_score then
            best_score = score
            best = p
        end
        ::continue::
    end
    return best
end

function M.register_menu()
    local T, G = menu_util.bind("aimbot")
    menu.add_checkbox(T, G, P, "Enable Aimbot", false, { key = 0x02 })
    menu.add_checkbox(T, G, "april_aimbot_players", "Target Players", true, { parent = P })
    menu.add_slider_int(T, G, "april_aimbot_fov", "FOV Radius (px)", 50, 500, 150, { parent = P })
    menu.add_slider_int(T, G, "april_aimbot_smooth", "Smoothing (frames)", 1, 100, 5, { parent = P })
    menu.add_combo(T, G, "april_aimbot_bone", "Target Bone", { "Head", "UpperTorso", "LowerTorso" }, 0, { parent = P })
    menu.add_combo(T, G, "april_aimbot_priority", "Target Priority", { "Distance", "Crosshair (FOV)" }, 1, { parent = P })
    menu.add_checkbox(T, G, "april_aimbot_sticky", "Sticky Aim", true, { parent = P })
    menu.add_checkbox(T, G, "april_aimbot_visible", "Visibility Check", true, { parent = P })
    menu.add_checkbox(T, G, "april_aimbot_prediction", "Velocity Prediction", true, { parent = P })
    menu.add_slider_float(T, G, "april_aimbot_lead_scale", "Lead Scale", 0.5, 2.0, 1.0, "%.2f", { parent = "april_aimbot_prediction" })
    menu.add_checkbox(T, G, "april_aimbot_drop_prediction", "Bullet Drop Prediction", false, { parent = P })
    menu.add_checkbox(T, G, "april_aimbot_auto_weapon", "Automatic Weapon Stats", true, { parent = P })
    menu.add_slider_int(T, G, "april_aimbot_bullet_speed", "Manual Bullet Speed", 100, 5000, 1000, { parent = P })
    menu.add_slider_int(T, G, "april_aimbot_gravity", "Manual Bullet Gravity", 0, 200, 35, { parent = P })
    menu.add_checkbox(T, G, "april_aimbot_draw_fov", "Show FOV Circle", true, { parent = P, colorpicker = { 1, 1, 1, 1 } })
    menu.add_checkbox(T, G, "april_aimbot_fov_fill", "Fill FOV Circle", false, { parent = "april_aimbot_draw_fov", colorpicker = { 1, 1, 1, 0.2 } })
    menu.add_checkbox(T, G, "april_aimbot_target_line", "Target Line", false, { parent = P, colorpicker = { 1, 0, 0, 1 } })
end

function M.update(dt)
    if not settings.bool(P, false) then
        locked_target = nil
        return
    end
    if not aim_key_down() then
        if not settings.bool("april_aimbot_sticky", true) then locked_target = nil end
        return
    end

    local sw, sh = screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num("april_aimbot_fov", 150)

    if settings.bool("april_aimbot_sticky", true) and locked_target and locked_target.is_alive then
        -- keep
    else
        locked_target = find_target(cx, cy, fov)
    end

    if locked_target and camera and camera.look_at then
        local aim = get_aim_point(locked_target, get_bone_name())
        if aim then
            local smooth = math.max(1, settings.num("april_aimbot_smooth", 5))
            camera.look_at(aim.x, aim.y, aim.z, smooth)
        end
    end
end

function M.draw()
    local sw, sh = screen_center()
    local cx, cy = sw * 0.5, sh * 0.5

    if settings.bool("april_aimbot_draw_fov", true) and settings.bool(P, false) then
        local fov = settings.num("april_aimbot_fov", 150)
        local col = settings.color("april_aimbot_draw_fov", { 1, 1, 1, 1 })
        if settings.bool("april_aimbot_fov_fill", false) and draw and draw.circle_filled then
            local fill = settings.color("april_aimbot_fov_fill", { 1, 1, 1, 0.2 })
            draw.circle_filled(cx, cy, fov, fill, 64)
        end
        if draw and draw.circle then
            draw.circle(cx, cy, fov, col, 64, 1)
        else
            draw_util.circle(cx, cy, fov, col, false)
        end
    end

    if not settings.bool(P, false) or not locked_target or not locked_target.is_alive then return end

    if settings.bool("april_aimbot_target_line", false) then
        local aim = get_aim_point(locked_target, get_bone_name())
        if aim then
            local tx, ty, vis = w2s(aim.x, aim.y, aim.z)
            if vis then
                local col = settings.color("april_aimbot_target_line", { 1, 0, 0, 1 })
                draw_util.line(cx, cy, tx, ty, col, 1.5)
            end
        end
    end

    local b = locked_target:get_bounds()
    if b and b.valid then
        draw_util.box_esp(b.x, b.y, b.w, b.h, { 1, 0.2, 0.2, 1 }, 1)
    end
end

return M

end)()

-- ── features/combat/recoil.lua ──
April._mods["features.combat.recoil"] = (function()
local settings = April.require("core.settings")
local weapons = April.require("game.weapons")
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_recoil_enabled"
local last_apply = 0

function M.register_menu()
    local T, G = menu_util.bind("recoil")
    weapons.load()

    menu.add_checkbox(T, G, P, "Enable Recoil Reduction", false, { key = 0 })
    menu.add_label(T, G, "Scales ToolInfo recoil client-side (same table the game uses).")
    menu.add_label(T, G, "0% = stock  |  100% = no kick. Server spread unchanged.")
    menu.add_slider_int(T, G, "april_recoil_global", "Global Reduction %", 0, 100, 0, { parent = P })
    menu.add_checkbox(T, G, "april_recoil_use_global", "Apply Global To All Guns", false, { parent = P })
    menu.add_separator(T, G)

    local names = weapons.recoil_weapon_names()
    for _, name in ipairs(names) do
        local id = weapons.slug(name)
        menu.add_slider_int(T, G, id, name .. " %", 0, 100, 0, { parent = P })
        if menu.set_callback then
            menu.set_callback(id, function()
                M.sync_patches()
            end)
        end
    end

    if menu.set_callback then
        menu.set_callback("april_recoil_global", function() M.sync_patches() end)
        menu.set_callback("april_recoil_use_global", function() M.sync_patches() end)
        menu.set_callback(P, function() M.sync_patches() end)
    end
end

function M.sync_patches()
    if not settings.bool(P, false) then
        for _, name in ipairs(weapons.recoil_weapon_names()) do
            weapons.set_recoil_reduction(name, 0)
        end
        return
    end

    local global_pct = settings.num("april_recoil_global", 0)
    local use_global = settings.bool("april_recoil_use_global", false)

    for _, name in ipairs(weapons.recoil_weapon_names()) do
        local pct = global_pct
        if not use_global then
            local id = weapons.slug(name)
            pct = settings.num(id, 0)
        end
        weapons.set_recoil_reduction(name, pct)
    end
end

function M.update(dt)
    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    if now - last_apply > 500 then
        last_apply = now
        M.sync_patches()
    end
end

function M.draw()
    if not settings.bool(P, false) then return end
    if not draw or not draw.text then return end
    local held = weapons.get_held_weapon_name()
    if held then
        local id = weapons.slug(held)
        local pct = settings.bool("april_recoil_use_global", false)
            and settings.num("april_recoil_global", 0)
            or settings.num(id, 0)
        draw.text(10, 24, "Weapon: " .. held .. "  RC: " .. pct .. "%", { 0.5, 1, 0.7, 0.9 }, 12)
    end
end

return M

end)()

-- ── features/visuals/player_esp.lua ──
April._mods["features.visuals.player_esp"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_esp_enabled"

function M.register_menu()
    local T, G = menu_util.bind("player_esp")
    menu.add_checkbox(T, G, "april_esp_enabled", "Player ESP", true, { key = 0 })
    menu.add_combo(T, G, "april_esp_box_mode", "Box Mode", { "None", "2D", "Corner" }, 1, { parent = P })
    menu.add_checkbox(T, G, "april_esp_name", "Name", true, { parent = P, colorpicker = { 1, 1, 1, 1 } })
    menu.add_checkbox(T, G, "april_esp_health", "Health Bar", true, { parent = P })
    menu.add_checkbox(T, G, "april_esp_distance", "Distance", true, { parent = P, colorpicker = { 0.7, 0.7, 0.7, 1 } })
    menu.add_checkbox(T, G, "april_esp_held_item", "Held Item", false, { parent = P, colorpicker = { 0.2, 0.8, 1, 1 } })
    menu.add_slider_int(T, G, "april_esp_max_dist", "Max Distance", 50, 5000, 1000, { parent = P })
    menu.add_checkbox(T, G, "april_esp_color", "Box Color", true, { parent = P, colorpicker = { 0.3, 1, 0.5, 1 } })
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
    local max_dist = settings.num("april_esp_max_dist", 1000)
    local col = settings.color("april_esp_color", { 0.3, 1, 0.5, 1 })
    local box_mode = settings.num("april_esp_box_mode", 1)
    local me = entity and entity.get_local_player and entity.get_local_player()
    local text_size = settings.num("april_esp_text_size", 13)

    for _, p in ipairs(cache.players) do
        if p.is_local or not p.is_alive then goto continue end
        if me and me.position and p.position then
            local dx = p.position.x - me.position.x
            local dy = p.position.y - me.position.y
            local dz = p.position.z - me.position.z
            local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
            if dist > max_dist then goto continue end
        end

        local b = p:get_bounds()
        if not b or not b.valid then goto continue end

        if box_mode == 1 then
            draw_util.box_esp(b.x, b.y, b.w, b.h, col, 0)
        elseif box_mode == 2 then
            draw_util.box_esp(b.x, b.y, b.w, b.h, col, 1)
        end

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
            local nc = settings.color("april_esp_name", { 1, 1, 1, 1 })
            draw_util.text_centered(b.x + b.w * 0.5, b.y - 14, label, nc, text_size)
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
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_crosshair_enabled"

function M.register_menu()
    local T, G = menu_util.bind("crosshair")
    menu.add_checkbox(T, G, "april_crosshair_enabled", "Enable Custom Crosshair", true, { key = 0 })
    menu.add_combo(T, G, "april_crosshair_type", "Crosshair Type", { "Cross", "Circle", "Dot", "T-Shape" }, 0, { parent = P })
    menu.add_slider_int(T, G, "april_crosshair_size", "Size", 1, 50, 10, { parent = P })
    menu.add_slider_int(T, G, "april_crosshair_gap", "Gap", 0, 20, 5, { parent = P })
    menu.add_slider_int(T, G, "april_crosshair_thickness", "Thickness", 1, 10, 2, { parent = P })
    menu.add_checkbox(T, G, "april_crosshair_color", "Crosshair Color", true, { parent = P, colorpicker = { 0, 1, 0, 1 } })
    menu.add_checkbox(T, G, "april_crosshair_dot", "Center Dot", false, { parent = P, colorpicker = { 1, 1, 1, 1 } })
    menu.add_checkbox(T, G, "april_crosshair_outline", "Outline", true, { parent = P, colorpicker = { 0, 0, 0, 1 } })
    menu.add_checkbox(T, G, "april_crosshair_rainbow", "Rainbow Crosshair", false, { parent = P })
    menu.add_slider_int(T, G, "april_crosshair_rainbow_speed", "Rainbow Speed", 1, 100, 10, { parent = "april_crosshair_rainbow" })
end

local function crosshair_color()
    if settings.bool("april_crosshair_rainbow", false) then
        local t = (utility and utility.get_tick_count and utility.get_tick_count() or 0) * 0.001
        local speed = settings.num("april_crosshair_rainbow_speed", 10) * 0.1
        return { (math.sin(t * speed) + 1) * 0.5, (math.sin(t * speed + 2) + 1) * 0.5, (math.sin(t * speed + 4) + 1) * 0.5, 1 }
    end
    return settings.color("april_crosshair_color", { 0, 1, 0, 1 })
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_crosshair_enabled", true) then return end
    local sw, sh = draw_util.screen_size()
    local cx, cy = sw * 0.5, sh * 0.5
    local size = settings.num("april_crosshair_size", 10)
    local gap = settings.num("april_crosshair_gap", 5)
    local thick = settings.num("april_crosshair_thickness", 2)
    local col = crosshair_color()
    local kind = settings.num("april_crosshair_type", 0)

    if kind == 1 then
        draw_util.circle(cx, cy, size, col, false)
    elseif kind == 2 then
        draw_util.circle(cx, cy, size * 0.5, col, true)
    elseif kind == 3 then
        draw_util.line(cx - size, cy, cx + size, cy, col, thick)
        draw_util.line(cx, cy, cx, cy + size, col, thick)
    else
        draw_util.line(cx - gap - size, cy, cx - gap, cy, col, thick)
        draw_util.line(cx + gap, cy, cx + gap + size, cy, col, thick)
        draw_util.line(cx, cy - gap - size, cx, cy - gap, col, thick)
        draw_util.line(cx, cy + gap, cx, cy + gap + size, col, thick)
    end

    if settings.bool("april_crosshair_dot", false) then
        local dc = settings.color("april_crosshair_dot", { 1, 1, 1, 1 })
        draw_util.circle(cx, cy, 2, dc, true)
    end
end

return M

end)()

-- ── features/visuals/feedback.lua ──
April._mods["features.visuals.feedback"] = (function()
local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local menu_util = April.require("core.menu_util")

local M = {}
local hit_time = 0
local P = "april_hitmarker_enabled"

function M.register_menu()
    local T, G = menu_util.bind("hitmarkers")
    menu.add_checkbox(T, G, "april_hitmarker_enabled", "Hitmarker", true, { colorpicker = { 1, 1, 1, 1 } })
    menu.add_checkbox(T, G, "april_hitmarker_glow", "Hitmarker Glow", false, { parent = P })
    menu.add_slider_int(T, G, "april_hitmarker_size", "Hitmarker Size", 1, 20, 5, { parent = P })
    menu.add_slider_int(T, G, "april_hitmarker_duration", "Duration (ms)", 100, 2000, 500, { parent = P })
    menu.add_checkbox(T, G, "april_hit_notifier", "Hit Notifier", true)
end

function M.trigger_hit()
    hit_time = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_hitmarker_enabled", true) then return end
    if hit_time == 0 then return end
    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    local dur = settings.num("april_hitmarker_duration", 500)
    if now - hit_time > dur then return end

    local sw, sh = draw_util.screen_size()
    local cx, cy = sw * 0.5, sh * 0.5
    local size = settings.num("april_hitmarker_size", 5)
    local col = settings.color("april_hitmarker_enabled", { 1, 1, 1, 1 })
    local alpha = 1 - (now - hit_time) / dur
    col = { col[1], col[2], col[3], (col[4] or 1) * alpha }

    draw_util.line(cx - size, cy - size, cx - size * 0.3, cy - size * 0.3, col, 2)
    draw_util.line(cx + size, cy - size, cx + size * 0.3, cy - size * 0.3, col, 2)
    draw_util.line(cx - size, cy + size, cx - size * 0.3, cy + size * 0.3, col, 2)
    draw_util.line(cx + size, cy + size, cx + size * 0.3, cy + size * 0.3, col, 2)

    if settings.bool("april_hitmarker_glow", false) then
        draw_util.circle(cx, cy, size * 1.5, { col[1], col[2], col[3], col[4] * 0.3 }, false)
    end
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
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_world_enabled"

local TOGGLES = {
    { id = "april_stone_node", label = "Stone Node", match = "Stone", color = { 0.5, 0.5, 0.5, 1 } },
    { id = "april_metal_node", label = "Metal Node", match = "Metal", color = { 0.7, 0.5, 0.3, 1 } },
    { id = "april_phosphate_node", label = "Phosphate Node", match = "Phosphate", color = { 0.2, 0.8, 0.2, 1 } },
    { id = "april_corn_plant", label = "Corn Plant", match = "Corn", color = { 1, 0.9, 0.3, 1 } },
    { id = "april_deer", label = "Deer", match = "Deer", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_boar", label = "Wild Boar", match = "Boar", color = { 0.4, 0.3, 0.2, 1 } },
    { id = "april_wolf", label = "Wolf", match = "Wolf", color = { 0.5, 0.5, 0.5, 1 } },
    { id = "april_dropped_item", label = "Dropped Items", match = "Drop", color = { 1, 0.8, 0, 1 } },
}

function M.register_menu()
    local T, G = menu_util.bind("world")
    menu.add_checkbox(T, G, "april_world_enabled", "Enable World ESP", true, { key = 0 })
    for _, t in ipairs(TOGGLES) do
        menu.add_checkbox(T, G, t.id, t.label, true, { parent = P, colorpicker = t.color })
    end
    menu.add_slider_int(T, G, "april_world_range", "World Range", 50, 2000, 500, { parent = P })
end

local function matches_toggle(name)
    name = name or ""
    for _, t in ipairs(TOGGLES) do
        if settings.bool(t.id, true) and name:find(t.match) then
            return settings.color(t.id, t.color)
        end
    end
    return nil
end

function M.scan()
    cache.world = {}
    folders.iter_workspace_folders({ "drops", "plants", "vegetation", "nodes", "animals" }, function(key, folder)
        local found = folders.scan_descendants(folder, nil, 400)
        for _, inst in ipairs(found) do
            table.insert(cache.world, { inst = inst, name = inst.Name, category = key })
        end
    end)
    cache.stats.last_world_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_world_enabled", true) then return end
    local range = settings.num("april_world_range", 500)
    for _, entry in ipairs(cache.world) do
        if env.is_valid(entry.inst) then
            local col = matches_toggle(entry.name)
            if col then
                draw_util.world_label(entry.inst, entry.name or "?", col, range)
            end
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
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_loot_enabled"

local TOGGLES = {
    { id = "april_wooden_crate", label = "Wooden Crate", match = "Wooden", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_metal_crate", label = "Metal Crate", match = "Metal", color = { 0.5, 0.5, 0.6, 1 } },
    { id = "april_steel_crate", label = "Steel Crate", match = "Steel", color = { 0.7, 0.7, 0.8, 1 } },
    { id = "april_food_crate", label = "Food Crate", match = "Food", color = { 0.2, 0.8, 0.2, 1 } },
    { id = "april_timed_crate", label = "Timed Crate", match = "Timed", color = { 1, 0.5, 0, 1 } },
    { id = "april_care_package", label = "Care Package", match = "Care", color = { 1, 0.2, 0.2, 1 } },
    { id = "april_body_bag", label = "Body Bag", match = "Body", color = { 0.3, 0.3, 0.3, 1 } },
    { id = "april_sleeper", label = "Sleepers", match = "Sleeper", color = { 0.8, 0.4, 0.8, 1 } },
}

function M.register_menu()
    local T, G = menu_util.bind("loot")
    menu.add_checkbox(T, G, "april_loot_enabled", "Enable Loot ESP", true, { key = 0 })
    for _, t in ipairs(TOGGLES) do
        menu.add_checkbox(T, G, t.id, t.label, true, { parent = P, colorpicker = t.color })
    end
    menu.add_slider_int(T, G, "april_loot_range", "Loot Range", 50, 2000, 300, { parent = P })
end

local function matches_toggle(name)
    name = name or ""
    for _, t in ipairs(TOGGLES) do
        if settings.bool(t.id, true) and name:find(t.match) then
            return settings.color(t.id, t.color)
        end
    end
    return nil
end

function M.scan()
    cache.loot = {}
    folders.iter_workspace_folders({ "loners", "military", "events", "drops" }, function(key, folder)
        local found = folders.scan_descendants(folder, nil, 400)
        for _, inst in ipairs(found) do
            table.insert(cache.loot, { inst = inst, name = inst.Name, category = key })
        end
    end)
    cache.stats.last_loot_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_loot_enabled", true) then return end
    local range = settings.num("april_loot_range", 300)
    for _, entry in ipairs(cache.loot) do
        if env.is_valid(entry.inst) then
            local col = matches_toggle(entry.name)
            if col then
                draw_util.world_label(entry.inst, entry.name or "Loot", col, range)
            end
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
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_base_enabled"

local TOGGLES = {
    { id = "april_base_cabinet", label = "Base Cabinet", match = "Cabinet", color = { 1, 0.8, 0, 1 } },
    { id = "april_storage_cabinet", label = "Storage Cabinet", match = "Storage", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_sleeping_bag", label = "Sleeping Bag", match = "Sleeping", color = { 0.8, 0.2, 0.2, 1 } },
    { id = "april_auto_turret", label = "Auto Turret", match = "Turret", color = { 1, 0.2, 0.2, 1 } },
    { id = "april_wooden_door", label = "Wooden Door", match = "Wooden Door", color = { 0.5, 0.3, 0.1, 1 } },
    { id = "april_metal_door", label = "Metal Door", match = "Metal Door", color = { 0.5, 0.5, 0.6, 1 } },
}

function M.register_menu()
    local T, G = menu_util.bind("base")
    menu.add_checkbox(T, G, "april_base_enabled", "Enable Base ESP", true, { key = 0 })
    for _, t in ipairs(TOGGLES) do
        menu.add_checkbox(T, G, t.id, t.label, true, { parent = P, colorpicker = t.color })
    end
    menu.add_checkbox(T, G, "april_base_distance", "Show Distance", true, { parent = P })
    menu.add_button(T, G, "april_base_rescan", "Force Base Scan", function()
        M.scan()
        print("[April] Base scan forced")
    end)
    menu.add_slider_int(T, G, "april_base_range", "Base Range", 50, 500, 150, { parent = P })
end

local function matches_toggle(name)
    name = name or ""
    for _, t in ipairs(TOGGLES) do
        if settings.bool(t.id, true) and name:find(t.match) then
            return settings.color(t.id, t.color)
        end
    end
    return nil
end

function M.scan()
    cache.base = {}
    folders.iter_workspace_folders({ "bases", "deployables" }, function(key, folder)
        local found = folders.scan_descendants(folder, nil, 300)
        for _, inst in ipairs(found) do
            table.insert(cache.base, { inst = inst, name = inst.Name, category = key })
        end
    end)
    cache.stats.last_base_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_base_enabled", true) then return end
    local range = settings.num("april_base_range", 150)
    for _, entry in ipairs(cache.base) do
        if env.is_valid(entry.inst) then
            local col = matches_toggle(entry.name)
            if col then
                local label = entry.name or "Base"
                draw_util.world_label(entry.inst, label, col, range)
            end
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
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_npc_enabled"

function M.register_menu()
    local T, G = menu_util.bind("npcs")
    menu.add_checkbox(T, G, "april_npc_enabled", "Enable NPC ESP", true, { key = 0, colorpicker = { 1, 0.3, 0.3, 1 } })
    menu.add_checkbox(T, G, "april_npc_soldiers", "Soldiers", true, { parent = P, colorpicker = { 1, 0.3, 0.3, 1 } })
    menu.add_combo(T, G, "april_npc_box_mode", "NPC Box Mode", { "None", "2D", "Corner" }, 1, { parent = P })
    menu.add_checkbox(T, G, "april_npc_health", "Health Bar", true, { parent = P })
    menu.add_checkbox(T, G, "april_npc_name", "Name", true, { parent = P, colorpicker = { 1, 1, 1, 1 } })
    menu.add_checkbox(T, G, "april_npc_distance", "Distance", true, { parent = P, colorpicker = { 0.7, 0.7, 0.7, 1 } })
    menu.add_checkbox(T, G, "april_npc_skeleton", "Skeleton", false, { parent = P, colorpicker = { 1, 1, 1, 1 } })
    menu.add_checkbox(T, G, "april_npc_offscreen", "Offscreen Arrows", false, { parent = P, colorpicker = { 1, 0.3, 0.3, 1 } })
    menu.add_slider_int(T, G, "april_npc_range", "NPC Range", 50, 2000, 500, { parent = P })
end

function M.scan()
    cache.npcs = {}
    folders.iter_workspace_folders({ "animals", "military", "npcs" }, function(key, folder)
        local found = folders.scan_descendants(folder, { "Soldier", "NPC", "Zombie", "BTR" }, 200)
        for _, inst in ipairs(found) do
            table.insert(cache.npcs, { inst = inst, name = inst.Name, category = key })
        end
    end)
    cache.stats.last_npc_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_npc_enabled", true) then return end
    if not settings.bool("april_npc_soldiers", true) then return end
    local range = settings.num("april_npc_range", 500)
    local col = settings.color("april_npc_enabled", { 1, 0.3, 0.3, 1 })
    local box_mode = settings.num("april_npc_box_mode", 1)

    for _, entry in ipairs(cache.npcs) do
        if env.is_valid(entry.inst) then
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
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_noclip_enabled"

function M.register_menu()
    local T, G = menu_util.bind("misc")
    menu.add_slider_int(T, G, "april_esp_text_size", "ESP Text Size", 8, 24, 14)

    menu.add_checkbox(T, G, "april_noclip_enabled", "Noclip", false, { key = 0x12 })
    menu.add_combo(T, G, "april_noclip_mode", "Noclip Mode", { "Toggle", "Hold" }, 1, { parent = P })
    menu.add_slider_int(T, G, "april_noclip_speed", "Noclip Speed", 1, 50, 16, { parent = P })

    menu.add_checkbox(T, G, "april_omnisprint_enabled", "Omnisprint", false, { key = 0 })
    menu.add_combo(T, G, "april_omnisprint_mode", "Sprint Mode", { "Toggle", "Hold" }, 0, { parent = "april_omnisprint_enabled" })
    menu.add_slider_int(T, G, "april_omnisprint_speed", "Sprint Speed", 16, 80, 32, { parent = "april_omnisprint_enabled" })

    menu.add_checkbox(T, G, "april_spider_enabled", "Spider Climb", false, { key = 0 })
    menu.add_slider_int(T, G, "april_spider_speed", "Wall Speed", 1, 50, 20, { parent = "april_spider_enabled" })
end

local function noclip_active()
    if not settings.bool("april_noclip_enabled", false) then return false end
    local vk = 0x12
    if input and input.is_key_down then
        local mode = settings.num("april_noclip_mode", 1)
        if mode == 0 then
            return utility and utility.is_key_toggled and utility.is_key_toggled(vk)
        end
        return input.is_key_down(vk)
    end
    return false
end

function M.update(dt)
    dt = dt or 0.016
    local lp = env.get_local_player()
    if not lp then return end

    if noclip_active() and lp.character then
        local hum = lp.character:FindFirstChildOfClass("Humanoid")
        if hum and hum.SetProperty then
            pcall(function() hum:SetProperty("PlatformStand", true) end)
        end
    end

    if settings.bool("april_omnisprint_enabled", false) and camera and camera.get_look_vector then
        local look = camera.get_look_vector()
        local speed = settings.num("april_omnisprint_speed", 32) * dt
        if input and input.is_key_down then
            if input.is_key_down(0x57) then -- W
                pcall(function()
                    if lp.set_velocity then
                        lp:set_velocity(look.x * speed, look.y * speed, look.z * speed)
                    end
                end)
            end
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
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_waypoints_enabled"

function M.register_menu()
    local T, G = menu_util.bind("waypoints")
    menu.add_checkbox(T, G, "april_waypoints_enabled", "Enable Waypoints", true, { key = 0 })
    menu.add_checkbox(T, G, "april_wp_dist", "Show Distance", true, { parent = P })
    menu.add_checkbox(T, G, "april_wp_line", "Draw Line", true, { parent = P })
    menu.add_checkbox(T, G, "april_wp_draw", "Draw Markers", true, { parent = P, colorpicker = { 0.2, 1, 0.8, 1 } })

    for i = 1, 5 do
        menu.add_button(T, G, "april_wp_set_" .. i, "Set Waypoint " .. i, function()
            local lp = env.get_local_player()
            if lp and lp.position then
                cache.waypoints[i] = {
                    name = "Waypoint " .. i,
                    pos = { x = lp.position.x, y = lp.position.y, z = lp.position.z },
                }
                print("[April] Waypoint " .. i .. " set")
            end
        end)
        menu.add_button(T, G, "april_wp_clear_" .. i, "Clear Waypoint " .. i, function()
            cache.waypoints[i] = nil
            print("[April] Waypoint " .. i .. " cleared")
        end)
    end
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_waypoints_enabled", true) then return end
    if not settings.bool("april_wp_draw", true) then return end
    if not utility or not utility.world_to_screen then return end

    local col = settings.color("april_wp_draw", { 0.2, 1, 0.8, 1 })
    local sw, sh = draw_util.screen_size()
    local me = env.get_local_player()

    for i, wp in pairs(cache.waypoints) do
        if wp and wp.pos then
            local sx, sy, vis = utility.world_to_screen(wp.pos.x, wp.pos.y, wp.pos.z)
            if vis then
                draw_util.circle(sx, sy, 6, col, true)
                local label = wp.name or ("WP" .. i)
                if settings.bool("april_wp_dist", true) and me and me.position then
                    local dx = wp.pos.x - me.position.x
                    local dy = wp.pos.y - me.position.y
                    local dz = wp.pos.z - me.position.z
                    local d = math.floor(math.sqrt(dx * dx + dy * dy + dz * dz))
                    label = label .. " [" .. d .. "m]"
                end
                draw_util.text_centered(sx, sy - 16, label, col, 12)
                if settings.bool("april_wp_line", true) then
                    draw_util.line(sw * 0.5, sh, sx, sy, { col[1], col[2], col[3], 0.25 }, 1)
                end
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
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_map_enabled"

function M.register_menu()
    local T, G = menu_util.bind("map")
    menu.add_checkbox(T, G, "april_map_enabled", "Enable Tactical Map", false, { key = 0x28 })
    menu.add_slider_float(T, G, "april_map_zoom", "Zoom Level", 0.05, 5.0, 1.0, "%.2f", { parent = P })
    menu.add_colorpicker(T, G, "april_map_bg", "Background Color", { 0.05, 0.05, 0.08, 0.95 }, { parent = P })
    menu.add_colorpicker(T, G, "april_map_grid", "Grid Color", { 1, 1, 1, 0.04 }, { parent = P })
    menu.add_colorpicker(T, G, "april_map_local", "Local Player Color", { 0.2, 0.8, 1, 1 }, { parent = P })
    menu.add_checkbox(T, G, "april_map_labels", "Show Labels", false, { parent = P })
    menu.add_checkbox(T, G, "april_map_coords", "Show Coordinates", true, { parent = P })
    menu.add_checkbox(T, G, "april_map_compass", "Compass Overlay", true, { parent = P, colorpicker = { 0.2, 0.8, 1, 0.8 } })
    menu.add_slider_int(T, G, "april_map_size", "Map Size", 120, 500, 220, { parent = P })
end

local function key_active()
    local vk = settings.num("april_map_key", 0x28)
    if input and input.is_key_down then return input.is_key_down(vk) end
    return settings.bool("april_map_enabled", false)
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_map_enabled", false) and not key_active() then return end

    local size = settings.num("april_map_size", 220)
    local sw, sh = draw_util.screen_size()
    local x, y = sw - size - 20, 20
    local bg = settings.color("april_map_bg", { 0.05, 0.05, 0.08, 0.95 })
    local grid = settings.color("april_map_grid", { 1, 1, 1, 0.04 })
    local local_col = settings.color("april_map_local", { 0.2, 0.8, 1, 1 })

    if draw and draw.rect_filled then
        draw.rect_filled(x, y, size, size, bg)
        draw.rect(x, y, size, size, { 1, 1, 1, 0.15 }, 1)
    end

    local step = size / 8
    for i = 1, 7 do
        draw_util.line(x + step * i, y, x + step * i, y + size, grid, 1)
        draw_util.line(x, y + step * i, x + size, y + step * i, grid, 1)
    end

    local lp = env.get_local_player()
    if lp and lp.position then
        local cx, cy = x + size * 0.5, y + size * 0.5
        draw_util.circle(cx, cy, 4, local_col, true)
        if settings.bool("april_map_coords", true) then
            local px, py, pz = lp.position.x, lp.position.y, lp.position.z
            draw_util.text(x + 6, y + size + 4, string.format("%.0f, %.0f, %.0f", px, py, pz), { 1, 1, 1, 0.8 }, 11)
        end
        if settings.bool("april_map_labels", false) then
            draw_util.text(x + 6, y + 4, "Tactical Map", { 1, 1, 1, 0.9 }, 12)
        end
    end

    if settings.bool("april_map_compass", true) then
        local cc = settings.color("april_map_compass", { 0.2, 0.8, 1, 0.8 })
        draw_util.text_centered(x + size * 0.5, y - 14, "N", cc, 12)
    end
end

return M

end)()

-- ── features/utility/config.lua ──
April._mods["features.utility.config"] = (function()
local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")

local M = {}

function M.get_config_path(name)
    local base = os.getenv and os.getenv("LOCALAPPDATA") or ""
    if base == "" then return name end
    return base .. "\\Project Vector\\Scripts\\" .. name
end

function M.save_slot(slot)
    slot = slot or 1
    local keys = {}
    -- collect known april_ ids from menu if possible; fallback list
    local CONFIG_KEYS = {
        "april_aimbot_enabled", "april_aimbot_fov", "april_aimbot_smooth",
        "april_esp_enabled", "april_world_enabled", "april_loot_enabled",
        "april_npc_enabled", "april_base_enabled", "april_noclip_enabled",
        "april_crosshair_enabled", "april_map_enabled",
    }
    local lines = {}
    for _, id in ipairs(CONFIG_KEYS) do
        if menu and menu.get then
            local v = menu.get(id)
            if v ~= nil then table.insert(lines, id .. "=" .. tostring(v)) end
        end
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
        if id and val and menu and menu.set then
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
    local T, G = menu_util.bind("config")
    menu.add_label(T, G, "April v3 — Fallen Survival")
    menu.add_button(T, G, "april_cfg_save_1", "Save Config Slot 1", function() M.save_slot(1) end)
    menu.add_button(T, G, "april_cfg_load_1", "Load Config Slot 1", function() M.load_slot(1) end)
    menu.add_button(T, G, "april_cfg_save_2", "Save Config Slot 2", function() M.save_slot(2) end)
    menu.add_button(T, G, "april_cfg_load_2", "Load Config Slot 2", function() M.load_slot(2) end)
    menu.add_separator(T, G)
    menu.add_checkbox(T, G, "april_debug_overlay", "Debug Overlay", false)
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
    draw.text(10, y, "World: " .. #cache.world .. "  Loot: " .. #cache.loot, { 1, 1, 1, 0.9 }, 12)
    y = y + 14
    draw.text(10, y, "NPCs: " .. #(cache.npcs or {}) .. "  Base: " .. #(cache.base or {}), { 1, 1, 1, 0.9 }, 12)
end

return M

end)()

-- ── menu/tabs.lua ──
April._mods["menu.tabs"] = (function()
local menu_util = April.require("core.menu_util")

local M = {}

M.features = {}

-- Registration order = sidebar group order (groups pre-registered in menu_util)
M.FEATURE_ORDER = {
    "features.combat.aimbot",
    "features.visuals.crosshair",
    "features.visuals.player_esp",
    "features.visuals.feedback",
    "features.world.world_esp",
    "features.combat.recoil",
    "features.radar.waypoints",
    "features.world.loot_esp",
    "features.world.npc_esp",
    "features.world.base_esp",
    "features.radar.tactical_map",
    "features.movement.exploits",
    "features.utility.config",
}

function M.register_all()
    M.features = {}
    local registered = 0

    for _, path in ipairs(M.FEATURE_ORDER) do
        local feat = April.require(path)
        table.insert(M.features, feat)
        local ok, err = pcall(function()
            if feat.register_menu then
                feat.register_menu()
                registered = registered + 1
            end
        end)
        if not ok then
            print("[April] menu register failed (" .. path .. "): " .. tostring(err))
        end
    end

    print("[April] Menu sections registered: " .. registered)
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
