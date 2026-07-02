local menu_util = April.require("core.menu_util")
local G = menu_util.G
local T = menu_util.tab()

local M = {}

M.features = {}

-- Registration order = sidebar group order (groups pre-registered in menu_util)
M.FEATURE_ORDER = {
    "features.combat.aimbot",
    "features.visuals.crosshair",
    "features.visuals.player_esp",
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
    April.TAB = menu_util.TAB

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
            print("[April] menu register failed (" .. path .. "): " .. tostring(err))
        end
    end

    print("[April] Menu sections registered: " .. registered .. " / " .. #menu_util.GROUPS .. " groups")
end

function M.setup_scans()
    local scheduler = April.require("core.scheduler")
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

    player_esp.scan()
    world_esp.scan()
    loot_esp.scan()
    base_esp.scan()
    npc_esp.scan()
end

function M.load_game_data()
    April.require("game.items").load()
    April.require("game.weapons").load()
end

function M.update(dt)
    local scheduler = April.require("core.scheduler")
    scheduler.tick_fallback()
    for _, feat in ipairs(M.features) do
        if feat.update then pcall(feat.update, dt) end
    end
end

function M.draw()
    for _, feat in ipairs(M.features) do
        if feat.draw then pcall(feat.draw) end
    end
end

function M.init()
    local env = April.require("core.env")
    local ok, missing = env.require_apis({ "menu", "draw", "utility", "entity", "game" })
    if not ok then
        print("[April v3] Missing API: " .. tostring(missing))
        return false
    end

    M.register_all()
    M.load_game_data()
    M.setup_scans()
    print("[April v3] Loaded — " .. April.version)
    return true
end

return M
