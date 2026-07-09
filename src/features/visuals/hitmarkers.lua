-- Screen hitmarkers (draw only). Triggered by HP drop / game HitMarker flash.

local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local combat_target = April.require("game.combat_target")
local env = April.require("core.env")
local draw_util = April.require("core.draw_util")

local M = {}

local P = "april_hitmarkers"
local markers = {}
local last_hp = {}
local last_spawn = 0
local hitmarker_was = false
local MAX = 12

local STYLES = { "Cross", "X", "Dot", "Bracket" }

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function spawn(is_head)
    local now = tick_ms()
    if now - last_spawn < 30 then return end
    last_spawn = now
    while #markers >= MAX do table.remove(markers, 1) end
    markers[#markers + 1] = {
        born = now,
        life = settings.num("april_hitmarkers_life", 280),
        head = is_head == true,
    }
end

local function watch_hp()
    local tgt = combat_target.get()
    if not tgt or tgt.health == nil then return end
    local uid = tostring(tgt.user_id or tgt.name or "?")
    local prev = last_hp[uid]
    last_hp[uid] = tgt.health
    if prev and tgt.health < prev - 0.35 then
        local max_hp = tgt.max_health or 100
        local drop = prev - tgt.health
        spawn(drop >= (max_hp * 0.35) or drop >= 40)
    end
end

local function watch_game_hitmarker()
    local lp = env.get_local_player and env.get_local_player()
    if not lp then return end
    local pg = env.safe_call(function()
        return lp.PlayerGui
            or (lp.find_first_child and lp:find_first_child("PlayerGui"))
            or (lp.FindFirstChild and lp:FindFirstChild("PlayerGui"))
    end)
    if not pg then return end
    local main = env.safe_call(function()
        return pg:FindFirstChild("Main") or (pg.find_first_child and pg:find_first_child("Main"))
    end)
    if not main then return end
    local hm = env.safe_call(function()
        return main:FindFirstChild("HitMarker") or (main.find_first_child and main:find_first_child("HitMarker"))
    end)
    if not hm then return end
    local vis = env.safe_call(function() return hm.Visible end)
    if vis and not hitmarker_was then
        local rot = env.safe_call(function() return hm.Rotation end)
        -- Game uses red children for headshots; Rotation alone isn't enough — treat as body.
        spawn(false)
        local ok, tracers = pcall(function()
            return April.require("features.visuals.bullet_tracers")
        end)
        if ok and tracers and tracers.notify_hit then tracers.notify_hit() end
    end
    hitmarker_was = vis and true or false
end

function M.register_menu()
    local G = menu_util.G
    local T = menu_util.group(G.VISUALS)
    local root = menu_util.parent(P)

    menu.add_checkbox(T, G.VISUALS, P, "Hitmarkers", false, {
        colorpicker = { 1, 1, 1, 0.95 },
    })
    menu.add_checkbox(T, G.VISUALS, "april_hitmarkers_head", "Headshot Color", true, {
        parent = P,
        colorpicker = { 1, 0.2, 0.2, 1 },
    })
    menu.add_combo(T, G.VISUALS, "april_hitmarkers_style", "Style", STYLES, 0, root)

    menu_util.gap(T, G.VISUALS)
    menu.add_slider_int(T, G.VISUALS, "april_hitmarkers_size", "Size", 4, 28, 10, root)
    menu.add_slider_int(T, G.VISUALS, "april_hitmarkers_gap", "Gap", 0, 12, 3, root)
    menu.add_slider_int(T, G.VISUALS, "april_hitmarkers_life", "Life (ms)", 80, 800, 280, root)
    menu.add_slider_int(T, G.VISUALS, "april_hitmarkers_thick", "Thickness", 1, 4, 2, root)

    menu_util.bind_children(P, {
        "april_hitmarkers_head", "april_hitmarkers_style",
        "april_hitmarkers_size", "april_hitmarkers_gap",
        "april_hitmarkers_life", "april_hitmarkers_thick",
    })
end

function M.update(_dt)
    if not settings.enabled(P) then
        markers = {}
        hitmarker_was = false
        return
    end
    watch_hp()
    watch_game_hitmarker()

    local now = tick_ms()
    local i = 1
    while i <= #markers do
        if now - markers[i].born > markers[i].life then
            table.remove(markers, i)
        else
            i = i + 1
        end
    end
end

local function draw_cross(cx, cy, size, gap, thick, col)
    local s = size
    local g = gap
    draw_util.line(cx - s, cy, cx - g, cy, col, thick)
    draw_util.line(cx + g, cy, cx + s, cy, col, thick)
    draw_util.line(cx, cy - s, cx, cy - g, col, thick)
    draw_util.line(cx, cy + g, cx, cy + s, col, thick)
end

local function draw_x(cx, cy, size, gap, thick, col)
    local s = size * 0.75
    local g = gap * 0.7
    draw_util.line(cx - s, cy - s, cx - g, cy - g, col, thick)
    draw_util.line(cx + g, cy + g, cx + s, cy + s, col, thick)
    draw_util.line(cx + s, cy - s, cx + g, cy - g, col, thick)
    draw_util.line(cx - g, cy + g, cx - s, cy + s, col, thick)
end

local function draw_bracket(cx, cy, size, gap, thick, col)
    local s = size
    local g = gap
    local arm = s * 0.45
    draw_util.line(cx - s, cy - s, cx - s, cy - g, col, thick)
    draw_util.line(cx - s, cy - s, cx - s + arm, cy - s, col, thick)
    draw_util.line(cx - s, cy + g, cx - s, cy + s, col, thick)
    draw_util.line(cx - s, cy + s, cx - s + arm, cy + s, col, thick)
    draw_util.line(cx + s, cy - s, cx + s, cy - g, col, thick)
    draw_util.line(cx + s, cy - s, cx + s - arm, cy - s, col, thick)
    draw_util.line(cx + s, cy + g, cx + s, cy + s, col, thick)
    draw_util.line(cx + s, cy + s, cx + s - arm, cy + s, col, thick)
end

function M.draw()
    if not settings.enabled(P) then return end
    if #markers == 0 then return end

    local sw, sh = draw_util.screen_size()
    local cx, cy = sw * 0.5, sh * 0.5
    local style = settings.num("april_hitmarkers_style", 0)
    local size = settings.num("april_hitmarkers_size", 10)
    local gap = settings.num("april_hitmarkers_gap", 3)
    local thick = settings.num("april_hitmarkers_thick", 2)
    local body_col = settings.color(P, { 1, 1, 1, 0.95 })
    local head_col = settings.color("april_hitmarkers_head", { 1, 0.2, 0.2, 1 })
    local now = tick_ms()

    for i = 1, #markers do
        local m = markers[i]
        local a = 1 - ((now - m.born) / math.max(1, m.life))
        if a <= 0 then goto continue end
        local expand = 1 + (1 - a) * 0.35
        local col = m.head and head_col or body_col
        col = { col[1], col[2], col[3], (col[4] or 1) * a }
        local s = size * expand
        local g = gap

        if style == 1 then
            draw_x(cx, cy, s, g, thick, col)
        elseif style == 2 then
            draw_util.circle(cx, cy, 2 + s * 0.15, col, true)
        elseif style == 3 then
            draw_bracket(cx, cy, s, g, thick, col)
        else
            draw_cross(cx, cy, s, g, thick, col)
        end
        ::continue::
    end
end

return M
