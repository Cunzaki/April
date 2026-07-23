local draw_util = April.require("core.draw_util")
local theme = April.require("core.ui_theme")
local overlay_theme = April.require("core.overlay_theme")
local text_util = April.require("core.text_util")

local M = {}
local queue = {}

local function tick()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

function M.show(msg, ntype, duration_ms)
    M.toast(msg, ntype, duration_ms, false)
end

function M.toast(msg, ntype, duration_ms, skip_dedupe)
    if not msg or msg == "" then return end
    msg = text_util.sanitize(msg)
    ntype = ntype or "warning"
    duration_ms = duration_ms or 5000

    if not skip_dedupe then
        for _, n in ipairs(queue) do
            if n.msg == msg and (tick() - n.time) < 3000 then return end
        end
    end

    if menu and menu.notify then
        pcall(function() menu.notify(msg) end)
    end

    table.insert(queue, {
        msg = msg,
        type = ntype,
        time = tick(),
        duration = duration_ms,
        alpha = 0,
        x_off = 80,
        y = 0,
    })

    while #queue > 6 do
        table.remove(queue, 1)
    end
end

function M.warning(msg, duration_ms)
    M.show(msg, "warning", duration_ms)
end

function M.success(msg, duration_ms)
    M.show(msg, "success", duration_ms)
end

function M.error(msg, duration_ms)
    M.show(msg, "danger", duration_ms)
end

function M.info(msg, duration_ms)
    M.show(msg, "info", duration_ms)
end

function M.draw()
    if #queue == 0 or not draw then return end

    overlay_theme.sync()
    local now = tick()
    local font = 13
    local pad = 12
    local gap = 8
    local target_y = 18

    for i = #queue, 1, -1 do
        local n = queue[i]
        local elapsed = now - n.time
        if elapsed > n.duration then
            table.remove(queue, i)
        else
            local fade = 350
            local target_alpha = 1
            if elapsed < fade then
                target_alpha = elapsed / fade
            elseif elapsed > n.duration - fade then
                target_alpha = (n.duration - elapsed) / fade
            end
            n.alpha = lerp(n.alpha or 0, target_alpha, 0.18)

            local slide = 0
            if elapsed > n.duration - fade then slide = 60 end
            n.x_off = lerp(n.x_off or 80, slide, 0.15)

            if n.y == 0 then n.y = target_y end
            n.y = lerp(n.y, target_y, 0.2)

            local accent = theme.toast_accent(n.type)
            local tw = select(1, theme.text_w(n.msg, font))
            local box_w = tw + pad * 2 + 4
            local box_h = font + pad * 2
            local sw = select(1, draw_util.screen_size())
            local x = sw - box_w - 16 + (n.x_off or 0)
            local y = n.y
            local a = n.alpha or 1

            theme.draw_panel(x, y, box_w, box_h, {
                bg = theme.alpha(overlay_theme.panel_bg(), 0.94 * a),
                border = theme.alpha(overlay_theme.border(), 0.58 * a),
                accent = theme.alpha(accent, a),
                accent_w = 2,
                rounding = 0,
            })
            overlay_theme.draw_accent_bar(x + 2, y, box_w - 3, 2, a)

            if draw.text then
                draw.text(x + pad, y + pad - 1, n.msg, theme.alpha(theme.TEXT, a), font)
            end

            target_y = target_y + box_h + gap
        end
    end
end

return M
