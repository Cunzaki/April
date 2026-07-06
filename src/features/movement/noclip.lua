--[[ Noclip menu — movement handled by core/movement_ctrl.lua ]]

local menu_util = April.require("core.menu_util")

local M = {}

local P = "april_walk_noclip_enabled"
local P_SPEED = "april_walk_noclip_speed"

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.register_keybind(T, G.MISC, P, "Noclip", false)
    menu.add_slider_int(T, G.MISC, P_SPEED, "Noclip Speed", 8, 80, 32, root)
    menu_util.bind_children(P, { P_SPEED })
end

function M.update(_dt) end

function M.draw() end

return M
