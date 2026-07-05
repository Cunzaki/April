--[[
    April — Fallen Survival for Project Vector
    https://github.com/Cunzaki/April
    Built: 2026-07-05T23:00:02.274Z
]]

April = {
    version = "3.23.0",
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

        local name = row.name or "?"
        if #name > 20 then name = name:sub(1, 18) .. ".." end
        draw.text(x + pad + 12, ry, name, M.TEXT, 13)

        local role = row.role or "Staff"
        if #role > 24 then role = role:sub(1, 22) .. ".." end
        draw.text(x + pad + 12, ry + 15, role, accent, 11)

        if row.meta and row.meta ~= "" then
            draw.text(x + pad + 12, ry + 28, row.meta, M.TEXT_MUTED, 10)
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
    msg = tostring(msg)
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
        debug.warn_once("img:" .. key, "load failed — " .. entry.url)
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
    COMBAT = "Combat",
    VISUALS = "Visuals",
    WORLD = "World",
    RADAR = "Radar",
    MISC = "Misc",
    CONFIG = "Config",
}

M.G_SIDE = {
    [M.G.COMBAT] = "left",
    [M.G.VISUALS] = "right",
    [M.G.WORLD] = "left",
    [M.G.RADAR] = "right",
    [M.G.MISC] = "left",
    [M.G.CONFIG] = "right",
}

M._tab_ready = false
M._groups = {}
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

function M.sync_masters()
    for master_id in pairs(M._master_hooked) do
        local show = settings_mod().enabled(master_id)
        for _, id in ipairs(M._master_children[master_id] or {}) do
            set_visible(id, show)
        end
    end
    for i = 1, #M._when_rules do
        local rule = M._when_rules[i]
        if rule.sync then rule.sync() end
    end
end

function M.bind_master(master_id, child_ids)
    if not master_id or not child_ids then return end
    M._master_children[master_id] = add_child_ids(M._master_children[master_id], child_ids)

    if M._master_hooked[master_id] then return end
    M._master_hooked[master_id] = true

    local function sync()
        local show = settings_mod().enabled(master_id)
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
}

local MENU_KEYS = {
    "april_esp_text_size",
    "april_tung_esp_enabled", "april_tung_esp_max_dist",
        "april_target_overlay", "april_target_overlay_fov", "april_target_overlay_gear_size", "april_target_overlay_top",
    "april_crosshair_enabled", "april_crosshair_type", "april_crosshair_size", "april_crosshair_gap",
    "april_crosshair_thickness", "april_crosshair_color", "april_crosshair_dot", "april_crosshair_outline",
    "april_crosshair_rainbow", "april_crosshair_rainbow_speed",
    "april_aimbot_enabled", "april_aimbot_fov", "april_aimbot_bone", "april_aimbot_priority",
    "april_aimbot_sticky", "april_aimbot_visible", "april_aimbot_smooth",
    "april_aimbot_draw_fov", "april_aimbot_fov_fill", "april_aimbot_target_line",
    "april_gunmods_enabled", "april_gm_recoil", "april_gm_recoil_pct", "april_gm_spread", "april_gm_spread_pct",
    "april_gm_sway", "april_gm_fire_rate", "april_gm_fire_rate_mult",
    "april_gm_speed", "april_gm_speed_mult", "april_gm_range", "april_gm_range_mult",
    "april_combat_skip_downed",
    "april_farm_helper", "april_farm_radius", "april_farm_smooth",
    "april_world_enabled", "april_stone_node", "april_metal_node", "april_phosphate_node",
    "april_corn_plant", "april_tomato_plant", "april_pumpkin_plant", "april_lemon_plant",
    "april_raspberry_plant", "april_blueberry_plant", "april_wool_plant", "april_hemp_plant",
    "april_deer", "april_boar", "april_wolf",
    "april_world_boxes", "april_world_show_name", "april_world_show_distance", "april_world_range",
    "april_loot_enabled", "april_dropped_item", "april_wooden_crate", "april_metal_crate",
    "april_steel_crate", "april_food_crate", "april_timed_crate", "april_care_package", "april_btr_crate",
    "april_body_bag", "april_sleeper", "april_trash_can", "april_oil_barrel",
    "april_small_egg", "april_medium_egg", "april_large_egg",
    "april_wooden_boat", "april_military_boat", "april_flycopter",
    "april_loot_boxes", "april_loot_show_name", "april_loot_show_distance", "april_loot_range",
    "april_npc_enabled", "april_npc_soldiers", "april_npc_bosses", "april_npc_box_mode",
    "april_npc_health", "april_npc_skeleton",
    "april_npc_offscreen", "april_npc_show_name", "april_npc_show_distance", "april_npc_range",
    "april_base_enabled", "april_base_cabinet", "april_storage_cabinet", "april_small_box", "april_large_box",
    "april_sleeping_bag", "april_auto_turret", "april_shotgun_turret",
    "april_wooden_door", "april_wooden_double_door", "april_salvaged_door", "april_metal_door",
    "april_metal_double_door", "april_steel_door", "april_steel_double_door",
    "april_garage_door", "april_trap_door", "april_triangle_trap_door",
    "april_small_battery", "april_medium_battery", "april_large_battery",
    "april_solar_panel", "april_windmill",
    "april_base_boxes", "april_base_show_name", "april_base_show_distance", "april_base_range",
    "april_waypoints_enabled", "april_wp_dist", "april_wp_beacon", "april_wp_beacon_h",
    "april_wp_draw", "april_wp_slot",
    "april_map_enabled", "april_map_mode", "april_map_zoom", "april_map_size", "april_map_icon_scale",
    "april_map_show_players", "april_map_show_npcs", "april_map_show_loot", "april_map_show_world",
    "april_map_show_base", "april_map_show_waypoints", "april_map_show_local",
    "april_map_labels", "april_map_coords", "april_map_compass", "april_map_tooltips",
    "april_noclip_enabled", "april_noclip_mode", "april_noclip_speed",
    "april_omnisprint_enabled", "april_spider_enabled", "april_spider_speed",
    "april_mod_checker_enabled", "april_mod_checker_interval",
    "april_hide_local_name",
}

local COLOR_KEYS = {
    "april_crosshair_color", "april_crosshair_dot", "april_crosshair_outline",
    "april_aimbot_enabled", "april_aimbot_draw_fov", "april_aimbot_target_line",
    "april_stone_node", "april_metal_node", "april_phosphate_node", "april_corn_plant", "april_tomato_plant",
    "april_pumpkin_plant", "april_lemon_plant", "april_raspberry_plant", "april_blueberry_plant",
    "april_wool_plant", "april_hemp_plant", "april_deer", "april_boar", "april_wolf",
    "april_dropped_item", "april_wooden_crate", "april_metal_crate", "april_steel_crate", "april_food_crate",
    "april_timed_crate", "april_care_package", "april_btr_crate", "april_body_bag", "april_sleeper",
    "april_trash_can", "april_oil_barrel", "april_small_egg", "april_medium_egg", "april_large_egg",
    "april_wooden_boat", "april_military_boat", "april_flycopter",
    "april_npc_soldiers", "april_npc_bosses", "april_npc_skeleton", "april_npc_offscreen",
    "april_base_cabinet", "april_storage_cabinet", "april_small_box", "april_large_box",
    "april_sleeping_bag", "april_auto_turret", "april_shotgun_turret", "april_wooden_door",
    "april_wooden_double_door", "april_salvaged_door", "april_metal_door", "april_metal_double_door",
    "april_steel_door", "april_steel_double_door", "april_garage_door", "april_trap_door",
    "april_triangle_trap_door", "april_small_battery", "april_medium_battery", "april_large_battery",
    "april_solar_panel", "april_windmill",
    "april_wp_draw", "april_map_bg", "april_map_grid", "april_map_player_col", "april_map_npc_col", "april_map_loot_col",
    "april_map_world_col", "april_map_base_col", "april_map_wp_col", "april_map_local", "april_map_compass",
}

