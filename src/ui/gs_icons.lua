-- Coherent procedural line icons for the primary navigation and HUD dock.
-- All glyphs share a compact 20px design grid and require no image assets.
local theme = April.require("ui.gs_theme")

local M = {}

local function line(x1, y1, x2, y2, col, t)
    if draw and draw.line then
        draw.line(x1, y1, x2, y2, col, t or 1.5)
    end
end

local function circle(x, y, r, col, filled, segs)
    if not draw then return end
    segs = segs or 24
    if filled and draw.circle_filled then
        draw.circle_filled(x, y, r, col, segs)
    elseif draw.circle then
        draw.circle(x, y, r, col, segs, 1.5)
    end
end

local function rect(x, y, w, h, col, filled, rounding)
    if not draw then return end
    if filled then
        draw.rect_filled(x, y, w, h, col, rounding or 0)
    else
        draw.rect(x, y, w, h, col, rounding or 0, 1.5)
    end
end

local function path(points, col, closed, t)
    if not draw then return end
    if closed and draw.poly_closed then
        draw.poly_closed(points, col, t or 1.5)
        return
    elseif draw.poly then
        draw.poly(points, col, t or 1.5)
    else
        for i = 1, #points - 1 do
            line(points[i][1], points[i][2], points[i + 1][1], points[i + 1][2], col, t)
        end
    end
    if closed and #points > 2 then
        line(points[#points][1], points[#points][2], points[1][1], points[1][2], col, t)
    end
end

local function ellipse_arc(cx, cy, rx, ry, a0, a1, col, steps)
    steps = steps or 12
    local pts = {}
    for i = 0, steps do
        local t = a0 + (a1 - a0) * (i / steps)
        pts[#pts + 1] = { cx + math.cos(t) * rx, cy + math.sin(t) * ry }
    end
    path(pts, col, false, 1.5)
end

function M.draw(name, cx, cy, col)
    col = col or theme.TEXT

    if name == "aim" then
        circle(cx, cy, 5.5, col, false)
        circle(cx, cy, 1.3, col, true, 10)
        line(cx - 9, cy, cx - 5.5, cy, col)
        line(cx + 5.5, cy, cx + 9, cy, col)
        line(cx, cy - 9, cx, cy - 5.5, col)
        line(cx, cy + 5.5, cx, cy + 9, col)

    elseif name == "visuals" then
        ellipse_arc(cx, cy, 8.5, 4.8, math.pi, math.pi * 2, col)
        ellipse_arc(cx, cy, 8.5, 4.8, 0, math.pi, col)
        circle(cx, cy, 2.5, col, false, 18)
        circle(cx, cy, 1.0, col, true, 10)

    elseif name == "world" then
        circle(cx, cy, 7.5, col, false)
        ellipse_arc(cx, cy, 7.3, 2.7, 0, math.pi * 2, col, 16)
        ellipse_arc(cx, cy, 3.2, 7.3, 0, math.pi * 2, col, 16)

    elseif name == "guns" then
        -- Single cartridge stays crisp on the navbar's small design grid.
        path({
            { cx - 8, cy - 3 }, { cx + 3, cy - 3 },
            { cx + 8, cy }, { cx + 3, cy + 3 },
            { cx - 8, cy + 3 },
        }, col, true, 1.5)
        line(cx - 5, cy - 3, cx - 5, cy + 3, col, 1.3)
        line(cx - 8, cy - 1.5, cx - 8, cy + 1.5, col, 1.5)

    elseif name == "misc" then
        line(cx - 8, cy - 5, cx + 8, cy - 5, col)
        line(cx - 8, cy, cx + 8, cy, col)
        line(cx - 8, cy + 5, cx + 8, cy + 5, col)
        circle(cx - 3, cy - 5, 2, col, false, 14)
        circle(cx + 4, cy, 2, col, false, 14)
        circle(cx - 1, cy + 5, 2, col, false, 14)

    elseif name == "radar" then
        circle(cx, cy, 7.5, col, false)
        ellipse_arc(cx, cy, 4.5, 4.5, -math.pi * 0.45, math.pi * 0.22, col, 8)
        line(cx, cy, cx + 6.2, cy - 4.2, col)
        circle(cx + 3.7, cy + 2.6, 1.1, col, true, 8)
        circle(cx, cy, 1.1, col, true, 8)

    elseif name == "config" then
        circle(cx, cy, 5.7, col, false)
        circle(cx, cy, 2.2, col, false, 16)
        for i = 0, 7 do
            local a = i * math.pi * 0.25
            line(
                cx + math.cos(a) * 6.1, cy + math.sin(a) * 6.1,
                cx + math.cos(a) * 8.2, cy + math.sin(a) * 8.2,
                col, 1.8
            )
        end

    elseif name == "keybinds" then
        rect(cx - 8, cy - 6, 16, 12, col, false, 2)
        for row = 0, 1 do
            for column = 0, 3 do
                circle(cx - 5.5 + column * 3.6, cy - 3 + row * 3.4, 0.65, col, true, 6)
            end
        end
        line(cx - 4, cy + 4, cx + 4, cy + 4, col, 1.2)

    elseif name == "staff" then
        circle(cx, cy - 4.5, 3, col, false, 18)
        ellipse_arc(cx, cy + 6, 6.5, 5.5, math.pi, math.pi * 2, col, 12)
        line(cx - 6.5, cy + 6, cx - 6.5, cy + 3.5, col)
        line(cx + 6.5, cy + 6, cx + 6.5, cy + 3.5, col)
        line(cx + 5.2, cy - 6.8, cx + 7.8, cy - 4.2, col, 1.3)
        line(cx + 7.8, cy - 4.2, cx + 5.2, cy - 1.6, col, 1.3)

    elseif name == "events" then
        circle(cx, cy, 7.5, col, false, 22)
        line(cx, cy, cx, cy - 4.5, col, 1.5)
        line(cx, cy, cx + 4, cy + 2.5, col, 1.5)
        circle(cx, cy, 1.1, col, true, 8)

    elseif name == "map" then
        path({
            { cx - 8, cy - 6 }, { cx - 3, cy - 8 }, { cx + 3, cy - 6 },
            { cx + 8, cy - 8 }, { cx + 8, cy + 6 }, { cx + 3, cy + 8 },
            { cx - 3, cy + 6 }, { cx - 8, cy + 8 },
        }, col, true)
        line(cx - 3, cy - 8, cx - 3, cy + 6, col, 1.2)
        line(cx + 3, cy - 6, cx + 3, cy + 8, col, 1.2)

    elseif name == "settings" then
        line(cx - 8, cy - 5, cx + 8, cy - 5, col)
        line(cx - 8, cy, cx + 8, cy, col)
        line(cx - 8, cy + 5, cx + 8, cy + 5, col)
        circle(cx + 3, cy - 5, 2, col, false, 14)
        circle(cx - 3, cy, 2, col, false, 14)
        circle(cx + 1, cy + 5, 2, col, false, 14)

    else
        circle(cx, cy, 4, col, false)
    end
end

return M
