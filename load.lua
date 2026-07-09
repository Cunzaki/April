-- Load April (local bundled file first, then GitHub).
local REMOTE_URL = "https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/april.lua"

local LOCAL_PATHS = {
    "april.lua",
    "April Fallen/april.lua",
    "April/april.lua",
}

local function try_load_local()
    if not loadfile then
        return false
    end

    for i = 1, #LOCAL_PATHS do
        local fn = loadfile(LOCAL_PATHS[i])
        if fn then
            fn()
            return true
        end
    end

    return false
end

if not try_load_local() then
    utility.load_url(REMOTE_URL)
end
