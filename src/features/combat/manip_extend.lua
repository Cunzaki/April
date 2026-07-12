-- Extend manip: incremental origin scan only (no desync, no HRP move, no fire-rate patch).

local manip_math = April.require("core.manip_math")

local M = {}

local scan = nil

local function scan_key(origin, target)
    if not origin or not target then return nil end
    return string.format("%.1f,%.1f,%.1f|%.1f,%.1f,%.1f",
        origin.x, origin.y, origin.z, target.x, target.y, target.z)
end

function M.reset()
    scan = nil
end

-- Incremental ring scan for extend — one ring per call (progress bar).
function M.evaluate_extend(origin, target_pos, base_r, extra_r)
    base_r = manip_math.clamp_radius(base_r)
    extra_r = manip_math.clamp_extend_extra(extra_r)
    local max_r = base_r + extra_r

    if not origin or not target_pos then
        return {
            state = "blocked", peek = nil, radius = base_r,
            base_radius = base_r, extend_active = false, scan_progress = 0,
        }
    end

    if manip_math.is_visible_from_pos(origin, target_pos) then
        scan = nil
        return {
            state = "direct", peek = nil, radius = base_r,
            base_radius = base_r, extend_active = false, scan_progress = 1,
        }
    end

    local key = scan_key(origin, target_pos)
    if not scan or scan.key ~= key or scan.base ~= base_r or scan.max ~= max_r then
        local radii = {}
        local r = base_r
        while r < max_r - 0.04 do
            radii[#radii + 1] = r
            r = r + (r < 1 and 0.15 or 0.5)
        end
        radii[#radii + 1] = max_r
        scan = {
            key = key, base = base_r, max = max_r,
            radii = radii, ri = 1, steps = 16,
            origin = origin, target = target_pos,
        }
    end

    local s = scan
    local radius = s.radii[s.ri]
    local peek = nil
    for i = 0, s.steps - 1 do
        local angle = (i / s.steps) * math.pi * 2
        local cx = s.origin.x + math.cos(angle) * radius
        local cy = s.origin.y
        local cz = s.origin.z + math.sin(angle) * radius
        if manip_math.is_visible_from(cx, cy, cz, s.target.x, s.target.y, s.target.z) then
            peek = { x = cx, y = cy, z = cz }
            break
        end
    end

    local progress = s.ri / #s.radii
    if peek then
        local extended = radius > base_r + 0.05
        scan = nil
        return {
            state = "ready", peek = peek, radius = radius,
            base_radius = base_r, extend_active = extended,
            scan_progress = 1,
        }
    end

    s.ri = s.ri + 1
    if s.ri > #s.radii then
        scan = nil
        return {
            state = "blocked", peek = nil, radius = max_r,
            base_radius = base_r, extend_active = false, scan_progress = 1,
        }
    end

    return {
        state = "scanning", peek = nil, radius = radius,
        base_radius = base_r, extend_active = false,
        scan_progress = progress,
    }
end

return M
