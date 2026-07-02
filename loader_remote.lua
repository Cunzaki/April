--[[
    April — remote bootstrap (GitHub raw)
    Fetches each module over HTTP via utility.http_get + loadstring.
]]

if menu and menu.add_tab then
    menu.add_tab("April", "A", "full")
end

April = April or {
    version = "3.0.0",
    TAB = "April",
    repo = "https://raw.githubusercontent.com/Cunzaki/April/main/",
    debug = false,
    _mods = {},
    remote = true,
}

function April.require(path)
    if April._mods[path] then return April._mods[path] end
    local url = April.repo .. path:gsub("%.", "/") .. ".lua"
    local body, status = utility.http_get(url)
    if not body or status ~= 200 then
        error("[April] fetch failed: " .. url .. " — " .. tostring(status))
    end
    local fn, err = loadstring(body, "@" .. path)
    if not fn then
        error("[April] compile failed: " .. path .. " — " .. tostring(err))
    end
    local mod = fn()
    April._mods[path] = mod
    return mod
end

local ok, err = pcall(function()
    local app = April.require("app")
    if not app.init() then return end

    function on_frame()
        app.on_frame()
    end

    if callbacks and callbacks.add then
        callbacks.add("on_frame", on_frame)
    elseif draw and draw.callback then
        draw.callback = on_frame
    end
end)

if not ok then
    print("[April] Fatal: " .. tostring(err))
end
