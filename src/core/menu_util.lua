--[[
    Vector script menus use one tab ("full" mode) with named groups in the left sidebar.
    Groups must be registered in order before any elements are added.
]]

local M = {}

M.TAB = "April"

-- Sidebar order (matches original Fallen layout)
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

M.G = {}
for _, name in ipairs(M.GROUPS) do
    M.G[name:gsub(" ", "_"):upper()] = name
    -- Aimbot -> AIMBOT, Recoil Control -> RECOIL_CONTROL
end
M.G.AIMBOT = "Aimbot"
M.G.VISUALS = "Visuals"
M.G.WORLD = "World"
M.G.RECOIL = "Recoil Control"
M.G.WAYPOINTS = "Waypoints"
M.G.LOOT = "Loot"
M.G.NPCS = "NPCs"
M.G.BASE = "Base"
M.G.MAP = "Tactical Map"
M.G.MISC = "Misc"
M.G.CONFIG = "Config"

M._tab_ready = false
M._groups_ready = false

function M.ensure_tab()
    if M._tab_ready then return end
    if menu and menu.add_tab then
        menu.add_tab(M.TAB, "A", "full")
    end
    M._tab_ready = true
end

function M.ensure_groups()
    M.ensure_tab()
    if M._groups_ready then return end
    for _, name in ipairs(M.GROUPS) do
        menu.add_group(M.TAB, name)
    end
    M._groups_ready = true
end

function M.tab()
    return M.TAB
end

return M
