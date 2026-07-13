--[[
  Fallen Fullbright — standalone Vector test script (NVG only)
  Load directly in Vector (not april.lua).

  F6 = toggle fullbright
  Console prefix: [fullbright]

  Target NVG state:
    Enabled=true, Brightness=0.2, Contrast=0, Saturation=1, TintColor=188,188,188
]]

local ENABLED = false
local VK_TOGGLE = 0x75 -- F6

local TARGET = {
    enabled = true,
    brightness = 0.2,
    contrast = 0,
    saturation = 1,
    tint_rgb = { 188, 188, 188 },
}

local saved = nil
local was_on = false
local frame = 0
local last_log = 0
local f6_down = false

local function log(msg)
    print("[fullbright] " .. tostring(msg))
end

local function safe(fn, ...)
    local ok, res = pcall(fn, ...)
    if ok then return res end
    return nil
end

local function inst_name(inst)
    return safe(function() return inst.Name or inst.name end)
end

local function get_lighting()
    if not game then return nil, "no game" end
    local lit = safe(function() return game.lighting end)
    if lit then return lit, "game.lighting" end
    lit = safe(function() return game.Lighting end)
    if lit then return lit, "game.Lighting" end
    lit = safe(function() return game.get_service and game.get_service("Lighting") end)
    if lit then return lit, "get_service" end
    local ws = safe(function() return game.workspace end)
    if ws then
        local p = safe(function() return ws.Parent or ws.parent end)
        if p and p.find_first_child then
            lit = safe(function() return p:find_first_child("Lighting") end)
            if lit then return lit, "workspace.Parent" end
        end
    end
    if game.get_children then
        local kids = safe(function() return game:get_children() end)
        if type(kids) == "table" then
            for _, c in ipairs(kids) do
                if inst_name(c) == "Lighting" then return c, "game:get_children" end
            end
        end
    end
    return nil, "not found"
end

local function find_nvg(lit)
    if not lit then return nil end
    local nvg = safe(function()
        if lit.find_first_child then return lit:find_first_child("NVG") end
        if lit.FindFirstChild then return lit:FindFirstChild("NVG") end
    end)
    if nvg then return nvg end
    local kids = safe(function()
        if lit.get_children then return lit:get_children() end
        if lit.GetChildren then return lit:GetChildren() end
    end)
    if type(kids) ~= "table" then return nil end
    for _, c in ipairs(kids) do
        if inst_name(c) == "NVG" then return c end
    end
end

local function read_tint(inst)
    local t = safe(function() return inst.TintColor or inst.tint_color end)
    if type(t) ~= "table" then return "nil" end
    local r = t.R or t.r or t[1] or 0
    local g = t.G or t.g or t[2] or 0
    local b = t.B or t.b or t[3] or 0
    return string.format("%.3f,%.3f,%.3f", r, g, b)
end

local function read_state(inst)
    return {
        enabled = safe(function() return inst.Enabled or inst.enabled end),
        brightness = safe(function() return inst.Brightness or inst.brightness end),
        contrast = safe(function() return inst.Contrast or inst.contrast end),
        saturation = safe(function() return inst.Saturation or inst.saturation end),
        tint = safe(function() return inst.TintColor or inst.tint_color end),
    }
end

local function write_prop(inst, keys, value)
    for _, k in ipairs(keys) do
        pcall(function() inst[k] = value end)
    end
    for _, k in ipairs(keys) do
        local after = safe(function() return inst[k] end)
        if after ~= nil then
            return true, k, after, nil
        end
    end
    return true, keys[1], nil, nil
end

local function write_tint(inst, rgb)
    local r, g, b = rgb[1], rgb[2], rgb[3]
    local tries = {
        { { "TintColor", "tint_color" }, { r / 255, g / 255, b / 255 } },
        { { "TintColor", "tint_color" }, { R = r / 255, G = g / 255, B = b / 255 } },
    }
    for i = 1, #tries do
        write_prop(inst, tries[i][1], tries[i][2])
    end
end

local function apply_on(inst)
    write_prop(inst, { "Brightness", "brightness" }, TARGET.brightness)
    write_prop(inst, { "Contrast", "contrast" }, TARGET.contrast)
    write_prop(inst, { "Saturation", "saturation" }, TARGET.saturation)
    write_tint(inst, TARGET.tint_rgb)
    return write_prop(inst, { "Enabled", "enabled" }, TARGET.enabled)
end

local function restore(inst, snap)
    if not snap then return end
    if snap.enabled ~= nil then write_prop(inst, { "Enabled", "enabled" }, snap.enabled) end
    if snap.brightness ~= nil then write_prop(inst, { "Brightness", "brightness" }, snap.brightness) end
    if snap.contrast ~= nil then write_prop(inst, { "Contrast", "contrast" }, snap.contrast) end
    if snap.saturation ~= nil then write_prop(inst, { "Saturation", "saturation" }, snap.saturation) end
end

local function dump_children(lit)
    local kids = safe(function()
        if lit.get_children then return lit:get_children() end
    end)
    if type(kids) ~= "table" then return end
    local parts = {}
    for _, c in ipairs(kids) do
        parts[#parts + 1] = tostring(inst_name(c))
    end
    log("Lighting children: " .. table.concat(parts, ", "))
end

local function probe(verbose)
    local lit, src = get_lighting()
    log("lighting ok=" .. tostring(lit ~= nil) .. " src=" .. tostring(src))
    if not lit then return end
    if verbose then dump_children(lit) end
    local inst = find_nvg(lit)
    log("NVG ok=" .. tostring(inst ~= nil) .. " class="
        .. tostring(safe(function() return inst and (inst.ClassName or inst.class_name) end))
        .. " addr=" .. tostring(safe(function() return inst and (inst.Address or inst.address) end)))
    if not inst then return end
    local st = read_state(inst)
    log(string.format("state enabled=%s bright=%s contrast=%s sat=%s tint=%s",
        tostring(st.enabled), tostring(st.brightness), tostring(st.contrast),
        tostring(st.saturation), read_tint(inst)))
    if verbose then
        apply_on(inst)
        st = read_state(inst)
        log(string.format("post enabled=%s bright=%s contrast=%s sat=%s tint=%s",
            tostring(st.enabled), tostring(st.brightness), tostring(st.contrast),
            tostring(st.saturation), read_tint(inst)))
    end
end

local function set_enabled(on)
    ENABLED = on and true or false
    log("toggle -> " .. tostring(ENABLED))
    if not ENABLED and was_on then
        local lit = get_lighting()
        local inst = lit and find_nvg(lit) or nil
        if inst and saved then restore(inst, saved) end
        was_on = false
        saved = nil
    end
    if ENABLED then probe(true) end
end

function on_frame()
    frame = frame + 1

    if input and input.is_key_down then
        local down = input.is_key_down(VK_TOGGLE)
        if down and not f6_down then set_enabled(not ENABLED) end
        f6_down = down
    end

    if not ENABLED then return end

    local lit = get_lighting()
    local inst = lit and find_nvg(lit) or nil
    if not inst then
        if frame % 120 == 1 then log("waiting for Lighting.NVG...") end
        return
    end

    if not was_on then
        saved = read_state(inst)
        was_on = true
        probe(true)
    end

    apply_on(inst)

    local now = utility and utility.get_tick_count and utility.get_tick_count() or frame
    if (now - last_log) > 3000 then
        last_log = now
        probe(true)
    end
end

log("loaded — press F6 to toggle fullbright (NVG only)")
