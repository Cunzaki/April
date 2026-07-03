-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local ReplicatedStorage = game:GetService("ReplicatedStorage");
ReplicatedStorage:WaitForChild("FavoriteStatusFunction");
ReplicatedStorage:WaitForChild("FavoriteTrackFunction");
local FavoriteIdsFunction = ReplicatedStorage:WaitForChild("FavoriteIdsFunction");
local Parent = script.Parent;
local Tracks = require(Parent.Tracks);
require(Parent.Sound);
local u1 = {
    GetFavorites = function() -- Line: 21, Name: GetFavorites
        -- upvalues: FavoriteIdsFunction (copy)
        return FavoriteIdsFunction:InvokeServer();
    end
};

function u1.GetFirstTrack() -- Line: 26
    -- upvalues: u1 (copy)
    return u1.GetFavorites()[1];
end;

function u1.GetNextTrack(p2) -- Line: 32
    -- upvalues: u1 (copy)
    local v3 = u1.GetFavorites();

    for i, v in ipairs(v3) do
        if not p2 then
            return v3[i];
        end;

        if tostring(v) == tostring(p2) then
            return v3[i % #v3 + 1];
        end;
    end;

    return nil;
end;

function u1.GetTracks() -- Line: 49
    -- upvalues: u1 (copy), Tracks (copy)
    local v4 = u1.GetFavorites();

    if not v4 then
        return {};
    end;

    local v5 = {};

    for _, v in ipairs(v4) do
        local v6 = Tracks.GetTrackById(v);
        table.insert(v5, v6);
    end;

    return v5;
end;

return u1;