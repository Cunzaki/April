-- Underground (UG) resolver for laying / sunk-HRP anti-aim (POC).
-- While enabled, the current silent/aimbot target gets a 4x head hitbox and
-- their whole body is lifted +2 studs on the client every frame.
-- Mutually exclusive with Hitbox Override.
--
-- UI retired for now — set UI_RETIRED = false and re-add the Bullet → Resolver
-- checkbox when bringing this back.

local settings = April.require("core.settings")
local ep = April.require("core.entity_props")
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local move = April.require("core.cframe_move")

local M = {}

-- POC parked: keep module + hooks, but never activate from UI/config.
local UI_RETIRED = true

local P_BULLET = "april_bullet_enabled"
local P = "april_bullet_ug_resolver"
local P_THICK = "april_thick_bullet"
local P_THICK_MULT = "april_thick_bullet_mult"

local UG_MULT = 4
local LIFT_STUDS = 2
local UG_MARGIN = 1.35
local HEAD_ROOT_GAP = 3.0

local last_ug_target = nil
local lift_state = nil -- { key, raw_y, applied_y }
local wired = false

local function thick()
    local ok, mod = pcall(function()
        return April.require("features.combat.thick_bullet")
    end)
    if ok then return mod end
    return nil
end

local function make_vec3(x, y, z)
    if not Vector3 then return nil end
    local ctor = Vector3.New or Vector3.new
    if type(ctor) ~= "function" then return nil end
    local ok, v = pcall(ctor, x, y, z)
    if ok then return v end
    return nil
end

local function cast_fn()
    if not raycast then return nil end
    return raycast.cast or raycast.Cast
end

local function ray_ready()
    if not raycast then return false end
    local ready = raycast.is_ready or raycast.IsReady
    if type(ready) ~= "function" then return true end
    local ok, value = pcall(ready)
    return (not ok) or value ~= false
end

local function unpack_hit_y(pos)
    if pos == nil or type(pos) == "number" then return nil end
    local y = pos.Y or pos.y
    if type(y) == "number" then return y end
    local _, py = esp_util.vec3_pos(pos)
    return py
end

local function floor_y_at(x, y, z)
    local cast = cast_fn()
    if type(cast) ~= "function" or not ray_ready() then return nil end
    local starts = { y + 64, y + 256, 512 }
    for i = 1, #starts do
        local sy = starts[i]
        if sy < y + 8 then sy = y + 8 end
        local ok, hit, pos = pcall(cast, x, sy, z, x, y - 512, z)
        if ok and hit then
            local fy = unpack_hit_y(pos)
            if fy then return fy end
        end
    end
    return nil
end

local function humanoid_hip_height(target)
    local hh = tonumber(ep.get(target, "HipHeight", "hip_height"))
    if hh then return hh end
    local hum = ep.humanoid(target)
    if not hum then return nil end
    local ok, value = pcall(function()
        return hum.HipHeight or hum.hip_height
    end)
    if ok then return tonumber(value) end
    return nil
end

local function set_bool(id, value)
    if menu and menu.set then
        pcall(menu.set, id, value == true)
    end
    pcall(function()
        April.require("ui.gs_state").set(id, value == true)
    end)
end

local function set_visible(id, show)
    if menu and menu.set_visible then
        pcall(menu.set_visible, id, show == true)
    end
    pcall(function()
        April.require("ui.gs_state").set_visible(id, show == true)
    end)
end

local function sync_thick_gate()
    local ug_on = settings.bool(P, false) == true
    if ug_on then
        if settings.bool(P_THICK, false) then
            set_bool(P_THICK, false)
        end
        set_visible(P_THICK, false)
        set_visible(P_THICK_MULT, false)
    else
        local bullet_on = settings.enabled(P_BULLET)
        set_visible(P_THICK, bullet_on)
        set_visible(P_THICK_MULT, bullet_on and settings.bool(P_THICK, false))
    end
end

function M.wire_menu()
    if wired then return end
    wired = true
    settings.on_change(P, function(v)
        if v == true or v == 1 then
            set_bool(P_THICK, false)
        end
        sync_thick_gate()
    end)
    settings.on_change(P_THICK, function(v)
        if (v == true or v == 1) and settings.bool(P, false) then
            set_bool(P_THICK, false)
        end
        sync_thick_gate()
    end)
    settings.on_change(P_BULLET, function()
        sync_thick_gate()
    end)
    sync_thick_gate()
