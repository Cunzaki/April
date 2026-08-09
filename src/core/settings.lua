local M = {}

local _callbacks = {}
local feature_bind = nil
local _frame = 0
local _value_cache = {}
local _color_cache = {}

local NIL = {}

local function clear_table(t)
    for key in pairs(t) do t[key] = nil end
end

-- Menu values are immutable for the duration of one April frame. Cache the
-- first bridge read per id so every consumer observes the same current value
-- without paying for duplicate host calls. UI/config writes invalidate the
-- affected entry immediately through invalidate().
function M.begin_frame(frame)
    frame = tonumber(frame) or (_frame + 1)
    if frame == _frame then return end
    _frame = frame
    clear_table(_value_cache)
    clear_table(_color_cache)
end

function M.frame()
    return _frame
end

function M.invalidate(id)
    if id ~= nil then
        _value_cache[id] = nil
        _color_cache[id] = nil
        return
    end
    clear_table(_value_cache)
    clear_table(_color_cache)
end

function M.get(id, default)
    local cached = _value_cache[id]
    if cached ~= nil then
        if cached == NIL then return default end
        return cached
    end
    if menu and menu.get then
        local v = menu.get(id)
        _value_cache[id] = v == nil and NIL or v
        if v ~= nil then return v end
    end
    _value_cache[id] = NIL
    return default
end

function M.bool(id, default)
    local v = M.get(id, default)
    if v == false or v == 0 or v == "false" then return false end
    return v == true or v == 1
end

function M.enabled(id)
    -- feature_bind requires settings, so resolve it lazily once to avoid a
    -- circular module load and hundreds of repeated pcall/require calls/frame.
    if not feature_bind then
        local ok, fb = pcall(April.require, "core.feature_bind")
        if ok then feature_bind = fb end
    end
    if feature_bind and feature_bind.is_registered(id) then
        return feature_bind.active(id)
    end

    return M.bool(id, false)
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
    -- Prefer 1-based. Only fall back to 0-based when the 1-based slot is absent.
    if t[index] ~= nil then
        return as_bool(t[index], default)
    end
    if index >= 1 and t[index - 1] ~= nil then
        return as_bool(t[index - 1], default)
    end
    return default == true
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
    local cached = _color_cache[id]
    if cached ~= nil then
        if cached == NIL then return default or { 1, 1, 1, 1 } end
        return cached
    end
    if menu and menu.get_color then
        local c = menu.get_color(id)
        _color_cache[id] = c or NIL
        if c then return c end
    end
    _color_cache[id] = NIL
    return default or { 1, 1, 1, 1 }
end

function M.on_change(id, fn)
    if not id or not fn then return end

    _callbacks[id] = _callbacks[id] or {}
    _callbacks[id][#_callbacks[id] + 1] = fn

    if menu and menu.set_callback then
        menu.set_callback(id, function(new_val)
            M.invalidate(id)
            for _, cb in ipairs(_callbacks[id] or {}) do
                pcall(cb, new_val)
            end
        end)
    end
end

function M.flush() end
function M.mark_dirty() end

return M
