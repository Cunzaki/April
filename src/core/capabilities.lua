--[[ Lightweight capability flags (no runtime probes — those block on getgc/refreshgc). ]]

local M = {}

function M.probe()
    return {
        menu = _G.menu ~= nil,
        draw = _G.draw ~= nil,
        entity = _G.entity ~= nil,
        game = _G.game ~= nil,
        camera = _G.camera ~= nil,
        input = _G.input ~= nil,
        utility = _G.utility ~= nil,
        thread = _G.thread ~= nil,
        raycast = _G.raycast ~= nil,
        fflag = _G.fflag ~= nil,
        memory = _G.memory ~= nil,
        fallen_gc = type(refreshgc) == "function"
            and type(applygc) == "function"
            and type(getgc) == "function",
        getgc = type(getgc) == "function",
    }
end

function M.summary(c)
    c = c or M.probe()
    local parts = {}
    if c.menu then table.insert(parts, "menu") end
    if c.draw then table.insert(parts, "draw") end
    if c.fallen_gc then table.insert(parts, "gc-mods") end
    if c.getgc then table.insert(parts, "getgc") end
    return #parts > 0 and table.concat(parts, ", ") or "minimal"
end

return M
