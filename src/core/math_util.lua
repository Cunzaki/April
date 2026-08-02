local M = {}

-- Vector Lua is 5.3+: math.atan2 was removed. Prefer atan(y,x), keep atan2 fallback.
function M.atan2(y, x)
    y = y or 0
    x = x or 0
    if math.atan2 then
        return math.atan2(y, x)
    end
    local ok, result = pcall(math.atan, y, x)
    if ok and type(result) == "number" then
        return result
    end
    if x > 0 then
        return math.atan(y / x)
    elseif x < 0 and y >= 0 then
        return math.atan(y / x) + math.pi
    elseif x < 0 and y < 0 then
        return math.atan(y / x) - math.pi
    elseif x == 0 and y > 0 then
        return math.pi * 0.5
    elseif x == 0 and y < 0 then
        return -math.pi * 0.5
    end
    return 0
end

function M.clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

function M.distance3(dx, dy, dz)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function M.distance2(dx, dy)
    return math.sqrt(dx * dx + dy * dy)
end

function M.dot(ax, ay, az, bx, by, bz)
    return ax * bx + ay * by + az * bz
end

function M.screen_fov_dist(sx, sy, cx, cy)
    local dx, dy = sx - cx, sy - cy
    return math.sqrt(dx * dx + dy * dy)
end

function M.vec3_str(v)
    if not v or v.x == nil then return "?" end
    return string.format("%.0f, %.0f, %.0f", v.x, v.y, v.z)
end

return M
