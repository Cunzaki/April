-- Misc → Fullbright (Lighting.NVG only — no other lighting writes).

local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local nvg = April.require("game.nvg_lighting")
local draw_util = April.require("core.draw_util")

local M = {}
local P = "april_fullbright"
local P_LOG = "april_fullbright_log"
local P_HUD = "april_fullbright_hud"

M._saved = nil
M._was_on = false
M._thread = nil
M._probe_at = 0
M._hud_lines = {}

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function verbose()
    return settings.bool(P_LOG, true)
end

local function stop_thread()
    if M._thread and thread and thread.stop then
        pcall(thread.stop, M._thread)
    end
    M._thread = nil
end

local function start_thread()
    if M._thread or not thread or not thread.create then return end
    M._thread = thread.create(function()
        if not settings.bool(P, false) then return end
        nvg.apply_with_log(false)
    end, 33)
end

local function capture_saved(inst)
    return nvg.read_state(inst)
end

function M.register_menu()
    local G = menu_util.G
    local T = menu_util.group(G.MISC)
    menu_util.section(T, G.MISC, "Render")
    menu.add_checkbox(T, G.MISC, P, "Fullbright", false)
    menu.add_checkbox(T, G.MISC, P_LOG, "Fullbright Debug Log", true)
    menu.add_checkbox(T, G.MISC, P_HUD, "Fullbright Debug HUD", true)
end

function M.update(_dt)
    local on = settings.bool(P, false)

    if not on then
        nvg.set_active(false)
        if M._was_on then
            local inst = select(1, nvg.resolve_nvg())
            if inst and M._saved then
                nvg.restore(inst, M._saved)
                if verbose() then nvg.log("restored NVG") end
            end
        end
        M._was_on = false
        M._saved = nil
        M._hud_lines = {}
        stop_thread()
        return
    end

    if not M._was_on then
        M._was_on = true
        nvg.set_active(true)
        local lit, inst = nvg.probe(verbose())
        if inst then
            M._saved = capture_saved(inst)
        end
        start_thread()
        if verbose() then
            nvg.log("toggle ON menu.get=" .. tostring(settings.get(P, false)))
        end
    end

    local now = tick_ms()
    if verbose() and (now - M._probe_at) > 3000 then
        M._probe_at = now
        nvg.apply_with_log(true)
    else
        nvg.apply_with_log(false)
    end

    local st = nvg.status()
    M._hud_lines = {
        "Fullbright ON",
        "Lighting: " .. tostring(st.lighting_ok) .. " (" .. tostring(st.lighting_src) .. ")",
        "NVG: " .. tostring(st.nvg_ok) .. " " .. tostring(st.nvg_class or ""),
        "addr: " .. tostring(st.nvg_addr or "—"),
    }
    local w = st.writes
    if w and w.enabled then
        M._hud_lines[#M._hud_lines + 1] = "Enabled write: " .. tostring(w.enabled.ok) .. " after=" .. tostring(w.enabled.after)
    end
    if st.lighting_children then
        M._hud_lines[#M._hud_lines + 1] = "children: " .. tostring(#st.lighting_children)
    end
    local logs = nvg.logs()
    if logs[#logs] then
        M._hud_lines[#M._hud_lines + 1] = logs[#logs]
    end
end

function M.draw()
    if not settings.bool(P, false) or not settings.bool(P_HUD, true) then return end
    if not draw or not draw.text then return end

    local x, y = 12, 120
    local col = { 0.45, 1, 0.75, 1 }
    for i, line in ipairs(M._hud_lines) do
        draw_util.text(x, y + (i - 1) * 14, line, col, 1)
    end
end

return M
