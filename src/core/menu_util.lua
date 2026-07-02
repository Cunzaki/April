--[[
    April registers each feature on its own Vector top-level tab (horizontal bar:
    AIMBOT, VISUALS, WORLD, etc.) instead of stacking everything under Scripts/April.

    Scripts/April "full" tab is only a loader marker — options live on feature tabs.
]]

local M = {}

M.SCRIPT_TAB = "April"
M.SCRIPT_GROUP = "Info"

-- Each slot = one top-level tab in Vector's main menu bar
M.SLOTS = {
    aimbot     = { tab = "Aimbot",      icon = "A", group = "April" },
    recoil     = { tab = "Aimbot",      icon = "A", group = "Recoil Control" },
    player_esp = { tab = "Player ESP",  icon = "P", group = "April" },
    crosshair  = { tab = "Crosshair",   icon = "C", group = "April" },
    hitmarkers = { tab = "Visuals",     icon = "V", group = "Hitmarkers" },
    world      = { tab = "World",       icon = "W", group = "Resources" },
    loot       = { tab = "World",       icon = "W", group = "Loot" },
    npcs       = { tab = "World",       icon = "W", group = "NPCs" },
    base       = { tab = "World",       icon = "W", group = "Base" },
    waypoints  = { tab = "Features",    icon = "F", group = "Waypoints" },
    map        = { tab = "Features",    icon = "F", group = "Tactical Map" },
    misc       = { tab = "Features",    icon = "F", group = "Movement" },
    config     = { tab = "Settings",    icon = "S", group = "April Config" },
}

M._tabs = {}
M._groups = {}
M._script_ready = false

function M.ensure_script_marker()
    if M._script_ready then return end
    if menu and menu.add_tab then
        menu.add_tab(M.SCRIPT_TAB, "A", "full")
        menu.add_group(M.SCRIPT_TAB, M.SCRIPT_GROUP)
        menu.add_label(M.SCRIPT_TAB, M.SCRIPT_GROUP, "April v3 loaded — use the top tabs above.")
        menu.add_label(M.SCRIPT_TAB, M.SCRIPT_GROUP, "Aimbot | Player ESP | Crosshair | World | Features | Settings")
    end
    M._script_ready = true
end

function M.bind(slot)
    M.ensure_script_marker()
    local s = M.SLOTS[slot]
    if not s then error("[April] unknown menu slot: " .. tostring(slot)) end

    if not M._tabs[s.tab] and menu and menu.add_tab then
        menu.add_tab(s.tab, s.icon)
        M._tabs[s.tab] = true
    end

    local gkey = s.tab .. "\0" .. s.group
    if not M._groups[gkey] and menu and menu.add_group then
        menu.add_group(s.tab, s.group)
        M._groups[gkey] = true
    end

    return s.tab, s.group
end

-- Legacy aliases
M.G = {
    AIMBOT = "aimbot",
    RECOIL = "recoil",
    VISUALS = "hitmarkers",
    WORLD = "world",
    LOOT = "loot",
    NPCS = "npcs",
    BASE = "base",
    WAYPOINTS = "waypoints",
    MAP = "map",
    MISC = "misc",
    CONFIG = "config",
}

return M
