-- Deprecated: custom UI is now built into april.lua.
-- Use load.lua / april.lua instead (INSERT toggles the Gamesense menu).

print("[April UI] Custom UI is part of april.lua now — use load.lua")
local URL = "https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/april.lua"
local load_fn = utility and (utility.load_url or utility.LoadUrl or utility.loadurl)
if load_fn then
    load_fn(URL)
end
