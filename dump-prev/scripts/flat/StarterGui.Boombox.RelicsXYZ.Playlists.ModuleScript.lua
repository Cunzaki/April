-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local Parent_1 = script.Parent;
local Tracks_upv_1 = require(Parent_1.Tracks);
local Sound_upv_1 = require(Parent_1.Sound);
local v1 = require(Parent_1.Constants).GetOptions();
local Sound_upv_2 = game:GetService("ReplicatedStorage"):WaitForChild("Sound");
local tbl_upv_1 = {};
local u1 = "";
local freemiumMode_upv_1 = v1.freemiumMode;
local u2 = Instance.new("BindableEvent");
local u3 = Instance.new("BindableEvent");
local u4 = require(script.Parent.Constants).GetPlaylists();
tbl_upv_1.UnlockPlaylists = function()
    --[[
      name: UnlockPlaylists
      line: 24
      upvalues:
        Sound_upv_2 (copy, index: 1)
        u3 (copy, index: 2)
    ]]
    if (not Sound_upv_2:InvokeServer("IsOwner")) then
        return;
    end;
    u3:Fire();
end;
tbl_upv_1.ClearActivePlaylist = function()
    --[[
      name: ClearActivePlaylist
      line: 32
      upvalues:
        u1 (ref,  index: 1)
        u2 (copy, index: 2)
    ]]
    u1 = "";
    u2:Fire("");
end;
tbl_upv_1.GetPlaylists = function()
    --[[
      name: GetPlaylists
      line: 37
      upvalues:
        Sound_upv_2 (copy, index: 1)
        u4 (copy, index: 2)
        freemiumMode_upv_1 (copy, index: 3)
    ]]
    local tbl_2 = {};
    local _ = Sound_upv_2:InvokeServer("IsOwner");
    for v1, value_1 in ipairs(u4) do
        if (not (value_1.isFree) or freemiumMode_upv_1 or (value_1.isFree) and not freemiumMode_upv_1) then
            table.insert(tbl_2, {id = value_1.id, isFree = value_1.isFree, name = value_1.name, image = value_1.image, tracks = value_1.tracks, unlocked = freemiumMode_upv_1});
        end;
    end;
    return tbl_2;
end;
tbl_upv_1.GetPlaylist = function(a1)
    --[[
      name: GetPlaylist
      line: 58
      upvalues:
        u4 (copy, index: 1)
    ]]
    return u4[a1];
end;
tbl_upv_1.Play = function(a1)
    --[[
      name: Play
      line: 62
      upvalues:
        u1 (ref,  index: 1)
        Sound_upv_1 (copy, index: 2)
        tbl_upv_1 (copy, index: 3)
        u2 (copy, index: 4)
    ]]
    u1 = a1;
    Sound_upv_1.PlayBySoundId(tbl_upv_1.GetFirstTrack());
    u2:Fire(a1);
end;
tbl_upv_1.GetActive = function()
    --[[
      name: GetActive
      line: 68
      upvalues:
        u4 (copy, index: 1)
        u1 (ref,  index: 2)
        Sound_upv_2 (copy, index: 3)
        freemiumMode_upv_1 (copy, index: 4)
    ]]
    for _, value_2 in ipairs(u4) do
        local v2 = nil;
        if (value_2.id == u1) then
            v2 = Sound_upv_2:InvokeServer("IsOwner");
            local v3, v3;
            v3 = value_2.isFree and freemiumMode_upv_1 or v2;
            local tbl_3 = {};
            tbl_3.id = value_2.id;
            tbl_3.isFree = value_2.isFree;
            tbl_3.name = value_2.name;
            tbl_3.image = value_2.image;
            tbl_3.tracks = value_2.tracks;
            tbl_3.unlocked = v3;
            return tbl_3;
        end;
    end;
end;
tbl_upv_1.GetFirstTrack = function()
    --[[
      name: GetFirstTrack
      line: 91
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    local v4 = tbl_upv_1.GetActive();
    if (v4) then
        return v4.tracks[1];
    end;
    return nil;
end;
tbl_upv_1.GetNextTrack = function(a1)
    --[[
      name: GetNextTrack
      line: 99
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    local tracks_1 = tbl_upv_1.GetActive().tracks;
    for key_1, value_3 in ipairs(tracks_1) do
        local v5 = nil;
        if (tostring(value_3) == tostring(a1)) then
            v5 = key_1 + 1;
            if (#tracks_1 < v5) then
                v5 = 1;
            end;
            return tracks_1[v5];
        end;
    end;
end;
tbl_upv_1.GetTracks = function()
    --[[
      name: GetTracks
      line: 116
      upvalues:
        tbl_upv_1 (copy, index: 1)
        Tracks_upv_1 (copy, index: 2)
    ]]
    local v6 = tbl_upv_1.GetActive();
    local v7 = Tracks_upv_1.GetTracks();
    if (v6) then
        local tbl_4 = {};
        for _, value_4 in v6.tracks do
            for v8, value_5 in v7 do
                if (tostring(value_5.id) == tostring(value_4)) then
                    table.insert(tbl_4, value_5);
                    break;
                end;
            end;
        end;
        return tbl_4;
    end;
    return {};
end;
tbl_upv_1.Selected = u2.Event;
tbl_upv_1.Unlocked = u3.Event;
return tbl_upv_1;