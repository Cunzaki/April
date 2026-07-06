--[[ ASCII-safe UI text — Vector draw font lacks many Unicode glyphs (shows as ?). ]]

local M = {}

local REPLACEMENTS = {
    ["\194\160"] = " ", -- nbsp
    ["\226\128\166"] = "...", -- ellipsis …
    ["\226\128\147"] = "-", -- em dash —
    ["\226\128\148"] = "-", -- en dash –
    ["\226\128\162"] = "*", -- bullet •
    ["\194\183"] = "|", -- middle dot ·
    ["\226\134\146"] = "->", -- arrow →
    ["\226\134\144"] = "<-", -- arrow ←
    ["\226\128\153"] = "'", -- right single quote
    ["\226\128\156"] = '"', -- left double quote
    ["\226\128\157"] = '"', -- right double quote
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
