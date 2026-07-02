local env = April.require("core.env")

local M = {}

M.PATHS = {
    drops = { "Drops" },
    bases = { "Bases" },
    animals = { "Animals" },
    plants = { "Plants" },
    vegetation = { "Vegetation" },
    military = { "Military" },
    events = { "Events" },
    monuments = { "Monuments" },
    nodes = { "Nodes" },
    loners = { "Bases", "Loners" },
}

function M.get_folder(...)
    local ws = env.get_workspace()
    if not ws then return nil end
    local cur = ws
    for _, name in ipairs({ ... }) do
        if not cur then return nil end
        cur = env.safe_call(function() return cur:find_first_child(name) end)
        if not env.is_valid(cur) then return nil end
    end
    return cur
end

function M.scan_children(folder, class_filter, max_count)
    local out = {}
    if not env.is_valid(folder) then return out end
    local children = env.safe_call(function() return folder:get_children() end) or {}
    for _, child in ipairs(children) do
        if #out >= (max_count or 500) then break end
        if env.is_valid(child) then
            if not class_filter or child.ClassName == class_filter or env.safe_call(function() return child:is_a(class_filter) end) then
                table.insert(out, child)
            end
        end
    end
    return out
end

function M.scan_descendants(folder, name_filters, max_count)
    local out = {}
    if not env.is_valid(folder) then return out end
    local desc = env.safe_call(function() return folder:get_descendants() end) or {}
    for _, inst in ipairs(desc) do
        if #out >= (max_count or 800) then break end
        if env.is_valid(inst) then
            local n = inst.Name or ""
            for _, pattern in ipairs(name_filters or {}) do
                if n:find(pattern, 1, true) then
                    table.insert(out, inst)
                    break
                end
            end
        end
    end
    return out
end

function M.iter_workspace_folders(keys, fn, max_per)
    for _, key in ipairs(keys) do
        local path = M.PATHS[key]
        if path then
            local folder = M.get_folder(unpack(path))
            if folder then fn(key, folder, max_per) end
        end
    end
end

return M
