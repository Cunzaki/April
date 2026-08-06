April._mods["core.env"] = (function()
local M = {}
function M.has_api(name)
    return _G[name] ~= nil
end
function M.require_apis(names)
    for _, name in ipairs(names) do
        if not M.has_api(name) then
            return false, name
        end
    end
    return true
end
function M.safe_call(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end
local function has_identity(inst)
    local ok, cn = pcall(function()
        return inst.ClassName or inst.class_name
    end)
    if ok and cn ~= nil and cn ~= "" then return true end
    local ok2, name = pcall(function()
        return inst.Name or inst.name
    end)
    return ok2 and name ~= nil and name ~= ""
end
function M.is_valid(inst)
    if not inst then return false end
    if utility and utility.is_valid then
        local ok, valid = pcall(utility.is_valid, inst)
        if ok and valid == true then
            return true
        end
        if ok and valid == false then
            return has_identity(inst)
        end
    end
    return has_identity(inst)
end
function M.get_workspace()
    if game and game.workspace then return game.workspace end
    local via_service = M.safe_call(function()
        if game.get_service then return game.get_service("Workspace") end
        if game.GetService then return game:GetService("Workspace") end
        return nil
    end)
    if via_service then return via_service end
    return M.safe_call(function() return workspace end)
end
function M.get_local_player()
    local ep = April and April.require and April.require("core.entity_props")
    if ep and ep.get_local_player then
        local lp = ep.get_local_player()
        if lp then return lp end
    end
    if entity then
        local fn = entity.get_local_player or entity.GetLocalPlayer
        if fn then
            local ok, lp = pcall(fn)
            if ok and lp then return lp end
        end
    end
    if game then
        local lp = game.local_player or game.LocalPlayer
        if lp then return lp end
    end
    return nil
end
function M.get_replicated_storage()
    return M.safe_call(function() return game.get_service("ReplicatedStorage") end)
end
function M.get_attribute(inst, key)
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
return M
end)()

April._mods["core.api_aliases"] = (function()
local M = {}
local function alias(tbl, snake, pascal)
    if not tbl then return end
    if tbl[snake] == nil and tbl[pascal] ~= nil then
        tbl[snake] = tbl[pascal]
    end
    if tbl[pascal] == nil and tbl[snake] ~= nil then
        tbl[pascal] = tbl[snake]
    end
end
function M.apply()
    if entity then
        alias(entity, "get_players", "GetPlayers")
        alias(entity, "get_local_player", "GetLocalPlayer")
        alias(entity, "get_player_count", "GetPlayerCount")
    end
    if draw then
        alias(draw, "line", "Line")
        alias(draw, "rect", "Rect")
        alias(draw, "rect_filled", "RectFilled")
        alias(draw, "circle", "Circle")
        alias(draw, "circle_filled", "CircleFilled")
        alias(draw, "text", "Text")
        alias(draw, "get_text_size", "GetTextSize")
        alias(draw, "box", "Box")
        alias(draw, "corner_box", "CornerBox")
        alias(draw, "health_bar", "HealthBar")
        alias(draw, "world_to_screen", "WorldToScreen")
        alias(draw, "get_screen_size", "GetScreenSize")
        alias(draw, "poly", "Poly")
        alias(draw, "poly_closed", "PolyClosed")
        alias(draw, "poly_filled", "PolyFilled")
        alias(draw, "compute_hull", "ComputeHull")
        alias(draw, "chams_player", "ChamsPlayer")
        alias(draw, "chams", "Chams")
        alias(draw, "get_player_hulls", "GetPlayerHulls")
        alias(draw, "load_image", "LoadImage")
        alias(draw, "image", "Image")
        alias(draw, "image_loaded", "ImageLoaded")
        alias(draw, "image_failed", "ImageFailed")
        alias(draw, "image_size", "ImageSize")
        alias(draw, "free_image", "FreeImage")
        alias(draw, "window", "Window")
        if draw.filled_rect == nil then
            draw.filled_rect = draw.rect_filled or draw.RectFilled
        end
        if draw.filled_circle == nil then
            draw.filled_circle = draw.circle_filled or draw.CircleFilled
        end
    end
    if utility then
        alias(utility, "world_to_screen", "WorldToScreen")
        alias(utility, "get_screen_size", "GetScreenSize")
        alias(utility, "get_mouse_pos", "GetMousePos")
        alias(utility, "get_tick_count", "GetTickCount")
        alias(utility, "get_delta_time", "GetDeltaTime")
        alias(utility, "get_time", "GetTime")
        alias(utility, "get_fps", "GetFPS")
        alias(utility, "on_key", "OnKey")
        alias(utility, "remove_key", "RemoveKey")
        alias(utility, "clear_keys", "ClearKeys")
        alias(utility, "is_key_toggled", "IsKeyToggled")
        alias(utility, "is_valid", "IsValid")
        alias(utility, "load_url", "LoadUrl")
        alias(utility, "http_get", "HttpGet")
        alias(utility, "key_down", "KeyDown")
        alias(utility, "key_up", "KeyUp")
        alias(utility, "key_press", "KeyPress")
        alias(utility, "mouse_click", "MouseClick")
    end
    if input then
        alias(input, "is_key_down", "IsKeyDown")
        alias(input, "is_mouse_down", "IsMouseDown")
        alias(input, "get_mouse_position", "GetMousePosition")
        alias(input, "get_mouse_pos", "GetMousePosition")
    end
    if thread then
        alias(thread, "create", "Create")
        alias(thread, "stop", "Stop")
        alias(thread, "stop_all", "StopAll")
        alias(thread, "is_running", "IsRunning")
        alias(thread, "set_interval", "SetInterval")
    end
    if game then
        alias(game, "local_player", "LocalPlayer")
        alias(game, "players", "Players")
        alias(game, "workspace", "Workspace")
        alias(game, "get_service", "GetService")
    end
    if camera then
        alias(camera, "get_position", "GetPosition")
        alias(camera, "get_look_vector", "GetLookVector")
        alias(camera, "look_at", "LookAt")
        alias(camera, "get_fov", "GetFov")
        alias(camera, "set_fov", "SetFov")
        alias(camera, "track_target", "TrackTarget")
        alias(camera, "stop_tracking", "StopTracking")
    end
    if raycast then
        alias(raycast, "is_ready", "IsReady")
        alias(raycast, "is_player_visible", "IsPlayerVisible")
        alias(raycast, "is_visible", "IsVisible")
        alias(raycast, "cast", "Cast")
        alias(raycast, "enable_silent_hook", "EnableSilentHook")
        alias(raycast, "disable_silent_hook", "DisableSilentHook")
        alias(raycast, "is_silent_hook_active", "IsSilentHookActive")
        alias(raycast, "set_silent_target", "SetSilentTarget")
        alias(raycast, "clear_silent_target", "ClearSilentTarget")
        alias(raycast, "track_silent_target", "TrackSilentTarget")
        alias(raycast, "stop_silent_tracking", "StopSilentTracking")
    end
end
return M
end)()

April._mods["core.entity_props"] = (function()
local M = {}
function M.ensure_api_aliases()
    local ok, aliases = pcall(function()
        return April.require("core.api_aliases")
    end)
    if ok and aliases and aliases.apply then
        aliases.apply()
    end
end
function M.get_local_player()
    M.ensure_api_aliases()
    if not entity then return nil end
    local fn = entity.get_local_player or entity.GetLocalPlayer
    if not fn then return nil end
    local ok, lp = pcall(fn)
    if ok then return lp end
    return nil
end
local function raw_get(obj, key)
    if obj == nil or key == nil then return nil end
    local ok, v = pcall(function()
        return obj[key]
    end)
    if ok and v ~= nil then return v end
    return nil
end
function M.get(obj, ...)
    local n = select("#", ...)
    for i = 1, n do
        local v = raw_get(obj, select(i, ...))
        if v ~= nil then return v end
    end
    return nil
end
function M.call(obj, ...)
    if not obj then return nil end
    local n = select("#", ...)
    for i = 1, n do
        local name = select(i, ...)
        local fn = raw_get(obj, name)
        if type(fn) == "function" then
            return function(...)
                return fn(obj, ...)
            end
        end
    end
    return nil
end
function M.name(p)
    return M.get(p, "Name", "name", "DisplayName", "display_name")
end
function M.display_name(p)
    return M.get(p, "DisplayName", "display_name", "Name", "name")
end
function M.user_id(p)
    local uid = tonumber(M.get(p, "UserId", "user_id"))
    if uid and uid ~= 0 then return uid end
    local pl = M.player_inst(p)
    if pl then
        local ok, v = pcall(function()
            return pl.UserId or pl.user_id
        end)
        if ok then
            uid = tonumber(v)
            if uid and uid ~= 0 then return uid end
        end
    end
    return uid
end
function M.is_local(p)
    local v = M.get(p, "IsLocal", "is_local")
    return v == true
end
function M.is_alive(p)
    local v = M.get(p, "IsAlive", "is_alive")
    if v ~= nil then return v == true end
    return nil
end
function M.is_workspace_entity(p)
    local v = M.get(p, "IsWorkspaceEntity", "is_workspace_entity")
    return v == true
end
function M.health(p)
    return tonumber(M.get(p, "Health", "health"))
end
function M.max_health(p)
    return tonumber(M.get(p, "MaxHealth", "max_health"))
end
function M.team(p)
    return M.get(p, "Team", "team")
end
function M.has_team(p)
    local v = M.get(p, "HasTeam", "has_team")
    return v == true
end
function M.character(p)
    return M.get(p, "Character", "character")
end
function M.humanoid(p)
    return M.get(p, "Humanoid", "humanoid")
end
function M.player_inst(p)
    return M.get(p, "Player", "player")
end
function M.position(p)
    return M.get(p, "Position", "position")
end
function M.head_position(p)
    return M.get(p, "HeadPosition", "head_position") or M.position(p)
end
function M.velocity(p)
    return M.get(p, "Velocity", "velocity")
end
function M.tool_name(p)
    return M.get(p, "ToolName", "tool_name")
end
function M.get_bounds(p)
    local fn = M.call(p, "GetBounds", "get_bounds", "getBounds")
    if not fn then return nil end
    local ok, b = pcall(fn)
    if ok then return b end
    return nil
end
function M.get_bones_screen(p)
    local fn = M.call(p, "GetBonesScreen", "get_bones_screen", "getBonesScreen")
    if not fn then return nil end
    local ok, bones = pcall(fn)
    if ok then return bones end
    return nil
end
function M.get_bone_screen(p, bone)
    local fn = M.call(p, "GetBoneScreen", "get_bone_screen", "getBoneScreen")
    if not fn then return 0, 0, false end
    local ok, x, y, vis = pcall(fn, bone)
    if not ok then return 0, 0, false end
    return x, y, vis
end
function M.distance_to(p, origin)
    local fn = M.call(p, "DistanceTo", "distance_to", "distanceTo")
    if not fn then return nil end
    local ok, d
    if origin ~= nil then
        ok, d = pcall(fn, origin)
    else
        ok, d = pcall(fn)
    end
    if ok then return tonumber(d) end
    return nil
end
return M
end)()

April._mods["core.math_util"] = (function()
local M = {}
function M.atan2(y, x)
    y = y or 0
    x = x or 0
    if math.atan2 then
        return math.atan2(y, x)
    end
    local ok, result = pcall(math.atan, y, x)
    if ok and type(result) == "number" then
        return result
    end
    if x > 0 then
        return math.atan(y / x)
    elseif x < 0 and y >= 0 then
        return math.atan(y / x) + math.pi
    elseif x < 0 and y < 0 then
        return math.atan(y / x) - math.pi
    elseif x == 0 and y > 0 then
        return math.pi * 0.5
    elseif x == 0 and y < 0 then
        return -math.pi * 0.5
    end
    return 0
end
function M.clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end
function M.distance3(dx, dy, dz)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end
function M.distance2(dx, dy)
    return math.sqrt(dx * dx + dy * dy)
end
function M.dot(ax, ay, az, bx, by, bz)
    return ax * bx + ay * by + az * bz
end
function M.screen_fov_dist(sx, sy, cx, cy)
    local dx, dy = sx - cx, sy - cy
    return math.sqrt(dx * dx + dy * dy)
end
function M.vec3_str(v)
    if not v or v.x == nil then return "?" end
    return string.format("%.0f, %.0f, %.0f", v.x, v.y, v.z)
end
return M
end)()

April._mods["core.text_util"] = (function()
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
end)()

April._mods["core.cache"] = (function()
local M = {}
M.all_entities = {}
M.players = {}
M.workspace_entities = {}
M.local_player = nil
M.world = {}
M.loot = {}
M.base = {}
M.npcs = {}
M.raids = {}
M.waypoints = {}
M.spatial = { world = nil, loot = nil, base = nil }
M.stats = {
    last_player_scan = 0,
    last_world_scan = 0,
    last_loot_scan = 0,
    last_base_scan = 0,
    last_npc_scan = 0,
}
M.WORKSPACE_SCAN_MS = 1000
M.DROPS_SCAN_MS = 3500
M.POS_CACHE_MS = 1000
M.PRUNE_MS = 2000
M._last_pos_cache = 0
M._last_prune = 0
M._entity_frame = 0
local function clear_array(list)
    for i = #list, 1, -1 do
        list[i] = nil
    end
end
function M.refresh_entities()
    M._entity_frame = M._entity_frame + 1
    local get_players = entity and (entity.GetPlayers or entity.get_players)
    local list = nil
    if get_players then
        local ok, result = pcall(get_players)
        if ok and type(result) == "table" then
            list = result
        end
    end
    list = list or {}
    M.all_entities = list
    clear_array(M.players)
    clear_array(M.workspace_entities)
    local local_player = nil
    for i = 1, #list do
        local player = list[i]
        if player then
            if player.IsLocal == true or player.is_local == true then
                local_player = player
            elseif player.IsWorkspaceEntity == true or player.is_workspace_entity == true then
                M.workspace_entities[#M.workspace_entities + 1] = player
            else
                M.players[#M.players + 1] = player
            end
        end
    end
    if not local_player then
        local get_local = entity and (entity.GetLocalPlayer or entity.get_local_player)
        if get_local then
            local ok, result = pcall(get_local)
            if ok then local_player = result end
        end
    end
    M.local_player = local_player
    return list
end
function M.should_refresh_positions()
    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    if now - M._last_pos_cache >= M.POS_CACHE_MS then
        M._last_pos_cache = now
        return true
    end
    return false
end
function M.should_prune()
    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    if now - M._last_prune >= M.PRUNE_MS then
        M._last_prune = now
        return true
    end
    return false
end
function M.clear_bucket(bucket)
    for k in pairs(bucket) do bucket[k] = nil end
end
function M.prune_invalid(list)
    if not list or #list == 0 then return 0 end
    local env = April.require("core.env")
    local write = 1
    for read = 1, #list do
        local entry = list[read]
        if entry and entry.inst and env.is_valid(entry.inst) then
            if write ~= read then
                list[write] = entry
            end
            write = write + 1
        end
    end
    for i = write, #list do
        list[i] = nil
    end
    return write - 1
end
function M.prune_distance(list, origin, max_dist)
    if not list or #list == 0 then return 0 end
    if not origin or not max_dist or max_dist <= 0 then
        return M.prune_invalid(list)
    end
    local env = April.require("core.env")
    local esp_scan = April.require("game.esp_scan")
    local limit2 = max_dist * max_dist
    local ox, oy, oz = origin.x, origin.y, origin.z
    local write = 1
    for read = 1, #list do
        local entry = list[read]
        if entry and entry.inst and env.is_valid(entry.inst) then
            local lx, ly, lz = esp_scan.entry_coords(entry)
            if lx then
                local dx, dy, dz = lx - ox, ly - oy, lz - oz
                if (dx * dx + dy * dy + dz * dz) <= limit2 then
                    if write ~= read then
                        list[write] = entry
                    end
                    write = write + 1
                end
            end
        end
    end
    for i = write, #list do
        list[i] = nil
    end
    return write - 1
end
local SPATIAL_CELL = 128
local function spatial_key(cx, cz)
    return tostring(cx) .. ":" .. tostring(cz)
end
function M.build_spatial(list)
    local index = { cells = {}, all = list or {}, cell = SPATIAL_CELL }
    local esp_scan = April.require("game.esp_scan")
    for _, entry in ipairs(list or {}) do
        local x, _, z = esp_scan.entry_coords(entry)
        if x and z then
            local cx = math.floor(x / SPATIAL_CELL)
            local cz = math.floor(z / SPATIAL_CELL)
            local key = spatial_key(cx, cz)
            local bucket = index.cells[key]
            if not bucket then
                bucket = {}
                index.cells[key] = bucket
            end
            bucket[#bucket + 1] = entry
        end
    end
    return index
end
function M.query_spatial(index, x, z, radius, out)
    out = out or {}
    for i = #out, 1, -1 do out[i] = nil end
    if not index or not x or not z or not radius then return out end
    local cell = index.cell or SPATIAL_CELL
    local min_x = math.floor((x - radius) / cell)
    local max_x = math.floor((x + radius) / cell)
    local min_z = math.floor((z - radius) / cell)
    local max_z = math.floor((z + radius) / cell)
    for cx = min_x, max_x do
        for cz = min_z, max_z do
            local bucket = index.cells[spatial_key(cx, cz)]
            if bucket then
                for i = 1, #bucket do out[#out + 1] = bucket[i] end
            end
        end
    end
    return out
end
return M
end)()

April._mods["core.capabilities"] = (function()
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
        exploits_chams = _G.exploits ~= nil
            and type(exploits.ApplyChamsToInstance) == "function"
            and type(exploits.RevertChams) == "function",
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
    if c.exploits_chams then table.insert(parts, "gpu-chams") end
    if c.getgc then table.insert(parts, "getgc") end
    return #parts > 0 and table.concat(parts, ", ") or "minimal"
end
return M
end)()

April._mods["core.debug"] = (function()
local M = {}
local seen_errors = {}
local frame_count = 0
function M.log_path()
    return nil
end
function M.last_step()
    return ""
end
function M.begin_session(_reason)
    return nil
end
function M.file(_msg) end
function M.step(_name) end
function M.step_done(_name) end
function M.force_step(_name) end
function M.force_event(_message) end
function M.enabled()
    return false
end
function M.verbose()
    return false
end
function M.log(_msg) end
function M.warn(_msg) end
function M.warn_once(_key, _msg) end
function M.error_once(_key, _err)
end
function M.guard(key, fn, ...)
    return M.guard_fast(key, fn, ...)
end
function M.guard_fast(_key, fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c = pcall(fn, ...)
    if not ok then
        return nil
    end
    return a, b, c
end
function M.guard_bool(_key, fn, ...)
    if type(fn) ~= "function" then return false end
    local ok, result = pcall(fn, ...)
    if not ok then
        return false
    end
    return true, result
end
function M.register_frame_hook(fn)
    if type(fn) ~= "function" then
        return false
    end
    _G.OnFrame = fn
    _G.onFrame = fn
    _G.on_frame = fn
    if callbacks and callbacks.add then
        pcall(callbacks.add, "on_frame", fn)
        pcall(callbacks.add, "OnFrame", fn)
    end
    if draw then
        draw.callback = fn
    end
    return true
end
function M.tick_frame()
    frame_count = frame_count + 1
end
function M.frame_count()
    return frame_count
end
function M.reset_errors()
    seen_errors = {}
end
function M.stats()
    return { frames = frame_count, errors = seen_errors }
end
return M
end)()
