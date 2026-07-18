-- Draggable overlay panels (mod checker, keybind viewer). Position persists via menu/gs_state.
local settings = April.require("core.settings")

local M = {}

local state = {}

local function mouse_pos()
    local mx, my = 0, 0
    if utility and utility.get_mouse_pos then
        mx, my = utility.get_mouse_pos()
    elseif input and input.get_mouse_pos then
        mx, my = input.get_mouse_pos()
    end
    return tonumber(mx) or 0, tonumber(my) or 0
end

local function lmb_down()
    return input and input.is_key_down and input.is_key_down(0x01)
end

local function persist_num(id, value)
    value = math.floor(tonumber(value) or 0)
    if menu and menu.set then
        pcall(menu.set, id, value)
    end
    pcall(function()
        April.require("ui.gs_state").set(id, value)
    end)
end

local function blocked()
    local ok, widgets = pcall(function()
        return April.require("ui.gs_widgets")
    end)
    if ok and widgets then
        if widgets.listening_key then return true end
        if widgets.dragging_window then return true end
        if widgets.interacted then return true end
    end
    return false
end

function M.clamp(x, y, w, panel_h, sw, sh)
    w = math.max(160, math.min(420, math.floor(w or 260)))
    panel_h = math.max(40, math.floor(panel_h or 80))
    x = math.max(0, math.min(math.max(0, sw - w), math.floor(x or 0)))
    y = math.max(0, math.min(math.max(0, sh - panel_h), math.floor(y or 0)))
    return x, y, w
end

--- Drag by title bar; returns clamped x, y after handling input this frame.
function M.update(id, x_id, y_id, title_w, title_h, sw, sh, default_x, default_y)
    local st = state[id]
    if not st then
        st = { was_lmb = false, dragging = false, off_x = 0, off_y = 0 }
        state[id] = st
    end

    local x = settings.num(x_id, default_x)
    local y = settings.num(y_id, default_y)
    local mx, my = mouse_pos()
    local lmb = lmb_down()
    local over_title = mx >= x and my >= y
        and mx <= x + title_w and my <= y + title_h

    if lmb and not st.was_lmb and over_title and not blocked() then
        st.dragging = true
        st.off_x = mx - x
        st.off_y = my - y
    end

    if st.dragging then
        if lmb then
            x = mx - st.off_x
            y = my - st.off_y
            persist_num(x_id, x)
            persist_num(y_id, y)
        else
            st.dragging = false
        end
    end

    st.was_lmb = lmb
    return x, y
end

return M
