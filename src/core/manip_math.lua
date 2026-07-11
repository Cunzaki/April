local M = {}

local EYE_OFFSET_Y = 2.5
local DEFAULT_STEPS = 16
local MIN_RADIUS = 0.1
local MAX_RADIUS = 1
local MAX_EXTEND_RADIUS = 8

function M.eye_offset_y()
    return EYE_OFFSET_Y
end

function M.clamp_radius(radius)
    radius = tonumber(radius) or 1
    if radius < MIN_RADIUS then return MIN_RADIUS end
    if radius > MAX_RADIUS then return MAX_RADIUS end
    return math.floor(radius * 100 + 0.5) / 100
end

function M.clamp_extend_radius(radius)
    radius = tonumber(radius) or MAX_EXTEND_RADIUS
    if radius < MIN_RADIUS then return MIN_RADIUS end
    if radius > MAX_EXTEND_RADIUS then return MAX_EXTEND_RADIUS end
    return math.floor(radius * 100 + 0.5) / 100
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

local function search_ring(origin, target_pos, radius, steps)
    for i = 0, steps - 1 do
        local angle = (i / steps) * math.pi * 2
        local cx = origin.x + math.cos(angle) * radius
        local cy = origin.y
        local cz = origin.z + math.sin(angle) * radius
        if M.is_visible_from(cx, cy, cz, target_pos.x, target_pos.y, target_pos.z) then
            return { x = cx, y = cy, z = cz }, radius
        end
    end
    return nil, radius
end

local function search_peek(origin, target_pos, max_radius, steps, extend)
    steps = steps or DEFAULT_STEPS

    if not extend then
        max_radius = M.clamp_radius(max_radius)
        return search_ring(origin, target_pos, max_radius, steps)
    end

    max_radius = M.clamp_extend_radius(max_radius)
    -- Prefer nearer peeks first (1 → … → max), matching divine multi-radius search.
    local radii = {}
    local r = 1
    while r < max_radius - 0.05 do
        radii[#radii + 1] = r
        r = r + 1
    end
    radii[#radii + 1] = max_radius

    for _, radius in ipairs(radii) do
        local peek = search_ring(origin, target_pos, radius, steps)
        if peek then
            return peek, radius
        end
    end

    return nil, max_radius
end

function M.evaluate_manipulation(origin, target_pos, opts)
    opts = opts or {}
    local extend = opts.extend == true
    local clamp = extend and M.clamp_extend_radius or M.clamp_radius

    if not origin or not target_pos then
        return { state = "blocked", peek = nil, radius = clamp(opts.max_radius) }
    end

    if M.is_visible_from_pos(origin, target_pos) then
        return { state = "direct", peek = nil, radius = clamp(opts.max_radius) }
    end

    local peek, radius = search_peek(origin, target_pos, opts.max_radius, opts.steps, extend)
    if peek then
        return { state = "ready", peek = peek, radius = radius }
    end

    return { state = "blocked", peek = nil, radius = clamp(opts.max_radius) }
end

function M.find_manipulation_position(origin, target_pos, opts)
    local ev = M.evaluate_manipulation(origin, target_pos, opts)
    if ev.state == "direct" then
        return { x = origin.x, y = origin.y, z = origin.z }
    end
    return ev.peek
end

function M.peek_track_origin(peek)
    if not peek then return nil end
    return {
        x = peek.x,
        y = peek.y + EYE_OFFSET_Y,
        z = peek.z,
    }
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
