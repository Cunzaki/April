-- Anti-AFK: Roblox kicks ~20m idle. Nudge input every 14m while enabled.

local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_anti_afk"

-- Stay under Roblox's ~20 minute idle kick.
local INTERVAL_MS = 14 * 60 * 1000

M._last_nudge = 0

local function now_ms()
    if utility and utility.get_tick_count then
        return utility.get_tick_count()
    end
    return math.floor(os.clock() * 1000)
end

local function nudge()
    -- Prefer a tiny mouse wiggle (doesn't fire weapons). Fall back to space tap.
    if input and input.move_mouse then
        pcall(input.move_mouse, 1, 0)
        pcall(input.move_mouse, -1, 0)
        return true
    end
    if utility and utility.key_press then
        pcall(utility.key_press, 0x20) -- space
        return true
    end
    if utility and utility.mouse_click then
        -- Last resort; avoid if possible (can shoot).
        return false
    end
    return false
end

function M.register_menu()
    local G = menu_util.G
    local T = menu_util.group(G.MISC)
    menu.add_checkbox(T, G.MISC, P, "Anti AFK", false)
end

function M.update(_dt)
    if not settings.bool(P, false) then
        M._last_nudge = 0
        return
    end

    local now = now_ms()
    if M._last_nudge == 0 then
        M._last_nudge = now
        return
    end
    if (now - M._last_nudge) < INTERVAL_MS then
        return
    end
    M._last_nudge = now
    nudge()
end

function M.draw() end

return M
