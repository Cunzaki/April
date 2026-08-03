-- Menu atmosphere drawn behind chrome (dim + optional snow).
local state = April.require("ui.gs_state")
local widgets = April.require("ui.gs_widgets")
local anim = April.require("ui.gs_anim")
local settings = April.require("core.settings")

local M = {}
local flakes = {}
local flake_count = 0
local last_now = nil

local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

local function screen_size()
    local w, h
    if draw then
        local fn = draw.get_screen_size or draw.GetScreenSize
        if fn then
            local ok, a, b = pcall(fn)
            if ok then w, h = a, b end
        end
    end
    if (not w or not h or w <= 0 or h <= 0) and utility then
        local fn = utility.get_screen_size or utility.GetScreenSize
        if fn then
            local ok, a, b = pcall(fn)
            if ok then w, h = a, b end
        end
    end
    w = math.floor(tonumber(w) or 0)
    h = math.floor(tonumber(h) or 0)
    if w <= 0 then w = 1920 end
    if h <= 0 then h = 1080 end
    return w, h
end

local function rebuild(count, sw, sh)
    flakes = {}
    flake_count = count
    for i = 1, count do
        flakes[i] = {
            x = math.random() * sw,
            y = math.random() * sh,
            size = 1.2 + math.random() * 2.4,
            speed = 0.35 + math.random() * 1.15,
            drift = (math.random() - 0.5) * 0.55,
            phase = math.random() * 6.28318,
            wobble = 0.6 + math.random() * 1.4,
        }
    end
end

local function dt()
    local now = anim.now()
    local d = 0.016
    if last_now then d = clamp(now - last_now, 0, 0.05) end
    last_now = now
    return d
end

local function fill_rect(x, y, w, h, col)
    if not draw or w <= 0 or h <= 0 then return end
    local fill = draw.rect_filled or draw.RectFilled or draw.filled_rect
    if not fill then return end
    pcall(fill, x, y, w, h, col, 0)
end

function M.draw_overlay(sw, sh, open_progress)
    if not settings.bool("april_ui_menu_overlay", true) then return end

    local strength = clamp(settings.num("april_ui_overlay_strength", 70), 0, 100)
    if strength <= 0 then
        -- Legacy profiles may still have the toggle on with unset strength.
        strength = 70
    end

    local t = open_progress or 0
    if anim.ease_out_cubic then
        t = anim.ease_out_cubic(t)
    end
    t = clamp(t, 0, 1)
    if t < 0.01 then return end

    -- Strong enough to read clearly around the menu (intro uses up to 1.0).
    local a = (strength / 100) * 0.88 * t
    if a < 0.02 then return end

    widgets.clip = nil
    sw = math.floor(tonumber(sw) or 0)
    sh = math.floor(tonumber(sh) or 0)
    if sw <= 0 or sh <= 0 then
        sw, sh = screen_size()
    end
    -- Vector silently rejects draw coordinates exactly at (0, 0).
    -- Start just outside the viewport and extend both edges instead.
    fill_rect(-1, -1, sw + 2, sh + 2, { 0, 0, 0, a })
end

function M.draw_snow(sw, sh, open_progress)
    if not settings.bool("april_ui_snow", false) or anim.reduce_motion() then return end
    local fade = anim.ease_out_cubic and anim.ease_out_cubic(open_progress or 0) or (open_progress or 0)
    if fade < 0.02 then return end

    sw = math.floor(tonumber(sw) or 0)
    sh = math.floor(tonumber(sh) or 0)
    if sw <= 0 or sh <= 0 then
        sw, sh = screen_size()
    end

    local amount = math.floor(clamp(settings.num("april_ui_snow_amount", 50), 10, 140) + 0.5)
    local speed_mul = clamp(settings.num("april_ui_snow_speed", 40), 1, 100) / 40
    local opacity = clamp(settings.num("april_ui_snow_opacity", 55), 10, 100) / 100
    local size_mul = clamp(settings.num("april_ui_snow_size", 3), 1, 8) / 3
    if flake_count ~= amount or #flakes == 0 then rebuild(amount, sw, sh) end

    widgets.clip = nil
    local step = dt()
    local fall = 38 * speed_mul * step
    local alpha = opacity * fade * 0.9
    for i = 1, #flakes do
        local f = flakes[i]
        f.phase = f.phase + step * f.wobble
        f.y = f.y + fall * f.speed
        f.x = f.x + math.sin(f.phase) * f.drift * 18 * step * speed_mul
        if f.y > sh + 6 then
            f.y = -6 - math.random() * 24
            f.x = math.random() * sw
        elseif f.x < -8 then
            f.x = sw + 4
        elseif f.x > sw + 8 then
            f.x = -4
        end
        local s = math.max(1, f.size * size_mul)
        local a = alpha * (0.55 + 0.45 * ((math.sin(f.phase * 0.7) + 1) * 0.5))
        fill_rect(f.x, f.y, s, s, { 0.92, 0.95, 1.0, a })
    end
end

function M.draw_backdrop(sw, sh, open_progress)
    if (not sw or not sh or sw <= 0 or sh <= 0) then
        sw, sh = screen_size()
    end
    M.draw_overlay(sw, sh, open_progress)
    M.draw_snow(sw, sh, open_progress)
end

return M