local HOTKEY_KEYS = {
    "april_tung_esp_enabled", "april_crosshair_enabled", "april_aimbot_enabled", "april_map_enabled",
    "april_waypoints_enabled", "april_noclip_enabled", "april_omnisprint_enabled", "april_spider_enabled",
    "april_world_enabled", "april_loot_enabled", "april_npc_enabled", "april_base_enabled",
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
                        menu.set_key(id, vk)
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
    Attachment = true,
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

function M.get_by_id(id)
    return item_catalog.get(id)
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

local MELEE_NAME_HINTS = {
    "hatchet", "pickaxe", "spear", "machete", "knife", "sword",
    "bone tool", "hammer", "crowbar",
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
    return M.get_held_ranged_weapon_name() ~= nil
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

-- ── game/player_gear.lua ──
April._mods["game.player_gear"] = (function()
local env = April.require("core.env")
local items = April.require("game.items")
local item_catalog = April.require("game.item_catalog")
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

local function add_armor_piece(out, seen, piece)
    if not piece or not piece.name then return end
    if seen[piece.name] then return end
    seen[piece.name] = true
    table.insert(out, piece)
end

local function add_held_piece(out, label)
    if not label or label == "" then return false end

    local piece = items.resolve_item_label(label)
    if not piece then
        local base, variant = parse_variant_name(label)
        piece = items.make_piece(base or label, variant)
    end

    out.held = piece
    return true
end

local function try_armor_model(out, seen, name)
    if not name then return end

    if name:sub(1, 6) == "Armor_" then
        local piece = items.resolve_armor_model(name)
        add_armor_piece(out, seen, piece)
        return
    end

    if name:sub(1, 6) == "Armor:" then
        local piece = items.resolve_item_label(name:sub(7))
        add_armor_piece(out, seen, piece)
    end
end

local function try_held_from_name(out, name)
    if not name or name == "" or out.held then return end

    if add_held_piece(out, name) then return end

    local base, variant = parse_variant_name(name)
    if weapons.is_weapon_name(base or name) or items.is_held_display(base or name) then
        add_held_piece(out, name)
    end
end

local function scan_armor_attributes(char, out, seen)
    for _, attr in ipairs(ARMOR_ATTRIBUTES) do
        local key = "Armor_" .. attr
        local val = read_attribute(char, key)
        if val then
            if attr == "ResistWet" then
                if seen["Hazmat Suit"] or seen["Wetsuit"] then
                    goto continue_attr
                end
            end

            local row = item_catalog.get_by_attribute(attr)
            if row and row.name then
                add_armor_piece(out, seen, items.make_piece(row.name, nil))
            end
        end

        ::continue_attr::
    end
end

local function scan_character_tree(char, out, seen, depth)
    if not env.is_valid(char) or depth > 3 then return end

    local children = env.safe_call(function() return char:get_children() end) or {}
    for _, child in ipairs(children) do
        if not env.is_valid(child) then goto continue end

        local name = child.Name or child.name
        if not name or name == "" then goto continue end

        local cn = child.ClassName or child.class_name

        if cn == "Model" then
            if name:sub(1, 6) == "Armor_" or name:sub(1, 6) == "Armor:" then
                try_armor_model(out, seen, name)
            end
        end

        if not out.held then
            if cn == "Tool" then
                add_held_piece(out, name)
            elseif items.is_held_display(name) or weapons.is_weapon_name(name) then
                try_held_from_name(out, name)
            end
        end

        if cn == "Model" or cn == "Folder" then
            scan_character_tree(child, out, seen, depth + 1)
        end

        ::continue::
    end
end

function M.scan_player(player)
    local out = {
        held = nil,
        armor = {},
    }

    if not player then return out end

    if player.tool_name and player.tool_name ~= "" then
        add_held_piece(out, player.tool_name)
    end

    local char = player.character
    if not char or not env.is_valid(char) then return out end

    local seen = {}
    scan_character_tree(char, out, seen, 0)
    scan_armor_attributes(char, out, seen)

    return out
end

return M

end)()

-- ── game/player_state.lua ──
April._mods["game.player_state"] = (function()
--[[ Fallen player state — Humanoid:GetAttribute("Downed") from game scripts. ]]

local settings = April.require("core.settings")
local env = April.require("core.env")

local M = {}

local SETTING = "april_combat_skip_downed"

function M.skip_downed_enabled()
    return settings.bool(SETTING, true)
end

function M.setting_key()
    return SETTING
end

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
    if M.skip_downed_enabled() and M.is_downed(player) then return false end
    return true
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

local function write_payload(keys, payload)
    -- API.md: applygc(keys, values) — two-arg form (required on current Vector)
    local ok, err = pcall(applygc, keys, payload)
    if ok then return true end

    ok, err = pcall(applygc, M.WEAPON_FIND_KEYS, payload)
    if ok then return true end

    debug.error_once("gun_mods:applygc", err)
    return false
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

    local ok_refresh, err_refresh = pcall(refreshgc)
    if not ok_refresh then
        debug.error_once("gun_mods:refreshgc", err_refresh)
        return false, 0, "refreshgc failed"
    end

    local patch_keys = keys_for_payload(payload)
    local count = warm_nodes(patch_keys)
    M._last_node_count = count

    if count <= 0 then
        debug.warn_once("gun_mods:nodes", "No GC nodes — equip a gun in-game, then toggle Gun Mods")
        return false, 0, "No nodes — equip a gun first"
    end

    if not write_payload(patch_keys, payload) then
        return false, count, "applygc failed"
    end

    return true, count, string.format("%d node(s) — mods active", count)
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

-- ── game/gun_mod_profiles.lua ──
April._mods["game.gun_mod_profiles"] = (function()
--[[ Global gun mod values — map menu sliders to applygc keys. ]]

local settings = April.require("core.settings")

local M = {}

local function pct_to_neg_mult(pct)
    pct = math.max(0, math.min(100, pct or 0))
    if pct >= 100 then return -1 end
    return -(pct / 100)
end

function M.has_gc_mods()
    return settings.bool("april_gm_recoil", false)
        or settings.bool("april_gm_spread", false)
        or settings.bool("april_gm_sway", false)
        or settings.bool("april_gm_fire_rate", false)
        or settings.bool("april_gm_speed", false)
        or settings.bool("april_gm_range", false)
end

function M.build_mods()
    local mods = {}

    if settings.bool("april_gm_recoil", false) then
        mods.RecoilMult = pct_to_neg_mult(settings.num("april_gm_recoil_pct", 100))
    end
    if settings.bool("april_gm_spread", false) then
        local m = pct_to_neg_mult(settings.num("april_gm_spread_pct", 100))
        mods.AimSpreadMult = m
        mods.HipSpreadMult = m
    end
    if settings.bool("april_gm_sway", false) then
        mods.SwayMult = -1
    end
    if settings.bool("april_gm_fire_rate", false) then
        mods.FireRateMult = settings.num("april_gm_fire_rate_mult", 1.5)
    end
    if settings.bool("april_gm_speed", false) then
        mods.SpeedMult = settings.num("april_gm_speed_mult", 100)
    end
    if settings.bool("april_gm_range", false) then
        mods.RangeMult = settings.num("april_gm_range_mult", 10)
    end

    return mods
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
    { id = "april_auto_turret", label = "Auto Turret", color = { 1, 0.2, 0.2, 1 } },
    { id = "april_shotgun_turret", label = "Shotgun Turret", color = { 1, 0.35, 0.2, 1 } },
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
--[[ Aimbot menu — prediction/weapon stats always on (no toggles). ]]

local menu_util = April.require("core.menu_util")
local esp_util = April.require("core.esp_util")

local M = {}

function M.register_filters(T, G, parent_id)
    local root = menu_util.parent(parent_id)
    menu_util.section(T, G, "Target Filters")
    menu.add_checkbox(T, G, "april_combat_skip_downed", "Ignore Downed Players", true, root)
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

    menu.add_separator(T, G)
    menu.add_checkbox(T, G, p .. "draw_fov", "Draw FOV Circle", false, menu_util.parent(parent_id, { colorpicker = opts.fov_color or { 1, 1, 1, 1 } }))
    menu.add_checkbox(T, G, p .. "fov_fill", "Fill FOV", false, root)
    menu.add_checkbox(T, G, p .. "target_line", "Target Line", false, menu_util.parent(parent_id, { colorpicker = opts.line_color or { 1, 0.2, 0.2, 1 } }))
end

return M

end)()

-- ── features/combat/perfect_farm.lua ──
April._mods["features.combat.perfect_farm"] = (function()
--[[
    Farm helper — smooth camera aim at NodeSpark / TreeX weak spots (Rust-style).
    When within range of a node/tree that has an active spark, camera.look_at keeps
    crosshair on the weak spot so melee raycasts register tier-3 hits.
]]

local settings = April.require("core.settings")
local env = April.require("core.env")
local folders = April.require("game.folders")
local math_util = April.require("core.math_util")
local menu_util = April.require("core.menu_util")

local M = {}

local P = "april_farm_helper"
local P_RADIUS = "april_farm_radius"
local P_SMOOTH = "april_farm_smooth"

local spark_parts = {}
local next_scan_ms = 0
local SCAN_MS = 350

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

    local root = env.safe_call(function()
        return char:find_first_child("HumanoidRootPart")
            or char:FindFirstChild("HumanoidRootPart")
    end)
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

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.COMBAT)
    local root = menu_util.parent(P)

    menu_util.section(T, G.COMBAT, "Farming")
    menu.add_checkbox(T, G.COMBAT, P, "Farm Helper", false)
    menu.add_slider_int(T, G.COMBAT, P_RADIUS, "Farm Range (studs)", 1, 15, 5, root)
    menu.add_slider_int(T, G.COMBAT, P_SMOOTH, "Aim Smoothness", 1, 30, 8, root)
    menu_util.bind_master(P, { P_RADIUS, P_SMOOTH })
end

function M.update(_dt)
    if not settings.bool(P, false) then return end
    if not camera or not camera.look_at then return end

    local lp = env.get_local_player()
    local pos = player_position(lp)
    if not pos then return end

    refresh_sparks()

    local radius = settings.num(P_RADIUS, 5)
    if radius <= 0 then return end

    local target = nearest_spark(pos, radius)
    if not target then return end

    local aim = part_position(target)
    if not aim then return end

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
local gc = April.require("game.gc_weapon_mods")
local env = April.require("core.env")

local M = {}
local P = "april_gunmods_enabled"
local REJOIN_GC_DELAY_MS = 20000

M._apply_dirty = false
M._last_hash = ""
M._defer_until = 0
M._session_id = nil
M._was_in_match = false
M._gc_redo_at = 0

local GM_KEYS = {
    "april_gm_recoil", "april_gm_recoil_pct",
    "april_gm_spread", "april_gm_spread_pct",
    "april_gm_sway",
    "april_gm_fire_rate", "april_gm_fire_rate_mult",
    "april_gm_speed", "april_gm_speed_mult",
    "april_gm_range", "april_gm_range_mult",
}

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

local function mods_hash(mods)
    local parts = {}
    for k, v in pairs(mods) do
        table.insert(parts, k .. "=" .. tostring(v))
    end
    table.sort(parts)
    return table.concat(parts, ";")
end

local function schedule_apply(delay_ms)
    M._apply_dirty = true
    local now = tick_ms()
    local until_ms = now + (delay_ms or 400)
    if until_ms > M._defer_until then
        M._defer_until = until_ms
    end
end

local function schedule_session_gc_refresh()
    if not settings.bool(P, false) then return end
    M._last_hash = ""
    M._apply_dirty = true
    M._gc_redo_at = tick_ms() + REJOIN_GC_DELAY_MS
end

function M.on_session_changed()
    schedule_session_gc_refresh()
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.COMBAT)
    local root = menu_util.parent(P)

    menu_util.section(T, G.COMBAT, "Gun Mods")
    menu.add_checkbox(T, G.COMBAT, P, "Enable Gun Mods", false, { key = 0 })

    menu_util.section(T, G.COMBAT, "Target Filters")
    menu.add_checkbox(T, G.COMBAT, "april_combat_skip_downed", "Ignore Downed Players", true, root)

    menu.add_checkbox(T, G.COMBAT, "april_gm_recoil", "Gun Recoil Mod", false, root)
    menu.add_slider_int(T, G.COMBAT, "april_gm_recoil_pct", "Recoil Reduction %", 0, 100, 100, root)

    menu.add_checkbox(T, G.COMBAT, "april_gm_spread", "Gun Spread Mod", false, root)
    menu.add_slider_int(T, G.COMBAT, "april_gm_spread_pct", "Spread Reduction %", 0, 100, 100, root)

    menu.add_checkbox(T, G.COMBAT, "april_gm_sway", "Gun No Sway", false, root)

    menu.add_checkbox(T, G.COMBAT, "april_gm_fire_rate", "Gun Fire Rate Mod", false, root)
    menu.add_slider_float(T, G.COMBAT, "april_gm_fire_rate_mult", "Fire Rate Multiplier", 1.0, 3.0, 1.5, "%.2f", root)

    menu.add_checkbox(T, G.COMBAT, "april_gm_speed", "Gun Bullet Speed Mod", false, root)
    menu.add_slider_int(T, G.COMBAT, "april_gm_speed_mult", "SpeedMult (100 = instant)", 0, 100, 100, root)

    menu.add_checkbox(T, G.COMBAT, "april_gm_range", "Gun Range Mod", false, root)
    menu.add_slider_int(T, G.COMBAT, "april_gm_range_mult", "RangeMult", 1, 20, 10, root)

    menu_util.bind_master(P, {
        "april_combat_skip_downed",
        "april_gm_recoil", "april_gm_recoil_pct",
        "april_gm_spread", "april_gm_spread_pct",
        "april_gm_sway",
        "april_gm_fire_rate", "april_gm_fire_rate_mult",
        "april_gm_speed", "april_gm_speed_mult",
        "april_gm_range", "april_gm_range_mult",
    })

    settings.on_change(P, function()
        if settings.bool(P, false) then
            schedule_apply(500)
        else
            M._apply_dirty = false
            M._last_hash = ""
            M._defer_until = 0
            M._gc_redo_at = 0
        end
    end)

    for _, id in ipairs(GM_KEYS) do
        settings.on_change(id, function()
            if settings.bool(P, false) then
                schedule_apply(250)
            end
        end)
    end
end

function M.try_apply()
    if not settings.bool(P, false) then
        return false
    end

    if not profiles.has_gc_mods() then
        M._apply_dirty = false
        return false
    end

    local mods = profiles.build_mods()
    if not next(mods) then
        M._apply_dirty = false
        return false
    end

    local hash = mods_hash(mods)
    if not M._apply_dirty and hash == M._last_hash then
        return true
    end

    local ok = gc.apply_weapon(mods)
    if ok then
        M._last_hash = hash
        M._apply_dirty = false
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

function M.update(_dt)
    M.tick_session()

    if not settings.bool(P, false) then return end

    local now = tick_ms()

    if M._gc_redo_at > 0 and now >= M._gc_redo_at then
        M._gc_redo_at = 0
        if in_match() then
            gc.refresh_cache()
            M._apply_dirty = true
            M._defer_until = now
        end
    end

    if not M._apply_dirty then return end
    if now < M._defer_until then return end

    M.try_apply()
end

function M.on_weapon_changed(_name) end

function M.on_modules_ready()
    if settings.bool(P, false) then
        schedule_apply(500)
    end
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
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)
    local root = menu_util.parent(P)

    menu.add_checkbox(T, G.VISUALS, P, "Tung ESP", false, { key = 0 })
    menu.add_slider_int(T, G.VISUALS, "april_tung_esp_max_dist", "Tung ESP Max Distance", 50, 5000, 1000, root)
    menu_util.bind_master(P, { "april_tung_esp_max_dist" })
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
    if not settings.bool(P, false) then return end

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

local M = {}

local P = "april_target_overlay"
local GEAR_SLOTS = 7

local gear_cache = {}
local GEAR_TTL = 150

M._target = nil
M._layout = nil

local SLOT_BG = { 0.14, 0.14, 0.16, 0.72 }
local HELD_BG = { 0.2, 0.2, 0.22, 0.85 }
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

    if type(piece) == "string" then
        local resolved = items.resolve_item_label(piece)
        if resolved and resolved.asset_id then
            local key = img_key("item_", resolved.asset_id)
            image_cache.ensure(key, resolved.asset_id)
            return key
        end
    end

    return nil
end

local function preload_layout_images(layout)
    if not layout then return end
    if layout.held then
        local key = resolve_image_key(layout.held)
        if key then image_cache.begin_load(key) end
    end
    for i = 1, layout.filled or 0 do
        local piece = layout.packed[i]
        local key = resolve_image_key(piece)
        if key then image_cache.begin_load(key) end
    end
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

local function build_layout(gear, gear_sz)
    local held = gear and gear.held
    local packed = pack_gear(gear and gear.armor)
    local held_sz = math.floor(gear_sz * 1.28)
    local gap = 5
    local row_w = GEAR_SLOTS * gear_sz + (GEAR_SLOTS - 1) * gap

    return {
        held = held,
        packed = packed,
        filled = #packed,
        gear_sz = gear_sz,
        held_sz = held_sz,
        gap = gap,
        row_w = row_w,
        row_gap = 8,
        name_fs = 11,
    }
end

local function held_piece(held)
    if not held then return nil end
    if type(held) == "table" then return held end
    return { name = held }
end

local function draw_slot(x, y, size, key, piece, style)
    local pad = 3
    local bg = SLOT_BG
    if style == "held" then
        bg = HELD_BG
    elseif style == "empty" then
        bg = EMPTY_BG
    end

    draw.rect_filled(x, y, size, size, bg, ROUND)
    if style == "empty" and draw.rect then
        draw.rect(x, y, size, size, EMPTY_EDGE, ROUND, 1)
    end

    if not piece then return end

    if key then
        image_cache.begin_load(key)
        if image_cache.draw_fit(key, x + pad, y + pad, size - pad * 2, size - pad * 2) then
            return
        end
        local st = image_cache.state(key)
        if st == "loading" or st == "none" then
            return
        end
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

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)

    menu_util.section(T, G.VISUALS, "Target Gear")
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

    if target and player_state.is_combat_target(target) then
        M._target = target
        M._layout = build_layout(get_gear(target), gear_sz)
        preload_layout_images(M._layout)
    else
        M._target = nil
        M._layout = nil
    end
