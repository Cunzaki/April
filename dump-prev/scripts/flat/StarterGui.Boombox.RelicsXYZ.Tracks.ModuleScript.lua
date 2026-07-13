-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local MarketplaceService_upv_1 = game:GetService("MarketplaceService");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local ContentProvider_upv_1 = game:GetService("ContentProvider");
local Sound_upv_1 = ReplicatedStorage_1:WaitForChild("Sound");
local GetTracksFunction_upv_1 = ReplicatedStorage_1:WaitForChild("GetTracksFunction");
local u1 = require(script.Parent.Constants).GetTracks();
local tbl_1 = {};
local function RegisterTracks_1()
    --[[
      name: RegisterTracks
      line: 16
      upvalues:
        GetTracksFunction_upv_1 (copy, index: 1)
        ContentProvider_upv_1 (copy, index: 2)
    ]]
    local v1 = GetTracksFunction_upv_1:InvokeServer();
    if (v1) then
        for _, value_upv_1 in pairs(v1) do
            local v2, v3 = pcall(
                function()
                    --[[
                      line: 21
                      upvalues:
                        ContentProvider_upv_1 (copy, index: 1)
                        value_upv_1 (copy, index: 2)
                    ]]
                    ContentProvider_upv_1:RegisterSessionEncryptedAsset(value_upv_1.id, value_upv_1.encryptedSecret);
                end
            );
        end;
    else
        warn("No response");
    end;
end;
RegisterTracks_1();
local function getSoundInfo_1(a1)
    --[[
      name: getSoundInfo
      line: 30
      upvalues:
        MarketplaceService_upv_1 (copy, index: 1)
    ]]
    local success_1, v2 = pcall(
        function()
            --[[
              line: 31
              upvalues:
                MarketplaceService_upv_1 (copy, index: 1)
                a1 (copy, index: 2)
            ]]
            return MarketplaceService_upv_1:GetProductInfo(a1);
        end
    );
    if (success_1 and v2.AssetTypeId == Enum.AssetType.Audio.Value and v2.Name ~= "(Removed for copyright)") then
        return v2;
    end;
    return nil;
end;
tbl_1.GetTracks = function()
    --[[
      name: GetTracks
      line: 40
      upvalues:
        u1 (copy, index: 1)
    ]]
    return u1;
end;
tbl_1.GetTrack = function(a1)
    --[[
      name: GetTrack
      line: 44
      upvalues:
        u1 (copy, index: 1)
    ]]
    return u1[a1];
end;
tbl_1.GetTrackById = function(a1)
    --[[
      name: GetTrackById
      line: 48
      upvalues:
        u1 (copy, index: 1)
        MarketplaceService_upv_1 (copy, index: 2)
    ]]
    for _, value_2 in ipairs(u1) do
        if (tostring(value_2.id) ~= tostring(a1)) then
            continue;
        end;
        return value_2;
    end;
    local v3, v4 = pcall(
        function()
            --[[
              line: 31
              upvalues:
                MarketplaceService_upv_1 (copy, index: 1)
                a1 (copy, index: 2)
            ]]
            return MarketplaceService_upv_1:GetProductInfo(a1);
        end
    );
    local v5;
    if (v3) then
        if (v4.AssetTypeId ~= Enum.AssetType.Audio.Value or v4.Name == "(Removed for copyright)") then
            v5 = nil;
        else
            v5 = v4;
        end;
    else
        v5 = nil;
    end;
    if (v5.AssetId) then
        v3 = {};
        v3.id = v5.AssetId;
        v3.title = v5.Name;
        v3.artist = v5.Creator.Name;
        return v3;
    end;
    return nil;
