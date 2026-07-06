--[[
    April loader — paste this short script into Vector instead of the full bundle.
    Fetches the latest april.lua from GitHub and runs it via utility.load_url.
]]

local BRANCH = "main"
local URL = "https://raw.githubusercontent.com/Cunzaki/April/refs/heads/" .. BRANCH .. "/april.lua"

if not utility or not utility.load_url then
    print("[April] utility.load_url is not available in this Vector build")
    return
end

print("[April] Loading from GitHub (" .. BRANCH .. ")...")
local ok, err = utility.load_url(URL)
if ok then
    print("[April] Loaded successfully")
else
    print("[April] Load failed: " .. tostring(err))
    print("[April] URL: " .. URL)
end
