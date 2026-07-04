--[[ Toast notifications — draws on-screen; also tries menu.notify if available. ]]

local draw_util = April.require("core.draw_util")

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
    msg = tostring(msg)
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

function M.draw()
    if #queue == 0 or not draw then return end

    local now = tick()
    local sw, sh = draw_util.screen_size()
    local font = 14
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

            local accent = { 1, 0.75, 0.2, 1 }
            if n.type == "success" then accent = { 0.2, 0.85, 0.35, 1 }
            elseif n.type == "danger" then accent = { 1, 0.25, 0.25, 1 }
            elseif n.type == "info" then accent = { 0.25, 0.65, 1, 1 }
            end

            local tw = draw.get_text_size and draw.get_text_size(n.msg, font) or (#n.msg * 7)
            local box_w = tw + pad * 2 + 6
            local box_h = font + pad * 2
            local x = sw - box_w - 16 + (n.x_off or 0)
            local y = n.y
            local a = n.alpha or 1

            if draw.rect_filled then
                draw.rect_filled(x, y, box_w, box_h, { 0.05, 0.05, 0.08, 0.82 * a })
            end
            if draw.rect then
                draw.rect(x, y, box_w, box_h, { accent[1], accent[2], accent[3], 0.9 * a }, 0, 1)
            end
            if draw.line then
                draw.line(x, y, x, y + box_h, { accent[1], accent[2], accent[3], a }, 3)
            end
            if draw.text then
                draw.text(x + pad + 4, y + pad - 1, n.msg, { 1, 1, 1, a }, font)
            end

            target_y = target_y + box_h + gap
        end
    end
end

return M
