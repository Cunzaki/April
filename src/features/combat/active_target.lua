-- Resolve the active combat target + aim point from ragebot / silent / aimbot.
local settings = April.require("core.settings")
local targeting = April.require("features.combat.targeting")
local combat_origin = April.require("game.combat_origin")
local esp_util = April.require("core.esp_util")

local M = {}

M.SOURCE_NAMES = { "Auto", "Ragebot", "Silent Aim", "Aimbot" }
M.SOURCE_CROSSHAIR = "april_crosshair_source"
M.SOURCE_GEAR = "april_target_gear_source"

local MODULES = {
    { id = "april_rage_enabled", path = "features.combat.ragebot", prefix = "april_rage_" },
    { id = "april_silent_aim", path = "features.combat.aimbot", prefix = "april_silent_" },
    { id = "april_aimbot", path = "features.combat.camera_aimbot", prefix = "april_aim_" },
}

local function load_mod(entry)
    local ok, mod = pcall(function()
        return April.require(entry.path)
    end)
    if ok then return mod end
    return nil
end

function M.source_index(source_id)
    source_id = source_id or M.SOURCE_CROSSHAIR
    return math.floor(settings.num(source_id, 0) or 0)
end

function M.resolve_source_index(source_id)
    local idx = M.source_index(source_id)
    if idx >= 1 and idx <= #MODULES then
        if settings.enabled(MODULES[idx].id) then
            return idx
        end
        return nil
    end

    for i = 1, #MODULES do
        if settings.enabled(MODULES[i].id) then
            return i
        end
    end
    return nil
end

function M.get_entry(source_idx, source_id)
    source_idx = source_idx or M.resolve_source_index(source_id)
    if not source_idx then return nil end
    return MODULES[source_idx]
end

function M.get_target(source_idx, source_id)
    local entry = M.get_entry(source_idx, source_id)
    if not entry then return nil, nil end

    local mod = load_mod(entry)
    if not mod then return nil, entry.prefix end

    if mod.get_target then
        local t = mod.get_target()
        if t then return t, entry.prefix end
    end
    if mod.get_scoped_target then
        local t = mod.get_scoped_target()
        if t then return t, entry.prefix end
    end
    return nil, entry.prefix
end

function M.get_aim_world(source_idx, cx, cy, source_id)
    local target, prefix = M.get_target(source_idx, source_id)
    if not target or not prefix then return nil, target, prefix end

    local sw, sh = targeting.screen_center()
    cx = cx or sw * 0.5
    cy = cy or sh * 0.5
    local origin = combat_origin.get_camera_origin() or combat_origin.get_fire_origin()
    local aim = targeting.get_aim_point(target, prefix, nil, origin, cx, cy, false)
    return aim, target, prefix
end

function M.get_aim_screen(source_idx, cx, cy, source_id)
    local aim, target, prefix = M.get_aim_world(source_idx, cx, cy, source_id)
    if not aim then return nil, target, prefix end

    local sx, sy, vis = esp_util.w2s(aim.x, aim.y, aim.z)
    if not vis then return nil, target, prefix end
    return { x = sx, y = sy }, target, prefix
end

return M
