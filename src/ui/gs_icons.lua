-- Vector-drawn sidebar icons (sharper Gamesense-style glyphs).
local theme = April.require("ui.gs_theme")

local M = {}

local function line(x1, y1, x2, y2, col, t)
    if draw and draw.line then
        draw.line(x1, y1, x2, y2, col, t or 1.6)
    end
end

local function circle(x, y, r, col, filled, segs)
    if not draw then return end
    segs = segs or 20
    if filled and draw.circle_filled then
        draw.circle_filled(x, y, r, col, segs)
    elseif draw.circle then
        draw.circle(x, y, r, col, segs, 1.6)
    end
end

local function rect(x, y, w, h, col, filled)
    if not draw then return end
    if filled then
        draw.rect_filled(x, y, w, h, col, 0)
    else
        draw.rect(x, y, w, h, col, 0, 1.5)
    end
end

local function poly(points, col, t)
    if draw and draw.poly then
        draw.poly(points, col, t or 1.5)
    else
        for i = 1, #points - 1 do
            line(points[i][1], points[i][2], points[i + 1][1], points[i + 1][2], col, t)
        end
    end
end

local function ellipse_arc(cx, cy, rx, ry, a0, a1, col, steps)
    steps = steps or 10
    local pts = {}
    for i = 0, steps do
        local t = a0 + (a1 - a0) * (i / steps)
        pts[#pts + 1] = { cx + math.cos(t) * rx, cy + math.sin(t) * ry }
    end
    poly(pts, col, 1.5)
end

function M.draw(name, cx, cy, col)
    col = col or theme.TEXT

    if name == "aim" then
        -- Crosshair with outer brackets
        circle(cx, cy, 5.5, col, false, 22)
        circle(cx, cy, 1.4, col, true, 10)
        line(cx - 9, cy, cx - 4, cy, col, 1.7)
        line(cx + 4, cy, cx + 9, cy, col, 1.7)
        line(cx, cy - 9, cx, cy - 4, col, 1.7)
        line(cx, cy + 4, cx, cy + 9, col, 1.7)
        -- corner ticks
        line(cx - 8, cy - 8, cx - 5, cy - 8, col, 1.3)
        line(cx - 8, cy - 8, cx - 8, cy - 5, col, 1.3)
        line(cx + 8, cy - 8, cx + 5, cy - 8, col, 1.3)
        line(cx + 8, cy - 8, cx + 8, cy - 5, col, 1.3)
        line(cx - 8, cy + 8, cx - 5, cy + 8, col, 1.3)
        line(cx - 8, cy + 8, cx - 8, cy + 5, col, 1.3)
        line(cx + 8, cy + 8, cx + 5, cy + 8, col, 1.3)
        line(cx + 8, cy + 8, cx + 8, cy + 5, col, 1.3)

    elseif name == "visuals" then
        -- Eye
        ellipse_arc(cx, cy, 8, 4.5, math.pi, math.pi * 2, col, 12)
        ellipse_arc(cx, cy, 8, 4.5, 0, math.pi, col, 12)
        circle(cx, cy, 2.8, col, false, 14)
        circle(cx + 0.6, cy - 0.4, 1.1, col, true, 8)

    elseif name == "world" then
        -- Globe with meridians
        circle(cx, cy, 7, col, false, 24)
        -- latitude
        ellipse_arc(cx, cy, 7, 2.8, 0, math.pi * 2, col, 16)
        -- longitude
        ellipse_arc(cx, cy, 2.8, 7, 0, math.pi * 2, col, 16)
        line(cx, cy - 7, cx, cy + 7, col, 1.2)

    elseif name == "guns" then
        -- Side-view rifle silhouette
        -- barrel
        rect(cx - 2, cy - 2.5, 10, 2.2, col, true)
        -- receiver
        rect(cx - 7, cy - 3.2, 7, 4.2, col, true)
        -- stock
        poly({
            { cx - 7, cy - 2.5 },
            { cx - 11, cy - 3.5 },
            { cx - 11, cy + 2.5 },
            { cx - 7, cy + 1.2 },
        }, col, 1.6)
        line(cx - 7, cy - 2.5, cx - 11, cy - 3.5, col, 1.6)
        line(cx - 11, cy - 3.5, cx - 11, cy + 2.5, col, 1.6)
        line(cx - 11, cy + 2.5, cx - 7, cy + 1.2, col, 1.6)
        -- mag
        rect(cx - 4.5, cy + 1, 2.4, 4, col, true)
        -- front sight
        line(cx + 6, cy - 2.5, cx + 6, cy - 5, col, 1.4)

    elseif name == "misc" then
        -- Three control sliders
        for i = 0, 2 do
            local yy = cy - 6 + i * 6
            line(cx - 7, yy, cx + 7, yy, col, 1.4)
            local knob = ({ -3, 3, 0 })[i + 1]
            circle(cx + knob, yy, 2.2, col, true, 10)
            circle(cx + knob, yy, 2.2, col, false, 10)
        end

    elseif name == "radar" then
        -- Radar dish + sweep
        circle(cx, cy, 7.5, col, false, 24)
        circle(cx, cy, 4.5, col, false, 18)
        circle(cx, cy, 1.5, col, true, 10)
        line(cx, cy, cx + 6.5, cy - 3.5, col, 1.8)
        -- blip
        circle(cx + 3.5, cy + 2.5, 1.3, col, true, 8)
        -- north tick
        line(cx, cy - 7.5, cx, cy - 9.5, col, 1.5)

    elseif name == "config" then
        -- Gear
        local teeth = 8
        for i = 0, teeth - 1 do
            local a = (i / teeth) * math.pi * 2
            local c, s = math.cos(a), math.sin(a)
            local x1, y1 = cx + c * 3.2, cy + s * 3.2
            local x2, y2 = cx + c * 7.2, cy + s * 7.2
            local px, py = -s * 1.5, c * 1.5
            poly({
                { x1 + px, y1 + py },
                { x2 + px * 0.7, y2 + py * 0.7 },
                { x2 - px * 0.7, y2 - py * 0.7 },
                { x1 - px, y1 - py },
                { x1 + px, y1 + py },
            }, col, 1.35)
        end
        circle(cx, cy, 3.8, col, false, 16)
        circle(cx, cy, 1.8, col, true, 10)

    else
        circle(cx, cy, 4, col, false)
    end
end

return M
