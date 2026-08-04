April._mods["game.module_scan"] = (function()
local M = {}
M._table_cache = nil
M._cache_at = 0
M._cache_ttl = 30000
function M.has_gc()
    return type(getgc) == "function"
end
function M.uses_fallen_weapon_gc()
    return type(refreshgc) == "function" and type(applygc) == "function"
end
local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end
local function add_tables(from, out, seen)
    if type(from) ~= "table" then return end
    for _, v in pairs(from) do
        if type(v) == "table" and not seen[v] then
            seen[v] = true
            table.insert(out, v)
        end
    end
end
function M.invalidate_cache()
    M._table_cache = nil
    M._cache_at = 0
end
function M.collect_tables(force)
    local now = tick_ms()
    if not force and M._table_cache and now - M._cache_at < M._cache_ttl then
        return M._table_cache
    end
    local list = {}
    local seen = {}
    local function add(v)
        if type(v) == "table" and not seen[v] then
            seen[v] = true
            table.insert(list, v)
        end
    end
    if type(filtergc) == "function" then
        local ok = pcall(function()
            filtergc("table", true, function(v)
                add(v)
                return false
            end)
        end)
        if ok and #list > 0 then
            M._table_cache = list
            M._cache_at = now
            return list
        end
        list = {}
        seen = {}
    end
    if M.has_gc() and not M.uses_fallen_weapon_gc() then
        local ok, all = pcall(getgc, true)
        if ok and type(all) == "table" then
            for _, v in ipairs(all) do add(v) end
        end
    end
    if package and type(package.loaded) == "table" then
        add_tables(package.loaded, list, seen)
    end
    if type(shared) == "table" then
        add_tables(shared, list, seen)
    end
    M._table_cache = list
    M._cache_at = now
    return list
end
function M.each_table(fn, force)
    local list = M.collect_tables(force)
    for i = 1, #list do
        fn(list[i])
    end
end
function M.find_toolinfo()
    local best, best_n = nil, 0
    M.each_table(function(v)
        local n = 0
        for k, entry in pairs(v) do
            if type(k) == "string" and type(entry) == "table" then
                if entry.Recoil or entry.Bullet or entry.Weapon or entry.Spread then
                    n = n + 1
                end
            end
        end
        if n > best_n and n >= 3 then
            best_n = n
            best = v
        end
    end)
    return best, best_n
end
function M.find_items()
    local best, best_n = nil, 0
    M.each_table(function(v)
        local n = 0
        if type(v[1]) == "table" and v[1].Name and v[1].Image then
            for i = 1, #v do
                local entry = v[i]
                if type(entry) == "table" and entry.Name and entry.Image then
                    n = n + 1
                end
            end
        else
            for _, entry in pairs(v) do
                if type(entry) == "table" and entry.Name and entry.Image then
                    n = n + 1
                end
            end
        end
        if n > best_n and n >= 100 then
            best_n = n
            best = v
        end
    end)
    return best, best_n
end
return M
end)()

April._mods["game.bootstrap"] = (function()
local env = April.require("core.env")
local debug = April.require("core.debug")
local module_scan = April.require("game.module_scan")
local M = {}
M._toolinfo = nil
M._ready = false
M._attempts = 0
M._last_try = 0
M._try_interval = 5000
M._logged_ready = false
M._scan_after = 0
M._defer_ms = 2500
local function in_game_ready()
    if env.get_local_player() then return true end
    local cache = April.require("core.cache")
    if cache.local_player or #cache.all_entities > 0 then return true end
    return false
end
local function try_load_toolinfo()
    local data, n = module_scan.find_toolinfo()
    if data then
        M._toolinfo = data
        M._ready = true
        return true, n or 0
    end
    return false, 0
end
function M.get_module(name)
    if name == "ToolInfo" then
        return M._toolinfo
    end
    return nil
end
function M.is_ready()
    return M._ready
end
local function on_toolinfo_ready(count)
    if M._logged_ready then return end
    M._logged_ready = true
    if April and April.debug then
        debug.log(string.format("ToolInfo ready (%d weapons)", count or 0))
    end
    local weapons = April.require("game.weapons")
    if weapons.on_modules_ready then
        weapons.on_modules_ready()
    else
        weapons.load()
    end
    local items = April.require("game.items")
    items.load()
end
function M.try_load_all()
    if M._ready then return true end
    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    if not in_game_ready() then
        M._scan_after = 0
        return false
    end
    if M._scan_after == 0 then
        M._scan_after = now + M._defer_ms
    end
    if now < M._scan_after then
        return false
    end
    if M._attempts > 0 and now - M._last_try < M._try_interval then
        return false
    end
    M._last_try = now
    M._attempts = M._attempts + 1
    local ok, count = try_load_toolinfo()
    if ok then
        on_toolinfo_ready(count)
    end
    return M._ready
end
function M.get_status()
    if M._ready then
        return "ToolInfo+scan"
    end
    return "ToolInfo-wait"
end
function M.force_reload()
    M._toolinfo = nil
    M._ready = false
    M._last_try = 0
    M._attempts = 0
    M._logged_ready = false
    M._scan_after = 0
    module_scan.invalidate_cache()
    April.require("game.weapons").invalidate()
    April.require("game.items").invalidate()
    return M.try_load_all()
end
function M.tick()
    if not M._ready then
        M.try_load_all()
    end
end
function M.start_background_retry()
end
return M
end)()

April._mods["game.folders"] = (function()
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
        cur = env.safe_call(function()
            return cur:find_first_child(name)
                or cur:FindFirstChild(name)
        end)
        if not cur then return nil end
    end
    return cur
end
function M.from_key(key)
    local path = M.PATHS[key]
    if not path then return nil end
    return M.get_folder(unpack(path))
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
end)()

