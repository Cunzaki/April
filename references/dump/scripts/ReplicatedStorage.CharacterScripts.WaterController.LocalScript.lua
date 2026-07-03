-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local UserInputService = game:GetService("UserInputService");
local Lighting = game:GetService("Lighting");
local SoundService = game:GetService("SoundService");
local Players = game:GetService("Players");
local RaycastUtil = require(Modules:WaitForChild("RaycastUtil"));
local NumberUtil = require(Modules:WaitForChild("NumberUtil"));
local SettingsModule = require(Modules:WaitForChild("SettingsModule"));
local u1 = require(Modules:WaitForChild("AssetContainer"))();
local VFX = ReplicatedStorage:WaitForChild("VFX");
local Parent = script.Parent;
local u2 = nil;
local u3 = nil;
local u4 = nil;

while true do
    u2 = u2 or Parent:FindFirstChild("Humanoid");
    u3 = u3 or Parent:FindFirstChild("HumanoidRootPart");
    u4 = u4 or Parent:FindFirstChild("Head");

    if u2 and (u3 and u4) then
        break;
    end;

    task.wait(0.1);
end;

local LocalPlayer = Players.LocalPlayer;
local Main = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Main");
local Stats = Main:WaitForChild("Stats");
local DivingGoggles = Main:WaitForChild("DivingGoggles");
local WaterBlur = Lighting:WaitForChild("WaterBlur");
local WaterColorCorrection = Lighting:WaitForChild("WaterColorCorrection");
local Bubbles = VFX:WaitForChild("Bubbles");
local u5 = 0.9;
local u6 = tick();
local u7 = tick();
local u8 = false;

local function _(p9) -- Line: 78
    -- upvalues: u6 (ref), u1 (copy)
    if tick() - u6 >= 1 then
        u6 = tick();
        u1("Fire", "\134n&\2\225A|[\0191\25\27m\1\128O>p\183\145", "^\8mwr\198\1bv\208\226\196{H~$rzv\t", p9);
    end;
end;

local function _(p10) -- Line: 87
    -- upvalues: NumberUtil (copy)
    local v11 = NumberUtil:Lerp(90, 10, p10 / 4);

    return math.ceil(v11);
end;

local function v20() -- Line: 95
    -- upvalues: u3 (ref), RaycastUtil (copy), NumberUtil (copy), u4 (ref), Stats (copy), u6 (ref), u1 (copy)
    local v12 = Vector3.new(u3.Position.X, u3.Position.Y + 1.5, u3.Position.Z);
    local _, v13, _, v14 = RaycastUtil:Raycast(v12, Vector3.new(0, -5, 0), "Whitelist", workspace.Terrain);
    local v15 = 0;

    if v14 == Enum.Material.Water then
        local Magnitude = (v12 - v13).Magnitude;

        if Magnitude <= 0.35 then
            script:SetAttribute("IsSwim", true);
            v15 = 100;
        else
            script:SetAttribute("InWater", true);
            local v16 = NumberUtil:Lerp(90, 10, Magnitude / 4);
            v15 = math.ceil(v16);
        end;

        script:SetAttribute("IsUnder", false);
    else
        local v17 = Region3.new(u4.Position - u4.Size / 2, u4.Position + u4.Size / 2):ExpandToGrid(4);
        local u18, _ = workspace.Terrain:ReadVoxels(v17, 4);
        local u19 = nil;

        if pcall(function() -- Line: 120
            -- upvalues: u19 (ref), u18 (copy)
            u19 = u18[1][1][1];
        end) and u19 == Enum.Material.Water then
            script:SetAttribute("IsSwim", true);
            script:SetAttribute("IsUnder", true);
            v15 = 100;
        else
            script:SetAttribute("InWater", false);
            script:SetAttribute("IsSwim", false);
            script:SetAttribute("IsUnder", false);
        end;
    end;

    local Wet = Stats:FindFirstChild("Wet");

    if Wet and (Wet:GetAttribute("Reach") and v15 > 0) then
        if Wet:GetAttribute("Reach") < v15 and tick() - u6 >= 1 then
            u6 = tick();
            u1("Fire", "\134n&\2\225A|[\0191\25\27m\1\128O>p\183\145", "^\8mwr\198\1bv\208\226\196{H~$rzv\t", v15);
        end;
    elseif Wet == nil and (v15 > 0 and tick() - u6 >= 1) then
        u6 = tick();
        u1("Fire", "\134n&\2\225A|[\0191\25\27m\1\128O>p\183\145", "^\8mwr\198\1bv\208\226\196{H~$rzv\t", v15);
    end;
end;

local function u23(p21) -- Line: 147
    -- upvalues: u3 (ref), Parent (copy), u2 (ref)
    u3.CustomPhysicalProperties = PhysicalProperties.new(p21, 0.3, 0.5);

    if not Parent.Parent or u2.SeatPart then
        return;
    end;

    local v22 = p21 == 0.2;

    for _, child in pairs(Parent:GetChildren()) do
        if child ~= u3 and (not child.Name:find("Torso") and (child.Name ~= "Head" and child:IsA("BasePart"))) then
            child.Massless = v22;
        end;
    end;
end;

