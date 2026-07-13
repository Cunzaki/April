-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local _ = game:GetService("Players");
local v18 = game:GetService("RunService");
local Modules_1 = game:GetService("ReplicatedStorage"):WaitForChild("Modules");
local v19 = workspace:WaitForChild("VFX");
local v20 = require(Modules_1:WaitForChild("RaycastUtil"));
local CurrentCamera_1 = workspace.CurrentCamera;
local Parent_1 = script.Parent.Parent;
local v1 = nil;
local v2 = nil;
local v3 = nil;
local v4 = nil;
while (true) do
    if (not (v1)) then
        v1 = Parent_1:FindFirstChild("Humanoid");
    end;
    v4 = v4 or (Parent_1:FindFirstChild("HumanoidRootPart"));
    v2 = v2 or (Parent_1:FindFirstChild("Head"));
    v3 = v3 or (Parent_1:FindFirstChild("UpperTorso"));
    if (not (v1) or not (v4) or not (v2)) then
        task.wait(0.1);
        continue;
    end;
    if (v3) then
        break;
    end;
    task.wait(0.1);
end;
local Neck_1 = v2:WaitForChild("Neck");
local Waist_1 = v3:WaitForChild("Waist");
local v5 = nil;
local v6 = nil;
local v7 = nil;
while ((Parent_1)) do
    if (Parent_1.Parent) then
        v5 = Parent_1:FindFirstChild("InventoryController");
        v6 = Parent_1:FindFirstChild("WheelController");
        v7 = Parent_1:FindFirstChild("CameraController");
        if (not (v5)) then
            task.wait();
            continue;
        elseif (not (v6) or not (v7)) then
            task.wait();
            ;
            continue;
        else
            break;
        end;
    else
        continue;
    end;
end;
print("TorsoController initiated");
local Look_1 = script.Parent:WaitForChild("Look");
local v8 = tick();
local v9 = 0;
local v10 = 0;
v8, v9, v10 = v8, v9, v10;
local v11 = nil;
while (true) do
    local v12, v13, v14, v15;
    if (not (task.wait(0.05))) then
        break;
    end;
    if (tick() - v8 < 0.09) then
        continue;
    end;
    v12 = v5:GetAttribute("Open");
    if (v12) then
        continue;
    end;
    v13 = v6:GetAttribute("Open");
    if (v13) then
        continue;
    end;
    v14 = script.Parent:GetAttribute("Initiated");
    if (not (v14)) then
        continue;
    end;
    v15 = v5:GetAttribute("Initiated");
    if (not (v15) or not (v4) or not (v4.Parent) or not (v3) or not (v3.Parent) or not (v2) or not (v2.Parent) or not (Neck_1) or not (Neck_1.Parent) or not (Waist_1) or not (Waist_1.Parent)) then
        continue;
    end;
    local v16;
    if (not (CurrentCamera_1.CameraSubject)) then
        continue;
    end;
    v12 = (CurrentCamera_1.CFrame * CFrame.new(0, 0, -5)).Position;
    local v17 = math.asin(-CurrentCamera_1.CFrame.LookVector.Y);
    v11 = math.max(math.abs(v17), 1e-04);
    v16 = ((math.sign(v17) ~= -1) and 1) or -1;
    v17 = v11 * v16;
    v11 = 0;
    if (v7:GetAttribute("ViewmodelCFrame")) then
        v11 = math.asin((CurrentCamera_1.CFrame.Position - v12).Unit:Cross(v3.CFrame.LookVector).Y);
    else
        v11 = v1.Parent and v1.SeatPart and v1.SeatPart.Parent and math.asin((CurrentCamera_1.CFrame.Position - v12).Unit:Cross(v3.CFrame.LookVector).Y);
    end;
    if (math.abs(v17 - v9) >= 0.017453292519943295 or math.abs(v11 - v10) >= 0.03490658503988659) then
        Look_1:FireServer(v17, v11);
        v8, v9, v10 = tick(), v17, v11;
    end;
end;