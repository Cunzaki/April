-- Mouse / key helpers. Raw cursor only — no windowed offset correction.
-- Wheel: UserInputService InputChanged + engine getters + PlayerMouse signals.
local M = {}

local prev_keys = {}
local prev_lmb = false
local prev_rmb = false
local prev_mmb = false

M.mx = 0
M.my = 0
M.raw_mx = 0
M.raw_my = 0
M.lmb = false
M.rmb = false
M.mmb = false
M.lmb_click = false
M.rmb_click = false
M.mmb_click = false
M.lmb_release = false
M.wheel = 0
M._wheel_accum = 0
M._scroll_ready = false
M._scroll_hook_tries = 0
M._uis_hooked = false
M._game_cursor_hidden = false
M._menu_open = false
M.ui_x, M.ui_y, M.ui_w, M.ui_h = 0, 0, 0, 0

local function on_wheel(dir)
    if not dir or dir == 0 then return end
    M._wheel_accum = (M._wheel_accum or 0) + dir
end

local function connect_signal(signal, fn)
    if not signal then return false end
    local connect = signal.Connect or signal.connect
    if type(connect) ~= "function" then return false end
    local ok = pcall(function()
        connect(signal, fn)
    end)
    return ok
end

local function wheel_from_input_obj(inputObj)
    if not inputObj then return 0 end
    local typ = inputObj.UserInputType or inputObj.user_input_type
    local name = tostring(typ):lower()
    if not name:find("wheel") and not name:find("mousewheel") then
        return 0
    end
    local pos = inputObj.Position or inputObj.position
    local z = pos and (pos.Z or pos.z or pos[3]) or 0
    if z == 0 then
        local delta = inputObj.Delta or inputObj.delta
        if delta then
            z = delta.Z or delta.z or delta[3] or 0
        end
    end
    if z == 0 then
        local dz = inputObj.Z or inputObj.z
        if dz then z = dz end
    end
    if z == 0 then return 0 end
    return z > 0 and 1 or -1
end

local function hook_user_input_service()
    if M._uis_hooked then return true end
    if not game then return false end

    local uis = nil
    pcall(function()
        if game.GetService then uis = game:GetService("UserInputService") end
    end)
    if not uis then
        pcall(function()
            if game.get_service then uis = game:get_service("UserInputService") end
        end)
    end
    if not uis then return false end

    local hooked = false
    local function handle(inputObj)
        if not M._menu_open then return end
        local dir = wheel_from_input_obj(inputObj)
        if dir ~= 0 then on_wheel(dir) end
    end

    if connect_signal(uis.InputChanged or uis.input_changed, handle) then
        hooked = true
    end
    if connect_signal(uis.InputBegan or uis.input_began, handle) then
        hooked = true
    end

    if hooked then
        M._uis_hooked = true
    end
    return hooked
end

local function pcall_get_service(name)
    local svc = nil
    if not game then return nil end
    pcall(function()
        if game.GetService then svc = game:GetService(name) end
    end)
    if not svc then
        pcall(function()
            if game.get_service then svc = game:get_service(name) end
        end)
    end
    return svc
end

local function hook_player_mouse()
    local lp = game and game.local_player
    if not lp then return false end
    local mouse = nil
    pcall(function()
        if lp.GetMouse then mouse = lp:GetMouse()
        elseif lp.get_mouse then mouse = lp:get_mouse()
        elseif lp.Mouse then mouse = lp.Mouse
        end
    end)
    if not mouse then return false end
    local ok = false
    if connect_signal(mouse.WheelForward or mouse.wheel_forward, function()
        on_wheel(1)
    end) then ok = true end
    if connect_signal(mouse.WheelBackward or mouse.wheel_backward, function()
        on_wheel(-1)
    end) then ok = true end
    return ok
end

local SCROLL_GETTERS = {
    "get_scroll_delta", "get_mouse_wheel", "get_mouse_scroll",
    "get_wheel_delta", "get_scroll", "scroll_delta",
    "mouse_wheel_delta", "wheel_delta", "scroll_y",
}

local function poll_scroll_getters()
    local tables = { input, utility, draw }
    for ti = 1, #tables do
        local tbl = tables[ti]
        if type(tbl) == "table" then
            for _, name in ipairs(SCROLL_GETTERS) do
                local fn = tbl[name]
                if type(fn) == "function" then
                    local ok, v = pcall(fn)
                    if ok and v ~= nil then
                        local n = tonumber(v)
                        if n and n ~= 0 then
                            on_wheel(n > 0 and 1 or -1)
                        elseif type(v) == "table" then
                            local z = tonumber(v.z or v.Z or v[3])
                            if z and z ~= 0 then
                                on_wheel(z > 0 and 1 or -1)
                            end
                        end
                    end
                end
                local prop = tbl[name]
                if type(prop) == "number" and prop ~= 0 then
                    on_wheel(prop > 0 and 1 or -1)
                end
            end
        end
    end
