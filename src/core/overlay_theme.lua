-- Theme helpers for draggable overlay panels (keybind viewer, mod checker).
local ui_theme = April.require("core.ui_theme")

local M = {}

local function gs_theme()
    local ok, theme = pcall(function()
        return April.require("ui.gs_theme")
    end)
    if ok then return theme end
    return nil
end

local function anim_mod()
    local ok, anim = pcall(function()
        return April.require("ui.gs_anim")
    end)
    if ok then return anim end
    return nil
end

function M.sync()
    local anim = anim_mod()
    if anim and anim.sync_theme then
        pcall(anim.sync_theme)
    end
end

function M.accent()
    local anim = anim_mod()
    if anim and anim.colors_enabled and anim.colors_enabled() then
        return anim.element_color(7, anim.COL_OVERLAY)
    end
    local gs = gs_theme()
    if gs and gs.ACCENT then
        return gs.ACCENT
    end
    return ui_theme.CYAN
end

function M.panel_bg()
    local anim = anim_mod()
    if anim and anim.colors_enabled and anim.colors_enabled() and anim.panel_bg then
        return anim.panel_bg()
    end
    return ui_theme.alpha(ui_theme.BG, 0.90)
end

function M.draw_accent_bar(x, y, w, h)
    h = h or 2
    local anim = anim_mod()
    if anim and anim.anim_enabled and anim.anim_enabled()
        and anim.anim_target_enabled and anim.anim_target_enabled(anim.TARGET_OVERLAY) then
        anim.draw_bar_h(x, y, w, h, anim.phase and (anim.phase() * 0.1) or 0,
            anim.STYLE_OVERLAY, anim.COL_OVERLAY, anim.TARGET_OVERLAY)
        return
    end
    if draw and draw.line then
        local col = M.accent()
        draw.line(x, y, x + w, y, col, h)
    end
end

function M.panel_opts()
    return {
        bg = M.panel_bg(),
        border = ui_theme.alpha(ui_theme.BORDER, 0.45),
        rounding = ui_theme.ROUND,
        accent = nil,
        accent_w = 0,
    }
end

return M
