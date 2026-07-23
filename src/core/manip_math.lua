local M = {}

local EYE_OFFSET_Y = 2.5
local DEFAULT_STEPS = 24
local MIN_RADIUS = 0.1
local MAX_RADIUS = 1
local MAX_EXTEND_EXTRA = 7
local CACHE_TTL_MS = 180
local MAX_Y_OFFSET = 2.5

-- Vertical samples around the body (full 3D peek search, not horizontal-only).
local Y_OFFSETS = { 0, 0.5, 1.0, 1.5, 2.0, 2.5, -0.5, -1.0, -1.5 }

local _peek_cache = {}

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function cache_key(origin, target_pos)
    if not origin or not target_pos then return nil end
    return string.format(
        "%.1f:%.1f:%.1f>%.1f:%.1f:%.1f",
        origin.x, origin.y, origin.z,
        target_pos.x, target_pos.y, target_pos.z
    )
end

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
    extra = tonumber(extra) or 0
    if extra < 0 then return 0 end
    if extra > MAX_EXTEND_EXTRA then return MAX_EXTEND_EXTRA end
    return math.floor(extra * 100 + 0.5) / 100
end

function M.max_y_offset()
    return MAX_Y_OFFSET
end

local function clamp_peek_y(peek, origin)
    if not peek or not origin then return peek end
    local dy = peek.y - origin.y
    if dy > MAX_Y_OFFSET then
        peek.y = origin.y + MAX_Y_OFFSET
    elseif dy < -MAX_Y_OFFSET then
        peek.y = origin.y - MAX_Y_OFFSET
    end
    return peek
end

local function peek_y_ok(peek, origin)
    if not peek or not origin then return false end
    local dy = peek.y - origin.y
    return dy >= -MAX_Y_OFFSET - 0.02 and dy <= MAX_Y_OFFSET + 0.02
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

local function steps_for_radius(radius, base_steps)
    base_steps = base_steps or DEFAULT_STEPS
    if radius <= 0.35 then
        return math.max(base_steps, 32)
    end
    if radius <= 0.7 then
        return math.max(base_steps, 26)
    end
    if radius <= 1.5 then
        return math.max(base_steps, 22)
    end
    return base_steps
end

local function yaw_to_target(origin, target_pos)
    local dx = target_pos.x - origin.x
    local dz = target_pos.z - origin.z
    if math.abs(dx) < 1e-6 and math.abs(dz) < 1e-6 then
        return 0
    end
    return math.atan2(dz, dx)
end

local function try_peek_at(cx, oy, cz, origin, target_pos)
    if M.is_visible_from(cx, oy, cz, target_pos.x, target_pos.y, target_pos.z) then
        return clamp_peek_y({ x = cx, y = oy, z = cz }, origin)
    end
    return nil
end

-- Ring + slight vertical jitter at each Y sample for fuller 3D coverage.
function M.search_peek_at_radius(origin, target_pos, radius, steps)
    if not origin or not target_pos then return nil end
    steps = steps_for_radius(radius, steps or DEFAULT_STEPS)

    local facing = yaw_to_target(origin, target_pos)
    local sector = math.pi * 0.65

    for _, yoff in ipairs(Y_OFFSETS) do
        local oy = origin.y + yoff

        local sector_steps = math.max(10, math.floor(steps * 0.6))
        for i = 0, sector_steps - 1 do
            local t = (i / math.max(1, sector_steps - 1)) * 2 - 1
            local angle = facing + t * sector
            local cx = origin.x + math.cos(angle) * radius
            local cz = origin.z + math.sin(angle) * radius
            local hit = try_peek_at(cx, oy, cz, origin, target_pos)
            if hit then return hit end
        end

        for i = 0, steps - 1 do
            local angle = (i / steps) * math.pi * 2
            local cx = origin.x + math.cos(angle) * radius
            local cz = origin.z + math.sin(angle) * radius
            local hit = try_peek_at(cx, oy, cz, origin, target_pos)
            if hit then return hit end
        end

        -- Diagonal samples on the ring (helps corner peeks).
        local diag = math.max(8, math.floor(steps * 0.35))
        for i = 0, diag - 1 do
            local angle = facing + (i / diag) * math.pi * 2
            local r2 = radius * 0.72
            local cx = origin.x + math.cos(angle) * r2
            local cz = origin.z + math.sin(angle) * r2
            local hit = try_peek_at(cx, oy, cz, origin, target_pos)
            if hit then return hit end
        end
    end

    return nil
end

local function build_radii(base, max_r)
    local radii = {}
    local r = base
    local step = r < 0.5 and 0.08 or (r < 1 and 0.12 or 0.35)
    while r < max_r - 0.03 do
        radii[#radii + 1] = r
        r = r + step
        step = r < 1 and 0.12 or 0.35
    end
    radii[#radii + 1] = max_r
    return radii
end

local function search_peek(origin, target_pos, base_r, max_r, steps, extend)
    steps = steps or DEFAULT_STEPS
    base_r = M.clamp_radius(base_r)

    local radii
    if extend and max_r > base_r + 0.04 then
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
    local base_r = M.clamp_radius(opts.base_radius or opts.max_radius or 1)
    local extra = M.clamp_extend_extra(opts.extend_extra or 0)
    local extend = opts.extend == true or extra > 0.04
    local max_r = extend and (base_r + extra) or base_r

    if not origin or not target_pos then
        return {
            state = "blocked", peek = nil, radius = base_r,
            base_radius = base_r, extend_active = extend, scan_progress = 0,
        }
    end

    if M.is_visible_from_pos(origin, target_pos) then
        return {
            state = "direct", peek = nil, radius = base_r,
            base_radius = base_r, extend_active = false, scan_progress = 1,
        }
    end

    local key = cache_key(origin, target_pos)
    local now = tick_ms()
    if key and _peek_cache[key] then
        local ent = _peek_cache[key]
        if ent.peek and (now - (ent.t or 0)) < CACHE_TTL_MS then
            clamp_peek_y(ent.peek, origin)
            if peek_y_ok(ent.peek, origin) and M.is_visible_from_pos(ent.peek, target_pos) then
                local extended = extend and (ent.radius or base_r) > base_r + 0.05
                return {
                    state = "ready", peek = ent.peek, radius = ent.radius or base_r,
                    base_radius = base_r, extend_active = extended,
                    scan_progress = 1, cached = true,
                }
            end
        end
    end

    local peek, radius, progress = search_peek(origin, target_pos, base_r, max_r, opts.steps, extend)
    if peek then
        clamp_peek_y(peek, origin)
        local extended = extend and radius > base_r + 0.05
        if key then
            _peek_cache[key] = { peek = peek, radius = radius, t = now }
        end
        return {
            state = "ready", peek = peek, radius = radius,
            base_radius = base_r, extend_active = extended,
            scan_progress = progress or 1,
        }
    end

    return {
        state = extend and "scanning" or "blocked",
        peek = nil, radius = max_r,
        base_radius = base_r, extend_active = extend, scan_progress = 1,
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
    local base = body or peek
    local yoff = peek.y - base.y
    if yoff > MAX_Y_OFFSET then
        yoff = MAX_Y_OFFSET
    elseif yoff < -MAX_Y_OFFSET then
        yoff = -MAX_Y_OFFSET
    end

    local y
    if muzzle and body then
        y = muzzle.y + yoff
    else
        y = body and (body.y + yoff) or peek.y
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

function M.clear_peek_cache()
    _peek_cache = {}
end

return M
