local settings = April.require("core.settings")

local M = {}

function M.register_menu()
    menu.add_group("Combat", "Recoil")
    menu.add_checkbox("Combat", "Recoil", "april_recoil_enabled", "Enable Recoil Control", false)
    menu.add_slider_float("Combat", "Recoil", "april_recoil_strength", "Strength", 0, 5, 1.0, "%.1f")
end

function M.update(dt)
    if not settings.bool("april_recoil_enabled", false) then return end
    if not input or not input.is_key_down or not input.move_mouse then return end
    if not input.is_key_down(0x01) or not input.is_key_down(0x02) then return end
    local strength = settings.num("april_recoil_strength", 1.0)
    input.move_mouse(0, strength * 2)
end

function M.draw() end

return M
