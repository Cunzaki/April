local M = {}

local EYE_OFFSET_Y = 2.5
local DEFAULT_STEPS = 16
local MIN_RADIUS = 0.1
local MAX_RADIUS = 1
local MAX_EXTEND_EXTRA = 7

-- Body Y offsets for ring peek (includes above-head peeks).
local RING_Y_OFFSETS = { 0, 0.75, 1.5, 2.5, 3.25, -0.5 }

function M.eye_offset_y()
    return EYE_OFFSET_Y
end

function M.clamp_radius(radius)
    radius = tonumber(radius) or 1
    if radius < MIN_RADIUS then return MIN_RADIUS end
    if radius > MAX_RADIUS then return MAX_RADIUS end
    return math.floor(radius * 100 + 0.5) / 100
end

function M.clamp_extend_extra(extra)
    extra = tonumber(extra) or MAX_EXTEND_EXTRA
    if extra < 0 then return 0 end
    if extra > MAX_EXTEND_EXTRA then return MAX_EXTEND_EXTRA end
    return math.floor(extra * 100 + 0.5) / 100
end

function M.is_visible_from(ox, oy, oz, tx, ty, tz)
    if not raycast or not raycast.is_visible then
        return true
    end
    local ex, ey, ez = ox, oy + EYE_OFFSET_Y, oz
    return raycast.is_visible(ex, ey, ez, tx, ty, tz) == true
end

function M.is_visible_from_pos(origin, target)
    if not origin or not target then return false end
    return M.is_visible_from(origin.x, origin.y, origin.z, target.x, target.y, target.z)
end

function M.search_peek_at_radius(origin, target_pos, radius, steps)
    if not origin or not target_pos then return nil end
    steps = steps or DEFAULT_STEPS

    for _, yoff in ipairs(RING_Y_OFFSETS) do
        local oy = origin.y + yoff
        for i = 0, steps - 1 do
            local angle = (i / steps) * math.pi * 2
            local cx = origin.x + math.cos(angle) * radius
            local cz = origin.z + math.sin(angle) * radius
            if M.is_visible_from(cx, oy, cz, target_pos.x, target_pos.y, target_pos.z) then
                return { x = cx, y = oy, z = cz }
            end
        end
    end

    return nil
end

local function build_radii(base, max_r)
    local radii = {}
    local r = base
    while r < max_r - 0.04 do
        radii[#radii + 1] = r
        r = r + (r < 1 and 0.15 or 0.5)
    end
    radii[#radii + 1] = max_r
    return radii
end

local function search_peek(origin, target_pos, base_r, max_r, steps, extend)
    steps = steps or DEFAULT_STEPS
    base_r = M.clamp_radius(base_r)

    local radii
    if extend then
        max_r = base_r + M.clamp_extend_extra(max_r - base_r)
        radii = build_radii(base_r, max_r)
    else
        radii = { base_r }
        max_r = base_r
    end

    local total = #radii
    for idx, radius in ipairs(radii) do
        local peek = M.search_peek_at_radius(origin, target_pos, radius, steps)
        if peek then
            return peek, radius, idx / total
        end
    end
    return nil, max_r, 1
end

function M.evaluate_manipulation(origin, target_pos, opts)
    opts = opts or {}
    local extend = opts.extend == true
    local base_r = M.clamp_radius(opts.base_radius or opts.max_radius or 1)
    local extra = extend and M.clamp_extend_extra(opts.extend_extra or 0) or 0
    local max_r = extend and (base_r + extra) or base_r

    if not origin or not target_pos then
        return {
            state = "blocked", peek = nil, radius = base_r,
            base_radius = base_r, extend_active = false, scan_progress = 0,
        }
    end

    if M.is_visible_from_pos(origin, target_pos) then
        return {
            state = "direct", peek = nil, radius = base_r,
            base_radius = base_r, extend_active = false, scan_progress = 1,
        }
    end

    local peek, radius, progress = search_peek(origin, target_pos, base_r, max_r, opts.steps, extend)
    if peek then
        local extended = extend and radius > base_r + 0.05
        return {
            state = "ready", peek = peek, radius = radius,
            base_radius = base_r, extend_active = extended,
            scan_progress = progress or 1,
        }
    end

    return {
        state = "blocked", peek = nil, radius = max_r,
        base_radius = base_r, extend_active = false, scan_progress = 1,
    }
end

function M.find_manipulation_position(origin, target_pos, opts)
    local ev = M.evaluate_manipulation(origin, target_pos, opts)
    if ev.state == "direct" then
        return { x = origin.x, y = origin.y, z = origin.z }
    end
    return ev.peek
end

function M.peek_track_origin(peek, muzzle, body)
    if not peek then return nil end
    local y = peek.y
    if muzzle and body then
        y = peek.y + (muzzle.y - body.y)
    else
        y = peek.y + EYE_OFFSET_Y
    end
    return { x = peek.x, y = y, z = peek.z }
end

function M.ring_y(origin)
    if not origin then return 0 end
    return origin.y
end

function M.dist_sq(a, b)
    if not a or not b then return math.huge end
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return dx * dx + dy * dy + dz * dz
end

return M
