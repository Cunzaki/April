local settings = April.require("core.settings")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local manip_math = April.require("core.manip_math")
local desync_vis = April.require("core.desync_vis")
local packet_desync = April.require("core.packet_desync")
local cframe_move = April.require("core.cframe_move")
local draw_util = April.require("core.draw_util")
local targeting = April.require("features.combat.targeting")
local misc_gate = April.require("core.misc_gate")

local M = {}

local P = "april_bullet_manip_enabled"
local VIS_MODES = { "Box", "Cross", "Ring" }

local STATE_IDLE = "idle"
local STATE_LOCKED = "locked"
local STATE_PEEKING = "peeking"

local state = STATE_IDLE
local origin = nil
local candidate = nil
local target_player = nil
local target_pos = nil
local debug_lines = {}
local desync_active = false
local last_log = ""
local last_idle_log = 0
local last_move_log = 0

local function push_debug(msg)
    last_log = tostring(msg)
    table.insert(debug_lines, 1, string.format("[%.2f] %s", utility and utility.get_time and utility.get_time() or os.clock(), msg))
    while #debug_lines > 12 do
        table.remove(debug_lines)
    end
    if settings.enabled("april_bullet_manip_console") then
        print("[BulletManip] " .. msg)
    end
end

local function clear_session(msg)
    if desync_active then
        packet_desync.release()
        desync_active = false
    end
    state = STATE_IDLE
    origin = nil
    candidate = nil
    target_player = nil
    target_pos = nil
    if msg then push_debug(msg) end
end

local function get_local_root()
    local lp = env.get_local_player()
    if not lp then return nil, nil end
    local char = lp.character or (game and game.local_player and game.local_player.character)
    if not char then return lp, nil end
    local root = env.safe_call(function()
        if char.find_first_child then return char:find_first_child("HumanoidRootPart") end
        return char:FindFirstChild("HumanoidRootPart")
    end)
    return lp, root
end

local function set_root_pos(root, v)
    if not root or not v then return end
    cframe_move.set_position(root, v.x, v.y, v.z)
end

local function apply_packet_desync(on)
    if on and not desync_active then
        packet_desync.apply_movement_only()
        desync_active = true
        push_debug("packet desync ON (movement only choke)")
    elseif not on and desync_active then
        packet_desync.release()
        desync_active = false
        push_debug("packet desync OFF")
    end
end

local function pick_target(lp, range)
    if not entity or not entity.get_players then return nil end
    range = range or 300
    local range_sq = range * range
    local me_pos = lp and lp.position
    local best, best_dist = nil, range_sq

    for _, p in ipairs(entity.get_players()) do
        if p.is_local or not p.is_alive then goto continue end
        if not p.position then goto continue end
        local dx = p.position.x - (me_pos and me_pos.x or 0)
        local dy = p.position.y - (me_pos and me_pos.y or 0)
        local dz = p.position.z - (me_pos and me_pos.z or 0)
        local dist_sq = dx * dx + dy * dy + dz * dz
        if dist_sq < best_dist then
            best_dist = dist_sq
            best = p
        end
        ::continue::
    end

    return best
end

local function target_aim_point(p)
    if not p then return nil end
    return targeting.bone_world(p, "Head") or (p.head_position and {
        x = p.head_position.x,
        y = p.head_position.y,
        z = p.head_position.z,
    }) or (p.position and {
        x = p.position.x,
        y = p.position.y,
        z = p.position.z,
    })
end

