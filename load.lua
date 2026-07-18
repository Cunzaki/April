-- Always fetch the latest bundled script (cache-bust raw.githubusercontent CDN).
local tick = 0
pcall(function()
    if utility and utility.get_tick_count then
        tick = utility.get_tick_count()
    end
end)
if tick == 0 then tick = os.time() end

utility.load_url(
    "https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/april.lua?cb=" .. tostring(tick)
)
