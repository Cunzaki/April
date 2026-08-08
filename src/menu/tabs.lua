local menu_util = April.require("core.menu_util")
local debug = April.require("core.debug")
local bootstrap = April.require("game.bootstrap")
local cache = April.require("core.cache")
local npcs = April.require("game.npcs")
local player_state = April.require("game.player_state")
local weapons = April.require("game.weapons")
local runservice = April.require("core.runservice")
local incremental_scan = April.require("core.incremental_scan")

local M = {}

M.features = {}
M._menu_registered = false

M.FEATURE_ORDER = {
    "features.combat.camera_aimbot",
    -- Inflate heads before silent/TP resolve so Override Size is live for aim math.
    "features.combat.thick_bullet",
    "features.combat.aimbot",
    "features.combat.fov_flags",
    "features.combat.body_peek",
    "features.combat.gun_mods",
    "features.visuals.bullet_tracers",
    "features.visuals.target_overlay",
    "features.visuals.target_visuals",
    "features.visuals.player_esp",
    "features.visuals.sound_esp",
    "features.world.world_esp",
    "features.world.loot_esp",
    "features.world.npc_esp",
    "features.world.raid_esp",
    "features.world.base_esp",
    "features.world.base_xray",
    "features.radar.tactical_map",
    "features.radar.waypoints",
    "features.movement.exploits",
    "features.movement.bhop",
    "features.movement.desync",
    "features.movement.anti_aim",
    "features.movement.fake_duck",
    "features.movement.fling",
    "features.movement.anti_fling",
    "features.combat.perfect_farm",
    "features.utility.autofarm",
    "features.utility.mod_checker",
    "features.utility.event_status",
    "features.utility.anti_afk",
    "features.utility.keybind_viewer",
    "features.utility.anime_announcer",
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
            local ok = pcall(feat.register_menu)
            if ok then
                registered = registered + 1
            end
        end
    end

    M._menu_registered = true
    pcall(function()
        local mod = April.require("features.utility.mod_checker")
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

    -- Shared budget for world / loot / base / npc — one incremental thread.
    iscan.configure({ budget_ms = 6, items_per_step = 18 })

    local SCAN_MS = cache.WORKSPACE_SCAN_MS or 1000
    local DROPS_SCAN_MS = cache.DROPS_SCAN_MS or 3500

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

    iscan.register("loot_drops", DROPS_SCAN_MS, function()
        if settings.enabled("april_loot_enabled") then
            return settings.enabled("april_dropped_item")
        end
        return map_on("loot")()
    end, loot_esp.begin_drops_scan, loot_esp.step_drops_scan, loot_esp.complete_drops_scan, 360)

    iscan.register("base", SCAN_MS, function()
        return settings.enabled("april_base_enabled") or map_on("base")()
    end, base_esp.begin_static_scan, base_esp.step_static_scan, base_esp.complete_static_scan, 480)

end

function M.update(dt)
    cache.refresh_entities()
    npcs.refresh_cache(cache.workspace_entities)
    player_state.tick(cache.players)
    bootstrap.tick()
    weapons.tick()
    runservice.dispatch(dt)
    incremental_scan.tick()
    pcall(function()
        April.require("core.rbx_offsets").tick_fps()
    end)
    for i, feat in ipairs(M.features) do
        if feat.update then
            local name = M.FEATURE_ORDER[i] or ("#" .. i)
            debug.guard_fast("update:" .. name, feat.update, dt)
        end
    end
end

function M.draw()
    for i, feat in ipairs(M.features) do
        if feat.draw then
            local name = M.FEATURE_ORDER[i] or ("#" .. i)
            debug.guard_fast("draw:" .. name, feat.draw)
        end
    end
end

function M.init()
    local env = April.require("core.env")
    local ok = env.require_apis({ "draw", "utility", "entity", "game" })
    if not ok then
        return false
    end

    pcall(function()
        April.require("ui.menu_shim").install()
    end)

    -- Theo offsets + MaxFPS unlock load with the script (not on feature toggle).
    pcall(function()
        April.require("core.rbx_offsets").boot()
    end)

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
        debug.guard_fast("on_player_added", mod.on_player_added, p)
    end

    _G.on_player_removed = function(p)
        debug.guard_fast("on_player_removed", mod.on_player_removed, p)
    end
end

return M
