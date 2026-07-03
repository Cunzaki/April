--[[
    Vector script menus (mode "full"):
      - One script tab: April
      - Each feature is a GROUP under that tab (Aimbot, Player ESP, Crosshair, ...)
      - Vector lays groups out in a 2-column grid (left / right, then next row)

    Do NOT register on Vector's built-in Aimbot/Visuals/World tabs — that breaks layout.
]]

local M = {}

M.TAB = "April"

-- Group registration order = grid order (L, R, L, R, ...)
M.GROUP_ORDER = {
    "Aimbot",
    "Player ESP",
    "Crosshair",
    "Hitmarkers",
    "World",
    "Recoil Control",
    "Waypoints",
    "Loot",
    "NPCs",
    "Base",
    "Tactical Map",
    "Movement",
    "Config",
}

M._tab_ready = false
M._groups = {}

function M.ensure_tab()
    if M._tab_ready then return end
    -- Bundled april.lua registers the tab in its file header (legacy pattern).
    if not (April and April._menu_tab_ready) and menu and menu.add_tab then
        menu.add_tab(M.TAB, "A", "full")
    end
    M._tab_ready = true
end

function M.group(name)
    M.ensure_tab()
    if not M._groups[name] then
        menu.add_group(M.TAB, name)
        M._groups[name] = true
    end
    return M.TAB, name
end

function M.group_count()
    local n = 0
    for _ in pairs(M._groups) do n = n + 1 end
    return n
end

return M
