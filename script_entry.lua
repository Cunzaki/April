--[[
    Paste this entire file into Vector as your script (e.g. Script 1.lua).
    Do NOT use a bare utility.load_url() one-liner — Vector needs menu.add_tab
    with mode "full" in the executed script file for options to appear.
]]

if menu and menu.add_tab then
    menu.add_tab("April", "A", "full")
end

local ok, err = utility.load_url("https://raw.githubusercontent.com/cunzaki/April/main/loader_remote.lua")
if not ok then
    print("[April] load_url failed: " .. tostring(err))
end
