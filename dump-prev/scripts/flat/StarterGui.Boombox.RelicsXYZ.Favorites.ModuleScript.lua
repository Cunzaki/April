-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local _ = ReplicatedStorage_1:WaitForChild("FavoriteStatusFunction");
local v1 = ReplicatedStorage_1:WaitForChild("FavoriteTrackFunction");
local FavoriteIdsFunction_upv_1 = ReplicatedStorage_1:WaitForChild("FavoriteIdsFunction");
local Parent_1 = script.Parent;
local Tracks_upv_1 = require(Parent_1.Tracks);
local v2 = require(Parent_1.Sound);
local tbl_upv_1 = {};
tbl_upv_1.GetFavorites = function()
    --[[
      name: GetFavorites
      line: 21
      upvalues:
        FavoriteIdsFunction_upv_1 (copy, index: 1)
    ]]
    return FavoriteIdsFunction_upv_1:InvokeServer();
end;
tbl_upv_1.GetFirstTrack = function()
    --[[
      name: GetFirstTrack
      line: 26
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    return tbl_upv_1.GetFavorites()[1];
end;
tbl_upv_1.GetNextTrack = function(a1)
    --[[
      name: GetNextTrack
      line: 32
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    local v1 = tbl_upv_1.GetFavorites();
    for key_1, value_1 in ipairs(v1) do
        if (a1) then
            if (tostring(value_1) ~= tostring(a1)) then
                continue;
            end;
            return v1[(key_1 % #v1) + 1];
        end;
        return v1[key_1];
    end;
    return nil;
end;
tbl_upv_1.GetTracks = function()
    --[[
      name: GetTracks
      line: 49
      upvalues:
        tbl_upv_1 (copy, index: 1)
        Tracks_upv_1 (copy, index: 2)
    ]]
    local v2 = tbl_upv_1.GetFavorites();
    if (v2) then
        local tbl_2 = {};
        for _, value_2 in ipairs(v2) do
            table.insert(tbl_2, (Tracks_upv_1.GetTrackById(value_2)));
        end;
        return tbl_2;
    end;
    return {};
end;
return tbl_upv_1;