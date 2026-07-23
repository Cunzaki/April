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
    return ui_theme.PANEL
end

function M.header_bg()
    return ui_theme.HEADER
end

function M.border(alpha)
    return ui_theme.alpha(ui_theme.BORDER, alpha or (ui_theme.BORDER[4] or 0.45))
end

function M.text()
    return ui_theme.TEXT
end

function M.text_muted()
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
    return {
        bg = M.panel_bg(),
        border = M.border(),
        rounding = 0,
        accent = nil,
        accent_w = 0,
    }
end

function M.draw_panel(x, y, w, h, title, opts)
    opts = opts or {}
    ui_theme.draw_panel(x, y, w, h, M.panel_opts())
    if draw and draw.rect_filled then
        draw.rect_filled(x + 1, y + 3, w - 2, 21, M.header_bg(), 0)
    end
    M.draw_accent_bar(x + 1, y, w - 2, 2)
    if title and draw and draw.text then
        if opts.title_center then
            local tw = ui_theme.text_w(title, 11)
            draw.text(x + (w - tw) * 0.5, y + 6, title, M.text(), 11)
        else
            draw.text(x + 9, y + 6, title, M.text(), 11)
        end
    end
end

return M
