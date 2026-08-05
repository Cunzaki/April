-- Silent bullet manip peek search.
-- Scans are amortized across frames with a hard ray budget so Extend Distance
-- no longer fires thousands of is_visible calls in a single frame.
local M = {}

local math_util = April.require("core.math_util")

local EYE_OFFSET_Y = 2.5
local DEFAULT_STEPS = 20
local MIN_RADIUS = 0.1
local MAX_RADIUS = 1
local MAX_EXTEND_EXTRA = 7
local POS_CACHE_TTL_MS = 220
local NEG_CACHE_TTL_MS = 160
local MAX_Y_OFFSET = 2.5
-- Soft cap per evaluate() call. Remaining radii continue next frame.
local RAY_BUDGET = 110

local Y_NEAR = { 0, 0.5, 1.0, 1.5, 2.0, -0.5, -1.0 }
local Y_FAR = { 0, 1.0, 2.0, -1.0 }

local _peek_cache = {}
local _neg_cache = {}
local _jobs = {}

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
    -- Larger rings use fewer angular samples (similar arc spacing).
    if radius <= 0.35 then
        return math.max(base_steps, 28)
    end
    if radius <= 0.7 then
        return math.max(base_steps, 22)
    end
    if radius <= 1.5 then
        return math.max(14, math.floor(base_steps * 0.85))
    end
    if radius <= 3.5 then
        return math.max(12, math.floor(base_steps * 0.65))
    end
    return math.max(10, math.floor(base_steps * 0.5))
end

local function y_layers_for_radius(radius)
    if radius <= 1.2 then return Y_NEAR end
    return Y_FAR
end

local function yaw_to_target(origin, target_pos)
    local dx = target_pos.x - origin.x
    local dz = target_pos.z - origin.z
    if math.abs(dx) < 1e-6 and math.abs(dz) < 1e-6 then
        return 0
    end
    return math_util.atan2(dz, dx)
end

local function try_peek_at(cx, oy, cz, origin, target_pos)
    if M.is_visible_from(cx, oy, cz, target_pos.x, target_pos.y, target_pos.z) then
        return clamp_peek_y({ x = cx, y = oy, z = cz }, origin)
    end
    return nil
end

