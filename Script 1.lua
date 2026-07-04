--[[
    April — Fallen Survival for Project Vector
    https://github.com/Cunzaki/April
    Built: 2026-07-04T07:04:36.144Z
]]

April = {
    version = "3.9.0",
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

-- ── core/notify.lua ──
April._mods["core.notify"] = (function()
--[[ Toast notifications — draws on-screen; also tries menu.notify if available. ]]

local draw_util = April.require("core.draw_util")

local M = {}
local queue = {}

local function tick()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

function M.show(msg, ntype, duration_ms)
    if not msg or msg == "" then return end
    msg = tostring(msg)
    ntype = ntype or "warning"
    duration_ms = duration_ms or 5000

    for _, n in ipairs(queue) do
        if n.msg == msg and (tick() - n.time) < 3000 then return end
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

    print("[April] " .. msg)
end

function M.warning(msg, duration_ms)
    M.show(msg, "warning", duration_ms)
end

function M.draw()
    if #queue == 0 or not draw then return end

    local now = tick()
    local sw, sh = draw_util.screen_size()
    local font = 14
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

            local accent = { 1, 0.75, 0.2, 1 }
            if n.type == "success" then accent = { 0.2, 0.85, 0.35, 1 }
            elseif n.type == "danger" then accent = { 1, 0.25, 0.25, 1 }
            elseif n.type == "info" then accent = { 0.25, 0.65, 1, 1 }
            end

            local tw = draw.get_text_size and draw.get_text_size(n.msg, font) or (#n.msg * 7)
            local box_w = tw + pad * 2 + 6
            local box_h = font + pad * 2
            local x = sw - box_w - 16 + (n.x_off or 0)
            local y = n.y
            local a = n.alpha or 1

            if draw.rect_filled then
                draw.rect_filled(x, y, box_w, box_h, { 0.05, 0.05, 0.08, 0.82 * a })
            end
            if draw.rect then
                draw.rect(x, y, box_w, box_h, { accent[1], accent[2], accent[3], 0.9 * a }, 0, 1)
            end
            if draw.line then
                draw.line(x, y, x, y + box_h, { accent[1], accent[2], accent[3], a }, 3)
            end
            if draw.text then
                draw.text(x + pad + 4, y + pad - 1, n.msg, { 1, 1, 1, a }, font)
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
    GitHub CDN URLs for draw.load_image (April/docs/API.md — HTTPS required).
    Assets live in repo assets/ — run: node scripts/download-assets.mjs
]]

local M = {}

-- Bump branch/path if you fork; must match raw GitHub path after push.
M.CDN_BASE = "https://raw.githubusercontent.com/cunzaki/April/main/assets"

function M.item_png(asset_id)
    asset_id = asset_id and tostring(asset_id):match("(%d+)")
    if not asset_id then return nil end
    return M.CDN_BASE .. "/items/" .. asset_id .. ".png"
end

function M.tung_png()
    return M.CDN_BASE .. "/tung.png"
end

function M.urls_for_item(asset_id)
    local png = M.item_png(asset_id)
    if not png then return {} end
    asset_id = tostring(asset_id):match("(%d+)")
    return {
        png,
        "rbxassetid://" .. asset_id,
        "https://www.roblox.com/asset/?id=" .. asset_id,
    }
end

function M.urls_for_tung()
    local id = "139818999438291"
    return {
        M.tung_png(),
        "rbxassetid://" .. id,
        "https://www.roblox.com/asset/?id=" .. id,
    }
end

function M.urls_for_avatar(user_id)
    user_id = tostring(user_id):match("(%d+)") or tostring(user_id)
    return {
        "https://www.roblox.com/headshot-thumbnail/image?userId=" .. user_id .. "&size=150x150&format=Png",
        "https://www.roblox.com/headshot-thumbnail/image?userId=" .. user_id .. "&width=150&height=150&format=png",
    }
end

return M

end)()

