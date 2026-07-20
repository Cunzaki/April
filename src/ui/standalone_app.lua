-- Entry for the Gamesense UI demo only (no features, no Vector menu registration).
local custom_menu = April.require("ui.custom_menu")

local M = {}

function M.init()
    if not draw then
        print("[April UI] draw API missing")
        return false
    end
    if not (utility and utility.get_mouse_pos) and not (input and input.is_key_down) then
        print("[April UI] input/utility mouse APIs missing - UI may not be interactive")
    end
    custom_menu.init()
    print("[April UI] Gamesense placeholder ready - INSERT to toggle")
    return true
end

function M.on_frame()
    custom_menu.draw()
end

return M
