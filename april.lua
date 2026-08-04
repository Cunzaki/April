--[[
    April Fallen - Fallen Survival for Project Vector
    https://github.com/Cunzaki/April
    Built: 2026-08-04T03:45:53.619Z
    UI: custom Gamesense menu (INSERT) - Vector menu tabs disabled
]]

April = {
    version = "4.0.68",
    debug = false,
    crash_logging = false,
    -- Set true only while hunting native crashes (writes dense STEP breadcrumbs).
    crash_trace = false,
    -- Targeted file trace for Autofarm native-crash diagnosis.
    autofarm_trace = true,
    _mods = {},
    load_status = {
        { name = "Core", state = "loaded" },
        { name = "Services", state = "loaded" },
        { name = "Game Data", state = "loaded" },
        { name = "Features", state = "loaded" },
        { name = "Interface", state = "loaded" },
    },
    bundled = true,
    custom_ui = true,
}

April._menu_tab_ready = true

function April.require(path)
    local mod = April._mods[path]
    if mod == nil then
        error("[April] bundled module missing: " .. path)
    end
    return mod
end


April.bundled = false
April.load_status = {
    { name = "Core", state = "pending" },
    { name = "Services", state = "pending" },
    { name = "Game Data", state = "pending" },
    { name = "Features", state = "pending" },
    { name = "Interface", state = "pending" },
}

local chunks = {
    "https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/chunks/01-core.lua?v=4.0.68",
    "https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/chunks/02-services.lua?v=4.0.68",
    "https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/chunks/03-game.lua?v=4.0.68",
    "https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/chunks/04-features.lua?v=4.0.68",
    "https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/chunks/05-interface.lua?v=4.0.68",
}

for index = 1, #chunks do
    local status = April.load_status[index]
    status.state = "loading"
    local ok, err = utility.LoadUrl(chunks[index])
    if not ok then
        status.state = "failed"
        status.error = tostring(err)
        error("[April] Failed to load " .. status.name .. ": " .. tostring(err))
    end
    status.state = "loaded"
end