April._mods["game.esp_maps"] = (function()
local M = {}
M.NODE_MAP = {
    ["Stone_Node"] = "april_stone_node",
    ["Metal_Node"] = "april_metal_node",
    ["Phosphate_Node"] = "april_phosphate_node",
}
M.NODE_LABELS = {
    ["Stone_Node"] = "Stone Node",
    ["Metal_Node"] = "Metal Node",
    ["Phosphate_Node"] = "Phosphate Node",
}
M.NODE_FOLDERS = { "nodes" }
M.PLANT_MAP = {
    ["Corn Plant"] = "april_corn_plant",
    ["Tomato Plant"] = "april_tomato_plant",
    ["Pumpkin Plant"] = "april_pumpkin_plant",
    ["Lemon Plant"] = "april_lemon_plant",
    ["Raspberry Plant"] = "april_raspberry_plant",
    ["Blueberry Plant"] = "april_blueberry_plant",
    ["Wool Plant"] = "april_wool_plant",
}
M.PLANT_LABELS = {
    ["Corn Plant"] = "Corn Plant",
    ["Tomato Plant"] = "Tomato Plant",
    ["Pumpkin Plant"] = "Pumpkin Plant",
    ["Lemon Plant"] = "Lemon Plant",
    ["Raspberry Plant"] = "Raspberry Plant",
    ["Blueberry Plant"] = "Blueberry Plant",
    ["Wool Plant"] = "Wool Plant",
}
M.PLANT_FOLDERS = { "plants" }
M.ANIMAL_MAP = {
    ["PREFAB_ANIMAL_DEER"] = "april_deer",
    ["PREFAB_ANIMAL_WILDBOAR"] = "april_boar",
    ["PREFAB_ANIMAL_WOLF"] = "april_wolf",
    ["Deer"] = "april_deer",
    ["Wild Boar"] = "april_boar",
    ["WildBoar"] = "april_boar",
    ["Boar"] = "april_boar",
    ["Wolf"] = "april_wolf",
}
M.ANIMAL_LABELS = {
    ["PREFAB_ANIMAL_DEER"] = "Deer",
    ["PREFAB_ANIMAL_WILDBOAR"] = "Wild Boar",
    ["PREFAB_ANIMAL_WOLF"] = "Wolf",
    ["Deer"] = "Deer",
    ["Wild Boar"] = "Wild Boar",
    ["WildBoar"] = "Wild Boar",
    ["Boar"] = "Boar",
    ["Wolf"] = "Wolf",
}
M.ANIMAL_FOLDERS = { "animals" }
M.WORLD_TOGGLES = {
    { id = "april_stone_node", label = "Stone Node", color = { 0.5, 0.5, 0.5, 1 } },
    { id = "april_metal_node", label = "Metal Node", color = { 0.7, 0.5, 0.3, 1 } },
    { id = "april_phosphate_node", label = "Phosphate Node", color = { 0.2, 0.8, 0.2, 1 } },
    { id = "april_corn_plant", label = "Corn Plant", color = { 1, 0.9, 0.3, 1 } },
    { id = "april_tomato_plant", label = "Tomato Plant", color = { 1, 0.4, 0.3, 1 } },
    { id = "april_pumpkin_plant", label = "Pumpkin Plant", color = { 1, 0.5, 0.1, 1 } },
    { id = "april_lemon_plant", label = "Lemon Plant", color = { 1, 0.95, 0.2, 1 } },
    { id = "april_raspberry_plant", label = "Raspberry Plant", color = { 0.9, 0.2, 0.4, 1 } },
    { id = "april_blueberry_plant", label = "Blueberry Plant", color = { 0.3, 0.4, 0.9, 1 } },
    { id = "april_wool_plant", label = "Wool Plant", color = { 0.85, 0.85, 0.9, 1 } },
    { id = "april_deer", label = "Deer", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_boar", label = "Wild Boar", color = { 0.4, 0.3, 0.2, 1 } },
    { id = "april_wolf", label = "Wolf", color = { 0.5, 0.5, 0.5, 1 } },
}
M.LOOT_MAP = {
    ["Wooden Crate"] = "april_wooden_crate",
    ["Locked Wooden Crate"] = "april_wooden_crate",
    ["Locked Metal Crate"] = "april_metal_crate",
    ["Locked Steel Crate"] = "april_steel_crate",
    ["Food Crate"] = "april_food_crate",
    ["Timed Crate"] = "april_timed_crate",
    ["Care Package"] = "april_care_package",
    ["BTR Crate"] = "april_btr_crate",
    ["Body Bag"] = "april_body_bag",
    ["Sleeper"] = "april_sleeper",
    ["Trash Can"] = "april_trash_can",
    ["Oil Barrel"] = "april_oil_barrel",
    ["Small Egg"] = "april_small_egg",
    ["Medium Egg"] = "april_medium_egg",
    ["Large Egg"] = "april_large_egg",
    ["Small Gift"] = "april_small_egg",
    ["Medium Gift"] = "april_medium_egg",
    ["Large Gift"] = "april_large_egg",
    ["Wooden Boat"] = "april_wooden_boat",
    ["Military Boat"] = "april_military_boat",
    ["Salvaged Flycopter"] = "april_flycopter",
    ["Heli Crate"] = "april_heli_crate",
}
M.LOOT_TOGGLES = {
    { id = "april_dropped_item", label = "Dropped Items", color = { 1, 0.8, 0, 1 } },
    { id = "april_wooden_crate", label = "Wooden Crate", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_metal_crate", label = "Metal Crate", color = { 0.5, 0.5, 0.6, 1 } },
    { id = "april_steel_crate", label = "Steel Crate", color = { 0.7, 0.7, 0.8, 1 } },
    { id = "april_food_crate", label = "Food Crate", color = { 0.2, 0.8, 0.2, 1 } },
    { id = "april_timed_crate", label = "Timed Crate", color = { 1, 0.5, 0, 1 } },
    { id = "april_care_package", label = "Care Package", color = { 1, 0.2, 0.2, 1 } },
    { id = "april_btr_crate", label = "BTR Crate", color = { 0.8, 0.15, 0.15, 1 } },
    { id = "april_body_bag", label = "Body Bag", color = { 0.3, 0.3, 0.3, 1 } },
    { id = "april_sleeper", label = "Sleepers", color = { 0.8, 0.4, 0.8, 1 } },
    { id = "april_trash_can", label = "Trash Can", color = { 0.45, 0.45, 0.45, 1 } },
    { id = "april_oil_barrel", label = "Oil Barrel", color = { 0.2, 0.2, 0.2, 1 } },
    { id = "april_small_egg", label = "Small Egg / Gift", color = { 0.95, 0.85, 0.5, 1 } },
    { id = "april_medium_egg", label = "Medium Egg / Gift", color = { 0.9, 0.7, 0.4, 1 } },
    { id = "april_large_egg", label = "Large Egg / Gift", color = { 0.85, 0.55, 0.3, 1 } },
    { id = "april_wooden_boat", label = "Wooden Boat", color = { 0.55, 0.35, 0.15, 1 } },
    { id = "april_military_boat", label = "Military Boat", color = { 0.35, 0.45, 0.35, 1 } },
    { id = "april_flycopter", label = "Salvaged Flycopter", color = { 0.6, 0.6, 0.65, 1 } },
    { id = "april_heli_crate", label = "Heli Crate", color = { 0.75, 0.25, 0.2, 1 } },
}
M.LOOT_SCAN_FOLDERS = { "loners", "vegetation", "military", "events", "monuments" }
M.BASE_MAP = {
    ["Base Cabinet"] = "april_base_cabinet",
    ["Storage Cabinet"] = "april_storage_cabinet",
    ["Cabinet"] = "april_base_cabinet",
    ["Large Cabinet"] = "april_storage_cabinet",
    ["Small Storage Box"] = "april_small_box",
    ["Large Storage Box"] = "april_large_box",
    ["Small Box"] = "april_small_box",
    ["Large Box"] = "april_large_box",
    ["Wooden Door"] = "april_wooden_door",
    ["Wooden Double Door"] = "april_wooden_double_door",
    ["Salvaged Metal Door"] = "april_salvaged_door",
    ["Metal Door"] = "april_metal_door",
    ["Metal Double Door"] = "april_metal_double_door",
    ["Steel Door"] = "april_steel_door",
    ["Steel Double Door"] = "april_steel_double_door",
    ["Trap Door"] = "april_trap_door",
    ["Triangle Trap Door"] = "april_triangle_trap_door",
    ["Garage Door"] = "april_garage_door",
    ["Sleeping Bag"] = "april_sleeping_bag",
    ["Shotgun Turret"] = "april_shotgun_turret",
    ["Auto Turret"] = "april_auto_turret",
    ["Small Battery"] = "april_small_battery",
    ["Medium Battery"] = "april_medium_battery",
    ["Large Battery"] = "april_large_battery",
    ["Solar Panel"] = "april_solar_panel",
    ["Windmill"] = "april_windmill",
}
M.BASE_SKIP_AREAS = {
    Loners = true,
    VMs = true,
    BTRMonumentPaths = true,
    Benches = true,
    Wires = true,
    Ragdolls = true,
    Fire = true,
}
M.BASE_TOGGLES = {
    { id = "april_base_cabinet", label = "Base Cabinet", color = { 1, 0.8, 0, 1 } },
    { id = "april_storage_cabinet", label = "Storage Cabinet", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_small_box", label = "Small Storage Box", color = { 0.55, 0.35, 0.15, 1 } },
    { id = "april_large_box", label = "Large Storage Box", color = { 0.45, 0.3, 0.12, 1 } },
    { id = "april_sleeping_bag", label = "Sleeping Bag", color = { 0.8, 0.2, 0.2, 1 } },
    { id = "april_auto_turret", label = "Auto Turret", color = { 1, 0.2, 0.2, 1 }, ring_id = "april_auto_turret_ring" },
    { id = "april_shotgun_turret", label = "Shotgun Turret", color = { 1, 0.35, 0.2, 1 }, ring_id = "april_shotgun_turret_ring" },
    { id = "april_wooden_door", label = "Wooden Door", color = { 0.5, 0.3, 0.1, 1 } },
    { id = "april_wooden_double_door", label = "Wooden Double Door", color = { 0.55, 0.32, 0.12, 1 } },
    { id = "april_metal_door", label = "Metal Door", color = { 0.5, 0.5, 0.6, 1 } },
    { id = "april_salvaged_door", label = "Salvaged Metal Door", color = { 0.55, 0.52, 0.48, 1 } },
    { id = "april_metal_double_door", label = "Metal Double Door", color = { 0.52, 0.52, 0.58, 1 } },
    { id = "april_steel_door", label = "Steel Door", color = { 0.65, 0.65, 0.72, 1 } },
    { id = "april_steel_double_door", label = "Steel Double Door", color = { 0.62, 0.62, 0.7, 1 } },
    { id = "april_garage_door", label = "Garage Door", color = { 0.4, 0.4, 0.42, 1 } },
    { id = "april_trap_door", label = "Trap Door", color = { 0.48, 0.38, 0.22, 1 } },
    { id = "april_triangle_trap_door", label = "Triangle Trap Door", color = { 0.46, 0.36, 0.2, 1 } },
    { id = "april_small_battery", label = "Small Battery", color = { 0.2, 0.75, 0.35, 1 } },
    { id = "april_medium_battery", label = "Medium Battery", color = { 0.15, 0.65, 0.3, 1 } },
    { id = "april_large_battery", label = "Large Battery", color = { 0.1, 0.55, 0.25, 1 } },
    { id = "april_solar_panel", label = "Solar Panel", color = { 0.2, 0.4, 0.85, 1 } },
    { id = "april_windmill", label = "Windmill", color = { 0.75, 0.85, 0.95, 1 } },
}
function M.toggle_color(list, toggle_id, fallback)
    for _, t in ipairs(list or {}) do
        if t.id == toggle_id then
            return t.color
        end
    end
    return fallback or { 1, 1, 1, 1 }
end
function M.turret_ring_toggle(toggle_id)
    for _, t in ipairs(M.BASE_TOGGLES) do
        if t.id == toggle_id then
            return t.ring_id
        end
    end
    return nil
end
return M
end)()

April._mods["game.esp_scan"] = (function()
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
    local primary = env.safe_call(function()
        return model.PrimaryPart or model.primary_part
    end)
    if primary and M.is_part(primary) then return primary end
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
local function entry_key(entry)
    if not entry or not entry.inst then return nil end
    return tostring(entry.inst.Address or entry.inst) .. ":" .. tostring(entry.toggle_id or "")
end
function M.merge_entries(prev, fresh)
    local env = April.require("core.env")
    local prev_by_key = {}
    for _, entry in ipairs(prev or {}) do
        local key = entry_key(entry)
        if key and entry.inst and env.is_valid(entry.inst) then
            prev_by_key[key] = entry
        end
    end
    local out = {}
    local seen = {}
    for _, entry in ipairs(fresh or {}) do
        if not entry or not entry.inst or not env.is_valid(entry.inst) then goto continue end
        local key = entry_key(entry)
        if not key or seen[key] then goto continue end
        seen[key] = true
        local existing = prev_by_key[key]
        if existing and env.is_valid(existing.inst) then
            out[#out + 1] = existing
        else
            out[#out + 1] = entry
        end
        ::continue::
    end
    return out
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
return M
end)()

April._mods["game.item_images"] = (function()
local M = {}
M.by_name = {
    ["Balaclava"] = { default = "14654791788", variants = { ["Default"] = "14654791788", ["Jester"] = "15344534842", ["Frankenstein"] = "15883389666", ["Independence"] = "18341880885", ["Digital"] = "18965910197", ["Jolly"] = "129387971218495", ["Skull"] = "139941774966045", ["Monkey"] = "74568523494874", ["Crimson Bunny"] = "16912319678", } },
    ["Base Cabinet"] = { default = "14653876852", variants = { ["Default"] = "14653876852", ["Server"] = "109131187101243", ["Winter Wrap"] = "79186461116233", } },
    ["Baseball Cap"] = { default = "14654795325", variants = { ["Default"] = "14654795325", ["Quack"] = "16208669800", ["Independence"] = "18341880766", ["Propeller"] = "115535550124192", ["Pilgrim"] = "132977576727336", } },
    ["Bed"] = { default = "15368539842", variants = { ["Default"] = "15368539842", ["Pixel"] = "125567129432156", } },
    ["Blast Furnace"] = { default = "15876671239", variants = { ["Default"] = "15876671239", ["Robot"] = "18149216269", ["Steampunk"] = "113856439034974", } },
    ["Bone Armor"] = { default = "119847143620647", variants = { ["Default"] = "119847143620647", } },
    ["Bone Tool"] = { default = "15510368323", variants = { ["Default"] = "15510368323", } },
    ["Boots"] = { default = "14654795457", variants = { ["Default"] = "14654795457", ["Black"] = "15283152697", ["Abibas"] = "15305690697", ["Valentine"] = "16293022275", ["Woodland"] = "16473066174", ["Correctional"] = "92577755087375", ["Nutcracker"] = "102533866187536", ["Brutus"] = "124559624944530", ["Tundra"] = "75185734630840", ["Pilot"] = "134265072222654", ["Medal"] = "107412050354842", ["Forest Camo"] = "15283152517", ["Hot Rod"] = "17768833072", ["Elite Bunny"] = "98142715632310", } },
    ["Boss Chestplate"] = { default = "16652581317", variants = { ["Default"] = "16652581317", ["Cryo"] = "106187507956822", ["Boris"] = "18354053691", ["Brutus"] = "120699966211693", ["Boris Abibas"] = "137740231154465", ["Bruno Tundra"] = "92200143576210", } },
    ["Boss Helmet"] = { default = "16652579167", variants = { ["Default"] = "16652579167", ["Cryo"] = "102872157681930", ["Boris"] = "18312187080", ["Brutus"] = "134265072222654", ["Boris Sky"] = "140423012958795", ["Boris Carbon"] = "106169002653059", ["Boris Abibas"] = "18450404634", ["Bruno Tundra"] = "106377950808399", } },
    ["Boulder"] = { default = "15304806846", variants = { ["Default"] = "15304806846", ["Bubblegum"] = "15304805303", ["Frosty"] = "15304805239", ["Tester"] = "15304805180", ["Voxel"] = "15574223076", ["Wrapped"] = "15712360641", ["Pixskull"] = "17766619061", ["Stellark"] = "97313343547804", ["Cursed"] = "92913832321996", ["Sushi"] = "78426403974796", ["Chocolate"] = "139716602333201", ["Moai"] = "115978938918724", ["Ducky"] = "124674000707337", ["Pumpkin"] = "126349162347833", ["Mosaic"] = "74510585736689", ["ERROR 404"] = "16031055626", ["Jack-O-Lantern"] = "86358241058177", ["Fish Tank"] = "15792001129", } },
    ["Bruno's M4A1"] = { default = "15574295393", variants = { ["Default"] = "15574295393", } },
    ["Bunny Ears"] = { default = "16916795577", variants = { ["Default"] = "16916795577", } },
    ["Campfire"] = { default = "15128008159", variants = { ["Default"] = "15128008159", ["Skulls"] = "133107732568884", } },
    ["Candy Cane"] = { default = "15633196493", variants = { ["Default"] = "15633196493", } },
    ["Carrot Blade"] = { default = "16916703095", variants = { ["Default"] = "16916703095", } },
    ["Chainsaw"] = { default = "17201657737", variants = { ["Default"] = "17201657737", ["Recycle"] = "17357130465", } },
    ["Christmas Lights"] = { default = "134491722995587", variants = { ["Default"] = "134491722995587", } },
    ["Christmas Tree"] = { default = "15634564093", variants = { ["Default"] = "15634564093", } },
    ["Cloth Footwraps"] = { default = "14654794730", variants = { ["Default"] = "14654794730", ["Ninja"] = "132892877448790", } },
    ["Cloth Handwraps"] = { default = "14654831164", variants = { ["Default"] = "14654831164", ["Ninja"] = "114878511497747", } },
    ["Cloth Headwrap"] = { default = "14654795058", variants = { ["Default"] = "14654795058", ["Ninja"] = "120080222783269", } },
    ["Cloth Pants"] = { default = "14654794952", variants = { ["Default"] = "14654794952", ["Ninja"] = "88014133756226", } },
    ["Cloth Shirt"] = { default = "14654794835", variants = { ["Default"] = "14654794835", ["Ninja"] = "107568365412229", } },
    ["Collared Shirt"] = { default = "14654793432", variants = { ["Default"] = "14654793432", ["Business"] = "15444462393", ["Correctional"] = "140110401401547", ["Flannel"] = "97292443788852", } },
    ["Cooking Pot"] = { default = "15127562373", variants = { ["Default"] = "15127562373", } },
    ["Crossbow"] = { default = "15305596532", variants = { ["Default"] = "15305596532", ["Crossbones"] = "15305756728", ["HotDog"] = "15877969435", ["Emerald"] = "16751858634", ["Rose"] = "80803215254174", ["Toy"] = "102956782968040", ["Chief"] = "137062431435688", ["Candy Whale"] = "16114353256", } },
    ["Crude Fuel Generator"] = { default = "117457710807147", variants = { ["Default"] = "117457710807147", } },
    ["Electric Furnace"] = { default = "71536889851799", variants = { ["Default"] = "71536889851799", ["ICBM"] = "115876027631434", } },
    ["Electric Heater"] = { default = "117015755787407", variants = { ["Default"] = "117015755787407", } },
    ["Fireplace"] = { default = "134438626724268", variants = { ["Default"] = "134438626724268", } },
    ["Flannel Jacket"] = { default = "14654794281", variants = { ["Default"] = "14654794281", ["Biker"] = "15877516070", ["Correctional"] = "100006176575349", ["Abibas"] = "138547747231782", ["Snow White"] = "15283151729", } },
    ["Furnace"] = { default = "15074084708", variants = { ["Default"] = "15074084708", ["Banana"] = "15344532656", ["Glyphs"] = "15630767150", ["Gorilla"] = "16484587298", ["Burger"] = "84948985557474", ["Penguin"] = "122396159441498", ["Pumpkin"] = "81542845446759", ["Chinese New Year"] = "137256732968955", ["Sweet Gingerbread"] = "15622165066", ["Blue Steel"] = "18761542136", ["Winter Wrap"] = "82920100728899", } },
    ["Garage Door"] = { default = "16574547137", variants = { ["Default"] = "16574547137", ["Blob"] = "15509791543", ["Cryo"] = "113706556350765", ["Witch"] = "85491019952546", ["King Raid"] = "15344456682", ["Surprise Meow"] = "16574535811", ["King of the street"] = "17193053474", ["Grand Prix"] = "88541547537698", } },
    ["Hammer"] = { default = "15318044673", variants = { ["Default"] = "15318044673", ["Toy"] = "15509809013", ["ERROR 404"] = "15305728235", ["Building Blocks"] = "15953856112", } },
    ["Hard Hat"] = { default = "14654794545", variants = { ["Default"] = "14654794545", ["Slurpee"] = "15950562586", } },
    ["Hazmat Suit"] = { default = "15046441717", variants = { ["Default"] = "15046441717", ["Snowman"] = "15712521421", ["Spark"] = "18965466357", ["Stellark"] = "123693400858947", ["Classified"] = "78801273340050", ["Front"] = "109185322610878", ["Guard"] = "113617571174399", ["Ducky"] = "116234383398695", ["Ghoul"] = "102977931837887", ["Specialist"] = "99406105774604", ["Blue Fissure"] = "16822398564", ["Digital Red"] = "17366071573", ["Digital Camo"] = "106956792584318", } },
    ["Hoodie"] = { default = "14654794392", variants = { ["Default"] = "14654794392", ["Boris"] = "18312277063", ["Red"] = "15283152304", ["Purple"] = "15283152380", ["Green"] = "15283152598", ["Abibas"] = "15305689057", ["Wool"] = "15877516276", ["Valentine"] = "16293021303", ["Woodland"] = "16448119412", ["Tyrant"] = "130901964742021", ["Nutcracker"] = "72418266986929", ["Puffer"] = "71855339887230", ["Brutus"] = "116605401922894", ["Tundra"] = "94852483691948", ["Pilot"] = "134265072222654", ["Player"] = "72323540553042", ["Bee"] = "106663686372311", ["Night"] = "104718096945503", ["Forest Camo"] = "15283152783", ["Hot Rod"] = "17768833509", ["Elite Bunny"] = "77892644977802", } },
    ["Iron Shard Hatchet"] = { default = "15073617640", variants = { ["Default"] = "15073617640", ["Fade"] = "16663953399", ["Sawblade"] = "18963884209", ["Leather"] = "82373698320243", } },
    ["Iron Shard Pickaxe"] = { default = "15073617491", variants = { ["Default"] = "15073617491", ["Fade"] = "16663949312", ["Leather"] = "99659875069484", } },
    ["Jukebox"] = { default = "17343466496", variants = { ["Default"] = "17343466496", } },
    ["Ladder"] = { default = "15127607098", variants = { ["Default"] = "15127607098", } },
    ["Large Battery"] = { default = "78253036378845", variants = { ["Default"] = "78253036378845", } },
    ["Large Furnace"] = { default = "15133678858", variants = { ["Default"] = "15133678858", } },
    ["Large Storage Box"] = { default = "15094083403", variants = { ["Default"] = "15094083403", ["Canvas"] = "15283200485", ["Festive"] = "15709683124", ["Forged"] = "17758887216", ["Coffin"] = "112688458744179", ["Ouja"] = "102172335761498", ["Egg Sketch"] = "16916931642", ["Game Buddy"] = "139299560912717", ["Industrial Guns"] = "15305708083", ["Industrial Resources"] = "15305708823", ["Industrial Medical"] = "15305709566", ["Industrial Components"] = "15305710817", ["Industrial Armor"] = "15305711681", } },
    ["Leather Boots"] = { default = "14654794176", variants = { ["Default"] = "14654794176", ["Correctional"] = "95515905374532", } },
    ["Leather Gloves"] = { default = "14654794097", variants = { ["Default"] = "14654794097", ["Correctional"] = "92980178755471", ["Noir"] = "107804982630320", } },
    ["Leather Pants"] = { default = "14654793993", variants = { ["Default"] = "14654793993", ["Correctional"] = "108412621160578", } },
    ["Leather Poncho"] = { default = "14654793821", variants = { ["Default"] = "14654793821", ["Viva"] = "16208668209", ["Pilgrim"] = "98358561085174", } },
    ["Leather Shirt"] = { default = "14654793568", variants = { ["Default"] = "14654793568", ["Correctional"] = "109168692318343", } },
    ["Lighter"] = { default = "15128007580", variants = { ["Default"] = "15128007580", ["Lantern"] = "123377357974589", } },
    ["Machete"] = { default = "16249771824", variants = { ["Default"] = "16249771824", ["Rainbow"] = "16823202004", ["Crimson"] = "16912320468", ["Foam"] = "18761536955", ["Oni"] = "84793810931259", } },
    ["Medium Battery"] = { default = "129552454538184", variants = { ["Default"] = "129552454538184", } },
    ["Metal Door"] = { default = "15132832907", variants = { ["Default"] = "15132832907", ["Pixel"] = "15310965325", ["Frosty"] = "15304875360", ["Independence"] = "18341881259", ["Comic"] = "18444379748", ["Industrial"] = "78073516430678", ["Demon"] = "137869636615146", ["Bayou"] = "88981731583061", ["PLZ NO RAID"] = "15310983705", ["Angry Bunny"] = "16924356510", ["Elite Bunny"] = "77825470317254", } },
    ["Metal Double Door"] = { default = "15132833297", variants = { ["Default"] = "15132833297", ["Pixel"] = "15310966370", ["Tropical"] = "16483738322", ["Nightwave"] = "119789304012674", ["Hells Gate"] = "90897641914339", } },
    ["Military AA12"] = { default = "15068791139", variants = { ["Default"] = "15068791139", ["Zombie"] = "17199281354", ["Monster"] = "136853604493538", ["Red Tiger"] = "16485447561", } },
    ["Military Backpack"] = { default = "117242081838466", variants = { ["Default"] = "117242081838466", ["Tundra"] = "98126095773472", ["Abibas"] = "82640089227507", ["Digital Red"] = "113943759309035", } },
    ["Military Barrett"] = { default = "15346280030", variants = { ["Default"] = "15346280030", ["Surge"] = "15876918136", ["Leprechaun"] = "16751857511", ["Mystra"] = "98792148092190", ["Fade"] = "73907766386158", ["Molten"] = "103075738835660", ["Cryo"] = "124741300378620", } },
    ["Military Chestplate"] = { default = "14654793303", variants = { ["Default"] = "14654793303", ["Nutcracker"] = "70853333750344", ["Pilot"] = "134265072222654", ["Medal"] = "81188910996008", } },
    ["Military Gloves"] = { default = "14654794652", variants = { ["Default"] = "14654794652", ["Nutcracker"] = "118158228480821", ["Arctic"] = "76148467345468", ["Pilot"] = "134265072222654", ["Grim"] = "123472167772965", ["Medal"] = "137375914230135", } },
    ["Military Grenade Launcher"] = { default = "136030704871223", variants = { ["Default"] = "136030704871223", } },
    ["Military Helmet"] = { default = "14654793165", variants = { ["Default"] = "14654793165", ["Nutcracker"] = "80633563389909", ["Pilot"] = "134265072222654", ["Medal"] = "108938282129584", } },
    ["Military Leggings"] = { default = "14654792938", variants = { ["Default"] = "14654792938", ["Nutcracker"] = "84566720271674", ["Brutus"] = "75512320758936", ["Tundra"] = "86308809791688", ["Cryo"] = "88056077715569", ["Medal"] = "136956516639652", } },
    ["Military M39"] = { default = "74435081612082", variants = { ["Default"] = "74435081612082", ["Medusa"] = "117342321001432", ["Turkey"] = "111197339750272", } },
    ["Military M4A1"] = { default = "15346201415", variants = { ["Default"] = "15346201415", ["Syntax"] = "15951831122", ["Monster"] = "16663261126", ["Toy"] = "17521734560", ["Independence"] = "18341881006", ["Phantom"] = "139190777075295", ["Nutcracker"] = "136729540441664", ["Medusa"] = "101267874762837", ["Cryo"] = "94745687589547", ["CyberPop"] = "101893225757265", ["Spring Lily"] = "117935810694220", ["Cherry Blossom"] = "15509842541", } },
    ["Military MP7"] = { default = "17607841424", variants = { ["Default"] = "17607841424", ["Fade"] = "18764670728", ["Whiteout"] = "112724849582854", ["Tyrant"] = "88901653074832", ["Wave"] = "108003941053496", ["Animeaster"] = "137259300477168", ["Solitare"] = "128296099845816", ["Grunge"] = "96361565266502", ["Zap"] = "126949129741030", ["Dark Matter"] = "17768541905", ["Digital Tiger"] = "109024303396384", ["Pink Plasm"] = "74447782460391", } },
    ["Military PKM"] = { default = "16471125314", variants = { ["Default"] = "16471125314", ["Woodland"] = "16471122135", ["Resistance"] = "18149212335", ["Turbo"] = "18950918343", ["Digital Red"] = "16828755578", ["Anime Sketch"] = "90293792623916", ["Anime Waifu"] = "102634442832437", } },
    ["Military USP"] = { default = "85577075764668", variants = { ["Default"] = "85577075764668", ["Fade"] = "89094430760827", ["Azure"] = "74032961902891", ["Bright Water"] = "110809910409468", ["Crimson Scale"] = "85217509353028", ["Cherry Blossom"] = "133722249630533", } },
    ["Mining Drill"] = { default = "17287978593", variants = { ["Default"] = "17287978593", ["Recycle"] = "17357129069", ["Brick"] = "111424776562874", } },
    ["Nail Gun"] = { default = "15305104734", variants = { ["Default"] = "15305104734", ["Striker"] = "15305729695", ["Magma"] = "15946260536", ["Wintrane"] = "114731373088561", } },
    ["Pants"] = { default = "14654792590", variants = { ["Default"] = "14654792590", ["Boris"] = "18312279038", ["Khaki"] = "15283151856", ["Abibas"] = "15305689962", ["Valentine"] = "16293019822", ["Woodland"] = "16448121262", ["Correctional"] = "135793344308303", ["Tyrant"] = "136885851029799", ["Nutcracker"] = "71901466636387", ["Brutus"] = "85540429494017", ["Tundra"] = "90847059484754", ["Pilot"] = "134265072222654", ["Player"] = "129572575838612", ["Bee"] = "136553486453775", ["Forest Camo"] = "15283152437", ["Hot Rod"] = "17768833305", ["Elite Bunny"] = "89074393808133", } },
    ["Petroleum Refinery"] = { default = "15304104065", variants = { ["Default"] = "15304104065", } },
    ["Repair Table"] = { default = "15283452092", variants = { ["Default"] = "15283452092", } },
    ["Rug"] = { default = "17205250687", variants = { ["Default"] = "17205250687", ["Kraken"] = "17518134457", ["Independence"] = "18341881393", ["Chinese Dragon"] = "71202563952285", ["Christmas Knit"] = "90714037219162", ["Jolly Rogers"] = "104276123436561", } },
    ["Salvaged AK47"] = { default = "14882620172", variants = { ["Default"] = "14882620172", ["Frosty"] = "15304886302", ["Vaporwave"] = "15574230457", ["Diablo"] = "16021791118", ["Fade"] = "79444477121964", ["Tyrant"] = "124312637758997", ["Gingerbread"] = "85687142665622", ["Ghillie"] = "132083989873001", ["Anodized"] = "80710562596890", ["CyberPop"] = "128785004285267", ["Oni"] = "105854184847862", ["Medal"] = "102460072725837", ["Dune"] = "83484244695308", ["Anodized Blue"] = "15792000837", ["Anodized Red"] = "15291340361", ["North Pole"] = "105407359855835", ["Cyber Hunter"] = "17199281165", ["Gold Sky"] = "106035094504671", ["Blue Gem"] = "16577230239", ["Phantom Rider"] = "85810076023854", ["Hot Rod"] = "17768697376", ["Red Relic"] = "132874855148397", } },
    ["Salvaged AK74u"] = { default = "15073408197", variants = { ["Default"] = "15073408197", ["Beast"] = "15305755800", ["Splash"] = "15509741616", ["VIP"] = "16014753591", ["Comic"] = "16114228051", ["Clover"] = "16748171046", ["Nebula"] = "17518135139", ["Tundra"] = "114982197234346", ["MP5"] = "78960618674854", ["Flarette"] = "125113179502352", ["Zombie"] = "101630769388124", ["Pink Ripple"] = "122346171773813", ["Black Ice"] = "128242163135902", ["Phantom Rider"] = "140329577619010", ["Stellark Dragon"] = "116297510128388", } },
    ["Salvaged Backpack"] = { default = "80978101846806", variants = { ["Default"] = "80978101846806", ["Ducky"] = "84777906931514", ["Elite Bunny"] = "130786989208457", } },
    ["Salvaged Break Action"] = { default = "15305085935", variants = { ["Default"] = "15305085935", ["Splat"] = "15305729191", ["HotDog"] = "15632163269", ["Boom"] = "16823202171", ["Carrot"] = "16917852163", ["Surf"] = "17766587211", ["Easter Wood"] = "16917852163", } },
    ["Salvaged Chestplate"] = { default = "14654792418", variants = { ["Default"] = "14654792418", ["Cupid"] = "16261611092", ["Burnout"] = "18557168052", ["Tempest"] = "18966646034", ["Digital Snow"] = "15283152111", ["Elite Bunny"] = "71496524358663", } },
    ["Salvaged Double Barrel"] = { default = "132642766917853", variants = { ["Default"] = "132642766917853", ["Ducky"] = "140296796147704", ["HotDog"] = "86842880761011", } },
    ["Salvaged Gloves"] = { default = "14654792260", variants = { ["Default"] = "14654792260", ["Cupid"] = "16261613114", ["Tempest"] = "18971460487", ["Digital Snow"] = "15283152030", } },
    ["Salvaged Grenade Launcher"] = { default = "122319440938090", variants = { ["Default"] = "122319440938090", } },
    ["Salvaged Helmet"] = { default = "14654792150", variants = { ["Default"] = "14654792150", ["Cupid"] = "16261611838", ["Tempest"] = "18966646232", ["Cardboard"] = "71323845635099", ["Kill to Survive"] = "15792001031", ["Digital Snow"] = "15283152199", ["Elite Bunny"] = "119864001362604", } },
    ["Salvaged Leggings"] = { default = "14654792046", variants = { ["Default"] = "14654792046", ["Cupid"] = "16261614321", ["Tempest"] = "18966645952", ["Digital Snow"] = "15283153195", ["Elite Bunny"] = "99275929303588", } },
    ["Salvaged M14"] = { default = "14882876522", variants = { ["Default"] = "14882876522", ["Paintball"] = "15305730875", ["Splat"] = "16031054728", ["Arcane"] = "17507702118", ["Stellark"] = "77123726699368", ["Huntsman"] = "121372881282577", ["Glitch"] = "82715807510122", ["Frog14"] = "133627766691157", ["Jingle Bell"] = "78927394340869", ["Candy Dragon"] = "15346320769", ["High Tide"] = "16483734949", ["Anime Bloss"] = "91134373735199", } },
    ["Salvaged Metal Door"] = { default = "15132658803", variants = { ["Default"] = "15132658803", ["Visions"] = "15444463543", ["Graffiti"] = "16664082484", } },
    ["Salvaged P250"] = { default = "15305065991", variants = { ["Default"] = "15305065991", ["Splat"] = "15305728596", ["Fade"] = "15631601051", ["Peppermint"] = "15712513595", ["Sketch"] = "16208668754", ["Tempest"] = "18966645823", ["Festive"] = "101842524476750", ["Drift"] = "94234232543243", ["Egg Sketch"] = "16916693041", ["Blue Gem"] = "18149208414", ["Blue Terror"] = "17366305322", ["Elite Bunny"] = "138989649466976", } },
    ["Salvaged Pipe Rifle"] = { default = "15073408081", variants = { ["Default"] = "15073408081", ["Surge"] = "15509721163", ["Gingerbread"] = "15638252851", ["Frost"] = "16208668377", ["Skyline"] = "18557168359", } },
    ["Salvaged Pump Action"] = { default = "15092313032", variants = { ["Default"] = "15092313032", ["Cyber"] = "91058444899439", ["Flurry"] = "138789905852084", ["Gold Ripple"] = "15444464740", ["Red Tiger"] = "15792000933", ["Joe Skeleton"] = "16828401186", } },
    ["Salvaged Python"] = { default = "15188995729", variants = { ["Default"] = "15188995729", ["Canvas"] = "15283200809", ["Hazard"] = "15305731383", ["Saku"] = "16029067988", ["Inferno"] = "16283806768", ["Shockwave"] = "17366304773", ["Independence"] = "18341881121", ["Stellark"] = "124497972716738", ["Hyper"] = "85697748071844", ["Smudge"] = "76952866923184", ["Medal"] = "128419932789140", ["Blue Prey"] = "15574225312", ["Pink Canvas"] = "16663261806", ["Crimson Glitched"] = "16912320052", ["Black Ice"] = "138482014642051", } },
    ["Salvaged RPG"] = { default = "15132772506", variants = { ["Default"] = "15132772506", ["Blast"] = "15305772236", ["Boomstick"] = "18965877488", ["Festive"] = "81287503464820", } },
    ["Salvaged SMG"] = { default = "15132874040", variants = { ["Default"] = "15132874040", ["Splat"] = "15313314715", ["Inferno"] = "15883391466", ["Checkmate"] = "16114277804", ["Valentine"] = "16281529715", ["Knight"] = "17366143384", ["Tempest"] = "18966646387", ["Joker"] = "104734469891887", ["Ducky"] = "119924390182546", ["Fire and Ice"] = "15312330570", ["Red Urban"] = "15574233065", ["Evil Easter"] = "16916946492", ["Digital Candy"] = "18557168240", ["Game Buddy"] = "75480260862201", ["Black Ice"] = "109856083708178", ["Elite Bunny"] = "138479957487119", } },
    ["Salvaged Shotgun"] = { default = "128621428767531", variants = { ["Default"] = "128621428767531", ["Banana"] = "90420924851404", ["HotDog"] = "94732589170018", ["Camo"] = "85391407055752", } },
    ["Salvaged Skorpion"] = { default = "15369212859", variants = { ["Default"] = "15369212859", ["Gingerbread"] = "15637191692", ["Superior"] = "15950161435", ["Pegasus"] = "16577230942", ["Surge"] = "18149214997", ["Rusty"] = "87710451691684", ["Comic"] = "103323135308928", ["Celestial"] = "102882157920367", ["Cyber Revenge"] = "112592127248445", } },
    ["Salvaged Sniper"] = { default = "74470836610605", variants = { ["Default"] = "74470836610605", ["Valentine"] = "134067753909583", ["Radioactive"] = "128500957974672", } },
    ["Santa Hat"] = { default = "15636087096", variants = { ["Default"] = "15636087096", } },
    ["Shop Machine"] = { default = "16769451135", variants = { ["Default"] = "16769451135", } },
    ["Shorts"] = { default = "14654791921", variants = { ["Default"] = "14654791921", ["Beach Day"] = "106157418298863", } },
    ["Sleeping Bag"] = { default = "15313154200", variants = { ["Default"] = "15313154200", ["Prismatic"] = "15574227229", ["Santa"] = "15715978392", ["Shark"] = "16117442613", ["Voxel"] = "18147427074", ["Spooky"] = "85015559308510", ["Fruit"] = "81952434018281", ["UwU"] = "96904970768142", ["Chocolate"] = "108416357231982", ["Cucumber John"] = "15313175563", ["Big Pillow"] = "128662593449303", } },
    ["Small Battery"] = { default = "88959343384498", variants = { ["Default"] = "88959343384498", } },
    ["Small Storage Box"] = { default = "15094083341", variants = { ["Default"] = "15094083341", ["Monster"] = "15883290696", ["Comic"] = "16577230729", ["Gremlin"] = "16748563435", ["Burger"] = "95806776502625", ["Medical"] = "97915388339168", } },
    ["Solar Panel"] = { default = "81539973869850", variants = { ["Default"] = "81539973869850", } },
    ["Steel Axe"] = { default = "13206734202", variants = { ["Default"] = "13206734202", ["Ruby"] = "15444465626", ["Freeze"] = "15712516834", ["Lava"] = "81357829552245", ["Fire Axe"] = "17199281023", } },
    ["Steel Chestplate"] = { default = "14654791689", variants = { ["Default"] = "14654791689", ["Frosty"] = "15305683641", ["OBEY"] = "15305695517", ["Woodland"] = "16447572145", ["Tyrant"] = "140168023066476", ["Oni"] = "126974041982300", ["Dune"] = "105836010915280", ["OH Deer"] = "15630407338", ["Hot Rod"] = "17768833992", ["Phantom Rider"] = "116301304304192", } },
    ["Steel Door"] = { default = "15132554218", variants = { ["Default"] = "15132554218", ["Galactic"] = "16483736587", ["Tyrant"] = "90255972475887", ["Duck"] = "132207599970757", ["Christmas Tree"] = "15638295051", } },
    ["Steel Double Door"] = { default = "15132553963", variants = { ["Default"] = "15132553963", ["Vaporwave"] = "17199280862", ["Red Lotus"] = "130069862861998", ["Elven Gate"] = "95946321412209", } },
    ["Steel Helmet"] = { default = "14654791532", variants = { ["Default"] = "14654791532", ["Golden"] = "15305714913", ["Frosty"] = "15305683226", ["OBEY"] = "15305695029", ["VIP"] = "16014684244", ["Cardboard"] = "15627624994", ["Woodland"] = "16447574211", ["Tyrant"] = "109539796004549", ["Bomo"] = "80249585885084", ["Hockey"] = "97015125505963", ["Fear"] = "81724456402833", ["Oni"] = "114978122703010", ["Dune"] = "72849082443137", ["OH Deer"] = "15630406001", ["Hot Rod"] = "17768832901", ["Phantom Rider"] = "122478227429676", } },
    ["Steel Leggings"] = { default = "14654791387", variants = { ["Default"] = "14654791387", ["Frosty"] = "15305684250", ["OBEY"] = "15311675719", ["Woodland"] = "16447575529", ["Tyrant"] = "79519920346999", ["Oni"] = "98478307520733", ["Dune"] = "76898574981463", ["OH Deer"] = "15630408363", ["Hot Rod"] = "17768833765", ["Phantom Rider"] = "85294785312442", } },
    ["Steel Pickaxe"] = { default = "13206733920", variants = { ["Default"] = "13206733920", ["Cross"] = "15444466662", ["Freeze"] = "15712518908", ["Molten"] = "18762535576", ["Ice Pick"] = "17750836356", } },
    ["Steel Shovel"] = { default = "15074351964", variants = { ["Default"] = "15074351964", ["Heart of Spades"] = "113366819252362", } },
    ["Stone Hatchet"] = { default = "15073617325", variants = { ["Default"] = "15073617325", ["Molten"] = "15305732445", ["Shark"] = "16208668072", ["VIP"] = "16014755281", ["Valentine"] = "16281532811", ["Slime"] = "80657230310751", ["Candy Cane"] = "113420518729636", ["Love Trip"] = "106301749629689", } },
    ["Stone Pickaxe"] = { default = "15073617163", variants = { ["Default"] = "15073617163", ["Molten"] = "15305731898", ["VIP"] = "16014754516", ["Valentine"] = "16281531919", ["Love Trip"] = "120075663072035", } },
    ["Storage Cabinet"] = { default = "15572100650", variants = { ["Default"] = "15572100650", ["Monster"] = "15631715604", ["Hades"] = "16293483340", ["Tyrant"] = "125396135034194", ["Server"] = "83936574533516", ["Gift Wrap"] = "118868800240580", ["Winter Wrap"] = "91326939040045", } },
    ["Tank Top"] = { default = "14654791246", variants = { ["Default"] = "14654791246", } },
    ["Trap Door"] = { default = "13143032792", variants = { ["Default"] = "13143032792", } },
    ["Triangle Trap Door"] = { default = "13724822281", variants = { ["Default"] = "13724822281", } },
    ["Water Turbine"] = { default = "118840048689367", variants = { ["Default"] = "118840048689367", } },
    ["Wetsuit"] = { default = "15304093679", variants = { ["Default"] = "15304093679", ["Pink"] = "17363544575", ["Frog"] = "80603678790020", } },
    ["Windmill"] = { default = "84509705966195", variants = { ["Default"] = "84509705966195", } },
    ["Wooden Bow"] = { default = "15313266356", variants = { ["Default"] = "15313266356", ["Cupid"] = "16260403928", ["Crimson"] = "16912320324", ["Dragon"] = "119198626388204", ["Blue Fissure"] = "15313269139", ["Sweet Gingerbread"] = "15623006255", ["Ancient Bone"] = "136557779662161", } },
    ["Wooden Chestplate"] = { default = "14776135830", variants = { ["Default"] = "14776135830", ["Crimson Bunny"] = "16912321117", } },
    ["Wooden Door"] = { default = "15132568626", variants = { ["Default"] = "15132568626", ["Beware"] = "15305026376", ["Chocolate"] = "15712523927", ["Cardboard"] = "132805078818983", ["Pixel"] = "106378082611103", ["Wise"] = "101629446511815", ["Pot of Gold"] = "16748559894", ["Summer Time"] = "18762630774", ["Christmas Tree"] = "111412634443690", } },
    ["Wooden Double Door"] = { default = "15132568988", variants = { ["Default"] = "15132568988", ["Rainbow"] = "15344501592", ["Cherry Blossom"] = "16577230495", ["Barn Doors"] = "17497777892", } },
    ["Wooden Helmet"] = { default = "14776135648", variants = { ["Default"] = "14776135648", ["Crimson Bunny"] = "16912320885", } },
    ["Wooden Leggings"] = { default = "14776135514", variants = { ["Default"] = "14776135514", ["Crimson Bunny"] = "16912320687", } },
    ["Wreath"] = { default = "125156247966096", variants = { ["Default"] = "125156247966096", } },
}
function M.get_asset_id(name, variant)
    local row = name and M.by_name[name]
    if not row then return nil end
    if variant and row.variants and row.variants[variant] then
        return row.variants[variant]
    end
    return row.default
end
return M
end)()

April._mods["game.attachment_images"] = (function()
local M = {}
M.by_name = {
    ["Bruno's ACOG Sight"] = "15426865503",
    ["Compensator"] = "15347030703",
    ["Holo Sight"] = "14162017273",
    ["Military ACOG Sight"] = "15426865503",
    ["Military Lasersight"] = "15376726516",
    ["Military Sniper Scope"] = "14764545466",
    ["Muzzle Boost"] = "15347030553",
    ["Salvaged Lasersight"] = "15347030437",
    ["Salvaged Sight"] = "13816428922",
    ["Salvaged Sniper Scope"] = "14623616888",
    ["Silencer"] = "15347030257",
    ["Weapon Flashlight"] = "15360516663",
}
function M.get_asset_id(name)
    return name and M.by_name[name]
end
return M
end)()

April._mods["game.item_catalog"] = (function()
local M = {}
M.by_id = {
    [1] = { name = "Wood Log", type = "Resource" },
    [2] = { name = "Bandage", type = "Tool" },
    [3] = { name = "Stone Hatchet", type = "Tool" },
    [4] = { name = "Heavy Ammo", type = "Ammo" },
    [5] = { name = "Salvaged AK47", type = "Gun" },
    [6] = { name = "Bottle Caps", type = "Resource" },
    [7] = { name = "Holo Sight", type = "Attachment" },
    [8] = { name = "Silencer", type = "Attachment" },
    [9] = { name = "Salvaged M14", type = "Gun" },
    [10] = { name = "Lighter", type = "Tool" },
    [11] = { name = "Swift Heavy Ammo", type = "Ammo" },
    [12] = { name = "Salvaged Sight", type = "Attachment" },
    [13] = { name = "Muzzle Boost", type = "Attachment" },
    [14] = { name = "Compensator", type = "Attachment" },
    [15] = { name = "Salvaged Lasersight", type = "Attachment" },
    [16] = { name = "Weapon Flashlight", type = "Attachment" },
    [17] = { name = "Salvaged Sniper Scope", type = "Attachment" },
    [18] = { name = "Military Sniper Scope", type = "Attachment" },
    [19] = { name = "Wooden Spear", type = "Tool" },
    [20] = { name = "Stone Spear", type = "Tool" },
    [21] = { name = "Stone Pickaxe", type = "Tool" },
    [22] = { name = "Crossbow", type = "Gun" },
    [23] = { name = "Wooden Bow", type = "Gun" },
    [24] = { name = "Cloth", type = "Resource" },
    [25] = { name = "Cactus Flesh", type = "Consumable" },
    [26] = { name = "Stone", type = "Resource" },
    [27] = { name = "Iron Ore", type = "Resource" },
    [28] = { name = "Quality Iron Ore", type = "Resource" },
    [29] = { name = "Campfire", type = "Bench" },
    [30] = { name = "Blueprint", type = "Tool" },
    [31] = { name = "Hammer", type = "Tool" },
    [32] = { name = "Raw Pork", type = "Consumable" },
    [33] = { name = "Cooked Pork", type = "Consumable" },
    [34] = { name = "Charcoal", type = "Resource" },
    [35] = { name = "Salvaged P250", type = "Gun" },
    [36] = { name = "Light Ammo", type = "Ammo" },
    [37] = { name = "Boulder", type = "Tool" },
    [38] = { name = "Salvaged SMG", type = "Gun" },
    [39] = { name = "Salvaged Python", type = "Gun" },
    [40] = { name = "Combustive Heavy Ammo", type = "Ammo" },
    [41] = { name = "Animal Fat", type = "Resource" },
    [42] = { name = "Small Storage Box", type = "Bench" },
    [43] = { name = "Raw Venison", type = "Consumable" },
    [44] = { name = "Cooked Venison", type = "Consumable" },
    [45] = { name = "Iron Shards", type = "Resource" },
    [46] = { name = "Steel Metal", type = "Resource" },
    [47] = { name = "Wooden Door", type = "Bench" },
    [48] = { name = "Wooden Lock", type = "Lock" },
    [49] = { name = "Combination Lock", type = "Lock" },
    [50] = { name = "Salvaged Metal Door", type = "Bench" },
    [51] = { name = "Base Cabinet", type = "Bench" },
    [52] = { name = "Wooden Double Door", type = "Bench" },
    [53] = { name = "Wooden Window Bars", type = "Bench" },
    [54] = { name = "Metal Window Bars", type = "Bench" },
    [55] = { name = "Glass Window", type = "Bench" },
    [56] = { name = "Steel Glass Window", type = "Bench" },
    [57] = { name = "Trap Door", type = "Bench" },
    [58] = { name = "Radiation Vitamins", type = "Consumable" },
    [59] = { name = "Hoodie", type = "Armor", armor_type = "Shirt" },
    [60] = { name = "Hazmat Suit", type = "Armor", armor_type = "All", attribute = "ResistWet" },
    [61] = { name = "Chicken MRE", type = "Consumable" },
    [62] = { name = "Beef MRE", type = "Consumable" },
    [63] = { name = "Pants", type = "Armor", armor_type = "Pants" },
    [64] = { name = "Phosphate Ore", type = "Resource" },
    [65] = { name = "Phosphate Dust", type = "Resource" },
    [66] = { name = "Leather", type = "Resource" },
    [67] = { name = "Furnace", type = "Bench" },
    [68] = { name = "Crude Fuel", type = "Resource" },
    [69] = { name = "Gunpowder", type = "Resource" },
    [70] = { name = "Bone Shards", type = "Resource" },
    [71] = { name = "Metal Door", type = "Bench" },
    [72] = { name = "Metal Double Door", type = "Bench" },
    [73] = { name = "Steel Door", type = "Bench" },
    [74] = { name = "Steel Double Door", type = "Bench" },
    [75] = { name = "Nail Gun", type = "Gun" },
    [76] = { name = "Steel Axe", type = "Tool" },
    [77] = { name = "Steel Pickaxe", type = "Tool" },
    [78] = { name = "Power Cell", type = "Misc" },
    [79] = { name = "Copper Cogs", type = "Misc" },
    [80] = { name = "Pipe", type = "Misc" },
    [81] = { name = "Propane Tank", type = "Misc" },
    [82] = { name = "Rope", type = "Misc" },
    [83] = { name = "Blade", type = "Misc" },
    [84] = { name = "Thread", type = "Misc" },
    [85] = { name = "Metal Plating", type = "Misc" },
    [86] = { name = "Spring", type = "Misc" },
    [87] = { name = "Tarp", type = "Misc" },
    [88] = { name = "Circuit Boards", type = "Misc" },
    [89] = { name = "Metal Scraps", type = "Misc" },
    [90] = { name = "Swift Light Ammo", type = "Ammo" },
    [91] = { name = "Sleeping Bag", type = "Bench" },
    [92] = { name = "Timed Charge", type = "Tool" },
    [93] = { name = "Nails", type = "Ammo" },
    [94] = { name = "Garage Door", type = "Bench" },
    [95] = { name = "Dynamite Bundle", type = "Tool" },
    [96] = { name = "Dynamite Stick", type = "Tool" },
    [97] = { name = "Salvaged RPG", type = "Gun" },
    [98] = { name = "Rocket", type = "Ammo" },
    [99] = { name = "Swift Rocket", type = "Ammo" },
    [100] = { name = "Combustive Rocket", type = "Ammo" },
    [101] = { name = "External Wooden Wall", type = "Bench" },
    [102] = { name = "External Wooden Gate", type = "Bench" },
    [103] = { name = "Vertical Window Cover", type = "Bench" },
    [104] = { name = "Horizontal Window Cover", type = "Bench" },
    [105] = { name = "Jail Wall", type = "Bench" },
    [106] = { name = "Jail Door", type = "Bench" },
    [107] = { name = "%s's Trophy", type = "Bench" },
    [108] = { name = "Salvaged AK74u", type = "Gun" },
    [109] = { name = "Salvaged Pipe Rifle", type = "Gun" },
    [110] = { name = "Petroleum", type = "Resource" },
    [111] = { name = "Boots", type = "Armor", armor_type = "Boots" },
    [112] = { name = "Collared Shirt", type = "Armor", armor_type = "Shirt" },
    [113] = { name = "Shorts", type = "Armor", armor_type = "Pants" },
    [114] = { name = "Tank Top", type = "Armor", armor_type = "Shirt" },
    [115] = { name = "Cloth Shirt", type = "Armor", armor_type = "Shirt" },
    [116] = { name = "Cloth Pants", type = "Armor", armor_type = "Pants" },
    [117] = { name = "Cloth Footwraps", type = "Armor", armor_type = "Boots" },
    [118] = { name = "Leather Poncho", type = "Armor", armor_type = "Chestplate" },
    [119] = { name = "Leather Pants", type = "Armor", armor_type = "Pants" },
    [120] = { name = "Leather Shirt", type = "Armor", armor_type = "Shirt" },
    [121] = { name = "Leather Boots", type = "Armor", armor_type = "Boots" },
    [122] = { name = "Flannel Jacket", type = "Armor", armor_type = "Chestplate" },
    [123] = { name = "Wooden Helmet", type = "Armor", armor_type = "Hat" },
    [124] = { name = "Wooden Chestplate", type = "Armor", armor_type = "Chestplate" },
    [125] = { name = "Wooden Leggings", type = "Armor", armor_type = "Kilt" },
    [126] = { name = "Wooden Arrow", type = "Ammo" },
    [127] = { name = "Swift Arrow", type = "Ammo" },
    [128] = { name = "Bone Arrow", type = "Ammo" },
    [129] = { name = "Combustive Arrow", type = "Ammo" },
    [130] = { name = "Iron Shard Hatchet", type = "Tool" },
    [131] = { name = "Iron Shard Pickaxe", type = "Tool" },
    [132] = { name = "Large Furnace", type = "Bench" },
    [133] = { name = "Yellow Keycard", type = "Tool" },
    [134] = { name = "Purple Keycard", type = "Tool" },
    [135] = { name = "Pink Keycard", type = "Tool" },
    [136] = { name = "Small Medkit", type = "Tool" },
    [137] = { name = "Salvaged Break Action", type = "Gun" },
    [138] = { name = "Buckshot", type = "Ammo" },
    [139] = { name = "Slug", type = "Ammo" },
    [140] = { name = "Combustive Buckshot", type = "Ammo" },
    [141] = { name = "Steel Helmet", type = "Armor", armor_type = "Helmet" },
    [142] = { name = "Steel Chestplate", type = "Armor", armor_type = "Chestplate" },
    [143] = { name = "Steel Leggings", type = "Armor", armor_type = "Kilt" },
    [144] = { name = "Large Storage Box", type = "Bench" },
    [145] = { name = "Salvaged Helmet", type = "Armor", armor_type = "Helmet" },
    [146] = { name = "Salvaged Chestplate", type = "Armor", armor_type = "Chestplate" },
    [147] = { name = "Salvaged Leggings", type = "Armor", armor_type = "Kilt" },
    [148] = { name = "Military Helmet", type = "Armor", armor_type = "Helmet" },
    [149] = { name = "Military Chestplate", type = "Armor", armor_type = "Chestplate" },
    [150] = { name = "Military Leggings", type = "Armor", armor_type = "Kilt" },
    [151] = { name = "Hard Hat", type = "Armor", armor_type = "Hat" },
    [152] = { name = "Balaclava", type = "Armor", armor_type = "Face" },
    [153] = { name = "Cloth Headwrap", type = "Armor", armor_type = "Helmet" },
    [154] = { name = "Baseball Cap", type = "Armor", armor_type = "Hat" },
    [155] = { name = "Salvaged Gloves", type = "Armor", armor_type = "Gloves" },
    [156] = { name = "Cloth Handwraps", type = "Armor", armor_type = "Gloves" },
    [157] = { name = "Military Gloves", type = "Armor", armor_type = "Gloves" },
    [158] = { name = "Leather Gloves", type = "Armor", armor_type = "Gloves" },
    [159] = { name = "Wetsuit", type = "Armor", armor_type = "Wetsuit", attribute = "ResistWet" },
    [160] = { name = "Flippers", type = "Armor", armor_type = "Boots", attribute = "HasFlippers" },
    [161] = { name = "Diving Tank", type = "Armor", armor_type = "Chestplate", attribute = "HasTank" },
    [162] = { name = "Diving Goggles", type = "Armor", armor_type = "Helmet", attribute = "HasGoggles" },
    [163] = { name = "Cooking Pot", type = "Bench" },
    [164] = { name = "Ladder", type = "Bench" },
    [165] = { name = "Chocolate Bar", type = "Consumable" },
    [166] = { name = "Bean Can", type = "Consumable" },
    [167] = { name = "Meatball Can", type = "Consumable" },
    [168] = { name = "Fish Can", type = "Consumable" },
    [169] = { name = "Water Bottle", type = "Consumable" },
    [170] = { name = "Piercing Heavy Ammo", type = "Ammo" },
    [171] = { name = "Piercing Light Ammo", type = "Ammo" },
    [172] = { name = "Semi Receiver", type = "Misc" },
    [173] = { name = "SMG Receiver", type = "Misc" },
    [174] = { name = "Rifle Receiver", type = "Misc" },
    [175] = { name = "Steel Shovel", type = "Tool" },
    [176] = { name = "Empty Can", type = "Misc" },
    [177] = { name = "Care Package Signal", type = "Tool" },
    [178] = { name = "Duct Tape", type = "Misc" },
    [179] = { name = "Glue", type = "Misc" },
    [180] = { name = "Pistol Receiver", type = "Misc" },
    [181] = { name = "Salvaged Shovel", type = "Tool" },
    [182] = { name = "ez shovel", type = "Tool" },
    [183] = { name = "Anvil", type = "Bench" },
    [184] = { name = "Chemistry Lab", type = "Bench" },
    [185] = { name = "Carpentry Table", type = "Bench" },
    [186] = { name = "Sewing Table", type = "Bench" },
    [187] = { name = "Ammo Press", type = "Bench" },
    [188] = { name = "Culinary Table", type = "Bench" },
    [189] = { name = "Petroleum Refinery", type = "Bench" },
    [190] = { name = "Triangle Trap Door", type = "Bench" },
    [191] = { name = "Military AA12", type = "Gun" },
    [192] = { name = "Repair Table", type = "Bench" },
    [193] = { name = "Salvaged Pump Action", type = "Gun" },
    [194] = { name = "Bed", type = "Bench" },
    [195] = { name = "Wooden Spikes", type = "Bench" },
    [196] = { name = "Military ACOG Sight", type = "Attachment" },
    [197] = { name = "Metal Barricade", type = "Bench" },
    [198] = { name = "Military M4A1", type = "Gun" },
    [199] = { name = "Small Wooden Sign", type = "Bench" },
    [200] = { name = "Large Wooden Sign", type = "Bench" },
    [201] = { name = "Storage Cabinet", type = "Bench" },
    [202] = { name = "External Stone Gate", type = "Bench" },
    [203] = { name = "Bone Tool", type = "Tool" },
    [204] = { name = "Salvaged Skorpion", type = "Gun" },
    [205] = { name = "Candy Cane", type = "Tool" },
    [206] = { name = "Christmas Tree", type = "Bench" },
    [207] = { name = "Santa Hat", type = "Armor", armor_type = "Hat" },
    [208] = { name = "External Stone Wall", type = "Bench" },
    [209] = { name = "Blast Furnace", type = "Bench" },
    [210] = { name = "Military Barrett", type = "Gun" },
    [211] = { name = "Shotgun Turret", type = "Bench" },
    [212] = { name = "Military Grenade", type = "Tool" },
    [213] = { name = "Floor Grill", type = "Bench" },
    [214] = { name = "Bear Trap", type = "Bench" },
    [215] = { name = "Landmine Trap", type = "Bench" },
    [216] = { name = "Saw Bat", type = "Tool" },
    [217] = { name = "Machete", type = "Tool" },
    [218] = { name = "Military PKM", type = "Gun" },
    [219] = { name = "Bruno's ACOG Sight", type = "Attachment" },
    [220] = { name = "Military Lasersight", type = "Attachment" },
    [221] = { name = "Bruno's M4A1", type = "Gun" },
    [222] = { name = "Boss Chestplate", type = "Armor", armor_type = "Chestplate" },
    [223] = { name = "Boss Helmet", type = "Armor", armor_type = "Helmet" },
    [224] = { name = "Bunny Ears", type = "Armor", armor_type = "Hat" },
    [225] = { name = "Carrot Blade", type = "Tool" },
    [226] = { name = "Metal Spikes", type = "Bench" },
    [227] = { name = "Rug", type = "Bench" },
    [228] = { name = "Shop Machine", type = "Bench" },
    [229] = { name = "Chainsaw", type = "Tool" },
    [230] = { name = "Mining Drill", type = "Tool" },
    [231] = { name = "Extended Mag", type = "Attachment" },
    [232] = { name = "Jukebox", type = "Bench" },
    [233] = { name = "Wool Plant Seed", type = "Bench" },
    [234] = { name = "Wool", type = "Resource" },
    [235] = { name = "Loom", type = "Bench" },
    [236] = { name = "Small Planter Box", type = "Bench" },
    [237] = { name = "Large Planter Box", type = "Bench" },
    [238] = { name = "Tomato Plant Seed", type = "Bench" },
    [239] = { name = "Corn Plant Seed", type = "Bench" },
    [240] = { name = "Tomato", type = "Consumable" },
    [241] = { name = "Corn", type = "Consumable" },
    [242] = { name = "Chicken Egg", type = "Consumable" },
    [243] = { name = "Milk", type = "Consumable" },
    [244] = { name = "Raspberry Pie I", type = "Consumable" },
    [245] = { name = "Raspberry Pie II", type = "Consumable" },
    [246] = { name = "Raspberry Pie III", type = "Consumable" },
    [247] = { name = "Raspberry Pie IV", type = "Consumable" },
    [248] = { name = "Blueberry Pie I", type = "Consumable" },
    [249] = { name = "Blueberry Pie II", type = "Consumable" },
    [250] = { name = "Blueberry Pie III", type = "Consumable" },
    [251] = { name = "Blueberry Pie IV", type = "Consumable" },
    [252] = { name = "Lemon Cake I", type = "Consumable" },
    [253] = { name = "Lemon Cake II", type = "Consumable" },
    [254] = { name = "Lemon Cake III", type = "Consumable" },
    [255] = { name = "Lemon Cake IV", type = "Consumable" },
    [256] = { name = "Corn Bread I", type = "Consumable" },
    [257] = { name = "Corn Bread II", type = "Consumable" },
    [258] = { name = "Corn Bread III", type = "Consumable" },
    [259] = { name = "Corn Bread IV", type = "Consumable" },
    [260] = { name = "Cow Pasture", type = "Bench" },
    [261] = { name = "Chicken House", type = "Bench" },
    [262] = { name = "Barrel Light", type = "Bench" },
    [263] = { name = "Raspberries", type = "Consumable" },
    [264] = { name = "Blueberries", type = "Consumable" },
    [265] = { name = "Lemon", type = "Consumable" },
    [266] = { name = "Lemon Plant Seed", type = "Bench" },
    [267] = { name = "Raspberry Plant Seed", type = "Bench" },
    [268] = { name = "Blueberry Plant Seed", type = "Bench" },
    [269] = { name = "Military MP7", type = "Gun" },
    [270] = { name = "Red Keycard", type = "Tool" },
    [271] = { name = "Salvaged Double Barrel", type = "Gun" },
    [272] = { name = "Military Boat", type = "Resource" },
    [273] = { name = "Clan Table", type = "Bench" },
    [274] = { name = "Wooden Boat", type = "Resource" },
    [275] = { name = "Military USP", type = "Gun" },
    [276] = { name = "Common Goodie Bag", type = "Misc" },
    [277] = { name = "Rare Goodie Bag", type = "Misc" },
    [278] = { name = "Epic Goodie Bag", type = "Misc" },
    [279] = { name = "Candle", type = "Bench" },
    [280] = { name = "Armor Stand", type = "Bench" },
    [281] = { name = "Jack-O-Lantern", type = "Bench" },
    [282] = { name = "Small Cobweb", type = "Bench" },
    [283] = { name = "Large Cobweb", type = "Bench" },
    [284] = { name = "Pumpkin Plant Seed", type = "Bench" },
    [285] = { name = "Pumpkin", type = "ConsumableAmmoArmor", armor_type = "Helmet" },
    [286] = { name = "Halloween Scythe", type = "Tool" },
    [287] = { name = "Pumpkin Launcher", type = "Gun" },
    [288] = { name = "Raw Wolf", type = "Consumable" },
    [289] = { name = "Cooked Wolf", type = "Consumable" },
    [290] = { name = "Pumpkin Pie", type = "Consumable" },
    [291] = { name = "Cursed Pumpkin", type = "Ammo" },
    [292] = { name = "Marsh Bar", type = "Consumable" },
    [293] = { name = "Peanut Butter Cup", type = "Consumable" },
    [294] = { name = "Candy Roll", type = "Consumable" },
    [295] = { name = "Scarecrow", type = "Bench" },
    [296] = { name = "Salvaged Shotgun", type = "Gun" },
    [297] = { name = "Salvaged Shell", type = "Ammo" },
    [298] = { name = "Bone Armor", type = "Armor", armor_type = "All" },
    [299] = { name = "Armor Plate", type = "Attachment" },
    [300] = { name = "Heavy Padding", type = "Attachment" },
    [301] = { name = "Night Vision Goggles", type = "Attachment", attribute = "NVG" },
    [302] = { name = "Lightweight Padding", type = "Attachment", attribute = "SilentSteps" },
    [303] = { name = "Resistant Rubber", type = "Attachment" },
    [304] = { name = "Armor Polish", type = "Attachment" },
    [305] = { name = "Water Filter", type = "Attachment", attribute = "WaterFilter" },
    [306] = { name = "Steel Toes", type = "Attachment", attribute = "SteelToes" },
    [307] = { name = "Snorkle", type = "Attachment", attribute = "Snorkle" },
    [308] = { name = "Military Backpack", type = "Backpack" },
    [309] = { name = "Salvaged Backpack", type = "Backpack" },
    [310] = { name = "Salvaged Sniper", type = "Gun" },
    [311] = { name = "Military Grenade Launcher", type = "Gun" },
    [312] = { name = "Explosive Shell", type = "Ammo" },
    [313] = { name = "Salvaged Flycopter", type = "Resource" },
    [314] = { name = "Fireplace", type = "Bench" },
    [315] = { name = "Black Keycard", type = "Tool" },
    [316] = { name = "Salvaged Grenade Launcher", type = "Gun" },
    [317] = { name = "Salvaged Explosive Shell", type = "Ammo" },
    [318] = { name = "Shotgun Shell", type = "Ammo" },
    [319] = { name = "Large Medkit", type = "Consumable" },
    [320] = { name = "Small Battery", type = "Bench" },
    [321] = { name = "Medium Battery", type = "Bench" },
    [322] = { name = "Large Battery", type = "Bench" },
    [323] = { name = "Crude Fuel Generator", type = "Bench" },
    [324] = { name = "Solar Panel", type = "Bench" },
    [325] = { name = "Water Turbine", type = "Bench" },
    [326] = { name = "Wire Cutters", type = "Tool" },
    [327] = { name = "Button", type = "Bench" },
    [328] = { name = "Electric Furnace", type = "Bench" },
    [329] = { name = "Electric Heater", type = "Bench" },
    [330] = { name = "Switch", type = "Bench" },
    [331] = { name = "Windmill", type = "Bench" },
    [332] = { name = "Splitter", type = "Bench" },
    [333] = { name = "Military Boat", type = "Resource" },
    [334] = { name = "Auto Turret", type = "Bench" },
    [335] = { name = "Military M39", type = "Gun" },
    [336] = { name = "White Ornament", type = "Resource" },
    [337] = { name = "Red Ornament", type = "Resource" },
    [338] = { name = "Purple Ornament", type = "Resource" },
    [339] = { name = "Wreath", type = "Bench" },
    [340] = { name = "Christmas Lights", type = "Bench" },
    [341] = { name = "Admin Tool", type = "Tool" },
}
M.by_attribute = {
    ["HasFlippers"] = "Flippers",
    ["HasGoggles"] = "Diving Goggles",
    ["HasTank"] = "Diving Tank",
    ["NVG"] = "Night Vision Goggles",
    ["ResistWet"] = "Wetsuit",
    ["SilentSteps"] = "Lightweight Padding",
    ["Snorkle"] = "Snorkle",
    ["SteelToes"] = "Steel Toes",
    ["WaterFilter"] = "Water Filter",
}
M.by_name = {
    ["Wood Log"] = { id = 1, type = "Resource" },
    ["Bandage"] = { id = 2, type = "Tool" },
    ["Stone Hatchet"] = { id = 3, type = "Tool" },
    ["Heavy Ammo"] = { id = 4, type = "Ammo" },
    ["Salvaged AK47"] = { id = 5, type = "Gun" },
    ["Bottle Caps"] = { id = 6, type = "Resource" },
    ["Holo Sight"] = { id = 7, type = "Attachment" },
    ["Silencer"] = { id = 8, type = "Attachment" },
    ["Salvaged M14"] = { id = 9, type = "Gun" },
    ["Lighter"] = { id = 10, type = "Tool" },
    ["Swift Heavy Ammo"] = { id = 11, type = "Ammo" },
    ["Salvaged Sight"] = { id = 12, type = "Attachment" },
    ["Muzzle Boost"] = { id = 13, type = "Attachment" },
    ["Compensator"] = { id = 14, type = "Attachment" },
    ["Salvaged Lasersight"] = { id = 15, type = "Attachment" },
    ["Weapon Flashlight"] = { id = 16, type = "Attachment" },
    ["Salvaged Sniper Scope"] = { id = 17, type = "Attachment" },
    ["Military Sniper Scope"] = { id = 18, type = "Attachment" },
    ["Wooden Spear"] = { id = 19, type = "Tool" },
    ["Stone Spear"] = { id = 20, type = "Tool" },
    ["Stone Pickaxe"] = { id = 21, type = "Tool" },
    ["Crossbow"] = { id = 22, type = "Gun" },
    ["Wooden Bow"] = { id = 23, type = "Gun" },
    ["Cloth"] = { id = 24, type = "Resource" },
    ["Cactus Flesh"] = { id = 25, type = "Consumable" },
    ["Stone"] = { id = 26, type = "Resource" },
    ["Iron Ore"] = { id = 27, type = "Resource" },
    ["Quality Iron Ore"] = { id = 28, type = "Resource" },
    ["Campfire"] = { id = 29, type = "Bench" },
    ["Blueprint"] = { id = 30, type = "Tool" },
    ["Hammer"] = { id = 31, type = "Tool" },
    ["Raw Pork"] = { id = 32, type = "Consumable" },
    ["Cooked Pork"] = { id = 33, type = "Consumable" },
    ["Charcoal"] = { id = 34, type = "Resource" },
    ["Salvaged P250"] = { id = 35, type = "Gun" },
    ["Light Ammo"] = { id = 36, type = "Ammo" },
    ["Boulder"] = { id = 37, type = "Tool" },
    ["Salvaged SMG"] = { id = 38, type = "Gun" },
    ["Salvaged Python"] = { id = 39, type = "Gun" },
    ["Combustive Heavy Ammo"] = { id = 40, type = "Ammo" },
    ["Animal Fat"] = { id = 41, type = "Resource" },
    ["Small Storage Box"] = { id = 42, type = "Bench" },
    ["Raw Venison"] = { id = 43, type = "Consumable" },
    ["Cooked Venison"] = { id = 44, type = "Consumable" },
    ["Iron Shards"] = { id = 45, type = "Resource" },
    ["Steel Metal"] = { id = 46, type = "Resource" },
    ["Wooden Door"] = { id = 47, type = "Bench" },
    ["Wooden Lock"] = { id = 48, type = "Lock" },
    ["Combination Lock"] = { id = 49, type = "Lock" },
    ["Salvaged Metal Door"] = { id = 50, type = "Bench" },
    ["Base Cabinet"] = { id = 51, type = "Bench" },
    ["Wooden Double Door"] = { id = 52, type = "Bench" },
    ["Wooden Window Bars"] = { id = 53, type = "Bench" },
    ["Metal Window Bars"] = { id = 54, type = "Bench" },
    ["Glass Window"] = { id = 55, type = "Bench" },
    ["Steel Glass Window"] = { id = 56, type = "Bench" },
    ["Trap Door"] = { id = 57, type = "Bench" },
    ["Radiation Vitamins"] = { id = 58, type = "Consumable" },
    ["Hoodie"] = { id = 59, type = "Armor", armor_type = "Shirt" },
    ["Hazmat Suit"] = { id = 60, type = "Armor", armor_type = "All", attribute = "ResistWet" },
    ["Chicken MRE"] = { id = 61, type = "Consumable" },
    ["Beef MRE"] = { id = 62, type = "Consumable" },
    ["Pants"] = { id = 63, type = "Armor", armor_type = "Pants" },
    ["Phosphate Ore"] = { id = 64, type = "Resource" },
    ["Phosphate Dust"] = { id = 65, type = "Resource" },
    ["Leather"] = { id = 66, type = "Resource" },
    ["Furnace"] = { id = 67, type = "Bench" },
    ["Crude Fuel"] = { id = 68, type = "Resource" },
    ["Gunpowder"] = { id = 69, type = "Resource" },
    ["Bone Shards"] = { id = 70, type = "Resource" },
    ["Metal Door"] = { id = 71, type = "Bench" },
    ["Metal Double Door"] = { id = 72, type = "Bench" },
    ["Steel Door"] = { id = 73, type = "Bench" },
    ["Steel Double Door"] = { id = 74, type = "Bench" },
    ["Nail Gun"] = { id = 75, type = "Gun" },
    ["Steel Axe"] = { id = 76, type = "Tool" },
    ["Steel Pickaxe"] = { id = 77, type = "Tool" },
    ["Power Cell"] = { id = 78, type = "Misc" },
    ["Copper Cogs"] = { id = 79, type = "Misc" },
    ["Pipe"] = { id = 80, type = "Misc" },
    ["Propane Tank"] = { id = 81, type = "Misc" },
    ["Rope"] = { id = 82, type = "Misc" },
    ["Blade"] = { id = 83, type = "Misc" },
    ["Thread"] = { id = 84, type = "Misc" },
    ["Metal Plating"] = { id = 85, type = "Misc" },
    ["Spring"] = { id = 86, type = "Misc" },
    ["Tarp"] = { id = 87, type = "Misc" },
    ["Circuit Boards"] = { id = 88, type = "Misc" },
    ["Metal Scraps"] = { id = 89, type = "Misc" },
    ["Swift Light Ammo"] = { id = 90, type = "Ammo" },
    ["Sleeping Bag"] = { id = 91, type = "Bench" },
    ["Timed Charge"] = { id = 92, type = "Tool" },
    ["Nails"] = { id = 93, type = "Ammo" },
    ["Garage Door"] = { id = 94, type = "Bench" },
    ["Dynamite Bundle"] = { id = 95, type = "Tool" },
    ["Dynamite Stick"] = { id = 96, type = "Tool" },
    ["Salvaged RPG"] = { id = 97, type = "Gun" },
    ["Rocket"] = { id = 98, type = "Ammo" },
    ["Swift Rocket"] = { id = 99, type = "Ammo" },
    ["Combustive Rocket"] = { id = 100, type = "Ammo" },
    ["External Wooden Wall"] = { id = 101, type = "Bench" },
    ["External Wooden Gate"] = { id = 102, type = "Bench" },
    ["Vertical Window Cover"] = { id = 103, type = "Bench" },
    ["Horizontal Window Cover"] = { id = 104, type = "Bench" },
    ["Jail Wall"] = { id = 105, type = "Bench" },
    ["Jail Door"] = { id = 106, type = "Bench" },
    ["%s's Trophy"] = { id = 107, type = "Bench" },
    ["Salvaged AK74u"] = { id = 108, type = "Gun" },
    ["Salvaged Pipe Rifle"] = { id = 109, type = "Gun" },
    ["Petroleum"] = { id = 110, type = "Resource" },
    ["Boots"] = { id = 111, type = "Armor", armor_type = "Boots" },
    ["Collared Shirt"] = { id = 112, type = "Armor", armor_type = "Shirt" },
    ["Shorts"] = { id = 113, type = "Armor", armor_type = "Pants" },
    ["Tank Top"] = { id = 114, type = "Armor", armor_type = "Shirt" },
    ["Cloth Shirt"] = { id = 115, type = "Armor", armor_type = "Shirt" },
    ["Cloth Pants"] = { id = 116, type = "Armor", armor_type = "Pants" },
    ["Cloth Footwraps"] = { id = 117, type = "Armor", armor_type = "Boots" },
    ["Leather Poncho"] = { id = 118, type = "Armor", armor_type = "Chestplate" },
    ["Leather Pants"] = { id = 119, type = "Armor", armor_type = "Pants" },
    ["Leather Shirt"] = { id = 120, type = "Armor", armor_type = "Shirt" },
    ["Leather Boots"] = { id = 121, type = "Armor", armor_type = "Boots" },
    ["Flannel Jacket"] = { id = 122, type = "Armor", armor_type = "Chestplate" },
    ["Wooden Helmet"] = { id = 123, type = "Armor", armor_type = "Hat" },
    ["Wooden Chestplate"] = { id = 124, type = "Armor", armor_type = "Chestplate" },
    ["Wooden Leggings"] = { id = 125, type = "Armor", armor_type = "Kilt" },
    ["Wooden Arrow"] = { id = 126, type = "Ammo" },
    ["Swift Arrow"] = { id = 127, type = "Ammo" },
    ["Bone Arrow"] = { id = 128, type = "Ammo" },
    ["Combustive Arrow"] = { id = 129, type = "Ammo" },
    ["Iron Shard Hatchet"] = { id = 130, type = "Tool" },
    ["Iron Shard Pickaxe"] = { id = 131, type = "Tool" },
    ["Large Furnace"] = { id = 132, type = "Bench" },
    ["Yellow Keycard"] = { id = 133, type = "Tool" },
    ["Purple Keycard"] = { id = 134, type = "Tool" },
    ["Pink Keycard"] = { id = 135, type = "Tool" },
    ["Small Medkit"] = { id = 136, type = "Tool" },
    ["Salvaged Break Action"] = { id = 137, type = "Gun" },
    ["Buckshot"] = { id = 138, type = "Ammo" },
    ["Slug"] = { id = 139, type = "Ammo" },
    ["Combustive Buckshot"] = { id = 140, type = "Ammo" },
    ["Steel Helmet"] = { id = 141, type = "Armor", armor_type = "Helmet" },
    ["Steel Chestplate"] = { id = 142, type = "Armor", armor_type = "Chestplate" },
    ["Steel Leggings"] = { id = 143, type = "Armor", armor_type = "Kilt" },
    ["Large Storage Box"] = { id = 144, type = "Bench" },
    ["Salvaged Helmet"] = { id = 145, type = "Armor", armor_type = "Helmet" },
    ["Salvaged Chestplate"] = { id = 146, type = "Armor", armor_type = "Chestplate" },
    ["Salvaged Leggings"] = { id = 147, type = "Armor", armor_type = "Kilt" },
    ["Military Helmet"] = { id = 148, type = "Armor", armor_type = "Helmet" },
    ["Military Chestplate"] = { id = 149, type = "Armor", armor_type = "Chestplate" },
    ["Military Leggings"] = { id = 150, type = "Armor", armor_type = "Kilt" },
    ["Hard Hat"] = { id = 151, type = "Armor", armor_type = "Hat" },
    ["Balaclava"] = { id = 152, type = "Armor", armor_type = "Face" },
    ["Cloth Headwrap"] = { id = 153, type = "Armor", armor_type = "Helmet" },
    ["Baseball Cap"] = { id = 154, type = "Armor", armor_type = "Hat" },
    ["Salvaged Gloves"] = { id = 155, type = "Armor", armor_type = "Gloves" },
    ["Cloth Handwraps"] = { id = 156, type = "Armor", armor_type = "Gloves" },
    ["Military Gloves"] = { id = 157, type = "Armor", armor_type = "Gloves" },
    ["Leather Gloves"] = { id = 158, type = "Armor", armor_type = "Gloves" },
    ["Wetsuit"] = { id = 159, type = "Armor", armor_type = "Wetsuit", attribute = "ResistWet" },
    ["Flippers"] = { id = 160, type = "Armor", armor_type = "Boots", attribute = "HasFlippers" },
    ["Diving Tank"] = { id = 161, type = "Armor", armor_type = "Chestplate", attribute = "HasTank" },
    ["Diving Goggles"] = { id = 162, type = "Armor", armor_type = "Helmet", attribute = "HasGoggles" },
    ["Cooking Pot"] = { id = 163, type = "Bench" },
    ["Ladder"] = { id = 164, type = "Bench" },
    ["Chocolate Bar"] = { id = 165, type = "Consumable" },
    ["Bean Can"] = { id = 166, type = "Consumable" },
    ["Meatball Can"] = { id = 167, type = "Consumable" },
    ["Fish Can"] = { id = 168, type = "Consumable" },
    ["Water Bottle"] = { id = 169, type = "Consumable" },
    ["Piercing Heavy Ammo"] = { id = 170, type = "Ammo" },
    ["Piercing Light Ammo"] = { id = 171, type = "Ammo" },
    ["Semi Receiver"] = { id = 172, type = "Misc" },
    ["SMG Receiver"] = { id = 173, type = "Misc" },
    ["Rifle Receiver"] = { id = 174, type = "Misc" },
    ["Steel Shovel"] = { id = 175, type = "Tool" },
    ["Empty Can"] = { id = 176, type = "Misc" },
    ["Care Package Signal"] = { id = 177, type = "Tool" },
    ["Duct Tape"] = { id = 178, type = "Misc" },
    ["Glue"] = { id = 179, type = "Misc" },
    ["Pistol Receiver"] = { id = 180, type = "Misc" },
    ["Salvaged Shovel"] = { id = 181, type = "Tool" },
    ["ez shovel"] = { id = 182, type = "Tool" },
    ["Anvil"] = { id = 183, type = "Bench" },
    ["Chemistry Lab"] = { id = 184, type = "Bench" },
    ["Carpentry Table"] = { id = 185, type = "Bench" },
    ["Sewing Table"] = { id = 186, type = "Bench" },
    ["Ammo Press"] = { id = 187, type = "Bench" },
    ["Culinary Table"] = { id = 188, type = "Bench" },
    ["Petroleum Refinery"] = { id = 189, type = "Bench" },
    ["Triangle Trap Door"] = { id = 190, type = "Bench" },
    ["Military AA12"] = { id = 191, type = "Gun" },
    ["Repair Table"] = { id = 192, type = "Bench" },
    ["Salvaged Pump Action"] = { id = 193, type = "Gun" },
    ["Bed"] = { id = 194, type = "Bench" },
    ["Wooden Spikes"] = { id = 195, type = "Bench" },
    ["Military ACOG Sight"] = { id = 196, type = "Attachment" },
    ["Metal Barricade"] = { id = 197, type = "Bench" },
    ["Military M4A1"] = { id = 198, type = "Gun" },
    ["Small Wooden Sign"] = { id = 199, type = "Bench" },
    ["Large Wooden Sign"] = { id = 200, type = "Bench" },
    ["Storage Cabinet"] = { id = 201, type = "Bench" },
    ["External Stone Gate"] = { id = 202, type = "Bench" },
    ["Bone Tool"] = { id = 203, type = "Tool" },
    ["Salvaged Skorpion"] = { id = 204, type = "Gun" },
    ["Candy Cane"] = { id = 205, type = "Tool" },
    ["Christmas Tree"] = { id = 206, type = "Bench" },
    ["Santa Hat"] = { id = 207, type = "Armor", armor_type = "Hat" },
    ["External Stone Wall"] = { id = 208, type = "Bench" },
    ["Blast Furnace"] = { id = 209, type = "Bench" },
    ["Military Barrett"] = { id = 210, type = "Gun" },
    ["Shotgun Turret"] = { id = 211, type = "Bench" },
    ["Military Grenade"] = { id = 212, type = "Tool" },
    ["Floor Grill"] = { id = 213, type = "Bench" },
    ["Bear Trap"] = { id = 214, type = "Bench" },
    ["Landmine Trap"] = { id = 215, type = "Bench" },
    ["Saw Bat"] = { id = 216, type = "Tool" },
    ["Machete"] = { id = 217, type = "Tool" },
    ["Military PKM"] = { id = 218, type = "Gun" },
    ["Bruno's ACOG Sight"] = { id = 219, type = "Attachment" },
    ["Military Lasersight"] = { id = 220, type = "Attachment" },
    ["Bruno's M4A1"] = { id = 221, type = "Gun" },
    ["Boss Chestplate"] = { id = 222, type = "Armor", armor_type = "Chestplate" },
    ["Boss Helmet"] = { id = 223, type = "Armor", armor_type = "Helmet" },
    ["Bunny Ears"] = { id = 224, type = "Armor", armor_type = "Hat" },
    ["Carrot Blade"] = { id = 225, type = "Tool" },
    ["Metal Spikes"] = { id = 226, type = "Bench" },
    ["Rug"] = { id = 227, type = "Bench" },
    ["Shop Machine"] = { id = 228, type = "Bench" },
    ["Chainsaw"] = { id = 229, type = "Tool" },
    ["Mining Drill"] = { id = 230, type = "Tool" },
    ["Extended Mag"] = { id = 231, type = "Attachment" },
    ["Jukebox"] = { id = 232, type = "Bench" },
    ["Wool Plant Seed"] = { id = 233, type = "Bench" },
    ["Wool"] = { id = 234, type = "Resource" },
    ["Loom"] = { id = 235, type = "Bench" },
    ["Small Planter Box"] = { id = 236, type = "Bench" },
    ["Large Planter Box"] = { id = 237, type = "Bench" },
    ["Tomato Plant Seed"] = { id = 238, type = "Bench" },
    ["Corn Plant Seed"] = { id = 239, type = "Bench" },
    ["Tomato"] = { id = 240, type = "Consumable" },
    ["Corn"] = { id = 241, type = "Consumable" },
    ["Chicken Egg"] = { id = 242, type = "Consumable" },
    ["Milk"] = { id = 243, type = "Consumable" },
    ["Raspberry Pie I"] = { id = 244, type = "Consumable" },
    ["Raspberry Pie II"] = { id = 245, type = "Consumable" },
    ["Raspberry Pie III"] = { id = 246, type = "Consumable" },
    ["Raspberry Pie IV"] = { id = 247, type = "Consumable" },
    ["Blueberry Pie I"] = { id = 248, type = "Consumable" },
    ["Blueberry Pie II"] = { id = 249, type = "Consumable" },
    ["Blueberry Pie III"] = { id = 250, type = "Consumable" },
    ["Blueberry Pie IV"] = { id = 251, type = "Consumable" },
    ["Lemon Cake I"] = { id = 252, type = "Consumable" },
    ["Lemon Cake II"] = { id = 253, type = "Consumable" },
    ["Lemon Cake III"] = { id = 254, type = "Consumable" },
    ["Lemon Cake IV"] = { id = 255, type = "Consumable" },
    ["Corn Bread I"] = { id = 256, type = "Consumable" },
    ["Corn Bread II"] = { id = 257, type = "Consumable" },
    ["Corn Bread III"] = { id = 258, type = "Consumable" },
    ["Corn Bread IV"] = { id = 259, type = "Consumable" },
    ["Cow Pasture"] = { id = 260, type = "Bench" },
    ["Chicken House"] = { id = 261, type = "Bench" },
    ["Barrel Light"] = { id = 262, type = "Bench" },
    ["Raspberries"] = { id = 263, type = "Consumable" },
    ["Blueberries"] = { id = 264, type = "Consumable" },
    ["Lemon"] = { id = 265, type = "Consumable" },
    ["Lemon Plant Seed"] = { id = 266, type = "Bench" },
    ["Raspberry Plant Seed"] = { id = 267, type = "Bench" },
    ["Blueberry Plant Seed"] = { id = 268, type = "Bench" },
    ["Military MP7"] = { id = 269, type = "Gun" },
    ["Red Keycard"] = { id = 270, type = "Tool" },
    ["Salvaged Double Barrel"] = { id = 271, type = "Gun" },
    ["Military Boat"] = { id = 272, type = "Resource" },
    ["Clan Table"] = { id = 273, type = "Bench" },
    ["Wooden Boat"] = { id = 274, type = "Resource" },
    ["Military USP"] = { id = 275, type = "Gun" },
    ["Common Goodie Bag"] = { id = 276, type = "Misc" },
    ["Rare Goodie Bag"] = { id = 277, type = "Misc" },
    ["Epic Goodie Bag"] = { id = 278, type = "Misc" },
    ["Candle"] = { id = 279, type = "Bench" },
    ["Armor Stand"] = { id = 280, type = "Bench" },
    ["Jack-O-Lantern"] = { id = 281, type = "Bench" },
    ["Small Cobweb"] = { id = 282, type = "Bench" },
    ["Large Cobweb"] = { id = 283, type = "Bench" },
    ["Pumpkin Plant Seed"] = { id = 284, type = "Bench" },
    ["Pumpkin"] = { id = 285, type = "ConsumableAmmoArmor", armor_type = "Helmet" },
    ["Halloween Scythe"] = { id = 286, type = "Tool" },
    ["Pumpkin Launcher"] = { id = 287, type = "Gun" },
    ["Raw Wolf"] = { id = 288, type = "Consumable" },
    ["Cooked Wolf"] = { id = 289, type = "Consumable" },
    ["Pumpkin Pie"] = { id = 290, type = "Consumable" },
    ["Cursed Pumpkin"] = { id = 291, type = "Ammo" },
    ["Marsh Bar"] = { id = 292, type = "Consumable" },
    ["Peanut Butter Cup"] = { id = 293, type = "Consumable" },
    ["Candy Roll"] = { id = 294, type = "Consumable" },
    ["Scarecrow"] = { id = 295, type = "Bench" },
    ["Salvaged Shotgun"] = { id = 296, type = "Gun" },
    ["Salvaged Shell"] = { id = 297, type = "Ammo" },
    ["Bone Armor"] = { id = 298, type = "Armor", armor_type = "All" },
    ["Armor Plate"] = { id = 299, type = "Attachment" },
    ["Heavy Padding"] = { id = 300, type = "Attachment" },
    ["Night Vision Goggles"] = { id = 301, type = "Attachment", attribute = "NVG" },
    ["Lightweight Padding"] = { id = 302, type = "Attachment", attribute = "SilentSteps" },
    ["Resistant Rubber"] = { id = 303, type = "Attachment" },
    ["Armor Polish"] = { id = 304, type = "Attachment" },
    ["Water Filter"] = { id = 305, type = "Attachment", attribute = "WaterFilter" },
    ["Steel Toes"] = { id = 306, type = "Attachment", attribute = "SteelToes" },
    ["Snorkle"] = { id = 307, type = "Attachment", attribute = "Snorkle" },
    ["Military Backpack"] = { id = 308, type = "Backpack" },
    ["Salvaged Backpack"] = { id = 309, type = "Backpack" },
    ["Salvaged Sniper"] = { id = 310, type = "Gun" },
    ["Military Grenade Launcher"] = { id = 311, type = "Gun" },
    ["Explosive Shell"] = { id = 312, type = "Ammo" },
    ["Salvaged Flycopter"] = { id = 313, type = "Resource" },
    ["Fireplace"] = { id = 314, type = "Bench" },
    ["Black Keycard"] = { id = 315, type = "Tool" },
    ["Salvaged Grenade Launcher"] = { id = 316, type = "Gun" },
    ["Salvaged Explosive Shell"] = { id = 317, type = "Ammo" },
    ["Shotgun Shell"] = { id = 318, type = "Ammo" },
    ["Large Medkit"] = { id = 319, type = "Consumable" },
    ["Small Battery"] = { id = 320, type = "Bench" },
    ["Medium Battery"] = { id = 321, type = "Bench" },
    ["Large Battery"] = { id = 322, type = "Bench" },
    ["Crude Fuel Generator"] = { id = 323, type = "Bench" },
    ["Solar Panel"] = { id = 324, type = "Bench" },
    ["Water Turbine"] = { id = 325, type = "Bench" },
    ["Wire Cutters"] = { id = 326, type = "Tool" },
    ["Button"] = { id = 327, type = "Bench" },
    ["Electric Furnace"] = { id = 328, type = "Bench" },
    ["Electric Heater"] = { id = 329, type = "Bench" },
    ["Switch"] = { id = 330, type = "Bench" },
    ["Windmill"] = { id = 331, type = "Bench" },
    ["Splitter"] = { id = 332, type = "Bench" },
    ["Military Boat"] = { id = 333, type = "Resource" },
    ["Auto Turret"] = { id = 334, type = "Bench" },
    ["Military M39"] = { id = 335, type = "Gun" },
    ["White Ornament"] = { id = 336, type = "Resource" },
    ["Red Ornament"] = { id = 337, type = "Resource" },
    ["Purple Ornament"] = { id = 338, type = "Resource" },
    ["Wreath"] = { id = 339, type = "Bench" },
    ["Christmas Lights"] = { id = 340, type = "Bench" },
    ["Admin Tool"] = { id = 341, type = "Tool" },
}
function M.get_by_name(name)
    return name and M.by_name[name] or nil
end
function M.get(id)
    return id and M.by_id[id] or nil
end
function M.get_by_attribute(attr)
    local name = attr and M.by_attribute[attr]
    if not name then return nil end
    return { name = name }
end
function M.name_for_armor_model(model_name)
    if not model_name or model_name:sub(1, 6) ~= "Armor_" then return nil end
    local id, skin = model_name:match("^Armor_(%d+)/(.+)$")
    if not id then
        id = model_name:match("^Armor_(%d+)$")
        skin = nil
    end
    if id then
        local row = M.by_id[tonumber(id)]
        if row then return row.name, skin end
    end
    local key = model_name:match("^(.-)/") or model_name
    key = key:gsub(" ", "_")
    local num = key:match("^Armor_(%d+)$")
    if num then
        local row = M.by_id[tonumber(num)]
        if row then return row.name, model_name:match("^.-/(.+)$") end
    end
    local attr = key:match("^Armor_(.+)$")
    if attr then
        local row = M.get_by_attribute(attr)
        if row then return row.name, model_name:match("^.-/(.+)$") end
    end
    return nil
end
return M
end)()

April._mods["game.items"] = (function()
local env = April.require("core.env")
local item_images = April.require("game.item_images")
local attachment_images = April.require("game.attachment_images")
local item_catalog = April.require("game.item_catalog")
local asset_urls = April.require("game.asset_urls")
local M = {}
local loaded = false
local by_name = {}
local FALLBACK = {
    ["Wood Log"] = { Type = "Resource" },
    ["Bandage"] = { Type = "Tool" },
    ["Salvaged M14"] = { Type = "Tool" },
}
local NAME_ALIASES = {
    ["Cloth Head Wrap"] = "Cloth Headwrap",
}
local HELD_TYPES = {
    Gun = true,
    Tool = true,
    Bench = true,
}
local function parse_variant_name(name)
    if not name then return nil, nil end
    local base, variant = name:match("^([^/]+)/(.+)$")
    if base and variant then
        return base, variant
    end
    return name, nil
end
local function rbx_asset_digits(value)
    if value == nil then return nil end
    return tostring(value):match("(%d+)$")
end
local function image_id_from_table(img, variant)
    if type(img) == "string" then
        return rbx_asset_digits(img)
    end
    if type(img) ~= "table" then return nil end
    local pick = (variant and img[variant]) or img.Default or img.default
    if pick then return rbx_asset_digits(pick) end
    return nil
end
local function index_data(data)
    if data[1] and type(data[1]) == "table" then
        for id, entry in ipairs(data) do
            if type(entry) == "table" then
                local cat = item_catalog.get(id)
                if cat and cat.name then
                    entry.Name = cat.name
                    by_name[cat.name] = entry
                end
                by_name[id] = entry
            end
        end
        return
    end
    for key, entry in pairs(data) do
        if type(entry) == "table" then
            if type(key) == "number" then
                local cat = item_catalog.get(key)
                if cat and cat.name then
                    entry.Name = cat.name
                    by_name[cat.name] = entry
                end
                by_name[key] = entry
            else
                entry.Name = entry.Name or key
                by_name[entry.Name] = entry
            end
        end
    end
end
function M.normalize_name(name)
    if not name then return nil end
    return NAME_ALIASES[name] or name
end
function M.load()
    if loaded then return true end
    local rep = env.get_replicated_storage()
    if rep then
        local modules = env.safe_call(function() return rep:find_first_child("Modules") end)
        local items_mod = modules and env.safe_call(function() return modules:find_first_child("Items") end)
        if items_mod then
            local ok, data = pcall(function() return require(items_mod) end)
            if ok and type(data) == "table" then
                index_data(data)
                loaded = true
                return true
            end
        end
    end
    local module_scan = April.require("game.module_scan")
    local data = module_scan.find_items()
    if data then
        index_data(data)
        loaded = true
        return true
    end
    return false
end
function M.invalidate()
    loaded = false
    by_name = {}
end
function M.get(name)
    if not loaded then M.load() end
    return by_name[name] or FALLBACK[name]
end
function M.get_catalog(name)
    return item_catalog.get_by_name(M.normalize_name(name))
end
function M.get_type(name)
    local row = M.get_catalog(name)
    if row then return row.type end
    local item = M.get(name)
    return item and item.Type or "Unknown"
end
function M.is_held_display(name)
    if not name or name == "" then return false end
    local base = select(1, parse_variant_name(name))
    local row = M.get_catalog(base)
    if row and HELD_TYPES[row.type] then return true end
    local t = M.get_type(base)
    return HELD_TYPES[t] == true
end
function M.get_by_id(id)
    if type(id) ~= "number" then return nil end
    if not loaded then M.load() end
    local cat = item_catalog.get(id)
    if cat and cat.name then
        local row = by_name[cat.name]
        if row then return row end
    end
    local rep = env.get_replicated_storage()
    if rep then
        local modules = env.safe_call(function() return rep:find_first_child("Modules") end)
        local items_mod = modules and env.safe_call(function() return modules:find_first_child("Items") end)
        if items_mod then
            local ok, data = pcall(function() return require(items_mod) end)
            if ok and data and data[id] then return data[id] end
        end
    end
    return nil
end
function M.get_image_asset_id(name, variant)
    if not name then return nil end
    name = M.normalize_name(name)
    local cat = item_catalog.get_by_name(name)
    local id = item_images.get_asset_id(name, variant)
    if id then return id end
    id = attachment_images.get_asset_id(name)
    if id then return id end
    if cat and cat.id then
        local item = M.get_by_id(cat.id)
        if item and item.Image then
            id = image_id_from_table(item.Image, variant)
            if id then return id end
        end
    end
    if variant and variant ~= "" and variant ~= "Default" then
        id = item_images.get_asset_id(name, "Default")
        if id then return id end
        if cat and cat.id then
            local item = M.get_by_id(cat.id)
            if item and item.Image then
                id = image_id_from_table(item.Image, "Default")
                if id then return id end
            end
        end
    end
    if not loaded then M.load() end
    local item = by_name[name]
    if item and item.Image then
        return image_id_from_table(item.Image, variant)
    end
    return nil
end
function M.make_piece(name, variant)
    name = M.normalize_name(name)
    if not name or name == "" then return nil end
    return {
        name = name,
        variant = variant,
        asset_id = M.get_image_asset_id(name, variant),
    }
end
function M.resolve_armor_model(model_name)
    if not model_name then return nil end
    local item_name, variant = item_catalog.name_for_armor_model(model_name)
    if not item_name then return nil end
    return M.make_piece(item_name, variant)
end
function M.resolve_item_label(label)
    if not label or label == "" then return nil end
    local base, variant = parse_variant_name(label)
    base = M.normalize_name(base)
    local numeric = tonumber(base)
    if numeric then
        local row = item_catalog.get(numeric)
        if row then
            return M.make_piece(row.name, variant)
        end
    end
    if item_catalog.get_by_name(base) or item_images.get_asset_id(base, variant)
        or attachment_images.get_asset_id(base) then
        return M.make_piece(base, variant)
    end
    if not loaded then M.load() end
    if by_name[base] then
        return M.make_piece(base, variant)
    end
    return nil
end
function M.get_image_url(name, variant)
    local id = M.get_image_asset_id(name, variant)
    if id then return asset_urls.item_png(id) end
    return nil
end
return M
end)()

April._mods["game.weapons"] = (function()
local bootstrap = April.require("game.bootstrap")
local env = April.require("core.env")
local M = {}
local loaded = false
local toolinfo = {}
local weapon_names = {}
local ROBLOX_GRAV = 196.2
local FALLBACK_STATS = {
    ["Military Barret"] = { speed = 2500, gravity = 0.55 },
    ["Military Barrett"] = { speed = 2500, gravity = 0.55 },
    ["Military M4A1"] = { speed = 2100, gravity = 0.55 },
    ["Military M39"] = { speed = 2400, gravity = 0.52 },
    ["Military MP7"] = { speed = 1900, gravity = 0.6 },
    ["Military PKM"] = { speed = 2400, gravity = 0.55 },
    ["Military USP"] = { speed = 1800, gravity = 0.6 },
    ["Military AA12"] = { speed = 400, gravity = 0.6 },
    ["Bruno's M4A1"] = { speed = 2100, gravity = 0.55 },
    ["Salvaged AK47"] = { speed = 2100, gravity = 0.55 },
    ["Salvaged AK74u"] = { speed = 1900, gravity = 0.6 },
    ["Salvaged AK4"] = { speed = 2100, gravity = 0.55 },
    ["Salvaged Sniper"] = { speed = 2100, gravity = 0.55 },
    ["Salvaged M14"] = { speed = 2100, gravity = 0.55 },
    ["Salvaged SMG"] = { speed = 1600, gravity = 0.6 },
    ["Salvaged Skorpion"] = { speed = 1400, gravity = 0.6 },
    ["Salvaged Python"] = { speed = 1500, gravity = 0.6 },
    ["Salvaged P250"] = { speed = 1400, gravity = 0.6 },
    ["Salvaged Pipe Rifle"] = { speed = 800, gravity = 0.55 },
    ["Salvaged Pump Action"] = { speed = 400, gravity = 0.6 },
    ["Salvaged Shotgun"] = { speed = 400, gravity = 0.6 },
    ["Salvaged Double Barrel"] = { speed = 400, gravity = 0.6 },
    ["Salvaged Break Action"] = { speed = 400, gravity = 0.6 },
    ["Crossbow"] = { speed = 420, gravity = 0.2 },
    ["Wooden Bow"] = { speed = 280, gravity = 0.2 },
    ["Nail Gun"] = { speed = 165, gravity = 0.25 },
    ["Pumpkin Launcher"] = { speed = 100, gravity = 0.12 },
    ["Salvaged RPG"] = { speed = 100, gravity = 0.12 },
    ["Military Grenade Launcher"] = { speed = 350, gravity = 0.55 },
    ["Salvaged Grenade Launcher"] = { speed = 350, gravity = 0.55 },
    ["Wooden Spear"] = { speed = 130, gravity = 0.35 },
    ["Stone Spear"] = { speed = 150, gravity = 0.35 },
}
M._last_held = nil
M._last_held_ranged = nil
M._was_in_game = false
M._weapon_changed_at = 0
local function inst_name(inst)
    if not inst then return nil end
    return inst.name or inst.Name
end
local function is_tool(inst)
    if not inst then return false end
    local cn = inst.ClassName or inst.class_name
    return cn == "Tool"
end
local function rebuild_weapon_names()
    weapon_names = {}
    for name in pairs(FALLBACK_STATS) do
        weapon_names[name] = true
    end
    for name in pairs(toolinfo) do
        if type(name) == "string" then
            weapon_names[name] = true
        end
    end
end
function M.is_weapon_name(name)
    return name and weapon_names[name] == true
end
local MELEE_NAME_HINTS = {
    "hatchet", "pickaxe", "pick axe", " axe", "axe ",
    "spear", "machete", "knife", "sword",
    "bone tool", "hammer", "crowbar",
    "chainsaw", "mining drill", "shovel", "scythe",
    "candy cane", "carrot blade", "boulder", "saw bat",
}
local function is_spear_name(name)
    if not name or name == "" then return false end
    return name:lower():find("spear", 1, true) ~= nil
end
local function name_looks_melee(name)
    if is_spear_name(name) then return false end
    local n = (name or ""):lower()
    for _, hint in ipairs(MELEE_NAME_HINTS) do
        if n:find(hint, 1, true) then return true end
    end
    return false
end
function M.is_ranged_weapon_name(name)
    if not name or name == "" then return false end
    local lower = name:lower()
    if lower:find("bow", 1, true) or lower:find("crossbow", 1, true) then return true end
    if is_spear_name(name) then return true end
    if name_looks_melee(name) then return false end
    if not loaded then M.load() end
    local entry = toolinfo[name]
    if entry then
        if entry.Bullet then return true end
        if entry.Melee and not entry.Bullet then return false end
        if entry.Weapon and (entry.Weapon.RPM or entry.Weapon.ActualRPM) then
            return true
        end
        if entry.Melee then return false end
    end
    if FALLBACK_STATS[name] then
        return true
    end
    return false
end
local function children_of(inst)
    if not inst then return {} end
    return env.safe_call(function()
        if inst.get_children then return inst:get_children() end
        return inst:GetChildren()
    end) or {}
end
local function find_child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        return parent:find_first_child(name) or parent:FindFirstChild(name)
    end)
end
local function pick_weapon_from_model(model)
    if not model then return nil, nil end
    local n = inst_name(model)
    if n and M.is_weapon_name(n) then
        return n, model
    end
    for _, child in ipairs(children_of(model)) do
        local cn = inst_name(child)
        if cn and M.is_weapon_name(cn) then
            return cn, child
        end
        local class = child.ClassName or child.class_name
        if class == "Model" and cn and M.is_ranged_weapon_name(cn) then
            return cn, child
        end
    end
    return nil, nil
end
local function find_held_in_viewmodels()
    local ws = env.get_workspace()
    if not ws then return nil end
    local cam = env.safe_call(function()
        return ws.CurrentCamera or ws.currentCamera
            or (ws.FindFirstChild and ws:FindFirstChild("CurrentCamera"))
    end)
    if cam then
        for _, child in ipairs(children_of(cam)) do
            local class = child.ClassName or child.class_name
            if class == "Model" then
                local n, inst = pick_weapon_from_model(child)
                if n then return n, inst end
            end
        end
    end
    local vfx = find_child(ws, "VFX")
    local vms_live = vfx and find_child(vfx, "VMs")
    if vms_live then
        for _, child in ipairs(children_of(vms_live)) do
            local n, inst = pick_weapon_from_model(child)
            if n then return n, inst end
        end
    end
    local vms = find_child(ws, "Viewmodels")
    if vms then
        for _, vm in ipairs(children_of(vms)) do
            if inst_name(vm) == "Viewmodel" then
                local n, inst = pick_weapon_from_model(vm)
                if n then return n, inst end
            end
        end
    end
    return nil, nil
end
local function find_held_in_character(lp)
    local char = lp and lp.character
    if not char or not env.is_valid(char) then return nil, nil end
    local fallback_tool = nil
    for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
        local n = inst_name(child)
        if n and M.is_weapon_name(n) then
            return n, child
        end
        if is_tool(child) and n then
            fallback_tool = fallback_tool or { name = n, inst = child }
        end
    end
    if fallback_tool then
        return fallback_tool.name, fallback_tool.inst
    end
    return nil, nil
end
local function read_tool_attributes(inst)
    if not inst then return nil end
    local speed, gravity
    pcall(function()
        if inst.GetAttribute then
            speed = inst:GetAttribute("BulletSpeed") or inst:GetAttribute("MuzzleVelocity")
            gravity = inst:GetAttribute("BulletGravity") or inst:GetAttribute("ProjectileGravity")
        elseif inst.get_attribute then
            speed = inst:get_attribute("BulletSpeed") or inst:get_attribute("MuzzleVelocity")
            gravity = inst:get_attribute("BulletGravity") or inst:get_attribute("ProjectileGravity")
        end
    end)
    if speed then
        local grav = gravity
        if not grav or grav <= 0 or grav > 2 then
            grav = 0.55
        end
        return {
            speed = speed,
            gravity = grav,
            name = inst_name(inst),
            from_attributes = true,
        }
    end
    return nil
end
function M.get_held_ranged_weapon_name()
    if not loaded then M.load() end
    local lp = env.get_local_player()
    if not lp then return nil end
    local function pick(name)
        if name and M.is_ranged_weapon_name(name) then return name end
    end
    local char = lp.character
    if char and env.is_valid(char) then
        for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
            local hit = pick(inst_name(child))
            if hit then return hit end
        end
    end
    local name = find_held_in_viewmodels()
    if name then
        local hit = pick(name)
        if hit then return hit end
    end
    return pick(lp.tool_name)
end
function M.holding_ranged_weapon()
    return M._last_held_ranged ~= nil
end
function M.cached_held_ranged()
    return M._last_held_ranged
end
function M.is_bow_weapon_name(name)
    if not name then return false end
    if not loaded then M.load() end
    local entry = toolinfo[name]
    if entry and entry.Weapon and entry.Weapon.IsBow then
        return true
    end
    local n = name:lower()
    if n:find("crossbow", 1, true) then return true end
    if n:find("wooden bow", 1, true) then return true end
    if n == "bow" or n:sub(-4) == " bow" then return true end
    return false
end
function M.invalidate()
    loaded = false
    toolinfo = {}
    recoil_weapons = {}
    weapon_names = {}
    M._last_held = nil
    M._last_held_ranged = nil
    M._weapon_changed_at = 0
    pcall(function()
        local origin = April.require("game.combat_origin")
        if origin.invalidate then origin.invalidate() end
    end)
end
function M.in_game_ready()
    if env.get_local_player() then return true end
    local cache = April.require("core.cache")
    if cache.local_player or #cache.all_entities > 0 then return true end
    return false
end
function M.load()
    if loaded then return true end
    local data = bootstrap.get_module("ToolInfo")
    if type(data) ~= "table" then
        rebuild_weapon_names()
        return false
    end
    toolinfo = data
    rebuild_weapon_names()
    loaded = next(toolinfo) ~= nil
    return loaded
end
function M.get(name)
    if not loaded then M.load() end
    return toolinfo[name]
end
function M.profile_weapon_names()
    if not loaded then M.load() end
    local farm = nil
    pcall(function()
        farm = April.require("game.farm_tools")
        if farm and farm.load then farm.load() end
    end)
    local seen = {}
    local list = {}
    local function add(name)
        if not name or name == "" or seen[name] then return end
        if not M.is_ranged_weapon_name(name) then return end
        if farm and farm.is_farm_tool_name and farm.is_farm_tool_name(name) then return end
        seen[name] = true
        list[#list + 1] = name
    end
    for name in pairs(toolinfo) do
        add(name)
    end
    for name in pairs(FALLBACK_STATS) do
        add(name)
    end
    table.sort(list)
    return list
end
function M.get_held_weapon_name()
    rebuild_weapon_names()
    local lp = env.get_local_player()
    if not lp then return nil end
    local name, inst = find_held_in_character(lp)
    if name then return name end
    name = find_held_in_viewmodels()
    if name then return name end
    if lp.tool_name and lp.tool_name ~= "" then
        if M.is_weapon_name(lp.tool_name) or loaded then
            return lp.tool_name
        end
    end
    return nil
end
function M.get_held_tool()
    local lp = env.get_local_player()
    if not lp then return nil, nil end
    local name, inst = find_held_in_character(lp)
    if name then return name, inst end
    name = find_held_in_viewmodels()
    return name, nil
end
function M.drop_gravity(grav)
    if not grav or grav <= 0 then return ROBLOX_GRAV * 0.55 end
    if grav <= 2 then return grav * ROBLOX_GRAV end
    return grav
end
function M.get_weapon_stats(name)
    name = name or M.get_held_weapon_name()
    if not name then return nil end
    local entry = M.get(name)
    if entry and entry.Bullet then
        return {
            speed = entry.Bullet.Speed or 950,
            gravity = entry.Bullet.Gravity or 0.55,
            name = name,
            from_toolinfo = true,
            is_bow = M.is_bow_weapon_name(name),
        }
    end
    local fb = FALLBACK_STATS[name]
    if fb then
        return {
            speed = fb.speed,
            gravity = fb.gravity,
            name = name,
            from_fallback = true,
            is_bow = M.is_bow_weapon_name(name),
        }
    end
    local _, tool_inst = M.get_held_tool()
    if tool_inst then
        local from_attrs = read_tool_attributes(tool_inst)
        if from_attrs then
            from_attrs.name = name
            return from_attrs
        end
    end
    return { speed = 950, gravity = 0.55, name = name }
end
function M.tick()
    local in_game = M.in_game_ready()
    if not in_game then
        if M._was_in_game then
            M._last_held = nil
            M._last_held_ranged = nil
            M._weapon_changed_at = 0
        end
        M._was_in_game = false
        return nil
    end
    if not M._was_in_game then
        M._was_in_game = true
        M.load()
    end
    if not loaded and bootstrap.is_ready and bootstrap.is_ready() then
        M.load()
    end
    local held = M.get_held_ranged_weapon_name()
    if held ~= M._last_held_ranged then
        M._last_held = held
        M._last_held_ranged = held
        M._weapon_changed_at = utility and utility.get_tick_count and utility.get_tick_count() or 0
        pcall(function()
            local origin = April.require("game.combat_origin")
            if origin.invalidate then origin.invalidate() end
        end)
        pcall(function()
            local gun_mods = April.require("features.combat.gun_mods")
            if gun_mods.on_weapon_changed then
                gun_mods.on_weapon_changed(held)
            end
        end)
    end
    return held
end
function M.on_modules_ready()
    M.load()
    pcall(function()
        farm_tools = April.require("game.farm_tools")
        if farm_tools.invalidate then farm_tools.invalidate() end
        if farm_tools.load then farm_tools.load() end
    end)
    pcall(function()
        local gun_mods = April.require("features.combat.gun_mods")
        if gun_mods.on_modules_ready then
            gun_mods.on_modules_ready()
        end
    end)
end
return M
end)()

April._mods["game.gc_weapon_mods"] = (function()
local debug = April.require("core.debug")
local env = April.require("core.env")
local M = {}
M.WEAPON_FIND_KEYS = {
    "RecoilMult",
    "RangeMult",
    "SpeedMult",
    "AimSpreadMult",
    "HipSpreadMult",
    "SwayMult",
    "FireRateMult",
}
M.ALLOWED = {
    RecoilMult = true,
    RangeMult = true,
    SpeedMult = true,
    AimSpreadMult = true,
    HipSpreadMult = true,
    SwayMult = true,
    FireRateMult = true,
}
M._last_node_count = 0
M._last_apply_ms = 0
M._last_refresh_ms = 0
M._fail_streak = 0
M._session_token = nil
M._disabled_until = 0
local MIN_APPLY_GAP_MS = 450
local MIN_REFRESH_GAP_MS = 5000
local FAIL_BACKOFF_MS = 1500
local MAX_FAIL_STREAK = 8
local COOLDOWN_MS = 15000
local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end
local function has_api()
    return type(refreshgc) == "function"
        and type(getgc) == "function"
        and type(applygc) == "function"
end
local function session_token()
    if not game then return "none" end
    local pid = game.place_id or 0
    local gid = game.game_id or 0
    local ws = game.workspace
    local ws_addr = (ws and (ws.Address or ws.address)) or 0
    return tostring(pid) .. ":" .. tostring(gid) .. ":" .. tostring(ws_addr)
end
function M.available()
    return has_api()
end
function M.last_node_count()
    return M._last_node_count
end
function M.in_game()
    return env.get_local_player() ~= nil
end
function M.cooldown_remaining_ms()
    local now = tick_ms()
    if M._disabled_until <= now then return 0 end
    return M._disabled_until - now
end
local function note_failure(reason)
    M._fail_streak = M._fail_streak + 1
    if M._fail_streak >= MAX_FAIL_STREAK then
        M._disabled_until = tick_ms() + COOLDOWN_MS
        M._fail_streak = 0
        M._last_node_count = 0
        debug.warn_once("gun_mods:cooldown", "Gun mods paused after repeated GC failures: " .. tostring(reason))
    end
end
local function note_success(patched)
    M._fail_streak = 0
    M._disabled_until = 0
    if patched and patched > 0 then
        M._last_node_count = math.max(M._last_node_count, patched)
    end
end
local function sanitize_payload(mods)
    local out = {}
    for k, v in pairs(mods) do
        if M.ALLOWED[k] and v ~= nil then
            out[k] = tonumber(v) or v
        end
    end
    return out
end
local function keys_for_payload(payload)
    local keys = {}
    for k in pairs(payload) do
        keys[#keys + 1] = k
    end
    table.sort(keys)
    return keys
end
local function warm_nodes(keys)
    local count = 0
    local ok, result = pcall(getgc, keys)
    if ok and type(result) == "number" then
        count = result
    end
    return count
end
local function maybe_refresh(force)
    local now = tick_ms()
    local tok = session_token()
    if tok ~= M._session_token then
        M._session_token = tok
        M._last_node_count = 0
        force = true
    end
    if not force and M._last_node_count > 0 then
        return
    end
    if not force and (now - M._last_refresh_ms) < MIN_REFRESH_GAP_MS then
        return
    end
    pcall(refreshgc)
    M._last_refresh_ms = now
end
function M.apply_weapon(mods, opts)
    opts = opts or {}
    if not has_api() then
        return false, 0, "GC API unavailable"
    end
    local now = tick_ms()
    if M._disabled_until > now then
        return false, 0, "GC cooling down"
    end
    local payload = sanitize_payload(mods)
    if not next(payload) then
        return false, 0, "No modifiers selected"
    end
    if not M.in_game() then
        return false, 0, "Enter a match first"
    end
    local gap = MIN_APPLY_GAP_MS
    if M._fail_streak > 2 then
        gap = FAIL_BACKOFF_MS
    end
    if not opts.force and (now - M._last_apply_ms) < gap then
        return false, 0, "throttled"
    end
    maybe_refresh(opts.force_refresh == true or M._last_node_count <= 0)
    local patch_keys = keys_for_payload(payload)
    local warm = warm_nodes(patch_keys)
    M._last_node_count = math.max(M._last_node_count, warm)
    if warm <= 0 then
        note_failure("no nodes")
        debug.warn_once("gun_mods:nodes", "GC still warming - equip a gun, enable a mod option, keep master on")
        return false, 0, "GC warming - equip gun and wait a moment"
    end
    local patched = 0
    local ok, result = pcall(applygc, patch_keys, payload)
    if ok and type(result) == "number" then
        patched = result
    elseif not ok then
        note_failure(result)
        return false, 0, "GC apply failed"
    end
    M._last_apply_ms = tick_ms()
    if patched > 0 then
        note_success(patched)
        return true, patched, string.format("%d node(s) patched", patched)
    end
    note_failure("zero patch")
    if M._fail_streak == 1 then
        M._last_node_count = 0
    end
    return false, 0, "GC warming - equip gun and wait a moment"
end
function M.apply(mods)
    return M.apply_weapon(mods)
end
function M.apply_once(mods)
    return M.apply_weapon(mods, { force = true })
end
function M.apply_cached(mods)
    return M.apply_weapon(mods)
end
function M.refresh_cache()
    if not has_api() or not M.in_game() then
        M._last_node_count = 0
        return 0
    end
    maybe_refresh(true)
    local count = warm_nodes(M.WEAPON_FIND_KEYS)
    M._last_node_count = count
    return count
end
function M.probe_on_load()
    if not has_api() then return 0 end
    if not M.in_game() then return 0 end
    return M.refresh_cache()
end
function M.status_text()
    if not has_api() then return "GC: unavailable" end
    local cd = M.cooldown_remaining_ms()
    if cd > 0 then
        return string.format("GC cooling down (%ds)", math.ceil(cd / 1000))
    end
    return string.format("GC nodes: %d", M._last_node_count)
end
return M
end)()

April._mods["game.gun_mod_profiles"] = (function()
local settings = April.require("core.settings")
local weapons = April.require("game.weapons")
local M = {}
local DEFAULT = {
    recoil = false,
    recoil_pct = 100,
    spread = false,
    spread_pct = 100,
    sway = false,
    fire_rate = false,
    fire_rate_mult = 1.5,
    speed = false,
    speed_mult = 100,
    range = false,
    range_mult = 10,
    double_tap = false,
}
local SETTING_KEYS = {
    recoil = "april_gm_recoil",
    recoil_pct = "april_gm_recoil_pct",
    spread = "april_gm_spread",
    spread_pct = "april_gm_spread_pct",
    sway = "april_gm_sway",
    fire_rate = "april_gm_fire_rate",
    fire_rate_mult = "april_gm_fire_rate_mult",
    speed = "april_gm_speed",
    speed_mult = "april_gm_speed_mult",
    range = "april_gm_range",
    range_mult = "april_gm_range_mult",
    double_tap = "april_gm_double_tap",
}
local function pct_to_neg_mult(pct)
    pct = math.max(0, math.min(100, pct or 0))
    if pct >= 100 then return -1 end
    return -(pct / 100)
end
function M.fire_rate_mult(slider)
    slider = math.max(1, math.min(3, tonumber(slider) or 1.5))
    local t = (slider - 1) / 2
    return 0.12 + t * (0.99 - 0.12)
end
function M.read_settings()
    local profile = {}
    for field, default in pairs(DEFAULT) do
        profile[field] = default
    end
    for field, id in pairs(SETTING_KEYS) do
        local default = DEFAULT[field]
        if type(default) == "boolean" then
            profile[field] = settings.bool(id, default)
        elseif type(default) == "number" and math.floor(default) == default then
            profile[field] = settings.num(id, default)
        else
            profile[field] = tonumber(settings.get(id, default)) or default
        end
    end
    return profile
end
function M.profile_has_active_mods(profile)
    if not profile then return false end
    return profile.recoil or profile.spread or profile.sway
        or profile.fire_rate or profile.speed or profile.range
        or profile.double_tap
end
function M.editor_has_active_mods()
    return M.profile_has_active_mods(M.read_settings())
end
function M.build_mods_from_profile(profile)
    local mods = {}
    if not profile then return mods end
    if profile.recoil then
        mods.RecoilMult = pct_to_neg_mult(profile.recoil_pct)
    end
    if profile.spread then
        local m = pct_to_neg_mult(profile.spread_pct)
        mods.AimSpreadMult = m
        mods.HipSpreadMult = m
    end
    if profile.sway then
        mods.SwayMult = -1
    end
    if profile.fire_rate then
        mods.FireRateMult = M.fire_rate_mult(profile.fire_rate_mult)
    end
    if profile.speed then
        mods.SpeedMult = profile.speed_mult or 100
    end
    if profile.range then
        mods.RangeMult = profile.range_mult or 10
    end
    return mods
end
function M.build_toolinfo_opts(profile)
    if not profile then
        return { double_tap = false }
    end
    return { double_tap = profile.double_tap == true }
end
function M.build_reset_mods()
    return {
        RecoilMult = 0,
        AimSpreadMult = 0,
        HipSpreadMult = 0,
        SwayMult = 0,
        FireRateMult = 0,
        SpeedMult = 0,
        RangeMult = 0,
    }
end
function M.held_weapon_name()
    return weapons.get_held_ranged_weapon_name()
end
function M.build_mods_for_apply(_held)
    if not M.editor_has_active_mods() then return nil end
    return M.build_mods_from_profile(M.read_settings())
end
function M.build_toolinfo_for_apply(held)
    if not M.editor_has_active_mods() then return nil, nil end
    return M.build_toolinfo_opts(M.read_settings()), held
end
function M.should_apply_for_held(held)
    if not held then return false end
    return M.editor_has_active_mods()
end
return M
end)()

April._mods["game.combat_stats"] = (function()
local settings = April.require("core.settings")
local weapons = April.require("game.weapons")
local M = {}
local function inventory_mod()
    return April.require("game.inventory")
end
local function profile_speed_mult()
    if not settings.enabled("april_gunmods_enabled") then return 0 end
    if not settings.enabled("april_gm_speed") then return 0 end
    return settings.num("april_gm_speed_mult", 100)
end
local function ammo_modifiers()
    local inv = inventory_mod()
    if not inv or not inv.get_equipped_ammo_stats then
        return 1, 1
    end
    local ammo = inv.get_equipped_ammo_stats()
    if not ammo then return 1, 1 end
    return ammo.speed_mult or 1, ammo.gravity_mult or 1
end
function M.get_effective_stats(weapon_name)
    weapon_name = weapon_name or weapons.cached_held_ranged() or weapons.get_held_ranged_weapon_name()
    local base = weapons.get_weapon_stats(weapon_name)
    if not base then
        base = { speed = 950, gravity = 0.55, name = weapon_name or "Unknown" }
    end
    local speed = base.speed or 950
    local gravity = base.gravity or 0.55
    local is_bow = base.is_bow
        or (weapon_name and (weapon_name:find("Bow", 1, true) or weapon_name:find("Crossbow", 1, true)))
    local sm = profile_speed_mult()
    if sm ~= 0 then
        speed = speed * (1 + sm)
    end
    local ammo_speed, ammo_grav = ammo_modifiers()
    speed = speed * ammo_speed
    gravity = gravity * ammo_grav
    return {
        speed = speed,
        gravity = gravity,
        name = weapon_name or base.name,
        is_bow = is_bow == true,
        base_speed = base.speed,
        speed_mult = sm,
        ammo_speed_mult = ammo_speed,
        ammo_gravity_mult = ammo_grav,
    }
end
return M
end)()

April._mods["game.combat_origin"] = (function()
local env = April.require("core.env")
local weapons = April.require("game.weapons")
local M = {}
local frame = { t = 0, weapon = nil, muzzle = nil, server = nil }
local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end
local function find_child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        return parent:find_first_child(name) or parent:FindFirstChild(name)
    end)
end
local function part_pos(part)
    if not part or not env.is_valid(part) then return nil end
    local p = part.Position or part.position
    if p and p.x ~= nil then
        return { x = p.x, y = p.y, z = p.z }
    end
    return nil
end
local function vec3_from_cf(cf)
    if not cf then return nil end
    local pos = cf.Position or cf.position
    if pos and pos.x ~= nil then
        return { x = pos.x, y = pos.y, z = pos.z }
    end
    return nil
end
local function camera_origin()
    if not camera or not camera.get_position then return nil end
    local ok, pos = pcall(camera.get_position)
    if ok and pos and pos.x then
        return { x = pos.x, y = pos.y, z = pos.z }
    end
    return nil
end
local function viewmodel_cframe_origin()
    local lp = env.get_local_player()
    local char = lp and lp.character
    if not char or not env.is_valid(char) then return nil end
    local cc = find_child(char, "CameraController")
    if not cc then return nil end
    local cf = env.safe_call(function() return cc:GetAttribute("ViewmodelCFrame") end)
    if not cf then return nil end
    local pos = vec3_from_cf(cf)
    if not pos then return nil end
    local look = cf.LookVector or cf.lookVector
    if look and look.x then
        return {
            x = pos.x + look.x * 0.5,
            y = pos.y + look.y * 0.5,
            z = pos.z + look.z * 0.5,
        }
    end
    return pos
end
local function find_flash_in(model)
    if not model then return nil end
    local flash = find_child(model, "FlashPart") or find_child(model, "Flash")
    if flash then return part_pos(flash) end
    local weapon = find_child(model, "Weapon")
    if weapon then
        flash = find_child(weapon, "FlashPart") or find_child(weapon, "Flash")
        if flash then return part_pos(flash) end
    end
    local desc = env.safe_call(function()
        if model.get_descendants then return model:get_descendants() end
        return model:GetDescendants()
    end) or {}
    for _, d in ipairs(desc) do
        local n = d.Name or d.name
        if n == "FlashPart" or n == "Flash" then
            return part_pos(d)
        end
    end
    return nil
end
local function camera_viewmodel()
    local ws = env.get_workspace()
    if not ws then return nil end
    local cam = env.safe_call(function()
        return ws.CurrentCamera or ws.currentCamera
            or (ws.FindFirstChild and ws:FindFirstChild("CurrentCamera"))
    end)
    if not cam then return nil end
    local kids = env.safe_call(function()
        if cam.get_children then return cam:get_children() end
        return cam:GetChildren()
    end) or {}
    for _, child in ipairs(kids) do
        local cn = child.ClassName or child.class_name
        if cn == "Model" then
            if find_child(child, "Weapon") or find_child(child, "Arms") then
                return child
            end
        end
    end
    return nil
end
local function flashpart_origin()
    local live = camera_viewmodel()
    local pos = find_flash_in(live)
    if pos then return pos end
    local ws = env.get_workspace()
    if not ws then return nil end
    local vfx = find_child(ws, "VFX")
    local vms = vfx and find_child(vfx, "VMs")
    if vms then
        local kids = env.safe_call(function()
            if vms.get_children then return vms:get_children() end
            return vms:GetChildren()
        end) or {}
        for _, child in ipairs(kids) do
            pos = find_flash_in(child)
            if pos then return pos end
        end
    end
    local legacy = find_child(ws, "Viewmodels")
    if legacy then
        local vm = find_child(legacy, "Viewmodel") or find_child(legacy, "ViewModel")
        pos = find_flash_in(vm)
        if pos then return pos end
    end
    return nil
end
local function compute_muzzle(weapon)
    local flash = flashpart_origin()
    if flash then return flash end
    local cframe = viewmodel_cframe_origin()
    if cframe then return cframe end
    if weapon and weapons.is_bow_weapon_name(weapon) then
        return camera_origin()
    end
    return camera_origin()
end
local function compute_server()
    local lp = env.get_local_player()
    if not lp then return nil end
    if lp.position then
        return { x = lp.position.x, y = lp.position.y, z = lp.position.z }
    end
    local char = lp.character
    if char and env.is_valid(char) then
        return part_pos(find_child(char, "HumanoidRootPart"))
    end
    return nil
end
function M.invalidate()
    frame.t = 0
    frame.weapon = nil
    frame.muzzle = nil
    frame.server = nil
end
function M.sync_weapon(weapon)
    weapon = weapon or weapons.cached_held_ranged()
    local now = tick_ms()
    if frame.t == now and frame.weapon == weapon and frame.muzzle then
        return
    end
    frame.t = now
    frame.weapon = weapon
    frame.muzzle = compute_muzzle(weapon)
    frame.server = compute_server()
end
function M.get_muzzle_origin()
    M.sync_weapon()
    return frame.muzzle
end
function M.get_server_origin()
    M.sync_weapon()
    return frame.server
end
function M.get_camera_origin()
    if not camera or not camera.get_position then return nil end
    local ok, pos = pcall(camera.get_position)
    if ok and pos and pos.x then
        return { x = pos.x, y = pos.y, z = pos.z }
    end
    return nil
end
function M.get_fire_origin()
    M.sync_weapon()
    return frame.muzzle or frame.server
end
local HRP_TO_FEET = 2.85
local BELOW_FEET = 0.45
function M.get_feet_below_origin()
    local body = M.get_server_origin()
    if not body then return nil end
    return {
        x = body.x,
        y = body.y - HRP_TO_FEET - BELOW_FEET,
        z = body.z,
    }
end
return M
end)()

April._mods["game.team_state"] = (function()
local env = April.require("core.env")
local M = {}
local CACHE_MS = 250
local cache = {
    t = -1,
    in_team = false,
    members = {},
    member_list = {},
}
local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end
local function find_child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        return parent:find_first_child(name) or parent:FindFirstChild(name)
    end)
end
local function attr(inst, name)
    if not inst then return nil end
    return env.safe_call(function()
        if inst.GetAttribute then return inst:GetAttribute(name) end
        if inst.get_attribute then return inst:get_attribute(name) end
        return nil
    end)
end
local function local_character()
    local lp = env.get_local_player()
    if not lp then return nil end
    local char = lp.character
    if char and env.is_valid(char) then return char end
    return nil
end
local function team_nav()
    local char = local_character()
    if not char then return nil end
    local tnc = find_child(char, "TeamNavigationController")
    if tnc and env.is_valid(tnc) then return tnc end
    return nil
end
local function add_member(set, list, uid)
    uid = tonumber(uid)
    if not uid or uid == 0 or set[uid] then return end
    set[uid] = true
    list[#list + 1] = uid
end
local function members_from_fetch(tnc)
    local fetch = find_child(tnc, "FetchTeam")
    if not fetch then return nil end
    local result = env.safe_call(function()
        if fetch.Invoke then return fetch:Invoke() end
        if fetch.invoke then return fetch:invoke() end
        return nil
    end)
    if type(result) ~= "table" then return nil end
    local set, list = {}, {}
    for _, v in pairs(result) do
        if v ~= "CantLeave" then
            add_member(set, list, v)
        end
    end
    return set, list
end
local function members_from_teamlist()
    local lp = env.get_local_player()
    if not lp then return nil end
    local player = env.safe_call(function()
        return game and game.local_player
    end)
    local pgui = player and find_child(player, "PlayerGui")
    local main = pgui and find_child(pgui, "Main")
    local team = main and find_child(main, "Team")
    local list_frame = team and find_child(team, "TeamList")
    if not list_frame then return nil end
    local labels = {}
    for _, child in ipairs(env.safe_call(function()
        if list_frame.get_children then return list_frame:get_children() end
        return list_frame:GetChildren()
    end) or {}) do
        local n = child.Name or child.name
        if n and tostring(n):find("Member", 1, true) then
            local text = env.safe_call(function()
                return child.Text or child.text
            end)
            if text and text ~= "" and text ~= "..." then
                labels[#labels + 1] = text
            end
        end
    end
    if #labels == 0 then return nil end
    local set, list = {}, {}
    local ep = April.require("core.entity_props")
    local players = April.require("core.cache").players
    if #players == 0 then return set, list end
    for _, p in ipairs(players) do
        local name = ep.name(p)
        local disp = ep.display_name(p)
        for i = 1, #labels do
            local lab = labels[i]
            if name == lab or disp == lab then
                add_member(set, list, ep.user_id(p))
                break
            end
        end
    end
    return set, list
end
local function refresh()
    local now = tick_ms()
    if cache.t >= 0 and (now - cache.t) < CACHE_MS then
        return
    end
    cache.t = now
    cache.in_team = false
    cache.members = {}
    cache.member_list = {}
    local tnc = team_nav()
    if not tnc then return end
    local in_team = attr(tnc, "InTeam")
    cache.in_team = in_team == true
    local set, list = members_from_fetch(tnc)
    if not set then
        set, list = members_from_teamlist()
    end
    if set then
        cache.members = set
        cache.member_list = list or {}
        if next(set) then
            cache.in_team = true
        end
    end
end
function M.invalidate()
    cache.t = -1
end
function M.in_party()
    refresh()
    return cache.in_team == true
end
function M.party_members()
    refresh()
    return cache.members
end
function M.has_team_highlight(player)
    local ep = April.require("core.entity_props")
    local char = ep.character(player)
    if not char then return false end
    if not env.is_valid(char) then return false end
    local hl = find_child(char, "TeamHighlight")
    return hl ~= nil and env.is_valid(hl)
end
function M.is_party_teammate(player)
    local ep = April.require("core.entity_props")
    if not player or ep.is_local(player) then return false end
    refresh()
    local uid = ep.user_id(player)
    if uid and cache.members[uid] then
        return true
    end
    if cache.in_team and M.has_team_highlight(player) then
        return true
    end
    return false
end
function M.same_roblox_team(player)
    if not player then return false end
    local ep = April.require("core.entity_props")
    local lp = ep.get_local_player()
    if not lp then return false end
    if not ep.has_team(lp) or not ep.has_team(player) then return false end
    local lt = ep.team(lp)
    local pt = ep.team(player)
    if not lt or not pt or lt == "" or pt == "" then
        return false
    end
    local a = tostring(lt)
    local b = tostring(pt)
    if a == "Attackers" or a == "Defenders" or b == "Attackers" or b == "Defenders" then
        return false
    end
    return a == b
end
function M.is_teammate(player)
    local ep = April.require("core.entity_props")
    if not player or ep.is_local(player) then return true end
    if M.is_party_teammate(player) then return true end
    if M.same_roblox_team(player) then return true end
    return false
end
return M
end)()

April._mods["game.player_state"] = (function()
local env = April.require("core.env")
local ep = April.require("core.entity_props")
local team_state = April.require("game.team_state")
local M = {}
local DYNAMIC_TTL_MS = 350
local STATIC_TTL_MS = 3000
local REFRESH_PER_FRAME = 2
local snaps = {}
local pl_cache = {}
local refresh_index = 0
local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end
local function cache_key(player)
    local uid = ep.user_id(player)
    if uid and uid ~= 0 then return "u:" .. tostring(uid) end
    return "n:" .. tostring(ep.name(player) or ep.display_name(player) or "?")
end
local function players_service()
    if game and (game.players or game.Players) then
        return game.players or game.Players
    end
    return env.safe_call(function()
        if game.get_service then return game.get_service("Players") end
        if game.GetService then return game:GetService("Players") end
        return nil
    end)
end
local function find_child(parent, name)
    if not parent or not name or name == "" then return nil end
    local ok, child = pcall(function()
        if parent.find_first_child then return parent:find_first_child(name) end
        if parent.FindFirstChild then return parent:FindFirstChild(name) end
        return nil
    end)
    if ok and child then return child end
    return nil
end
local function find_humanoid(char)
    if not char then return nil end
    local ok, hum = pcall(function()
        if char.find_first_child_of_class then
            return char:find_first_child_of_class("Humanoid")
        end
        if char.FindFirstChildOfClass then
            return char:FindFirstChildOfClass("Humanoid")
        end
        return find_child(char, "Humanoid")
    end)
    if ok then return hum end
    return nil
end
local function read_attr(inst, key)
    if not inst or not key then return nil end
    local ok, v = pcall(function()
        if inst.get_attribute then return inst:get_attribute(key) end
        return nil
    end)
    if ok and v ~= nil then return v end
    ok, v = pcall(function()
        if inst.GetAttribute then return inst:GetAttribute(key) end
        return nil
    end)
    if ok and v ~= nil then return v end
    return nil
end
local function read_all_attrs(inst)
    if not inst then return nil end
    local ok, bag = pcall(function()
        if inst.get_attributes then return inst:get_attributes() end
        if inst.GetAttributes then return inst:GetAttributes() end
        return nil
    end)
    if ok and type(bag) == "table" then return bag end
    return nil
end
local function bag_get(bag, key)
    if type(bag) ~= "table" or not key then return nil end
    local v = bag[key]
    if v ~= nil then return v end
    local want = key:lower()
    for k, val in pairs(bag) do
        if type(k) == "string" and k:lower() == want then
            return val
        end
    end
    return nil
end
local function as_bool(v)
    if v == true then return true end
    if v == false or v == nil then return false end
    if type(v) == "boolean" then return v end
    if v == 1 or v == 1.0 then return true end
    if v == 0 or v == 0.0 then return false end
    if type(v) == "string" then
        local s = v:lower():match("^%s*(.-)%s*$") or ""
        if s == "true" or s == "1" or s == "yes" then return true end
        return false
    end
    if type(v) == "number" then return v ~= 0 end
    return false
end
local function normalize_rgb(r, g, b)
    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    if r == nil or g == nil or b == nil then return nil end
    if r > 1 or g > 1 or b > 1 then
        r, g, b = r / 255, g / 255, b / 255
    end
    if r < 0 then r = 0 elseif r > 1 then r = 1 end
    if g < 0 then g = 0 elseif g > 1 then g = 1 end
    if b < 0 then b = 0 elseif b > 1 then b = 1 end
    return { r, g, b, 1 }
end
local function parse_color3(c)
    if c == nil or c == false then return nil end
    if type(c) == "table" then
        local r = c.r or c.R or c.red or c.Red
        local g = c.g or c.G or c.green or c.Green
        local b = c.b or c.B or c.blue or c.Blue
        if r == nil then r = c.x or c.X end
        if g == nil then g = c.y or c.Y end
        if b == nil then b = c.z or c.Z end
        if r == nil then r = c[1] end
        if g == nil then g = c[2] end
        if b == nil then b = c[3] end
        if r == nil and c[0] ~= nil and c[1] ~= nil and c[2] ~= nil then
            r, g, b = c[0], c[1], c[2]
        end
        if r == nil and (c.value or c.Value or c.color or c.Color) then
            return parse_color3(c.value or c.Value or c.color or c.Color)
        end
        if r == nil then
            local nums = {}
            for _, val in pairs(c) do
                if type(val) == "number" then
                    nums[#nums + 1] = val
                end
            end
            if #nums >= 3 then
                r, g, b = nums[1], nums[2], nums[3]
            end
        end
        return normalize_rgb(r, g, b)
    end
    if type(c) == "string" then
        local r = c:match("<R>([%d%.]+)</R>")
        local g = c:match("<G>([%d%.]+)</G>")
        local b = c:match("<B>([%d%.]+)</B>")
        if r then return normalize_rgb(r, g, b) end
        r, g, b = c:match("([%d%.]+)%s*,%s*([%d%.]+)%s*,%s*([%d%.]+)")
        return normalize_rgb(r, g, b)
    end
    if type(c) == "number" then
        local n = math.floor(c)
        return normalize_rgb(
            math.floor(n / 65536) % 256,
            math.floor(n / 256) % 256,
            n % 256
        )
    end
    local ok, r, g, b = pcall(function()
        return c.r or c.R or c.x or c.X, c.g or c.G or c.y or c.Y, c.b or c.B or c.z or c.Z
    end)
    if ok then
        local parsed = normalize_rgb(r, g, b)
        if parsed then return parsed end
    end
    r, g, b = nil, nil, nil
    ok = pcall(function()
        if c.GetComponents then
            r, g, b = c:GetComponents()
        elseif c.get_components then
            r, g, b = c:get_components()
        end
    end)
    if ok then
        local parsed = normalize_rgb(r, g, b)
        if parsed then return parsed end
    end
    local s = env.safe_call(function() return tostring(c) end)
    if type(s) == "string" and not s:lower():find("userdata", 1, true) then
        return parse_color3(s)
    end
    return nil
end
local function read_color3_attr(inst, key)
    if not inst or not key then return nil end
    local parsed = parse_color3(read_attr(inst, key))
    if parsed then return parsed end
    local bag = read_all_attrs(inst)
    if bag then
        parsed = parse_color3(bag_get(bag, key))
        if parsed then return parsed end
    end
    return nil
end
local function read_gui_color3(inst)
    if not inst then return nil end
    local v = env.safe_call(function()
        return inst.TextColor3 or inst.text_color3
            or inst.BackgroundColor3 or inst.background_color3
            or inst.ImageColor3 or inst.image_color3
    end)
    return parse_color3(v)
end
local function parse_rgb_from_text(text)
    if type(text) ~= "string" then return nil end
    local r, g, b = text:match('rgb%(([%d%.]+)[,%s]+([%d%.]+)[,%s]+([%d%.]+)%)')
    if not r then
        r, g, b = text:match('color="rgb%(([%d%.]+)[,%s]+([%d%.]+)[,%s]+([%d%.]+)%)"')
    end
    return normalize_rgb(r, g, b)
end
local function is_near_white(col)
    if not col then return true end
    local r = col[1] or col.r or col.R or 1
    local g = col[2] or col.g or col.G or 1
    local b = col[3] or col.b or col.B or 1
    return r > 0.95 and g > 0.95 and b > 0.95
end
local function normalize_clan_tag(tag)
    if tag == nil or tag == false then return nil end
    if type(tag) == "string" then
        tag = tag:match("^%[(.-)%]$") or tag
        tag = tag:match("^%s*(.-)%s*$") or tag
        if tag == "" then return nil end
        return tag
    end
    if type(tag) == "number" then return tostring(tag) end
    local s = tostring(tag)
    if s == "" or s == "nil" or s == "false" or s == "true" then return nil end
    return s
end
function M.resolve_player_inst(player)
    if not player then return nil end
    local key = cache_key(player)
    local now = tick_ms()
    local cached = pl_cache[key]
    if cached and cached.inst and (now - cached.t) < 1500 then
        local still = env.safe_call(function()
            return cached.inst.Name or cached.inst.name
        end)
        if still then return cached.inst end
    end
    local players = players_service()
    local found = nil
    if players then
        local pname = ep.name(player)
        local pdisp = ep.display_name(player)
        local names = { pname, pdisp }
        for i = 1, #names do
            local want = names[i]
            if want and want ~= "" then
                found = find_child(players, want)
                if found then break end
            end
        end
        if not found then
            local uid = ep.user_id(player)
            local kids = env.safe_call(function()
                if players.get_children then return players:get_children() end
                if players.GetChildren then return players:GetChildren() end
                return nil
            end) or {}
            for i = 1, #kids do
                local pl = kids[i]
                local id = tonumber(env.safe_call(function()
                    return pl.UserId or pl.user_id
                end))
                if uid and id and id == uid then
                    found = pl
                    break
                end
                local n = env.safe_call(function() return pl.Name or pl.name end)
                local dn = env.safe_call(function() return pl.DisplayName or pl.display_name end)
                if (pname and (n == pname or dn == pname))
                    or (pdisp and (n == pdisp or dn == pdisp)) then
                    found = pl
                    break
                end
            end
        end
    end
    if not found and player.player then
        found = player.player
    end
    if found then
        pl_cache[key] = { t = now, inst = found }
    end
    return found
end
function M.resolve_character(player)
    if not player then return nil end
    if player.character then
        local ok = env.safe_call(function()
            return utility and utility.is_valid(player.character)
        end)
        if ok ~= false and player.character then
            return player.character
        end
    end
    local pl = M.resolve_player_inst(player)
    if not pl then return nil end
    return env.safe_call(function()
        return pl.Character or pl.character
    end)
end
function M.resolve_humanoid(player)
    if not player then return nil end
    if player.humanoid then return player.humanoid end
    return find_humanoid(M.resolve_character(player))
end
local function read_player_attrs(pl)
    local out = {
        vip = false,
        safezone = false,
        hide = false,
        owner = false,
        admin = false,
        mod = false,
        clan_tag = nil,
        clan_color = nil,
        from_player = false,
    }
    if not pl then return out end
    local bag = read_all_attrs(pl)
    if bag then
        out.from_player = true
        out.vip = as_bool(bag_get(bag, "VIP"))
        out.safezone = as_bool(bag_get(bag, "SafeZone"))
        out.hide = as_bool(bag_get(bag, "HideTag"))
        out.owner = as_bool(bag_get(bag, "Owner"))
        out.admin = as_bool(bag_get(bag, "Admin"))
        out.mod = as_bool(bag_get(bag, "Mod"))
        out.clan_tag = normalize_clan_tag(bag_get(bag, "ClanTag"))
        out.clan_color = read_color3_attr(pl, "ClanColor")
    end
    if not out.clan_tag then
        local v = read_attr(pl, "ClanTag")
        if v ~= nil then
            out.from_player = true
            out.clan_tag = normalize_clan_tag(v)
        end
    end
    if not out.clan_color then
        out.clan_color = read_color3_attr(pl, "ClanColor")
    end
    if not out.vip then
        local v = read_attr(pl, "VIP")
        if v ~= nil then
            out.from_player = true
            out.vip = as_bool(v)
        end
    end
    if not out.safezone then
        local v = read_attr(pl, "SafeZone")
        if v ~= nil then
            out.from_player = true
            out.safezone = as_bool(v)
        end
    end
    if not out.mod then
        local v = read_attr(pl, "Mod")
        if v ~= nil then
            out.from_player = true
            out.mod = as_bool(v)
        end
    end
    if not out.owner then
        local v = read_attr(pl, "Owner")
        if v ~= nil then out.owner = as_bool(v) end
    end
    if not out.admin then
        local v = read_attr(pl, "Admin")
        if v ~= nil then out.admin = as_bool(v) end
    end
    if not out.hide then
        local v = read_attr(pl, "HideTag")
        if v ~= nil then out.hide = as_bool(v) end
    end
    return out
end
local function nametag_clan_tag_only(char)
    if not char then return nil end
    local nt = find_child(char, "NameTag")
    if not nt then return nil end
    local label = find_child(nt, "Label")
    if not label then return nil end
    local text = env.safe_call(function()
        return label.Text or label.text
    end)
    if type(text) ~= "string" then return nil end
    local tag = normalize_clan_tag(text:match("%[([^%]]+)%]"))
    if not tag then return nil end
    local upper = tag:upper()
    if upper == "MOD" or upper == "ADMIN" or upper == "OWNER" or upper == "VIP" then
        return nil
    end
    return tag
end
local function nametag_clan_color(char)
    if not char then return nil end
    local nt = find_child(char, "NameTag")
    if not nt then return nil end
    local label = find_child(nt, "Label")
    if not label then return nil end
    local text = env.safe_call(function()
        return label.Text or label.text
    end)
    local from_text = parse_rgb_from_text(text)
    if from_text then return from_text end
    local tc = read_gui_color3(label)
    if tc and not is_near_white(tc) then
        return tc
    end
    local clan_lbl = find_child(nt, "ClanTag")
    if clan_lbl then
        from_text = parse_rgb_from_text(env.safe_call(function()
            return clan_lbl.Text or clan_lbl.text
        end))
        if from_text then return from_text end
        tc = read_gui_color3(clan_lbl)
        if tc and not is_near_white(tc) then
            return tc
        end
    end
    return nil
end
local function resolve_clan_color(pl, char, entity_player)
    if pl then
        local c = read_color3_attr(pl, "ClanColor")
        if c then return c end
    end
    if entity_player and entity_player.player and entity_player.player ~= pl then
        local c = read_color3_attr(entity_player.player, "ClanColor")
        if c then return c end
    end
    if entity_player then
        local c = read_color3_attr(entity_player, "ClanColor")
        if c then return c end
    end
    return nametag_clan_color(char)
end
local function ensure_snap(player)
    local key = cache_key(player)
    local snap = snaps[key]
    if snap then return snap end
    snap = {
        dynamic_t = -DYNAMIC_TTL_MS,
        static_t = -STATIC_TTL_MS,
        vip = false,
        safezone = false,
        downed = false,
        reviving = false,
    }
    snaps[key] = snap
    return snap
end
local function refresh_dynamic(player, snap, now)
    local pl = M.resolve_player_inst(player)
    local char = M.resolve_character(player)
    local hum = M.resolve_humanoid(player)
    if not hum and char then hum = find_humanoid(char) end
    local ic = char and find_child(char, "InteractController") or nil
    snap.safezone = as_bool(read_attr(pl, "SafeZone")) or as_bool(read_attr(pl, "InSafeZone"))
    snap.downed = as_bool(read_attr(hum, "Downed"))
    snap.reviving = as_bool(read_attr(ic, "Reviving"))
    snap.dynamic_t = now
end
local function refresh_static(player, snap, now)
    local pl = M.resolve_player_inst(player)
    local char = M.resolve_character(player)
    local pa = read_player_attrs(pl)
    if not pa.clan_tag then
        pa.clan_tag = nametag_clan_tag_only(char)
    end
    pa.clan_color = pa.clan_color or resolve_clan_color(pl, char, player)
    local staff = nil
    if not pa.hide then
        if pa.owner then
            staff = "OWNER"
        elseif pa.admin then
            staff = "ADMIN"
        elseif pa.mod then
            staff = "MOD"
        end
    end
    snap.vip = pa.vip
    snap.staff = staff
    snap.clan_tag = pa.clan_tag
    snap.clan_color = pa.clan_color
    snap.resolved = pl ~= nil
    snap.from_player = pa.from_player
    snap.static_t = now
end
local function get_snap(player)
    if not player then return nil end
    return ensure_snap(player)
end
function M.tick(players)
    local n = #(players or {})
    if n == 0 then
        refresh_index = 0
        return
    end
    local now = tick_ms()
    for _ = 1, math.min(REFRESH_PER_FRAME, n) do
        refresh_index = (refresh_index % n) + 1
        local player = players[refresh_index]
        if player then
            local snap = ensure_snap(player)
            if now - (snap.dynamic_t or 0) >= DYNAMIC_TTL_MS then
                refresh_dynamic(player, snap, now)
            end
            if now - (snap.static_t or 0) >= STATIC_TTL_MS then
                refresh_static(player, snap, now)
            end
        end
    end
end
function M.invalidate(player)
    if not player then
        snaps = {}
        pl_cache = {}
        return
    end
    local key = cache_key(player)
    snaps[key] = nil
    pl_cache[key] = nil
end
function M.esp_state(player)
    return get_snap(player)
end
function M.player_attr(player, key)
    return read_attr(M.resolve_player_inst(player), key)
end
function M.char_attr(player, key)
    return read_attr(M.resolve_character(player), key)
end
function M.humanoid_attr(player, key)
    return read_attr(M.resolve_humanoid(player), key)
end
function M.is_safezone(player)
    local s = get_snap(player)
    return s and s.safezone or false
end
function M.is_vip(player)
    local s = get_snap(player)
    return s and s.vip or false
end
function M.staff_tag(player)
    local s = get_snap(player)
    return s and s.staff or nil
end
function M.is_reviving(player)
    local s = get_snap(player)
    return s and s.reviving or false
end
function M.clan_tag(player)
    local s = get_snap(player)
    return s and s.clan_tag or nil
end
function M.clan_color(player)
    local s = get_snap(player)
    return s and s.clan_color or nil
end
function M.is_downed(player)
    local s = get_snap(player)
    return s and s.downed or false
end
function M.is_alive_body(player)
    if not player then return false end
    if ep.is_alive(player) == false then return false end
    local char = ep.character(player)
    if not char then return false end
    if not env.is_valid(char) then return false end
    local hp = ep.health(player)
    if hp ~= nil and hp <= 0 then return false end
    return true
end
function M.is_combat_target(player)
    if not player or ep.is_local(player) then return false end
    if ep.is_alive(player) ~= false then return true end
    if M.is_downed(player) then return true end
    local hp = ep.health(player)
    if hp and hp > 0 then return true end
    return false
end
function M.passes_health_check(player)
    if not player then return false end
    if ep.is_alive(player) then
        local hp = ep.health(player)
        if hp and hp <= 0 then return false end
        return true
    end
    return M.is_downed(player)
end
function M.passes_team_check(player)
    if not player then return false end
    return not team_state.is_teammate(player)
end
function M.passes_downed_check(player, mode)
    if not player then return false end
    mode = tonumber(mode) or 0
    if mode == 1 then return true end
    local downed = M.is_downed(player)
    if mode == 2 then return downed end
    return not downed
end
function M.passes_safezone_check(player, skip_safezone)
    if not player then return false end
    if not skip_safezone then return true end
    return not M.is_safezone(player)
end
return M
end)()

April._mods["game.farm_tools"] = (function()
local bootstrap = April.require("game.bootstrap")
local env = April.require("core.env")
local M = {}
local loaded = false
local farm_tools = {}
local tool_caps = {}
local FALLBACK_GATHER_TOOLS = {
    ["Stone Hatchet"] = { Trees = true, Logs = true, Cactus = true },
    ["Iron Shard Hatchet"] = { Trees = true, Logs = true, Cactus = true },
    ["Steel Axe"] = { Trees = true, Logs = true, Cactus = true },
    Chainsaw = { Trees = true, Logs = true, Cactus = true },
    Machete = { Trees = true, Logs = true, Cactus = true },
    ["Saw Bat"] = { Cactus = true },
    ["Stone Pickaxe"] = { Nodes = true },
    ["Iron Shard Pickaxe"] = { Nodes = true },
    ["Steel Pickaxe"] = { Nodes = true },
    ["Mining Drill"] = { Nodes = true },
    ["Bone Tool"] = { Trees = true, Nodes = true, Logs = true, Cactus = true },
    ["Candy Cane"] = { Trees = true, Nodes = true, Logs = true, Cactus = true },
    ["Carrot Blade"] = { Trees = true, Nodes = true, Logs = true, Cactus = true },
    Boulder = { Trees = true, Nodes = true, Logs = true, Cactus = true },
    ["Steel Shovel"] = { Dig = true, Shovel = true },
    ["Salvaged Shovel"] = { Dig = true, Shovel = true },
    ["ez shovel"] = { Dig = true, Shovel = true },
}
local NAME_HINTS = {
    "hatchet", "pickaxe", "pick axe", " axe", "axe ",
    "chainsaw", "mining drill", "bone tool",
    "candy cane", "carrot blade", "boulder", "machete",
    "saw bat", "shovel",
}
local MELEE_RANGE = {
    ["Stone Hatchet"] = 5,
    ["Iron Shard Hatchet"] = 5,
    ["Steel Axe"] = 5.5,
    Chainsaw = 6.5,
    Machete = 5.5,
    ["Saw Bat"] = 5,
    ["Stone Pickaxe"] = 5,
    ["Iron Shard Pickaxe"] = 5,
    ["Steel Pickaxe"] = 5.5,
    ["Mining Drill"] = 6.5,
    ["Bone Tool"] = 5,
    ["Candy Cane"] = 5,
    ["Carrot Blade"] = 5,
    Boulder = 4.5,
    ["Steel Shovel"] = 5,
    ["Salvaged Shovel"] = 5,
    ["ez shovel"] = 5,
}
local SWING_COOLDOWN = {
    ["Stone Hatchet"] = 0.9,
    ["Iron Shard Hatchet"] = 0.9,
    ["Steel Axe"] = 1.5,
    Chainsaw = 0.15,
    Machete = 0.9,
    ["Saw Bat"] = 1.5,
    ["Stone Pickaxe"] = 0.9,
    ["Iron Shard Pickaxe"] = 0.9,
    ["Steel Pickaxe"] = 1.5,
    ["Mining Drill"] = 0.15,
    Boulder = 1.5,
}
local function inst_name(inst)
    if not inst then return nil end
    return inst.name or inst.Name
end
local function normalize(name)
    if not name or name == "" then return nil end
    return name
end
local function caps_from_object_damages(od)
    if type(od) ~= "table" then return nil end
    local caps = {}
    if od.Trees ~= nil then caps.Trees = true end
    if od.Nodes ~= nil then caps.Nodes = true end
    if od.Logs ~= nil then caps.Logs = true end
    if od.Cactus ~= nil then caps.Cactus = true end
    if next(caps) == nil then return nil end
    return caps
end
local function entry_can_gather(entry)
    if not entry or not entry.Melee then return false end
    return caps_from_object_damages(entry.ObjectDamages) ~= nil
end
local function name_hint_match(name)
    local n = (name or ""):lower()
    for _, hint in ipairs(NAME_HINTS) do
        if n:find(hint, 1, true) then return true end
    end
    return false
end
local function hint_caps(name)
    local n = (name or ""):lower()
    if n:find("shovel", 1, true) then
        return { Dig = true, Shovel = true }
    end
    if n:find("pickaxe", 1, true) or n:find("pick axe", 1, true) or n:find("mining drill", 1, true) then
        return { Nodes = true }
    end
    if n:find("saw bat", 1, true) then
        return { Cactus = true }
    end
    if n:find("hatchet", 1, true) or n:find("axe", 1, true) or n:find("chainsaw", 1, true)
        or n:find("machete", 1, true) then
        return { Trees = true, Logs = true, Cactus = true }
    end
    return { Trees = true, Nodes = true, Logs = true, Cactus = true }
end
function M.load()
    if loaded then return true end
    farm_tools = {}
    tool_caps = {}
    for name, caps in pairs(FALLBACK_GATHER_TOOLS) do
        farm_tools[name] = true
        tool_caps[name] = caps
    end
    local data = bootstrap.get_module("ToolInfo")
    if type(data) == "table" then
        for name, entry in pairs(data) do
            if type(name) == "string" and entry_can_gather(entry) then
                farm_tools[name] = true
                local caps = caps_from_object_damages(entry.ObjectDamages)
                if caps then
                    tool_caps[name] = caps
                end
            end
        end
    end
    loaded = true
    return next(farm_tools) ~= nil
end
function M.invalidate()
    loaded = false
    farm_tools = {}
    tool_caps = {}
end
function M.is_farm_tool_name(name)
    name = normalize(name)
    if not name then return false end
    if not loaded then M.load() end
    if farm_tools[name] then return true end
    return name_hint_match(name)
end
function M.tool_caps(tool_name)
    tool_name = normalize(tool_name)
    if not tool_name then return nil end
    if not loaded then M.load() end
    local caps = tool_caps[tool_name]
    if caps then return caps end
    if name_hint_match(tool_name) then
        return hint_caps(tool_name)
    end
    return nil
end
local function pick_farm_name(name)
    if M.is_farm_tool_name(name) then return name end
    return nil
end
local function scan_children(list)
    if not list then return nil end
    for _, child in ipairs(list) do
        local hit = pick_farm_name(inst_name(child))
        if hit then return hit end
    end
    return nil
end
local function children(inst)
    if not inst then return nil end
    return env.safe_call(function()
        local fn = inst.GetChildren or inst.get_children
        return fn and fn(inst) or nil
    end)
end
function M.get_held_farm_tool_name()
    if not loaded then M.load() end
    local lp = env.get_local_player()
    if not lp then return nil end
    local from_lp = pick_farm_name(lp.ToolName or lp.tool_name)
    if from_lp then return from_lp end
    local char = lp.Character or lp.character
    if char and env.is_valid(char) then
        local hit = scan_children(children(char))
        if hit then return hit end
    end
    local ws = env.get_workspace()
    if ws then
        local vms = env.safe_call(function() return ws:find_first_child("Viewmodels") end)
            or env.safe_call(function() return ws:FindFirstChild("Viewmodels") end)
        if vms then
            for _, vm in ipairs(children(vms) or {}) do
                if inst_name(vm) == "Viewmodel" then
                    local hit = scan_children(children(vm))
                    if hit then return hit end
                end
            end
        end
    end
    return nil
end
function M.holding_farm_tool()
    return M.get_held_farm_tool_name() ~= nil
end
local function box_reach(box)
    if not box then return nil end
    local sz = box.Size or box.size
    if sz then
        local r = sz.X or sz.x
        if r and r > 0 then return r end
    end
    local mag = box.Magnitude
    if type(mag) == "number" and mag > 0 then
        return mag
    end
    return nil
end
function M.melee_range(tool_name)
    tool_name = normalize(tool_name)
    if not tool_name then return 5 end
    local data = bootstrap.get_module("ToolInfo")
    local entry = data and data[tool_name]
    local melee = entry and entry.Melee
    local max_range = type(melee) == "table"
        and tonumber(melee.MaxRange or melee.max_range or melee.maxRange)
        or nil
    if max_range and max_range > 0 then
        return max_range
    end
    local checks = entry and entry.Melee and entry.Melee.MeleeChecks
    if type(checks) == "table" then
        local best = 0
        for i = 1, #checks do
            local row = checks[i]
            local reach = row and box_reach(row[2])
            if reach and reach > best then
                best = reach
            end
        end
        if best > 0 then
            return best
        end
    end
    return MELEE_RANGE[tool_name] or 5
end
function M.swing_cooldown(tool_name)
    tool_name = normalize(tool_name)
    if not tool_name then return 0.9 end
    local data = bootstrap.get_module("ToolInfo")
    local entry = data and data[tool_name]
    local weapon = entry and entry.Weapon
    local cooldown = type(weapon) == "table"
        and tonumber(weapon.Cooldown or weapon.cooldown)
        or nil
    if cooldown and cooldown > 0 then
        return math.max(0.1, cooldown)
    end
    return SWING_COOLDOWN[tool_name] or 0.9
end
function M.all_names()
    if not loaded then M.load() end
    local out = {}
    for name in pairs(farm_tools) do
        out[#out + 1] = name
    end
    table.sort(out)
    return out
end
return M
end)()

April._mods["game.farm_targets"] = (function()
local env = April.require("core.env")
local folders = April.require("game.folders")
local M = {}
local CELL_SIZE = 24
local INDEX_REFRESH_MS = 900
local buckets = {}
local records = {}
local last_refresh_ms = -INDEX_REFRESH_MS
local function now_ms()
    local fn = utility and (utility.get_tick_count or utility.GetTickCount)
    if type(fn) ~= "function" then return 0 end
    local ok, value = pcall(fn)
    return ok and (tonumber(value) or 0) or 0
end
local function child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        if parent.FindFirstChild then return parent:FindFirstChild(name) end
        if parent.find_first_child then return parent:find_first_child(name) end
        return nil
    end)
end
local function children(parent)
    if not parent then return {} end
    return env.safe_call(function()
        if parent.GetChildren then return parent:GetChildren() end
        if parent.get_children then return parent:get_children() end
        return {}
    end) or {}
end
local function name_of(inst)
    return inst and (inst.Name or inst.name) or nil
end
local function read_pos(part)
    if not part or not env.is_valid(part) then return nil end
    local p = part.Position or part.position
    if not p then return nil end
    local x, y, z = p.x or p.X, p.y or p.Y, p.z or p.Z
    if x == nil or y == nil or z == nil then return nil end
    return { x = x, y = y, z = z }
end
local function horizontal_radius(part)
    if not part then return 0 end
    local size
    local ok = pcall(function() size = part.Size or part.size end)
    if not ok or not size then return 0 end
    local sx = tonumber(size.X or size.x) or 0
    local sz = tonumber(size.Z or size.z) or 0
    return math.min(12, (sx + sz) * 0.25)
end
local function d2(a, b)
    if not a or not b then return math.huge end
    local ax, ay, az = a.x or a.X, a.y or a.Y, a.z or a.Z
    local bx, by, bz = b.x or b.X, b.y or b.Y, b.z or b.Z
    if ax == nil or ay == nil or az == nil or bx == nil or by == nil or bz == nil then
        return math.huge
    end
    local dx, dy, dz = ax - bx, ay - by, az - bz
    return dx * dx + dy * dy + dz * dz
end
local function flat_d2(a, b)
    if not a or not b then return math.huge end
    local ax, az = a.x or a.X, a.z or a.Z
    local bx, bz = b.x or b.X, b.z or b.Z
    if ax == nil or az == nil or bx == nil or bz == nil then return math.huge end
    local dx, dz = ax - bx, az - bz
    return dx * dx + dz * dz
end
local function record_key(model)
    return tostring(model and (model.Address or model.address or model) or "")
end
local function bucket_key(x, z)
    return tostring(math.floor(x / CELL_SIZE)) .. ":" .. tostring(math.floor(z / CELL_SIZE))
end
function M.kind_from_name(name)
    if not name or name == "" then return nil end
    if name:find("_Node", 1, true) then return "Nodes" end
    if name:find("Desert_Tree", 1, true) or name:find("Tree_", 1, true) then return "Trees" end
    if name:find("Forest_Log", 1, true) then return "Logs" end
    if name:find("Desert_Cactus", 1, true) then return "Cactus" end
    if name == "DigPile" then return "Dig" end
    return nil
end
function M.resource_type_from_name(name)
    if not name or name == "" then return nil end
    local lower = name:lower()
    if lower:find("stone_node", 1, true) then return "Stone" end
    if lower:find("metal_node", 1, true) then return "Metal" end
    if lower:find("phosphate_node", 1, true) then return "Phosphate" end
    local kind = M.kind_from_name(name)
    if kind == "Trees" then return "Trees" end
    return kind
end
local function marker_main(model, marker_name)
    local marker = child(model, marker_name)
    if not marker or not env.is_valid(marker) then return nil end
    local main = child(marker, "Main")
    if main and env.is_valid(main) then return main end
    return nil
end
local function weak_part(model, kind)
    if kind == "Trees" then return marker_main(model, "TreeX") end
    if kind == "Nodes" then return marker_main(model, "NodeSpark") end
    return nil
end
local function proxy_part(model, kind)
    if kind == "Cactus" then return child(model, "CactusPart") end
    if kind == "Dig" then return child(model, "Dirt") end
    if kind == "Logs" then return child(model, "Main") or child(model, "Branch") end
    return child(model, "Main")
end
local function aim_part(model, kind)
    if kind == "Trees" or kind == "Nodes" then
        local mark = weak_part(model, kind)
        return mark or proxy_part(model, kind), mark ~= nil
    end
    local part = proxy_part(model, kind)
    return part, part ~= nil
end
local function depleted(model)
    if not model or not env.is_valid(model) then return true end
    local destroyed = env.get_attribute(model, "Destroyed")
    if destroyed == true or destroyed == 1 then return true end
    local health = tonumber(env.get_attribute(model, "Health"))
    return health ~= nil and health <= 0
end
local function health_snapshot(model)
    if not model then return nil, nil, nil end
    return tonumber(env.get_attribute(model, "Health")),
        tonumber(env.get_attribute(model, "MaxHealth")),
        tonumber(env.get_attribute(model, "State"))
end
local function kind_allowed(caps, kind)
    if not kind then return false end
    if not caps then return kind == "Trees" or kind == "Nodes" end
    if kind == "Dig" then return caps.Dig == true or caps.Shovel == true end
    return caps[kind] == true
end
local function record_allowed(record, caps, opts)
    if not record or not kind_allowed(caps, record.kind) then return false end
    opts = opts or {}
    if opts.allowed and opts.allowed[record.resource_type] ~= true then return false end
    if opts.skip_keys and opts.skip_keys[record.key] then return false end
    return true
end
local function add_record(model, parent)
    if not model or not env.is_valid(model) then return end
    local kind = M.kind_from_name(name_of(model))
    if not kind then return end
    local proxy = proxy_part(model, kind)
    local pos = read_pos(proxy)
    if not pos then return end
    local record = {
        model = model,
        kind = kind,
        resource_type = M.resource_type_from_name(name_of(model)),
        proxy = proxy,
        base_pos = pos,
        body_radius = horizontal_radius(proxy),
        key = record_key(model),
        parent_key = record_key(parent),
    }
    records[#records + 1] = record
    local key = bucket_key(pos.x, pos.z)
    buckets[key] = buckets[key] or {}
    buckets[key][#buckets[key] + 1] = record
end
local function resource_folders()
    local out = {}
    local nodes = folders.from_key("nodes")
    local trees = folders.get_folder("Trees")
    local vegetation = folders.from_key("vegetation")
    if nodes then out[#out + 1] = nodes end
    if trees then out[#out + 1] = trees end
    if vegetation then out[#out + 1] = vegetation end
    return out
end
function M.refresh_index(force)
    local now = now_ms()
    if not force and now - last_refresh_ms < INDEX_REFRESH_MS then return false end
    last_refresh_ms = now
    buckets = {}
    records = {}
    local seen = {}
    for _, folder in ipairs(resource_folders()) do
        if folder and not seen[folder] then
            seen[folder] = true
            for _, model in ipairs(children(folder)) do
                add_record(model, folder)
            end
        end
    end
    return true
end
function M.invalidate()
    buckets = {}
    records = {}
    last_refresh_ms = -INDEX_REFRESH_MS
end
function M.hit_part(model, kind)
    if not model or depleted(model) then return nil, false end
    kind = kind or M.kind_from_name(name_of(model))
    return aim_part(model, kind)
end
function M.is_depleted(model)
    return depleted(model)
end
function M.health(model)
    return health_snapshot(model)
end
function M.resolve(record)
    if not record or depleted(record.model) then return nil end
    local current_parent = record.model.Parent or record.model.parent
    if not current_parent or record_key(current_parent) ~= record.parent_key then
        return nil
    end
    local body = record.proxy
    if not body or not env.is_valid(body) then
        body = proxy_part(record.model, record.kind)
        record.proxy = body
    end
    local body_pos = read_pos(body)
    if not body_pos then return nil end
    local weak = weak_part(record.model, record.kind)
    local weak_pos = read_pos(weak)
    local health, max_health, resource_state = health_snapshot(record.model)
    record.body_part = body
    record.body_pos = body_pos
    record.body_radius = horizontal_radius(body)
    record.base_pos = body_pos
    record.weak_part = weak_pos and weak or nil
    record.weak_pos = weak_pos
    record.weak_key = weak_pos and record_key(weak) or nil
    record.health = health
    record.max_health = max_health
    record.resource_state = resource_state
    record.part = record.weak_part or body
    record.pos = record.weak_pos or body_pos
    record.weak = record.weak_part ~= nil
    return record
end
local function visible(origin, pos)
    if not origin or not pos or not raycast then return nil end
    local ready_fn = raycast.is_ready or raycast.IsReady
    if type(ready_fn) == "function" then
        local ok, ready = pcall(ready_fn)
        if ok and ready == false then return nil end
    end
    local fn = raycast.is_visible or raycast.IsVisible
    if type(fn) ~= "function" then return nil end
    local ox, oy, oz = origin.x or origin.X, origin.y or origin.Y, origin.z or origin.Z
    if ox == nil or oy == nil or oz == nil then return nil end
    local ok, clear = pcall(fn, ox, oy, oz, pos.x, pos.y, pos.z)
    if not ok then return nil end
    return clear == true
end
local function better(candidate, candidate_d2, best, best_d2)
    if not best then return true end
    if candidate_d2 < best_d2 - 1e-6 then return true end
    if math.abs(candidate_d2 - best_d2) <= 1e-6 then
        return tostring(candidate.key) < tostring(best.key)
    end
    return false
end
function M.find_target(origin, radius, tool_caps, opts)
    if not origin or not radius or radius <= 0 then return nil end
    opts = opts or {}
    M.refresh_index(false)
    local ox, oz = origin.x or origin.X, origin.z or origin.Z
    if ox == nil or oz == nil then return nil end
    local limit2 = radius * radius
    local span = math.max(1, math.ceil(radius / CELL_SIZE) + 1)
    local cell_x = math.floor(ox / CELL_SIZE)
    local cell_z = math.floor(oz / CELL_SIZE)
    local best_visible, best_visible_d2 = nil, limit2
    local best_any, best_any_d2 = nil, limit2
    local visited = {}
    local function consider(record)
        if not visited[record.key] and record_allowed(record, tool_caps, opts) then
            visited[record.key] = true
            local resolved = M.resolve(record)
            if resolved then
                local center_d2 = flat_d2(resolved.base_pos or resolved.pos, origin)
                local surface = math.max(0, math.sqrt(center_d2) - (resolved.body_radius or 0))
                local dist = surface * surface
                if dist <= limit2 then
                    if better(resolved, dist, best_any, best_any_d2) then
                        best_any, best_any_d2 = resolved, dist
                    end
                    if opts.check_visibility ~= false
                        and visible(origin, resolved.pos) ~= false
                        and better(resolved, dist, best_visible, best_visible_d2)
                    then
                        best_visible, best_visible_d2 = resolved, dist
                    end
                end
            end
        end
    end
    if span > 16 then
        for _, list in pairs(buckets) do
            for _, record in ipairs(list) do consider(record) end
        end
    else
        for x = cell_x - span, cell_x + span do
            for z = cell_z - span, cell_z + span do
                local list = buckets[tostring(x) .. ":" .. tostring(z)]
                for _, record in ipairs(list or {}) do consider(record) end
            end
        end
    end
    local best = best_visible or best_any
    if best then
        best.distance2 = best == best_visible and best_visible_d2 or best_any_d2
    end
    return best
end
function M.find_nearest(origin, radius, tool_caps)
    local record = M.find_target(origin, radius, tool_caps)
    return record and record.part or nil
end
function M.collect_near(origin, radius, out, _max_out, tool_caps)
    out = out or {}
    local part = M.find_nearest(origin, radius, tool_caps)
    if part then out[1] = part end
    return out
end
function M.distance2(pos, origin)
    return d2(pos, origin)
end
function M.surface_distance2(record, origin)
    if not record or not origin then return math.huge end
    local center = record.body_pos or record.base_pos or record.pos
    local center_d2 = flat_d2(center, origin)
    local surface = math.max(0, math.sqrt(center_d2) - (record.body_radius or 0))
    return surface * surface
end
return M
end)()

April._mods["game.inventory"] = (function()
local env = April.require("core.env")
local items = April.require("game.items")
local item_catalog = April.require("game.item_catalog")
local M = {}
function M.get_local_inventory()
    local lp = env.get_local_player()
    if not lp or not lp.character then return nil end
    local char = lp.character
    if not env.is_valid(char) then return nil end
    local ic = env.safe_call(function() return char:find_first_child("InventoryController") end)
    if not ic then return nil end
    local fetch = env.safe_call(function() return ic:find_first_child("Fetch") end)
    if not fetch or not fetch.Invoke then return nil end
    local ok, inv, toolbar, armor = pcall(function() return fetch:Invoke() end)
    if not ok or not inv then return nil end
    return { inventory = inv, toolbar = toolbar, armor = armor }
end
function M.resolve_item_name(id)
    if type(id) ~= "number" then return tostring(id) end
    local row = item_catalog.get(id)
    if row and row.name then return row.name end
    local rep = env.get_replicated_storage()
    if not rep then return "Item#" .. id end
    local modules = env.safe_call(function() return rep:find_first_child("Modules") end)
    local items_mod = modules and env.safe_call(function() return modules:find_first_child("Items") end)
    if items_mod then
        local ok, data = pcall(function() return require(items_mod) end)
        if ok and data and data[id] and data[id].Name then
            return data[id].Name
        end
    end
    return "Item#" .. id
end
local function read_attribute(inst, key)
    if not inst or not key then return nil end
    if inst.GetAttribute then return inst:GetAttribute(key) end
    if inst.get_attribute then return inst:get_attribute(key) end
    return nil
end
local function find_child(char, name)
    if not char then return nil end
    return env.safe_call(function()
        if char.find_first_child then return char:find_first_child(name) end
        return char:FindFirstChild(name)
    end)
end
function M.get_toolbar_entry(char)
    if not char or not env.is_valid(char) then return nil, nil end
    local ic = find_child(char, "InventoryController")
    if not ic then return nil, nil end
    local fetch = env.safe_call(function()
        if ic.find_first_child then return ic:find_first_child("Fetch") end
        return ic:FindFirstChild("Fetch")
    end)
    if not fetch or not fetch.Invoke then return nil, nil end
    local slot = read_attribute(find_child(char, "EquipController"), "Equipped")
    if type(slot) ~= "number" or slot <= 0 then
        slot = read_attribute(find_child(char, "ViewmodelController"), "Equipped")
    end
    if type(slot) ~= "number" or slot <= 0 then return nil, nil end
    local ok, data = pcall(function() return fetch:Invoke() end)
    if not ok or type(data) ~= "table" then return nil, nil end
    local toolbar = data.Toolbar or data.toolbar
    if type(toolbar) ~= "table" then return nil, nil end
    local entry = toolbar[slot]
    if not entry or entry == 0 then return nil, nil end
    if type(entry) == "table" and entry.Amount and entry.Amount <= 0 then return nil, nil end
    return entry, slot
end
function M.get_equipped_ammo_stats()
    local lp = env.get_local_player()
    local char = lp and lp.character
    if not char or not env.is_valid(char) then return nil end
    local entry = M.get_toolbar_entry(char)
    if not entry or type(entry) ~= "table" then return nil end
    local ammo = entry.Ammo
    if not ammo or type(ammo) ~= "table" then return nil end
    local ammo_id = ammo.ID
    if type(ammo_id) ~= "number" then return nil end
    items.load()
    local row = items.get_by_id and items.get_by_id(ammo_id)
    if row and row.AmmoStats then return row.AmmoStats end
    local rep = env.get_replicated_storage()
    if rep then
        local modules = env.safe_call(function() return rep:find_first_child("Modules") end)
        local items_mod = modules and env.safe_call(function() return modules:find_first_child("Items") end)
        if items_mod then
            local ok, data = pcall(function() return require(items_mod) end)
            if ok and data and data[ammo_id] and data[ammo_id].AmmoStats then
                return data[ammo_id].AmmoStats
            end
        end
    end
    return nil
end
function M.get_toolbar_held_name(char)
    local entry = M.get_toolbar_entry(char)
    if not entry then return nil end
    local id = type(entry) == "table" and entry.ID or entry
    if type(id) ~= "number" then return nil end
    return M.resolve_item_name(id)
end
function M.get_held_tool_name()
    local lp = env.get_local_player()
    if not lp then return nil end
    if lp.tool_name and lp.tool_name ~= "" then return lp.tool_name end
    local char = lp.character
    if not char or not env.is_valid(char) then return nil end
    local toolbar_name = M.get_toolbar_held_name(char)
    if toolbar_name and toolbar_name ~= "" then return toolbar_name end
    for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
        if child.ClassName == "Tool" then return child.Name end
    end
    return nil
end
return M
end)()

April._mods["game.player_gear"] = (function()
local env = April.require("core.env")
local items = April.require("game.items")
local item_catalog = April.require("game.item_catalog")
local inventory = April.require("game.inventory")
local weapons = April.require("game.weapons")
local attachment_images = April.require("game.attachment_images")
local M = {}
local ARMOR_ATTRIBUTES = {
    "ResistWet",
    "HasFlippers",
    "HasTank",
    "HasGoggles",
    "NVG",
    "SilentSteps",
    "WaterFilter",
    "SteelToes",
    "Snorkle",
}
local ATTACHMENT_SLOT_HINTS = {
    ["p1"] = true, ["p2"] = true, ["p3"] = true, ["p4"] = true,
    ["slot1"] = true, ["slot2"] = true, ["slot3"] = true,
    ["sight"] = true, ["muzzle"] = true, ["underbarrel"] = true,
    ["barrel"] = true, ["magazine"] = true,
}
local EMPTY_HELD_NAMES = {
    ["hand"] = true, ["hands"] = true, ["fist"] = true, ["fists"] = true,
    ["unarmed"] = true, ["nothing"] = true, ["none"] = true, ["empty"] = true,
    ["hair"] = true,
}
local function parse_variant_name(name)
    if not name then return nil, nil end
    local base, variant = name:match("^([^/]+)/(.+)$")
    if base and variant then
        return base, variant
    end
    return name, nil
end
local function read_attribute(inst, key)
    if not inst or not key then return nil end
    if inst.GetAttribute then
        return inst:GetAttribute(key)
    end
    if inst.get_attribute then
        return inst:get_attribute(key)
    end
    return nil
end
local function is_tool(inst)
    if not inst then return false end
    local cn = inst.ClassName or inst.class_name
    return cn == "Tool"
end
local function is_empty_held_name(name)
    if not name or name == "" then return true end
    return EMPTY_HELD_NAMES[name:lower()] == true
end
local function is_attachment_slot_name(name)
    if not name or name == "" then return true end
    local lower = name:lower()
    if ATTACHMENT_SLOT_HINTS[lower] then return true end
    if lower:match("^p%d+$") then return true end
    if lower:match("^slot%d+$") then return true end
    return false
end
local function is_armor_child_name(name)
    if not name or name == "" then return true end
    if name:sub(1, 6) == "Armor_" or name:sub(1, 6) == "Armor:" then return true end
    if name:find("Armor", 1, true) and name:find("/", 1, true) then return true end
    return false
end
local function is_attachment_name(name)
    if not name or name == "" then return false end
    if is_attachment_slot_name(name) then return false end
    local base = select(1, parse_variant_name(name))
    local row = item_catalog.get_by_name(base)
    if row and row.type == "Attachment" then return true end
    local t = items.get_type(base)
    return t == "Attachment"
end
local function is_valid_held_label(name)
    if is_empty_held_name(name) then return false end
    if not name or name == "" then return false end
    if is_attachment_slot_name(name) then return false end
    if is_armor_child_name(name) then return false end
    if is_attachment_name(name) then return false end
    return true
end
local function looks_like_held_item(name)
    if not is_valid_held_label(name) then return false end
    if weapons.is_weapon_name(name) then return true end
    if items.is_held_display(name) then return true end
    return true
end
local function add_armor_piece(out, seen, piece)
    if not piece or not piece.name then return end
    if seen[piece.name] then return end
    seen[piece.name] = true
    table.insert(out.armor, piece)
end
local function add_held_piece(out, label)
    if is_empty_held_name(label) then
        out.held = nil
        return false
    end
    if not is_valid_held_label(label) then return false end
    local piece = items.resolve_item_label(label)
    if not piece then
        local base, variant = parse_variant_name(label)
        piece = items.make_piece(base or label, variant)
    end
    out.held = piece
    return true
end
local function add_attachment_piece(out, seen, label)
    if not label or label == "" then return end
    if is_attachment_slot_name(label) then return end
    if not is_attachment_name(label) then return end
    if seen[label] then return end
    seen[label] = true
    local piece = items.resolve_item_label(label)
    if not piece then
        local base, variant = parse_variant_name(label)
        piece = items.make_piece(base or label, variant)
    end
    table.insert(out.attachments, piece)
end
local function try_armor_model(out, seen, name)
    if not name then return end
    if name:sub(1, 6) == "Armor_" then
        add_armor_piece(out, seen, items.resolve_armor_model(name))
        return
    end
    if name:sub(1, 6) == "Armor:" then
        add_armor_piece(out, seen, items.resolve_item_label(name:sub(7)))
    end
end
local function try_armor_attribute(out, seen, attr_key)
    if not attr_key or attr_key:sub(1, 6) ~= "Armor_" then return end
    local tail = attr_key:match("^Armor_(.+)$")
    if not tail then return end
    local piece = items.resolve_armor_model(attr_key)
    if piece then
        add_armor_piece(out, seen, piece)
        return
    end
    local row = item_catalog.get_by_attribute(tail)
    if row and row.name then
        if tail == "ResistWet" and (seen["Hazmat Suit"] or seen["Wetsuit"]) then
            return
        end
        add_armor_piece(out, seen, items.make_piece(row.name, nil))
    end
end
local function scan_armor_attributes(inst, out, seen)
    for _, attr in ipairs(ARMOR_ATTRIBUTES) do
        local key = "Armor_" .. attr
        if read_attribute(inst, key) then
            try_armor_attribute(out, seen, key)
        end
    end
    local attrs = env.safe_call(function()
        if inst.get_attributes then return inst:get_attributes() end
        if inst.GetAttributes then return inst:GetAttributes() end
    end)
    if type(attrs) == "table" then
        for key in pairs(attrs) do
            if type(key) == "string" then
                try_armor_attribute(out, seen, key)
            end
        end
    end
end
local function scan_sleeves_string(out, seen, sleeves)
    if not sleeves or sleeves == "" then return end
    for entry in sleeves:gmatch("[^%^]+") do
        entry = entry:match("^%s*(.-)%s*$")
        if entry and entry ~= "" then
            add_armor_piece(out, seen, items.resolve_item_label(entry))
        end
    end
end
local function resolve_character(player)
    if player.character and env.is_valid(player.character) then
        return player.character
    end
    if player.player and env.is_valid(player.player) then
        local char = env.safe_call(function()
            local pl = player.player
            if pl.Character then return pl.Character end
            if pl.character then return pl.character end
        end)
        if char and env.is_valid(char) then return char end
    end
    if player.name and game and game.workspace then
        local char = env.safe_call(function()
            if game.workspace.find_first_child then
                return game.workspace:find_first_child(player.name)
            end
        end)
        if char and env.is_valid(char) then return char end
    end
    return nil
end
local function resolve_player_inst(player)
    if player.player and env.is_valid(player.player) then
        return player.player
    end
    if not player.name or not game or not game.players then return nil end
    return env.safe_call(function()
        if game.players.find_first_child then
            return game.players:find_first_child(player.name)
        end
    end)
end
local function find_inst_by_name(char, name)
    if not char or not name then return nil end
    for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
        local child_name = child.Name or child.name
        if child_name == name then
            return child
        end
    end
    return nil
end
local function find_held_on_character(char)
    if not char then return nil, nil end
    local fallback = nil
    for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
        local name = child.Name or child.name
        if not name or name == "" or is_armor_child_name(name) then goto continue end
        if not is_valid_held_label(name) then goto continue end
        if is_tool(child) then
            return name, child
        end
        local cn = child.ClassName or child.class_name
        if cn == "Model" and looks_like_held_item(name) then
            if weapons.is_weapon_name(name) or items.is_held_display(name) then
                return name, child
            end
            fallback = fallback or { name = name, inst = child }
        end
        ::continue::
    end
    if fallback then
        return fallback.name, fallback.inst
    end
    return nil, nil
end
local function player_tool_name(player)
    if not player then return nil end
    local name = player.ToolName or player.tool_name
    if type(name) == "string" and name ~= "" then return name end
    return nil
end
local function resolve_held_weapon(player, char)
    local tool_name = player_tool_name(player)
    if tool_name and is_valid_held_label(tool_name) then
        local inst = char and find_inst_by_name(char, tool_name) or nil
        return tool_name, inst
    end
    if char then
        local toolbar_name = inventory.get_toolbar_held_name(char)
        if toolbar_name and is_valid_held_label(toolbar_name) then
            local inst = find_inst_by_name(char, toolbar_name) or select(2, find_held_on_character(char))
            return toolbar_name, inst
        end
        local name, inst = find_held_on_character(char)
        if name then
            return name, inst
        end
    end
    if player.is_local then
        local name = weapons.get_held_weapon_name()
        if name and is_valid_held_label(name) then
            local inst = char and (find_inst_by_name(char, name) or select(2, find_held_on_character(char))) or nil
            return name, inst
        end
    end
    return nil, nil
end
local function find_attachments_folder(parent)
    if not parent or not env.is_valid(parent) then return nil end
    return env.safe_call(function()
        if parent.find_first_child then
            return parent:find_first_child("Attachments") or parent:find_first_child("attachments")
        end
        return parent:FindFirstChild("Attachments") or parent:FindFirstChild("attachments")
    end)
end
local function scan_weapon_attachments_folder(folder, out, seen, depth)
    depth = depth or 0
    if not folder or not env.is_valid(folder) or depth > 4 then return end
    local children = env.safe_call(function()
        if folder.get_children then return folder:get_children() end
        if folder.GetChildren then return folder:GetChildren() end
    end) or {}
    for _, child in ipairs(children) do
        local name = child.Name or child.name
        if not name or name == "" then goto continue end
        local cn = child.ClassName or child.class_name
        if cn == "StringValue" or cn == "stringvalue" then
            local val = child.Value or child.value
            if val and val ~= "" then
                add_attachment_piece(out, seen, val)
            end
            goto continue
        end
        if is_attachment_slot_name(name) then
            scan_weapon_attachments_folder(child, out, seen, depth + 1)
            goto continue
        end
        add_attachment_piece(out, seen, name)
        ::continue::
    end
end
local function scan_weapon_attachments(char, tool_inst, out, seen)
    if tool_inst and env.is_valid(tool_inst) then
        scan_weapon_attachments_folder(find_attachments_folder(tool_inst), out, seen)
        local weapon = env.safe_call(function()
            if tool_inst.find_first_child then return tool_inst:find_first_child("Weapon") end
            return tool_inst:FindFirstChild("Weapon")
        end)
        if weapon and env.is_valid(weapon) then
            scan_weapon_attachments_folder(find_attachments_folder(weapon), out, seen)
        end
        return
    end
    if not char then return end
    for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
        if is_tool(child) or (child.ClassName or child.class_name) == "Model" then
            scan_weapon_attachments(char, child, out, seen)
        end
    end
end
local function scan_armor_tree(inst, out, seen, depth)
    if not inst or not env.is_valid(inst) or depth > 8 then return end
    local name = inst.Name or inst.name
    if name and name ~= "" then
        if name:sub(1, 6) == "Armor_" or name:sub(1, 6) == "Armor:" then
            try_armor_model(out, seen, name)
        end
    end
    local children = env.safe_call(function()
        if inst.get_children then return inst:get_children() end
        if inst.GetChildren then return inst:GetChildren() end
    end) or {}
    for _, child in ipairs(children) do
        scan_armor_tree(child, out, seen, depth + 1)
    end
end
function M.is_empty_held_name(name)
    return is_empty_held_name(name)
end
function M.held_name(player)
    if not player then return nil end
    local char = resolve_character(player)
    local name = select(1, resolve_held_weapon(player, char))
    if name and is_valid_held_label(name) then return name end
    return nil
end
function M.held_name_from_character(char)
    if not char or not env.is_valid(char) then return nil end
    local name = select(1, find_held_on_character(char))
    if name and is_valid_held_label(name) then return name end
    return nil
end
function M.scan_player(player)
    local out = {
        held = nil,
        attachments = {},
        armor = {},
    }
    if not player then return out end
    local char = resolve_character(player)
    local held_name, tool_inst = resolve_held_weapon(player, char)
    if held_name then
        add_held_piece(out, held_name)
    end
    local att_seen = {}
    scan_weapon_attachments(char, tool_inst, out, att_seen)
    local seen = {}
    if char then
        scan_armor_tree(char, out, seen, 0)
        scan_armor_attributes(char, out, seen)
    end
    local pl = resolve_player_inst(player)
    if pl then
        scan_armor_attributes(pl, out, seen)
        scan_sleeves_string(out, seen, read_attribute(pl, "ArmorSleeves"))
    end
    return out
end
return M
end)()

April._mods["game.npcs"] = (function()
local env = April.require("core.env")
local folders = April.require("game.folders")
local esp_scan = April.require("game.esp_scan")
local M = {}
M.HOSTILE_NAMES = {
    Soldier = true,
    Bruno = true,
    Boris = true,
    Brutus = true,
    AttackHeli = true,
    BTR = true,
}
M.NPC_NAMES = {
    Soldier = true,
    Bruno = true,
    Boris = true,
    Brutus = true,
    AttackHeli = true,
    BTR = true,
    ["Diver Dave"] = true,
    ["Pilot Pete"] = true,
}
local EVENT_REFRESH_MS = 750
local entity_entries = {}
local event_entries = {}
local last_event_refresh = -EVENT_REFRESH_MS
local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end
local function clear_array(list)
    for i = #list, 1, -1 do list[i] = nil end
end
local function find_child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        if parent.FindFirstChild then return parent:FindFirstChild(name) end
        if parent.find_first_child then return parent:find_first_child(name) end
        return nil
    end)
end
local function children(parent)
    if not parent then return {} end
    return env.safe_call(function()
        if parent.GetChildren then return parent:GetChildren() end
        if parent.get_children then return parent:get_children() end
        return {}
    end) or {}
end
local function vec3(v)
    if not v then return nil end
    return v.X or v.x, v.Y or v.y, v.Z or v.z
end
local function address(value)
    if not value then return nil end
    return tostring(value.Address or value.address or value)
end
function M.is_hostile_name(name)
    return name and M.HOSTILE_NAMES[name] == true
end
function M.is_hostile_kind(kind)
    return kind == "soldier" or kind == "bruno" or kind == "boris"
        or kind == "brutus" or kind == "heli" or kind == "btr"
end
function M.is_boss_kind(kind)
    return kind == "bruno" or kind == "boris" or kind == "brutus"
        or kind == "heli" or kind == "btr"
end
function M.is_boss_name(name)
    return M.is_boss_kind(M.kind(name))
end
function M.kind(name)
    name = tostring(name or ""):lower():gsub("[%s_%-]", "")
    if name == "soldier" or name:find("soldier", 1, true) == 1 then return "soldier" end
    if name == "bruno" then return "bruno" end
    if name == "boris" then return "boris" end
    if name == "brutus" then return "brutus" end
    if name == "attackheli" or name:find("attackheli", 1, true) == 1 then return "heli" end
    if name == "btr" then return "btr" end
    if name == "diverdave" then return "diver_dave" end
    if name == "pilotpete" then return "pilot_pete" end
    return nil
end
function M.display_name(name, kind)
    if kind == "heli" then return "Attack Heli" end
    if kind == "btr" then return "BTR" end
    if kind == "diver_dave" then return "Diver Dave" end
    if kind == "pilot_pete" then return "Pilot Pete" end
    return name
end
local function part_pos(part)
    if not part then return nil end
    return vec3(part.Position or part.position)
end
local function part_name_lower(part)
    return tostring(part and (part.Name or part.name) or ""):lower()
end
function M.collect_heli_weak_points(model)
    if not model or not env.is_valid(model) then return {} end
    local out = {}
    local seen = {}
    local function add(part, score)
        if not part or not env.is_valid(part) then return end
        local key = address(part)
        if not key or seen[key] then return end
        local x, y, z = part_pos(part)
        if not x then return end
        seen[key] = true
        out[#out + 1] = {
            part = part,
            x = x, y = y, z = z,
            score = score or 1,
            name = part.Name or part.name,
        }
    end
    local desc = env.safe_call(function()
        if model.GetDescendants then return model:GetDescendants() end
        if model.get_descendants then return model:get_descendants() end
        return nil
    end)
    if type(desc) == "table" then
        for i = 1, #desc do
            local part = desc[i]
            if not part then goto cont end
            local cn = part.ClassName or part.class_name or ""
            if cn ~= "Part" and cn ~= "MeshPart" and cn ~= "BasePart"
                and cn ~= "WedgePart" and cn ~= "UnionOperation" then
                goto cont
            end
            local bonus = tonumber(env.get_attribute(part, "RotorBonus")) or 0
            if bonus > 0 then
                add(part, 100 + bonus)
            else
                local n = part_name_lower(part)
                if n:find("rotor", 1, true) or n:find("blade", 1, true)
                    or n == "spinner" or n:find("tailrotor", 1, true)
                    or n:find("mainrotor", 1, true) then
                    add(part, 40)
                end
            end
            ::cont::
        end
    else
        for _, name in ipairs({ "MainRotor", "TailRotor", "Blades", "Spinner" }) do
            local part = find_child(model, name)
            if part then add(part, 40) end
            for _, child in ipairs(children(part)) do
                local n = part_name_lower(child)
                if n:find("rotor", 1, true) or n:find("blade", 1, true) or n == "spinner" then
                    add(child, 40)
                end
            end
        end
    end
    table.sort(out, function(a, b)
        return (a.score or 0) > (b.score or 0)
    end)
    return out
end
function M.heli_aim_world(entry, prefer_screen, cx, cy)
    if not entry then return nil end
    local model = entry.inst
    if (not model or not env.is_valid(model)) and entry.entity then
        model = entry.entity.Character or entry.entity.character
    end
    local weak = M.collect_heli_weak_points(model)
    if #weak == 0 then
        local body = entry.root or entry.anchor or entry.head
        if (not body or not env.is_valid(body)) and model and env.is_valid(model) then
            body = find_child(model, "Main") or find_child(model, "HumanoidRootPart")
                or model.PrimaryPart or model.primary_part or esp_scan.find_main_part(model)
        end
        local x, y, z = part_pos(body)
        if x then return { x = x, y = y, z = z } end
        if entry.lx ~= nil and entry.ly ~= nil and entry.lz ~= nil then
            return { x = entry.lx, y = entry.ly, z = entry.lz }
        end
        return nil
    end
    if prefer_screen and cx and cy then
        local esp_util = April.require("core.esp_util")
        local math_util = April.require("core.math_util")
        local best, best_d = nil, math.huge
        for i = 1, #weak do
            local w = weak[i]
            local sx, sy, on = esp_util.w2s(w.x, w.y, w.z)
            if on then
                local d = math_util.screen_fov_dist(sx, sy, cx, cy)
                d = d - (w.score or 0) * 0.01
                if d < best_d then
                    best, best_d = w, d
                end
            end
        end
        if best then
            return { x = best.x, y = best.y, z = best.z }
        end
    end
    local top = weak[1]
    return { x = top.x, y = top.y, z = top.z }
end
local function read_humanoid(model)
    if not model then return nil end
    return env.safe_call(function()
        if model.FindFirstChildOfClass then return model:FindFirstChildOfClass("Humanoid") end
        if model.find_first_child_of_class then return model:find_first_child_of_class("Humanoid") end
        return find_child(model, "Humanoid")
    end)
end
function M.read_health(model, humanoid)
    if not model or not env.is_valid(model) then return nil end
    local hum = humanoid or read_humanoid(model)
    if hum then
        local hp = tonumber(hum.Health or hum.health)
        if hp and hp <= 0 then return nil end
        return {
            source = "humanoid",
            humanoid = hum,
            hp = hp,
            max_hp = tonumber(hum.MaxHealth or hum.max_health),
        }
    end
    local hp = tonumber(env.get_attribute(model, "Health"))
    local max_hp = tonumber(env.get_attribute(model, "MaxHealth"))
    if hp == nil and max_hp == nil then return nil end
    if hp and hp <= 0 then return nil end
    return { source = "attribute", hp = hp, max_hp = max_hp }
end
local function update_entity_entry(entry, player, name, kind)
    entry.entity = player
    entry.inst = player.Character or player.character
    entry.name = M.display_name(name, kind)
    entry.raw_name = name
    entry.kind = kind
    entry.event = false
    local x, y, z = vec3(player.HeadPosition or player.head_position or player.Position or player.position)
    if x then entry.lx, entry.ly, entry.lz = x, y, z end
    return entry
end
local function event_entry(model, name, kind)
    if not model or not env.is_valid(model) then return nil end
    local key = address(model)
    local entry = event_entries[key] or {}
    local root = entry.root
    if not root or not env.is_valid(root) then
        root = find_child(model, "HumanoidRootPart") or find_child(model, "Main")
            or esp_scan.find_main_part(model)
    end
    if not root or not env.is_valid(root) then return nil end
    entry.entity = nil
    entry.inst = model
    entry.name = M.display_name(name, kind)
    entry.raw_name = name
    entry.kind = kind
    entry.event = true
    entry.vehicle = kind == "heli" or kind == "btr"
    entry.root = root
    entry.anchor = root
    entry.humanoid = entry.humanoid or read_humanoid(model)
    entry.key = key
    entry.lx, entry.ly, entry.lz = vec3(root.Position or root.position)
    event_entries[key] = entry
    return entry
end
local function add_event(out, seen, model, expected_name)
    if not model then return end
    local name = model.Name or model.name or expected_name
    local kind = M.kind(name)
    if not kind and expected_name then
        name = expected_name
        kind = M.kind(name)
    end
    if not kind then return end
    local entry = event_entry(model, name, kind)
    if not entry or seen[entry.key] then return end
    seen[entry.key] = true
    out[#out + 1] = entry
end
local function refresh_events()
    local out, seen = {}, {}
    local events = folders.from_key("events")
    add_event(out, seen, find_child(events, "BTR"), "BTR")
    for _, child in ipairs(children(events)) do
        local name = child.Name or child.name
        if name == "AttackHeli" then add_event(out, seen, child, name) end
    end
    local ws = env.get_workspace()
    for _, child in ipairs(children(ws)) do
        local name = child.Name or child.name
        if name == "AttackHeli" or name == "BTR" then
            add_event(out, seen, child, name)
        end
    end
    local military = folders.from_key("military")
    for _, monument in ipairs(children(military)) do
        local location = monument.Name or monument.name
        for _, model in ipairs(children(monument)) do
            local kind = M.kind(model.Name or model.name)
            if kind == "soldier" or kind == "bruno" or kind == "boris" or kind == "brutus" then
                add_event(out, seen, model)
                local entry = event_entries[address(model)]
                if entry then entry.location = location end
            elseif (model.ClassName or model.class_name) == "Model" and read_humanoid(model) then
                add_event(out, seen, model, "Soldier")
                local entry = event_entries[address(model)]
                if entry then entry.location = location end
            end
        end
    end
    local loners = folders.from_key("loners")
    for _, npc_name in ipairs({ "Diver Dave", "Pilot Pete" }) do
        local bucket = find_child(loners, npc_name)
        for _, model in ipairs(children(bucket)) do
            if M.kind(model.Name or model.name) then
                add_event(out, seen, model, npc_name)
            end
        end
    end
    for key in pairs(event_entries) do
        if not seen[key] then event_entries[key] = nil end
    end
    return out
end
function M.refresh_cache(workspace_entities)
    local cache = April.require("core.cache")
    local out = cache.npcs
    clear_array(out)
    local seen = {}
    for i = 1, #(workspace_entities or {}) do
        local player = workspace_entities[i]
        local character = player and (player.Character or player.character)
        local name = player and (player.Name or player.name)
        if not M.kind(name) and character then
            name = character.Name or character.name or name
        end
        local kind = M.kind(name)
        if kind then
            local key = address(character or player)
            local entry = entity_entries[key] or {}
            entity_entries[key] = update_entity_entry(entry, player, name, kind)
            seen[key] = true
            out[#out + 1] = entry
        end
    end
    for key in pairs(entity_entries) do
        if not seen[key] then entity_entries[key] = nil end
    end
    local now = tick_ms()
    if now - last_event_refresh >= EVENT_REFRESH_MS then
        M._events = refresh_events()
        last_event_refresh = now
    end
    for i = 1, #(M._events or {}) do
        local entry = M._events[i]
        local duplicate = entry.key and seen[entry.key]
        if not duplicate and entry.inst and env.is_valid(entry.inst) then
            local x, y, z = vec3(entry.root and (entry.root.Position or entry.root.position))
            if x then entry.lx, entry.ly, entry.lz = x, y, z end
            out[#out + 1] = entry
        end
    end
    cache.stats.last_npc_scan = now
    return out
end
return M
end)()

April._mods["game.map_image"] = (function()
local env = April.require("core.env")
local asset_urls = April.require("game.asset_urls")
local config_store = April.require("core.config_store")
local debug = April.require("core.debug")
local M = {}
M.WORLD_SIZE = 12800
M.ORIGIN_X = 0
M.ORIGIN_Z = 0
M.DEFAULT_ASSET = "121836456123484"
M.TILE_GRID = 16
M.SOURCE_PX = 700
M.OCEAN = { 0.55, 0.78, 0.90, 0.55 }
local state = {
    place_id = nil,
    asset_id = nil,
    path = nil,
    png_url = nil,
    handle = nil,
    load_url = nil,
    load_idx = 0,
    load_chain = nil,
    ready = false,
    failed = false,
    fetch_started = false,
    fetch_done = false,
    last_resolve_ms = 0,
    next_retry_ms = 0,
    crops = {},
    active_crop = nil,
}
local RETRY_MS = 30000
local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end
local function place_id()
    if not game then return "0" end
    return tostring(game.place_id or game.PlaceId or 0)
end
local function find_child(parent, name)
    if not parent or not name then return nil end
    return env.safe_call(function()
        if parent.FindFirstChild then return parent:FindFirstChild(name) end
        if parent.find_first_child then return parent:find_first_child(name) end
        return parent[name]
    end)
end
local function player_inst()
    local lp = env.get_local_player()
    if not lp then return nil end
    local ep = April.require("core.entity_props")
    return ep.player_inst(lp) or lp
end
local function read_image_prop(inst)
    if not inst then return nil end
    return env.safe_call(function()
        return inst.Image or inst.image
    end)
end
local function asset_digits(value)
    if value == nil then return nil end
    return tostring(value):match("(%d+)")
end
local function resolve_map_image_inst()
    local pl = player_inst()
    local pgui = find_child(pl, "PlayerGui")
    local main = find_child(pgui, "Main")
    local map = find_child(main, "Map")
    local frame = find_child(map, "Frame")
    local map_img = find_child(frame, "Map")
    if map_img then return map_img end
    local rs = env.get_replicated_storage()
    if not rs then
        rs = env.safe_call(function()
            if game.GetService then return game:GetService("ReplicatedStorage") end
            if game.get_service then return game.get_service("ReplicatedStorage") end
            return nil
        end)
    end
    local uis = find_child(rs, "UIs")
    main = find_child(uis, "Main")
    map = find_child(main, "Map")
    frame = find_child(map, "Frame")
    return find_child(frame, "Map")
end
function M.resolve_asset_id()
    local now = tick_ms()
    if state.asset_id and (now - (state.last_resolve_ms or 0)) < 2000 then
        return state.asset_id
    end
    state.last_resolve_ms = now
    local inst = resolve_map_image_inst()
    local raw = read_image_prop(inst)
    local id = asset_digits(raw) or M.DEFAULT_ASSET
    state.asset_id = id
    return id
end
local function maps_dir()
    return config_store.get_config_path("April_maps")
end
local function ensure_dir(dir)
    if not dir or dir == "" then return false end
    local open = io and io.open
    if type(open) ~= "function" then return false end
    local probe = open(dir .. "\\.april_dir", "w")
    if probe then
        probe:close()
        if os and os.remove then pcall(os.remove, dir .. "\\.april_dir") end
        return true
    end
    if os and os.execute then
        pcall(os.execute, 'mkdir "' .. dir .. '" >nul 2>&1')
    end
    probe = open(dir .. "\\.april_dir", "w")
    if probe then
        probe:close()
        if os and os.remove then pcall(os.remove, dir .. "\\.april_dir") end
        return true
    end
    return false
end
function M.cache_path(pid, asset_id)
    pid = tostring(pid or place_id())
    asset_id = tostring(asset_id or M.resolve_asset_id() or M.DEFAULT_ASSET)
    local dir = maps_dir()
    ensure_dir(dir)
    return dir .. "\\" .. pid .. "_" .. asset_id .. ".png"
end
local function tiles_dir(asset_id)
    asset_id = tostring(asset_id or M.resolve_asset_id() or M.DEFAULT_ASSET)
    local dir = maps_dir() .. "\\tiles\\" .. asset_id
    ensure_dir(maps_dir())
    ensure_dir(maps_dir() .. "\\tiles")
    ensure_dir(dir)
    return dir
end
local function http_get(url)
    if not utility or not url then return nil end
    local fn = utility.HttpGet or utility.http_get
    if not fn then return nil end
    local ok, body = pcall(fn, url)
    if not ok then return nil end
    if type(body) == "string" and #body > 64 then
        return body
    end
    return nil
end
local function is_png(body)
    return type(body) == "string"
        and #body >= 8
        and body:byte(1) == 0x89
        and body:byte(2) == 0x50
        and body:byte(3) == 0x4E
        and body:byte(4) == 0x47
end
local function is_jpeg(body)
    return type(body) == "string"
        and #body >= 3
        and body:byte(1) == 0xFF
        and body:byte(2) == 0xD8
        and body:byte(3) == 0xFF
end
local function is_image_bytes(body)
    return is_png(body) or is_jpeg(body)
end
local function file_is_image(path)
    local f = io and io.open and io.open(path, "rb")
    if not f then return false end
    local head = f:read(16) or ""
    f:close()
    return is_image_bytes(head)
end
local function file_exists(path)
    return path and file_is_image(path)
end
local function write_bytes(path, body)
    if not path or not is_image_bytes(body) then return false end
    local f = io.open(path, "wb")
    if not f then return false end
    f:write(body)
    f:close()
    return file_is_image(path)
end
local function parse_thumbnail_image_url(json)
    if type(json) ~= "string" then return nil end
    local completed = json:match('"state"%s*:%s*"Completed".-"imageUrl"%s*:%s*"(https://[^"]+)"')
    if completed then return completed end
    return json:match('"imageUrl"%s*:%s*"(https://[^"]+)"')
end
local function is_https(url)
    return type(url) == "string" and url:find("^https://") ~= nil
end
local function is_usable_load_url(url)
    if not is_https(url) then return false end
    if url:find("Thumbs/Asset.ashx", 1, true) then return false end
    if url:find("assetdelivery", 1, true) then return false end
    if url:find("roblox.com/asset", 1, true) then return false end
    return true
end
local function resolve_png_url(asset_id)
    local sizes = { "700x700", "512x512", "420x420" }
    for i = 1, #sizes do
        local api = asset_urls.roblox_thumbnails_api(asset_id, sizes[i])
        local body = http_get(api)
        local url = parse_thumbnail_image_url(body)
        if is_usable_load_url(url) then
            return url
        end
    end
    return asset_urls.map_png(asset_id)
end
local function download_to(path, asset_id)
    local png_url = resolve_png_url(asset_id)
    state.png_url = png_url
    local candidates = {
        png_url,
        asset_urls.map_png(asset_id),
        asset_urls.roblox_thumb_hq(asset_id),
        asset_urls.roblox_thumb(asset_id),
    }
    for i = 1, #candidates do
        local url = candidates[i]
        if url then
            local body = http_get(url)
            if body and is_image_bytes(body) and write_bytes(path, body) then
                if is_usable_load_url(url) then
                    state.png_url = url
                elseif is_usable_load_url(png_url) then
                    state.png_url = png_url
                else
                    state.png_url = url
                end
                return true, state.png_url
            end
        end
    end
    return false, png_url
end
local function to_file_url(path)
    if not path then return nil end
    local normalized = path:gsub("\\", "/")
    if normalized:match("^[A-Za-z]:") then
        return "file:///" .. normalized
    end
    return "file://" .. normalized
end
local function build_load_chain(path, asset_id, png_url)
    local chain = {}
    local seen = {}
    local function add(url)
        if not is_usable_load_url(url) or seen[url] then return end
        seen[url] = true
        chain[#chain + 1] = url
    end
    add(png_url)
    add(resolve_png_url(asset_id))
    add(asset_urls.map_png(asset_id))
    return chain
end
local function invalidate_handle()
    if state.handle and draw and draw.free_image then
        pcall(draw.free_image, state.handle)
    end
    state.handle = nil
    state.ready = false
    state.failed = false
    state.load_idx = 0
    state.load_chain = nil
    state.load_url = nil
end
local function invalidate_crops()
    if draw and draw.free_image then
        for _, crop in pairs(state.crops) do
            if crop and crop.handle then
                pcall(draw.free_image, crop.handle)
            end
        end
    end
    state.crops = {}
    state.active_crop = nil
end
function M.invalidate()
    invalidate_handle()
    invalidate_crops()
    state.fetch_started = false
    state.fetch_done = false
    state.next_retry_ms = 0
    state.path = nil
    state.png_url = nil
    state.asset_id = nil
    state.place_id = nil
end
local function begin_load(path, asset_id, png_url)
    invalidate_handle()
    state.path = path
    state.asset_id = asset_id
    state.png_url = png_url or state.png_url
    state.load_chain = build_load_chain(path, asset_id, state.png_url)
    state.load_idx = 1
    state.failed = false
    state.ready = false
end
local function advance_load()
    if not draw or not draw.load_image then
        state.failed = true
        state.next_retry_ms = tick_ms() + RETRY_MS
        return nil
    end
    local chain = state.load_chain
    if not chain or state.load_idx > #chain then
        state.failed = true
        state.handle = nil
        state.next_retry_ms = tick_ms() + RETRY_MS
        return nil
    end
    local url = chain[state.load_idx]
    state.load_url = url
    debug.step("map_image.LoadImage.full " .. tostring(url))
    local ok, handle = pcall(draw.load_image, url)
    if not ok or not handle then
        state.load_idx = state.load_idx + 1
        return advance_load()
    end
    state.handle = handle
    return handle
end
local function tick_load()
    if state.failed then return nil end
    if not state.load_chain then return nil end
    if not state.handle then
        return advance_load()
    end
    if draw.image_failed and draw.image_failed(state.handle) then
        debug.warn_once("map_img:" .. tostring(state.load_url), "map load failed - " .. tostring(state.load_url))
        state.load_idx = state.load_idx + 1
        state.handle = nil
        return advance_load()
    end
    state.ready = true
    return state.handle
end
function M.ensure()
    local pid = place_id()
    local asset_id = M.resolve_asset_id()
    if state.place_id and state.place_id ~= pid then
        M.invalidate()
    end
    if state.asset_id and state.asset_id ~= asset_id and state.fetch_done then
        M.invalidate()
    end
    state.place_id = pid
    state.asset_id = asset_id
    local path = M.cache_path(pid, asset_id)
    state.path = path
    if path and not file_is_image(path) then
        pcall(os.remove, path)
    end
    if state.failed then
        local now = tick_ms()
        if now < (state.next_retry_ms or 0) then
            return nil
        end
        state.next_retry_ms = now + RETRY_MS
        invalidate_handle()
        state.fetch_started = false
        state.fetch_done = false
        state.failed = false
        state.load_chain = nil
        debug.warn_once("map_img:retry", "retrying world map load")
    end
    if not state.fetch_started then
        state.fetch_started = true
        if file_exists(path) then
            state.fetch_done = true
            state.png_url = resolve_png_url(asset_id)
            begin_load(path, asset_id, state.png_url)
        else
            local ok, png_url = download_to(path, asset_id)
            state.fetch_done = true
            state.png_url = png_url
            if ok then
                begin_load(path, asset_id, png_url)
            else
                begin_load(nil, asset_id, png_url)
            end
        end
    elseif state.fetch_done and not state.load_chain and not state.failed then
        begin_load(file_exists(path) and path or nil, asset_id, state.png_url or resolve_png_url(asset_id))
    end
    local handle = tick_load()
    if state.ready then
        state.next_retry_ms = 0
    end
    return handle
end
function M.handle()
    return M.ensure()
end
function M.ready()
    M.ensure()
    return state.ready == true and state.handle ~= nil and not state.failed
end
function M.failed()
    M.ensure()
    return state.failed == true
end
function M.world_size()
    return M.WORLD_SIZE
end
function M.origin()
    return M.ORIGIN_X, M.ORIGIN_Z
end
function M.world_to_uv(wx, wz)
    local ox, oz = M.origin()
    local size = M.world_size()
    local u = 0.5 + ((wx or 0) - ox) / size
    local v = 0.5 + ((wz or 0) - oz) / size
    return u, v
end
function M.uv_to_viewport(u, v, vp)
    if not vp then return nil, nil end
    local du = (vp.u1 - vp.u0)
    local dv = (vp.v1 - vp.v0)
    if du < 1e-6 or dv < 1e-6 then return nil, nil end
    return (u - vp.u0) / du, (v - vp.v0) / dv
end
function M.world_to_viewport(wx, wz, vp)
    local u, v = M.world_to_uv(wx, wz)
    return M.uv_to_viewport(u, v, vp)
end
local function image_is_loaded(handle)
    if not handle or not draw then return false end
    local loaded = draw.image_loaded or draw.ImageLoaded
    if loaded then
        local ok, yes = pcall(loaded, handle)
        return ok and yes == true
    end
    return true
end
local function image_has_failed(handle)
    if not handle or not draw then return false end
    local failed = draw.image_failed or draw.ImageFailed
    if not failed then return false end
    local ok, yes = pcall(failed, handle)
    return ok and yes == true
end
local function image_draw(handle, x, y, w, h, alpha)
    if not handle or not draw then return false end
    local image_fn = draw.image or draw.Image
    if not image_fn then return false end
    local a = math.floor(math.max(0, math.min(1, alpha or 1)) * 255)
    return pcall(image_fn, handle, x, y, w, h, 255, 255, 255, a)
end
local function draw_fit(map_rect, alpha)
    if not (M.ready() and state.handle) then return false end
    if image_has_failed(state.handle) then return false end
    return image_draw(state.handle, map_rect.x, map_rect.y, map_rect.w, map_rect.h, alpha)
end
local MAX_CROP_HANDLES = 12
local function crop_key(spec)
    return table.concat({
        spec.asset_id, spec.cx, spec.cy, spec.cw, spec.ch, spec.out_w, spec.out_h,
    }, ":")
end
local function crop_spec(view, map_rect)
    local img_size = tonumber(view and view.img_size) or 0
    if img_size <= 0 then return nil end
    local src = M.SOURCE_PX
    local cw = math.max(1, math.min(src, math.floor(src * map_rect.w / img_size + 0.5)))
    local ch = math.max(1, math.min(src, math.floor(src * map_rect.h / img_size + 0.5)))
    if cw >= src and ch >= src then return nil end
    local pu, pv = M.world_to_uv(view.view_x or 0, view.view_z or 0)
    local cx = math.floor(pu * src - cw * 0.5 + 0.5)
    local cy = math.floor(pv * src - ch * 0.5 + 0.5)
    cx = math.max(0, math.min(src - cw, cx))
    cy = math.max(0, math.min(src - ch, cy))
    local spec = {
        asset_id = tostring(state.asset_id or M.DEFAULT_ASSET),
        cx = cx, cy = cy, cw = cw, ch = ch,
        out_w = math.max(32, math.floor(map_rect.w + 0.5)),
        out_h = math.max(32, math.floor(map_rect.h + 0.5)),
        vp = {
            u0 = cx / src,
            v0 = cy / src,
            u1 = (cx + cw) / src,
            v1 = (cy + ch) / src,
            ready = true,
        },
    }
    spec.key = crop_key(spec)
    return spec
end
local function free_crop(entry)
    if entry and entry.handle and draw and draw.free_image then
        pcall(draw.free_image, entry.handle)
    end
    if state.active_crop == entry then state.active_crop = nil end
end
local function prune_crops()
    local count = 0
    for _ in pairs(state.crops) do count = count + 1 end
    while count > MAX_CROP_HANDLES do
        local oldest_key, oldest
        for key, entry in pairs(state.crops) do
            if entry ~= state.active_crop
                and (not oldest or (entry.last_used or 0) < (oldest.last_used or 0))
            then
                oldest_key, oldest = key, entry
            end
        end
        if not oldest_key then break end
        free_crop(oldest)
        state.crops[oldest_key] = nil
        count = count - 1
    end
end
local function ensure_crop(spec)
    if not spec or not draw then return nil end
    local load_fn = draw.load_image or draw.LoadImage
    if not load_fn then return nil end
    local entry = state.crops[spec.key]
    if not entry then
        local urls = asset_urls.map_crop_urls(
            spec.asset_id, spec.cx, spec.cy, spec.cw, spec.ch, spec.out_w, spec.out_h
        )
        entry = {
            key = spec.key,
            urls = urls,
            idx = 1,
            vp = spec.vp,
            last_used = tick_ms(),
        }
        state.crops[spec.key] = entry
        prune_crops()
        if state.crops[spec.key] ~= entry then return nil end
    end
    entry.last_used = tick_ms()
    if entry.handle then
        if image_has_failed(entry.handle) then
            free_crop(entry)
            entry.handle = nil
        elseif image_is_loaded(entry.handle) then
            entry.ready = true
            state.active_crop = entry
            prune_crops()
            return entry
        else
            return nil
        end
    end
    while entry.idx <= #(entry.urls or {}) do
        local url = entry.urls[entry.idx]
        entry.idx = entry.idx + 1
        debug.step("map_image.LoadImage.crop " .. tostring(url))
        local ok, handle = pcall(load_fn, url)
        if ok and handle then
            entry.handle = handle
            entry.url = url
            if image_is_loaded(handle) then
                entry.ready = true
                state.active_crop = entry
                prune_crops()
                return entry
            end
            return nil
        end
    end
    entry.failed = true
    prune_crops()
    return nil
end
local function draw_crop(entry, map_rect, alpha)
    if not entry or not entry.handle or not image_is_loaded(entry.handle) then
        return false
    end
    return image_draw(entry.handle, map_rect.x, map_rect.y, map_rect.w, map_rect.h, alpha)
end
function M.draw_centered(view, map_rect, alpha)
    if not view or not map_rect then
        return nil
    end
    M.ensure()
    alpha = alpha or 0.92
    if draw and (draw.rect_filled or draw.RectFilled) then
        local rf = draw.rect_filled or draw.RectFilled
        pcall(rf, map_rect.x, map_rect.y, map_rect.w, map_rect.h, M.OCEAN, 0)
    end
    local spec = crop_spec(view, map_rect)
    if spec then
        debug.step("map_image.ensure_crop:" .. tostring(spec.key))
        local wanted = ensure_crop(spec)
        if wanted and draw_crop(wanted, map_rect, alpha) then
            view.vp = wanted.vp
            debug.step_done("map_image.crop")
            return "crop"
        end
        local active = state.active_crop
        if active and draw_crop(active, map_rect, alpha) then
            active.last_used = tick_ms()
            view.vp = active.vp
            debug.step_done("map_image.crop_prev")
            return "crop"
        end
    end
    debug.step("map_image.draw_fit")
    if draw_fit(map_rect, alpha) then
        view.vp = { u0 = 0, v0 = 0, u1 = 1, v1 = 1, ready = true }
        debug.step_done("map_image.fit")
        return "fit"
    end
    return nil
end
function M.draw(x, y, w, h, alpha)
    local handle = M.handle()
    if not handle then return false end
    return image_draw(handle, x, y, w, h, alpha)
end
return M
end)()

April._mods["game.turret_stats"] = (function()
local M = {}
M.ACTIVATION_RANGE = {
    ["Auto Turret"] = 100,
    ["Shotgun Turret"] = 110,
}
M.BULLET_RANGE = {
    ["Auto Turret"] = 150,
    ["Shotgun Turret"] = 14.25,
}
M.DAMAGE_RANGE = {
    ["Auto Turret"] = { 85, 150 },
    ["Shotgun Turret"] = { 9, 25 },
}
function M.activation_range(name)
    return M.ACTIVATION_RANGE[name]
end
return M
end)()

April._mods["game.toolinfo_weapon_mods"] = (function()
local bootstrap = April.require("game.bootstrap")
local M = {}
M._baseline = nil
M._applied = false
M._last_sig = nil
local function deep_copy(v, seen)
    if type(v) ~= "table" then return v end
    seen = seen or {}
    if seen[v] then return seen[v] end
    local out = {}
    seen[v] = out
    for k, val in pairs(v) do
        out[k] = deep_copy(val, seen)
    end
    return out
end
local function ensure_baseline(toolinfo)
    if M._baseline then return true end
    if type(toolinfo) ~= "table" then return false end
    M._baseline = deep_copy(toolinfo)
    return true
end
local function weapon_entry(toolinfo, name)
    local entry = toolinfo[name]
    if type(entry) ~= "table" then return nil end
    return entry.Weapon
end
local function baseline_weapon(name)
    if not M._baseline then return nil end
    local entry = M._baseline[name]
    if type(entry) ~= "table" then return nil end
    return entry.Weapon
end
local function restore_weapon(live_w, old_w)
    if not live_w or not old_w then return end
    pcall(function()
        if old_w.Burst ~= nil then
            live_w.Burst = old_w.Burst
        end
        if old_w.BurstRPM ~= nil then
            live_w.BurstRPM = old_w.BurstRPM
        end
    end)
end
local function apply_weapon(live_w, old_w, opts)
    if not live_w then return false end
    local changed = false
    if opts.double_tap then
        local ok = pcall(function()
            if live_w.Burst ~= nil or (old_w and old_w.Burst ~= nil) then
                live_w.Burst = 2
                live_w.BurstRPM = 10000
                changed = true
            end
        end)
        if not ok then return false end
    elseif old_w then
        restore_weapon(live_w, old_w)
    end
    return changed
end
function M.invalidate()
    M._baseline = nil
    M._applied = false
    M._last_sig = nil
end
function M.reset()
    local ok = pcall(function()
        local toolinfo = bootstrap.get_module("ToolInfo")
        if not toolinfo or not M._baseline then
            M._applied = false
            M._last_sig = nil
            return false
        end
        for name, entry in pairs(toolinfo) do
            if type(entry) == "table" and type(entry.Weapon) == "table" then
                restore_weapon(entry.Weapon, baseline_weapon(name))
            end
        end
        M._applied = false
        M._last_sig = nil
        return true
    end)
    if not ok then
        M._applied = false
        M._last_sig = nil
    end
    return ok
end
function M.apply(opts, weapon_name)
    opts = opts or {}
    local ok, success, count, msg = pcall(function()
        local toolinfo = bootstrap.get_module("ToolInfo")
        if not toolinfo then
            return false, 0, "ToolInfo not ready"
        end
        if not ensure_baseline(toolinfo) then
            return false, 0, "ToolInfo baseline failed"
        end
        local any = opts.double_tap == true
        if not any then
            if M._applied then
                M.reset()
            end
            return true, 0, "no toolinfo mods"
        end
        if not weapon_name or weapon_name == "" then
            return false, 0, "Equip a gun first"
        end
        local sig = table.concat({
            opts.double_tap and "1" or "0",
            tostring(weapon_name),
        }, ":")
        if sig == M._last_sig and M._applied then
            return true, 0, "unchanged"
        end
        for name, entry in pairs(toolinfo) do
            if type(entry) == "table" and type(entry.Weapon) == "table" then
                restore_weapon(entry.Weapon, baseline_weapon(name))
            end
        end
        local patched = 0
        local live_w = weapon_entry(toolinfo, weapon_name)
        if apply_weapon(live_w, baseline_weapon(weapon_name), opts) then
            patched = 1
        end
        M._applied = patched > 0
        M._last_sig = sig
        if patched > 0 then
            return true, patched, string.format("%d weapon(s) patched", patched)
        end
        return false, 0, "Weapon does not support burst"
    end)
    if not ok then
        return false, 0, tostring(success)
    end
    return success, count, msg
end
return M
end)()
