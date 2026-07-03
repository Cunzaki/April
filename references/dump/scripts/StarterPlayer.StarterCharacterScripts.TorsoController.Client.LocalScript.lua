-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local Players = game:GetService("Players");
game:GetService("RunService");
local Modules = game:GetService("ReplicatedStorage"):WaitForChild("Modules");
workspace:WaitForChild("VFX");
require(Modules:WaitForChild("RaycastUtil"));
local _ = Players.LocalPlayer;
local CurrentCamera = workspace.CurrentCamera;
local Parent = script.Parent.Parent;
local v1 = nil;
local v2 = nil;
local v3 = nil;
local v4 = nil;

while true do
    v1 = v1 or Parent:FindFirstChild("Humanoid");
    v2 = v2 or Parent:FindFirstChild("HumanoidRootPart");
    v3 = v3 or Parent:FindFirstChild("Head");
    v4 = v4 or Parent:FindFirstChild("UpperTorso");

    if v1 and (v2 and (v3 and v4)) then
        break;
    end;

    task.wait(0.1);
end;

local Neck = v3:WaitForChild("Neck");
local Waist = v4:WaitForChild("Waist");
local v5 = nil;
local v6 = nil;
local v7 = nil;

while Parent and Parent.Parent do
    v6 = Parent:FindFirstChild("InventoryController");
    v7 = Parent:FindFirstChild("WheelController");
    v5 = Parent:FindFirstChild("CameraController");

    if v6 and (v7 and v5) then
        break;
    end;

    task.wait();
end;

print("TorsoController initiated");
local Look = script.Parent:WaitForChild("Look");
local v8 = tick();
local v9 = 0;
local v10 = 0;

while task.wait(0.05) do
    local v11, v12;

    if tick() - v8 < 0.09 or (v6:GetAttribute("Open") or (v7:GetAttribute("Open") or not (script.Parent:GetAttribute("Initiated") and (v6:GetAttribute("Initiated") and (v2 and (v2.Parent and (v4 and (v4.Parent and (v3 and (v3.Parent and (Neck and (Neck.Parent and (Waist and (Waist.Parent and CurrentCamera.CameraSubject)))))))))))))) then
        v11 = v10;
        v12 = v9;
    else
        local Position = (CurrentCamera.CFrame * CFrame.new(0, 0, -5)).Position;
        local v13 = math.asin(-CurrentCamera.CFrame.LookVector.Y);
        local v14 = math.abs(v13);
        v11 = math.max(v14, 0.0001) * (math.sign(v13) == -1 and -1 or 1);

        if v5:GetAttribute("ViewmodelCFrame") or v1.Parent and (v1.SeatPart and v1.SeatPart.Parent) then
            local Y = (CurrentCamera.CFrame.Position - Position).Unit:Cross(v4.CFrame.LookVector).Y;
            v12 = math.asin(Y);
        else
            v12 = 0;
        end;

        if math.abs(v11 - v10) >= 0.017453292519943295 or math.abs(v12 - v9) >= 0.03490658503988659 then
            Look:FireServer(v11, v12);
            v8 = tick();
        else
            v11 = v10;
            v12 = v9;
        end;
    end;

    v10 = v11;
    v9 = v12;
end;