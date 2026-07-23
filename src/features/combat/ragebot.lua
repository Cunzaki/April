-- Ragebot: no FOV, range + filters, autofire. Bullet hitscan/TP/manip come only from Bullet section.
local settings = April.require("core.settings")
local targeting = April.require("features.combat.targeting")
local weapons = April.require("game.weapons")
local combat_origin = April.require("game.combat_origin")
local menu_util = April.require("core.menu_util")
local combat_menu = April.require("features.combat.combat_menu")
local silent_ray = April.require("core.silent_ray")
local silent_resolve = April.require("features.combat.silent_resolve")
local bullet_hud = April.require("features.combat.bullet_hud")
local body_peek = April.require("features.combat.body_peek")
local silent_whitelist = April.require("features.combat.silent_whitelist")

local M = {}

local PREFIX = "april_rage_"
local P_MASTER = "april_rage_enabled"
local TARGET_SCAN_MS = 33

local locked_target = nil
local last_target_scan = 0
local last_fire_ms = 0
local cached = { origin = nil, aim = nil, manip = { state = "off" } }

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
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

local function enabled()
    return settings.enabled(P_MASTER) and silent_ray.available()
end

local function update_target(cx, cy)
    local sticky = settings.multi(PREFIX .. "options", combat_menu.OPT_STICKY, false)
    local now = tick_ms()
    local opts = { ignore_fov = true }
    if silent_resolve.bypass_visibility() then
        opts.ignore_visible = true
    end

    if locked_target and targeting.is_npc_target(locked_target) then
        locked_target = targeting.refresh_npc_target(locked_target)
    end

    if locked_target and not targeting.is_target_valid(locked_target, PREFIX, cx, cy, 99999, opts) then
        locked_target = nil
    end

    if locked_target and sticky then
        return
    end

    if sticky and now - last_target_scan < TARGET_SCAN_MS then
        return
    end
    last_target_scan = now
    locked_target = targeting.find_target(cx, cy, 99999, PREFIX, opts)
end

-- When Bullet manip is on: only autofire wall peeks if a peek is ready.
-- Clear / direct / normal muzzle shots always allowed (same as silent).
local function ok_to_fire(info, aim)
    if not info then return false end

    if info.state == "ready" or info.state == "direct" or info.state == "hitscan" or info.state == "tp" or info.state == "curve" then
        return true
    end

    -- Manip scanning/blocked with no fallback aim should not click.
    if not aim then return false end
    return true
end

