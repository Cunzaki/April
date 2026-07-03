-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local RocketFactoryPinkCardInvisWalls = workspace:WaitForChild("RocketFactoryPinkCardInvisWalls");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local NumberUtil = require(Modules:WaitForChild("NumberUtil"));
local LocalPlayer = Players.LocalPlayer;
local u1 = nil;
local u2 = nil;
local u3 = nil;

local function v9(u4) -- Line: 18
    -- upvalues: u1 (ref), u2 (ref), u3 (ref), RocketFactoryPinkCardInvisWalls (copy), NumberUtil (copy)
    local u5 = nil;

    while not u5 do
        u5 = u4:FindFirstChildOfClass("Humanoid");

        if u5 then
            break;
        end;

        task.wait();
    end;

    while not u4.Parent do
        task.wait();
    end;

    u1 = u4;
    u2 = u5;

    if u3 then
        pcall(task.cancel, u3);
    end;

    u3 = task.defer(function() -- Line: 33
        -- upvalues: u4 (copy), u5 (ref), RocketFactoryPinkCardInvisWalls (ref), NumberUtil (ref)
        while true do
            local v6 = false;
            local v7 = nil;

            if u4.Parent and u5.Parent then
                local SeatPart = u5.SeatPart;
                local PrimaryPart = u4.PrimaryPart;

                if PrimaryPart and (SeatPart and SeatPart.Parent) then
                    v7 = PrimaryPart.Position;
                end;
            else
                v6 = true;
            end;

            for _, child in RocketFactoryPinkCardInvisWalls:GetChildren() do
                if child:IsA("BasePart") then
                    local Position = child.Position;
                    local v8;

                    if v7 == nil then
                        v8 = false;
                    else
                        v8 = NumberUtil:IsWithin(v7, Position, 250);
                    end;

                    child.Transparency = v8 and 0.1 or 1;
                end;
            end;

            if v6 then
                return;
            end;

            task.wait(0.1);
        end;
    end);
end;

LocalPlayer.CharacterAdded:Connect(v9);

if LocalPlayer.Character then
    v9(LocalPlayer.Character);
end;