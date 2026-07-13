-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local UserInputService_1 = game:GetService("UserInputService");
local Lighting_1 = game:GetService("Lighting");
local SoundService_upv_1 = game:GetService("SoundService");
local Players_1 = game:GetService("Players");
local RaycastUtil_upv_1 = require(Modules_1:WaitForChild("RaycastUtil"));
local NumberUtil_upv_1 = require(Modules_1:WaitForChild("NumberUtil"));
local SettingsModule_upv_1 = require(Modules_1:WaitForChild("SettingsModule"));
local u1 = require(Modules_1:WaitForChild("AssetContainer"))();
local VFX_1 = ReplicatedStorage_1:WaitForChild("VFX");
local Parent_upv_1 = script.Parent;
local Humanoid_upv_1 = nil;
local u2 = nil;
local u3 = nil;
while (true) do
    if (not (Humanoid_upv_1)) then
        Humanoid_upv_1 = Parent_upv_1:FindFirstChild("Humanoid");
    end;
    u2 = u2 or (Parent_upv_1:FindFirstChild("HumanoidRootPart"));
    u3 = u3 or (Parent_upv_1:FindFirstChild("Head"));
    if (not (Humanoid_upv_1) or not (u2)) then
        task.wait(0.1);
        continue;
    end;
    if (u3) then
        break;
    end;
    task.wait(0.1);
end;
local LocalPlayer_upv_1 = Players_1.LocalPlayer;
local Main_1 = LocalPlayer_upv_1:WaitForChild("PlayerGui"):WaitForChild("Main");
local Stats_upv_1 = Main_1:WaitForChild("Stats");
local DivingGoggles_upv_1 = Main_1:WaitForChild("DivingGoggles");
local WaterBlur_upv_1 = Lighting_1:WaitForChild("WaterBlur");
local WaterColorCorrection_upv_1 = Lighting_1:WaitForChild("WaterColorCorrection");
local Bubbles_upv_1 = VFX_1:WaitForChild("Bubbles");
local u4 = 0.9;
local u5 = tick();
local u6 = tick();
local u7 = false;
local function v1()
    --[[
      line: 95
      upvalues:
        u2 (ref,  index: 1)
        RaycastUtil_upv_1 (copy, index: 2)
        NumberUtil_upv_1 (copy, index: 3)
        u3 (ref,  index: 4)
        Stats_upv_1 (copy, index: 5)
        u5 (ref,  index: 6)
        u1 (copy, index: 7)
    ]]
    local v2 = Vector3.new(u2.Position.X, u2.Position.Y + 1.5, u2.Position.Z);
    local _, v3, v7, v4 = RaycastUtil_upv_1:Raycast(v2, Vector3.new(0, -5, 0), "Whitelist", workspace.Terrain);
    local v5 = 0;
    local v6 = nil;
    if (v4 ~= Enum.Material.Water) then
        local u8, v8 = workspace.Terrain:ReadVoxels(Region3.new(u3.Position - (u3.Size / 2), u3.Position + (u3.Size / 2)):ExpandToGrid(4), 4);
        local u9 = nil;
        if ((pcall(
            function()
                --[[
                  line: 120
                  upvalues:
                    u9 (ref,  index: 1)
                    u8 (copy, index: 2)
                ]]
                u9 = u8[1][1][1];
            end
        )) and u9 == Enum.Material.Water) then
            script:SetAttribute("IsSwim", true);
            script:SetAttribute("IsUnder", true);
            v5 = 100;
        else
            script:SetAttribute("InWater", false);
            script:SetAttribute("IsSwim", false);
            script:SetAttribute("IsUnder", false);
        end;
    else
        v6 = (v2 - v3).Magnitude;
        if (v6 > 0.35) then
            script:SetAttribute("InWater", true);
            v5 = math.ceil(NumberUtil_upv_1:Lerp(90, 10, v6 / 4));
        else
            script:SetAttribute("IsSwim", true);
            v5 = 100;
        end;
        script:SetAttribute("IsUnder", false);
    end;
    local Wet_1 = Stats_upv_1:FindFirstChild("Wet");
    if (Wet_1 and Wet_1:GetAttribute("Reach") and v5 > 0) then
        if (Wet_1:GetAttribute("Reach") < v5 and tick() - u5 >= 1) then
            u5 = tick();
            u1("Fire", "\134n&\002\225A|[\0191\025\027m\001\128O>p\183\145", "^\bmwr\198\001bv\208\226\196{H~$rzv\t", v5);
        end;
        return;
    end;
    if (Wet_1 ~= nil or v5 <= 0 or tick() - u5 < 1) then
        return;
    end;
    u5 = tick();
    u1("Fire", "\134n&\002\225A|[\0191\025\027m\001\128O>p\183\145", "^\bmwr\198\001bv\208\226\196{H~$rzv\t", v5);
