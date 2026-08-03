-- Optional startup splash rendered entirely with Project Vector draw primitives.
local theme = April.require("ui.gs_theme")
local anim = April.require("ui.gs_anim")
local settings = April.require("core.settings")
local image_cache = April.require("core.image_cache")
local asset_urls = April.require("game.asset_urls")

local M = {}
local DURATION = 4.35
local MENU_REVEAL_AT = 3.72
local TEXT_EXIT_AT = 3.12
local PROFILE_KEY = "startup_author_profile"

local active = false
local started_at = 0

local function clamp01(value)
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

local function ease_out_cubic(value)
    local t = clamp01(value)
    local q = 1 - t
    return 1 - q * q * q
end

local function now()
    if utility and utility.get_time then return utility.get_time() end
    if utility and utility.get_tick_count then return utility.get_tick_count() * 0.001 end
    return 0
end

local function screen_size()
    local fn = draw and (draw.get_screen_size or draw.GetScreenSize)
    if fn then
        local ok, width, height = pcall(fn)
        if ok and width and height then return width, height end
    end
    return 1920, 1080
end

local function text_width(text, size)
    local fn = draw and (draw.get_text_size or draw.GetTextSize)
    if fn then
        local ok, width = pcall(fn, text, size)
        if ok and type(width) == "number" then return width end
    end
    return #tostring(text or "") * size * 0.56
end

local function draw_wave(text, center_x, y, size, alpha, phase_offset, amplitude)
    if alpha <= 0 or not draw then return end
    local draw_text = draw.text or draw.Text
    if not draw_text then return end

    local total_width = text_width(text, size)
    local cursor_x = center_x - total_width * 0.5
    local phase = now() * 4.0 + (phase_offset or 0)
    local accent = anim.title_color()
    amplitude = amplitude or 2

    for index = 1, #text do
        local char = text:sub(index, index)
        local wave = math.sin(phase + (index - 1) * 0.68)
        local mix = 0.12 + (wave + 1) * 0.12
        local color = anim.mix(accent, theme.TEXT_ACTIVE, mix)
        color = { color[1], color[2], color[3], alpha * (color[4] or 1) }
        draw_text(cursor_x, y + wave * amplitude, char, color, size)
        cursor_x = cursor_x + text_width(char, size)
    end
end

function M.init()
    -- tabs.init loads the autoload profile before this check.
    active = settings.bool("april_ui_startup_intro", true)
    if active then
        -- HTTPS asset: every user downloads it through Vector's image loader.
        image_cache.ensure(PROFILE_KEY, asset_urls.author_profile_png())
    end
    started_at = now()
    return active
end

function M.cancel()
    active = false
end

function M.is_active()
    return active
end

function M.should_reveal_menu()
    return active and (now() - started_at) >= MENU_REVEAL_AT
end

-- Returns true while the intro owns the frame.
function M.draw()
    if not active or not draw then return false end

    local elapsed = math.max(0, now() - started_at)
    if elapsed >= DURATION then
        active = false
        return false
    end

    theme.sync()
    anim.sync_theme()

    local width, height = screen_size()
    local black_alpha
    if elapsed < 0.22 then
        black_alpha = ease_out_cubic(elapsed / 0.22)
    elseif elapsed < MENU_REVEAL_AT then
        black_alpha = 1
    else
        black_alpha = 1 - ease_out_cubic((elapsed - MENU_REVEAL_AT) / (DURATION - MENU_REVEAL_AT))
    end

    local fill = draw.rect_filled or draw.RectFilled
    -- Vector silently rejects draw coordinates exactly at (0, 0).
    if fill then fill(-1, -1, width + 2, height + 2, { 0, 0, 0, black_alpha }, 0) end

    local title_t = ease_out_cubic((elapsed - 0.16) / 0.62)
    local author_t = ease_out_cubic((elapsed - 0.58) / 0.52)
    local profile_t = ease_out_cubic((elapsed - 0.86) / 0.72)
    -- Text exits quickly before the menu starts to reveal, avoiding a long
    -- semi-transparent linger over the next scene.
    local text_out = 1 - ease_out_cubic((elapsed - TEXT_EXIT_AT) / 0.20)
    local profile_out = 1 - ease_out_cubic((elapsed - (MENU_REVEAL_AT - 0.18)) / 0.26)
    local title_alpha = title_t * text_out * black_alpha
    local author_alpha = author_t * text_out * black_alpha
    local profile_alpha = profile_t * profile_out * black_alpha
    local center_x = width * 0.5
    local center_y = height * 0.5

    local title_x = center_x - (1 - title_t) * math.min(160, width * 0.15)
    local author_x = center_x + (1 - author_t) * math.min(125, width * 0.12)
    local title_size = math.max(40, math.floor(54 * (theme.SCALE or 1)))
    local author_size = math.max(15, math.floor(18 * (theme.SCALE or 1)))

    draw_wave("April.lua", title_x, center_y - 38, title_size, title_alpha, 0, 1.35)
    draw_wave("Made by Cunzaki", author_x, center_y + 22, author_size, author_alpha, 1.7, 0.8)

    if profile_alpha > 0.01 then
        -- The portrait peeks in from the bottom-right instead of competing
        -- with the title in the center.
        local final_w = math.max(230, math.min(420, math.floor(math.min(width, height) * 0.50)))
        local profile_w = final_w
        local profile_h = math.floor(profile_w * 399 / 375)
        local profile_x = width - profile_w * 0.76 + (1 - profile_t) * 94
        local profile_y = height - profile_h * 0.80 + (1 - profile_t) * 74
        image_cache.draw_fit(
            PROFILE_KEY,
            profile_x,
            profile_y,
            profile_w,
            profile_h,
            { 1, 1, 1, profile_alpha }
        )
    end

    local line = draw.line or draw.Line
    if line and author_alpha > 0 then
        local line_t = ease_out_cubic((elapsed - 0.82) / 0.44) * text_out
        local half = 76 * line_t
        local accent = anim.title_color()
        line(center_x - half, center_y + 46, center_x + half, center_y + 46,
            { accent[1], accent[2], accent[3], author_alpha * 0.58 }, 1)
    end

    return true
end

return M
