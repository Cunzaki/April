-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local Players_1 = game:GetService("Players");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local Lighting_upv_1 = game:GetService("Lighting");
local RunService_upv_1 = game:GetService("RunService");
local VFX_upv_1 = ReplicatedStorage_1:WaitForChild("VFX");
local _ = ReplicatedStorage_1:WaitForChild("LocalSounds");
local Ambience_upv_1 = script:WaitForChild("Ambience");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local v16 = workspace:WaitForChild("VFX");
local SpawnAreas_1 = workspace:WaitForChild("SpawnAreas");
local Values_upv_1 = ReplicatedStorage_1:WaitForChild("Values");
local RaycastUtil_1 = require(Modules_1:WaitForChild("RaycastUtil"));
local TweenUtil_upv_1 = require(Modules_1:WaitForChild("TweenUtil"));
local v17 = require(Modules_1:WaitForChild("WeldModule"));
local LocalPlayer_upv_1 = Players_1.LocalPlayer;
local tbl_upv_1 = {};
local u1 = false;
local u2 = nil;
for key_upv_1, value_1 in pairs(Ambience_upv_1:GetChildren()) do
    tbl_upv_1[value_1] = value_1.Volume;
    value_1.Volume = 0;
    if (value_1.Name ~= "Rain") then
        value_1:Play();
    end;
end;
local function u3(a1)
    --[[
      line: 49
      upvalues:
        tbl_upv_1 (copy, index: 1)
        TweenUtil_upv_1 (copy, index: 2)
    ]]
    local v1 = script:GetAttribute("BelowCeiling");
    local v4;
    local v2 = nil;
    local key_2 = nil;
    local value_2 = nil;
    local v3 = nil;
    for key_2, value_2 in pairs(tbl_upv_1) do
        if (key_2.Name == a1 or key_2.Name == "Rain") then
            v2 = value_2 * ((v1 and 0.45) or 1) or 0;
        else
            v2 = 0;
        end;
        v3 = math.abs(key_2.Volume - v2) / value_2 * 2;
        if (v3 > 0) then
            TweenUtil_upv_1:Tween(key_2, "Volume", v2, v3, "Linear", "InOut");
        end;
    end;
end;
local function v4()
    --[[
      line: 59
      upvalues:
        u1 (ref,  index: 1)
        Lighting_upv_1 (copy, index: 2)
        u3 (copy, index: 3)
    ]]
    local v5 = nil;
    if (u1) then
        local v6 = Lighting_upv_1:GetAttribute("Stage") or "";
        v5 = script:GetAttribute("Biome");
        if (v5 ~= "Tundra" and v5 ~= "Desert") then
            if (v6:find("Night")) then
                u3("Night");
            else
                u3("Day");
            end;
            return;
        end;
        u3(v5);
    end;
end;
local function u4()
    --[[
      line: 73
      upvalues:
        u2 (ref,  index: 1)
        LocalPlayer_upv_1 (copy, index: 2)
        RunService_upv_1 (copy, index: 3)
    ]]
    local v7 = nil;
    if (u2) then
        v7 = LocalPlayer_upv_1.Character;
        local HumanoidRootPart_1 = v7:FindFirstChild("HumanoidRootPart");
        if (v7) then
            local v8 = nil;
            if (HumanoidRootPart_1) then
                u2 = false;
                RunService_upv_1:UnbindFromRenderStep("WeatherPart");
                v8 = v7:FindFirstChild("WeatherPart");
                if (v8) then
                    v8:Destroy();
                end;
                return;
            end;
        end;
    end;
end;
local function key_upv_1()
    --[[
      line: 88
      upvalues:
        LocalPlayer_upv_1 (copy, index: 1)
        VFX_upv_1 (copy, index: 2)
        Values_upv_1 (copy, index: 3)
        u4 (copy, index: 4)
    ]]
    local Character_1 = LocalPlayer_upv_1.Character;
    local HumanoidRootPart_2 = Character_1:FindFirstChild("HumanoidRootPart");
    if (not Character_1) then
        return;
    end;
    if (HumanoidRootPart_2) then
        local v9 = Character_1:FindFirstChild("WeatherPart") or (VFX_upv_1.WeatherPart:Clone());
        v9.Parent = Character_1;
        v9.CFrame = CFrame.new(HumanoidRootPart_2.Position) * CFrame.new(0, 10, 0);
        local Snow_1 = v9.Snow;
        Snow_1.Enabled = script:GetAttribute("Biome") == "Tundra";
        if (Values_upv_1.Raining.Value < 0.8) then
            u4();
        end;
    end;
