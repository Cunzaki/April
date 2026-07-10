local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local draw_util = April.require("core.draw_util")
local theme = April.require("core.ui_theme")
local feature_bind = April.require("core.feature_bind")
local panel_drag = April.require("core.panel_drag")

local M = {}

local P = "april_keybinds_enabled"
local X_ID = "april_keybinds_x"
local Y_ID = "april_keybinds_y"
local W_ID = "april_keybinds_w"
local PANEL_ID = "april_keybinds_panel"

-- Full Win32 VK map (printable + modifiers + OEM + media/nav).
local VK_NAMES = {
    [0x01] = "M1", [0x02] = "M2", [0x04] = "M3", [0x05] = "M4", [0x06] = "M5",
    [0x08] = "Backspace", [0x09] = "Tab", [0x0C] = "Clear", [0x0D] = "Enter",
    [0x10] = "Shift", [0x11] = "Ctrl", [0x12] = "Alt",
    [0x13] = "Pause", [0x14] = "Caps", [0x1B] = "Esc",
    [0x20] = "Space",
    [0x21] = "PgUp", [0x22] = "PgDn", [0x23] = "End", [0x24] = "Home",
    [0x25] = "Left", [0x26] = "Up", [0x27] = "Right", [0x28] = "Down",
    [0x29] = "Select", [0x2A] = "Print", [0x2B] = "Execute",
    [0x2C] = "PrtSc", [0x2D] = "Ins", [0x2E] = "Del", [0x2F] = "Help",
    [0x30] = "0", [0x31] = "1", [0x32] = "2", [0x33] = "3", [0x34] = "4",
    [0x35] = "5", [0x36] = "6", [0x37] = "7", [0x38] = "8", [0x39] = "9",
    [0x41] = "A", [0x42] = "B", [0x43] = "C", [0x44] = "D", [0x45] = "E",
    [0x46] = "F", [0x47] = "G", [0x48] = "H", [0x49] = "I", [0x4A] = "J",
    [0x4B] = "K", [0x4C] = "L", [0x4D] = "M", [0x4E] = "N", [0x4F] = "O",
    [0x50] = "P", [0x51] = "Q", [0x52] = "R", [0x53] = "S", [0x54] = "T",
    [0x55] = "U", [0x56] = "V", [0x57] = "W", [0x58] = "X", [0x59] = "Y",
    [0x5A] = "Z",
    [0x5B] = "LWin", [0x5C] = "RWin", [0x5D] = "Apps",
    [0x60] = "Num0", [0x61] = "Num1", [0x62] = "Num2", [0x63] = "Num3",
    [0x64] = "Num4", [0x65] = "Num5", [0x66] = "Num6", [0x67] = "Num7",
    [0x68] = "Num8", [0x69] = "Num9",
    [0x6A] = "Num*", [0x6B] = "Num+", [0x6C] = "Separator",
    [0x6D] = "Num-", [0x6E] = "Num.", [0x6F] = "Num/",
    [0x70] = "F1", [0x71] = "F2", [0x72] = "F3", [0x73] = "F4",
    [0x74] = "F5", [0x75] = "F6", [0x76] = "F7", [0x77] = "F8",
    [0x78] = "F9", [0x79] = "F10", [0x7A] = "F11", [0x7B] = "F12",
    [0x7C] = "F13", [0x7D] = "F14", [0x7E] = "F15", [0x7F] = "F16",
    [0x80] = "F17", [0x81] = "F18", [0x82] = "F19", [0x83] = "F20",
    [0x84] = "F21", [0x85] = "F22", [0x86] = "F23", [0x87] = "F24",
    [0x90] = "NumLock", [0x91] = "Scroll",
    [0xA0] = "LShift", [0xA1] = "RShift",
    [0xA2] = "LCtrl", [0xA3] = "RCtrl",
    [0xA4] = "LAlt", [0xA5] = "RAlt",
    [0xA6] = "BrowserBack", [0xA7] = "BrowserForward",
    [0xA8] = "BrowserRefresh", [0xA9] = "BrowserStop",
    [0xAA] = "BrowserSearch", [0xAB] = "BrowserFav",
    [0xAC] = "BrowserHome",
    [0xAD] = "Mute", [0xAE] = "Vol-", [0xAF] = "Vol+",
    [0xB0] = "NextTrack", [0xB1] = "PrevTrack",
    [0xB2] = "StopMedia", [0xB3] = "PlayPause",
    [0xB4] = "Mail", [0xB5] = "MediaSelect",
    [0xB6] = "App1", [0xB7] = "App2",
    [0xBA] = ";", [0xBB] = "=", [0xBC] = ",", [0xBD] = "-",
    [0xBE] = ".", [0xBF] = "/", [0xC0] = "`",
    [0xDB] = "[", [0xDC] = "\\", [0xDD] = "]", [0xDE] = "'",
    [0xDF] = "OEM8", [0xE2] = "OEM102",
}

