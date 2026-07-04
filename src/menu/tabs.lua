local menu_util = April.require("core.menu_util")
local debug = April.require("core.debug")
local scheduler = April.require("core.scheduler")
local bootstrap = April.require("game.bootstrap")

local M = {}

M.features = {}
M._menu_registered = false

M.FEATURE_ORDER = {
    "features.combat.aimbot",
    "features.combat.gun_mods",
    "features.visuals.player_esp",
    "features.visuals.crosshair",
    "features.visuals.feedback",
    "features.world.world_esp",
    "features.world.loot_esp",
    "features.world.npc_esp",
    "features.world.base_esp",
    "features.radar.waypoints",
    "features.radar.tactical_map",
    "features.movement.exploits",
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
                print("[April] Menu registration failed: " .. path .. " — " .. tostring(err))
                debug.error_once("menu:" .. path, err)
            end
        end
    end

    M._menu_registered = true
    if April and April.debug then
        debug.log("Menu: " .. registered .. " sections")
    end
end

function M.setup_scans()
    local player_esp = April.require("features.visuals.player_esp")
    local world_esp = April.require("features.world.world_esp")
    local loot_esp = April.require("features.world.loot_esp")
    local base_esp = April.require("features.world.base_esp")
    local npc_esp = April.require("features.world.npc_esp")

    scheduler.register("players", 250, function() player_esp.scan() end)
    scheduler.register("world", 1500, function() world_esp.scan() end)
    scheduler.register("loot", 2000, function() loot_esp.scan() end)
    scheduler.register("base", 1000, function() base_esp.scan() end)
    scheduler.register("npcs", 750, function() npc_esp.scan() end)
    scheduler.start_all()
end

function M.update(dt)
    bootstrap.tick()

    local weapons = April.require("game.weapons")
    weapons.tick()

    scheduler.tick()
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
    return true
end

return M