end;
local function u10(a1)
    --[[
      line: 147
      upvalues:
        u2 (ref,  index: 1)
        Parent_upv_1 (copy, index: 2)
        Humanoid_upv_1 (ref,  index: 3)
    ]]
    u2.CustomPhysicalProperties = PhysicalProperties.new(a1, 0.3, 0.5);
    if (not Parent_upv_1.Parent) then
        return;
    end;
    if (not Humanoid_upv_1.SeatPart) then
        local v7 = a1 == 0.2;
        local value_1 = nil;
        for _, value_1 in pairs(Parent_upv_1:GetChildren()) do
            if (value_1 == u2 or value_1.Name:find("Torso") or value_1.Name == "Head") then
                continue;
            end;
            if (value_1:IsA("BasePart")) then
                value_1.Massless = v7;
            end;
        end;
    end;
end;
local function u11()
    --[[
      line: 157
      upvalues:
        u7 (ref,  index: 1)
        u4 (ref,  index: 2)
        u10 (copy, index: 3)
    ]]
    local v8 = script:GetAttribute("IsSwim");
    if (u7 and v8) then
        u4 = 0.2;
        u10(u4);
        return;
    end;
    if (script:GetAttribute("InWater")) then
        u4 = 0.6;
        u10(u4);
    elseif (u4 ~= 0.9) then
        u4 = 0.9;
        u10(u4);
    end;
end;
Humanoid_upv_1:SetStateEnabled(Enum.HumanoidStateType.Swimming, false);
Humanoid_upv_1:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false);
script:GetAttributeChangedSignal("IsSwim"):Connect(
    function()
        --[[
          line: 193
          upvalues:
            u2 (ref,  index: 1)
            u11 (copy, index: 2)
        ]]
        if (script:GetAttribute("IsSwim")) then
            local v9 = Instance.new("BodyVelocity");
            v9.Name = "WaterForce";
            v9.Parent = u2;
            u11();
            task.wait(0.03333333333333333);
            v9:Destroy();
        else
            u11();
        end;
    end
);
local function u12(a1)
    --[[
      line: 171
      upvalues:
        WaterBlur_upv_1 (copy, index: 1)
        LocalPlayer_upv_1 (copy, index: 2)
        WaterColorCorrection_upv_1 (copy, index: 3)
        SoundService_upv_1 (copy, index: 4)
        Parent_upv_1 (copy, index: 5)
        Bubbles_upv_1 (copy, index: 6)
    ]]
    WaterBlur_upv_1.Enabled = a1 and not LocalPlayer_upv_1:GetAttribute("Armor_HasGoggles");
    WaterColorCorrection_upv_1.Enabled = a1;
    script.Ambient.Volume = (a1 and 0.2) or 0;
    SoundService_upv_1.AmbientReverb = (a1 and (Enum.ReverbType.UnderWater)) or (Enum.ReverbType.NoReverb);
    workspace.Terrain.WaterTransparency = (a1 and 0.03) or 0.04;
    local Head_1 = Parent_upv_1:FindFirstChild("Head");
    if (Head_1) then
        local Bubbles_2 = Head_1:FindFirstChild("Bubbles");
        if (a1 and not (Bubbles_2)) then
            local v11 = Bubbles_upv_1:Clone();
            v11.Name = "Bubbles";
            v11.Parent = Head_1;
            return;
        end;
        if (not (a1) and Bubbles_2) then
            Bubbles_2:Destroy();
        end;
    end;
