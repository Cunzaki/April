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
    if ui_theme.sync then pcall(ui_theme.sync) end
end

function M.accent()
    local anim = anim_mod()
    if anim and type(anim.colors_enabled) == "function" and anim.colors_enabled()
        and type(anim.element_color) == "function" then
        local ok, col = pcall(anim.element_color, 7, anim.COL_OVERLAY)
        if ok and col then return col end
    end
    local gs = gs_theme()
    if gs and gs.ACCENT then
        return gs.ACCENT
    end
    return ui_theme.CYAN
end

function M.panel_bg()
    local gs = gs_theme()
    if gs and gs.PANEL then return gs.PANEL end
    return ui_theme.PANEL
end

function M.header_bg()
    local gs = gs_theme()
    if gs and gs.PANEL_ALT then return gs.PANEL_ALT end
    return ui_theme.HEADER
end

function M.border(alpha)
    local gs = gs_theme()
    if gs and gs.BORDER_SOFT then
        return { gs.BORDER_SOFT[1], gs.BORDER_SOFT[2], gs.BORDER_SOFT[3],
            alpha or gs.BORDER_SOFT[4] or 0.45 }
    end
    return ui_theme.alpha(ui_theme.BORDER, alpha or (ui_theme.BORDER[4] or 0.45))
end

function M.text()
    local gs = gs_theme()
    if gs and gs.TEXT_ACTIVE then return gs.TEXT_ACTIVE end
    return ui_theme.TEXT
end

function M.text_muted()
    local gs = gs_theme()
    if gs and gs.TEXT_DIM then return gs.TEXT_DIM end
    return ui_theme.TEXT_MUTED
end

function M.slot(kind)
    if kind == "held" then return ui_theme.SLOT_HELD end
    if kind == "empty" then return ui_theme.SLOT_EMPTY end
    return ui_theme.SLOT
end

function M.draw_accent_bar(x, y, w, h, alpha)
    h = h or 2
    alpha = alpha == nil and 1 or alpha
    local anim = anim_mod()
    if alpha >= 0.99 and anim and anim.anim_enabled and anim.anim_enabled()
        and anim.anim_target_enabled and anim.anim_target_enabled(anim.TARGET_OVERLAY) then
        anim.draw_bar_h(x, y, w, h, anim.phase and (anim.phase() * 0.1) or 0,
            anim.STYLE_OVERLAY, anim.COL_OVERLAY, anim.TARGET_OVERLAY)
        return
    end
    if draw and draw.line then
        local col = ui_theme.alpha(M.accent(), alpha)
        draw.line(x, y, x + w, y, col, h)
    end
end

function M.panel_opts()
    local gs = gs_theme()
    return {
        bg = M.panel_bg(),
        border = M.border(),
        rounding = gs and gs.CORNER or 6,
        accent = nil,
        accent_w = 0,
    }
end

function M.draw_panel(x, y, w, h, title, opts)
    opts = opts or {}
    local gs = gs_theme()
    local fill = draw and (draw.rect_filled or draw.RectFilled)
    local text = draw and (draw.text or draw.Text)
    local rounding = gs and gs.CORNER or 6
    if fill then
        -- One surface only. Vector shadows every primitive, so layered headers
        -- and borders make these compact modules look embossed.
        fill(x, y, w, h, M.panel_bg(), rounding)
    end
    if title and text then
        if opts.title_center then
            local tw = ui_theme.text_w(title, 11)
            text(x + (w - tw) * 0.5, y + 8, title, M.text(), 11)
        else
            text(x + 12, y + 8, title, M.text(), 11)
        end
    end
end

return M
