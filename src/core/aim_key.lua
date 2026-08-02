-- Aim-key state (Always / Hold / Toggle) separate from feature master toggle.
local settings = April.require("core.settings")

local M = {}

M.MODES = { "Always", "Hold", "Toggle" }

local toggled = {}
local last_down = {}
local last_key = {}
local last_mode = {}

local function key_down(vk)
    if not input then return false end
    local fn = input.is_key_down or input.IsKeyDown
    if type(fn) ~= "function" then return false end
    local ok, down = pcall(fn, vk)
    return ok and down == true
end

local function key_capture_active()
    local ok, widgets = pcall(function()
        return April.require("ui.gs_widgets")
    end)
    return ok and widgets and widgets.listening_key ~= nil
end

local function key_store()
    return April.require("ui.gs_state")
end

function M.mode_index(mode_id)
    return settings.combo_index(mode_id, M.MODES, 0)
end

function M.tick(key_id, mode_id)
    if not input or type(input.is_key_down or input.IsKeyDown) ~= "function" then return end
    local mode = M.mode_index(mode_id)
    local vk = key_store().get_key(key_id)
    local changed = last_key[key_id] ~= vk or last_mode[key_id] ~= mode
    if changed then
        last_key[key_id] = vk
        last_mode[key_id] = mode
        last_down[key_id] = vk > 0 and key_down(vk) or false
    end
    if key_capture_active() then
        last_down[key_id] = vk > 0 and key_down(vk) or false
        return
    end
    if mode == 0 then
        if vk > 0 then last_down[key_id] = key_down(vk) end
        return
    end
    if vk <= 0 then return end
    local down = key_down(vk)
    if mode == 1 then
        last_down[key_id] = down
        return
    end
    -- Toggle
    if not changed and down and not last_down[key_id] then
        toggled[key_id] = not (toggled[key_id] == true)
    end
    last_down[key_id] = down
end

function M.active(key_id, mode_id)
    local mode = M.mode_index(mode_id)
    if mode == 0 then return true end
    local vk = key_store().get_key(key_id)
    if vk <= 0 then return mode == 0 end
    if mode == 1 then
        return key_down(vk)
    end
    return toggled[key_id] == true
end

function M.reset(key_id)
    toggled[key_id] = false
    last_down[key_id] = false
    last_key[key_id] = nil
    last_mode[key_id] = nil
end

return M
