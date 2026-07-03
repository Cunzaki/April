-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Lighting = game:GetService("Lighting");
local RunService = game:GetService("RunService");
local VFX = ReplicatedStorage:WaitForChild("VFX");
ReplicatedStorage:WaitForChild("LocalSounds");
local Ambience = script:WaitForChild("Ambience");
local Modules = ReplicatedStorage:WaitForChild("Modules");
workspace:WaitForChild("VFX");
local SpawnAreas = workspace:WaitForChild("SpawnAreas");
local Values = ReplicatedStorage:WaitForChild("Values");
local RaycastUtil = require(Modules:WaitForChild("RaycastUtil"));
local TweenUtil = require(Modules:WaitForChild("TweenUtil"));
require(Modules:WaitForChild("WeldModule"));
local LocalPlayer = Players.LocalPlayer;
local u1 = {};
local u2 = false;
local u3 = false;

for _, child in pairs(Ambience:GetChildren()) do
    u1[child] = child.Volume;
    child.Volume = 0;

    if child.Name ~= "Rain" then
        child:Play();
    end;
end;

local function u8(p4) -- Line: 49
    -- upvalues: u1 (copy), TweenUtil (copy)
    local v5 = script:GetAttribute("BelowCeiling");

    for i, v in pairs(u1) do
        local v6 = (i.Name == p4 or i.Name == "Rain") and (v * (v5 and 0.45 or 1) or 0) or 0;
        local v7 = math.abs(i.Volume - v6) / v * 2;

        if v7 > 0 then
            TweenUtil:Tween(i, "Volume", v6, v7, "Linear", "InOut");
        end;
    end;
end;

local function v11() -- Line: 59
    -- upvalues: u2 (ref), Lighting (copy), u8 (copy)
    if not u2 then
        return;
    end;

    local v9 = Lighting:GetAttribute("Stage") or "";
    local v10 = script:GetAttribute("Biome");

    if v10 == "Tundra" or v10 == "Desert" then
        u8(v10);

        return;
    end;

    if v9:find("Night") then
        u8("Night");

        return;
    end;

    u8("Day");
end;

local function u12() -- Line: 73
    -- upvalues: u3 (ref), LocalPlayer (copy), RunService (copy)
    if not u3 then
        return;
    end;

    local Character = LocalPlayer.Character;

    if not (Character and Character:FindFirstChild("HumanoidRootPart")) then
        return;
    end;

    u3 = false;
    RunService:UnbindFromRenderStep("WeatherPart");
    local WeatherPart = Character:FindFirstChild("WeatherPart");

    if WeatherPart then
        WeatherPart:Destroy();
    end;
end;

local function u14() -- Line: 88
    -- upvalues: LocalPlayer (copy), VFX (copy), Values (copy), u12 (copy)
    local Character = LocalPlayer.Character;
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart");

    if not (Character and HumanoidRootPart) then
        return;
    end;

    local v13 = Character:FindFirstChild("WeatherPart") or VFX.WeatherPart:Clone();
    v13.Parent = Character;
    v13.CFrame = CFrame.new(HumanoidRootPart.Position) * CFrame.new(0, 10, 0);
    v13.Snow.Enabled = script:GetAttribute("Biome") == "Tundra";

    if Values.Raining.Value < 0.8 then
        u12();
    end;
end;

local function _() -- Line: 104
    -- upvalues: u3 (ref), Ambience (copy), RunService (copy), u14 (copy)
    if u3 then
        return;
    end;

    local _ = Ambience.Rain.IsPlaying;
    u3 = true;
    RunService:BindToRenderStep("WeatherPart", Enum.RenderPriority.Character.Value + 1, u14);
end;

local function v16() -- Line: 115
    -- upvalues: LocalPlayer (copy), Values (copy), Ambience (copy), u3 (ref), RunService (copy), u14 (copy), u12 (copy)
    if not LocalPlayer.Character then
        return;
    end;

    local _ = LocalPlayer.Character;
    local v15 = Values.Raining.Value >= 0.8;

    if v15 then
        if not Ambience.Rain.IsPlaying then
            Ambience.Rain:Play();
        end;
    elseif Ambience.Rain.IsPlaying then
        Ambience.Rain:Stop();
    end;

    if not v15 or script:GetAttribute("BelowCeiling") then
        u12();

        return;
    end;

    if u3 then
        return;
    end;

    local _ = Ambience.Rain.IsPlaying;
    u3 = true;
    RunService:BindToRenderStep("WeatherPart", Enum.RenderPriority.Character.Value + 1, u14);
end;

Lighting:GetAttributeChangedSignal("Stage"):Connect(v11);
script:GetAttributeChangedSignal("BelowCeiling"):Connect(v11);
script:GetAttributeChangedSignal("BelowCeiling"):Connect(v16);
Values.Raining.Changed:Connect(v16);
v11();

while true do
    local Character = LocalPlayer.Character;

    if Character then
        local PrimaryPart = Character.PrimaryPart;

        if PrimaryPart then
            local Position = PrimaryPart.Position;
            local v17 = RaycastUtil:Raycast(Vector3.new(Position.X, 577.4, Position.Z), Vector3.new(0, 0.2, 0), "Include", SpawnAreas, false);
            local v18;

            if v17 == nil or v17.Parent == nil then
                v18 = false;
            else
                v18 = v17.Parent.Name;
            end;

            local v19 = v18 and (v18:find("Tundra") and "Tundra" or (v18:find("Desert") and "Desert" or "Forest")) or "Forest";

            if script:GetAttribute("Biome") ~= v19 or not u2 then
                u2 = true;
                script:SetAttribute("Biome", v19);
                v11();
                v16();
            end;
        end;
    end;

    task.wait(1);
end;