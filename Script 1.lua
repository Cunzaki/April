--[[
    April — Fallen Survival for Project Vector
    https://github.com/Cunzaki/April
    Built: 2026-07-03T09:58:45.521Z
]]

if _G.__APRIL_V3_ACTIVE then
    print("[April WARN] Already running — unload other copies (only load ONE script)")
    return
end
_G.__APRIL_V3_ACTIVE = true

April = {
    version = "3.0.0",
    debug = true,
    _mods = {},
    bundled = true,
}

-- Required first: Scripts > April uses "full" mode (2-column group grid)
if menu and menu.add_tab then
    menu.add_tab("April", "A", "full")
end
April._menu_tab_ready = true

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

-- ── core/debug.lua ──
April._mods["core.debug"] = (function()
--[[
    April debug — always on by default.
    Errors are deduplicated so the console is readable; re-enable spam with April.debug_verbose = true.
]]

local M = {}

local seen_errors = {}
local frame_count = 0
local last_heartbeat = nil

function M.enabled()
    return not (April and April.debug == false)
end

function M.verbose()
    return April and April.debug_verbose == true
end

function M.log(msg)
    print("[April] " .. tostring(msg))
end

function M.warn(msg)
    print("[April WARN] " .. tostring(msg))
end

function M.warn_once(key, msg)
    M.error_once("warn:" .. key, msg)
end

function M.error_once(key, err)
    key = tostring(key)
    if seen_errors[key] and not M.verbose() then return end
    seen_errors[key] = (seen_errors[key] or 0) + 1
    local count = seen_errors[key]
    local suffix = count > 1 and (" (x" .. count .. ")") or ""
    print("[April ERROR][" .. key .. "] " .. tostring(err) .. suffix)
    if debug and debug.traceback then
        print(debug.traceback(err, 2))
    end
end

function M.guard(key, fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c = pcall(fn, ...)
    if not ok then
        M.error_once(key, a)
        return nil
    end
    return a, b, c
end

function M.guard_bool(key, fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then
        M.error_once(key, result)
        return false
    end
    return true, result
end

function M.audit_apis()
    local required = { "menu", "draw", "utility", "entity", "game" }
    local recommended = { "camera", "input", "raycast", "callbacks" }
    local missing = {}
    local warn = {}

    for _, name in ipairs(required) do
        if _G[name] == nil then table.insert(missing, name) end
    end
    for _, name in ipairs(recommended) do
        if _G[name] == nil then table.insert(warn, name) end
    end

    if #missing > 0 then
        M.warn("Missing required APIs: " .. table.concat(missing, ", "))
        return false, missing
    end
    if #warn > 0 then
        M.warn("Optional APIs missing (some features limited): " .. table.concat(warn, ", "))
    end
    return true
end

function M.register_frame_hook(fn)
    if type(fn) ~= "function" then
        M.error_once("frame_hook", "on_frame handler is not a function")
        return false
    end

    -- Vector engine invokes global on_frame() every frame (primary hook).
    _G.on_frame = fn
    M.log("Frame hook: global on_frame()")

    if callbacks and callbacks.add then
        callbacks.add("on_frame", fn)
        M.log("Frame hook: callbacks.add('on_frame')")
    end

    if draw then
        draw.callback = fn
        M.log("Frame hook: draw.callback")
    end

    return true
end

function M.tick_frame()
    frame_count = frame_count + 1
    if not M.enabled() then return end

    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    if last_heartbeat == nil then
        last_heartbeat = now
    end
    if frame_count == 1 then
        M.log("First frame running (#" .. frame_count .. ")")
    end
    if now - last_heartbeat > 30000 then
        last_heartbeat = now
        local players = entity and entity.get_players and #entity.get_players() or 0
        local bootstrap = April.require("game.bootstrap")
        local hooks = April.require("game.shoot_hooks")
        M.log(string.format("Heartbeat — frames=%d players=%d modules=%s hooks=%s %s",
            frame_count, players,
            bootstrap.is_ready() and "OK" or "wait",
            hooks.is_installed() and "OK" or "no",
            bootstrap.get_status and bootstrap.get_status() or ""))
    end
end

function M.reset_errors()
    seen_errors = {}
end

function M.stats()
    return { frames = frame_count, errors = seen_errors }
end

return M

end)()

-- ── core/settings.lua ──
April._mods["core.settings"] = (function()
--[[
    Live menu reads — always fetch from menu.get (legacy cache_settings pattern).
    Stale caching was breaking every feature after first read.
]]

local M = {}

function M.invalidate() end

function M.get(id, default)
    if menu and menu.get then
        local v = menu.get(id)
        if v ~= nil then return v end
    end
    return default
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
        if c then return c end
    end
    return default or { 1, 1, 1, 1 }
end

function M.on_change(id, fn)
    if menu and menu.set_callback then
        menu.set_callback(id, function(new_val)
            if fn then fn(new_val) end
        end)
    end
end

function M.flush() end
function M.mark_dirty() end

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
local debug = April.require("core.debug")

local M = {}
local jobs = {}

function M.register(id, interval_ms, fn)
    jobs[id] = {
        id = id,
        interval = interval_ms,
        fn = fn,
        last = 0,
    }
end

function M.tick()
    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    for id, job in pairs(jobs) do
        if now - job.last >= job.interval then
            job.last = now
            debug.guard("scan:" .. id, job.fn)
        end
    end
end

function M.start_all()
    -- Scans run from on_frame via M.tick() (same as legacy Fallen)
end

function M.stop_all()
    jobs = {}
end

return M

end)()

-- ── core/menu_util.lua ──
April._mods["core.menu_util"] = (function()
local M = {}

M.TAB = "April"

-- 2-column grid order under Scripts > April (full mode)
M.GROUP_ORDER = {
    "Aimbot",
    "Silent Aim",
    "Recoil Control",
    "Player ESP",
    "Crosshair",
    "Hitmarkers",
    "World ESP",
    "Loot ESP",
    "NPC ESP",
    "Base ESP",
    "Radar",
    "Movement",
    "Settings",
}

M._tab_ready = false
M._groups = {}

function M.ensure_tab()
    if M._tab_ready then return end
    if not (April and April._menu_tab_ready) and menu and menu.add_tab then
        menu.add_tab(M.TAB, "A", "full")
    end
    if menu and menu.add_group then
        for _, name in ipairs(M.GROUP_ORDER) do
            if not M._groups[name] then
                menu.add_group(M.TAB, name)
                M._groups[name] = true
            end
        end
    end
    M._tab_ready = true
end

function M.group(name)
    M.ensure_tab()
    if not M._groups[name] and menu and menu.add_group then
        menu.add_group(M.TAB, name)
        M._groups[name] = true
    end
    return M.TAB, name
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

-- ── game/module_scan.lua ──
April._mods["game.module_scan"] = (function()
--[[
    Locate Fallen modules already loaded by the game client.
    Plain loops only — no coroutines (Vector forbids yield during menu/C calls).
]]

local M = {}

function M.has_gc()
    return type(getgc) == "function"
end

local function add_tables(from, out, seen)
    if type(from) ~= "table" then return end
    for _, v in pairs(from) do
        if type(v) == "table" and not seen[v] then
            seen[v] = true
            table.insert(out, v)
        end
    end
end

function M.collect_tables()
    local list = {}
    local seen = {}

    if M.has_gc() then
        local ok, all = pcall(getgc, true)
        if ok and type(all) == "table" then
            for _, v in ipairs(all) do
                if type(v) == "table" and not seen[v] then
                    seen[v] = true
                    table.insert(list, v)
                end
            end
        else
            ok, all = pcall(getgc)
            if ok and type(all) == "table" then
                for _, v in ipairs(all) do
                    if type(v) == "table" and not seen[v] then
                        seen[v] = true
                        table.insert(list, v)
                    end
                end
            end
        end
    end

    if package and type(package.loaded) == "table" then
        add_tables(package.loaded, list, seen)
    end

    if type(shared) == "table" then
        add_tables(shared, list, seen)
    end

    if debug and debug.getregistry then
        local ok, reg = pcall(debug.getregistry)
        if ok and type(reg) == "table" then
            add_tables(reg, list, seen)
        end
    end

    for _, v in pairs(_G) do
        if type(v) == "table" and not seen[v] then
            seen[v] = true
            table.insert(list, v)
        end
    end

    return list
end

function M.each_table(fn)
    local list = M.collect_tables()
    for i = 1, #list do
        fn(list[i])
    end
end

function M.find_vfx_module()
    local found
    M.each_table(function(v)
        if found then return end
        if type(v.CreateProjectile) == "function"
            and type(v.CreateBlood) == "function"
            and type(v.CreateHole) == "function" then
            found = v
        end
    end)
    return found
end

function M.find_raycast_util()
    local found
    M.each_table(function(v)
        if found then return end
        if type(v.MouseRaycast) == "function"
            and type(v.Raycast) == "function"
            and type(v.FilterFunction) == "function" then
            found = v
        end
    end)
    return found
end

function M.find_toolinfo()
    local best, best_n = nil, 0
    M.each_table(function(v)
        local n = 0
        for k, entry in pairs(v) do
            if type(k) == "string" and type(entry) == "table" then
                if entry.Recoil or entry.Bullet or entry.Weapon or entry.Spread then
                    n = n + 1
                end
            end
        end
        if n > best_n and n >= 8 then
            best_n = n
            best = v
        end
    end)
    return best, best_n
end

function M.capabilities()
    return {
        getgc = M.has_gc(),
        require = type(require) == "function",
        load = type(load) == "function",
        loadstring = type(loadstring) == "function",
        package = package ~= nil,
        shared = type(shared) == "table",
        registry = debug and debug.getregistry ~= nil,
    }
end

return M

end)()

-- ── game/bootstrap.lua ──
April._mods["game.bootstrap"] = (function()
--[[
    Fallen game module loader — instance require, source load, memory scan.
]]

local env = April.require("core.env")
local debug = April.require("core.debug")
local module_scan = April.require("game.module_scan")

local M = {}

M._cache = {}
M._errors = {}
M._loading = {}
M._methods = {}
M._ready = false
M._attempts = 0
M._last_try = 0
M._try_interval = 1000
M._diag_logged = false
M._probe = {}

local MODULE_NAMES = { "ToolInfo", "Items", "RaycastUtil", "VFXModule" }

local function find_child(parent, name)
    if not parent then return nil end
    return env.safe_call(function() return parent:find_first_child(name) end)
        or env.safe_call(function() return parent:FindFirstChild(name) end)
end

function M.get_replicated_storage()
    if not game then return nil end
    return env.safe_call(function() return game.get_service("ReplicatedStorage") end)
        or env.safe_call(function() return game:GetService("ReplicatedStorage") end)
        or game.replicated_storage
        or env.safe_call(function() return game.ReplicatedStorage end)
end

function M.get_modules_folder()
    local rep = M.get_replicated_storage()
    if not rep or not env.is_valid(rep) then return nil end

    local modules = find_child(rep, "Modules")
    if modules and env.is_valid(modules) then return modules end

    modules = env.safe_call(function() return rep:find_first_descendant("Modules") end)
        or env.safe_call(function() return rep:FindFirstDescendant("Modules") end)
    if modules and env.is_valid(modules) then return modules end

    for _, child in ipairs(env.safe_call(function() return rep:get_children() end) or {}) do
        local n = child.name or child.Name
        if n == "Modules" and env.is_valid(child) then
            return child
        end
    end
    return nil
end

local function find_module_instance(name)
    local modules = M.get_modules_folder()
    if modules then
        local inst = find_child(modules, name)
        if inst and env.is_valid(inst) then return inst end
    end

    local rep = M.get_replicated_storage()
    if not rep then return nil end

    return env.safe_call(function() return rep:find_first_descendant(name) end)
        or env.safe_call(function() return rep:FindFirstDescendant(name) end)
end

local function module_name_from_arg(mod)
    if type(mod) == "string" then return mod end
    if mod then return mod.name or mod.Name end
    return nil
end

local function sibling_require(mod)
    local n = module_name_from_arg(mod)
    if not n then error("bootstrap require: bad argument") end
    local data = M.get_module(n)
    if data == nil then error("bootstrap require: module not loaded: " .. n) end
    return data
end

local function try_game_require(inst, label)
    if not require or not inst then return nil end

    local tries = {
        function() return require(inst) end,
    }

    local parent = inst.Parent or inst.parent
    local name = inst.Name or inst.name
    if parent and name then
        table.insert(tries, function() return require(parent[name]) end)
        table.insert(tries, function()
            local child = parent:find_first_child(name) or parent:FindFirstChild(name)
            return require(child)
        end)
    end

    for i, fn in ipairs(tries) do
        local ok, result = pcall(fn)
        if ok and type(result) == "table" then
            M._methods[label] = "require:" .. i
            return result
        end
        if not ok then
            M._errors[label] = tostring(result)
        end
    end
    return nil
end

local function load_from_source(inst, label)
    local source = inst.Source or inst.source
    if type(source) ~= "string" or source == "" then
        return nil, "no source"
    end

    local loader_env = setmetatable({
        game = game,
        require = sibling_require,
        script = inst,
        workspace = env.get_workspace(),
    }, { __index = _G })

    local fn, err
    if load then
        fn, err = load(source, "@" .. label, "t", loader_env)
    elseif loadstring then
        fn, err = loadstring(source, "@" .. label)
        if fn and setfenv then setfenv(fn, loader_env) end
    end
    if not fn then return nil, tostring(err) end

    local ok, result = pcall(fn)
    if ok and type(result) == "table" then
        M._methods[label] = "source"
        return result
    end
    return nil, ok and "module returned nil" or tostring(result)
end

function M.require_instance(inst, label)
    if not inst or not env.is_valid(inst) then
        return nil, "invalid instance"
    end

    local data = try_game_require(inst, label)
    if data then return data end

    data = load_from_source(inst, label)
    if data then return data end

    return nil, M._errors[label] or "require unavailable"
end

local function scan_for(name)
    if name == "VFXModule" then
        local v = module_scan.find_vfx_module()
        if v then M._methods[name] = "scan" end
        return v
    end
    if name == "RaycastUtil" then
        local v = module_scan.find_raycast_util()
        if v then M._methods[name] = "scan" end
        return v
    end
    if name == "ToolInfo" then
        local v, n = module_scan.find_toolinfo()
        if v then M._methods[name] = "scan:" .. tostring(n) end
        return v
    end
    return nil
end

function M.get_module(name)
    if M._cache[name] then return M._cache[name] end
    if M._loading[name] then return nil end

    M._loading[name] = true

    -- Scan first: game client may already have modules in memory before require works
    local data = scan_for(name)

    if not data then
        local inst = find_module_instance(name)
        if inst then
            data = M.require_instance(inst, name)
        else
            M._errors[name] = M._errors[name] or "instance not found"
        end
    end

    M._loading[name] = nil

    if data then
        M._cache[name] = data
        M._errors[name] = nil
    end
    return data, M._errors[name]
end

local function in_game_ready()
    if env.get_local_player() then return true end
    if entity and entity.get_players and #entity.get_players() > 0 then return true end
    return false
end

local function count_module_instances()
    local rep = M.get_replicated_storage()
    if not rep then return 0 end
    local n = 0
    for _, name in ipairs(MODULE_NAMES) do
        if find_module_instance(name) then n = n + 1 end
    end
    return n
end

function M.run_probe()
    local caps = module_scan.capabilities()
    local rep = M.get_replicated_storage()
    local folder = M.get_modules_folder()
    M._probe = {
        rep = rep ~= nil,
        folder = folder ~= nil,
        instances = count_module_instances(),
        caps = caps,
        players = entity and entity.get_players and #entity.get_players() or 0,
    }
    return M._probe
end

local function log_diagnostics(loaded)
    if M._diag_logged then return end
    M._diag_logged = true

    local p = M.run_probe()
    local caps = p.caps or {}

    debug.log(string.format(
        "Module probe — players=%d rep=%s folder=%s inst=%d/4 require=%s getgc=%s scan=%s loaded=%d",
        p.players or 0,
        p.rep and "yes" or "no",
        p.folder and "yes" or "no",
        p.instances or 0,
        caps.require and "yes" or "no",
        caps.getgc and "yes" or "no",
        (caps.getgc or caps.registry or caps.shared or caps.package) and "yes" or "no",
        loaded
    ))

    for _, name in ipairs(MODULE_NAMES) do
        if M._cache[name] then
            debug.log("  " .. name .. ": OK (" .. (M._methods[name] or "?") .. ")")
        elseif M._errors[name] then
            debug.warn("  " .. name .. ": FAIL — " .. M._errors[name])
        else
            debug.warn("  " .. name .. ": not found")
        end
    end

    if not M._ready then
        debug.log("Silent aim mouse fallback active until hooks install (LMB + target in FOV)")
    end
end

local function on_modules_ready(loaded)
    debug.log("Game modules ready (" .. loaded .. "/" .. #MODULE_NAMES .. ")")

    local weapons = April.require("game.weapons")
    if weapons.invalidate then weapons.invalidate() end
    weapons.load()

    local count = #(weapons.recoil_weapon_names and weapons.recoil_weapon_names() or {})
    if count > 0 then
        debug.log("ToolInfo weapons: " .. count)
    end

    local recoil = April.require("features.combat.recoil")
    if recoil.register_weapon_sliders then recoil.register_weapon_sliders() end

    local shoot_hooks = April.require("game.shoot_hooks")
    if shoot_hooks.install then shoot_hooks.install() end
end

function M.try_load_all()
    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    if M._attempts > 0 and now - M._last_try < M._try_interval and not M._ready then
        return M._ready
    end
    M._last_try = now
    M._attempts = M._attempts + 1

    if not in_game_ready() then
        return false
    end

    local loaded = 0
    for _, name in ipairs(MODULE_NAMES) do
        if M.get_module(name) then
            loaded = loaded + 1
        end
    end

    local had_ready = M._ready
    M._ready = M._cache.VFXModule ~= nil and M._cache.RaycastUtil ~= nil

    if not M._ready and (M._attempts == 1 or M._attempts == 5 or M._attempts == 15) then
        log_diagnostics(loaded)
    end

    if M._ready and not had_ready then
        on_modules_ready(loaded)
    elseif M._ready then
        local shoot_hooks = April.require("game.shoot_hooks")
        if shoot_hooks.is_installed and not shoot_hooks.is_installed() then
            shoot_hooks.install()
        end
    end

    return M._ready
end

function M.is_ready()
    return M._ready
end

function M.get_status()
    local parts = {}
    for _, name in ipairs({ "VFXModule", "RaycastUtil", "ToolInfo" }) do
        if M._cache[name] then
            table.insert(parts, name:sub(1, 3) .. "+" .. (M._methods[name] or "?"))
        else
            table.insert(parts, name:sub(1, 3) .. "-")
        end
    end
    local p = M._probe
    if p and p.instances and p.instances > 0 and not M._ready then
        table.insert(parts, "inst=" .. p.instances)
    end
    return table.concat(parts, " ")
end

function M.force_reload()
    M._cache = {}
    M._errors = {}
    M._methods = {}
    M._ready = false
    M._last_try = 0
    M._attempts = 0
    M._diag_logged = false
    April.require("game.weapons").invalidate()
    return M.try_load_all()
end

function M.tick()
    if not M._ready then
        M.try_load_all()
    else
        local shoot_hooks = April.require("game.shoot_hooks")
        if shoot_hooks.is_installed and not shoot_hooks.is_installed() then
            shoot_hooks.install()
        end
    end
end

function M.start_background_retry()
    if M._bg_thread or not thread or not thread.create then return end
    M._bg_thread = true
    thread.create(function()
        for _ = 1, 30 do
            if M._ready then return end
            M._last_try = 0
            M.try_load_all()
        end
        if not M._ready then
            log_diagnostics(0)
        end
    end, 2000)
end

return M

end)()

-- ── game/weapons.lua ──
April._mods["game.weapons"] = (function()
local bootstrap = April.require("game.bootstrap")
local env = April.require("core.env")

local M = {}
local loaded = false
local toolinfo = {}
local recoil_weapons = {}

local FALLBACK_STATS = {
    ["Salvaged M14"] = { speed = 2100, gravity = 0.55 },
    ["Salvaged AK47"] = { speed = 2100, gravity = 0.52 },
    ["Military M4A1"] = { speed = 2500, gravity = 0.52 },
    ["Military MP7"] = { speed = 1900, gravity = 0.6 },
    ["Military PKM"] = { speed = 2400, gravity = 0.52 },
    ["Bruno's M4A1"] = { speed = 2500, gravity = 0.52 },
    ["Salvaged Pump Action"] = { speed = 400, gravity = 0.6 },
    ["Salvaged Skorpion"] = { speed = 1400, gravity = 0.6 },
    ["Salvaged SMG"] = { speed = 1600, gravity = 0.6 },
    ["Salvaged AK74u"] = { speed = 1800, gravity = 0.55 },
    ["Salvaged AK4"] = { speed = 2100, gravity = 0.52 },
    ["Military Barrett"] = { speed = 3000, gravity = 0.45 },
    ["Military Barret"] = { speed = 3000, gravity = 0.45 },
    ["Crossbow"] = { speed = 420, gravity = 0.2 },
    ["Wooden Bow"] = { speed = 280, gravity = 0.2 },
}

local function inst_name(inst)
    if not inst then return nil end
    return inst.name or inst.Name
end

function M.slug(name)
    return "april_rc_" .. (name or ""):gsub("[^%w]", "_")
end

function M.invalidate()
    loaded = false
    toolinfo = {}
    recoil_weapons = {}
end

function M.load()
    if loaded then return true end

    local data = bootstrap.get_module("ToolInfo")
    if type(data) ~= "table" then return false end

    toolinfo = data
    recoil_weapons = {}
    for name, entry in pairs(data) do
        if type(entry) == "table" and entry.Recoil and entry.Recoil.Camera then
            table.insert(recoil_weapons, name)
        end
    end
    table.sort(recoil_weapons)
    loaded = #recoil_weapons > 0
    return loaded
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
            local n = inst_name(child)
            if n and toolinfo[n] then
                if toolinfo[n].Recoil or toolinfo[n].Bullet or toolinfo[n].Weapon then
                    return n
                end
            end
            if child and (child.ClassName == "Tool" or child.class_name == "Tool") and n and toolinfo[n] then
                return n
            end
        end
    end

    local ws = env.get_workspace()
    if ws then
        local vms = env.safe_call(function() return ws:find_first_child("Viewmodels") end)
            or env.safe_call(function() return ws:FindFirstChild("Viewmodels") end)
        if vms then
            for _, vm in ipairs(env.safe_call(function() return vms:get_children() end) or {}) do
                if inst_name(vm) == "Viewmodel" then
                    for _, item in ipairs(env.safe_call(function() return vm:get_children() end) or {}) do
                        local n = inst_name(item)
                        if n and toolinfo[n] then return n end
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
            speed = entry.Bullet.Speed or 2000,
            gravity = entry.Bullet.Gravity or 0.55,
            name = name,
        }
    end

    local fb = FALLBACK_STATS[name]
    if fb then
        return { speed = fb.speed, gravity = fb.gravity, name = name }
    end
    return { speed = 2000, gravity = 0.55, name = name }
end

return M

end)()

-- ── game/shoot_hooks.lua ──
April._mods["game.shoot_hooks"] = (function()
local bootstrap = April.require("game.bootstrap")
local april_debug = April.require("core.debug")

local M = {}
local installed = false
local old_create_projectile = nil

local function from_viewmodel()
    if _G.debug and _G.debug.traceback then
        local tb = _G.debug.traceback()
        return type(tb) == "string" and tb:find("ViewmodelController", 1, true) ~= nil
    end
    return true
end

function M.install()
    if installed then return true end

    local VFXModule = bootstrap.get_module("VFXModule")
    local RaycastUtil = bootstrap.get_module("RaycastUtil")

    if not VFXModule or not VFXModule.CreateProjectile then
        april_debug.warn_once("shoot_hooks:vfx", "VFXModule.CreateProjectile not available yet")
        return false
    end

    if RaycastUtil and RaycastUtil.MouseRaycast and not M._old_mouse then
        M._old_mouse = RaycastUtil.MouseRaycast
        RaycastUtil.MouseRaycast = function(self, ...)
            local pos, a, b, c, d, e = M._old_mouse(self, ...)
            if from_viewmodel() then
                local silent = April.require("features.combat.silent_aim")
                local aim = silent.get_redirect_point()
                if aim and Vector3 then
                    pos = Vector3.new(aim.x, aim.y, aim.z)
                end
            end
            return pos, a, b, c, d, e
        end
        april_debug.log("shoot_hooks: RaycastUtil.MouseRaycast hooked")
    end

    if not old_create_projectile then
        old_create_projectile = VFXModule.CreateProjectile
        VFXModule.CreateProjectile = function(self, opts, ...)
            if type(opts) == "table" and from_viewmodel() then
                if opts.StepFunction ~= "FakeStepFunc" and opts.HitFunction ~= "FakeHitFunc" then
                    local silent = April.require("features.combat.silent_aim")
                    silent.apply_projectile(opts)
                end
            end
            if select("#", ...) > 0 then
                return old_create_projectile(self, opts, ...)
            end
            return old_create_projectile(self, opts)
        end
    end

    installed = true
    april_debug.log("shoot_hooks: VFXModule.CreateProjectile hooked")
    return true
end

function M.is_installed()
    return installed
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

-- ── features/combat/targeting.lua ──
April._mods["features.combat.targeting"] = (function()
local settings = April.require("core.settings")
local weapons = April.require("game.weapons")
local math_util = April.require("core.math_util")

local M = {}

M.BONES = { "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart" }

local function w2s(x, y, z)
    if draw and draw.world_to_screen then
        return draw.world_to_screen(x, y, z)
    end
    if utility and utility.world_to_screen then
        return utility.world_to_screen(x, y, z)
    end
    return 0, 0, false
end

function M.bone_name(prefix)
    local idx = settings.num(prefix .. "bone", 0)
    return M.BONES[(idx or 0) + 1] or "Head"
end

function M.weapon_stats(prefix)
    if settings.bool(prefix .. "auto_weapon", true) then
        local stats = weapons.get_weapon_stats()
        if stats then return stats end
    end
    return {
        speed = settings.num(prefix .. "bullet_speed", 2000),
        gravity = settings.num(prefix .. "gravity", 0.55),
    }
end

function M.bone_world(target, bone)
    if not target or not target.is_alive then return nil end
    if target.get_bone_screen then
        local _, _, vis = target:get_bone_screen(bone)
        if not vis then return nil end
    end
    local pos = target.head_position or target.position
    if bone == "Head" and target.head_position then
        pos = target.head_position
    elseif bone ~= "Head" and target.position then
        pos = target.position
    end
    if not pos or pos.x == nil then return nil end
    return { x = pos.x, y = pos.y, z = pos.z }
end

function M.predict_point(origin, point, target, prefix)
    local ax, ay, az = point.x, point.y, point.z

    if settings.bool(prefix .. "prediction", true) and target.velocity then
        local stats = M.weapon_stats(prefix)
        local speed = math.max(stats.speed or 2000, 1)
        local dx = ax - origin.x
        local dy = ay - origin.y
        local dz = az - origin.z
        local dist = math_util.distance3(dx, dy, dz)
        local t = dist / speed
        local lead = settings.num(prefix .. "lead_scale", 1.0)
        ax = ax + target.velocity.x * t * lead
        ay = ay + target.velocity.y * t * lead
        az = az + target.velocity.z * t * lead
    end

    if settings.bool(prefix .. "drop_prediction", true) then
        local stats = M.weapon_stats(prefix)
        local speed = math.max(stats.speed or 2000, 1)
        local grav = stats.gravity or 0.55
        local dx = ax - origin.x
        local dy = ay - origin.y
        local dz = az - origin.z
        local horiz = math.sqrt(dx * dx + dz * dz)
        local t = horiz / speed
        -- Fallen projectiles drop — compensate by aiming higher
        ay = ay + 0.5 * grav * t * t
    end

    return { x = ax, y = ay, z = az }
end

function M.get_aim_point(target, prefix, bone, origin)
    bone = bone or M.bone_name(prefix)
    local base = M.bone_world(target, bone)
    if not base then return nil end

    if not origin and camera and camera.get_position then
        origin = camera.get_position()
    end
    if not origin then return base end

    return M.predict_point(origin, base, target, prefix)
end

function M.find_target(cx, cy, fov_px, prefix)
    if not entity or not entity.get_players then return nil end
    if not settings.bool(prefix .. "players", true) then return nil end

    local bone = M.bone_name(prefix)
    local use_fov = settings.num(prefix .. "priority", 1) == 1
    local best, best_score = nil, use_fov and fov_px or math.huge
    local cam = camera and camera.get_position and camera.get_position()

    for _, p in ipairs(entity.get_players()) do
        if p.is_local or not p.is_alive then goto continue end
        local aim = M.get_aim_point(p, prefix, bone, cam)
        if not aim then goto continue end

        if settings.bool(prefix .. "visible", true) and raycast and raycast.is_visible and cam then
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

end)()

-- ── features/combat/combat_menu.lua ──
April._mods["features.combat.combat_menu"] = (function()
--[[ Shared targeting menu block for Aimbot + Silent Aim ]]

local M = {}

function M.register_targeting(T, G, prefix, parent_id, opts)
    opts = opts or {}
    local p = prefix

    menu.add_checkbox(T, G, p .. "players", "Target Players", true, { parent = parent_id })
    menu.add_slider_int(T, G, p .. "fov", opts.fov_label or "FOV Radius (px)", 20, 600, opts.fov_default or 150, { parent = parent_id })
    menu.add_combo(T, G, p .. "bone", "Target Bone", { "Head", "UpperTorso", "LowerTorso" }, 0, { parent = parent_id })
    menu.add_combo(T, G, p .. "priority", "Priority", { "Distance", "Crosshair (FOV)" }, 1, { parent = parent_id })
    menu.add_checkbox(T, G, p .. "sticky", "Sticky Target", true, { parent = parent_id })
    menu.add_checkbox(T, G, p .. "visible", "Visibility Check", true, { parent = parent_id })
    menu.add_separator(T, G)
    menu.add_checkbox(T, G, p .. "prediction", "Velocity Prediction", true, { parent = parent_id })
    menu.add_slider_float(T, G, p .. "lead_scale", "Lead Scale", 0.5, 2.0, 1.0, "%.2f", { parent = p .. "prediction" })
    menu.add_checkbox(T, G, p .. "drop_prediction", "Bullet Drop Compensation", true, { parent = parent_id })
    menu.add_checkbox(T, G, p .. "auto_weapon", "Auto Weapon Stats (ToolInfo)", true, { parent = parent_id })
    menu.add_slider_int(T, G, p .. "bullet_speed", "Manual Bullet Speed", 100, 5000, 2000, { parent = parent_id })
    menu.add_slider_float(T, G, p .. "gravity", "Manual Bullet Gravity", 0, 5, 0.55, "%.2f", { parent = parent_id })

    if opts.smooth then
        menu.add_slider_int(T, G, p .. "smooth", "Smoothing (frames)", 1, 100, 5, { parent = parent_id })
    end

    menu.add_separator(T, G)
    menu.add_checkbox(T, G, p .. "draw_fov", "Draw FOV Circle", true, { parent = parent_id, colorpicker = opts.fov_color or { 1, 1, 1, 1 } })
    menu.add_checkbox(T, G, p .. "fov_fill", "Fill FOV", false, { parent = p .. "draw_fov", colorpicker = opts.fill_color or { 1, 1, 1, 0.15 } })
    menu.add_checkbox(T, G, p .. "target_line", "Target Line", false, { parent = parent_id, colorpicker = opts.line_color or { 1, 0.2, 0.2, 1 } })
end

return M

end)()

-- ── features/combat/aimbot.lua ──
April._mods["features.combat.aimbot"] = (function()
local settings = April.require("core.settings")
local targeting = April.require("features.combat.targeting")
local draw_util = April.require("core.draw_util")
local menu_util = April.require("core.menu_util")
local combat_menu = April.require("features.combat.combat_menu")

local M = {}
local locked_target = nil
local P = "april_aimbot_enabled"
local PREFIX = "april_aimbot_"

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

function M.register_menu()
    local T, G = menu_util.group("Aimbot")
    menu.add_checkbox(T, G, P, "Enable Aimbot", false, { key = 0x02 })
    menu.add_label(T, G, "Smooth camera aim — hold aim key (default RMB).")
    combat_menu.register_targeting(T, G, PREFIX, P, {
        fov_default = 150,
        smooth = true,
        fov_color = { 0.4, 0.9, 1, 1 },
        fill_color = { 0.4, 0.9, 1, 0.12 },
        line_color = { 1, 0.25, 0.25, 1 },
    })
end

function M.update(dt)
    if not settings.bool(P, false) then
        locked_target = nil
        return
    end
    if not aim_key_down() then
        if not settings.bool(PREFIX .. "sticky", true) then locked_target = nil end
        return
    end

    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num(PREFIX .. "fov", 150)

    if settings.bool(PREFIX .. "sticky", true) and locked_target and locked_target.is_alive then
        -- keep
    else
        locked_target = targeting.find_target(cx, cy, fov, PREFIX)
    end

    if locked_target and camera and camera.look_at then
        local cam = camera.get_position and camera.get_position()
        local aim = targeting.get_aim_point(locked_target, PREFIX, nil, cam)
        if aim then
            local smooth = math.max(1, settings.num(PREFIX .. "smooth", 5))
            camera.look_at(aim.x, aim.y, aim.z, smooth)
        end
    end
end

function M.draw()
    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5

    if settings.bool(PREFIX .. "draw_fov", true) and settings.bool(P, false) then
        local fov = settings.num(PREFIX .. "fov", 150)
        local col = settings.color(PREFIX .. "draw_fov", { 0.4, 0.9, 1, 1 })
        if settings.bool(PREFIX .. "fov_fill", false) and draw and draw.circle_filled then
            local fill = settings.color(PREFIX .. "fov_fill", { 0.4, 0.9, 1, 0.12 })
            draw.circle_filled(cx, cy, fov, fill, 64)
        end
        if draw and draw.circle then
            draw.circle(cx, cy, fov, col, 64, 1)
        else
            draw_util.circle(cx, cy, fov, col, false)
        end
    end

    if not settings.bool(P, false) or not locked_target or not locked_target.is_alive then return end

    if settings.bool(PREFIX .. "target_line", false) then
        local cam = camera and camera.get_position and camera.get_position()
        local aim = targeting.get_aim_point(locked_target, PREFIX, nil, cam)
        if aim then
            local tx, ty, vis = w2s(aim.x, aim.y, aim.z)
            if vis then
                local col = settings.color(PREFIX .. "target_line", { 1, 0.25, 0.25, 1 })
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

-- ── features/combat/silent_aim.lua ──
April._mods["features.combat.silent_aim"] = (function()
local settings = April.require("core.settings")
local targeting = April.require("features.combat.targeting")
local draw_util = April.require("core.draw_util")
local math_util = April.require("core.math_util")
local menu_util = April.require("core.menu_util")
local combat_menu = April.require("features.combat.combat_menu")

local M = {}
local PREFIX = "april_silent_"
local P = PREFIX .. "enabled"
local locked_target = nil
local redirect_point = nil

local function w2s(x, y, z)
    if draw and draw.world_to_screen then
        return draw.world_to_screen(x, y, z)
    end
    if utility and utility.world_to_screen then
        return utility.world_to_screen(x, y, z)
    end
    return 0, 0, false
end

local function is_firing()
    return input and input.is_key_down and input.is_key_down(0x01)
end

local function active()
    return settings.bool(P, false) and is_firing()
end

local function screen_center()
    local sw, sh = targeting.screen_center()
    return sw * 0.5, sh * 0.5
end

function M.get_redirect_point()
    if not active() or not redirect_point then return nil end
    return redirect_point
end

local function vec3_pos(v)
    if not v then return nil end
    if v.X ~= nil then return { x = v.X, y = v.Y, z = v.Z } end
    if v.x ~= nil then return { x = v.x, y = v.y, z = v.z } end
    return nil
end

local function hooks_ready()
    local shoot_hooks = April.require("game.shoot_hooks")
    return shoot_hooks.is_installed and shoot_hooks.is_installed()
end

local function apply_mouse_fallback()
    if not redirect_point or not is_firing() or hooks_ready() then return end

    local sx, sy, vis = w2s(redirect_point.x, redirect_point.y, redirect_point.z)
    if not vis then return end

    if utility and utility.mouse_move then
        utility.mouse_move(sx, sy, true)
    elseif input and input.move_mouse and utility and utility.get_mouse_pos then
        local mx, my = utility.get_mouse_pos()
        input.move_mouse(sx - mx, sy - my)
    end
end

function M.apply_projectile(opts)
    if not active() or not redirect_point or type(opts) ~= "table" then return end

    local origin = vec3_pos(opts.Position) or vec3_pos(opts.PositionFirst)
    if not origin then return end

    local tx, ty, tz = redirect_point.x, redirect_point.y, redirect_point.z

    if settings.bool(PREFIX .. "drop_prediction", true) then
        local stats = targeting.weapon_stats(PREFIX)
        local speed = math.max(stats.speed or 2000, 1)
        local grav = stats.gravity or 0.55
        local dx = tx - origin.x
        local dz = tz - origin.z
        local horiz = math.sqrt(dx * dx + dz * dz)
        local t = horiz / speed
        local drop = 0.5 * grav * t * t
        ty = ty + drop
    end

    local dx = tx - origin.x
    local dy = ty - origin.y
    local dz = tz - origin.z
    local len = math_util.distance3(dx, dy, dz)
    if len < 0.01 then return end

    if Vector3 then
        local dir = Vector3.new(dx / len, dy / len, dz / len)
        opts.Direction = dir
        opts.DirectionFirst = dir
    end
end

function M.register_menu()
    local T, G = menu_util.group("Silent Aim")
    menu.add_checkbox(T, G, P, "Enable Silent Aim", false, { key = 0 })
    menu.add_label(T, G, "Uses projectile hooks when available; otherwise moves mouse to target.")
    menu.add_label(T, G, "Active while LMB firing.")
    combat_menu.register_targeting(T, G, PREFIX, P, {
        fov_label = "Silent FOV (px)",
        fov_default = 120,
        fov_color = { 1, 0.45, 0.85, 1 },
        fill_color = { 1, 0.45, 0.85, 0.12 },
        line_color = { 1, 0.3, 0.85, 1 },
    })
end

function M.update(dt)
    redirect_point = nil

    if not settings.bool(P, false) then
        locked_target = nil
        return
    end

    if not is_firing() then
        if not settings.bool(PREFIX .. "sticky", true) then
            locked_target = nil
        end
        return
    end

    local cx, cy = screen_center()
    local fov = settings.num(PREFIX .. "fov", 120)

    if settings.bool(PREFIX .. "sticky", true) and locked_target and locked_target.is_alive then
        -- keep
    else
        locked_target = targeting.find_target(cx, cy, fov, PREFIX)
    end

    if locked_target then
        local cam = camera and camera.get_position and camera.get_position()
        redirect_point = targeting.get_aim_point(locked_target, PREFIX, nil, cam)
        apply_mouse_fallback()
    end
end

function M.draw()
    local cx, cy = screen_center()

    if settings.bool(PREFIX .. "draw_fov", true) and settings.bool(P, false) then
        local fov = settings.num(PREFIX .. "fov", 120)
        local col = settings.color(PREFIX .. "draw_fov", { 1, 0.45, 0.85, 1 })
        if settings.bool(PREFIX .. "fov_fill", false) and draw and draw.circle_filled then
            local fill = settings.color(PREFIX .. "fov_fill", { 1, 0.45, 0.85, 0.12 })
            draw.circle_filled(cx, cy, fov, fill, 64)
        end
        if draw and draw.circle then
            draw.circle(cx, cy, fov, col, 64, 1)
        else
            draw_util.circle(cx, cy, fov, col, false)
        end
    end

    if not settings.bool(P, false) or not locked_target or not locked_target.is_alive then return end

    if settings.bool(PREFIX .. "target_line", false) and redirect_point then
        local tx, ty, vis = w2s(redirect_point.x, redirect_point.y, redirect_point.z)
        if vis then
            local col = settings.color(PREFIX .. "target_line", { 1, 0.3, 0.85, 1 })
            draw_util.line(cx, cy, tx, ty, col, 1.5)
        end
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
local weapon_sliders_done = false

local MAX_PULL = 10.0
local acc_y = 0
local acc_x = 0

local function pct_to_pull(pct)
    return (math.max(0, math.min(100, pct or 0)) / 100) * MAX_PULL
end

local function should_compensate()
    if not input or not input.is_key_down then return false end
    local mode = settings.num("april_recoil_mode", 0)
    local firing = input.is_key_down(0x01)
    if mode == 1 then
        return firing and input.is_key_down(0x02)
    end
    return firing
end

local function reset_accumulators()
    acc_y = 0
    acc_x = 0
end

local function get_strength(weapon_name)
    if not weapon_name then return 0, 0 end

    local use_global = settings.bool("april_recoil_use_global", true)
    local pct_y, pct_x
    if use_global then
        pct_y = settings.num("april_recoil_global", 60)
        pct_x = settings.num("april_recoil_global_x", 0)
    else
        pct_y = settings.num(weapons.slug(weapon_name), 50)
        pct_x = settings.num(weapons.slug(weapon_name) .. "_x", 0)
    end

    return pct_to_pull(pct_y), pct_to_pull(pct_x)
end

function M.register_weapon_sliders()
    if weapon_sliders_done then return end
    local names = weapons.recoil_weapon_names()
    if #names == 0 then return end

    local T, G = menu_util.group("Recoil Control")
    menu.add_separator(T, G)
    menu.add_label(T, G, "Per-Weapon (disable global to use)")
    for _, name in ipairs(names) do
        local id = weapons.slug(name)
        menu.add_slider_int(T, G, id, name .. " Vert %", 0, 100, 60, { parent = P })
        menu.add_slider_int(T, G, id .. "_x", name .. " Horiz %", 0, 100, 0, { parent = P })
    end
    weapon_sliders_done = true
    April.require("core.debug").log("Recoil: " .. #names .. " weapon sliders registered")
end

function M.register_menu()
    local T, G = menu_util.group("Recoil Control")

    menu.add_checkbox(T, G, P, "Enable Recoil Control", false, { key = 0 })
    menu.add_combo(T, G, "april_recoil_mode", "Active While", { "Firing (LMB)", "ADS + Firing" }, 0, { parent = P })
    menu.add_slider_int(T, G, "april_recoil_global", "Global Vertical %", 0, 100, 60, { parent = P })
    menu.add_slider_int(T, G, "april_recoil_global_x", "Global Horizontal %", 0, 100, 0, { parent = P })
    menu.add_checkbox(T, G, "april_recoil_use_global", "Use Global For All Guns", true, { parent = P })
    menu.add_separator(T, G)
    menu.add_label(T, G, "Per-weapon sliders register after ToolInfo loads in-game.")
end

function M.update(dt)
    if not settings.bool(P, false) then
        reset_accumulators()
        return
    end

    if not should_compensate() then
        reset_accumulators()
        return
    end

    local held = weapons.get_held_weapon_name()
    if not held then
        reset_accumulators()
        return
    end

    local amount_y, amount_x = get_strength(held)
    if amount_y <= 0 and amount_x <= 0 then
        reset_accumulators()
        return
    end

    if not input or not input.move_mouse then return end

    acc_y = acc_y + amount_y
    local move_y = math.floor(acc_y)
    if move_y > 0 then
        acc_y = acc_y - move_y
    end

    local sign_x = amount_x >= 0 and 1 or -1
    acc_x = acc_x + math.abs(amount_x)
    local move_x = math.floor(acc_x) * sign_x
    if math.abs(move_x) > 0 then
        acc_x = acc_x - math.abs(move_x)
    end

    if move_x ~= 0 or move_y ~= 0 then
        input.move_mouse(move_x, move_y)
    end
end

function M.draw()
    if not settings.bool(P, false) then return end
    if not draw or not draw.text then return end

    local held = weapons.get_held_weapon_name()
    if not held then return end

    local y, x = get_strength(held)
    draw.text(10, 24, string.format("RC: %s  V:%.1f H:%.1f px/f", held, y, x), { 0.5, 1, 0.7, 0.9 }, 12)
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
    local T, G = menu_util.group("Player ESP")
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
        if p.is_valid and not p.is_local then
            table.insert(cache.players, p)
        end
    end
    cache.stats.last_player_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.get_players()
    if entity and entity.get_players then
        return entity.get_players()
    end
    return cache.players
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_esp_enabled", true) then return end
    local max_dist = settings.num("april_esp_max_dist", 1000)
    local col = settings.color("april_esp_color", { 0.3, 1, 0.5, 1 })
    local box_mode = settings.num("april_esp_box_mode", 1)
    local me = entity and entity.get_local_player and entity.get_local_player()
    local text_size = settings.num("april_esp_text_size", 13)

    for _, p in ipairs(M.get_players()) do
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
    local T, G = menu_util.group("Crosshair")
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
    local T, G = menu_util.group("Hitmarkers")
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
    local T, G = menu_util.group("World ESP")
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
    local T, G = menu_util.group("Loot ESP")
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
    local T, G = menu_util.group("Base ESP")
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
    local T, G = menu_util.group("NPC ESP")
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
    local T, G = menu_util.group("Movement")
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
    local T, G = menu_util.group("Radar")
    menu.add_label(T, G, "Waypoints")
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
    local T, G = menu_util.group("Radar")
    menu.add_separator(T, G)
    menu.add_label(T, G, "Tactical Map")
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
    local T, G = menu_util.group("Settings")
    menu.add_label(T, G, "April v3 — Fallen Survival")
    menu.add_button(T, G, "april_cfg_save_1", "Save Config Slot 1", function() M.save_slot(1) end)
    menu.add_button(T, G, "april_cfg_load_1", "Load Config Slot 1", function() M.load_slot(1) end)
    menu.add_separator(T, G)
    menu.add_checkbox(T, G, "april_debug_overlay", "Debug Overlay", false)
    menu.add_button(T, G, "april_debug_clear", "Clear Error Log", function()
        April.require("core.debug").reset_errors()
        print("[April] Error log cleared")
    end)
    menu.add_button(T, G, "april_reload_modules", "Reload Game Modules", function()
        local ok = April.require("game.bootstrap").force_reload()
        print("[April] Module reload: " .. (ok and "OK" or "waiting"))
    end)
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_debug_overlay", false) then return end
    if not draw or not draw.text then return end
    local cache = April.require("core.cache")
    local dbg = April.require("core.debug")
    local bootstrap = April.require("game.bootstrap")
    local shoot_hooks = April.require("game.shoot_hooks")
    local stats = dbg.stats()
    local y = 40
    draw.text(10, y, "April v3 " .. (April.version or "?"), { 0.4, 1, 0.6, 1 }, 14)
    y = y + 16
    draw.text(10, y, "Modules: " .. (bootstrap.is_ready() and "OK" or "waiting...") ..
        "  Hooks: " .. (shoot_hooks.is_installed() and "OK" or "no"), { 1, 1, 1, 0.9 }, 12)
    y = y + 14
    if bootstrap.get_status then
        draw.text(10, y, bootstrap.get_status(), { 0.85, 0.85, 0.85, 0.85 }, 11)
        y = y + 14
    end
    if not shoot_hooks.is_installed() then
        draw.text(10, y, "Silent aim: mouse fallback (no game hooks)", { 1, 0.85, 0.4, 0.9 }, 11)
        y = y + 14
    end
    draw.text(10, y, "Frames: " .. stats.frames, { 1, 1, 1, 0.9 }, 12)
    y = y + 14
    draw.text(10, y, "Players: " .. #cache.players, { 1, 1, 1, 0.9 }, 12)
    y = y + 14
    draw.text(10, y, "World: " .. #cache.world .. "  Loot: " .. #cache.loot, { 1, 1, 1, 0.9 }, 12)
end

return M

end)()

-- ── menu/tabs.lua ──
April._mods["menu.tabs"] = (function()
local menu_util = April.require("core.menu_util")
local debug = April.require("core.debug")
local scheduler = April.require("core.scheduler")
local bootstrap = April.require("game.bootstrap")

local M = {}

M.features = {}
M._bootstrapped = false

M.FEATURE_ORDER = {
    "features.combat.aimbot",
    "features.combat.silent_aim",
    "features.combat.recoil",
    "features.visuals.player_esp",
    "features.visuals.crosshair",
    "features.visuals.feedback",
    "features.world.world_esp",
    "features.world.loot_esp",
    "features.world.npc_esp",
    "features.world.base_esp",
    "features.radar.waypoints",
    "features.radar.tactical_map",
    "features.movement.exploits",
    "features.utility.config",
}

function M.register_all()
    menu_util.ensure_tab()
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
            debug.error_once("menu:" .. path, err)
        end
    end

    debug.log("Menu: " .. registered .. " sections (Scripts > April)")
end

function M.setup_scans()
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

    debug.guard("scan:initial_players", player_esp.scan)
end

function M.load_game_data()
    April.require("game.items").load()
end

function M.update(dt)
    if not M._bootstrapped then
        M._bootstrapped = true
        bootstrap.try_load_all()
        bootstrap.start_background_retry()
    end
    bootstrap.tick()
    scheduler.tick()
    for i, feat in ipairs(M.features) do
        if feat.update then
            debug.guard("update:" .. i, feat.update, dt)
        end
    end
end

function M.draw()
    for i, feat in ipairs(M.features) do
        if feat.draw then
            debug.guard("draw:" .. i, feat.draw)
        end
    end
end

function M.init()
    local env = April.require("core.env")
    local ok, missing = env.require_apis({ "menu", "draw", "utility", "entity", "game" })
    if not ok then
        debug.error_once("init:apis", "Missing required API: " .. tostring(missing))
        return false
    end

    debug.audit_apis()
    M.register_all()
    M.load_game_data()
    M.setup_scans()

    debug.log("Init complete — v" .. April.version)
    return true
end

return M

end)()

-- ── app.lua ──
April._mods["app"] = (function()
local tabs = April.require("menu.tabs")
local debug = April.require("core.debug")

local M = {}
local initialized = false

function M.init()
    if initialized then return true end
    initialized = tabs.init()
    return initialized
end

function M.on_frame()
    if not initialized then return end
    debug.tick_frame()

    local dt = 0.016
    if utility and utility.get_delta_time then
        dt = utility.get_delta_time()
    end

    debug.guard("tabs.update", tabs.update, dt)
    debug.guard("tabs.draw", tabs.draw)
end

return M

end)()

April._init_ok = false

local ok, err = pcall(function()
    local debug = April.require("core.debug")
    local app = April.require("app")

    if not app.init() then
        debug.error_once("init", "app.init() returned false — features disabled")
        return
    end

    April._init_ok = true

    if not debug.register_frame_hook(function()
        app.on_frame()
    end) then
        debug.error_once("init", "Failed to register on_frame")
    end
end)

if not ok then
    print("[April] Fatal: " .. tostring(err))
    if debug and debug.traceback then print(debug.traceback(err)) end
elseif April._init_ok then
    print("[April v3] Ready — " .. April.version .. " (debug on, watch console for errors)")
else
    print("[April v3] Init failed — check console above")
end