end

function M.enabled()
    if UI_RETIRED then return false end
    return settings.enabled(P_BULLET) and settings.bool(P, false)
end

function M.is_underground(target, point)
    if not target and not point then return false end

    local hx, hy, hz
    if point then
        hx, hy, hz = point.x, point.y, point.z
    end
    if type(hx) ~= "number" then
        local head = ep.head_position(target)
        if head then
            hx, hy, hz = esp_util.vec3_pos(head)
        end
    end

    local rx, ry, rz
    local root = target and ep.position(target) or nil
    if root then
        rx, ry, rz = esp_util.vec3_pos(root)
    end

    -- Live HRP read (entity cache can lag behind the sunk root).
    if target then
        local char = ep.character(target)
        local hrp = char and move.find_part(char, "HumanoidRootPart") or nil
        if hrp and env.is_valid(hrp) then
            local px, py, pz = move.read_pos(hrp)
            if px then
                rx, ry, rz = px.x, px.y, px.z
            end
        end
    end

    if hy and ry and (hy - ry) >= HEAD_ROOT_GAP then
        return true
    end

    if type(rx) == "number" and type(ry) == "number" and type(rz) == "number" then
        local fy = floor_y_at(rx, ry, rz)
        if fy and ry < fy + UG_MARGIN then
            return true
        end
    end

    if type(hx) == "number" and type(hy) == "number" and type(hz) == "number" then
        local fy = floor_y_at(hx, hy, hz)
        if fy and hy < fy + UG_MARGIN then
            return true
        end
    end

    local hh = humanoid_hip_height(target)
    if hh and hh < 0.15 then
        return true
    end

    return false
end

local function part_key(part)
    return part.Address or part.address or tostring(part)
end

local function read_part_pos(part)
    local p = move.read_pos(part)
    if not p then return nil end
    return p.x, p.y, p.z
end

local function write_part_pos(inst, x, y, z)
    if not inst then return false end
    local wrote = false
    -- Do not name the arg `part` — that shadows Vector's global part.* API.
    if part and part.set_position then
        wrote = pcall(part.set_position, inst, x, y, z) or wrote
    end
    local v = make_vec3(x, y, z)
    if v then
        wrote = pcall(function() inst.Position = v end) or wrote
        wrote = pcall(function() inst.position = v end) or wrote
    end
    pcall(function()
        local cf = inst.CFrame or inst.cframe
        if not cf then return end
        local ctor = CFrame and (CFrame.new or CFrame.New)
        if type(ctor) ~= "function" then return end
        if cf.Position or cf.position then
            local pos = cf.Position or cf.position
            local rotation = cf - pos
            inst.CFrame = ctor(x, y, z) * rotation
        else
            inst.CFrame = ctor(x, y, z)
        end
        wrote = true
    end)
    move.set_position_only(inst, x, y, z)
    return wrote
end

local function write_entity_pos(player, x, y, z)
    if not player then return false end
    local v = make_vec3(x, y, z)
    if not v then return false end
    local wrote = false
    wrote = pcall(function() player.Position = v end) or wrote
    wrote = pcall(function() player.position = v end) or wrote
    return wrote
end

local function find_hrp(char)
    if not char then return nil end
    return move.find_part(char, "HumanoidRootPart")
end

local function clear_lift()
    lift_state = nil
end

local function clear_last_if_needed(current)
    if not last_ug_target or last_ug_target == current then return end
    local tb = thick()
    if tb and tb.restore_player then
        pcall(tb.restore_player, last_ug_target)
    end
    last_ug_target = nil
    clear_lift()
end

