local tabs = April.require("menu.tabs")
local debug = April.require("core.debug")
local notify = April.require("core.notify")
local custom_menu = April.require("ui.custom_menu")
local startup_intro = April.require("ui.startup_intro")
local api_aliases = April.require("core.api_aliases")
local feature_bind = April.require("core.feature_bind")
local aim_key = April.require("core.aim_key")
local overlay_theme = April.require("core.overlay_theme")

local M = {}
local initialized = false
local first_post_intro = true
local alias_refresh_elapsed = 0

function M.init()
    debug.step("app.init")
    if initialized then return true end
    pcall(function()
        April.require("core.entity_props").ensure_api_aliases()
    end)
    debug.step("app.init.tabs")
    initialized = tabs.init()
    if initialized then
        debug.step("app.init.custom_menu")
        pcall(custom_menu.init)
        debug.step("app.init.startup_intro")
        pcall(startup_intro.init)
    end
    debug.file("app.init done ok=" .. tostring(initialized))
    return initialized
end

function M.on_frame()
    if not initialized then return end
    debug.tick_frame()
    local fc = debug.frame_count()
    -- Dense breadcrumbs for the first frames and the first post-intro frame.
    local dense = fc <= 8 or first_post_intro
    if dense then
        debug.step("frame:" .. tostring(fc) .. ".begin")
    end

    pcall(feature_bind.tick)
    pcall(aim_key.tick, "april_aim_key", "april_aim_key_mode")

    if startup_intro.is_active() then
        if dense then debug.step("frame.intro.active") end
        if startup_intro.should_reveal_menu() then
            debug.guard("custom_menu.draw:intro", custom_menu.draw)
        end
        local ok, err = pcall(startup_intro.draw)
        if ok then
            if dense then debug.step_done("frame.intro") end
            return
        end
        startup_intro.cancel()
        debug.error_once("startup_intro", err)
    elseif first_post_intro then
        first_post_intro = false
        debug.file("POST_INTRO first normal frame fc=" .. tostring(fc))
    end

    local dt = 0.016
    if utility and utility.get_delta_time then
        local ok, v = pcall(utility.get_delta_time)
        if ok and type(v) == "number" then dt = v end
    end
    -- API tables are stable after boot. Keep a slow refresh for late-provided
    -- capabilities without repeating dozens of alias checks every render frame.
    alias_refresh_elapsed = alias_refresh_elapsed + dt
    if alias_refresh_elapsed >= 2 then
        alias_refresh_elapsed = 0
        pcall(api_aliases.apply)
    end

    debug.guard("tabs.update", tabs.update, dt)
    debug.guard("overlay_theme.sync", overlay_theme.sync)
    debug.guard("tabs.draw", tabs.draw)
    debug.guard("notify.draw", notify.draw)
    debug.guard("custom_menu.draw", custom_menu.draw)

    if dense then
        debug.step_done("frame:" .. tostring(fc))
    end
end

return M
