local M = {}

local cache = {}
local ready = false

local FLAG_DEFAULTS = {
    PhysicsSenderMaxBandwidthBps = 38760,
    DataSenderRate = 60,
    S2PhysicsSenderRate = 15,
}

local function can_mem()
    return memory and type(memory.write) == "function"
end

local function can_fflag()
    return fflag and type(fflag.set_value) == "function"
end

function M.available()
    return can_mem() or can_fflag()
end

function M.refresh()
    cache = {}
    ready = false
    if not fflag or not fflag.is_scanned or not fflag.is_scanned() then return end

    local ok, all = pcall(fflag.get_all)
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
    if not fflag or not fflag.find then return nil end
    local ok, hits = pcall(fflag.find, name)
    if ok and type(hits) == "table" and hits[1] and hits[1].address then
        local e = { addr = hits[1].address, original = hits[1].original or hits[1].value }
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
        local ok = pcall(memory.write, e.addr, "int32", num)
        if ok then return true end
    end

    if can_fflag() then
        return pcall(fflag.set_value, name, num) == true
    end
    return false
end

function M.reset(name)
    if not name then return false end
    local e = lookup(name)
    local orig = (e and e.original) or FLAG_DEFAULTS[name]
    if orig == nil then
        if fflag and fflag.reset_value then
            return pcall(fflag.reset_value, name)
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
