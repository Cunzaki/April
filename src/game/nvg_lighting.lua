-- Fallen Lighting.NVG resolver + apply (NVG ColorCorrectionEffect only).

local env = April.require("core.env")

local M = {}

M.TARGET = {
    enabled = true,
    brightness = 0.2,
    contrast = 0,
    saturation = 1,
    tint_rgb = { 188, 188, 188 },
}

M._logs = {}
M._active = false
M._hooked = false
M._status = {
    lighting_src = nil,
    lighting_ok = false,
    nvg_ok = false,
    nvg_class = nil,
    nvg_addr = nil,
    last_apply_ms = 0,
    writes = {},
    lighting_children = nil,
}

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.log(msg, force)
    msg = tostring(msg)
    M._logs[#M._logs + 1] = msg
    if #M._logs > 24 then
        table.remove(M._logs, 1)
    end
    if force ~= false then
        print("[April NVG] " .. msg)
    end
end

function M.logs()
    return M._logs
end

function M.status()
    return M._status
end

function M.set_active(on)
    M._active = on and true or false
    if M._active then
        M.ensure_hooks()
    end
end

function M.ensure_hooks()
    if M._hooked or not game then return end
    local rs = env.safe_call(function()
        return game.get_service and game.get_service("RunService")
    end)
    if not rs then return end

    for _, name in ipairs({ "RenderStepped", "render_stepped", "Heartbeat", "heartbeat" }) do
        local ev = rs[name]
        if ev and ev.Connect then
            local hooked = env.safe_call(function()
                ev:Connect(function()
                    if not M._active then return end
                    local inst = select(1, M.resolve_nvg())
                    if inst then M.apply(inst) end
                end)
                return true
            end)
            if hooked then
                M._hooked = true
                M.log("hooked RunService." .. name)
                return
            end
        end
    end
end

local function mem_patch_float(base, expect, newv, span)
    if not memory or type(memory.read) ~= "function" or type(memory.write) ~= "function" then
        return false
    end
    base = tonumber(base) or 0
    if base <= 0 then return false end
    span = span or 0x300
    for off = 0, span, 4 do
        local addr = base + off
        local v = memory.read(addr, "float")
        if type(v) == "number" and math.abs(v - expect) < 0.02 then
            pcall(memory.write, addr, "float", newv)
            local v2 = memory.read(addr, "float")
            if type(v2) == "number" and math.abs(v2 - newv) < 0.02 then
                M.log("mem float patch off=0x" .. string.format("%X", off) .. " " .. expect .. "->" .. newv)
                return true
            end
        end
    end
    return false
end

function M.mem_fallback(nvg, before)
    if not nvg or not before then return false end
    local addr = inst_addr(nvg)
    if not addr or addr == 0 then return false end
    local patched = false
    if type(before.brightness) == "number" then
        patched = mem_patch_float(addr, before.brightness, M.TARGET.brightness) or patched
    end
    if type(before.saturation) == "number" then
        patched = mem_patch_float(addr, before.saturation, M.TARGET.saturation) or patched
    end
    return patched
end

local function inst_name(inst)
    return env.safe_call(function() return inst.Name or inst.name end)
end

local function inst_class(inst)
    return env.safe_call(function() return inst.ClassName or inst.class_name end)
end

local function inst_addr(inst)
    return env.safe_call(function() return inst.Address or inst.address end)
end

function M.get_lighting()
    if not game then return nil, "no game" end

    local lit = env.safe_call(function() return game.lighting end)
    if lit then return lit, "game.lighting" end

    lit = env.safe_call(function() return game.Lighting end)
    if lit then return lit, "game.Lighting" end

    lit = env.safe_call(function() return game.get_service and game.get_service("Lighting") end)
    if lit then return lit, "get_service(Lighting)" end

    local ws = env.safe_call(function() return game.workspace end)
    if ws then
        local parent = env.safe_call(function() return ws.Parent or ws.parent end)
        if parent then
            lit = env.safe_call(function()
                if parent.find_first_child then
                    return parent:find_first_child("Lighting")
                end
            end)
            if lit then return lit, "workspace.Parent:find_first_child" end
        end
    end

    if env.safe_call(function() return game.get_children end) then
        local kids = env.safe_call(function() return game:get_children() end)
        if type(kids) == "table" then
            for _, c in ipairs(kids) do
                if inst_name(c) == "Lighting" then
                    return c, "game:get_children"
                end
            end
        end
    end

    if env.safe_call(function() return game.find_first_child end) then
        lit = env.safe_call(function() return game:find_first_child("Lighting") end)
        if lit then return lit, "game:find_first_child" end
    end

    return nil, "not found"
end

local function list_lighting_children(lit)
    local names = {}
    local kids = env.safe_call(function()
        if lit.get_children then return lit:get_children() end
        if lit.GetChildren then return lit:GetChildren() end
    end)
    if type(kids) ~= "table" then return names end
    for _, c in ipairs(kids) do
        names[#names + 1] = tostring(inst_name(c)) .. ":" .. tostring(inst_class(c))
    end
    return names
end

function M.find_nvg(lit)
    if not lit then return nil end

    local nvg = env.safe_call(function()
        if lit.find_first_child then return lit:find_first_child("NVG") end
        if lit.FindFirstChild then return lit:FindFirstChild("NVG") end
    end)
    if nvg then return nvg end

    nvg = env.safe_call(function()
        if lit.find_first_child then return lit:find_first_child("NVG", true) end
    end)
    if nvg then return nvg end

    local kids = env.safe_call(function()
        if lit.get_children then return lit:get_children() end
        if lit.GetChildren then return lit:GetChildren() end
    end)
    if type(kids) == "table" then
        for _, c in ipairs(kids) do
            if inst_name(c) == "NVG" then return c end
        end
        for _, c in ipairs(kids) do
            if inst_class(c) == "ColorCorrectionEffect" and inst_name(c) == "NVG" then
                return c
            end
        end
    end

    local desc = env.safe_call(function()
        if lit.get_descendants then return lit:get_descendants() end
    end)
    if type(desc) == "table" then
        for _, c in ipairs(desc) do
            if inst_name(c) == "NVG" then return c end
        end
    end

    return env.safe_call(function()
        if lit.find_first_child_of_class then
            local cc = lit:find_first_child_of_class("ColorCorrectionEffect")
            if cc and inst_name(cc) == "NVG" then return cc end
        end
    end)
end

local function read_prop(inst, keys)
    for _, k in ipairs(keys) do
        local v = env.safe_call(function() return inst[k] end)
        if v ~= nil then return v, k end
    end
    return nil, nil
end

local function fmt_tint(t)
    if type(t) ~= "table" then return "nil" end
    local r = t.R or t.r or t[1]
    local g = t.G or t.g or t[2]
    local b = t.B or t.b or t[3]
    if not r then return "table?" end
    return string.format("%.3f,%.3f,%.3f", r, g, b)
end

function M.read_state(nvg)
    if not nvg then return nil end
    return {
        enabled = select(1, read_prop(nvg, { "Enabled", "enabled" })),
        brightness = select(1, read_prop(nvg, { "Brightness", "brightness" })),
        contrast = select(1, read_prop(nvg, { "Contrast", "contrast" })),
        saturation = select(1, read_prop(nvg, { "Saturation", "saturation" })),
        tint = select(1, read_prop(nvg, { "TintColor", "tint_color" })),
    }
end

local function write_prop(inst, keys, value)
    local result = { keys = keys, wanted = value, ok = false, err = nil, before = nil, after = nil, key = nil }
    result.before = select(1, read_prop(inst, keys))

    for _, k in ipairs(keys) do
        pcall(function()
            inst[k] = value
        end)
    end

    local after, key = read_prop(inst, keys)
    result.after = after
    result.key = key
    result.ok = after == value or (type(value) == "boolean" and after == value)
        or (type(value) == "number" and type(after) == "number" and math.abs(after - value) < 0.001)
    if not result.ok and result.before == nil and after == nil then
        -- ponytail: Vector may not mirror writes back on read; treat silent pcall as ok.
        local any_ok = false
        for _, k in ipairs(keys) do
            local ok = select(1, pcall(function() inst[k] = value end))
            if ok then any_ok = true end
        end
        result.ok = any_ok
    end
    return result
end

local function write_tint(inst, rgb)
    local r, g, b = rgb[1], rgb[2], rgb[3]
    local attempts = {
        { { "TintColor", "tint_color" }, { r / 255, g / 255, b / 255 } },
        { { "TintColor", "tint_color" }, { R = r / 255, G = g / 255, B = b / 255 } },
        { { "TintColor", "tint_color" }, { r, g, b } },
    }
    for i = 1, #attempts do
        local keys, val = attempts[i][1], attempts[i][2]
        local res = write_prop(inst, keys, val)
        if res.ok then return res end
    end
    return { ok = false, err = "TintColor write failed" }
end

function M.apply(nvg, target)
    target = target or M.TARGET
    local writes = {}

    writes.brightness = write_prop(nvg, { "Brightness", "brightness" }, target.brightness)
    writes.contrast = write_prop(nvg, { "Contrast", "contrast" }, target.contrast)
    writes.saturation = write_prop(nvg, { "Saturation", "saturation" }, target.saturation)
    writes.tint = write_tint(nvg, target.tint_rgb)
    writes.enabled = write_prop(nvg, { "Enabled", "enabled" }, target.enabled)

    M._status.writes = writes
    M._status.last_apply_ms = tick_ms()
    return writes
end

function M.restore(nvg, saved)
    if not nvg or not saved then return end
    if saved.enabled ~= nil then
        write_prop(nvg, { "Enabled", "enabled" }, saved.enabled)
    end
    if saved.brightness ~= nil then
        write_prop(nvg, { "Brightness", "brightness" }, saved.brightness)
    end
    if saved.contrast ~= nil then
        write_prop(nvg, { "Contrast", "contrast" }, saved.contrast)
    end
    if saved.saturation ~= nil then
        write_prop(nvg, { "Saturation", "saturation" }, saved.saturation)
    end
    if saved.tint ~= nil then
        write_tint(nvg, {
            math.floor((saved.tint[1] or saved.tint.R or saved.tint.r or 1) * 255 + 0.5),
            math.floor((saved.tint[2] or saved.tint.G or saved.tint.g or 1) * 255 + 0.5),
            math.floor((saved.tint[3] or saved.tint.B or saved.tint.b or 1) * 255 + 0.5),
        })
    end
end

function M.resolve_nvg()
    local lit, lit_src = M.get_lighting()
    if lit then
        local nvg = M.find_nvg(lit)
        if nvg then return nvg, "lighting:" .. tostring(lit_src) end
    end

    local desc = env.safe_call(function()
        if game.get_descendants then return game:get_descendants() end
    end)
    if type(desc) == "table" then
        for _, inst in ipairs(desc) do
            if inst_name(inst) == "NVG" and inst_class(inst) == "ColorCorrectionEffect" then
                return inst, "game:get_descendants"
            end
        end
        for _, inst in ipairs(desc) do
            if inst_name(inst) == "NVG" then
                return inst, "game:get_descendants(name)"
            end
        end
    end

    return nil, "not found"
end

function M.probe(verbose)
    local lit, src = M.get_lighting()
    M._status.lighting_src = src
    M._status.lighting_ok = lit ~= nil
    M._status.lighting_children = lit and list_lighting_children(lit) or nil

    local nvg, nvg_src = M.resolve_nvg()
    M._status.nvg_ok = nvg ~= nil
    M._status.nvg_class = nvg and inst_class(nvg) or nil
    M._status.nvg_addr = nvg and inst_addr(nvg) or nil

    if verbose then
        M.log("lighting=" .. tostring(lit ~= nil) .. " src=" .. tostring(src))
        if lit and M._status.lighting_children then
            M.log("Lighting children: " .. table.concat(M._status.lighting_children, " | "))
        end
        M.log("NVG=" .. tostring(nvg ~= nil) .. " via=" .. tostring(nvg_src)
            .. " class=" .. tostring(M._status.nvg_class)
            .. " addr=" .. tostring(M._status.nvg_addr))
        if nvg then
            local st = M.read_state(nvg)
            M.log(string.format("before enabled=%s bright=%s contrast=%s sat=%s tint=%s",
                tostring(st.enabled), tostring(st.brightness), tostring(st.contrast),
                tostring(st.saturation), fmt_tint(st.tint)))
        end
    end

    return lit, nvg
end

function M.apply_with_log(verbose)
    local lit, nvg = M.probe(verbose)
    if not nvg then
        M.log("FAIL: Lighting.NVG not found (lighting=" .. tostring(lit ~= nil) .. ")")
        return false, "no nvg"
    end

    local before = M.read_state(nvg)
    local writes = M.apply(nvg)
    local after = M.read_state(nvg)

    local stuck = false
    if type(before.brightness) == "number" and type(after.brightness) == "number" then
        if math.abs(after.brightness - M.TARGET.brightness) > 0.02 then
            stuck = true
        end
    elseif writes.enabled and not writes.enabled.ok then
        stuck = true
    end

    if stuck then
        local mem_ok = M.mem_fallback(nvg, before)
        if mem_ok then
            M.log("used memory fallback for NVG floats")
        elseif verbose then
            M.log("WARN: NVG props may not stick via instance API")
        end
    end
    if verbose then
        for k, w in pairs(writes) do
            if type(w) == "table" then
                M.log(string.format("write %s key=%s ok=%s before=%s after=%s err=%s",
                    k, tostring(w.key), tostring(w.ok), tostring(w.before), tostring(w.after), tostring(w.err)))
            end
        end
        local st = M.read_state(nvg)
        M.log(string.format("after enabled=%s bright=%s contrast=%s sat=%s tint=%s",
            tostring(st.enabled), tostring(st.brightness), tostring(st.contrast),
            tostring(st.saturation), fmt_tint(st.tint)))
    end

    local ok = writes.enabled and writes.enabled.ok
    if not ok then
        M.log("WARN: Enabled write may have failed — Vector might not expose ColorCorrection props")
    end
    return true
end

if April and not April.bundled then
    assert(M.TARGET.brightness == 0.2 and M.TARGET.tint_rgb[1] == 188)
end

return M
