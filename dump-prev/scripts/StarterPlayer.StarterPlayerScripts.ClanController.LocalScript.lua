-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local Players_1 = game:GetService("Players");
local LocalPlayer_1 = Players_1.LocalPlayer;
local _ = ReplicatedStorage_1:WaitForChild("ClientSignals");
local ClanRemoteFunction_1 = ReplicatedStorage_1:WaitForChild("ClanRemoteFunction");
local Values_1 = ReplicatedStorage_1:WaitForChild("Values");
local UpdateChannel_1 = LocalPlayer_1.PlayerScripts:WaitForChild("ChatController"):WaitForChild("UpdateChannel");
shared.ClanInfo = nil;
repeat
    task.wait(10);
    shared.ClanInfo = ClanRemoteFunction_1:InvokeServer("GetClanInfo");
    UpdateChannel_1:Fire("Clan");
until (Values_1.ServerType.Value ~= "Combat");
local v5, v6;
local function v1(a1)
    --[[
      line: 28
    ]]
    if (a1) then
        if (shared.ClanInfo) then
            if (shared.ClanInfo.ClanData.Owner[1] ~= a1.UserId) then
                for _, value_1 in pairs(shared.ClanInfo.ClanData.Admins) do
                    if (value_1[1] ~= a1.UserId) then
                        continue;
                    end;
                    return true;
                end;
                for _, value_2 in pairs(shared.ClanInfo.ClanData.Members) do
                    if (value_2[1] ~= a1.UserId) then
                        continue;
                    end;
                    return true;
                end;
                return false;
            end;
            return true;
        end;
        return false;
    end;
end;
if (Values_1.ServerType.Value ~= "GunGame") then
    local v2 = nil;
    local v3 = nil;
    local v4 = nil;
    for v7, value_3 in pairs(Players_1:GetChildren()) do
        if (value_3 == LocalPlayer_1 or not (value_3.Character)) then
            continue;
        end;
        v2 = value_3.Character:FindFirstChild("NameTag");
        if (not (v2) or shared.cachedTeamModels == nil) then
            continue;
        end;
        if (shared.cachedTeamModels[value_3.Character] == nil) then
            v3 = v1(value_3);
            v4 = (v3 and (Color3.fromRGB(shared.ClanInfo.ClanData.ClanColor.R, shared.ClanInfo.ClanData.ClanColor.G, shared.ClanInfo.ClanData.ClanColor.B))) or (Color3.fromRGB(255, 255, 255));
            v2.MaxDistance = (v3 and 600) or 20;
            v2.Label.TextColor3 = v4;
        end;
    end;
end;