--[[ Peek / bullet manipulation visibility math (raycast-backed). ]]

local M = {}

local EYE_OFFSET_Y = 2.5
local SEARCH_RADII = { 4, 8 }
local SEARCH_STEPS = 8

function M.eye_offset_y()
    return EYE_OFFSET_Y
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

function M.find_manipulation_position(origin, target_pos)
    if not origin or not target_pos then return nil end

    if M.is_visible_from_pos(origin, target_pos) then
        return { x = origin.x, y = origin.y, z = origin.z }
    end

    for _, radius in ipairs(SEARCH_RADII) do
        for i = 0, SEARCH_STEPS - 1 do
            local angle = (i / SEARCH_STEPS) * math.pi * 2
            local cx = origin.x + math.cos(angle) * radius
            local cy = origin.y
            local cz = origin.z + math.sin(angle) * radius
            local candidate = { x = cx, y = cy, z = cz }
            if M.is_visible_from(cx, cy, cz, target_pos.x, target_pos.y, target_pos.z) then
                return candidate
            end
        end
    end

    return nil
end

function M.dist_sq(a, b)
    if not a or not b then return math.huge end
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return dx * dx + dy * dy + dz * dz
end

return M
