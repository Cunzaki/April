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

local function mark(dense, name)
    if dense then debug.step(name) end
end

M.FEATURE_ORDER = {
    "features.combat.camera_aimbot",
    "features.combat.aimbot",
    "features.combat.body_peek",
    "features.combat.gun_mods",
    "features.visuals.target_overlay",
    "features.visuals.target_visuals",
    "features.visuals.player_esp",
    "features.world.world_esp",
    "features.world.loot_esp",
    "features.world.npc_esp",
    "features.world.raid_esp",
    "features.world.base_esp",
    "features.world.base_xray",
    "features.radar.tactical_map",
    "features.radar.waypoints",
    "features.movement.exploits",
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
    local dense = (April and April.crash_trace == true) or (debug.frame_count() <= 45)

    mark(dense, "tabs.update.cache")
    cache.refresh_entities()
    mark(dense, "tabs.update.npcs")
    npcs.refresh_cache(cache.workspace_entities)
    mark(dense, "tabs.update.player_state")
    player_state.tick(cache.players)

    mark(dense, "tabs.update.bootstrap")
    bootstrap.tick()

    mark(dense, "tabs.update.weapons")
    weapons.tick()

    mark(dense, "tabs.update.runservice")
    runservice.dispatch(dt)

    mark(dense, "tabs.update.incremental_scan")
    incremental_scan.tick()
    for i, feat in ipairs(M.features) do
        if feat.update then
            local name = M.FEATURE_ORDER[i] or ("#" .. i)
            debug.guard("update:" .. name, feat.update, dt)
        end
    end
end

function M.draw()
    for i, feat in ipairs(M.features) do
        if feat.draw then
            local name = M.FEATURE_ORDER[i] or ("#" .. i)
            debug.guard("draw:" .. name, feat.draw)
        end
    end
end

function M.init()
    debug.step("tabs.init")
    local env = April.require("core.env")
    local ok, missing = env.require_apis({ "draw", "utility", "entity", "game" })
    if not ok then
        debug.error_once("init:apis", "Missing required API: " .. tostring(missing))
        return false
    end

    -- Custom UI backend: feature register_menu() writes into gs_state, not Vector menu.
    debug.step("tabs.init.menu_shim")
    pcall(function()
        April.require("ui.menu_shim").install()
    end)

    debug.step("tabs.init.register_all")
    M.register_all()
    debug.step("tabs.init.setup_scans")
    M.setup_scans()
    debug.step("tabs.init.setup_player_hooks")
    M.setup_player_hooks()

    debug.step("tabs.init.try_autoload")
    pcall(function()
        April.require("features.utility.config").try_autoload()
    end)
    debug.step_done("tabs.init")

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