end

local function ensure_scroll_hooks()
    if M._scroll_ready then return end
    M._scroll_hook_tries = (M._scroll_hook_tries or 0) + 1
    if hook_user_input_service() or hook_player_mouse() then
        M._scroll_ready = true
    elseif M._scroll_hook_tries > 240 then
        M._scroll_ready = true
    end
end

function M.set_ui_rect(x, y, w, h)
    M.ui_x, M.ui_y, M.ui_w, M.ui_h = x, y, w, h
end

function M.set_menu_open(open)
    M._menu_open = open == true
    M.set_game_cursor_visible(not M._menu_open)
end

function M.set_game_cursor_visible(visible)
    local sg = pcall_get_service("StarterGui")
    if sg then
        pcall(function()
            if sg.SetCore then sg:SetCore("MouseIconEnabled", visible) end
        end)
        pcall(function()
            if sg.set_core then sg:set_core("MouseIconEnabled", visible) end
        end)
    end

    local uis = pcall_get_service("UserInputService")
    if uis then
        pcall(function() uis.MouseIconEnabled = visible end)
        pcall(function() uis.mouse_icon_enabled = visible end)
    end

    pcall(function()
        local lp = game and game.local_player
        if not lp then return end
        local mouse = lp.GetMouse and lp:GetMouse() or (lp.get_mouse and lp:get_mouse())
        if not mouse then return end
        if not visible then
            mouse.Icon = "rbxassetid://0"
            if mouse.icon ~= nil then mouse.icon = "rbxassetid://0" end
        else
            mouse.Icon = ""
        end
    end)

    M._game_cursor_hidden = not visible
end

function M.mouse()
    return M.mx, M.my
end

function M.key_down(vk)
    return input and input.is_key_down and input.is_key_down(vk) or false
end

function M.key_pressed(vk)
    local down = M.key_down(vk)
    local was = prev_keys[vk] == true
    prev_keys[vk] = down
    return down and not was
end

function M.begin_frame()
    ensure_scroll_hooks()

    local amx, amy = 0, 0
    if utility and utility.get_mouse_pos then
        amx, amy = utility.get_mouse_pos()
    elseif input and input.get_mouse_pos then
        amx, amy = input.get_mouse_pos()
    end
    amx = tonumber(amx) or 0
    amy = tonumber(amy) or 0
    M.raw_mx, M.raw_my = amx, amy
    M.mx, M.my = amx, amy

    M.lmb = M.key_down(0x01)
    M.rmb = M.key_down(0x02)
    M.mmb = M.key_down(0x04)
    M.lmb_click = M.lmb and not prev_lmb
    M.rmb_click = M.rmb and not prev_rmb
    M.mmb_click = M.mmb and not prev_mmb
    M.lmb_release = (not M.lmb) and prev_lmb
    prev_lmb = M.lmb
    prev_rmb = M.rmb
    prev_mmb = M.mmb

    poll_scroll_getters()

    if M._menu_open and M.hover(M.ui_x, M.ui_y, M.ui_w, M.ui_h) then
        if M.key_pressed(0x21) then on_wheel(3) end
        if M.key_pressed(0x22) then on_wheel(-3) end
    end

    local w = M._wheel_accum
    M._wheel_accum = 0
    if w > 0 then
        M.wheel = math.max(1, math.floor(w + 0.5))
    elseif w < 0 then
        M.wheel = math.min(-1, math.ceil(w - 0.5))
    else
        M.wheel = 0
    end
end

function M.hover(x, y, w, h)
    return M.mx >= x and M.my >= y and M.mx <= x + w and M.my <= y + h
end

function M.clicked(x, y, w, h)
    return M.lmb_click and M.hover(x, y, w, h)
end

function M.draw_cursor()
    if not draw then return end
    local show = true
    pcall(function()
        show = April.require("core.settings").bool("april_ui_show_cursor_dot", true)
    end)
    if not show then return end
    local x, y = M.mx, M.my
    local col = { 0.75, 0.15, 0.83, 1 }
    if draw.circle_filled then
        draw.circle_filled(x, y, 4.5, col, 14)
    end
    if draw.circle then
        draw.circle(x, y, 5.5, { 1, 1, 1, 0.9 }, 16, 1.4)
    end
end

return M
