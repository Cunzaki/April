local M = {}

local _callbacks = {}

function M.invalidate() end

function M.get(id, default)
    if menu and menu.get then
        local v = menu.get(id)
        if v ~= nil then return v end
    end
    return default
end

function M.bool(id, default)
    local v = M.get(id, default)
    if v == false or v == 0 or v == "false" then return false end
    return v == true or v == 1
end

function M.enabled(id)
    local ok, fb = pcall(function()
        return April.require("core.feature_bind")
    end)
    if ok and fb and fb.is_registered(id) then
        return fb.active(id)
    end

    if not menu or not menu.get then return false end
    local v = menu.get(id)
    if v == nil or v == false or v == 0 or v == "false" then return false end
    return v == true or v == 1
end

function M.num(id, default)
    return tonumber(M.get(id, default)) or default or 0
end

local function as_bool(v, default)
    if v == nil then
        return default == true
    end
    if v == true or v == 1 or v == "1" or v == "true" or v == "True" then
        return true
    end
    if v == false or v == 0 or v == "0" or v == "false" or v == "False" then
        return false
    end
    return default == true
end

-- Multicombo slot (1-based). Accepts bool / 0|1 / "0"|"1"|"true"|"false".
function M.multi(id, index, default)
    local t = M.get(id)
    if type(t) ~= "table" then
        return default == true
    end
    -- Prefer 1-based; some builds expose 0-based arrays.
    local v = t[index]
    if v == nil and index >= 1 then
        v = t[index - 1]
    end
    return as_bool(v, default)
end

function M.combo_index(id, labels, default)
    default = default or 0
    local v = M.get(id, default)
    if type(v) == "string" then
        local lower = v:lower()
        for i, label in ipairs(labels or {}) do
            if label:lower() == lower then return i - 1 end
        end
        return default
    end
    local n = tonumber(v)
    if n == nil then return default end
    return n
end

function M.str(id, default)
    local v = M.get(id, default)
    if v == nil then return default or "" end
    return tostring(v)
end

function M.color(id, default)
    if menu and menu.get_color then
        local c = menu.get_color(id)
        if c then return c end
    end
    return default or { 1, 1, 1, 1 }
end

function M.on_change(id, fn)
    if not id or not fn then return end

    _callbacks[id] = _callbacks[id] or {}
    _callbacks[id][#_callbacks[id] + 1] = fn

    if menu and menu.set_callback then
        menu.set_callback(id, function(new_val)
            for _, cb in ipairs(_callbacks[id] or {}) do
                pcall(cb, new_val)
            end
        end)
    end
end

function M.flush() end
function M.mark_dirty() end

return M
