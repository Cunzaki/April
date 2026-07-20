-- Play Fallen animations like StateAssetController: LoadAnimation + bare :Play().
-- Stops competing loco tracks so our selection can actually stick.

local env = April.require("core.env")
local fallen_anims = April.require("game.fallen_anims")

local M = {}

local _holder = nil
local _anim_cache = {}
local _track_cache = {}
local _active = {
    hum = nil,
    id = nil,
    track = nil,
}

local function find_child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        if parent.FindFirstChild then return parent:FindFirstChild(name) end
        if parent.find_first_child then return parent:find_first_child(name) end
        return nil
    end)
end

local function find_child_of_class(parent, class_name)
    if not parent then return nil end
    return env.safe_call(function()
        if parent.FindFirstChildOfClass then return parent:FindFirstChildOfClass(class_name) end
        if parent.find_first_child_of_class then return parent:find_first_child_of_class(class_name) end
        return nil
    end)
end

local function get_children(parent)
    if not parent then return nil end
    return env.safe_call(function()
        if parent.GetChildren then return parent:GetChildren() end
        if parent.get_children then return parent:get_children() end
        return nil
    end)
end

local function get_holder()
    if _holder then return _holder end
    local rs = env.get_replicated_storage()
    if not rs then return nil end
    local existing = find_child(rs, "AprilAnimHolder")
    if existing then
        _holder = existing
        return _holder
    end
    if instance and instance.New then
        local ok, created = pcall(instance.New, "Folder", rs)
        if ok and created then
            pcall(function() created.Name = "AprilAnimHolder" end)
            _holder = created
            return _holder
        end
    end
    return nil
end

local function anim_id_matches(anim, url)
    local aid = env.safe_call(function() return anim.AnimationId or anim.animation_id end)
    if not aid then return false end
    local na = tostring(aid):match("(%d+)$")
    local nb = tostring(url):match("(%d+)$")
    return (tostring(aid) == tostring(url)) or (na and nb and na == nb)
end

local function find_existing_animation(asset_url)
    local lp = game and (game.LocalPlayer or game.local_player)
    if lp then
        local ps = find_child(lp, "PlayerScripts")
        local sac = ps and find_child(ps, "StateAssetController")
        local folder = sac and find_child(sac, "Animations")
        local kids = get_children(folder)
        if kids then
            for _, anim in ipairs(kids) do
                if anim_id_matches(anim, asset_url) then return anim end
            end
        end
    end

    local rs = env.get_replicated_storage()
    local vms = rs and find_child(rs, "VMs")
    local tools = get_children(vms)
    if not tools then return nil end
    for _, tool in ipairs(tools) do
        for _, folder_name in ipairs({ "GlobalAnims", "LocalAnims" }) do
            local kids = get_children(find_child(tool, folder_name))
            if kids then
                for _, anim in ipairs(kids) do
                    if anim_id_matches(anim, asset_url) then return anim end
                end
            end
        end
    end
    return nil
end

local function get_or_create_animation(id)
    if not id then return nil end
    local url = fallen_anims.asset_url(id)
    if not url then return nil end
    if _anim_cache[id] then return _anim_cache[id] end

    local existing = find_existing_animation(url)
    if existing then
        _anim_cache[id] = existing
        return existing
    end

    local holder = get_holder()
    if not holder or not instance or not instance.New then return nil end
    local ok, anim = pcall(instance.New, "Animation", holder)
    if not ok or not anim then return nil end
    pcall(function()
        anim.Name = "April_" .. tostring(id)
        anim.AnimationId = url
    end)
    _anim_cache[id] = anim
    return anim
end

local function hum_key(hum)
    return tostring(hum and (hum.Address or hum.address or hum) or "nil")
end

local function get_animator(hum)
    if not hum then return nil end
    local a = find_child_of_class(hum, "Animator")
    if a then return a end
    return env.safe_call(function()
        if hum.FindFirstChildOfClass then return hum:FindFirstChildOfClass("Animator") end
        return nil
    end)
end

local function load_track(hum, id)
    if not hum or not id then return nil end
    local key = hum_key(hum) .. "|" .. tostring(id)
    if _track_cache[key] then return _track_cache[key] end

    local anim = get_or_create_animation(id)
    if not anim then return nil end

    local track = env.safe_call(function()
        if hum.LoadAnimation then return hum:LoadAnimation(anim) end
        if hum.load_animation then return hum:load_animation(anim) end
        return nil
    end)

    if not track then
        local animator = get_animator(hum)
        if animator then
            track = env.safe_call(function()
                if animator.LoadAnimation then return animator:LoadAnimation(anim) end
                return nil
            end)
        end
    end

    if track then
        -- Match Roblox bare Play() defaults; loop so StateAsset can't leave us idle-gap.
        pcall(function() track.Looped = true end)
        pcall(function()
            if Enum and Enum.AnimationPriority and Enum.AnimationPriority.Action then
                track.Priority = Enum.AnimationPriority.Action
            end
        end)
        _track_cache[key] = track
    end
    return track
end

-- Bare Play defaults = fade 0.1, weight 1, speed 1 (same as Fallen :Play()).
local function play_default(track)
    if not track then return false end
    return env.safe_call(function()
        if track.Play then
            track:Play(0.1, 1, 1)
            return true
        end
        if track.play then
            track:play(0.1, 1, 1)
            return true
        end
        return false
    end) == true
end

local function stop_default(track)
    if not track then return end
    pcall(function()
        if track.Stop then track:Stop(0.1)
        elseif track.stop then track:stop(0.1)
        end
    end)
end

local function stop_other_tracks(hum, keep)
    local animator = get_animator(hum)
    if not animator then return end
    local tracks = env.safe_call(function()
        if animator.GetPlayingAnimationTracks then
            return animator:GetPlayingAnimationTracks()
        end
        if animator.get_playing_animation_tracks then
            return animator:get_playing_animation_tracks()
        end
        return nil
    end)
    if type(tracks) ~= "table" then return end
    for _, t in ipairs(tracks) do
        if t ~= keep then
            stop_default(t)
        end
    end
end

function M.stop()
    if _active.track then stop_default(_active.track) end
    _active.hum = nil
    _active.id = nil
    _active.track = nil
end

function M.sync(hum, id)
    if not hum or not id then
        M.stop()
        return false
    end

    if _active.hum == hum and _active.id == id and _active.track then
        stop_other_tracks(hum, _active.track)
        local playing = env.safe_call(function() return _active.track.IsPlaying end)
        if playing ~= true then
            play_default(_active.track)
        end
        return true
    end

    if _active.track then stop_default(_active.track) end

    local track = load_track(hum, id)
    if not track then return false end

    stop_other_tracks(hum, track)
    play_default(track)
    _active.hum = hum
    _active.id = id
    _active.track = track
    return true
end

return M
