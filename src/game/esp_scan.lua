local env = April.require("core.env")

local M = {}

local PART_CLASSES = {
    Part = true,
    MeshPart = true,
    UnionOperation = true,
    WedgePart = true,
    CornerWedgePart = true,
}

function M.is_part(inst)
    if not inst then return false end
    local cn = inst.ClassName or inst.class_name
    return PART_CLASSES[cn] == true
end

function M.find_main_part(model)
    if not env.is_valid(model) then return nil end

    local main = env.safe_call(function()
        if model.Main then return model.Main end
        return model:find_first_child("Main") or model:FindFirstChild("Main")
    end)
    if main and M.is_part(main) then return main end

    local hrp = env.safe_call(function()
        if model.HumanoidRootPart then return model.HumanoidRootPart end
        return model:find_first_child("HumanoidRootPart") or model:FindFirstChild("HumanoidRootPart")
    end)
    if hrp and M.is_part(hrp) then return hrp end

    local children = env.safe_call(function() return model:get_children() end) or {}
    for _, child in ipairs(children) do
        if M.is_part(child) then return child end
    end

    if M.is_part(model) then return model end
    return nil
end

local function vec3(v, axis)
    if not v then return 0 end
    if axis == "x" then return v.x or v.X or 0 end
    if axis == "y" then return v.y or v.Y or 0 end
    return v.z or v.Z or 0
end

function M.read_part_box(part)
    if not env.is_valid(part) or not M.is_part(part) then return nil end

    local pos, size, rv, uv, lv
    pcall(function()
        pos = part.Position or part.position
        size = part.Size or part.size
        rv = part.RightVector or part.right_vector
        uv = part.UpVector or part.up_vector
        lv = part.LookVector or part.look_vector
    end)

    if not pos or not size then return nil end

    return {
        x = vec3(pos, "x"),
        y = vec3(pos, "y"),
        z = vec3(pos, "z"),
        hx = vec3(size, "x") * 0.5,
        hy = vec3(size, "y") * 0.5,
        hz = vec3(size, "z") * 0.5,
        rx = rv and vec3(rv, "x") or 1,
        ry = rv and vec3(rv, "y") or 0,
        rz = rv and vec3(rv, "z") or 0,
        ux = uv and vec3(uv, "x") or 0,
        uy = uv and vec3(uv, "y") or 1,
        uz = uv and vec3(uv, "z") or 0,
        lx = lv and vec3(lv, "x") or 0,
        ly = lv and vec3(lv, "y") or 0,
        lz = lv and vec3(lv, "z") or 1,
    }
end

function M.collect_boxes(model, max_parts)
    max_parts = max_parts or 6
    local boxes = {}
    if not env.is_valid(model) then return boxes end

    local main = M.find_main_part(model)
    if main then
        local box = M.read_part_box(main)
        if box then table.insert(boxes, box) end
    end

    if #boxes >= max_parts then return boxes end

    local desc = env.safe_call(function() return model:get_descendants() end) or {}
    for _, inst in ipairs(desc) do
        if #boxes >= max_parts then break end
        if M.is_part(inst) and inst ~= main then
            local cn = inst.ClassName or inst.class_name
            if cn == "MeshPart" or cn == "Part" then
                local box = M.read_part_box(inst)
                if box then table.insert(boxes, box) end
            end
        end
    end

    return boxes
end

function M.label_position(entry)
    if not entry or not env.is_valid(entry.inst) then return nil end
    local main = M.find_main_part(entry.inst)
    if main then
        local box = M.read_part_box(main)
        if box then
            return box.x, box.y + box.hy + 0.25, box.z
        end
        local pos = main.Position or main.position
        if pos then
            return vec3(pos, "x"), vec3(pos, "y"), vec3(pos, "z")
        end
    end
    return nil
end

function M.make_entry(model, name, toggle_id, opts)
    opts = opts or {}
    local entry = {
        inst = model,
        name = name,
        toggle_id = toggle_id,
        dynamic = opts.dynamic == true,
    }
    if opts.hydrate ~= false then
        M.hydrate_entry(entry)
    end
    return entry
