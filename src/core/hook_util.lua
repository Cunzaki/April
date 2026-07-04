--[[
    Safe function hooking — uses hookfunction when Vector provides it, else table replace.
]]

local M = {}

function M.can_hook()
    return type(hookfunction) == "function"
end

function M.hook_method(obj, key, wrapper)
    if not obj or type(obj[key]) ~= "function" then return nil end
    local original = obj[key]

    local function replacement(...)
        return wrapper(original, ...)
    end

    if M.can_hook() then
        local ok, hooked = pcall(hookfunction, original, replacement)
        if ok and type(hooked) == "function" then
            obj[key] = hooked
            return original
        end
    end

    obj[key] = replacement
    return original
end

return M