local function build_radii(base, max_r)
    local radii = {}
    local r = base
    -- Wider steps at large extend radii — quality stays high near body.
    local step = r < 0.5 and 0.10 or (r < 1 and 0.16 or 0.45)
    while r < max_r - 0.04 do
        radii[#radii + 1] = r
        r = r + step
        step = r < 1 and 0.16 or (r < 3 and 0.40 or 0.55)
    end
    radii[#radii + 1] = max_r
    return radii
end

-- Synchronous single-radius search (used by bullet TP). LOD keeps it cheap.
function M.search_peek_at_radius(origin, target_pos, radius, steps)
    if not origin or not target_pos then return nil end
    steps = steps_for_radius(radius, steps or DEFAULT_STEPS)
    local facing = yaw_to_target(origin, target_pos)
    local sector = math.pi * 0.65
    local layers = y_layers_for_radius(radius)

    for li = 1, #layers do
        local oy = origin.y + layers[li]
        local sector_steps = math.max(8, math.floor(steps * 0.55))
        for i = 0, sector_steps - 1 do
            local t = (i / math.max(1, sector_steps - 1)) * 2 - 1
            local angle = facing + t * sector
            local hit = try_peek_at(
                origin.x + math.cos(angle) * radius,
                oy,
                origin.z + math.sin(angle) * radius,
                origin, target_pos
            )
            if hit then return hit end
        end

        for i = 0, steps - 1 do
            local angle = (i / steps) * math.pi * 2
            local hit = try_peek_at(
                origin.x + math.cos(angle) * radius,
                oy,
                origin.z + math.sin(angle) * radius,
                origin, target_pos
            )
            if hit then return hit end
        end

        if radius <= 2.0 then
            local diag = math.max(6, math.floor(steps * 0.3))
            local r2 = radius * 0.72
            for i = 0, diag - 1 do
                local angle = facing + (i / diag) * math.pi * 2
                local hit = try_peek_at(
                    origin.x + math.cos(angle) * r2,
                    oy,
                    origin.z + math.sin(angle) * r2,
                    origin, target_pos
                )
                if hit then return hit end
            end
        end
    end
    return nil
end

local function job_key(origin, target_pos, base_r, max_r, extend)
    local ck = cache_key(origin, target_pos)
    if not ck then return nil end
    return ck .. string.format("|%.2f:%.2f:%d", base_r, max_r, extend and 1 or 0)
end

local function ensure_job(key, origin, target_pos, base_r, max_r, extend, steps)
    local job = _jobs[key]
    if job then return job end
    local radii = extend and build_radii(base_r, max_r) or { base_r }
    job = {
        key = key,
        origin = origin,
        target = target_pos,
        radii = radii,
        ri = 1,
        yi = 1,
        phase = 1, -- 1 sector, 2 full, 3 diag
        ai = 0,
        steps = steps or DEFAULT_STEPS,
        rays = 0,
        started = tick_ms(),
    }
    _jobs[key] = job
    return job
end

local function clear_job(key)
    if key then _jobs[key] = nil end
end

-- Advance one sample. Returns peek or nil. Updates job cursor.
local function job_step(job)
    local radii = job.radii
    if job.ri > #radii then return nil, true end

    local radius = radii[job.ri]
    local layers = y_layers_for_radius(radius)
    if job.yi > #layers then
        job.ri = job.ri + 1
        job.yi = 1
        job.phase = 1
        job.ai = 0
        return nil, job.ri > #radii
    end

    local origin = job.origin
    local target_pos = job.target
    local steps = steps_for_radius(radius, job.steps)
    local facing = yaw_to_target(origin, target_pos)
    local oy = origin.y + layers[job.yi]
    local angle, use_r

    if job.phase == 1 then
        local sector_steps = math.max(8, math.floor(steps * 0.55))
        if job.ai >= sector_steps then
            job.phase = 2
            job.ai = 0
            return nil, false
        end
        local t = (job.ai / math.max(1, sector_steps - 1)) * 2 - 1
        angle = facing + t * (math.pi * 0.65)
        use_r = radius
        job.ai = job.ai + 1
    elseif job.phase == 2 then
        if job.ai >= steps then
            if radius <= 2.0 then
                job.phase = 3
            else
                job.yi = job.yi + 1
                job.phase = 1
            end
            job.ai = 0
            return nil, false
        end
        angle = (job.ai / steps) * math.pi * 2
        use_r = radius
        job.ai = job.ai + 1
    else
        local diag = math.max(6, math.floor(steps * 0.3))
        if job.ai >= diag then
            job.yi = job.yi + 1
            job.phase = 1
            job.ai = 0
            return nil, false
        end
        angle = facing + (job.ai / diag) * math.pi * 2
        use_r = radius * 0.72
        job.ai = job.ai + 1
    end

    job.rays = job.rays + 1
    local hit = try_peek_at(
        origin.x + math.cos(angle) * use_r,
        oy,
        origin.z + math.sin(angle) * use_r,
        origin, target_pos
    )
    return hit, false
end

local function progress_of(job)
    local total = #job.radii
    if total <= 0 then return 1 end
    return math.min(1, (job.ri - 1) / total)
end

function M.evaluate_manipulation(origin, target_pos, opts)
    opts = opts or {}
    local base_r = M.clamp_radius(opts.base_radius or opts.max_radius or 1)
    local extra = M.clamp_extend_extra(opts.extend_extra or 0)
    local extend = opts.extend == true or extra > 0.04
    local max_r = extend and (base_r + extra) or base_r
    local budget = tonumber(opts.ray_budget) or RAY_BUDGET
    if budget < 24 then budget = 24 end

    if not origin or not target_pos then
        return {
            state = "blocked", peek = nil, radius = base_r,
            base_radius = base_r, extend_active = extend, scan_progress = 0,
            rays = 0,
        }
    end

    if M.is_visible_from_pos(origin, target_pos) then
        return {
            state = "direct", peek = nil, radius = base_r,
            base_radius = base_r, extend_active = false, scan_progress = 1,
            rays = 1,
        }
    end

    local key = cache_key(origin, target_pos)
    local now = tick_ms()

    if key and _neg_cache[key] then
        local neg = _neg_cache[key]
        if (now - (neg.t or 0)) < NEG_CACHE_TTL_MS
            and (neg.max_r or 0) + 0.02 >= max_r
        then
            return {
                state = "blocked", peek = nil, radius = max_r,
                base_radius = base_r, extend_active = extend,
                scan_progress = 1, cached = true, rays = 0,
            }
        end
    end

    if key and _peek_cache[key] then
        local ent = _peek_cache[key]
        if ent.peek and (now - (ent.t or 0)) < POS_CACHE_TTL_MS then
            clamp_peek_y(ent.peek, origin)
            if peek_y_ok(ent.peek, origin) and M.is_visible_from_pos(ent.peek, target_pos) then
                local extended = extend and (ent.radius or base_r) > base_r + 0.05
                return {
                    state = "ready", peek = ent.peek, radius = ent.radius or base_r,
                    base_radius = base_r, extend_active = extended,
                    scan_progress = 1, cached = true, rays = 1,
                }
            end
        end
    end

    local jkey = job_key(origin, target_pos, base_r, max_r, extend)
    local job = ensure_job(jkey, origin, target_pos, base_r, max_r, extend, opts.steps)
    -- Refresh live positions each frame so the cursor tracks the target.
    job.origin = origin
    job.target = target_pos

    local used = 0
    while used < budget do
        local peek, done = job_step(job)
        used = used + 1
        if peek then
            clamp_peek_y(peek, origin)
            local radius = job.radii[job.ri] or max_r
            local extended = extend and radius > base_r + 0.05
            if key then
                _peek_cache[key] = { peek = peek, radius = radius, t = now }
                _neg_cache[key] = nil
            end
            clear_job(jkey)
            return {
                state = "ready", peek = peek, radius = radius,
                base_radius = base_r, extend_active = extended,
                scan_progress = 1, rays = used,
            }
        end
        if done then
            if key then
                _neg_cache[key] = { t = now, max_r = max_r }
            end
            clear_job(jkey)
            return {
                state = "blocked", peek = nil, radius = max_r,
                base_radius = base_r, extend_active = extend,
                scan_progress = 1, rays = used,
            }
        end
    end

    return {
        state = "scanning",
        peek = nil,
        radius = job.radii[job.ri] or max_r,
        base_radius = base_r,
        extend_active = extend,
        scan_progress = progress_of(job),
        rays = used,
        radius_idx = job.ri,
        radii_total = #job.radii,
    }
end

function M.find_manipulation_position(origin, target_pos, opts)
    -- Prefer a completed result; allow a larger one-shot budget for callers
    -- like body_peek that need an answer this frame.
    opts = opts or {}
    if opts.ray_budget == nil then
        opts = {
            base_radius = opts.base_radius,
            max_radius = opts.max_radius,
            extend = opts.extend,
            extend_extra = opts.extend_extra,
            steps = opts.steps,
            ray_budget = 220,
        }
    end
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
    _neg_cache = {}
    _jobs = {}
end

return M
