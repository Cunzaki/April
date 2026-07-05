local menu_util = April.require("core.menu_util")
local debug = April.require("core.debug")
local scheduler = April.require("core.scheduler")
local bootstrap = April.require("game.bootstrap")

local M = {}

M.features = {}
M._menu_registered = false

M.FEATURE_ORDER = {
    "features.combat.perfect_farm",
    "features.combat.gun_mods",
    "features.visuals.player_esp",
    "features.visuals.target_overlay",
    "features.visuals.crosshair",
    "features.world.world_esp",
    "features.world.loot_esp",
    "features.world.npc_esp",
    "features.world.base_esp",
    "features.radar.waypoints",
    "features.radar.tactical_map",
    "features.movement.exploits",
    "features.utility.mod_checker",
    "features.utility.name_hider",
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
                debug.error_once("menu:" .. path, err)
            end
        end
    end

    M._menu_registered = true
    if April and April.debug then
        debug.log("Menu: " .. registered .. " sections")
    end

    pcall(function()
        local esp = April.require("features.visuals.player_esp")
        if esp.init then esp.init() end
        local mod = April.require("features.utility.mod_checker")
        if mod.init then mod.init() end
    end)
end

function M.setup_scans()
    local settings = April.require("core.settings")
    local iscan = April.require("core.incremental_scan")
    local world_esp = April.require("features.world.world_esp")
    local loot_esp = April.require("features.world.loot_esp")
    local base_esp = April.require("features.world.base_esp")
    local npc_esp = April.require("features.world.npc_esp")

    iscan.configure({ budget_ms = 5, items_per_step = 14 })

    local function map_on(layer)
        return function()
            if not settings.enabled("april_map_enabled") then return false end
            return settings.enabled("april_map_show_" .. layer)
        end
    end

    local function need_npcs()
        if settings.enabled("april_npc_enabled") then return true end
        return map_on("npcs")()
    end

    iscan.register("world", 3500, function()
        return settings.enabled("april_world_enabled") or map_on("world")()
    end, world_esp.begin_static_scan, world_esp.step_static_scan, world_esp.complete_static_scan, 0)

    iscan.register("world_dynamic", 900, function()
        if not settings.enabled("april_world_enabled") then return false end
        return settings.enabled("april_deer")
            or settings.enabled("april_boar")
            or settings.enabled("april_wolf")
    end, world_esp.begin_dynamic_scan, world_esp.step_dynamic_scan, world_esp.complete_dynamic_scan, 450)

    iscan.register("loot", 4000, function()
        return settings.enabled("april_loot_enabled") or map_on("loot")()
    end, loot_esp.begin_static_scan, loot_esp.step_static_scan, loot_esp.complete_static_scan, 900)

    iscan.register("loot_drops", 700, function()
        if not settings.enabled("april_loot_enabled") then return false end
        return settings.enabled("april_dropped_item")
    end, loot_esp.begin_drops_scan, loot_esp.step_drops_scan, loot_esp.complete_drops_scan, 1350)

    iscan.register("base", 4500, function()
        return settings.enabled("april_base_enabled") or map_on("base")()
    end, base_esp.begin_scan, base_esp.step_scan, base_esp.complete_scan, 1800)

    iscan.register("npcs", 1400, need_npcs, npc_esp.begin_scan, npc_esp.step_scan, npc_esp.complete_scan, 2250)
end

function M.update(dt)
    bootstrap.tick()

    local weapons = April.require("game.weapons")
    weapons.tick()

    scheduler.tick()
    April.require("core.incremental_scan").tick()
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
    M.setup_player_hooks()

    pcall(function()
        April.require("features.utility.config").try_autoload()
    end)

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
