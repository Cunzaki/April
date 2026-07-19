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

function M.text_size()
    return settings.num("april_esp_text_size", 13)
end

function M.w2s(x, y, z)
    if draw and draw.world_to_screen then
        return draw.world_to_screen(x, y, z)
    end
    if utility and utility.world_to_screen then
        return utility.world_to_screen(x, y, z)
    end
    return 0, 0, false
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

function M.draw_player_skeleton(player, col, thick)
    if not player or not player.get_bones_screen then return end
    local bones = player:get_bones_screen()
    if not bones then return end
    M.draw_skeleton_bones(bones, col, thick)
end

function M.model_screen_bounds(model)
    if not model then return nil end
    local env = April.require("core.env")
    if not env.is_valid(model) then return nil end

    local part_names = {
        "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso",
        "LeftFoot", "RightFoot", "LeftHand", "RightHand",
        "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg",
    }

    local min_x, min_y, max_x, max_y
    local any = false

    for i = 1, #part_names do
        local name = part_names[i]
        local part = env.safe_call(function()
            return model:find_first_child(name) or model:FindFirstChild(name)
        end)
        if part and env.is_valid(part) then
            local pos = part.Position or part.position
            if pos and pos.x then
                local sx, sy, vis = M.w2s(pos.x, pos.y, pos.z)
                if vis then
                    any = true
                    min_x = min_x and math.min(min_x, sx) or sx
                    min_y = min_y and math.min(min_y, sy) or sy
                    max_x = max_x and math.max(max_x, sx) or sx
                    max_y = max_y and math.max(max_y, sy) or sy
                end
            end
        end
    end

    if not any then return nil end

    local w = math.max(8, max_x - min_x)
    local h = math.max(12, max_y - min_y)
    -- Pad so boxes don't hug the mesh too tightly.
    local pad_x = math.max(2, w * 0.12)
    local pad_y = math.max(2, h * 0.06)
    return {
        x = min_x - pad_x,
        y = min_y - pad_y,
        w = w + pad_x * 2,
        h = h + pad_y * 2,
        valid = true,
    }
end

-- Build screen AABB from entity bone projections (best far-range box).
function M.bones_screen_bounds(player)
    if not player or not player.get_bones_screen then return nil end
    local bones = player:get_bones_screen()
    if not bones then return nil end

    local min_x, min_y, max_x, max_y
    local any = false
    for _, pt in pairs(bones) do
        if pt then
            local x = pt.x or pt[1]
            local y = pt.y or pt[2]
            if x and y then
                any = true
                min_x = min_x and math.min(min_x, x) or x
                min_y = min_y and math.min(min_y, y) or y
                max_x = max_x and math.max(max_x, x) or x
                max_y = max_y and math.max(max_y, y) or y
            end
        end
    end
    if not any then return nil end

    local w = math.max(4, max_x - min_x)
    local h = math.max(6, max_y - min_y)
    local pad_x = math.max(2, w * 0.14)
    local pad_y = math.max(2, h * 0.06)
    return {
        x = min_x - pad_x,
        y = min_y - pad_y,
        w = w + pad_x * 2,
        h = h + pad_y * 2,
        valid = true,
    }
end

-- Keep far targets readable: only expand collapsed specks, never inflate real bounds.
function M.ensure_min_bounds(b, min_w, min_h)
    if not b or not b.valid then return b end
    min_w = min_w or 22
    min_h = min_h or 40
    local cx = b.x + b.w * 0.5
    local cy = b.y + b.h * 0.5
    if b.w < min_w then
        b.w = min_w
        b.x = cx - min_w * 0.5
    end
    if b.h < min_h then
        b.h = min_h
        b.y = cy - min_h * 0.5
    end
    return b
end

function M.dist_min_bounds(dist)
    dist = math.max(1, tonumber(dist) or 80)
    local h = math.max(6, math.min(38, 2200 / (dist + 35)))
    local w = math.max(4, math.min(22, h * 0.55))
    return w, h
end

function M.dist_point_size(dist)
    dist = math.max(1, tonumber(dist) or 80)
    return math.max(6, math.min(34, 2000 / (dist + 30)))
end

function M.guard_tiny_bounds(b, dist)
    if not b or not b.valid then return b end
    if b.w >= 6 and b.h >= 8 then return b end
    local min_w, min_h = M.dist_min_bounds(dist)
    return M.ensure_min_bounds(b, min_w, min_h)
end

local function vec3_pos(v)
    if not v then return nil end
    if v.x ~= nil then return v.x, v.y, v.z end
    return v[1], v[2], v[3]
end

