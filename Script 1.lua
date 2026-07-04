--[[
    April — Fallen Survival for Project Vector
    https://github.com/Cunzaki/April
    Built: 2026-07-04T03:41:05.545Z
]]

April = {
    version = "3.6.0",
    debug = false,
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

-- ── core/capabilities.lua ──
April._mods["core.capabilities"] = (function()
--[[ Lightweight capability flags (no runtime probes — those block on getgc/refreshgc). ]]

local M = {}

function M.probe()
    return {
        menu = _G.menu ~= nil,
        draw = _G.draw ~= nil,
        entity = _G.entity ~= nil,
        game = _G.game ~= nil,
        camera = _G.camera ~= nil,
        input = _G.input ~= nil,
        utility = _G.utility ~= nil,
        thread = _G.thread ~= nil,
        raycast = _G.raycast ~= nil,
        fflag = _G.fflag ~= nil,
        memory = _G.memory ~= nil,
        fallen_gc = type(refreshgc) == "function"
            and type(applygc) == "function"
            and type(getgc) == "function",
        getgc = type(getgc) == "function",
    }
end

function M.summary(c)
    c = c or M.probe()
    local parts = {}
    if c.menu then table.insert(parts, "menu") end
    if c.draw then table.insert(parts, "draw") end
    if c.fallen_gc then table.insert(parts, "gc-mods") end
    if c.getgc then table.insert(parts, "getgc") end
    return #parts > 0 and table.concat(parts, ", ") or "minimal"
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
    if not M.enabled() then return end
    print("[April] " .. tostring(msg))
end

function M.warn(msg)
    if not M.enabled() then return end
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

function M.register_frame_hook(fn)
    if type(fn) ~= "function" then
        M.error_once("frame_hook", "on_frame handler is not a function")
        return false
    end

    -- Vector engine invokes global on_frame() every frame (primary hook).
    _G.on_frame = fn

    if callbacks and callbacks.add then
        callbacks.add("on_frame", fn)
    end

    if draw then
        draw.callback = fn
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
    if now - last_heartbeat > 30000 then
        last_heartbeat = now
        local players = entity and entity.get_players and #entity.get_players() or 0
        local bootstrap = April.require("game.bootstrap")
        M.log(string.format("Heartbeat — frames=%d players=%d modules=%s %s",
            frame_count, players,
            bootstrap.is_ready() and "OK" or "wait",
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

function M.text(x, y, text, col, size)
    M.text_outlined(x, y, text, col, size)
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

-- ── core/esp_util.lua ──
April._mods["core.esp_util"] = (function()
local draw_util = April.require("core.draw_util")
local settings = April.require("core.settings")

local M = {}

M.AIM_BONES = {
    "Closest",
    "Head",
    "UpperTorso",
    "LowerTorso",
    "HumanoidRootPart",
    "LeftUpperArm",
    "RightUpperArm",
    "LeftLowerArm",
    "RightLowerArm",
    "LeftHand",
    "RightHand",
    "LeftUpperLeg",
    "RightUpperLeg",
    "LeftLowerLeg",
    "RightLowerLeg",
    "LeftFoot",
    "RightFoot",
}

M.SKELETON_PAIRS = {
    { "Head", "UpperTorso" },
    { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" },
    { "UpperTorso", "RightUpperArm" },
    { "LeftUpperArm", "LeftLowerArm" },
    { "RightUpperArm", "RightLowerArm" },
    { "LeftLowerArm", "LeftHand" },
    { "RightLowerArm", "RightHand" },
    { "LowerTorso", "LeftUpperLeg" },
    { "LowerTorso", "RightUpperLeg" },
    { "LeftUpperLeg", "LeftLowerLeg" },
    { "RightUpperLeg", "RightLowerLeg" },
    { "LeftLowerLeg", "LeftFoot" },
    { "RightLowerLeg", "RightFoot" },
}

function M.text_size()
    return settings.num("april_esp_text_size", 13)
end

function M.w2s(x, y, z)
    if draw and draw.world_to_screen then
        return draw.world_to_screen(x, y, z)
    end
    if utility and utility.world_to_screen then
        return utility.world_to_screen(x, y, z)
    end
    return 0, 0, false
end

function M.draw_skeleton_bones(bones, col, thick)
    if not bones then return end
    thick = thick or 1.5

    local function pt(entry)
        if not entry then return end
        if entry.x and entry.y then return entry.x, entry.y end
        if entry[1] and entry[2] then return entry[1], entry[2] end
    end

    for i = 1, #M.SKELETON_PAIRS do
        local pair = M.SKELETON_PAIRS[i]
        local ax, ay = pt(bones[pair[1]])
        local bx, by = pt(bones[pair[2]])
        if ax and bx then
            draw_util.line(ax, ay, bx, by, col, thick)
        end
    end
end

function M.draw_player_skeleton(player, col, thick)
    if not player or not player.get_bones_screen then return end
    local bones = player:get_bones_screen()
    if not bones then return end
    M.draw_skeleton_bones(bones, col, thick)
end

function M.draw_model_skeleton(model, col, thick)
    if not model then return end
    local env = April.require("core.env")
    if not env.is_valid(model) then return end

    local screen = {}
    local function part_pos(name)
        local part = env.safe_call(function()
            return model:find_first_child(name) or model:FindFirstChild(name)
        end)
        if not part or not env.is_valid(part) then return end
        local pos = part.Position or part.position
        if not pos or pos.x == nil then return end
        local sx, sy, vis = M.w2s(pos.x, pos.y, pos.z)
        if vis then screen[name] = { x = sx, y = sy } end
    end

    for _, pair in ipairs(M.SKELETON_PAIRS) do
        part_pos(pair[1])
        part_pos(pair[2])
    end
    M.draw_skeleton_bones(screen, col, thick)
end

function M.draw_beacon(sx, sy, col, opts)
    opts = opts or {}
    local sw, sh = draw_util.screen_size()
    local origin_x = opts.origin_x or sw * 0.5
    local origin_y = opts.origin_y or sh
    local steps = opts.steps or 5

    for i = 1, steps do
        local t = i / steps
        local alpha = (col[4] or 1) * (0.08 + t * 0.22)
        local c = { col[1], col[2], col[3], alpha }
        local ox = origin_x + (sx - origin_x) * t
        local oy = origin_y + (sy - origin_y) * t
        draw_util.line(ox, oy, sx, sy, c, 1 + t)
    end

    if draw and draw.circle_filled then
        draw.circle_filled(sx, sy, opts.marker_r or 5, col, 16)
        draw.circle(sx, sy, opts.marker_r or 5 + 2, { col[1], col[2], col[3], 0.35 }, 16, 1)
    else
        draw_util.circle(sx, sy, opts.marker_r or 5, col, true)
    end
end

function M.draw_offscreen_arrow(cx, cy, tx, ty, col, size)
    size = size or 14
    local dx, dy = tx - cx, ty - cy
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1 then return end
    dx, dy = dx / len, dy / len
    local px, py = cx + dx * (size + 8), cy + dy * (size + 8)
    local lx, ly = -dy, dx
    if draw and draw.poly_filled then
        draw.poly_filled({
            { px + dx * size, py + dy * size },
            { px - dx * 4 + lx * size * 0.5, py - dy * 4 + ly * size * 0.5 },
            { px - dx * 4 - lx * size * 0.5, py - dy * 4 - ly * size * 0.5 },
        }, col)
    else
        draw_util.line(px, py, px - dx * 8 + lx * 6, py - dy * 8 + ly * 6, col, 2)
        draw_util.line(px, py, px - dx * 8 - lx * 6, py - dy * 8 - ly * 6, col, 2)
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
--[[
    Vector "full" mode grid (Lone script pattern):
      menu.add_group(tab, name)           → left column, new row
      menu.add_group(tab, name, 0, true)  → right column, same row as previous left
]]

local M = {}

M.TAB = "April"

M.G = {
    AIMBOT = "Aimbot",
    VISUALS = "Visuals",
    WORLD = "World",
    RADAR = "Radar",
    MISC = "Misc",
    CONFIG = "Config",
}

-- Which side each group renders on (must register left before its right pair).
M.G_SIDE = {
    [M.G.AIMBOT] = "left",
    [M.G.VISUALS] = "right",
    [M.G.WORLD] = "left",
    [M.G.RADAR] = "right",
    [M.G.MISC] = "left",
    [M.G.CONFIG] = "right",
}

M._tab_ready = false
M._groups = {}

function M.ensure_tab()
    if M._tab_ready then return end
    if not (April and April._menu_tab_ready) and menu and menu.add_tab then
        menu.add_tab(M.TAB, "A", "full")
    end
    M._tab_ready = true
end

function M.group(name, side)
    M.ensure_tab()
    if M._groups[name] then
        return M.TAB, name
    end

    side = side or M.G_SIDE[name] or "left"

    if menu and menu.add_group then
        if side == "right" then
            menu.add_group(M.TAB, name, 0, true)
        else
            menu.add_group(M.TAB, name)
        end
        M._groups[name] = true
    end

    return M.TAB, name
end

function M.section(T, G, title)
    menu.add_separator(T, G)
    menu.add_label(T, G, title)
end

function M.parent(main_id, extra)
    local opts = { parent = main_id }
    if type(extra) == "table" then
        for k, v in pairs(extra) do
            opts[k] = v
        end
    end
    return opts
end

return M

end)()

-- ── game/module_scan.lua ──
April._mods["game.module_scan"] = (function()
--[[
    Locate Fallen modules already loaded by the game client.
    Plain loops only — no coroutines (Vector forbids yield during menu/C calls).

    IMPORTANT: When refreshgc/applygc exist, never call getgc(true) — it breaks
    the Fallen weapon-mod node cache (getgc({ keys }) returns 0 afterward).
]]

local M = {}

M._table_cache = nil
M._cache_at = 0
M._cache_ttl = 8000

function M.has_gc()
    return type(getgc) == "function"
end

function M.uses_fallen_weapon_gc()
    return type(refreshgc) == "function" and type(applygc) == "function"
end

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
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

function M.invalidate_cache()
    M._table_cache = nil
    M._cache_at = 0
end

function M.collect_tables(force)
    local now = tick_ms()
    if not force and M._table_cache and now - M._cache_at < M._cache_ttl then
        return M._table_cache
    end

    local list = {}
    local seen = {}

    local function add(v)
        if type(v) == "table" and not seen[v] then
            seen[v] = true
            table.insert(list, v)
        end
    end

    if type(filtergc) == "function" then
        local ok = pcall(function()
            filtergc("table", true, function(v)
                add(v)
                return false
            end)
        end)
        if ok and #list > 0 then
            M._table_cache = list
            M._cache_at = now
            return list
        end
        list = {}
        seen = {}
    end

    -- Never getgc(true) when Fallen weapon GC API is present — poisons getgc(keys).
    if M.has_gc() and not M.uses_fallen_weapon_gc() then
        local ok, all = pcall(getgc, true)
        if ok and type(all) == "table" then
            for _, v in ipairs(all) do add(v) end
        end
    end

    if package and type(package.loaded) == "table" then
        add_tables(package.loaded, list, seen)
    end
    if type(shared) == "table" then
        add_tables(shared, list, seen)
    end

    M._table_cache = list
    M._cache_at = now
    return list
end

function M.each_table(fn, force)
    local list = M.collect_tables(force)
    for i = 1, #list do
        fn(list[i])
    end
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
        if n > best_n and n >= 3 then
            best_n = n
            best = v
        end
    end)
    return best, best_n
end

return M

end)()

-- ── game/bootstrap.lua ──
April._mods["game.bootstrap"] = (function()
--[[
    Lightweight ToolInfo loader for weapon stats / aimbot prediction.
    Uses GC scan only — no instance require (Fallen hides Modules from scripts).
]]

local env = April.require("core.env")
local debug = April.require("core.debug")
local module_scan = April.require("game.module_scan")

local M = {}

M._toolinfo = nil
M._ready = false
M._attempts = 0
M._last_try = 0
M._try_interval = 5000
M._logged_ready = false
M._scan_after = 0
M._defer_ms = 2500

local function in_game_ready()
    if env.get_local_player() then return true end
    if entity and entity.get_players and #entity.get_players() > 0 then return true end
    return false
end

local function try_load_toolinfo()
    local data, n = module_scan.find_toolinfo()
    if data then
        M._toolinfo = data
        M._ready = true
        return true, n or 0
    end
    return false, 0
end

function M.get_module(name)
    if name == "ToolInfo" then
        return M._toolinfo
    end
    return nil
end

function M.is_ready()
    return M._ready
end

local function on_toolinfo_ready(count)
    if M._logged_ready then return end
    M._logged_ready = true
    if April and April.debug then
        debug.log(string.format("ToolInfo ready (%d weapons)", count or 0))
    end

    local weapons = April.require("game.weapons")
    if weapons.on_modules_ready then
        weapons.on_modules_ready()
    else
        weapons.load()
    end
end

function M.try_load_all()
    if M._ready then return true end

    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0

    if not in_game_ready() then
        M._scan_after = 0
        return false
    end

    if M._scan_after == 0 then
        M._scan_after = now + M._defer_ms
    end
    if now < M._scan_after then
        return false
    end

    if M._attempts > 0 and now - M._last_try < M._try_interval then
        return false
    end
    M._last_try = now
    M._attempts = M._attempts + 1

    local ok, count = try_load_toolinfo()
    if ok then
        on_toolinfo_ready(count)
    end

    return M._ready
end

function M.get_status()
    if M._ready then
        return "ToolInfo+scan"
    end
    return "ToolInfo-wait"
end

function M.force_reload()
    M._toolinfo = nil
    M._ready = false
    M._last_try = 0
    M._attempts = 0
    M._logged_ready = false
    M._scan_after = 0
    module_scan.invalidate_cache()
    April.require("game.weapons").invalidate()
    return M.try_load_all()
end

function M.tick()
    if not M._ready then
        M.try_load_all()
    end
end

function M.start_background_retry()
    -- no-op: frame tick is enough; avoids slow startup thread spam
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
local bootstrap = April.require("game.bootstrap")
local env = April.require("core.env")

local M = {}
local loaded = false
local toolinfo = {}
local recoil_weapons = {}
local weapon_names = {}

local ROBLOX_GRAV = 196.2

-- Legacy effective drop constants (used when ToolInfo gravity is a multiplier < 5).
local FALLBACK_STATS = {
    ["Military Barret"] = { speed = 1500, gravity = 25 },
    ["Military Barrett"] = { speed = 1500, gravity = 25 },
    ["Military M4A1"] = { speed = 950, gravity = 18 },
    ["Military M39"] = { speed = 900, gravity = 18 },
    ["Military MP7"] = { speed = 750, gravity = 15 },
    ["Military PKM"] = { speed = 850, gravity = 18 },
    ["Military USP"] = { speed = 650, gravity = 12 },
    ["Bruno's M4A1"] = { speed = 1000, gravity = 18 },
    ["Salvaged AK47"] = { speed = 800, gravity = 15 },
    ["Salvaged AK74u"] = { speed = 750, gravity = 15 },
    ["Salvaged AK4"] = { speed = 800, gravity = 15 },
    ["Salvaged Sniper"] = { speed = 1100, gravity = 20 },
    ["Salvaged M14"] = { speed = 850, gravity = 18 },
    ["Salvaged SMG"] = { speed = 700, gravity = 12 },
    ["Salvaged Skorpion"] = { speed = 650, gravity = 12 },
    ["Salvaged Python"] = { speed = 750, gravity = 15 },
    ["Salvaged P250"] = { speed = 650, gravity = 12 },
    ["Salvaged Pipe Rifle"] = { speed = 800, gravity = 20 },
    ["Salvaged Pump Action"] = { speed = 550, gravity = 15 },
    ["Salvaged Shotgun"] = { speed = 550, gravity = 15 },
    ["Salvaged Double Barrel"] = { speed = 550, gravity = 15 },
    ["Crossbow"] = { speed = 420, gravity = 35 },
    ["Wooden Bow"] = { speed = 280, gravity = 30 },
    ["Nail Gun"] = { speed = 350, gravity = 20 },
    ["Wooden Spear"] = { speed = 200, gravity = 45 },
    ["Stone Spear"] = { speed = 200, gravity = 45 },
    ["Pumpkin Launcher"] = { speed = 300, gravity = 50 },
    ["Salvaged RPG"] = { speed = 400, gravity = 60 },
    ["Military Grenade Launcher"] = { speed = 350, gravity = 55 },
    ["Salvaged Grenade Launcher"] = { speed = 350, gravity = 55 },
    ["Military AA12"] = { speed = 550, gravity = 15 },
    ["Salvaged Break Action"] = { speed = 550, gravity = 15 },
}

M._last_held = nil
M._was_in_game = false
M._weapon_changed_at = 0

local function inst_name(inst)
    if not inst then return nil end
    return inst.name or inst.Name
end

local function is_tool(inst)
    if not inst then return false end
    local cn = inst.ClassName or inst.class_name
    return cn == "Tool"
end

local function rebuild_weapon_names()
    weapon_names = {}
    for name in pairs(FALLBACK_STATS) do
        weapon_names[name] = true
    end
    for name in pairs(toolinfo) do
        if type(name) == "string" then
            weapon_names[name] = true
        end
    end
end

function M.slug(name)
    return "april_rc_" .. (name or ""):gsub("[^%w]", "_")
end

function M.is_weapon_name(name)
    return name and weapon_names[name] == true
end

function M.invalidate()
    loaded = false
    toolinfo = {}
    recoil_weapons = {}
    weapon_names = {}
    M._last_held = nil
    M._weapon_changed_at = 0
end

function M.in_game_ready()
    if env.get_local_player() then return true end
    if entity and entity.get_players and #entity.get_players() > 0 then return true end
    return false
end

function M.load()
    if loaded then return true end

    local data = bootstrap.get_module("ToolInfo")
    if type(data) ~= "table" then
        rebuild_weapon_names()
        return false
    end

    toolinfo = data
    recoil_weapons = {}
    for name, entry in pairs(data) do
        if type(entry) == "table" and (entry.Bullet or entry.Recoil or entry.Weapon) then
            table.insert(recoil_weapons, name)
        end
    end
    table.sort(recoil_weapons)
    rebuild_weapon_names()
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

local function read_tool_attributes(inst)
    if not inst then return nil end
    local speed, gravity
    pcall(function()
        if inst.GetAttribute then
            speed = inst:GetAttribute("BulletSpeed") or inst:GetAttribute("MuzzleVelocity")
            gravity = inst:GetAttribute("BulletGravity") or inst:GetAttribute("ProjectileGravity")
        elseif inst.get_attribute then
            speed = inst:get_attribute("BulletSpeed") or inst:get_attribute("MuzzleVelocity")
            gravity = inst:get_attribute("BulletGravity") or inst:get_attribute("ProjectileGravity")
        end
    end)
    if speed then
        return {
            speed = speed,
            gravity = gravity or 35,
            name = inst_name(inst),
            from_attributes = true,
        }
    end
    return nil
end

local function find_held_in_character(lp)
    local char = lp and lp.character
    if not char or not env.is_valid(char) then return nil, nil end

    local fallback_tool = nil
    for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
        local n = inst_name(child)
        if n and M.is_weapon_name(n) then
            return n, child
        end
        if is_tool(child) and n then
            fallback_tool = fallback_tool or { name = n, inst = child }
        end
    end

    if fallback_tool then
        return fallback_tool.name, fallback_tool.inst
    end
    return nil, nil
end

local function find_held_in_viewmodels()
    local ws = env.get_workspace()
    if not ws then return nil end

    local vms = env.safe_call(function() return ws:find_first_child("Viewmodels") end)
        or env.safe_call(function() return ws:FindFirstChild("Viewmodels") end)
    if not vms then return nil end

    for _, vm in ipairs(env.safe_call(function() return vms:get_children() end) or {}) do
        if inst_name(vm) == "Viewmodel" then
            for _, item in ipairs(env.safe_call(function() return vm:get_children() end) or {}) do
                local n = inst_name(item)
                if n and M.is_weapon_name(n) then
                    return n, item
                end
                local cn = item and (item.ClassName or item.class_name)
                if cn == "Model" and n and M.is_weapon_name(n) then
                    return n, item
                end
            end
        end
    end
    return nil, nil
end

function M.get_held_weapon_name()
    rebuild_weapon_names()

    local lp = env.get_local_player()
    if not lp then return nil end

    local name, inst = find_held_in_character(lp)
    if name then return name end

    name = find_held_in_viewmodels()
    if name then return name end

    if lp.tool_name and lp.tool_name ~= "" then
        if M.is_weapon_name(lp.tool_name) or loaded then
            return lp.tool_name
        end
    end

    return nil
end

function M.get_held_tool()
    local lp = env.get_local_player()
    if not lp then return nil, nil end
    local name, inst = find_held_in_character(lp)
    if name then return name, inst end
    name = find_held_in_viewmodels()
    return name, nil
end

function M.drop_gravity(grav)
    if not grav or grav <= 0 then return 35 end
    if grav < 5 then return grav * ROBLOX_GRAV end
    return grav
end

function M.get_weapon_stats(name)
    name = name or M.get_held_weapon_name()
    if not name then return nil end

    local _, tool_inst = M.get_held_tool()
    if tool_inst then
        local from_attrs = read_tool_attributes(tool_inst)
        if from_attrs then
            from_attrs.name = name
            return from_attrs
        end
    end

    local entry = M.get(name)
    if entry and entry.Bullet then
        return {
            speed = entry.Bullet.Speed or 950,
            gravity = entry.Bullet.Gravity or 0.55,
            name = name,
            from_toolinfo = true,
            is_bow = entry.Weapon and entry.Weapon.IsBow or false,
        }
    end

    local fb = FALLBACK_STATS[name]
    if fb then
        return {
            speed = fb.speed,
            gravity = fb.gravity,
            name = name,
            from_fallback = true,
            is_bow = name == "Wooden Bow" or name == "Crossbow",
        }
    end

    return { speed = 950, gravity = 35, name = name }
end

function M.tick()
    local in_game = M.in_game_ready()

    if not in_game then
        if M._was_in_game then
            M._last_held = nil
            M._weapon_changed_at = 0
        end
        M._was_in_game = false
        return nil
    end

    if not M._was_in_game then
        M._was_in_game = true
        M.load()
    end

    if not loaded and bootstrap.is_ready and bootstrap.is_ready() then
        M.load()
    end

    local held = M.get_held_weapon_name()
    if held and held ~= M._last_held then
        M._last_held = held
        M._weapon_changed_at = utility and utility.get_tick_count and utility.get_tick_count() or 0
        pcall(function()
            local gun_mods = April.require("features.combat.gun_mods")
            if gun_mods.on_weapon_changed then
                gun_mods.on_weapon_changed(held)
            end
        end)
    elseif not held then
        M._last_held = nil
    end

    return held
end

function M.on_modules_ready()
    M.load()
    pcall(function()
        local gun_mods = April.require("features.combat.gun_mods")
        if gun_mods.on_modules_ready then
            gun_mods.on_modules_ready()
        end
    end)
end

return M

end)()

-- ── game/gc_weapon_mods.lua ──
April._mods["game.gc_weapon_mods"] = (function()
--[[
    Fallen Survival weapon mods — Vector globals (undocumented in GitBook):

        refreshgc()
        local n = getgc({ "RecoilMult", ... })
        applygc({ RecoilMult = -1, ... })
]]

local april_debug = April.require("core.debug")

local M = {}

M.GC_KEYS = {
    "RecoilMult",
    "RangeMult",
    "SpeedMult",
    "AimSpreadMult",
    "HipSpreadMult",
    "SwayMult",
    "FireRateMult",
}

M._last_node_count = 0
M._probed = false

local function has_api()
    return type(refreshgc) == "function"
        and type(getgc) == "function"
        and type(applygc) == "function"
end

function M.available()
    return has_api()
end

function M.last_node_count()
    return M._last_node_count
end

--[[ One-time startup probe: refreshgc + getgc(keys) only — no applygc. ]]
function M.probe_on_load()
    if M._probed then return M._last_node_count end
    M._probed = true

    if not has_api() then
        return 0
    end

    local count = 0
    pcall(function()
        refreshgc()
    end)
    pcall(function()
        local n = getgc(M.GC_KEYS)
        if type(n) == "number" then
            count = n
        end
    end)

    M._last_node_count = count
    return count
end

function M.apply_once(mods)
    if not has_api() then
        return false, 0, "GC API unavailable (refreshgc/getgc/applygc)"
    end
    if type(mods) ~= "table" or not next(mods) then
        return false, 0, "No modifiers selected"
    end

    local count = 0
    pcall(function()
        refreshgc()
    end)
    pcall(function()
        local n = getgc(M.GC_KEYS)
        if type(n) == "number" then
            count = n
        end
    end)

    M._last_node_count = count
    if count <= 0 then
        return false, 0, "No tables found — enter a match with a gun equipped"
    end

    local ok, err = pcall(applygc, mods)
    if not ok then
        april_debug.error_once("gun_mods:applygc", err)
        return false, count, "applygc failed: " .. tostring(err)
    end

    return true, count, string.format("%d node(s) cached — mods active", count)
end

function M.status_text()
    if not has_api() then return "GC: unavailable" end
    return string.format("GC nodes: %d", M._last_node_count)
end

return M

end)()

-- ── game/gun_mod_profiles.lua ──
April._mods["game.gun_mod_profiles"] = (function()
--[[
    Per-weapon gun mod profiles (Global + each projectile weapon).
    Editor widgets sync to the active profile; auto-apply reads profiles by weapon name.
]]

local weapons = April.require("game.weapons")

local M = {}

M.GLOBAL = "Global"

-- Every Fallen projectile weapon (guns, bows, crossbows, launchers, spears, nail gun).
M.PROJECTILE_WEAPONS = {
    "Bruno's M4A1",
    "Crossbow",
    "Military AA12",
    "Military Barret",
    "Military Barrett",
    "Military Grenade Launcher",
    "Military M39",
    "Military M4A1",
    "Military MP7",
    "Military PKM",
    "Military USP",
    "Nail Gun",
    "Pumpkin Launcher",
    "Salvaged AK4",
    "Salvaged AK47",
    "Salvaged AK74u",
    "Salvaged Break Action",
    "Salvaged Double Barrel",
    "Salvaged Grenade Launcher",
    "Salvaged M14",
    "Salvaged P250",
    "Salvaged Pipe Rifle",
    "Salvaged Pump Action",
    "Salvaged Python",
    "Salvaged RPG",
    "Salvaged Shotgun",
    "Salvaged Skorpion",
    "Salvaged SMG",
    "Salvaged Sniper",
    "Stone Spear",
    "Wooden Bow",
    "Wooden Spear",
}

M.FIELDS = {
    { key = "recoil", menu = "april_gm_recoil", kind = "bool", default = false },
    { key = "recoil_pct", menu = "april_gm_recoil_pct", kind = "num", default = 100 },
    { key = "spread", menu = "april_gm_spread", kind = "bool", default = false },
    { key = "spread_pct", menu = "april_gm_spread_pct", kind = "num", default = 100 },
    { key = "sway", menu = "april_gm_sway", kind = "bool", default = false },
    { key = "fire_rate", menu = "april_gm_fire_rate", kind = "bool", default = false },
    { key = "fire_rate_mult", menu = "april_gm_fire_rate_mult", kind = "num", default = 1.5 },
    { key = "speed", menu = "april_gm_speed", kind = "bool", default = false },
    { key = "speed_mult", menu = "april_gm_speed_mult", kind = "num", default = 100 },
    { key = "range", menu = "april_gm_range", kind = "bool", default = false },
    { key = "range_mult", menu = "april_gm_range_mult", kind = "num", default = 10 },
}

M._profiles = {}
M._combo_items = nil
M._name_by_index = nil

local function pct_to_neg_mult(pct)
    pct = math.max(0, math.min(100, pct or 0))
    if pct >= 100 then return -1 end
    return -(pct / 100)
end

function M.default_profile()
    local p = {}
    for _, f in ipairs(M.FIELDS) do
        p[f.key] = f.default
    end
    return p
end

function M.weapon_slug(name)
    if not name or name == M.GLOBAL then return "Global" end
    return name:gsub("[^%w]", "_")
end

function M.ensure_profile(name)
    name = name or M.GLOBAL
    if not M._profiles[name] then
        M._profiles[name] = M.default_profile()
    end
    return M._profiles[name]
end

function M.get_profile(name)
    return M.ensure_profile(name)
end

function M.set_profile(name, data)
    M._profiles[name] = data or M.default_profile()
end

function M.merge_toolinfo_weapons()
    weapons.load()
    local names = weapons.recoil_weapon_names()
    local seen = {}
    for _, n in ipairs(M.PROJECTILE_WEAPONS) do
        seen[n] = true
    end
    for _, n in ipairs(names) do
        if not seen[n] then
            seen[n] = true
            table.insert(M.PROJECTILE_WEAPONS, n)
        end
    end
    table.sort(M.PROJECTILE_WEAPONS)
end

function M.combo_items()
    if M._combo_items then return M._combo_items, M._name_by_index end

    M.merge_toolinfo_weapons()

    local items = { M.GLOBAL }
    local name_by_index = { [0] = M.GLOBAL }

    for i, name in ipairs(M.PROJECTILE_WEAPONS) do
        table.insert(items, name)
        name_by_index[i] = name
    end

    M._combo_items = items
    M._name_by_index = name_by_index
    return items, name_by_index
end

function M.name_at_index(idx)
    local _, map = M.combo_items()
    return map[idx or 0] or M.GLOBAL
end

function M.index_for_name(name)
    local items = M.combo_items()
    for i, n in ipairs(items) do
        if n == name then return i - 1 end
    end
    return 0
end

function M.read_editor()
    local p = {}
    for _, f in ipairs(M.FIELDS) do
        if menu and menu.get then
            local v = menu.get(f.menu)
            if v ~= nil then
                p[f.key] = v
            else
                p[f.key] = f.default
            end
        else
            p[f.key] = f.default
        end
    end
    return p
end

function M.write_editor(profile)
    profile = profile or M.default_profile()
    if not menu or not menu.set then return end
    for _, f in ipairs(M.FIELDS) do
        local v = profile[f.key]
        if v == nil then v = f.default end
        menu.set(f.menu, v)
    end
end

function M.sync_editor_to_profile(name)
    M._profiles[name or M.GLOBAL] = M.read_editor()
end

function M.sync_profile_to_editor(name)
    M.write_editor(M.ensure_profile(name))
end

function M.build_mods(profile)
    profile = profile or M.default_profile()
    local mods = {}

    if profile.recoil then
        mods.RecoilMult = pct_to_neg_mult(profile.recoil_pct)
    end
    if profile.spread then
        local m = pct_to_neg_mult(profile.spread_pct)
        mods.AimSpreadMult = m
        mods.HipSpreadMult = m
    end
    if profile.sway then
        mods.SwayMult = -1
    end
    if profile.fire_rate then
        mods.FireRateMult = profile.fire_rate_mult or 1.5
    end
    if profile.speed then
        mods.SpeedMult = profile.speed_mult or 100
    end
    if profile.range then
        mods.RangeMult = profile.range_mult or 10
    end

    return mods
end

function M.mods_for_weapon(held_name, per_weapon)
    local profile_name = M.GLOBAL
    if per_weapon and held_name and held_name ~= "" then
        profile_name = held_name
    end

    local profile = M.ensure_profile(profile_name)
    local mods = M.build_mods(profile)

    if per_weapon and held_name and not next(mods) then
        mods = M.build_mods(M.ensure_profile(M.GLOBAL))
    end

    return mods, profile_name
end

function M.config_prefix()
    return "april_gm_p_"
end

function M.config_key(profile_name, field_key)
    return M.config_prefix() .. M.weapon_slug(profile_name) .. "_" .. field_key
end

local function all_profile_names()
    local names = { M.GLOBAL }
    for _, w in ipairs(M.PROJECTILE_WEAPONS) do
        table.insert(names, w)
    end
    return names
end

function M.import_config_value(id, val)
    local prefix = M.config_prefix()
    if id:sub(1, #prefix) ~= prefix then return false end

    local rest = id:sub(#prefix + 1)
    local field_key = rest:match("_(recoil_pct|recoil|spread_pct|spread|sway|fire_rate_mult|fire_rate|speed_mult|speed|range_mult|range)$")
    if not field_key then return false end

    local slug = rest:sub(1, #rest - #field_key - 1)
    local profile_name = M.GLOBAL
    if slug ~= "Global" then
        for _, w in ipairs(M.PROJECTILE_WEAPONS) do
            if M.weapon_slug(w) == slug then
                profile_name = w
                break
            end
        end
        if profile_name == M.GLOBAL and slug ~= "Global" then
            profile_name = slug:gsub("_", " ")
        end
    end

    local profile = M.ensure_profile(profile_name)
    if val == "true" then profile[field_key] = true
    elseif val == "false" then profile[field_key] = false
    else
        local n = tonumber(val)
        profile[field_key] = n or val
    end
    return true
end

function M.export_config_values()
    local lines = {}
    M.merge_toolinfo_weapons()
    for _, weapon in ipairs(all_profile_names()) do
        local profile = M.ensure_profile(weapon)
        for _, f in ipairs(M.FIELDS) do
            local v = profile[f.key]
            if v ~= nil then
                table.insert(lines, { M.config_key(weapon, f.key), tostring(v) })
            end
        end
    end
    return lines
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
local esp_util = April.require("core.esp_util")

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
    if not target or not target.is_alive then return false, nil end

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
        if p.is_local or not p.is_alive then goto continue end

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

end)()

-- ── features/combat/combat_menu.lua ──
April._mods["features.combat.combat_menu"] = (function()
--[[ Aimbot menu — prediction/weapon stats always on (no toggles). ]]

local menu_util = April.require("core.menu_util")
local esp_util = April.require("core.esp_util")

local M = {}

function M.register_targeting(T, G, prefix, parent_id, opts)
    opts = opts or {}
    local p = prefix
    local root = menu_util.parent(parent_id)

    menu.add_slider_int(T, G, p .. "fov", opts.fov_label or "FOV Radius (px)", 20, 600, opts.fov_default or 150, root)
    menu.add_combo(T, G, p .. "bone", "Target Bone", esp_util.AIM_BONES, 0, root)
    menu.add_combo(T, G, p .. "priority", "Priority", { "Distance", "Crosshair (FOV)" }, 1, root)
    menu.add_checkbox(T, G, p .. "sticky", "Sticky Target", false, root)
    menu.add_checkbox(T, G, p .. "visible", "Visibility Check", false, root)

    if opts.smooth then
        menu.add_slider_int(T, G, p .. "smooth", "Smoothing (frames)", 1, 100, 5, root)
    end

    menu.add_separator(T, G)
    menu.add_checkbox(T, G, p .. "draw_fov", "Draw FOV Circle", false, menu_util.parent(parent_id, { colorpicker = opts.fov_color or { 1, 1, 1, 1 } }))
    menu.add_checkbox(T, G, p .. "fov_fill", "Fill FOV", false, root)
    menu.add_checkbox(T, G, p .. "target_line", "Target Line", false, menu_util.parent(parent_id, { colorpicker = opts.line_color or { 1, 0.2, 0.2, 1 } }))
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
    local G = menu_util.G
    local T, _ = menu_util.group(G.AIMBOT)
    menu.add_checkbox(T, G.AIMBOT, P, "Enable Aimbot", false, { key = 0x02 })
    menu.add_label(T, G.AIMBOT, "Auto weapon drop + velocity prediction (always on).")
    combat_menu.register_targeting(T, G.AIMBOT, PREFIX, P, {
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

    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num(PREFIX .. "fov", 150)
    local sticky = settings.bool(PREFIX .. "sticky", false)

    if not aim_key_down() then
        if not sticky then locked_target = nil end
        return
    end

    if sticky and locked_target then
        local ok = targeting.is_target_valid(locked_target, PREFIX, cx, cy, fov)
        if not ok then locked_target = nil end
    end

    if not locked_target or not sticky then
        locked_target = targeting.find_target(cx, cy, fov, PREFIX)
    end

    if locked_target and camera and camera.look_at then
        local cam = camera.get_position and camera.get_position()
        local aim = targeting.get_aim_point(locked_target, PREFIX, nil, cam, cx, cy)
        if aim then
            local smooth = math.max(1, settings.num(PREFIX .. "smooth", 5))
            camera.look_at(aim.x, aim.y, aim.z, smooth)
        else
            locked_target = nil
        end
    end
end

function M.draw()
    if not settings.bool(P, false) then return end

    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5

    if settings.bool(PREFIX .. "draw_fov", false) then
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

    if not locked_target or not locked_target.is_alive then return end

    if settings.bool(PREFIX .. "target_line", false) then
        local cam = camera and camera.get_position and camera.get_position()
        local aim = targeting.get_aim_point(locked_target, PREFIX, nil, cam, cx, cy)
        if aim then
            local tx, ty, vis = w2s(aim.x, aim.y, aim.z)
            if vis then
                local col = settings.color(PREFIX .. "target_line", { 1, 0.25, 0.25, 1 })
                draw_util.line(cx, cy, tx, ty, col, 1.5)
            end
        end
    end
end

return M

end)()

-- ── features/combat/gun_mods.lua ──
April._mods["features.combat.gun_mods"] = (function()
local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local weapons = April.require("game.weapons")
local profiles = April.require("game.gun_mod_profiles")
local gc = April.require("game.gc_weapon_mods")

local M = {}
local P = "april_gunmods_enabled"

M._editing = profiles.GLOBAL
M._last_applied_weapon = nil
M._last_applied_profile = nil
M._apply_dirty = false
M._last_retry = 0
M._retry_ms = 1000

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function request_apply()
    M._apply_dirty = true
end

local function switch_profile(idx)
    profiles.sync_editor_to_profile(M._editing)
    M._editing = profiles.name_at_index(idx)
    profiles.sync_profile_to_editor(M._editing)
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.AIMBOT)
    local root = menu_util.parent(P)

    local combo_items = profiles.combo_items()

    menu_util.section(T, G.AIMBOT, "Gun Mods")
    menu.add_checkbox(T, G.AIMBOT, P, "Enable Gun Mods", false, { key = 0 })
    menu.add_checkbox(T, G.AIMBOT, "april_gm_auto_detect", "Auto Weapon Detection", true, root)
    menu.add_checkbox(T, G.AIMBOT, "april_gm_per_weapon", "Per-Weapon Profiles", false, root)
    menu.add_combo(T, G.AIMBOT, "april_gm_profile", "Edit Profile", combo_items, 0, root)
    menu.add_button(T, G.AIMBOT, "april_gm_save", "Save Profile", function()
        profiles.sync_editor_to_profile(M._editing)
        print("[April Gun Mods] Saved profile: " .. M._editing)
        request_apply()
    end)
    menu.add_label(T, G.AIMBOT, "Global = all weapons. Per-weapon uses saved profile on swap.", root)

    menu.add_checkbox(T, G.AIMBOT, "april_gm_recoil", "Recoil Modifier", false, root)
    menu.add_slider_int(T, G.AIMBOT, "april_gm_recoil_pct", "Recoil Reduction %", 0, 100, 100, root)

    menu.add_checkbox(T, G.AIMBOT, "april_gm_spread", "Spread Modifier", false, root)
    menu.add_slider_int(T, G.AIMBOT, "april_gm_spread_pct", "Spread Reduction %", 0, 100, 100, root)

    menu.add_checkbox(T, G.AIMBOT, "april_gm_sway", "No Weapon Sway", false, root)

    menu.add_checkbox(T, G.AIMBOT, "april_gm_fire_rate", "Fire Rate Modifier", false, root)
    menu.add_slider_float(T, G.AIMBOT, "april_gm_fire_rate_mult", "Fire Rate Multiplier", 1.0, 3.0, 1.5, "%.2f", root)

    menu.add_checkbox(T, G.AIMBOT, "april_gm_speed", "Bullet Speed Modifier", false, root)
    menu.add_slider_int(T, G.AIMBOT, "april_gm_speed_mult", "SpeedMult (100 = instant)", 0, 100, 100, root)

    menu.add_checkbox(T, G.AIMBOT, "april_gm_range", "Range Modifier", false, root)
    menu.add_slider_int(T, G.AIMBOT, "april_gm_range_mult", "RangeMult", 1, 20, 10, root)

    settings.on_change("april_gm_profile", switch_profile)
    settings.on_change(P, request_apply)
    settings.on_change("april_gm_auto_detect", request_apply)
    settings.on_change("april_gm_per_weapon", request_apply)

    profiles.sync_profile_to_editor(M._editing)
end

function M.try_apply(held)
    if not settings.bool(P, false) then
        M._last_applied_weapon = nil
        M._last_applied_profile = nil
        return false
    end

    local auto_detect = settings.bool("april_gm_auto_detect", true)
    local per_weapon = settings.bool("april_gm_per_weapon", false)

    local apply_held = held
    if not auto_detect then
        apply_held = nil
    end

    local mods, profile_name = profiles.mods_for_weapon(apply_held, per_weapon)
    if not next(mods) then
        return false
    end

    local weapon_key = apply_held or "__global__"
    if weapon_key == M._last_applied_weapon
        and profile_name == M._last_applied_profile
        and not M._apply_dirty then
        return true
    end

    local ok, n, msg = gc.apply_once(mods)
    if ok then
        M._last_applied_weapon = weapon_key
        M._last_applied_profile = profile_name
        M._apply_dirty = false
    else
        M._apply_dirty = true
    end

    return ok
end

function M.update(dt)
    if not settings.bool(P, false) then return end

    local held = weapons._last_held
    local now = tick_ms()

    if M._apply_dirty or held ~= M._last_applied_weapon then
        M.try_apply(held)
    elseif held and now - M._last_retry >= M._retry_ms then
        if gc.last_node_count() <= 0 then
            M._last_retry = now
            M.try_apply(held)
        end
    end
end

function M.on_weapon_changed(name)
    request_apply()
end

function M.on_modules_ready()
    profiles.merge_toolinfo_weapons()
end

function M.draw() end

return M

end)()

-- ── features/visuals/player_esp.lua ──
April._mods["features.visuals.player_esp"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_esp_enabled"

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)
    local root = menu_util.parent(P)

    menu.add_label(T, G.VISUALS, "Player ESP")
    menu.add_checkbox(T, G.VISUALS, P, "Player ESP", false, { key = 0 })
    menu.add_combo(T, G.VISUALS, "april_esp_box_mode", "Box Mode", { "None", "2D", "Corner" }, 0, root)
    menu.add_checkbox(T, G.VISUALS, "april_esp_name", "Name", false, menu_util.parent(P, { colorpicker = { 1, 1, 1, 1 } }))
    menu.add_checkbox(T, G.VISUALS, "april_esp_health", "Health Bar", false, root)
    menu.add_checkbox(T, G.VISUALS, "april_esp_distance", "Distance", false, menu_util.parent(P, { colorpicker = { 0.7, 0.7, 0.7, 1 } }))
    menu.add_checkbox(T, G.VISUALS, "april_esp_held_item", "Held Item", false, menu_util.parent(P, { colorpicker = { 0.2, 0.8, 1, 1 } }))
    menu.add_checkbox(T, G.VISUALS, "april_esp_skeleton", "Skeleton", false, menu_util.parent(P, { colorpicker = { 1, 1, 1, 0.85 } }))
    menu.add_checkbox(T, G.VISUALS, "april_esp_offscreen", "Offscreen Arrows", false, menu_util.parent(P, { colorpicker = { 0.3, 1, 0.5, 1 } }))
    menu.add_slider_int(T, G.VISUALS, "april_esp_max_dist", "Max Distance", 50, 5000, 1000, root)
    menu.add_checkbox(T, G.VISUALS, "april_esp_color", "Box Color", false, menu_util.parent(P, { colorpicker = { 0.3, 1, 0.5, 1 } }))
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
    if not settings.bool(P, false) then return end

    local max_dist = settings.num("april_esp_max_dist", 1000)
    local col = settings.color("april_esp_color", { 0.3, 1, 0.5, 1 })
    local box_mode = settings.num("april_esp_box_mode", 0)
    local me = entity and entity.get_local_player and entity.get_local_player()
    local text_size = esp_util.text_size()
    local sw, sh = draw_util.screen_size()
    local cx, cy = sw * 0.5, sh * 0.5

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
        if not b or not b.valid then
            if settings.bool("april_esp_offscreen", false) and p.head_position then
                local hx, hy, hvis = esp_util.w2s(p.head_position.x, p.head_position.y, p.head_position.z)
                if not hvis then
                    local ac = settings.color("april_esp_offscreen", { 0.3, 1, 0.5, 1 })
                    esp_util.draw_offscreen_arrow(cx, cy, hx ~= 0 and hx or cx, hy ~= 0 and hy or cy, ac, 12)
                end
            end
            goto continue
        end

        if box_mode == 1 and settings.bool("april_esp_color", false) then
            draw_util.box_esp(b.x, b.y, b.w, b.h, col, 0)
        elseif box_mode == 2 and settings.bool("april_esp_color", false) then
            draw_util.box_esp(b.x, b.y, b.w, b.h, col, 1)
        end

        if settings.bool("april_esp_health", false) then
            draw_util.health_bar(b.x - 4, b.y, b.h, p.health, p.max_health)
        end

        if settings.bool("april_esp_skeleton", false) then
            local sk_col = settings.color("april_esp_skeleton", { 1, 1, 1, 0.85 })
            esp_util.draw_player_skeleton(p, sk_col, 1.5)
        end

        local label = ""
        if settings.bool("april_esp_name", false) then label = p.name or "?" end
        if settings.bool("april_esp_distance", false) and me and p.distance_to then
            local d = math.floor(p:distance_to(me.position))
            label = label .. (label ~= "" and " " or "") .. "[" .. d .. "m]"
        end
        if settings.bool("april_esp_held_item", false) and p.tool_name and p.tool_name ~= "" then
            label = label .. (label ~= "" and " " or "") .. "(" .. p.tool_name .. ")"
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
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)
    menu_util.section(T, G.VISUALS, "Crosshair")
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_enabled", "Enable Custom Crosshair", false, { key = 0 })
    menu.add_combo(T, G.VISUALS, "april_crosshair_type", "Crosshair Type", { "Cross", "Circle", "Dot", "T-Shape" }, 0, { parent = P })
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_size", "Size", 1, 50, 10, { parent = P })
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_gap", "Gap", 0, 20, 5, { parent = P })
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_thickness", "Thickness", 1, 10, 2, { parent = P })
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_color", "Crosshair Color", true, { parent = P, colorpicker = { 0, 1, 0, 1 } })
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_dot", "Center Dot", false, { parent = P, colorpicker = { 1, 1, 1, 1 } })
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_outline", "Outline", true, { parent = P, colorpicker = { 0, 0, 0, 1 } })
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_rainbow", "Rainbow Crosshair", false, { parent = P })
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_rainbow_speed", "Rainbow Speed", 1, 100, 10, { parent = P })
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
    if not settings.bool("april_crosshair_enabled", false) then return end
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
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)
    menu_util.section(T, G.VISUALS, "Hitmarkers")
    menu.add_checkbox(T, G.VISUALS, "april_hitmarker_enabled", "Hitmarker", false, { colorpicker = { 1, 1, 1, 1 } })
    menu.add_checkbox(T, G.VISUALS, "april_hitmarker_glow", "Hitmarker Glow", false, { parent = P })
    menu.add_slider_int(T, G.VISUALS, "april_hitmarker_size", "Hitmarker Size", 1, 20, 5, { parent = P })
    menu.add_slider_int(T, G.VISUALS, "april_hitmarker_duration", "Duration (ms)", 100, 2000, 500, { parent = P })
    menu.add_checkbox(T, G.VISUALS, "april_hit_notifier", "Hit Notifier", false)
end

function M.trigger_hit()
    hit_time = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_hitmarker_enabled", false) then return end
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
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    menu.add_label(T, G.WORLD, "Resources & Nodes")
    menu.add_checkbox(T, G.WORLD, "april_world_enabled", "Enable World ESP", false, { key = 0 })
    for _, t in ipairs(TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
    end
    menu.add_slider_int(T, G.WORLD, "april_world_range", "World Range", 50, 2000, 500, { parent = P })
end

local function matches_toggle(name)
    name = name or ""
    for _, t in ipairs(TOGGLES) do
        if settings.bool(t.id, false) and name:find(t.match) then
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
    if not settings.bool("april_world_enabled", false) then return end
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
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    menu_util.section(T, G.WORLD, "Loot ESP")
    menu.add_checkbox(T, G.WORLD, "april_loot_enabled", "Enable Loot ESP", false, { key = 0 })
    for _, t in ipairs(TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
    end
    menu.add_slider_int(T, G.WORLD, "april_loot_range", "Loot Range", 50, 2000, 300, { parent = P })
end

local function matches_toggle(name)
    name = name or ""
    for _, t in ipairs(TOGGLES) do
        if settings.bool(t.id, false) and name:find(t.match) then
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
    if not settings.bool("april_loot_enabled", false) then return end
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
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    menu_util.section(T, G.WORLD, "Base ESP")
    menu.add_checkbox(T, G.WORLD, "april_base_enabled", "Enable Base ESP", false, { key = 0 })
    for _, t in ipairs(TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
    end
    menu.add_checkbox(T, G.WORLD, "april_base_distance", "Show Distance", false, { parent = P })
    menu.add_slider_int(T, G.WORLD, "april_base_range", "Base Range", 50, 500, 150, { parent = P })
end

local function matches_toggle(name)
    name = name or ""
    for _, t in ipairs(TOGGLES) do
        if settings.bool(t.id, false) and name:find(t.match) then
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
    if not settings.bool("april_base_enabled", false) then return end
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
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_npc_enabled"

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    local root = menu_util.parent(P)

    menu_util.section(T, G.WORLD, "NPC ESP")
    menu.add_checkbox(T, G.WORLD, P, "Enable NPC ESP", false, { key = 0, colorpicker = { 1, 0.3, 0.3, 1 } })
    menu.add_checkbox(T, G.WORLD, "april_npc_soldiers", "Soldiers", false, menu_util.parent(P, { colorpicker = { 1, 0.3, 0.3, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_zombies", "Zombies", false, menu_util.parent(P, { colorpicker = { 0.4, 1, 0.3, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_animals", "Animals", false, menu_util.parent(P, { colorpicker = { 0.8, 0.6, 0.2, 1 } }))
    menu.add_combo(T, G.WORLD, "april_npc_box_mode", "NPC Box Mode", { "None", "2D", "Corner" }, 0, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_health", "Health Bar", false, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_name", "Name", false, menu_util.parent(P, { colorpicker = { 1, 1, 1, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_distance", "Distance", false, menu_util.parent(P, { colorpicker = { 0.7, 0.7, 0.7, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_skeleton", "Skeleton", false, menu_util.parent(P, { colorpicker = { 1, 1, 1, 0.85 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_offscreen", "Offscreen Arrows", false, menu_util.parent(P, { colorpicker = { 1, 0.3, 0.3, 1 } }))
    menu.add_slider_int(T, G.WORLD, "april_npc_range", "NPC Range", 50, 2000, 500, root)
end

function M.scan()
    cache.npcs = {}
    folders.iter_workspace_folders({ "animals", "military", "npcs" }, function(key, folder)
        local found = folders.scan_descendants(folder, { "Soldier", "NPC", "Zombie", "BTR", "Deer", "Boar", "Wolf" }, 200)
        for _, inst in ipairs(found) do
            table.insert(cache.npcs, { inst = inst, name = inst.Name or inst.name, category = key })
        end
    end)
    cache.stats.last_npc_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function category_enabled(entry)
    local cat = entry.category or ""
    local name = (entry.name or ""):lower()
    if cat == "military" or name:find("soldier") or name:find("btr") then
        return settings.bool("april_npc_soldiers", false)
    end
    if name:find("zombie") then return settings.bool("april_npc_zombies", false) end
    if cat == "animals" or name:find("deer") or name:find("boar") or name:find("wolf") then
        return settings.bool("april_npc_animals", false)
    end
    return settings.bool("april_npc_soldiers", false)
end

local function category_color(entry)
    local cat = entry.category or ""
    local name = (entry.name or ""):lower()
    if name:find("zombie") then return settings.color("april_npc_zombies", { 0.4, 1, 0.3, 1 }) end
    if cat == "animals" or name:find("deer") or name:find("boar") or name:find("wolf") then
        return settings.color("april_npc_animals", { 0.8, 0.6, 0.2, 1 })
    end
    return settings.color("april_npc_soldiers", { 1, 0.3, 0.3, 1 })
end

function M.update(dt) end

function M.draw()
    if not settings.bool(P, false) then return end

    local range = settings.num("april_npc_range", 500)
    local box_mode = settings.num("april_npc_box_mode", 0)
    local text_size = esp_util.text_size()
    local me = env.get_local_player()
    local sw, sh = draw_util.screen_size()
    local cx, cy = sw * 0.5, sh * 0.5

    for _, entry in ipairs(cache.npcs) do
        if not category_enabled(entry) then goto continue end
        if not env.is_valid(entry.inst) then goto continue end

        local col = category_color(entry)
        local pos = entry.inst.Position or entry.inst.position
        if not pos or pos.x == nil then goto continue end

        if me and me.position then
            local dx = pos.x - me.position.x
            local dy = pos.y - me.position.y
            local dz = pos.z - me.position.z
            if math.sqrt(dx * dx + dy * dy + dz * dz) > range then goto continue end
        end

        local sx, sy, vis = esp_util.w2s(pos.x, pos.y, pos.z)
        if not vis then
            if settings.bool("april_npc_offscreen", false) then
                esp_util.draw_offscreen_arrow(cx, cy, sx, sy, col, 12)
            end
            goto continue
        end

        local label = entry.name or "NPC"
        if settings.bool("april_npc_name", false) then
            if settings.bool("april_npc_distance", false) and me and me.position then
                local dx = pos.x - me.position.x
                local dy = pos.y - me.position.y
                local dz = pos.z - me.position.z
                label = label .. string.format(" [%dm]", math.floor(math.sqrt(dx * dx + dy * dy + dz * dz)))
            end
            local nc = settings.color("april_npc_name", { 1, 1, 1, 1 })
            draw_util.text_centered(sx, sy - 14, label, nc, text_size)
        end

        if settings.bool("april_npc_skeleton", false) then
            local sk = settings.color("april_npc_skeleton", { 1, 1, 1, 0.85 })
            esp_util.draw_model_skeleton(entry.inst, sk, 1.5)
        end

        if box_mode > 0 then
            local pad = 18
            if box_mode == 1 then
                draw_util.box_esp(sx - pad, sy - pad * 2, pad * 2, pad * 3, col, 0)
            else
                draw_util.box_esp(sx - pad, sy - pad * 2, pad * 2, pad * 3, col, 1)
            end
        end

        ::continue::
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
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu.add_checkbox(T, G.MISC, "april_noclip_enabled", "Noclip", false, { key = 0x12 })
    menu.add_combo(T, G.MISC, "april_noclip_mode", "Noclip Mode", { "Toggle", "Hold" }, 1, root)
    menu.add_slider_int(T, G.MISC, "april_noclip_speed", "Noclip Speed", 1, 50, 16, root)

    menu.add_checkbox(T, G.MISC, "april_omnisprint_enabled", "Omnisprint", false, { key = 0 })
    menu.add_combo(T, G.MISC, "april_omnisprint_mode", "Sprint Mode", { "Toggle", "Hold" }, 0, { parent = "april_omnisprint_enabled" })
    menu.add_slider_int(T, G.MISC, "april_omnisprint_speed", "Sprint Speed", 16, 80, 32, { parent = "april_omnisprint_enabled" })

    menu.add_checkbox(T, G.MISC, "april_spider_enabled", "Spider Climb", false, { key = 0 })
    menu.add_slider_int(T, G.MISC, "april_spider_speed", "Wall Speed", 1, 50, 20, { parent = "april_spider_enabled" })
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
            if input.is_key_down(0x57) then
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
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_waypoints_enabled"

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.RADAR)
    local root = menu_util.parent(P)

    menu.add_label(T, G.RADAR, "Waypoints")
    menu.add_checkbox(T, G.RADAR, P, "Enable Waypoints", false, { key = 0 })
    menu.add_checkbox(T, G.RADAR, "april_wp_dist", "Show Distance", false, root)
    menu.add_checkbox(T, G.RADAR, "april_wp_beacon", "Beacon Line", false, root)
    menu.add_checkbox(T, G.RADAR, "april_wp_draw", "Draw Markers", false, menu_util.parent(P, { colorpicker = { 0.2, 1, 0.8, 1 } }))
    menu.add_slider_int(T, G.RADAR, "april_wp_slot", "Active Slot", 1, 5, 1, root)

    menu.add_button(T, G.RADAR, "april_wp_set", "Set Active Waypoint", function()
        local slot = settings.num("april_wp_slot", 1)
        local lp = env.get_local_player()
        if lp and lp.position then
            cache.waypoints[slot] = {
                name = "Waypoint " .. slot,
                pos = { x = lp.position.x, y = lp.position.y, z = lp.position.z },
            }
            print("[April] Waypoint " .. slot .. " set")
        end
    end)

    menu.add_button(T, G.RADAR, "april_wp_clear", "Clear Active Waypoint", function()
        local slot = settings.num("april_wp_slot", 1)
        cache.waypoints[slot] = nil
        print("[April] Waypoint " .. slot .. " cleared")
    end)

    menu.add_button(T, G.RADAR, "april_wp_clear_all", "Clear All Waypoints", function()
        cache.waypoints = {}
        print("[April] All waypoints cleared")
    end)
end

function M.update(dt) end

function M.draw()
    if not settings.bool(P, false) then return end
    if not settings.bool("april_wp_draw", false) and not settings.bool("april_wp_beacon", false) then return end

    local col = settings.color("april_wp_draw", { 0.2, 1, 0.8, 1 })
    local sw, sh = draw_util.screen_size()
    local me = env.get_local_player()

    for i, wp in pairs(cache.waypoints) do
        if wp and wp.pos then
            local sx, sy, vis = esp_util.w2s(wp.pos.x, wp.pos.y, wp.pos.z)
            if not vis then goto continue end

            local label = wp.name or ("WP" .. tostring(i))
            if settings.bool("april_wp_dist", false) and me and me.position then
                local dx = wp.pos.x - me.position.x
                local dy = wp.pos.y - me.position.y
                local dz = wp.pos.z - me.position.z
                label = label .. string.format(" [%.0fm]", math.sqrt(dx * dx + dy * dy + dz * dz))
            end

            if settings.bool("april_wp_beacon", false) then
                esp_util.draw_beacon(sx, sy, col, { origin_x = sw * 0.5, origin_y = sh })
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

-- ── features/radar/tactical_map.lua ──
April._mods["features.radar.tactical_map"] = (function()
local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local cache = April.require("core.cache")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_map_enabled"

M._offset_x = 0
M._offset_y = 0
M._dragging = false
M._drag_mx = 0
M._drag_my = 0
M._old_off_x = 0
M._old_off_y = 0

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.RADAR)
    local root = menu_util.parent(P)

    menu_util.section(T, G.RADAR, "Tactical Map")
    menu.add_checkbox(T, G.RADAR, P, "Enable Tactical Map", false, { key = 0x28 })
    menu.add_combo(T, G.RADAR, "april_map_mode", "Display Mode", { "Corner Widget", "Fullscreen Overlay" }, 0, root)
    menu.add_slider_float(T, G.RADAR, "april_map_zoom", "Zoom Level", 0.05, 5.0, 1.0, "%.2f", root)
    menu.add_slider_int(T, G.RADAR, "april_map_size", "Corner Size", 120, 500, 220, root)
    menu.add_slider_int(T, G.RADAR, "april_map_icon_scale", "Icon Scale", 1, 8, 3, root)

    menu.add_separator(T, G.RADAR)
    menu.add_label(T, G.RADAR, "Layers")
    menu.add_checkbox(T, G.RADAR, "april_map_show_players", "Players", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_npcs", "NPCs", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_loot", "Loot", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_world", "World Resources", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_base", "Base Parts", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_waypoints", "Waypoints", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_local", "Local Player", true, root)

    menu.add_separator(T, G.RADAR)
    menu.add_colorpicker(T, G.RADAR, "april_map_bg", "Background Color", { 0.05, 0.05, 0.08, 0.95 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_grid", "Grid Color", { 1, 1, 1, 0.04 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_player_col", "Player Color", { 1, 0.35, 0.35, 1 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_npc_col", "NPC Color", { 1, 0.6, 0.2, 1 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_loot_col", "Loot Color", { 1, 0.85, 0.2, 1 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_world_col", "World Color", { 0.4, 0.9, 0.5, 1 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_base_col", "Base Color", { 0.5, 0.5, 1, 1 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_wp_col", "Waypoint Color", { 0.2, 1, 0.8, 1 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_local", "Local Player Color", { 0.2, 0.8, 1, 1 }, root)

    menu.add_separator(T, G.RADAR)
    menu.add_checkbox(T, G.RADAR, "april_map_labels", "Show Labels", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_coords", "Show Coordinates", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_compass", "Compass Overlay", false, menu_util.parent(P, { colorpicker = { 0.2, 0.8, 1, 0.8 } }))
    menu.add_checkbox(T, G.RADAR, "april_map_tooltips", "Hover Tooltips", false, root)
    menu.add_button(T, G.RADAR, "april_map_recenter", "Recenter Map", function()
        M._offset_x = 0
        M._offset_y = 0
    end)
end

local function key_active()
    if settings.bool(P, false) then return true end
    if not menu or not menu.get_key then return false end
    local vk = menu.get_key(P)
    return vk and vk > 0 and input and input.is_key_down and input.is_key_down(vk)
end

local function get_mouse()
    if not utility or not utility.get_mouse_pos then return 0, 0 end
    local ok, a, b = pcall(utility.get_mouse_pos)
    if not ok then return 0, 0 end
    if type(a) == "table" then
        return a.x or a.X or 0, a.y or a.Y or 0
    end
    if type(a) == "number" then
        return a, b or 0
    end
    return 0, 0
end

local function vec_xz(v)
    if not v then return 0, 0 end
    return v.x or v.X or 0, v.z or v.Z or 0
end

local function get_look_vector()
    if camera and camera.get_look_vector then
        local ok, lv = pcall(camera.get_look_vector)
        if ok and lv then return lv end
    end
    return nil
end

-- Horizontal camera yaw (radians). Forward on XZ = (sin(yaw), cos(yaw)).
local function get_camera_yaw()
    if camera and camera.get_angles then
        local ok, a = pcall(camera.get_angles)
        if ok and a then
            local deg = a.Y or a.y
            if deg then return math.rad(deg) end
        end
    end
    if utility and utility.get_camera_angles then
        local ok, pitch, yaw = pcall(utility.get_camera_angles)
        if ok and yaw then return math.rad(yaw) end
        if ok and pitch and not yaw then return math.rad(pitch) end
    end
    local lv = get_look_vector()
    if lv then
        local lx, lz = vec_xz(lv)
        if math.abs(lx) > 0.001 or math.abs(lz) > 0.001 then
            return math.atan2(lx, lz)
        end
    end
    return 0
end

local function get_view_origin()
    local cx, cy, cz = nil, nil, nil

    if camera and camera.get_position then
        local ok, pos = pcall(camera.get_position)
        if ok and pos and (pos.x or pos.X) then
            cx = pos.x or pos.X
            cy = pos.y or pos.Y
            cz = pos.z or pos.Z
        end
    end

    local lp = env.get_local_player()
    local px, py, pz = nil, nil, nil
    if lp and lp.position then
        px = lp.position.x
        py = lp.position.y
        pz = lp.position.z
    end

    if not cx then
        cx, cy, cz = px, py, pz
    end

    return cx or 0, cy or 0, cz or 0, px, py, pz
end

local function map_layout(sw, sh, fullscreen)
    if fullscreen then
        return 0, 0, sw, sh, sw * 0.5, sh * 0.5
    end
    local size = settings.num("april_map_size", 220)
    local x, y = sw - size - 20, 20
    return x, y, size, size, x + size * 0.5, y + size * 0.5
end

-- Camera-relative: forward = up on screen, right = right on screen.
local function world_to_map(wx, wz, view_x, view_z, map_cx, map_cy, zoom, yaw)
    local wdx = wx - view_x
    local wdz = wz - view_z
    local fx, fz = math.sin(yaw), math.cos(yaw)
    local rx, rz = math.cos(yaw), -math.sin(yaw)
    local local_fwd = wdx * fx + wdz * fz
    local local_right = wdx * rx + wdz * rz
    return map_cx + local_right * zoom, map_cy - local_fwd * zoom
end

local function world_dir_to_screen(dx, dz, yaw, radius)
    local fx, fz = math.sin(yaw), math.cos(yaw)
    local rx, rz = math.cos(yaw), -math.sin(yaw)
    local local_fwd = dx * fx + dz * fz
    local local_right = dx * rx + dz * rz
    return local_right * radius, -local_fwd * radius
end

local function draw_dot(mx, my, scale, col)
    if draw and draw.circle_filled then
        draw.circle_filled(mx, my, scale, col, 10)
    else
        draw_util.circle(mx, my, scale, col, true)
    end
end

local function entry_world_xz(entry)
    if entry.x and entry.z then return entry.x, entry.z end
    local inst = entry.inst
    if inst then
        local pos = inst.Position or inst.position
        if pos and pos.x then return pos.x, pos.z end
    end
    return nil, nil
end

local function draw_map_item(wx, wz, col, label, view_x, view_z, map_cx, map_cy, zoom, yaw, scale, x, y, w, h)
    if not wx or not wz then return end
    local mx, my = world_to_map(wx, wz, view_x, view_z, map_cx, map_cy, zoom, yaw)
    if mx < x - 8 or mx > x + w + 8 or my < y - 8 or my > y + h + 8 then return end
    draw_dot(mx, my, scale, col)
    if settings.bool("april_map_labels", false) and label and label ~= "" then
        draw_util.text(mx + scale + 2, my - 6, label, col, 10)
    end
end

local function draw_grid(x, y, w, h, grid, map_cx, map_cy, zoom)
    local step = math.max(12, (w / 8))
    for i = -4, 4 do
        if i ~= 0 then
            draw_util.line(map_cx + i * step, y + 4, map_cx + i * step, y + h - 4, grid, 1)
            draw_util.line(x + 4, map_cy + i * step, x + w - 4, map_cy + i * step, grid, 1)
        end
    end
end

local function draw_compass_rose(cx, cy, radius, yaw, cmp_col, inside_x, inside_y, inside_w, inside_h)
    if draw and draw.circle_filled then
        draw.circle_filled(cx, cy, radius, { 0.05, 0.05, 0.08, 0.75 }, 24)
    end
    if draw and draw.circle then
        draw.circle(cx, cy, radius, cmp_col, 24, 1.5)
    end

    local function marker(lbl, wdx, wdz, col)
        local sx, sy = world_dir_to_screen(wdx, wdz, yaw, radius - 10)
        draw_util.text(cx + sx - 4, cy + sy - 6, lbl, col, 11)
    end

    marker("N", 0, -1, { 1, 0.2, 0.2, 1 })
    marker("S", 0, 1, cmp_col)
    marker("E", 1, 0, cmp_col)
    marker("W", -1, 0, cmp_col)

    if draw and draw.line then
        local nx, ny = world_dir_to_screen(0, -1, yaw, radius - 4)
        draw.line(cx, cy, cx + nx, cy + ny, { 1, 0.2, 0.2, 0.9 }, 2)
    end
end

local function handle_fullscreen_pan(zoom, mx, my, yaw)
    if not input or not input.is_key_down then return end

    if input.is_key_down(0x04) then
        M._offset_x = 0
        M._offset_y = 0
        return
    end

    if input.is_key_down(0x01) then
        if not M._dragging then
            M._dragging = true
            M._drag_mx = mx
            M._drag_my = my
            M._old_off_x = M._offset_x
            M._old_off_y = M._offset_y
        elseif zoom > 0 then
            local dx = (mx - M._drag_mx) / zoom
            local dy = (my - M._drag_my) / zoom
            local fx, fz = math.sin(yaw), math.cos(yaw)
            local rx, rz = math.cos(yaw), -math.sin(yaw)
            M._offset_x = M._old_off_x - (dx * rx + dy * rz)
            M._offset_y = M._old_off_y - (-dx * fx + dy * fz)
        end
    else
        M._dragging = false
    end
end

function M.update(dt) end

function M.draw()
    if not key_active() then return end
    if not draw then return end

    local sw, sh = draw_util.screen_size()
    local fullscreen = settings.num("april_map_mode", 0) == 1
    local x, y, w, h, map_cx, map_cy = map_layout(sw, sh, fullscreen)
    local zoom = settings.num("april_map_zoom", 1.0)
    local scale = settings.num("april_map_icon_scale", 3)
    local bg = settings.color("april_map_bg", { 0.05, 0.05, 0.08, 0.95 })
    local grid = settings.color("april_map_grid", { 1, 1, 1, 0.04 })

    local cam_x, cam_y, cam_z, body_x, body_y, body_z = get_view_origin()
    local yaw = get_camera_yaw()

    local mx, my = get_mouse()

    if fullscreen then
        handle_fullscreen_pan(zoom, mx, my, yaw)
    else
        M._offset_x = 0
        M._offset_y = 0
        M._dragging = false
    end

    local view_x = cam_x + M._offset_x
    local view_z = cam_z + M._offset_y

    if draw.rect_filled then
        draw.rect_filled(x, y, w, h, bg, fullscreen and 0 or 1)
        if draw.rect then
            draw.rect(x, y, w, h, { 1, 1, 1, 0.15 }, fullscreen and 0 or 1, 1)
        end
    end

    draw_grid(x, y, w, h, grid, map_cx, map_cy, zoom)

    if settings.bool("april_map_show_players", false) and entity and entity.get_players then
        local col = settings.color("april_map_player_col", { 1, 0.35, 0.35, 1 })
        for _, p in ipairs(entity.get_players()) do
            if not p.is_local and p.is_alive and p.position then
                draw_map_item(p.position.x, p.position.z, col, p.name, view_x, view_z, map_cx, map_cy, zoom, yaw, scale, x, y, w, h)
            end
        end
    end

    if settings.bool("april_map_show_npcs", false) then
        local col = settings.color("april_map_npc_col", { 1, 0.6, 0.2, 1 })
        for _, entry in ipairs(cache.npcs) do
            local inst = entry.inst
            if inst and env.is_valid(inst) then
                local pos = inst.Position or inst.position
                if pos then
                    draw_map_item(pos.x, pos.z, col, entry.name, view_x, view_z, map_cx, map_cy, zoom, yaw, scale, x, y, w, h)
                end
            end
        end
    end

    if settings.bool("april_map_show_loot", false) then
        local col = settings.color("april_map_loot_col", { 1, 0.85, 0.2, 1 })
        for _, item in ipairs(cache.loot) do
            local wx, wz = entry_world_xz(item)
            if wx then
                draw_map_item(wx, wz, col, item.name, view_x, view_z, map_cx, map_cy, zoom, yaw, scale, x, y, w, h)
            end
        end
    end

    if settings.bool("april_map_show_world", false) then
        local col = settings.color("april_map_world_col", { 0.4, 0.9, 0.5, 1 })
        for _, item in ipairs(cache.world) do
            local wx, wz = entry_world_xz(item)
            if wx then
                draw_map_item(wx, wz, col, item.name, view_x, view_z, map_cx, map_cy, zoom, yaw, scale, x, y, w, h)
            end
        end
    end

    if settings.bool("april_map_show_base", false) then
        local col = settings.color("april_map_base_col", { 0.5, 0.5, 1, 1 })
        for _, item in ipairs(cache.base) do
            local wx, wz = entry_world_xz(item)
            if wx then
                draw_map_item(wx, wz, col, item.label or item.name, view_x, view_z, map_cx, map_cy, zoom, yaw, scale, x, y, w, h)
            end
        end
    end

    if settings.bool("april_map_show_waypoints", false) then
        local col = settings.color("april_map_wp_col", { 0.2, 1, 0.8, 1 })
        for i, wp in pairs(cache.waypoints) do
            if wp and wp.pos then
                draw_map_item(wp.pos.x, wp.pos.z, col, wp.name or ("WP" .. i), view_x, view_z, map_cx, map_cy, zoom, yaw, scale, x, y, w, h)
            end
        end
    end

    local show_local = settings.bool("april_map_show_local", true)
    if not fullscreen then
        show_local = true
    end

    if show_local then
        local col = settings.color("april_map_local", { 0.2, 0.8, 1, 1 })
        local dot_x, dot_y = map_cx, map_cy

        if body_x and body_z then
            dot_x, dot_y = world_to_map(body_x, body_z, view_x, view_z, map_cx, map_cy, zoom, yaw)
        end

        draw_dot(dot_x, dot_y, scale + 1, col)
        if draw and draw.circle then
            draw.circle(dot_x, dot_y, scale + 4, { col[1], col[2], col[3], (col[4] or 1) * 0.35 }, 16, 1)
        end

        if draw and draw.line then
            local tip_x, tip_y = map_cx, map_cy - (scale + 10)
            draw.line(map_cx, map_cy, tip_x, tip_y, { col[1], col[2], col[3], 0.85 }, 2)
            draw.line(tip_x, tip_y - 5, tip_x - 4, tip_y + 2, { col[1], col[2], col[3], 0.85 }, 2)
            draw.line(tip_x, tip_y - 5, tip_x + 4, tip_y + 2, { col[1], col[2], col[3], 0.85 }, 2)
        end
    end

    if settings.bool("april_map_compass", false) then
        local cmp_col = settings.color("april_map_compass", { 0.2, 0.8, 1, 0.8 })
        if fullscreen then
            draw_compass_rose(sw - 60, sh - 60, 42, yaw, cmp_col)
        else
            draw_compass_rose(map_cx, map_cy, math.min(w, h) * 0.42, yaw, cmp_col, x, y, w, h)
        end
    end

    if settings.bool("april_map_coords", false) then
        local coord_y = fullscreen and (sh - 22) or (y + h + 4)
        draw_util.text(x + 6, coord_y, string.format("Cam: %.0f, %.0f, %.0f", cam_x, cam_y, cam_z), { 1, 1, 1, 0.8 }, 11)
        if body_x then
            draw_util.text(x + 6, coord_y + 13, string.format("Body: %.0f, %.0f, %.0f", body_x, body_y or 0, body_z or 0), { 0.7, 0.7, 0.7, 0.75 }, 10)
        end
    end

    if fullscreen then
        draw_util.text(10, sh - 18, "Drag: LMB pan  |  Recenter: MMB  |  Forward = up", { 1, 1, 1, 0.35 }, 10)
    end
end

return M

end)()

-- ── features/utility/config.lua ──
April._mods["features.utility.config"] = (function()
local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local profiles = April.require("game.gun_mod_profiles")

local M = {}

function M.get_config_path(name)
    local base = os.getenv and os.getenv("LOCALAPPDATA") or ""
    if base == "" then return name end
    return base .. "\\Project Vector\\Scripts\\" .. name
end

local function base_config_keys()
    return {
        "april_aimbot_enabled", "april_aimbot_fov", "april_aimbot_smooth",
        "april_esp_enabled", "april_world_enabled", "april_loot_enabled",
        "april_npc_enabled", "april_base_enabled", "april_noclip_enabled",
        "april_crosshair_enabled", "april_map_enabled", "april_gunmods_enabled",
        "april_gm_auto_detect", "april_gm_per_weapon", "april_gm_profile",
        "april_gm_recoil", "april_gm_recoil_pct", "april_gm_spread", "april_gm_spread_pct",
        "april_gm_sway", "april_gm_fire_rate", "april_gm_fire_rate_mult",
        "april_gm_speed", "april_gm_speed_mult", "april_gm_range", "april_gm_range_mult",
    }
end

function M.save_slot(slot)
    slot = slot or 1
    local lines = {}

    for _, id in ipairs(base_config_keys()) do
        if menu and menu.get then
            local v = menu.get(id)
            if v ~= nil then table.insert(lines, id .. "=" .. tostring(v)) end
        end
    end

    for _, pair in ipairs(profiles.export_config_values()) do
        table.insert(lines, pair[1] .. "=" .. pair[2])
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
            if profiles.import_config_value(id, val) then
                -- stored in profile table
            elseif menu and menu.set then
                if val == "true" then menu.set(id, true)
                elseif val == "false" then menu.set(id, false)
                else
                    local n = tonumber(val)
                    menu.set(id, n or val)
                end
                April.require("core.settings").invalidate()
            end
        end
    end

    f:close()

    pcall(function()
        local gun_mods = April.require("features.combat.gun_mods")
        local weapons = April.require("game.weapons")
        local idx = settings.num("april_gm_profile", 0)
        gun_mods._editing = profiles.name_at_index(idx)
        profiles.sync_profile_to_editor(gun_mods._editing)
        gun_mods._apply_dirty = true
        if gun_mods.on_weapon_changed then
            gun_mods.on_weapon_changed(weapons._last_held)
        end
    end)

    print("[April] Config loaded slot " .. slot)
    return true
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.CONFIG)
    menu.add_label(T, G.CONFIG, "April v3 — Fallen Survival")
    menu.add_slider_int(T, G.CONFIG, "april_esp_text_size", "ESP Text Size", 8, 24, 13)
    menu.add_separator(T, G.CONFIG)
    menu.add_button(T, G.CONFIG, "april_cfg_save_1", "Save Config Slot 1", function() M.save_slot(1) end)
    menu.add_button(T, G.CONFIG, "april_cfg_load_1", "Load Config Slot 1", function() M.load_slot(1) end)
    menu.add_separator(T, G.CONFIG)
    menu.add_checkbox(T, G.CONFIG, "april_debug_overlay", "Debug Overlay", false)
    menu.add_button(T, G.CONFIG, "april_debug_clear", "Clear Error Log", function()
        April.require("core.debug").reset_errors()
        print("[April] Error log cleared")
    end)
    menu.add_button(T, G.CONFIG, "april_reload_modules", "Reload Game Modules", function()
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
    local gc = April.require("game.gc_weapon_mods")
    local stats = dbg.stats()
    local y = 40
    draw.text(10, y, "April v3 " .. (April.version or "?"), { 0.4, 1, 0.6, 1 }, 14)
    y = y + 16
    draw.text(10, y, "ToolInfo: " .. (bootstrap.is_ready() and "OK" or "waiting...") ..
        "  " .. gc.status_text(), { 1, 1, 1, 0.9 }, 12)
    y = y + 14
    if bootstrap.get_status then
        draw.text(10, y, bootstrap.get_status(), { 0.85, 0.85, 0.85, 0.85 }, 11)
        y = y + 14
    end
    draw.text(10, y, "Frames: " .. stats.frames, { 1, 1, 1, 0.9 }, 12)
    y = y + 14
    draw.text(10, y, "Players: " .. #cache.players, { 1, 1, 1, 0.9 }, 12)
    y = y + 14
    draw.text(10, y, "World: " .. #cache.world .. "  Loot: " .. #cache.loot, { 1, 1, 1, 0.9 }, 12)
    y = y + 14
    local caps = April.require("core.capabilities")
    draw.text(10, y, caps.summary(), { 0.6, 0.85, 1, 0.85 }, 10)
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
M._menu_registered = false

M.FEATURE_ORDER = {
    "features.combat.aimbot",
    "features.combat.gun_mods",
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
    if M._menu_registered then return end

    M.features = {}
    local registered = 0

    for _, path in ipairs(M.FEATURE_ORDER) do
        local feat = April.require(path)
        table.insert(M.features, feat)
        if feat.register_menu then
            local ok, err = pcall(feat.register_menu)
            if ok then
                registered = registered + 1
            else
                print("[April] Menu registration failed: " .. path .. " — " .. tostring(err))
                debug.error_once("menu:" .. path, err)
            end
        end
    end

    M._menu_registered = true
    if April and April.debug then
        debug.log("Menu: " .. registered .. " sections")
    end
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
end

function M.update(dt)
    bootstrap.tick()

    local weapons = April.require("game.weapons")
    weapons.tick()

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

    M.register_all()
    M.setup_scans()
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

-- Vector requires menu registration from the script main chunk (not nested init).
do
    April.require("menu.tabs").register_all()
end

April._init_ok = false

local ok, err = pcall(function()
    local debug = April.require("core.debug")
    local caps = April.require("core.capabilities")
    local app = April.require("app")

    if not app.init() then
        debug.error_once("init", "app.init() returned false — features disabled")
        return
    end

    April._init_ok = true

    local c = caps.probe()
    if c.fallen_gc then
        local gc = April.require("game.gc_weapon_mods")
        local n = gc.probe_on_load()
        print(string.format("[April] Fallen GC API: getgc(keys) OK — %d node(s) (enter match if 0)", n))
    end

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
    print("[April v3] Ready — " .. April.version)
else
    print("[April v3] Init failed — check console above")
end
