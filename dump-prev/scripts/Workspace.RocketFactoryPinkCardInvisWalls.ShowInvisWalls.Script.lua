-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local Players_1 = game:GetService("Players");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local RocketFactoryPinkCardInvisWalls_upv_1 = workspace:WaitForChild("RocketFactoryPinkCardInvisWalls");
local NumberUtil_upv_1 = require(ReplicatedStorage_1:WaitForChild("Modules"):WaitForChild("NumberUtil"));
local LocalPlayer_1 = Players_1.LocalPlayer;
local u1 = nil;
local u2 = nil;
local u3 = nil;
local function v1(a1)
    --[[
      line: 18
      upvalues:
        u1 (ref,  index: 1)
        u2 (ref,  index: 2)
        u3 (ref,  index: 3)
        RocketFactoryPinkCardInvisWalls_upv_1 (copy, index: 4)
        NumberUtil_upv_1 (copy, index: 5)
    ]]
    local u4 = nil;
    while (not u4) do
        u4 = a1:FindFirstChildOfClass("Humanoid");
        if (u4) then
            break;
        else
            task.wait();
        end;
    end;
    while (not (a1.Parent)) do
        task.wait();
    end;
    u1 = a1;
    u2 = u4;
    if (u3) then
        pcall(task.cancel, u3);
    end;
    u3 = task.defer(
        function()
            --[[
              line: 33
              upvalues:
                a1 (copy, index: 1)
                u4 (ref,  index: 2)
                RocketFactoryPinkCardInvisWalls_upv_1 (copy, index: 3)
                NumberUtil_upv_1 (copy, index: 4)
            ]]
            while (true) do
                local _ = false;
                local v2 = nil;
                if (a1.Parent and u4.Parent) then
                    local SeatPart_1 = u4.SeatPart;
                    local PrimaryPart_1 = a1.PrimaryPart;
                    if (PrimaryPart_1 and SeatPart_1) then
                        v2 = (not (SeatPart_1.Parent)) or (PrimaryPart_1.Position);
                    end;
                else
                    _ = true;
                end;
                for v6, value_1 in RocketFactoryPinkCardInvisWalls_upv_1:GetChildren() do
                    local v3 = value_1:IsA("BasePart");
                    if (v3) then
                        v3 = value_1.Position;
                        local v4;
                        v4 = false;
                        if (v2 ~= nil) then
                            v4 = NumberUtil_upv_1:IsWithin(v2, v3, 250);
                        end;
                        local v5;
                        if (v4) then
                            v5 = 0.1;
                        else
                            v5 = 1;
                        end;
                        value_1.Transparency = v5;
                    end;
                end;
            end;
        end
    );
end;
LocalPlayer_1.CharacterAdded:Connect(v1);
if (not LocalPlayer_1.Character) then
    return;
end;
v1(LocalPlayer_1.Character);