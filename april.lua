--[[
    April — Fallen Survival for Project Vector
    https://github.com/Cunzaki/April
    Built: 2026-07-06T23:03:45.460Z
]]

April = {
    version = "3.55.0",
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

-- ── core/text_util.lua ──
April._mods["core.text_util"] = (function()
--[[ ASCII-safe UI text — Vector draw font lacks many Unicode glyphs (shows as ?). ]]

local M = {}

local REPLACEMENTS = {
    ["\194\160"] = " ", -- nbsp
    ["\226\128\166"] = "...", -- ellipsis …
    ["\226\128\147"] = "-", -- em dash —
    ["\226\128\148"] = "-", -- en dash –
    ["\226\128\162"] = "*", -- bullet •
    ["\194\183"] = "|", -- middle dot ·
    ["\226\134\146"] = "->", -- arrow →
    ["\226\134\144"] = "<-", -- arrow ←
    ["\226\128\153"] = "'", -- right single quote
    ["\226\128\156"] = '"', -- left double quote
    ["\226\128\157"] = '"', -- right double quote
}

function M.sanitize(text)
    if text == nil then return "" end
    text = tostring(text)
    for bad, good in pairs(REPLACEMENTS) do
        text = text:gsub(bad, good)
    end
    if text:find("[^\32-\126]") then
        text = text:gsub("[^\32-\126]", "")
    end
    return text
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

M.WORKSPACE_SCAN_MS = 1000
M.POS_CACHE_MS = 1000
M._last_pos_cache = 0

function M.should_refresh_positions()
    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    if now - M._last_pos_cache >= M.POS_CACHE_MS then
        M._last_pos_cache = now
        return true
    end
    return false
end

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
    April debug — off by default. Set April.debug = true for console logs.
]]

local M = {}

local seen_errors = {}
local frame_count = 0

function M.enabled()
    return April and April.debug == true
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

local _callbacks = {}

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
    if v == false or v == 0 or v == "false" then return false end
    return v == true or v == 1
end

--[[ Strict checkbox read — never treats missing menu value as enabled. ]]
function M.enabled(id)
    local ok, fb = pcall(function()
        return April.require("core.feature_bind")
    end)
    if ok and fb and fb.is_registered(id) then
        return fb.active(id)
    end

    if not menu or not menu.get then return false end
    local v = menu.get(id)
    if v == nil or v == false or v == 0 or v == "false" then return false end
    return v == true or v == 1
end

function M.num(id, default)
    return tonumber(M.get(id, default)) or default or 0
end

--[[ Combo index — zero-based per API.md; also accepts label strings. ]]
function M.combo_index(id, labels, default)
    default = default or 0
    local v = M.get(id, default)
    if type(v) == "string" then
        local lower = v:lower()
        for i, label in ipairs(labels or {}) do
            if label:lower() == lower then return i - 1 end
        end
        return default
    end
    local n = tonumber(v)
    if n == nil then return default end
    return n
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
    if not id or not fn then return end

    _callbacks[id] = _callbacks[id] or {}
    _callbacks[id][#_callbacks[id] + 1] = fn

    if menu and menu.set_callback then
        menu.set_callback(id, function(new_val)
            for _, cb in ipairs(_callbacks[id] or {}) do
                pcall(cb, new_val)
            end
        end)
    end
end

function M.flush() end
function M.mark_dirty() end

return M

end)()

-- ── core/feature_bind.lua ──
April._mods["core.feature_bind"] = (function()
--[[
    Legacy Fallen keybinds — Toggle / Hold via menu combo + manual key polling.
    Vector's built-in checkbox Hold/Toggle modes are disabled (show_mode = false).
]]

local settings = April.require("core.settings")

local M = {}

M.MODES = { "Toggle", "Hold" }

local registry = {}
local last_down = {}

function M.register(spec)
    if not spec or not spec.id then return end
    registry[spec.id] = {
        id = spec.id,
        mode_id = spec.mode_id or (spec.id .. "_mode"),
        key_id = spec.key_id or spec.id,
    }
end

function M.is_registered(id)
    return registry[id] ~= nil
end

function M.get_key(id)
    local e = registry[id]
    local key_id = e and e.key_id or id
    if menu and menu.get_key then
        local k = menu.get_key(key_id)
        if k and k > 0 then return k end
    end
    return 0
end

function M.is_hold(id)
    local e = registry[id]
    if not e then return false end
    return settings.combo_index(e.mode_id, M.MODES, 0) == 1
end

function M.armed(id)
    return settings.bool(id, false)
end

function M.active(id)
    if not registry[id] then
        return settings.bool(id, false)
    end

    if M.is_hold(id) then
        if not M.armed(id) then return false end
        local key = M.get_key(id)
        if key <= 0 then return false end
        return input and input.is_key_down and input.is_key_down(key)
    end

    return M.armed(id)
end

function M.tick()
    if not input or not input.is_key_down then return end

    for id in pairs(registry) do
        if M.is_hold(id) then
            last_down[id] = input.is_key_down(M.get_key(id))
            goto continue
        end

        local key = M.get_key(id)
        if key <= 0 then goto continue end

        local down = input.is_key_down(key)
        if down and not last_down[id] then
            local cur = settings.bool(id, false)
            if menu and menu.set then
                pcall(menu.set, id, not cur)
            end
            pcall(function()
                April.require("core.menu_util").sync_master(id)
            end)
        end
        last_down[id] = down

        ::continue::
    end
end

return M

end)()

-- ── core/draw_util.lua ──
April._mods["core.draw_util"] = (function()
local math_util = April.require("core.math_util")
local text_util = April.require("core.text_util")
local settings = April.require("core.settings")

local M = {}

function M.white(r, g, b, a)
    return { r or 1, g or 1, b or 1, a or 1 }
end

function M.text_centered(x, y, text, col, size)
    if not draw or not draw.text or not draw.get_text_size then return end
    text = text_util.sanitize(text)
    local tw, th = draw.get_text_size(text, size or 14)
    draw.text(x - tw * 0.5, y, text, col, size or 14)
end

function M.text_outlined(x, y, text, col, size)
    if not draw or not draw.text then return end
    draw.text(x, y, text_util.sanitize(text), col, size or 14)
end

function M.text(x, y, text, col, size)
    M.text_outlined(x, y, text, col, size)
end

function M.box_esp(x, y, w, h, col, style)
    if settings and settings.enabled and settings.enabled("april_brainrot_enabled") then
        return
    end
    if not draw then return end
    if style == 1 and draw.corner_box then
        draw.corner_box(x, y, w, h, col)
        return
    end
    if draw.box then
        draw.box(x, y, w, h, col, 0, style or 0)
    end
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

-- ── core/ui_theme.lua ──
April._mods["core.ui_theme"] = (function()
--[[ Project Vector — shared overlay / HUD theme (matches main cheat menu). ]]

local draw_util = April.require("core.draw_util")
local text_util = April.require("core.text_util")

local M = {}

-- #0D0D0D base, #00C3E3 cyan accent
M.BG          = { 13 / 255, 13 / 255, 13 / 255, 0.94 }
M.PANEL       = { 18 / 255, 18 / 255, 20 / 255, 0.92 }
M.PANEL_DEEP  = { 10 / 255, 10 / 255, 12 / 255, 0.90 }
M.SLOT        = { 22 / 255, 22 / 255, 24 / 255, 0.82 }
M.SLOT_HELD   = { 28 / 255, 28 / 255, 30 / 255, 0.90 }
M.SLOT_EMPTY  = { 14 / 255, 14 / 255, 16 / 255, 0.55 }

M.CYAN        = { 0, 195 / 255, 227 / 255, 1 }
M.CYAN_SOFT   = { 0, 195 / 255, 227 / 255, 0.35 }
M.CYAN_GLOW   = { 0, 195 / 255, 227 / 255, 0.18 }

M.TEXT        = { 1, 1, 1, 0.96 }
M.TEXT_DIM    = { 128 / 255, 128 / 255, 128 / 255, 0.95 }
M.TEXT_MUTED  = { 0.62, 0.64, 0.68, 0.88 }

M.BORDER      = { 1, 1, 1, 0.08 }
M.BORDER_CYAN = { 0, 195 / 255, 227 / 255, 0.45 }

M.RED         = { 1, 0.35, 0.35, 1 }
M.ORANGE      = { 1, 0.55, 0.22, 1 }
M.PURPLE      = { 0.92, 0.45, 1, 1 }
M.GREEN       = { 0.35, 0.85, 0.55, 1 }

M.ROUND       = 4
M.MAP_BG      = { 13 / 255, 13 / 255, 13 / 255, 0.95 }
M.MAP_GRID    = { 0, 195 / 255, 227 / 255, 0.06 }

function M.alpha(col, a)
    return { col[1], col[2], col[3], a }
end

function M.text_w(text, size)
    if draw and draw.get_text_size then
        return draw.get_text_size(text, size or 13)
    end
    return (#text * (size or 13) * 0.55), size or 13
end

function M.draw_panel(x, y, w, h, opts)
    if not draw then return end
    opts = opts or {}

    local bg = opts.bg or M.PANEL
    local border = opts.border or M.BORDER
    local rounding = opts.rounding ~= nil and opts.rounding or M.ROUND

    if draw.rect_filled then
        draw.rect_filled(x, y, w, h, bg, rounding)
    end
    if draw.rect then
        draw.rect(x, y, w, h, border, rounding, opts.border_w or 1)
    end

    if opts.accent and draw.line then
        local ax = x + (rounding > 0 and 1 or 0)
        local aw = w - (rounding > 0 and 2 or 0)
        draw.line(ax, y, ax + aw, y, opts.accent, opts.accent_w or 2)
    end

    if opts.accent_left and draw.line then
        draw.line(x, y + 1, x, y + h - 1, opts.accent_left, opts.accent_w or 2)
    end
end

function M.draw_section_title(x, y, title, col)
    col = col or M.CYAN
    draw_util.text(x, y, title, col, 13)
end

function M.draw_tooltip_box(x, y, lines)
    if not draw or not lines or #lines == 0 then return end
    lines = type(lines) == "table" and lines or { tostring(lines) }

    local fs = 12
    local pad = 8
    local tw = 0
    for i = 1, #lines do
        local w = select(1, M.text_w(lines[i], fs))
        if w > tw then tw = w end
    end

    local box_w = tw + pad * 2
    local box_h = #lines * 14 + pad * 2
    local sw = select(1, draw_util.screen_size())
    x = math.min(x, sw - box_w - 12)
    y = math.max(y, 8)

    M.draw_panel(x, y, box_w, box_h, {
        bg = M.alpha(M.PANEL, 0.96),
        accent = M.CYAN,
        rounding = M.ROUND,
    })

    for i = 1, #lines do
        local col = (i == 1) and M.TEXT or M.TEXT_MUTED
        draw_util.text(x + pad, y + pad + (i - 1) * 14, lines[i], col, fs)
    end
end

function M.toast_accent(ntype)
    if ntype == "danger" then return M.RED end
    if ntype == "warning" then return M.ORANGE end
    if ntype == "success" then return M.CYAN end
    return M.CYAN
end

function M.role_accent(role)
    if not role then return M.CYAN end
    local r = role:lower()
    if r:find("founder") or r:find("developer") then return M.PURPLE end
    if r:find("moderator") then return M.RED end
    return M.CYAN
end

function M.draw_mod_marker(sx, sy, image_cache, icon_key)
    if not draw or not draw.text then return end

    local label = "MOD"
    local fs = 11
    local icon_size = 14
    local gap = 4
    local pad_x, pad_y = 6, 4
    local tw = select(1, M.text_w(label, fs))
    local w = pad_x * 2 + icon_size + gap + tw
    local h = pad_y * 2 + math.max(icon_size, fs + 2)
    local x = math.floor(sx - w * 0.5)
    local y = math.floor(sy - h - 8)

    M.draw_panel(x, y, w, h, {
        bg = M.alpha(M.BG, 0.86),
        border = M.alpha(M.BORDER, 0.35),
        accent = M.RED,
        accent_w = 2,
        rounding = 3,
    })

    if image_cache and icon_key then
        image_cache.begin_load(icon_key)
        image_cache.draw_fit(icon_key, x + pad_x, y + pad_y, icon_size, icon_size)
    end

    draw.text(
        x + pad_x + icon_size + gap,
        y + pad_y + 1,
        label,
        M.RED,
        fs
    )
end

function M.draw_staff_list(x, y, width, rows, max_rows)
    if not draw or not draw.text or not rows or #rows == 0 then return end

    max_rows = max_rows or 4
    local pad = 10
    local title_h = 24
    local row_h = 44
    local count = math.min(#rows, max_rows)
    local height = title_h + count * row_h + 6

    M.draw_panel(x, y, width, height, {
        bg = M.alpha(M.BG, 0.90),
        border = M.alpha(M.BORDER, 0.45),
        accent = M.RED,
        accent_w = 2,
        rounding = M.ROUND,
    })

    draw_util.text(x + pad, y + 6, "Staff In Lobby", M.TEXT, 12)

    local div_y = y + title_h
    if draw.line then
        draw.line(x + pad, div_y, x + width - pad, div_y, M.alpha(M.BORDER, 0.55), 1)
    end

    local ry = div_y + 6
    for i = 1, count do
        local row = rows[i]
        local accent = row.accent or M.role_accent(row.role)

        if i > 1 and draw.line then
            draw.line(x + pad, ry - 4, x + width - pad, ry - 4, M.alpha(M.BORDER, 0.22), 1)
        end

        if draw.circle_filled then
            draw.circle_filled(x + pad + 3, ry + 7, 3, accent, 8)
        end

        local name = text_util.sanitize(row.name or "?")
        if #name > 20 then name = name:sub(1, 18) .. ".." end
        draw.text(x + pad + 12, ry, name, M.TEXT, 13)

        local role = text_util.sanitize(row.role or "Staff")
        if #role > 24 then role = role:sub(1, 22) .. ".." end
        draw.text(x + pad + 12, ry + 15, role, accent, 11)

        if row.meta and row.meta ~= "" then
            draw.text(x + pad + 12, ry + 28, text_util.sanitize(row.meta), M.TEXT_MUTED, 10)
        end

        ry = ry + row_h
    end
end

return M

end)()

-- ── core/notify.lua ──
April._mods["core.notify"] = (function()
--[[ Toast notifications — Project Vector themed HUD toasts. ]]

local draw_util = April.require("core.draw_util")
local theme = April.require("core.ui_theme")
local text_util = April.require("core.text_util")

local M = {}
local queue = {}

local function tick()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

function M.show(msg, ntype, duration_ms)
    M.toast(msg, ntype, duration_ms, false)
end

function M.toast(msg, ntype, duration_ms, skip_dedupe)
    if not msg or msg == "" then return end
    msg = text_util.sanitize(msg)
    ntype = ntype or "warning"
    duration_ms = duration_ms or 5000

    if not skip_dedupe then
        for _, n in ipairs(queue) do
            if n.msg == msg and (tick() - n.time) < 3000 then return end
        end
    end

    if menu and menu.notify then
        pcall(function() menu.notify(msg) end)
    end

    table.insert(queue, {
        msg = msg,
        type = ntype,
        time = tick(),
        duration = duration_ms,
        alpha = 0,
        x_off = 80,
        y = 0,
    })

    while #queue > 6 do
        table.remove(queue, 1)
    end
end

function M.warning(msg, duration_ms)
    M.show(msg, "warning", duration_ms)
end

function M.success(msg, duration_ms)
    M.show(msg, "success", duration_ms)
end

function M.error(msg, duration_ms)
    M.show(msg, "danger", duration_ms)
end

function M.info(msg, duration_ms)
    M.show(msg, "info", duration_ms)
end

function M.draw()
    if #queue == 0 or not draw then return end

    local now = tick()
    local font = 13
    local pad = 12
    local gap = 8
    local target_y = 18

    for i = #queue, 1, -1 do
        local n = queue[i]
        local elapsed = now - n.time
        if elapsed > n.duration then
            table.remove(queue, i)
        else
            local fade = 350
            local target_alpha = 1
            if elapsed < fade then
                target_alpha = elapsed / fade
            elseif elapsed > n.duration - fade then
                target_alpha = (n.duration - elapsed) / fade
            end
            n.alpha = lerp(n.alpha or 0, target_alpha, 0.18)

            local slide = 0
            if elapsed > n.duration - fade then slide = 60 end
            n.x_off = lerp(n.x_off or 80, slide, 0.15)

            if n.y == 0 then n.y = target_y end
            n.y = lerp(n.y, target_y, 0.2)

            local accent = theme.toast_accent(n.type)
            local tw = select(1, theme.text_w(n.msg, font))
            local box_w = tw + pad * 2 + 4
            local box_h = font + pad * 2
            local sw = select(1, draw_util.screen_size())
            local x = sw - box_w - 16 + (n.x_off or 0)
            local y = n.y
            local a = n.alpha or 1

            theme.draw_panel(x, y, box_w, box_h, {
                bg = theme.alpha(theme.PANEL, 0.94 * a),
                border = theme.alpha(theme.BORDER_CYAN, 0.55 * a),
                accent = theme.alpha(accent, a),
                accent_w = 2,
                rounding = theme.ROUND,
            })

            if draw.text then
                draw.text(x + pad, y + pad - 1, n.msg, theme.alpha(theme.TEXT, a), font)
            end

            target_y = target_y + box_h + gap
        end
    end
end

return M

end)()

-- ── game/asset_urls.lua ──
April._mods["game.asset_urls"] = (function()
--[[
    One HTTPS URL per asset — April/docs/API.md Images section.
    API example: draw.load_image("https://raw.githubusercontent.com/user/repo/main/icon.png")
    Assets: https://github.com/Cunzaki/April/tree/main/assets
]]

local M = {}

M.CDN_BASE = "https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/assets"

local function digits(id)
    return id and tostring(id):match("(%d+)")
end

function M.roblox_thumb(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return string.format(
        "https://www.roblox.com/Thumbs/Asset.ashx?width=420&height=420&assetId=%s",
        asset_id
    )
end

function M.item_png(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return M.CDN_BASE .. "/items/" .. asset_id .. ".png"
end

function M.tung_png()
    return M.CDN_BASE .. "/tung.png"
end

function M.brainrot_png(file)
    if not file or file == "" then return nil end
    return M.CDN_BASE .. "/brainrot/" .. file .. ".png"
end

function M.mod_warning_png()
    return M.CDN_BASE .. "/mod_warning.png"
end

return M

end)()

-- ── core/image_cache.lua ──
April._mods["core.image_cache"] = (function()
--[[
    Image loader — Vector on_frame pattern (working reference):
      cam_icon = draw.load_image(url)   -- once, first frame
      if draw.image_failed(cam_icon) then return end
      draw.image(cam_icon, x, y, w, h, 255, 255, 255, 255)  -- every frame; no-ops until ready
]]

local asset_urls = April.require("game.asset_urls")
local debug = April.require("core.debug")

local M = {}

local keys = {}

local function url_for(asset_id_or_url)
    if type(asset_id_or_url) == "string" and asset_id_or_url:find("https://", 1, true) then
        return asset_id_or_url
    end
    return asset_urls.item_png(asset_id_or_url)
end

function M.ensure(key, asset_id_or_url)
    if keys[key] then return keys[key] end
    local url = url_for(asset_id_or_url)
    if not url then return nil end
    local asset_id = type(asset_id_or_url) == "number" and asset_id_or_url
        or (type(asset_id_or_url) == "string" and asset_id_or_url:match("^(%d+)$"))
    keys[key] = {
        url = url,
        asset_id = asset_id and tostring(asset_id) or nil,
        handle = nil,
        failed = false,
        fallback = false,
    }
    return keys[key]
end

function M.register(key, asset_id_or_url)
    return M.ensure(key, asset_id_or_url)
end

local function try_fallback(entry)
    if entry.fallback or not entry.asset_id then return false end
    local fb = asset_urls.roblox_thumb(entry.asset_id)
    if not fb or fb == entry.url then return false end
    entry.fallback = true
    entry.url = fb
    entry.handle = nil
    entry.failed = false
    entry.just_loaded = nil
    return true
end

local function get_handle(key)
    local entry = keys[key]
    if not entry or entry.failed or not draw or not draw.load_image then
        return nil
    end

    if not entry.handle then
        entry.handle = draw.load_image(entry.url)
        return nil
    end

    if draw.image_failed and draw.image_failed(entry.handle) then
        if try_fallback(entry) then
            return nil
        end
        debug.warn_once("img:" .. key, "load failed - " .. entry.url)
        entry.failed = true
        entry.handle = nil
        return nil
    end

    return entry.handle
end

local function draw_image(handle, x, y, w, h, col)
    if col and type(col) == "table" then
        local r = math.floor((col[1] or 1) * 255)
        local g = math.floor((col[2] or 1) * 255)
        local b = math.floor((col[3] or 1) * 255)
        local a = math.floor((col[4] or 1) * 255)
        draw.image(handle, x, y, w, h, r, g, b, a)
    else
        draw.image(handle, x, y, w, h, 255, 255, 255, 255)
    end
end

function M.draw_fit(key, x, y, w, h, col)
    if not draw or not draw.image then return false end

    local handle = get_handle(key)
    if not handle then return false end

    w = math.max(w or 0, 8)
    h = math.max(h or 0, 8)
    draw_image(handle, x, y, w, h, col)
    return true
end

function M.state(key)
    local entry = keys[key]
    if not entry then return "none" end
    if entry.failed then return "failed" end
    if not entry.handle then return "loading" end
    if draw and draw.image_failed and draw.image_failed(entry.handle) then
        if try_fallback(entry) then
            return "loading"
        end
        entry.failed = true
        entry.handle = nil
        return "failed"
    end
    return "ready"
end

function M.is_ready(key)
    return M.state(key) == "ready"
end

function M.preload(key, asset_id_or_url)
    M.ensure(key, asset_id_or_url)
    get_handle(key)
end

function M.begin_load(key)
    if not key then return end
    get_handle(key)
end

function M.draw_at_world(key, wx, wy, wz, size)
    if not draw or not draw.image or not utility or not utility.world_to_screen then
        return false
    end

    local handle = get_handle(key)
    if not handle then return false end

    local sx, sy, vis = utility.world_to_screen(wx, wy, wz)
    if not vis then return false end

    size = size or 64
    local hs = math.floor(size * 0.5)
    draw.image(handle, sx - hs, sy - hs, size, size, 255, 255, 255, 255)
    return true
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

function M.model_screen_bounds(model)
    if not model then return nil end
    local env = April.require("core.env")
    if not env.is_valid(model) then return nil end

    local part_names = {
        "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso",
        "LeftFoot", "RightFoot", "Left Leg", "Right Leg",
    }

    local min_x, min_y, max_x, max_y
    local any = false

    for i = 1, #part_names do
        local name = part_names[i]
        local part = env.safe_call(function()
            return model:find_first_child(name) or model:FindFirstChild(name)
        end)
        if part and env.is_valid(part) then
            local pos = part.Position or part.position
            if pos and pos.x then
                local sx, sy, vis = M.w2s(pos.x, pos.y, pos.z)
                if vis then
                    any = true
                    min_x = min_x and math.min(min_x, sx) or sx
                    min_y = min_y and math.min(min_y, sy) or sy
                    max_x = max_x and math.max(max_x, sx) or sx
                    max_y = max_y and math.max(max_y, sy) or sy
                end
            end
        end
    end

    if not any then return nil end

    local w = math.max(8, max_x - min_x)
    local h = math.max(12, max_y - min_y)
    return { x = min_x, y = min_y, w = w, h = h, valid = true }
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

function M.draw_vertical_beacon(wx, wy, wz, col, opts)
    opts = opts or {}
    local height = opts.height or 90
    local steps = opts.steps or 10
    local prev_sx, prev_sy, prev_vis

    for i = 0, steps do
        local py = wy + (height * i / steps)
        local sx, sy, vis = M.w2s(wx, py, wz)
        if i > 0 and vis and prev_vis and draw and draw.line then
            local alpha = (col[4] or 1) * (0.35 + 0.65 * (i / steps))
            draw.line(prev_sx, prev_sy, sx, sy, { col[1], col[2], col[3], alpha }, opts.thickness or 2)
        end
        prev_sx, prev_sy, prev_vis = sx, sy, vis
    end

    if prev_vis and draw and draw.circle_filled then
        draw.circle_filled(prev_sx, prev_sy, opts.marker_r or 4, col, 12)
    end
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

local BOX_EDGES = {
    { 1, 2 }, { 1, 3 }, { 2, 4 }, { 3, 4 },
    { 5, 6 }, { 5, 7 }, { 6, 8 }, { 7, 8 },
    { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 },
}

local BOX_SIGNS = {
    { -1, -1, -1 }, { 1, -1, -1 }, { -1, 1, -1 }, { 1, 1, -1 },
    { -1, -1, 1 }, { 1, -1, 1 }, { -1, 1, 1 }, { 1, 1, 1 },
}

function M.draw_world_line(x1, y1, z1, x2, y2, z2, col, thick)
    if not draw then return false end
    local sx1, sy1, v1 = M.w2s(x1, y1, z1)
    local sx2, sy2, v2 = M.w2s(x2, y2, z2)
    if v1 or v2 then
        draw_util.line(sx1, sy1, sx2, sy2, col, thick or 2)
        return true
    end
    return false
end

function M.draw_world_cross(wx, wy, wz, size, col, thick)
    if not camera or not camera.get_look_vector then return end

    local look = camera.get_look_vector()
    if not look then return end

    local lx = look.x or look.X or 0
    local ly = look.y or look.Y or 0
    local lz = look.z or look.Z or 0
    local mag = math.sqrt(lx * lx + ly * ly + lz * lz)
    if mag < 0.001 then return end
    lx, ly, lz = lx / mag, ly / mag, lz / mag

    local ux, uy, uz = 0, 1, 0
    local rx = uy * lz - uz * ly
    local ry = uz * lx - ux * lz
    local rz = ux * ly - uy * lx
    local rm = math.sqrt(rx * rx + ry * ry + rz * rz)
    if rm < 0.001 then
        ux, uy, uz = 0, 0, 1
        rx = uy * lz - uz * ly
        ry = uz * lx - ux * lz
        rz = ux * ly - uy * lx
        rm = math.sqrt(rx * rx + ry * ry + rz * rz)
    end
    if rm < 0.001 then return end
    rx, ry, rz = rx / rm, ry / rm, rz / rm

    ux = ly * rz - lz * ry
    uy = lz * rx - lx * rz
    uz = lx * ry - ly * rx
    local um = math.sqrt(ux * ux + uy * uy + uz * uz)
    if um < 0.001 then return end
    ux, uy, uz = ux / um, uy / um, uz / um

    size = size or 0.35
    thick = thick or 2
    local s = size * 0.5

    M.draw_world_line(
        wx - rx * s - ux * s, wy - ry * s - uy * s, wz - rz * s - uz * s,
        wx + rx * s + ux * s, wy + ry * s + uy * s, wz + rz * s + uz * s,
        col, thick
    )
    M.draw_world_line(
        wx - rx * s + ux * s, wy - ry * s + uy * s, wz - rz * s + uz * s,
        wx + rx * s - ux * s, wy + ry * s - uy * s, wz + rz * s - uz * s,
        col, thick
    )
end

function M.draw_oriented_box(box, col, thick)
    if not box or not draw or not draw.line then return end
    thick = thick or 1

    local corners = {}
    for i = 1, 8 do
        local sx, sy, sz = BOX_SIGNS[i][1], BOX_SIGNS[i][2], BOX_SIGNS[i][3]
        local lx, ly, lz = sx * box.hx, sy * box.hy, sz * box.hz
        local wx = box.x + box.rx * lx + box.ux * ly - box.lx * lz
        local wy = box.y + box.ry * lx + box.uy * ly - box.ly * lz
        local wz = box.z + box.rz * lx + box.uz * ly - box.lz * lz
        corners[i] = { wx, wy, wz }
    end

    local screen = {}
    for i = 1, 8 do
        local c = corners[i]
        local sx, sy, vis = M.w2s(c[1], c[2], c[3])
        if vis then screen[i] = { x = sx, y = sy } end
    end

    for _, edge in ipairs(BOX_EDGES) do
        local a, b = screen[edge[1]], screen[edge[2]]
        if a and b then
            draw_util.line(a.x, a.y, b.x, b.y, col, thick)
        end
    end
end

function M.draw_entry_boxes(entry, col, thick)
    if settings.enabled("april_brainrot_enabled") then return end
    if not entry or not entry.inst then return end
    if entry.box then
        M.draw_oriented_box(entry.box, col, thick)
        return
    end
    local scan = April.require("game.esp_scan")
    local main = entry.main_part or scan.find_main_part(entry.inst)
    local box = scan.read_part_box(main)
    if box then
        entry.box = box
        M.draw_oriented_box(box, col, thick)
    end
end

function M.oriented_box_screen_bounds(box)
    if not box then return nil end

    local min_x, min_y, max_x, max_y
    local any = false

    for i = 1, 8 do
        local sx, sy, sz = BOX_SIGNS[i][1], BOX_SIGNS[i][2], BOX_SIGNS[i][3]
        local lx, ly, lz = sx * box.hx, sy * box.hy, sz * box.hz
        local wx = box.x + box.rx * lx + box.ux * ly - box.lx * lz
        local wy = box.y + box.ry * lx + box.uy * ly - box.ly * lz
        local wz = box.z + box.rz * lx + box.uz * ly - box.lz * lz
        local px, py, vis = M.w2s(wx, wy, wz)
        if vis then
            any = true
            min_x = min_x and math.min(min_x, px) or px
            min_y = min_y and math.min(min_y, py) or py
            max_x = max_x and math.max(max_x, px) or px
            max_y = max_y and math.max(max_y, py) or py
        end
    end

    if not any then return nil end

    return {
        x = min_x,
        y = min_y,
        w = math.max(12, max_x - min_x),
        h = math.max(12, max_y - min_y),
        valid = true,
    }
end

function M.point_screen_bounds(wx, wy, wz, size)
    local sx, sy, vis = M.w2s(wx, wy, wz)
    if not vis then return nil end
    size = size or 48
    return {
        x = sx - size * 0.5,
        y = sy - size * 0.5,
        w = size,
        h = size,
        valid = true,
    }
end

function M.entry_screen_bounds(entry)
    if not entry then return nil end

    if entry.box then
        local bounds = M.oriented_box_screen_bounds(entry.box)
        if bounds then return bounds end
    end

    if entry.inst then
        local scan = April.require("game.esp_scan")
        local main = entry.main_part or scan.find_main_part(entry.inst)
        if main then
            local box = scan.read_part_box(main)
            if box then
                entry.box = box
                local bounds = M.oriented_box_screen_bounds(box)
                if bounds then return bounds end
            end
        end
    end

    local esp_scan = April.require("game.esp_scan")
    local lx, ly, lz = esp_scan.entry_coords(entry)
    if lx then
        return M.point_screen_bounds(lx, ly, lz, 52)
    end

    return nil
end

return M

end)()

-- ── core/scheduler.lua ──
April._mods["core.scheduler"] = (function()
local debug = April.require("core.debug")

local M = {}
local jobs = {}

function M.register(id, interval_ms, fn, when)
    jobs[id] = {
        id = id,
        interval = interval_ms,
        fn = fn,
        last = 0,
        when = when,
    }
end

function M.tick()
    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    for id, job in pairs(jobs) do
        if job.when then
            local ok, pass = pcall(job.when)
            if not ok or not pass then
                goto continue
            end
        end
        if now - job.last >= job.interval then
            job.last = now
            debug.guard("scan:" .. id, job.fn)
        end
        ::continue::
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

-- ── core/incremental_scan.lua ──
April._mods["core.incremental_scan"] = (function()
--[[ Time-budgeted ESP scans — spread work across frames to avoid stutter spikes. ]]

local debug = April.require("core.debug")

local M = {}

local jobs = {}
local BUDGET_MS = 5
local ITEMS_PER_STEP = 16
local MAX_STARTS_PER_TICK = 1
local starts_this_tick = 0

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.configure(opts)
    if not opts then return end
    if opts.budget_ms then BUDGET_MS = opts.budget_ms end
    if opts.items_per_step then ITEMS_PER_STEP = opts.items_per_step end
end

function M.register(id, interval_ms, when_fn, create_state_fn, step_fn, complete_fn, phase_ms)
    jobs[id] = {
        id = id,
        interval = interval_ms,
        last_done = tick_ms() - (interval_ms - (phase_ms or 0)),
        when = when_fn,
        create_state = create_state_fn,
        step = step_fn,
        complete = complete_fn,
        active = false,
        state = nil,
    }
end

function M.is_active(id)
    local job = jobs[id]
    return job and job.active == true
end

function M.force(id)
    local job = jobs[id]
    if not job then return end
    job.last_done = 0
    job.active = false
    job.state = nil
end

function M.tick()
    starts_this_tick = 0
    local budget_left = BUDGET_MS
    local now = tick_ms()

    for id, job in pairs(jobs) do
        if budget_left <= 0 then break end

        if job.when then
            local ok, pass = pcall(job.when)
            if not ok or not pass then
                job.active = false
                job.state = nil
                goto continue
            end
        end

        if job.active and job.state then
            while budget_left > 0 do
                local t0 = tick_ms()
                local ok, done = pcall(job.step, job.state, ITEMS_PER_STEP)
                if not ok then
                    debug.error_once("iscan:" .. id, done)
                    job.active = false
                    job.state = nil
                    job.last_done = now
                    break
                end

                budget_left = budget_left - (tick_ms() - t0)

                if done then
                    pcall(job.complete, job.state)
                    job.active = false
                    job.state = nil
                    job.last_done = now
                    break
                end

                if budget_left <= 0 then break end
            end
        elseif now - job.last_done >= job.interval and starts_this_tick < MAX_STARTS_PER_TICK then
            job.state = job.create_state and job.create_state() or {}
            job.active = true
            starts_this_tick = starts_this_tick + 1
        end

        ::continue::
    end
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
    SILENT_AIM = "Silent Aim",
    GUN_MODS = "Gun Mods",
    VISUALS = "Visuals",
    WORLD = "World",
    RADAR = "Radar",
    MISC = "Misc",
    CONFIG = "Config",
}

M.G_SIDE = {
    [M.G.SILENT_AIM] = "left",
    [M.G.GUN_MODS] = "right",
    [M.G.VISUALS] = "left",
    [M.G.WORLD] = "right",
    [M.G.RADAR] = "left",
    [M.G.MISC] = "right",
    [M.G.CONFIG] = "left",
}

M._tab_ready = false
M._groups = {}
M._groups_ready = false
M._master_children = {}
M._master_hooked = {}
M._when_rules = {}

local function settings_mod()
    return April.require("core.settings")
end

function M.ensure_tab()
    if M._tab_ready then return end
    if not (April and April._menu_tab_ready) and menu and menu.add_tab then
        menu.add_tab(M.TAB, "A", "full")
    end
    M._tab_ready = true
end

--[[ Full-mode grid rows must be created left then right before any controls register. ]]
function M.ensure_groups()
    if M._groups_ready then return end
    M.ensure_tab()

    local rows = {
        { M.G.SILENT_AIM, M.G.GUN_MODS },
        { M.G.VISUALS, M.G.WORLD },
        { M.G.RADAR, M.G.MISC },
        { M.G.CONFIG },
    }

    for _, row in ipairs(rows) do
        M.group(row[1], "left")
        if row[2] then
            M.group(row[2], "right")
        end
    end

    M._groups_ready = true
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

function M.gap(T, G)
    menu.add_separator(T, G)
end

function M.section(T, G, title)
    menu.add_separator(T, G)
    if title and title ~= "" and menu.add_label then
        menu.add_label(T, G, title)
    end
end

function M.label(T, G, text)
    if menu and menu.add_label then
        menu.add_label(T, G, text)
    end
end

function M.input(T, G, id, label, default)
    if menu and menu.add_input then
        menu.add_input(T, G, id, label, default or "")
    end
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

local function add_child_ids(bucket, ids)
    bucket = bucket or {}
    local seen = {}
    for _, id in ipairs(bucket) do
        seen[id] = true
    end
    for _, id in ipairs(ids or {}) do
        if id and not seen[id] then
            seen[id] = true
            bucket[#bucket + 1] = id
        end
    end
    return bucket
end

local function set_visible(id, show)
    if menu and menu.set_visible and id then
        pcall(menu.set_visible, id, show)
    end
end

local function master_visible(master_id)
    local ok, fb = pcall(function()
        return April.require("core.feature_bind")
    end)
    if ok and fb and fb.is_registered(master_id) then
        return fb.armed(master_id)
    end
    return settings_mod().bool(master_id, false)
end

function M.sync_masters()
    for master_id in pairs(M._master_hooked) do
        local show = master_visible(master_id)
        for _, id in ipairs(M._master_children[master_id] or {}) do
            set_visible(id, show)
        end
    end
    for i = 1, #M._when_rules do
        local rule = M._when_rules[i]
        if rule.sync then rule.sync() end
    end
end

function M.sync_master(master_id)
    if not master_id or not M._master_hooked[master_id] then return end
    local show = master_visible(master_id)
    for _, id in ipairs(M._master_children[master_id] or {}) do
        set_visible(id, show)
    end
end

function M.bind_master(master_id, child_ids)
    if not master_id or not child_ids then return end
    M._master_children[master_id] = add_child_ids(M._master_children[master_id], child_ids)

    if M._master_hooked[master_id] then return end
    M._master_hooked[master_id] = true

    local function sync(new_val)
        local show
        if new_val == nil then
            show = master_visible(master_id)
        else
            show = new_val == true or new_val == 1
        end
        for _, id in ipairs(M._master_children[master_id] or {}) do
            set_visible(id, show)
        end
    end

    settings_mod().on_change(master_id, sync)
    sync()
end

function M.bind_when(when_fn, child_ids, watch_ids)
    if not when_fn or not child_ids then return end

    local rule = {
        fn = when_fn,
        ids = {},
    }
    rule.ids = add_child_ids(rule.ids, child_ids)

    local watch = {}
    for _, id in ipairs(watch_ids or {}) do
        watch[id] = true
    end
    rule.watch = watch

    M._when_rules[#M._when_rules + 1] = rule

    local function sync()
        local show = when_fn()
        for _, id in ipairs(rule.ids) do
            set_visible(id, show)
        end
    end

    rule.sync = sync
    sync()

    for id in pairs(watch) do
        settings_mod().on_change(id, sync)
    end
end

function M.button(T, G, id, label, callback, master_id)
    if menu and menu.add_button then
        menu.add_button(T, G, id, label, callback)
    end
    if master_id then
        M.bind_master(master_id, { id })
    end
end

--[[ Master toggle — key on checkbox row; Key Mode uses native parent only (no bind_master). ]]
function M.keybind_children(_id)
    return {}
end

function M.bind_children(master_id, extra_ids)
    M.bind_master(master_id, extra_ids or {})
end

function M.register_keybind(T, G, id, label, default, extra)
    extra = extra or {}
    local cb_opts = { show_mode = false, key = extra.key or 0 }
    if extra.parent then cb_opts.parent = extra.parent end
    if extra.colorpicker then cb_opts.colorpicker = extra.colorpicker end

    menu.add_checkbox(T, G, id, label, default or false, cb_opts)

    local mode_id = id .. "_mode"
    local mode_label = label .. " Bind Mode"
    menu.add_combo(T, G, mode_id, mode_label, { "Toggle", "Hold" }, 0, M.parent(id))

    April.require("core.feature_bind").register({
        id = id,
        mode_id = mode_id,
        key_id = id,
    })

    return mode_id
end

return M

end)()

-- ── core/silent_ray.lua ──
April._mods["core.silent_ray"] = (function()
--[[ Silent raycast hook — matches Fallen MouseRaycast (UnitRay * 1024). ]]

local M = {}

local hook_ready = false
local tracking = false

-- Fallen RaycastUtil:MouseRaycast uses UnitRay.Direction * (p15 or 1024)
local MOUSE_RAY_LEN = 1024

M._last_origin = nil
M._last_target = nil
M._last_ok = false

local function unpack_pos(v)
    if not v then return nil end
    if v.x ~= nil then return v.x, v.y, v.z end
    if v.X ~= nil then return v.X, v.Y, v.Z end
    return nil
end

local function make_vec3(x, y, z)
    if Vector3 and Vector3.new then
        return Vector3.new(x, y, z)
    end
    return { x = x, y = y, z = z }
end

function M.available()
    return raycast
        and raycast.track_silent_target
        and raycast.stop_silent_tracking
end

function M.ensure_hook()
    if not M.available() then return false end
    if hook_ready or (raycast.is_silent_hook_active and raycast.is_silent_hook_active()) then
        hook_ready = true
        return true
    end
    if not raycast.enable_silent_hook then
        hook_ready = true
        return true
    end
    local ok = raycast.enable_silent_hook()
    hook_ready = ok == true
    return hook_ready
end

function M.is_tracking()
    return tracking
end

function M.last_ok()
    return M._last_ok
end

function M.get_camera_origin()
    if not camera or not camera.get_position then return nil end
    local ok, pos = pcall(camera.get_position)
    if not ok or not pos then return nil end
    local x, y, z = unpack_pos(pos)
    if not x then return nil end
    return { x = x, y = y, z = z }
end

function M.stop()
    M._last_origin = nil
    M._last_target = nil
    M._last_ok = false
    tracking = false
    if not M.available() then return end
    pcall(raycast.stop_silent_tracking)
    if raycast.clear_silent_target then
        pcall(raycast.clear_silent_target)
    end
end

function M.last_segment()
    return M._last_origin, M._last_target
end

--[[
    Fallen: MouseRaycast -> hit, muzzle fires toward hit.
    Silent hook replaces engine ray — peek manip uses peek eye as track origin.
]]
function M.track(origin, aim_point, shoot_vk)
    M._last_ok = false

    if not aim_point then
        return false
    end

    origin = origin or M.get_camera_origin()
    if not origin then
        return false
    end

    if not M.ensure_hook() then
        return false
    end

    local ox, oy, oz = unpack_pos(origin)
    local ax, ay, az = unpack_pos(aim_point)
    if not ox or not ax then
        return false
    end

    local dx, dy, dz = ax - ox, ay - oy, az - oz
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    if dist < 0.001 then
        return false
    end

    local inv = 1 / dist
    local dir = make_vec3(dx * inv * MOUSE_RAY_LEN, dy * inv * MOUSE_RAY_LEN, dz * inv * MOUSE_RAY_LEN)
    local origin_v = make_vec3(ox, oy, oz)
    local key = shoot_vk or 0x01

    M._last_origin = { x = ox, y = oy, z = oz }
    M._last_target = { x = ax, y = ay, z = az }

    local ok = raycast.track_silent_target(origin_v, dir, key) == true
    M._last_ok = ok
    tracking = ok
    return ok
end

return M

end)()

-- ── core/fflag_mem.lua ──
April._mods["core.fflag_mem"] = (function()
--[[ Fast FFlag writes via cached addresses + memory.write (fallback: fflag API). ]]

local M = {}

local cache = {}
local ready = false

local FLAG_DEFAULTS = {
    PhysicsSenderMaxBandwidthBps = 38760,
    DataSenderRate = 60,
    S2PhysicsSenderRate = 15,
}

local function can_mem()
    return memory and type(memory.write) == "function"
end

local function can_fflag()
    return fflag and type(fflag.set_value) == "function"
end

function M.available()
    return can_mem() or can_fflag()
end

function M.refresh()
    cache = {}
    ready = false
    if not fflag or not fflag.is_scanned or not fflag.is_scanned() then return end

    local ok, all = pcall(fflag.get_all)
    if ok and type(all) == "table" then
        for i = 1, #all do
            local e = all[i]
            if e and e.name and e.address and e.address > 0 then
                cache[e.name] = {
                    addr = e.address,
                    original = e.original or e.value,
                }
            end
        end
    end
    ready = next(cache) ~= nil
end

local function lookup(name)
    if cache[name] then return cache[name] end
    if not fflag or not fflag.find then return nil end
    local ok, hits = pcall(fflag.find, name)
    if ok and type(hits) == "table" and hits[1] and hits[1].address then
        local e = { addr = hits[1].address, original = hits[1].original or hits[1].value }
        cache[name] = e
        return e
    end
    return nil
end

function M.set_int(name, value)
    if not name then return false end
    if not ready then M.refresh() end

    local num = tonumber(value)
    if num == nil then return false end

    local e = lookup(name)
    if e and e.addr and can_mem() then
        local ok = pcall(memory.write, e.addr, "int32", num)
        if ok then return true end
    end

    if can_fflag() then
        return pcall(fflag.set_value, name, num) == true
    end
    return false
end

function M.reset(name)
    if not name then return false end
    local e = lookup(name)
    local orig = (e and e.original) or FLAG_DEFAULTS[name]
    if orig == nil then
        if fflag and fflag.reset_value then
            return pcall(fflag.reset_value, name)
        end
        return false
    end
    return M.set_int(name, orig)
end

function M.reset_defaults()
    M.set_int("PhysicsSenderMaxBandwidthBps", FLAG_DEFAULTS.PhysicsSenderMaxBandwidthBps)
    M.set_int("DataSenderRate", FLAG_DEFAULTS.DataSenderRate)
    M.set_int("S2PhysicsSenderRate", FLAG_DEFAULTS.S2PhysicsSenderRate)
end

return M

end)()

-- ── core/manip_math.lua ──
April._mods["core.manip_math"] = (function()
--[[ Peek / bullet manipulation visibility math (raycast-backed). ]]

local M = {}

local EYE_OFFSET_Y = 2.5
local DEFAULT_STEPS = 16
local MIN_RADIUS = 0.1
local MAX_RADIUS = 1

function M.eye_offset_y()
    return EYE_OFFSET_Y
end

function M.clamp_radius(radius)
    radius = tonumber(radius) or 1
    if radius < MIN_RADIUS then return MIN_RADIUS end
    if radius > MAX_RADIUS then return MAX_RADIUS end
    return math.floor(radius * 100 + 0.5) / 100
end

function M.is_visible_from(ox, oy, oz, tx, ty, tz)
    if not raycast or not raycast.is_visible then
        return true
    end
    local ex, ey, ez = ox, oy + EYE_OFFSET_Y, oz
    return raycast.is_visible(ex, ey, ez, tx, ty, tz) == true
end

function M.is_visible_from_pos(origin, target)
    if not origin or not target then return false end
    return M.is_visible_from(origin.x, origin.y, origin.z, target.x, target.y, target.z)
end

local function search_peek(origin, target_pos, max_radius, steps)
    max_radius = M.clamp_radius(max_radius)
    steps = steps or DEFAULT_STEPS

    for i = 0, steps - 1 do
        local angle = (i / steps) * math.pi * 2
        local cx = origin.x + math.cos(angle) * max_radius
        local cy = origin.y
        local cz = origin.z + math.sin(angle) * max_radius
        if M.is_visible_from(cx, cy, cz, target_pos.x, target_pos.y, target_pos.z) then
            return { x = cx, y = cy, z = cz }, max_radius
        end
    end

    return nil, max_radius
end

--[[ state: off | direct | ready | blocked ]]
function M.evaluate_manipulation(origin, target_pos, opts)
    opts = opts or {}

    if not origin or not target_pos then
        return { state = "blocked", peek = nil, radius = M.clamp_radius(opts.max_radius) }
    end

    if M.is_visible_from_pos(origin, target_pos) then
        return { state = "direct", peek = nil, radius = M.clamp_radius(opts.max_radius) }
    end

    local peek, radius = search_peek(origin, target_pos, opts.max_radius, opts.steps)
    if peek then
        return { state = "ready", peek = peek, radius = radius }
    end

    return { state = "blocked", peek = nil, radius = M.clamp_radius(opts.max_radius) }
end

function M.find_manipulation_position(origin, target_pos, opts)
    local ev = M.evaluate_manipulation(origin, target_pos, opts)
    if ev.state == "direct" then
        return { x = origin.x, y = origin.y, z = origin.z }
    end
    return ev.peek
end

function M.peek_track_origin(peek)
    if not peek then return nil end
    return {
        x = peek.x,
        y = peek.y + EYE_OFFSET_Y,
        z = peek.z,
    }
end

function M.ring_y(origin)
    if not origin then return 0 end
    return origin.y
end

function M.dist_sq(a, b)
    if not a or not b then return math.huge end
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return dx * dx + dy * dy + dz * dz
end

return M

end)()

-- ── core/desync_vis.lua ──
April._mods["core.desync_vis"] = (function()
--[[ Shared 3D desync / manipulation visualizer helpers. ]]

local esp_util = April.require("core.esp_util")
local draw_util = April.require("core.draw_util")

local M = {}

function M.draw_box(wx, wy, wz, size, col, thick)
    if not wx then return end
    size = size or 1.2
    thick = thick or 2
    local s = size

    esp_util.draw_world_line(wx - s, wy - s, wz - s, wx + s, wy - s, wz - s, col, thick)
    esp_util.draw_world_line(wx + s, wy - s, wz - s, wx + s, wy - s, wz + s, col, thick)
    esp_util.draw_world_line(wx + s, wy - s, wz + s, wx - s, wy - s, wz + s, col, thick)
    esp_util.draw_world_line(wx - s, wy - s, wz + s, wx - s, wy - s, wz - s, col, thick)
    esp_util.draw_world_line(wx - s, wy + s, wz - s, wx + s, wy + s, wz - s, col, thick)
    esp_util.draw_world_line(wx + s, wy + s, wz - s, wx + s, wy + s, wz + s, col, thick)
    esp_util.draw_world_line(wx + s, wy + s, wz + s, wx - s, wy + s, wz + s, col, thick)
    esp_util.draw_world_line(wx - s, wy + s, wz + s, wx - s, wy + s, wz - s, col, thick)
    esp_util.draw_world_line(wx - s, wy - s, wz - s, wx - s, wy + s, wz - s, col, thick)
    esp_util.draw_world_line(wx + s, wy - s, wz - s, wx + s, wy + s, wz - s, col, thick)
    esp_util.draw_world_line(wx + s, wy - s, wz + s, wx + s, wy + s, wz + s, col, thick)
    esp_util.draw_world_line(wx - s, wy - s, wz + s, wx - s, wy + s, wz + s, col, thick)
end

function M.draw_cross(wx, wy, wz, size, col, thick)
    if not wx then return end
    size = size or 1.5
    thick = thick or 2
    esp_util.draw_world_line(wx - size, wy, wz, wx + size, wy, wz, col, thick)
    esp_util.draw_world_line(wx, wy - size, wz, wx, wy + size, wz, col, thick)
    esp_util.draw_world_line(wx, wy, wz - size, wx, wy, wz + size, col, thick)
end

function M.draw_sphere_ring(wx, wy, wz, radius, col, thick)
    if not wx then return end
    radius = radius or 1.5
    thick = thick or 2
    local steps = 16
    local prev_sx, prev_sy, prev_vis
    for i = 0, steps do
        local a = (i / steps) * math.pi * 2
        local px = wx + math.cos(a) * radius
        local pz = wz + math.sin(a) * radius
        local sx, sy, vis = esp_util.w2s(px, wy, pz)
        if vis and prev_vis then
            draw_util.line(prev_sx, prev_sy, sx, sy, col, thick)
        end
        prev_sx, prev_sy, prev_vis = sx, sy, vis
    end
end

function M.draw_link(a, b, col, thick)
    if not a or not b then return end
    esp_util.draw_world_line(a.x, a.y, a.z, b.x, b.y, b.z, col, thick or 2)
end

function M.draw_labeled(wx, wy, wz, label, col, size)
    if not wx or not label then return end
    local sx, sy, vis = esp_util.w2s(wx, wy + 2, wz)
    if vis then
        draw_util.text_centered(sx, sy, label, col, size or 13)
    end
end

function M.draw_mode(mode, wx, wy, wz, size, col, thick)
    mode = mode or 0
    if mode == 1 then
        M.draw_cross(wx, wy, wz, size, col, thick)
    elseif mode == 2 then
        M.draw_sphere_ring(wx, wy, wz, size, col, thick)
    else
        M.draw_box(wx, wy, wz, size, col, thick)
    end
end

function M.draw_server_local(server, local_pos, opts)
    if not server or not local_pos then return end
    opts = opts or {}

    local mode = opts.mode or 0
    local size = opts.size or 1.2
    local col_server = opts.col_server or { 0.2, 0.85, 1, 0.9 }
    local col_local = opts.col_local or { 1, 0.35, 0.35, 0.9 }
    local col_link = opts.col_link or { 1, 1, 1, 0.4 }
    local server_label = opts.server_label or "SERVER"
    local local_label = opts.local_label or "LOCAL"

    M.draw_mode(mode, server.x, server.y, server.z, size, col_server, 2)
    M.draw_mode(mode, local_pos.x, local_pos.y, local_pos.z, size * 0.85, col_local, 2)

    if opts.link ~= false then
        M.draw_link(server, local_pos, col_link, 2)
    end

    if opts.labels then
        M.draw_labeled(server.x, server.y, server.z, server_label, col_server, 12)
        M.draw_labeled(local_pos.x, local_pos.y, local_pos.z, local_label, col_local, 12)
    end
end

return M

end)()

-- ── core/packet_desync.lua ──
April._mods["core.packet_desync"] = (function()
--[[ Movement-only packet desync (shared by desync, freecam, bullet manip). ]]

local fflag_mem = April.require("core.fflag_mem")

local M = {}

local active_count = 0

function M.apply_movement_only()
    active_count = active_count + 1
    pcall(fflag_mem.refresh)
    fflag_mem.set_int("S2PhysicsSenderRate", 0)
    fflag_mem.set_int("PhysicsSenderMaxBandwidthBps", 0)
    fflag_mem.set_int("DataSenderRate", 60)
end

function M.release()
    active_count = math.max(0, active_count - 1)
    if active_count == 0 then
        fflag_mem.reset_defaults()
    end
end

function M.force_reset()
    active_count = 0
    fflag_mem.reset_defaults()
end

function M.is_active()
    return active_count > 0
end

return M

end)()

-- ── core/cframe_move.lua ──
April._mods["core.cframe_move"] = (function()
--[[ Movement helpers — position nudge + velocity (no WalkSpeed writes). ]]

local env = April.require("core.env")

local M = {}

local BASE_PARTS = {
    Part = true, MeshPart = true, UnionOperation = true,
    WedgePart = true, CornerWedgePart = true, TrussPart = true,
}

local NOCLIP_PARTS = {
    "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso", "Head",
}

local HIP_OFFSET = 3.0

function M.delta_time()
    if utility and utility.get_delta_time then
        local dt = utility.get_delta_time()
        if dt and dt > 0 and dt <= 0.1 then return dt end
    end
    return 0.016
end

function M.key_down(code)
    return input and input.is_key_down and input.is_key_down(code)
end

function M.read_pos(inst)
    if not inst then return nil end
    local pos = inst.Position or inst.position
    if not pos then return nil end
    return {
        x = pos.X or pos.x or 0,
        y = pos.Y or pos.y or 0,
        z = pos.Z or pos.z or 0,
    }
end

function M.read_velocity(inst)
    if not inst then return 0, 0, 0 end
    local vel = inst.AssemblyLinearVelocity or inst.Velocity or inst.velocity
    if not vel then return 0, 0, 0 end
    return vel.X or vel.x or 0, vel.Y or vel.y or 0, vel.Z or vel.z or 0
end

function M.is_base_part(inst)
    if not inst then return false end
    if inst.is_a then
        local ok, yes = pcall(function() return inst:is_a("BasePart") end)
        if ok and yes then return true end
    end
    local cn = inst.ClassName or inst.class_name
    return BASE_PARTS[cn] == true
end

function M.find_part(char, name)
    if not char then return nil end
    return env.safe_call(function()
        if char.find_first_child then return char:find_first_child(name) end
        return char:FindFirstChild(name)
    end)
end

function M.iter_parts(char)
    local out = {}
    if not char then return out end

    local desc = env.safe_call(function() return char:get_descendants() end)
        or env.safe_call(function() return char:GetDescendants() end)
    if desc then
        for _, inst in ipairs(desc) do
            if M.is_base_part(inst) then
                out[#out + 1] = inst
            end
        end
    end

    return out
end

function M.set_character_noclip(char, _root, enabled)
    local collide = not enabled
    for _, inst in ipairs(M.iter_parts(char)) do
        M.set_part_collide(inst, collide)
    end
end

function M.set_velocity(inst, x, y, z)
    if not inst then return end
    if part and part.set_velocity then
        pcall(part.set_velocity, inst, x, y, z)
    else
        pcall(function() inst.Velocity = Vector3.new(x, y, z) end)
    end
end

function M.set_position_only(inst, x, y, z)
    if not inst then return end
    if part and part.set_position then
        pcall(part.set_position, inst, x, y, z)
    else
        pcall(function() inst.Position = Vector3.new(x, y, z) end)
    end
end

function M.set_position(inst, x, y, z)
    M.set_position_only(inst, x, y, z)
end

function M.set_part_collide(inst, collide)
    if not inst then return end
    if part and part.set_can_collide then
        pcall(part.set_can_collide, inst, collide)
    else
        pcall(function() inst.CanCollide = collide end)
    end
end

function M.set_noclip_parts(char, enabled)
    if not char then return end
    local collide = not enabled
    for i = 1, #NOCLIP_PARTS do
        local p = M.find_part(char, NOCLIP_PARTS[i])
        if p and M.is_base_part(p) then
            M.set_part_collide(p, collide)
        end
    end
end

function M.humanoid_state(hum, state)
    if not hum or state == nil then return end
    pcall(function() hum.state = state end)
end

function M.humanoid_suspend(hum)
    if not hum then return end
    pcall(function() hum.platform_stand = false end)
    pcall(function() hum.auto_rotate = false end)
    pcall(function() hum.evaluate_state_machine = false end)
    pcall(function() hum.sit = false end)
end

function M.humanoid_running(hum)
    M.humanoid_state(hum, 8)
end

function M.zero_part(inst)
    if not inst then return end
    M.set_velocity(inst, 0, 0, 0)
    if part and part.set_angular_velocity then
        pcall(part.set_angular_velocity, inst, 0, 0, 0)
    end
end

function M.zero_character(char, root)
    if root then M.zero_part(root) end
    for i = 1, #NOCLIP_PARTS do
        local p = char and M.find_part(char, NOCLIP_PARTS[i])
        if p and p ~= root then
            M.zero_part(p)
        end
    end
end

function M.camera_flat_axes()
    if not camera or not camera.get_look_vector then return nil end
    local ok, look = pcall(camera.get_look_vector)
    if not ok or not look then return nil end

    local lx = look.x or look.X or 0
    local lz = look.z or look.Z or 0
    local lm = math.sqrt(lx * lx + lz * lz)
    if lm < 0.001 then return nil end
    lx, lz = lx / lm, lz / lm

    return lx, lz, -lz, lx
end

function M.read_flat_input()
    local lx, lz, rx, rz = M.camera_flat_axes()
    if not lx then return 0, 0 end

    local mx, mz = 0, 0
    if M.key_down(0x57) then mx, mz = mx + lx, mz + lz end
    if M.key_down(0x53) then mx, mz = mx - lx, mz - lz end
    if M.key_down(0x41) then mx, mz = mx - rx, mz - rz end
    if M.key_down(0x44) then mx, mz = mx + rx, mz + rz end

    local mag = math.sqrt(mx * mx + mz * mz)
    if mag < 0.001 then return 0, 0 end
    return mx / mag, mz / mag
end

function M.read_fly_input()
    local mx, mz = M.read_flat_input()
    local my = 0
    if M.key_down(0x20) then my = 1 end
    if M.key_down(0x11) then my = -1 end
    return mx, my, mz
end

function M.ground_distance(x, y, z)
    if not raycast or not raycast.cast then return nil end
    if raycast.is_ready and not raycast.is_ready() then return nil end

    local hit, _, dist = raycast.cast(x, y + 2, z, x, y - 512, z)
    if not hit then return nil end
    return dist
end

function M.floor_y_at(x, y, z)
    local dist = M.ground_distance(x, y, z)
    if not dist then return nil end
    return y + 2 - dist + HIP_OFFSET
end

function M.clamp_above_floor(x, y, z)
    local floor_y = M.floor_y_at(x, y, z)
    if floor_y and y < floor_y then return floor_y end
    return y
end

--[[ Position nudge + matching velocity — legacy Fallen pattern. ]]
function M.drive_root(root, pos, dx, dy, dz, speed, dt)
    if not root or not pos then return pos end

    dt = dt or M.delta_time()
    local mag = math.sqrt(dx * dx + dy * dy + dz * dz)

    if mag < 0.001 then
        M.set_velocity(root, 0, -0.1, 0)
        return pos
    end

    dx, dy, dz = dx / mag, dy / mag, dz / mag
    local step = speed * dt
    local nx = pos.x + dx * step
    local ny = pos.y + dy * step
    local nz = pos.z + dz * step

    M.set_position_only(root, nx, ny, nz)
    M.set_velocity(root, dx * speed, dy * speed, dz * speed)

    return { x = nx, y = ny, z = nz }
end

return M

end)()

-- ── core/runservice.lua ──
April._mods["core.runservice"] = (function()
--[[
    RunService helper — API 1.4 game.get_service("RunService").
    Vector documents service retrieval; sim hooks always run from on_frame dispatch.
]]

local env = April.require("core.env")

local M = {}

local _svc = nil
local _svc_checked = false
local _sim_hooks = {}

local function delta_time(fallback)
    if utility and utility.get_delta_time then
        return utility.get_delta_time()
    end
    return fallback or 0.016
end

local function run_sim_hooks(dt)
    for i = 1, #_sim_hooks do
        local hook = _sim_hooks[i]
        if hook then
            env.safe_call(hook, dt)
        end
    end
end

function M.get()
    if _svc_checked then return _svc end
    _svc_checked = true

    if not game or not game.get_service then return nil end

    local ok, svc = pcall(function()
        return game.get_service("RunService")
    end)

    if ok and svc then
        _svc = svc
    end
    return _svc
end

function M.available()
    return M.get() ~= nil
end

--[[ Movement uses part/camera APIs — only needs game + local player, not RunService events. ]]
function M.movement_allowed()
    if not game then return false end
    return env.get_local_player() ~= nil
end

function M.on_sim(fn)
    if type(fn) ~= "function" then return false end
    _sim_hooks[#_sim_hooks + 1] = fn
    return true
end

function M.dispatch(dt)
    run_sim_hooks(dt or delta_time())
end

return M

end)()

-- ── core/misc_gate.lua ──
April._mods["core.misc_gate"] = (function()
--[[ Misc tab — movement features need RunService from Game API 1.4+ ]]

local runservice = April.require("core.runservice")

local M = {}

function M.movement_allowed()
    return runservice.movement_allowed()
end

return M

end)()

-- ── core/movement_ctrl.lua ──
April._mods["core.movement_ctrl"] = (function()
--[[ Movement sim — Inf Fly, Spider, Noclip, Slowfall (velocity + position nudge). ]]

local settings = April.require("core.settings")
local env = April.require("core.env")
local move = April.require("core.cframe_move")

local M = {}

local P_FLY = "april_noclip_enabled"
local P_SPIDER = "april_spider_enabled"
local P_NOCLIP = "april_walk_noclip_enabled"
local P_SLOWFALL = "april_slowfall_enabled"

local MODE_NONE = "none"
local MODE_FLY = "fly"
local MODE_SPIDER = "spider"
local MODE_NOCLIP = "noclip"

local _installed = false
local active_mode = MODE_NONE
local tracked_char_id = nil
local noclip_on = false
local last_state_ms = 0

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function char_id(char)
    if not char then return nil end
    return char.Address or char.address or tostring(char)
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
    return move.find_part(char, "HumanoidRootPart")
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

local function resolve_mode()
    if settings.enabled(P_NOCLIP) then return MODE_NOCLIP end
    if settings.enabled(P_FLY) then return MODE_FLY end
    if settings.enabled(P_SPIDER) then return MODE_SPIDER end
    return MODE_NONE
end

local function maybe_state(hum, state)
    local now = tick_ms()
    if now - last_state_ms < 150 then return end
    last_state_ms = now
    move.humanoid_state(hum, state)
end

local function set_noclip(char, on)
    if noclip_on == on then return end
    noclip_on = on
    move.set_noclip_parts(char, on)
end

local function leave_mode(char, hum)
    set_noclip(char, false)
    if hum then move.humanoid_running(hum) end
    last_state_ms = 0
end

local function tick_noclip(root, hum, speed, dt)
    maybe_state(hum, 8)

    local pos = move.read_pos(root)
    if not pos then return end

    local mx, my, mz = move.read_fly_input()
    local next_pos = move.drive_root(root, pos, mx, my, mz, speed, dt)
    if not next_pos then return end

    local ny = move.clamp_above_floor(next_pos.x, next_pos.y, next_pos.z)
    if ny ~= next_pos.y then
        move.set_position_only(root, next_pos.x, ny, next_pos.z)
        local vx, _, vz = move.read_velocity(root)
        move.set_velocity(root, vx, 0, vz)
    end
end

local function tick_fly(root, hum, speed, dt)
    maybe_state(hum, 6)

    local pos = move.read_pos(root)
    if not pos then return end

    local mx, my, mz = move.read_fly_input()
    local next_pos = move.drive_root(root, pos, mx, my, mz, speed, dt)
    if not next_pos then return end

    if my <= 0 then
        local ny = move.clamp_above_floor(next_pos.x, next_pos.y, next_pos.z)
        if ny > next_pos.y then
            move.set_position_only(root, next_pos.x, ny, next_pos.z)
            local vx, _, vz = move.read_velocity(root)
            move.set_velocity(root, vx, 0, vz)
        end
    end
end

local function tick_spider(root, hum, speed, dt)
    maybe_state(hum, 12)

    local pos = move.read_pos(root)
    if not pos then return end

    local mx, my, mz = move.read_fly_input()
    if my == 0 then my = 1 end

    move.drive_root(root, pos, mx, my, mz, speed, dt)
end

local function tick_slowfall(root, dt)
    local pos = move.read_pos(root)
    if not pos then return end

    local cap = settings.num("april_slowfall_speed", -5)
    if cap > 0 then cap = -cap end

    local vx, vy, vz = move.read_velocity(root)
    if vy >= cap then return end

    move.set_velocity(root, vx, cap, vz)
    move.set_position_only(root, pos.x, pos.y + cap * dt * 0.05, pos.z)
end

local function abort_active()
    if active_mode == MODE_NONE then return end

    local lp = env.get_local_player()
    if lp then
        local char = get_character(lp)
        local hum = get_humanoid(lp)
        if char and hum then
            leave_mode(char, hum)
        end
    end

    active_mode = MODE_NONE
end

function M.tick(_dt)
    local misc_gate = April.require("core.misc_gate")
    if not misc_gate.movement_allowed() then
        abort_active()
        return
    end

    local fling = April.require("features.movement.fling")
    if fling.is_active and fling.is_active() then
        abort_active()
        return
    end

    local dt = move.delta_time()
    local lp = env.get_local_player()
    if not lp then return end

    local char = get_character(lp)
    if not char or not env.is_valid(char) then return end

    local root = get_root(lp)
    local hum = get_humanoid(lp)
    if not root or not hum then return end

    local cid = char_id(char)
    if cid ~= tracked_char_id then
        if active_mode ~= MODE_NONE then
            leave_mode(char, hum)
        end
        active_mode = MODE_NONE
        tracked_char_id = cid
    end

    local mode = resolve_mode()

    if active_mode ~= mode then
        if active_mode ~= MODE_NONE then
            leave_mode(char, hum)
        end
        active_mode = mode
        if mode == MODE_NOCLIP then
            set_noclip(char, true)
        end
    end

    if mode == MODE_NOCLIP then
        tick_noclip(root, hum, settings.num("april_walk_noclip_speed", 32), dt)
    elseif mode == MODE_FLY then
        tick_fly(root, hum, settings.num("april_noclip_speed", 72), dt)
    elseif mode == MODE_SPIDER then
        tick_spider(root, hum, settings.num("april_spider_speed", 20), dt)
    elseif noclip_on then
        set_noclip(char, false)
    end

    if mode == MODE_NONE and settings.enabled(P_SLOWFALL) then
        tick_slowfall(root, dt)
    end
end

function M.install()
    if _installed then return end
    _installed = true
    April.require("core.runservice").on_sim(function(dt)
        M.tick(dt)
    end)
end

return M

end)()

-- ── core/config_store.lua ──
April._mods["core.config_store"] = (function()
--[[
    Config persistence — multi-slot save/load, colors, hotkeys, waypoints, autoload meta.
]]

local cache = April.require("core.cache")

local M = {}

M.SLOT_MIN = 1
M.SLOT_MAX = 5
M.FILE_VERSION = 2

local META_FILE = "April_meta.txt"

local EXCLUDE = {
    april_cfg_slot = true,
    april_cfg_profile_name = true,
    april_cfg_autoload = true,
    april_cfg_autoload_slot = true,
    april_cfg_autoload_profile = true,
    april_debug_overlay = true,
    april_gm_held_weapon = true,
}

local MENU_KEYS = {
    "april_esp_text_size",
    "april_tung_esp_enabled", "april_tung_esp_max_dist",
        "april_target_overlay", "april_target_overlay_fov", "april_target_overlay_gear_size", "april_target_overlay_top",
    "april_crosshair_enabled", "april_crosshair_type", "april_crosshair_size", "april_crosshair_gap",
    "april_crosshair_thickness", "april_crosshair_color", "april_crosshair_dot", "april_crosshair_outline",
    "april_crosshair_rainbow", "april_crosshair_rainbow_speed",
    "april_brainrot_enabled", "april_brainrot_enabled_mode", "april_brainrot_style", "april_brainrot_size",
    "april_silent_aim", "april_silent_aim_mode",
    "april_silent_target_type", "april_silent_bone",
    "april_silent_filter_health", "april_silent_filter_visible", "april_silent_filter_team",
    "april_silent_max_dist", "april_silent_fov", "april_silent_sticky",
    "april_silent_bullet_manip",
    "april_silent_manip_dist", "april_silent_manip_status", "april_silent_manip_ring", "april_silent_manip_peek_vis",
    "april_silent_draw_fov", "april_silent_fov_style", "april_silent_target_line",
    "april_gunmods_enabled", "april_gunmods_enabled_mode", "april_gm_mode", "april_gm_weapon_select", "april_gm_recoil", "april_gm_recoil_pct", "april_gm_spread", "april_gm_spread_pct",
    "april_gm_sway", "april_gm_fire_rate", "april_gm_fire_rate_mult",
    "april_gm_speed", "april_gm_speed_mult", "april_gm_range", "april_gm_range_mult",
    "april_farm_helper", "april_farm_helper_mode", "april_farm_radius", "april_farm_smooth",
    "april_farm_silent",
    "april_world_enabled", "april_world_enabled_mode", "april_stone_node", "april_metal_node", "april_phosphate_node",
    "april_corn_plant", "april_tomato_plant", "april_pumpkin_plant", "april_lemon_plant",
    "april_raspberry_plant", "april_blueberry_plant", "april_wool_plant", "april_hemp_plant",
    "april_deer", "april_boar", "april_wolf",
    "april_world_boxes", "april_world_show_name", "april_world_show_distance", "april_world_range",
    "april_loot_enabled", "april_loot_enabled_mode", "april_dropped_item", "april_wooden_crate", "april_metal_crate",
    "april_steel_crate", "april_food_crate", "april_timed_crate", "april_care_package", "april_btr_crate",
    "april_body_bag", "april_sleeper", "april_trash_can", "april_oil_barrel",
    "april_small_egg", "april_medium_egg", "april_large_egg",
    "april_wooden_boat", "april_military_boat", "april_flycopter",
    "april_loot_boxes", "april_loot_show_name", "april_loot_show_distance", "april_loot_range",
    "april_npc_enabled", "april_npc_enabled_mode", "april_npc_soldiers", "april_npc_bosses", "april_npc_box_mode",
    "april_npc_health", "april_npc_skeleton",
    "april_npc_offscreen", "april_npc_show_name", "april_npc_show_distance", "april_npc_range",
    "april_base_enabled", "april_base_enabled_mode", "april_base_cabinet", "april_storage_cabinet", "april_small_box", "april_large_box",
    "april_sleeping_bag", "april_auto_turret", "april_auto_turret_ring", "april_shotgun_turret", "april_shotgun_turret_ring",
    "april_wooden_door", "april_wooden_double_door", "april_salvaged_door", "april_metal_door",
    "april_metal_double_door", "april_steel_door", "april_steel_double_door",
    "april_garage_door", "april_trap_door", "april_triangle_trap_door",
    "april_small_battery", "april_medium_battery", "april_large_battery",
    "april_solar_panel", "april_windmill",
    "april_base_boxes", "april_base_show_name", "april_base_show_distance", "april_base_range",
    "april_waypoints_enabled", "april_waypoints_enabled_mode", "april_wp_dist", "april_wp_beacon", "april_wp_beacon_h",
    "april_wp_draw", "april_wp_slot",
    "april_map_enabled", "april_map_enabled_mode", "april_map_zoom", "april_map_size", "april_map_icon_scale",
    "april_map_show_players", "april_map_show_npcs", "april_map_show_loot", "april_map_show_world",
    "april_map_show_base", "april_map_show_waypoints",
    "april_map_labels",
    "april_noclip_enabled", "april_noclip_enabled_mode", "april_noclip_speed",
    "april_spider_enabled", "april_spider_enabled_mode", "april_spider_speed",
    "april_slowfall_enabled", "april_slowfall_enabled_mode", "april_slowfall_speed",
    "april_walk_noclip_enabled", "april_walk_noclip_enabled_mode", "april_walk_noclip_speed",
    "april_fling_enabled", "april_fling_fov", "april_fling_key", "april_fling_key_mode", "april_fling_duration",
    "april_desync_enabled", "april_desync_enabled_mode", "april_desync_autosend", "april_desync_autosend_len",
    "april_desync_visualizer",
    "april_bullet_manip_enabled", "april_bullet_manip_enabled_mode", "april_bullet_manip_range", "april_bullet_manip_speed",
    "april_bullet_manip_debug", "april_bullet_manip_console", "april_bullet_manip_vis",
    "april_bullet_manip_vis_style", "april_bullet_manip_vis_size",
    "april_bullet_manip_vis_link", "april_bullet_manip_vis_labels", "april_bullet_manip_vis_peek",
    "april_mod_checker_enabled", "april_mod_checker_interval",
}

local COLOR_KEYS = {
    "april_crosshair_color", "april_crosshair_dot", "april_crosshair_outline",
    "april_silent_aim", "april_silent_draw_fov", "april_silent_target_line",
    "april_stone_node", "april_metal_node", "april_phosphate_node", "april_corn_plant", "april_tomato_plant",
    "april_pumpkin_plant", "april_lemon_plant", "april_raspberry_plant", "april_blueberry_plant",
    "april_wool_plant", "april_hemp_plant", "april_deer", "april_boar", "april_wolf",
    "april_dropped_item", "april_wooden_crate", "april_metal_crate", "april_steel_crate", "april_food_crate",
    "april_timed_crate", "april_care_package", "april_btr_crate", "april_body_bag", "april_sleeper",
    "april_trash_can", "april_oil_barrel", "april_small_egg", "april_medium_egg", "april_large_egg",
    "april_wooden_boat", "april_military_boat", "april_flycopter",
    "april_npc_soldiers", "april_npc_bosses", "april_npc_skeleton", "april_npc_offscreen",
    "april_base_cabinet", "april_storage_cabinet", "april_small_box", "april_large_box",
    "april_sleeping_bag", "april_auto_turret", "april_auto_turret_ring", "april_shotgun_turret", "april_shotgun_turret_ring", "april_wooden_door",
    "april_wooden_double_door", "april_salvaged_door", "april_metal_door", "april_metal_double_door",
    "april_steel_door", "april_steel_double_door", "april_garage_door", "april_trap_door",
    "april_triangle_trap_door", "april_small_battery", "april_medium_battery", "april_large_battery",
    "april_solar_panel", "april_windmill",
    "april_wp_draw", "april_map_bg", "april_map_grid", "april_map_player_col", "april_map_npc_col", "april_map_loot_col",
    "april_map_world_col", "april_map_base_col", "april_map_wp_col", "april_map_local",
    "april_desync_visualizer",
    "april_bullet_manip_vis_server", "april_bullet_manip_vis_local", "april_bullet_manip_vis_peek", "april_bullet_manip_vis_link",
}

local LEGACY_HOTKEY_TO_CHECKBOX = {
    april_crosshair_enabled_key = "april_crosshair_enabled",
    april_brainrot_enabled_key = "april_brainrot_enabled",
    april_gunmods_enabled_key = "april_gunmods_enabled",
    april_farm_helper_key = "april_farm_helper",
    april_world_enabled_key = "april_world_enabled",
    april_loot_enabled_key = "april_loot_enabled",
    april_npc_enabled_key = "april_npc_enabled",
    april_base_enabled_key = "april_base_enabled",
    april_waypoints_enabled_key = "april_waypoints_enabled",
    april_map_enabled_key = "april_map_enabled",
    april_noclip_enabled_key = "april_noclip_enabled",
    april_spider_enabled_key = "april_spider_enabled",
    april_slowfall_enabled_key = "april_slowfall_enabled",
    april_desync_enabled_key = "april_desync_enabled",
    april_bullet_manip_enabled_key = "april_bullet_manip_enabled",
    april_mod_checker_enabled_key = "april_mod_checker_enabled",
}

local HOTKEY_KEYS = {
    "april_brainrot_enabled",
    "april_gunmods_enabled",
    "april_farm_helper",
    "april_world_enabled",
    "april_loot_enabled",
    "april_npc_enabled",
    "april_base_enabled",
    "april_waypoints_enabled",
    "april_map_enabled",
    "april_noclip_enabled",
    "april_spider_enabled",
    "april_slowfall_enabled",
    "april_walk_noclip_enabled",
    "april_desync_enabled",
    "april_bullet_manip_enabled",
    "april_tung_esp_enabled",
    "april_silent_aim",
}

function M.get_config_path(name)
    local base = os.getenv and os.getenv("LOCALAPPDATA") or ""
    if base == "" then return name end
    return base .. "\\Project Vector\\Scripts\\" .. name
end

local function slot_path(slot)
    return M.get_config_path("April_Slot_" .. tostring(slot) .. ".txt")
end

local function serialize_value(v)
    local t = type(v)
    if t == "boolean" then return v and "true" or "false" end
    if t == "number" then return tostring(v) end
    if t == "string" then return v end
    if t == "table" then
        local parts = {}
        for i = 1, #v do
            parts[i] = tostring(v[i])
        end
        return table.concat(parts, ",")
    end
    return nil
end

local function parse_value(raw)
    if raw == "true" then return true end
    if raw == "false" then return false end
    local n = tonumber(raw)
    if n then return n end
    if raw:find(",") then
        local out = {}
        for part in raw:gmatch("[^,]+") do
            table.insert(out, tonumber(part) or part)
        end
        return out
    end
    return raw
end

local function color_line(id, c)
    if not c then return nil end
    return string.format("@color:%s=%s,%s,%s,%s", id, c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 1)
end

local function collect_menu_keys()
    local seen = {}
    local out = {}

    local function add(id)
        if not id or EXCLUDE[id] or seen[id] then return end
        seen[id] = true
        table.insert(out, id)
    end

    for _, id in ipairs(MENU_KEYS) do add(id) end

    pcall(function()
        local weapons = April.require("game.weapons")
        for _, name in ipairs(weapons.recoil_weapon_names()) do
            add(weapons.slug(name))
        end
    end)

    return out
end

local function write_waypoints(lines)
    for i = M.SLOT_MIN, M.SLOT_MAX do
        local wp = cache.waypoints[i]
        if wp and wp.pos then
            table.insert(lines, string.format("wp:%d:name=%s", i, wp.name or ("Waypoint " .. i)))
            table.insert(lines, string.format("wp:%d:x=%s", i, wp.pos.x))
            table.insert(lines, string.format("wp:%d:y=%s", i, wp.pos.y))
            table.insert(lines, string.format("wp:%d:z=%s", i, wp.pos.z))
        end
    end
end

local function read_waypoints(id, field, val)
    local slot = tonumber(id)
    if not slot then return end
    cache.waypoints[slot] = cache.waypoints[slot] or { name = "Waypoint " .. slot, pos = {} }
    local wp = cache.waypoints[slot]
    if field == "name" then
        wp.name = val
    elseif field == "x" or field == "y" or field == "z" then
        wp.pos = wp.pos or {}
        wp.pos[field] = tonumber(val) or 0
    end
end

local function profile_name_from_menu()
    if not menu or not menu.get then return "Default" end
    local name = menu.get("april_cfg_profile_name")
    if type(name) ~= "string" or name:gsub("%s", "") == "" then
        return "Default"
    end
    return name:gsub("[\r\n=]", " "):sub(1, 48)
end

local function read_slot_meta(slot)
    local path = slot_path(slot)
    local f = io.open(path, "r")
    if not f then return nil end

    local meta = {}
    for line in f:lines() do
        if line:sub(1, 1) == "#" then goto continue end
        local key, val = line:match("^([^=]+)=(.+)$")
        if key == "profile_name" then
            meta.profile_name = val
        end
        ::continue::
    end
    f:close()
    return meta
end

function M.find_slot_by_profile_name(name)
    if not name or name == "" then return nil end
    local target = name:lower()
    for slot = M.SLOT_MIN, M.SLOT_MAX do
        local meta = read_slot_meta(slot)
        if meta and meta.profile_name and meta.profile_name:lower() == target then
            return slot
        end
    end
    return nil
end

function M.get_slot_profile_name(slot)
    local meta = read_slot_meta(slot)
    return meta and meta.profile_name or nil
end

function M.slot_exists(slot)
    local f = io.open(slot_path(slot), "r")
    if not f then return false end
    f:close()
    return true
end

function M.save_slot(slot)
    slot = math.floor(tonumber(slot) or 1)
    if slot < M.SLOT_MIN or slot > M.SLOT_MAX then return false end
    if not menu or not menu.get then return false end

    local lines = {
        "# April config v" .. M.FILE_VERSION,
        "version=" .. M.FILE_VERSION,
        "profile_name=" .. profile_name_from_menu(),
    }

    for _, id in ipairs(collect_menu_keys()) do
        local v = menu.get(id)
        local s = serialize_value(v)
        if s ~= nil then
            table.insert(lines, id .. "=" .. s)
        end
    end

    for _, id in ipairs(COLOR_KEYS) do
        if menu.get_color then
            local line = color_line(id, menu.get_color(id))
            if line then table.insert(lines, line) end
        end
    end

    for _, id in ipairs(HOTKEY_KEYS) do
        if menu.get_key then
            local vk = menu.get_key(id)
            if vk and vk > 0 then
                table.insert(lines, string.format("@key:%s=%d", id, vk))
            end
        end
    end

    write_waypoints(lines)

    local f = io.open(slot_path(slot), "w")
    if not f then return false end
    f:write(table.concat(lines, "\n"))
    f:close()
    return true
end

function M.load_slot(slot, opts)
    opts = opts or {}
    slot = math.floor(tonumber(slot) or 1)
    if slot < M.SLOT_MIN or slot > M.SLOT_MAX then return false end
    if not menu or not menu.set then return false end

    local path = slot_path(slot)
    local f = io.open(path, "r")
    if not f then return false end

    for i = M.SLOT_MIN, M.SLOT_MAX do
        cache.waypoints[i] = nil
    end

    for line in f:lines() do
        if line:sub(1, 1) ~= "#" and line:find("=") then
            local key, val = line:match("^([^=]+)=(.+)$")
            if key and val then
                if key == "profile_name" then
                    if menu.set then menu.set("april_cfg_profile_name", val) end
                elseif key:sub(1, 7) == "@color:" then
                    local id = key:sub(8)
                    local r, g, b, a = val:match("([^,]+),([^,]+),([^,]+),([^,]+)")
                    if id and menu.set_color then
                        menu.set_color(id, {
                            tonumber(r) or 0,
                            tonumber(g) or 0,
                            tonumber(b) or 0,
                            tonumber(a) or 1,
                        })
                    end
                elseif key:sub(1, 5) == "@key:" then
                    local id = key:sub(6)
                    local vk = tonumber(val)
                    if id and vk and menu.set_key then
                        local target = LEGACY_HOTKEY_TO_CHECKBOX[id] or id
                        menu.set_key(target, vk)
                    end
                elseif key:sub(1, 3) == "wp:" then
                    local slot_id, field = key:match("^wp:(%d+):(%w+)$")
                    read_waypoints(slot_id, field, val)
                elseif not EXCLUDE[key] then
                    menu.set(key, parse_value(val))
                end
            end
        end
    end

    f:close()
    April.require("core.settings").invalidate()
    April.require("core.menu_util").sync_masters()

    pcall(function()
        local gun_mods = April.require("features.combat.gun_mods")
        gun_mods._apply_dirty = true
    end)

    return true
end

function M.delete_slot(slot)
    slot = math.floor(tonumber(slot) or 1)
    local path = slot_path(slot)
    if os.remove then
        return os.remove(path) == true
    end
    return false
end

function M.save_meta()
    if not menu or not menu.get then return false end
    local lines = {
        "version=" .. M.FILE_VERSION,
        "autoload=" .. (menu.get("april_cfg_autoload") and "true" or "false"),
        "autoload_slot=" .. tostring(menu.get("april_cfg_autoload_slot") or 1),
        "autoload_profile=" .. tostring(menu.get("april_cfg_autoload_profile") or ""),
        "active_slot=" .. tostring(menu.get("april_cfg_slot") or 1),
    }
    local f = io.open(M.get_config_path(META_FILE), "w")
    if not f then return false end
    f:write(table.concat(lines, "\n"))
    f:close()
    return true
end

function M.load_meta()
    local f = io.open(M.get_config_path(META_FILE), "r")
    if not f or not menu or not menu.set then return false end

    for line in f:lines() do
        local key, val = line:match("^([^=]+)=(.+)$")
        if key == "autoload" then
            menu.set("april_cfg_autoload", val == "true")
        elseif key == "autoload_slot" then
            menu.set("april_cfg_autoload_slot", tonumber(val) or 1)
        elseif key == "autoload_profile" then
            menu.set("april_cfg_autoload_profile", val or "")
        elseif key == "active_slot" then
            menu.set("april_cfg_slot", tonumber(val) or 1)
        end
    end

    f:close()
    April.require("core.settings").invalidate()
    return true
end

function M.try_autoload()
    M.load_meta()
    if not menu or not menu.get then return false end

    local autoload = menu.get("april_cfg_autoload")
    if autoload ~= true and autoload ~= 1 then return false end

    local profile = menu.get("april_cfg_autoload_profile")
    local slot

    if type(profile) == "string" and profile:gsub("%s", "") ~= "" then
        slot = M.find_slot_by_profile_name(profile)
    end

    if not slot then
        slot = math.floor(tonumber(menu.get("april_cfg_autoload_slot")) or 1)
    end

    if slot < M.SLOT_MIN then slot = M.SLOT_MIN end
    if slot > M.SLOT_MAX then slot = M.SLOT_MAX end

    if not M.slot_exists(slot) then
        return false
    end

    if M.load_slot(slot, { silent = true }) then
        return true
    end
    return false
end

return M

end)()

-- ── core/memory_string.lua ──
April._mods["core.memory_string"] = (function()
--[[ Scan process memory for ASCII / UTF-16 strings via memory.read_buffer (Vector Memory API). ]]

local env = April.require("core.env")

local M = {}

local CHUNK = 65536
local ANCHOR_RADIUS = 1024 * 1024
local HEAP_SCAN_SIZE = 32 * 1024 * 1024
local MAX_HITS = 128

local function has_memory()
    return memory and type(memory.read_buffer) == "function"
        and type(memory.write) == "function"
end

function M.available()
    return has_memory()
end

function M.instance_addr(inst)
    if not inst then return nil end
    local addr = inst.Address or inst.address
    if type(addr) == "number" and addr > 0 then return addr end
    return nil
end

function M.utf16_bytes(ascii)
    if not ascii or ascii == "" then return "" end
    local out = {}
    for i = 1, #ascii do
        out[#out + 1] = string.char(string.byte(ascii, i))
        out[#out + 1] = string.char(0)
    end
    return table.concat(out)
end

function M.scan_buffer(buf, needle, base_addr, hits, max_hits)
    if not buf or buf == "" or not needle or needle == "" then return hits end
    max_hits = max_hits or MAX_HITS
    hits = hits or {}

    local pos = 1
    while #hits < max_hits do
        local found = buf:find(needle, pos, true)
        if not found then break end
        hits[#hits + 1] = { addr = base_addr + found - 1, enc = needle:find(string.char(0), 1, true) and "utf16" or "ascii" }
        pos = found + 1
    end
    return hits
end

function M.scan_range(start_addr, size, needle, max_hits, enc)
    local hits = {}
    if not has_memory() or not start_addr or start_addr <= 0 then return hits end
    if not needle or #needle < 2 then return hits end

    max_hits = max_hits or MAX_HITS
    size = math.max(256, math.min(size or ANCHOR_RADIUS, HEAP_SCAN_SIZE))
    local overlap = math.min(#needle + 4, 256)
    local offset = 0

    while offset < size and #hits < max_hits do
        local read_size = math.min(CHUNK, size - offset)
        local buf = memory.read_buffer(start_addr + offset, read_size)
        if buf and buf ~= "" then
            M.scan_buffer(buf, needle, start_addr + offset, hits, max_hits)
            for i = 1, #hits do
                hits[i].enc = enc or hits[i].enc or "ascii"
            end
        end
        if read_size <= overlap then break end
        offset = offset + read_size - overlap
    end

    return hits
end

function M.try_engine_scan(needle, max_hits)
    if not needle or needle == "" then return {} end
    for _, fn_name in ipairs({ "scan_string", "find_string", "search_string" }) do
        local fn = memory and memory[fn_name]
        if type(fn) == "function" then
            for _, args in ipairs({ { needle }, { needle, true }, { needle, false } }) do
                local ok, result = pcall(fn, unpack(args))
                if ok and type(result) == "table" then
                    local hits = {}
                    for i = 1, math.min(#result, max_hits or MAX_HITS) do
                        local addr = result[i]
                        if type(addr) == "number" and addr > 0 then
                            hits[#hits + 1] = { addr = addr, enc = "ascii" }
                        elseif type(addr) == "table" and type(addr.addr or addr.address) == "number" then
                            hits[#hits + 1] = { addr = addr.addr or addr.address, enc = addr.enc or "ascii" }
                        end
                    end
                    if #hits > 0 then return hits end
                end
            end
        end
    end
    return {}
end

function M.collect_anchors()
    local anchors = {}
    local seen = {}

    local function add(addr, radius)
        if not addr or addr <= 0 or seen[addr] then return end
        seen[addr] = true
        anchors[#anchors + 1] = { addr = addr, radius = radius or ANCHOR_RADIUS }
    end

    if memory and memory.base and memory.base > 0 then
        add(memory.base, HEAP_SCAN_SIZE)
    end

    if game then
        add(M.instance_addr(game.workspace), ANCHOR_RADIUS)
        add(M.instance_addr(game.players), ANCHOR_RADIUS * 2)
        add(M.instance_addr(game.local_player), ANCHOR_RADIUS * 2)

        local core = env.safe_call(function() return game.get_service("CoreGui") end)
        add(M.instance_addr(core), ANCHOR_RADIUS)

        local starter = env.safe_call(function() return game.get_service("StarterGui") end)
        add(M.instance_addr(starter), ANCHOR_RADIUS)
    end

    if entity and entity.get_players then
        for _, p in ipairs(entity.get_players()) do
            if p.is_local then
                add(M.instance_addr(p.player), ANCHOR_RADIUS * 2)
                add(M.instance_addr(p.character), ANCHOR_RADIUS)
                add(M.instance_addr(p.humanoid), ANCHOR_RADIUS)
            end
        end
    end

    local lp = env.get_local_player()
    if lp then
        add(M.instance_addr(lp.player), ANCHOR_RADIUS * 2)
        add(M.instance_addr(lp.character), ANCHOR_RADIUS)
    end

    return anchors
end

function M.find_string_variants(text, max_hits)
    if not has_memory() or not text or #text < 2 then return {} end

    local variants = {
        { needle = text, enc = "ascii" },
        { needle = M.utf16_bytes(text), enc = "utf16" },
    }

    if not text:find("@", 1, true) then
        variants[#variants + 1] = { needle = "@" .. text, enc = "ascii" }
        variants[#variants + 1] = { needle = M.utf16_bytes("@" .. text), enc = "utf16" }
    end

    local hits = {}
    local seen_addr = {}

    local function merge(list)
        for i = 1, #list do
            local hit = list[i]
            local addr = type(hit) == "table" and hit.addr or hit
            local enc = type(hit) == "table" and hit.enc or "ascii"
            if addr and not seen_addr[addr] then
                seen_addr[addr] = true
                hits[#hits + 1] = { addr = addr, enc = enc }
                if #hits >= (max_hits or MAX_HITS) then return true end
            end
        end
        return false
    end

    for i = 1, #variants do
        local v = variants[i]
        if merge(M.try_engine_scan(v.needle, max_hits)) then return hits end
    end

    for i = 1, #variants do
        local v = variants[i]
        for _, anchor in ipairs(M.collect_anchors()) do
            if merge(M.scan_range(anchor.addr, anchor.radius, v.needle, max_hits, v.enc)) then
                return hits
            end
        end
    end

    return hits
end

function M.find_string(needle, max_hits)
    local hits = M.find_string_variants(needle, max_hits)
    local out = {}
    for i = 1, #hits do
        out[i] = hits[i].addr
    end
    return out
end

M._heap_offset = 0
M._heap_needle = ""

function M.reset_heap_scan()
    M._heap_offset = 0
    M._heap_needle = ""
end

function M.heap_scan_step(needle, bytes_per_tick, max_hits)
    if not has_memory() or not memory.base or memory.base <= 0 then return {} end
    if not needle or #needle < 2 then return {} end

    if needle ~= M._heap_needle then
        M._heap_needle = needle
        M._heap_offset = 0
    end

    local hits = {}
    local budget = bytes_per_tick or (512 * 1024)
    local scanned = 0

    while M._heap_offset < HEAP_SCAN_SIZE and scanned < budget and #hits < (max_hits or 16) do
        local size = math.min(CHUNK, HEAP_SCAN_SIZE - M._heap_offset)
        local start = memory.base + M._heap_offset
        local buf = memory.read_buffer(start, size) or ""
        for _, v in ipairs({
            { needle = needle, enc = "ascii" },
            { needle = M.utf16_bytes(needle), enc = "utf16" },
        }) do
            local before = #hits
            M.scan_buffer(buf, v.needle, start, hits, max_hits)
            for j = before + 1, #hits do
                hits[j].enc = v.enc
            end
        end
        scanned = scanned + size
        M._heap_offset = M._heap_offset + size - math.min(#needle + 4, 128)
    end

    if M._heap_offset >= HEAP_SCAN_SIZE then
        M._heap_offset = 0
    end

    return hits
end

function M.read_at(addr, max_len, enc)
    if not has_memory() or not addr or addr <= 0 then return "" end
    if enc == "utf16" then
        local buf = memory.read_buffer(addr, math.min((max_len or 64) * 2, 512))
        if not buf or buf == "" then return "" end
        local chars = {}
        for i = 1, #buf - 1, 2 do
            local b = string.byte(buf, i)
            if b == 0 then break end
            chars[#chars + 1] = string.char(b)
        end
        return table.concat(chars)
    end
    return memory.read_string(addr, max_len or 256) or ""
end

function M.write_bytes(addr, data)
    if not has_memory() or not addr or addr <= 0 or not data then return false end
    for i = 1, #data do
        local ok = pcall(memory.write, addr + i - 1, "uint8", string.byte(data, i))
        if not ok then return false end
    end
    return true
end

function M.write_at(addr, text, max_len, enc)
    if not has_memory() or not addr or addr <= 0 or not text then return false end

    if enc == "utf16" then
        local bytes = M.utf16_bytes(text)
        local limit = (max_len or #text) * 2
        if #bytes > limit then
            bytes = bytes:sub(1, limit)
        end
        bytes = bytes .. string.char(0, 0)
        return M.write_bytes(addr, bytes)
    end

    return pcall(memory.write_string, addr, text, max_len)
end

function M.random_alias(length)
    length = math.max(3, math.min(length or 12, 20))
    local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    local n = #chars
    local out = {}
    for i = 1, length do
        local r = math.random(1, n)
        out[i] = chars:sub(r, r)
    end
    return table.concat(out)
end

function M.pad_alias(alias, target_len)
    target_len = math.max(1, target_len or #alias)
    if #alias >= target_len then
        return alias:sub(1, target_len)
    end
    return alias .. string.rep("_", target_len - #alias)
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
M._cache_ttl = 30000

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

function M.find_items()
    local best, best_n = nil, 0
    M.each_table(function(v)
        local n = 0
        if type(v[1]) == "table" and v[1].Name and v[1].Image then
            for i = 1, #v do
                local entry = v[i]
                if type(entry) == "table" and entry.Name and entry.Image then
                    n = n + 1
                end
            end
        else
            for _, entry in pairs(v) do
                if type(entry) == "table" and entry.Name and entry.Image then
                    n = n + 1
                end
            end
        end
        if n > best_n and n >= 100 then
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

    local items = April.require("game.items")
    items.load()
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
    April.require("game.items").invalidate()
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
        cur = env.safe_call(function()
            return cur:find_first_child(name)
                or cur:FindFirstChild(name)
        end)
        if not env.is_valid(cur) then return nil end
    end
    return cur
end

function M.from_key(key)
    local path = M.PATHS[key]
    if not path then return nil end
    return M.get_folder(unpack(path))
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

-- ── game/item_images.lua ──
April._mods["game.item_images"] = (function()
-- AUTO-GENERATED by scripts/extract-item-catalog.mjs — do not edit by hand
-- Source: dump/scripts/ReplicatedStorage.Modules.Items.ModuleScript.lua

local M = {}

M.by_name = {
    ["%s\\'s Trophy"] = { default = "15274399715" },
    ["Admin Tool"] = { default = "16630443040" },
    ["Ammo Press"] = { default = "15061609857" },
    ["Animal Fat"] = { default = "15304534433" },
    ["Anvil"] = { default = "15082009292" },
    ["Armor Plate"] = { default = "126213314272257" },
    ["Armor Polish"] = { default = "106804025023012" },
    ["Armor Stand"] = { default = "80529735817758" },
    ["Auto Turret"] = { default = "92892387954820" },
    ["Balaclava"] = { default = "14654791788", variants = { ["Default"] = "14654791788", ["Jester"] = "15344534842", ["Frankenstein"] = "15883389666", ["Independence"] = "18341880885", ["Digital"] = "18965910197", ["Jolly"] = "129387971218495", ["Skull"] = "139941774966045", ["Monkey"] = "74568523494874", } },
    ["Bandage"] = { default = "14134567329" },
    ["Barrel Light"] = { default = "17508402018" },
    ["Base Cabinet"] = { default = "14653876852", variants = { ["Default"] = "14653876852", ["Server"] = "109131187101243", } },
    ["Baseball Cap"] = { default = "14654795325", variants = { ["Default"] = "14654795325", ["Quack"] = "16208669800", ["Independence"] = "18341880766", ["Propeller"] = "115535550124192", ["Pilgrim"] = "132977576727336", } },
    ["Bean Can"] = { default = "14162885124" },
    ["Bear Trap"] = { default = "16283811174" },
    ["Bed"] = { default = "15368539842", variants = { ["Default"] = "15368539842", ["Pixel"] = "125567129432156", } },
    ["Beef MRE"] = { default = "14162884919" },
    ["Black Keycard"] = { default = "115892814344173" },
    ["Blade"] = { default = "14651119220" },
    ["Blast Furnace"] = { default = "15876671239", variants = { ["Default"] = "15876671239", ["Robot"] = "18149216269", ["Steampunk"] = "113856439034974", } },
    ["Blueberries"] = { default = "17508520653" },
    ["Blueberry Pie I"] = { default = "17513319274" },
    ["Blueberry Pie II"] = { default = "17513319171" },
    ["Blueberry Pie III"] = { default = "17513318992" },
    ["Blueberry Pie IV"] = { default = "17513318548" },
    ["Blueberry Plant Seed"] = { default = "17357236681" },
    ["Blueprint"] = { default = "15132469785" },
    ["Bone Armor"] = { default = "119847143620647", variants = { ["Default"] = "119847143620647", } },
    ["Bone Arrow"] = { default = "13981013521" },
    ["Bone Shards"] = { default = "13207713694" },
    ["Bone Tool"] = { default = "15510368323", variants = { ["Default"] = "15510368323", } },
    ["Boots"] = { default = "14654795457", variants = { ["Default"] = "14654795457", ["Black"] = "15283152697", ["Abibas"] = "15305690697", ["Valentine"] = "16293022275", ["Woodland"] = "16473066174", ["Correctional"] = "92577755087375", ["Nutcracker"] = "102533866187536", ["Brutus"] = "124559624944530", ["Tundra"] = "75185734630840", ["Pilot"] = "134265072222654", ["Medal"] = "107412050354842", } },
    ["Boss Chestplate"] = { default = "16652581317", variants = { ["Default"] = "16652581317", ["Cryo"] = "106187507956822", ["Boris"] = "18354053691", ["Brutus"] = "120699966211693", } },
    ["Boss Helmet"] = { default = "16652579167", variants = { ["Default"] = "16652579167", ["Cryo"] = "102872157681930", ["Boris"] = "18312187080", ["Brutus"] = "134265072222654", } },
    ["Bottle Caps"] = { default = "14654996629" },
    ["Boulder"] = { default = "15304806846", variants = { ["Default"] = "15304806846", ["Bubblegum"] = "15304805303", ["Frosty"] = "15304805239", ["Tester"] = "15304805180", ["Voxel"] = "15574223076", ["Wrapped"] = "15712360641", ["Pixskull"] = "17766619061", ["Stellark"] = "97313343547804", ["Cursed"] = "92913832321996", ["Sushi"] = "78426403974796", ["Chocolate"] = "139716602333201", ["Moai"] = "115978938918724", ["Ducky"] = "124674000707337", ["Pumpkin"] = "126349162347833", ["Mosaic"] = "74510585736689", } },
    ["Bruno\\'s ACOG Sight"] = { default = "16671196298" },
    ["Bruno\\'s M4A1"] = { default = "15574295393", variants = { ["Default"] = "15574295393", } },
    ["Buckshot"] = { default = "13186566301" },
    ["Bunny Ears"] = { default = "16916795577", variants = { ["Default"] = "16916795577", } },
    ["Button"] = { default = "93858053715998" },
    ["Cactus Flesh"] = { default = "13219980518" },
    ["Campfire"] = { default = "15128008159", variants = { ["Default"] = "15128008159", ["Skulls"] = "133107732568884", } },
    ["Candle"] = { default = "117249643725742", variants = { ["Default"] = "117249643725742", ["Medium"] = "108927440959870", ["Large"] = "84899373039469", } },
    ["Candy Cane"] = { default = "15633196493", variants = { ["Default"] = "15633196493", } },
    ["Candy Roll"] = { default = "138463136634140" },
    ["Care Package Signal"] = { default = "15128007999" },
    ["Carpentry Table"] = { default = "15082010398" },
    ["Carrot Blade"] = { default = "16916703095", variants = { ["Default"] = "16916703095", } },
    ["Chainsaw"] = { default = "17201657737", variants = { ["Default"] = "17201657737", ["Recycle"] = "17357130465", } },
    ["Charcoal"] = { default = "13207713474" },
    ["Chemistry Lab"] = { default = "15074207343" },
    ["Chicken Egg"] = { default = "17497768025" },
    ["Chicken House"] = { default = "17499918454" },
    ["Chicken MRE"] = { default = "14162884663" },
    ["Chocolate Bar"] = { default = "14162884792" },
    ["Christmas Lights"] = { default = "134491722995587", variants = { ["Default"] = "134491722995587", } },
    ["Christmas Tree"] = { default = "15634564093", variants = { ["Default"] = "15634564093", } },
    ["Circuit Boards"] = { default = "14651118848" },
    ["Clan Table"] = { default = "74442604226077" },
    ["Cloth"] = { default = "13207713326" },
    ["Cloth Footwraps"] = { default = "14654794730", variants = { ["Default"] = "14654794730", ["Ninja"] = "132892877448790", } },
    ["Cloth Handwraps"] = { default = "14654831164", variants = { ["Default"] = "14654831164", ["Ninja"] = "114878511497747", } },
    ["Cloth Headwrap"] = { default = "14654795058", variants = { ["Default"] = "14654795058", ["Ninja"] = "120080222783269", } },
    ["Cloth Pants"] = { default = "14654794952", variants = { ["Default"] = "14654794952", ["Ninja"] = "88014133756226", } },
    ["Cloth Shirt"] = { default = "14654794835", variants = { ["Default"] = "14654794835", ["Ninja"] = "107568365412229", } },
    ["Collared Shirt"] = { default = "14654793432", variants = { ["Default"] = "14654793432", ["Business"] = "15444462393", ["Correctional"] = "140110401401547", ["Flannel"] = "97292443788852", } },
    ["Combination Lock"] = { default = "15305165381" },
    ["Combustive Arrow"] = { default = "13981013386" },
    ["Combustive Buckshot"] = { default = "13186565241" },
    ["Combustive Heavy Ammo"] = { default = "13186583441" },
    ["Combustive Rocket"] = { default = "15637959127" },
    ["Common Goodie Bag"] = { default = "118444522725158" },
    ["Compensator"] = { default = "15347108187" },
    ["Cooked Pork"] = { default = "15295773801" },
    ["Cooked Venison"] = { default = "13220221662" },
    ["Cooked Wolf"] = { default = "15295773801" },
    ["Cooking Pot"] = { default = "15127562373", variants = { ["Default"] = "15127562373", } },
    ["Copper Cogs"] = { default = "14651228837" },
    ["Corn"] = { default = "17412555936" },
    ["Corn Bread I"] = { default = "17513318249" },
    ["Corn Bread II"] = { default = "17513318071" },
    ["Corn Bread III"] = { default = "17513317915" },
    ["Corn Bread IV"] = { default = "17513317765" },
    ["Corn Plant Seed"] = { default = "17357236563" },
    ["Cow Pasture"] = { default = "17499917838" },
    ["Crossbow"] = { default = "15305596532", variants = { ["Default"] = "15305596532", ["Crossbones"] = "15305756728", ["HotDog"] = "15877969435", ["Emerald"] = "16751858634", ["Rose"] = "80803215254174", ["Toy"] = "102956782968040", ["Chief"] = "137062431435688", } },
    ["Crude Fuel"] = { default = "14651282157" },
    ["Crude Fuel Generator"] = { default = "117457710807147", variants = { ["Default"] = "117457710807147", } },
    ["Culinary Table"] = { default = "15061609707" },
    ["Cursed Pumpkin"] = { default = "74135087469069" },
    ["Diving Goggles"] = { default = "13842989638" },
    ["Diving Tank"] = { default = "13843003364" },
    ["Duct Tape"] = { default = "14651118525" },
    ["Dynamite Bundle"] = { default = "15127431071" },
    ["Dynamite Stick"] = { default = "15127430886" },
    ["Electric Furnace"] = { default = "71536889851799", variants = { ["Default"] = "71536889851799", ["ICBM"] = "115876027631434", } },
    ["Electric Heater"] = { default = "117015755787407", variants = { ["Default"] = "117015755787407", } },
    ["Empty Can"] = { default = "14594762895" },
    ["Epic Goodie Bag"] = { default = "93565798791105" },
    ["Explosive Shell"] = { default = "71411772918243" },
    ["Extended Mag"] = { default = "17286302189" },
    ["External Stone Gate"] = { default = "14134361372" },
    ["External Stone Wall"] = { default = "15709318091" },
    ["External Wooden Gate"] = { default = "15132487698" },
    ["External Wooden Wall"] = { default = "15132487460" },
    ["Fireplace"] = { default = "134438626724268", variants = { ["Default"] = "134438626724268", } },
    ["Fish Can"] = { default = "14162884523" },
    ["Flannel Jacket"] = { default = "14654794281", variants = { ["Default"] = "14654794281", ["Biker"] = "15877516070", ["Correctional"] = "100006176575349", ["Abibas"] = "138547747231782", } },
    ["Flippers"] = { default = "13843003596" },
    ["Floor Grill"] = { default = "15853202987" },
    ["Furnace"] = { default = "15074084708", variants = { ["Default"] = "15074084708", ["Banana"] = "15344532656", ["Glyphs"] = "15630767150", ["Gorilla"] = "16484587298", ["Burger"] = "84948985557474", ["Penguin"] = "122396159441498", ["Pumpkin"] = "81542845446759", } },
    ["Garage Door"] = { default = "16574547137", variants = { ["Default"] = "16574547137", ["Blob"] = "15509791543", ["Cryo"] = "113706556350765", ["Witch"] = "85491019952546", } },
    ["Glass Window"] = { default = "15210914495" },
    ["Glue"] = { default = "14651236358" },
    ["Gunpowder"] = { default = "15074277771" },
    ["Halloween Scythe"] = { default = "97593929634585" },
    ["Hammer"] = { default = "15318044673", variants = { ["Default"] = "15318044673", ["Toy"] = "15509809013", } },
    ["Hard Hat"] = { default = "14654794545", variants = { ["Default"] = "14654794545", ["Slurpee"] = "15950562586", } },
    ["Hazmat Suit"] = { default = "15046441717", variants = { ["Default"] = "15046441717", ["Snowman"] = "15712521421", ["Spark"] = "18965466357", ["Stellark"] = "123693400858947", ["Classified"] = "78801273340050", ["Front"] = "109185322610878", ["Guard"] = "113617571174399", ["Ducky"] = "116234383398695", ["Ghoul"] = "102977931837887", ["Specialist"] = "99406105774604", } },
    ["Heavy Ammo"] = { default = "13186564679" },
    ["Heavy Padding"] = { default = "136131316663930" },
    ["Holo Sight"] = { default = "14162721610" },
    ["Hoodie"] = { default = "14654794392", variants = { ["Default"] = "14654794392", ["Boris"] = "18312277063", ["Red"] = "15283152304", ["Purple"] = "15283152380", ["Green"] = "15283152598", ["Abibas"] = "15305689057", ["Wool"] = "15877516276", ["Valentine"] = "16293021303", ["Woodland"] = "16448119412", ["Tyrant"] = "130901964742021", ["Nutcracker"] = "72418266986929", ["Puffer"] = "71855339887230", ["Brutus"] = "116605401922894", ["Tundra"] = "94852483691948", ["Pilot"] = "134265072222654", ["Player"] = "72323540553042", ["Bee"] = "106663686372311", ["Night"] = "104718096945503", } },
    ["Horizontal Window Cover"] = { default = "15396925485" },
    ["Iron Ore"] = { default = "14308849053" },
    ["Iron Shard Hatchet"] = { default = "15073617640", variants = { ["Default"] = "15073617640", ["Fade"] = "16663953399", ["Sawblade"] = "18963884209", ["Leather"] = "82373698320243", } },
    ["Iron Shard Pickaxe"] = { default = "15073617491", variants = { ["Default"] = "15073617491", ["Fade"] = "16663949312", ["Leather"] = "99659875069484", } },
    ["Iron Shards"] = { default = "14184000696" },
    ["Jack-O-Lantern"] = { default = "139460860545325", variants = { ["Default"] = "139460860545325", ["Sad"] = "101370696376275", ["Happy"] = "130966939339167", } },
    ["Jail Door"] = { default = "13547704298" },
    ["Jail Wall"] = { default = "13547704099" },
    ["Jukebox"] = { default = "17343466496", variants = { ["Default"] = "17343466496", } },
    ["Ladder"] = { default = "15127607098", variants = { ["Default"] = "15127607098", } },
    ["Landmine Trap"] = { default = "16283811057" },
    ["Large Battery"] = { default = "78253036378845", variants = { ["Default"] = "78253036378845", } },
    ["Large Cobweb"] = { default = "104604287353224" },
    ["Large Furnace"] = { default = "15133678858", variants = { ["Default"] = "15133678858", } },
    ["Large Medkit"] = { default = "75730798424498" },
    ["Large Planter Box"] = { default = "17506371558" },
    ["Large Storage Box"] = { default = "15094083403", variants = { ["Default"] = "15094083403", ["Canvas"] = "15283200485", ["Festive"] = "15709683124", ["Forged"] = "17758887216", ["Coffin"] = "112688458744179", ["Ouja"] = "102172335761498", } },
    ["Large Wooden Sign"] = { default = "15509119053" },
    ["Leather"] = { default = "13207712789" },
    ["Leather Boots"] = { default = "14654794176", variants = { ["Default"] = "14654794176", ["Correctional"] = "95515905374532", } },
    ["Leather Gloves"] = { default = "14654794097", variants = { ["Default"] = "14654794097", ["Correctional"] = "92980178755471", ["Noir"] = "107804982630320", } },
    ["Leather Pants"] = { default = "14654793993", variants = { ["Default"] = "14654793993", ["Correctional"] = "108412621160578", } },
    ["Leather Poncho"] = { default = "14654793821", variants = { ["Default"] = "14654793821", ["Viva"] = "16208668209", ["Pilgrim"] = "98358561085174", } },
    ["Leather Shirt"] = { default = "14654793568", variants = { ["Default"] = "14654793568", ["Correctional"] = "109168692318343", } },
    ["Lemon"] = { default = "17508522472" },
    ["Lemon Cake I"] = { default = "17513316973" },
    ["Lemon Cake II"] = { default = "17513316847" },
    ["Lemon Cake III"] = { default = "17513316683" },
    ["Lemon Cake IV"] = { default = "17513316422" },
    ["Lemon Plant Seed"] = { default = "17357236426" },
    ["Light Ammo"] = { default = "13685818536" },
    ["Lighter"] = { default = "15128007580", variants = { ["Default"] = "15128007580", ["Lantern"] = "123377357974589", } },
    ["Lightweight Padding"] = { default = "96591489718879" },
    ["Loom"] = { default = "17517380322" },
    ["Machete"] = { default = "16249771824", variants = { ["Default"] = "16249771824", ["Rainbow"] = "16823202004", ["Crimson"] = "16912320468", ["Foam"] = "18761536955", ["Oni"] = "84793810931259", } },
    ["Marsh Bar"] = { default = "113016339245665" },
    ["Meatball Can"] = { default = "14162884362" },
    ["Medium Battery"] = { default = "129552454538184", variants = { ["Default"] = "129552454538184", } },
    ["Metal Barricade"] = { default = "15380991275" },
    ["Metal Door"] = { default = "15132832907", variants = { ["Default"] = "15132832907", ["Pixel"] = "15310965325", ["Frosty"] = "15304875360", ["Independence"] = "18341881259", ["Comic"] = "18444379748", ["Industrial"] = "78073516430678", ["Demon"] = "137869636615146", ["Bayou"] = "88981731583061", } },
    ["Metal Double Door"] = { default = "15132833297", variants = { ["Default"] = "15132833297", ["Pixel"] = "15310966370", ["Tropical"] = "16483738322", ["Nightwave"] = "119789304012674", } },
    ["Metal Plating"] = { default = "14651164157" },
    ["Metal Scraps"] = { default = "14651117901" },
    ["Metal Spikes"] = { default = "16484592502" },
    ["Metal Window Bars"] = { default = "15132553555" },
    ["Military AA12"] = { default = "15068791139", variants = { ["Default"] = "15068791139", ["Zombie"] = "17199281354", ["Monster"] = "136853604493538", } },
    ["Military ACOG Sight"] = { default = "15373701079" },
    ["Military Backpack"] = { default = "117242081838466", variants = { ["Default"] = "117242081838466", ["Tundra"] = "98126095773472", ["Abibas"] = "82640089227507", } },
    ["Military Barrett"] = { default = "15346280030", variants = { ["Default"] = "15346280030", ["Surge"] = "15876918136", ["Leprechaun"] = "16751857511", ["Mystra"] = "98792148092190", ["Fade"] = "73907766386158", ["Molten"] = "103075738835660", ["Cryo"] = "124741300378620", } },
    ["Military Boat"] = { default = "14183996624" },
    ["Military Chestplate"] = { default = "14654793303", variants = { ["Default"] = "14654793303", ["Nutcracker"] = "70853333750344", ["Pilot"] = "134265072222654", ["Medal"] = "81188910996008", } },
    ["Military Gloves"] = { default = "14654794652", variants = { ["Default"] = "14654794652", ["Nutcracker"] = "118158228480821", ["Arctic"] = "76148467345468", ["Pilot"] = "134265072222654", ["Grim"] = "123472167772965", ["Medal"] = "137375914230135", } },
    ["Military Grenade"] = { default = "15444535479" },
    ["Military Grenade Launcher"] = { default = "136030704871223", variants = { ["Default"] = "136030704871223", } },
    ["Military Helmet"] = { default = "14654793165", variants = { ["Default"] = "14654793165", ["Nutcracker"] = "80633563389909", ["Pilot"] = "134265072222654", ["Medal"] = "108938282129584", } },
    ["Military Lasersight"] = { default = "15510372535" },
    ["Military Leggings"] = { default = "14654792938", variants = { ["Default"] = "14654792938", ["Nutcracker"] = "84566720271674", ["Brutus"] = "75512320758936", ["Tundra"] = "86308809791688", ["Cryo"] = "88056077715569", ["Medal"] = "136956516639652", } },
    ["Military M39"] = { default = "74435081612082", variants = { ["Default"] = "74435081612082", ["Medusa"] = "117342321001432", ["Turkey"] = "111197339750272", } },
    ["Military M4A1"] = { default = "15346201415", variants = { ["Default"] = "15346201415", ["Syntax"] = "15951831122", ["Monster"] = "16663261126", ["Toy"] = "17521734560", ["Independence"] = "18341881006", ["Phantom"] = "139190777075295", ["Nutcracker"] = "136729540441664", ["Medusa"] = "101267874762837", ["Cryo"] = "94745687589547", ["CyberPop"] = "101893225757265", } },
    ["Military MP7"] = { default = "17607841424", variants = { ["Default"] = "17607841424", ["Fade"] = "18764670728", ["Whiteout"] = "112724849582854", ["Tyrant"] = "88901653074832", ["Wave"] = "108003941053496", ["Animeaster"] = "137259300477168", ["Solitare"] = "128296099845816", ["Grunge"] = "96361565266502", ["Zap"] = "126949129741030", } },
    ["Military PKM"] = { default = "16471125314", variants = { ["Default"] = "16471125314", ["Woodland"] = "16471122135", ["Resistance"] = "18149212335", ["Turbo"] = "18950918343", } },
    ["Military Sniper Scope"] = { default = "15304097316" },
    ["Military USP"] = { default = "85577075764668", variants = { ["Default"] = "85577075764668", ["Fade"] = "89094430760827", ["Azure"] = "74032961902891", } },
    ["Milk"] = { default = "17497767948" },
    ["Mining Drill"] = { default = "17287978593", variants = { ["Default"] = "17287978593", ["Recycle"] = "17357129069", ["Brick"] = "111424776562874", } },
    ["Muzzle Boost"] = { default = "15347107233" },
    ["Nail Gun"] = { default = "15305104734", variants = { ["Default"] = "15305104734", ["Striker"] = "15305729695", ["Magma"] = "15946260536", ["Wintrane"] = "114731373088561", } },
    ["Nails"] = { default = "13186564996" },
    ["Night Vision Goggles"] = { default = "97551543360376" },
    ["Pants"] = { default = "14654792590", variants = { ["Default"] = "14654792590", ["Boris"] = "18312279038", ["Khaki"] = "15283151856", ["Abibas"] = "15305689962", ["Valentine"] = "16293019822", ["Woodland"] = "16448121262", ["Correctional"] = "135793344308303", ["Tyrant"] = "136885851029799", ["Nutcracker"] = "71901466636387", ["Brutus"] = "85540429494017", ["Tundra"] = "90847059484754", ["Pilot"] = "134265072222654", ["Player"] = "129572575838612", ["Bee"] = "136553486453775", } },
    ["Peanut Butter Cup"] = { default = "77624523695187" },
    ["Petroleum"] = { default = "14651118356" },
    ["Petroleum Refinery"] = { default = "15304104065", variants = { ["Default"] = "15304104065", } },
    ["Phosphate Dust"] = { default = "14183996960" },
    ["Phosphate Ore"] = { default = "15132608151" },
    ["Piercing Heavy Ammo"] = { default = "13186565419" },
    ["Piercing Light Ammo"] = { default = "13186588755" },
    ["Pink Keycard"] = { default = "15247381747" },
    ["Pipe"] = { default = "14651117776" },
    ["Pistol Receiver"] = { default = "14651117642" },
    ["Power Cell"] = { default = "13187407477" },
    ["Propane Tank"] = { default = "13187406443" },
    ["Pumpkin"] = { default = "88626583598376" },
    ["Pumpkin Launcher"] = { default = "119532925295032" },
    ["Pumpkin Pie"] = { default = "84895386905458" },
    ["Pumpkin Plant Seed"] = { default = "121878490679837" },
    ["Purple Keycard"] = { default = "15247381544" },
    ["Purple Ornament"] = { default = "131580423003709" },
    ["Quality Iron Ore"] = { default = "14308848947" },
    ["Radiation Vitamins"] = { default = "15304290390" },
    ["Rare Goodie Bag"] = { default = "82913604650237" },
    ["Raspberries"] = { default = "17508521640" },
    ["Raspberry Pie I"] = { default = "17513317601" },
    ["Raspberry Pie II"] = { default = "17513317487" },
    ["Raspberry Pie III"] = { default = "17513317352" },
    ["Raspberry Pie IV"] = { default = "17513317172" },
    ["Raspberry Plant Seed"] = { default = "17357236197" },
    ["Raw Pork"] = { default = "15295774046" },
    ["Raw Venison"] = { default = "13220221327" },
    ["Raw Wolf"] = { default = "15295774046" },
    ["Red Keycard"] = { default = "18313788194" },
    ["Red Ornament"] = { default = "100403008362378" },
    ["Repair Table"] = { default = "15283452092", variants = { ["Default"] = "15283452092", } },
    ["Resistant Rubber"] = { default = "114763366778253" },
    ["Rifle Receiver"] = { default = "14651117496" },
    ["Rocket"] = { default = "15132772763" },
    ["Rope"] = { default = "14651117276" },
    ["Rug"] = { default = "17205250687", variants = { ["Default"] = "17205250687", ["Kraken"] = "17518134457", ["Independence"] = "18341881393", } },
    ["SMG Receiver"] = { default = "14651115848" },
    ["Salvaged AK47"] = { default = "14882620172", variants = { ["Default"] = "14882620172", ["Frosty"] = "15304886302", ["Vaporwave"] = "15574230457", ["Diablo"] = "16021791118", ["Fade"] = "79444477121964", ["Tyrant"] = "124312637758997", ["Gingerbread"] = "85687142665622", ["Ghillie"] = "132083989873001", ["Anodized"] = "80710562596890", ["CyberPop"] = "128785004285267", ["Oni"] = "105854184847862", ["Medal"] = "102460072725837", ["Dune"] = "83484244695308", } },
    ["Salvaged AK74u"] = { default = "15073408197", variants = { ["Default"] = "15073408197", ["Beast"] = "15305755800", ["Splash"] = "15509741616", ["VIP"] = "16014753591", ["Comic"] = "16114228051", ["Clover"] = "16748171046", ["Nebula"] = "17518135139", ["Tundra"] = "114982197234346", ["MP5"] = "78960618674854", ["Flarette"] = "125113179502352", ["Zombie"] = "101630769388124", } },
    ["Salvaged Backpack"] = { default = "80978101846806", variants = { ["Default"] = "80978101846806", ["Ducky"] = "84777906931514", } },
    ["Salvaged Break Action"] = { default = "15305085935", variants = { ["Default"] = "15305085935", ["Splat"] = "15305729191", ["HotDog"] = "15632163269", ["Boom"] = "16823202171", ["Carrot"] = "16917852163", ["Surf"] = "17766587211", } },
    ["Salvaged Chestplate"] = { default = "14654792418", variants = { ["Default"] = "14654792418", ["Cupid"] = "16261611092", ["Burnout"] = "18557168052", ["Tempest"] = "18966646034", } },
    ["Salvaged Double Barrel"] = { default = "132642766917853", variants = { ["Default"] = "132642766917853", ["Ducky"] = "140296796147704", ["HotDog"] = "86842880761011", } },
    ["Salvaged Explosive Shell"] = { default = "100468627382165" },
    ["Salvaged Flycopter"] = { default = "14183996624" },
    ["Salvaged Gloves"] = { default = "14654792260", variants = { ["Default"] = "14654792260", ["Cupid"] = "16261613114", ["Tempest"] = "18971460487", } },
    ["Salvaged Grenade Launcher"] = { default = "122319440938090", variants = { ["Default"] = "122319440938090", } },
    ["Salvaged Helmet"] = { default = "14654792150", variants = { ["Default"] = "14654792150", ["Cupid"] = "16261611838", ["Tempest"] = "18966646232", ["Cardboard"] = "71323845635099", } },
    ["Salvaged Lasersight"] = { default = "15347108897" },
    ["Salvaged Leggings"] = { default = "14654792046", variants = { ["Default"] = "14654792046", ["Cupid"] = "16261614321", ["Tempest"] = "18966645952", } },
    ["Salvaged M14"] = { default = "14882876522", variants = { ["Default"] = "14882876522", ["Paintball"] = "15305730875", ["Splat"] = "16031054728", ["Arcane"] = "17507702118", ["Stellark"] = "77123726699368", ["Huntsman"] = "121372881282577", ["Glitch"] = "82715807510122", ["Frog14"] = "133627766691157", } },
    ["Salvaged Metal Door"] = { default = "15132658803", variants = { ["Default"] = "15132658803", ["Visions"] = "15444463543", ["Graffiti"] = "16664082484", } },
    ["Salvaged P250"] = { default = "15305065991", variants = { ["Default"] = "15305065991", ["Splat"] = "15305728596", ["Fade"] = "15631601051", ["Peppermint"] = "15712513595", ["Sketch"] = "16208668754", ["Tempest"] = "18966645823", ["Festive"] = "101842524476750", ["Drift"] = "94234232543243", } },
    ["Salvaged Pipe Rifle"] = { default = "15073408081", variants = { ["Default"] = "15073408081", ["Surge"] = "15509721163", ["Gingerbread"] = "15638252851", ["Frost"] = "16208668377", ["Skyline"] = "18557168359", } },
    ["Salvaged Pump Action"] = { default = "15092313032", variants = { ["Default"] = "15092313032", ["Cyber"] = "91058444899439", ["Flurry"] = "138789905852084", } },
    ["Salvaged Python"] = { default = "15188995729", variants = { ["Default"] = "15188995729", ["Canvas"] = "15283200809", ["Hazard"] = "15305731383", ["Saku"] = "16029067988", ["Inferno"] = "16283806768", ["Shockwave"] = "17366304773", ["Independence"] = "18341881121", ["Stellark"] = "124497972716738", ["Hyper"] = "85697748071844", ["Smudge"] = "76952866923184", ["Medal"] = "128419932789140", } },
    ["Salvaged RPG"] = { default = "15132772506", variants = { ["Default"] = "15132772506", ["Blast"] = "15305772236", ["Boomstick"] = "18965877488", ["Festive"] = "81287503464820", } },
    ["Salvaged SMG"] = { default = "15132874040", variants = { ["Default"] = "15132874040", ["Splat"] = "15313314715", ["Inferno"] = "15883391466", ["Checkmate"] = "16114277804", ["Valentine"] = "16281529715", ["Knight"] = "17366143384", ["Tempest"] = "18966646387", ["Joker"] = "104734469891887", ["Ducky"] = "119924390182546", } },
    ["Salvaged Shell"] = { default = "127373719846093" },
    ["Salvaged Shotgun"] = { default = "128621428767531", variants = { ["Default"] = "128621428767531", ["Banana"] = "90420924851404", ["HotDog"] = "94732589170018", ["Camo"] = "85391407055752", } },
    ["Salvaged Shovel"] = { default = "15074352064" },
    ["Salvaged Sight"] = { default = "15283494417" },
    ["Salvaged Skorpion"] = { default = "15369212859", variants = { ["Default"] = "15369212859", ["Gingerbread"] = "15637191692", ["Superior"] = "15950161435", ["Pegasus"] = "16577230942", ["Surge"] = "18149214997", ["Rusty"] = "87710451691684", ["Comic"] = "103323135308928", ["Celestial"] = "102882157920367", } },
    ["Salvaged Sniper"] = { default = "74470836610605", variants = { ["Default"] = "74470836610605", ["Valentine"] = "134067753909583", ["Radioactive"] = "128500957974672", } },
    ["Salvaged Sniper Scope"] = { default = "15304097362" },
    ["Santa Hat"] = { default = "15636087096", variants = { ["Default"] = "15636087096", } },
    ["Saw Bat"] = { default = "16249771997" },
    ["Scarecrow"] = { default = "99382957417299" },
    ["Semi Receiver"] = { default = "14651116315" },
    ["Sewing Table"] = { default = "15061609510" },
    ["Shop Machine"] = { default = "16769451135", variants = { ["Default"] = "16769451135", } },
    ["Shorts"] = { default = "14654791921", variants = { ["Default"] = "14654791921", } },
    ["Shotgun Shell"] = { default = "90346230004065" },
    ["Shotgun Turret"] = { default = "16009975774" },
    ["Silencer"] = { default = "15347105863" },
    ["Sleeping Bag"] = { default = "15313154200", variants = { ["Default"] = "15313154200", ["Prismatic"] = "15574227229", ["Santa"] = "15715978392", ["Shark"] = "16117442613", ["Voxel"] = "18147427074", ["Spooky"] = "85015559308510", ["Fruit"] = "81952434018281", ["UwU"] = "96904970768142", ["Chocolate"] = "108416357231982", } },
    ["Slug"] = { default = "13186564525" },
    ["Small Battery"] = { default = "88959343384498", variants = { ["Default"] = "88959343384498", } },
    ["Small Cobweb"] = { default = "72444796789811" },
    ["Small Medkit"] = { default = "15086741523" },
    ["Small Planter Box"] = { default = "17506371372" },
    ["Small Storage Box"] = { default = "15094083341", variants = { ["Default"] = "15094083341", ["Monster"] = "15883290696", ["Comic"] = "16577230729", ["Gremlin"] = "16748563435", ["Burger"] = "95806776502625", ["Medical"] = "97915388339168", } },
    ["Small Wooden Sign"] = { default = "15509119765" },
    ["Snorkle"] = { default = "136407336127139" },
    ["Solar Panel"] = { default = "81539973869850", variants = { ["Default"] = "81539973869850", } },
    ["Splitter"] = { default = "119105209870894" },
    ["Spring"] = { default = "14651115579" },
    ["Steel Axe"] = { default = "13206734202", variants = { ["Default"] = "13206734202", ["Ruby"] = "15444465626", ["Freeze"] = "15712516834", ["Lava"] = "81357829552245", } },
    ["Steel Chestplate"] = { default = "14654791689", variants = { ["Default"] = "14654791689", ["Frosty"] = "15305683641", ["OBEY"] = "15305695517", ["Woodland"] = "16447572145", ["Tyrant"] = "140168023066476", ["Oni"] = "126974041982300", ["Dune"] = "105836010915280", } },
    ["Steel Door"] = { default = "15132554218", variants = { ["Default"] = "15132554218", ["Galactic"] = "16483736587", ["Tyrant"] = "90255972475887", ["Duck"] = "132207599970757", } },
    ["Steel Double Door"] = { default = "15132553963", variants = { ["Default"] = "15132553963", ["Vaporwave"] = "17199280862", } },
    ["Steel Glass Window"] = { default = "15132487922" },
    ["Steel Helmet"] = { default = "14654791532", variants = { ["Default"] = "14654791532", ["Golden"] = "15305714913", ["Frosty"] = "15305683226", ["OBEY"] = "15305695029", ["VIP"] = "16014684244", ["Cardboard"] = "15627624994", ["Woodland"] = "16447574211", ["Tyrant"] = "109539796004549", ["Bomo"] = "80249585885084", ["Hockey"] = "97015125505963", ["Fear"] = "81724456402833", ["Oni"] = "114978122703010", ["Dune"] = "72849082443137", } },
    ["Steel Leggings"] = { default = "14654791387", variants = { ["Default"] = "14654791387", ["Frosty"] = "15305684250", ["OBEY"] = "15311675719", ["Woodland"] = "16447575529", ["Tyrant"] = "79519920346999", ["Oni"] = "98478307520733", ["Dune"] = "76898574981463", } },
    ["Steel Metal"] = { default = "16252541108" },
    ["Steel Pickaxe"] = { default = "13206733920", variants = { ["Default"] = "13206733920", ["Cross"] = "15444466662", ["Freeze"] = "15712518908", ["Molten"] = "18762535576", } },
    ["Steel Shovel"] = { default = "15074351964", variants = { ["Default"] = "15074351964", } },
    ["Steel Toes"] = { default = "117409121428636" },
    ["Stone"] = { default = "14308848818" },
    ["Stone Hatchet"] = { default = "15073617325", variants = { ["Default"] = "15073617325", ["Molten"] = "15305732445", ["Shark"] = "16208668072", ["VIP"] = "16014755281", ["Valentine"] = "16281532811", ["Slime"] = "80657230310751", } },
    ["Stone Pickaxe"] = { default = "15073617163", variants = { ["Default"] = "15073617163", ["Molten"] = "15305731898", ["VIP"] = "16014754516", ["Valentine"] = "16281531919", } },
    ["Stone Spear"] = { default = "15303292549" },
    ["Storage Cabinet"] = { default = "15572100650", variants = { ["Default"] = "15572100650", ["Monster"] = "15631715604", ["Hades"] = "16293483340", ["Tyrant"] = "125396135034194", ["Server"] = "83936574533516", } },
    ["Swift Arrow"] = { default = "13981013848" },
    ["Swift Heavy Ammo"] = { default = "13186565740" },
    ["Swift Light Ammo"] = { default = "13186591166" },
    ["Swift Rocket"] = { default = "15637955888" },
    ["Switch"] = { default = "99819564678318" },
    ["Tank Top"] = { default = "14654791246", variants = { ["Default"] = "14654791246", } },
    ["Tarp"] = { default = "14651115367" },
    ["Thread"] = { default = "14651157447" },
    ["Timed Charge"] = { default = "13169199238" },
    ["Tomato"] = { default = "17412555272" },
    ["Tomato Plant Seed"] = { default = "17357235843" },
    ["Trap Door"] = { default = "13143032792", variants = { ["Default"] = "13143032792", } },
    ["Triangle Trap Door"] = { default = "13724822281", variants = { ["Default"] = "13724822281", } },
    ["Vertical Window Cover"] = { default = "15396925620" },
    ["Water Bottle"] = { default = "14162884193" },
    ["Water Filter"] = { default = "128444748129429" },
    ["Water Turbine"] = { default = "118840048689367", variants = { ["Default"] = "118840048689367", } },
    ["Weapon Flashlight"] = { default = "15373700419" },
    ["Wetsuit"] = { default = "15304093679", variants = { ["Default"] = "15304093679", ["Pink"] = "17363544575", ["Frog"] = "80603678790020", } },
    ["White Ornament"] = { default = "125029502429647" },
    ["Windmill"] = { default = "84509705966195", variants = { ["Default"] = "84509705966195", } },
    ["Wire Cutters"] = { default = "118552370695485" },
    ["Wood Log"] = { default = "14183996624" },
    ["Wooden Arrow"] = { default = "13981013657" },
    ["Wooden Boat"] = { default = "14183996624" },
    ["Wooden Bow"] = { default = "15313266356", variants = { ["Default"] = "15313266356", ["Cupid"] = "16260403928", ["Crimson"] = "16912320324", ["Dragon"] = "119198626388204", } },
    ["Wooden Chestplate"] = { default = "14776135830", variants = { ["Default"] = "14776135830", } },
    ["Wooden Door"] = { default = "15132568626", variants = { ["Default"] = "15132568626", ["Beware"] = "15305026376", ["Chocolate"] = "15712523927", ["Cardboard"] = "132805078818983", ["Pixel"] = "106378082611103", ["Wise"] = "101629446511815", } },
    ["Wooden Double Door"] = { default = "15132568988", variants = { ["Default"] = "15132568988", ["Rainbow"] = "15344501592", } },
    ["Wooden Helmet"] = { default = "14776135648", variants = { ["Default"] = "14776135648", } },
    ["Wooden Leggings"] = { default = "14776135514", variants = { ["Default"] = "14776135514", } },
    ["Wooden Lock"] = { default = "15305165322" },
    ["Wooden Spear"] = { default = "15303292373" },
    ["Wooden Spikes"] = { default = "15380989444" },
    ["Wooden Window Bars"] = { default = "15128007380" },
    ["Wool"] = { default = "17499807914" },
    ["Wool Plant Seed"] = { default = "17357235671" },
    ["Wreath"] = { default = "125156247966096", variants = { ["Default"] = "125156247966096", } },
    ["Yellow Keycard"] = { default = "15247381343" },
    ["ez shovel"] = { default = "13877485530" },
}

function M.get_asset_id(name, variant)
    local row = name and M.by_name[name]
    if not row then return nil end
    if variant and row.variants and row.variants[variant] then
        return row.variants[variant]
    end
    return row.default
end

return M

end)()

-- ── game/item_catalog.lua ──
April._mods["game.item_catalog"] = (function()
-- AUTO-GENERATED by scripts/extract-item-catalog.mjs — do not edit by hand
-- Items: 341 entries from dump

local M = {}

M.by_id = {
    [1] = { name = "Wood Log", type = "Resource" },
    [2] = { name = "Bandage", type = "Tool" },
    [3] = { name = "Stone Hatchet", type = "Tool" },
    [4] = { name = "Heavy Ammo", type = "Ammo" },
    [5] = { name = "Salvaged AK47", type = "Gun" },
    [6] = { name = "Bottle Caps", type = "Resource" },
    [7] = { name = "Holo Sight", type = "Attachment" },
    [8] = { name = "Silencer", type = "Attachment" },
    [9] = { name = "Salvaged M14", type = "Gun" },
    [10] = { name = "Lighter", type = "Tool" },
    [11] = { name = "Swift Heavy Ammo", type = "Ammo" },
    [12] = { name = "Salvaged Sight", type = "Attachment" },
    [13] = { name = "Muzzle Boost", type = "Attachment" },
    [14] = { name = "Compensator", type = "Attachment" },
    [15] = { name = "Salvaged Lasersight", type = "Attachment" },
    [16] = { name = "Weapon Flashlight", type = "Attachment" },
    [17] = { name = "Salvaged Sniper Scope", type = "Attachment" },
    [18] = { name = "Military Sniper Scope", type = "Attachment" },
    [19] = { name = "Wooden Spear", type = "Tool" },
    [20] = { name = "Stone Spear", type = "Tool" },
    [21] = { name = "Stone Pickaxe", type = "Tool" },
    [22] = { name = "Crossbow", type = "Gun" },
    [23] = { name = "Wooden Bow", type = "Gun" },
    [24] = { name = "Cloth", type = "Resource" },
    [25] = { name = "Cactus Flesh", type = "Consumable" },
    [26] = { name = "Stone", type = "Resource" },
    [27] = { name = "Iron Ore", type = "Resource" },
    [28] = { name = "Quality Iron Ore", type = "Resource" },
    [29] = { name = "Campfire", type = "Bench" },
    [30] = { name = "Blueprint", type = "Tool" },
    [31] = { name = "Hammer", type = "Tool" },
    [32] = { name = "Raw Pork", type = "Consumable" },
    [33] = { name = "Cooked Pork", type = "Consumable" },
    [34] = { name = "Charcoal", type = "Resource" },
    [35] = { name = "Salvaged P250", type = "Gun" },
    [36] = { name = "Light Ammo", type = "Ammo" },
    [37] = { name = "Boulder", type = "Tool" },
    [38] = { name = "Salvaged SMG", type = "Gun" },
    [39] = { name = "Salvaged Python", type = "Gun" },
    [40] = { name = "Combustive Heavy Ammo", type = "Ammo" },
    [41] = { name = "Animal Fat", type = "Resource" },
    [42] = { name = "Small Storage Box", type = "Bench" },
    [43] = { name = "Raw Venison", type = "Consumable" },
    [44] = { name = "Cooked Venison", type = "Consumable" },
    [45] = { name = "Iron Shards", type = "Resource" },
    [46] = { name = "Steel Metal", type = "Resource" },
    [47] = { name = "Wooden Door", type = "Bench" },
    [48] = { name = "Wooden Lock", type = "Lock" },
    [49] = { name = "Combination Lock", type = "Lock" },
    [50] = { name = "Salvaged Metal Door", type = "Bench" },
    [51] = { name = "Base Cabinet", type = "Bench" },
    [52] = { name = "Wooden Double Door", type = "Bench" },
    [53] = { name = "Wooden Window Bars", type = "Bench" },
    [54] = { name = "Metal Window Bars", type = "Bench" },
    [55] = { name = "Glass Window", type = "Bench" },
    [56] = { name = "Steel Glass Window", type = "Bench" },
    [57] = { name = "Trap Door", type = "Bench" },
    [58] = { name = "Radiation Vitamins", type = "Consumable" },
    [59] = { name = "Hoodie", type = "Armor", armor_type = "Shirt" },
    [60] = { name = "Hazmat Suit", type = "Armor", armor_type = "All", attribute = "ResistWet" },
    [61] = { name = "Chicken MRE", type = "Consumable" },
    [62] = { name = "Beef MRE", type = "Consumable" },
    [63] = { name = "Pants", type = "Armor", armor_type = "Pants" },
    [64] = { name = "Phosphate Ore", type = "Resource" },
    [65] = { name = "Phosphate Dust", type = "Resource" },
    [66] = { name = "Leather", type = "Resource" },
    [67] = { name = "Furnace", type = "Bench" },
    [68] = { name = "Crude Fuel", type = "Resource" },
    [69] = { name = "Gunpowder", type = "Resource" },
    [70] = { name = "Bone Shards", type = "Resource" },
    [71] = { name = "Metal Door", type = "Bench" },
    [72] = { name = "Metal Double Door", type = "Bench" },
    [73] = { name = "Steel Door", type = "Bench" },
    [74] = { name = "Steel Double Door", type = "Bench" },
    [75] = { name = "Nail Gun", type = "Gun" },
    [76] = { name = "Steel Axe", type = "Tool" },
    [77] = { name = "Steel Pickaxe", type = "Tool" },
    [78] = { name = "Power Cell", type = "Misc" },
    [79] = { name = "Copper Cogs", type = "Misc" },
    [80] = { name = "Pipe", type = "Misc" },
    [81] = { name = "Propane Tank", type = "Misc" },
    [82] = { name = "Rope", type = "Misc" },
    [83] = { name = "Blade", type = "Misc" },
    [84] = { name = "Thread", type = "Misc" },
    [85] = { name = "Metal Plating", type = "Misc" },
    [86] = { name = "Spring", type = "Misc" },
    [87] = { name = "Tarp", type = "Misc" },
    [88] = { name = "Circuit Boards", type = "Misc" },
    [89] = { name = "Metal Scraps", type = "Misc" },
    [90] = { name = "Swift Light Ammo", type = "Ammo" },
    [91] = { name = "Sleeping Bag", type = "Bench" },
    [92] = { name = "Timed Charge", type = "Tool" },
    [93] = { name = "Nails", type = "Ammo" },
    [94] = { name = "Garage Door", type = "Bench" },
    [95] = { name = "Dynamite Bundle", type = "Tool" },
    [96] = { name = "Dynamite Stick", type = "Tool" },
    [97] = { name = "Salvaged RPG", type = "Gun" },
    [98] = { name = "Rocket", type = "Ammo" },
    [99] = { name = "Swift Rocket", type = "Ammo" },
    [100] = { name = "Combustive Rocket", type = "Ammo" },
    [101] = { name = "External Wooden Wall", type = "Bench" },
    [102] = { name = "External Wooden Gate", type = "Bench" },
    [103] = { name = "Vertical Window Cover", type = "Bench" },
    [104] = { name = "Horizontal Window Cover", type = "Bench" },
    [105] = { name = "Jail Wall", type = "Bench" },
    [106] = { name = "Jail Door", type = "Bench" },
    [107] = { name = "%s\\'s Trophy", type = "Bench" },
    [108] = { name = "Salvaged AK74u", type = "Gun" },
    [109] = { name = "Salvaged Pipe Rifle", type = "Gun" },
    [110] = { name = "Petroleum", type = "Resource" },
    [111] = { name = "Boots", type = "Armor", armor_type = "Boots" },
    [112] = { name = "Collared Shirt", type = "Armor", armor_type = "Shirt" },
    [113] = { name = "Shorts", type = "Armor", armor_type = "Pants" },
    [114] = { name = "Tank Top", type = "Armor", armor_type = "Shirt" },
    [115] = { name = "Cloth Shirt", type = "Armor", armor_type = "Shirt" },
    [116] = { name = "Cloth Pants", type = "Armor", armor_type = "Pants" },
    [117] = { name = "Cloth Footwraps", type = "Armor", armor_type = "Boots" },
    [118] = { name = "Leather Poncho", type = "Armor", armor_type = "Chestplate" },
    [119] = { name = "Leather Pants", type = "Armor", armor_type = "Pants" },
    [120] = { name = "Leather Shirt", type = "Armor", armor_type = "Shirt" },
    [121] = { name = "Leather Boots", type = "Armor", armor_type = "Boots" },
    [122] = { name = "Flannel Jacket", type = "Armor", armor_type = "Chestplate" },
    [123] = { name = "Wooden Helmet", type = "Armor", armor_type = "Hat" },
    [124] = { name = "Wooden Chestplate", type = "Armor", armor_type = "Chestplate" },
    [125] = { name = "Wooden Leggings", type = "Armor", armor_type = "Kilt" },
    [126] = { name = "Wooden Arrow", type = "Ammo" },
    [127] = { name = "Swift Arrow", type = "Ammo" },
    [128] = { name = "Bone Arrow", type = "Ammo" },
    [129] = { name = "Combustive Arrow", type = "Ammo" },
    [130] = { name = "Iron Shard Hatchet", type = "Tool" },
    [131] = { name = "Iron Shard Pickaxe", type = "Tool" },
    [132] = { name = "Large Furnace", type = "Bench" },
    [133] = { name = "Yellow Keycard", type = "Tool" },
    [134] = { name = "Purple Keycard", type = "Tool" },
    [135] = { name = "Pink Keycard", type = "Tool" },
    [136] = { name = "Small Medkit", type = "Tool" },
    [137] = { name = "Salvaged Break Action", type = "Gun" },
    [138] = { name = "Buckshot", type = "Ammo" },
    [139] = { name = "Slug", type = "Ammo" },
    [140] = { name = "Combustive Buckshot", type = "Ammo" },
    [141] = { name = "Steel Helmet", type = "Armor", armor_type = "Helmet" },
    [142] = { name = "Steel Chestplate", type = "Armor", armor_type = "Chestplate" },
    [143] = { name = "Steel Leggings", type = "Armor", armor_type = "Kilt" },
    [144] = { name = "Large Storage Box", type = "Bench" },
    [145] = { name = "Salvaged Helmet", type = "Armor", armor_type = "Helmet" },
    [146] = { name = "Salvaged Chestplate", type = "Armor", armor_type = "Chestplate" },
    [147] = { name = "Salvaged Leggings", type = "Armor", armor_type = "Kilt" },
    [148] = { name = "Military Helmet", type = "Armor", armor_type = "Helmet" },
    [149] = { name = "Military Chestplate", type = "Armor", armor_type = "Chestplate" },
    [150] = { name = "Military Leggings", type = "Armor", armor_type = "Kilt" },
    [151] = { name = "Hard Hat", type = "Armor", armor_type = "Hat" },
    [152] = { name = "Balaclava", type = "Armor", armor_type = "Face" },
    [153] = { name = "Cloth Headwrap", type = "Armor", armor_type = "Helmet" },
    [154] = { name = "Baseball Cap", type = "Armor", armor_type = "Hat" },
    [155] = { name = "Salvaged Gloves", type = "Armor", armor_type = "Gloves" },
    [156] = { name = "Cloth Handwraps", type = "Armor", armor_type = "Gloves" },
    [157] = { name = "Military Gloves", type = "Armor", armor_type = "Gloves" },
    [158] = { name = "Leather Gloves", type = "Armor", armor_type = "Gloves" },
    [159] = { name = "Wetsuit", type = "Armor", armor_type = "Wetsuit", attribute = "ResistWet" },
    [160] = { name = "Flippers", type = "Armor", armor_type = "Boots", attribute = "HasFlippers" },
    [161] = { name = "Diving Tank", type = "Armor", armor_type = "Chestplate", attribute = "HasTank" },
    [162] = { name = "Diving Goggles", type = "Armor", armor_type = "Helmet", attribute = "HasGoggles" },
    [163] = { name = "Cooking Pot", type = "Bench" },
    [164] = { name = "Ladder", type = "Bench" },
    [165] = { name = "Chocolate Bar", type = "Consumable" },
    [166] = { name = "Bean Can", type = "Consumable" },
    [167] = { name = "Meatball Can", type = "Consumable" },
    [168] = { name = "Fish Can", type = "Consumable" },
    [169] = { name = "Water Bottle", type = "Consumable" },
    [170] = { name = "Piercing Heavy Ammo", type = "Ammo" },
    [171] = { name = "Piercing Light Ammo", type = "Ammo" },
    [172] = { name = "Semi Receiver", type = "Misc" },
    [173] = { name = "SMG Receiver", type = "Misc" },
    [174] = { name = "Rifle Receiver", type = "Misc" },
    [175] = { name = "Steel Shovel", type = "Tool" },
    [176] = { name = "Empty Can", type = "Misc" },
    [177] = { name = "Care Package Signal", type = "Tool" },
    [178] = { name = "Duct Tape", type = "Misc" },
    [179] = { name = "Glue", type = "Misc" },
    [180] = { name = "Pistol Receiver", type = "Misc" },
    [181] = { name = "Salvaged Shovel", type = "Tool" },
    [182] = { name = "ez shovel", type = "Tool" },
    [183] = { name = "Anvil", type = "Bench" },
    [184] = { name = "Chemistry Lab", type = "Bench" },
    [185] = { name = "Carpentry Table", type = "Bench" },
    [186] = { name = "Sewing Table", type = "Bench" },
    [187] = { name = "Ammo Press", type = "Bench" },
    [188] = { name = "Culinary Table", type = "Bench" },
    [189] = { name = "Petroleum Refinery", type = "Bench" },
    [190] = { name = "Triangle Trap Door", type = "Bench" },
    [191] = { name = "Military AA12", type = "Gun" },
    [192] = { name = "Repair Table", type = "Bench" },
    [193] = { name = "Salvaged Pump Action", type = "Gun" },
    [194] = { name = "Bed", type = "Bench" },
    [195] = { name = "Wooden Spikes", type = "Bench" },
    [196] = { name = "Military ACOG Sight", type = "Attachment" },
    [197] = { name = "Metal Barricade", type = "Bench" },
    [198] = { name = "Military M4A1", type = "Gun" },
    [199] = { name = "Small Wooden Sign", type = "Bench" },
    [200] = { name = "Large Wooden Sign", type = "Bench" },
    [201] = { name = "Storage Cabinet", type = "Bench" },
    [202] = { name = "External Stone Gate", type = "Bench" },
    [203] = { name = "Bone Tool", type = "Tool" },
    [204] = { name = "Salvaged Skorpion", type = "Gun" },
    [205] = { name = "Candy Cane", type = "Tool" },
    [206] = { name = "Christmas Tree", type = "Bench" },
    [207] = { name = "Santa Hat", type = "Armor", armor_type = "Hat" },
    [208] = { name = "External Stone Wall", type = "Bench" },
    [209] = { name = "Blast Furnace", type = "Bench" },
    [210] = { name = "Military Barrett", type = "Gun" },
    [211] = { name = "Shotgun Turret", type = "Bench" },
    [212] = { name = "Military Grenade", type = "Tool" },
    [213] = { name = "Floor Grill", type = "Bench" },
    [214] = { name = "Bear Trap", type = "Bench" },
    [215] = { name = "Landmine Trap", type = "Bench" },
    [216] = { name = "Saw Bat", type = "Tool" },
    [217] = { name = "Machete", type = "Tool" },
    [218] = { name = "Military PKM", type = "Gun" },
    [219] = { name = "Bruno\\'s ACOG Sight", type = "Attachment" },
    [220] = { name = "Military Lasersight", type = "Attachment" },
    [221] = { name = "Bruno\\'s M4A1", type = "Gun" },
    [222] = { name = "Boss Chestplate", type = "Armor", armor_type = "Chestplate" },
    [223] = { name = "Boss Helmet", type = "Armor", armor_type = "Helmet" },
    [224] = { name = "Bunny Ears", type = "Armor", armor_type = "Hat" },
    [225] = { name = "Carrot Blade", type = "Tool" },
    [226] = { name = "Metal Spikes", type = "Bench" },
    [227] = { name = "Rug", type = "Bench" },
    [228] = { name = "Shop Machine", type = "Bench" },
    [229] = { name = "Chainsaw", type = "Tool" },
    [230] = { name = "Mining Drill", type = "Tool" },
    [231] = { name = "Extended Mag", type = "Attachment" },
    [232] = { name = "Jukebox", type = "Bench" },
    [233] = { name = "Wool Plant Seed", type = "Bench" },
    [234] = { name = "Wool", type = "Resource" },
    [235] = { name = "Loom", type = "Bench" },
    [236] = { name = "Small Planter Box", type = "Bench" },
    [237] = { name = "Large Planter Box", type = "Bench" },
    [238] = { name = "Tomato Plant Seed", type = "Bench" },
    [239] = { name = "Corn Plant Seed", type = "Bench" },
    [240] = { name = "Tomato", type = "Consumable" },
    [241] = { name = "Corn", type = "Consumable" },
    [242] = { name = "Chicken Egg", type = "Consumable" },
    [243] = { name = "Milk", type = "Consumable" },
    [244] = { name = "Raspberry Pie I", type = "Consumable" },
    [245] = { name = "Raspberry Pie II", type = "Consumable" },
    [246] = { name = "Raspberry Pie III", type = "Consumable" },
    [247] = { name = "Raspberry Pie IV", type = "Consumable" },
    [248] = { name = "Blueberry Pie I", type = "Consumable" },
    [249] = { name = "Blueberry Pie II", type = "Consumable" },
    [250] = { name = "Blueberry Pie III", type = "Consumable" },
    [251] = { name = "Blueberry Pie IV", type = "Consumable" },
    [252] = { name = "Lemon Cake I", type = "Consumable" },
    [253] = { name = "Lemon Cake II", type = "Consumable" },
    [254] = { name = "Lemon Cake III", type = "Consumable" },
    [255] = { name = "Lemon Cake IV", type = "Consumable" },
    [256] = { name = "Corn Bread I", type = "Consumable" },
    [257] = { name = "Corn Bread II", type = "Consumable" },
    [258] = { name = "Corn Bread III", type = "Consumable" },
    [259] = { name = "Corn Bread IV", type = "Consumable" },
    [260] = { name = "Cow Pasture", type = "Bench" },
    [261] = { name = "Chicken House", type = "Bench" },
    [262] = { name = "Barrel Light", type = "Bench" },
    [263] = { name = "Raspberries", type = "Consumable" },
    [264] = { name = "Blueberries", type = "Consumable" },
    [265] = { name = "Lemon", type = "Consumable" },
    [266] = { name = "Lemon Plant Seed", type = "Bench" },
    [267] = { name = "Raspberry Plant Seed", type = "Bench" },
    [268] = { name = "Blueberry Plant Seed", type = "Bench" },
    [269] = { name = "Military MP7", type = "Gun" },
    [270] = { name = "Red Keycard", type = "Tool" },
    [271] = { name = "Salvaged Double Barrel", type = "Gun" },
    [272] = { name = "Military Boat", type = "Resource" },
    [273] = { name = "Clan Table", type = "Bench" },
    [274] = { name = "Wooden Boat", type = "Resource" },
    [275] = { name = "Military USP", type = "Gun" },
    [276] = { name = "Common Goodie Bag", type = "Misc" },
    [277] = { name = "Rare Goodie Bag", type = "Misc" },
    [278] = { name = "Epic Goodie Bag", type = "Misc" },
    [279] = { name = "Candle", type = "Bench" },
    [280] = { name = "Armor Stand", type = "Bench" },
    [281] = { name = "Jack-O-Lantern", type = "Bench" },
    [282] = { name = "Small Cobweb", type = "Bench" },
    [283] = { name = "Large Cobweb", type = "Bench" },
    [284] = { name = "Pumpkin Plant Seed", type = "Bench" },
    [285] = { name = "Pumpkin", type = "ConsumableAmmoArmor", armor_type = "Helmet" },
    [286] = { name = "Halloween Scythe", type = "Tool" },
    [287] = { name = "Pumpkin Launcher", type = "Gun" },
    [288] = { name = "Raw Wolf", type = "Consumable" },
    [289] = { name = "Cooked Wolf", type = "Consumable" },
    [290] = { name = "Pumpkin Pie", type = "Consumable" },
    [291] = { name = "Cursed Pumpkin", type = "Ammo" },
    [292] = { name = "Marsh Bar", type = "Consumable" },
    [293] = { name = "Peanut Butter Cup", type = "Consumable" },
    [294] = { name = "Candy Roll", type = "Consumable" },
    [295] = { name = "Scarecrow", type = "Bench" },
    [296] = { name = "Salvaged Shotgun", type = "Gun" },
    [297] = { name = "Salvaged Shell", type = "Ammo" },
    [298] = { name = "Bone Armor", type = "Armor", armor_type = "All" },
    [299] = { name = "Armor Plate", type = "Attachment" },
    [300] = { name = "Heavy Padding", type = "Attachment" },
    [301] = { name = "Night Vision Goggles", type = "Attachment", attribute = "NVG" },
    [302] = { name = "Lightweight Padding", type = "Attachment", attribute = "SilentSteps" },
    [303] = { name = "Resistant Rubber", type = "Attachment" },
    [304] = { name = "Armor Polish", type = "Attachment" },
    [305] = { name = "Water Filter", type = "Attachment", attribute = "WaterFilter" },
    [306] = { name = "Steel Toes", type = "Attachment", attribute = "SteelToes" },
    [307] = { name = "Snorkle", type = "Attachment", attribute = "Snorkle" },
    [308] = { name = "Military Backpack", type = "Backpack" },
    [309] = { name = "Salvaged Backpack", type = "Backpack" },
    [310] = { name = "Salvaged Sniper", type = "Gun" },
    [311] = { name = "Military Grenade Launcher", type = "Gun" },
    [312] = { name = "Explosive Shell", type = "Ammo" },
    [313] = { name = "Salvaged Flycopter", type = "Resource" },
    [314] = { name = "Fireplace", type = "Bench" },
    [315] = { name = "Black Keycard", type = "Tool" },
    [316] = { name = "Salvaged Grenade Launcher", type = "Gun" },
    [317] = { name = "Salvaged Explosive Shell", type = "Ammo" },
    [318] = { name = "Shotgun Shell", type = "Ammo" },
    [319] = { name = "Large Medkit", type = "Consumable" },
    [320] = { name = "Small Battery", type = "Bench" },
    [321] = { name = "Medium Battery", type = "Bench" },
    [322] = { name = "Large Battery", type = "Bench" },
    [323] = { name = "Crude Fuel Generator", type = "Bench" },
    [324] = { name = "Solar Panel", type = "Bench" },
    [325] = { name = "Water Turbine", type = "Bench" },
    [326] = { name = "Wire Cutters", type = "Tool" },
    [327] = { name = "Button", type = "Bench" },
    [328] = { name = "Electric Furnace", type = "Bench" },
    [329] = { name = "Electric Heater", type = "Bench" },
    [330] = { name = "Switch", type = "Bench" },
    [331] = { name = "Windmill", type = "Bench" },
    [332] = { name = "Splitter", type = "Bench" },
    [333] = { name = "Military Boat", type = "Resource" },
    [334] = { name = "Auto Turret", type = "Bench" },
    [335] = { name = "Military M39", type = "Gun" },
    [336] = { name = "White Ornament", type = "Resource" },
    [337] = { name = "Red Ornament", type = "Resource" },
    [338] = { name = "Purple Ornament", type = "Resource" },
    [339] = { name = "Wreath", type = "Bench" },
    [340] = { name = "Christmas Lights", type = "Bench" },
    [341] = { name = "Admin Tool", type = "Tool" },
}

M.by_attribute = {
    ["HasFlippers"] = "Flippers",
    ["HasGoggles"] = "Diving Goggles",
    ["HasTank"] = "Diving Tank",
    ["NVG"] = "Night Vision Goggles",
    ["ResistWet"] = "Wetsuit",
    ["SilentSteps"] = "Lightweight Padding",
    ["Snorkle"] = "Snorkle",
    ["SteelToes"] = "Steel Toes",
    ["WaterFilter"] = "Water Filter",
}

M.by_name = {
    ["Wood Log"] = { id = 1, type = "Resource" },
    ["Bandage"] = { id = 2, type = "Tool" },
    ["Stone Hatchet"] = { id = 3, type = "Tool" },
    ["Heavy Ammo"] = { id = 4, type = "Ammo" },
    ["Salvaged AK47"] = { id = 5, type = "Gun" },
    ["Bottle Caps"] = { id = 6, type = "Resource" },
    ["Holo Sight"] = { id = 7, type = "Attachment" },
    ["Silencer"] = { id = 8, type = "Attachment" },
    ["Salvaged M14"] = { id = 9, type = "Gun" },
    ["Lighter"] = { id = 10, type = "Tool" },
    ["Swift Heavy Ammo"] = { id = 11, type = "Ammo" },
    ["Salvaged Sight"] = { id = 12, type = "Attachment" },
    ["Muzzle Boost"] = { id = 13, type = "Attachment" },
    ["Compensator"] = { id = 14, type = "Attachment" },
    ["Salvaged Lasersight"] = { id = 15, type = "Attachment" },
    ["Weapon Flashlight"] = { id = 16, type = "Attachment" },
    ["Salvaged Sniper Scope"] = { id = 17, type = "Attachment" },
    ["Military Sniper Scope"] = { id = 18, type = "Attachment" },
    ["Wooden Spear"] = { id = 19, type = "Tool" },
    ["Stone Spear"] = { id = 20, type = "Tool" },
    ["Stone Pickaxe"] = { id = 21, type = "Tool" },
    ["Crossbow"] = { id = 22, type = "Gun" },
    ["Wooden Bow"] = { id = 23, type = "Gun" },
    ["Cloth"] = { id = 24, type = "Resource" },
    ["Cactus Flesh"] = { id = 25, type = "Consumable" },
    ["Stone"] = { id = 26, type = "Resource" },
    ["Iron Ore"] = { id = 27, type = "Resource" },
    ["Quality Iron Ore"] = { id = 28, type = "Resource" },
    ["Campfire"] = { id = 29, type = "Bench" },
    ["Blueprint"] = { id = 30, type = "Tool" },
    ["Hammer"] = { id = 31, type = "Tool" },
    ["Raw Pork"] = { id = 32, type = "Consumable" },
    ["Cooked Pork"] = { id = 33, type = "Consumable" },
    ["Charcoal"] = { id = 34, type = "Resource" },
    ["Salvaged P250"] = { id = 35, type = "Gun" },
    ["Light Ammo"] = { id = 36, type = "Ammo" },
    ["Boulder"] = { id = 37, type = "Tool" },
    ["Salvaged SMG"] = { id = 38, type = "Gun" },
    ["Salvaged Python"] = { id = 39, type = "Gun" },
    ["Combustive Heavy Ammo"] = { id = 40, type = "Ammo" },
    ["Animal Fat"] = { id = 41, type = "Resource" },
    ["Small Storage Box"] = { id = 42, type = "Bench" },
    ["Raw Venison"] = { id = 43, type = "Consumable" },
    ["Cooked Venison"] = { id = 44, type = "Consumable" },
    ["Iron Shards"] = { id = 45, type = "Resource" },
    ["Steel Metal"] = { id = 46, type = "Resource" },
    ["Wooden Door"] = { id = 47, type = "Bench" },
    ["Wooden Lock"] = { id = 48, type = "Lock" },
    ["Combination Lock"] = { id = 49, type = "Lock" },
    ["Salvaged Metal Door"] = { id = 50, type = "Bench" },
    ["Base Cabinet"] = { id = 51, type = "Bench" },
    ["Wooden Double Door"] = { id = 52, type = "Bench" },
    ["Wooden Window Bars"] = { id = 53, type = "Bench" },
    ["Metal Window Bars"] = { id = 54, type = "Bench" },
    ["Glass Window"] = { id = 55, type = "Bench" },
    ["Steel Glass Window"] = { id = 56, type = "Bench" },
    ["Trap Door"] = { id = 57, type = "Bench" },
    ["Radiation Vitamins"] = { id = 58, type = "Consumable" },
    ["Hoodie"] = { id = 59, type = "Armor", armor_type = "Shirt" },
    ["Hazmat Suit"] = { id = 60, type = "Armor", armor_type = "All", attribute = "ResistWet" },
    ["Chicken MRE"] = { id = 61, type = "Consumable" },
    ["Beef MRE"] = { id = 62, type = "Consumable" },
    ["Pants"] = { id = 63, type = "Armor", armor_type = "Pants" },
    ["Phosphate Ore"] = { id = 64, type = "Resource" },
    ["Phosphate Dust"] = { id = 65, type = "Resource" },
    ["Leather"] = { id = 66, type = "Resource" },
    ["Furnace"] = { id = 67, type = "Bench" },
    ["Crude Fuel"] = { id = 68, type = "Resource" },
    ["Gunpowder"] = { id = 69, type = "Resource" },
    ["Bone Shards"] = { id = 70, type = "Resource" },
    ["Metal Door"] = { id = 71, type = "Bench" },
    ["Metal Double Door"] = { id = 72, type = "Bench" },
    ["Steel Door"] = { id = 73, type = "Bench" },
    ["Steel Double Door"] = { id = 74, type = "Bench" },
    ["Nail Gun"] = { id = 75, type = "Gun" },
    ["Steel Axe"] = { id = 76, type = "Tool" },
    ["Steel Pickaxe"] = { id = 77, type = "Tool" },
    ["Power Cell"] = { id = 78, type = "Misc" },
    ["Copper Cogs"] = { id = 79, type = "Misc" },
    ["Pipe"] = { id = 80, type = "Misc" },
    ["Propane Tank"] = { id = 81, type = "Misc" },
    ["Rope"] = { id = 82, type = "Misc" },
    ["Blade"] = { id = 83, type = "Misc" },
    ["Thread"] = { id = 84, type = "Misc" },
    ["Metal Plating"] = { id = 85, type = "Misc" },
    ["Spring"] = { id = 86, type = "Misc" },
    ["Tarp"] = { id = 87, type = "Misc" },
    ["Circuit Boards"] = { id = 88, type = "Misc" },
    ["Metal Scraps"] = { id = 89, type = "Misc" },
    ["Swift Light Ammo"] = { id = 90, type = "Ammo" },
    ["Sleeping Bag"] = { id = 91, type = "Bench" },
    ["Timed Charge"] = { id = 92, type = "Tool" },
    ["Nails"] = { id = 93, type = "Ammo" },
    ["Garage Door"] = { id = 94, type = "Bench" },
    ["Dynamite Bundle"] = { id = 95, type = "Tool" },
    ["Dynamite Stick"] = { id = 96, type = "Tool" },
    ["Salvaged RPG"] = { id = 97, type = "Gun" },
    ["Rocket"] = { id = 98, type = "Ammo" },
    ["Swift Rocket"] = { id = 99, type = "Ammo" },
    ["Combustive Rocket"] = { id = 100, type = "Ammo" },
    ["External Wooden Wall"] = { id = 101, type = "Bench" },
    ["External Wooden Gate"] = { id = 102, type = "Bench" },
    ["Vertical Window Cover"] = { id = 103, type = "Bench" },
    ["Horizontal Window Cover"] = { id = 104, type = "Bench" },
    ["Jail Wall"] = { id = 105, type = "Bench" },
    ["Jail Door"] = { id = 106, type = "Bench" },
    ["%s\\'s Trophy"] = { id = 107, type = "Bench" },
    ["Salvaged AK74u"] = { id = 108, type = "Gun" },
    ["Salvaged Pipe Rifle"] = { id = 109, type = "Gun" },
    ["Petroleum"] = { id = 110, type = "Resource" },
    ["Boots"] = { id = 111, type = "Armor", armor_type = "Boots" },
    ["Collared Shirt"] = { id = 112, type = "Armor", armor_type = "Shirt" },
    ["Shorts"] = { id = 113, type = "Armor", armor_type = "Pants" },
    ["Tank Top"] = { id = 114, type = "Armor", armor_type = "Shirt" },
    ["Cloth Shirt"] = { id = 115, type = "Armor", armor_type = "Shirt" },
    ["Cloth Pants"] = { id = 116, type = "Armor", armor_type = "Pants" },
    ["Cloth Footwraps"] = { id = 117, type = "Armor", armor_type = "Boots" },
    ["Leather Poncho"] = { id = 118, type = "Armor", armor_type = "Chestplate" },
    ["Leather Pants"] = { id = 119, type = "Armor", armor_type = "Pants" },
    ["Leather Shirt"] = { id = 120, type = "Armor", armor_type = "Shirt" },
    ["Leather Boots"] = { id = 121, type = "Armor", armor_type = "Boots" },
    ["Flannel Jacket"] = { id = 122, type = "Armor", armor_type = "Chestplate" },
    ["Wooden Helmet"] = { id = 123, type = "Armor", armor_type = "Hat" },
    ["Wooden Chestplate"] = { id = 124, type = "Armor", armor_type = "Chestplate" },
    ["Wooden Leggings"] = { id = 125, type = "Armor", armor_type = "Kilt" },
    ["Wooden Arrow"] = { id = 126, type = "Ammo" },
    ["Swift Arrow"] = { id = 127, type = "Ammo" },
    ["Bone Arrow"] = { id = 128, type = "Ammo" },
    ["Combustive Arrow"] = { id = 129, type = "Ammo" },
    ["Iron Shard Hatchet"] = { id = 130, type = "Tool" },
    ["Iron Shard Pickaxe"] = { id = 131, type = "Tool" },
    ["Large Furnace"] = { id = 132, type = "Bench" },
    ["Yellow Keycard"] = { id = 133, type = "Tool" },
    ["Purple Keycard"] = { id = 134, type = "Tool" },
    ["Pink Keycard"] = { id = 135, type = "Tool" },
    ["Small Medkit"] = { id = 136, type = "Tool" },
    ["Salvaged Break Action"] = { id = 137, type = "Gun" },
    ["Buckshot"] = { id = 138, type = "Ammo" },
    ["Slug"] = { id = 139, type = "Ammo" },
    ["Combustive Buckshot"] = { id = 140, type = "Ammo" },
    ["Steel Helmet"] = { id = 141, type = "Armor", armor_type = "Helmet" },
    ["Steel Chestplate"] = { id = 142, type = "Armor", armor_type = "Chestplate" },
    ["Steel Leggings"] = { id = 143, type = "Armor", armor_type = "Kilt" },
    ["Large Storage Box"] = { id = 144, type = "Bench" },
    ["Salvaged Helmet"] = { id = 145, type = "Armor", armor_type = "Helmet" },
    ["Salvaged Chestplate"] = { id = 146, type = "Armor", armor_type = "Chestplate" },
    ["Salvaged Leggings"] = { id = 147, type = "Armor", armor_type = "Kilt" },
    ["Military Helmet"] = { id = 148, type = "Armor", armor_type = "Helmet" },
    ["Military Chestplate"] = { id = 149, type = "Armor", armor_type = "Chestplate" },
    ["Military Leggings"] = { id = 150, type = "Armor", armor_type = "Kilt" },
    ["Hard Hat"] = { id = 151, type = "Armor", armor_type = "Hat" },
    ["Balaclava"] = { id = 152, type = "Armor", armor_type = "Face" },
    ["Cloth Headwrap"] = { id = 153, type = "Armor", armor_type = "Helmet" },
    ["Baseball Cap"] = { id = 154, type = "Armor", armor_type = "Hat" },
    ["Salvaged Gloves"] = { id = 155, type = "Armor", armor_type = "Gloves" },
    ["Cloth Handwraps"] = { id = 156, type = "Armor", armor_type = "Gloves" },
    ["Military Gloves"] = { id = 157, type = "Armor", armor_type = "Gloves" },
    ["Leather Gloves"] = { id = 158, type = "Armor", armor_type = "Gloves" },
    ["Wetsuit"] = { id = 159, type = "Armor", armor_type = "Wetsuit", attribute = "ResistWet" },
    ["Flippers"] = { id = 160, type = "Armor", armor_type = "Boots", attribute = "HasFlippers" },
    ["Diving Tank"] = { id = 161, type = "Armor", armor_type = "Chestplate", attribute = "HasTank" },
    ["Diving Goggles"] = { id = 162, type = "Armor", armor_type = "Helmet", attribute = "HasGoggles" },
    ["Cooking Pot"] = { id = 163, type = "Bench" },
    ["Ladder"] = { id = 164, type = "Bench" },
    ["Chocolate Bar"] = { id = 165, type = "Consumable" },
    ["Bean Can"] = { id = 166, type = "Consumable" },
    ["Meatball Can"] = { id = 167, type = "Consumable" },
    ["Fish Can"] = { id = 168, type = "Consumable" },
    ["Water Bottle"] = { id = 169, type = "Consumable" },
    ["Piercing Heavy Ammo"] = { id = 170, type = "Ammo" },
    ["Piercing Light Ammo"] = { id = 171, type = "Ammo" },
    ["Semi Receiver"] = { id = 172, type = "Misc" },
    ["SMG Receiver"] = { id = 173, type = "Misc" },
    ["Rifle Receiver"] = { id = 174, type = "Misc" },
    ["Steel Shovel"] = { id = 175, type = "Tool" },
    ["Empty Can"] = { id = 176, type = "Misc" },
    ["Care Package Signal"] = { id = 177, type = "Tool" },
    ["Duct Tape"] = { id = 178, type = "Misc" },
    ["Glue"] = { id = 179, type = "Misc" },
    ["Pistol Receiver"] = { id = 180, type = "Misc" },
    ["Salvaged Shovel"] = { id = 181, type = "Tool" },
    ["ez shovel"] = { id = 182, type = "Tool" },
    ["Anvil"] = { id = 183, type = "Bench" },
    ["Chemistry Lab"] = { id = 184, type = "Bench" },
    ["Carpentry Table"] = { id = 185, type = "Bench" },
    ["Sewing Table"] = { id = 186, type = "Bench" },
    ["Ammo Press"] = { id = 187, type = "Bench" },
    ["Culinary Table"] = { id = 188, type = "Bench" },
    ["Petroleum Refinery"] = { id = 189, type = "Bench" },
    ["Triangle Trap Door"] = { id = 190, type = "Bench" },
    ["Military AA12"] = { id = 191, type = "Gun" },
    ["Repair Table"] = { id = 192, type = "Bench" },
    ["Salvaged Pump Action"] = { id = 193, type = "Gun" },
    ["Bed"] = { id = 194, type = "Bench" },
    ["Wooden Spikes"] = { id = 195, type = "Bench" },
    ["Military ACOG Sight"] = { id = 196, type = "Attachment" },
    ["Metal Barricade"] = { id = 197, type = "Bench" },
    ["Military M4A1"] = { id = 198, type = "Gun" },
    ["Small Wooden Sign"] = { id = 199, type = "Bench" },
    ["Large Wooden Sign"] = { id = 200, type = "Bench" },
    ["Storage Cabinet"] = { id = 201, type = "Bench" },
    ["External Stone Gate"] = { id = 202, type = "Bench" },
    ["Bone Tool"] = { id = 203, type = "Tool" },
    ["Salvaged Skorpion"] = { id = 204, type = "Gun" },
    ["Candy Cane"] = { id = 205, type = "Tool" },
    ["Christmas Tree"] = { id = 206, type = "Bench" },
    ["Santa Hat"] = { id = 207, type = "Armor", armor_type = "Hat" },
    ["External Stone Wall"] = { id = 208, type = "Bench" },
    ["Blast Furnace"] = { id = 209, type = "Bench" },
    ["Military Barrett"] = { id = 210, type = "Gun" },
    ["Shotgun Turret"] = { id = 211, type = "Bench" },
    ["Military Grenade"] = { id = 212, type = "Tool" },
    ["Floor Grill"] = { id = 213, type = "Bench" },
    ["Bear Trap"] = { id = 214, type = "Bench" },
    ["Landmine Trap"] = { id = 215, type = "Bench" },
    ["Saw Bat"] = { id = 216, type = "Tool" },
    ["Machete"] = { id = 217, type = "Tool" },
    ["Military PKM"] = { id = 218, type = "Gun" },
    ["Bruno\\'s ACOG Sight"] = { id = 219, type = "Attachment" },
    ["Military Lasersight"] = { id = 220, type = "Attachment" },
    ["Bruno\\'s M4A1"] = { id = 221, type = "Gun" },
    ["Boss Chestplate"] = { id = 222, type = "Armor", armor_type = "Chestplate" },
    ["Boss Helmet"] = { id = 223, type = "Armor", armor_type = "Helmet" },
    ["Bunny Ears"] = { id = 224, type = "Armor", armor_type = "Hat" },
    ["Carrot Blade"] = { id = 225, type = "Tool" },
    ["Metal Spikes"] = { id = 226, type = "Bench" },
    ["Rug"] = { id = 227, type = "Bench" },
    ["Shop Machine"] = { id = 228, type = "Bench" },
    ["Chainsaw"] = { id = 229, type = "Tool" },
    ["Mining Drill"] = { id = 230, type = "Tool" },
    ["Extended Mag"] = { id = 231, type = "Attachment" },
    ["Jukebox"] = { id = 232, type = "Bench" },
    ["Wool Plant Seed"] = { id = 233, type = "Bench" },
    ["Wool"] = { id = 234, type = "Resource" },
    ["Loom"] = { id = 235, type = "Bench" },
    ["Small Planter Box"] = { id = 236, type = "Bench" },
    ["Large Planter Box"] = { id = 237, type = "Bench" },
    ["Tomato Plant Seed"] = { id = 238, type = "Bench" },
    ["Corn Plant Seed"] = { id = 239, type = "Bench" },
    ["Tomato"] = { id = 240, type = "Consumable" },
    ["Corn"] = { id = 241, type = "Consumable" },
    ["Chicken Egg"] = { id = 242, type = "Consumable" },
    ["Milk"] = { id = 243, type = "Consumable" },
    ["Raspberry Pie I"] = { id = 244, type = "Consumable" },
    ["Raspberry Pie II"] = { id = 245, type = "Consumable" },
    ["Raspberry Pie III"] = { id = 246, type = "Consumable" },
    ["Raspberry Pie IV"] = { id = 247, type = "Consumable" },
    ["Blueberry Pie I"] = { id = 248, type = "Consumable" },
    ["Blueberry Pie II"] = { id = 249, type = "Consumable" },
    ["Blueberry Pie III"] = { id = 250, type = "Consumable" },
    ["Blueberry Pie IV"] = { id = 251, type = "Consumable" },
    ["Lemon Cake I"] = { id = 252, type = "Consumable" },
    ["Lemon Cake II"] = { id = 253, type = "Consumable" },
    ["Lemon Cake III"] = { id = 254, type = "Consumable" },
    ["Lemon Cake IV"] = { id = 255, type = "Consumable" },
    ["Corn Bread I"] = { id = 256, type = "Consumable" },
    ["Corn Bread II"] = { id = 257, type = "Consumable" },
    ["Corn Bread III"] = { id = 258, type = "Consumable" },
    ["Corn Bread IV"] = { id = 259, type = "Consumable" },
    ["Cow Pasture"] = { id = 260, type = "Bench" },
    ["Chicken House"] = { id = 261, type = "Bench" },
    ["Barrel Light"] = { id = 262, type = "Bench" },
    ["Raspberries"] = { id = 263, type = "Consumable" },
    ["Blueberries"] = { id = 264, type = "Consumable" },
    ["Lemon"] = { id = 265, type = "Consumable" },
    ["Lemon Plant Seed"] = { id = 266, type = "Bench" },
    ["Raspberry Plant Seed"] = { id = 267, type = "Bench" },
    ["Blueberry Plant Seed"] = { id = 268, type = "Bench" },
    ["Military MP7"] = { id = 269, type = "Gun" },
    ["Red Keycard"] = { id = 270, type = "Tool" },
    ["Salvaged Double Barrel"] = { id = 271, type = "Gun" },
    ["Military Boat"] = { id = 272, type = "Resource" },
    ["Clan Table"] = { id = 273, type = "Bench" },
    ["Wooden Boat"] = { id = 274, type = "Resource" },
    ["Military USP"] = { id = 275, type = "Gun" },
    ["Common Goodie Bag"] = { id = 276, type = "Misc" },
    ["Rare Goodie Bag"] = { id = 277, type = "Misc" },
    ["Epic Goodie Bag"] = { id = 278, type = "Misc" },
    ["Candle"] = { id = 279, type = "Bench" },
    ["Armor Stand"] = { id = 280, type = "Bench" },
    ["Jack-O-Lantern"] = { id = 281, type = "Bench" },
    ["Small Cobweb"] = { id = 282, type = "Bench" },
    ["Large Cobweb"] = { id = 283, type = "Bench" },
    ["Pumpkin Plant Seed"] = { id = 284, type = "Bench" },
    ["Pumpkin"] = { id = 285, type = "ConsumableAmmoArmor", armor_type = "Helmet" },
    ["Halloween Scythe"] = { id = 286, type = "Tool" },
    ["Pumpkin Launcher"] = { id = 287, type = "Gun" },
    ["Raw Wolf"] = { id = 288, type = "Consumable" },
    ["Cooked Wolf"] = { id = 289, type = "Consumable" },
    ["Pumpkin Pie"] = { id = 290, type = "Consumable" },
    ["Cursed Pumpkin"] = { id = 291, type = "Ammo" },
    ["Marsh Bar"] = { id = 292, type = "Consumable" },
    ["Peanut Butter Cup"] = { id = 293, type = "Consumable" },
    ["Candy Roll"] = { id = 294, type = "Consumable" },
    ["Scarecrow"] = { id = 295, type = "Bench" },
    ["Salvaged Shotgun"] = { id = 296, type = "Gun" },
    ["Salvaged Shell"] = { id = 297, type = "Ammo" },
    ["Bone Armor"] = { id = 298, type = "Armor", armor_type = "All" },
    ["Armor Plate"] = { id = 299, type = "Attachment" },
    ["Heavy Padding"] = { id = 300, type = "Attachment" },
    ["Night Vision Goggles"] = { id = 301, type = "Attachment", attribute = "NVG" },
    ["Lightweight Padding"] = { id = 302, type = "Attachment", attribute = "SilentSteps" },
    ["Resistant Rubber"] = { id = 303, type = "Attachment" },
    ["Armor Polish"] = { id = 304, type = "Attachment" },
    ["Water Filter"] = { id = 305, type = "Attachment", attribute = "WaterFilter" },
    ["Steel Toes"] = { id = 306, type = "Attachment", attribute = "SteelToes" },
    ["Snorkle"] = { id = 307, type = "Attachment", attribute = "Snorkle" },
    ["Military Backpack"] = { id = 308, type = "Backpack" },
    ["Salvaged Backpack"] = { id = 309, type = "Backpack" },
    ["Salvaged Sniper"] = { id = 310, type = "Gun" },
    ["Military Grenade Launcher"] = { id = 311, type = "Gun" },
    ["Explosive Shell"] = { id = 312, type = "Ammo" },
    ["Salvaged Flycopter"] = { id = 313, type = "Resource" },
    ["Fireplace"] = { id = 314, type = "Bench" },
    ["Black Keycard"] = { id = 315, type = "Tool" },
    ["Salvaged Grenade Launcher"] = { id = 316, type = "Gun" },
    ["Salvaged Explosive Shell"] = { id = 317, type = "Ammo" },
    ["Shotgun Shell"] = { id = 318, type = "Ammo" },
    ["Large Medkit"] = { id = 319, type = "Consumable" },
    ["Small Battery"] = { id = 320, type = "Bench" },
    ["Medium Battery"] = { id = 321, type = "Bench" },
    ["Large Battery"] = { id = 322, type = "Bench" },
    ["Crude Fuel Generator"] = { id = 323, type = "Bench" },
    ["Solar Panel"] = { id = 324, type = "Bench" },
    ["Water Turbine"] = { id = 325, type = "Bench" },
    ["Wire Cutters"] = { id = 326, type = "Tool" },
    ["Button"] = { id = 327, type = "Bench" },
    ["Electric Furnace"] = { id = 328, type = "Bench" },
    ["Electric Heater"] = { id = 329, type = "Bench" },
    ["Switch"] = { id = 330, type = "Bench" },
    ["Windmill"] = { id = 331, type = "Bench" },
    ["Splitter"] = { id = 332, type = "Bench" },
    ["Military Boat"] = { id = 333, type = "Resource" },
    ["Auto Turret"] = { id = 334, type = "Bench" },
    ["Military M39"] = { id = 335, type = "Gun" },
    ["White Ornament"] = { id = 336, type = "Resource" },
    ["Red Ornament"] = { id = 337, type = "Resource" },
    ["Purple Ornament"] = { id = 338, type = "Resource" },
    ["Wreath"] = { id = 339, type = "Bench" },
    ["Christmas Lights"] = { id = 340, type = "Bench" },
    ["Admin Tool"] = { id = 341, type = "Tool" },
}

function M.get_by_name(name)
    return name and M.by_name[name] or nil
end

function M.get(id)
    return id and M.by_id[id] or nil
end

function M.get_by_attribute(attr)
    local name = attr and M.by_attribute[attr]
    if not name then return nil end
    return { name = name }
end

function M.name_for_armor_model(model_name)
    if not model_name or model_name:sub(1, 6) ~= "Armor_" then return nil end
    local id, skin = model_name:match("^Armor_(%d+)/(.+)$")
    if not id then
        id = model_name:match("^Armor_(%d+)$")
        skin = nil
    end
    if id then
        local row = M.by_id[tonumber(id)]
        if row then return row.name, skin end
    end
    local key = model_name:match("^(.-)/") or model_name
    key = key:gsub(" ", "_")
    local num = key:match("^Armor_(%d+)$")
    if num then
        local row = M.by_id[tonumber(num)]
        if row then return row.name, model_name:match("^.-/(.+)$") end
    end
    local attr = key:match("^Armor_(.+)$")
    if attr then
        local row = M.get_by_attribute(attr)
        if row then return row.name, model_name:match("^.-/(.+)$") end
    end
    return nil
end

return M

end)()

-- ── game/items.lua ──
April._mods["game.items"] = (function()
local env = April.require("core.env")
local item_images = April.require("game.item_images")
local item_catalog = April.require("game.item_catalog")
local asset_urls = April.require("game.asset_urls")

local M = {}
local loaded = false
local by_name = {}

local FALLBACK = {
    ["Wood Log"] = { Type = "Resource" },
    ["Bandage"] = { Type = "Tool" },
    ["Salvaged M14"] = { Type = "Tool" },
}

local NAME_ALIASES = {
    ["Cloth Head Wrap"] = "Cloth Headwrap",
}

local HELD_TYPES = {
    Gun = true,
    Tool = true,
    Bench = true,
}

local function parse_variant_name(name)
    if not name then return nil, nil end
    local base, variant = name:match("^([^/]+)/(.+)$")
    if base and variant then
        return base, variant
    end
    return name, nil
end

local function index_data(data)
    if data[1] and type(data[1]) == "table" then
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
end

function M.normalize_name(name)
    if not name then return nil end
    return NAME_ALIASES[name] or name
end

function M.load()
    if loaded then return true end

    local rep = env.get_replicated_storage()
    if rep then
        local modules = env.safe_call(function() return rep:find_first_child("Modules") end)
        local items_mod = modules and env.safe_call(function() return modules:find_first_child("Items") end)
        if items_mod then
            local ok, data = pcall(function() return require(items_mod) end)
            if ok and type(data) == "table" then
                index_data(data)
                loaded = true
                return true
            end
        end
    end

    local module_scan = April.require("game.module_scan")
    local data = module_scan.find_items()
    if data then
        index_data(data)
        loaded = true
        return true
    end

    return false
end

function M.invalidate()
    loaded = false
    by_name = {}
end

function M.get(name)
    if not loaded then M.load() end
    return by_name[name] or FALLBACK[name]
end

function M.get_catalog(name)
    return item_catalog.get_by_name(M.normalize_name(name))
end

function M.get_type(name)
    local row = M.get_catalog(name)
    if row then return row.type end

    local item = M.get(name)
    return item and item.Type or "Unknown"
end

function M.is_held_display(name)
    if not name or name == "" then return false end

    local base = select(1, parse_variant_name(name))
    local row = M.get_catalog(base)
    if row and HELD_TYPES[row.type] then return true end

    local t = M.get_type(base)
    return HELD_TYPES[t] == true
end

local function rbx_id_from_image(img)
    if type(img) == "string" then
        return img:match("(%d+)")
    end
    if type(img) == "table" then
        local pick = img.Default or img.default
        if type(pick) == "string" then
            return pick:match("(%d+)")
        end
    end
    return nil
end

function M.get_by_id(id)
    if type(id) ~= "number" then return nil end
    if not loaded then M.load() end

    local cat = item_catalog.get(id)
    if cat and cat.name then
        local row = by_name[cat.name]
        if row then return row end
    end

    local rep = env.get_replicated_storage()
    if rep then
        local modules = env.safe_call(function() return rep:find_first_child("Modules") end)
        local items_mod = modules and env.safe_call(function() return modules:find_first_child("Items") end)
        if items_mod then
            local ok, data = pcall(function() return require(items_mod) end)
            if ok and data and data[id] then return data[id] end
        end
    end

    return nil
end

function M.get_image_asset_id(name, variant)
    if not name then return nil end

    name = M.normalize_name(name)

    local id = item_images.get_asset_id(name, variant)
    if id then return id end

    if variant and variant ~= "" and variant ~= "Default" then
        id = item_images.get_asset_id(name, "Default")
        if id then return id end
    end

    if not loaded then M.load() end
    local item = by_name[name]
    if not item or not item.Image then return nil end

    local img = item.Image
    if type(img) == "string" then
        return img:match("(%d+)")
    end
    if type(img) == "table" then
        if variant and img[variant] then
            return tostring(img[variant]):match("(%d+)")
        end
        return rbx_id_from_image(img)
    end
    return nil
end

function M.make_piece(name, variant)
    name = M.normalize_name(name)
    if not name or name == "" then return nil end
    return {
        name = name,
        variant = variant,
        asset_id = M.get_image_asset_id(name, variant),
    }
end

function M.resolve_armor_model(model_name)
    if not model_name then return nil end
    local item_name, variant = item_catalog.name_for_armor_model(model_name)
    if not item_name then return nil end
    return M.make_piece(item_name, variant)
end

function M.resolve_item_label(label)
    if not label or label == "" then return nil end

    local base, variant = parse_variant_name(label)
    base = M.normalize_name(base)

    local numeric = tonumber(base)
    if numeric then
        local row = item_catalog.get(numeric)
        if row then
            return M.make_piece(row.name, variant)
        end
    end

    if item_catalog.get_by_name(base) or item_images.get_asset_id(base, variant) then
        return M.make_piece(base, variant)
    end

    if not loaded then M.load() end
    if by_name[base] then
        return M.make_piece(base, variant)
    end

    return nil
end

function M.get_image_url(name, variant)
    local id = M.get_image_asset_id(name, variant)
    if id then return asset_urls.item_png(id) end
    return nil
end

return M

end)()

-- ── game/armor_map.lua ──
April._mods["game.armor_map"] = (function()
--[[ Armor model names on character -> Items module display names (legacy ARMOR_MAP). ]]

local M = {}

M.BY_MODEL = {
    ["Armor_153"] = "Cloth Headwrap",
    ["Armor_115"] = "Cloth Shirt",
    ["Armor_116"] = "Cloth Pants",
    ["Armor_156"] = "Cloth Handwraps",
    ["Armor_117"] = "Cloth Footwraps",
    ["Armor_124"] = "Wooden Chestplate",
    ["Armor_125"] = "Wooden Leggings",
    ["Armor_123"] = "Wooden Helmet",
    ["Armor_145"] = "Salvaged Helmet",
    ["Armor_146"] = "Salvaged Chestplate",
    ["Armor_147"] = "Salvaged Leggings",
    ["Armor_155"] = "Salvaged Gloves",
    ["Armor_148"] = "Military Helmet",
    ["Armor_149"] = "Military Chestplate",
    ["Armor_150"] = "Military Leggings",
    ["Armor_157"] = "Military Gloves",
    ["Armor_271"] = "Altyn Helmet",
    ["Armor_272"] = "Boris Chestplate",
    ["Armor_141"] = "Steel Helmet",
    ["Armor_142"] = "Steel Chestplate",
    ["Armor_143"] = "Steel Leggings",
    ["Armor_158"] = "Leather Gloves",
    ["Armor_113"] = "Shorts",
    ["Armor_59"] = "Hoodie",
    ["Armor_63"] = "Pants",
    ["Armor_60"] = "Hazmat Suit",
    ["Armor_111"] = "Boots",
    ["Armor_121"] = "Boots",
    ["Armor_112"] = "Collared Shirt",
    ["Armor_122"] = "Flannel Jacket",
    ["Armor_114"] = "Tank Top",
    ["Armor_159"] = "Wetsuit",
    ["Armor_154"] = "Baseball Cap",
    ["Armor_152"] = "Balaclava",
    ["Armor_223"] = "Bruno's Helmet",
    ["Armor_222"] = "Bruno's Chestplate",
    ["Armor_298"] = "Bone Armor",
    ["Armor_308"] = "Military Backpack",
    ["Armor_309"] = "Salvaged Backpack",
}

function M.item_name(model_key)
    return model_key and M.BY_MODEL[model_key]
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

-- ToolInfo-aligned fallbacks when live module is unavailable (gravity = Bullet.Gravity multiplier).
local FALLBACK_STATS = {
    ["Military Barret"] = { speed = 2500, gravity = 0.55 },
    ["Military Barrett"] = { speed = 2500, gravity = 0.55 },
    ["Military M4A1"] = { speed = 2100, gravity = 0.55 },
    ["Military M39"] = { speed = 2400, gravity = 0.52 },
    ["Military MP7"] = { speed = 1900, gravity = 0.6 },
    ["Military PKM"] = { speed = 2400, gravity = 0.55 },
    ["Military USP"] = { speed = 1800, gravity = 0.6 },
    ["Military AA12"] = { speed = 400, gravity = 0.6 },
    ["Bruno's M4A1"] = { speed = 2100, gravity = 0.55 },
    ["Salvaged AK47"] = { speed = 2100, gravity = 0.55 },
    ["Salvaged AK74u"] = { speed = 1900, gravity = 0.6 },
    ["Salvaged AK4"] = { speed = 2100, gravity = 0.55 },
    ["Salvaged Sniper"] = { speed = 2100, gravity = 0.55 },
    ["Salvaged M14"] = { speed = 2100, gravity = 0.55 },
    ["Salvaged SMG"] = { speed = 1600, gravity = 0.6 },
    ["Salvaged Skorpion"] = { speed = 1400, gravity = 0.6 },
    ["Salvaged Python"] = { speed = 1500, gravity = 0.6 },
    ["Salvaged P250"] = { speed = 1400, gravity = 0.6 },
    ["Salvaged Pipe Rifle"] = { speed = 800, gravity = 0.55 },
    ["Salvaged Pump Action"] = { speed = 400, gravity = 0.6 },
    ["Salvaged Shotgun"] = { speed = 400, gravity = 0.6 },
    ["Salvaged Double Barrel"] = { speed = 400, gravity = 0.6 },
    ["Salvaged Break Action"] = { speed = 400, gravity = 0.6 },
    ["Crossbow"] = { speed = 420, gravity = 0.2 },
    ["Wooden Bow"] = { speed = 280, gravity = 0.2 },
    ["Nail Gun"] = { speed = 165, gravity = 0.25 },
    ["Pumpkin Launcher"] = { speed = 100, gravity = 0.12 },
    ["Salvaged RPG"] = { speed = 100, gravity = 0.12 },
    ["Military Grenade Launcher"] = { speed = 350, gravity = 0.55 },
    ["Salvaged Grenade Launcher"] = { speed = 350, gravity = 0.55 },
}

M._last_held = nil
M._last_held_ranged = nil
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

local MELEE_NAME_HINTS = {
    "hatchet", "pickaxe", "pick axe", " axe", "axe ",
    "spear", "machete", "knife", "sword",
    "bone tool", "hammer", "crowbar",
    "chainsaw", "mining drill", "shovel", "scythe",
    "candy cane", "carrot blade", "boulder", "saw bat",
}

local function name_looks_melee(name)
    local n = (name or ""):lower()
    for _, hint in ipairs(MELEE_NAME_HINTS) do
        if n:find(hint, 1, true) then return true end
    end
    return false
end

function M.is_ranged_weapon_name(name)
    if not name or name == "" then return false end
    local lower = name:lower()
    if lower:find("bow", 1, true) or lower:find("crossbow", 1, true) then return true end
    if name_looks_melee(name) then return false end

    if not loaded then M.load() end

    local entry = toolinfo[name]
    if entry then
        if entry.Bullet then return true end
        if entry.Melee and not entry.Bullet then return false end
        if entry.Weapon and (entry.Weapon.RPM or entry.Weapon.ActualRPM) then
            return true
        end
        if entry.Melee then return false end
    end

    if FALLBACK_STATS[name] then
        return true
    end

    return false
end

function M.get_held_ranged_weapon_name()
    if not loaded then M.load() end

    local lp = env.get_local_player()
    if not lp then return nil end

    local function pick(name)
        if name and M.is_ranged_weapon_name(name) then return name end
    end

    local char = lp.character
    if char and env.is_valid(char) then
        for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
            local hit = pick(inst_name(child))
            if hit then return hit end
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
                        local hit = pick(inst_name(item))
                        if hit then return hit end
                    end
                end
            end
        end
    end

    return pick(lp.tool_name)
end

function M.holding_ranged_weapon()
    return M._last_held_ranged ~= nil
end

function M.cached_held_ranged()
    return M._last_held_ranged
end

function M.is_bow_weapon_name(name)
    if not name then return false end
    local n = name:lower()
    return n:find("bow", 1, true) ~= nil
end

function M.invalidate()
    loaded = false
    toolinfo = {}
    recoil_weapons = {}
    weapon_names = {}
    M._last_held = nil
    M._last_held_ranged = nil
    M._weapon_changed_at = 0
    pcall(function()
        local origin = April.require("game.combat_origin")
        if origin.invalidate then origin.invalidate() end
    end)
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

function M.profile_weapon_names()
    if not loaded then M.load() end

    local farm = nil
    pcall(function()
        farm = April.require("game.farm_tools")
        if farm and farm.load then farm.load() end
    end)

    local seen = {}
    local list = {}

    local function add(name)
        if not name or name == "" or seen[name] then return end
        if not M.is_ranged_weapon_name(name) then return end
        if farm and farm.is_farm_tool_name and farm.is_farm_tool_name(name) then return end
        seen[name] = true
        list[#list + 1] = name
    end

    for name in pairs(toolinfo) do
        add(name)
    end
    for name in pairs(FALLBACK_STATS) do
        add(name)
    end

    table.sort(list)
    return list
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
        local grav = gravity
        if not grav or grav <= 0 or grav > 2 then
            grav = 0.55
        end
        return {
            speed = speed,
            gravity = grav,
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
    if not grav or grav <= 0 then return ROBLOX_GRAV * 0.55 end
    if grav <= 2 then return grav * ROBLOX_GRAV end
    return grav
end

function M.get_weapon_stats(name)
    name = name or M.get_held_weapon_name()
    if not name then return nil end

    local entry = M.get(name)
    if entry and entry.Bullet then
        return {
            speed = entry.Bullet.Speed or 950,
            gravity = entry.Bullet.Gravity or 0.55,
            name = name,
            from_toolinfo = true,
            is_bow = (entry.Weapon and entry.Weapon.IsBow)
                or name == "Wooden Bow"
                or name == "Crossbow",
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

    local _, tool_inst = M.get_held_tool()
    if tool_inst then
        local from_attrs = read_tool_attributes(tool_inst)
        if from_attrs then
            from_attrs.name = name
            return from_attrs
        end
    end

    return { speed = 950, gravity = 0.55, name = name }
end

function M.tick()
    local in_game = M.in_game_ready()

    if not in_game then
        if M._was_in_game then
            M._last_held = nil
            M._last_held_ranged = nil
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

    local held = M.get_held_ranged_weapon_name()
    if held ~= M._last_held_ranged then
        M._last_held = held
        M._last_held_ranged = held
        M._weapon_changed_at = utility and utility.get_tick_count and utility.get_tick_count() or 0
        pcall(function()
            local origin = April.require("game.combat_origin")
            if origin.invalidate then origin.invalidate() end
        end)
        pcall(function()
            local gun_mods = April.require("features.combat.gun_mods")
            if gun_mods.on_weapon_changed then
                gun_mods.on_weapon_changed(held)
            end
        end)
    end

    return held
end

function M.on_modules_ready()
    M.load()
    pcall(function()
        farm_tools = April.require("game.farm_tools")
        if farm_tools.invalidate then farm_tools.invalidate() end
        if farm_tools.load then farm_tools.load() end
    end)
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
--[[ Fallen weapon mods — Vector globals: refreshgc → getgc(keys) → applygc(keys, values) ]]

local debug = April.require("core.debug")
local env = April.require("core.env")

local M = {}

M.WEAPON_FIND_KEYS = {
    "RecoilMult",
    "RangeMult",
    "SpeedMult",
    "AimSpreadMult",
    "HipSpreadMult",
    "SwayMult",
    "FireRateMult",
}

M.ALLOWED = {
    RecoilMult = true,
    RangeMult = true,
    SpeedMult = true,
    AimSpreadMult = true,
    HipSpreadMult = true,
    SwayMult = true,
    FireRateMult = true,
}

M._last_node_count = 0

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

function M.in_game()
    return env.get_local_player() ~= nil
end

local function sanitize_payload(mods)
    local out = {}
    for k, v in pairs(mods) do
        if M.ALLOWED[k] and v ~= nil then
            out[k] = tonumber(v) or v
        end
    end
    return out
end

local function keys_for_payload(payload)
    local keys = {}
    for k in pairs(payload) do
        keys[#keys + 1] = k
    end
    table.sort(keys)
    return keys
end

local function warm_nodes(keys)
    local count = 0
    local ok, result = pcall(getgc, keys)
    if ok and type(result) == "number" then
        count = result
    end
    if count <= 0 then
        ok, result = pcall(getgc, M.WEAPON_FIND_KEYS)
        if ok and type(result) == "number" then
            count = result
        end
    end
    return count
end

local function patch_count(keys, payload)
    local patched = 0

    local ok, result = pcall(applygc, keys, payload)
    if ok and type(result) == "number" then
        patched = result
    end

    if patched <= 0 then
        ok, result = pcall(applygc, M.WEAPON_FIND_KEYS, payload)
        if ok and type(result) == "number" then
            patched = result
        end
    end

    if patched <= 0 then
        ok, result = pcall(applygc, payload)
        if ok and type(result) == "number" then
            patched = result
        end
    end

    return patched
end

function M.apply_weapon(mods)
    if not has_api() then
        return false, 0, "GC API unavailable"
    end

    local payload = sanitize_payload(mods)
    if not next(payload) then
        return false, 0, "No modifiers selected"
    end

    if not M.in_game() then
        return false, 0, "Enter a match first"
    end

    pcall(refreshgc)

    local patch_keys = keys_for_payload(payload)
    warm_nodes(M.WEAPON_FIND_KEYS)
    warm_nodes(patch_keys)

    local patched = patch_count(patch_keys, payload)
    M._last_node_count = math.max(M._last_node_count, patched, warm_nodes(patch_keys))

    if patched > 0 then
        return true, patched, string.format("%d node(s) patched", patched)
    end

    debug.warn_once("gun_mods:nodes", "GC still warming — equip a gun, enable a mod option, keep master on")
    return false, 0, "GC warming — equip gun and wait a moment"
end

function M.apply(mods)
    return M.apply_weapon(mods)
end

function M.apply_once(mods)
    return M.apply_weapon(mods)
end

function M.apply_cached(mods)
    return M.apply_weapon(mods)
end

function M.refresh_cache()
    if not has_api() or not M.in_game() then
        M._last_node_count = 0
        return 0
    end

    pcall(refreshgc)
    warm_nodes(M.WEAPON_FIND_KEYS)
    local count = warm_nodes(M.WEAPON_FIND_KEYS)
    M._last_node_count = count
    return count
end

function M.probe_on_load()
    if not has_api() then return 0 end
    if not M.in_game() then return 0 end
    return M.refresh_cache()
end

function M.status_text()
    if not has_api() then return "GC: unavailable" end
    return string.format("GC nodes: %d", M._last_node_count)
end

return M

end)()

-- ── game/weapon_profile_store.lua ──
April._mods["game.weapon_profile_store"] = (function()
--[[ Per-weapon gun mod profiles — persisted separately from config slots. ]]

local settings = April.require("core.settings")
local config_store = April.require("core.config_store")

local M = {}

local FILE = "April_gun_profiles.txt"
local VERSION = 1

local DEFAULT = {
    recoil = false,
    recoil_pct = 100,
    spread = false,
    spread_pct = 100,
    sway = false,
    fire_rate = false,
    fire_rate_mult = 1.5,
    speed = false,
    speed_mult = 100,
    range = false,
    range_mult = 10,
}

local EDITOR_KEYS = {
    recoil = "april_gm_recoil",
    recoil_pct = "april_gm_recoil_pct",
    spread = "april_gm_spread",
    spread_pct = "april_gm_spread_pct",
    sway = "april_gm_sway",
    fire_rate = "april_gm_fire_rate",
    fire_rate_mult = "april_gm_fire_rate_mult",
    speed = "april_gm_speed",
    speed_mult = "april_gm_speed_mult",
    range = "april_gm_range",
    range_mult = "april_gm_range_mult",
}

M._profiles = {}
M._loaded = false

local function file_path()
    return config_store.get_config_path(FILE)
end

function M.default_profile()
    local out = {}
    for k, v in pairs(DEFAULT) do
        out[k] = v
    end
    return out
end

function M.normalize_profile(profile)
    local out = M.default_profile()
    if type(profile) ~= "table" then return out end
    for k in pairs(DEFAULT) do
        if profile[k] ~= nil then
            out[k] = profile[k]
        end
    end
    return out
end

function M.get(weapon_name)
    if not weapon_name or weapon_name == "" then return nil end
    local profile = M._profiles[weapon_name]
    if not profile then return nil end
    return M.normalize_profile(profile)
end

function M.set(weapon_name, profile)
    if not weapon_name or weapon_name == "" then return false end
    M._profiles[weapon_name] = M.normalize_profile(profile)
    M.save()
    return true
end

function M.remove(weapon_name)
    if not weapon_name or weapon_name == "" then return false end
    if not M._profiles[weapon_name] then return false end
    M._profiles[weapon_name] = nil
    M.save()
    return true
end

function M.has_saved(weapon_name)
    return weapon_name and M._profiles[weapon_name] ~= nil
end

function M.has_active_mods(weapon_name)
    local profile = M.get(weapon_name)
    if not profile then return false end
    return profile.recoil or profile.spread or profile.sway
        or profile.fire_rate or profile.speed or profile.range
end

function M.read_editor()
    local profile = M.default_profile()
    for field, id in pairs(EDITOR_KEYS) do
        local default = DEFAULT[field]
        if type(default) == "boolean" then
            profile[field] = settings.bool(id, default)
        elseif type(default) == "number" and math.floor(default) == default then
            profile[field] = settings.num(id, default)
        else
            profile[field] = tonumber(settings.get(id, default)) or default
        end
    end
    return profile
end

function M.write_editor(profile)
    if not menu or not menu.set then return end
    profile = M.normalize_profile(profile)
    for field, id in pairs(EDITOR_KEYS) do
        pcall(menu.set, id, profile[field])
    end
end

function M.save_editor_weapon(weapon_name)
    return M.set(weapon_name, M.read_editor())
end

function M.load_editor_weapon(weapon_name)
    M.write_editor(M.get(weapon_name) or M.default_profile())
end

function M.load_editor_weapon_key(weapon_key)
    M.load_editor_weapon(weapon_key)
end

local function serialize_profile(profile)
    local parts = {}
    for field in pairs(DEFAULT) do
        local val = profile[field]
        if type(val) == "boolean" then
            parts[#parts + 1] = field .. "=" .. (val and "1" or "0")
        else
            parts[#parts + 1] = field .. "=" .. tostring(val)
        end
    end
    table.sort(parts)
    return table.concat(parts, "|")
end

local function parse_profile_line(raw)
    local profile = M.default_profile()
    for token in (raw or ""):gmatch("[^|]+") do
        local field, val = token:match("^([^=]+)=(.+)$")
        if field and DEFAULT[field] ~= nil then
            local default = DEFAULT[field]
            if type(default) == "boolean" then
                profile[field] = val == "1" or val == "true"
            elseif type(default) == "number" and math.floor(default) == default then
                profile[field] = tonumber(val) or default
            else
                profile[field] = tonumber(val) or default
            end
        end
    end
    return profile
end

function M.save()
    local lines = { "version=" .. VERSION }
    local names = {}
    for name in pairs(M._profiles) do
        names[#names + 1] = name
    end
    table.sort(names)
    for _, name in ipairs(names) do
        table.insert(lines, "weapon=" .. name:gsub("\r", " "):gsub("\n", " "))
        table.insert(lines, "data=" .. serialize_profile(M._profiles[name]))
    end

    local f = io.open(file_path(), "w")
    if not f then return false end
    f:write(table.concat(lines, "\n"))
    f:close()
    return true
end

function M.load()
    if M._loaded then return true end
    M._loaded = true
    M._profiles = {}

    local f = io.open(file_path(), "r")
    if not f then return false end

    local current_weapon
    for line in f:lines() do
        local key, val = line:match("^([^=]+)=(.*)$")
        if key == "weapon" then
            current_weapon = val
        elseif key == "data" and current_weapon and current_weapon ~= "" then
            M._profiles[current_weapon] = parse_profile_line(val)
            current_weapon = nil
        end
    end
    f:close()
    return true
end

return M

end)()

-- ── game/gun_mod_profiles.lua ──
April._mods["game.gun_mod_profiles"] = (function()
--[[ Map saved per-weapon profiles to applygc keys. ]]

local settings = April.require("core.settings")
local store = April.require("game.weapon_profile_store")
local weapons = April.require("game.weapons")

local M = {}

M.GLOBAL_PROFILE_KEY = "__global__"
M.GLOBAL_DISPLAY_NAME = "Global"
M.MODE_ID = "april_gm_mode"
M.MODES = { "Profile Based", "Global" }

local function pct_to_neg_mult(pct)
    pct = math.max(0, math.min(100, pct or 0))
    if pct >= 100 then return -1 end
    return -(pct / 100)
end

function M.build_mods_from_profile(profile)
    local mods = {}
    if not profile then return mods end

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

function M.build_reset_mods()
    return {
        RecoilMult = 0,
        AimSpreadMult = 0,
        HipSpreadMult = 0,
        SwayMult = 0,
        FireRateMult = 1,
        SpeedMult = 1,
        RangeMult = 1,
    }
end

function M.held_weapon_name()
    return weapons.get_held_ranged_weapon_name()
end

function M.has_gc_mods_for_weapon(name)
    return store.has_active_mods(name)
end

function M.has_gc_mods()
    local held = M.held_weapon_name()
    return held and M.has_gc_mods_for_weapon(held)
end

function M.editor_weapon_key(name)
    if name == M.GLOBAL_DISPLAY_NAME then
        return M.GLOBAL_PROFILE_KEY
    end
    return name
end

function M.is_global_mode()
    return settings.combo_index(M.MODE_ID, M.MODES, 0) == 1
end

function M.build_mods_for_weapon(name)
    local mods = M.build_reset_mods()
    local profile = store.get(name)
    if not profile then return mods end
    local patched = M.build_mods_from_profile(profile)
    for k, v in pairs(patched) do
        mods[k] = v
    end
    return mods
end

function M.build_mods_for_apply(held)
    if M.is_global_mode() then
        if store.has_saved(M.GLOBAL_PROFILE_KEY) then
            return M.build_mods_for_weapon(M.GLOBAL_PROFILE_KEY)
        end
        return nil
    end

    if held and store.has_saved(held) then
        return M.build_mods_for_weapon(held)
    end
    return nil
end

function M.should_apply_for_held(held)
    if not held then return false end
    if M.is_global_mode() then
        return store.has_saved(M.GLOBAL_PROFILE_KEY) and store.has_active_mods(M.GLOBAL_PROFILE_KEY)
    end
    return store.has_saved(held) and store.has_active_mods(held)
end

function M.build_mods()
    local held = M.held_weapon_name()
    if not held then return {} end
    return M.build_mods_for_weapon(held)
end

function M.weapon_combo_names()
    local list = { M.GLOBAL_DISPLAY_NAME }
    for _, name in ipairs(weapons.profile_weapon_names()) do
        list[#list + 1] = name
    end
    return list
end

function M.selected_editor_weapon()
    local names = M.weapon_combo_names()
    if #names == 0 then return nil end
    local idx = settings.combo_index("april_gm_weapon_select", names, 0)
    return names[idx + 1]
end

function M.selected_editor_weapon_key()
    return M.editor_weapon_key(M.selected_editor_weapon())
end

return M

end)()

-- ── game/combat_stats.lua ──
April._mods["game.combat_stats"] = (function()
--[[ Effective weapon stats for silent aim — ToolInfo + ammo + optional gun mod multipliers. ]]

local settings = April.require("core.settings")
local weapons = April.require("game.weapons")

local M = {}

local function profiles_mod()
    return April.require("game.gun_mod_profiles")
end

local function store_mod()
    return April.require("game.weapon_profile_store")
end

local function inventory_mod()
    return April.require("game.inventory")
end

local function profile_speed_mult(held)
    if not settings.enabled("april_gunmods_enabled") then return 0 end

    if settings.enabled("april_gm_speed") then
        return settings.num("april_gm_speed_mult", 100)
    end

    if not held then return 0 end

    local profiles = profiles_mod()
    local store = store_mod()

    if profiles.is_global_mode() then
        if not store.has_saved(profiles.GLOBAL_PROFILE_KEY) then return 0 end
        local p = store.get(profiles.GLOBAL_PROFILE_KEY)
        if not p or not p.speed then return 0 end
        return p.speed_mult or 0
    end

    if store.has_saved(held) then
        local p = store.get(held)
        if p and p.speed then return p.speed_mult or 0 end
    end

    return 0
end

local function ammo_modifiers()
    local inv = inventory_mod()
    if not inv or not inv.get_equipped_ammo_stats then
        return 1, 1
    end
    local ammo = inv.get_equipped_ammo_stats()
    if not ammo then return 1, 1 end
    return ammo.speed_mult or 1, ammo.gravity_mult or 1
end

function M.get_effective_stats(weapon_name)
    weapon_name = weapon_name or weapons.cached_held_ranged() or weapons.get_held_ranged_weapon_name()
    local base = weapons.get_weapon_stats(weapon_name)
    if not base then
        base = { speed = 950, gravity = 0.55, name = weapon_name or "Unknown" }
    end

    local speed = base.speed or 950
    local gravity = base.gravity or 0.55
    local is_bow = base.is_bow
        or (weapon_name and (weapon_name:find("Bow", 1, true) or weapon_name:find("Crossbow", 1, true)))

    local sm = profile_speed_mult(weapon_name)
    if sm ~= 0 then
        speed = speed * (1 + sm)
    end

    local ammo_speed, ammo_grav = ammo_modifiers()
    speed = speed * ammo_speed
    gravity = gravity * ammo_grav

    return {
        speed = speed,
        gravity = gravity,
        name = weapon_name or base.name,
        is_bow = is_bow == true,
        base_speed = base.speed,
        speed_mult = sm,
        ammo_speed_mult = ammo_speed,
        ammo_gravity_mult = ammo_grav,
    }
end

return M

end)()

-- ── core/ballistic.lua ──
April._mods["core.ballistic"] = (function()
--[[ Ballistic prediction — muzzle lead + drop for Fallen projectiles. ]]

local math_util = April.require("core.math_util")

local M = {}

local ROBLOX_GRAV = 196.2
local LEAD_PASSES = 6

local function vec3(v)
    if not v then return 0, 0, 0 end
    return v.x or v.X or 0, v.y or v.Y or 0, v.z or v.Z or 0
end

local function combat_stats_mod()
    return April.require("game.combat_stats")
end

function M.gravity_accel(gravity_mult)
    if not gravity_mult or gravity_mult <= 0 then
        return ROBLOX_GRAV * 0.55
    end
    if gravity_mult <= 2 then
        return ROBLOX_GRAV * gravity_mult
    end
    return gravity_mult
end

function M.calculate_drop(bullet_speed, bullet_gravity, position, origin)
    local px, py, pz = vec3(position)
    local ox, oy, oz = vec3(origin)

    local speed = math.max(bullet_speed or 950, 1)
    local dist = math_util.distance3(px - ox, py - oy, pz - oz)
    local time = dist / speed
    local g = M.gravity_accel(bullet_gravity)
    return 0.5 * g * time * time
end

--[[
    Mouse hit point for muzzle projectile (ViewmodelController uses v321 from MouseRaycast).
    Position + Velocity * time + (0, Drop, 0) — drop from muzzle distance / speed only.
]]
function M.calculate_target_position(bullet_speed, bullet_gravity, velocity, position, origin)
    local px, py, pz = vec3(position)
    local ox, oy, oz = vec3(origin)
    local vx, vy, vz = vec3(velocity)

    local speed = math.max(bullet_speed or 950, 1)
    local g = M.gravity_accel(bullet_gravity)

    local horiz_speed = math.sqrt(vx * vx + vz * vz)
    if horiz_speed < 1.5 then
        vx, vy, vz = 0, vy, 0
    end

    vy = math.max(-80, math.min(80, vy))

    local time = math_util.distance3(px - ox, py - oy, pz - oz) / speed

    for _ = 1, LEAD_PASSES do
        local tx = px + vx * time
        local ty = py + vy * time
        local tz = pz + vz * time
        time = math_util.distance3(tx - ox, ty - oy, tz - oz) / speed
    end

    local tx = px + vx * time
    local ty = py + vy * time
    local tz = pz + vz * time
    local drop = 0.5 * g * time * time

    return {
        x = tx,
        y = ty + drop,
        z = tz,
    }
end

function M.predict_for_weapon(origin, position, velocity, weapon_name)
    local stats = combat_stats_mod().get_effective_stats(weapon_name)
    return M.calculate_target_position(stats.speed, stats.gravity, velocity, position, origin)
end

return M

end)()

-- ── game/combat_origin.lua ──
April._mods["game.combat_origin"] = (function()
--[[ Ray origins — cheap per-frame viewmodel muzzle / server body (no tree scans). ]]

local env = April.require("core.env")
local weapons = April.require("game.weapons")

local M = {}

local frame = { t = 0, weapon = nil, muzzle = nil, server = nil }

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function find_child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        return parent:find_first_child(name) or parent:FindFirstChild(name)
    end)
end

local function part_pos(part)
    if not part or not env.is_valid(part) then return nil end
    local p = part.Position or part.position
    if p and p.x ~= nil then
        return { x = p.x, y = p.y, z = p.z }
    end
    return nil
end

local function vec3_from_cf(cf)
    if not cf then return nil end
    local pos = cf.Position or cf.position
    if pos and pos.x ~= nil then
        return { x = pos.x, y = pos.y, z = pos.z }
    end
    return nil
end

local function camera_origin()
    if not camera or not camera.get_position then return nil end
    local ok, pos = pcall(camera.get_position)
    if ok and pos and pos.x then
        return { x = pos.x, y = pos.y, z = pos.z }
    end
    return nil
end

local function viewmodel_cframe_origin()
    local lp = env.get_local_player()
    local char = lp and lp.character
    if not char or not env.is_valid(char) then return nil end

    local cc = find_child(char, "CameraController")
    if not cc then return nil end

    local cf = env.safe_call(function() return cc:GetAttribute("ViewmodelCFrame") end)
    if not cf then return nil end

    local pos = vec3_from_cf(cf)
    if not pos then return nil end

    local look = cf.LookVector or cf.lookVector
    if look and look.x then
        return {
            x = pos.x + look.x * 0.5,
            y = pos.y + look.y * 0.5,
            z = pos.z + look.z * 0.5,
        }
    end
    return pos
end

local function flashpart_origin()
    local ws = env.get_workspace()
    if not ws then return nil end

    local vms = env.safe_call(function() return ws:find_first_child("Viewmodels") end)
        or env.safe_call(function() return ws:FindFirstChild("Viewmodels") end)
    if not vms then return nil end

    local vm = env.safe_call(function() return vms:find_first_child("Viewmodel") end)
        or env.safe_call(function() return vms:FindFirstChild("Viewmodel") end)
    if not vm then return nil end

    local flash = find_child(vm, "FlashPart") or find_child(vm, "Flash")
    return part_pos(flash)
end

local function compute_muzzle(weapon)
    local flash = flashpart_origin()
    if flash then return flash end

    local cframe = viewmodel_cframe_origin()
    if cframe then return cframe end

    if weapon and weapons.is_bow_weapon_name(weapon) then
        return camera_origin()
    end

    return camera_origin()
end

local function compute_server()
    local lp = env.get_local_player()
    if not lp then return nil end

    if lp.position then
        return { x = lp.position.x, y = lp.position.y, z = lp.position.z }
    end

    local char = lp.character
    if char and env.is_valid(char) then
        return part_pos(find_child(char, "HumanoidRootPart"))
    end

    return nil
end

function M.invalidate()
    frame.t = 0
    frame.weapon = nil
    frame.muzzle = nil
    frame.server = nil
end

function M.sync_weapon(weapon)
    weapon = weapon or weapons.cached_held_ranged()
    local now = tick_ms()
    if frame.t == now and frame.weapon == weapon and frame.muzzle then
        return
    end
    frame.t = now
    frame.weapon = weapon
    frame.muzzle = compute_muzzle(weapon)
    frame.server = compute_server()
end

function M.get_muzzle_origin()
    M.sync_weapon()
    return frame.muzzle
end

function M.get_server_origin()
    M.sync_weapon()
    return frame.server
end

function M.get_camera_origin()
    if not camera or not camera.get_position then return nil end
    local ok, pos = pcall(camera.get_position)
    if ok and pos and pos.x then
        return { x = pos.x, y = pos.y, z = pos.z }
    end
    return nil
end

function M.get_fire_origin()
    M.sync_weapon()
    return frame.muzzle or frame.server
end

return M

end)()

-- ── game/farm_tools.lua ──
April._mods["game.farm_tools"] = (function()
--[[ Gather / farm tool detection for Farm Helper (NodeSpark / TreeX). ]]

local bootstrap = April.require("game.bootstrap")
local env = April.require("core.env")

local M = {}

local loaded = false
local farm_tools = {}

-- Fallback when ToolInfo is unavailable (Melee + Trees or Nodes in dump ToolInfo).
local FALLBACK_GATHER_TOOLS = {
    ["Stone Hatchet"] = true,
    ["Iron Shard Hatchet"] = true,
    ["Steel Axe"] = true,
    Chainsaw = true,
    ["Stone Pickaxe"] = true,
    ["Iron Shard Pickaxe"] = true,
    ["Steel Pickaxe"] = true,
    ["Mining Drill"] = true,
    ["Bone Tool"] = true,
    ["Candy Cane"] = true,
    ["Carrot Blade"] = true,
    ["Halloween Scythe"] = true,
    Boulder = true,
}

local NAME_HINTS = {
    "hatchet", "pickaxe", "pick axe", " axe", "axe ",
    "chainsaw", "mining drill", "bone tool",
    "candy cane", "carrot blade", "halloween scythe", "boulder",
}

local function inst_name(inst)
    if not inst then return nil end
    return inst.name or inst.Name
end

local function entry_can_gather(entry)
    if not entry or not entry.Melee then return false end
    local od = entry.ObjectDamages
    if not od then return false end
    return od.Trees ~= nil or od.Nodes ~= nil
end

local function normalize(name)
    if not name or name == "" then return nil end
    return name
end

local function name_hint_match(name)
    local n = (name or ""):lower()
    for _, hint in ipairs(NAME_HINTS) do
        if n:find(hint, 1, true) then return true end
    end
    return false
end

function M.load()
    if loaded then return true end

    farm_tools = {}
    for name in pairs(FALLBACK_GATHER_TOOLS) do
        farm_tools[name] = true
    end

    local data = bootstrap.get_module("ToolInfo")
    if type(data) == "table" then
        for name, entry in pairs(data) do
            if type(name) == "string" and entry_can_gather(entry) then
                farm_tools[name] = true
            end
        end
    end

    loaded = true
    return next(farm_tools) ~= nil
end

function M.invalidate()
    loaded = false
    farm_tools = {}
end

function M.is_farm_tool_name(name)
    name = normalize(name)
    if not name then return false end
    if not loaded then M.load() end
    if farm_tools[name] then return true end
    return name_hint_match(name)
end

local function pick_farm_name(name)
    if M.is_farm_tool_name(name) then return name end
    return nil
end

local function scan_children(list)
    if not list then return nil end
    for _, child in ipairs(list) do
        local hit = pick_farm_name(inst_name(child))
        if hit then return hit end
    end
    return nil
end

function M.get_held_farm_tool_name()
    if not loaded then M.load() end

    local lp = env.get_local_player()
    if not lp then return nil end

    local char = lp.character
    if char and env.is_valid(char) then
        local hit = scan_children(env.safe_call(function() return char:get_children() end))
        if hit then return hit end
    end

    local ws = env.get_workspace()
    if ws then
        local vms = env.safe_call(function() return ws:find_first_child("Viewmodels") end)
            or env.safe_call(function() return ws:FindFirstChild("Viewmodels") end)
        if vms then
            for _, vm in ipairs(env.safe_call(function() return vms:get_children() end) or {}) do
                if inst_name(vm) == "Viewmodel" then
                    local hit = scan_children(env.safe_call(function() return vm:get_children() end))
                    if hit then return hit end
                end
            end
        end
    end

    return pick_farm_name(lp.tool_name)
end

function M.holding_farm_tool()
    return M.get_held_farm_tool_name() ~= nil
end

function M.all_names()
    if not loaded then M.load() end
    local out = {}
    for name in pairs(farm_tools) do
        out[#out + 1] = name
    end
    table.sort(out)
    return out
end

return M

end)()

-- ── game/inventory.lua ──
April._mods["game.inventory"] = (function()
local env = April.require("core.env")
local items = April.require("game.items")
local item_catalog = April.require("game.item_catalog")

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

    local row = item_catalog.get(id)
    if row and row.name then return row.name end

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

local function read_attribute(inst, key)
    if not inst or not key then return nil end
    if inst.GetAttribute then return inst:GetAttribute(key) end
    if inst.get_attribute then return inst:get_attribute(key) end
    return nil
end

local function find_child(char, name)
    if not char then return nil end
    return env.safe_call(function()
        if char.find_first_child then return char:find_first_child(name) end
        return char:FindFirstChild(name)
    end)
end

function M.get_toolbar_entry(char)
    if not char or not env.is_valid(char) then return nil, nil end

    local ic = find_child(char, "InventoryController")
    if not ic then return nil, nil end

    local fetch = env.safe_call(function()
        if ic.find_first_child then return ic:find_first_child("Fetch") end
        return ic:FindFirstChild("Fetch")
    end)
    if not fetch or not fetch.Invoke then return nil, nil end

    local slot = read_attribute(find_child(char, "EquipController"), "Equipped")
    if type(slot) ~= "number" or slot <= 0 then
        slot = read_attribute(find_child(char, "ViewmodelController"), "Equipped")
    end
    if type(slot) ~= "number" or slot <= 0 then return nil, nil end

    local ok, data = pcall(function() return fetch:Invoke() end)
    if not ok or type(data) ~= "table" then return nil, nil end

    local toolbar = data.Toolbar or data.toolbar
    if type(toolbar) ~= "table" then return nil, nil end

    local entry = toolbar[slot]
    if not entry or entry == 0 then return nil, nil end
    if type(entry) == "table" and entry.Amount and entry.Amount <= 0 then return nil, nil end

    return entry, slot
end

function M.get_equipped_ammo_stats()
    local lp = env.get_local_player()
    local char = lp and lp.character
    if not char or not env.is_valid(char) then return nil end

    local entry = M.get_toolbar_entry(char)
    if not entry or type(entry) ~= "table" then return nil end

    local ammo = entry.Ammo
    if not ammo or type(ammo) ~= "table" then return nil end

    local ammo_id = ammo.ID
    if type(ammo_id) ~= "number" then return nil end

    items.load()
    local row = items.get_by_id and items.get_by_id(ammo_id)
    if row and row.AmmoStats then return row.AmmoStats end

    local rep = env.get_replicated_storage()
    if rep then
        local modules = env.safe_call(function() return rep:find_first_child("Modules") end)
        local items_mod = modules and env.safe_call(function() return modules:find_first_child("Items") end)
        if items_mod then
            local ok, data = pcall(function() return require(items_mod) end)
            if ok and data and data[ammo_id] and data[ammo_id].AmmoStats then
                return data[ammo_id].AmmoStats
            end
        end
    end

    return nil
end

function M.get_toolbar_held_name(char)
    local entry = M.get_toolbar_entry(char)
    if not entry then return nil end

    local id = type(entry) == "table" and entry.ID or entry
    if type(id) ~= "number" then return nil end

    return M.resolve_item_name(id)
end

function M.get_held_tool_name()
    local lp = env.get_local_player()
    if not lp then return nil end
    if lp.tool_name and lp.tool_name ~= "" then return lp.tool_name end

    local char = lp.character
    if not char or not env.is_valid(char) then return nil end

    local toolbar_name = M.get_toolbar_held_name(char)
    if toolbar_name and toolbar_name ~= "" then return toolbar_name end

    for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
        if child.ClassName == "Tool" then return child.Name end
    end
    return nil
end

return M

end)()

-- ── game/player_gear.lua ──
April._mods["game.player_gear"] = (function()
local env = April.require("core.env")
local items = April.require("game.items")
local item_catalog = April.require("game.item_catalog")
local inventory = April.require("game.inventory")
local weapons = April.require("game.weapons")

local M = {}

local ARMOR_ATTRIBUTES = {
    "ResistWet",
    "HasFlippers",
    "HasTank",
    "HasGoggles",
    "NVG",
    "SilentSteps",
    "WaterFilter",
    "SteelToes",
    "Snorkle",
}

local ATTACHMENT_SLOT_HINTS = {
    ["p1"] = true, ["p2"] = true, ["p3"] = true, ["p4"] = true,
    ["slot1"] = true, ["slot2"] = true, ["slot3"] = true,
    ["sight"] = true, ["muzzle"] = true, ["underbarrel"] = true,
}

local function parse_variant_name(name)
    if not name then return nil, nil end
    local base, variant = name:match("^([^/]+)/(.+)$")
    if base and variant then
        return base, variant
    end
    return name, nil
end

local function read_attribute(inst, key)
    if not inst or not key then return nil end
    if inst.GetAttribute then
        return inst:GetAttribute(key)
    end
    if inst.get_attribute then
        return inst:get_attribute(key)
    end
    return nil
end

local function is_tool(inst)
    if not inst then return false end
    local cn = inst.ClassName or inst.class_name
    return cn == "Tool"
end

local function is_attachment_slot_name(name)
    if not name or name == "" then return true end
    local lower = name:lower()
    if ATTACHMENT_SLOT_HINTS[lower] then return true end
    if lower:match("^p%d+$") then return true end
    if lower:match("^slot%d+$") then return true end
    return false
end

local function is_armor_child_name(name)
    if not name or name == "" then return true end
    if name:sub(1, 6) == "Armor_" or name:sub(1, 6) == "Armor:" then return true end
    if name:find("Armor", 1, true) and name:find("/", 1, true) then return true end
    return false
end

local function is_attachment_name(name)
    if not name or name == "" then return false end
    if is_attachment_slot_name(name) then return false end

    local base = select(1, parse_variant_name(name))
    local row = item_catalog.get_by_name(base)
    if row and row.type == "Attachment" then return true end

    local t = items.get_type(base)
    return t == "Attachment"
end

local function is_valid_held_label(name)
    if not name or name == "" then return false end
    if is_attachment_slot_name(name) then return false end
    if is_armor_child_name(name) then return false end
    if is_attachment_name(name) then return false end
    return true
end

local function looks_like_held_item(name)
    if not is_valid_held_label(name) then return false end
    if weapons.is_weapon_name(name) then return true end
    if items.is_held_display(name) then return true end
    return true
end

local function add_armor_piece(out, seen, piece)
    if not piece or not piece.name then return end
    if seen[piece.name] then return end
    seen[piece.name] = true
    table.insert(out.armor, piece)
end

local function add_held_piece(out, label)
    if not is_valid_held_label(label) then return false end

    local piece = items.resolve_item_label(label)
    if not piece then
        local base, variant = parse_variant_name(label)
        piece = items.make_piece(base or label, variant)
    end

    out.held = piece
    return true
end

local function add_attachment_piece(out, seen, label)
    if not label or label == "" then return end
    if is_attachment_slot_name(label) then return end
    if not is_attachment_name(label) then return end
    if seen[label] then return end

    seen[label] = true
    local piece = items.resolve_item_label(label)
    if not piece then
        local base, variant = parse_variant_name(label)
        piece = items.make_piece(base or label, variant)
    end
    table.insert(out.attachments, piece)
end

local function try_armor_model(out, seen, name)
    if not name then return end

    if name:sub(1, 6) == "Armor_" then
        add_armor_piece(out, seen, items.resolve_armor_model(name))
        return
    end

    if name:sub(1, 6) == "Armor:" then
        add_armor_piece(out, seen, items.resolve_item_label(name:sub(7)))
    end
end

local function try_armor_attribute(out, seen, attr_key)
    if not attr_key or attr_key:sub(1, 6) ~= "Armor_" then return end

    local tail = attr_key:match("^Armor_(.+)$")
    if not tail then return end

    local piece = items.resolve_armor_model(attr_key)
    if piece then
        add_armor_piece(out, seen, piece)
        return
    end

    local row = item_catalog.get_by_attribute(tail)
    if row and row.name then
        if tail == "ResistWet" and (seen["Hazmat Suit"] or seen["Wetsuit"]) then
            return
        end
        add_armor_piece(out, seen, items.make_piece(row.name, nil))
    end
end

local function scan_armor_attributes(inst, out, seen)
    for _, attr in ipairs(ARMOR_ATTRIBUTES) do
        local key = "Armor_" .. attr
        if read_attribute(inst, key) then
            try_armor_attribute(out, seen, key)
        end
    end

    local attrs = env.safe_call(function()
        if inst.get_attributes then return inst:get_attributes() end
        if inst.GetAttributes then return inst:GetAttributes() end
    end)

    if type(attrs) == "table" then
        for key in pairs(attrs) do
            if type(key) == "string" then
                try_armor_attribute(out, seen, key)
            end
        end
    end
end

local function scan_sleeves_string(out, seen, sleeves)
    if not sleeves or sleeves == "" then return end
    for entry in sleeves:gmatch("[^%^]+") do
        entry = entry:match("^%s*(.-)%s*$")
        if entry and entry ~= "" then
            add_armor_piece(out, seen, items.resolve_item_label(entry))
        end
    end
end

local function resolve_character(player)
    if player.character and env.is_valid(player.character) then
        return player.character
    end

    if player.player and env.is_valid(player.player) then
        local char = env.safe_call(function()
            local pl = player.player
            if pl.Character then return pl.Character end
            if pl.character then return pl.character end
        end)
        if char and env.is_valid(char) then return char end
    end

    if player.name and game and game.workspace then
        local char = env.safe_call(function()
            if game.workspace.find_first_child then
                return game.workspace:find_first_child(player.name)
            end
        end)
        if char and env.is_valid(char) then return char end
    end

    return nil
end

local function resolve_player_inst(player)
    if player.player and env.is_valid(player.player) then
        return player.player
    end
    if not player.name or not game or not game.players then return nil end
    return env.safe_call(function()
        if game.players.find_first_child then
            return game.players:find_first_child(player.name)
        end
    end)
end

local function find_inst_by_name(char, name)
    if not char or not name then return nil end

    for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
        local child_name = child.Name or child.name
        if child_name == name then
            return child
        end
    end

    return nil
end

local function find_held_on_character(char)
    if not char then return nil, nil end

    local fallback = nil
    for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
        local name = child.Name or child.name
        if not name or name == "" or is_armor_child_name(name) then goto continue end
        if not is_valid_held_label(name) then goto continue end

        if is_tool(child) then
            return name, child
        end

        local cn = child.ClassName or child.class_name
        if cn == "Model" and looks_like_held_item(name) then
            if weapons.is_weapon_name(name) or items.is_held_display(name) then
                return name, child
            end
            fallback = fallback or { name = name, inst = child }
        end

        ::continue::
    end

    if fallback then
        return fallback.name, fallback.inst
    end

    return nil, nil
end

local function resolve_held_weapon(player, char)
    if player.tool_name and player.tool_name ~= "" and is_valid_held_label(player.tool_name) then
        local inst = char and find_inst_by_name(char, player.tool_name) or nil
        return player.tool_name, inst
    end

    if char then
        local toolbar_name = inventory.get_toolbar_held_name(char)
        if toolbar_name and is_valid_held_label(toolbar_name) then
            local inst = find_inst_by_name(char, toolbar_name) or select(2, find_held_on_character(char))
            return toolbar_name, inst
        end

        local name, inst = find_held_on_character(char)
        if name then
            return name, inst
        end
    end

    if player.is_local then
        local name = weapons.get_held_weapon_name()
        if name and is_valid_held_label(name) then
            local inst = char and (find_inst_by_name(char, name) or select(2, find_held_on_character(char))) or nil
            return name, inst
        end
    end

    return nil, nil
end

local function scan_attachments_folder(folder, out, seen)
    if not folder or not env.is_valid(folder) then return end

    local children = env.safe_call(function()
        if folder.get_children then return folder:get_children() end
        if folder.GetChildren then return folder:GetChildren() end
    end) or {}

    for _, child in ipairs(children) do
        local name = child.Name or child.name
        if name and name ~= "" then
            add_attachment_piece(out, seen, name)
        end
    end
end

local function scan_weapon_attachments(char, tool_inst, out, seen)
    if tool_inst and env.is_valid(tool_inst) then
        local attachments = env.safe_call(function()
            if tool_inst.find_first_child then return tool_inst:find_first_child("Attachments") end
            return tool_inst:FindFirstChild("Attachments")
        end)
        scan_attachments_folder(attachments, out, seen)

        local weapon = env.safe_call(function()
            if tool_inst.find_first_child then return tool_inst:find_first_child("Weapon") end
            return tool_inst:FindFirstChild("Weapon")
        end)
        if weapon and env.is_valid(weapon) then
            local nested = env.safe_call(function()
                if weapon.find_first_child then return weapon:find_first_child("Attachments") end
                return weapon:FindFirstChild("Attachments")
            end)
            scan_attachments_folder(nested, out, seen)
        end
        return
    end

    if not char then return end
    for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
        if is_tool(child) or (child.ClassName or child.class_name) == "Model" then
            scan_weapon_attachments(char, child, out, seen)
        end
    end
end

local function scan_armor_tree(inst, out, seen, depth)
    if not inst or not env.is_valid(inst) or depth > 8 then return end

    local name = inst.Name or inst.name
    if name and name ~= "" then
        if name:sub(1, 6) == "Armor_" or name:sub(1, 6) == "Armor:" then
            try_armor_model(out, seen, name)
        end
    end

    local children = env.safe_call(function()
        if inst.get_children then return inst:get_children() end
        if inst.GetChildren then return inst:GetChildren() end
    end) or {}

    for _, child in ipairs(children) do
        scan_armor_tree(child, out, seen, depth + 1)
    end
end

function M.scan_player(player)
    local out = {
        held = nil,
        attachments = {},
        armor = {},
    }

    if not player then return out end

    local char = resolve_character(player)
    local held_name, tool_inst = resolve_held_weapon(player, char)

    if held_name then
        add_held_piece(out, held_name)
    end

    local att_seen = {}
    scan_weapon_attachments(char, tool_inst, out, att_seen)

    local seen = {}
    if char then
        scan_armor_tree(char, out, seen, 0)
        scan_armor_attributes(char, out, seen)
    end

    local pl = resolve_player_inst(player)
    if pl then
        scan_armor_attributes(pl, out, seen)
        scan_sleeves_string(out, seen, read_attribute(pl, "ArmorSleeves"))
    end

    return out
end

return M

end)()

-- ── game/player_state.lua ──
April._mods["game.player_state"] = (function()
--[[ Fallen player state — Humanoid:GetAttribute("Downed") from game scripts. ]]

local env = April.require("core.env")

local M = {}

function M.is_downed(player)
    if not player then return false end

    local hum = player.humanoid
    if not hum and player.character then
        hum = env.safe_call(function()
            if player.character.FindFirstChildOfClass then
                return player.character:FindFirstChildOfClass("Humanoid")
            end
            return player.character:FindFirstChild("Humanoid")
        end)
    end
    if not hum then return false end

    local down = env.safe_call(function()
        if hum.GetAttribute then
            return hum:GetAttribute("Downed")
        end
        if hum.get_attribute then
            return hum:get_attribute("Downed")
        end
        return nil
    end)

    return down == true
end

function M.is_combat_target(player)
    if not player or player.is_local then return false end
    if not player.is_alive then return false end
    return true
end

function M.passes_health_check(player)
    if not player then return false end
    if not player.is_alive then return false end
    if M.is_downed(player) then return false end
    if player.health and player.health <= 0 then return false end
    return true
end

function M.passes_team_check(player)
    if not player then return false end
    if not entity or not entity.get_local_player then return true end

    local lp = entity.get_local_player()
    if not lp then return true end
    if not lp.has_team or not player.has_team then return true end
    if not lp.team or not player.team or lp.team == "" or player.team == "" then return true end

    return lp.team ~= player.team
end

return M

end)()

-- ── game/brainrot_catalog.lua ──
April._mods["game.brainrot_catalog"] = (function()
--[[ Brainrot character catalog — PNGs hosted on GitHub CDN. ]]

local asset_urls = April.require("game.asset_urls")

local M = {}

M.ENTRIES = {
    { file = "tung_tung_sahur", name = "Tung Tung Sahur" },
    { file = "tralalero_tralala", name = "Tralalero Tralala" },
    { file = "brr_brr_patapim", name = "Brr Brr Patapim" },
    { file = "orangutini", name = "Orangutini Ananasini" },
    { file = "cappuccino_assassino", name = "Cappuccino Assassino" },
    { file = "lirili_larila", name = "Lirili Larila" },
    { file = "boneca_ambalabu", name = "Boneca Ambalabu" },
    { file = "bombardiro_crocodilo", name = "Bombardiro Crocodilo" },
    { file = "chimpanzini", name = "Chimpanzini Bananini" },
    { file = "ta_ta_sahur", name = "Ta Ta Ta Sahur" },
    { file = "tung_head", name = "Tung Tung Head" },
    { file = "tung_clipart", name = "Tung Clipart" },
    { file = "trippi_troppi", name = "Trippi Troppi" },
    { file = "frigo_camelo", name = "Frigo Camelo" },
    { file = "ballerina_cappuccina", name = "Ballerina Cappuccina" },
    { file = "udin_din_din", name = "Udin Din Din Dun" },
}

function M.image_key(file)
    return "brainrot_" .. (file or "")
end

function M.url(file)
    return asset_urls.brainrot_png(file)
end

function M.combo_labels()
    local out = {}
    for _, entry in ipairs(M.ENTRIES) do
        out[#out + 1] = entry.name
    end
    return out
end

function M.entry_at_index(idx)
    return M.ENTRIES[(idx or 0) + 1]
end

return M

end)()

-- ── game/npcs.lua ──
April._mods["game.npcs"] = (function()
--[[
    Fallen hostile NPCs — Soldiers + bosses under Workspace.Military monuments.
    Soldiers spawn at runtime (not in static dump); scan runs periodically.
]]

local env = April.require("core.env")
local folders = April.require("game.folders")

local M = {}

M.HOSTILE_NAMES = {
    Soldier = true,
    Bruno = true,
    Boris = true,
    Brutus = true,
}

function M.is_hostile_name(name)
    return name and M.HOSTILE_NAMES[name] == true
end

function M.kind(name)
    if name == "Soldier" then return "soldier" end
    if name == "Bruno" or name == "Boris" or name == "Brutus" then return "boss" end
    return nil
end

local function read_health(model)
    local hum = env.safe_call(function()
        if model.find_first_child_of_class then
            return model:find_first_child_of_class("Humanoid")
        end
        for _, child in ipairs(model:get_children()) do
            if child.ClassName == "Humanoid" then return child end
        end
        return nil
    end)
    if not hum then return nil end
    local hp = hum.Health or hum.health
    if hp and hp <= 0 then return nil end
    return hum
end

local function try_add_npc(out, model, seen)
    if not env.is_valid(model) then return end
    local cn = model.ClassName or model.class_name
    if cn ~= "Model" then return end

    local name = model.Name or model.name
    if not M.is_hostile_name(name) then return end

    local addr = model.Address or model.address or tostring(model)
    if seen[addr] then return end

    if not read_health(model) then return end

    local head = env.safe_call(function()
        return model:find_first_child("Head") or model:FindFirstChild("Head")
    end)
    if not head or not env.is_valid(head) then return end

    seen[addr] = true

    local pos = head.Position or head.position
    local entry = {
        inst = model,
        name = name,
        kind = M.kind(name),
        head = head,
    }
    if pos and pos.x then
        entry.lx = pos.x
        entry.ly = pos.y
        entry.lz = pos.z
    end
    table.insert(out, entry)
end

function M.begin_scan()
    return {
        monuments = nil,
        mi = 1,
        queue = {},
        qi = 1,
        out = {},
        seen = {},
    }
end

function M.step_scan(state, batch)
    if not state.monuments then
        state.monuments = env.safe_call(function()
            local military = folders.from_key("military")
            if not env.is_valid(military) then return {} end
            return military:get_children()
        end) or {}
        state.mi = 1
        state.queue = {}
        state.qi = 1
    end

    local processed = 0

    while processed < batch do
        if state.qi > #state.queue then
            if state.mi > #state.monuments then
                return true
            end

            local monument = state.monuments[state.mi]
            state.mi = state.mi + 1
            processed = processed + 1

            if env.is_valid(monument) then
                table.insert(state.queue, { inst = monument, depth = 0 })
            end
            goto continue
        end

        local item = state.queue[state.qi]
        state.qi = state.qi + 1
        processed = processed + 1

        local container = item.inst
        if not env.is_valid(container) or item.depth > 4 then goto continue end

        try_add_npc(state.out, container, state.seen)

        local children = env.safe_call(function() return container:get_children() end) or {}
        for _, child in ipairs(children) do
            try_add_npc(state.out, child, state.seen)
            if item.depth < 4 and env.is_valid(child) then
                table.insert(state.queue, { inst = child, depth = item.depth + 1 })
            end
        end

        ::continue::
    end

    return false
end

function M.complete_scan(state)
    return state.out or {}
end

function M.scan()
    local state = M.begin_scan()
    while not M.step_scan(state, 9999) do end
    return M.complete_scan(state)
end

return M

end)()

-- ── game/mod_ids.lua ──
April._mods["game.mod_ids"] = (function()
--[[ Fallen staff / mod user IDs — from matchascript + legacy fallen list. ]]

local M = {}

M.ROLES = {
    [51281722] = "Game Moderator",
    [7178750309] = "Game Moderator",
    [113179883] = "Game Moderator",
    [3122439095] = "Game Moderator",
    [991290934] = "Game Moderator",
    [3968854760] = "Game Moderator",
    [81993536] = "Game Moderator",
    [1004214871] = "Game Moderator",
    [3034930770] = "Game Moderator",
    [2364950171] = "Game Moderator",
    [1528346843] = "Game Moderator",
    [165053216] = "Game Moderator",
    [1127954045] = "Game Moderator",
    [3640120679] = "Game Moderator",
    [602009251] = "Game Moderator",
    [372791101] = "Game Moderator",
    [1378169111] = "Game Moderator",
    [3020799797] = "Game Moderator",
    [2567998467] = "Game Moderator",
    [4243907215] = "Game Moderator",
    [353983652] = "Game Moderator",
    [1406181681] = "Game Moderator",
    [2229169589] = "Game Moderator",
    [3004094651] = "Game Moderator",
    [839333692] = "Game Moderator",
    [979624578] = "Game Moderator",
    [1478885961] = "Game Moderator",
    [399754916] = "Game Moderator",
    [1193091081] = "Game Moderator",
    [4553863490] = "Game Moderator",
    [4225513035] = "Game Moderator",
    [41482597] = "Game Moderator",
    [2924549627] = "Game Moderator",
    [2732967856] = "Game Moderator",
    [1937516999] = "Game Moderator",
    [1374319325] = "Game Moderator",
    [1058831985] = "Game Moderator",
    [9621064456] = "Game Moderator",
    [584370127] = "Game Moderator",
    [813030262] = "Game Moderator",
    [3470393585] = "Game Moderator",
    [122915793] = "Game Moderator",
    [1534692727] = "Game Moderator",
    [7278178099] = "Game Moderator",
    [8593140875] = "Game Moderator",
    [2525997354] = "Game Moderator",
    [3126891654] = "Game Moderator",
    [1190967808] = "Game Moderator",
    [833946684] = "Game Moderator",
    [202751467] = "Game Moderator",
    [510349404] = "Game Moderator",
    [174212818] = "Contribution",
    [25548179] = "Lead Developer",
    [363101315] = "Lead Developer",
    [47983795] = "Co-Founder",
    [16681869] = "Founder",
    -- legacy extras
    [3544497889] = "Game Moderator",
    [3739152618] = "Game Moderator",
    [4252853044] = "Game Moderator",
    [1500535353] = "Game Moderator",
    [1116486172] = "Game Moderator",
    [1304140224] = "Game Moderator",
    [542183759] = "Game Moderator",
    [2620215562] = "Game Moderator",
    [1622256215] = "Game Moderator",
    [2792072212] = "Game Moderator",
    [3994092139] = "Game Moderator",
    [914847610] = "Game Moderator",
    [114812725] = "Game Moderator",
    [1072151937] = "Game Moderator",
    [1771300283] = "Game Moderator",
    [1249478607] = "Game Moderator",
}

function M.role_for(user_id)
    if not user_id then return nil end
    return M.ROLES[user_id] or M.ROLES[tonumber(user_id)]
end

function M.is_mod(user_id)
    return M.role_for(user_id) ~= nil
end

return M

end)()

-- ── game/turret_stats.lua ──
April._mods["game.turret_stats"] = (function()
--[[ Fallen turret ranges — from dump/ReplicatedStorage.Modules.BenchInfo + RayParts layout. ]]

local M = {}

-- Activation / targeting range (what the ring should represent).
M.ACTIVATION_RANGE = {
    ["Auto Turret"] = 100,      -- BenchInfo TypeArguments.TargetRange
    ["Shotgun Turret"] = 110,   -- longest RayPart offset in Benches.Shotgun Turret.Default
}

-- Projectile travel (for reference / future use).
M.BULLET_RANGE = {
    ["Auto Turret"] = 150,      -- BenchInfo TypeArguments.BulletRange
    ["Shotgun Turret"] = 14.25, -- BenchInfo TypeArguments.BulletRange
}

M.DAMAGE_RANGE = {
    ["Auto Turret"] = { 85, 150 },
    ["Shotgun Turret"] = { 9, 25 },
}

function M.activation_range(name)
    return M.ACTIVATION_RANGE[name]
end

return M

end)()

-- ── game/esp_maps.lua ──
April._mods["game.esp_maps"] = (function()
--[[ Fallen Survival ESP maps — derived from dump/hierarchy.txt + legacy fallen.lua ]]

local M = {}

-- ── World: resource nodes (live in Workspace.Vegetation, not Workspace.Nodes) ──

M.NODE_MAP = {
    ["Stone_Node"] = "april_stone_node",
    ["Metal_Node"] = "april_metal_node",
    ["Phosphate_Node"] = "april_phosphate_node",
}

M.NODE_LABELS = {
    ["Stone_Node"] = "Stone Node",
    ["Metal_Node"] = "Metal Node",
    ["Phosphate_Node"] = "Phosphate Node",
}

M.NODE_FOLDERS = { "vegetation", "nodes" }

-- ── World: farm plants (Workspace.Plants) ──

M.PLANT_MAP = {
    ["Corn Plant"] = "april_corn_plant",
    ["Tomato Plant"] = "april_tomato_plant",
    ["Pumpkin Plant"] = "april_pumpkin_plant",
    ["Lemon Plant"] = "april_lemon_plant",
    ["Raspberry Plant"] = "april_raspberry_plant",
    ["Blueberry Plant"] = "april_blueberry_plant",
    ["Wool Plant"] = "april_wool_plant",
    ["Hemp Plant"] = "april_hemp_plant",
    ["Hemp"] = "april_hemp_plant",
}

M.PLANT_LABELS = {
    ["Corn Plant"] = "Corn Plant",
    ["Tomato Plant"] = "Tomato Plant",
    ["Pumpkin Plant"] = "Pumpkin Plant",
    ["Lemon Plant"] = "Lemon Plant",
    ["Raspberry Plant"] = "Raspberry Plant",
    ["Blueberry Plant"] = "Blueberry Plant",
    ["Wool Plant"] = "Wool Plant",
    ["Hemp Plant"] = "Hemp Plant",
    ["Hemp"] = "Hemp",
}

M.PLANT_FOLDERS = { "plants", "vegetation" }

-- ── World: animals (Workspace.Animals) ──

M.ANIMAL_MAP = {
    ["PREFAB_ANIMAL_DEER"] = "april_deer",
    ["PREFAB_ANIMAL_WILDBOAR"] = "april_boar",
    ["PREFAB_ANIMAL_WOLF"] = "april_wolf",
    ["Deer"] = "april_deer",
    ["Wild Boar"] = "april_boar",
    ["WildBoar"] = "april_boar",
    ["Boar"] = "april_boar",
    ["Wolf"] = "april_wolf",
}

M.ANIMAL_LABELS = {
    ["PREFAB_ANIMAL_DEER"] = "Deer",
    ["PREFAB_ANIMAL_WILDBOAR"] = "Wild Boar",
    ["PREFAB_ANIMAL_WOLF"] = "Wolf",
    ["Deer"] = "Deer",
    ["Wild Boar"] = "Wild Boar",
    ["WildBoar"] = "Wild Boar",
    ["Boar"] = "Boar",
    ["Wolf"] = "Wolf",
}

M.ANIMAL_FOLDERS = { "animals" }

M.WORLD_TOGGLES = {
    { id = "april_stone_node", label = "Stone Node", color = { 0.5, 0.5, 0.5, 1 } },
    { id = "april_metal_node", label = "Metal Node", color = { 0.7, 0.5, 0.3, 1 } },
    { id = "april_phosphate_node", label = "Phosphate Node", color = { 0.2, 0.8, 0.2, 1 } },
    { id = "april_corn_plant", label = "Corn Plant", color = { 1, 0.9, 0.3, 1 } },
    { id = "april_tomato_plant", label = "Tomato Plant", color = { 1, 0.4, 0.3, 1 } },
    { id = "april_pumpkin_plant", label = "Pumpkin Plant", color = { 1, 0.5, 0.1, 1 } },
    { id = "april_lemon_plant", label = "Lemon Plant", color = { 1, 0.95, 0.2, 1 } },
    { id = "april_raspberry_plant", label = "Raspberry Plant", color = { 0.9, 0.2, 0.4, 1 } },
    { id = "april_blueberry_plant", label = "Blueberry Plant", color = { 0.3, 0.4, 0.9, 1 } },
    { id = "april_wool_plant", label = "Wool Plant", color = { 0.85, 0.85, 0.9, 1 } },
    { id = "april_hemp_plant", label = "Hemp Plant", color = { 0.3, 0.7, 0.25, 1 } },
    { id = "april_deer", label = "Deer", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_boar", label = "Wild Boar", color = { 0.4, 0.3, 0.2, 1 } },
    { id = "april_wolf", label = "Wolf", color = { 0.5, 0.5, 0.5, 1 } },
}

-- ── Loot ──

M.LOOT_MAP = {
    ["Wooden Crate"] = "april_wooden_crate",
    ["Locked Wooden Crate"] = "april_wooden_crate",
    ["Locked Metal Crate"] = "april_metal_crate",
    ["Locked Steel Crate"] = "april_steel_crate",
    ["Food Crate"] = "april_food_crate",
    ["Timed Crate"] = "april_timed_crate",
    ["Care Package"] = "april_care_package",
    ["BTR Crate"] = "april_btr_crate",
    ["Body Bag"] = "april_body_bag",
    ["Sleeper"] = "april_sleeper",
    ["Trash Can"] = "april_trash_can",
    ["Oil Barrel"] = "april_oil_barrel",
    ["Small Egg"] = "april_small_egg",
    ["Medium Egg"] = "april_medium_egg",
    ["Large Egg"] = "april_large_egg",
    ["Small Gift"] = "april_small_egg",
    ["Medium Gift"] = "april_medium_egg",
    ["Large Gift"] = "april_large_egg",
    ["Wooden Boat"] = "april_wooden_boat",
    ["Military Boat"] = "april_military_boat",
    ["Salvaged Flycopter"] = "april_flycopter",
}

M.LOOT_TOGGLES = {
    { id = "april_dropped_item", label = "Dropped Items", color = { 1, 0.8, 0, 1 } },
    { id = "april_wooden_crate", label = "Wooden Crate", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_metal_crate", label = "Metal Crate", color = { 0.5, 0.5, 0.6, 1 } },
    { id = "april_steel_crate", label = "Steel Crate", color = { 0.7, 0.7, 0.8, 1 } },
    { id = "april_food_crate", label = "Food Crate", color = { 0.2, 0.8, 0.2, 1 } },
    { id = "april_timed_crate", label = "Timed Crate", color = { 1, 0.5, 0, 1 } },
    { id = "april_care_package", label = "Care Package", color = { 1, 0.2, 0.2, 1 } },
    { id = "april_btr_crate", label = "BTR Crate", color = { 0.8, 0.15, 0.15, 1 } },
    { id = "april_body_bag", label = "Body Bag", color = { 0.3, 0.3, 0.3, 1 } },
    { id = "april_sleeper", label = "Sleepers", color = { 0.8, 0.4, 0.8, 1 } },
    { id = "april_trash_can", label = "Trash Can", color = { 0.45, 0.45, 0.45, 1 } },
    { id = "april_oil_barrel", label = "Oil Barrel", color = { 0.2, 0.2, 0.2, 1 } },
    { id = "april_small_egg", label = "Small Egg / Gift", color = { 0.95, 0.85, 0.5, 1 } },
    { id = "april_medium_egg", label = "Medium Egg / Gift", color = { 0.9, 0.7, 0.4, 1 } },
    { id = "april_large_egg", label = "Large Egg / Gift", color = { 0.85, 0.55, 0.3, 1 } },
    { id = "april_wooden_boat", label = "Wooden Boat", color = { 0.55, 0.35, 0.15, 1 } },
    { id = "april_military_boat", label = "Military Boat", color = { 0.35, 0.45, 0.35, 1 } },
    { id = "april_flycopter", label = "Salvaged Flycopter", color = { 0.6, 0.6, 0.65, 1 } },
}

M.LOOT_SCAN_FOLDERS = { "loners", "vegetation", "military", "events", "monuments" }

-- ── Base deployables (Workspace.Bases → player areas) ──

M.BASE_MAP = {
    ["Base Cabinet"] = "april_base_cabinet",
    ["Storage Cabinet"] = "april_storage_cabinet",
    ["Cabinet"] = "april_base_cabinet",
    ["Large Cabinet"] = "april_storage_cabinet",
    ["Small Storage Box"] = "april_small_box",
    ["Large Storage Box"] = "april_large_box",
    ["Small Box"] = "april_small_box",
    ["Large Box"] = "april_large_box",
    ["Wooden Door"] = "april_wooden_door",
    ["Wooden Double Door"] = "april_wooden_double_door",
    ["Salvaged Metal Door"] = "april_salvaged_door",
    ["Metal Door"] = "april_metal_door",
    ["Metal Double Door"] = "april_metal_double_door",
    ["Steel Door"] = "april_steel_door",
    ["Steel Double Door"] = "april_steel_double_door",
    ["Trap Door"] = "april_trap_door",
    ["Triangle Trap Door"] = "april_triangle_trap_door",
    ["Garage Door"] = "april_garage_door",
    ["Sleeping Bag"] = "april_sleeping_bag",
    ["Shotgun Turret"] = "april_shotgun_turret",
    ["Auto Turret"] = "april_auto_turret",
    ["Small Battery"] = "april_small_battery",
    ["Medium Battery"] = "april_medium_battery",
    ["Large Battery"] = "april_large_battery",
    ["Solar Panel"] = "april_solar_panel",
    ["Windmill"] = "april_windmill",
}

M.BASE_SKIP_AREAS = {
    Loners = true,
    VMs = true,
    BTRMonumentPaths = true,
    Benches = true,
    Wires = true,
    Ragdolls = true,
    Fire = true,
}

M.BASE_TOGGLES = {
    { id = "april_base_cabinet", label = "Base Cabinet", color = { 1, 0.8, 0, 1 } },
    { id = "april_storage_cabinet", label = "Storage Cabinet", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_small_box", label = "Small Storage Box", color = { 0.55, 0.35, 0.15, 1 } },
    { id = "april_large_box", label = "Large Storage Box", color = { 0.45, 0.3, 0.12, 1 } },
    { id = "april_sleeping_bag", label = "Sleeping Bag", color = { 0.8, 0.2, 0.2, 1 } },
    { id = "april_auto_turret", label = "Auto Turret", color = { 1, 0.2, 0.2, 1 }, ring_id = "april_auto_turret_ring" },
    { id = "april_shotgun_turret", label = "Shotgun Turret", color = { 1, 0.35, 0.2, 1 }, ring_id = "april_shotgun_turret_ring" },
    { id = "april_wooden_door", label = "Wooden Door", color = { 0.5, 0.3, 0.1, 1 } },
    { id = "april_wooden_double_door", label = "Wooden Double Door", color = { 0.55, 0.32, 0.12, 1 } },
    { id = "april_metal_door", label = "Metal Door", color = { 0.5, 0.5, 0.6, 1 } },
    { id = "april_salvaged_door", label = "Salvaged Metal Door", color = { 0.55, 0.52, 0.48, 1 } },
    { id = "april_metal_double_door", label = "Metal Double Door", color = { 0.52, 0.52, 0.58, 1 } },
    { id = "april_steel_door", label = "Steel Door", color = { 0.65, 0.65, 0.72, 1 } },
    { id = "april_steel_double_door", label = "Steel Double Door", color = { 0.62, 0.62, 0.7, 1 } },
    { id = "april_garage_door", label = "Garage Door", color = { 0.4, 0.4, 0.42, 1 } },
    { id = "april_trap_door", label = "Trap Door", color = { 0.48, 0.38, 0.22, 1 } },
    { id = "april_triangle_trap_door", label = "Triangle Trap Door", color = { 0.46, 0.36, 0.2, 1 } },
    { id = "april_small_battery", label = "Small Battery", color = { 0.2, 0.75, 0.35, 1 } },
    { id = "april_medium_battery", label = "Medium Battery", color = { 0.15, 0.65, 0.3, 1 } },
    { id = "april_large_battery", label = "Large Battery", color = { 0.1, 0.55, 0.25, 1 } },
    { id = "april_solar_panel", label = "Solar Panel", color = { 0.2, 0.4, 0.85, 1 } },
    { id = "april_windmill", label = "Windmill", color = { 0.75, 0.85, 0.95, 1 } },
}

function M.toggle_color(list, toggle_id, fallback)
    for _, t in ipairs(list or {}) do
        if t.id == toggle_id then
            return t.color
        end
    end
    return fallback or { 1, 1, 1, 1 }
end

function M.turret_ring_toggle(toggle_id)
    for _, t in ipairs(M.BASE_TOGGLES) do
        if t.id == toggle_id then
            return t.ring_id
        end
    end
    return nil
end

return M

end)()

-- ── game/esp_scan.lua ──
April._mods["game.esp_scan"] = (function()
--[[ Shared ESP scan helpers — part lookup + oriented 3D box data. ]]

local env = April.require("core.env")

local M = {}

local PART_CLASSES = {
    Part = true,
    MeshPart = true,
    UnionOperation = true,
}

function M.is_part(inst)
    if not inst then return false end
    local cn = inst.ClassName or inst.class_name
    return PART_CLASSES[cn] == true
end

function M.find_main_part(model)
    if not env.is_valid(model) then return nil end

    local main = env.safe_call(function()
        if model.Main then return model.Main end
        return model:find_first_child("Main") or model:FindFirstChild("Main")
    end)
    if main and M.is_part(main) then return main end

    local hrp = env.safe_call(function()
        if model.HumanoidRootPart then return model.HumanoidRootPart end
        return model:find_first_child("HumanoidRootPart") or model:FindFirstChild("HumanoidRootPart")
    end)
    if hrp and M.is_part(hrp) then return hrp end

    local children = env.safe_call(function() return model:get_children() end) or {}
    for _, child in ipairs(children) do
        if M.is_part(child) then return child end
    end

    if M.is_part(model) then return model end
    return nil
end

local function vec3(v, axis)
    if not v then return 0 end
    if axis == "x" then return v.x or v.X or 0 end
    if axis == "y" then return v.y or v.Y or 0 end
    return v.z or v.Z or 0
end

function M.read_part_box(part)
    if not env.is_valid(part) or not M.is_part(part) then return nil end

    local pos, size, rv, uv, lv
    pcall(function()
        pos = part.Position or part.position
        size = part.Size or part.size
        rv = part.RightVector or part.right_vector
        uv = part.UpVector or part.up_vector
        lv = part.LookVector or part.look_vector
    end)

    if not pos or not size then return nil end

    return {
        x = vec3(pos, "x"),
        y = vec3(pos, "y"),
        z = vec3(pos, "z"),
        hx = vec3(size, "x") * 0.5,
        hy = vec3(size, "y") * 0.5,
        hz = vec3(size, "z") * 0.5,
        rx = rv and vec3(rv, "x") or 1,
        ry = rv and vec3(rv, "y") or 0,
        rz = rv and vec3(rv, "z") or 0,
        ux = uv and vec3(uv, "x") or 0,
        uy = uv and vec3(uv, "y") or 1,
        uz = uv and vec3(uv, "z") or 0,
        lx = lv and vec3(lv, "x") or 0,
        ly = lv and vec3(lv, "y") or 0,
        lz = lv and vec3(lv, "z") or 1,
    }
end

function M.collect_boxes(model, max_parts)
    max_parts = max_parts or 6
    local boxes = {}
    if not env.is_valid(model) then return boxes end

    local main = M.find_main_part(model)
    if main then
        local box = M.read_part_box(main)
        if box then table.insert(boxes, box) end
    end

    if #boxes >= max_parts then return boxes end

    local desc = env.safe_call(function() return model:get_descendants() end) or {}
    for _, inst in ipairs(desc) do
        if #boxes >= max_parts then break end
        if M.is_part(inst) and inst ~= main then
            local cn = inst.ClassName or inst.class_name
            if cn == "MeshPart" or cn == "Part" then
                local box = M.read_part_box(inst)
                if box then table.insert(boxes, box) end
            end
        end
    end

    return boxes
end

function M.label_position(entry)
    if not entry or not env.is_valid(entry.inst) then return nil end
    local main = M.find_main_part(entry.inst)
    if main then
        local box = M.read_part_box(main)
        if box then
            return box.x, box.y + box.hy + 0.25, box.z
        end
        local pos = main.Position or main.position
        if pos then
            return vec3(pos, "x"), vec3(pos, "y"), vec3(pos, "z")
        end
    end
    return nil
end

function M.make_entry(model, name, toggle_id, opts)
    opts = opts or {}
    local entry = {
        inst = model,
        name = name,
        toggle_id = toggle_id,
        dynamic = opts.dynamic == true,
    }
    if opts.hydrate ~= false then
        M.hydrate_entry(entry)
    end
    return entry
end

function M.hydrate_entry(entry)
    if not entry or not env.is_valid(entry.inst) then return entry end

    local main = M.find_main_part(entry.inst)
    entry.main_part = main

    if main then
        local box = M.read_part_box(main)
        entry.box = box
        if box then
            entry.lx = box.x
            entry.ly = box.y + box.hy + 0.25
            entry.lz = box.z
        else
            local pos = main.Position or main.position
            if pos then
                entry.lx = vec3(pos, "x")
                entry.ly = vec3(pos, "y")
                entry.lz = vec3(pos, "z")
            end
        end
    end

    return entry
end

function M.refresh_entry_position(entry)
    if not entry or not env.is_valid(entry.inst) then return false end

    if entry.main_part and env.is_valid(entry.main_part) then
        local box = M.read_part_box(entry.main_part)
        if box then
            entry.box = box
            entry.lx = box.x
            entry.ly = box.y + box.hy + 0.25
            entry.lz = box.z
            return true
        end
    end

    M.hydrate_entry(entry)
    return entry.lx ~= nil
end

function M.entry_coords(entry)
    if entry and entry.lx and entry.ly and entry.lz then
        return entry.lx, entry.ly, entry.lz
    end
    return M.label_position(entry)
end

function M.create_folder_scan(folder_keys, name_map, label_map, dynamic)
    return {
        folder_keys = folder_keys,
        name_map = name_map,
        label_map = label_map,
        dynamic = dynamic == true,
        fi = 1,
        ci = 1,
        children = nil,
        folder = nil,
        out = {},
        seen = {},
    }
end

function M.folder_scan_step(state, max_items)
    max_items = max_items or 16
    local processed = 0
    local folders_mod = April.require("game.folders")

    while processed < max_items do
        if state.fi > #state.folder_keys then
            return true, state.out
        end

        if not state.folder or not state.children then
            state.folder = folders_mod.from_key(state.folder_keys[state.fi])
            state.ci = 1
            if env.is_valid(state.folder) then
                state.children = env.safe_call(function() return state.folder:get_children() end) or {}
            else
                state.children = {}
            end
        end

        if state.ci > #state.children then
            state.fi = state.fi + 1
            state.folder = nil
            state.children = nil
            goto continue
        end

        local model = state.children[state.ci]
        state.ci = state.ci + 1
        processed = processed + 1

        if not env.is_valid(model) then goto continue end

        local inst_name = model.Name or model.name
        if not inst_name then goto continue end

        local toggle_id = state.name_map[inst_name]
        if not toggle_id then goto continue end

        local key = tostring(model.Address or model) .. ":" .. toggle_id
        if state.seen[key] then goto continue end
        state.seen[key] = true

        local label = (state.label_map and state.label_map[inst_name]) or inst_name
        table.insert(state.out, M.make_entry(model, label, toggle_id, { dynamic = state.dynamic }))

        ::continue::
    end

    return false, state.out
end

--[[ Scan direct children of folder keys against a name→toggle map. ]]
function M.scan_folders(folder_keys, name_map, label_map, dynamic)
    local folders_mod = April.require("game.folders")
    local out = {}
    local seen = {}

    local function add_entry(model, inst_name)
        local toggle_id = name_map[inst_name]
        if not toggle_id then return end
        local key = tostring(model.Address or model) .. ":" .. toggle_id
        if seen[key] then return end
        seen[key] = true
        local label = (label_map and label_map[inst_name]) or inst_name
        table.insert(out, M.make_entry(model, label, toggle_id, { dynamic = dynamic }))
    end

    for _, folder_key in ipairs(folder_keys or {}) do
        local folder = folders_mod.from_key(folder_key)
        if not env.is_valid(folder) then goto next_folder end

        local children = env.safe_call(function() return folder:get_children() end) or {}
        for _, model in ipairs(children) do
            if not env.is_valid(model) then goto continue end
            local inst_name = model.Name or model.name
            if inst_name then add_entry(model, inst_name) end
            ::continue::
        end
        ::next_folder::
    end

    return out
end

return M

end)()

-- ── features/combat/combat_menu.lua ──
April._mods["features.combat.combat_menu"] = (function()
--[[ Aimbot / silent aim menu helpers ]]

local menu_util = April.require("core.menu_util")
local esp_util = April.require("core.esp_util")

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

function M.bone_from_index(idx)
    local label = M.SILENT_BONES[(idx or 0) + 1] or "Head"
    return M.BONE_MAP[label] or label
end

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

    menu.add_checkbox(T, G, p .. "draw_fov", "Draw FOV Circle", false, menu_util.parent(parent_id, { colorpicker = opts.fov_color or { 1, 1, 1, 1 } }))
    menu.add_checkbox(T, G, p .. "fov_fill", "Fill FOV", false, root)
    menu.add_checkbox(T, G, p .. "target_line", "Target Line", false, menu_util.parent(parent_id, { colorpicker = opts.line_color or { 1, 0.2, 0.2, 1 } }))
end

function M.register_silent_aim(T, G, prefix, parent_id, opts)
    opts = opts or {}
    local p = prefix
    local root = menu_util.parent(parent_id)

    menu.add_combo(T, G, p .. "target_type", "Target Type", { "Crosshair", "Distance" }, 0, root)
    menu.add_combo(T, G, p .. "bone", "Target Hitbox", M.SILENT_BONES, 0, root)

    menu_util.gap(T, G)
    menu_util.label(T, G, "Filters")
    menu.add_checkbox(T, G, p .. "filter_health", "Health Check", true, root)
    menu.add_checkbox(T, G, p .. "filter_visible", "Visible Only", false, root)
    menu.add_checkbox(T, G, p .. "filter_team", "Team Check", true, root)

    menu_util.gap(T, G)
    menu.add_slider_int(T, G, p .. "max_dist", "Max Distance (m)", 50, 2000, 500, root)
    menu.add_slider_int(T, G, p .. "fov", "FOV Radius (px)", 20, 600, opts.fov_default or 150, root)
    menu.add_checkbox(T, G, p .. "sticky", "Sticky Target", false, root)
    menu.add_checkbox(T, G, p .. "bullet_manip", "Bullet Manipulation", false, root)
    menu.add_slider_float(T, G, p .. "manip_dist", "Manip Distance", 0.1, 1, 1, "%.2f", root)
    menu.add_checkbox(T, G, p .. "manip_status", "Manip Status Bar", false, root)
    menu.add_checkbox(T, G, p .. "manip_ring", "Manip Ring Visual", false, root)
    menu.add_checkbox(T, G, p .. "manip_peek_vis", "Manip Peek Visual", true, root)

    menu_util.gap(T, G)
    menu_util.label(T, G, "Visuals")
    menu.add_checkbox(T, G, p .. "draw_fov", "Field Of View Circle", false, menu_util.parent(parent_id, { colorpicker = opts.fov_color or { 0.55, 0.2, 1, 1 } }))
    menu.add_combo(T, G, p .. "fov_style", "FOV Style", { "Outline", "Filled Circle" }, 1, root)
    menu.add_checkbox(T, G, p .. "target_line", "Target Line", false, menu_util.parent(parent_id, { colorpicker = opts.line_color or { 1, 0.25, 0.25, 1 } }))
end

return M

end)()

-- ── features/combat/targeting.lua ──
April._mods["features.combat.targeting"] = (function()
local settings = April.require("core.settings")
local weapons = April.require("game.weapons")
local ballistic = April.require("core.ballistic")
local combat_origin = April.require("game.combat_origin")
local combat_menu = April.require("features.combat.combat_menu")
local math_util = April.require("core.math_util")
local esp_util = April.require("core.esp_util")
local player_state = April.require("game.player_state")

local M = {}

M.BONES = esp_util.AIM_BONES

local function w2s(x, y, z)
    return esp_util.w2s(x, y, z)
end

local function passes_visibility(target, aim, origin)
    if not raycast then return true end
    if not origin or not aim then return true end

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

function M.target_priority_crosshair(prefix)
    local idx = settings.num(prefix .. "target_type", 0)
    return idx == 0
end

function M.passes_filters(target, prefix, aim, origin)
    if not target then return false end

    if settings.bool(prefix .. "filter_health", true) then
        if not player_state.passes_health_check(target) then return false end
    end

    if settings.bool(prefix .. "filter_team", true) then
        if not player_state.passes_team_check(target) then return false end
    end

    if settings.bool(prefix .. "filter_visible", false) then
        if not passes_visibility(target, aim, origin) then return false end
    end

    return true
end

function M.within_max_distance(target, origin, prefix)
    local max_d = settings.num(prefix .. "max_dist", 500)
    if max_d <= 0 or not origin then return true end

    local dist = target.distance_to and target:distance_to(origin) or nil
    if not dist and target.position and origin then
        local pos = target.position
        dist = math_util.distance3((pos.x or 0) - origin.x, (pos.y or 0) - origin.y, (pos.z or 0) - origin.z)
    end

    return dist == nil or dist <= max_d
end

function M.bone_world(target, bone)
    if not target or not target.is_alive then return nil end
    if bone == "Closest" then return nil end

    if bone == "Head" and target.head_position then
        local pos = target.head_position
        return { x = pos.x, y = pos.y, z = pos.z }
    end

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

    if target.position then
        local pos = target.position
        if bone == "Head" then
            return nil
        end
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
        local env = April.require("core.env")
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
    return M.bone_world(target, bone)
end

function M.get_aim_point(target, prefix, bone, origin, cx, cy, use_prediction)
    bone = bone or M.bone_name(prefix)
    local base = M.resolve_bone_world(target, bone, cx, cy)
    if not base then return nil end

    if use_prediction == false then
        return base
    end

    origin = origin or combat_origin.get_fire_origin()
    if not origin then return base end

    return M.predict_point(origin, base, target, weapons.cached_held_ranged())
end

function M.is_target_valid(target, prefix, cx, cy, fov_px)
    if not player_state.is_combat_target(target) then return false end

    local origin = combat_origin.get_camera_origin() or combat_origin.get_fire_origin()
    if not M.within_max_distance(target, origin, prefix) then return false end

    local bone = M.bone_name(prefix)
    local base = M.resolve_bone_world(target, bone == "Closest" and "Head" or bone, cx, cy)
    if not base then return false end

    if not M.passes_filters(target, prefix, base, origin) then return false end

    local sx, sy, on_screen = w2s(base.x, base.y, base.z)
    if not on_screen then return false end

    local fov_dist = math_util.screen_fov_dist(sx, sy, cx, cy)
    return fov_dist <= fov_px
end

function M.find_target(cx, cy, fov_px, prefix)
    if not entity or not entity.get_players then return nil end

    local bone = M.bone_name(prefix)
    local screen_bone = bone == "Closest" and "Head" or bone
    local use_fov = M.target_priority_crosshair(prefix)
    local best, best_score = nil, use_fov and fov_px or math.huge
    local origin = combat_origin.get_camera_origin() or combat_origin.get_fire_origin()
    local filter_visible = settings.bool(prefix .. "filter_visible", false)

    for _, p in ipairs(entity.get_players()) do
        if not player_state.is_combat_target(p) then goto continue end
        if not M.within_max_distance(p, origin, prefix) then goto continue end

        local base = M.bone_world(p, screen_bone)
        if not base then goto continue end

        if filter_visible and not passes_visibility(p, base, origin) then goto continue end
        if not M.passes_filters(p, prefix, base, origin) then goto continue end

        local sx, sy, on_screen = w2s(base.x, base.y, base.z)
        if not on_screen then goto continue end

        local fov_dist = math_util.screen_fov_dist(sx, sy, cx, cy)
        if fov_dist > fov_px then goto continue end

        local score = use_fov and fov_dist or (p.distance_to and origin and p:distance_to(origin) or fov_dist)
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

-- ── features/combat/silent_resolve.lua ──
April._mods["features.combat.silent_resolve"] = (function()
--[[ Resolve silent hook — camera ray, or peek eye when bullet manip needs a corner ray. ]]

local settings = April.require("core.settings")
local combat_origin = April.require("game.combat_origin")
local silent_ray = April.require("core.silent_ray")
local manip_math = April.require("core.manip_math")
local targeting = April.require("features.combat.targeting")

local M = {}

local OFF_INFO = { state = "off", peek = nil, radius = 1 }

function M.resolve_track(target, prefix, cx, cy)
    if not target then return nil, nil, OFF_INFO end

    local camera = silent_ray.get_camera_origin()
    if not camera then return nil, nil, OFF_INFO end

    local aim = targeting.resolve_bone_world(target, targeting.bone_name(prefix), cx, cy)
    if not aim then return nil, nil, OFF_INFO end

    local track_origin = camera
    local manip_info = OFF_INFO

    if settings.bool(prefix .. "bullet_manip", false) then
        local body = combat_origin.get_server_origin()
        local max_r = manip_math.clamp_radius(settings.num(prefix .. "manip_dist", 1))

        if body then
            local ev = manip_math.evaluate_manipulation(body, aim, { max_radius = max_r })
            manip_info = {
                state = ev.state,
                peek = ev.peek,
                radius = ev.radius or max_r,
            }
            if ev.state == "ready" and ev.peek then
                track_origin = manip_math.peek_track_origin(ev.peek) or camera
            end
        else
            manip_info = { state = "blocked", peek = nil, radius = max_r }
        end
    end

    return track_origin, aim, manip_info
end

return M

end)()

-- ── features/combat/aimbot.lua ──
April._mods["features.combat.aimbot"] = (function()
local settings = April.require("core.settings")
local targeting = April.require("features.combat.targeting")
local player_state = April.require("game.player_state")
local weapons = April.require("game.weapons")
local combat_origin = April.require("game.combat_origin")
local draw_util = April.require("core.draw_util")
local menu_util = April.require("core.menu_util")
local combat_menu = April.require("features.combat.combat_menu")
local silent_ray = April.require("core.silent_ray")
local silent_resolve = April.require("features.combat.silent_resolve")
local manip_math = April.require("core.manip_math")
local desync_vis = April.require("core.desync_vis")
local theme = April.require("core.ui_theme")

local M = {}
local locked_target = nil
local PREFIX = "april_silent_"
local P_MASTER = "april_silent_aim"
local SHOOT_VK = 0x01
local TARGET_SCAN_MS = 33

local cached_track = { origin = nil, aim = nil, manip = { state = "off" }, tracking = false }
local last_target_scan = 0

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

local MANIP_LABELS = {
    direct = "MANIP: CLEAR SHOT",
    ready = "MANIP: RAY READY",
    blocked = "MANIP: NO PEEK",
    off = "",
}

local function draw_manip_status(cx, cy, fov, info)
    if not info or info.state == "off" then return end
    if not settings.bool(PREFIX .. "manip_status", false) then return end

    local ready = info.state == "ready" or info.state == "direct"
    local text = MANIP_LABELS[info.state] or "MANIP: ..."
    local col = ready and theme.GREEN or theme.RED

    local tw = theme.text_w(text, 11)
    local pad_x, pad_y = 10, 4
    local w = tw + pad_x * 2
    local h = 18
    local x = cx - w * 0.5
    local y = cy + fov + 10

    theme.draw_panel(x, y, w, h, {
        bg = theme.alpha(theme.PANEL_DEEP, 0.9),
        border = theme.alpha(ready and theme.GREEN or theme.RED, 0.45),
        accent = theme.alpha(col, 0.85),
        accent_w = 2,
    })
    draw_util.text_centered(cx, y + pad_y, text, col, 11)
end

local function draw_manip_ring(info)
    if not settings.bool(PREFIX .. "bullet_manip", false) then return end
    if not settings.bool(PREFIX .. "manip_ring", false) then return end

    local body = combat_origin.get_server_origin()
    if not body then return end

    local radius = manip_math.clamp_radius(settings.num(PREFIX .. "manip_dist", 1))
    local ring_y = manip_math.ring_y(body)

    local ring_col = { 0.15, 0.95, 0.55, 0.55 }
    if info and info.state == "blocked" then
        ring_col = { 0.95, 0.25, 0.25, 0.45 }
    elseif info and info.state == "ready" then
        ring_col = { 0.2, 0.95, 0.45, 0.7 }
    end

    desync_vis.draw_sphere_ring(body.x, ring_y, body.z, radius, ring_col, 1.5)
end

local function draw_manip_peek(info)
    if not settings.bool(PREFIX .. "manip_peek_vis", true) then return end
    if not info or not info.peek then return end
    if info.state ~= "ready" then return end

    local body = combat_origin.get_server_origin()
    if not body then return end

    local peek = info.peek
    local col_peek = { 1, 0.85, 0.2, 0.95 }
    local show_labels = settings.bool(PREFIX .. "manip_status", false)
    local eye_y = peek.y + manip_math.eye_offset_y()

    desync_vis.draw_cross(peek.x, eye_y, peek.z, 0.85, col_peek, 2)
    if show_labels then
        desync_vis.draw_labeled(peek.x, eye_y, peek.z, "PEEK", col_peek, 11)
    end
    desync_vis.draw_link(body, peek, { col_peek[1], col_peek[2], col_peek[3], 0.3 }, 1)

    local ray_from = manip_math.peek_track_origin(peek)
    if ray_from and cached_track.aim then
        desync_vis.draw_link(ray_from, cached_track.aim, { 1, 0.45, 0.2, 0.55 }, 1.5)
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.SILENT_AIM)

    menu_util.register_keybind(T, G.SILENT_AIM, P_MASTER, "Enable Silent Aim", false)

    combat_menu.register_silent_aim(T, G.SILENT_AIM, PREFIX, P_MASTER, {
        fov_default = 150,
        fov_color = theme.CYAN,
        line_color = theme.RED,
    })

    menu_util.bind_children(P_MASTER, {
        PREFIX .. "target_type", PREFIX .. "bone",
        PREFIX .. "filter_health", PREFIX .. "filter_visible", PREFIX .. "filter_team",
        PREFIX .. "max_dist", PREFIX .. "fov", PREFIX .. "sticky",
        PREFIX .. "draw_fov", PREFIX .. "fov_style", PREFIX .. "target_line",
        PREFIX .. "bullet_manip", PREFIX .. "manip_dist", PREFIX .. "manip_status", PREFIX .. "manip_ring", PREFIX .. "manip_peek_vis",
    })

    menu_util.bind_children(PREFIX .. "bullet_manip", {
        PREFIX .. "manip_dist", PREFIX .. "manip_status", PREFIX .. "manip_ring", PREFIX .. "manip_peek_vis",
    })
end

local function active()
    return settings.enabled(P_MASTER) and silent_ray.available()
end

local function update_target(cx, cy, fov)
    local sticky = settings.bool(PREFIX .. "sticky", false)
    local now = tick_ms()

    if sticky and locked_target then
        if not targeting.is_target_valid(locked_target, PREFIX, cx, cy, fov) then
            locked_target = nil
        end
    end

    if locked_target and sticky then
        return
    end

    if now - last_target_scan < TARGET_SCAN_MS then
        return
    end
    last_target_scan = now
    locked_target = targeting.find_target(cx, cy, fov, PREFIX)
end

function M.update(_dt)
    cached_track.origin = nil
    cached_track.aim = nil
    cached_track.manip = { state = "off" }
    cached_track.tracking = false

    if not active() then
        locked_target = nil
        silent_ray.stop()
        return
    end

    silent_ray.ensure_hook()

    if not holding_weapon() then
        silent_ray.stop()
        return
    end

    combat_origin.sync_weapon(weapons.cached_held_ranged() or weapons.get_held_ranged_weapon_name())

    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num(PREFIX .. "fov", 150)

    update_target(cx, cy, fov)

    if not locked_target or not player_state.is_combat_target(locked_target) then
        silent_ray.stop()
        return
    end

    local origin, aim, manip_info = silent_resolve.resolve_track(locked_target, PREFIX, cx, cy)
    if not aim or not origin then
        silent_ray.stop()
        return
    end

    cached_track.origin = origin
    cached_track.aim = aim
    cached_track.manip = manip_info or { state = "off" }
    cached_track.tracking = silent_ray.track(origin, aim, SHOOT_VK) == true
end

function M.get_target()
    return locked_target
end

function M.draw()
    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num(PREFIX .. "fov", 150)

    if active() and settings.bool(PREFIX .. "draw_fov", false) then
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

    if active() and settings.bool(PREFIX .. "bullet_manip", false) then
        draw_manip_ring(cached_track.manip)
        draw_manip_status(cx, cy, fov, cached_track.manip)
        draw_manip_peek(cached_track.manip)
    end

    if active() and locked_target and settings.bool(PREFIX .. "target_line", false) then
        local aim = cached_track.aim
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

-- ── features/combat/perfect_farm.lua ──
April._mods["features.combat.perfect_farm"] = (function()
--[[
    Farm helper — tier-3 weak spot hits on NodeSpark / TreeX.
    Silent mode redirects engine melee raycasts via track_silent_target (LMB).
    Camera mode uses camera.look_at to keep crosshair on the spark.
]]

local settings = April.require("core.settings")
local env = April.require("core.env")
local debug = April.require("core.debug")
local folders = April.require("game.folders")
local farm_tools = April.require("game.farm_tools")
local math_util = April.require("core.math_util")
local menu_util = April.require("core.menu_util")
local silent_ray = April.require("core.silent_ray")

local M = {}

local P = "april_farm_helper"
local P_RADIUS = "april_farm_radius"
local P_SMOOTH = "april_farm_smooth"
local P_SILENT = "april_farm_silent"
local SHOOT_VK = 0x01

local spark_parts = {}
local next_scan_ms = 0
local SCAN_MS = 350
M._tracking = false

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function find_child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        return parent:find_first_child(name) or parent:FindFirstChild(name)
    end)
end

local function part_position(part)
    if not part or not env.is_valid(part) then return nil end
    local pos = part.Position or part.position
    if not pos or pos.x == nil then return nil end
    return pos
end

local function vec3_position(value)
    if not value then return nil end
    if value.x ~= nil then
        return { x = value.x, y = value.y, z = value.z }
    end
    if value[1] then
        return { x = value[1], y = value[2], z = value[3] }
    end
    return nil
end

local function camera_controller()
    local lp = env.get_local_player()
    local char = lp and lp.character
    if not char or not env.is_valid(char) then return nil end
    return find_child(char, "CameraController")
end

local function viewmodel_origin()
    local cc = camera_controller()
    if cc and env.is_valid(cc) then
        local cf = env.safe_call(function() return cc:GetAttribute("ViewmodelCFrame") end)
        local pos = vec3_position(cf and (cf.Position or cf.position))
        if pos then return pos end
    end

    if camera and camera.get_position then
        local cam = camera.get_position()
        return vec3_position(cam)
    end

    return nil
end

local function spark_part_from_model(model)
    if not env.is_valid(model) then return nil end

    local spark = find_child(model, "NodeSpark") or find_child(model, "TreeX")
    if not spark or not env.is_valid(spark) then return nil end

    local main = env.safe_call(function() return spark.PrimaryPart end)
    if main and env.is_valid(main) then return main end

    main = find_child(spark, "Main")
    if main and env.is_valid(main) then return main end

    return nil
end

local function scan_folder(folder, out)
    if not env.is_valid(folder) then return end
    for _, model in ipairs(folders.scan_children(folder, "Model", 250)) do
        local part = spark_part_from_model(model)
        if part then
            table.insert(out, part)
        end
    end
end

local function refresh_sparks()
    local now = tick_ms()
    if now < next_scan_ms then return end
    next_scan_ms = now + SCAN_MS

    local out = {}
    scan_folder(folders.from_key("nodes"), out)
    scan_folder(folders.from_key("plants"), out)
    scan_folder(folders.get_folder("Trees"), out)
    spark_parts = out
end

local function player_position(lp)
    if not lp then return nil end

    if lp.position and lp.position.x ~= nil then
        return lp.position
    end

    local char = lp.character
    if not char and game and game.local_player then
        char = game.local_player.character
    end
    if not char then return nil end

    local root = find_child(char, "HumanoidRootPart")
    return part_position(root)
end

local function nearest_spark(player_pos, radius)
    local best_part = nil
    local best_dist = radius

    for i = 1, #spark_parts do
        local part = spark_parts[i]
        if env.is_valid(part) then
            local pos = part_position(part)
            if pos then
                local dx = pos.x - player_pos.x
                local dy = pos.y - player_pos.y
                local dz = pos.z - player_pos.z
                local dist = math_util.distance3(dx, dy, dz)
                if dist < best_dist then
                    best_dist = dist
                    best_part = part
                end
            end
        end
    end

    return best_part
end

local function silent_mode()
    return settings.bool(P_SILENT, true) and silent_ray.available()
end

local function stop_silent()
    if not M._tracking then return end
    silent_ray.stop()
    M._tracking = false
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.register_keybind(T, G.MISC, P, "Farm Helper", false)
    menu.add_slider_int(T, G.MISC, P_RADIUS, "Farm Range (studs)", 1, 15, 5, root)
    menu.add_checkbox(T, G.MISC, P_SILENT, "Silent Farm", true, root)
    menu.add_slider_int(T, G.MISC, P_SMOOTH, "Camera Smoothness", 1, 30, 8, root)
    menu_util.bind_children(P, { P_RADIUS, P_SILENT, P_SMOOTH })
end

function M.update(_dt)
    if not settings.enabled(P) then
        stop_silent()
        return
    end

    farm_tools.load()
    if not farm_tools.holding_farm_tool() then
        stop_silent()
        return
    end

    local lp = env.get_local_player()
    local pos = player_position(lp)
    if not pos then
        stop_silent()
        return
    end

    refresh_sparks()

    local radius = settings.num(P_RADIUS, 5)
    if radius <= 0 then
        stop_silent()
        return
    end

    local target = nearest_spark(pos, radius)
    if not target then
        stop_silent()
        return
    end

    local aim = part_position(target)
    if not aim then
        stop_silent()
        return
    end

    if silent_mode() then
        local origin = viewmodel_origin()
        if not origin then
            stop_silent()
            return
        end

        if silent_ray.track(origin, aim, SHOOT_VK) then
            M._tracking = true
        else
            debug.error_once("farm:silent", "Silent farm hook unavailable — toggle Silent Farm off for camera aim")
            stop_silent()
        end
        return
    end

    stop_silent()

    if not camera or not camera.look_at then return end

    local smooth = math.max(1, settings.num(P_SMOOTH, 8))
    pcall(camera.look_at, aim.x, aim.y, aim.z, smooth)
end

return M

end)()

-- ── features/combat/gun_mods.lua ──
April._mods["features.combat.gun_mods"] = (function()
local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local profiles = April.require("game.gun_mod_profiles")
local store = April.require("game.weapon_profile_store")
local gc = April.require("game.gc_weapon_mods")
local env = April.require("core.env")
local notify = April.require("core.notify")

local M = {}
local P = "april_gunmods_enabled"
local HELD_ID = "april_gm_held_weapon"
local REJOIN_GC_DELAY_MS = 20000
local RETRY_MS = 750
local RETRY_MAX_MS = 30000

M._apply_dirty = false
M._force_apply = false
M._defer_until = 0
M._retry_until = 0
M._session_id = nil
M._was_in_match = false
M._gc_redo_at = 0
M._notify_next = false
M._last_held_apply = nil
M._held_display = "—"
M._combo_registered = false
M._combo_ctx = nil
M._had_applied_mods = false

local function tick_ms()
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

local function schedule_apply(delay_ms)
    M._apply_dirty = true
    M._force_apply = true
    local now = tick_ms()
    local until_ms = now + (delay_ms or 400)
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
end

local function schedule_session_gc_refresh()
    if not settings.enabled(P) then return end
    M._apply_dirty = true
    M._force_apply = true
    M._gc_redo_at = tick_ms() + REJOIN_GC_DELAY_MS
    M._retry_until = tick_ms() + RETRY_MAX_MS
end

local function weapon_names()
    return profiles.weapon_combo_names()
end

local function selected_weapon_key()
    return profiles.selected_editor_weapon_key()
end

local function sync_held_display(held)
    held = held or profiles.held_weapon_name()
    local text = held or "—"
    if held then
        if profiles.is_global_mode() and store.has_saved(profiles.GLOBAL_PROFILE_KEY) then
            text = held .. " (global profile)"
        elseif store.has_saved(held) then
            text = held .. " (saved)"
        else
            text = held .. " (no profile)"
        end
    end
    if text ~= M._held_display then
        M._held_display = text
        if menu and menu.set then
            pcall(menu.set, HELD_ID, text)
        end
    end
end

local function load_selected_editor()
    local key = selected_weapon_key()
    if key then
        store.load_editor_weapon(key)
    end
end

local function ensure_weapon_combo()
    if M._combo_registered or not M._combo_ctx then return end

    local weapons = April.require("game.weapons")
    weapons.load()
    local names = weapon_names()
    if #names == 0 then return end

    local ctx = M._combo_ctx
    menu.add_combo(ctx.T, ctx.G, "april_gm_weapon_select", "Edit Weapon", names, 0, ctx.root)
    M._combo_registered = true
    M._combo_weapon_count = #names
    load_selected_editor()
end

function M.on_session_changed()
    schedule_session_gc_refresh()
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.GUN_MODS)
    local root = menu_util.parent(P)

    store.load()

    menu_util.register_keybind(T, G.GUN_MODS, P, "Enable Gun Mods", false)

    menu_util.gap(T, G.GUN_MODS)
    menu_util.input(T, G.GUN_MODS, HELD_ID, "Held Weapon", "—")

    menu.add_combo(T, G.GUN_MODS, profiles.MODE_ID, "Apply Mode", profiles.MODES, 0, root)

    M._combo_ctx = { T = T, G = G.GUN_MODS, root = root }
    ensure_weapon_combo()

    menu_util.gap(T, G.GUN_MODS)
    menu.add_checkbox(T, G.GUN_MODS, "april_gm_recoil", "No Recoil", false, root)
    menu.add_slider_int(T, G.GUN_MODS, "april_gm_recoil_pct", "Recoil Reduction %", 0, 100, 100, root)

    menu.add_checkbox(T, G.GUN_MODS, "april_gm_spread", "No Spread", false, root)
    menu.add_slider_int(T, G.GUN_MODS, "april_gm_spread_pct", "Spread Reduction %", 0, 100, 100, root)

    menu.add_checkbox(T, G.GUN_MODS, "april_gm_sway", "No Sway", false, root)

    menu.add_checkbox(T, G.GUN_MODS, "april_gm_fire_rate", "Fire Rate", false, root)
    menu.add_slider_float(T, G.GUN_MODS, "april_gm_fire_rate_mult", "Fire Rate Multiplier", 1.0, 3.0, 1.5, "%.2f", root)

    menu.add_checkbox(T, G.GUN_MODS, "april_gm_speed", "Bullet Speed", false, root)
    menu.add_slider_int(T, G.GUN_MODS, "april_gm_speed_mult", "Speed Mult (100 = instant)", 0, 100, 100, root)

    menu.add_checkbox(T, G.GUN_MODS, "april_gm_range", "Range", false, root)
    menu.add_slider_int(T, G.GUN_MODS, "april_gm_range_mult", "Range Mult", 1, 20, 10, root)

    menu_util.gap(T, G.GUN_MODS)
    menu_util.button(T, G.GUN_MODS, "april_gm_save", "Save Profile", function()
        local key = selected_weapon_key()
        if not key then
            notify.warning("Select a weapon to save", 3500)
            return
        end
        store.save_editor_weapon(key)
        sync_held_display()
        local label = key == profiles.GLOBAL_PROFILE_KEY and "Global" or key
        notify.success("Saved profile: " .. label, 3500)
    end, P)

    menu_util.button(T, G.GUN_MODS, "april_gm_clear", "Clear Saved Profile", function()
        local key = selected_weapon_key()
        if not key then
            notify.warning("Select a weapon to clear", 3500)
            return
        end
        if not store.remove(key) then
            local label = key == profiles.GLOBAL_PROFILE_KEY and "Global" or key
            notify.info("No saved profile for " .. label, 3000)
            return
        end
        store.load_editor_weapon(key)
        sync_held_display()
        local label = key == profiles.GLOBAL_PROFILE_KEY and "Global" or key
        notify.info("Cleared profile: " .. label, 3500)
    end, P)

    menu_util.bind_children(P, {
        HELD_ID, profiles.MODE_ID, "april_gm_weapon_select",
        "april_gm_recoil", "april_gm_recoil_pct",
        "april_gm_spread", "april_gm_spread_pct",
        "april_gm_sway",
        "april_gm_fire_rate", "april_gm_fire_rate_mult",
        "april_gm_speed", "april_gm_speed_mult",
        "april_gm_range", "april_gm_range_mult",
        "april_gm_save", "april_gm_clear",
    })

    settings.on_change("april_gm_weapon_select", function()
        load_selected_editor()
    end)

    settings.on_change(profiles.MODE_ID, function()
        sync_held_display()
    end)

    settings.on_change(P, function()
        if settings.enabled(P) then
            M._notify_next = true
            schedule_apply(500)
        else
            clear_apply_state()
            M.reset_mods()
        end
    end)

    load_selected_editor()
    sync_held_display()
end

function M.reset_mods()
    if not gc.available() then
        notify.info("Gun mods disabled", 3000)
        return true
    end

    local mods = profiles.build_reset_mods()
    local ok, count, msg = gc.apply_weapon(mods)
    if ok then
        M._had_applied_mods = false
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
    if not held then
        if M._had_applied_mods then
            gc.apply_weapon(profiles.build_reset_mods())
            M._had_applied_mods = false
        end
        M._apply_dirty = false
        M._force_apply = false
        return false
    end

    local mods = profiles.build_mods_for_apply(held)
    if not mods or not profiles.should_apply_for_held(held) then
        if M._had_applied_mods then
            gc.apply_weapon(profiles.build_reset_mods())
            M._had_applied_mods = false
        end
        M._apply_dirty = false
        M._force_apply = false
        return false
    end

    if not M._force_apply and not M._apply_dirty then
        return true
    end

    local ok, count, msg = gc.apply_weapon(mods)
    if ok then
        M._had_applied_mods = true
        M._apply_dirty = false
        M._force_apply = false
        M._retry_until = 0
        if M._notify_next or not silent then
            M._notify_next = false
            local suffix = profiles.is_global_mode() and " (global)" or (" (" .. held .. ")")
            notify.success("Gun mods applied" .. suffix .. ": " .. tostring(msg or (count .. " nodes")), 3500)
        end
    else
        M._apply_dirty = true
        M._force_apply = true
        M._defer_until = tick_ms() + RETRY_MS
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
    sync_held_display(held)
    if settings.enabled(P) then
        schedule_apply(150)
    end
end

function M.update(_dt)
    M.tick_session()

    local held = profiles.held_weapon_name()
    if held ~= M._last_held_apply then
        M.on_weapon_equip_changed(held)
    end

    if not settings.enabled(P) then return end

    local now = tick_ms()

    if M._gc_redo_at > 0 and now >= M._gc_redo_at then
        M._gc_redo_at = 0
        if in_match() then
            gc.refresh_cache()
            M._apply_dirty = true
            M._force_apply = true
            M._defer_until = now
            M._retry_until = now + RETRY_MAX_MS
            notify.info("Re-applying gun mods after session change…", 2500)
        end
    end

    if not M._apply_dirty then return end
    if now < M._defer_until then return end
    if M._retry_until > 0 and now > M._retry_until then
        M._apply_dirty = false
        M._force_apply = false
        notify.warning("Gun mods: could not patch — equip gun in match and switch weapons", 5000)
        return
    end

    M.try_apply(true)
end

function M.on_weapon_changed(name)
    M.on_weapon_equip_changed(name)
end

function M.on_modules_ready()
    store.load()
    ensure_weapon_combo()
    load_selected_editor()
    sync_held_display()
end

function M.draw() end

return M

end)()

-- ── features/visuals/player_esp.lua ──
April._mods["features.visuals.player_esp"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local esp_util = April.require("core.esp_util")
local player_state = April.require("game.player_state")
local menu_util = April.require("core.menu_util")
local image_cache = April.require("core.image_cache")
local asset_urls = April.require("game.asset_urls")

local M = {}
local P = "april_tung_esp_enabled"
local TUNG_KEY = "tung"

local function draw_tung_box(x, y, w, h)
    w = math.max(12, math.floor(w or 12))
    h = math.max(12, math.floor(h or 12))
    image_cache.begin_load(TUNG_KEY)
    return image_cache.draw_fit(TUNG_KEY, x, y, w, h)
end

function M.register_menu()
end

function M.scan()
    cache.players = {}
    if not entity or not entity.get_players then return end
    for _, p in ipairs(entity.get_players()) do
        if p.is_valid and not p.is_local and player_state.is_combat_target(p) then
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

function M.init()
    image_cache.ensure(TUNG_KEY, asset_urls.tung_png())
end

function M.update(_dt) end

function M.draw()
    if not settings.enabled(P) then return end

    local max_dist = settings.num("april_tung_esp_max_dist", 1000)
    local me = entity and entity.get_local_player and entity.get_local_player()

    for _, p in ipairs(M.get_players()) do
        if p.is_local or not player_state.is_combat_target(p) then goto continue end

        if me and me.position and p.position then
            local dx = p.position.x - me.position.x
            local dy = p.position.y - me.position.y
            local dz = p.position.z - me.position.z
            local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
            if dist > max_dist then goto continue end
        end

        local b = p:get_bounds()
        if b and b.valid and b.w > 0 and b.h > 0 then
            draw_tung_box(b.x, b.y, b.w, b.h)
        end

        ::continue::
    end
end

return M

end)()

-- ── features/visuals/target_overlay.lua ──
April._mods["features.visuals.target_overlay"] = (function()
local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local menu_util = April.require("core.menu_util")
local image_cache = April.require("core.image_cache")
local items = April.require("game.items")
local player_gear = April.require("game.player_gear")
local player_state = April.require("game.player_state")
local math_util = April.require("core.math_util")
local text_util = April.require("core.text_util")

local M = {}

local P = "april_target_overlay"
local GEAR_SLOTS = 7
local GEAR_TTL = 500
local TARGET_POLL_MS = 120
local MAX_ATTACHMENTS = 5

local gear_cache = {}
local last_poll_ms = 0

M._target = nil
M._layout = nil

local SLOT_BG = { 0.14, 0.14, 0.16, 0.72 }
local HELD_BG = { 0.52, 0.12, 0.14, 0.9 }
local HELD_EDGE = { 0.95, 0.28, 0.32, 0.85 }
local ATT_BG = { 0.16, 0.16, 0.18, 0.82 }
local ATT_EDGE = { 0.45, 0.45, 0.48, 0.5 }
local EMPTY_BG = { 0.08, 0.08, 0.1, 0.55 }
local EMPTY_EDGE = { 1, 1, 1, 0.12 }
local ROUND = 5

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

local function get_gear(player)
    if not player then return nil end
    local uid = player.user_id or player.name or "?"
    local now = tick_ms()
    local cached = gear_cache[uid]
    if cached and (now - cached.t) < GEAR_TTL then
        return cached.data
    end
    local data = player_gear.scan_player(player)
    gear_cache[uid] = { t = now, data = data }
    return data
end

local function crosshair_center()
    local sw, sh = draw_util.screen_size()
    return sw * 0.5, sh * 0.5
end

local function find_crosshair_target(fov_px)
    if not entity or not entity.get_players then return nil end

    local cx, cy = crosshair_center()
    local best, best_dist = nil, fov_px

    for _, p in ipairs(entity.get_players()) do
        if not player_state.is_combat_target(p) then goto continue end

        local pos = p.head_position or p.position
        if not pos then goto continue end

        local px = pos.x or pos[1]
        local py = pos.y or pos[2]
        local pz = pos.z or pos[3]
        if not px then goto continue end

        local sx, sy, vis = esp_util.w2s(px, py, pz)
        if not vis then goto continue end

        local dist = math_util.screen_fov_dist(sx, sy, cx, cy)
        if dist <= fov_px and dist < best_dist then
            best_dist = dist
            best = p
        end

        ::continue::
    end

    return best
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
    if type(held) == "table" then return held end
    return { name = held }
end

local function draw_slot(x, y, size, key, piece, style)
    local pad = 3
    local bg = SLOT_BG
    local edge = nil

    if style == "held" then
        bg = HELD_BG
        edge = HELD_EDGE
    elseif style == "attachment" then
        bg = ATT_BG
        edge = ATT_EDGE
    elseif style == "empty" then
        bg = EMPTY_BG
        edge = EMPTY_EDGE
    end

    draw.rect_filled(x, y, size, size, bg, ROUND)
    if edge and draw.rect then
        draw.rect(x, y, size, size, edge, ROUND, 1.5)
    elseif style == "empty" and draw.rect then
        draw.rect(x, y, size, size, EMPTY_EDGE, ROUND, 1)
    end

    if not piece then return end

    if key and image_cache.draw_fit(key, x + pad, y + pad, size - pad * 2, size - pad * 2) then
        return
    end

    local label = "?"
    if type(piece) == "table" and piece.name and piece.name ~= "" then
        label = piece.name:sub(1, 1):upper()
    end

    local fs = math.max(10, math.floor(size * 0.34))
    local tw = select(1, draw.get_text_size(label, fs))
    draw.text(
        x + size * 0.5 - tw * 0.5,
        y + size * 0.5 - fs * 0.45,
        label,
        { 0.55, 0.55, 0.58, 0.85 },
        fs
    )
end

local function same_target(a, b)
    if a == b then return true end
    if not a or not b then return false end
    local aid = a.user_id or a.name
    local bid = b.user_id or b.name
    return aid and bid and aid == bid
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)

    menu.add_checkbox(T, G.VISUALS, P, "Target Gear", false)
    menu.add_slider_int(T, G.VISUALS, P .. "_fov", "Target FOV", 40, 400, 150, menu_util.parent(P))
    menu.add_slider_int(T, G.VISUALS, P .. "_gear_size", "Gear Icon Size", 32, 64, 48, menu_util.parent(P))
    menu.add_slider_int(T, G.VISUALS, P .. "_top", "Top Offset", 48, 160, 88, menu_util.parent(P))

    menu_util.bind_master(P, { P .. "_fov", P .. "_gear_size", P .. "_top" })
end

function M.refresh_target()
    if not settings.enabled(P) then
        M._target = nil
        M._layout = nil
        return
    end

    local fov = settings.num(P .. "_fov", 150)
    local gear_sz = settings.num(P .. "_gear_size", 48)
    local target = find_crosshair_target(fov)

    if not target or not player_state.is_combat_target(target) then
        M._target = nil
        M._layout = nil
        return
    end

    local target_changed = not same_target(M._target, target)
    local uid = target.user_id or target.name or "?"
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

    local target = M._target
    local layout = M._layout
    if not target or not layout then return end

    local sw, _ = draw_util.screen_size()
    local top = settings.num(P .. "_top", 88)
    local cx = sw * 0.5

    local name = text_util.sanitize(target.display_name or target.name or "Unknown")
    local nw = select(1, draw.get_text_size(name, layout.name_fs))
    draw.text(cx - nw * 0.5, top, name, { 1, 1, 1, 1 }, layout.name_fs)

    local y = top + layout.name_fs + 6
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
        draw.text(cx - hw * 0.5, y + layout.gear_sz + 6, hint, { 0.55, 0.55, 0.58, 0.85 }, 10)
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
    menu.add_checkbox(T, G.VISUALS, P, "Custom Crosshair", false)
    menu.add_combo(T, G.VISUALS, "april_crosshair_type", "Crosshair Type", { "Cross", "Circle", "Dot", "T-Shape" }, 0, { parent = P })
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_size", "Crosshair Size", 1, 50, 10, { parent = P })
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_gap", "Crosshair Gap", 0, 20, 5, { parent = P })
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_thickness", "Crosshair Thickness", 1, 10, 2, { parent = P })
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_color", "Crosshair Color", true, { parent = P, colorpicker = { 0, 1, 0, 1 } })
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_dot", "Center Dot", false, { parent = P, colorpicker = { 1, 1, 1, 1 } })
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_outline", "Outline", true, { parent = P, colorpicker = { 0, 0, 0, 1 } })
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_rainbow", "Rainbow Crosshair", false, { parent = P })
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_rainbow_speed", "Rainbow Speed", 1, 100, 10, { parent = P })

    menu_util.bind_children(P, {
        "april_crosshair_type", "april_crosshair_size", "april_crosshair_gap", "april_crosshair_thickness",
        "april_crosshair_color", "april_crosshair_dot", "april_crosshair_outline",
        "april_crosshair_rainbow", "april_crosshair_rainbow_speed",
    })
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
    if not settings.enabled(P) then return end
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

-- ── features/visuals/brainrot_esp.lua ──
April._mods["features.visuals.brainrot_esp"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local env = April.require("core.env")
local esp_util = April.require("core.esp_util")
local esp_scan = April.require("game.esp_scan")
local menu_util = April.require("core.menu_util")
local image_cache = April.require("core.image_cache")
local catalog = April.require("game.brainrot_catalog")

local M = {}

local P = "april_brainrot_enabled"
local P_STYLE = "april_brainrot_style"
local P_SIZE = "april_brainrot_size"

local _active_key = nil

local function labels()
    return catalog.combo_labels()
end

local function selected_entry()
    local idx = settings.combo_index(P_STYLE, labels(), 0)
    return catalog.entry_at_index(idx)
end

local function active_key()
    local entry = selected_entry()
    if not entry then return nil end
    return catalog.image_key(entry.file)
end

local function ensure_image(key, file)
    if not key or not file then return end
    image_cache.ensure(key, catalog.url(file))
end

local function draw_bounds(bounds)
    if not bounds or not bounds.valid then return false end

    local key = active_key()
    if not key then return false end

    local min_sz = settings.num(P_SIZE, 48)
    local w = math.max(min_sz, math.floor(bounds.w or min_sz))
    local h = math.max(min_sz, math.floor(bounds.h or min_sz))

    image_cache.begin_load(key)
    return image_cache.draw_fit(key, bounds.x, bounds.y, w, h)
end

local function draw_entry(entry)
    if not entry then return end
    if entry.inst and not env.is_valid(entry.inst) then return end
    if entry.entity and entry.entity.is_alive == false then return end

    local bounds = esp_util.entry_screen_bounds(entry)
    if bounds then
        draw_bounds(bounds)
        return
    end

    local lx, ly, lz
    if entry.lx then
        lx, ly, lz = entry.lx, entry.ly, entry.lz
    elseif entry.entity and entry.entity.position then
        lx, ly, lz = entry.entity.position.x, entry.entity.position.y, entry.entity.position.z
    else
        lx, ly, lz = esp_scan.entry_coords(entry)
    end

    if lx then
        draw_bounds(esp_util.point_screen_bounds(lx, ly, lz, settings.num(P_SIZE, 48)))
    end
end

local function draw_cache_list(list)
    for _, entry in ipairs(list or {}) do
        draw_entry(entry)
    end
end

local function draw_players()
    if not entity or not entity.get_players then return end

    for _, p in ipairs(entity.get_players()) do
        if p.is_local then goto continue end

        local bounds
        if p.get_bounds then
            bounds = p:get_bounds()
        end

        if bounds and bounds.valid and bounds.w > 0 and bounds.h > 0 then
            draw_bounds(bounds)
        elseif p.position then
            draw_bounds(esp_util.point_screen_bounds(
                p.position.x, p.position.y, p.position.z,
                settings.num(P_SIZE, 64)
            ))
        end

        ::continue::
    end
end

local function draw_npcs()
    for _, entry in ipairs(cache.npcs or {}) do
        if entry.entity then
            if entry.entity.is_alive == false then goto continue end
            local bounds = entry.entity.get_bounds and entry.entity:get_bounds()
            if bounds and bounds.valid then
                draw_bounds(bounds)
                goto continue
            end
        end
        draw_entry(entry)
        ::continue::
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)
    local root = menu_util.parent(P)

    menu_util.register_keybind(T, G.VISUALS, P, "Brainrot ESP", false)
    menu.add_combo(T, G.VISUALS, P_STYLE, "Brainrot Character", labels(), 0, root)
    menu.add_slider_int(T, G.VISUALS, P_SIZE, "Brainrot Min Box Size", 24, 160, 48, root)

    menu_util.bind_children(P, { P_STYLE, P_SIZE })
end

function M.init()
    for _, entry in ipairs(catalog.ENTRIES) do
        ensure_image(catalog.image_key(entry.file), entry.file)
    end
end

function M.update(_dt)
    if not settings.enabled(P) then
        _active_key = nil
        return
    end

    local key = active_key()
    if key ~= _active_key then
        _active_key = key
        local entry = selected_entry()
        if entry then
            ensure_image(key, entry.file)
        end
    end
end

function M.draw()
    if not settings.enabled(P) then return end

    local entry = selected_entry()
    if entry then
        ensure_image(active_key(), entry.file)
    end

    draw_cache_list(cache.world)
    draw_cache_list(cache.loot)
    draw_cache_list(cache.base)
    draw_npcs()
    draw_players()
end

return M

end)()

-- ── features/world/world_esp.lua ──
April._mods["features.world.world_esp"] = (function()
local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local maps = April.require("game.esp_maps")
local esp_scan = April.require("game.esp_scan")

local M = {}
local P = "april_world_enabled"

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
    menu_util.register_keybind(T, G.WORLD, P, "Resource ESP", false)
    for _, t in ipairs(maps.WORLD_TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
    end
    menu.add_checkbox(T, G.WORLD, "april_world_boxes", "Resource 3D Boxes", false, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_world_show_name", "Resource Show Name", true, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_world_show_distance", "Resource Show Distance", true, { parent = P })
    menu.add_slider_int(T, G.WORLD, "april_world_range", "Resource Range", 50, 2000, 500, { parent = P })

    local child_ids = { "april_world_boxes", "april_world_show_name", "april_world_show_distance", "april_world_range" }
    for _, t in ipairs(maps.WORLD_TOGGLES) do
        child_ids[#child_ids + 1] = t.id
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
    M._static = state.out or {}
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
    M._dynamic = state.out or {}
    rebuild_cache()
end

function M.scan_static()
    local state = M.begin_static_scan()
    while not M.step_static_scan(state, 9999) do end
    M.complete_static_scan(state)
end

function M.scan_dynamic()
    local state = M.begin_dynamic_scan()
    while not M.step_dynamic_scan(state, 9999) do end
    M.complete_dynamic_scan(state)
end

function M.scan()
    M.scan_static()
    M.scan_dynamic()
end

function M.update(_dt)
    if not settings.enabled(P) then return end
    if #M._dynamic > 0 and cache.should_refresh_positions() then
        refresh_dynamic_positions(M._dynamic)
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

-- ── features/world/loot_esp.lua ──
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

local M = {}
local P = "april_loot_enabled"

M._static = {}
M._drops = {}

local UNLIMITED_RANGE = {
    april_timed_crate = true,
    april_care_package = true,
    april_btr_crate = true,
}

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
    M._static = state.out or {}
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
    M._drops = state.out or {}
    rebuild_cache()
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    menu_util.register_keybind(T, G.WORLD, P, "Loot ESP", false)
    for _, t in ipairs(maps.LOOT_TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
    end
    menu.add_checkbox(T, G.WORLD, "april_loot_boxes", "Loot 3D Boxes", false, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_loot_show_name", "Loot Show Name", true, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_loot_show_distance", "Loot Show Distance", true, { parent = P })
    menu.add_slider_int(T, G.WORLD, "april_loot_range", "Loot Range", 50, 2000, 300, { parent = P })

    local child_ids = { "april_loot_boxes", "april_loot_show_name", "april_loot_show_distance", "april_loot_range" }
    for _, t in ipairs(maps.LOOT_TOGGLES) do
        child_ids[#child_ids + 1] = t.id
    end
    menu_util.bind_children(P, child_ids)
end

function M.scan_drops()
    local state = M.begin_drops_scan()
    while not M.step_drops_scan(state, 9999) do end
    M.complete_drops_scan(state)
end

function M.scan_static()
    local state = M.begin_static_scan()
    while not M.step_static_scan(state, 9999) do end
    M.complete_static_scan(state)
end

function M.scan()
    M.scan_static()
    M.scan_drops()
end

function M.update(_dt)
    local map_loot = settings.enabled("april_map_enabled") and settings.enabled("april_map_show_loot")
    if not settings.enabled(P) and not map_loot then return end
    if #M._drops > 0 and cache.should_refresh_positions() then
        refresh_dynamic_positions(M._drops)
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

-- ── features/world/base_esp.lua ──
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

local M = {}
local P = "april_base_enabled"

local function append_base_entry(state, model, type_name, toggle_id)
    if not model or not env.is_valid(model) then return end
    if not esp_scan.find_main_part(model) and not esp_scan.is_part(model) then return end

    state.seen = state.seen or {}
    local key = tostring(model.Address or model) .. ":" .. toggle_id
    if state.seen[key] then return end
    state.seen[key] = true

    table.insert(state.out, esp_scan.make_entry(model, type_name, toggle_id))
end

local function collect_base_container(state, container, type_name, toggle_id)
    if not env.is_valid(container) then return end

    if type_name == "Sleeping Bag" then
        local bag = env.safe_call(function()
            return container:find_first_child("SleepingBag")
                or container:FindFirstChild("SleepingBag")
                or container:find_first_child("Sleeping_Bag")
                or container:FindFirstChild("Sleeping_Bag")
        end)
        if bag and env.is_valid(bag) then
            append_base_entry(state, bag, type_name, toggle_id)
            return
        end
    end

    local cn = container.ClassName or container.class_name
    if cn == "Model" then
        append_base_entry(state, container, type_name, toggle_id)
        return
    end

    if esp_scan.find_main_part(container) or esp_scan.is_part(container) then
        append_base_entry(state, container, type_name, toggle_id)
    end

    local subs = env.safe_call(function() return container:get_children() end) or {}
    for _, child in ipairs(subs) do
        if not env.is_valid(child) then goto child_continue end
        local cc = child.ClassName or child.class_name
        if cc == "Model" then
            append_base_entry(state, child, type_name, toggle_id)
        elseif esp_scan.find_main_part(child) or esp_scan.is_part(child) then
            append_base_entry(state, child, type_name, toggle_id)
        end
        ::child_continue::
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
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
    menu.add_slider_int(T, G.WORLD, "april_base_range", "Base Range", 50, 500, 150, { parent = P })

    local child_ids = { "april_base_boxes", "april_base_show_name", "april_base_show_distance", "april_base_range" }
    for _, t in ipairs(maps.BASE_TOGGLES) do
        child_ids[#child_ids + 1] = t.id
        if t.ring_id then
            child_ids[#child_ids + 1] = t.ring_id
        end
    end
    menu_util.bind_children(P, child_ids)
end

function M.begin_scan()
    return {
        areas = nil,
        ai = 1,
        items = nil,
        ii = 1,
        out = {},
        seen = {},
    }
end

function M.step_scan(state, batch)
    if not state.areas then
        state.areas = env.safe_call(function()
            local bases = folders.from_key("bases")
            if not env.is_valid(bases) then return {} end
            return bases:get_children()
        end) or {}
        state.ai = 1
        state.items = nil
        state.ii = 1
    end

    local processed = 0

    while processed < batch do
        if state.ai > #state.areas then
            return true
        end

        if not state.items then
            local area = state.areas[state.ai]
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

            if maps.BASE_MAP[area_name] then
                state.items = { area }
                local children = env.safe_call(function() return area:get_children() end) or {}
                for _, child in ipairs(children) do
                    state.items[#state.items + 1] = child
                end
            else
                state.items = env.safe_call(function() return area:get_children() end) or {}
            end
            state.ii = 1
        end

        if state.ii > #state.items then
            state.ai = state.ai + 1
            state.items = nil
            goto continue
        end

        local type_folder = state.items[state.ii]
        state.ii = state.ii + 1
        processed = processed + 1

        if not env.is_valid(type_folder) then goto continue end

        local type_name = type_folder.Name or type_folder.name or ""
        local toggle_id = maps.BASE_MAP[type_name]
        if not toggle_id then goto continue end

        collect_base_container(state, type_folder, type_name, toggle_id)

        ::continue::
    end

    return false
end

function M.complete_scan(state)
    cache.base = state.out or {}
    cache.stats.last_base_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.scan()
    local state = M.begin_scan()
    while not M.step_scan(state, 9999) do end
    M.complete_scan(state)
end

function M.update(_dt) end

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
    local label_groups = {}

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
                local ring_col = { col[1], col[2], col[3], 0.35 }
                desync_vis.draw_sphere_ring(lx, ly, lz, activation, ring_col, 1.5)
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
                    local gk = string.format("%d:%d:%d",
                        math.floor(lx * 2), math.floor(ly * 2), math.floor(lz * 2))
                    local group = label_groups[gk]
                    if not group then
                        group = { sx = sx, sy = sy, lines = {} }
                        label_groups[gk] = group
                    end
                    group.lines[#group.lines + 1] = { label = label, col = col }
                end
            end
        end

        ::continue::
    end

    for _, group in pairs(label_groups) do
        for i, line in ipairs(group.lines) do
            local offset = (i - 1) * (text_size + 2)
            draw_util.text_centered(group.sx, group.sy - offset, line.label, line.col, text_size)
        end
    end
end

return M

end)()

-- ── features/world/npc_esp.lua ──
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
local POS_REFRESH_BATCH = 8

M._pos_idx = 0

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    local root = menu_util.parent(P)

    menu_util.register_keybind(T, G.WORLD, P, "NPC ESP", false, { colorpicker = { 1, 0.3, 0.3, 1 } })
    menu.add_checkbox(T, G.WORLD, "april_npc_soldiers", "Soldiers", false, menu_util.parent(P, { colorpicker = { 1, 0.3, 0.3, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_bosses", "Bosses (Bruno / Boris / Brutus)", false, menu_util.parent(P, { colorpicker = { 1, 0.5, 0.1, 1 } }))
    menu.add_combo(T, G.WORLD, "april_npc_box_mode", "NPC Box Mode", { "None", "2D", "Corner" }, 0, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_health", "Health Bar", false, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_skeleton", "Skeleton", false, menu_util.parent(P, { colorpicker = { 1, 1, 1, 0.85 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_offscreen", "Offscreen Arrows", false, menu_util.parent(P, { colorpicker = { 1, 0.3, 0.3, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_show_name", "NPC Show Name", true, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_show_distance", "NPC Show Distance", true, root)
    menu.add_slider_int(T, G.WORLD, "april_npc_range", "NPC Range", 50, 2000, 500, root)

    menu_util.bind_children(P, {
        "april_npc_soldiers", "april_npc_bosses", "april_npc_box_mode", "april_npc_health",
        "april_npc_skeleton", "april_npc_offscreen", "april_npc_show_name", "april_npc_show_distance",
        "april_npc_range",
    })
end

function M.begin_scan()
    return npcs.begin_scan()
end

function M.step_scan(state, batch)
    return npcs.step_scan(state, batch)
end

function M.complete_scan(state)
    cache.npcs = npcs.complete_scan(state)
    cache.stats.last_npc_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.scan()
    local state = M.begin_scan()
    while not M.step_scan(state, 9999) do end
    M.complete_scan(state)
end

local function kind_enabled(kind)
    if kind == "soldier" then return settings.bool("april_npc_soldiers", false) end
    if kind == "boss" then return settings.bool("april_npc_bosses", false) end
    return false
end

local function kind_color(kind)
    if kind == "boss" then return settings.color("april_npc_bosses", { 1, 0.5, 0.1, 1 }) end
    return settings.color("april_npc_soldiers", { 1, 0.3, 0.3, 1 })
end

local function entity_addr(p)
    if not p then return nil end
    if p.character then
        local addr = p.character.Address or p.character.address
        if addr then return tostring(addr) end
    end
    return (p.name or "?") .. ":" .. tostring(p.user_id or 0)
end

local function instance_addr(entry)
    if not entry or not entry.inst then return nil end
    return tostring(entry.inst.Address or entry.inst.address or entry.inst)
end

local function refresh_npc_position(entry)
    if entry.entity then
        local p = entry.entity
        if not p.is_alive then return false end
        if p.head_position then
            local pos = p.head_position
            entry.lx = pos.x
            entry.ly = pos.y
            entry.lz = pos.z
            return true
        end
        if p.position then
            local pos = p.position
            entry.lx = pos.x
            entry.ly = pos.y
            entry.lz = pos.z
            return true
        end
        return false
    end

    if not entry or not env.is_valid(entry.inst) then return false end
    local head = entry.head
    if head and env.is_valid(head) then
        local pos = head.Position or head.position
        if pos and pos.x then
            entry.lx = pos.x
            entry.ly = pos.y
            entry.lz = pos.z
            return true
        end
    end
    return false
end

local function collect_draw_targets()
    local out = {}
    local seen = {}

    if entity and entity.get_players then
        for _, p in ipairs(entity.get_players()) do
            if p.is_local or not p.is_alive then goto continue end

            local kind = npcs.kind(p.name)
            if not kind then goto continue end
            if not p.is_workspace_entity and p.user_id ~= 0 then goto continue end

            local addr = entity_addr(p)
            if addr and seen[addr] then goto continue end
            if addr then seen[addr] = true end

            out[#out + 1] = {
                entity = p,
                name = p.name,
                kind = kind,
            }

            ::continue::
        end
    end

    for _, entry in ipairs(cache.npcs or {}) do
        local addr = instance_addr(entry)
        if addr and seen[addr] then goto continue_scan end
        if addr then seen[addr] = true end
        out[#out + 1] = entry
        ::continue_scan::
    end

    return out
end

local function screen_bounds(entry)
    if entry.entity and entry.entity.get_bounds then
        local b = entry.entity:get_bounds()
        if b and b.valid and b.w > 0 and b.h > 0 then
            return b
        end
    end

    if entry.inst then
        return esp_util.model_screen_bounds(entry.inst)
    end

    return nil
end

local function draw_npc_box(bounds, col, box_mode)
    if not bounds or not bounds.valid then return end
    local x, y, w, h = bounds.x, bounds.y, bounds.w, bounds.h
    if box_mode == 1 then
        draw_util.box_esp(x, y, w, h, col, 0)
    else
        draw_util.box_esp(x, y, w, h, col, 1)
    end
end

local function draw_npc_health(bounds, entry)
    if not settings.bool("april_npc_health", false) then return end
    if not bounds or not bounds.valid or not draw or not draw.health_bar then return end

    local hp, max_hp
    if entry.entity then
        hp = entry.entity.health
        max_hp = entry.entity.max_health
    elseif entry.inst then
        local hum = env.safe_call(function()
            if entry.inst.find_first_child_of_class then
                return entry.inst:find_first_child_of_class("Humanoid")
            end
            return entry.inst:FindFirstChild("Humanoid")
        end)
        if hum then
            hp = hum.Health or hum.health
            max_hp = hum.MaxHealth or hum.max_health
        end
    end

    if not hp or not max_hp or max_hp <= 0 then return end
    draw.health_bar(bounds.x - 6, bounds.y, bounds.h, hp, max_hp)
end

function M.update(_dt)
    if not settings.enabled(P) then return end

    local list = collect_draw_targets()
    local n = #list
    if n == 0 then return end

    for _ = 1, POS_REFRESH_BATCH do
        M._pos_idx = (M._pos_idx % n) + 1
        refresh_npc_position(list[M._pos_idx])
    end
end

function M.draw()
    if not settings.enabled(P) then return end

    local range = settings.num("april_npc_range", 500)
    local range_sq = range * range
    local box_mode = settings.num("april_npc_box_mode", 0)
    local text_size = esp_util.text_size()
    local me = env.get_local_player()
    local me_pos = me and me.position
    local sw, sh = draw_util.screen_size()
    local cx, cy = sw * 0.5, sh * 0.5

    for _, entry in ipairs(collect_draw_targets()) do
        if not kind_enabled(entry.kind) then goto continue end

        if entry.entity then
            if not entry.entity.is_alive then goto continue end
        elseif not env.is_valid(entry.inst) then
            goto continue
        end

        local col = kind_color(entry.kind)

        refresh_npc_position(entry)
        local lx, ly, lz = entry.lx, entry.ly, entry.lz

        if not lx and entry.entity and entry.entity.position then
            local pos = entry.entity.position
            lx, ly, lz = pos.x, pos.y, pos.z
            entry.lx, entry.ly, entry.lz = lx, ly, lz
        end
        if not lx then goto continue end

        local dist_sq = 0
        if me_pos then
            local dx = lx - me_pos.x
            local dy = ly - me_pos.y
            local dz = lz - me_pos.z
            dist_sq = dx * dx + dy * dy + dz * dz
            if dist_sq > range_sq then goto continue end
        end

        local bounds = screen_bounds(entry)
        local label_y = ly

        if bounds and bounds.valid then
            label_y = bounds.y
        else
            local sx, sy, vis = esp_util.w2s(lx, ly, lz)
            if not vis then
                if settings.bool("april_npc_offscreen", false) then
                    esp_util.draw_offscreen_arrow(cx, cy, sx, sy, col, 12)
                end
                goto continue
            end
            label_y = sy
        end

        local label = entry.name or "NPC"
        local show_name = settings.bool("april_npc_show_name", true)
        local show_dist = settings.bool("april_npc_show_distance", true)

        if show_name or show_dist then
            if show_dist and me_pos then
                local dist_text = string.format("%dm", math.floor(math.sqrt(dist_sq)))
                if show_name then
                    label = label .. " [" .. dist_text .. "]"
                else
                    label = dist_text
                end
            elseif not show_name then
                label = nil
            end

            if label then
                local tx = bounds and bounds.valid and (bounds.x + bounds.w * 0.5) or lx
                local ty = label_y - 14
                if bounds and bounds.valid then
                    draw_util.text_centered(tx, ty, label, col, text_size)
                else
                    local sx, sy, vis = esp_util.w2s(lx, ly, lz)
                    if vis then
                        draw_util.text_centered(sx, sy - 14, label, col, text_size)
                    end
                end
            end
        end

        if settings.bool("april_npc_skeleton", false) then
            local sk = settings.color("april_npc_skeleton", { 1, 1, 1, 0.85 })
            if entry.entity and entry.entity.get_bones_screen then
                esp_util.draw_player_skeleton(entry.entity, sk, 1.5)
            elseif entry.inst then
                esp_util.draw_model_skeleton(entry.inst, sk, 1.5)
            end
        end

        if box_mode > 0 then
            if not bounds or not bounds.valid then
                bounds = screen_bounds(entry)
            end
            if bounds and bounds.valid then
                draw_npc_box(bounds, col, box_mode)
            end
        end

        draw_npc_health(bounds, entry)

        ::continue::
    end
end

return M

end)()

-- ── features/movement/exploits.lua ──
April._mods["features.movement.exploits"] = (function()
local menu_util = April.require("core.menu_util")

local M = {}

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)

    menu_util.register_keybind(T, G.MISC, "april_noclip_enabled", "Inf Fly", false)
    menu.add_slider_int(T, G.MISC, "april_noclip_speed", "Inf Fly Speed", 16, 200, 72, menu_util.parent("april_noclip_enabled"))

    menu_util.register_keybind(T, G.MISC, "april_spider_enabled", "Spider", false)
    menu.add_slider_int(T, G.MISC, "april_spider_speed", "Spider Climb Speed", 1, 50, 20, menu_util.parent("april_spider_enabled"))

    menu_util.register_keybind(T, G.MISC, "april_slowfall_enabled", "Slowfall", false)
    menu.add_slider_int(T, G.MISC, "april_slowfall_speed", "Fall Speed", 1, 50, 5, menu_util.parent("april_slowfall_enabled"))

    menu_util.bind_children("april_noclip_enabled", { "april_noclip_speed" })
    menu_util.bind_children("april_spider_enabled", { "april_spider_speed" })
    menu_util.bind_children("april_slowfall_enabled", { "april_slowfall_speed" })
end

function M.update(_dt) end

function M.draw() end

return M

end)()

-- ── features/movement/noclip.lua ──
April._mods["features.movement.noclip"] = (function()
--[[ Noclip menu — movement handled by core/movement_ctrl.lua ]]

local menu_util = April.require("core.menu_util")

local M = {}

local P = "april_walk_noclip_enabled"
local P_SPEED = "april_walk_noclip_speed"

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.register_keybind(T, G.MISC, P, "Noclip", false)
    menu.add_slider_int(T, G.MISC, P_SPEED, "Noclip Speed", 8, 80, 32, root)
    menu_util.bind_children(P, { P_SPEED })
end

function M.update(_dt) end

function M.draw() end

return M

end)()

-- ── features/movement/fling.lua ──
April._mods["features.movement.fling"] = (function()
--[[ Fling — noclip TP spin: far-range entity lock, approach warmup, return to origin. ]]

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
local P_KEY = "april_fling_key"
local P_KEY_MODE = "april_fling_key_mode"
local P_DURATION = "april_fling_duration"
local KEY_MODES = { "Toggle", "Hold" }

local MAX_DIST = 300.0
local FAR_RANGE = 40.0
local SPIN_Y_START = 48000.0
local SPIN_Y_MAX = 70000.0
local SPIN_RAMP_SEC = 0.35
local BASE_PREDICT = 0.05

local function fling_duration()
    return settings.num(P_DURATION, 2)
end

local function key_is_hold()
    return settings.combo_index(P_KEY_MODE, KEY_MODES, 0) == 1
end

local STATE_IDLE = 0
local STATE_APPROACH = 1
local STATE_FLING = 2

local _installed = false
local state = STATE_IDLE
local fling_t0 = 0
local approach_left = 0
local start_range = 0
local saved_pos = nil
local target_root = nil
local target_player = nil
local last_attach = nil
local key_was_down = false

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
    if not entity or not entity.get_players then return nil, nil end

    local cx, cy = screen_center()
    local cam = camera and camera.get_position and camera.get_position()
    local best, best_dist = nil, fov_px

    for _, p in ipairs(entity.get_players()) do
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
    local base = 5
    if range > 220 then base = 22
    elseif range > 150 then base = 18
    elseif range > 100 then base = 14
    elseif range > 60 then base = 10
    elseif range > 30 then base = 7
    end

    if drift > 12 then base = base + 8
    elseif drift > 6 then base = base + 5
    elseif drift > 2 then base = base + 3
    end

    return base
end

local function approach_ticks_for(dist)
    if dist <= FAR_RANGE then return 0 end
    return math.min(12, math.floor(dist / 22) + 3)
end

local function prep_fling(char, root, hum)
    move.set_character_noclip(char, root, true)
    move.humanoid_suspend(hum)
    pcall(function() hum.platform_stand = true end)
    pcall(function() hum.auto_rotate = false end)
    pcall(function() hum.evaluate_state_machine = false end)
    pcall(function() hum.sit = false end)
    pcall(function() hum.state = 14 end)
end

local function release_fling(char, root, hum)
    if root then
        move.set_velocity(root, 0, 0, 0)
        if part and part.set_angular_velocity then
            pcall(part.set_angular_velocity, root, 0, 0, 0)
        end
    end
    move.zero_character(char, root)
    move.set_character_noclip(char, root, false)
    pcall(function() hum.platform_stand = false end)
    move.humanoid_running(hum)
end

local function write_pos(inst, x, y, z)
    if not inst then return end
    if part and part.set_position then
        pcall(part.set_position, inst, x, y, z)
    else
        pcall(function() inst.Position = Vector3.new(x, y, z) end)
    end
end

local function freeze_body(char, root)
    if root then
        move.set_velocity(root, 0, 0, 0)
    end
    for _, inst in ipairs(move.iter_parts(char)) do
        move.set_velocity(inst, 0, 0, 0)
        if inst ~= root and part and part.set_angular_velocity then
            pcall(part.set_angular_velocity, inst, 0, 0, 0)
        end
    end
end

local function pin_to_target(char, root, tgt_root, from_pos)
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

    freeze_body(char, root)
    return true, tx, ty, tz
end

local function spin_strength(elapsed)
    local t = math.min(1, elapsed / SPIN_RAMP_SEC)
    return SPIN_Y_START + (SPIN_Y_MAX - SPIN_Y_START) * t
end

local function apply_spin(root, elapsed)
    move.set_velocity(root, 0, 0, 0)
    if part and part.set_angular_velocity then
        pcall(part.set_angular_velocity, root, 0, spin_strength(elapsed), 0)
    end
end

local function stop_fling(root, char, hum)
    if saved_pos and root then
        write_pos(root, saved_pos.x, saved_pos.y, saved_pos.z)
        move.set_velocity(root, 0, 0, 0)
    end
    release_fling(char, root, hum)
    state = STATE_IDLE
    fling_t0 = 0
    approach_left = 0
    start_range = 0
    saved_pos = nil
    target_root = nil
    target_player = nil
    last_attach = nil
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
    pin_to_target(char, root, tgt_root, pos)

    if state == STATE_FLING then
        apply_spin(root, 0)
    end

    return true
end

local function tick_approach(root, char, hum)
    prep_fling(char, root, hum)

    if not pin_to_target(char, root, target_root, nil) then
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

    local ok, tx, ty, tz = pin_to_target(char, root, target_root, nil)
    if not ok then
        return
    end

    apply_spin(root, elapsed)
    write_pos(root, tx, ty, tz)
end

local function tick_active(root, char, hum)
    if state == STATE_APPROACH then
        tick_approach(root, char, hum)
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

local function poll_key()
    if not settings.enabled(P) then
        key_was_down = false
        return
    end
    if state ~= STATE_IDLE then return end
    if not menu or not menu.get_key then return end

    local key = menu.get_key(P_KEY) or 0
    if key <= 0 then
        key_was_down = false
        return
    end
    if not input or not input.is_key_down then return end

    local down = input.is_key_down(key)
    if key_is_hold() then
        if down then
            try_trigger()
        end
    elseif down and not key_was_down then
        try_trigger()
    end
    key_was_down = down
end

local function tick(_dt)
    if not misc_gate.movement_allowed() then return end

    poll_key()
    if state == STATE_IDLE then return end

    local lp = env.get_local_player()
    if not lp then
        state = STATE_IDLE
        approach_left = 0
        start_range = 0
        target_root = nil
        target_player = nil
        saved_pos = nil
        last_attach = nil
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
    return state == STATE_APPROACH or state == STATE_FLING
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu.add_checkbox(T, G.MISC, P, "Fling", false)
    menu.add_slider_int(T, G.MISC, P_FOV, "Fling FOV", 20, 600, 150, root)
    menu.add_slider_int(T, G.MISC, P_DURATION, "Fling Duration", 2, 10, 2, root)
    menu.add_combo(T, G.MISC, P_KEY_MODE, "Fling Key Mode", KEY_MODES, 0, root)
    if menu.add_hotkey then
        menu.add_hotkey(T, G.MISC, P_KEY, "Fling Key", 0, root)
    end
    menu_util.bind_children(P, { P_FOV, P_DURATION, P_KEY_MODE, P_KEY })
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

-- ── features/movement/desync.lua ──
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

local RANGE_RADIUS = 7.5
local DESYNC_RING_RADIUS = 2.5

local LOOP_MS = 30
local last_tick = 0
local last_flag_apply = 0
local old_phys, old_send = nil, nil
local was_active = false
local was_sending = false
local anchor_pos = nil
local server_pos = nil

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

local function disable_desync()
    if menu and menu.set then
        pcall(menu.set, P, false)
    end
end

local function compute_rates(t)
    local phys, send = 0, 60

    if settings.enabled("april_desync_autosend") then
        local window = settings.num("april_desync_autosend_len", 0.3)
        local cycle = window + 0.1
        if (t % cycle) > window then
            phys, send = 15, 60
        end
    end

    return phys, send
end

local function update_server_pos(root, sending_now)
    if not root then return end
    local pos = capture_pos(root)
    if not pos then return end

    if not settings.enabled("april_desync_autosend") then
        server_pos = server_pos or pos
    elseif sending_now and not was_sending then
        server_pos = pos
    elseif sending_now then
        server_pos = pos
    elseif was_sending and not sending_now then
        server_pos = server_pos or pos
    end
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

    local range_col = { 0.2, 0.85, 1, 0.55 }
    desync_vis.draw_sphere_ring(anchor_pos.x, anchor_pos.y, anchor_pos.z, RANGE_RADIUS, range_col, 2)

    if not settings.bool(P_VIS, false) then return end

    local col = settings.color(P_VIS, { 0.2, 0.85, 1, 0.9 })
    draw_center_dot(anchor_pos.x, anchor_pos.y, anchor_pos.z, col)

    if server_pos then
        desync_vis.draw_sphere_ring(server_pos.x, server_pos.y, server_pos.z, DESYNC_RING_RADIUS, col, 2)
        desync_vis.draw_link(server_pos, anchor_pos, { col[1], col[2], col[3], (col[4] or 1) * 0.35 }, 1)
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.gap(T, G.MISC)
    menu_util.register_keybind(T, G.MISC, P, "Desync", false)
    menu.add_checkbox(T, G.MISC, "april_desync_autosend", "Desync Auto Send", false, root)
    menu.add_slider_float(T, G.MISC, "april_desync_autosend_len", "Desync Send Threshold", 0, 1, 0.3, root)
    menu.add_checkbox(T, G.MISC, P_VIS, "Desync Visualize", false, menu_util.parent(P, {
        colorpicker = { 0.2, 0.85, 1, 0.9 },
    }))

    menu_util.bind_children(P, {
        "april_desync_autosend", "april_desync_autosend_len", P_VIS,
    })

    menu_util.bind_when(function()
        return settings.enabled(P) and settings.enabled("april_desync_autosend")
    end, { "april_desync_autosend_len" }, { P, "april_desync_autosend" })
end

function M.update(_dt)
    if not misc_gate.movement_allowed() then return end
    local on = active()
    local t = now()

    if was_active and not on then
        restore_rates()
        anchor_pos = nil
        server_pos = nil
        was_sending = false
    end

    if on and not was_active then
        pcall(fflag_mem.refresh)
        local root = get_root()
        anchor_pos = capture_pos(root)
        server_pos = anchor_pos and { x = anchor_pos.x, y = anchor_pos.y, z = anchor_pos.z } or nil
    end

    was_active = on
    if not on then return end

    if (t - last_tick) * 1000 < LOOP_MS then return end
    last_tick = t

    local phys, send = compute_rates(t)
    local sending_now = phys ~= 0
    local root = get_root()

    if root and anchor_pos then
        local pos = capture_pos(root)
        if pos and dist_from_anchor(pos) > RANGE_RADIUS then
            restore_rates()
            anchor_pos = nil
            server_pos = nil
            was_sending = false
            was_active = false
            disable_desync()
            return
        end
    end

    update_server_pos(root, sending_now)
    was_sending = sending_now

    if phys ~= old_phys or send ~= old_send or (t - last_flag_apply) > 0.35 then
        apply_rates(phys, send)
        old_phys, old_send = phys, send
        last_flag_apply = t
    end
end

function M.draw()
    if not misc_gate.movement_allowed() then return end
    if not active() then return end
    draw_visualizer()
end

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

    menu_util.register_keybind(T, G.RADAR, P, "Enable Waypoints", false)
    menu.add_checkbox(T, G.RADAR, "april_wp_dist", "Waypoint Show Distance", false, root)
    menu.add_checkbox(T, G.RADAR, "april_wp_beacon", "Beacon Pillar", false, root)
    menu.add_slider_int(T, G.RADAR, "april_wp_beacon_h", "Beacon Height", 20, 200, 90, menu_util.parent("april_wp_beacon"))
    menu.add_checkbox(T, G.RADAR, "april_wp_draw", "Draw Markers", false, menu_util.parent(P, { colorpicker = { 0.2, 1, 0.8, 1 } }))
    menu.add_slider_int(T, G.RADAR, "april_wp_slot", "Active Slot", 1, 5, 1, root)

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

-- ── features/radar/tactical_map.lua ──
April._mods["features.radar.tactical_map"] = (function()
local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local cache = April.require("core.cache")
local env = April.require("core.env")
local player_state = April.require("game.player_state")
local menu_util = April.require("core.menu_util")
local esp_scan = April.require("game.esp_scan")
local theme = April.require("core.ui_theme")

local M = {}
local P = "april_map_enabled"

local function get_camera_yaw()
    if camera and camera.get_angles then
        local ok, a = pcall(camera.get_angles)
        if ok and a then
            local deg = a.Y or a.y
            if deg then return math.rad(deg) end
        end
    end
    if utility and utility.get_camera_angles then
        local ok, _, yaw = pcall(utility.get_camera_angles)
        if ok and yaw then return math.rad(yaw) end
    end
    if camera and camera.get_look_vector then
        local ok, lv = pcall(camera.get_look_vector)
        if ok and lv then
            local lx, lz = lv.x or lv.X or 0, lv.z or lv.Z or 0
            if math.abs(lx) > 0.001 or math.abs(lz) > 0.001 then
                return math.atan2(lx, lz)
            end
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

    if not cx then cx, cy, cz = px, py, pz end
    return cx or 0, cy or 0, cz or 0, px, py, pz
end

local function map_basis(yaw)
    local fx, fz = math.sin(yaw), math.cos(yaw)
    local rx, rz = -math.cos(yaw), math.sin(yaw)
    return fx, fz, rx, rz
end

local function world_to_map(wx, wz, view_x, view_z, map_cx, map_cy, zoom, yaw)
    local wdx = wx - view_x
    local wdz = wz - view_z
    local fx, fz, rx, rz = map_basis(yaw)
    local local_fwd = wdx * fx + wdz * fz
    local local_right = wdx * rx + wdz * rz
    return map_cx + local_right * zoom, map_cy - local_fwd * zoom
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
    if not text or text == "" then return "" end
    text = text:gsub("%s*%(Sleeper%)", "")
    if #text > 10 then
        return text:sub(1, 9) .. ".."
    end
    return text
end

local function draw_radar_label(lx, ly, text, col, x, y, w, h, fs)
    if not text or text == "" or not draw or not draw.get_text_size then return end
    fs = fs or 9
    local tw = select(1, draw.get_text_size(text, fs))
    local th = fs + 2
    lx = lx - tw * 0.5
    ly = ly + 5
    if lx < x + 4 then lx = x + 4 end
    if lx + tw > x + w - 4 then lx = x + w - 4 - tw end
    if ly + th > y + h - 4 then ly = ly - th - 8 end
    if ly < y + 4 then return end

    if draw.rect_filled then
        draw.rect_filled(lx - 2, ly - 1, tw + 4, th, { 0.04, 0.05, 0.07, 0.82 }, 3)
    end
    draw_util.text(lx, ly, text, col, fs)
end

local function draw_blip(mx, my, scale, col, clamped)
    local alpha = clamped and 0.72 or 1
    local c = { col[1], col[2], col[3], (col[4] or 1) * alpha }
    local r = math.max(2, scale - (clamped and 1 or 0))
    if draw and draw.circle_filled then
        draw.circle_filled(mx, my, r + 1, { c[1], c[2], c[3], c[4] * 0.25 }, 10)
        draw.circle_filled(mx, my, r, c, 10)
    else
        draw_util.circle(mx, my, r, c, true)
    end
end

local function draw_map_item(wx, wz, col, label, view_x, view_z, map_cx, map_cy, zoom, yaw, scale, layout)
    if not wx or not wz then return end

    local mx, my = world_to_map(wx, wz, view_x, view_z, map_cx, map_cy, zoom, yaw)
    mx, my, clamped = clamp_to_disc(mx, my, map_cx, map_cy, layout.radius)

    draw_blip(mx, my, scale, col, clamped)

    if settings.bool("april_map_labels", false) and not clamped then
        draw_radar_label(mx, my, short_label(label), col, layout.x, layout.y, layout.w, layout.h, 9)
    end
end

local function draw_radar_frame(layout, bg, border, grid)
    local x, y, w, h = layout.x, layout.y, layout.w, layout.h
    local cx, cy = layout.cx, layout.cy

    if draw.rect_filled then
        draw.rect_filled(x, y, w, h, bg, theme.ROUND)
        draw.rect_filled(x + 2, y + 2, w - 4, 18, { 0.06, 0.07, 0.09, 0.95 }, 4)
    end
    if draw.rect then
        draw.rect(x, y, w, h, border, theme.ROUND, 1)
    end

    draw_util.text(x + 8, y + 4, "RADAR", theme.TEXT, 10)

    if draw and draw.circle then
        draw.circle(cx, cy, layout.radius, grid, 48, 1)
        draw.circle(cx, cy, layout.radius * 0.66, grid, 48, 1)
        draw.circle(cx, cy, layout.radius * 0.33, grid, 48, 1)
    end

    local n_x, n_y = cx, cy - layout.radius + 10
    draw_util.text(n_x - 3, n_y - 6, "N", theme.alpha(theme.CYAN, 0.9), 10)
end

local function draw_local_blip(layout, col, body_x, body_z, view_x, view_z, zoom, yaw)
    local cx, cy = layout.cx, layout.cy
    local mx, my = cx, cy
    if body_x and body_z then
        mx, my = world_to_map(body_x, body_z, view_x, view_z, cx, cy, zoom, yaw)
        mx, my = clamp_to_disc(mx, my, cx, cy, layout.radius)
    end

    if draw and draw.line then
        local tip_x, tip_y = cx, cy - 10
        draw.line(mx, my, tip_x, tip_y, theme.alpha(col, 0.85), 2)
        draw.line(tip_x, tip_y - 4, tip_x - 3, tip_y + 2, theme.alpha(col, 0.85), 2)
        draw.line(tip_x, tip_y - 4, tip_x + 3, tip_y + 2, theme.alpha(col, 0.85), 2)
    end

    draw_blip(mx, my, layout.scale + 1, col, false)
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.RADAR)
    local root = menu_util.parent(P)

    menu_util.register_keybind(T, G.RADAR, P, "Enable Radar", false, { key = 0x28 })
    menu.add_slider_float(T, G.RADAR, "april_map_zoom", "Zoom Level", 0.05, 5.0, 1.0, "%.2f", root)
    menu.add_slider_int(T, G.RADAR, "april_map_size", "Radar Size", 140, 420, 240, root)
    menu.add_slider_int(T, G.RADAR, "april_map_icon_scale", "Blip Size", 2, 6, 3, root)

    menu.add_checkbox(T, G.RADAR, "april_map_show_players", "Players", true, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_npcs", "NPCs", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_loot", "Loot", true, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_world", "Resources", true, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_base", "Base Parts", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_waypoints", "Waypoints", true, root)

    menu.add_colorpicker(T, G.RADAR, "april_map_bg", "Background", theme.MAP_BG, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_grid", "Grid", theme.MAP_GRID, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_player_col", "Players", theme.RED, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_npc_col", "NPCs", theme.ORANGE, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_loot_col", "Loot", { 1, 0.85, 0.35, 1 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_world_col", "Resources", theme.GREEN, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_base_col", "Base", { 0.55, 0.55, 1, 1 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_wp_col", "Waypoints", theme.CYAN, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_local", "You", theme.CYAN, root)
    menu.add_checkbox(T, G.RADAR, "april_map_labels", "Radar Show Labels", false, root)

    menu_util.bind_children(P, {
        "april_map_zoom", "april_map_size", "april_map_icon_scale",
        "april_map_show_players", "april_map_show_npcs", "april_map_show_loot",
        "april_map_show_world", "april_map_show_base", "april_map_show_waypoints",
        "april_map_bg", "april_map_grid", "april_map_player_col", "april_map_npc_col",
        "april_map_loot_col", "april_map_world_col", "april_map_base_col",
        "april_map_wp_col", "april_map_local", "april_map_labels",
    })
end

function M.update(_dt) end

function M.draw()
    if not settings.enabled(P) then return end
    if not draw then return end

    local sw, sh = draw_util.screen_size()
    local size = settings.num("april_map_size", 240)
    local x, y = sw - size - 16, 16
    local w, h = size, size
    local cx, cy = x + w * 0.5, y + h * 0.5
    local radius = math.min(w, h) * 0.5 - 14
    local zoom = settings.num("april_map_zoom", 1.0)
    local scale = settings.num("april_map_icon_scale", 3)

    local layout = { x = x, y = y, w = w, h = h, cx = cx, cy = cy, radius = radius, scale = scale }

    local bg = settings.color("april_map_bg", theme.MAP_BG)
    local grid = settings.color("april_map_grid", theme.MAP_GRID)
    local border = theme.BORDER_CYAN

    local cam_x, _, cam_z, body_x, _, body_z = get_view_origin()
    local yaw = get_camera_yaw()
    local view_x, view_z = cam_x, cam_z

    draw_radar_frame(layout, bg, border, grid)

    if settings.bool("april_map_show_world", false) then
        local col = settings.color("april_map_world_col", theme.GREEN)
        for _, item in ipairs(cache.world) do
            if env.is_valid(item.inst) then
                local wx, wz = entry_world_xz(item)
                if wx then
                    draw_map_item(wx, wz, col, item.name, view_x, view_z, cx, cy, zoom, yaw, scale, layout)
                end
            end
        end
    end

    if settings.bool("april_map_show_loot", false) then
        local col = settings.color("april_map_loot_col", { 1, 0.85, 0.35, 1 })
        for _, item in ipairs(cache.loot) do
            if env.is_valid(item.inst) then
                local wx, wz = entry_world_xz(item)
                if wx then
                    draw_map_item(wx, wz, col, item.name, view_x, view_z, cx, cy, zoom, yaw, scale, layout)
                end
            end
        end
    end

    if settings.bool("april_map_show_base", false) then
        local col = settings.color("april_map_base_col", { 0.55, 0.55, 1, 1 })
        for _, item in ipairs(cache.base) do
            if env.is_valid(item.inst) then
                local wx, wz = entry_world_xz(item)
                if wx then
                    draw_map_item(wx, wz, col, item.name, view_x, view_z, cx, cy, zoom, yaw, scale, layout)
                end
            end
        end
    end

    if settings.bool("april_map_show_npcs", false) then
        local col = settings.color("april_map_npc_col", theme.ORANGE)
        for _, entry in ipairs(cache.npcs) do
            if env.is_valid(entry.inst) then
                local wx, wz = entry_world_xz(entry)
                if wx then
                    draw_map_item(wx, wz, col, entry.name, view_x, view_z, cx, cy, zoom, yaw, scale, layout)
                end
            end
        end
    end

    if settings.bool("april_map_show_waypoints", false) then
        local col = settings.color("april_map_wp_col", theme.CYAN)
        for i, wp in pairs(cache.waypoints) do
            if wp and wp.pos then
                draw_map_item(wp.pos.x, wp.pos.z, col, wp.name or ("WP" .. i), view_x, view_z, cx, cy, zoom, yaw, scale, layout)
            end
        end
    end

    if settings.bool("april_map_show_players", false) and entity and entity.get_players then
        local col = settings.color("april_map_player_col", theme.RED)
        for _, p in ipairs(entity.get_players()) do
            if player_state.is_combat_target(p) and p.position then
                local label = (p.display_name and p.display_name ~= "" and p.display_name) or p.name
                draw_map_item(p.position.x, p.position.z, col, label, view_x, view_z, cx, cy, zoom, yaw, scale, layout)
            end
        end
    end

    local local_col = settings.color("april_map_local", theme.CYAN)
    draw_local_blip(layout, local_col, body_x, body_z, view_x, view_z, zoom, yaw)
end

return M

end)()

-- ── features/utility/mod_checker.lua ──
April._mods["features.utility.mod_checker"] = (function()
local settings = April.require("core.settings")
local notify = April.require("core.notify")
local mod_ids = April.require("game.mod_ids")
local menu_util = April.require("core.menu_util")
local draw_util = April.require("core.draw_util")
local env = April.require("core.env")
local esp_util = April.require("core.esp_util")
local image_cache = April.require("core.image_cache")
local asset_urls = April.require("game.asset_urls")
local theme = April.require("core.ui_theme")

local M = {}
local P = "april_mod_checker_enabled"
local MOD_ICON_KEY = "mod_warning"
local HEAD_OFFSET = 3.5

local seen = {}
local active = {}
local last_scan = -1
local SCAN_MS = 2500
M._session = nil
M._was_enabled = false

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function session_id()
    if not game then return "none" end
    local pid = game.place_id or 0
    local ws = game.workspace
    local ws_addr = (ws and (ws.Address or ws.address)) or 0
    return pid .. ":" .. ws_addr
end

function M.reset_state()
    seen = {}
    active = {}
    last_scan = -1
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
        M.reset_state()
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
    menu.add_checkbox(T, G.MISC, P, "Mod Checker", false)
    menu.add_slider_int(T, G.MISC, "april_mod_checker_interval", "Mod Scan Interval (ms)", 1000, 10000, 2500, { parent = P })
    menu_util.bind_master(P, { "april_mod_checker_interval" })
end

function M.init()
    image_cache.ensure(MOD_ICON_KEY, asset_urls.mod_warning_png())
    last_scan = -1
end

function M.track_player(p, role)
    local uid = p.user_id
    if not uid or uid == 0 then return end

    local now = tick_ms()
    if not active[uid] then
        active[uid] = {
            uid = uid,
            label = player_label(p),
            username = p.name or "?",
            role = role,
            first_seen = now,
        }
    else
        local entry = active[uid]
        entry.label = player_label(p)
        entry.username = p.name or entry.username
        entry.role = role
    end
end

function M.check_player(p)
    if not settings.enabled(P) then return end
    if not p or p.is_local then return end

    local uid = p.user_id
    if not uid or uid == 0 then return end

    local role = mod_ids.role_for(uid)
    if not role then return end

    M.track_player(p, role)

    if seen[uid] then return end
    seen[uid] = true
    local label = player_label(p)
    notify.warning(string.format("MOD: %s (%s) - %s", label, p.name or "?", role), 6000)
end

function M.reconcile_active()
    if not entity or not entity.get_players then return end

    local players = entity.get_players()
    if #players == 0 then return end

    local present = {}
    for _, p in ipairs(players) do
        if p.is_local then goto continue end
        local uid = p.user_id
        if not uid or uid == 0 then goto continue end

        local role = mod_ids.role_for(uid)
        if role then
            present[uid] = true
            M.track_player(p, role)
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
    M.reconcile_active()

    for _, p in ipairs(entity and entity.get_players and entity.get_players() or {}) do
        M.check_player(p)
    end
end

function M.on_player_added(p)
    M.check_player(p)
end

function M.on_player_removed(p)
    if not p then return end
    local uid = p.user_id
    if uid and uid ~= 0 then
        seen[uid] = nil
        active[uid] = nil
    end
end

function M.is_staff(player)
    if not player then return false end
    local uid = player.user_id
    if not uid or uid == 0 then return false end
    if active[uid] then return true end
    return mod_ids.role_for(uid) ~= nil
end

function M.update(_dt)
    M.tick_session()

    if not settings.enabled(P) then
        if M._was_enabled then M.reset_state() end
        M._was_enabled = false
        return
    end
    M._was_enabled = true

    local now = tick_ms()
    local interval = settings.num("april_mod_checker_interval", SCAN_MS)
    if last_scan < 0 or (now - last_scan) >= interval then
        last_scan = now
        M.scan_all()
    end
end

function M.draw_mod_markers()
    if not settings.enabled(P) then return end
    if not entity or not entity.get_players then return end

    for _, p in ipairs(entity.get_players()) do
        if p.is_local then goto continue end

        local uid = p.user_id
        if not uid or uid == 0 then goto continue end
        if not mod_ids.role_for(uid) then goto continue end

        local wx, wy, wz = head_world_pos(p)
        if not wx then goto continue end

        local sx, sy, vis = esp_util.w2s(wx, wy, wz)
        if not vis then goto continue end

        theme.draw_mod_marker(sx, sy, image_cache, MOD_ICON_KEY)

        ::continue::
    end
end

local function build_staff_rows()
    local rows = {}
    local me = env.get_local_player()
    local now = tick_ms()

    if not entity or not entity.get_players then return rows end

    for _, p in ipairs(entity.get_players()) do
        if p.is_local then goto continue end

        local uid = p.user_id
        if not uid or uid == 0 then goto continue end

        local role = mod_ids.role_for(uid)
        if not role then goto continue end

        M.track_player(p, role)
        local entry = active[uid]
        if not entry then goto continue end

        local dist = nil
        if me and me.position and p.position then
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
            role = role,
            meta = meta,
            first_seen = entry.first_seen or now,
        }

        ::continue::
    end

    table.sort(rows, function(a, b)
        return (a.first_seen or 0) < (b.first_seen or 0)
    end)

    return rows
end

local function draw_staff_panel(x, y, width, rows)
    if not draw or not draw.text then return end

    local pad = 10
    local title_h = 24
    local row_h = 44
    local count = math.max(#rows, 1)
    local height = title_h + count * row_h + 6

    theme.draw_panel(x, y, width, height, {
        bg = theme.alpha(theme.BG, 0.90),
        border = theme.alpha(theme.BORDER, 0.45),
        accent = theme.RED,
        accent_w = 2,
        rounding = theme.ROUND,
    })

    local title = "Staff In Lobby"
    if #rows > 1 then
        title = title .. " (" .. #rows .. ")"
    end
    draw_util.text(x + pad, y + 6, title, theme.TEXT, 12)

    local div_y = y + title_h
    if draw.line then
        draw.line(x + pad, div_y, x + width - pad, div_y, theme.alpha(theme.BORDER, 0.55), 1)
    end

    local ry = div_y + 6
    if #rows == 0 then
        draw.text(x + pad + 12, ry, "No staff detected", theme.TEXT_MUTED, 11)
        return
    end

    for i = 1, #rows do
        local row = rows[i]
        local accent = row.accent or theme.role_accent(row.role)

        if i > 1 and draw.line then
            draw.line(x + pad, ry - 4, x + width - pad, ry - 4, theme.alpha(theme.BORDER, 0.22), 1)
        end

        if draw.circle_filled then
            draw.circle_filled(x + pad + 3, ry + 7, 3, accent, 8)
        end

        local name = row.name or "?"
        if #name > 20 then name = name:sub(1, 18) .. ".." end
        draw.text(x + pad + 12, ry, name, theme.TEXT, 13)

        local role = row.role or "Staff"
        if #role > 24 then role = role:sub(1, 22) .. ".." end
        draw.text(x + pad + 12, ry + 15, role, accent, 11)

        if row.meta and row.meta ~= "" then
            draw.text(x + pad + 12, ry + 28, row.meta, theme.TEXT_MUTED, 10)
        end

        ry = ry + row_h
    end
end

function M.draw()
    M.draw_mod_markers()

    if not settings.enabled(P) then return end

    M.reconcile_active()

    local sw, _ = draw_util.screen_size()
    local panel_w = 260
    local x = sw - panel_w - 16
    local rows = build_staff_rows()

    draw_staff_panel(x, 72, panel_w, rows)
end

return M

end)()

-- ── features/utility/config.lua ──
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
    "features.visuals.target_overlay",
    "features.visuals.crosshair",
    "features.visuals.brainrot_esp",
    "features.world.world_esp",
    "features.world.loot_esp",
    "features.world.npc_esp",
    "features.world.base_esp",
    "features.radar.tactical_map",
    "features.radar.waypoints",
    "features.utility.mod_checker",
    "features.combat.perfect_farm",
    "features.movement.exploits",
    "features.movement.noclip",
    "features.movement.fling",
    "features.movement.desync",
    "features.utility.config",
}

function M.register_all()
    if M._menu_registered then return end

    menu_util.ensure_groups()

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
                debug.error_once("menu:" .. path, err)
            end
        end
    end

    M._menu_registered = true
    if April and April.debug then
        debug.log("Menu: " .. registered .. " sections")
    end

    pcall(function()
        local mod = April.require("features.utility.mod_checker")
        if mod.init then mod.init() end
    end)

    pcall(function()
        local mod = April.require("features.visuals.brainrot_esp")
        if mod.init then mod.init() end
    end)
end

function M.setup_scans()
    local settings = April.require("core.settings")
    local cache = April.require("core.cache")
    local iscan = April.require("core.incremental_scan")
    local world_esp = April.require("features.world.world_esp")
    local loot_esp = April.require("features.world.loot_esp")
    local base_esp = April.require("features.world.base_esp")
    local npc_esp = April.require("features.world.npc_esp")

    iscan.configure({ budget_ms = 6, items_per_step = 18 })

    local SCAN_MS = cache.WORKSPACE_SCAN_MS or 1000

    local function map_on(layer)
        return function()
            if not settings.enabled("april_map_enabled") then return false end
            return settings.enabled("april_map_show_" .. layer)
        end
    end

    iscan.register("world", SCAN_MS, function()
        return settings.enabled("april_world_enabled") or map_on("world")()
    end, world_esp.begin_static_scan, world_esp.step_static_scan, world_esp.complete_static_scan, 0)

    iscan.register("world_dynamic", SCAN_MS, function()
        if not settings.enabled("april_world_enabled") then return false end
        return settings.enabled("april_deer")
            or settings.enabled("april_boar")
            or settings.enabled("april_wolf")
    end, world_esp.begin_dynamic_scan, world_esp.step_dynamic_scan, world_esp.complete_dynamic_scan, 120)

    iscan.register("loot", SCAN_MS, function()
        return settings.enabled("april_loot_enabled") or map_on("loot")()
    end, loot_esp.begin_static_scan, loot_esp.step_static_scan, loot_esp.complete_static_scan, 240)

    iscan.register("loot_drops", SCAN_MS, function()
        if settings.enabled("april_loot_enabled") then
            return settings.enabled("april_dropped_item")
        end
        return map_on("loot")()
    end, loot_esp.begin_drops_scan, loot_esp.step_drops_scan, loot_esp.complete_drops_scan, 360)

    iscan.register("base", SCAN_MS, function()
        return settings.enabled("april_base_enabled") or map_on("base")()
    end, base_esp.begin_scan, base_esp.step_scan, base_esp.complete_scan, 480)

    iscan.register("npcs", SCAN_MS, function()
        if settings.enabled("april_npc_enabled") then return true end
        return map_on("npcs")()
    end, npc_esp.begin_scan, npc_esp.step_scan, npc_esp.complete_scan, 600)
end

function M.update(dt)
    bootstrap.tick()

    local weapons = April.require("game.weapons")
    weapons.tick()

    local runservice = April.require("core.runservice")
    runservice.dispatch(dt)

    scheduler.tick()
    April.require("core.incremental_scan").tick()
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
    M.setup_player_hooks()

    pcall(function()
        April.require("features.utility.config").try_autoload()
    end)

    return true
end

function M.setup_player_hooks()
    local mod = April.require("features.utility.mod_checker")

    _G.on_player_added = function(p)
        debug.guard("on_player_added", mod.on_player_added, p)
    end

    _G.on_player_removed = function(p)
        debug.guard("on_player_removed", mod.on_player_removed, p)
    end
end

return M

end)()

-- ── app.lua ──
April._mods["app"] = (function()
local tabs = April.require("menu.tabs")
local debug = April.require("core.debug")
local notify = April.require("core.notify")

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

    pcall(function()
        April.require("core.feature_bind").tick()
    end)

    local dt = 0.016
    if utility and utility.get_delta_time then
        dt = utility.get_delta_time()
    end

    debug.guard("tabs.update", tabs.update, dt)
    debug.guard("tabs.draw", tabs.draw)
    debug.guard("notify.draw", notify.draw)
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

    April.require("core.movement_ctrl").install()
    April.require("features.movement.fling").install()

    April._init_ok = true

    local c = caps.probe()
    if c.fallen_gc then
        local gc = April.require("game.gc_weapon_mods")
        gc.probe_on_load()
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
end
