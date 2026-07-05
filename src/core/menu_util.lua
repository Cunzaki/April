--[[
    Vector "full" mode grid (Lone script pattern):
      menu.add_group(tab, name)           → left column, new row
      menu.add_group(tab, name, 0, true)  → right column, same row as previous left
]]

local M = {}

M.TAB = "April"

M.G = {
    COMBAT = "Combat",
    VISUALS = "Visuals",
    WORLD = "World",
    RADAR = "Radar",
    MISC = "Misc",
    CONFIG = "Config",
}

-- Which side each group renders on (must register left before its right pair).
M.G_SIDE = {
    [M.G.COMBAT] = "left",
    [M.G.VISUALS] = "right",
    [M.G.WORLD] = "left",
    [M.G.RADAR] = "right",
    [M.G.MISC] = "left",
    [M.G.CONFIG] = "right",
}

M._tab_ready = false
M._groups = {}

function M.ensure_tab()
    if M._tab_ready then return end
    if not (April and April._menu_tab_ready) and menu and menu.add_tab then
        menu.add_tab(M.TAB, "A", "full")
    end
    M._tab_ready = true
end

function M.group(name, side)
    M.ensure_tab()
    if M._groups[name] then
        return M.TAB, name
    end

    side = side or M.G_SIDE[name] or "left"

    if menu and menu.add_group then
        if side == "right" then
            menu.add_group(M.TAB, name, 0, true)
        else
            menu.add_group(M.TAB, name)
        end
        M._groups[name] = true
    end

    return M.TAB, name
end

function M.section(T, G, _title)
    menu.add_separator(T, G)
end

function M.parent(main_id, extra)
    local opts = { parent = main_id }
    if type(extra) == "table" then
        for k, v in pairs(extra) do
            opts[k] = v
        end
    end
    return opts
end

return M
