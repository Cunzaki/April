local settings = April.require("core.settings")
local G = April.require("core.menu_util").G
local T = April.require("core.menu_util").tab()

local M = {}
local P = "april_recoil_enabled"

function M.register_menu()
    menu.add_checkbox(T, G.RECOIL, "april_recoil_enabled", "Enable Recoil Control", false, { key = 0 })
    menu.add_slider_float(T, G.RECOIL, "april_recoil_strength", "Global Strength (Y)", 0, 10, 1.0, "%.1f", { parent = P })
    menu.add_slider_float(T, G.RECOIL, "april_recoil_strength_x", "Global Strength (X)", -10, 10, 0, "%.1f", { parent = P })
    menu.add_checkbox(T, G.RECOIL, "april_recoil_auto", "Scale With Fire Rate", true, { parent = P })
    menu.add_separator(T, G.RECOIL)
    menu.add_label(T, G.RECOIL, "Per-weapon overrides (0 = use global)")
    menu.add_slider_float(T, G.RECOIL, "april_rc_ak47_y", "AK47 (Y)", 0, 10, 0, "%.1f", { parent = P })
    menu.add_slider_float(T, G.RECOIL, "april_rc_ak47_x", "AK47 (X)", -10, 10, 0, "%.1f", { parent = P })
    menu.add_slider_float(T, G.RECOIL, "april_rc_m4_y", "M4A1 (Y)", 0, 10, 0, "%.1f", { parent = P })
    menu.add_slider_float(T, G.RECOIL, "april_rc_m4_x", "M4A1 (X)", -10, 10, 0, "%.1f", { parent = P })
    menu.add_slider_float(T, G.RECOIL, "april_rc_smg_y", "SMG (Y)", 0, 10, 0, "%.1f", { parent = P })
    menu.add_slider_float(T, G.RECOIL, "april_rc_smg_x", "SMG (X)", -10, 10, 0, "%.1f", { parent = P })
end

function M.update(dt)
    if not settings.bool("april_recoil_enabled", false) then return end
    if not input or not input.is_key_down or not input.move_mouse then return end
    if not input.is_key_down(0x01) then return end
    local y = settings.num("april_recoil_strength", 1.0)
    local x = settings.num("april_recoil_strength_x", 0)
    if settings.bool("april_recoil_auto", true) then
        y = y * (dt and (1 / math.max(dt, 0.008)) or 1) * 0.016
    end
    input.move_mouse(x, y * 2)
end

function M.draw() end

return M
