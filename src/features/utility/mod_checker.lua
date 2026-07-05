local settings = April.require("core.settings")
local notify = April.require("core.notify")
local mod_ids = April.require("game.mod_ids")
local menu_util = April.require("core.menu_util")
local draw_util = April.require("core.draw_util")
local env = April.require("core.env")
local esp_util = April.require("core.esp_util")
local image_cache = April.require("core.image_cache")
local asset_urls = April.require("game.asset_urls")

local M = {}
local P = "april_mod_checker_enabled"
local MOD_ICON_KEY = "mod_warning"
local ICON_SIZE = 28
local HEAD_OFFSET = 3.5

local seen = {}
local active = {}
local last_scan = 0
local SCAN_MS = 2500

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
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

local function role_accent(role)
    if not role then return { 1, 0.75, 0.2, 1 } end
    local r = role:lower()
    if r:find("founder") or r:find("developer") then
        return { 0.95, 0.45, 1, 1 }
    end
    if r:find("moderator") then
        return { 1, 0.35, 0.35, 1 }
    end
    return { 0.35, 0.75, 1, 1 }
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
        active[uid] = nil
    end
end

function M.update(_dt)
    if not settings.enabled(P) then
        seen = {}
        active = {}
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
    if not draw or not draw.text then return end

    image_cache.begin_load(MOD_ICON_KEY)

    for _, p in ipairs(entity.get_players()) do
        if p.is_local then goto continue end

        local uid = p.user_id
        if not uid or uid == 0 then goto continue end
        if not mod_ids.role_for(uid) then goto continue end

        local wx, wy, wz = head_world_pos(p)
        if not wx then goto continue end

        local sx, sy, vis = esp_util.w2s(wx, wy, wz)
        if not vis then goto continue end

        local label = "[MOD]"
        local text_w = #label * 7
        local gap = 4
        local total_w = ICON_SIZE + gap + text_w
        local x = math.floor(sx - total_w * 0.5)
        local y = math.floor(sy - ICON_SIZE - 6)

        image_cache.draw_fit(MOD_ICON_KEY, x, y, ICON_SIZE, ICON_SIZE)
        draw.text(x + ICON_SIZE + gap, y + 7, label, { 1, 0.72, 0.18, 1 }, 12)

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
        local dist = nil
        for _, p in ipairs(entity and entity.get_players and entity.get_players() or {}) do
            if p.user_id == uid then
                if me and me.position and p.position then
                    local dx = p.position.x - me.position.x
                    local dy = p.position.y - me.position.y
                    local dz = p.position.z - me.position.z
                    dist = math.floor(math.sqrt(dx * dx + dy * dy + dz * dz))
                end
                break
            end
        end
        rows[#rows + 1] = {
            entry = entry,
            dist = dist,
            duration = format_duration(now - (entry.first_seen or now)),
        }
    end

    if #rows == 0 then return end

    table.sort(rows, function(a, b)
        return (a.entry.first_seen or 0) < (b.entry.first_seen or 0)
    end)

    local sw, sh = draw_util.screen_size()
    local pad = 12
    local row_h = 54
    local title_h = 28
    local width = 250
    local x = sw - width - 18
    local count = math.min(#rows, 4)
    local height = title_h + count * row_h + pad

    if draw.rect_filled then
        draw.rect_filled(x, 72, width, height, { 0.04, 0.05, 0.08, 0.88 })
    end
    if draw.rect then
        draw.rect(x, 72, width, height, { 1, 1, 1, 0.08 }, 0, 1)
    end
    if draw.line then
        draw.line(x, 72, x, 72 + height, { 1, 0.45, 0.35, 0.95 }, 3)
    end

    draw.text(x + pad, 78, "Staff In Lobby", { 0.92, 0.94, 0.98, 1 }, 13)

    local y = 72 + title_h
    for i = 1, count do
        local row = rows[i]
        local entry = row.entry
        local accent = role_accent(entry.role)

        if draw.line then
            draw.line(x + pad, y, x + width - pad, y, { 1, 1, 1, 0.06 }, 1)
        end

        if draw.circle_filled then
            draw.circle_filled(x + pad + 4, y + 16, 4, accent, 12)
        end

        local name = entry.label
        if #name > 18 then name = name:sub(1, 16) .. ".." end
        draw.text(x + pad + 14, y + 4, name, { 1, 1, 1, 0.96 }, 13)

        local role_text = entry.role or "Staff"
        if #role_text > 22 then role_text = role_text:sub(1, 20) .. ".." end
        draw.text(x + pad + 14, y + 20, role_text, { accent[1], accent[2], accent[3], 0.85 }, 11)

        local meta = row.duration
        if row.dist then
            meta = meta .. "  ·  " .. row.dist .. "m"
        end
        draw.text(x + pad + 14, y + 34, meta, { 0.65, 0.68, 0.74, 0.9 }, 11)

        y = y + row_h
    end
end

return M