end

function M.hydrate_entry(entry)
    if not entry or not env.is_valid(entry.inst) then return entry end

    local main = M.find_main_part(entry.inst)
    entry.main_part = main

    if main then
        local box = M.read_part_box(main)
        entry.box = box
        if box then
            entry.lx = box.x
            entry.ly = box.y + box.hy + 0.25
            entry.lz = box.z
        else
            local pos = main.Position or main.position
            if pos then
                entry.lx = vec3(pos, "x")
                entry.ly = vec3(pos, "y")
                entry.lz = vec3(pos, "z")
            end
        end
    end

    return entry
end

function M.refresh_entry_position(entry)
    if not entry or not env.is_valid(entry.inst) then return false end

    if entry.main_part and env.is_valid(entry.main_part) then
        local box = M.read_part_box(entry.main_part)
        if box then
            entry.box = box
            entry.lx = box.x
            entry.ly = box.y + box.hy + 0.25
            entry.lz = box.z
            return true
        end
    end

    M.hydrate_entry(entry)
    return entry.lx ~= nil
end

function M.entry_coords(entry)
    if entry and entry.lx and entry.ly and entry.lz then
        return entry.lx, entry.ly, entry.lz
    end
    return M.label_position(entry)
end

function M.create_folder_scan(folder_keys, name_map, label_map, dynamic)
    return {
        folder_keys = folder_keys,
        name_map = name_map,
        label_map = label_map,
        dynamic = dynamic == true,
        fi = 1,
        ci = 1,
        children = nil,
        folder = nil,
        out = {},
        seen = {},
    }
end

function M.folder_scan_step(state, max_items)
    max_items = max_items or 16
    local processed = 0
    local folders_mod = April.require("game.folders")

    while processed < max_items do
        if state.fi > #state.folder_keys then
            return true, state.out
        end

        if not state.folder or not state.children then
            state.folder = folders_mod.from_key(state.folder_keys[state.fi])
            state.ci = 1
            if env.is_valid(state.folder) then
                state.children = env.safe_call(function() return state.folder:get_children() end) or {}
            else
                state.children = {}
            end
        end

        if state.ci > #state.children then
            state.fi = state.fi + 1
            state.folder = nil
            state.children = nil
            goto continue
        end

        local model = state.children[state.ci]
        state.ci = state.ci + 1
        processed = processed + 1

        if not env.is_valid(model) then goto continue end

        local inst_name = model.Name or model.name
        if not inst_name then goto continue end

        local toggle_id = state.name_map[inst_name]
        if not toggle_id then goto continue end

        local key = tostring(model.Address or model) .. ":" .. toggle_id
        if state.seen[key] then goto continue end
        state.seen[key] = true

        local label = (state.label_map and state.label_map[inst_name]) or inst_name
        table.insert(state.out, M.make_entry(model, label, toggle_id, { dynamic = state.dynamic }))

        ::continue::
    end

    return false, state.out
end

function M.scan_folders(folder_keys, name_map, label_map, dynamic)
    local folders_mod = April.require("game.folders")
    local out = {}
    local seen = {}

    local function add_entry(model, inst_name)
        local toggle_id = name_map[inst_name]
        if not toggle_id then return end
        local key = tostring(model.Address or model) .. ":" .. toggle_id
        if seen[key] then return end
        seen[key] = true
        local label = (label_map and label_map[inst_name]) or inst_name
        table.insert(out, M.make_entry(model, label, toggle_id, { dynamic = dynamic }))
    end

    for _, folder_key in ipairs(folder_keys or {}) do
        local folder = folders_mod.from_key(folder_key)
        if not env.is_valid(folder) then goto next_folder end

        local children = env.safe_call(function() return folder:get_children() end) or {}
        for _, model in ipairs(children) do
            if not env.is_valid(model) then goto continue end
            local inst_name = model.Name or model.name
            if inst_name then add_entry(model, inst_name) end
            ::continue::
        end
        ::next_folder::
    end

    return out
end

return M
