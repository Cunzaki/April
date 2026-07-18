local env = April.require("core.env")
local team_state = April.require("game.team_state")

local M = {}

local function read_attribute(inst, key)
    if not inst or not key then return nil end
    local v = env.safe_call(function()
        if inst.GetAttribute then return inst:GetAttribute(key) end
        return nil
    end)
    if v ~= nil then return v end
    return env.safe_call(function()
        if inst.get_attribute then return inst:get_attribute(key) end
        return nil
    end)
end

local function inst_attr(inst, key)
    return read_attribute(inst, key)
end

local function players_children()
    if not game or not game.players then return {} end
    return env.safe_call(function()
        if game.players.get_children then return game.players:get_children() end
        return game.players:GetChildren()
    end) or {}
end

function M.resolve_player_inst(player)
    if not player then return nil end
    if player.player and env.is_valid(player.player) then
        return player.player
    end

    local uid = tonumber(player.user_id)
    if uid and uid ~= 0 and game and game.players then
        local pl = env.safe_call(function()
            if game.players.GetPlayerByUserId then
                return game.players:GetPlayerByUserId(uid)
            end
            if game.players.get_player_by_user_id then
                return game.players:get_player_by_user_id(uid)
            end
            return nil
        end)
        if pl and env.is_valid(pl) then return pl end
    end

    local want_name = player.name
    local kids = players_children()
    for i = 1, #kids do
        local pl = kids[i]
        if env.is_valid(pl) then
            local id = tonumber(pl.UserId or pl.user_id)
            if uid and id and id == uid then
                return pl
            end
        end
    end
    if want_name then
        for i = 1, #kids do
            local pl = kids[i]
            if env.is_valid(pl) then
                local n = pl.Name or pl.name
                local dn = pl.DisplayName or pl.display_name
                if n == want_name or dn == want_name then
                    return pl
                end
            end
        end
        local by_name = env.safe_call(function()
            if game.players.find_first_child then
                return game.players:find_first_child(want_name)
            end
            if game.players.FindFirstChild then
                return game.players:FindFirstChild(want_name)
            end
            return nil
        end)
        if by_name and env.is_valid(by_name) then return by_name end
    end
    return nil
end

function M.player_attr(player, key)
    local inst = M.resolve_player_inst(player)
    if inst then
        local v = read_attribute(inst, key)
        if v ~= nil then return v end
    end
    if player and type(player) == "table" then
        return read_attribute(player, key)
    end
    return nil
end

function M.char_attr(player, key)
    if not player or not player.character or not env.is_valid(player.character) then
        return nil
    end
    return inst_attr(player.character, key)
end

function M.humanoid_attr(player, key)
    if not player then return nil end
    local hum = player.humanoid
    if not hum and player.character and env.is_valid(player.character) then
        local char = player.character
        hum = env.safe_call(function()
            if char.find_first_child_of_class then
                return char:find_first_child_of_class("Humanoid")
            end
            if char.FindFirstChildOfClass then
                return char:FindFirstChildOfClass("Humanoid")
            end
            return char:FindFirstChild("Humanoid") or char:find_first_child("Humanoid")
        end)
    end
    if not hum or not env.is_valid(hum) then return nil end
    return inst_attr(hum, key)
end

local function truthy(v)
    if v == true or v == 1 then return true end
    if type(v) == "string" then
        local s = v:lower()
        return s == "true" or s == "1" or s == "yes"
    end
    return false
end

function M.is_safezone(player)
    return truthy(M.player_attr(player, "SafeZone"))
end

function M.is_vip(player)
    return truthy(M.player_attr(player, "VIP"))
end

-- ChatController staff tags (Owner / Admin / Mod).
function M.staff_tag(player)
    if truthy(M.player_attr(player, "HideTag")) then return nil end
    if truthy(M.player_attr(player, "Owner")) then return "OWNER" end
    if truthy(M.player_attr(player, "Admin")) then return "ADMIN" end
    if truthy(M.player_attr(player, "Mod")) then return "MOD" end
    return nil
end

local function find_char_child(char, name)
    if not char or not env.is_valid(char) then return nil end
    return env.safe_call(function()
        if char.find_first_child then return char:find_first_child(name) end
        return char:FindFirstChild(name)
    end)
end

function M.is_reviving(player)
    if player and player.character and env.is_valid(player.character) then
        local ic = find_char_child(player.character, "InteractController")
        if ic and truthy(inst_attr(ic, "Reviving")) then
            return true
        end
    end
    if truthy(M.humanoid_attr(player, "Reviving")) then return true end
    if truthy(M.char_attr(player, "Reviving")) then return true end
    return false
end

local function normalize_clan_tag(tag)
    if tag == nil or tag == false then return nil end
    if type(tag) == "string" then
        tag = tag:match("^%[(.-)%]$") or tag
        tag = tag:match("^%s*(.-)%s*$") or tag
        if tag == "" then return nil end
        return tag
    end
    if type(tag) == "number" then
        return tostring(tag)
    end
    local s = tostring(tag)
    if s == "" or s == "nil" or s == "false" or s == "true" then return nil end
    return s
end

function M.clan_tag(player)
    local tag = normalize_clan_tag(M.player_attr(player, "ClanTag"))
    if tag then return tag end
    tag = normalize_clan_tag(M.char_attr(player, "ClanTag"))
    if tag then return tag end
    return nil
end

local function parse_color3(c)
    if not c then return nil end
    if type(c) == "table" and c[1] and c[2] and c[3] and not (c.R or c.r) then
        local r, g, b = c[1], c[2], c[3]
        if r > 1 or g > 1 or b > 1 then r, g, b = r / 255, g / 255, b / 255 end
        return { r, g, b, c[4] or 1 }
    end

    local r = c.R or c.r
    local g = c.G or c.g
    local b = c.B or c.b
    if r == nil or g == nil or b == nil then
        r = env.safe_call(function() return c.R end) or env.safe_call(function() return c.r end)
        g = env.safe_call(function() return c.G end) or env.safe_call(function() return c.g end)
        b = env.safe_call(function() return c.B end) or env.safe_call(function() return c.b end)
    end
    if r == nil or g == nil or b == nil then return nil end
    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    if not r or not g or not b then return nil end
    if r > 1 or g > 1 or b > 1 then
        r, g, b = r / 255, g / 255, b / 255
    end
    return { r, g, b, 1 }
end

function M.clan_color(player)
    local c = M.player_attr(player, "ClanColor")
    if not c then c = M.char_attr(player, "ClanColor") end
    return parse_color3(c)
end

function M.is_downed(player)
    if not player then return false end
    return truthy(M.humanoid_attr(player, "Downed"))
end

function M.is_combat_target(player)
    if not player or player.is_local then return false end
    if not player.is_alive then return false end
    return true
end

function M.passes_health_check(player)
    if not player then return false end
    if not player.is_alive then return false end
    if player.health and player.health <= 0 then return false end
    return true
end

function M.passes_team_check(player)
    if not player then return false end
    return not team_state.is_teammate(player)
end

-- mode: 0 = skip downed, 1 = allow, 2 = only downed
function M.passes_downed_check(player, mode)
    if not player then return false end
    mode = tonumber(mode) or 0
    local downed = M.is_downed(player)
    if mode == 1 then return true end
    if mode == 2 then return downed end
    return not downed
end

function M.passes_safezone_check(player, skip_safezone)
    if not player then return false end
    if not skip_safezone then return true end
    return not M.is_safezone(player)
end

return M
