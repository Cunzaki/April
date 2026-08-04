local M = {}

local cache = {}
local ready = false

local FLAG_DEFAULTS = {
    PhysicsSenderMaxBandwidthBps = 38760,
    DataSenderRate = 60,
    S2PhysicsSenderRate = 15,
}

local function fflag_api(snake, pascal)
    if not fflag then return nil end
    local fn = fflag[snake] or fflag[pascal]
    return type(fn) == "function" and fn or nil
end

local function can_mem()
    return memory and type(memory.write or memory.Write) == "function"
end

local function can_fflag()
    return fflag_api("set_value", "SetValue") ~= nil
end

function M.available()
    return can_mem() or can_fflag()
end

function M.refresh()
    cache = {}
    ready = false
    local is_scanned = fflag_api("is_scanned", "IsScanned")
    local get_all = fflag_api("get_all", "GetAll")
    if not is_scanned or not get_all then return end
    local ok_scan, scanned = pcall(is_scanned)
    if not ok_scan or scanned ~= true then return end

    local ok, all = pcall(get_all)
    if ok and type(all) == "table" then
        for i = 1, #all do
            local e = all[i]
            if e and e.name and e.address and e.address > 0 then
                cache[e.name] = {
                    addr = e.address,
                    original = e.original or e.value,
                }
            end
        end
    end
    ready = next(cache) ~= nil
end

local function lookup(name)
    if cache[name] then return cache[name] end
    local find = fflag_api("find", "Find")
    if not find then return nil end
    local ok, hits = pcall(find, name)
    if ok and type(hits) == "table" and hits[1] then
        local hit = hits[1]
        local e = { addr = hit.address, original = hit.original or hit.value }
        cache[name] = e
        return e
    end
    return nil
end

function M.set_int(name, value)
    if not name then return false end
    if not ready then M.refresh() end

    local num = tonumber(value)
    if num == nil then return false end

    local e = lookup(name)
    if e and e.addr and can_mem() then
        local write = memory.write or memory.Write
        local ok, result = pcall(write, e.addr, "int32", num)
        if ok and result ~= false then return true end
    end

    if can_fflag() then
        local ok, result = pcall(fflag_api("set_value", "SetValue"), name, num)
        return ok and result == true
    end
    return false
end

function M.get_int(name)
    if not name then return nil end
    if not ready then M.refresh() end
    local e = lookup(name)
    local read = memory and (memory.read or memory.Read)
    if e and e.addr and type(read) == "function" then
        local ok, value = pcall(read, e.addr, "int32")
        if ok and tonumber(value) ~= nil then return tonumber(value) end
    end
    local get_value = fflag_api("get_value", "GetValue")
    if not get_value then return nil end
    local ok, value = pcall(get_value, name)
    return ok and tonumber(value) or nil
end

function M.reset(name)
    if not name then return false end
    local e = lookup(name)
    local orig = (e and e.original) or FLAG_DEFAULTS[name]
    if orig == nil then
        local reset_value = fflag_api("reset_value", "ResetValue")
        if reset_value then
            local ok, result = pcall(reset_value, name)
            return ok and result == true
        end
        return false
    end
    return M.set_int(name, orig)
end

function M.reset_defaults()
    M.set_int("PhysicsSenderMaxBandwidthBps", FLAG_DEFAULTS.PhysicsSenderMaxBandwidthBps)
    M.set_int("DataSenderRate", FLAG_DEFAULTS.DataSenderRate)
    M.set_int("S2PhysicsSenderRate", FLAG_DEFAULTS.S2PhysicsSenderRate)
end

return M
