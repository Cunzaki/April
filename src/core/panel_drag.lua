-- Draggable overlay panels (mod checker, keybind viewer). Position persists via menu/gs_state.
local settings = April.require("core.settings")

local M = {}

local state = {}
local custom_menu = nil
local widgets = nil
local gs_state = nil

local function resolve_ui_modules()
    if not custom_menu then
        pcall(function() custom_menu = April.require("ui.custom_menu") end)
    end
    if not widgets then
        pcall(function() widgets = April.require("ui.gs_widgets") end)
    end
    if not gs_state then
        pcall(function() gs_state = April.require("ui.gs_state") end)
    end
end

local function mouse_pos()
    local mx, my = 0, 0
    local util_mouse = utility and (utility.get_mouse_pos or utility.GetMousePos)
    local input_mouse = input and (input.get_mouse_pos or input.get_mouse_position or input.GetMousePosition)
    if util_mouse then
        mx, my = util_mouse()
    elseif input_mouse then
        mx, my = input_mouse()
    end
    return tonumber(mx) or 0, tonumber(my) or 0
end

local function lmb_down()
    local fn = input and (input.is_key_down or input.IsKeyDown)
    return fn and fn(0x01)
end

local function persist_num(id, value)
    value = math.floor(tonumber(value) or 0)
    if menu and menu.set then
        pcall(menu.set, id, value)
    end
    resolve_ui_modules()
    if gs_state and gs_state.set then pcall(gs_state.set, id, value) end
end

local function blocked(mx, my, allow_menu)
    resolve_ui_modules()
    if custom_menu and custom_menu.contains_point
        and custom_menu.contains_point(mx or 0, my or 0)
        and not allow_menu
    then
        return true
    end
    if widgets then
        if widgets.listening_key then return true end
        if widgets.dragging_window then return true end
        if widgets.interacted then return true end
    end
    return false
end

function M.clamp(x, y, w, panel_h, sw, sh, x_id, y_id)
    local old_x, old_y = x, y
    w = math.max(160, math.min(420, math.floor(w or 260)))
    panel_h = math.max(40, math.floor(panel_h or 80))
    x = math.max(0, math.min(math.max(0, sw - w), math.floor(x or 0)))
    y = math.max(0, math.min(math.max(0, sh - panel_h), math.floor(y or 0)))
    if x_id and x ~= old_x then persist_num(x_id, x) end
    if y_id and y ~= old_y then persist_num(y_id, y) end
    return x, y, w
end

--- Drag by title bar; returns clamped x, y after handling input this frame.
--- allow_menu permits overlay movement while April's menu is open.
function M.update(id, x_id, y_id, title_w, title_h, sw, sh, default_x, default_y, allow_menu)
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

    if lmb and not st.was_lmb and over_title and not blocked(mx, my, allow_menu) then
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