end;
script:GetAttributeChangedSignal("IsUnder"):Connect(
    function()
        --[[
          line: 214
          upvalues:
            u12 (copy, index: 1)
            u6 (ref,  index: 2)
            u1 (copy, index: 3)
        ]]
        local v12 = script:GetAttribute("IsUnder");
        u12(v12);
        if ((v12) or tick() - u6 < 1) then
            return;
        end;
        u6 = tick();
        u1("Fire", "\134n&\002\225A|[\0191\025\027m\001\128O>p\183\145", "oX\255v\001T/R`\127\132\138\129@M\028K\180}0");
    end
);
UserInputService_1.InputBegan:Connect(
    function(a1)
        --[[
          line: 224
          upvalues:
            SettingsModule_upv_1 (copy, index: 1)
            u7 (ref,  index: 2)
            u11 (copy, index: 3)
        ]]
        if (a1.UserInputType ~= Enum.UserInputType.Keyboard) then
            if (a1.UserInputType ~= Enum.UserInputType.Gamepad1 or a1.KeyCode.Name ~= SettingsModule_upv_1.GetSetting("Gamepad", "Jump")) then
                return;
            end;
            u7 = true;
            u11();
        elseif (a1.KeyCode.Name == SettingsModule_upv_1.GetSetting("Controls", "Jump")) then
            u7 = true;
            u11();
        end;
    end
);
UserInputService_1.InputEnded:Connect(
    function(a1)
        --[[
          line: 240
          upvalues:
            SettingsModule_upv_1 (copy, index: 1)
            u7 (ref,  index: 2)
            u11 (copy, index: 3)
        ]]
        if (a1.UserInputType ~= Enum.UserInputType.Keyboard) then
            if (a1.UserInputType ~= Enum.UserInputType.Gamepad1 or a1.KeyCode.Name ~= SettingsModule_upv_1.GetSetting("Gamepad", "Jump")) then
                return;
            end;
            u7 = false;
            u11();
        elseif (a1.KeyCode.Name == SettingsModule_upv_1.GetSetting("Controls", "Jump")) then
            u7 = false;
            u11();
        end;
    end
);
LocalPlayer_upv_1:GetAttributeChangedSignal("Armor_HasGoggles"):Connect(
    function()
        --[[
          line: 256
          upvalues:
            LocalPlayer_upv_1 (copy, index: 1)
            DivingGoggles_upv_1 (copy, index: 2)
            u12 (copy, index: 3)
        ]]
        DivingGoggles_upv_1.Visible = LocalPlayer_upv_1:GetAttribute("Armor_HasGoggles");
        u12(script:GetAttribute("IsUnder"));
    end
);
WaterBlur_upv_1.Enabled = false;
WaterColorCorrection_upv_1.Enabled = false;
script.Ambient.Volume = 0;
SoundService_upv_1.AmbientReverb = Enum.ReverbType.NoReverb;
workspace.Terrain.WaterTransparency = 0.04;
local Head_2 = Parent_upv_1:FindFirstChild("Head");
local v13 = nil;
if (Head_2) then
    v13 = Head_2:FindFirstChild("Bubbles");
    if (v13) then
        v13:Destroy();
    end;
end;
while (Humanoid_upv_1.Health > 0) do
    v1();
    task.wait(0.2);
end;
WaterBlur_upv_1.Enabled = false;
WaterColorCorrection_upv_1.Enabled = false;
script.Ambient.Volume = 0;
SoundService_upv_1.AmbientReverb = Enum.ReverbType.NoReverb;
workspace.Terrain.WaterTransparency = 0.04;
local Head_3 = Parent_upv_1:FindFirstChild("Head");
if (Head_3) then
    local Bubbles_3 = Head_3:FindFirstChild("Bubbles");
    if (not Bubbles_3) then
        return;
    end;
    Bubbles_3:Destroy();
end;