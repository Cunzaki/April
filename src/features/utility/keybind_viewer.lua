local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local draw_util = April.require("core.draw_util")
local theme = April.require("core.ui_theme")
local feature_bind = April.require("core.feature_bind")
local vk_names = April.require("core.vk_names")
local panel_drag = April.require("core.panel_drag")
local overlay_theme = April.require("core.overlay_theme")

local M = {}

local P = "april_keybinds_enabled"
local X_ID = "april_keybinds_x"
local Y_ID = "april_keybinds_y"
local PANEL_W = 260
local TITLE_H = 22

local function strip_enable_prefix(label)
    if type(label) ~= "string" then return tostring(label or "?") end
    label = label:gsub("^Enable%s+", "")
    return label
end

local function collect_rows()
    local rows = {}
    local only_active = settings.bool("april_keybinds_active_only", false)
    local show_unbound = settings.bool("april_keybinds_show_unbound", true)
    local show_mode = settings.bool("april_keybinds_show_mode", true)

    for _, entry in ipairs(feature_bind.list_entries()) do
        local id = entry.id
        local key = feature_bind.get_key(id)
        local active = feature_bind.active(id)
        if key <= 0 and not show_unbound then
            goto continue
        end
        if only_active and not active then
            goto continue
        end

        rows[#rows + 1] = {
            id = id,
            label = strip_enable_prefix(entry.label or id),
            key = vk_names.chip(key),
            mode = feature_bind.mode_name(id),
            active = active,
            show_mode = show_mode,
        }

        ::continue::
    end

    table.sort(rows, function(a, b)
        if a.active ~= b.active then return a.active end
        return a.label < b.label
    end)

    return rows
end

function M.register_menu()
    local G = menu_util.G
    local T = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu.add_checkbox(T, G.MISC, P, "Keybind Viewer", false)

    menu_util.section(T, G.MISC, "Keybinds Display")
    menu.add_checkbox(T, G.MISC, "april_keybinds_active_only", "Only Show Active", false, root)
    menu.add_checkbox(T, G.MISC, "april_keybinds_show_unbound", "Show Unbound", true, root)
    menu.add_checkbox(T, G.MISC, "april_keybinds_show_mode", "Show Bind Mode", true, root)

    menu_util.bind_children(P, {
        "april_keybinds_active_only", "april_keybinds_show_unbound", "april_keybinds_show_mode",
    })
end

function M.update(_dt) end

function M.draw()
    if not settings.enabled(P) then return end
    if not draw or not draw.text then return end

    overlay_theme.sync()
    local accent = overlay_theme.accent()

    local sw, sh = draw_util.screen_size()
    local rows = collect_rows()
    local pad = 10
    local row_h = 18
    local count = math.max(#rows, 1)
    local height = TITLE_H + count * row_h + 10

    local x, y = panel_drag.update(
        "keybind_viewer",
        X_ID, Y_ID,
        PANEL_W, TITLE_H,
        sw, sh,
        16, 280
    )
    x, y = panel_drag.clamp(x, y, PANEL_W, height, sw, sh)

    theme.draw_panel(x, y, PANEL_W, height, overlay_theme.panel_opts())
    overlay_theme.draw_accent_bar(x + 1, y, PANEL_W - 2, 2)

    draw_util.text(x + pad, y + 5, "Keybinds", theme.TEXT, 12)

    local ry = y + TITLE_H
    if #rows == 0 then
        draw_util.text(x + pad, ry, "No binds", theme.TEXT_MUTED, 11)
        return
    end

    local max_label = math.max(8, math.floor((PANEL_W - pad * 2) * 0.55 / 7))

    for i = 1, #rows do
        local row = rows[i]
        local name_col = row.active and theme.TEXT or theme.TEXT_MUTED
        local key_col = row.active and accent or theme.TEXT_DIM

        local label = row.label
        if #label > max_label then label = label:sub(1, math.max(1, max_label - 2)) .. ".." end
        draw_util.text(x + pad, ry, label, name_col, 11)

        local right = row.key
        if row.show_mode then
            right = right .. " - " .. row.mode
        end
        local tw = theme.text_w(right, 11)
        draw_util.text(x + PANEL_W - pad - tw, ry, right, key_col, 11)

        ry = ry + row_h
    end
end

return M
