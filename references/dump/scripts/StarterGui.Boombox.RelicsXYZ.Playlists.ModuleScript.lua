-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local Parent = script.Parent;
local Tracks = require(Parent.Tracks);
local Sound = require(Parent.Sound);
local v1 = require(Parent.Constants).GetOptions();
local Sound2 = game:GetService("ReplicatedStorage"):WaitForChild("Sound");
local u2 = {};
local u3 = "";
local freemiumMode = v1.freemiumMode;
local BindableEvent = Instance.new("BindableEvent");
local BindableEvent2 = Instance.new("BindableEvent");
local u4 = require(script.Parent.Constants).GetPlaylists();

function u2.UnlockPlaylists() -- Line: 24
    -- upvalues: Sound2 (copy), BindableEvent2 (copy)
    if Sound2:InvokeServer("IsOwner") then
        BindableEvent2:Fire();
    end;
end;

function u2.ClearActivePlaylist() -- Line: 32
    -- upvalues: u3 (ref), BindableEvent (copy)
    u3 = "";
    BindableEvent:Fire("");
end;

function u2.GetPlaylists() -- Line: 37
    -- upvalues: Sound2 (copy), u4 (copy), freemiumMode (copy)
    local v5 = Sound2:InvokeServer("IsOwner");
    local v6 = {};

    for _, v in ipairs(u4) do
        local v7;

        if v.isFree then
            v7 = freemiumMode or v5;
        else
            v7 = v5;
        end;

        table.insert(v6, {
            id = v.id,
            isFree = v.isFree,
            name = v.name,
            image = v.image,
            tracks = v.tracks,
            unlocked = v7
        });
    end;

    return v6;
end;

function u2.GetPlaylist(p8) -- Line: 58
    -- upvalues: u4 (copy)
    return u4[p8];
end;

function u2.Play(p9) -- Line: 62
    -- upvalues: u3 (ref), Sound (copy), u2 (copy), BindableEvent (copy)
    u3 = p9;
    Sound.PlayBySoundId(u2.GetFirstTrack());
    BindableEvent:Fire(p9);
end;

function u2.GetActive() -- Line: 68
    -- upvalues: u4 (copy), u3 (ref), Sound2 (copy), freemiumMode (copy)
    for _, v in ipairs(u4) do
        if v.id == u3 then
            local v10 = Sound2:InvokeServer("IsOwner");

            if v.isFree then
                v10 = freemiumMode or v10;
            end;

            return {
                id = v.id,
                isFree = v.isFree,
                name = v.name,
                image = v.image,
                tracks = v.tracks,
                unlocked = v10
            };
        end;
    end;

    return nil;
end;

function u2.GetFirstTrack() -- Line: 91
    -- upvalues: u2 (copy)
    local v11 = u2.GetActive();

    if v11 then
        return v11.tracks[1];
    end;

    return nil;
end;

function u2.GetNextTrack(p12) -- Line: 99
    -- upvalues: u2 (copy)
    local tracks = u2.GetActive().tracks;

    for i, v in ipairs(tracks) do
        if tostring(v) == tostring(p12) then
            local v13 = i + 1;

            return tracks[#tracks < v13 and 1 or v13];
        end;
    end;

    return nil;
end;

function u2.GetTracks() -- Line: 116
    -- upvalues: u2 (copy), Tracks (copy)
    local v14 = u2.GetActive();
    local v15 = Tracks.GetTracks();

    if not v14 then
        return {};
    end;

    local v16 = {};

    for _, v in v14.tracks do
        for _, v2 in v15 do
            if tostring(v2.id) == tostring(v) then
                table.insert(v16, v2);
                break;
            end;
        end;
    end;

    return v16;
end;

u2.Selected = BindableEvent.Event;
u2.Unlocked = BindableEvent2.Event;

return u2;