local function body_parts(char, hrp)
    local parts = move.iter_parts(char)
    if type(parts) == "table" and #parts > 0 then
        return parts
    end
    -- Fallback: named R6/R15 body parts if descendant scan failed.
    local names = {
        "HumanoidRootPart", "Head", "Torso", "UpperTorso", "LowerTorso",
        "Left Arm", "Right Arm", "Left Leg", "Right Leg",
        "LeftUpperArm", "LeftLowerArm", "LeftHand",
        "RightUpperArm", "RightLowerArm", "RightHand",
        "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
        "RightUpperLeg", "RightLowerLeg", "RightFoot",
    }
    local out = {}
    local seen = {}
    if hrp and env.is_valid(hrp) then
        out[#out + 1] = hrp
        seen[part_key(hrp)] = true
    end
    for i = 1, #names do
        local p = move.find_part(char, names[i])
        if p and env.is_valid(p) and move.is_base_part(p) then
            local key = part_key(p)
            if not seen[key] then
                seen[key] = true
                out[#out + 1] = p
            end
        end
    end
    return out
end

-- Lift every character BasePart by the same delta so the whole body moves +2.
local function lift_body(target)
    local char = ep.character(target)
    if not char or not env.is_valid(char) then return nil end

    local hrp = find_hrp(char)
    local anchor = hrp
    if not anchor or not env.is_valid(anchor) then
        local tb = thick()
        anchor = tb and tb.find_head and tb.find_head(target) or nil
    end
    if not anchor or not env.is_valid(anchor) then return nil end

    local ax, ay, az = read_part_pos(anchor)
    if not ax then
        local ent = ep.position(target)
        if ent then
            ax, ay, az = esp_util.vec3_pos(ent)
        end
    end
    if not ax then return nil end

    local key = part_key(anchor)
    local raw_y = ay
    if lift_state and lift_state.key == key and lift_state.applied_y then
        if math.abs(ay - lift_state.applied_y) < 0.35 then
            raw_y = lift_state.raw_y
        end
    end

    local target_y = raw_y + LIFT_STUDS
    local dy = target_y - ay

    -- Always re-assert the lift (network snaps remote characters back).
    write_entity_pos(target, ax, target_y, az)

    local parts = body_parts(char, hrp)
    if #parts == 0 then
        write_part_pos(anchor, ax, target_y, az)
        write_part_pos(anchor, ax, target_y, az)
    else
        for _ = 1, 2 do
            for i = 1, #parts do
                local inst = parts[i]
                local px, py, pz = read_part_pos(inst)
                if px then
                    if math.abs(dy) >= 1e-4 then
                        write_part_pos(inst, px, py + dy, pz)
                    else
                        -- Re-assert current lifted pose against network snapback.
                        write_part_pos(inst, px, py, pz)
                    end
                end
            end
            -- Re-read anchor after first pass so second pass uses updated dy=0 path
            -- only when the write stuck; otherwise dy still lifts again.
            ax, ay, az = read_part_pos(anchor)
            if ax then
                dy = target_y - ay
            end
        end
    end

    lift_state = {
        key = key,
        raw_y = raw_y,
        applied_y = target_y,
    }

    local tb = thick()
    local head = tb and tb.find_head and tb.find_head(target) or nil
    if head then
        local hx, hy, hz = read_part_pos(head)
        if hx then
            -- If the head write did not stick, still aim at the intended lift.
            if math.abs(hy - (raw_y + (hy - ay) + LIFT_STUDS)) > 0.75 then
                return { x = hx, y = hy + dy, z = hz }
            end
            return { x = hx, y = hy, z = hz }
        end
    end

    local head_pos = ep.head_position(target)
    if head_pos then
        local hx, hy, hz = esp_util.vec3_pos(head_pos)
        if hx then
            return { x = hx, y = hy + dy, z = hz }
        end
    end

    return { x = ax, y = target_y, z = az }
end

--- Force Head hitbox 4x, lift whole body +2 studs, aim at lifted head.
function M.apply(target, point)
    if not M.enabled() then
        clear_last_if_needed(nil)
        last_ug_target = nil
        clear_lift()
        return point
    end
    if not target or ep.is_local(target) then return point end

    clear_last_if_needed(target)
    last_ug_target = target

    local tb = thick()
    if tb and tb.ensure_inflated then
        tb.ensure_inflated(target, UG_MULT)
    end

    local lifted_aim = lift_body(target)
    if lifted_aim then
        return lifted_aim
    end

    if point then
        return {
            x = point.x,
            y = point.y + LIFT_STUDS,
            z = point.z,
        }
    end
    return point
end

function M.update(_dt)
    if not M.enabled() then
        clear_last_if_needed(nil)
        last_ug_target = nil
        clear_lift()
        return
    end

    local ok, active_target = pcall(function()
        return April.require("features.combat.active_target")
    end)
    if not ok or not active_target or not active_target.get_target then
        return
    end

    local target = active_target.get_target()
    if not target or ep.is_local(target) then
        clear_last_if_needed(nil)
        last_ug_target = nil
        clear_lift()
        return
    end

    -- Keep the body lifted every frame while they are the aim target.
    M.apply(target, nil)
end

function M.draw() end

return M