local function try_autofire()
    if not settings.bool(PREFIX .. "autofire", true) then return end
    local delay = math.max(20, settings.num(PREFIX .. "fire_delay", 80))
    local now = tick_ms()
    if now - last_fire_ms < delay then return end

    if utility and utility.mouse_click then
        pcall(utility.mouse_click, "left")
        last_fire_ms = now
    elseif input and input.key_press then
        pcall(input.key_press, 0x01)
        last_fire_ms = now
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.SILENT_AIM)

    menu_util.register_keybind(T, G.SILENT_AIM, P_MASTER, "Enable Ragebot", false)

    menu_util.section(T, G.SILENT_AIM, "Ragebot Targeting")
    menu.add_combo(T, G.SILENT_AIM, PREFIX .. "target_type", "Target Type", { "Crosshair", "Distance" }, 1,
        { parent = P_MASTER })
    menu.add_combo(T, G.SILENT_AIM, PREFIX .. "bone", "Hitbox", combat_menu.SILENT_BONES, 0, { parent = P_MASTER })
    menu.add_multicombo(T, G.SILENT_AIM, PREFIX .. "targets", "Aim At", {
        "Players", "NPCs",
    }, { true, false }, { parent = P_MASTER })
    menu.add_multicombo(T, G.SILENT_AIM, PREFIX .. "filters", "Filters", {
        "Health Check",
        "Visible Only",
        "Team Check",
        "Skip Safezone",
        "Whitelist",
        "Skip Downed",
    }, { true, false, true, true, false, true }, { parent = P_MASTER })
    menu.add_input(T, G.SILENT_AIM, PREFIX .. "whitelist_ids", "Whitelist IDs", "")
    if menu and menu.set_visible then
        pcall(menu.set_visible, PREFIX .. "whitelist_ids", false)
    end
    menu.add_button(T, G.SILENT_AIM, PREFIX .. "whitelist_clear", "Clear Whitelist", function()
        if silent_whitelist and silent_whitelist.clear then
            silent_whitelist.clear(PREFIX)
        end
    end)
    menu.add_slider_int(T, G.SILENT_AIM, PREFIX .. "max_dist", "Max Distance (m)", 50, 2000, 500, { parent = P_MASTER })

    menu_util.section(T, G.SILENT_AIM, "Ragebot Fire")
    menu.add_multicombo(T, G.SILENT_AIM, PREFIX .. "options", "Options", { "Sticky Target" }, { false },
        { parent = P_MASTER })
    menu.add_checkbox(T, G.SILENT_AIM, PREFIX .. "autofire", "Autofire", true, { parent = P_MASTER })
    menu.add_slider_int(T, G.SILENT_AIM, PREFIX .. "fire_delay", "Fire Delay (ms)", 20, 400, 80,
        { parent = P_MASTER })

    menu_util.bind_children(P_MASTER, {
        PREFIX .. "target_type", PREFIX .. "bone",
        PREFIX .. "filters",
        PREFIX .. "whitelist_ids", PREFIX .. "whitelist_clear",
        PREFIX .. "targets", PREFIX .. "options",
        PREFIX .. "max_dist",
        PREFIX .. "autofire", PREFIX .. "fire_delay",
    })
end

function M.update(dt)
    bullet_hud.update(dt)
    cached.origin = nil
    cached.aim = nil
    cached.manip = { state = "off" }

    if not enabled() then
        locked_target = nil
        body_peek.tick(nil, nil)
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
    update_target(cx, cy)

    local wl_target = locked_target
    if not wl_target or not targeting.is_aim_target(wl_target) then
        wl_target = targeting.find_target(cx, cy, 99999, PREFIX, {
            ignore_fov = true,
            ignore_whitelist = true,
            ignore_visible = opts.ignore_visible,
        })
    end
    silent_whitelist.tick(wl_target, PREFIX)

    if not locked_target or not targeting.is_aim_target(locked_target) then
        silent_ray.stop()
        body_peek.tick(nil, nil)
        return
    end

    local ok_resolve, origin, aim, manip_info = pcall(
        silent_resolve.resolve_track, locked_target, PREFIX, cx, cy
    )
    if manip_info then
        cached.manip = manip_info
    end
    if not ok_resolve or not aim or not origin then
        silent_ray.stop()
        return
    end

    cached.origin = origin
    cached.aim = aim

    if not ok_to_fire(manip_info, aim) then
        silent_ray.stop()
        return
    end

    local hit = (manip_info and manip_info.hitpart) or aim
    local track_aim = aim
    -- Prefer key-track so engine fire path matches silent; also set for autofire frames.
    if silent_ray.track then
        silent_ray.track(origin, track_aim, 0x01, hit)
    end
    silent_ray.set_target(origin, track_aim, hit)

    try_autofire()
    body_peek.tick(locked_target, hit)
end

function M.get_target()
    return locked_target
end

function M.get_scoped_target()
    if locked_target then return locked_target end
    if not enabled() then return nil end
    local sw, sh = targeting.screen_center()
    return targeting.find_target(sw * 0.5, sh * 0.5, 99999, PREFIX, { ignore_fov = true })
end

function M.draw()
    if not settings.bool("april_bullet_enabled", false) then return end
    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num(PREFIX .. "fov", 150)
    bullet_hud.draw(cx, cy, fov, cached)
end

return M
