local settings = April.require("core.settings")
local esp_util = April.require("core.esp_util")
local menu_util = April.require("core.menu_util")
local notify = April.require("core.notify")

local M = {}

local P = "april_hitmarker_enabled"
local P_NOTIFY = "april_hit_notify_enabled"

local world_hits = {}

local function tick()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function format_part(name)
    if not name or name == "" then return "body" end
    return name:gsub("(%l)(%u)", "%1 %2"):lower()
end

local function show_hit_toast(hit)
    if not settings.enabled(P_NOTIFY) then return end

    local dmg = math.floor((hit.damage or 0) + 0.5)
    if dmg <= 0 then return end

    local dist = math.floor(hit.distance or 0)
    local part = format_part(hit.part)
    local hp_left = ""
    if hit.health and hit.max_health and hit.max_health > 0 then
        hp_left = string.format(" - %d HP left", math.floor(hit.health))
    end

    local msg
    if hit.is_player then
        msg = string.format("Hit %s - %d dmg - %dm - %s%s", hit.name, dmg, dist, part, hp_left)
    else
        msg = string.format("Hit %s - %d dmg - %s", hit.name, dmg, part)
    end

    notify.toast(msg, "danger", settings.num("april_hit_notify_duration", 1000), true)
end

function M.on_hit(hit)
    if not hit or not hit.hx then return end

    table.insert(world_hits, {
        hx = hit.hx,
        hy = hit.hy,
        hz = hit.hz,
        time = tick(),
    })
    while #world_hits > 12 do
        table.remove(world_hits, 1)
    end

    show_hit_toast(hit)
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)
    local notify_root = menu_util.parent(P_NOTIFY)

    menu_util.section(T, G.VISUALS, "Hitmarkers")
    menu.add_checkbox(T, G.VISUALS, P, "Hitmarker", false, { colorpicker = { 1, 1, 1, 1 } })
    menu.add_checkbox(T, G.VISUALS, "april_hitmarker_at_impact", "At Impact Point", true, { parent = P })
    menu.add_checkbox(T, G.VISUALS, "april_hitmarker_glow", "Hitmarker Glow", false, { parent = P })
    menu.add_slider_int(T, G.VISUALS, "april_hitmarker_size", "Hitmarker Size", 1, 20, 5, { parent = P })
    menu.add_slider_int(T, G.VISUALS, "april_hitmarker_duration", "Duration (ms)", 100, 2000, 500, { parent = P })

    menu_util.section(T, G.VISUALS, "Hit Notifications")
    menu.add_checkbox(T, G.VISUALS, P_NOTIFY, "Hit Toasts", false)
    menu.add_label(T, G.VISUALS, "Shows damage, distance, and body part.", notify_root)
    menu.add_slider_int(T, G.VISUALS, "april_hit_notify_duration", "Toast Duration (ms)", 500, 3000, 1000, notify_root)
end

function M.trigger_hit()
    M.on_hit({
        hx = 0, hy = 0, hz = 0,
        damage = 0,
        name = "",
        is_player = false,
    })
end

function M.update(_dt)
    if not settings.bool(P, false) then
        if #world_hits > 0 then world_hits = {} end
        return
    end

    local now = tick()
    local dur = settings.num("april_hitmarker_duration", 500)
    local i = 1
    while i <= #world_hits do
        if now - world_hits[i].time > dur then
            table.remove(world_hits, i)
        else
            i = i + 1
        end
    end
end

function M.draw()
    if not settings.bool(P, false) or #world_hits == 0 then return end

    local now = tick()
    local dur = settings.num("april_hitmarker_duration", 500)
    local col = settings.color(P, { 1, 1, 1, 1 })
    local size_studs = settings.num("april_hitmarker_size", 5) * 0.08
    local thick = 2

    for _, hit in ipairs(world_hits) do
        local age = now - hit.time
        if age > dur then goto next_hit end

        local alpha = 1 - (age / dur)
        local c = { col[1], col[2], col[3], (col[4] or 1) * alpha }

        if settings.bool("april_hitmarker_at_impact", true) and hit.hx then
            esp_util.draw_world_cross(hit.hx, hit.hy, hit.hz, size_studs, c, thick)

            if settings.bool("april_hitmarker_glow", false) then
                local sx, sy, vis = esp_util.w2s(hit.hx, hit.hy, hit.hz)
                if vis and draw and draw.circle_filled then
                    draw.circle_filled(sx, sy, size_studs * 12, { c[1], c[2], c[3], c[4] * 0.25 }, 12)
                end
            end
        end

        ::next_hit::
    end
end

return M
