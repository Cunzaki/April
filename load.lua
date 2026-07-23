-- April LOCAL loader — paste into Vector Script 1/2.
-- Loads the built april.lua from disk (not GitHub CDN).

local path = [[C:\\Users\\Cunza\\Desktop\\Vector Fallen V2\\April Fallen\\april.lua]]
local f = io.open(path, "r")
if not f then
    print("[April] missing local file: " .. path)
    print("[April] Run npm run build, or paste april.lua into this script slot")
    return
end
local src = f:read("*a")
f:close()
if not src or #src < 1000 then
    print("[April] local april.lua empty/corrupt")
    return
end
local fn, err = loadstring(src)
if not fn then
    print("[April] compile failed: " .. tostring(err))
    return
end
local ok, run_err = pcall(fn)
if not ok then
    print("[April] run failed: " .. tostring(run_err))
end