local function move_toward(root, dest, speed)
    local cur = cframe_move.read_pos(root)
    if not cur or not dest then return false end
    local dx, dy, dz = dest.x - cur.x, dest.y - cur.y, dest.z - cur.z
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    if dist < 0.35 then
        set_root_pos(root, dest)
        return true
    end
    local step = math.min(dist, speed * cframe_move.delta_time())
    set_root_pos(root, {
        x = cur.x + (dx / dist) * step,
        y = cur.y + (dy / dist) * step,
        z = cur.z + (dz / dist) * step,
    })
    return false
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.section(T, G.MISC, "Bullet Manip (TEST)")
    menu_util.register_keybind(T, G.MISC, P, "Bullet Manipulation", false)
    menu.add_slider_int(T, G.MISC, "april_bullet_manip_range", "Target Range", 50, 500, 250, root)
    menu.add_slider_int(T, G.MISC, "april_bullet_manip_speed", "Peek Move Speed", 4, 40, 18, root)
    menu.add_checkbox(T, G.MISC, "april_bullet_manip_debug", "Debug Overlay", true, root)
    menu.add_checkbox(T, G.MISC, "april_bullet_manip_console", "Debug Console Log", true, root)
    menu.add_checkbox(T, G.MISC, "april_bullet_manip_vis", "Visualizer", true, root)
    menu.add_combo(T, G.MISC, "april_bullet_manip_vis_style", "Vis Style", VIS_MODES, 0, root)
    menu.add_slider_float(T, G.MISC, "april_bullet_manip_vis_size", "Vis Size", 0.5, 4, 1.2, root)
    menu.add_checkbox(T, G.MISC, "april_bullet_manip_vis_link", "Show Link Line", true, root)
    menu.add_checkbox(T, G.MISC, "april_bullet_manip_vis_labels", "Show Labels", true, root)
    menu.add_checkbox(T, G.MISC, "april_bullet_manip_vis_peek", "Show Peek Point", true, root)

    menu_util.bind_children(P, {
        "april_bullet_manip_range", "april_bullet_manip_speed",
        "april_bullet_manip_debug", "april_bullet_manip_console",
        "april_bullet_manip_vis", "april_bullet_manip_vis_style", "april_bullet_manip_vis_size",
        "april_bullet_manip_vis_link", "april_bullet_manip_vis_labels", "april_bullet_manip_vis_peek",
    })

    menu_util.bind_when(function()
        return settings.enabled(P) and settings.enabled("april_bullet_manip_vis")
    end, {
        "april_bullet_manip_vis_style", "april_bullet_manip_vis_size",
        "april_bullet_manip_vis_link", "april_bullet_manip_vis_labels", "april_bullet_manip_vis_peek",
    }, { P, "april_bullet_manip_vis" })
end

function M.update(_dt)
    if not misc_gate.movement_allowed() then return end
    if not settings.enabled(P) then
        if state ~= STATE_IDLE then
            local _, root = get_local_root()
            if origin and root then set_root_pos(root, origin) end
            clear_session("disabled")
        end
        return
    end

    local lp, root = get_local_root()
    if not lp or not root then
        clear_session("no local root")
        return
    end

    local local_pos = cframe_move.read_pos(root)
    if not local_pos then return end

    if state == STATE_IDLE then
        local tgt = pick_target(lp, settings.num("april_bullet_manip_range", 250))
        if not tgt then
            local t = utility and utility.get_time and utility.get_time() or os.clock()
            if t - last_idle_log > 1.0 then
                push_debug("scan: no target in range")
                last_idle_log = t
            end
            return
        end

        local aim = target_aim_point(tgt)
        if not aim then
            push_debug("scan: no aim point for " .. tostring(tgt.name))
            return
        end

        origin = { x = local_pos.x, y = local_pos.y, z = local_pos.z }
        target_player = tgt
        target_pos = aim

        candidate = manip_math.find_manipulation_position(origin, target_pos)
        if not candidate then
            push_debug("scan: FindManipulationPosition failed for " .. tostring(tgt.name))
            origin = nil
            target_player = nil
            target_pos = nil
            return
        end

        push_debug(string.format(
            "LOCK %s | origin vis=%s | peek=(%.1f,%.1f,%.1f)",
            tgt.name,
            tostring(manip_math.is_visible_from_pos(origin, target_pos)),
            candidate.x, candidate.y, candidate.z
        ))

        apply_packet_desync(true)
        state = STATE_LOCKED
    end

    if state == STATE_LOCKED or state == STATE_PEEKING then
        if not target_player or not target_player.is_alive then
            set_root_pos(root, origin)
            clear_session("target dead/gone")
            return
        end

        target_pos = target_aim_point(target_player) or target_pos
        if not target_pos then
            set_root_pos(root, origin)
            clear_session("lost aim point")
            return
        end

        if not manip_math.is_visible_from_pos(origin, target_pos) then
            push_debug("origin lost LOS -> restore")
            set_root_pos(root, origin)
            clear_session("origin LOS lost")
            return
        end

        local speed = settings.num("april_bullet_manip_speed", 18)
        local at_peek = move_toward(root, candidate, speed)
        if at_peek then
            if state ~= STATE_PEEKING then
                state = STATE_PEEKING
                push_debug("PEEK reached | can shoot from peek point")
            end
        else
            local t = utility and utility.get_time and utility.get_time() or os.clock()
            if state ~= STATE_PEEKING and t - last_move_log > 0.5 then
                push_debug(string.format(
                    "MOVE -> peek | dist=%.1f",
                    math.sqrt(manip_math.dist_sq(cframe_move.read_pos(root), candidate))
                ))
                last_move_log = t
            end
        end
    end
