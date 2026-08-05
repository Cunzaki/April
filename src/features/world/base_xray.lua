-- Base Xray: Wireframe ApplyChams on structural Detail meshes ONLY.
--
-- Detection note: writing Material/TextureID/Transparency/LTM on Workspace.Bases
-- parts is unsafe and has correlated with Fallen bans. This module never mutates
-- instance properties and never creates instances — only exploits.ApplyChamsToInstance
-- via gpu_chams (engine overlay, Wireframe mode locked).
--
-- Structural only (Wall/Floor/Foundation/…). Never Base ESP targets.
local settings = April.require("core.settings")
local env = April.require("core.env")
local folders = April.require("game.folders")
local menu_util = April.require("core.menu_util")
local maps = April.require("game.esp_maps")
local gpu_chams = April.require("core.gpu_chams")

local M = {}

local P = "april_base_xray_enabled"
local P_RANGE = "april_base_xray_range"
local OWNER = "base_xray"
local WIREFRAME = 1

local RESCAN_MS = 700
local BATCH = 72

local STRUCT = {
    Wall = true,
    ["Half Wall"] = true,
    ["Wall Frame"] = true,
    Foundation = true,
    ["Triangle Foundation"] = true,
    Floor = true,
    ["Triangle Floor"] = true,
    Doorway = true,
    Window = true,
    ["Foundation Steps"] = true,
    Ramps = true,
    ["Floor Grill"] = true,
    ["L-Shaped Stairs"] = true,
}

local VISUAL_NAMES = {
    Detail = true,
    Detail1 = true,
    Detail2 = true,
    Pole = true,
    Fill = true,
}

local SKIP_PART_NAMES = {
    BuildingPriv = true,
    CollisionPart = true,
    Collision = true,
    WeldPart = true,
}

local installed = false
local scan = nil
local cached_parts = {}
local last_scan_done = 0

local function now_ms()
    local fn = utility and (utility.get_tick_count or utility.GetTickCount)
    if type(fn) ~= "function" then return 0 end
    local ok, value = pcall(fn)
    return ok and (tonumber(value) or 0) or 0
end

local function children_of(parent)
    if not parent then return {} end
    return env.safe_call(function()
        if parent.GetChildren then return parent:GetChildren() end
        if parent.get_children then return parent:get_children() end
        return {}
    end) or {}
end

local function read_pos(inst)
    if not inst then return nil end
    local p = inst.Position or inst.position
    if not p then return nil end
    local x, y, z = p.x or p.X, p.y or p.Y, p.z or p.Z
    if x == nil or y == nil or z == nil then return nil end
    return x, y, z
end

local function local_pos()
    local me = env.get_local_player()
    local p = me and (me.Position or me.position)
    if not p then return nil end
    local x, y, z = p.x or p.X, p.y or p.Y, p.z or p.Z
    if x == nil then return nil end
    return { x = x, y = y, z = z }
end

local function is_visual_part(inst)
    if not gpu_chams.is_part(inst) then return false end
    local name = inst.Name or inst.name
    if not name or SKIP_PART_NAMES[name] then return false end
    if VISUAL_NAMES[name] then return true end
    local cn = inst.ClassName or inst.class_name
    return name == "Main" and (cn == "UnionOperation" or cn == "MeshPart")
end

