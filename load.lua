-- April loader — paste this into Vector as "Script 1.lua" (small file, always pulls latest build).
local tick = 0
pcall(function()
    if utility and utility.get_tick_count then
        tick = utility.get_tick_count()
    end
end)
if tick == 0 then tick = os.time() end

local urls = {
    "https://cdn.jsdelivr.net/gh/Cunzaki/April@main/april.lua?v=3.95.8&cb=" .. tostring(tick),
    "https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/april.lua?v=3.95.8&cb=" .. tostring(tick),
}

local load_fn = utility and (utility.load_url or utility.LoadUrl or utility.loadurl)
if not load_fn then
    print("[April] utility.load_url unavailable")
    return
end

for i = 1, #urls do
    local ok, err = pcall(load_fn, urls[i])
    if ok then return end
    print("[April] load failed (" .. i .. "): " .. tostring(err))
end
