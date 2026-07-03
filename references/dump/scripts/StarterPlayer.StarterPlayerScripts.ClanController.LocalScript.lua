-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService("Players");
local LocalPlayer = Players.LocalPlayer;
local PlayerScripts = LocalPlayer.PlayerScripts;
ReplicatedStorage:WaitForChild("ClientSignals");
local ClanRemoteFunction = ReplicatedStorage:WaitForChild("ClanRemoteFunction");
local Values = ReplicatedStorage:WaitForChild("Values");
local UpdateChannel = PlayerScripts:WaitForChild("ChatController"):WaitForChild("UpdateChannel");
shared.ClanInfo = nil;

local function v2(p1) -- Line: 28
    if p1 then
        if not shared.ClanInfo then
            return false;
        end;

        if shared.ClanInfo.ClanData.Owner[1] == p1.UserId then
            return true;
        end;

        for _, v in pairs(shared.ClanInfo.ClanData.Admins) do
            if v[1] == p1.UserId then
                return true;
            end;
        end;

        for _, v in pairs(shared.ClanInfo.ClanData.Members) do
            if v[1] == p1.UserId then
                return true;
            end;
        end;

        return false;
    end;
end;

while true do
    repeat
        task.wait(10);
        shared.ClanInfo = ClanRemoteFunction:InvokeServer("GetClanInfo");
        UpdateChannel:Fire("Clan");
    until Values.ServerType.Value ~= "Combat" and Values.ServerType.Value ~= "GunGame";

    for _, child in pairs(Players:GetChildren()) do
        if child ~= LocalPlayer and child.Character then
            local NameTag = child.Character:FindFirstChild("NameTag");

            if NameTag and (shared.cachedTeamModels ~= nil and shared.cachedTeamModels[child.Character] == nil) then
                local v3 = v2(child);
                local v4 = v3 and Color3.fromRGB(shared.ClanInfo.ClanData.ClanColor.R, shared.ClanInfo.ClanData.ClanColor.G, shared.ClanInfo.ClanData.ClanColor.B) or Color3.fromRGB(255, 255, 255);
                NameTag.MaxDistance = v3 and 600 or 20;
                NameTag.Label.TextColor3 = v4;
            end;
        end;
    end;
end;