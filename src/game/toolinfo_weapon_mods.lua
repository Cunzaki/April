-- Patch live ToolInfo Weapon fields (Double Tap / Burst).
-- GC applygc only covers *Mult keys; Burst needs direct table writes.

local bootstrap = April.require("game.bootstrap")

local M = {}

M._baseline = nil
M._applied = false
M._last_sig = nil

local function deep_copy(v, seen)
    if type(v) ~= "table" then return v end
    seen = seen or {}
    if seen[v] then return seen[v] end
    local out = {}
    seen[v] = out
    for k, val in pairs(v) do
        out[k] = deep_copy(val, seen)
    end
    return out
end

local function ensure_baseline(toolinfo)
    if M._baseline then return true end
    if type(toolinfo) ~= "table" then return false end
    M._baseline = deep_copy(toolinfo)
    return true
end

local function weapon_entry(toolinfo, name)
    local entry = toolinfo[name]
    if type(entry) ~= "table" then return nil end
    return entry.Weapon
end

local function baseline_weapon(name)
    if not M._baseline then return nil end
    local entry = M._baseline[name]
    if type(entry) ~= "table" then return nil end
    return entry.Weapon
end

local function restore_weapon(live_w, old_w)
    if not live_w or not old_w then return end
    if old_w.Burst ~= nil then
        live_w.Burst = old_w.Burst
    end
    if old_w.BurstRPM ~= nil then
        live_w.BurstRPM = old_w.BurstRPM
    end
end

local function apply_weapon(live_w, old_w, opts)
    if not live_w then return false end
    local changed = false

    if opts.double_tap then
        if live_w.Burst ~= nil or (old_w and old_w.Burst ~= nil) then
            live_w.Burst = 2
            live_w.BurstRPM = 10000
            changed = true
        end
    elseif old_w then
        if old_w.Burst ~= nil then live_w.Burst = old_w.Burst end
        if old_w.BurstRPM ~= nil then live_w.BurstRPM = old_w.BurstRPM end
    end

    return changed
end

function M.invalidate()
    M._baseline = nil
    M._applied = false
    M._last_sig = nil
end

function M.reset()
    local toolinfo = bootstrap.get_module("ToolInfo")
    if not toolinfo or not M._baseline then
        M._applied = false
        M._last_sig = nil
        return false
    end

    for name, entry in pairs(toolinfo) do
        if type(entry) == "table" and type(entry.Weapon) == "table" then
            restore_weapon(entry.Weapon, baseline_weapon(name))
        end
    end

    M._applied = false
    M._last_sig = nil
    return true
end

-- opts: { double_tap }
-- weapon_name: nil = all weapons (global), string = that weapon only
function M.apply(opts, weapon_name)
    opts = opts or {}
    local toolinfo = bootstrap.get_module("ToolInfo")
    if not toolinfo then
        return false, 0, "ToolInfo not ready"
    end
    if not ensure_baseline(toolinfo) then
        return false, 0, "ToolInfo baseline failed"
    end

    local any = opts.double_tap == true
    if not any then
        if M._applied then
            M.reset()
        end
        return true, 0, "no toolinfo mods"
    end

    local sig = table.concat({
        opts.double_tap and "1" or "0",
        tostring(weapon_name or "*"),
    }, ":")

    if sig == M._last_sig and M._applied then
        return true, 0, "unchanged"
    end

    for name, entry in pairs(toolinfo) do
        if type(entry) == "table" and type(entry.Weapon) == "table" then
            restore_weapon(entry.Weapon, baseline_weapon(name))
        end
    end

    local count = 0
    if weapon_name then
        local live_w = weapon_entry(toolinfo, weapon_name)
        if apply_weapon(live_w, baseline_weapon(weapon_name), opts) then
            count = 1
        end
    else
        for name, entry in pairs(toolinfo) do
            if type(entry) == "table" and type(entry.Weapon) == "table" then
                if apply_weapon(entry.Weapon, baseline_weapon(name), opts) then
                    count = count + 1
                end
            end
        end
    end

    M._applied = count > 0 or any
    M._last_sig = sig
    return true, count, string.format("%d weapon(s) patched", count)
end

return M