end

function M.draw()
    if not misc_gate.movement_allowed() then return end
    if not settings.enabled(P) then return end

    local _, root = get_local_root()
    local local_pos = root and cframe_move.read_pos(root)

    if settings.enabled("april_bullet_manip_vis") and origin and local_pos then
        local mode = settings.num("april_bullet_manip_vis_style", 0)
        local size = settings.num("april_bullet_manip_vis_size", 1.2)

        desync_vis.draw_server_local(origin, local_pos, {
            mode = mode,
            size = size,
            col_server = settings.color("april_bullet_manip_vis_server", { 0.2, 0.85, 1, 0.9 }),
            col_local = settings.color("april_bullet_manip_vis_local", { 1, 0.35, 0.35, 0.9 }),
            col_link = settings.color("april_bullet_manip_vis_link", { 1, 1, 1, 0.4 }),
            link = settings.enabled("april_bullet_manip_vis_link"),
            labels = settings.enabled("april_bullet_manip_vis_labels"),
            server_label = "SERVER",
            local_label = "LOCAL",
        })

        if settings.enabled("april_bullet_manip_vis_peek") and candidate then
            local col_peek = settings.color("april_bullet_manip_vis_peek", { 1, 0.85, 0.2, 0.95 })
            desync_vis.draw_mode(mode, candidate.x, candidate.y, candidate.z, size, col_peek, 2)
            if settings.enabled("april_bullet_manip_vis_labels") then
                desync_vis.draw_labeled(candidate.x, candidate.y, candidate.z, "PEEK", col_peek, 12)
            end
            if settings.enabled("april_bullet_manip_vis_link") then
                desync_vis.draw_link(origin, candidate, { col_peek[1], col_peek[2], col_peek[3], 0.35 }, 1)
            end
        end

        if target_pos then
            desync_vis.draw_cross(target_pos.x, target_pos.y, target_pos.z, 0.8, { 1, 0.2, 0.2, 1 }, 2)
        end
    end

    if not settings.enabled("april_bullet_manip_debug") then return end

    local y = 80
    local col = { 0.9, 0.95, 1, 1 }
    draw_util.text(12, y, "Bullet Manip DEBUG", col, 14)
    y = y + 18
    draw_util.text(12, y, "state: " .. state .. " | desync: " .. tostring(desync_active), col, 12)
    y = y + 16
    if target_player then
        draw_util.text(12, y, "target: " .. tostring(target_player.name), col, 12)
        y = y + 14
    end
    if origin and target_pos then
        draw_util.text(12, y, "origin LOS: " .. tostring(manip_math.is_visible_from_pos(origin, target_pos)), col, 12)
        y = y + 14
    end
    if raycast then
        draw_util.text(12, y, "raycast ready: " .. tostring(raycast.is_ready and raycast.is_ready() or "?"), col, 12)
        y = y + 14
    end
    draw_util.text(12, y, "last: " .. last_log, { 1, 1, 0.6, 1 }, 11)
    y = y + 16
    for i = 1, math.min(#debug_lines, 8) do
        draw_util.text(12, y, debug_lines[i], { 0.75, 0.8, 0.85, 0.95 }, 10)
        y = y + 12
    end
end

return M