-- Head + feet projection when bone AABB APIs fail for a frame.
function M.head_feet_screen_bounds(player, opts)
    if not player then return nil end
    opts = opts or {}
    local env = April.require("core.env")

    local hx, hy, hz = vec3_pos(player.head_position)
    if not hx then
        local char = player.character
        if char and env.is_valid(char) then
            local head = env.safe_call(function()
                return char:find_first_child("Head") or char:FindFirstChild("Head")
            end)
            if head and env.is_valid(head) then
                hx, hy, hz = vec3_pos(head.Position or head.position)
            end
        end
    end
    if not hx then return nil end

    local sx, sy, vis = M.w2s(hx, hy, hz)
    if not vis then return nil end

    local fx, fy, fz
    local char = player.character
    if char and env.is_valid(char) then
        for _, name in ipairs({ "LeftFoot", "RightFoot", "LeftLowerLeg", "RightLowerLeg" }) do
            local foot = env.safe_call(function()
                return char:find_first_child(name) or char:FindFirstChild(name)
            end)
            if foot and env.is_valid(foot) then
                fx, fy, fz = vec3_pos(foot.Position or foot.position)
                if fx then break end
            end
        end
    end
    if not fx then
        fx, fy, fz = vec3_pos(player.position)
        if fx then fy = fy - 2.8 end
    end
    if not fx then
        fx, fy, fz = hx, hy - 3, hz
    end

    local bx, by, bvis = M.w2s(fx, fy, fz)
    if not bvis then
        local size = opts.point_size or M.dist_point_size(opts.dist)
        return M.point_screen_bounds(hx, hy, hz, size)
    end

    local min_x = math.min(sx, bx)
    local max_x = math.max(sx, bx)
    local min_y = math.min(sy, by)
    local max_y = math.max(sy, by)
    local w = math.max(4, max_x - min_x)
    local h = math.max(6, max_y - min_y)
    local pad_x = math.max(1, w * 0.08)
    local pad_y = math.max(1, h * 0.05)

    return {
        x = min_x - pad_x,
        y = min_y - pad_y,
        w = w + pad_x * 2,
        h = h + pad_y * 2,
        valid = true,
    }
end

-- Stable player box: entity bounds -> bones -> model parts -> head/feet fallback.
function M.player_screen_bounds(player, opts)
    if not player then return nil end
    opts = opts or {}
    local dist = opts.dist

    if player.get_bounds then
        local gb = player:get_bounds()
        if gb and gb.valid and (gb.w or 0) >= 2 and (gb.h or 0) >= 3 then
            return gb
        end
    end

    local b = M.bones_screen_bounds(player)
    if b and b.valid then
        return M.guard_tiny_bounds(b, dist)
    end

    if player.character then
        b = M.model_screen_bounds(player.character)
        if b and b.valid then
            return M.guard_tiny_bounds(b, dist)
        end
    end

    b = M.head_feet_screen_bounds(player, opts)
    if b and b.valid then
        return M.guard_tiny_bounds(b, dist)
    end

    return nil
end

function M.draw_model_skeleton(model, col, thick)
    if not model then return end
    local env = April.require("core.env")
    if not env.is_valid(model) then return end

    local screen = {}
    local function part_pos(name)
        local part = env.safe_call(function()
            return model:find_first_child(name) or model:FindFirstChild(name)
        end)
        if not part or not env.is_valid(part) then return end
        local pos = part.Position or part.position
        if not pos or pos.x == nil then return end
        local sx, sy, vis = M.w2s(pos.x, pos.y, pos.z)
        if vis then screen[name] = { x = sx, y = sy } end
    end

    for _, pair in ipairs(M.SKELETON_PAIRS) do
        part_pos(pair[1])
        part_pos(pair[2])
    end
    M.draw_skeleton_bones(screen, col, thick)
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
    if entry.box then
        M.draw_oriented_box(entry.box, col, thick)
        return
    end
    local scan = April.require("game.esp_scan")
    local main = entry.main_part or scan.find_main_part(entry.inst)
    local box = scan.read_part_box(main)
    if box then
        entry.box = box
        M.draw_oriented_box(box, col, thick)
    end
end

function M.oriented_box_screen_bounds(box)
    if not box then return nil end

    local min_x, min_y, max_x, max_y
    local any = false

    for i = 1, 8 do
        local sx, sy, sz = BOX_SIGNS[i][1], BOX_SIGNS[i][2], BOX_SIGNS[i][3]
        local lx, ly, lz = sx * box.hx, sy * box.hy, sz * box.hz
        local wx = box.x + box.rx * lx + box.ux * ly - box.lx * lz
        local wy = box.y + box.ry * lx + box.uy * ly - box.ly * lz
        local wz = box.z + box.rz * lx + box.uz * ly - box.lz * lz
        local px, py, vis = M.w2s(wx, wy, wz)
        if vis then
            any = true
            min_x = min_x and math.min(min_x, px) or px
            min_y = min_y and math.min(min_y, py) or py
            max_x = max_x and math.max(max_x, px) or px
            max_y = max_y and math.max(max_y, py) or py
        end
    end

    if not any then return nil end

    return {
        x = min_x,
        y = min_y,
        w = math.max(12, max_x - min_x),
        h = math.max(12, max_y - min_y),
        valid = true,
    }
end

function M.point_screen_bounds(wx, wy, wz, size)
    local sx, sy, vis = M.w2s(wx, wy, wz)
    if not vis then return nil end
    size = size or 48
    return {
        x = sx - size * 0.5,
        y = sy - size * 0.5,
        w = size,
        h = size,
        valid = true,
    }
end

function M.entry_screen_bounds(entry)
    if not entry then return nil end

    if entry.box then
        local bounds = M.oriented_box_screen_bounds(entry.box)
        if bounds then return bounds end
    end

    if entry.inst then
        local scan = April.require("game.esp_scan")
        local main = entry.main_part or scan.find_main_part(entry.inst)
        if main then
            local box = scan.read_part_box(main)
            if box then
                entry.box = box
                local bounds = M.oriented_box_screen_bounds(box)
                if bounds then return bounds end
            end
        end
    end

    local esp_scan = April.require("game.esp_scan")
    local lx, ly, lz = esp_scan.entry_coords(entry)
    if lx then
        return M.point_screen_bounds(lx, ly, lz, 52)
    end

    return nil
end

return M
