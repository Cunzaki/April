-- Pure draw bullet tracers (3D world lines). No instance.new.
-- Fires on LMB while silent-aim has a target, or on confirmed HP drop.

local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local combat_origin = April.require("game.combat_origin")
local combat_target = April.require("game.combat_target")
local weapons = April.require("game.weapons")
local move = April.require("core.cframe_move")
local esp_util = April.require("core.esp_util")
local draw_util = April.require("core.draw_util")

local M = {}

local P = "april_bullet_tracers"
local MAX = 36
local tracers = {}
local was_fire = false
local last_hp = {}
local last_spawn = 0

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function fire_origin()
    local weapon = weapons.cached_held_ranged and weapons.cached_held_ranged()
    combat_origin.sync_weapon(weapon)
    return combat_origin.get_fire_origin()
        or combat_origin.get_camera_origin()
end

local function entity_pos(ent)
    if not ent then return nil end
    local pos = ent.head_position or ent.position
    if not pos then return nil end
    return {
        x = pos.x or pos.X or pos[1],
        y = pos.y or pos.Y or pos[2],
        z = pos.z or pos.Z or pos[3],
    }
end

local function spawn(from, to)
    local now = tick_ms()
    if now - last_spawn < 20 then return end
    last_spawn = now
    while #tracers >= MAX do table.remove(tracers, 1) end
    tracers[#tracers + 1] = {
        from = from,
        to = to,
        born = now,
        life = settings.num("april_bullet_tracers_life", 450),
    }
end

local function try_spawn_to_target()
    local from = fire_origin()
    if not from then return end
    local tgt = combat_target.get()
    local to = entity_pos(tgt)
    if not to then return end
    spawn(from, to)
end

function M.register_menu()
    local G = menu_util.G
    local T = menu_util.group(G.VISUALS)
    local root = menu_util.parent(P)

    menu.add_checkbox(T, G.VISUALS, P, "Bullet Tracers", false, {
        colorpicker = { 1, 0.55, 0.15, 0.95 },
    })
    menu.add_colorpicker(T, G.VISUALS, "april_bullet_tracers_color2", "Tracer Glow",
        { 1, 0.25, 0.35, 0.55 }, root)
    menu.add_slider_int(T, G.VISUALS, "april_bullet_tracers_thick", "Thickness", 1, 6, 2, root)
    menu.add_slider_int(T, G.VISUALS, "april_bullet_tracers_life", "Life (ms)", 100, 1500, 450, root)

    menu_util.bind_children(P, {
        "april_bullet_tracers_color2",
        "april_bullet_tracers_thick", "april_bullet_tracers_life",
    })
end

function M.notify_hit(from, to)
    if not settings.enabled(P) then return end
    from = from or fire_origin()
    to = to or entity_pos(combat_target.get())
    if from and to then spawn(from, to) end
end

function M.update(_dt)
    if not settings.enabled(P) then
        was_fire = false
        tracers = {}
        return
    end

    local firing = move.key_down(0x01)
    if firing and not was_fire then
        try_spawn_to_target()
    end
    was_fire = firing

    -- Damage confirm while holding fire
    if firing then
        local tgt = combat_target.get()
        if tgt and tgt.health ~= nil then
            local uid = tostring(tgt.user_id or tgt.name or "?")
            local prev = last_hp[uid]
            last_hp[uid] = tgt.health
            if prev and tgt.health < prev - 0.35 then
                try_spawn_to_target()
            end
        end
    end

    local now = tick_ms()
    local i = 1
    while i <= #tracers do
        if now - tracers[i].born > tracers[i].life then
            table.remove(tracers, i)
        else
            i = i + 1
        end
    end
end

function M.draw()
    if not settings.enabled(P) then return end

    local c1 = settings.color(P, { 1, 0.55, 0.15, 0.95 })
    local c2 = settings.color("april_bullet_tracers_color2", { 1, 0.25, 0.35, 0.55 })
    local thick = settings.num("april_bullet_tracers_thick", 2)
    local now = tick_ms()

    for i = 1, #tracers do
        local tr = tracers[i]
        local a = 1 - ((now - tr.born) / math.max(1, tr.life))
        if a <= 0 then goto continue end

        local glow = { c2[1], c2[2], c2[3], (c2[4] or 0.55) * a * 0.5 }
        local core = { c1[1], c1[2], c1[3], (c1[4] or 0.95) * a }

        -- Soft outer + bright core (world-space 3D lines)
        esp_util.draw_world_line(
            tr.from.x, tr.from.y, tr.from.z,
            tr.to.x, tr.to.y, tr.to.z,
            glow, thick + 2
        )
        esp_util.draw_world_line(
            tr.from.x, tr.from.y, tr.from.z,
            tr.to.x, tr.to.y, tr.to.z,
            core, thick
        )

        -- Tip spark
        local sx, sy, vis = nil, nil, false
        if utility and utility.world_to_screen then
            sx, sy, vis = utility.world_to_screen(tr.to.x, tr.to.y, tr.to.z)
        end
        if vis and sx and draw_util.circle then
            draw_util.circle(sx, sy, 2 + thick, core, true)
        end

        ::continue::
    end
end

return M