end

function M.update(_dt)
    M.refresh_target()
end

function M.draw()
    if not settings.enabled(P) then return end
    if not draw or not draw.text or not draw.rect_filled then return end

    M.refresh_target()

    local target = M._target
    local layout = M._layout
    if not target or not layout then return end

    local sw, _ = draw_util.screen_size()
    local top = settings.num(P .. "_top", 88)
    local cx = sw * 0.5

    local name = target.display_name or target.name or "Unknown"
    local nw = select(1, draw.get_text_size(name, layout.name_fs))
    draw.text(cx - nw * 0.5, top, name, { 1, 1, 1, 1 }, layout.name_fs)

    local y = top + layout.name_fs + 6

    local held = held_piece(layout.held)
    local held_key = held and resolve_image_key(held) or nil
    draw_slot(cx - layout.held_sz * 0.5, y, layout.held_sz, held_key, held, held and "held" or "empty")
    y = y + layout.held_sz + layout.row_gap

    local start_x = cx - layout.row_w * 0.5
    for i = 1, GEAR_SLOTS do
        local piece = i <= layout.filled and layout.packed[i] or nil
        local key = piece and resolve_image_key(piece) or nil
        local sx = start_x + (i - 1) * (layout.gear_sz + layout.gap)
        draw_slot(sx, y, layout.gear_sz, key, piece, piece and "gear" or "empty")
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

    menu_util.bind_master(P, {
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
local POS_REFRESH_BATCH = 10

M._static = {}
M._dynamic = {}
M._pos_idx = 0

local function rebuild_cache()
    cache.world = {}
    for _, entry in ipairs(M._static) do
        table.insert(cache.world, entry)
    end
    for _, entry in ipairs(M._dynamic) do
        table.insert(cache.world, entry)
    end
end

local function refresh_dynamic_positions()
    local n = #M._dynamic
    if n == 0 then return end

    for _ = 1, POS_REFRESH_BATCH do
        M._pos_idx = (M._pos_idx % n) + 1
        local entry = M._dynamic[M._pos_idx]
        if entry and env.is_valid(entry.inst) then
            esp_scan.refresh_entry_position(entry)
        end
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    menu.add_checkbox(T, G.WORLD, P, "Enable World ESP", false, { key = 0 })
    for _, t in ipairs(maps.WORLD_TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
    end
    menu.add_checkbox(T, G.WORLD, "april_world_boxes", "World 3D Boxes", false, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_world_show_name", "World Show Name", true, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_world_show_distance", "World Show Distance", true, { parent = P })
    menu.add_slider_int(T, G.WORLD, "april_world_range", "World Range", 50, 2000, 500, { parent = P })

    local child_ids = { "april_world_boxes", "april_world_show_name", "april_world_show_distance", "april_world_range" }
    for _, t in ipairs(maps.WORLD_TOGGLES) do
        child_ids[#child_ids + 1] = t.id
    end
    menu_util.bind_master(P, child_ids)
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
    if #M._dynamic > 0 then
        refresh_dynamic_positions()
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
            if entry.dynamic then
                esp_scan.refresh_entry_position(entry)
            end
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
local POS_REFRESH_BATCH = 12

M._static = {}
M._drops = {}
M._pos_idx = 0

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

local function refresh_dynamic_positions()
    local n = #M._drops
    if n == 0 then return end

    for _ = 1, POS_REFRESH_BATCH do
        M._pos_idx = (M._pos_idx % n) + 1
        local entry = M._drops[M._pos_idx]
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
    menu_util.section(T, G.WORLD, "Loot ESP")
    menu.add_checkbox(T, G.WORLD, P, "Enable Loot ESP", false, { key = 0 })
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
    menu_util.bind_master(P, child_ids)
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
    if not settings.enabled(P) then return end
    if #M._drops > 0 then
        refresh_dynamic_positions()
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
            if entry.dynamic then
                esp_scan.refresh_entry_position(entry)
            end
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
local esp_scan = April.require("game.esp_scan")

local M = {}
local P = "april_base_enabled"

local function resolve_model(container, type_name)
    if not env.is_valid(container) then return nil end

    if type_name == "Sleeping Bag" then
        local bag = env.safe_call(function()
            return container:find_first_child("SleepingBag")
                or container:FindFirstChild("SleepingBag")
                or container:find_first_child("Sleeping_Bag")
                or container:FindFirstChild("Sleeping_Bag")
        end)
        if bag and env.is_valid(bag) then return bag end

        local children = env.safe_call(function() return container:get_children() end) or {}
        for _, child in ipairs(children) do
            local cn = child.ClassName or child.class_name
            if cn == "Model" and env.is_valid(child) then
                return child
            end
        end
    end

    local cn = container.ClassName or container.class_name
    if cn == "Model" then return container end

    if esp_scan.find_main_part(container) then return container end

    local children = env.safe_call(function() return container:get_children() end) or {}
    for _, child in ipairs(children) do
        if env.is_valid(child) then
            local cc = child.ClassName or child.class_name
            if cc == "Model" then return child end
        end
    end

    return container
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    menu_util.section(T, G.WORLD, "Base ESP")
    menu.add_checkbox(T, G.WORLD, P, "Enable Base ESP", false, { key = 0 })
    for _, t in ipairs(maps.BASE_TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
    end
    menu.add_checkbox(T, G.WORLD, "april_base_boxes", "Base 3D Boxes", false, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_base_show_name", "Base Show Name", true, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_base_show_distance", "Base Show Distance", false, { parent = P })
    menu.add_slider_int(T, G.WORLD, "april_base_range", "Base Range", 50, 500, 150, { parent = P })

    local child_ids = { "april_base_boxes", "april_base_show_name", "april_base_show_distance", "april_base_range" }
    for _, t in ipairs(maps.BASE_TOGGLES) do
        child_ids[#child_ids + 1] = t.id
    end
    menu_util.bind_master(P, child_ids)
end

function M.begin_scan()
    return {
        areas = nil,
        ai = 1,
        items = nil,
        ii = 1,
        out = {},
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

        local model = resolve_model(type_folder, type_name)
        if not model or not env.is_valid(model) then goto continue end
        if not esp_scan.find_main_part(model) and not esp_scan.is_part(model) then goto continue end

        table.insert(state.out, esp_scan.make_entry(model, type_name, toggle_id))

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

    menu_util.section(T, G.WORLD, "NPC ESP")
    menu.add_checkbox(T, G.WORLD, P, "Enable NPC ESP", false, { key = 0, colorpicker = { 1, 0.3, 0.3, 1 } })
    menu.add_checkbox(T, G.WORLD, "april_npc_soldiers", "Soldiers", false, menu_util.parent(P, { colorpicker = { 1, 0.3, 0.3, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_bosses", "Bosses (Bruno / Boris / Brutus)", false, menu_util.parent(P, { colorpicker = { 1, 0.5, 0.1, 1 } }))
    menu.add_combo(T, G.WORLD, "april_npc_box_mode", "NPC Box Mode", { "None", "2D", "Corner" }, 0, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_health", "NPC Health Bar", false, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_skeleton", "NPC Skeleton", false, menu_util.parent(P, { colorpicker = { 1, 1, 1, 0.85 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_offscreen", "NPC Offscreen Arrows", false, menu_util.parent(P, { colorpicker = { 1, 0.3, 0.3, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_show_name", "NPC Show Name", true, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_show_distance", "NPC Show Distance", true, root)
    menu.add_slider_int(T, G.WORLD, "april_npc_range", "NPC Range", 50, 2000, 500, root)

    menu_util.bind_master(P, {
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
    if not settings.bool(P, false) then return end

    local list = collect_draw_targets()
    local n = #list
    if n == 0 then return end

    for _ = 1, POS_REFRESH_BATCH do
        M._pos_idx = (M._pos_idx % n) + 1
        refresh_npc_position(list[M._pos_idx])
    end
end

function M.draw()
    if not settings.bool(P, false) then return end

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
local settings = April.require("core.settings")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_noclip_enabled"
local OMNISPRINT_SPEED = 16

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu.add_checkbox(T, G.MISC, "april_noclip_enabled", "Noclip", false, { key = 0x12 })
    menu.add_combo(T, G.MISC, "april_noclip_mode", "Noclip Mode", { "Toggle", "Hold" }, 1, root)
    menu.add_slider_int(T, G.MISC, "april_noclip_speed", "Noclip Speed", 1, 50, 16, root)

    menu.add_checkbox(T, G.MISC, "april_omnisprint_enabled", "Omnisprint", false, { key = 0 })

    menu.add_checkbox(T, G.MISC, "april_spider_enabled", "Spider Climb", false, { key = 0 })
    menu.add_slider_int(T, G.MISC, "april_spider_speed", "Wall Speed", 1, 50, 20, { parent = "april_spider_enabled" })

    menu_util.bind_master("april_noclip_enabled", { "april_noclip_mode", "april_noclip_speed" })
    menu_util.bind_master("april_spider_enabled", { "april_spider_speed" })
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

local function key_down(code)
    return input and input.is_key_down and input.is_key_down(code)
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
        if char.find_first_child then
            return char:find_first_child("HumanoidRootPart")
        end
        if char.FindFirstChild then
            return char:FindFirstChild("HumanoidRootPart")
        end
    end)
end

local function movement_vector(lp)
    local md = lp and lp.move_direction
    if md then
        local mx = md.x or md.X or 0
        local mz = md.z or md.Z or 0
        local mag = math.sqrt(mx * mx + mz * mz)
        if mag > 0.05 then
            return mx / mag, mz / mag
        end
    end

    local look = camera and camera.get_look_vector and camera.get_look_vector()
    if not look then return nil end

    local fx, fz = look.x, look.z
    local fmag = math.sqrt(fx * fx + fz * fz)
    if fmag < 0.001 then return nil end
    fx, fz = fx / fmag, fz / fmag
    local rx, rz = -fz, fx

    local mvx, mvz = 0, 0
    if key_down(0x57) then mvx, mvz = mvx + fx, mvz + fz end
    if key_down(0x53) then mvx, mvz = mvx - fx, mvz - fz end
    if key_down(0x41) then mvx, mvz = mvx - rx, mvz - rz end
    if key_down(0x44) then mvx, mvz = mvx + rx, mvz + rz end

    local mmag = math.sqrt(mvx * mvx + mvz * mvz)
    if mmag < 0.001 then return nil end
    return mvx / mmag, mvz / mmag
end

local function apply_velocity(lp, vx, vy, vz)
    pcall(function()
        if lp then
            if Vector3 then
                lp.velocity = Vector3.new(vx, vy, vz)
            else
                lp.velocity = { x = vx, y = vy, z = vz }
            end
        end
    end)

    local root = lp and get_root(lp)
    if root then
        pcall(function()
            if root.set_velocity then
                root:set_velocity(vx, vy, vz)
            elseif part and part.set_velocity then
                part.set_velocity(root, vx, vy, vz)
            end
        end)
    end
end

local function run_omnisprint()
    if not settings.bool("april_omnisprint_enabled", false) then return end

    local lp = entity and entity.get_local_player and entity.get_local_player()
    if not lp then return end

    local ux, uz = movement_vector(lp)
    if not ux then return end

    local vy = 0
    if lp.velocity then
        vy = lp.velocity.y or lp.velocity.Y or 0
    end

    local vx = ux * OMNISPRINT_SPEED
    local vz = uz * OMNISPRINT_SPEED
    apply_velocity(lp, vx, vy, vz)
end

function M.update(dt)
    local lp = env.get_local_player()
    if not lp then return end

    if noclip_active() and lp.character then
        local hum = lp.character:FindFirstChildOfClass("Humanoid")
        if hum and hum.SetProperty then
            pcall(function() hum:SetProperty("PlatformStand", true) end)
        end
    end

    run_omnisprint()
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

    menu.add_checkbox(T, G.RADAR, P, "Enable Waypoints", false, { key = 0 })
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

    menu_util.bind_master(P, {
        "april_wp_dist", "april_wp_beacon", "april_wp_beacon_h", "april_wp_draw",
        "april_wp_slot", "april_wp_set", "april_wp_clear", "april_wp_clear_all",
    })
end

function M.update(dt) end

function M.draw()
    if not settings.bool(P, false) then return end
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

M._offset_x = 0
M._offset_y = 0
M._dragging = false
M._drag_mx = 0
M._drag_my = 0
M._old_off_x = 0
M._old_off_y = 0
M._hover_items = {}

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
    menu.add_checkbox(T, G.RADAR, "april_map_show_players", "Players", true, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_npcs", "NPCs", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_loot", "Loot", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_world", "World Resources", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_base", "Base Parts", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_waypoints", "Waypoints", true, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_local", "Local Player", true, root)

    menu.add_separator(T, G.RADAR)
    menu.add_colorpicker(T, G.RADAR, "april_map_bg", "Background Color", theme.MAP_BG, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_grid", "Grid Color", theme.MAP_GRID, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_player_col", "Player Color", theme.RED, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_npc_col", "NPC Color", theme.ORANGE, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_loot_col", "Loot Color", { 1, 0.85, 0.35, 1 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_world_col", "World Color", theme.GREEN, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_base_col", "Base Color", { 0.55, 0.55, 1, 1 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_wp_col", "Waypoint Color", theme.CYAN, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_local", "Local Player Color", theme.CYAN, root)

    menu.add_separator(T, G.RADAR)
    menu.add_checkbox(T, G.RADAR, "april_map_labels", "Show Labels", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_coords", "Show Coordinates", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_compass", "Compass Overlay", false, menu_util.parent(P, { colorpicker = theme.CYAN }))
    menu.add_checkbox(T, G.RADAR, "april_map_tooltips", "Hover Tooltips (Fullscreen)", false, root)

    menu_util.button(T, G.RADAR, "april_map_recenter", "Recenter Map", function()
        M._offset_x = 0
        M._offset_y = 0
    end)

    menu_util.bind_when(function()
        return settings.enabled(P) and settings.num("april_map_mode", 0) == 1
    end, { "april_map_tooltips", "april_map_recenter" }, { P, "april_map_mode" })

    menu_util.bind_when(function()
        return settings.enabled(P) and settings.num("april_map_mode", 0) == 0
    end, { "april_map_size" }, { P, "april_map_mode" })

    menu_util.bind_master(P, {
        "april_map_mode", "april_map_zoom", "april_map_size", "april_map_icon_scale",
        "april_map_show_players", "april_map_show_npcs", "april_map_show_loot",
        "april_map_show_world", "april_map_show_base", "april_map_show_waypoints",
        "april_map_show_local",
        "april_map_bg", "april_map_grid", "april_map_player_col", "april_map_npc_col",
        "april_map_loot_col", "april_map_world_col", "april_map_base_col",
        "april_map_wp_col", "april_map_local",
        "april_map_labels", "april_map_coords", "april_map_compass", "april_map_tooltips",
    })
end

local function key_active()
    if settings.enabled(P) then return true end
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

local function world_dir_to_screen(dx, dz, yaw, radius)
    local fx, fz, rx, rz = map_basis(yaw)
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
    if not entry then return nil, nil end

    local lx, ly, lz = esp_scan.entry_coords(entry)
    if lx and lz then return lx, lz end

    if entry.lx and entry.lz then return entry.lx, entry.lz end

    if entry.pos then
        return entry.pos.x, entry.pos.z
    end

    local inst = entry.inst
    if inst and env.is_valid(inst) then
        local pos = inst.Position or inst.position
        if pos and pos.x then return pos.x, pos.z end
    end

    return nil, nil
end

local function register_hover(mx, my, scale, label, extra)
    if not label or label == "" then return end
    M._hover_items[#M._hover_items + 1] = {
        mx = mx,
        my = my,
        r = scale + 8,
        label = label,
        extra = extra,
    }
end

local function draw_map_item(wx, wz, col, label, view_x, view_z, map_cx, map_cy, zoom, yaw, scale, x, y, w, h, track_hover, hover_extra)
    if not wx or not wz then return end
    local mx, my = world_to_map(wx, wz, view_x, view_z, map_cx, map_cy, zoom, yaw)
    if mx < x - 8 or mx > x + w + 8 or my < y - 8 or my > y + h + 8 then return end
    draw_dot(mx, my, scale, col)
    if settings.bool("april_map_labels", false) and label and label ~= "" then
        draw_util.text(mx + scale + 2, my - 6, label, col, 10)
    end
    if track_hover then
        register_hover(mx, my, scale, label, hover_extra)
        M._hover_items[#M._hover_items].wx = wx
        M._hover_items[#M._hover_items].wz = wz
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

local function draw_compass_rose(cx, cy, radius, yaw, cmp_col)
    if draw and draw.circle_filled then
        draw.circle_filled(cx, cy, radius, theme.alpha(theme.PANEL_DEEP, 0.82), 24)
    end
    if draw and draw.circle then
        draw.circle(cx, cy, radius, theme.alpha(theme.CYAN, 0.55), 24, 1.5)
    end

    local function marker(lbl, wdx, wdz, col)
        local sx, sy = world_dir_to_screen(wdx, wdz, yaw, radius - 10)
        draw_util.text(cx + sx - 4, cy + sy - 6, lbl, col, 11)
    end

    marker("N", 0, -1, theme.RED)
    marker("S", 0, 1, cmp_col)
    marker("E", 1, 0, cmp_col)
    marker("W", -1, 0, cmp_col)

    if draw and draw.line then
        local nx, ny = world_dir_to_screen(0, -1, yaw, radius - 4)
        draw.line(cx, cy, cx + nx, cy + ny, theme.alpha(theme.CYAN, 0.9), 2)
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
            local fx, fz, rx, rz = map_basis(yaw)
            M._offset_x = M._old_off_x - (dx * rx + dy * rz)
            M._offset_y = M._old_off_y - (-dx * fx + dy * fz)
        end
    else
        M._dragging = false
    end
end

local function draw_hover_tooltip(mx, my, me)
    local best = nil
    local best_d = 9999

    for _, item in ipairs(M._hover_items) do
        local dx = mx - item.mx
        local dy = my - item.my
        local d = math.sqrt(dx * dx + dy * dy)
        if d <= item.r and d < best_d then
            best = item
            best_d = d
        end
    end

    if not best then return end

    local lines = { best.label or "?" }
    if best.extra then
        lines[#lines + 1] = best.extra
    elseif me and me.position and best.wx and best.wz then
        local dx = best.wx - me.position.x
        local dz = best.wz - me.position.z
        lines[#lines + 1] = string.format("%.0fm away", math.sqrt(dx * dx + dz * dz))
    end

    theme.draw_tooltip_box(mx + 14, my + 14, lines)
end

function M.update(_dt) end

function M.draw()
    if not key_active() then return end
    if not draw then return end

    M._hover_items = {}

    local sw, sh = draw_util.screen_size()
    local fullscreen = settings.num("april_map_mode", 0) == 1
    local x, y, w, h, map_cx, map_cy = map_layout(sw, sh, fullscreen)
    local zoom = settings.num("april_map_zoom", 1.0)
    local scale = settings.num("april_map_icon_scale", 3)
    local bg = settings.color("april_map_bg", theme.MAP_BG)
    local grid = settings.color("april_map_grid", theme.MAP_GRID)
    local track_hover = fullscreen and settings.bool("april_map_tooltips", false)
    local me = env.get_local_player()

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
        draw.rect_filled(x, y, w, h, bg, fullscreen and 0 or theme.ROUND)
        if draw.rect then
            draw.rect(x, y, w, h, theme.BORDER_CYAN, fullscreen and 0 or theme.ROUND, 1)
        end
    end

    draw_grid(x, y, w, h, grid, map_cx, map_cy, zoom)

    if settings.bool("april_map_show_world", false) then
        local col = settings.color("april_map_world_col", { 0.4, 0.9, 0.5, 1 })
        for _, item in ipairs(cache.world) do
            if env.is_valid(item.inst) then
                local wx, wz = entry_world_xz(item)
                if wx then
                    draw_map_item(wx, wz, col, item.name, view_x, view_z, map_cx, map_cy, zoom, yaw, scale, x, y, w, h, track_hover, item.name)
                end
            end
        end
    end

    if settings.bool("april_map_show_loot", false) then
        local col = settings.color("april_map_loot_col", { 1, 0.85, 0.2, 1 })
        for _, item in ipairs(cache.loot) do
            if env.is_valid(item.inst) then
                local wx, wz = entry_world_xz(item)
                if wx then
                    draw_map_item(wx, wz, col, item.name, view_x, view_z, map_cx, map_cy, zoom, yaw, scale, x, y, w, h, track_hover, item.name)
                end
            end
        end
    end

    if settings.bool("april_map_show_base", false) then
        local col = settings.color("april_map_base_col", { 0.5, 0.5, 1, 1 })
        for _, item in ipairs(cache.base) do
            if env.is_valid(item.inst) then
                local wx, wz = entry_world_xz(item)
                if wx then
                    draw_map_item(wx, wz, col, item.name, view_x, view_z, map_cx, map_cy, zoom, yaw, scale, x, y, w, h, track_hover, item.name)
                end
            end
        end
    end

    if settings.bool("april_map_show_npcs", false) then
        local col = settings.color("april_map_npc_col", { 1, 0.6, 0.2, 1 })
        for _, entry in ipairs(cache.npcs) do
            if env.is_valid(entry.inst) then
                local wx, wz = entry_world_xz(entry)
                if not wx and entry.lx and entry.lz then wx, wz = entry.lx, entry.lz end
                if wx then
                    draw_map_item(wx, wz, col, entry.name, view_x, view_z, map_cx, map_cy, zoom, yaw, scale, x, y, w, h, track_hover, entry.name)
                end
            end
        end
    end

    if settings.bool("april_map_show_waypoints", false) then
        local col = settings.color("april_map_wp_col", { 0.2, 1, 0.8, 1 })
        for i, wp in pairs(cache.waypoints) do
            if wp and wp.pos then
                local wx, wz = wp.pos.x, wp.pos.z
                draw_map_item(wx, wz, col, wp.name or ("WP" .. i), view_x, view_z, map_cx, map_cy, zoom, yaw, scale, x, y, w, h, track_hover, wp.name)
            end
        end
    end

    if settings.bool("april_map_show_players", false) and entity and entity.get_players then
        local col = settings.color("april_map_player_col", { 1, 0.35, 0.35, 1 })
        for _, p in ipairs(entity.get_players()) do
            if player_state.is_combat_target(p) and p.position then
                local wx, wz = p.position.x, p.position.z
                local extra = p.display_name and p.display_name ~= "" and p.display_name or p.name
                draw_map_item(wx, wz, col, p.name, view_x, view_z, map_cx, map_cy, zoom, yaw, scale, x, y, w, h, track_hover, extra)
            end
        end
    end

    local show_local = settings.bool("april_map_show_local", true)
    if not fullscreen then
        show_local = true
    end

    if show_local then
        local col = settings.color("april_map_local", theme.CYAN)
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
        local cmp_col = settings.color("april_map_compass", theme.CYAN)
        if fullscreen then
            draw_compass_rose(sw - 60, sh - 60, 42, yaw, cmp_col)
        else
            draw_compass_rose(map_cx, map_cy, math.min(w, h) * 0.42, yaw, cmp_col)
        end
    end

    if settings.bool("april_map_coords", false) then
        local coord_y = fullscreen and (sh - 22) or (y + h + 4)
        draw_util.text(x + 6, coord_y, string.format("Cam: %.0f, %.0f, %.0f", cam_x, cam_y, cam_z), theme.TEXT, 11)
        if body_x then
            draw_util.text(x + 6, coord_y + 13, string.format("Body: %.0f, %.0f, %.0f", body_x, body_y or 0, body_z or 0), theme.TEXT_MUTED, 10)
        end
    end

    if track_hover then
        draw_hover_tooltip(mx, my, me)
        draw_util.text(10, sh - 18, "Drag: LMB pan  |  Recenter: MMB  |  Hover icons for info", theme.TEXT_DIM, 10)
    elseif fullscreen then
        draw_util.text(10, sh - 18, "Drag: LMB pan  |  Recenter: MMB  |  Forward = up", theme.TEXT_DIM, 10)
    end
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
local last_scan = 0
local SCAN_MS = 2500
M._session = nil

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
    last_scan = 0
end

function M.tick_session()
    local sid = session_id()
    if M._session == nil then
        M._session = sid
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
    menu_util.section(T, G.MISC, "Mod Checker")
    menu.add_checkbox(T, G.MISC, P, "Mod Checker", false, { key = 0 })
    menu.add_slider_int(T, G.MISC, "april_mod_checker_interval", "Mod Scan Interval (ms)", 1000, 10000, 2500, { parent = P })
    menu_util.bind_master(P, { "april_mod_checker_interval" })
end

function M.init()
    image_cache.ensure(MOD_ICON_KEY, asset_urls.mod_warning_png())
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
    notify.warning(string.format("MOD: %s (%s) — %s", label, p.name or "?", role), 6000)
end

function M.reconcile_active()
    if not entity or not entity.get_players then
        M.reset_state()
        return
    end

    local players = entity.get_players()
    if #players == 0 then
        M.reset_state()
        return
    end

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

function M.update(_dt)
    M.tick_session()

    if not settings.enabled(P) then
        M.reset_state()
        return
    end

    local now = tick_ms()
    local interval = settings.num("april_mod_checker_interval", SCAN_MS)
    if now - last_scan >= interval then
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

function M.draw()
    M.draw_mod_markers()

    if not settings.enabled(P) then return end
    if not draw or not draw.text then return end

    local rows = {}
    local me = env.get_local_player()
    local now = tick_ms()

    for uid, entry in pairs(active) do
        local still_here = false
        local dist = nil

        for _, p in ipairs(entity and entity.get_players and entity.get_players() or {}) do
            if p.user_id == uid then
                still_here = true
                if me and me.position and p.position then
                    local dx = p.position.x - me.position.x
                    local dy = p.position.y - me.position.y
                    local dz = p.position.z - me.position.z
                    dist = math.floor(math.sqrt(dx * dx + dy * dy + dz * dz))
                end
                break
            end
        end

        if not still_here then
            active[uid] = nil
            seen[uid] = nil
            goto continue
        end

        rows[#rows + 1] = {
            entry = entry,
            dist = dist,
            duration = format_duration(now - (entry.first_seen or now)),
        }

        ::continue::
    end

    if #rows == 0 then return end

    table.sort(rows, function(a, b)
        return (a.entry.first_seen or 0) < (b.entry.first_seen or 0)
    end)

    if not draw.window then return end

    local sw, _ = draw_util.screen_size()
    local panel_w = 260
    local x = sw - panel_w - 16
    local items = {}

    for i = 1, #rows do
        local row = rows[i]
        local entry = row.entry
        local meta = row.duration
        if row.dist then
            meta = meta .. "  ·  " .. row.dist .. "m"
        end

        local name = entry.label or entry.username or "Unknown"
        if #name > 18 then name = name:sub(1, 16) .. ".." end

        local role = entry.role or "Staff"
        items[#items + 1] = { name .. "  ·  " .. role, meta }
    end

    local title = "Staff In Lobby"
    if #items > 1 then
        title = title .. " (" .. #items .. ")"
    end

    draw.window(x, 72, "april_staff_lobby", title, items)
end

return M

end)()

-- ── features/utility/name_hider.lua ──
April._mods["features.utility.name_hider"] = (function()
local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local env = April.require("core.env")
local mem = April.require("core.memory_string")

local M = {}
local P = "april_hide_local_name"
local APPLY_DELAY_MS = 1500

M._aliases = {}
M._patched = {}
M._source_key = ""
M._applied_for = nil
M._scheduled_for = nil
M._apply_after = 0

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

local function real_names()
    local lp = env.get_local_player()
    if not lp then return nil end

    local names = {}
    local seen = {}

    local function add(name)
        if not name or name == "" or seen[name] then return end
        if #name < 2 then return end
        seen[name] = true
        names[#names + 1] = name
    end

    add(lp.name)
    add(lp.display_name)

    if game and game.local_player then
        local inst = game.local_player
        if env.is_valid(inst) then
            add(inst.Name or inst.name)
        end
    end

    if #names == 0 then return nil end
    return names
end

local function alias_for(real)
    if M._aliases[real] then return M._aliases[real] end
    math.randomseed(tick_ms() + #real * 9973)
    local alias = mem.random_alias(#real)
    M._aliases[real] = mem.pad_alias(alias, #real)
    return M._aliases[real]
end

local function alias_for_at(real)
    local key = "@" .. real
    if M._aliases[key] then return M._aliases[key] end
    local base = alias_for(real)
    M._aliases[key] = "@" .. base
    return M._aliases[key]
end

local function patch_hit(real, hit)
    local enc = hit.enc or "ascii"
    local addr = hit.addr
    if not addr or addr <= 0 then return false end

    local current = mem.read_at(addr, #real + 8, enc)
    local alias

    if current:sub(1, 1) == "@" then
        alias = alias_for_at(real)
    else
        alias = alias_for(real)
    end

    if #alias > #current and enc == "ascii" then
        alias = alias:sub(1, #current)
    end
    if enc == "utf16" then
        alias = mem.pad_alias(alias, #real)
    end

    if current ~= real and current ~= ("@" .. real) and current:sub(1, #real) ~= real then
        return false
    end

    if mem.write_at(addr, alias, #alias + 1, enc) then
        M._patched[addr] = { real = real, alias = alias, enc = enc }
        return true
    end
    return false
end

local function patch_name(real)
    local hits = mem.find_string_variants(real, 128)
    local patched = 0

    for i = 1, #hits do
        if patch_hit(real, hits[i]) then
            patched = patched + 1
        end
    end

    return patched
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    menu.add_checkbox(T, G.MISC, P, "Hide Local Name", false, menu_util.parent("april_mod_checker_enabled"))

    settings.on_change(P, function()
        M._aliases = {}
        M._patched = {}
        M._applied_for = nil
        M._scheduled_for = nil
        if settings.enabled(P) then
            M.schedule_apply()
        end
    end)

    menu_util.bind_master("april_mod_checker_enabled", { P })
end

function M.schedule_apply()
    M._scheduled_for = session_id()
    M._apply_after = tick_ms() + APPLY_DELAY_MS
end

function M.apply()
    if not settings.enabled(P) then return end
    if not mem.available() then return end

    local names = real_names()
    if not names then return end

    for i = 1, #names do
        patch_name(names[i])
    end
end

function M.reset()
    M._aliases = {}
    M._patched = {}
    M._source_key = ""
    M._applied_for = nil
    M._scheduled_for = nil
    M._apply_after = 0
end

function M.update(_dt)
    if not settings.enabled(P) then
        if M._applied_for or M._scheduled_for or M._source_key ~= "" then
            M.reset()
        end
        return
    end

    if not mem.available() then return end

    local sid = session_id()
    local names = real_names()
    if not names then return end

    local key = table.concat(names, "|")
    if key ~= M._source_key then
        M._aliases = {}
        M._patched = {}
        M._source_key = key
        M._applied_for = nil
        M._scheduled_for = nil
    end

    if M._applied_for == sid then return end

    if M._scheduled_for ~= sid then
        M.schedule_apply()
    end

    if tick_ms() >= M._apply_after then
        M.apply()
        M._applied_for = sid
        M._scheduled_for = nil
    end
end

function M.draw() end

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
        notify.success(string.format('Saved "%s" → Slot %d', profile_label(), slot), 3500)
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

    menu_util.section(T, G.CONFIG, "Config Profiles")

    menu_util.input(T, G.CONFIG, "april_cfg_profile_name", "Profile Name", "Default")

    menu.add_slider_int(T, G.CONFIG, "april_cfg_slot", "Active Slot (1–5)", store.SLOT_MIN, store.SLOT_MAX, 1)

    menu_util.button(T, G.CONFIG, "april_cfg_save", "Save to Active Slot", function()
        M.save_slot(active_slot())
    end)
    menu_util.button(T, G.CONFIG, "april_cfg_load", "Load Active Slot", function()
        M.load_slot(active_slot())
    end)
    menu_util.button(T, G.CONFIG, "april_cfg_delete", "Delete Active Slot", function()
        M.delete_slot(active_slot())
    end)

    menu.add_separator(T, G.CONFIG)
    menu_util.label(T, G.CONFIG, "Autoload on script start")

    menu.add_checkbox(T, G.CONFIG, "april_cfg_autoload", "Enable Autoload", false)
    menu_util.input(T, G.CONFIG, "april_cfg_autoload_profile", "Autoload Profile Name", "")
    menu.add_slider_int(
        T, G.CONFIG, "april_cfg_autoload_slot", "Autoload Slot (fallback)",
        store.SLOT_MIN, store.SLOT_MAX, 1,
        menu_util.parent("april_cfg_autoload")
    )

    menu.add_separator(T, G.CONFIG)
    menu_util.label(T, G.CONFIG, "Display & modules")

    menu.add_slider_int(T, G.CONFIG, "april_esp_text_size", "ESP Text Size", 8, 24, 13)
    menu.add_button(T, G.CONFIG, "april_reload_modules", "Reload Game Modules", function()
        April.require("game.bootstrap").force_reload()
        notify.info("Reloading game modules…", 2500)
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
    "features.combat.perfect_farm",
    "features.combat.gun_mods",
    "features.visuals.player_esp",
    "features.visuals.target_overlay",
    "features.visuals.crosshair",
    "features.world.world_esp",
    "features.world.loot_esp",
    "features.world.npc_esp",
    "features.world.base_esp",
    "features.radar.waypoints",
    "features.radar.tactical_map",
    "features.movement.exploits",
    "features.utility.mod_checker",
    "features.utility.name_hider",
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
                debug.error_once("menu:" .. path, err)
            end
        end
    end

    M._menu_registered = true
    if April and April.debug then
        debug.log("Menu: " .. registered .. " sections")
    end

    pcall(function()
        local esp = April.require("features.visuals.player_esp")
        if esp.init then esp.init() end
        local mod = April.require("features.utility.mod_checker")
        if mod.init then mod.init() end
    end)
end

function M.setup_scans()
    local settings = April.require("core.settings")
    local iscan = April.require("core.incremental_scan")
    local world_esp = April.require("features.world.world_esp")
    local loot_esp = April.require("features.world.loot_esp")
    local base_esp = April.require("features.world.base_esp")
    local npc_esp = April.require("features.world.npc_esp")

    iscan.configure({ budget_ms = 5, items_per_step = 14 })

    local function map_on(layer)
        return function()
            if not settings.enabled("april_map_enabled") then return false end
            return settings.enabled("april_map_show_" .. layer)
        end
    end

    local function need_npcs()
        if settings.enabled("april_npc_enabled") then return true end
        return map_on("npcs")()
    end

    iscan.register("world", 3500, function()
        return settings.enabled("april_world_enabled") or map_on("world")()
    end, world_esp.begin_static_scan, world_esp.step_static_scan, world_esp.complete_static_scan, 0)

    iscan.register("world_dynamic", 900, function()
        if not settings.enabled("april_world_enabled") then return false end
        return settings.enabled("april_deer")
            or settings.enabled("april_boar")
            or settings.enabled("april_wolf")
    end, world_esp.begin_dynamic_scan, world_esp.step_dynamic_scan, world_esp.complete_dynamic_scan, 450)

    iscan.register("loot", 4000, function()
        return settings.enabled("april_loot_enabled") or map_on("loot")()
    end, loot_esp.begin_static_scan, loot_esp.step_static_scan, loot_esp.complete_static_scan, 900)

    iscan.register("loot_drops", 700, function()
        if not settings.enabled("april_loot_enabled") then return false end
        return settings.enabled("april_dropped_item")
    end, loot_esp.begin_drops_scan, loot_esp.step_drops_scan, loot_esp.complete_drops_scan, 1350)

    iscan.register("base", 4500, function()
        return settings.enabled("april_base_enabled") or map_on("base")()
    end, base_esp.begin_scan, base_esp.step_scan, base_esp.complete_scan, 1800)

    iscan.register("npcs", 1400, need_npcs, npc_esp.begin_scan, npc_esp.step_scan, npc_esp.complete_scan, 2250)
end

function M.update(dt)
    bootstrap.tick()

    local weapons = April.require("game.weapons")
    weapons.tick()

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
