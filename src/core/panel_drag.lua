-- Click-drag floating HUD panels while the Vector menu is open.
-- Uses utility.get_mouse_pos + input.is_key_down(LMB). Positions write back
-- via menu.set so config_store persists them.

local settings = April.require("core.settings")

local M = {}

local LMB = 0x01
local TITLE_H = 24

local active_id = nil
local grab_dx, grab_dy = 0, 0

local frame = {
    t = -1,
    mx = nil,
    my = nil,
    down = false,
    just_pressed = false,
    open = false,
}

local menu_open_probed = false
local menu_open_fn = nil
local insert_toggle = false
local insert_was_down = false
local INSERT_VK = 0x2D

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function probe_menu_open()
    if menu_open_probed then return menu_open_fn end
    menu_open_probed = true

    if not menu then
        menu_open_fn = nil
        return nil
    end

    local candidates = {
        "is_open", "is_opened", "is_visible", "opened", "visible",
        "IsOpen", "IsOpened", "IsVisible",
    }
    for i = 1, #candidates do
        local fn = menu[candidates[i]]
        if type(fn) == "function" then
            menu_open_fn = function()
                local ok, v = pcall(fn)
                return ok and v == true
            end
            return menu_open_fn
        end
    end

    if type(menu.open) == "boolean" or type(menu.opened) == "boolean" then
        menu_open_fn = function()
            return menu.open == true or menu.opened == true
        end
        return menu_open_fn
    end

    menu_open_fn = nil
    return nil
end

local function track_insert_toggle()
    local down = input and input.is_key_down and input.is_key_down(INSERT_VK) == true
    if down and not insert_was_down then
        insert_toggle = not insert_toggle
    end
    insert_was_down = down
end

local function mouse_pos()
    if utility and utility.get_mouse_pos then
        local ok, mx, my = pcall(utility.get_mouse_pos)
        if ok and mx and my then return mx, my end
    end
    if input and input.get_mouse_pos then
        local ok, mx, my = pcall(input.get_mouse_pos)
        if ok and mx and my then return mx, my end
    end
    return nil, nil
end

local function sync_frame()
    local now = tick_ms()
    if frame.t == now then return end

    local prev_down = frame.down
    frame.t = now
    frame.mx, frame.my = mouse_pos()
    frame.down = input and input.is_key_down and input.is_key_down(LMB) == true
    frame.just_pressed = frame.down and not prev_down

    local fn = probe_menu_open()
    if fn then
        frame.open = fn()
    else
        track_insert_toggle()
        frame.open = insert_toggle
    end

    if not frame.open and active_id then
        active_id = nil
    end
end

function M.menu_is_open()
    sync_frame()
    return frame.open == true
end

local function point_in(mx, my, x, y, w, h)
    return mx >= x and my >= y and mx <= x + w and my <= y + h
end

local function clamp_pos(x, y, w, h, sw, sh)
    w = math.max(40, w or 200)
    h = math.max(24, h or 40)
    sw = sw or 1920
    sh = sh or 1080
    x = math.floor(math.max(0, math.min(sw - w, x)))
    y = math.floor(math.max(0, math.min(sh - h, y)))
    return x, y
end

local function write_pos(x_id, y_id, x, y)
    if menu and menu.set then
        pcall(menu.set, x_id, x)
        pcall(menu.set, y_id, y)
    end
end

-- Call once per frame before drawing the panel.
-- Returns x, y (possibly updated while dragging), and dragging bool.
function M.update(id, x, y, w, h, x_id, y_id, sw, sh)
    sync_frame()

    x = tonumber(x) or 0
    y = tonumber(y) or 0
    w = tonumber(w) or 200
    h = tonumber(h) or 40
    x, y = clamp_pos(x, y, w, h, sw, sh)

    local mx, my = frame.mx, frame.my
    local dragging = false

    if not frame.open or not mx then
        if active_id == id then
            active_id = nil
        end
        return x, y, false
    end

    if active_id == id then
        if frame.down then
            x = mx - grab_dx
            y = my - grab_dy
            x, y = clamp_pos(x, y, w, h, sw, sh)
            write_pos(x_id, y_id, x, y)
            dragging = true
        else
            write_pos(x_id, y_id, x, y)
            active_id = nil
        end
    elseif frame.just_pressed and active_id == nil then
        if point_in(mx, my, x, y, w, TITLE_H) then
            active_id = id
            grab_dx = mx - x
            grab_dy = my - y
            dragging = true
        end
    end

    return x, y, dragging
end

function M.read_pos(x_id, y_id, default_x, default_y)
    return settings.num(x_id, default_x or 16), settings.num(y_id, default_y or 72)
end

function M.title_h()
    return TITLE_H
end

return M