-- ── core/image_cache.lua ──
April._mods["core.image_cache"] = (function()
--[[ Async image loader — April/docs/API.md: HTTPS GitHub CDN first, lazy load in on_frame. ]]

local asset_urls = April.require("game.asset_urls")

local M = {}

local entries = {}

function M.urls_for_asset(id)
    return asset_urls.urls_for_item(id)
end

function M.urls_for_tung()
    return asset_urls.urls_for_tung()
end

function M.urls_for_avatar(user_id)
    return asset_urls.urls_for_avatar(user_id)
end

local function normalize_urls(asset_id_or_urls)
    if type(asset_id_or_urls) == "table" then
        return asset_id_or_urls
    end

    if type(asset_id_or_urls) == "string" then
        local id = asset_id_or_urls:match("(%d+)")
        if asset_id_or_urls:find("http", 1, true) then
            return { asset_id_or_urls }
        end
        if asset_id_or_urls:find("rbxassetid", 1, true) and id then
            return asset_urls.urls_for_item(id)
        end
        if id then
            return asset_urls.urls_for_item(id)
        end
    end

    return asset_urls.urls_for_item(asset_id_or_urls)
end

function M.register(key, asset_id_or_urls)
    if entries[key] then return entries[key] end

    entries[key] = {
        urls = normalize_urls(asset_id_or_urls),
        url_index = 1,
        handle = nil,
        failed = false,
    }
    return entries[key]
end

function M.register_avatar(key, user_id)
    return M.register(key, asset_urls.urls_for_avatar(user_id))
end

function M.ensure(key, asset_id_or_urls)
    if not entries[key] then
        M.register(key, asset_id_or_urls)
    end
    return entries[key]
end

function M.tick(key)
    local entry = entries[key]
    if not entry or entry.failed or not draw or not draw.load_image then return end

    if not entry.handle then
        local url = entry.urls[entry.url_index]
        if not url then
            entry.failed = true
            return
        end
        entry.handle = draw.load_image(url)
        if not entry.handle then
            entry.url_index = entry.url_index + 1
            if entry.url_index > #entry.urls then
                entry.failed = true
            end
        end
        return
    end

    if draw.image_loaded and draw.image_loaded(entry.handle) then
        return
    end

    if draw.image_failed and draw.image_failed(entry.handle) then
        if draw.free_image then
            pcall(function() draw.free_image(entry.handle) end)
        end
        entry.handle = nil
        entry.url_index = entry.url_index + 1
        if entry.url_index > #entry.urls then
            entry.failed = true
        end
    end
end

function M.tick_all()
    for key, _ in pairs(entries) do
        M.tick(key)
    end
end

function M.ready(key)
    local entry = entries[key]
    if not entry or not entry.handle then return false end
    return draw and draw.image_loaded and draw.image_loaded(entry.handle)
end

function M.handle(key)
    local entry = entries[key]
    return entry and entry.handle
end

function M.draw_fit(key, x, y, w, h, col)
    M.tick(key)
    if not M.ready(key) or not draw.image then return false end

    local handle = M.handle(key)
    local iw, ih = draw.image_size(handle)
    if not iw or iw <= 0 or not ih or ih <= 0 then return false end

    w = math.max(w or 0, 8)
    h = math.max(h or 0, 8)

    local dw = w
    local dh = math.floor(w * ih / iw)
    if dh < h then
        dh = h
        dw = math.floor(h * iw / ih)
    end

    local dx = x + (w - dw) * 0.5
    local dy = y + (h - dh) * 0.5

    if col then
        draw.image(handle, dx, dy, dw, dh, col)
    else
        draw.image(handle, dx, dy, dw, dh)
    end
    return true
end

function M.draw_at_world(key, wx, wy, wz, display_w)
    M.tick(key)
    if not M.ready(key) then return false end

    local sx, sy, vis
    if draw and draw.world_to_screen then
        sx, sy, vis = draw.world_to_screen(wx, wy, wz)
    elseif utility and utility.world_to_screen then
        sx, sy, vis = utility.world_to_screen(wx, wy, wz)
    end
    if not vis then return false end

    local handle = M.handle(key)
    local iw, ih = draw.image_size(handle)
    if not iw or iw <= 0 or not ih or ih <= 0 then return false end

    display_w = display_w or 64
    local dh = math.floor(display_w * ih / iw)

    draw.image(handle, sx - display_w * 0.5, sy - dh, display_w, dh)
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

local BOX_EDGES = {
    { 1, 2 }, { 1, 3 }, { 2, 4 }, { 3, 4 },
    { 5, 6 }, { 5, 7 }, { 6, 8 }, { 7, 8 },
    { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 },
}

local BOX_SIGNS = {
    { -1, -1, -1 }, { 1, -1, -1 }, { -1, 1, -1 }, { 1, 1, -1 },
    { -1, -1, 1 }, { 1, -1, 1 }, { -1, 1, 1 }, { 1, 1, 1 },
}

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
    local scan = April.require("game.esp_scan")
    local main = scan.find_main_part(entry.inst)
    local box = scan.read_part_box(main)
    if box then
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
    else
        April.require("game.items").load()
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
-- AUTO-GENERATED by scripts/extract-item-images.mjs — do not edit by hand
-- Source: references/dump/scripts/ReplicatedStorage.Modules.Items.ModuleScript.lua

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

-- ── game/items.lua ──
April._mods["game.items"] = (function()
local env = April.require("core.env")
local item_images = April.require("game.item_images")
local asset_urls = April.require("game.asset_urls")

local M = {}
local loaded = false
local by_name = {}

local FALLBACK = {
    ["Wood Log"] = { Type = "Resource" },
    ["Bandage"] = { Type = "Tool" },
    ["Salvaged M14"] = { Type = "Tool" },
}

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

function M.get_type(name)
    local item = M.get(name)
    return item and item.Type or "Unknown"
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

    local id = item_images.get_asset_id(name, variant)
    if id then return id end

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
    ["Armor_153"] = "Cloth Head Wrap",
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

-- ── game/player_gear.lua ──
April._mods["game.player_gear"] = (function()
local env = April.require("core.env")
local armor_map = April.require("game.armor_map")
local items = April.require("game.items")
local weapons = April.require("game.weapons")

local M = {}

local function parse_armor_child(name)
    if not name or not name:find("Armor_", 1, true) then return nil end
    local model_key, variant = name:match("^(Armor_%d+)[%/]?(%w*)")
    if not model_key then
        model_key = name:match("^(Armor_%d+)")
    end
    if variant == "" then variant = nil end
    return model_key, variant
end

function M.scan_player(player)
    local out = {
        held = nil,
        armor = {},
    }

    if not player then return out end

    if player.tool_name and player.tool_name ~= "" then
        out.held = player.tool_name
    end

    local char = player.character
    if not char or not env.is_valid(char) then return out end

    local children = env.safe_call(function() return char:get_children() end) or {}
    local seen = {}

    for _, child in ipairs(children) do
        if not env.is_valid(child) then goto continue end
        local name = child.Name or child.name
        if not name then goto continue end

        if not out.held and weapons.is_weapon_name(name) then
            out.held = name
        end

        local model_key, variant = parse_armor_child(name)
        if model_key then
            local item_name = armor_map.item_name(model_key)
            if item_name and not seen[item_name] then
                seen[item_name] = true
                local asset_id = items.get_image_asset_id(item_name, variant)
                table.insert(out.armor, {
                    name = item_name,
                    variant = variant,
                    asset_id = asset_id,
                    model_key = model_key,
                })
            end
        end

        ::continue::
    end

    return out
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
M._last_refresh_at = 0
M._refresh_cooldown_ms = 2500

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

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

local function refresh_nodes(force)
    if not has_api() then return 0 end

    local now = tick_ms()
    if not force and M._last_node_count > 0 and now - M._last_refresh_at < M._refresh_cooldown_ms then
        return M._last_node_count
    end

    pcall(function()
        refreshgc()
    end)
    pcall(function()
        local n = getgc(M.GC_KEYS)
        if type(n) == "number" then
            M._last_node_count = n
        end
    end)

    M._last_refresh_at = now
    return M._last_node_count
end

--[[ One-time startup probe: refreshgc + getgc(keys) only — no applygc. ]]
function M.probe_on_load()
    if M._probed then return M._last_node_count end
    M._probed = true

    if not has_api() then
        return 0
    end

    return refresh_nodes(true)
end

function M.refresh_cache(force)
    return refresh_nodes(force)
end

function M.apply_cached(mods)
    if not has_api() then
        return false, 0, "GC API unavailable (refreshgc/getgc/applygc)"
    end
    if type(mods) ~= "table" or not next(mods) then
        return false, 0, "No modifiers selected"
    end
    if M._last_node_count <= 0 then
        return false, 0, "No GC nodes cached"
    end

    local ok, err = pcall(applygc, mods)
    if not ok then
        april_debug.error_once("gun_mods:applygc", err)
        return false, M._last_node_count, "applygc failed: " .. tostring(err)
    end

    return true, M._last_node_count, string.format("%d node(s) — mods active", M._last_node_count)
end

function M.apply_once(mods)
    if not has_api() then
        return false, 0, "GC API unavailable (refreshgc/getgc/applygc)"
    end
    if type(mods) ~= "table" or not next(mods) then
        return false, 0, "No modifiers selected"
    end

    local count = refresh_nodes(true)
    if count <= 0 then
        return false, 0, "No tables found — enter a match with a gun equipped"
    end

    return M.apply_cached(mods)
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

-- ── game/npcs.lua ──
April._mods["game.npcs"] = (function()
--[[
    Fallen Survival hostile NPCs — from workspace.Military monument children.
    Dump confirms: Soldier, Bruno, Boris, Brutus (no zombies; VM "Zombie" skins are viewmodels only).
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

function M.scan()
    local out = {}
    local military = folders.from_key("military")
    if not env.is_valid(military) then return out end

    local monuments = env.safe_call(function() return military:get_children() end) or {}
    for _, monument in ipairs(monuments) do
        if not env.is_valid(monument) then goto next_monument end
        local children = env.safe_call(function() return monument:get_children() end) or {}
        for _, model in ipairs(children) do
            if not env.is_valid(model) then goto next_npc end
            local name = model.Name or model.name
            if not M.is_hostile_name(name) then goto next_npc end
            if not read_health(model) then goto next_npc end
            local head = env.safe_call(function()
                return model:find_first_child("Head") or model:FindFirstChild("Head")
            end)
            if not head or not env.is_valid(head) then goto next_npc end

            table.insert(out, {
                inst = model,
                name = name,
                kind = M.kind(name),
                head = head,
            })
            ::next_npc::
        end
        ::next_monument::
    end

    return out
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
--[[ Fallen Survival ESP name maps — from dump + legacy scan_world / scan_loot. ]]

local M = {}

M.NODE_MAP = {
    ["Stone_Node"] = "april_stone_node",
    ["Metal_Node"] = "april_metal_node",
    ["Phosphate_Node"] = "april_phosphate_node",
}

M.PLANT_MAP = {
    ["Corn Plant"] = "april_corn_plant",
    ["Tomato Plant"] = "april_tomato_plant",
    ["Lemon Plant"] = "april_lemon_plant",
    ["Raspberry Plant"] = "april_raspberry_plant",
    ["Blueberry Plant"] = "april_blueberry_plant",
    ["Wool Plant"] = "april_wool_plant",
    ["Pumpkin Plant"] = "april_pumpkin_plant",
}

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

M.LOOT_MAP = {
    ["Wooden Crate"] = "april_wooden_crate",
    ["Locked Wooden Crate"] = "april_wooden_crate",
    ["Locked Metal Crate"] = "april_metal_crate",
    ["Locked Steel Crate"] = "april_steel_crate",
    ["Food Crate"] = "april_food_crate",
    ["Timed Crate"] = "april_timed_crate",
    ["Care Package"] = "april_care_package",
    ["Body Bag"] = "april_body_bag",
    ["Sleeper"] = "april_sleeper",
    ["Trash Can"] = "april_trash_can",
    ["Oil Barrel"] = "april_oil_barrel",
}

M.PLANT_LABELS = {
    ["Corn Plant"] = "Corn Plant",
    ["Tomato Plant"] = "Tomato Plant",
    ["Lemon Plant"] = "Lemon Plant",
    ["Raspberry Plant"] = "Raspberry Plant",
    ["Blueberry Plant"] = "Blueberry Plant",
    ["Wool Plant"] = "Wool Plant",
    ["Pumpkin Plant"] = "Pumpkin Plant",
}

M.NODE_LABELS = {
    ["Stone_Node"] = "Stone Node",
    ["Metal_Node"] = "Metal Node",
    ["Phosphate_Node"] = "Phosphate Node",
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
    return {
        inst = model,
        name = name,
        toggle_id = toggle_id,
        dynamic = opts.dynamic == true,
    }
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

function M.get_target()
    return locked_target
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
M._needs_refresh = false
M._last_retry = 0
M._retry_ms = 2500

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function request_apply(refresh)
    M._apply_dirty = true
    if refresh then
        M._needs_refresh = true
    end
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
    end)
    menu.add_label(T, G.AIMBOT, "Save stores settings only. Auto-apply runs on weapon swap.", root)

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
    settings.on_change(P, function() request_apply(true) end)
    settings.on_change("april_gm_auto_detect", function() request_apply(false) end)
    settings.on_change("april_gm_per_weapon", function() request_apply(false) end)

    profiles.sync_profile_to_editor(M._editing)
end

function M.try_apply(held)
    if not settings.bool(P, false) then
        M._last_applied_weapon = nil
        M._last_applied_profile = nil
        M._apply_dirty = false
        M._needs_refresh = false
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
        M._apply_dirty = false
        return false
    end

    local weapon_key = apply_held or "__global__"
    if weapon_key == M._last_applied_weapon
        and profile_name == M._last_applied_profile
        and not M._apply_dirty then
        return true
    end

    local ok
    if M._needs_refresh or gc.last_node_count() <= 0 then
        ok = gc.apply_once(mods)
        M._needs_refresh = false
    else
        ok = gc.apply_cached(mods)
        if not ok and gc.last_node_count() <= 0 then
            ok = gc.apply_once(mods)
            M._needs_refresh = false
        end
    end

    if ok then
        M._last_applied_weapon = weapon_key
        M._last_applied_profile = profile_name
        M._apply_dirty = false
    end

    return ok
end

function M.update(dt)
    if not settings.bool(P, false) then return end

    local held = weapons._last_held
    local now = tick_ms()

    if M._apply_dirty or held ~= M._last_applied_weapon then
        M.try_apply(held)
    elseif held and now - M._last_retry >= M._retry_ms and M._apply_dirty then
        M._last_retry = now
        M._needs_refresh = true
        M.try_apply(held)
    end
end

function M.on_weapon_changed(name)
    request_apply(true)
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
local image_cache = April.require("core.image_cache")

local M = {}
local P = "april_esp_enabled"
local TUNG_KEY = "tung"

local BOX_LABELS = { "None", "2D", "Corner", "Tung" }

local function box_mode()
    return settings.combo_index("april_esp_box_mode", BOX_LABELS, 0)
end

local function is_tung_mode()
    return box_mode() == 3
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)
    local root = menu_util.parent(P)

    menu.add_label(T, G.VISUALS, "Player ESP")
    menu.add_checkbox(T, G.VISUALS, P, "Player ESP", false, { key = 0 })
    menu.add_combo(T, G.VISUALS, "april_esp_box_mode", "Box Mode", { "None", "2D", "Corner", "Tung" }, 0, root)
    menu.add_checkbox(T, G.VISUALS, "april_esp_name", "Name", false, menu_util.parent(P, { colorpicker = { 1, 1, 1, 1 } }))
    menu.add_checkbox(T, G.VISUALS, "april_esp_health", "Health Bar", false, root)
    menu.add_checkbox(T, G.VISUALS, "april_esp_distance", "Distance", false, menu_util.parent(P, { colorpicker = { 0.7, 0.7, 0.7, 1 } }))
    menu.add_checkbox(T, G.VISUALS, "april_esp_held_item", "Held Item", false, menu_util.parent(P, { colorpicker = { 0.2, 0.8, 1, 1 } }))
    menu.add_checkbox(T, G.VISUALS, "april_esp_skeleton", "Skeleton", false, menu_util.parent(P, { colorpicker = { 1, 1, 1, 0.85 } }))
    menu.add_checkbox(T, G.VISUALS, "april_esp_offscreen", "Offscreen Arrows", false, menu_util.parent(P, { colorpicker = { 0.3, 1, 0.5, 1 } }))
    menu.add_colorpicker(T, G.VISUALS, "april_esp_box_color", "Box Color", { 0.3, 1, 0.5, 1 }, root)
    menu.add_slider_int(T, G.VISUALS, "april_esp_max_dist", "Max Distance", 50, 5000, 1000, root)
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

function M.init()
    image_cache.register(TUNG_KEY, image_cache.urls_for_tung())
end

function M.update(_dt)
    -- tick_all runs from menu/tabs.update
end

local function draw_tung(p, b)
    image_cache.tick(TUNG_KEY)

    if b and b.valid and b.w > 0 and b.h > 0 then
        if image_cache.draw_fit(TUNG_KEY, b.x, b.y, b.w, b.h) then
            return
        end
    end

    local pos = p.head_position or p.position
    if not pos then return end

    local display_w = 72
    if b and b.valid and b.w > 0 then
        display_w = math.max(48, math.floor(b.w))
    end

    image_cache.draw_at_world(
        TUNG_KEY,
        pos.x,
        pos.y + 1,
        pos.z,
        display_w
    )
end

function M.draw()
    if not settings.bool(P, false) then return end

    local max_dist = settings.num("april_esp_max_dist", 1000)
    local col = settings.color("april_esp_box_color", { 0.3, 1, 0.5, 1 })
    local mode = box_mode()
    local tung = mode == 3
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
            if tung and p.head_position then
                draw_tung(p, nil)
            elseif settings.bool("april_esp_offscreen", false) and p.head_position then
                local hx, hy, hvis = esp_util.w2s(p.head_position.x, p.head_position.y, p.head_position.z)
                if not hvis then
                    local ac = settings.color("april_esp_offscreen", { 0.3, 1, 0.5, 1 })
                    esp_util.draw_offscreen_arrow(cx, cy, hx ~= 0 and hx or cx, hy ~= 0 and hy or cy, ac, 12)
                end
            end
            goto continue
        end

        if tung then
            draw_tung(p, b)
        elseif mode == 1 then
            draw_util.box_esp(b.x, b.y, b.w, b.h, col, 0)
        elseif mode == 2 then
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

-- ── features/visuals/target_overlay.lua ──
April._mods["features.visuals.target_overlay"] = (function()
local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local menu_util = April.require("core.menu_util")
local image_cache = April.require("core.image_cache")
local items = April.require("game.items")
local player_gear = April.require("game.player_gear")
local targeting = April.require("features.combat.targeting")

local M = {}

local P = "april_target_overlay"
local AIM = "april_aimbot_enabled"
local AIM_PREFIX = "april_aimbot_"

local gear_cache = {}
local GEAR_TTL = 400

M._anchor_x = nil
M._anchor_y = nil
M._last_uid = nil

local function scale()
    return math.max(0.55, settings.num(P .. "_scale", 72) / 100)
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function img_key(prefix, id)
    return prefix .. tostring(id)
end

local function ensure_item_image(name, variant)
    if not name then return nil end
    local url = items.get_image_url(name, variant)
    if not url then return nil end
    local asset_id = url:match("(%d+)")
    local key = img_key("item_", asset_id or name)
    image_cache.ensure(key, url)
    return key
end

local function ensure_avatar(user_id)
    if not user_id or user_id <= 0 then return nil end
    local key = img_key("avatar_", user_id)
    image_cache.ensure(key, image_cache.urls_for_avatar(user_id))
    return key
end

local function get_gear(player)
    if not player then return nil end
    local uid = player.user_id or player.name or "?"
    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    local cached = gear_cache[uid]
    if cached and (now - cached.t) < GEAR_TTL then
        return cached.data
    end
    local data = player_gear.scan_player(player)
    gear_cache[uid] = { t = now, data = data }
    return data
end

local function resolve_target()
    if not settings.bool(AIM, false) then return nil end

    local aimbot = April.require("features.combat.aimbot")
    local locked = aimbot.get_target and aimbot.get_target()
    if locked and locked.is_alive then return locked end

    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num(AIM_PREFIX .. "fov", 150)
    return targeting.find_target(cx, cy, fov, AIM_PREFIX)
end

local function hp_color(ratio)
    if ratio > 0.6 then return { 0.35, 0.92, 0.45, 1 } end
    if ratio > 0.3 then return { 0.95, 0.85, 0.25, 1 } end
    return { 0.95, 0.3, 0.3, 1 }
end

local function draw_icon_slot(x, y, size, key, accent)
    local pad = 2
    draw.rect_filled(x, y, size, size, { 0.08, 0.08, 0.1, 0.9 })
    draw.rect(x, y, size, size, accent or { 0.35, 0.55, 0.95, 0.45 }, 1)
    if key then
        image_cache.draw_fit(key, x + pad, y + pad, size - pad * 2, size - pad * 2)
    end
end

local function measure_panel(target, s)
    local gear = get_gear(target)
    local armor_list = (gear and gear.armor) or {}
    local held_name = gear and gear.held

    local show_avatar = settings.bool(P .. "_avatar", true)
    local show_held = settings.bool(P .. "_held", true) and held_name
    local show_armor = settings.bool(P .. "_armor", true) and #armor_list > 0

    local avatar_sz = math.floor(38 * s)
    local slot_sz = math.floor(26 * s)
    local pad = math.floor(6 * s)
    local title_fs = math.max(11, math.floor(12 * s))
    local body_fs = math.max(9, math.floor(10 * s))
    local gap = math.floor(4 * s)

    local cols = show_armor and math.min(4, math.max(1, #armor_list)) or 0
    local armor_rows = show_armor and math.ceil(#armor_list / 4) or 0

    local header_h = show_avatar and avatar_sz or math.floor(34 * s)
    local info_w = math.floor(150 * s)
    local content_w = (show_avatar and (avatar_sz + pad) or 0) + info_w

    if show_armor then
        content_w = math.max(content_w, cols * (slot_sz + gap) + pad)
    end

    local panel_w = content_w + pad * 2
    local panel_h = header_h + pad * 2

    if show_held then
        panel_h = panel_h + slot_sz + gap + body_fs
    end
    if show_armor then
        panel_h = panel_h + body_fs + gap + armor_rows * (slot_sz + gap)
    end

    return panel_w, panel_h, {
        s = s,
        pad = pad,
        gap = gap,
        avatar_sz = avatar_sz,
        slot_sz = slot_sz,
        title_fs = title_fs,
        body_fs = body_fs,
        show_avatar = show_avatar,
        show_held = show_held,
        show_armor = show_armor,
        armor_list = armor_list,
        held_name = held_name,
        cols = cols,
        armor_rows = armor_rows,
    }
end

local function compute_anchor(target, panel_w, panel_h, sw, sh)
    local gap = math.floor(14 + settings.num(P .. "_x_offset", 0))
    local y_off = settings.num(P .. "_y_offset", 0)
    local b = target.get_bounds and target:get_bounds()

    local ax, ay, flip_left

    if b and b.valid and b.w > 0 and b.h > 0 then
        flip_left = (b.x + b.w + gap + panel_w) > (sw - 10)
        if flip_left then
            ax = b.x - gap - panel_w
        else
            ax = b.x + b.w + gap
        end
        ay = b.y + b.h * 0.5 - panel_h * 0.5 + y_off
    else
        local pos = target.head_position or target.position
        if not pos then return nil, nil end
        local sx, sy, vis = esp_util.w2s(pos.x, pos.y + 1.5, pos.z)
        if not vis then return nil, nil end
        flip_left = (sx + gap + panel_w) > (sw - 10)
        if flip_left then
            ax = sx - gap - panel_w
        else
            ax = sx + gap + 24
        end
        ay = sy - panel_h * 0.5 + y_off
    end

    ax = math.max(6, math.min(sw - panel_w - 6, ax))
    ay = math.max(6, math.min(sh - panel_h - 6, ay))

    return ax, ay
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)
    local root = menu_util.parent(AIM)

    menu_util.section(T, G.VISUALS, "Target Overlay")
    menu.add_checkbox(T, G.VISUALS, P, "Target Overlay", false, root)
    menu.add_slider_int(T, G.VISUALS, P .. "_scale", "Scale %", 55, 120, 72, menu_util.parent(P))
    menu.add_slider_int(T, G.VISUALS, P .. "_follow", "Follow Speed", 4, 24, 14, menu_util.parent(P))
    menu.add_slider_int(T, G.VISUALS, P .. "_x_offset", "Side Offset", 0, 80, 14, menu_util.parent(P))
    menu.add_slider_int(T, G.VISUALS, P .. "_y_offset", "Y Offset", -120, 120, 0, menu_util.parent(P))
    menu.add_checkbox(T, G.VISUALS, P .. "_avatar", "Avatar", true, menu_util.parent(P))
    menu.add_checkbox(T, G.VISUALS, P .. "_held", "Held Item", true, menu_util.parent(P))
    menu.add_checkbox(T, G.VISUALS, P .. "_armor", "Armor Icons", true, menu_util.parent(P))
    menu.add_checkbox(T, G.VISUALS, P .. "_distance", "Distance", true, menu_util.parent(P))
    menu.add_colorpicker(T, G.VISUALS, P .. "_accent", "Accent", { 0.35, 0.72, 1, 1 }, menu_util.parent(P))
    menu.add_colorpicker(T, G.VISUALS, P .. "_name", "Name Color", { 1, 1, 1, 1 }, menu_util.parent(P))
    menu.add_colorpicker(T, G.VISUALS, P .. "_held_col", "Held Color", { 1, 0.45, 0.35, 1 }, menu_util.parent(P))
end

function M.update(dt)
    if not settings.bool(AIM, false) or not settings.bool(P, false) then
        M._anchor_x, M._anchor_y, M._last_uid = nil, nil, nil
        return
    end

    image_cache.tick_all()

    local target = resolve_target()
    if not target then
        M._anchor_x, M._anchor_y, M._last_uid = nil, nil, nil
        return
    end

    local uid = target.user_id or target.name
    if M._last_uid ~= uid then
        M._anchor_x, M._anchor_y = nil, nil
        M._last_uid = uid
    end

    if settings.bool(P .. "_avatar", true) and target.user_id then
        ensure_avatar(target.user_id)
    end

    local gear = get_gear(target)
    if gear then
        if gear.held then ensure_item_image(gear.held) end
        if settings.bool(P .. "_armor", true) then
            for _, piece in ipairs(gear.armor) do
                ensure_item_image(piece.name, piece.variant)
            end
        end
    end

    local sw, sh = draw_util.screen_size()
    local panel_w, panel_h = measure_panel(target, scale())
    local ax, ay = compute_anchor(target, panel_w, panel_h, sw, sh)
    if not ax then return end

    local speed = settings.num(P .. "_follow", 14)
    local t = math.min(1, dt * speed)

    if not M._anchor_x then
        M._anchor_x, M._anchor_y = ax, ay
    else
        M._anchor_x = lerp(M._anchor_x, ax, t)
        M._anchor_y = lerp(M._anchor_y, ay, t)
    end
end

function M.draw()
    if not settings.bool(AIM, false) or not settings.bool(P, false) then return end
    if not draw or not M._anchor_x then return end

    local target = resolve_target()
    if not target or not target.is_alive then return end

    local px, py = M._anchor_x, M._anchor_y
    local s, layout = scale(), nil
    local panel_w, panel_h
    panel_w, panel_h, layout = measure_panel(target, s)

    local accent = settings.color(P .. "_accent", { 0.35, 0.72, 1, 1 })
    local name_col = settings.color(P .. "_name", { 1, 1, 1, 1 })
    local held_col = settings.color(P .. "_held_col", { 1, 0.45, 0.35, 1 })
    local sub_col = { 0.72, 0.76, 0.82, 1 }
    local panel_bg = { 0.04, 0.05, 0.08, 0.9 }
    local panel_edge = { accent[1], accent[2], accent[3], 0.4 }

    local pad = layout.pad
    local hp = target.health or 0
    local max_hp = target.max_health or 100
    if max_hp <= 0 then max_hp = 100 end
    local hp_ratio = math.max(0, math.min(1, hp / max_hp))
    local hp_col = hp_color(hp_ratio)

    local name = target.name or "Unknown"
    local dist_text = ""
    if settings.bool(P .. "_distance", true) then
        local me = entity and entity.get_local_player and entity.get_local_player()
        if me and me.position and target.position then
            local dx = target.position.x - me.position.x
            local dy = target.position.y - me.position.y
            local dz = target.position.z - me.position.z
            dist_text = string.format("%dm", math.floor(math.sqrt(dx * dx + dy * dy + dz * dz)))
        end
    end

    draw.rect_filled(px, py, panel_w, panel_h, panel_bg)
    draw.rect(px, py, panel_w, panel_h, panel_edge, 1)
    draw.rect_filled(px, py, panel_w, 2, accent)

    local tx = px + pad
    local ty = py + pad

    if layout.show_avatar and target.user_id then
        local av_key = ensure_avatar(target.user_id)
        draw_icon_slot(tx, ty, layout.avatar_sz, av_key, accent)
        tx = tx + layout.avatar_sz + pad
    end

    local info_x = tx
    local info_w = px + panel_w - pad - info_x

    draw.text(info_x, ty, name, name_col, layout.title_fs)

    if dist_text ~= "" then
        local dw = select(1, draw.get_text_size(dist_text, layout.body_fs))
        draw.text(px + panel_w - pad - dw, ty + 1, dist_text, sub_col, layout.body_fs)
    end

    local hp_y = ty + layout.title_fs + 2
    local hp_text = string.format("HP %d / %d", math.ceil(hp), math.ceil(max_hp))
    draw.text(info_x, hp_y, hp_text, hp_col, layout.body_fs)

    local bar_y = hp_y + layout.body_fs + 2
    local bar_h = math.max(3, math.floor(4 * s))
    draw.rect_filled(info_x, bar_y, info_w, bar_h, { 0.15, 0.16, 0.2, 0.9 })
    if hp_ratio > 0 then
        draw.rect_filled(info_x, bar_y, info_w * hp_ratio, bar_h, hp_col)
    end

    local row_y = py + pad + (layout.show_avatar and layout.avatar_sz or math.floor(34 * s)) + pad

    if layout.show_held then
        local held_key = ensure_item_image(layout.held_name)
        draw.text(px + pad, row_y, "Held", sub_col, layout.body_fs)
        draw_icon_slot(px + pad + math.floor(34 * s), row_y - 2, layout.slot_sz + 4, held_key, held_col)
        if layout.held_name then
            local label = layout.held_name
            if #label > 18 then label = label:sub(1, 16) .. ".." end
            draw.text(px + pad + math.floor(34 * s) + layout.slot_sz + 10, row_y + 4, label, held_col, layout.body_fs)
        end
        row_y = row_y + layout.slot_sz + layout.gap + layout.body_fs + 2
    end

    if layout.show_armor then
        draw.text(px + pad, row_y, "Gear", sub_col, layout.body_fs)
        row_y = row_y + layout.body_fs + layout.gap

        local grid_x = px + pad
        for i, piece in ipairs(layout.armor_list) do
            local col_i = (i - 1) % 4
            local row_i = math.floor((i - 1) / 4)
            local sx = grid_x + col_i * (layout.slot_sz + layout.gap)
            local sy = row_y + row_i * (layout.slot_sz + layout.gap)
            local key = ensure_item_image(piece.name, piece.variant)
            draw_icon_slot(sx, sy, layout.slot_sz, key, panel_edge)
        end
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

-- ── features/visuals/bullet_tracers.lua ──
April._mods["features.visuals.bullet_tracers"] = (function()
local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local menu_util = April.require("core.menu_util")
local weapons = April.require("game.weapons")
local cache = April.require("core.cache")
local env = April.require("core.env")

local M = {}
local P = "april_bullet_tracer_enabled"

local tracers = {}
local health_history = {}
local last_shoot_tick = 0
local last_hit_notify = {}

local function tick()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function lerp_color(c1, c2, t)
    return {
        lerp(c1[1] or 1, c2[1] or 1, t),
        lerp(c1[2] or 1, c2[2] or 1, t),
        lerp(c1[3] or 1, c2[3] or 1, t),
        lerp(c1[4] or 1, c2[4] or 1, t),
    }
end

local function gradient_t(mode, speed, u)
    mode = mode or 0
    speed = speed or 1
    if mode == 1 then
        return 0.5 + 0.5 * math.sin(tick() * 0.001 * speed * 3)
    elseif mode == 2 then
        return (tick() * 0.001 * speed + u) % 1
    elseif mode == 3 then
        return math.abs(math.sin(tick() * 0.001 * speed * 2 + u * math.pi))
    end
    return u
end

local function shooting_recently(now)
    if input and input.is_key_down and input.is_key_down(0x01) then return true end
    return (now - last_shoot_tick) < 150
end

local function read_npc_health(npc)
    if not npc or not env.is_valid(npc.inst) then return nil end
    local hum = env.safe_call(function()
        if npc.inst.find_first_child_of_class then
            return npc.inst:find_first_child_of_class("Humanoid")
        end
        return nil
    end)
    if not hum then return nil end
    return hum.Health or hum.health
end

local function npc_hit_pos(npc)
    if npc.head and env.is_valid(npc.head) then
        local pos = npc.head.Position or npc.head.position
        if pos then
            return pos.x or pos.X, pos.y or pos.Y, pos.z or pos.Z
        end
    end
    local scan = April.require("game.esp_scan")
    return scan.label_position({ inst = npc.inst })
end

local function add_tracer(hit_x, hit_y, hit_z)
    if not camera or not camera.get_position then return end
    local cam = camera.get_position()
    if not cam then return end

    local cx = cam.x or cam.X or 0
    local cy = cam.y or cam.Y or 0
    local cz = cam.z or cam.Z or 0

    local stats = weapons.get_weapon_stats()
    local grav = 20
    local spd = 800
    if stats then
        spd = stats.speed or spd
        grav = stats.gravity or grav
        if grav < 5 then
            grav = weapons.drop_gravity(grav)
        end
    end

    local dx = hit_x - cx
    local dy = hit_y - cy
    local dz = hit_z - cz
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    local flight_time = dist / math.max(spd, 1)

    table.insert(tracers, {
        ox = cx, oy = cy, oz = cz,
        tx = hit_x, ty = hit_y, tz = hit_z,
        gravity = grav,
        flight_time = flight_time,
        created = tick(),
    })

    while #tracers > 30 do
        table.remove(tracers, 1)
    end
end

local function on_health_drop(target_id, hit_x, hit_y, hit_z, now)
    local last = last_hit_notify[target_id] or 0
    if now - last < 50 then return end
    last_hit_notify[target_id] = now

    if settings.enabled(P) then
        add_tracer(hit_x, hit_y, hit_z)
    end

    pcall(function()
        local feedback = April.require("features.visuals.feedback")
        if feedback.trigger_hit then feedback.trigger_hit() end
    end)
end

function M.track_hits()
    if not settings.enabled(P)
        and not settings.enabled("april_hitmarker_enabled")
        and not settings.enabled("april_hit_notifier") then
        return
    end

    local now = tick()
    if input and input.is_key_down and input.is_key_down(0x01) then
        last_shoot_tick = now
    end

    if not shooting_recently(now) then
        if entity and entity.get_players then
            for _, p in ipairs(entity.get_players()) do
                if not p.is_local and p.is_alive then
                    local id = p.user_id or p.name or tostring(p)
                    health_history[id] = p.health
                end
            end
        end
        for _, npc in ipairs(cache.npcs or {}) do
            local id = "npc:" .. (npc.name or "") .. ":" .. tostring(npc.inst)
            health_history[id] = read_npc_health(npc)
        end
        return
    end

    if entity and entity.get_players then
        for _, p in ipairs(entity.get_players()) do
            if p.is_local or not p.is_alive then goto next_player end
            local id = p.user_id or p.name or tostring(p)
            local cur = p.health
            local last = health_history[id]
            if type(last) == "number" and type(cur) == "number" and cur < last and cur >= 0 then
                local hx, hy, hz
                if p.head_position then
                    hx, hy, hz = p.head_position.x, p.head_position.y, p.head_position.z
                elseif p.position then
                    hx, hy, hz = p.position.x, p.position.y, p.position.z
                end
                if hx then
                    on_health_drop(id, hx, hy, hz, now)
                end
            end
            health_history[id] = cur
            ::next_player::
        end
    end

    for _, npc in ipairs(cache.npcs or {}) do
        local id = "npc:" .. (npc.name or "") .. ":" .. tostring(npc.inst)
        local cur = read_npc_health(npc)
        local last = health_history[id]
        if type(last) == "number" and type(cur) == "number" and cur < last and cur >= 0 then
            local hx, hy, hz = npc_hit_pos(npc)
            if hx then
                on_health_drop(id, hx, hy, hz, now)
            end
        end
        health_history[id] = cur
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)
    menu_util.section(T, G.VISUALS, "Bullet Tracers")
    menu.add_checkbox(T, G.VISUALS, P, "Bullet Tracers", false, { colorpicker = { 1, 0.6, 0.2, 1 } })
    menu.add_slider_float(T, G.VISUALS, "april_bullet_tracer_lifetime", "Tracer Fade Time", 0.1, 3.0, 0.5, "%.1fs", { parent = P })
    menu.add_slider_int(T, G.VISUALS, "april_bullet_tracer_thickness", "Tracer Thickness", 1, 5, 2, { parent = P })
    menu.add_slider_int(T, G.VISUALS, "april_bullet_tracer_segments", "Tracer Smoothness", 5, 30, 15, { parent = P })
    menu.add_checkbox(T, G.VISUALS, "april_bullet_tracer_gradient", "Tracer Gradient", false, { parent = P, colorpicker = { 0, 0.8, 1, 1 } })
    menu.add_combo(T, G.VISUALS, "april_bullet_tracer_grad_anim", "Gradient Animation", { "Static", "Pulse", "Cycle", "Bounce" }, 0, { parent = "april_bullet_tracer_gradient" })
    menu.add_slider_float(T, G.VISUALS, "april_bullet_tracer_grad_speed", "Gradient Speed", 0.1, 10.0, 1.0, "%.1f", { parent = "april_bullet_tracer_gradient" })
end

function M.update(dt)
    if settings.enabled(P)
        or settings.enabled("april_hitmarker_enabled")
        or settings.enabled("april_hit_notifier") then
        M.track_hits()
    end

    if not settings.enabled(P) then
        if #tracers > 0 then tracers = {} end
        return
    end

    local now = tick()
    local lifetime_ms = settings.num("april_bullet_tracer_lifetime", 0.5) * 1000
    local i = 1
    while i <= #tracers do
        if now - tracers[i].created > lifetime_ms then
            table.remove(tracers, i)
        else
            i = i + 1
        end
    end
end

function M.draw()
    if not settings.enabled(P) or #tracers == 0 then return end

    local now = tick()
    local color = settings.color(P, { 1, 0.6, 0.2, 1 })
    local thickness = settings.num("april_bullet_tracer_thickness", 2)
    local num_segs = settings.num("april_bullet_tracer_segments", 15)
    local lifetime_ms = settings.num("april_bullet_tracer_lifetime", 0.5) * 1000
    local use_grad = settings.enabled("april_bullet_tracer_gradient")
    local color2 = settings.color("april_bullet_tracer_gradient", { 0, 0.8, 1, 1 })
    local grad_anim = settings.num("april_bullet_tracer_grad_anim", 0)
    local grad_speed = settings.num("april_bullet_tracer_grad_speed", 1)

    for _, tr in ipairs(tracers) do
        local elapsed_ms = now - tr.created
        local alpha = 1.0 - (elapsed_ms / lifetime_ms)
        if alpha <= 0 then goto next_tracer end

        local prev_sx, prev_sy, prev_vis = nil, nil, false
        local cr, cg, cb, ca = color[1], color[2], color[3], color[4] or 1
        local arc_peak = 0.5 * tr.gravity * tr.flight_time * tr.flight_time

        for seg = 0, num_segs do
            local u = seg / num_segs
            local px = tr.ox + (tr.tx - tr.ox) * u
            local py = tr.oy + (tr.ty - tr.oy) * u + arc_peak * u * (1 - u)
            local pz = tr.oz + (tr.tz - tr.oz) * u

            local sx, sy, vis = esp_util.w2s(px, py, pz)

            if seg > 0 and vis and prev_vis then
                local seg_alpha = (0.3 + 0.7 * u) * alpha * ca
                if use_grad then
                    local gt = gradient_t(grad_anim, grad_speed, u)
                    local gc = lerp_color(color, color2, gt)
                    draw_util.line(prev_sx, prev_sy, sx, sy, { gc[1], gc[2], gc[3], seg_alpha }, thickness)
                else
                    draw_util.line(prev_sx, prev_sy, sx, sy, { cr, cg, cb, seg_alpha }, thickness)
                end
            end

            prev_sx, prev_sy, prev_vis = sx, sy, vis
        end

        ::next_tracer::
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
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local maps = April.require("game.esp_maps")
local esp_scan = April.require("game.esp_scan")

local M = {}
local P = "april_world_enabled"

M._static = {}
M._dynamic = {}

local TOGGLES = {
    { id = "april_stone_node", label = "Stone Node", color = { 0.5, 0.5, 0.5, 1 } },
    { id = "april_metal_node", label = "Metal Node", color = { 0.7, 0.5, 0.3, 1 } },
    { id = "april_phosphate_node", label = "Phosphate Node", color = { 0.2, 0.8, 0.2, 1 } },
    { id = "april_corn_plant", label = "Corn Plant", color = { 1, 0.9, 0.3, 1 } },
    { id = "april_tomato_plant", label = "Tomato Plant", color = { 1, 0.4, 0.3, 1 } },
    { id = "april_pumpkin_plant", label = "Pumpkin Plant", color = { 1, 0.5, 0.1, 1 } },
    { id = "april_deer", label = "Deer", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_boar", label = "Wild Boar", color = { 0.4, 0.3, 0.2, 1 } },
    { id = "april_wolf", label = "Wolf", color = { 0.5, 0.5, 0.5, 1 } },
}

local function scan_folder(map, label_map, dynamic)
    local out = {}
    local key = map == maps.NODE_MAP and "nodes" or (map == maps.PLANT_MAP and "plants" or "animals")
    local folder = folders.from_key(key)
    if not env.is_valid(folder) then return out end

    local children = env.safe_call(function() return folder:get_children() end) or {}
    for _, model in ipairs(children) do
        if not env.is_valid(model) then goto continue end
        local name = model.Name or model.name
        local toggle_id = name and map[name]
        if toggle_id then
            local label = (label_map and label_map[name]) or name
            table.insert(out, esp_scan.make_entry(model, label, toggle_id, { dynamic = dynamic }))
        end
        ::continue::
    end
    return out
end

local function rebuild_cache()
    cache.world = {}
    for _, entry in ipairs(M._static) do
        table.insert(cache.world, entry)
    end
    for _, entry in ipairs(M._dynamic) do
        table.insert(cache.world, entry)
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    menu.add_label(T, G.WORLD, "Resources & Nodes")
    menu.add_checkbox(T, G.WORLD, P, "Enable World ESP", false, { key = 0 })
    for _, t in ipairs(TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
    end
    menu.add_checkbox(T, G.WORLD, "april_world_boxes", "3D Boxes", false, { parent = P })
    menu.add_slider_int(T, G.WORLD, "april_world_range", "World Range", 50, 2000, 500, { parent = P })
end

local function toggle_color(toggle_id)
    for _, t in ipairs(TOGGLES) do
        if t.id == toggle_id then
            return settings.color(toggle_id, t.color)
        end
    end
    return settings.color(toggle_id, { 1, 1, 1, 1 })
end

function M.scan_static()
    M._static = {}
    for _, entry in ipairs(scan_folder(maps.NODE_MAP, maps.NODE_LABELS, false)) do
        table.insert(M._static, entry)
    end
    for _, entry in ipairs(scan_folder(maps.PLANT_MAP, maps.PLANT_LABELS, false)) do
        table.insert(M._static, entry)
    end
    rebuild_cache()
    cache.stats.last_world_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.scan_dynamic()
    M._dynamic = scan_folder(maps.ANIMAL_MAP, maps.ANIMAL_LABELS, true)
    rebuild_cache()
end

function M.scan()
    M.scan_static()
    M.scan_dynamic()
end

function M.update(dt) end

function M.draw()
    if not settings.enabled(P) then return end

    local range = settings.num("april_world_range", 500)
    local draw_boxes = settings.enabled("april_world_boxes")
    local me = env.get_local_player()
    local text_size = esp_util.text_size()

    for _, entry in ipairs(cache.world) do
        if not settings.enabled(entry.toggle_id) then goto continue end
        if not env.is_valid(entry.inst) then goto continue end

        local lx, ly, lz = esp_scan.label_position(entry)
        if not lx then goto continue end

        if me and me.position then
            local dx = lx - me.position.x
            local dy = ly - me.position.y
            local dz = lz - me.position.z
            if math.sqrt(dx * dx + dy * dy + dz * dz) > range then goto continue end
        end

        local col = toggle_color(entry.toggle_id)
        if draw_boxes then
            esp_util.draw_entry_boxes(entry, col, 1)
        end

        local sx, sy, vis = esp_util.w2s(lx, ly, lz)
        if vis then
            local label = entry.name or "?"
            if me and me.position then
                local dx = lx - me.position.x
                local dy = ly - me.position.y
                local dz = lz - me.position.z
                label = string.format("%s [%dm]", label, math.floor(math.sqrt(dx * dx + dy * dy + dz * dz)))
            end
            draw_util.text_centered(sx, sy, label, col, text_size)
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

local TOGGLES = {
    { id = "april_dropped_item", label = "Dropped Items", color = { 1, 0.8, 0, 1 } },
    { id = "april_wooden_crate", label = "Wooden Crate", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_metal_crate", label = "Metal Crate", color = { 0.5, 0.5, 0.6, 1 } },
    { id = "april_steel_crate", label = "Steel Crate", color = { 0.7, 0.7, 0.8, 1 } },
    { id = "april_food_crate", label = "Food Crate", color = { 0.2, 0.8, 0.2, 1 } },
    { id = "april_timed_crate", label = "Timed Crate", color = { 1, 0.5, 0, 1 } },
    { id = "april_care_package", label = "Care Package", color = { 1, 0.2, 0.2, 1 } },
    { id = "april_body_bag", label = "Body Bag", color = { 0.3, 0.3, 0.3, 1 } },
    { id = "april_sleeper", label = "Sleepers", color = { 0.8, 0.4, 0.8, 1 } },
    { id = "april_trash_can", label = "Trash Can", color = { 0.45, 0.45, 0.45, 1 } },
    { id = "april_oil_barrel", label = "Oil Barrel", color = { 0.2, 0.2, 0.2, 1 } },
}

local function toggle_color(toggle_id)
    for _, t in ipairs(TOGGLES) do
        if t.id == toggle_id then
            return settings.color(toggle_id, t.color)
        end
    end
    return settings.color(toggle_id, { 1, 1, 1, 1 })
end

local function append_loot_model(out, model, base_name, toggle_id, dynamic)
    if not env.is_valid(model) then return end

    local display = base_name
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
        if label then display = label end
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
        if extra then display = base_name .. " (" .. extra .. ")" end
    end

    table.insert(out, esp_scan.make_entry(model, display, toggle_id, { dynamic = dynamic }))
end

local function scan_named_loot_folder(folder, out)
    if not env.is_valid(folder) then return end
    local children = env.safe_call(function() return folder:get_children() end) or {}
    for _, model in ipairs(children) do
        if not env.is_valid(model) then goto continue end
        local name = model.Name or model.name
        local toggle_id = name and maps.LOOT_MAP[name]
        if toggle_id then
            append_loot_model(out, model, name, toggle_id, false)
        end
        ::continue::
    end
end

local function collect_drops(out)
    local drops = folders.from_key("drops")
    if not env.is_valid(drops) then return end
    local children = env.safe_call(function() return drops:get_children() end) or {}
    for _, model in ipairs(children) do
        if not env.is_valid(model) then goto continue end
        local name = model.Name or model.name
        if name and name ~= "" then
            append_loot_model(out, model, name, "april_dropped_item", true)
        end
        ::continue::
    end
end

local function collect_loners(out)
    local loners = folders.from_key("loners")
    if not env.is_valid(loners) then return end
    local children = env.safe_call(function() return loners:get_children() end) or {}
    for _, child in ipairs(children) do
        if not env.is_valid(child) then goto continue end
        local name = child.Name or child.name
        local toggle_id = name and maps.LOOT_MAP[name]
        if not toggle_id then goto continue end

        local cn = child.ClassName or child.class_name
        if cn == "Model" then
            append_loot_model(out, child, name, toggle_id, false)
        else
            local subs = env.safe_call(function() return child:get_children() end) or {}
            for _, model in ipairs(subs) do
                append_loot_model(out, model, name, toggle_id, false)
            end
        end
        ::continue::
    end
end

local function rebuild_cache()
    cache.loot = {}
    for _, entry in ipairs(M._static) do
        table.insert(cache.loot, entry)
    end
    for _, entry in ipairs(M._drops) do
        table.insert(cache.loot, entry)
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    menu_util.section(T, G.WORLD, "Loot ESP")
    menu.add_checkbox(T, G.WORLD, P, "Enable Loot ESP", false, { key = 0 })
    for _, t in ipairs(TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
    end
    menu.add_checkbox(T, G.WORLD, "april_loot_boxes", "3D Boxes", false, { parent = P })
    menu.add_slider_int(T, G.WORLD, "april_loot_range", "Loot Range", 50, 2000, 300, { parent = P })
end

function M.scan_drops()
    M._drops = {}
    collect_drops(M._drops)
    rebuild_cache()
end

function M.scan_static()
    M._static = {}
    collect_loners(M._static)
    scan_named_loot_folder(folders.from_key("vegetation"), M._static)
    scan_named_loot_folder(folders.from_key("military"), M._static)
    scan_named_loot_folder(folders.from_key("events"), M._static)
    rebuild_cache()
    cache.stats.last_loot_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.scan()
    M.scan_static()
    M.scan_drops()
end

function M.update(dt) end

function M.draw()
    if not settings.enabled(P) then return end

    local range = settings.num("april_loot_range", 300)
    local draw_boxes = settings.enabled("april_loot_boxes")
    local me = env.get_local_player()
    local text_size = esp_util.text_size()

    for _, entry in ipairs(cache.loot) do
        if not settings.enabled(entry.toggle_id) then goto continue end
        if not env.is_valid(entry.inst) then goto continue end

        local lx, ly, lz = esp_scan.label_position(entry)
        if not lx then goto continue end

        local dist = 0
        if me and me.position then
            local dx = lx - me.position.x
            local dy = ly - me.position.y
            local dz = lz - me.position.z
            dist = math.sqrt(dx * dx + dy * dy + dz * dz)
            local unlimited = entry.toggle_id == "april_timed_crate"
                or entry.toggle_id == "april_care_package"
            if not unlimited and dist > range then goto continue end
        end

        local col = toggle_color(entry.toggle_id)
        if draw_boxes then
            esp_util.draw_entry_boxes(entry, col, 1)
        end

        local sx, sy, vis = esp_util.w2s(lx, ly, lz)
        if vis then
            local label = entry.name or "Loot"
            if me and me.position then
                label = string.format("%s [%dm]", label, math.floor(dist))
            end
            draw_util.text_centered(sx, sy, label, col, text_size)
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
local esp_scan = April.require("game.esp_scan")

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
    menu.add_checkbox(T, G.WORLD, P, "Enable Base ESP", false, { key = 0 })
    for _, t in ipairs(TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
    end
    menu.add_checkbox(T, G.WORLD, "april_base_boxes", "3D Boxes", false, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_base_distance", "Show Distance", false, { parent = P })
    menu.add_slider_int(T, G.WORLD, "april_base_range", "Base Range", 50, 500, 150, { parent = P })
end

local function match_toggle_id(name)
    name = name or ""
    for _, t in ipairs(TOGGLES) do
        if name:find(t.match, 1, true) then
            return t.id
        end
    end
    return nil
end

function M.scan()
    cache.base = {}
    folders.iter_workspace_folders({ "bases", "deployables" }, function(key, folder)
        local found = folders.scan_descendants(folder, nil, 300)
        for _, inst in ipairs(found) do
            local toggle_id = match_toggle_id(inst.Name)
            if toggle_id then
                table.insert(cache.base, esp_scan.make_entry(inst, inst.Name, toggle_id))
            end
        end
    end)
    cache.stats.last_base_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.enabled(P) then return end
    local range = settings.num("april_base_range", 150)
    local draw_boxes = settings.enabled("april_base_boxes")
    local me = env.get_local_player()
    local text_size = esp_util.text_size()

    for _, entry in ipairs(cache.base) do
        if not settings.enabled(entry.toggle_id) then goto continue end
        if not env.is_valid(entry.inst) then goto continue end

        local lx, ly, lz = esp_scan.label_position(entry)
        if not lx then goto continue end

        local dist = 0
        if me and me.position then
            local dx = lx - me.position.x
            local dy = ly - me.position.y
            local dz = lz - me.position.z
            dist = math.sqrt(dx * dx + dy * dy + dz * dz)
            if dist > range then goto continue end
        end

        local col = settings.color(entry.toggle_id, { 1, 1, 1, 1 })
        if draw_boxes then
            esp_util.draw_entry_boxes(entry, col, 1)
        end

        local sx, sy, vis = esp_util.w2s(lx, ly, lz)
        if vis then
            local label = entry.name or "Base"
            if settings.bool("april_base_distance", false) and me and me.position then
                label = string.format("%s [%dm]", label, math.floor(dist))
            end
            draw_util.text_centered(sx, sy, label, col, text_size)
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

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    local root = menu_util.parent(P)

    menu_util.section(T, G.WORLD, "NPC ESP")
    menu.add_checkbox(T, G.WORLD, P, "Enable NPC ESP", false, { key = 0, colorpicker = { 1, 0.3, 0.3, 1 } })
    menu.add_checkbox(T, G.WORLD, "april_npc_soldiers", "Soldiers", false, menu_util.parent(P, { colorpicker = { 1, 0.3, 0.3, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_bosses", "Bosses (Bruno / Boris / Brutus)", false, menu_util.parent(P, { colorpicker = { 1, 0.5, 0.1, 1 } }))
    menu.add_combo(T, G.WORLD, "april_npc_box_mode", "NPC Box Mode", { "None", "2D", "Corner" }, 0, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_health", "Health Bar", false, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_name", "Name", false, menu_util.parent(P, { colorpicker = { 1, 1, 1, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_distance", "Distance", false, menu_util.parent(P, { colorpicker = { 0.7, 0.7, 0.7, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_skeleton", "Skeleton", false, menu_util.parent(P, { colorpicker = { 1, 1, 1, 0.85 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_offscreen", "Offscreen Arrows", false, menu_util.parent(P, { colorpicker = { 1, 0.3, 0.3, 1 } }))
    menu.add_slider_int(T, G.WORLD, "april_npc_range", "NPC Range", 50, 2000, 500, root)
end

function M.scan()
    cache.npcs = npcs.scan()
    cache.stats.last_npc_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
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
        if not kind_enabled(entry.kind) then goto continue end
        if not env.is_valid(entry.inst) then goto continue end

        local col = kind_color(entry.kind)
        local head = entry.head
        local pos = head and (head.Position or head.position)
        if not pos or pos.x == nil then
            pos = entry.inst.Position or entry.inst.position
        end
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

-- ── features/utility/mod_checker.lua ──
April._mods["features.utility.mod_checker"] = (function()
local settings = April.require("core.settings")
local notify = April.require("core.notify")
local mod_ids = April.require("game.mod_ids")
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_mod_checker_enabled"
local seen = {}
local last_scan = 0
local SCAN_MS = 2500

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    menu_util.section(T, G.MISC, "Mod Checker")
    menu.add_checkbox(T, G.MISC, P, "Mod Checker", false, { key = 0 })
    menu.add_slider_int(T, G.MISC, "april_mod_checker_interval", "Scan Interval (ms)", 1000, 10000, 2500, { parent = P })
end

local function player_label(p)
    if not p then return "Unknown" end
    if p.display_name and p.display_name ~= "" then return p.display_name end
    return p.name or "Unknown"
end

function M.check_player(p)
    if not settings.enabled(P) then return end
    if not p or p.is_local then return end

    local uid = p.user_id
    if not uid or uid == 0 then return end

    local role = mod_ids.role_for(uid)
    if not role then return end
    if seen[uid] then return end

    seen[uid] = true
    local label = player_label(p)
    notify.warning(string.format("MOD: %s (%s) — %s", label, p.name or "?", role), 6000)
end

function M.scan_all()
    if not settings.enabled(P) then return end
    if not entity or not entity.get_players then return end

    for _, p in ipairs(entity.get_players()) do
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
    end
end

function M.update(dt)
    if not settings.enabled(P) then
        seen = {}
        return
    end

    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    local interval = settings.num("april_mod_checker_interval", SCAN_MS)
    if now - last_scan >= interval then
        last_scan = now
        M.scan_all()
    end
end

function M.draw() end

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
    "features.visuals.target_overlay",
    "features.visuals.crosshair",
    "features.visuals.feedback",
    "features.visuals.bullet_tracers",
    "features.world.world_esp",
    "features.world.loot_esp",
    "features.world.npc_esp",
    "features.world.base_esp",
    "features.radar.waypoints",
    "features.radar.tactical_map",
    "features.movement.exploits",
    "features.utility.mod_checker",
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
    scheduler.register("world", 1500, function() world_esp.scan_static() end)
    scheduler.register("world_dynamic", 200, function() world_esp.scan_dynamic() end)
    scheduler.register("loot", 1500, function() loot_esp.scan_static() end)
    scheduler.register("loot_drops", 100, function() loot_esp.scan_drops() end)
    scheduler.register("base", 1000, function() base_esp.scan() end)
    scheduler.register("npcs", 400, function() npc_esp.scan() end)
    scheduler.start_all()
end

function M.update(dt)
    bootstrap.tick()

    local image_cache = April.require("core.image_cache")
    image_cache.tick_all()

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

    local player_esp = April.require("features.visuals.player_esp")
    if player_esp.init then player_esp.init() end

    M.setup_player_hooks()

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
