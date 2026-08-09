local tabs = April.require("menu.tabs")
local debug = April.require("core.debug")
local notify = April.require("core.notify")
local custom_menu = April.require("ui.custom_menu")
local startup_intro = April.require("ui.startup_intro")
local api_aliases = April.require("core.api_aliases")
local feature_bind = April.require("core.feature_bind")
local aim_key = April.require("core.aim_key")
local overlay_theme = April.require("core.overlay_theme")
local settings = April.require("core.settings")

local M = {}
local initialized = false
local alias_refresh_elapsed = 0

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
    settings.begin_frame(debug.frame_count())

    pcall(feature_bind.tick)
    pcall(aim_key.tick, "april_aim_key", "april_aim_key_mode")

    if startup_intro.is_active() then
        if startup_intro.should_reveal_menu() then
            debug.guard_fast("custom_menu.draw:intro", custom_menu.draw)
        end
        local ok = pcall(startup_intro.draw)
        if ok then
            return
        end
        startup_intro.cancel()
    end

    local dt = 0.016
    if utility and utility.get_delta_time then
        local ok, v = pcall(utility.get_delta_time)
        if ok and type(v) == "number" then dt = v end
    end
    alias_refresh_elapsed = alias_refresh_elapsed + dt
    if alias_refresh_elapsed >= 2 then
        alias_refresh_elapsed = 0
        pcall(api_aliases.apply)
    end

    debug.guard_fast("tabs.update", tabs.update, dt)
    debug.guard_fast("overlay_theme.sync", overlay_theme.sync)
    debug.guard_fast("tabs.draw", tabs.draw)
    debug.guard_fast("notify.draw", notify.draw)
    debug.guard_fast("custom_menu.draw", custom_menu.draw)
end

return M
