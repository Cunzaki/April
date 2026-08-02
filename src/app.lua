local tabs = April.require("menu.tabs")
local debug = April.require("core.debug")
local notify = April.require("core.notify")
local custom_menu = April.require("ui.custom_menu")
local startup_intro = April.require("ui.startup_intro")

local M = {}
local initialized = false

function M.init()
    if initialized then return true end
    pcall(function()
        April.require("core.entity_props").ensure_api_aliases()
    end)
    initialized = tabs.init()
    if initialized then
        pcall(custom_menu.init)
        pcall(startup_intro.init)
    end
    return initialized
end

function M.on_frame()
    if not initialized then return end
    debug.tick_frame()

    pcall(function()
        April.require("core.api_aliases").apply()
    end)
    if startup_intro.is_active() then
        -- Reveal the fully initialized menu beneath the final black fade so it
        -- appears as part of the intro instead of popping in afterward.
        if startup_intro.should_reveal_menu() then
            debug.guard("custom_menu.draw:intro", custom_menu.draw)
        end
        local ok, err = pcall(startup_intro.draw)
        if ok then return end
        -- A splash failure must never lock the user out of the menu.
        startup_intro.cancel()
        debug.error_once("startup_intro", err)
    end
    pcall(function()
        April.require("core.feature_bind").tick()
    end)
    pcall(function()
        April.require("core.aim_key").tick("april_aim_key", "april_aim_key_mode")
    end)

    local dt = 0.016
    if utility and utility.get_delta_time then
        dt = utility.get_delta_time()
    end

    debug.guard("tabs.update", tabs.update, dt)
    debug.guard("overlay_theme.sync", April.require("core.overlay_theme").sync)
    debug.guard("tabs.draw", tabs.draw)
    debug.guard("notify.draw", notify.draw)
    debug.guard("custom_menu.draw", custom_menu.draw)
end

return M
