local M = {}

local values = {}
local read_count = 0

function M.invalidate()
    values = {}
end

function M.get(id, default)
    if values[id] == nil then
        if menu and menu.get then
            local v = menu.get(id)
            if v ~= nil then values[id] = v else values[id] = default end
        else
            values[id] = default
        end
    end
    read_count = read_count + 1
    return values[id]
end

function M.bool(id, default)
    local v = M.get(id, default)
    return v == true or v == 1
end

function M.num(id, default)
    return tonumber(M.get(id, default)) or default or 0
end

function M.str(id, default)
    local v = M.get(id, default)
    if v == nil then return default or "" end
    return tostring(v)
end

function M.color(id, default)
    if menu and menu.get_color then
        local c = menu.get_color(id)
        if c then
            values[id] = c
            return c
        end
    end
    return default or { 1, 1, 1, 1 }
end

function M.on_change(id, fn)
    if menu and menu.set_callback then
        menu.set_callback(id, function(new_val)
            values[id] = new_val
            if fn then fn(new_val) end
        end)
    end
end

function M.flush()
    values = {}
end

function M.mark_dirty()
    values = {}
end

function M.stats()
    return { reads = read_count }
end

return M