local function strip_enable_prefix(label)
    if type(label) ~= "string" then return tostring(label or "?") end
    label = label:gsub("^Enable%s+", "")
    return label
end

local function vk_name(vk)
    vk = tonumber(vk) or 0
    if vk <= 0 then return "—" end

    local named = VK_NAMES[vk]
    if named then return named end

    if vk >= 0x20 and vk <= 0x7E then
        return string.char(vk)
    end

    return string.format("VK-%d", vk)
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
        local hold = feature_bind.is_hold(id)

        if key <= 0 and not show_unbound then
            goto continue
        end
        if only_active and not active then
            goto continue
        end

        rows[#rows + 1] = {
            id = id,
            label = strip_enable_prefix(entry.label or id),
            key = vk_name(key),
            mode = hold and "Hold" or "Toggle",
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
    menu.add_checkbox(T, G.MISC, "april_keybinds_active_only", "Only Show Active", false, root)
    menu.add_checkbox(T, G.MISC, "april_keybinds_show_unbound", "Show Unbound", true, root)
    menu.add_checkbox(T, G.MISC, "april_keybinds_show_mode", "Show Bind Mode", true, root)

    menu_util.gap(T, G.MISC)
    menu_util.label(T, G.MISC, "Drag the panel title while Vector UI is open.")
    menu.add_slider_int(T, G.MISC, X_ID, "Pos X", 0, 4000, 16, root)
    menu.add_slider_int(T, G.MISC, Y_ID, "Pos Y", 0, 4000, 280, root)
    menu.add_slider_int(T, G.MISC, W_ID, "Width", 160, 420, 260, root)

    menu_util.bind_children(P, {
        "april_keybinds_active_only", "april_keybinds_show_unbound", "april_keybinds_show_mode",
        X_ID, Y_ID, W_ID,
    })
end

function M.update(_dt) end

function M.draw()
    if not settings.enabled(P) then return end
    if not draw or not draw.text then return end

    local sw, sh = draw_util.screen_size()
    local panel_w = settings.num(W_ID, 260)
    local x = settings.num(X_ID, 16)
    local y = settings.num(Y_ID, 280)

    local rows = collect_rows()
    local pad = 10
    local title_h = panel_drag.title_h()
    local row_h = 18
    local count = math.max(#rows, 1)
    local height = title_h + count * row_h + 10

    local dragging
    x, y, dragging = panel_drag.update(PANEL_ID, x, y, panel_w, height, X_ID, Y_ID, sw, sh)

    local can_drag = panel_drag.menu_is_open()
    theme.draw_panel(x, y, panel_w, height, {
        bg = theme.alpha(theme.BG, 0.88),
        border = theme.alpha(theme.BORDER, (dragging or can_drag) and 0.7 or 0.4),
        accent = theme.CYAN,
        accent_w = 2,
        rounding = theme.ROUND,
    })

    local title = "Keybinds"
    if can_drag then
        title = title .. "  · drag"
    end
    draw_util.text(x + pad, y + 5, title, theme.TEXT, 12)

    local ry = y + title_h
    if #rows == 0 then
        draw_util.text(x + pad, ry, "No binds", theme.TEXT_MUTED, 11)
        return
    end

    for i = 1, #rows do
        local row = rows[i]
        local name_col = row.active and theme.TEXT or theme.TEXT_MUTED
        local key_col = row.active and theme.CYAN or theme.TEXT_DIM

        local label = row.label
        if #label > 16 then label = label:sub(1, 14) .. ".." end
        draw_util.text(x + pad, ry, label, name_col, 11)

        local right = row.key
        if row.show_mode then
            right = right .. " · " .. row.mode
        end
        local tw = theme.text_w(right, 11)
        draw_util.text(x + panel_w - pad - tw, ry, right, key_col, 11)

        ry = ry + row_h
    end
end

return M
