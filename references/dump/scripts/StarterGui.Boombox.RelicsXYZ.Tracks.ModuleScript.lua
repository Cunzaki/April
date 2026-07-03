-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local MarketplaceService = game:GetService("MarketplaceService");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ContentProvider = game:GetService("ContentProvider");
local Sound = ReplicatedStorage:WaitForChild("Sound");
local GetTracksFunction = ReplicatedStorage:WaitForChild("GetTracksFunction");
local u1 = require(script.Parent.Constants).GetTracks();
local v2 = {};
(function() -- Line: 16, Name: RegisterTracks
    -- upvalues: GetTracksFunction (copy), ContentProvider (copy)
    local v3 = GetTracksFunction:InvokeServer();

    if v3 then
        for _, v in pairs(v3) do
            local _, _ = pcall(function() -- Line: 21
                -- upvalues: ContentProvider (ref), v (copy)
                ContentProvider:RegisterSessionEncryptedAsset(v.id, v.encryptedSecret);
            end);
        end;

        return;
    end;

    warn("No response");
end)();

local function getSoundInfo(u4) -- Line: 30
    -- upvalues: MarketplaceService (copy)
    local success, result = pcall(function() -- Line: 31
        -- upvalues: MarketplaceService (ref), u4 (copy)
        return MarketplaceService:GetProductInfo(u4);
    end);

    if success and (result.AssetTypeId == Enum.AssetType.Audio.Value and result.Name ~= "(Removed for copyright)") then
        return result;
    end;

    return nil;
end;

function v2.GetTracks() -- Line: 40
    -- upvalues: u1 (copy)
    return u1;
end;

function v2.GetTrack(p5) -- Line: 44
    -- upvalues: u1 (copy)
    return u1[p5];
end;

function v2.GetTrackById(u6) -- Line: 48
    -- upvalues: u1 (copy), MarketplaceService (copy)
    for _, v in ipairs(u1) do
        if tostring(v.id) == tostring(u6) then
            return v;
        end;
    end;

    local success, result = pcall(function() -- Line: 31
        -- upvalues: MarketplaceService (ref), u6 (copy)
        return MarketplaceService:GetProductInfo(u6);
    end);

    if not success or (result.AssetTypeId ~= Enum.AssetType.Audio.Value or result.Name == "(Removed for copyright)") then
        result = nil;
    end;

    return result.AssetId and {
        id = result.AssetId,
        title = result.Name,
        artist = result.Creator.Name
    } or nil;
end;

function v2.GetNextTrack(p7) -- Line: 65
    -- upvalues: u1 (copy)
    for i, v in ipairs(u1) do
        if v.id == p7 then
            local v8 = i + 1;

            return u1[#u1 < v8 and 1 or v8];
        end;
    end;

    return nil;
end;

function v2.search(p9, p10) -- Line: 78
    -- upvalues: Sound (copy), u1 (copy)
    if not Sound:InvokeServer("IsOwner") then
        return {};
    end;

    local v11 = {};
    local v12 = {};

    if p9 and p9 ~= "" then
        v12.title = p9;
    end;

    if p10 and p10 ~= "" then
        v12.artist = p10;
    end;

    for _, v in fuzzySearch(u1, v12, 2) do
        table.insert(v11, v);
    end;

    return v11;
end;

local function levenshteinDistance(p13, p14) -- Line: 103
    local v15 = #p13;
    local v16 = #p14;
    local v17 = {};

    for i = 0, v15 do
        v17[i] = { i };
    end;

    for i = 0, v16 do
        v17[0][i] = i;
    end;

    for i = 1, v15 do
        for i2 = 1, v16 do
            local v18 = p13:sub(i, i):lower() == p14:sub(i2, i2):lower() and 0 or 1;
            v17[i][i2] = math.min(v17[i - 1][i2] + 1, v17[i][i2 - 1] + 1, v17[i - 1][i2 - 1] + v18);
        end;
    end;

    return v17[v15][v16];
end;

function advancedSearch(p19, u20)
    return function(p21, p22) -- Line: 131
        -- upvalues: u20 (copy)
        while true do
            local v23;
            p22, v23 = next(p21, p22);

            if p22 == nil then
                return;
            end;

            local v24 = true;

            for i, v in pairs(u20) do
                local v25 = v23[i];

                if type(v25) == "string" and type(v) == "string" then
                    if string.lower(v25) ~= string.lower(v) then
                        v24 = false;
                        break;
                    end;
                elseif v25 ~= v then
                    v24 = false;
                    break;
                end;
            end;

            if v24 then
                return p22, v23;
            end;
        end;
    end, p19, nil;
end;

function fuzzySearch(p26, u27, u28)
    -- upvalues: levenshteinDistance (copy)
    return function(p29, p30) -- Line: 161
        -- upvalues: u27 (copy), levenshteinDistance (ref), u28 (copy)
        while true do
            local v31;
            p30, v31 = next(p29, p30);

            if p30 == nil then
                return;
            end;

            local v32 = true;

            for i, v in pairs(u27) do
                local v33 = v31[i];

                if type(v33) == "string" and type(v) == "string" then
                    if u28 < levenshteinDistance(v33:lower(), v:lower()) then
                        v32 = false;
                        break;
                    end;
                elseif v33 ~= v then
                    v32 = false;
                    break;
                end;
            end;

            if v32 then
                return p30, v31;
            end;
        end;
    end, p26, nil;
end;

return v2;