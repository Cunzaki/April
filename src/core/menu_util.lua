--[[
    Menu layout: register each group once, right before its elements (not all upfront).
    Vector uses the left sidebar for groups; options appear when a group is selected.
]]

local M = {}

M.TAB = "April"

M.GROUPS = {
    "Aimbot",
    "Visuals",
    "World",
    "Recoil Control",
    "Waypoints",
    "Loot",
    "NPCs",
    "Base",
    "Tactical Map",
    "Misc",
    "Config",
}

M.G = {
    AIMBOT = "Aimbot",
    VISUALS = "Visuals",
    WORLD = "World",
    RECOIL = "Recoil Control",
    WAYPOINTS = "Waypoints",
    LOOT = "Loot",
    NPCS = "NPCs",
    BASE = "Base",
    MAP = "Tactical Map",
    MISC = "Misc",
    CONFIG = "Config",
}

M._tab_ready = false
M._groups_done = {}

function M.ensure_tab()
    if M._tab_ready then return end
    if menu and menu.add_tab then
        menu.add_tab(M.TAB, "A", "full")
    end
    M._tab_ready = true
end

function M.ensure_group(name)
    M.ensure_tab()
    if M._groups_done[name] then return end
    menu.add_group(M.TAB, name)
    M._groups_done[name] = true
end

function M.tab()
    return M.TAB
end

return M
