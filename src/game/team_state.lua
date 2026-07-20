-- Official Fallen party teams (TeamNavigationController) + Roblox Team fallback.
-- Dump: CharacterScripts.TeamNavigationController - InTeam / CanInvite attrs,
-- FetchTeam returns userId list, teammates get TeamHighlight on character.

local env = April.require("core.env")

local M = {}

local CACHE_MS = 250
local cache = {
    t = -1,
    in_team = false,
    members = {}, -- [userId] = true
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

    -- Resolve Member* TextLabels -> userIds via entity name match.
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
    if not entity or not entity.get_players then return set, list end
    for _, p in ipairs(entity.get_players()) do
        local name = p.name
        local disp = p.display_name
        for i = 1, #labels do
            local lab = labels[i]
            if name == lab or disp == lab then
                add_member(set, list, p.user_id)
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
    if not player or not player.character then return false end
    local char = player.character
    if not env.is_valid(char) then return false end
    local hl = find_child(char, "TeamHighlight")
    return hl ~= nil and env.is_valid(hl)
end

function M.is_party_teammate(player)
    if not player or player.is_local then return false end
    refresh()

    local uid = tonumber(player.user_id)
    if uid and cache.members[uid] then
        return true
    end

    -- Highlight is only cloned onto party mates by TeamNavigationController.
    if cache.in_team and M.has_team_highlight(player) then
        return true
    end

    return false
end

function M.same_roblox_team(player)
    if not player then return false end
    local lp = entity and entity.get_local_player and entity.get_local_player()
    if not lp then return false end
    if not lp.has_team or not player.has_team then return false end
    if not lp.team or not player.team or lp.team == "" or player.team == "" then
        return false
    end
    return lp.team == player.team
end

-- True if target should be skipped by team check (is ally).
function M.is_teammate(player)
    if not player or player.is_local then return true end
    if M.is_party_teammate(player) then return true end
    if M.same_roblox_team(player) then return true end
    return false
end

return M
