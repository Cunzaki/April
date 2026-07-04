local settings = April.require("core.settings")
local esp_util = April.require("core.esp_util")
local menu_util = April.require("core.menu_util")
local hit_tracker = April.require("game.hit_tracker")

local M = {}
local P = "april_bullet_tracer_enabled"

local tracers = {}

local function tick()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function add_tracer(ox, oy, oz, tx, ty, tz)
    table.insert(tracers, {
        ox = ox, oy = oy, oz = oz,
        tx = tx, ty = ty, tz = tz,
        created = tick(),
    })
    while #tracers > 16 do
        table.remove(tracers, 1)
    end
end

local function on_hit(hit)
    if settings.enabled(P) then
        add_tracer(hit.ox, hit.oy, hit.oz, hit.hx, hit.hy, hit.hz)
    end

    pcall(function()
        local feedback = April.require("features.visuals.feedback")
        if feedback.on_hit then feedback.on_hit(hit) end
    end)
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)
    menu_util.section(T, G.VISUALS, "Bullet Tracers")
    menu.add_checkbox(T, G.VISUALS, P, "Bullet Tracers", false, { colorpicker = { 1, 0.6, 0.2, 1 } })
    menu.add_slider_int(T, G.VISUALS, "april_hit_aim_fov", "Aim FOV (px)", 40, 600, 250, { parent = P })
    menu.add_slider_int(T, G.VISUALS, "april_hit_max_distance", "Max Hit Distance", 50, 1000, 450, { parent = P })
    menu.add_slider_float(T, G.VISUALS, "april_bullet_tracer_lifetime", "Tracer Fade Time", 0.1, 2.0, 0.35, "%.1fs", { parent = P })
    menu.add_slider_int(T, G.VISUALS, "april_bullet_tracer_thickness", "Tracer Thickness", 1, 4, 2, { parent = P })
end

function M.update(_dt)
    if hit_tracker.enabled() then
        hit_tracker.track(on_hit)
    end

    if not settings.enabled(P) then
        if #tracers > 0 then tracers = {} end
        return
    end

    local now = tick()
    local lifetime_ms = settings.num("april_bullet_tracer_lifetime", 0.35) * 1000
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
    local lifetime_ms = settings.num("april_bullet_tracer_lifetime", 0.35) * 1000
    local cr, cg, cb, ca = color[1], color[2], color[3], color[4] or 1

    for _, tr in ipairs(tracers) do
        local alpha = 1.0 - ((now - tr.created) / lifetime_ms)
        if alpha <= 0 then goto next_tracer end

        esp_util.draw_world_line(
            tr.ox, tr.oy, tr.oz,
            tr.tx, tr.ty, tr.tz,
            { cr, cg, cb, alpha * ca },
            thickness
        )

        ::next_tracer::
    end
end

return M
