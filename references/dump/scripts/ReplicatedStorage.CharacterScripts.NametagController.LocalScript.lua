-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local Players = game:GetService("Players");
local v1 = { workspace:WaitForChild("Bases"), workspace:WaitForChild("Monuments") };
local v2 = os.clock();
local v3 = os.clock();
local v4 = {};

while true do
    if os.clock() - v2 >= 2 then
        v2 = os.clock();

        for i, v in v4 do
            if v and (v.Character and v.Character:FindFirstChild("HumanoidRootPart")) then
                local HumanoidRootPart = v.Character.HumanoidRootPart;
                local v5 = RaycastParams.new();
                v5.FilterDescendantsInstances = v1;
                v5.FilterType = Enum.RaycastFilterType.Include;
                v5.IgnoreWater = true;
                v5.RespectCanCollide = true;
                workspace:Raycast(HumanoidRootPart.Position, Vector3.new(0, 3.1, 0), v5);
                task.wait();
            else
                v4[i] = nil;
            end;
        end;
    end;

    if os.clock() - v3 >= 8 then
        v3 = os.clock();
        v4 = {};

        for _, child in Players:GetChildren() do
            table.insert(v4, child);
            task.wait();
        end;
    end;

    task.wait(0.15);
end;