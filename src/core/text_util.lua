local M = {}

local REPLACEMENTS = {
    ["\194\160"] = " ",
    ["\226\128\166"] = "...",
    ["\226\128\147"] = "-",
    ["\226\128\148"] = "-",
    ["\226\128\162"] = "*",
    ["\194\183"] = "|",
    ["\226\134\146"] = "->",
    ["\226\134\144"] = "<-",
    ["\226\128\153"] = "'",
    ["\226\128\156"] = '"',
    ["\226\128\157"] = '"',
}

function M.sanitize(text)
    if text == nil then return "" end
    text = tostring(text)
    for bad, good in pairs(REPLACEMENTS) do
        text = text:gsub(bad, good)
    end
    if text:find("[^\32-\126]") then
        text = text:gsub("[^\32-\126]", "")
    end
    return text
end

return M
