April = {
    version = "4.1.31",
    debug = false,
    crash_logging = false,
    crash_trace = false,
    autofarm_trace = false,
    _mods = {},
    load_status = {
        { name = "Core", state = "loaded" },
        { name = "Services", state = "loaded" },
        { name = "Game Data", state = "loaded" },
        { name = "Features", state = "loaded" },
        { name = "Interface", state = "loaded" },
    },
    bundled = true,
    custom_ui = true,
}

April._menu_tab_ready = true

function April.require(path)
    local mod = April._mods[path]
    if mod == nil then
        error("[April] bundled module missing: " .. path)
    end
    return mod
end

April.bundled = false
April.load_status = {
    { name = "Core", state = "pending" },
    { name = "Services", state = "pending" },
    { name = "Game Data", state = "pending" },
    { name = "Features", state = "pending" },
    { name = "Interface", state = "pending" },
}

local chunks = {
    "https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/chunks/01-core.lua?v=4.1.31",
    "https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/chunks/02-services.lua?v=4.1.31",
    "https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/chunks/03-game.lua?v=4.1.31",
    "https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/chunks/04-features.lua?v=4.1.31",
    "https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/chunks/05-interface.lua?v=4.1.31",
}

local loader_index = 1
local loader_failed = false

local function loader_screen()
    local fn = draw and (draw.GetScreenSize or draw.get_screen_size)
    if type(fn) == "function" then
        local ok, width, height = pcall(fn)
        if ok and width and height then return width, height end
    end
    return 1920, 1080
end

local function loader_text_width(text, size)
    local fn = draw and (draw.GetTextSize or draw.get_text_size)
    if type(fn) == "function" then
        local ok, width = pcall(fn, text, size)
        if ok and type(width) == "number" then return width end
    end
    return #text * size * 0.56
end

local function loader_draw()
    if not draw then return end
    local fill = draw.RectFilled or draw.rect_filled
    local text = draw.Text or draw.text
    local line = draw.Line or draw.line
    if not fill or not text or not line then return end
    local width, height = loader_screen()
    local center_x, center_y = width * 0.5, height * 0.5
    fill(-1, -1, width + 2, height + 2, { 0, 0, 0, 1 }, 0)

    local title = "April.lua"
    local author = "Made by Cunzaki"
    local heading = "Loading modules"
    text(center_x - loader_text_width(title, 52) * 0.5, center_y - 72,
        title, { 0.83, 0.47, 1, 1 }, 52)
    text(center_x - loader_text_width(author, 18) * 0.5, center_y - 8,
        author, { 0.92, 0.92, 0.96, 0.9 }, 18)
    text(center_x - loader_text_width(heading, 13) * 0.5, center_y + 34,
        heading, { 0.72, 0.72, 0.78, 0.72 }, 13)

    for index, status in ipairs(April.load_status) do
        local label = status.state == "loaded" and status.name
            or status.state == "failed" and ("Failed: " .. status.name)
            or status.state == "loading" and ("Loading " .. status.name .. "...")
            or status.name
        local size = 13
        local label_width = loader_text_width(label, size)
        local x = center_x - (label_width + 24) * 0.5
        local y = center_y + 59 + (index - 1) * 20
        local color = status.state == "failed" and { 1, 0.28, 0.28, 1 }
            or { 0.88, 0.88, 0.92, status.state == "pending" and 0.38 or 0.88 }
        if status.state == "loaded" then
            line(x, y + 7, x + 3, y + 11, { 0.55, 0.92, 0.68, 1 }, 1.8)
            line(x + 3, y + 11, x + 10, y + 2, { 0.55, 0.92, 0.68, 1 }, 1.8)
        elseif status.state == "failed" then
            line(x, y + 3, x + 9, y + 11, color, 1.6)
            line(x + 9, y + 3, x, y + 11, color, 1.6)
        else
            local pulse = 0.35 + (math.sin((utility.GetTime and utility.GetTime() or 0) * 5) + 1) * 0.2
            line(x, y + 7, x + 8, y + 7, { 0.83, 0.47, 1, pulse }, 1.7)
        end
        text(x + 18, y, label, color, size)
    end
end

OnFrame = function()
    loader_draw()
    if loader_failed or loader_index > #chunks then return end
    local status = April.load_status[loader_index]
    if status.state == "pending" then
        status.state = "loading"
        return
    end
    local ok, err = utility.LoadUrl(chunks[loader_index])
    if not ok then
        status.state = "failed"
        status.error = tostring(err)
        loader_failed = true
        print("[April] Failed to load " .. status.name .. ": " .. tostring(err))
        return
    end
    status.state = "loaded"
    loader_index = loader_index + 1
end