end;
local function v11()
    --[[
      line: 115
      upvalues:
        LocalPlayer_upv_1 (copy, index: 1)
        Values_upv_1 (copy, index: 2)
        Ambience_upv_1 (copy, index: 3)
        u2 (ref,  index: 4)
        RunService_upv_1 (copy, index: 5)
        key_upv_1 (copy, index: 6)
        u4 (copy, index: 7)
    ]]
    if (LocalPlayer_upv_1.Character) then
        local v12 = Values_upv_1.Raining.Value >= 0.8;
        if (v12) then
            if (not (Ambience_upv_1.Rain.IsPlaying)) then
                Ambience_upv_1.Rain:Play();
            end;
        elseif (Ambience_upv_1.Rain.IsPlaying) then
            Ambience_upv_1.Rain:Stop();
        end;
        if (v12 and not (script:GetAttribute("BelowCeiling"))) then
            if (not u2) then
                u2 = true;
                RunService_upv_1:BindToRenderStep("WeatherPart", Enum.RenderPriority.Character.Value + 1, key_upv_1);
            end;
            return;
        end;
        u4();
    end;
end;
Lighting_upv_1:GetAttributeChangedSignal("Stage"):Connect(v4);
script:GetAttributeChangedSignal("BelowCeiling"):Connect(v4);
script:GetAttributeChangedSignal("BelowCeiling"):Connect(v11);
Values_upv_1.Raining.Changed:Connect(v11);
v4();
local v13 = nil;
local Character_2 = LocalPlayer_upv_1.Character;
if (Character_2) then
    local PrimaryPart_1 = Character_2.PrimaryPart;
end;
if (Character_2 and PrimaryPart_1) then
    local Position_1 = PrimaryPart_1.Position;
    local v14 = RaycastUtil_1:Raycast(Vector3.new(Position_1.X, 577.4, Position_1.Z), Vector3.new(0, 0.20000000298023224, 0), "Include", SpawnAreas_1, false);
    v13 = false;
    if (v14 == nil) then
        local v15 = nil;
        if (v13) then
            if (v13:find("Tundra")) then
                v15 = "Tundra";
                if (script:GetAttribute("Biome") ~= v15 or not u1) then
                    u1 = true;
                    script:SetAttribute("Biome", v15);
                    v4();
                    v11();
                end;
                task.wait(1);
            else
                if (v13:find("Desert")) then
                    v15 = "Desert";
                else
                    v15 = "Forest";
                end;
                if (script:GetAttribute("Biome") ~= v15) then
                    u1 = true;
                    script:SetAttribute("Biome", v15);
                    v4();
                    v11();
                    task.wait(1);
                elseif (not u1) then
                    u1 = true;
                    script:SetAttribute("Biome", v15);
                    v4();
                    v11();
                end;
            end;
        else
            v15 = "Forest";
            if (script:GetAttribute("Biome") ~= v15) then
                u1 = true;
                script:SetAttribute("Biome", v15);
                v4();
                v11();
                task.wait(1);
            elseif (not u1) then
                u1 = true;
                script:SetAttribute("Biome", v15);
                v4();
                v11();
            end;
        end;
    else
        v13 = false;
        if (v14.Parent ~= nil) then
            v13 = v14.Parent.Name;
        end;
        local v15 = nil;
        if (v13) then
            if (v13:find("Tundra")) then
                v15 = "Tundra";
                if (script:GetAttribute("Biome") ~= v15 or not u1) then
                    u1 = true;
                    script:SetAttribute("Biome", v15);
                    v4();
                    v11();
                end;
                task.wait(1);
            else
                if (v13:find("Desert")) then
                    v15 = "Desert";
                else
                    v15 = "Forest";
                end;
                if (script:GetAttribute("Biome") ~= v15) then
                    u1 = true;
                    script:SetAttribute("Biome", v15);
                    v4();
                    v11();
                    task.wait(1);
                elseif (not u1) then
                    u1 = true;
                    script:SetAttribute("Biome", v15);
                    v4();
                    v11();
                end;
            end;
        else
            v15 = "Forest";
            if (script:GetAttribute("Biome") ~= v15) then
                u1 = true;
                script:SetAttribute("Biome", v15);
                v4();
                v11();
                task.wait(1);
            elseif (not u1) then
                u1 = true;
                script:SetAttribute("Biome", v15);
                v4();
                v11();
            end;
        end;
    end;
else
    task.wait(1);
end;