end;
tbl_1.GetNextTrack = function(a1)
    --[[
      name: GetNextTrack
      line: 65
      upvalues:
        u1 (copy, index: 1)
    ]]
    for key_1, value_3 in ipairs(u1) do
        local v6 = nil;
        if (value_3.id == a1) then
            v6 = key_1 + 1;
            if (#u1 < v6) then
                v6 = 1;
            end;
            return u1[v6];
        end;
    end;
end;
tbl_1.search = function(a1, a2)
    --[[
      name: search
      line: 78
      upvalues:
        Sound_upv_1 (copy, index: 1)
        u1 (copy, index: 2)
    ]]
    if (Sound_upv_1:InvokeServer("IsOwner")) then
        local tbl_2 = {};
        local tbl_3 = {};
        if (a1 and a1 ~= "") then
            tbl_3.title = a1;
        end;
        if (a2 and a2 ~= "") then
            tbl_3.artist = a2;
        end;
        for _, value_4 in fuzzySearch(u1, tbl_3, 2) do
            table.insert(tbl_2, value_4);
        end;
        return tbl_2;
    end;
    return {};
end;
function advancedSearch(a1, a2)
    --[[
      name: advancedSearch
      line: 130
    ]]
    return function(a3, a4)
        --[[
          line: 131
          upvalues:
            a2 (copy, index: 1)
        ]]
        local v7 = nil;
        while (true) do
            local v8;
            v7, v8 = next(a3, a4);
            local v9 = nil;
            if (v7 == nil) then
                break;
            end;
            v7 = true;
            for key_2, value_5 in pairs(a2) do
                v9 = v8[key_2];
                if (type(v9) ~= "string" or type(value_5) ~= "string") then
                    if (v9 ~= value_5) then
                        v7 = false;
                        break;
                    end;
                elseif (string.lower(v9) ~= string.lower(value_5)) then
                    v7 = false;
                    break;
                end;
                break;
            end;
            if (not (v7)) then
                continue;
            end;
            return a4, v8;
        end;
    end, a1, nil;
end;
local function levenshteinDistance_upv_1(a1, a2)
    --[[
      name: levenshteinDistance
      line: 103
    ]]
    local v10 = #a1;
    local v11 = #a2;
    local tbl_4 = {};
    for n_1 = 0, v10 do
        tbl_4[n_1] = {[0] = n_1};
    end;
    for n_2 = 0, v11 do
        tbl_4[0][n_2] = n_2;
    end;
    for n_3 = 1, v10 do
        for n_4 = 1, v11 do
            local v12;
            v12 = ((a1:sub(n_3, n_3):lower() == a2:sub(n_4, n_4):lower()) and 0) or 1;
            tbl_4[n_3][n_4] = math.min(tbl_4[n_3 - 1][n_4] + 1, tbl_4[n_3][n_4 - 1] + 1, tbl_4[n_3 - 1][n_4 - 1] + v12);
        end;
    end;
    return tbl_4[v10][v11];
end;
function fuzzySearch(a1, a2, a3)
    --[[
      name: fuzzySearch
      line: 160
      upvalues:
        levenshteinDistance_upv_1 (copy, index: 1)
    ]]
    return function(a4, a5)
        --[[
          line: 161
          upvalues:
            a2 (copy, index: 1)
            levenshteinDistance_upv_1 (copy, index: 2)
            a3 (copy, index: 3)
        ]]
        local v13 = nil;
        while (true) do
            local v14;
            v13, v14 = next(a4, a5);
            local v15 = nil;
            if (v13 == nil) then
                break;
            end;
            v13 = true;
            for key_3, value_6 in pairs(a2) do
                v15 = v14[key_3];
                if (type(v15) ~= "string" or type(value_6) ~= "string") then
                    if (v15 ~= value_6) then
                        v13 = false;
                        break;
                    end;
                elseif (a3 < levenshteinDistance_upv_1(v15:lower(), value_6:lower())) then
                    v13 = false;
                    break;
                end;
                break;
            end;
            if (not (v13)) then
                continue;
            end;
            return a5, v14;
        end;
    end, a1, nil;
end;
return tbl_1;