local function collect_visual_parts(model, out)
    if not model or not env.is_valid(model) then return end
    if is_visual_part(model) then
        out[#out + 1] = model
        return
    end
    local kids = children_of(model)
    for i = 1, #kids do
        local child = kids[i]
        if not child or not env.is_valid(child) then goto cont end
        local name = child.Name or child.name
        if name == "CollisionParts" or (name and SKIP_PART_NAMES[name]) then
            goto cont
        end
        if is_visual_part(child) then
            out[#out + 1] = child
        else
            local cn = child.ClassName or child.class_name
            if cn == "Folder" or cn == "Model" then
                collect_visual_parts(child, out)
            end
        end
        ::cont::
    end
end

local function model_anchor(model)
    if not model then return nil end
    local detail = env.safe_call(function()
        if model.FindFirstChild then return model:FindFirstChild("Detail") end
        if model.find_first_child then return model:find_first_child("Detail") end
        return nil
    end)
    if detail and gpu_chams.is_part(detail) then return detail end
    local main = env.safe_call(function()
        if model.FindFirstChild then return model:FindFirstChild("Main") end
        if model.find_first_child then return model:find_first_child("Main") end
        return nil
    end)
    if main and gpu_chams.is_part(main) then return main end
    local kids = children_of(model)
    for i = 1, #kids do
        if gpu_chams.is_part(kids[i]) then return kids[i] end
    end
    return nil
end

local function begin_scan()
    return {
        areas = children_of(folders.from_key("bases")),
        ai = 1,
        types = nil,
        ti = 1,
        models = nil,
        mi = 1,
        parts = {},
    }
end

local function step_scan(state, origin, range_sq, batch)
    local processed = 0
    while processed < batch do
        if state.ai > #state.areas then
            return true
        end
        if not state.types then
            local area = state.areas[state.ai]
            if not env.is_valid(area) then
                state.ai = state.ai + 1
                processed = processed + 1
                goto continue
            end
            local area_name = area.Name or area.name or ""
            if maps.BASE_SKIP_AREAS[area_name] or maps.BASE_MAP[area_name] then
                state.ai = state.ai + 1
                processed = processed + 1
                goto continue
            end
            state.types = children_of(area)
            state.ti = 1
            state.models = nil
        end
        if state.ti > #state.types then
            state.ai = state.ai + 1
            state.types = nil
            state.models = nil
            goto continue
        end
        if not state.models then
            local type_folder = state.types[state.ti]
            if not env.is_valid(type_folder) then
                state.ti = state.ti + 1
                processed = processed + 1
                goto continue
            end
            local type_name = type_folder.Name or type_folder.name
            if not type_name or not STRUCT[type_name] or maps.BASE_MAP[type_name] then
                state.ti = state.ti + 1
                processed = processed + 1
                goto continue
            end
            state.models = children_of(type_folder)
            state.mi = 1
        end
        if state.mi > #state.models then
            state.ti = state.ti + 1
            state.models = nil
            goto continue
        end
        local model = state.models[state.mi]
        state.mi = state.mi + 1
        processed = processed + 1
        if env.is_valid(model) then
            local model_name = model.Name or model.name
            if model_name and maps.BASE_MAP[model_name] then
                goto continue
            end
            local anchor = model_anchor(model)
            local x, y, z = read_pos(anchor)
            if x then
                local dx = x - origin.x
                local dy = y - origin.y
                local dz = z - origin.z
                if (dx * dx + dy * dy + dz * dz) <= range_sq then
                    collect_visual_parts(model, state.parts)
                end
            end
        end
        ::continue::
    end
    return false
end

local function xray_active()
    return settings.enabled(P) and gpu_chams.available()
end

local function collect_xray(applied)
    local origin = local_pos()
    if not origin then return end
    local range = math.max(40, settings.num(P_RANGE, 180))
    local range_sq = range * range
    local now = now_ms()

    if not scan or (scan.done and now - last_scan_done >= RESCAN_MS) then
        scan = begin_scan()
    end

    if scan and not scan.done then
        if step_scan(scan, origin, range_sq, BATCH) then
            scan.done = true
            last_scan_done = now
            cached_parts = scan.parts
        end
    end

    for i = 1, #cached_parts do
        local part = cached_parts[i]
        if part and env.is_valid(part) then
            local x, y, z = read_pos(part)
            if x then
                local dx = x - origin.x
                local dy = y - origin.y
                local dz = z - origin.z
                if (dx * dx + dy * dy + dz * dz) <= range_sq then
                    -- ApplyChams only. No property writes. No instance creation.
                    gpu_chams.cham_part(part, applied)
                end
            end
        end
    end
end

local function ensure_owner()
    if not gpu_chams.available() then return end
    if gpu_chams.get_owner(OWNER) then return end
    gpu_chams.register_owner(OWNER, {
        rescan_ms = 250,
        is_active = xray_active,
        style = function()
            return WIREFRAME, 0
        end,
        collect = collect_xray,
    })
    settings.on_change(P, function(v)
        if v == true or v == 1 then
            gpu_chams.sync_owner(OWNER, true)
        else
            gpu_chams.clear_owner(OWNER)
            scan = nil
            cached_parts = {}
        end
    end)
    settings.on_change(P_RANGE, function()
        gpu_chams.sync_owner(OWNER, true)
    end)
end

function M.install()
    if installed then return end
    installed = true
    ensure_owner()
end

function M.register_menu()
    local G = menu_util.G
    local T = menu_util.group(G.WORLD)
    menu_util.section(T, G.WORLD, "Base Xray")
    menu_util.register_keybind(T, G.WORLD, P, "Base Xray", false)
    menu.add_slider_int(
        T, G.WORLD, P_RANGE, "Xray Range", 40, 500, 180,
        menu_util.parent(P)
    )
    menu_util.bind_children(P, { P_RANGE })
    if gpu_chams.available() then
        ensure_owner()
    end
end

function M.update()
    ensure_owner()
    if not settings.enabled(P) or not gpu_chams.available() then return end

    local origin = local_pos()
    local range = math.max(40, settings.num(P_RANGE, 180))
    local range_sq = range * range

    if origin then
        if not scan or (scan.done and now_ms() - last_scan_done >= RESCAN_MS) then
            scan = begin_scan()
        end
        if scan and not scan.done then
            if step_scan(scan, origin, range_sq, BATCH) then
                scan.done = true
                last_scan_done = now_ms()
                cached_parts = scan.parts
            end
        end
    end

    local owner = gpu_chams.get_owner(OWNER)
    if xray_active() or (owner and (owner.was_active or next(owner.applied))) then
        gpu_chams.sync_owner(OWNER)
    end
end

function M.draw() end

return M
