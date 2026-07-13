local URL = "https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/april.lua"
local load_fn = utility and (utility.load_url or utility.LoadUrl or utility.loadurl)
if load_fn then
    load_fn(URL)
else
    print("[April] utility.load_url missing — load april.lua directly or update Vector")
end
