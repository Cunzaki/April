--[[
    April — local bootstrap loader
    Vector binds script menu UI to a tab registered with mode "full".
    Place this repo under Vector Scripts/April/, then Load Script -> loader.lua
]]

if menu and menu.add_tab then
    menu.add_tab("April", "A", "full")
end

April = April or {
    version = "3.0.0",
    TAB = "April",
    script_dir = "",
    debug = false,
    _mods = {},
    remote = false,
}

local function resolve_path(rel)
    local file = rel:gsub("%.", "/") .. ".lua"
    local dirs = {
        April.script_dir,
        "",
        "./",
        "April/",
        "./April/",
    }
    for _, dir in ipairs(dirs) do
        local path = dir .. file
        local f = io.open(path, "r")
        if f then
            f:close()
            return path
        end
    end
    return file
end

function April.require(path)
    if April._mods[path] then return April._mods[path] end
    local filepath = resolve_path(path)
    local fn, err = loadfile(filepath)
    if not fn then
        error("[April] load failed: " .. filepath .. " — " .. tostring(err))
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
