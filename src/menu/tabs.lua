local menu_util = April.require("core.menu_util")
local debug = April.require("core.debug")
local scheduler = April.require("core.scheduler")

local M = {}

M.features = {}

M.FEATURE_ORDER = {
    "features.combat.aimbot",
    "features.visuals.player_esp",
    "features.visuals.crosshair",
    "features.visuals.feedback",
    "features.world.world_esp",
    "features.combat.recoil",
    "features.radar.waypoints",
    "features.world.loot_esp",
    "features.world.npc_esp",
    "features.world.base_esp",
    "features.radar.tactical_map",
    "features.movement.exploits",
    "features.utility.config",
}

function M.register_all()
    menu_util.ensure_tab()
    M.features = {}
    local registered = 0

    for _, path in ipairs(M.FEATURE_ORDER) do
        local feat = April.require(path)
        table.insert(M.features, feat)
        local ok, err = pcall(function()
            if feat.register_menu then
                feat.register_menu()
                registered = registered + 1
            end
        end)
        if not ok then
            debug.error_once("menu:" .. path, err)
        end
    end

    debug.log("Menu groups registered: " .. registered .. " (Scripts > April)")
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

    debug.guard("scan:initial_players", player_esp.scan)
    debug.guard("scan:initial_world", world_esp.scan)
    debug.guard("scan:initial_loot", loot_esp.scan)
    debug.guard("scan:initial_base", base_esp.scan)
    debug.guard("scan:initial_npcs", npc_esp.scan)
end

function M.load_game_data()
    local weapons = April.require("game.weapons")
    local items = April.require("game.items")

    debug.guard("items.load", items.load)
    local weapons_ok = debug.guard_bool("weapons.load", weapons.load)
    if weapons_ok and weapons.recoil_weapon_names then
        local names = weapons.recoil_weapon_names()
        debug.log("ToolInfo weapons: " .. #names)
    else
        debug.warn("ToolInfo not loaded — recoil/weapon stats use fallbacks until in-game")
    end
end

function M.update(dt)
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

    debug.audit_apis()

    M.register_all()
    M.load_game_data()
    M.setup_scans()

    local me = entity.get_local_player and entity.get_local_player()
    if me then
        debug.log("Local player: " .. tostring(me.name))
    else
        debug.warn("Local player not ready yet (normal before spawn)")
    end

    debug.log("Init complete — v" .. April.version)
    return true
end

return M
