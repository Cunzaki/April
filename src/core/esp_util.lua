local draw_util = April.require("core.draw_util")
local settings = April.require("core.settings")

local M = {}

M.AIM_BONES = {
    "Closest",
    "Head",
    "UpperTorso",
    "LowerTorso",
    "HumanoidRootPart",
    "LeftUpperArm",
    "RightUpperArm",
    "LeftLowerArm",
    "RightLowerArm",
    "LeftHand",
    "RightHand",
    "LeftUpperLeg",
    "RightUpperLeg",
    "LeftLowerLeg",
    "RightLowerLeg",
    "LeftFoot",
    "RightFoot",
}

M.SKELETON_PAIRS = {
    { "Head", "UpperTorso" },
    { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" },
    { "UpperTorso", "RightUpperArm" },
    { "LeftUpperArm", "LeftLowerArm" },
    { "RightUpperArm", "RightLowerArm" },
    { "LeftLowerArm", "LeftHand" },
    { "RightLowerArm", "RightHand" },
    { "LowerTorso", "LeftUpperLeg" },
    { "LowerTorso", "RightUpperLeg" },
    { "LeftUpperLeg", "LeftLowerLeg" },
    { "RightUpperLeg", "RightLowerLeg" },
    { "LeftLowerLeg", "LeftFoot" },
    { "RightLowerLeg", "RightFoot" },
}

-- Must be declared before any M.* that closes over it (Lua local scoping).
-- Vector3 userdata from the new API exposes .X/.Y/.Z (PascalCase).
local function vec3_pos(v)
    if not v then return nil end
    if type(v) == "number" then return nil end
    local x, y, z
    local ok = pcall(function()
        x = tonumber(v.x or v.X or v[1])
        y = tonumber(v.y or v.Y or v[2])
        z = tonumber(v.z or v.Z or v[3])
    end)
    if not ok or not x or not y or not z then return nil end
    return x, y, z
end
M.vec3_pos = vec3_pos

function M.text_size()
    return settings.num("april_esp_text_size", 13)
end

local function normalize_w2s(a, b, c)
    -- Multi-return: sx, sy, visible
    if type(a) == "number" and type(b) == "number" then
        local vis = c
        if vis == nil then vis = true end
        if vis == 0 or vis == false then return a, b, false end
        return a, b, vis and true or false
    end
    -- Table return: {x,y,visible} / {X,Y,Visible} / {sx,sy,on_screen}
    if type(a) == "table" then
        local sx = tonumber(a.x or a.X or a.sx or a[1])
        local sy = tonumber(a.y or a.Y or a.sy or a[2])
        local vis = a.visible
        if vis == nil then vis = a.Visible end
        if vis == nil then vis = a.on_screen end
        if vis == nil then vis = a[3] end
        if vis == nil then vis = true end
        if not sx or not sy then return 0, 0, false end
        if vis == 0 or vis == false then return sx, sy, false end
        return sx, sy, true
    end
    return 0, 0, false
end

local function call_w2s(fn, x, y, z)
    if not fn then return 0, 0, false end
    -- New API: utility.WorldToScreen(vec3) or (x,y,z)
    local ok, a, b, c = pcall(fn, x, y, z)
    if ok then return normalize_w2s(a, b, c) end
    return 0, 0, false
end

function M.w2s(x, y, z)
    -- Allow passing a Vector3 / vector-like value as the first arg.
    if y == nil and x ~= nil then
        local vx, vy, vz = vec3_pos(x)
        if vx then
            x, y, z = vx, vy, vz
        end
    end
    x = tonumber(x)
    y = tonumber(y)
    z = tonumber(z)
    if not x or not y or not z then
        return 0, 0, false
    end

    local draw_fn = draw and (draw.world_to_screen or draw.WorldToScreen or draw.worldToScreen)
    local sx, sy, vis = call_w2s(draw_fn, x, y, z)
    if vis then return sx, sy, true end

    local util_fn = utility and (utility.world_to_screen or utility.WorldToScreen or utility.worldToScreen)
    sx, sy, vis = call_w2s(util_fn, x, y, z)
    if vis then return sx, sy, true end

    return sx or 0, sy or 0, false
end

-- Strict on-screen check. Behind-camera W2S often returns "visible" with coords
-- glued to screen edges — reject those so ESP cannot stick to borders.
function M.screen_point_ok(sx, sy, margin)
    sx, sy = tonumber(sx), tonumber(sy)
    if not sx or not sy then return false end
    local sw, sh = draw_util.screen_size()
    if not sw or sw < 1 or not sh or sh < 1 then return true end
    margin = margin or 64
    return sx >= -margin and sy >= -margin and sx <= (sw + margin) and sy <= (sh + margin)
end

function M.w2s_visible(x, y, z, margin)
    local sx, sy, vis = M.w2s(x, y, z)
    if not vis then return sx, sy, false end
    if not M.screen_point_ok(sx, sy, margin) then
        return sx, sy, false
    end
    return sx, sy, true
end

function M.draw_skeleton_bones(bones, col, thick)
    if not bones then return end
    thick = thick or 1.5

    local function pt(entry)
        if not entry then return end
        if entry.x and entry.y then return entry.x, entry.y end
        if entry[1] and entry[2] then return entry[1], entry[2] end
    end

    for i = 1, #M.SKELETON_PAIRS do
        local pair = M.SKELETON_PAIRS[i]
        local ax, ay = pt(bones[pair[1]])
        local bx, by = pt(bones[pair[2]])
        if ax and bx then
            draw_util.line(ax, ay, bx, by, col, thick)
        end
    end
end

-- Perspective-correct box from a head world point + body height in studs.
-- This is the cheap OG-style path: two W2S calls, natural distance scaling.
function M.head_body_screen_bounds(hx, hy, hz, opts)
    opts = opts or {}
    hx, hy, hz = tonumber(hx), tonumber(hy), tonumber(hz)
    if not hx then return nil end

    local body_h = opts.body_h or 5.0
    local top_pad = opts.top_pad or 0.35
    local bot_pad = opts.bot_pad or 0.15
    local width_mul = opts.width_mul or 0.55

    local sx, sy, vis = M.w2s_visible(hx, hy + top_pad, hz)
    if not vis then return nil end

    local fx, fy, fz = hx, hy - body_h - bot_pad, hz
    if opts.fx then
        fx, fy, fz = opts.fx, opts.fy, opts.fz
    end
    local bx, by, bvis = M.w2s(fx, fy, fz)
    -- Feet may leave the screen while the head is still visible — still draw.
    if (not bvis) or (not M.screen_point_ok(bx, by, 200)) then
        local dist = tonumber(opts.dist) or 80
        local approx = math.max(2, math.min(120, 520 / (dist + 8)))
        local w = approx * width_mul
        return {
            x = sx - w * 0.5,
            y = sy,
            w = w,
            h = approx,
            valid = true,
        }
    end

    local top = math.min(sy, by)
    local bot = math.max(sy, by)
    local h = math.max(2, bot - top)
    local w = math.max(2, h * width_mul)
    local cx = (sx + bx) * 0.5
    return {
        x = cx - w * 0.5,
        y = top,
        w = w,
        h = h,
        valid = true,
    }
end

function M.bounds_usable(b)
    -- Far targets are often only a few pixels; do not reject tiny valid boxes.
    return b and b.valid and (b.w or 0) >= 1 and (b.h or 0) >= 1
end

function M.draw_vertical_beacon(wx, wy, wz, col, opts)
    opts = opts or {}
    local height = opts.height or 90
    local steps = opts.steps or 10
    local prev_sx, prev_sy, prev_vis

    for i = 0, steps do
        local py = wy + (height * i / steps)
        local sx, sy, vis = M.w2s(wx, py, wz)
        if i > 0 and vis and prev_vis and draw and draw.line then
            local alpha = (col[4] or 1) * (0.35 + 0.65 * (i / steps))
            draw.line(prev_sx, prev_sy, sx, sy, { col[1], col[2], col[3], alpha }, opts.thickness or 2)
        end
        prev_sx, prev_sy, prev_vis = sx, sy, vis
    end

    if prev_vis and draw and draw.circle_filled then
        draw.circle_filled(prev_sx, prev_sy, opts.marker_r or 4, col, 12)
    end
end

function M.draw_beacon(sx, sy, col, opts)
    opts = opts or {}
    local sw, sh = draw_util.screen_size()
    local origin_x = opts.origin_x or sw * 0.5
    local origin_y = opts.origin_y or sh
    local steps = opts.steps or 5

    for i = 1, steps do
        local t = i / steps
        local alpha = (col[4] or 1) * (0.08 + t * 0.22)
        local c = { col[1], col[2], col[3], alpha }
        local ox = origin_x + (sx - origin_x) * t
        local oy = origin_y + (sy - origin_y) * t
        draw_util.line(ox, oy, sx, sy, c, 1 + t)
    end

    if draw and draw.circle_filled then
        draw.circle_filled(sx, sy, opts.marker_r or 5, col, 16)
        draw.circle(sx, sy, opts.marker_r or 5 + 2, { col[1], col[2], col[3], 0.35 }, 16, 1)
    else
        draw_util.circle(sx, sy, opts.marker_r or 5, col, true)
    end
end

function M.draw_offscreen_arrow(cx, cy, tx, ty, col, size, style)
    size = size or 14
    style = style or 0 -- 0 triangle, 1 chevron, 2 diamond
    local dx, dy = tx - cx, ty - cy
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1 then return end
    dx, dy = dx / len, dy / len
    local px, py = cx + dx * (size + 8), cy + dy * (size + 8)
    local lx, ly = -dy, dx

    if style == 1 then
        -- Chevron / open arrow
        local thick = math.max(1.5, size * 0.18)
        draw_util.line(px - dx * size + lx * size * 0.55, py - dy * size + ly * size * 0.55,
            px + dx * size * 0.15, py + dy * size * 0.15, col, thick)
        draw_util.line(px - dx * size - lx * size * 0.55, py - dy * size - ly * size * 0.55,
            px + dx * size * 0.15, py + dy * size * 0.15, col, thick)
        return
    end

    if style == 2 then
        local tip = { px + dx * size, py + dy * size }
        local back = { px - dx * size * 0.55, py - dy * size * 0.55 }
        local left = { px + lx * size * 0.45, py + ly * size * 0.45 }
        local right = { px - lx * size * 0.45, py - ly * size * 0.45 }
        if draw and draw.poly_filled then
            draw.poly_filled({ tip, left, back, right }, col)
        else
            draw_util.line(tip[1], tip[2], left[1], left[2], col, 2)
            draw_util.line(left[1], left[2], back[1], back[2], col, 2)
            draw_util.line(back[1], back[2], right[1], right[2], col, 2)
            draw_util.line(right[1], right[2], tip[1], tip[2], col, 2)
        end
        return
    end

    if draw and draw.poly_filled then
        draw.poly_filled({
            { px + dx * size, py + dy * size },
            { px - dx * 4 + lx * size * 0.55, py - dy * 4 + ly * size * 0.55 },
            { px - dx * 4 - lx * size * 0.55, py - dy * 4 - ly * size * 0.55 },
        }, col)
    else
        draw_util.line(px, py, px - dx * 8 + lx * 6, py - dy * 8 + ly * 6, col, 2)
        draw_util.line(px, py, px - dx * 8 - lx * 6, py - dy * 8 - ly * 6, col, 2)
    end
end

-- Clamp a world point to the screen edge and draw an arrow pointing at it.
-- opts: size, margin, style, label, label_col, outline
-- Returns true if an arrow was drawn (target off-screen / outside margin).
function M.draw_offscreen_to(wx, wy, wz, col, size, margin, opts)
    opts = opts or {}
    if type(size) == "table" then
        opts = size
        size = opts.size
        margin = opts.margin
    end

    local sw, sh = draw_util.screen_size()
    if not sw or sw < 1 or not sh or sh < 1 then return false end

    local cx, cy = sw * 0.5, sh * 0.5
    margin = margin or opts.margin or 36
    size = size or opts.size or 14
    local style = opts.style or 0

    local sx, sy, on = M.w2s(wx, wy, wz)
    sx = tonumber(sx) or cx
    sy = tonumber(sy) or cy

    if on and sx >= margin and sy >= margin and sx <= (sw - margin) and sy <= (sh - margin) then
        return false
    end

    local dx, dy = sx - cx, sy - cy
    if (dx * dx + dy * dy) < 1 then
        if camera and camera.get_look_vector then
            local look = camera.get_look_vector()
            if look then
                dx = look.x or look.X or 0
                dy = -(look.y or look.Y or 0)
            end
        end
        if (dx * dx + dy * dy) < 0.0001 then
            dx, dy = 0, -1
        end
    end

    local len = math.sqrt(dx * dx + dy * dy)
    dx, dy = dx / len, dy / len

    local hw = (sw * 0.5) - margin
    local hh = (sh * 0.5) - margin
    local scale_x = (math.abs(dx) > 1e-6) and (hw / math.abs(dx)) or 1e9
    local scale_y = (math.abs(dy) > 1e-6) and (hh / math.abs(dy)) or 1e9
    local scale = math.min(scale_x, scale_y)
    local ex = cx + dx * scale
    local ey = cy + dy * scale

    if opts.outline then
        local oc = { 0, 0, 0, (col[4] or 1) * 0.85 }
        M.draw_offscreen_arrow(cx, cy, ex, ey, oc, size + 2, style)
    end
    M.draw_offscreen_arrow(cx, cy, ex, ey, col, size, style)

    if opts.label then
        local lx = ex - dx * (size + 10)
        local ly = ey - dy * (size + 10)
        draw_util.text_centered(lx, ly - 6, tostring(opts.label), opts.label_col or col, opts.label_size or 11)
    end
    return true
end

local BOX_EDGES = {
    { 1, 2 }, { 1, 3 }, { 2, 4 }, { 3, 4 },
    { 5, 6 }, { 5, 7 }, { 6, 8 }, { 7, 8 },
    { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 },
}

local BOX_SIGNS = {
    { -1, -1, -1 }, { 1, -1, -1 }, { -1, 1, -1 }, { 1, 1, -1 },
    { -1, -1, 1 }, { 1, -1, 1 }, { -1, 1, 1 }, { 1, 1, 1 },
}

function M.draw_world_line(x1, y1, z1, x2, y2, z2, col, thick)
    if not draw then return false end
    local sx1, sy1, v1 = M.w2s(x1, y1, z1)
    local sx2, sy2, v2 = M.w2s(x2, y2, z2)
    if v1 or v2 then
        draw_util.line(sx1, sy1, sx2, sy2, col, thick or 2)
        return true
    end
    return false
end

function M.draw_world_cross(wx, wy, wz, size, col, thick)
    if not camera or not camera.get_look_vector then return end

    local look = camera.get_look_vector()
    if not look then return end

    local lx = look.x or look.X or 0
    local ly = look.y or look.Y or 0
    local lz = look.z or look.Z or 0
    local mag = math.sqrt(lx * lx + ly * ly + lz * lz)
    if mag < 0.001 then return end
    lx, ly, lz = lx / mag, ly / mag, lz / mag

    local ux, uy, uz = 0, 1, 0
    local rx = uy * lz - uz * ly
    local ry = uz * lx - ux * lz
    local rz = ux * ly - uy * lx
    local rm = math.sqrt(rx * rx + ry * ry + rz * rz)
    if rm < 0.001 then
        ux, uy, uz = 0, 0, 1
        rx = uy * lz - uz * ly
        ry = uz * lx - ux * lz
        rz = ux * ly - uy * lx
        rm = math.sqrt(rx * rx + ry * ry + rz * rz)
    end
    if rm < 0.001 then return end
    rx, ry, rz = rx / rm, ry / rm, rz / rm

    ux = ly * rz - lz * ry
    uy = lz * rx - lx * rz
    uz = lx * ry - ly * rx
    local um = math.sqrt(ux * ux + uy * uy + uz * uz)
    if um < 0.001 then return end
    ux, uy, uz = ux / um, uy / um, uz / um

    size = size or 0.35
    thick = thick or 2
    local s = size * 0.5

    M.draw_world_line(
        wx - rx * s - ux * s, wy - ry * s - uy * s, wz - rz * s - uz * s,
        wx + rx * s + ux * s, wy + ry * s + uy * s, wz + rz * s + uz * s,
        col, thick
    )
    M.draw_world_line(
        wx - rx * s + ux * s, wy - ry * s + uy * s, wz - rz * s + uz * s,
        wx + rx * s - ux * s, wy + ry * s - uy * s, wz + rz * s - uz * s,
        col, thick
    )
end

function M.draw_oriented_box(box, col, thick)
    if not box or not draw or not draw.line then return end
    thick = thick or 1

    local corners = {}
    for i = 1, 8 do
        local sx, sy, sz = BOX_SIGNS[i][1], BOX_SIGNS[i][2], BOX_SIGNS[i][3]
        local lx, ly, lz = sx * box.hx, sy * box.hy, sz * box.hz
        local wx = box.x + box.rx * lx + box.ux * ly - box.lx * lz
        local wy = box.y + box.ry * lx + box.uy * ly - box.ly * lz
        local wz = box.z + box.rz * lx + box.uz * ly - box.lz * lz
        corners[i] = { wx, wy, wz }
    end

    local screen = {}
    for i = 1, 8 do
        local c = corners[i]
        local sx, sy, vis = M.w2s(c[1], c[2], c[3])
        if vis then screen[i] = { x = sx, y = sy } end
    end

    for _, edge in ipairs(BOX_EDGES) do
        local a, b = screen[edge[1]], screen[edge[2]]
        if a and b then
            draw_util.line(a.x, a.y, b.x, b.y, col, thick)
        end
    end
end

function M.draw_entry_boxes(entry, col, thick)
    if not entry or not entry.inst then return end
    local env = April.require("core.env")
    if not env.is_valid(entry.inst) then return end

    if entry.box then
        M.draw_oriented_box(entry.box, col, thick)
        return
    end
    local scan = April.require("game.esp_scan")
    local main = entry.main_part or scan.find_main_part(entry.inst)
    if main then entry.main_part = main end
    local box = main and scan.read_part_box(main)
    if box then
        entry.box = box
        M.draw_oriented_box(box, col, thick)
    end
end

return M
