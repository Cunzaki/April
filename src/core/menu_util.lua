--[[
    Vector binds per-script menu UI to a single tab registered with mode "full".
    All April menu elements must use April.TAB as their tab name.
]]

local M = {}

M.TAB = "April"
M._registered = false

function M.ensure_tab()
    if M._registered then return end
    if menu and menu.add_tab then
        menu.add_tab(M.TAB, "A", "full")
    end
    M._registered = true
end

function M.group(name)
    M.ensure_tab()
    menu.add_group(M.TAB, name)
end

return M