local function u24() -- Line: 157
    -- upvalues: u8 (ref), u5 (ref), u23 (copy)
    if u8 and script:GetAttribute("IsSwim") then
        u5 = 0.2;
        u23(u5);

        return;
    end;

    if not script:GetAttribute("InWater") then
        if u5 ~= 0.9 then
            u5 = 0.9;
            u23(u5);
        end;

        return;
    end;

    u5 = 0.6;
    u23(u5);
end;

local function u28(p25) -- Line: 171
    -- upvalues: WaterBlur (copy), LocalPlayer (copy), WaterColorCorrection (copy), SoundService (copy), Parent (copy), Bubbles (copy)
    local v26;

    if p25 then
        v26 = not LocalPlayer:GetAttribute("Armor_HasGoggles");
    else
        v26 = p25;
    end;

    WaterBlur.Enabled = v26;
    WaterColorCorrection.Enabled = p25;
    script.Ambient.Volume = p25 and 0.2 or 0;
    SoundService.AmbientReverb = p25 and Enum.ReverbType.UnderWater or Enum.ReverbType.NoReverb;
    workspace.Terrain.WaterTransparency = p25 and 0.03 or 0.04;
    local Head = Parent:FindFirstChild("Head");

    if not Head then
        return;
    end;

    local Bubbles2 = Head:FindFirstChild("Bubbles");

    if not p25 or Bubbles2 then
        if not p25 and Bubbles2 then
            Bubbles2:Destroy();
        end;

        return;
    end;

    local v27 = Bubbles:Clone();
    v27.Name = "Bubbles";
    v27.Parent = Head;
end;

u2:SetStateEnabled(Enum.HumanoidStateType.Swimming, false);
u2:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false);
script:GetAttributeChangedSignal("IsSwim"):Connect(function() -- Line: 193
    -- upvalues: u3 (ref), u24 (copy)
    if not script:GetAttribute("IsSwim") then
        u24();

        return;
    end;

    local BodyVelocity = Instance.new("BodyVelocity");
    BodyVelocity.Name = "WaterForce";
    BodyVelocity.Parent = u3;
    u24();
    task.wait(0.03333333333333333);
    BodyVelocity:Destroy();
end);
script:GetAttributeChangedSignal("IsUnder"):Connect(function() -- Line: 214
    -- upvalues: u28 (copy), u7 (ref), u1 (copy)
    local v29 = script:GetAttribute("IsUnder");
    u28(v29);

    if not v29 and tick() - u7 >= 1 then
        u7 = tick();
        u1(
            "Fire",
            "\134n&\2\225A|[\0191\25\27m\1\128O>p\183\145",
            "oX\255v\1T/R`\127\132\138\129@M\28K\180}0"
        );
    end;
end);
UserInputService.InputBegan:Connect(function(p30) -- Line: 224
    -- upvalues: SettingsModule (copy), u8 (ref), u24 (copy)
    if p30.UserInputType == Enum.UserInputType.Keyboard then
        if p30.KeyCode.Name == SettingsModule.GetSetting("Controls", "Jump") then
            u8 = true;
            u24();
        end;
    elseif p30.UserInputType == Enum.UserInputType.Gamepad1 and p30.KeyCode.Name == SettingsModule.GetSetting("Gamepad", "Jump") then
        u8 = true;
        u24();
    end;
end);
UserInputService.InputEnded:Connect(function(p31) -- Line: 240
    -- upvalues: SettingsModule (copy), u8 (ref), u24 (copy)
    if p31.UserInputType == Enum.UserInputType.Keyboard then
        if p31.KeyCode.Name == SettingsModule.GetSetting("Controls", "Jump") then
            u8 = false;
            u24();
        end;
    elseif p31.UserInputType == Enum.UserInputType.Gamepad1 and p31.KeyCode.Name == SettingsModule.GetSetting("Gamepad", "Jump") then
        u8 = false;
        u24();
    end;
end);
LocalPlayer:GetAttributeChangedSignal("Armor_HasGoggles"):Connect(function() -- Line: 256
    -- upvalues: LocalPlayer (copy), DivingGoggles (copy), u28 (copy)
    DivingGoggles.Visible = LocalPlayer:GetAttribute("Armor_HasGoggles");
    u28(script:GetAttribute("IsUnder"));
end);
WaterBlur.Enabled = false;
WaterColorCorrection.Enabled = false;
script.Ambient.Volume = 0;
SoundService.AmbientReverb = Enum.ReverbType.NoReverb;
workspace.Terrain.WaterTransparency = 0.04;
local Head = Parent:FindFirstChild("Head");

if Head then
    local Bubbles2 = Head:FindFirstChild("Bubbles");

    if Bubbles2 then
        Bubbles2:Destroy();
    end;
end;

while u2.Health > 0 do
    v20();
    task.wait(0.2);
end;

WaterBlur.Enabled = false;
WaterColorCorrection.Enabled = false;
script.Ambient.Volume = 0;
SoundService.AmbientReverb = Enum.ReverbType.NoReverb;
workspace.Terrain.WaterTransparency = 0.04;
local Head2 = Parent:FindFirstChild("Head");
local v32 = Head2 and Head2:FindFirstChild("Bubbles");

if v32 then
    v32:Destroy();
end;