-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

Run = game:GetService("RunService");
Replicated = game:GetService("ReplicatedStorage");
InputService = game:GetService("UserInputService");
Players = game:GetService("Players");
Sound = game:GetService("SoundService");
Debris = game:GetService("Debris");
Lighting = game:GetService("Lighting");
VFX_PARTS = workspace:WaitForChild("VFX");
VM_PARTS = VFX_PARTS:WaitForChild("VMs");
Drops = workspace:WaitForChild("Drops");
Nodes = workspace:WaitForChild("Nodes");
Plants = workspace:WaitForChild("Plants");
VMs = Replicated:WaitForChild("VMs");
Modules = Replicated:WaitForChild("Modules");
Values = Replicated:WaitForChild("Values");
VFX_STORAGE = Replicated:WaitForChild("VFX");
Sleeves = Replicated:WaitForChild("Sleeves");
Player = Players.LocalPlayer;
PlayerGui = Player:WaitForChild("PlayerGui");
local Parent = script.Parent;
local Humanoid = Parent:WaitForChild("Humanoid");
Camera = workspace.CurrentCamera;
local v1 = Player:GetMouse();
StateController = Parent:WaitForChild("StateController");
InventoryController = Parent:WaitForChild("InventoryController");
WheelController = Parent:WaitForChild("WheelController");
CameraController = Parent:WaitForChild("CameraController");
WaterController = Parent:WaitForChild("WaterController");
InteractController = Parent:WaitForChild("InteractController");
TeamNavigationController = Parent:WaitForChild("TeamNavigationController");
local PreferredInputController = Player:WaitForChild("PlayerScripts"):WaitForChild("PreferredInputController");
local ChatController = Player:WaitForChild("PlayerScripts"):WaitForChild("ChatController");

local function _() -- Line: 58
    -- upvalues: PreferredInputController (copy)
    local v2 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

    return v2;
end;

local ToolInfo = require(Modules:WaitForChild("ToolInfo"));
local NumberUtil = require(Modules:WaitForChild("NumberUtil"));
local TableUtil = require(Modules:WaitForChild("TableUtil"));
local Spring = require(Modules:WaitForChild("Spring"));
local Items = require(Modules:WaitForChild("Items"));
local VFXModule = require(Modules:WaitForChild("VFXModule"));
local WeldModule = require(Modules:WaitForChild("WeldModule"));
local ItemClass = require(Modules:WaitForChild("ItemClass"));
local SoundModule = require(Modules:WaitForChild("SoundModule"));
local RaycastUtil = require(Modules:WaitForChild("RaycastUtil"));
local TweenUtil = require(Modules:WaitForChild("TweenUtil"));
local SettingsModule = require(Modules:WaitForChild("SettingsModule"));
local u3 = require(Modules:WaitForChild("AssetContainer"))();
EquipVM = script:WaitForChild("EquipVM");
UpdateVM = script:WaitForChild("UpdateVM");
PlayVMAnimation = script:WaitForChild("PlayVMAnimation");
local Main = PlayerGui:WaitForChild("Main");
local Crosshair = Main:WaitForChild("Crosshair");
local HitMarker = Main:WaitForChild("HitMarker");
local Scope = Main:WaitForChild("Scope");
local Codelock = Main:WaitForChild("Codelock");
local RenameBed = Main:WaitForChild("RenameBed");
local GiveBed = Main:WaitForChild("GiveBed");
local Toolbar = Main:WaitForChild("Toolbar");
local Stats = Main:WaitForChild("Stats");
local GamepadControls = Main:WaitForChild("GamepadControls");
local Highlight = VFX_STORAGE:WaitForChild("Highlight");
local CameraRoot = Replicated:WaitForChild("CameraRoot");
local u4 = RaycastUtil:FilterFunction("View");
local u5 = RaycastUtil:FilterFunction("HitIgnore");
local u6 = RaycastUtil:FilterFunction("HitMelee");
local u7 = RaycastUtil:FilterFunction("HitMeleeIgnore");
local u8 = nil;
local u9 = nil;
local u10 = nil;
local u11 = nil;
local u12 = nil;
local u13 = nil;
local u14 = nil;
local u15 = nil;
local u16 = nil;
local u17 = nil;
local u18 = nil;
local u19 = nil;
local u20 = nil;
local u21 = nil;
local u22 = {
    Local = {},
    Global = {},
    Camera = {}
};
local u23 = 0;
local u24 = 0;
local u25 = 0.0135;
local u26 = 0.0025;
local u27 = 0.015;
local u28 = 0.006;
local u29 = CFrame.new();
local u30 = CFrame.new();
local u31 = CFrame.new();
local u32 = false;
local u33 = false;
local u34 = tick();
local u35 = tick();
local u36 = CFrame.new();
local u37 = 0;
local u38 = 0;
local u39 = 1;
local u40 = 1;
local u41 = 7;
local u42 = false;
local u43 = 1;
local u44 = {};
local u45 = nil;
local u46 = nil;
local u47 = nil;
local u48 = "None";
local u49 = "None";
local u50 = false;
local u51 = false;
local u52 = false;
local u53 = 0;
local u54 = 0;
local u55 = 0;
local u56 = 0;
local u57 = 0;
local u58 = nil;
local u59 = 0;
local u60 = 0;
local u61 = 0;
local u62 = 0;
local u63 = 0;
local u64 = 0;
local u65 = 1;
local u66 = 0;
local u67 = tick();
local u68 = tick();
local u69 = 0;
local u70 = nil;
local u71 = tick();
local u72 = 0;
local u73 = 0;
local u74 = CFrame.new();
local u75 = 1;
local u76 = 1;
local u77 = tick();
local u78 = 0;
local u79 = 0;
local u80 = 0;
local u81 = 0;
local u82 = CFrame.new();
local u83 = 0;
local u84 = 0;
local u85 = {
    Code = nil,
    Pos = Vector3.new(),
    Rot = Vector3.new()
};
local u86 = tick();
local u87 = CFrame.new();
local u88 = 1;
local u89 = false;
local u90 = false;
local u91 = 0;
local u92 = 1;
local u93 = true;
local Size = Scope.Size;
local u94 = 0;
local u95 = nil;
local u96 = CFrame.new();
local u97 = CFrame.new();
local u98 = CFrame.new();
local u99 = CFrame.new();
local u100 = CFrame.new();
local u101 = false;
local u102 = nil;
local u103 = false;
local u104 = Spring.new((Vector3.new()));
u104.Damper = 0.48;
u104.Speed = 25;
local u105 = Spring.new((Vector3.new()));
u105.Damper = 0.55;
u105.Speed = 25;
local u106 = Spring.new((Vector3.new()));
u106.Damper = 0.6;
u106.Speed = 20;
local u107 = nil;
local u108 = Spring.new((Vector3.new()));
u108.Damper = 0.6;
u108.Speed = 20;
local u109 = 0;
local u110 = 0;
local u111 = 1;
local u112 = CFrame.new();
local u113 = Vector3.new();
local u114 = Spring.new((Vector3.new()));
u114.Damper = 0.36;
u114.Speed = 25;
local u115 = nil;
local u116 = Spring.new((Vector3.new()));
u116.Damper = 0.2;
u116.Speed = 40;
local u117 = nil;

local function _(p118) -- Line: 251
    local v119 = InventoryController.Fetch:Invoke();

    if not v119 then
        return;
    end;

    local Toolbar2 = v119.Toolbar;

    if Toolbar2 then
        local v120 = Toolbar2[p118 or script:GetAttribute("Equipped")];

        if v120 == nil then
            v120 = false;
        elseif v120 == 0 then
            v120 = false;
        end;

        return v120;
    end;
end;

local function u132(p121) -- Line: 260
    -- upvalues: SettingsModule (copy), u9 (ref), Humanoid (copy), u93 (ref), u20 (ref), TableUtil (copy)
    if not SettingsModule.GetSetting("Graphics", "Bullet Casings") then
        return;
    end;

    local v122 = VFX_STORAGE[p121.Type];

    if not (v122 and (u9 and (Humanoid and (Humanoid.Parent and u93)))) then
        return;
    end;

    if not u20 then
        warn("CasingRelease not found in VM.");

        return;
    end;

    local v123 = StateController:GetAttribute("Direction");
    local v124 = p121.ExtraMoveVelocities or { 0, 0 };
    local v125 = (v123:find("Left") and v124[1] or (v123:find("Right") and v124[2] or 0)) * (Humanoid.WalkSpeed / 10);
    local v126 = v122:Clone();
    local PrimaryPart = v126.PrimaryPart;
    v126:PivotTo(u20.CFrame * p121.Offset);
    PrimaryPart.Velocity = PrimaryPart.CFrame.RightVector * (TableUtil:TableRandom(p121.Velocity) + v125);
    local RotationVariance = p121.RotationVariance;
    local v127 = math.random(-RotationVariance * 10, RotationVariance * 10) / 10;
    local v128 = math.random(-RotationVariance * 10, RotationVariance * 10) / 10;
    local v129 = math.random(-RotationVariance * 10, RotationVariance * 10) / 10;
    PrimaryPart.RotVelocity = Vector3.new(v127, v128, v129);
    local u130 = nil;
    u130 = PrimaryPart.Touched:Connect(function(p131) -- Line: 274
        -- upvalues: PrimaryPart (copy), u130 (ref)
        if not (p131 and (p131.Parent and (p131.CanCollide and (PrimaryPart and PrimaryPart.Parent)))) then
            return;
        end;

        PrimaryPart.Velocity = Vector3.new();
        PrimaryPart.RotVelocity = Vector3.new();
        u130:Disconnect();
    end);
    v126.Parent = VFX_PARTS;
    Debris:AddItem(v126, 6);
end;

local function u148(p133, p134, p135) -- Line: 285
    -- upvalues: u22 (copy), u10 (ref), u8 (ref), Parent (copy), Items (copy), ToolInfo (copy), u132 (copy), u12 (ref), SoundModule (copy)
    for i, _ in pairs(u22) do
        local v136 = {};
        local v137 = i == "Local";
        local v138 = p133[i .. "Anims"];

        if v137 and p135 then
            v138 = p133:FindFirstChild((`LocalAnims{p135}`)) or v138;
        end;

        for _, child in pairs(v138:GetChildren()) do
            local v139 = (i == "Camera" and u10.AnimationController or (v137 and u8 or Parent).Humanoid):LoadAnimation(child);
            v136[child.Name] = v139;

            if v137 then
                v139.KeyframeReached:Connect(function(p140) -- Line: 298
                    -- upvalues: Items (ref), Parent (ref), ToolInfo (ref), u132 (ref), u12 (ref), SoundModule (ref)
                    local v141 = p140 == "Bolt Back" and "BoltBack" or p140;
                    local v142 = InventoryController.Fetch:Invoke();
                    local v143;

                    if v142 then
                        local Toolbar2 = v142.Toolbar;

                        if Toolbar2 then
                            v143 = Toolbar2[script:GetAttribute("Equipped")];

                            if v143 == nil then
                                v143 = false;
                            elseif v143 == 0 then
                                v143 = false;
                            end;
                        else
                            v143 = nil;
                        end;
                    else
                        v143 = nil;
                    end;

                    if not v143 then
                        return;
                    end;

                    local v144 = Items[v143.ID];

                    if not (v144 and (Parent and Parent.PrimaryPart)) then
                        return;
                    end;

                    local Name = v144.Name;
                    local Casing = ToolInfo[Name].Casing;

                    if v141 == "EjectCasing" and Casing then
                        u132(Casing);

                        return;
                    end;

                    if v141 == "ShowLoader" then
                        u12.Python_Loader.Transparency = 0;

                        return;
                    end;

                    if v141 == "HideLoader" then
                        u12.Python_Loader.Transparency = 1;

                        return;
                    end;

                    local v145 = v141 == "Pin" and u12:FindFirstChild("Pin");

                    if v145 then
                        v145.Transparency = 1;
                    end;

                    local v146 = v141:find("Transparency%d") and u12:FindFirstChild((v141:gsub("Transparency", "")));

                    if v146 then
                        v146.Transparency = 0;
                    end;

                    local v147 = Parent.PrimaryPart:FindFirstChild(Name .. v141);

                    if not v147 then
                        return;
                    end;

                    SoundModule:PlaySound(v147, nil, nil, v143.Skin);
                end);
            end;
        end;

        u22[i] = v136;
    end;
end;

local function u152(p149) -- Line: 338
    -- upvalues: u22 (copy)
    if not u22.Local[p149] then
        local _ = u22.Global[p149];
    end;

    for _, v in pairs({ "Local", "Global" }) do
        local v150 = u22[v];

        if v150 then
            local v151 = v150[p149];

            if v151 == nil and v150[p149 .. "1"] then
                for i = 1, 100 do
                    v151 = v150[p149 .. i];

                    if not v151 then
                        break;
                    end;

                    if v151.IsPlaying then
                        return true;
                    end;
                end;
            end;

            if v151 then
                return v151.IsPlaying;
            end;
        end;
    end;

    return false;
end;

local function u160(p153, p154, p155, p156) -- Line: 361
    -- upvalues: u152 (copy), u22 (copy)
    local v157 = u152(p153);
    local v158 = nil;

    for i, v in pairs(u22) do
        local v159 = v[p153];

        if v159 == nil and v[p153 .. "1"] then
            for i2 = 1, 100 do
                if not v[p153 .. i2] then
                    v159 = v[p153 .. math.random(1, i2 - 1)];
                    break;
                end;
            end;
        end;

        if v159 ~= nil then
            if not v157 then
                v159:Play(p155 or 0.1, p156 or 1, p154 or 1);
            end;

            if i == "Local" then
                if v157 or not (Run:IsStudio() and p153:find("Reload")) then
                    v158 = v159;
                else
                    print(p153, v159.Length / (p154 or 1));
                    v158 = v159;
                end;
            end;
        end;
    end;

    return v158;
end;

local function u165(p161, p162) -- Line: 386
    -- upvalues: u22 (copy)
    for _, v in pairs(u22) do
        local v163 = v[p161];

        if v163 == nil then
            if v[p161 .. "1"] then
                for i = 1, 100 do
                    local v164 = v[p161 .. i];

                    if not v164 then
                        break;
                    end;

                    v164:Stop();
                end;
            end;
        else
            v163:Stop(p162);
        end;
    end;
end;

local function u167(p166) -- Line: 402
    -- upvalues: u22 (copy)
    for i, v in pairs(u22) do
        if i ~= "Local" or not p166 then
            for _, v2 in pairs(v) do
                v2:Stop();
            end;
        end;
    end;
end;

local function u170() -- Line: 412
    -- upvalues: u8 (ref), u9 (ref), u37 (ref), u38 (ref), PreferredInputController (copy), u75 (ref), u80 (ref), Scope (copy), Toolbar (copy), u42 (ref), u167 (copy), u22 (copy), u90 (ref), Parent (copy)
    if u8 then
        u8:Destroy();
    end;

    u8 = nil;
    local v168;

    if u9 then
        v168 = u9.Name;
        u9:Destroy();
    else
        v168 = nil;
    end;

    u9 = nil;
    script:SetAttribute("Equipped", 0);
    script:SetAttribute("Using", false);
    script:SetAttribute("CanUse", nil);
    script:SetAttribute("SReduction", nil);
    script:SetAttribute("LocalAmmo", 0);
    u37 = 0;
    u38 = 0;
    local v169 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

    if not v169 then
        u75 = 1;
    end;

    u80 = 0;
    Scope.Visible = false;

    if CameraController:GetAttribute("UI") then
        Toolbar.Visible = true;
    end;

    u42 = false;
    u167(true);
    u22.Local = {};
    u22.Global = {};
    u22.Camera = {};
    WheelController.Close:Invoke("Reload");
    u90 = false;
    local PrimaryPart = Parent.PrimaryPart;

    if PrimaryPart and v168 then
        for _, child in pairs(PrimaryPart:GetChildren()) do
            if child.Name:sub(1, v168:len()) == v168 and v168:sub(v168:len() - 4) ~= "Shoot" then
                child:Stop();
            end;
        end;
    end;
end;

local function _(p171) -- Line: 455
    -- upvalues: u44 (ref), ItemClass (copy)
    if type(p171) ~= "table" then
        return;
    end;

    u44 = ItemClass.AttachmentStats(p171, script:GetAttribute("Aiming"));
end;

local function u180(p172) -- Line: 461
    -- upvalues: u44 (ref), u45 (ref), u46 (ref), u47 (ref), u8 (ref), u22 (copy), u165 (copy), u152 (copy), u160 (copy), WeldModule (copy), u12 (ref), u9 (ref), ItemClass (copy), Items (copy), u18 (ref), VFXModule (copy)
    u44 = {};
    u45 = nil;
    u46 = nil;
    u47 = nil;

    if not u8 then
        return;
    end;

    local v173 = type(p172) == "table";

    if v173 and u22.Local.Loaded then
        local Ammo = p172.Ammo;

        if Ammo and Ammo.Amount > 0 then
            u165("Unloaded", 0);

            if not u152("Loaded") then
                u160("Loaded", 1, 0);
            end;
        else
            u165("Loaded", 0);

            if not u152("Unloaded") then
                u160("Unloaded", 1, 0);
            end;
        end;
    end;

    local v174, v175, v176 = WeldModule:WeldAttachments(u12, p172, nil, nil, nil, u9:GetScale());
    u45 = v174;
    u46 = v175;
    u47 = v176;

    if type(p172) == "table" then
        u44 = ItemClass.AttachmentStats(p172, script:GetAttribute("Aiming"));
    end;

    local v177 = false;

    for _, v in pairs(v173 and p172.Attachments or {}) do
        local v178 = Items[v.ID];

        if v178 and v178.AttachmentType == "Sight" then
            v177 = true;
        else
            local AttachmentStats = v178.AttachmentStats;

            if u18 and (AttachmentStats and AttachmentStats.Toggle) then
                local v179 = u18:FindFirstChild(v178.Name);

                if v179 then
                    if v178.Name == "Weapon Flashlight" then
                        v179.Base.Light.Enabled = v.On;
                    elseif v178.Name:find(" Lasersight") then
                        local Laser = v179.Laser;
                        Laser.Laser.Enabled = v.On;

                        if v.On then
                            VFXModule:InitializeLaser(Laser);
                        end;
                    end;
                end;
            end;
        end;
    end;

    if u22.Local.SightFix then
        if v177 and not u152("SightFix") then
            u160("SightFix");

            return;
        end;

        if not v177 and u152("SightFix") then
            u165("SightFix");
        end;
    end;
end;

local function u190() -- Line: 514
    -- upvalues: u9 (ref), u13 (ref), WeldModule (copy)
    if not (u9 and (u13 and u13.Parent)) then
        return;
    end;

    local v181 = Player:GetAttribute("ArmorSleeves") or "";
    local v182 = string.split(v181, "^");
    local v183 = u9:GetScale();

    for _, child in pairs(u13:GetChildren()) do
        local Name = child.Name;

        if Name:sub(1, 5) == "Armor" and child:IsA("Model") then
            local v184 = Name:sub(6);
            local v185 = false;

            for _, v in pairs(v182) do
                if v == v184 then
                    v185 = true;
                    break;
                end;
            end;

            if not v185 then
                child:Destroy();
            end;
        end;
    end;

    for _, v in pairs(v182) do
        if v and v ~= "" then
            local v186, v187 = unpack(string.split(v, "/"));
            local v188 = Sleeves[v186][v187]:Clone();

            if v183 ~= 1 then
                v188:ScaleTo(v183);
            end;

            local v189 = WeldModule:FullyWeldModels(v188, u13, true);

            for _, v2 in pairs(v189) do
                v2.Name = "Armor:" .. v;
            end;
        end;
    end;
end;

local function v191() -- Line: 550
    -- upvalues: u103 (ref)
    u103 = true;
end;

local function u212(p192, p193, p194) -- Line: 554
    -- upvalues: Items (copy), u22 (copy), u8 (ref), u170 (copy), Humanoid (copy), ToolInfo (copy), u11 (ref), u12 (ref), u13 (ref), u14 (ref), u18 (ref), u16 (ref), u17 (ref), u20 (ref), u19 (ref), u15 (ref), u31 (ref), u21 (ref), WeldModule (copy), u9 (ref), Parent (copy), u148 (copy), u180 (copy), u103 (ref), SettingsModule (copy), Highlight (copy), u36 (ref), SoundModule (copy), u93 (ref), u48 (ref), u49 (ref), u52 (ref), u160 (copy)
    local v195 = InventoryController.Fetch:Invoke();
    local v196;

    if v195 then
        local Toolbar2 = v195.Toolbar;

        if Toolbar2 then
            v196 = Toolbar2[p192 or script:GetAttribute("Equipped")];

            if v196 == nil then
                v196 = false;
            elseif v196 == 0 then
                v196 = false;
            end;
        else
            v196 = nil;
        end;
    else
        v196 = nil;
    end;

    local v197;

    if v196 then
        v197 = Items[v196.ID];
    else
        v197 = v196;
    end;

    local v198;

    if v197 then
        v198 = v197.Type == "Bench" and "Blueprint" or v197.Name;
    else
        v198 = v197;
    end;

    local v199 = script:GetAttribute("Equipped");

    if v199 > 0 and (u22.Local.Idle == nil and u22.Global.Idle or u8 and (v199 ~= p192 or v197 and u8.Name ~= v197.Name)) then
        u170();
    end;

    if not v196 or (not Humanoid.Parent or Humanoid.Health <= 0) then
        return;
    end;

    local v200 = ToolInfo[v198];
    local v201 = VMs:FindFirstChild(v198);

    if not (v201 and v200) then
        return;
    end;

    local Weapon = v200.Weapon;
    local Offsets = v200.Offsets;
    local Skin = v196.Skin;
    local v202 = v201:FindFirstChild(Skin) or v201:FindFirstChild("Default");
    local v203 = nil;

    if v202 then
        v202 = v202:Clone();
        v202.Name = v198;
        v202:SetAttribute("_", true);
        u11 = v202:WaitForChild("HumanoidRootPart");
        u12 = v202:WaitForChild("Weapon");
        u13 = v202:WaitForChild("Arms");
        u14 = u13:WaitForChild("RightArm");
        u18 = u12:FindFirstChild("Attachments");
        u16 = u12:FindFirstChild("AimFront");
        u17 = u12:FindFirstChild("AimBack");
        u20 = u12:FindFirstChild("CasingRelease");
        u19 = u12:FindFirstChild("FlashPart");
        u15 = u12:FindFirstChild("Handle") or u12.Main;
        u31 = Offsets[`Local{Skin}`] or Offsets.Local;
        u21 = Offsets.RootPartBased;

        if u17 then
            u17.CFrame = CFrame.new(u17.Position, u16.Position) * (Offsets.SightBack or CFrame.new());
            WeldModule:WeldParts(u17, u15);
        end;

        u9 = v202;
        u8 = v202;

        for _, v in pairs(u13 and u13:GetChildren() or {}) do
            if v:IsA("BasePart") then
                local v204 = Parent:FindFirstChild(v.Name:find("Left") and "LeftUpperArm" or "RightUpperArm");

                if v204 then
                    v.Color = v204.Color;
                end;
            end;
        end;

        u9 = v202;
        u8 = v202;
        v202.Parent = Camera;
        u148(v201, p193, Skin);
        u180(v196);
        u103 = true;
        local v205 = SettingsModule.GetSetting("Graphics", "Outline Transparency");

        if SettingsModule.GetSetting("Graphics", "Toggle Outline") == true and v205 < 1 then
            v203 = Highlight:Clone();
            v203.OutlineTransparency = v205;
            v203.Parent = u9;
            v203.Enabled = true;
        end;

        u36 = u17 and u11.CFrame:ToObjectSpace(u17.CFrame):inverse() or Offsets.Aim;

        if Parent.PrimaryPart then
            local Equip = Parent.PrimaryPart:FindFirstChild("Equip");

            if Equip then
                SoundModule:PlaySound(Equip);
            end;
        end;
    else
        u148(v201, p193);
    end;

    local v206 = script;
    local v207;

    if type(Weapon) == "table" then
        v207 = Weapon.CanSprintWhileAttacking;
    else
        v207 = false;
    end;

    v206:SetAttribute("CanUse", v207);
    local v208 = script;
    local v209;

    if type(Weapon) == "table" then
        v209 = Weapon.SReduction;
    else
        v209 = false;
    end;

    v208:SetAttribute("SReduction", v209);
    script:SetAttribute("Equipped", p192);
    local Ammo = v196.Ammo;
    script:SetAttribute("LocalAmmo", Ammo and Ammo.Amount or 0);

    for _, child in pairs(VM_PARTS:GetChildren()) do
        if child ~= v202 then
            child:Destroy();
        end;
    end;

    u93 = true;
    u48 = "None";
    u49 = "None";
    u52 = false;
    u160("Idle");
    local v210;

    if Weapon then
        local v211;

        if type(Weapon.EquipAnimSpeed) == "table" then
            v211 = Weapon.EquipAnimSpeed[v196.Skin or "Default"] or Weapon.EquipAnimSpeed.Default;
        else
            v211 = Weapon.EquipAnimSpeed;
        end;

        v210 = v211 or 1;
    else
        v210 = 1;
    end;

    u160("Equip", v210 * (p194 or 1));
    task.wait(0.1);

    if v202 and v202.Parent then
        v202.Parent = VM_PARTS;

        if v203 and v203.Parent then
            v203.Adornee = u9;
        end;
    end;
end;

local function u216(p213) -- Line: 673
    -- upvalues: u93 (ref), u9 (ref), u13 (ref), u12 (ref), u18 (ref)
    if p213 == u93 or not u9 then
        return;
    end;

    local v214 = {};

    for _, child in pairs(u13:GetChildren()) do
        if child:IsA("Model") then
            table.insert(v214, child);
        end;
    end;

    for _, v in pairs({
        u13,
        u12,
        u18 and u18:GetChildren() or {},
        unpack(v214)
    }) do
        for _, v2 in pairs(type(v) == "table" and v and v or { v }) do
            for _, child in pairs(v2:GetChildren()) do
                if child:IsA("BasePart") then
                    local v215 = child:GetAttribute("OrigTrans");

                    if v215 then
                        if child.Name == "RailExtender" then
                            child.LocalTransparencyModifier = p213 and 0 or 1;
                        else
                            child.Transparency = p213 and v215 and v215 or 1;
                        end;

                        if child.Name == "Bolt" then
                            for _, child2 in pairs(child:GetChildren()) do
                                if child2:IsA("Beam") then
                                    child2.Enabled = p213;
                                end;
                            end;
                        end;
                    elseif child.Transparency ~= 1 then
                        v215 = child.Transparency;
                        child:SetAttribute("OrigTrans", v215);

                        if child.Name == "RailExtender" then
                            child.LocalTransparencyModifier = p213 and 0 or 1;
                        else
                            child.Transparency = p213 and v215 and v215 or 1;
                        end;

                        if child.Name == "Bolt" then
                            for _, child2 in pairs(child:GetChildren()) do
                                if child2:IsA("Beam") then
                                    child2.Enabled = p213;
                                end;
                            end;
                        end;
                    end;
                end;
            end;
        end;
    end;

    u93 = p213;

    return true;
end;

local function _(p217, p218, p219) -- Line: 709
    -- upvalues: u85 (copy)
    u85.Code = math.random(1, 100000000);
    u85.X = 0;
    u85.Increment = 1.5 / p219;
    u85.PrevPos = u85.Pos;
    u85.PrevRot = u85.Rot;
    u85.NewPos = p217;
    u85.NewRot = p218;
end;

local function u233(p220, p221) -- Line: 719
    -- upvalues: u109 (ref), u110 (ref), u111 (ref), u108 (copy), u113 (ref)
    if not p220 then
        return;
    end;

    local v222 = (p220.Strength or Vector3.new(1, 1, 1)) * (p221 or 1);
    local v223 = p220.Speed or 1;
    local v224 = p220.Angles or { -75, 75 };
    local _ = p220.SnapBack;
    local v225 = p220.DelayTime or 0;

    if v222 == 0 or v223 <= 0 then
        return;
    end;

    if v225 > 0 then
        task.wait(v225);
    end;

    u109 = 0;
    u110 = 0;
    u111 = 0.15 * v223;
    local v226 = math.random(v224[1], v224[2]);
    local v227 = math.rad(v226);
    local v228 = math.sin(v227) / 300 * v222.X;
    local v229 = math.cos(v227) / 225 * v222.Y;
    local v230 = math.random(-15, 15);
    local v231 = math.rad(v230) / 15 * v222.Z;
    local v232 = -0.005235987755982988 * v222.Y;
    u108.Damper = 0.6;
    u108.Speed = 20;
    u113 = Vector3.new(v228, v229, v231);
    task.wait(0.15 * v223);
    u108.Damper = 0.4;

    if p220.SnapBack then
        u108.Speed = 30;
        u113 = Vector3.new(-v228, -v229 + v232, -v231);
        task.wait(0.15 * v223);
        u108.Speed = 20;
        u113 = Vector3.new(0, -v232, 0);
        task.wait(0.175 * v223);
    end;

    u113 = Vector3.new();
end;

local function u236(p234) -- Line: 754
    -- upvalues: u76 (ref), HitMarker (copy), TweenUtil (copy)
    Sound:PlayLocalSound(Sound[p234]);
    u76 = 0;
    HitMarker.Rotation = math.random(430, 470) / 10;
    local v235 = p234 == "HitHead";

    for _, child in pairs(HitMarker:GetChildren()) do
        if not HitMarker.Visible then
            child.BackgroundColor3 = Color3.new(1, 1, 1);
        end;

        TweenUtil:Tween(child, "BackgroundColor3", v235 and Color3.new(1, 0, 0) or Color3.new(1, 1, 1), 0.09, "Quart", "In");
    end;
end;

local function _(p237) -- Line: 776
    return p237.X ^ 2 + p237.Y ^ 2 + p237.Z ^ 2;
end;

local function u243(p238, p239, p240) -- Line: 780
    -- upvalues: u8 (ref), u9 (ref), u243 (ref)
    if not (u8 and u9) then
        return;
    end;

    local HumanoidRootPart = u8.HumanoidRootPart;
    local HumanoidRootPart2 = u9.HumanoidRootPart;

    for _, child in pairs(p238:GetChildren()) do
        local v241 = p239:FindFirstChild(child.Name);

        if v241 then
            if child.Name ~= "HumanoidRootPart" and (child:IsA("BasePart") and v241:IsA("BasePart")) then
                local v242 = HumanoidRootPart.CFrame:ToObjectSpace(child.CFrame);
                v241.CFrame = HumanoidRootPart2.CFrame * v242;
            end;

            u243(child, v241, p240);
        end;
    end;
end;

local function u261(p244, p245, p246, p247) -- Line: 819
    -- upvalues: u3 (copy), u236 (copy), VFXModule (copy)
    local v248 = p244[1];
    local v249 = p244[2];
    local v250 = p244[3];
    local v251 = p244[4];
    local v252 = p244[5];
    local v253 = p244[6];
    local v254 = p244[7] or {};
    local v255 = v248 and v248.Parent;

    if v255 then
        if v249 then
            v249 = v248.CFrame:PointToObjectSpace(v249);
        end;
    else
        v249 = v255;
    end;

    if v251 then
        v251 = v251.Name;
    end;

    if v249 and (v250 and v249 == v250) then
        return;
    end;

    local v256 = {
        v253,
        v252,
        v251,
        v250,
        v249 or "nil",
        v248
    };

    if p244[8] or p244[9] then
        v256[7] = p244[8];
        v256[8] = p244[9];
    end;

    u3("Fire", "d\147e\1R\169#o\249,9\133\153`B4q^W\6", "\160\29\229\248\31\16pJ\140]\137-\250\171Z_\1\135\223#", unpack(v256));

    if not (v248 and v248.Parent) then
        return;
    end;

    local v257 = v248.Parent:FindFirstChild("Humanoid") or v248.Parent.Parent:FindFirstChild("Humanoid");
    local v258;

    if p246 == true then
        v258 = true;
    elseif p246 then
        v258 = p246 ~= "Stick";
    else
        v258 = p246;
    end;

    if not v257 then
        if not v258 then
            if p245 and (p245[1] and p245[1].Parent) then
                p244 = p245 or p244;
            end;

            task.defer(VFXModule.CreateHole, VFXModule, p244[1], p244[2], p244[3], p244[4], nil, p246 == "Stick");
        end;

        return;
    end;

    local v259 = v254[v257];
    local v260 = v248.Name == "Head" and "HitHead" or "Hit";

    if not v259 then
        v259 = {};
        v254[v257] = v259;
    end;

    if not v259[v260] then
        v259[v260] = true;

        if not p247 then
            u236(v260);
        end;
    end;

    if v258 then
        return;
    end;

    task.defer(VFXModule.CreateBlood, VFXModule, unpack(p244));
end;

local function u271(p262, p263, p264, p265) -- Line: 870
    -- upvalues: u9 (ref), u170 (copy), u212 (copy)
    local v266 = p265 or tick();
    local v267;

    if p263.Amount == 1 then
        v267 = true;
    else
        v267 = false;
    end;

    while tick() - v266 < p262 and u9 == u9 do
        task.wait();
    end;

    local v268 = InventoryController.Fetch:Invoke();
    local v269;

    if v268 then
        local Toolbar2 = v268.Toolbar;

        if Toolbar2 then
            v269 = Toolbar2[script:GetAttribute("Equipped")];

            if v269 == nil then
                v269 = false;
            elseif v269 == 0 then
                v269 = false;
            end;
        else
            v269 = nil;
        end;
    else
        v269 = nil;
    end;

    if v269 then
        if v269.ID == p263.ID then
            if v267 and v269.Amount == 1 then
                u170();

                return;
            end;

            local v270 = script:GetAttribute("Equipped");
            u170();
            u212(v270, nil, p264);
        end;
    else
        u170();
    end;
end;

function ChooseRandom(p272)
    local v273 = math.random(1, 100);
    local v274 = 0;

    for i, v in p272 do
        v274 = v274 + v[1];

        if v274 >= v273 then
            return math.random(v[2] * 100, v[3] * 100) / 100, i;
        end;
    end;
end;

local u275 = nil;
local u276 = nil;

local function u455(u277) -- Line: 905
    -- upvalues: u32 (ref), u35 (ref), u102 (ref), Items (copy), u152 (copy), u90 (ref), ToolInfo (copy), Parent (copy), SoundModule (copy), Humanoid (copy), u49 (ref), u67 (ref), u33 (ref), u48 (ref), u275 (ref), u50 (ref), u276 (ref), u51 (ref), u12 (ref), u160 (copy), u9 (ref), u44 (ref), u165 (copy), u132 (copy), u47 (ref), u19 (ref), VFXModule (copy), u77 (ref), u79 (ref), u78 (ref), RaycastUtil (copy), u5 (copy), u261 (copy), u3 (copy), TableUtil (copy), u85 (copy), u83 (ref), u84 (ref), u86 (ref), PreferredInputController (copy), u82 (ref), u233 (copy), u52 (ref), u22 (copy), u15 (ref), u4 (copy), u271 (copy), u6 (copy), u7 (copy), u116 (copy)
    if WheelController:GetAttribute("Open") then
        return;
    end;

    u32 = true;

    if script:GetAttribute("Using") then
        u35 = tick();

        return;
    end;

    if u102 then
        task.cancel(u102);
    end;

    u102 = task.spawn(function() -- Line: 916
        -- upvalues: u32 (ref), Items (ref), u152 (ref), u90 (ref), ToolInfo (ref), Parent (ref), SoundModule (ref), Humanoid (ref), u49 (ref), u67 (ref), u33 (ref), u48 (ref), u275 (ref), u50 (ref), u276 (ref), u51 (ref), u12 (ref), u160 (ref), u9 (ref), u44 (ref), u165 (ref), u132 (ref), u47 (ref), u19 (ref), VFXModule (ref), u77 (ref), u79 (ref), u78 (ref), RaycastUtil (ref), u5 (ref), u261 (ref), u3 (ref), TableUtil (ref), u85 (ref), u83 (ref), u84 (ref), u86 (ref), PreferredInputController (ref), u82 (ref), u233 (ref), u52 (ref), u22 (ref), u15 (ref), u277 (copy), u4 (ref), u271 (ref), u6 (ref), u7 (ref), u116 (ref), u35 (ref)
        local v278 = false;
        local v279 = false;
        local v280 = false;

        while true do
            local u281, u282, v283, v284, v285, v286, v287, v288, v289, v290, v291, v292, u293, u294, v295, v296, v297, v298, v299, v300, v301, v302, v303, v304, v305, v306, v307, v308, v309, v310, v311, u312, v313, v314, v315, v316, v317, v318, v319, u320, v321, v322, v323, v324, u325, v326, v327, v328, v329, v330, v331, v332, v333, v334, v335, v336, u337, v338, v339, v340, v341, v342, v343, v344, u345, u346, v347, u348, u349, u350, u351, u352, u353, u354, v355, v356, v357, v358, v359, v360;

            while true do
                if not (u32 or v280) then
                    script:SetAttribute("Using", false);

                    return;
                end;

                local v361 = InventoryController.Fetch:Invoke();

                if v361 then
                    local Toolbar2 = v361.Toolbar;

                    if Toolbar2 then
                        u281 = Toolbar2[script:GetAttribute("Equipped")];

                        if u281 == nil or u281 == 0 then
                            u281 = false;
                        end;
                    else
                        u281 = nil;
                    end;
                else
                    u281 = nil;
                end;

                u282 = nil;
                local v362;

                if u281 then
                    v362 = u281.Ammo;
                    v283 = Items[u281.ID];
                else
                    v362 = nil;
                    v283 = nil;
                end;

                if v362 then
                    u282 = Items[v362.ID].AmmoStats;
                end;

                v284 = script:GetAttribute("LocalAmmo");

                if v283 and (v283.Type ~= "Bench" and (not u152("Equip") and (not u90 and (not InventoryController:GetAttribute("Open") and (u281 and (not v283.MaxDurability or u281.Durability > 0)))))) then
                    local Type = v283.Type;
                    local Name = v283.Name;
                    v285 = ToolInfo[Name];

                    if not v285 then
                        return;
                    end;

                    v286 = v285.Weapon;

                    if v286 and v286.CustomUse then
                        return;
                    end;

                    local v363;

                    if v286 == nil then
                        v363 = false;
                    else
                        v363 = v286.ThrowInfo;
                    end;

                    if v286 == nil then
                        v287 = false;
                    else
                        v287 = v286.IsBow;
                    end;

                    local Melee = v285.Melee;
                    v288 = v285.Shake;

                    if Type == "Gun" and (Parent.PrimaryPart and (v279 == false and (v286 and (v286.IgnoreEmptyClick ~= true and (v362 == nil or v284 <= 0))))) then
                        local GunEmpty = Parent.PrimaryPart:FindFirstChild("GunEmpty");

                        if GunEmpty then
                            SoundModule:PlaySound(GunEmpty);
                            v279 = true;
                        end;
                    end;

                    if (Type ~= "Gun" or (v362 == nil or v284 <= 0)) and (Type ~= "Tool" or not (v286 and v286.Cooldown)) or (Humanoid.SeatPart ~= nil and Humanoid.SeatPart.Name == "VehicleSeat" or (not v287 or u49 ~= "Holding" and u49 ~= "NoneJump" or WaterController:GetAttribute("IsSwim")) and (v287 or not (Melee and Melee.MeleeChecks) and tick() - u67 < 0.1)) then
                        Run.Heartbeat:Wait();
                        v278 = false;
                        goto l0;
                    end;

                    local v364;

                    if v286.AimDownSpeed == nil or (not v363 or (u33 == false or u48 == "Holding")) then
                        v364 = Type ~= "Gun" and true or not CameraController:GetAttribute("ViewmodelCFrame");
                    else
                        v364 = false;
                    end;

                    script:SetAttribute("Using", v364);

                    if Type == "Gun" then
                        CameraController:SetAttribute("FreeLooking", false);
                    end;

                    if not v364 then
                        Run.Heartbeat:Wait();
                        v278 = false;
                        goto l0;
                    end;

                    if v286.RequiresAim then
                        v280 = true;

                        if not v278 then
                            v278 = true;

                            if not u33 then
                                task.spawn(u275, "Auto");
                            end;
                        end;

                        if u50 then
                            if u33 == "Auto" then
                                u276();
                            else
                                u51 = true;
                                task.delay(0.7, function() -- Line: 983
                                    -- upvalues: u51 (ref)
                                    u51 = false;
                                end);
                            end;

                            goto l2;
                        end;

                        Run.Heartbeat:Wait();
                    else
                        local v365 = 0;

                        while true do
                            if v365 == 0 then
                                v365 = -1;
                                local v366, v367, v368, v369, v370, u371, v372, v373, v374, v375, v376, v377, v378, v379, v380, v381, v382, v383, v384, v385, v386, v387, v388, v389, v390, v391, v392, v393, u394, v395, u396, u397, u398, u399, v400, v401, v402, v403, v404, v405, v406, v407, v408, v409, v410, v411, v412, v413, v414, v415, v416, v417, u418, u419, u420, u421, u422, u423, u424, v425, v426, v427, v428;

                                if Name == "Salvaged Shotgun" then
                                    local Fuse = u12:FindFirstChild("Fuse");

                                    if Fuse and u160("Light") then
                                        local v429 = u9;
                                        task.wait(0.5);

                                        if u9 == v429 and (u9 and (u9.Parent and Fuse.Parent)) then
                                            for _, child in Fuse.Effect:GetChildren() do
                                                child.Enabled = true;
                                            end;

                                            local v430 = ChooseRandom({ { 15, 0.25, 0.5 }, { 20, 0.5, 1 }, { 35, 1, 1.5 }, { 15, 2, 2 }, { 15, 2.5, 3 } });
                                            local v431 = ChooseRandom({ { 45, 0, 0 }, { 25, 0, 0.5 }, { 20, 0.5, 1 }, { 10, 1.5, 2 } });
                                            local v432 = 0;

                                            while v432 < v430 do
                                                v432 = v432 + task.wait(0.03333333333333333);

                                                if u9 ~= v429 or not (u9 and (u9.Parent and Fuse.Parent)) then
                                                    v432 = false;
                                                    break;
                                                end;

                                                local v433 = math.clamp(v432 / v430, 0, 1);
                                                local v434 = math.floor(v433 / 0.2);
                                                local v435 = Fuse[tostring(v434 + 1)];
                                                local v436 = math.ceil(v433 / 0.2) + 1;
                                                local v437 = Fuse[tostring(v436)];
                                                Fuse.Effect.CFrame = v435.CFrame:Lerp(v437.CFrame, (v433 - v434 * 0.2) / 0.2);
                                            end;

                                            if v432 then
                                                local v438 = Parent.PrimaryPart:FindFirstChild(v283.Name .. "Fuse");

                                                if v438 then
                                                    SoundModule:StopSound(v438);
                                                end;

                                                for _, child in Fuse.Effect:GetChildren() do
                                                    child.Enabled = false;
                                                end;

                                                if v431 > 0 then
                                                    task.wait(v431);

                                                    if u9 == v429 and (u9 and (u9.Parent and Fuse.Parent)) then
                                                        if Type == "Gun" then
                                                            v289 = v285.Spread;
                                                            v290 = v285.Bullet;
                                                            v291 = v285.Casing;
                                                            v292 = v285.Recoil;
                                                            u293 = v292.VM;
                                                            u294 = v292.Camera;
                                                            v295 = 1 - (u44.FireRateMult or 0);
                                                            v296 = 60 / v286.RPM * v295;
                                                            v297 = 60 / v286.BurstRPM * v295;

                                                            for i = 1, v286.Burst do
                                                                u165("Inspect", 0);
                                                                u165("Shoot", 0);
                                                                u160("Shoot", 1, 0);

                                                                if v291 and not v291.IgnoreShoot then
                                                                    u132(v291);
                                                                end;

                                                                v298 = script:GetAttribute("Aiming");
                                                                v299 = u47 or u19;

                                                                if not (u44.Scope and v298) then
                                                                    VFXModule:FlashPart(v299);
                                                                end;

                                                                v300 = Parent.PrimaryPart:FindFirstChild(v283.Name .. "Shoot");

                                                                if v300 then
                                                                    SoundModule:PlayDuplicateSound(v300, nil, nil, true, u281.Skin);
                                                                end;

                                                                u77 = tick();
                                                                v301 = u281.Skin == "Hot Rod" and 0.75 or 1;
                                                                v302 = 1 + (v298 and u44.GunRecoilAimMult or 0);
                                                                v303 = v289[v298 and "Aiming" or "Hip"].ShootingExtra * (1 + (u44[(v298 and "Aim" or "Hip") .. "SpreadMult"] or 0)) * (u79 < 0.001 and 0 or u79) * (u282[(v298 and "Aim" or "Hip") .. "SpreadMult"] or 1);
                                                                u79 = math.min(u79 + 1 / v289.Shooting.BulletsForMax, 1);
                                                                v304 = u78 < 0.001 and 0 or math.floor(u78 * 100) / 100;
                                                                v305 = v303 < 0.001 and 0 or math.floor(v303 * 100) / 100;
                                                                v306 = v304 + v305;
                                                                v307 = CFrame.Angles(v290.Offset or 0, 0, 0);
                                                                v308 = Camera.CFrame;
                                                                v309 = workspace:GetServerTimeNow();
                                                                v310 = math.round(v309 * 10000);
                                                                v311 = Random.new(v310);
                                                                u312 = v311.NextInteger(v311, 1, 1000000000);
                                                                v313 = Random.new(v310);
                                                                v314 = {};

                                                                for _ = 1, u282.Bullets or 1 do
                                                                    v315 = {
                                                                        Radius = v313:NextNumber(0, math.floor(v306 * 100) / 100) / 500,
                                                                        Degree = v313:NextNumber(0, 6.283185307179586)
                                                                    };
                                                                    v316 = math.floor(v306 * 100) / 100;
                                                                    v317 = math.max(1, v316) * 1000000000;
                                                                    v315.ID = v313:NextInteger(1, (math.ceil(v317)));
                                                                    table.insert(v314, v315);
                                                                end;

                                                                v318 = v299.Position;
                                                                v319 = Parent.PrimaryPart.CFrame * CFrame.new(0, 1.5, 0);
                                                                u320 = {};
                                                                v321, v322 = RaycastUtil:MouseRaycast(u5, { Parent, VFX_PARTS });

                                                                if u44.HideTracer then
                                                                    v323 = "";
                                                                elseif table.find(VFXModule.TracerSkins, u281.Skin) then
                                                                    v323 = u281.Skin .. "Bullet";
                                                                else
                                                                    v323 = u282.TracerName;
                                                                end;

                                                                for _, v in pairs(v314) do
                                                                    v324 = v307 * CFrame.Angles(math.sin(v.Degree) * v.Radius, math.cos(v.Degree) * v.Radius, 0);
                                                                    u325 = v.ID;
                                                                    VFXModule:CreateProjectile({
                                                                        FilterType = "Blacklist",
                                                                        Position = v318,
                                                                        Direction = (CFrame.new(v318, v321) * v324).LookVector,
                                                                        PositionFirst = v319.p,
                                                                        DirectionFirst = (v308 * v324).LookVector,
                                                                        Filters = {
                                                                            Parent,
                                                                            VFX_PARTS,
                                                                            Drops,
                                                                            Plants
                                                                        },
                                                                        FilterFunction = u282.FilterType or "Hit",
                                                                        VisualizeRay = script:GetAttribute("DebugShowRays"),
                                                                        Speed = v290.Speed * (1 + (u44.SpeedMult or 0)) * (u282.SpeedMult or 1),
                                                                        Gravity = v290.Gravity * (u282.GravityMult or 1),
                                                                        MaxRange = v290.MaxRange * (1 + (u44.RangeMult or 0)) * (u282.RangeMult or 1),
                                                                        Size = u282.BulletSize,
                                                                        TracerName = v323,

                                                                        HitFunction = function(...) -- Line: 1119, Name: HitFunction
                                                                            -- upvalues: u261 (ref), u312 (copy), u325 (copy), u320 (copy), u282 (ref)
                                                                            local v439 = { ... };
                                                                            u261({
                                                                                v439[1],
                                                                                v439[2],
                                                                                v439[3],
                                                                                v439[4],
                                                                                u312,
                                                                                u325,
                                                                                u320
                                                                            }, nil, u282.Impact);
                                                                        end,

                                                                        MissFunction = function() -- Line: 1123, Name: MissFunction
                                                                            -- upvalues: u3 (ref), u325 (copy), u312 (copy)
                                                                            u3("Fire", "d\147e\1R\169#o\249,9\133\153`B4q^W\6", "\160\29\229\248\31\16pJ\140]\137-\250\171Z_\1\135\223#", u325, u312);
                                                                        end
                                                                    });
                                                                end;

                                                                v284 = v284 - 1;
                                                                script:SetAttribute("LocalAmmo", v284);
                                                                u3("Fire", "d\147e\1R\169#o\249,9\133\153`B4q^W\6", "#\250)\215\28\1U\143\237}\154\218\231Cl-\15H\1\147", v309, v283.Name, v308, v319:PointToObjectSpace(v318), v319, v304, v305, v321);
                                                                v326 = TableUtil:TableRandom(u293.Pos.X);
                                                                v327 = TableUtil:TableRandom(u293.Pos.Y);
                                                                v328 = Vector3.new(v326, v327, TableUtil:TableRandom(u293.Pos.Z)) * v301;
                                                                v329 = TableUtil:TableRandom(u293.Rot.Y);
                                                                v330 = math.rad(v329);
                                                                v331 = TableUtil:TableRandom(u293.Rot.X);
                                                                v332 = math.rad(v331) * v302;
                                                                v333 = TableUtil:TableRandom(u293.Rot.Z);
                                                                v334 = math.rad(v333) * v302;
                                                                v335 = Vector3.new(v330, v332, v334) * v301;
                                                                v336 = u293.StartTime;
                                                                u85.Code = math.random(1, 100000000);
                                                                u85.X = 0;
                                                                u85.Increment = 1.5 / v336;
                                                                u85.PrevPos = u85.Pos;
                                                                u85.PrevRot = u85.Rot;
                                                                u85.NewPos = v328;
                                                                u85.NewRot = v335;
                                                                u337 = u85.Code;
                                                                u83 = 0;
                                                                u84 = u84 + 1;
                                                                u86 = tick();
                                                                v338, v339 = u294.RecoilStart(u84);
                                                                v340, v341 = u294.RecoilFinish(u84);
                                                                v342 = v338 + TableUtil:TableRandom(u294.Shake.Y);
                                                                v343 = v339 + TableUtil:TableRandom(u294.Shake.X);
                                                                v344 = -math.rad(v343);
                                                                u345 = math.rad(v342);
                                                                u346 = v344;
                                                                v347 = -math.rad(v341);
                                                                u348 = math.rad(v340);
                                                                u349 = v347;
                                                                u350 = tick();
                                                                u351 = 0;
                                                                u352 = 0;
                                                                u353 = 0;
                                                                u354 = u294.Duration - u294.FinishStart;
                                                                task.spawn(function() -- Line: 1166
                                                                    -- upvalues: u44 (ref), PreferredInputController (ref), u351 (ref), u294 (copy), u345 (ref), u346 (ref), u82 (ref), u353 (ref), u352 (ref), u354 (copy), u348 (ref), u349 (ref), u350 (copy), u293 (copy), u85 (ref), u337 (copy)
                                                                    local v440 = true;
                                                                    local v441 = false;

                                                                    while v440 or not v441 do
                                                                        local v442 = script:GetAttribute("DebugFrameworkSpeed");
                                                                        local v443 = Run.Heartbeat:Wait() * v442;

                                                                        if v440 then
                                                                            local v444 = (script:GetAttribute("Aiming") and 0.7 or 1.2) * (StateController:GetAttribute("IsCrouch") and 0.75 or 1) * (1 + (u44.RecoilMult or 0));
                                                                            local v445 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";
                                                                            local v446 = v444 * (v445 and 0.65 or 1);
                                                                            local v447 = u351;
                                                                            u351 = math.min(u351 + v443, u294.FinishStart);
                                                                            local v448 = (u351 - v447) / u294.FinishStart * v446;
                                                                            local v449 = CFrame.Angles(u345 * v448, u346 * v448, 0);
                                                                            u82 = u82 * v449;
                                                                            Camera.CFrame = Camera.CFrame * v449;
                                                                            local v450 = u353;
                                                                            u352 = math.min(u352 + v443, u294.Duration);
                                                                            u353 = math.clamp(u352 - u294.FinishStart, 0, u354);
                                                                            local v451 = (u353 - v450) / u354 * v446;
                                                                            local v452 = CFrame.Angles(u348 * v451, u349 * v451, 0);
                                                                            u82 = u82 * v452;
                                                                            Camera.CFrame = Camera.CFrame * v452;

                                                                            if tick() - u350 >= u294.Duration / v442 then
                                                                                v440 = false;
                                                                            end;
                                                                        end;

                                                                        if tick() - u350 >= u293.StartTime / v442 and not v441 then
                                                                            v441 = true;

                                                                            if u85.Code == u337 or not u85.Code then
                                                                                local v453 = Vector3.new();
                                                                                local v454 = Vector3.new();
                                                                                local EndTime = u293.EndTime;
                                                                                u85.Code = math.random(1, 100000000);
                                                                                u85.X = 0;
                                                                                u85.Increment = 1.5 / EndTime;
                                                                                u85.PrevPos = u85.Pos;
                                                                                u85.PrevRot = u85.Rot;
                                                                                u85.NewPos = v453;
                                                                                u85.NewRot = v454;
                                                                            end;
                                                                        end;
                                                                    end;
                                                                end);
                                                                task.defer(u233, v288, v298 and 0.4 or 1);

                                                                if v286.BurstRPM > 0 then
                                                                    task.wait(v297);

                                                                    if v284 <= 0 or (u152("Equip") or (InventoryController:GetAttribute("Open") or (CameraController:GetAttribute("ViewmodelCFrame") or tick() - u67 < 0.1))) then
                                                                        script:SetAttribute("Using", false);

                                                                        if not u281 then
                                                                            return;
                                                                        end;

                                                                        break;
                                                                    else
                                                                        v355 = InventoryController.Fetch:Invoke();

                                                                        if v355 then
                                                                            v356 = v355.Toolbar;

                                                                            if v356 then
                                                                                v357 = v356[script:GetAttribute("Equipped")];

                                                                                if v357 == nil then
                                                                                    v357 = false;
                                                                                elseif v357 == 0 then
                                                                                    v357 = false;
                                                                                end;
                                                                            else
                                                                                v357 = nil;
                                                                            end;
                                                                        else
                                                                            v357 = nil;
                                                                        end;

                                                                        if v357 and (u281.Durability ~= nil and u281.Durability > 0) then
                                                                            continue;
                                                                        else
                                                                            break;
                                                                        end;
                                                                    end;
                                                                end;
                                                            end;

                                                            if v287 then
                                                                u165("AimStart");
                                                                u165("AimHold");
                                                                u49 = "None";
                                                                u52 = false;

                                                                for _, child in pairs(u12:GetChildren()) do
                                                                    if child:IsA("BasePart") and child.Name:find("Arrow") then
                                                                        child.Transparency = 1;
                                                                    end;
                                                                end;
                                                            end;

                                                            task.wait(v296);
                                                            v358 = v286.BoltAnimSpeed or 1;

                                                            if not u22.Local.Bolt then
                                                                goto l1;
                                                            end;

                                                            v359 = u9;
                                                            v360 = u160("Bolt", v358);

                                                            if v360 then
                                                                script:SetAttribute("CanUse", true);
                                                                task.wait(v360.Length);
                                                                script:SetAttribute("CanUse", nil);

                                                                if v359 and v359.Parent then
                                                                    u165("Bolt");
                                                                    goto l1;
                                                                end;
                                                            end;
                                                        else
                                                            u165("Inspect", 0);
                                                            u165("Hit", 0.1);
                                                            u165("Miss", 0.1);
                                                            u77 = tick();
                                                            v366, v367 = pcall(function() -- Line: 1251
                                                                return workspace:GetServerTimeNow();
                                                            end);

                                                            if v366 then
                                                                if v363 then
                                                                    v368 = v363.Logic;
                                                                else
                                                                    v368 = v363;
                                                                end;

                                                                if v363 and (v368 ~= "Normal" or u48 == "Holding") then
                                                                    u165("ThrowHold");
                                                                    u165("Aim");
                                                                    v369 = u9;

                                                                    if u22.Local.Light then
                                                                        v370 = u160("Light");

                                                                        if not v370 then
                                                                            script:SetAttribute("Using", false);

                                                                            return;
                                                                        end;

                                                                        u371 = u15:FindFirstChild("Effect");

                                                                        if u371 then
                                                                            task.delay(0.5, function() -- Line: 1269
                                                                                -- upvalues: u371 (copy), u15 (ref)
                                                                                if not (u371 and u371.Parent) then
                                                                                    return;
                                                                                end;

                                                                                for _, child in pairs(u371:GetChildren()) do
                                                                                    child.Enabled = true;
                                                                                end;

                                                                                u15.Fuse:Play();
                                                                            end);
                                                                        end;

                                                                        task.wait(v370.Length);

                                                                        if not (v369 and v369.Parent) then
                                                                            script:SetAttribute("Using", false);

                                                                            return;
                                                                        end;

                                                                        u165("Light");
                                                                    end;

                                                                    v372 = (v368 == "Grenade" or v368 == "PlaceableGrenade") and ({ "ThrowStart", u277 and "UnderHandThrow" or "OverHandThrow" } or { "Throw" }) or { "Throw" };
                                                                    v373 = nil;
                                                                    v374 = nil;

                                                                    for i, v in pairs(v372) do
                                                                        v375 = v363.AnimSpeed or 1;
                                                                        v373 = u160(v, v375);

                                                                        if not v373 then
                                                                            return;
                                                                        end;

                                                                        if i == #v372 then
                                                                            if v368 ~= "Normal" then
                                                                                v374 = tick();
                                                                                task.wait(0.3);

                                                                                if not (v369 and v369.Parent) then
                                                                                    break;
                                                                                end;

                                                                                for _, child in pairs(u12:GetChildren()) do
                                                                                    child.Transparency = 1;
                                                                                    v376 = child:FindFirstChild("Effect");

                                                                                    if v376 then
                                                                                        v376:ClearAllChildren();
                                                                                        v377 = child:FindFirstChild("Fuse");

                                                                                        if v377 then
                                                                                            v377:Stop();
                                                                                        end;
                                                                                    end;
                                                                                end;
                                                                            end;
                                                                        else
                                                                            task.wait(v373.Length / v375);
                                                                            u165(v);
                                                                        end;
                                                                    end;

                                                                    v378 = { v367, Name, (CameraController:GetAttribute("ViewmodelCFrame") or Camera.CFrame) * CFrame.new(0.5, 0, 0) * CFrame.Angles(v363.Offset or 0, 0, 0) };

                                                                    if v368 == "PlaceableGrenade" and u277 then
                                                                        v379, v380 = RaycastUtil:MouseRaycast(u4, {
                                                                            VFX_PARTS,
                                                                            Parent,
                                                                            Drops,
                                                                            Plants
                                                                        }, 4);

                                                                        if v380 then
                                                                            v378[4] = v380.CFrame:PointToObjectSpace(v379);
                                                                            v378[5] = v380;
                                                                        else
                                                                            v378[4] = 0;
                                                                        end;
                                                                    elseif v368 == "Grenade" and u277 then
                                                                        v378[4] = 0;
                                                                    end;

                                                                    u3("Fire", "d\147e\1R\169#o\249,9\133\153`B4q^W\6", "#\250)\215\28\1U\143\237}\154\218\231Cl-\15H\1\147", unpack(v378));
                                                                    task.spawn(u233, {
                                                                        Strength = Vector3.new(4, 4, 4),
                                                                        Speed = 0.25,
                                                                        SnapBack = true,
                                                                        Angles = { -179, 180 }
                                                                    });

                                                                    if v368 == "Normal" then
                                                                        v374 = tick();

                                                                        while tick() - v374 < v373.Length and (v373.IsPlaying and u9 == v369) do
                                                                            task.wait();
                                                                        end;
                                                                    end;

                                                                    u48 = "None";

                                                                    if v368 == "Normal" then
                                                                        script:SetAttribute("Using", false);
                                                                        u32 = false;

                                                                        return;
                                                                    end;

                                                                    u271(math.max(v373.Length, 0.46), u281, 3, v374);
                                                                end;

                                                                u3("Fire", "d\147e\1R\169#o\249,9\133\153`B4q^W\6", "#\250)\215\28\1U\143\237}\154\218\231Cl-\15H\1\147", v367, v283.Name);
                                                                task.spawn(u233, v288);
                                                                v381 = v286.Cooldown;

                                                                if v286.KeycardColor then
                                                                    u165("Use");
                                                                    u160("Use", 1);
                                                                    task.wait(v381);
                                                                elseif Name == "Lighter" then
                                                                    v382 = u9;
                                                                    u165("Use");
                                                                    u160("Use", 1);
                                                                    task.wait(0.5);

                                                                    if not (v382 and v382.Parent) then
                                                                        script:SetAttribute("Using", false);

                                                                        return;
                                                                    end;

                                                                    for _, child in u12.LightPart:GetChildren() do
                                                                        child.Enabled = not child.Enabled;
                                                                    end;

                                                                    task.wait((math.max(v381 - 0.5, 0)));
                                                                else
                                                                    if v286.HealthItem then
                                                                        v383 = v286.AnimationTimeScale;
                                                                        u165("Use");
                                                                        u160("Use", v383);
                                                                        u271(v381, u281, 1);
                                                                    end;

                                                                    v384 = v286.SwingAnimSpeed or 1;
                                                                    u165("Swing", 0);
                                                                    u160("Swing", v384);
                                                                    v385 = u22.Local.WindupLoop ~= nil;
                                                                    v386 = u160(v385 and "WindupLoop" or "Windup", v384, v385 and 0.15 or 0);

                                                                    if v386 then
                                                                        v387 = v385 and v381 and v381 or v386.Length / v384;
                                                                        v388 = tick();
                                                                        v389 = Melee.MeleeChecks;
                                                                        v390 = u9;
                                                                        v391 = 0;
                                                                        v392 = 0;
                                                                        v393 = (1 / 0);
                                                                        u394 = 0;
                                                                        v395 = nil;
                                                                        u396 = nil;
                                                                        u397 = nil;
                                                                        u398 = nil;
                                                                        u399 = nil;
                                                                        v400 = nil;

                                                                        while Run.Heartbeat:Wait() do
                                                                            if u9 ~= v390 then
                                                                                script:SetAttribute("Using", false);
                                                                                break;
                                                                            end;

                                                                            v401 = (tick() - v388) / v387;
                                                                            v402 = math.clamp(v401, 0, 1);
                                                                            v403 = 0;

                                                                            for i, v in pairs(v389) do
                                                                                v403 = v[1] <= v402 and i or v403;
                                                                            end;

                                                                            if v391 ~= v403 then
                                                                                v404 = CameraController:GetAttribute("ViewmodelCFrame") or Camera.CFrame;

                                                                                for _, v in pairs(v389[v403][2]) do
                                                                                    v405 = (v404 * v.Offset).Position;
                                                                                    v406 = v404.LookVector * v.Range;
                                                                                    v407, v408, v409, v410, v411 = RaycastUtil:Raycast(v405, v406, "Blacklist", {
                                                                                        Parent,
                                                                                        VFX_PARTS,
                                                                                        Drops,
                                                                                        Plants
                                                                                    }, script:GetAttribute("DebugShowRays"), u6, true);

                                                                                    if v411 then
                                                                                        Debris:AddItem(v411, 3);
                                                                                    end;

                                                                                    if v407 and v407.Parent then
                                                                                        v412 = v407.Name;
                                                                                        v413 = v407.Parent;

                                                                                        if v413:FindFirstChild("Humanoid") or v413.Parent:FindFirstChild("Humanoid") then
                                                                                            v414 = v412 == "Head" and 7 or (v412:find("Torso") and 6 or (v412:find("Arm") and 5 or 4));
                                                                                        else
                                                                                            v414 = (v413.Name == "NodeSpark" or v413.Name == "TreeX") and 3 or (v407:IsA("Terrain") and 1 or 2);
                                                                                        end;

                                                                                        v415 = (v408 - v405).Magnitude;
                                                                                    else
                                                                                        v414 = 0;
                                                                                        v415 = (1 / 0);
                                                                                    end;

                                                                                    if v392 < v414 or v414 == v392 and v415 < v393 then
                                                                                        v400 = v406;
                                                                                        u399 = v409;
                                                                                        u398 = v408;
                                                                                        u397 = v407;
                                                                                        u396 = v410;
                                                                                        v395 = v404;
                                                                                        u394 = v403;
                                                                                        v393 = v415;
                                                                                        v392 = v414;
                                                                                    end;
                                                                                end;
                                                                            end;

                                                                            if v402 >= 1 then
                                                                                break;
                                                                            end;

                                                                            v391 = v403;
                                                                        end;

                                                                        if script:GetAttribute("Using") then
                                                                            if not v385 then
                                                                                u165("Windup", 0);
                                                                            end;

                                                                            v416 = Parent.PrimaryPart:FindFirstChild(v283.Name .. "Swing");

                                                                            if v416 then
                                                                                if v385 then
                                                                                    v416:Play();
                                                                                else
                                                                                    SoundModule:PlayDuplicateSound(v416, nil, nil, true, u281.Skin);
                                                                                end;
                                                                            end;

                                                                            v417 = math.round(v367 * 10000);
                                                                            u418 = Random.new(v417):NextInteger(1, 1000000000);
                                                                            u419 = Random.new(v417):NextInteger(1, 10000000000);
                                                                            u420 = v395 or (CameraController:GetAttribute("ViewmodelCFrame") or Camera.CFrame);

                                                                            if v400 then
                                                                                u421, u422, u423, u424 = RaycastUtil:Raycast(u420.Position, v400 * 1.5, "Blacklist", {
                                                                                    Parent,
                                                                                    VFX_PARTS,
                                                                                    Drops,
                                                                                    Plants
                                                                                }, script:GetAttribute("DebugShowRays"), u7, true);
                                                                            else
                                                                                u421 = nil;
                                                                                u422 = nil;
                                                                                u423 = nil;
                                                                                u424 = nil;
                                                                            end;

                                                                            if u397 and u397.Parent then
                                                                                v425 = u116;
                                                                                v426 = math.random(-15, 15) / 100;
                                                                                v427 = math.random(-15, 15) / 100;
                                                                                v425.Target = Vector3.new(v426, v427, 0.5) * (Melee.BounceMult or 1);
                                                                            end;

                                                                            task.spawn(function() -- Line: 1466
                                                                                -- upvalues: u261 (ref), u397 (ref), u398 (ref), u399 (ref), u396 (ref), u418 (copy), u419 (copy), u420 (ref), u394 (ref), u421 (ref), u422 (ref), u423 (ref), u424 (ref), u281 (copy)
                                                                                u261({
                                                                                    u397,
                                                                                    u398,
                                                                                    u399,
                                                                                    u396,
                                                                                    u418,
                                                                                    u419,
                                                                                    nil,
                                                                                    u420,
                                                                                    u394
                                                                                }, {
                                                                                    u421,
                                                                                    u422,
                                                                                    u423,
                                                                                    u424
                                                                                }, true, u281.ID == 31);
                                                                            end);
                                                                            v428 = u397 and "Hit" or "Miss";
                                                                            u160(v428, v384, v428 == "Hit" and 0.1 or 0.4, 10);

                                                                            if not v385 then
                                                                                task.wait(v381 - v387);
                                                                            end;
                                                                        end;
                                                                    else
                                                                        Run.Heartbeat:Wait();
                                                                    end;
                                                                end;

                                                                goto l1;
                                                            end;

                                                            warn("MELEE SYNCHRONIZATION INTERNAL ERROR: ", v367);
                                                        end;
                                                    end;
                                                elseif Type == "Gun" then
                                                    v289 = v285.Spread;
                                                    v290 = v285.Bullet;
                                                    v291 = v285.Casing;
                                                    v292 = v285.Recoil;
                                                    u293 = v292.VM;
                                                    u294 = v292.Camera;
                                                    v295 = 1 - (u44.FireRateMult or 0);
                                                    v296 = 60 / v286.RPM * v295;
                                                    v297 = 60 / v286.BurstRPM * v295;

                                                    for i = 1, v286.Burst do
                                                        u165("Inspect", 0);
                                                        u165("Shoot", 0);
                                                        u160("Shoot", 1, 0);

                                                        if v291 and not v291.IgnoreShoot then
                                                            u132(v291);
                                                        end;

                                                        v298 = script:GetAttribute("Aiming");
                                                        v299 = u47 or u19;

                                                        if not (u44.Scope and v298) then
                                                            VFXModule:FlashPart(v299);
                                                        end;

                                                        v300 = Parent.PrimaryPart:FindFirstChild(v283.Name .. "Shoot");

                                                        if v300 then
                                                            SoundModule:PlayDuplicateSound(v300, nil, nil, true, u281.Skin);
                                                        end;

                                                        u77 = tick();
                                                        v301 = u281.Skin == "Hot Rod" and 0.75 or 1;
                                                        v302 = 1 + (v298 and u44.GunRecoilAimMult or 0);
                                                        v303 = v289[v298 and "Aiming" or "Hip"].ShootingExtra * (1 + (u44[(v298 and "Aim" or "Hip") .. "SpreadMult"] or 0)) * (u79 < 0.001 and 0 or u79) * (u282[(v298 and "Aim" or "Hip") .. "SpreadMult"] or 1);
                                                        u79 = math.min(u79 + 1 / v289.Shooting.BulletsForMax, 1);
                                                        v304 = u78 < 0.001 and 0 or math.floor(u78 * 100) / 100;
                                                        v305 = v303 < 0.001 and 0 or math.floor(v303 * 100) / 100;
                                                        v306 = v304 + v305;
                                                        v307 = CFrame.Angles(v290.Offset or 0, 0, 0);
                                                        v308 = Camera.CFrame;
                                                        v309 = workspace:GetServerTimeNow();
                                                        v310 = math.round(v309 * 10000);
                                                        v311 = Random.new(v310);
                                                        u312 = v311.NextInteger(v311, 1, 1000000000);
                                                        v313 = Random.new(v310);
                                                        v314 = {};

                                                        for _ = 1, u282.Bullets or 1 do
                                                            v315 = {
                                                                Radius = v313:NextNumber(0, math.floor(v306 * 100) / 100) / 500,
                                                                Degree = v313:NextNumber(0, 6.283185307179586)
                                                            };
                                                            v316 = math.floor(v306 * 100) / 100;
                                                            v317 = math.max(1, v316) * 1000000000;
                                                            v315.ID = v313:NextInteger(1, (math.ceil(v317)));
                                                            table.insert(v314, v315);
                                                        end;

                                                        v318 = v299.Position;
                                                        v319 = Parent.PrimaryPart.CFrame * CFrame.new(0, 1.5, 0);
                                                        u320 = {};
                                                        v321, v322 = RaycastUtil:MouseRaycast(u5, { Parent, VFX_PARTS });

                                                        if u44.HideTracer then
                                                            v323 = "";
                                                        elseif table.find(VFXModule.TracerSkins, u281.Skin) then
                                                            v323 = u281.Skin .. "Bullet";
                                                        else
                                                            v323 = u282.TracerName;
                                                        end;

                                                        for _, v in pairs(v314) do
                                                            v324 = v307 * CFrame.Angles(math.sin(v.Degree) * v.Radius, math.cos(v.Degree) * v.Radius, 0);
                                                            u325 = v.ID;
                                                            VFXModule:CreateProjectile({
                                                                FilterType = "Blacklist",
                                                                Position = v318,
                                                                Direction = (CFrame.new(v318, v321) * v324).LookVector,
                                                                PositionFirst = v319.p,
                                                                DirectionFirst = (v308 * v324).LookVector,
                                                                Filters = {
                                                                    Parent,
                                                                    VFX_PARTS,
                                                                    Drops,
                                                                    Plants
                                                                },
                                                                FilterFunction = u282.FilterType or "Hit",
                                                                VisualizeRay = script:GetAttribute("DebugShowRays"),
                                                                Speed = v290.Speed * (1 + (u44.SpeedMult or 0)) * (u282.SpeedMult or 1),
                                                                Gravity = v290.Gravity * (u282.GravityMult or 1),
                                                                MaxRange = v290.MaxRange * (1 + (u44.RangeMult or 0)) * (u282.RangeMult or 1),
                                                                Size = u282.BulletSize,
                                                                TracerName = v323,

                                                                HitFunction = function(...) -- Line: 1119, Name: HitFunction
                                                                    -- upvalues: u261 (ref), u312 (copy), u325 (copy), u320 (copy), u282 (ref)
                                                                    local v439 = { ... };
                                                                    u261({
                                                                        v439[1],
                                                                        v439[2],
                                                                        v439[3],
                                                                        v439[4],
                                                                        u312,
                                                                        u325,
                                                                        u320
                                                                    }, nil, u282.Impact);
                                                                end,

                                                                MissFunction = function() -- Line: 1123, Name: MissFunction
                                                                    -- upvalues: u3 (ref), u325 (copy), u312 (copy)
                                                                    u3("Fire", "d\147e\1R\169#o\249,9\133\153`B4q^W\6", "\160\29\229\248\31\16pJ\140]\137-\250\171Z_\1\135\223#", u325, u312);
                                                                end
                                                            });
                                                        end;

                                                        v284 = v284 - 1;
                                                        script:SetAttribute("LocalAmmo", v284);
                                                        u3("Fire", "d\147e\1R\169#o\249,9\133\153`B4q^W\6", "#\250)\215\28\1U\143\237}\154\218\231Cl-\15H\1\147", v309, v283.Name, v308, v319:PointToObjectSpace(v318), v319, v304, v305, v321);
                                                        v326 = TableUtil:TableRandom(u293.Pos.X);
                                                        v327 = TableUtil:TableRandom(u293.Pos.Y);
                                                        v328 = Vector3.new(v326, v327, TableUtil:TableRandom(u293.Pos.Z)) * v301;
                                                        v329 = TableUtil:TableRandom(u293.Rot.Y);
                                                        v330 = math.rad(v329);
                                                        v331 = TableUtil:TableRandom(u293.Rot.X);
                                                        v332 = math.rad(v331) * v302;
                                                        v333 = TableUtil:TableRandom(u293.Rot.Z);
                                                        v334 = math.rad(v333) * v302;
                                                        v335 = Vector3.new(v330, v332, v334) * v301;
                                                        v336 = u293.StartTime;
                                                        u85.Code = math.random(1, 100000000);
                                                        u85.X = 0;
                                                        u85.Increment = 1.5 / v336;
                                                        u85.PrevPos = u85.Pos;
                                                        u85.PrevRot = u85.Rot;
                                                        u85.NewPos = v328;
                                                        u85.NewRot = v335;
                                                        u337 = u85.Code;
                                                        u83 = 0;
                                                        u84 = u84 + 1;
                                                        u86 = tick();
                                                        v338, v339 = u294.RecoilStart(u84);
                                                        v340, v341 = u294.RecoilFinish(u84);
                                                        v342 = v338 + TableUtil:TableRandom(u294.Shake.Y);
                                                        v343 = v339 + TableUtil:TableRandom(u294.Shake.X);
                                                        v344 = -math.rad(v343);
                                                        u345 = math.rad(v342);
                                                        u346 = v344;
                                                        v347 = -math.rad(v341);
                                                        u348 = math.rad(v340);
                                                        u349 = v347;
                                                        u350 = tick();
                                                        u351 = 0;
                                                        u352 = 0;
                                                        u353 = 0;
                                                        u354 = u294.Duration - u294.FinishStart;
                                                        task.spawn(function() -- Line: 1166
                                                            -- upvalues: u44 (ref), PreferredInputController (ref), u351 (ref), u294 (copy), u345 (ref), u346 (ref), u82 (ref), u353 (ref), u352 (ref), u354 (copy), u348 (ref), u349 (ref), u350 (copy), u293 (copy), u85 (ref), u337 (copy)
                                                            local v440 = true;
                                                            local v441 = false;

                                                            while v440 or not v441 do
                                                                local v442 = script:GetAttribute("DebugFrameworkSpeed");
                                                                local v443 = Run.Heartbeat:Wait() * v442;

                                                                if v440 then
                                                                    local v444 = (script:GetAttribute("Aiming") and 0.7 or 1.2) * (StateController:GetAttribute("IsCrouch") and 0.75 or 1) * (1 + (u44.RecoilMult or 0));
                                                                    local v445 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";
                                                                    local v446 = v444 * (v445 and 0.65 or 1);
                                                                    local v447 = u351;
                                                                    u351 = math.min(u351 + v443, u294.FinishStart);
                                                                    local v448 = (u351 - v447) / u294.FinishStart * v446;
                                                                    local v449 = CFrame.Angles(u345 * v448, u346 * v448, 0);
                                                                    u82 = u82 * v449;
                                                                    Camera.CFrame = Camera.CFrame * v449;
                                                                    local v450 = u353;
                                                                    u352 = math.min(u352 + v443, u294.Duration);
                                                                    u353 = math.clamp(u352 - u294.FinishStart, 0, u354);
                                                                    local v451 = (u353 - v450) / u354 * v446;
                                                                    local v452 = CFrame.Angles(u348 * v451, u349 * v451, 0);
                                                                    u82 = u82 * v452;
                                                                    Camera.CFrame = Camera.CFrame * v452;

                                                                    if tick() - u350 >= u294.Duration / v442 then
                                                                        v440 = false;
                                                                    end;
                                                                end;

                                                                if tick() - u350 >= u293.StartTime / v442 and not v441 then
                                                                    v441 = true;

                                                                    if u85.Code == u337 or not u85.Code then
                                                                        local v453 = Vector3.new();
                                                                        local v454 = Vector3.new();
                                                                        local EndTime = u293.EndTime;
                                                                        u85.Code = math.random(1, 100000000);
                                                                        u85.X = 0;
                                                                        u85.Increment = 1.5 / EndTime;
                                                                        u85.PrevPos = u85.Pos;
                                                                        u85.PrevRot = u85.Rot;
                                                                        u85.NewPos = v453;
                                                                        u85.NewRot = v454;
                                                                    end;
                                                                end;
                                                            end;
                                                        end);
                                                        task.defer(u233, v288, v298 and 0.4 or 1);

                                                        if v286.BurstRPM > 0 then
                                                            task.wait(v297);

                                                            if v284 <= 0 or (u152("Equip") or (InventoryController:GetAttribute("Open") or (CameraController:GetAttribute("ViewmodelCFrame") or tick() - u67 < 0.1))) then
                                                                script:SetAttribute("Using", false);

                                                                if not u281 then
                                                                    return;
                                                                end;

                                                                break;
                                                            else
                                                                v355 = InventoryController.Fetch:Invoke();

                                                                if v355 then
                                                                    v356 = v355.Toolbar;

                                                                    if v356 then
                                                                        v357 = v356[script:GetAttribute("Equipped")];

                                                                        if v357 == nil then
                                                                            v357 = false;
                                                                        elseif v357 == 0 then
                                                                            v357 = false;
                                                                        end;
                                                                    else
                                                                        v357 = nil;
                                                                    end;
                                                                else
                                                                    v357 = nil;
                                                                end;

                                                                if v357 and (u281.Durability ~= nil and u281.Durability > 0) then
                                                                    continue;
                                                                else
                                                                    break;
                                                                end;
                                                            end;
                                                        end;
                                                    end;

                                                    if v287 then
                                                        u165("AimStart");
                                                        u165("AimHold");
                                                        u49 = "None";
                                                        u52 = false;

                                                        for _, child in pairs(u12:GetChildren()) do
                                                            if child:IsA("BasePart") and child.Name:find("Arrow") then
                                                                child.Transparency = 1;
                                                            end;
                                                        end;
                                                    end;

                                                    task.wait(v296);
                                                    v358 = v286.BoltAnimSpeed or 1;

                                                    if u22.Local.Bolt then
                                                        v359 = u9;
                                                        v360 = u160("Bolt", v358);

                                                        if v360 then
                                                            script:SetAttribute("CanUse", true);
                                                            task.wait(v360.Length);
                                                            script:SetAttribute("CanUse", nil);

                                                            if v359 and v359.Parent then
                                                                u165("Bolt");
                                                                goto l1;
                                                            end;
                                                        end;
                                                    else
                                                        if script:GetAttribute("Using") and (not v286.Auto and tick() - u35 > 0.2) then
                                                            script:SetAttribute("Using", false);

                                                            return;
                                                        end;

                                                        v280 = false;

                                                        if u22.Local.WindupLoop and u22.Local.WindupLoop.IsPlaying then
                                                            u165("WindupLoop", 0.15);
                                                        end;
                                                    end;
                                                else
                                                    u165("Inspect", 0);
                                                    u165("Hit", 0.1);
                                                    u165("Miss", 0.1);
                                                    u77 = tick();
                                                    v366, v367 = pcall(function() -- Line: 1251
                                                        return workspace:GetServerTimeNow();
                                                    end);

                                                    if v366 then
                                                        if v363 then
                                                            v368 = v363.Logic;
                                                        else
                                                            v368 = v363;
                                                        end;

                                                        if v363 and (v368 ~= "Normal" or u48 == "Holding") then
                                                            u165("ThrowHold");
                                                            u165("Aim");
                                                            v369 = u9;

                                                            if u22.Local.Light then
                                                                v370 = u160("Light");

                                                                if not v370 then
                                                                    script:SetAttribute("Using", false);

                                                                    return;
                                                                end;

                                                                u371 = u15:FindFirstChild("Effect");

                                                                if u371 then
                                                                    task.delay(0.5, function() -- Line: 1269
                                                                        -- upvalues: u371 (copy), u15 (ref)
                                                                        if not (u371 and u371.Parent) then
                                                                            return;
                                                                        end;

                                                                        for _, child in pairs(u371:GetChildren()) do
                                                                            child.Enabled = true;
                                                                        end;

                                                                        u15.Fuse:Play();
                                                                    end);
                                                                end;

                                                                task.wait(v370.Length);

                                                                if not (v369 and v369.Parent) then
                                                                    script:SetAttribute("Using", false);

                                                                    return;
                                                                end;

                                                                u165("Light");
                                                            end;

                                                            v372 = (v368 == "Grenade" or v368 == "PlaceableGrenade") and ({ "ThrowStart", u277 and "UnderHandThrow" or "OverHandThrow" } or { "Throw" }) or { "Throw" };
                                                            v373 = nil;
                                                            v374 = nil;

                                                            for i, v in pairs(v372) do
                                                                v375 = v363.AnimSpeed or 1;
                                                                v373 = u160(v, v375);

                                                                if not v373 then
                                                                    return;
                                                                end;

                                                                if i == #v372 then
                                                                    if v368 ~= "Normal" then
                                                                        v374 = tick();
                                                                        task.wait(0.3);

                                                                        if not (v369 and v369.Parent) then
                                                                            break;
                                                                        end;

                                                                        for _, child in pairs(u12:GetChildren()) do
                                                                            child.Transparency = 1;
                                                                            v376 = child:FindFirstChild("Effect");

                                                                            if v376 then
                                                                                v376:ClearAllChildren();
                                                                                v377 = child:FindFirstChild("Fuse");

                                                                                if v377 then
                                                                                    v377:Stop();
                                                                                end;
                                                                            end;
                                                                        end;
                                                                    end;
                                                                else
                                                                    task.wait(v373.Length / v375);
                                                                    u165(v);
                                                                end;
                                                            end;

                                                            v378 = { v367, Name, (CameraController:GetAttribute("ViewmodelCFrame") or Camera.CFrame) * CFrame.new(0.5, 0, 0) * CFrame.Angles(v363.Offset or 0, 0, 0) };

                                                            if v368 == "PlaceableGrenade" and u277 then
                                                                v379, v380 = RaycastUtil:MouseRaycast(u4, {
                                                                    VFX_PARTS,
                                                                    Parent,
                                                                    Drops,
                                                                    Plants
                                                                }, 4);

                                                                if v380 then
                                                                    v378[4] = v380.CFrame:PointToObjectSpace(v379);
                                                                    v378[5] = v380;
                                                                else
                                                                    v378[4] = 0;
                                                                end;
                                                            elseif v368 == "Grenade" and u277 then
                                                                v378[4] = 0;
                                                            end;

                                                            u3("Fire", "d\147e\1R\169#o\249,9\133\153`B4q^W\6", "#\250)\215\28\1U\143\237}\154\218\231Cl-\15H\1\147", unpack(v378));
                                                            task.spawn(u233, {
                                                                Strength = Vector3.new(4, 4, 4),
                                                                Speed = 0.25,
                                                                SnapBack = true,
                                                                Angles = { -179, 180 }
                                                            });

                                                            if v368 == "Normal" then
                                                                v374 = tick();

                                                                while tick() - v374 < v373.Length and (v373.IsPlaying and u9 == v369) do
                                                                    task.wait();
                                                                end;
                                                            end;

                                                            u48 = "None";

                                                            if v368 == "Normal" then
                                                                script:SetAttribute("Using", false);
                                                                u32 = false;

                                                                return;
                                                            end;

                                                            u271(math.max(v373.Length, 0.46), u281, 3, v374);
                                                        end;

                                                        u3("Fire", "d\147e\1R\169#o\249,9\133\153`B4q^W\6", "#\250)\215\28\1U\143\237}\154\218\231Cl-\15H\1\147", v367, v283.Name);
                                                        task.spawn(u233, v288);
                                                        v381 = v286.Cooldown;

                                                        if v286.KeycardColor then
                                                            u165("Use");
                                                            u160("Use", 1);
                                                            task.wait(v381);
                                                        elseif Name == "Lighter" then
                                                            v382 = u9;
                                                            u165("Use");
                                                            u160("Use", 1);
                                                            task.wait(0.5);

                                                            if not (v382 and v382.Parent) then
                                                                script:SetAttribute("Using", false);

                                                                return;
                                                            end;

                                                            for _, child in u12.LightPart:GetChildren() do
                                                                child.Enabled = not child.Enabled;
                                                            end;

                                                            task.wait((math.max(v381 - 0.5, 0)));
                                                        else
                                                            if v286.HealthItem then
                                                                v383 = v286.AnimationTimeScale;
                                                                u165("Use");
                                                                u160("Use", v383);
                                                                u271(v381, u281, 1);
                                                            end;

                                                            v384 = v286.SwingAnimSpeed or 1;
                                                            u165("Swing", 0);
                                                            u160("Swing", v384);
                                                            v385 = u22.Local.WindupLoop ~= nil;
                                                            v386 = u160(v385 and "WindupLoop" or "Windup", v384, v385 and 0.15 or 0);

                                                            if v386 then
                                                                v387 = v385 and v381 and v381 or v386.Length / v384;
                                                                v388 = tick();
                                                                v389 = Melee.MeleeChecks;
                                                                v390 = u9;
                                                                v391 = 0;
                                                                v392 = 0;
                                                                v393 = (1 / 0);
                                                                u394 = 0;
                                                                v395 = nil;
                                                                u396 = nil;
                                                                u397 = nil;
                                                                u398 = nil;
                                                                u399 = nil;
                                                                v400 = nil;

                                                                while Run.Heartbeat:Wait() do
                                                                    if u9 ~= v390 then
                                                                        script:SetAttribute("Using", false);
                                                                        break;
                                                                    end;

                                                                    v401 = (tick() - v388) / v387;
                                                                    v402 = math.clamp(v401, 0, 1);
                                                                    v403 = 0;

                                                                    for i, v in pairs(v389) do
                                                                        v403 = v[1] <= v402 and i or v403;
                                                                    end;

                                                                    if v391 ~= v403 then
                                                                        v404 = CameraController:GetAttribute("ViewmodelCFrame") or Camera.CFrame;

                                                                        for _, v in pairs(v389[v403][2]) do
                                                                            v405 = (v404 * v.Offset).Position;
                                                                            v406 = v404.LookVector * v.Range;
                                                                            v407, v408, v409, v410, v411 = RaycastUtil:Raycast(v405, v406, "Blacklist", {
                                                                                Parent,
                                                                                VFX_PARTS,
                                                                                Drops,
                                                                                Plants
                                                                            }, script:GetAttribute("DebugShowRays"), u6, true);

                                                                            if v411 then
                                                                                Debris:AddItem(v411, 3);
                                                                            end;

                                                                            if v407 and v407.Parent then
                                                                                v412 = v407.Name;
                                                                                v413 = v407.Parent;

                                                                                if v413:FindFirstChild("Humanoid") or v413.Parent:FindFirstChild("Humanoid") then
                                                                                    v414 = v412 == "Head" and 7 or (v412:find("Torso") and 6 or (v412:find("Arm") and 5 or 4));
                                                                                else
                                                                                    v414 = (v413.Name == "NodeSpark" or v413.Name == "TreeX") and 3 or (v407:IsA("Terrain") and 1 or 2);
                                                                                end;

                                                                                v415 = (v408 - v405).Magnitude;
                                                                            else
                                                                                v414 = 0;
                                                                                v415 = (1 / 0);
                                                                            end;

                                                                            if v392 < v414 or v414 == v392 and v415 < v393 then
                                                                                v400 = v406;
                                                                                u399 = v409;
                                                                                u398 = v408;
                                                                                u397 = v407;
                                                                                u396 = v410;
                                                                                v395 = v404;
                                                                                u394 = v403;
                                                                                v393 = v415;
                                                                                v392 = v414;
                                                                            end;
                                                                        end;
                                                                    end;

                                                                    if v402 >= 1 then
                                                                        break;
                                                                    end;

                                                                    v391 = v403;
                                                                end;

                                                                if script:GetAttribute("Using") then
                                                                    if not v385 then
                                                                        u165("Windup", 0);
                                                                    end;

                                                                    v416 = Parent.PrimaryPart:FindFirstChild(v283.Name .. "Swing");

                                                                    if v416 then
                                                                        if v385 then
                                                                            v416:Play();
                                                                        else
                                                                            SoundModule:PlayDuplicateSound(v416, nil, nil, true, u281.Skin);
                                                                        end;
                                                                    end;

                                                                    v417 = math.round(v367 * 10000);
                                                                    u418 = Random.new(v417):NextInteger(1, 1000000000);
                                                                    u419 = Random.new(v417):NextInteger(1, 10000000000);
                                                                    u420 = v395 or (CameraController:GetAttribute("ViewmodelCFrame") or Camera.CFrame);

                                                                    if v400 then
                                                                        u421, u422, u423, u424 = RaycastUtil:Raycast(u420.Position, v400 * 1.5, "Blacklist", {
                                                                            Parent,
                                                                            VFX_PARTS,
                                                                            Drops,
                                                                            Plants
                                                                        }, script:GetAttribute("DebugShowRays"), u7, true);
                                                                    else
                                                                        u421 = nil;
                                                                        u422 = nil;
                                                                        u423 = nil;
                                                                        u424 = nil;
                                                                    end;

                                                                    if u397 and u397.Parent then
                                                                        v425 = u116;
                                                                        v426 = math.random(-15, 15) / 100;
                                                                        v427 = math.random(-15, 15) / 100;
                                                                        v425.Target = Vector3.new(v426, v427, 0.5) * (Melee.BounceMult or 1);
                                                                    end;

                                                                    task.spawn(function() -- Line: 1466
                                                                        -- upvalues: u261 (ref), u397 (ref), u398 (ref), u399 (ref), u396 (ref), u418 (copy), u419 (copy), u420 (ref), u394 (ref), u421 (ref), u422 (ref), u423 (ref), u424 (ref), u281 (copy)
                                                                        u261({
                                                                            u397,
                                                                            u398,
                                                                            u399,
                                                                            u396,
                                                                            u418,
                                                                            u419,
                                                                            nil,
                                                                            u420,
                                                                            u394
                                                                        }, {
                                                                            u421,
                                                                            u422,
                                                                            u423,
                                                                            u424
                                                                        }, true, u281.ID == 31);
                                                                    end);
                                                                    v428 = u397 and "Hit" or "Miss";
                                                                    u160(v428, v384, v428 == "Hit" and 0.1 or 0.4, 10);

                                                                    if not v385 then
                                                                        task.wait(v381 - v387);
                                                                    end;
                                                                end;
                                                            else
                                                                Run.Heartbeat:Wait();
                                                            end;
                                                        end;

                                                        goto l1;
                                                    end;

                                                    warn("MELEE SYNCHRONIZATION INTERNAL ERROR: ", v367);
                                                end;
                                            end;
                                        end;
                                    end;
                                elseif Type == "Gun" then
                                    v289 = v285.Spread;
                                    v290 = v285.Bullet;
                                    v291 = v285.Casing;
                                    v292 = v285.Recoil;
                                    u293 = v292.VM;
                                    u294 = v292.Camera;
                                    v295 = 1 - (u44.FireRateMult or 0);
                                    v296 = 60 / v286.RPM * v295;
                                    v297 = 60 / v286.BurstRPM * v295;

                                    for i = 1, v286.Burst do
                                        u165("Inspect", 0);
                                        u165("Shoot", 0);
                                        u160("Shoot", 1, 0);

                                        if v291 and not v291.IgnoreShoot then
                                            u132(v291);
                                        end;

                                        v298 = script:GetAttribute("Aiming");
                                        v299 = u47 or u19;

                                        if not (u44.Scope and v298) then
                                            VFXModule:FlashPart(v299);
                                        end;

                                        v300 = Parent.PrimaryPart:FindFirstChild(v283.Name .. "Shoot");

                                        if v300 then
                                            SoundModule:PlayDuplicateSound(v300, nil, nil, true, u281.Skin);
                                        end;

                                        u77 = tick();
                                        v301 = u281.Skin == "Hot Rod" and 0.75 or 1;
                                        v302 = 1 + (v298 and u44.GunRecoilAimMult or 0);
                                        v303 = v289[v298 and "Aiming" or "Hip"].ShootingExtra * (1 + (u44[(v298 and "Aim" or "Hip") .. "SpreadMult"] or 0)) * (u79 < 0.001 and 0 or u79) * (u282[(v298 and "Aim" or "Hip") .. "SpreadMult"] or 1);
                                        u79 = math.min(u79 + 1 / v289.Shooting.BulletsForMax, 1);
                                        v304 = u78 < 0.001 and 0 or math.floor(u78 * 100) / 100;
                                        v305 = v303 < 0.001 and 0 or math.floor(v303 * 100) / 100;
                                        v306 = v304 + v305;
                                        v307 = CFrame.Angles(v290.Offset or 0, 0, 0);
                                        v308 = Camera.CFrame;
                                        v309 = workspace:GetServerTimeNow();
                                        v310 = math.round(v309 * 10000);
                                        v311 = Random.new(v310);
                                        u312 = v311.NextInteger(v311, 1, 1000000000);
                                        v313 = Random.new(v310);
                                        v314 = {};

                                        for _ = 1, u282.Bullets or 1 do
                                            v315 = {
                                                Radius = v313:NextNumber(0, math.floor(v306 * 100) / 100) / 500,
                                                Degree = v313:NextNumber(0, 6.283185307179586)
                                            };
                                            v316 = math.floor(v306 * 100) / 100;
                                            v317 = math.max(1, v316) * 1000000000;
                                            v315.ID = v313:NextInteger(1, (math.ceil(v317)));
                                            table.insert(v314, v315);
                                        end;

                                        v318 = v299.Position;
                                        v319 = Parent.PrimaryPart.CFrame * CFrame.new(0, 1.5, 0);
                                        u320 = {};
                                        v321, v322 = RaycastUtil:MouseRaycast(u5, { Parent, VFX_PARTS });

                                        if u44.HideTracer then
                                            v323 = "";
                                        elseif table.find(VFXModule.TracerSkins, u281.Skin) then
                                            v323 = u281.Skin .. "Bullet";
                                        else
                                            v323 = u282.TracerName;
                                        end;

                                        for _, v in pairs(v314) do
                                            v324 = v307 * CFrame.Angles(math.sin(v.Degree) * v.Radius, math.cos(v.Degree) * v.Radius, 0);
                                            u325 = v.ID;
                                            VFXModule:CreateProjectile({
                                                FilterType = "Blacklist",
                                                Position = v318,
                                                Direction = (CFrame.new(v318, v321) * v324).LookVector,
                                                PositionFirst = v319.p,
                                                DirectionFirst = (v308 * v324).LookVector,
                                                Filters = {
                                                    Parent,
                                                    VFX_PARTS,
                                                    Drops,
                                                    Plants
                                                },
                                                FilterFunction = u282.FilterType or "Hit",
                                                VisualizeRay = script:GetAttribute("DebugShowRays"),
                                                Speed = v290.Speed * (1 + (u44.SpeedMult or 0)) * (u282.SpeedMult or 1),
                                                Gravity = v290.Gravity * (u282.GravityMult or 1),
                                                MaxRange = v290.MaxRange * (1 + (u44.RangeMult or 0)) * (u282.RangeMult or 1),
                                                Size = u282.BulletSize,
                                                TracerName = v323,

                                                HitFunction = function(...) -- Line: 1119, Name: HitFunction
                                                    -- upvalues: u261 (ref), u312 (copy), u325 (copy), u320 (copy), u282 (ref)
                                                    local v439 = { ... };
                                                    u261({
                                                        v439[1],
                                                        v439[2],
                                                        v439[3],
                                                        v439[4],
                                                        u312,
                                                        u325,
                                                        u320
                                                    }, nil, u282.Impact);
                                                end,

                                                MissFunction = function() -- Line: 1123, Name: MissFunction
                                                    -- upvalues: u3 (ref), u325 (copy), u312 (copy)
                                                    u3("Fire", "d\147e\1R\169#o\249,9\133\153`B4q^W\6", "\160\29\229\248\31\16pJ\140]\137-\250\171Z_\1\135\223#", u325, u312);
                                                end
                                            });
                                        end;

                                        v284 = v284 - 1;
                                        script:SetAttribute("LocalAmmo", v284);
                                        u3("Fire", "d\147e\1R\169#o\249,9\133\153`B4q^W\6", "#\250)\215\28\1U\143\237}\154\218\231Cl-\15H\1\147", v309, v283.Name, v308, v319:PointToObjectSpace(v318), v319, v304, v305, v321);
                                        v326 = TableUtil:TableRandom(u293.Pos.X);
                                        v327 = TableUtil:TableRandom(u293.Pos.Y);
                                        v328 = Vector3.new(v326, v327, TableUtil:TableRandom(u293.Pos.Z)) * v301;
                                        v329 = TableUtil:TableRandom(u293.Rot.Y);
                                        v330 = math.rad(v329);
                                        v331 = TableUtil:TableRandom(u293.Rot.X);
                                        v332 = math.rad(v331) * v302;
                                        v333 = TableUtil:TableRandom(u293.Rot.Z);
                                        v334 = math.rad(v333) * v302;
                                        v335 = Vector3.new(v330, v332, v334) * v301;
                                        v336 = u293.StartTime;
                                        u85.Code = math.random(1, 100000000);
                                        u85.X = 0;
                                        u85.Increment = 1.5 / v336;
                                        u85.PrevPos = u85.Pos;
                                        u85.PrevRot = u85.Rot;
                                        u85.NewPos = v328;
                                        u85.NewRot = v335;
                                        u337 = u85.Code;
                                        u83 = 0;
                                        u84 = u84 + 1;
                                        u86 = tick();
                                        v338, v339 = u294.RecoilStart(u84);
                                        v340, v341 = u294.RecoilFinish(u84);
                                        v342 = v338 + TableUtil:TableRandom(u294.Shake.Y);
                                        v343 = v339 + TableUtil:TableRandom(u294.Shake.X);
                                        v344 = -math.rad(v343);
                                        u345 = math.rad(v342);
                                        u346 = v344;
                                        v347 = -math.rad(v341);
                                        u348 = math.rad(v340);
                                        u349 = v347;
                                        u350 = tick();
                                        u351 = 0;
                                        u352 = 0;
                                        u353 = 0;
                                        u354 = u294.Duration - u294.FinishStart;
                                        task.spawn(function() -- Line: 1166
                                            -- upvalues: u44 (ref), PreferredInputController (ref), u351 (ref), u294 (copy), u345 (ref), u346 (ref), u82 (ref), u353 (ref), u352 (ref), u354 (copy), u348 (ref), u349 (ref), u350 (copy), u293 (copy), u85 (ref), u337 (copy)
                                            local v440 = true;
                                            local v441 = false;

                                            while v440 or not v441 do
                                                local v442 = script:GetAttribute("DebugFrameworkSpeed");
                                                local v443 = Run.Heartbeat:Wait() * v442;

                                                if v440 then
                                                    local v444 = (script:GetAttribute("Aiming") and 0.7 or 1.2) * (StateController:GetAttribute("IsCrouch") and 0.75 or 1) * (1 + (u44.RecoilMult or 0));
                                                    local v445 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";
                                                    local v446 = v444 * (v445 and 0.65 or 1);
                                                    local v447 = u351;
                                                    u351 = math.min(u351 + v443, u294.FinishStart);
                                                    local v448 = (u351 - v447) / u294.FinishStart * v446;
                                                    local v449 = CFrame.Angles(u345 * v448, u346 * v448, 0);
                                                    u82 = u82 * v449;
                                                    Camera.CFrame = Camera.CFrame * v449;
                                                    local v450 = u353;
                                                    u352 = math.min(u352 + v443, u294.Duration);
                                                    u353 = math.clamp(u352 - u294.FinishStart, 0, u354);
                                                    local v451 = (u353 - v450) / u354 * v446;
                                                    local v452 = CFrame.Angles(u348 * v451, u349 * v451, 0);
                                                    u82 = u82 * v452;
                                                    Camera.CFrame = Camera.CFrame * v452;

                                                    if tick() - u350 >= u294.Duration / v442 then
                                                        v440 = false;
                                                    end;
                                                end;

                                                if tick() - u350 >= u293.StartTime / v442 and not v441 then
                                                    v441 = true;

                                                    if u85.Code == u337 or not u85.Code then
                                                        local v453 = Vector3.new();
                                                        local v454 = Vector3.new();
                                                        local EndTime = u293.EndTime;
                                                        u85.Code = math.random(1, 100000000);
                                                        u85.X = 0;
                                                        u85.Increment = 1.5 / EndTime;
                                                        u85.PrevPos = u85.Pos;
                                                        u85.PrevRot = u85.Rot;
                                                        u85.NewPos = v453;
                                                        u85.NewRot = v454;
                                                    end;
                                                end;
                                            end;
                                        end);
                                        task.defer(u233, v288, v298 and 0.4 or 1);

                                        if v286.BurstRPM > 0 then
                                            task.wait(v297);

                                            if v284 <= 0 or (u152("Equip") or (InventoryController:GetAttribute("Open") or (CameraController:GetAttribute("ViewmodelCFrame") or tick() - u67 < 0.1))) then
                                                script:SetAttribute("Using", false);

                                                if not u281 then
                                                    return;
                                                end;

                                                break;
                                            else
                                                v355 = InventoryController.Fetch:Invoke();

                                                if v355 then
                                                    v356 = v355.Toolbar;

                                                    if v356 then
                                                        v357 = v356[script:GetAttribute("Equipped")];

                                                        if v357 == nil then
                                                            v357 = false;
                                                        elseif v357 == 0 then
                                                            v357 = false;
                                                        end;
                                                    else
                                                        v357 = nil;
                                                    end;
                                                else
                                                    v357 = nil;
                                                end;

                                                if v357 and (u281.Durability ~= nil and u281.Durability > 0) then
                                                    continue;
                                                else
                                                    break;
                                                end;
                                            end;
                                        end;
                                    end;

                                    if v287 then
                                        u165("AimStart");
                                        u165("AimHold");
                                        u49 = "None";
                                        u52 = false;

                                        for _, child in pairs(u12:GetChildren()) do
                                            if child:IsA("BasePart") and child.Name:find("Arrow") then
                                                child.Transparency = 1;
                                            end;
                                        end;
                                    end;

                                    task.wait(v296);
                                    v358 = v286.BoltAnimSpeed or 1;

                                    if not u22.Local.Bolt then
                                        goto l1;
                                    end;

                                    v359 = u9;
                                    v360 = u160("Bolt", v358);

                                    if v360 then
                                        script:SetAttribute("CanUse", true);
                                        task.wait(v360.Length);
                                        script:SetAttribute("CanUse", nil);

                                        if v359 and v359.Parent then
                                            u165("Bolt");
                                            goto l1;
                                        end;
                                    end;
                                else
                                    u165("Inspect", 0);
                                    u165("Hit", 0.1);
                                    u165("Miss", 0.1);
                                    u77 = tick();
                                    v366, v367 = pcall(function() -- Line: 1251
                                        return workspace:GetServerTimeNow();
                                    end);

                                    if v366 then
                                        if v363 then
                                            v368 = v363.Logic;
                                        else
                                            v368 = v363;
                                        end;

                                        if v363 and (v368 ~= "Normal" or u48 == "Holding") then
                                            u165("ThrowHold");
                                            u165("Aim");
                                            v369 = u9;

                                            if u22.Local.Light then
                                                v370 = u160("Light");

                                                if not v370 then
                                                    script:SetAttribute("Using", false);

                                                    return;
                                                end;

                                                u371 = u15:FindFirstChild("Effect");

                                                if u371 then
                                                    task.delay(0.5, function() -- Line: 1269
                                                        -- upvalues: u371 (copy), u15 (ref)
                                                        if not (u371 and u371.Parent) then
                                                            return;
                                                        end;

                                                        for _, child in pairs(u371:GetChildren()) do
                                                            child.Enabled = true;
                                                        end;

                                                        u15.Fuse:Play();
                                                    end);
                                                end;

                                                task.wait(v370.Length);

                                                if not (v369 and v369.Parent) then
                                                    script:SetAttribute("Using", false);

                                                    return;
                                                end;

                                                u165("Light");
                                            end;

                                            v372 = (v368 == "Grenade" or v368 == "PlaceableGrenade") and ({ "ThrowStart", u277 and "UnderHandThrow" or "OverHandThrow" } or { "Throw" }) or { "Throw" };
                                            v373 = nil;
                                            v374 = nil;

                                            for i, v in pairs(v372) do
                                                v375 = v363.AnimSpeed or 1;
                                                v373 = u160(v, v375);

                                                if not v373 then
                                                    return;
                                                end;

                                                if i == #v372 then
                                                    if v368 ~= "Normal" then
                                                        v374 = tick();
                                                        task.wait(0.3);

                                                        if not (v369 and v369.Parent) then
                                                            break;
                                                        end;

                                                        for _, child in pairs(u12:GetChildren()) do
                                                            child.Transparency = 1;
                                                            v376 = child:FindFirstChild("Effect");

                                                            if v376 then
                                                                v376:ClearAllChildren();
                                                                v377 = child:FindFirstChild("Fuse");

                                                                if v377 then
                                                                    v377:Stop();
                                                                end;
                                                            end;
                                                        end;
                                                    end;
                                                else
                                                    task.wait(v373.Length / v375);
                                                    u165(v);
                                                end;
                                            end;

                                            v378 = { v367, Name, (CameraController:GetAttribute("ViewmodelCFrame") or Camera.CFrame) * CFrame.new(0.5, 0, 0) * CFrame.Angles(v363.Offset or 0, 0, 0) };

                                            if v368 == "PlaceableGrenade" and u277 then
                                                v379, v380 = RaycastUtil:MouseRaycast(u4, {
                                                    VFX_PARTS,
                                                    Parent,
                                                    Drops,
                                                    Plants
                                                }, 4);

                                                if v380 then
                                                    v378[4] = v380.CFrame:PointToObjectSpace(v379);
                                                    v378[5] = v380;
                                                else
                                                    v378[4] = 0;
                                                end;
                                            elseif v368 == "Grenade" and u277 then
                                                v378[4] = 0;
                                            end;

                                            u3("Fire", "d\147e\1R\169#o\249,9\133\153`B4q^W\6", "#\250)\215\28\1U\143\237}\154\218\231Cl-\15H\1\147", unpack(v378));
                                            task.spawn(u233, {
                                                Strength = Vector3.new(4, 4, 4),
                                                Speed = 0.25,
                                                SnapBack = true,
                                                Angles = { -179, 180 }
                                            });

                                            if v368 == "Normal" then
                                                v374 = tick();

                                                while tick() - v374 < v373.Length and (v373.IsPlaying and u9 == v369) do
                                                    task.wait();
                                                end;
                                            end;

                                            u48 = "None";

                                            if v368 == "Normal" then
                                                script:SetAttribute("Using", false);
                                                u32 = false;

                                                return;
                                            end;

                                            u271(math.max(v373.Length, 0.46), u281, 3, v374);
                                        end;

                                        u3("Fire", "d\147e\1R\169#o\249,9\133\153`B4q^W\6", "#\250)\215\28\1U\143\237}\154\218\231Cl-\15H\1\147", v367, v283.Name);
                                        task.spawn(u233, v288);
                                        v381 = v286.Cooldown;

                                        if v286.KeycardColor then
                                            u165("Use");
                                            u160("Use", 1);
                                            task.wait(v381);
                                        elseif Name == "Lighter" then
                                            v382 = u9;
                                            u165("Use");
                                            u160("Use", 1);
                                            task.wait(0.5);

                                            if not (v382 and v382.Parent) then
                                                script:SetAttribute("Using", false);

                                                return;
                                            end;

                                            for _, child in u12.LightPart:GetChildren() do
                                                child.Enabled = not child.Enabled;
                                            end;

                                            task.wait((math.max(v381 - 0.5, 0)));
                                        else
                                            if v286.HealthItem then
                                                v383 = v286.AnimationTimeScale;
                                                u165("Use");
                                                u160("Use", v383);
                                                u271(v381, u281, 1);
                                            end;

                                            v384 = v286.SwingAnimSpeed or 1;
                                            u165("Swing", 0);
                                            u160("Swing", v384);
                                            v385 = u22.Local.WindupLoop ~= nil;
                                            v386 = u160(v385 and "WindupLoop" or "Windup", v384, v385 and 0.15 or 0);

                                            if v386 then
                                                v387 = v385 and v381 and v381 or v386.Length / v384;
                                                v388 = tick();
                                                v389 = Melee.MeleeChecks;
                                                v390 = u9;
                                                v391 = 0;
                                                v392 = 0;
                                                v393 = (1 / 0);
                                                u394 = 0;
                                                v395 = nil;
                                                u396 = nil;
                                                u397 = nil;
                                                u398 = nil;
                                                u399 = nil;
                                                v400 = nil;

                                                while Run.Heartbeat:Wait() do
                                                    if u9 ~= v390 then
                                                        script:SetAttribute("Using", false);
                                                        break;
                                                    end;

                                                    v401 = (tick() - v388) / v387;
                                                    v402 = math.clamp(v401, 0, 1);
                                                    v403 = 0;

                                                    for i, v in pairs(v389) do
                                                        v403 = v[1] <= v402 and i or v403;
                                                    end;

                                                    if v391 ~= v403 then
                                                        v404 = CameraController:GetAttribute("ViewmodelCFrame") or Camera.CFrame;

                                                        for _, v in pairs(v389[v403][2]) do
                                                            v405 = (v404 * v.Offset).Position;
                                                            v406 = v404.LookVector * v.Range;
                                                            v407, v408, v409, v410, v411 = RaycastUtil:Raycast(v405, v406, "Blacklist", {
                                                                Parent,
                                                                VFX_PARTS,
                                                                Drops,
                                                                Plants
                                                            }, script:GetAttribute("DebugShowRays"), u6, true);

                                                            if v411 then
                                                                Debris:AddItem(v411, 3);
                                                            end;

                                                            if v407 and v407.Parent then
                                                                v412 = v407.Name;
                                                                v413 = v407.Parent;

                                                                if v413:FindFirstChild("Humanoid") or v413.Parent:FindFirstChild("Humanoid") then
                                                                    v414 = v412 == "Head" and 7 or (v412:find("Torso") and 6 or (v412:find("Arm") and 5 or 4));
                                                                else
                                                                    v414 = (v413.Name == "NodeSpark" or v413.Name == "TreeX") and 3 or (v407:IsA("Terrain") and 1 or 2);
                                                                end;

                                                                v415 = (v408 - v405).Magnitude;
                                                            else
                                                                v414 = 0;
                                                                v415 = (1 / 0);
                                                            end;

                                                            if v392 < v414 or v414 == v392 and v415 < v393 then
                                                                v400 = v406;
                                                                u399 = v409;
                                                                u398 = v408;
                                                                u397 = v407;
                                                                u396 = v410;
                                                                v395 = v404;
                                                                u394 = v403;
                                                                v393 = v415;
                                                                v392 = v414;
                                                            end;
                                                        end;
                                                    end;

                                                    if v402 >= 1 then
                                                        break;
                                                    end;

                                                    v391 = v403;
                                                end;

                                                if script:GetAttribute("Using") then
                                                    if not v385 then
                                                        u165("Windup", 0);
                                                    end;

                                                    v416 = Parent.PrimaryPart:FindFirstChild(v283.Name .. "Swing");

                                                    if v416 then
                                                        if v385 then
                                                            v416:Play();
                                                        else
                                                            SoundModule:PlayDuplicateSound(v416, nil, nil, true, u281.Skin);
                                                        end;
                                                    end;

                                                    v417 = math.round(v367 * 10000);
                                                    u418 = Random.new(v417):NextInteger(1, 1000000000);
                                                    u419 = Random.new(v417):NextInteger(1, 10000000000);
                                                    u420 = v395 or (CameraController:GetAttribute("ViewmodelCFrame") or Camera.CFrame);

                                                    if v400 then
                                                        u421, u422, u423, u424 = RaycastUtil:Raycast(u420.Position, v400 * 1.5, "Blacklist", {
                                                            Parent,
                                                            VFX_PARTS,
                                                            Drops,
                                                            Plants
                                                        }, script:GetAttribute("DebugShowRays"), u7, true);
                                                    else
                                                        u421 = nil;
                                                        u422 = nil;
                                                        u423 = nil;
                                                        u424 = nil;
                                                    end;

                                                    if u397 and u397.Parent then
                                                        v425 = u116;
                                                        v426 = math.random(-15, 15) / 100;
                                                        v427 = math.random(-15, 15) / 100;
                                                        v425.Target = Vector3.new(v426, v427, 0.5) * (Melee.BounceMult or 1);
                                                    end;

                                                    task.spawn(function() -- Line: 1466
                                                        -- upvalues: u261 (ref), u397 (ref), u398 (ref), u399 (ref), u396 (ref), u418 (copy), u419 (copy), u420 (ref), u394 (ref), u421 (ref), u422 (ref), u423 (ref), u424 (ref), u281 (copy)
                                                        u261({
                                                            u397,
                                                            u398,
                                                            u399,
                                                            u396,
                                                            u418,
                                                            u419,
                                                            nil,
                                                            u420,
                                                            u394
                                                        }, {
                                                            u421,
                                                            u422,
                                                            u423,
                                                            u424
                                                        }, true, u281.ID == 31);
                                                    end);
                                                    v428 = u397 and "Hit" or "Miss";
                                                    u160(v428, v384, v428 == "Hit" and 0.1 or 0.4, 10);

                                                    if not v385 then
                                                        task.wait(v381 - v387);
                                                    end;
                                                end;
                                            else
                                                Run.Heartbeat:Wait();
                                            end;
                                        end;

                                        goto l1;
                                    end;

                                    warn("MELEE SYNCHRONIZATION INTERNAL ERROR: ", v367);
                                end;

                                break;
                            else
                                break;
                            end;
                        end;
                    end;
                else
                    Run.Heartbeat:Wait();
                    v278 = false;
                end;
            end;

            v289 = v285.Spread;
            v290 = v285.Bullet;
            v291 = v285.Casing;
            v292 = v285.Recoil;
            u293 = v292.VM;
            u294 = v292.Camera;
            v295 = 1 - (u44.FireRateMult or 0);
            v296 = 60 / v286.RPM * v295;
            v297 = 60 / v286.BurstRPM * v295;

            for i = 1, v286.Burst do
                u165("Inspect", 0);
                u165("Shoot", 0);
                u160("Shoot", 1, 0);

                if v291 and not v291.IgnoreShoot then
                    u132(v291);
                end;

                v298 = script:GetAttribute("Aiming");
                v299 = u47 or u19;

                if not (u44.Scope and v298) then
                    VFXModule:FlashPart(v299);
                end;

                v300 = Parent.PrimaryPart:FindFirstChild(v283.Name .. "Shoot");

                if v300 then
                    SoundModule:PlayDuplicateSound(v300, nil, nil, true, u281.Skin);
                end;

                u77 = tick();
                v301 = u281.Skin == "Hot Rod" and 0.75 or 1;
                v302 = 1 + (v298 and u44.GunRecoilAimMult or 0);
                v303 = v289[v298 and "Aiming" or "Hip"].ShootingExtra * (1 + (u44[(v298 and "Aim" or "Hip") .. "SpreadMult"] or 0)) * (u79 < 0.001 and 0 or u79) * (u282[(v298 and "Aim" or "Hip") .. "SpreadMult"] or 1);
                u79 = math.min(u79 + 1 / v289.Shooting.BulletsForMax, 1);
                v304 = u78 < 0.001 and 0 or math.floor(u78 * 100) / 100;
                v305 = v303 < 0.001 and 0 or math.floor(v303 * 100) / 100;
                v306 = v304 + v305;
                v307 = CFrame.Angles(v290.Offset or 0, 0, 0);
                v308 = Camera.CFrame;
                v309 = workspace:GetServerTimeNow();
                v310 = math.round(v309 * 10000);
                v311 = Random.new(v310);
                u312 = v311.NextInteger(v311, 1, 1000000000);
                v313 = Random.new(v310);
                v314 = {};

                for _ = 1, u282.Bullets or 1 do
                    v315 = {
                        Radius = v313:NextNumber(0, math.floor(v306 * 100) / 100) / 500,
                        Degree = v313:NextNumber(0, 6.283185307179586)
                    };
                    v316 = math.floor(v306 * 100) / 100;
                    v317 = math.max(1, v316) * 1000000000;
                    v315.ID = v313:NextInteger(1, (math.ceil(v317)));
                    table.insert(v314, v315);
                end;

                v318 = v299.Position;
                v319 = Parent.PrimaryPart.CFrame * CFrame.new(0, 1.5, 0);
                u320 = {};
                v321, v322 = RaycastUtil:MouseRaycast(u5, { Parent, VFX_PARTS });

                if u44.HideTracer then
                    v323 = "";
                elseif table.find(VFXModule.TracerSkins, u281.Skin) then
                    v323 = u281.Skin .. "Bullet";
                else
                    v323 = u282.TracerName;
                end;

                for _, v in pairs(v314) do
                    v324 = v307 * CFrame.Angles(math.sin(v.Degree) * v.Radius, math.cos(v.Degree) * v.Radius, 0);
                    u325 = v.ID;
                    VFXModule:CreateProjectile({
                        FilterType = "Blacklist",
                        Position = v318,
                        Direction = (CFrame.new(v318, v321) * v324).LookVector,
                        PositionFirst = v319.p,
                        DirectionFirst = (v308 * v324).LookVector,
                        Filters = {
                            Parent,
                            VFX_PARTS,
                            Drops,
                            Plants
                        },
                        FilterFunction = u282.FilterType or "Hit",
                        VisualizeRay = script:GetAttribute("DebugShowRays"),
                        Speed = v290.Speed * (1 + (u44.SpeedMult or 0)) * (u282.SpeedMult or 1),
                        Gravity = v290.Gravity * (u282.GravityMult or 1),
                        MaxRange = v290.MaxRange * (1 + (u44.RangeMult or 0)) * (u282.RangeMult or 1),
                        Size = u282.BulletSize,
                        TracerName = v323,

                        HitFunction = function(...) -- Line: 1119, Name: HitFunction
                            -- upvalues: u261 (ref), u312 (copy), u325 (copy), u320 (copy), u282 (ref)
                            local v439 = { ... };
                            u261({
                                v439[1],
                                v439[2],
                                v439[3],
                                v439[4],
                                u312,
                                u325,
                                u320
                            }, nil, u282.Impact);
                        end,

                        MissFunction = function() -- Line: 1123, Name: MissFunction
                            -- upvalues: u3 (ref), u325 (copy), u312 (copy)
                            u3("Fire", "d\147e\1R\169#o\249,9\133\153`B4q^W\6", "\160\29\229\248\31\16pJ\140]\137-\250\171Z_\1\135\223#", u325, u312);
                        end
                    });
                end;

                v284 = v284 - 1;
                script:SetAttribute("LocalAmmo", v284);
                u3("Fire", "d\147e\1R\169#o\249,9\133\153`B4q^W\6", "#\250)\215\28\1U\143\237}\154\218\231Cl-\15H\1\147", v309, v283.Name, v308, v319:PointToObjectSpace(v318), v319, v304, v305, v321);
                v326 = TableUtil:TableRandom(u293.Pos.X);
                v327 = TableUtil:TableRandom(u293.Pos.Y);
                v328 = Vector3.new(v326, v327, TableUtil:TableRandom(u293.Pos.Z)) * v301;
                v329 = TableUtil:TableRandom(u293.Rot.Y);
                v330 = math.rad(v329);
                v331 = TableUtil:TableRandom(u293.Rot.X);
                v332 = math.rad(v331) * v302;
                v333 = TableUtil:TableRandom(u293.Rot.Z);
                v334 = math.rad(v333) * v302;
                v335 = Vector3.new(v330, v332, v334) * v301;
                v336 = u293.StartTime;
                u85.Code = math.random(1, 100000000);
                u85.X = 0;
                u85.Increment = 1.5 / v336;
                u85.PrevPos = u85.Pos;
                u85.PrevRot = u85.Rot;
                u85.NewPos = v328;
                u85.NewRot = v335;
                u337 = u85.Code;
                u83 = 0;
                u84 = u84 + 1;
                u86 = tick();
                v338, v339 = u294.RecoilStart(u84);
                v340, v341 = u294.RecoilFinish(u84);
                v342 = v338 + TableUtil:TableRandom(u294.Shake.Y);
                v343 = v339 + TableUtil:TableRandom(u294.Shake.X);
                v344 = -math.rad(v343);
                u345 = math.rad(v342);
                u346 = v344;
                v347 = -math.rad(v341);
                u348 = math.rad(v340);
                u349 = v347;
                u350 = tick();
                u351 = 0;
                u352 = 0;
                u353 = 0;
                u354 = u294.Duration - u294.FinishStart;
                task.spawn(function() -- Line: 1166
                    -- upvalues: u44 (ref), PreferredInputController (ref), u351 (ref), u294 (copy), u345 (ref), u346 (ref), u82 (ref), u353 (ref), u352 (ref), u354 (copy), u348 (ref), u349 (ref), u350 (copy), u293 (copy), u85 (ref), u337 (copy)
                    local v440 = true;
                    local v441 = false;

                    while v440 or not v441 do
                        local v442 = script:GetAttribute("DebugFrameworkSpeed");
                        local v443 = Run.Heartbeat:Wait() * v442;

                        if v440 then
                            local v444 = (script:GetAttribute("Aiming") and 0.7 or 1.2) * (StateController:GetAttribute("IsCrouch") and 0.75 or 1) * (1 + (u44.RecoilMult or 0));
                            local v445 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";
                            local v446 = v444 * (v445 and 0.65 or 1);
                            local v447 = u351;
                            u351 = math.min(u351 + v443, u294.FinishStart);
                            local v448 = (u351 - v447) / u294.FinishStart * v446;
                            local v449 = CFrame.Angles(u345 * v448, u346 * v448, 0);
                            u82 = u82 * v449;
                            Camera.CFrame = Camera.CFrame * v449;
                            local v450 = u353;
                            u352 = math.min(u352 + v443, u294.Duration);
                            u353 = math.clamp(u352 - u294.FinishStart, 0, u354);
                            local v451 = (u353 - v450) / u354 * v446;
                            local v452 = CFrame.Angles(u348 * v451, u349 * v451, 0);
                            u82 = u82 * v452;
                            Camera.CFrame = Camera.CFrame * v452;

                            if tick() - u350 >= u294.Duration / v442 then
                                v440 = false;
                            end;
                        end;

                        if tick() - u350 >= u293.StartTime / v442 and not v441 then
                            v441 = true;

                            if u85.Code == u337 or not u85.Code then
                                local v453 = Vector3.new();
                                local v454 = Vector3.new();
                                local EndTime = u293.EndTime;
                                u85.Code = math.random(1, 100000000);
                                u85.X = 0;
                                u85.Increment = 1.5 / EndTime;
                                u85.PrevPos = u85.Pos;
                                u85.PrevRot = u85.Rot;
                                u85.NewPos = v453;
                                u85.NewRot = v454;
                            end;
                        end;
                    end;
                end);
                task.defer(u233, v288, v298 and 0.4 or 1);

                if v286.BurstRPM > 0 then
                    task.wait(v297);

                    if v284 <= 0 or (u152("Equip") or (InventoryController:GetAttribute("Open") or (CameraController:GetAttribute("ViewmodelCFrame") or tick() - u67 < 0.1))) then
                        script:SetAttribute("Using", false);

                        if not u281 then
                            return;
                        end;

                        break;
                    else
                        v355 = InventoryController.Fetch:Invoke();

                        if v355 then
                            v356 = v355.Toolbar;

                            if v356 then
                                v357 = v356[script:GetAttribute("Equipped")];

                                if v357 == nil then
                                    v357 = false;
                                elseif v357 == 0 then
                                    v357 = false;
                                end;
                            else
                                v357 = nil;
                            end;
                        else
                            v357 = nil;
                        end;

                        if v357 and (u281.Durability ~= nil and u281.Durability > 0) then
                            continue;
                        else
                            break;
                        end;
                    end;
                end;
            end;

            if v287 then
                u165("AimStart");
                u165("AimHold");
                u49 = "None";
                u52 = false;

                for _, child in pairs(u12:GetChildren()) do
                    if child:IsA("BasePart") and child.Name:find("Arrow") then
                        child.Transparency = 1;
                    end;
                end;
            end;

            task.wait(v296);
            v358 = v286.BoltAnimSpeed or 1;

            if not u22.Local.Bolt then
                goto l1;
            end;

            v359 = u9;
            v360 = u160("Bolt", v358);

            if v360 then
                script:SetAttribute("CanUse", true);
                task.wait(v360.Length);
                script:SetAttribute("CanUse", nil);

                if v359 and v359.Parent then
                    u165("Bolt");
                    goto l1;
                end;
            end;
        end;
    end);
end;

local function u456() -- Line: 1509
    -- upvalues: u32 (ref)
    u32 = false;
end;

u275 = function(p457) -- Line: 1513
    -- upvalues: u33 (ref), u50 (ref), u276 (ref), Items (copy), ToolInfo (copy), u455 (ref), u51 (ref), u152 (copy), u90 (ref), u67 (ref), u160 (copy), u165 (copy), u44 (ref), ItemClass (copy), u37 (ref)
    local v458 = u33;

    if p457 then
        u33 = p457;
    else
        u33 = true;
    end;

    if p457 == nil and v458 == "Auto" then
        return;
    end;

    while u33 ~= false do
        u50 = false;
        local v459 = script:GetAttribute("Using");

        if u33 == "Auto" and not v459 then
            u276();
        end;

        local v460 = script:GetAttribute("Aiming");
        local v461 = InventoryController.Fetch:Invoke();
        local v462;

        if v461 then
            local Toolbar2 = v461.Toolbar;

            if Toolbar2 then
                v462 = Toolbar2[script:GetAttribute("Equipped")];

                if v462 == nil then
                    v462 = false;
                elseif v462 == 0 then
                    v462 = false;
                end;
            else
                v462 = nil;
            end;
        else
            v462 = nil;
        end;

        local v463;

        if v462 then
            v463 = Items[v462.ID];
        else
            v463 = v462;
        end;

        local v464;

        if v463 then
            v464 = ToolInfo[v463.Name];
        else
            v464 = v463;
        end;

        if v464 then
            v464 = v464.Weapon;
        end;

        local v465;

        if v464 then
            v465 = v464.ThrowInfo;
        else
            v465 = v464;
        end;

        if v465 and (v465.Logic == "Grenade" or v465.Logic == "PlaceableGrenade") then
            return u455(true);
        end;

        local v466 = true;

        if v463 and (v463.Type ~= "Bench" and (v463.Name ~= "Blueprint" and (not u51 and (not u152("Equip") and (not u90 and (not u152("Bolt") and (not u152("Throw") and (not InventoryController:GetAttribute("Open") and (not CameraController:GetAttribute("FreeLooking") and (tick() - u67 >= 0.1 and v462)))))))))) then
            if v463.Type == "Tool" and (v464.AimDownSpeed == nil or v459) then
                v466 = false;
            end;
        else
            v466 = false;
        end;

        if v466 then
            if not v460 then
                script:SetAttribute("Aiming", true);
                u160("Aim");
                u165("Inspect");

                if type(v462) == "table" then
                    u44 = ItemClass.AttachmentStats(v462, script:GetAttribute("Aiming"));
                end;
            end;

            u50 = u37 >= 1;
        elseif v460 then
            script:SetAttribute("Aiming", false);
            u165("Aim");

            if type(v462) == "table" then
                u44 = ItemClass.AttachmentStats(v462, script:GetAttribute("Aiming"));
            end;
        end;

        Run.Heartbeat:Wait();
    end;

    script:SetAttribute("Aiming", false);
    u165("Aim");
end;

u276 = function() -- Line: 1561
    -- upvalues: u33 (ref)
    u33 = false;
end;

local function u506(p467) -- Line: 1565
    -- upvalues: u89 (ref), u22 (copy), u152 (copy), u90 (ref), Items (copy), u44 (ref), NumberUtil (copy), ToolInfo (copy), u3 (copy), u12 (ref), WeldModule (copy), u9 (ref), u52 (ref), u165 (copy), u91 (ref), u160 (copy)
    u89 = true;
    local v468 = 0;
    local v469 = true;
    local v470 = {};
    local v471 = nil;
    local v472 = nil;
    local v473 = false;
    local v474 = nil;

    while true do
        if v468 >= 0.5 or p467 and not v469 then
            if v468 <= 0 or (not v470 or v468 < 0.5 and (v471 and (v472 and v472 <= v471.Amount))) then
                return false;
            end;

            local v475 = nil;

            if v468 >= 0.5 then
                local v476 = {};

                for _, v in pairs(v470) do
                    local v477 = Items[v.ID];
                    local v478 = {
                        Selectable = true,
                        Image = v477.AmmoWheelImage,
                        Name = v477.Name,
                        Description = v477.Description,
                        Cost = NumberUtil:FormatNumber(v.Amount) .. " Left",
                        SelectFirst = v.IsEquipped
                    };
                    table.insert(v476, v478);
                end;

                local v479 = WheelController.Open:Invoke(v476, "Reload", true);

                if not v479 then
                    return;
                end;

                local v480 = v470[v479];

                if not v480 or v471 and (v471.ID == v480.ID and (v472 and v472 <= v471.Amount)) then
                    return;
                end;

                v475 = v480.ID;
            elseif v473 and not p467 then
                return;
            end;

            if v474 ~= script:GetAttribute("Equipped") then
                return;
            end;

            local v481 = InventoryController.Fetch:Invoke();
            local u482;

            if v481 then
                local Toolbar2 = v481.Toolbar;

                if Toolbar2 then
                    u482 = Toolbar2[script:GetAttribute("Equipped")];

                    if u482 == nil then
                        u482 = false;
                    elseif u482 == 0 then
                        u482 = false;
                    end;
                else
                    u482 = nil;
                end;
            else
                u482 = nil;
            end;

            local Weapon = ToolInfo[Items[u482.ID].Name].Weapon;
            u3("Fire", "d\147e\1R\169#o\249,9\133\153`B4q^W\6", "\197s5m:\246\237\135\220Hr\235\1\239\214\\\209\212\219\219", workspace:GetServerTimeNow(), v475 or "None");

            if not v475 then
                for _, v in pairs(v470) do
                    if v.IsEquipped then
                        v475 = v.ID;
                        break;
                    end;
                end;
            end;

            local u483 = v475 or v470[1].ID;

            if p467 then
                return true, u483;
            end;

            local v484 = script:GetAttribute("Aiming");
            task.delay(v473 and v484 and 1 or 0.1, function() -- Line: 1678
                -- upvalues: u12 (ref), WeldModule (ref), u482 (copy), u483 (copy), u9 (ref)
                if not (u12 and u12.Parent) then
                    return;
                end;

                WeldModule:WeldAttachments(u12, u482, nil, nil, u483, u9:GetScale());
            end);

            if v473 then
                if v484 then
                    u52 = true;
                end;

                return;
            end;

            u165("Inspect");
            u90 = true;
            local BoltFed = Weapon.BoltFed;
            local ReloadAnimSpeed = Weapon.ReloadAnimSpeed;

            if type(ReloadAnimSpeed) == "table" then
                ReloadAnimSpeed = ReloadAnimSpeed[u482.Skin or "Default"] or (ReloadAnimSpeed.Default or ReloadAnimSpeed);
            end;

            local u485 = u9;
            local u486 = u91;
            task.delay(0.1, function() -- Line: 1697
                -- upvalues: u485 (copy), u165 (ref)
                if not (u485 and u485.Parent) then
                    return;
                end;

                u165("Unloaded", 0);
                u165("Loaded", 0);
            end);

            if BoltFed then
                local v487 = ReloadAnimSpeed or {};
                local v488 = u160("Reload1", v487[1]);

                if not v488 then
                    return;
                end;

                task.wait(v488.Length / v487[1]);

                if not (u485 and u485.Parent) then
                    return;
                end;

                local u489 = nil;
                u489 = InputService.InputBegan:Connect(function(p490, p491) -- Line: 1709
                    -- upvalues: u486 (ref), u91 (ref), u3 (ref), u489 (ref)
                    local UserInputType = p490.UserInputType;

                    if InputService:GetFocusedTextBox() or (p491 or UserInputType ~= Enum.UserInputType.MouseButton1) then
                        return;
                    end;

                    if u486 == u91 then
                        u3("Fire", "d\147e\1R\169#o\249,9\133\153`B4q^W\6", "\197s5m:\246\237\135\220Hr\235\1\239\214\\\209\212\219\219", workspace:GetServerTimeNow(), "Cancel");
                    end;

                    u486 = nil;
                    u489:Disconnect();
                end);

                while u486 == u91 do
                    u165("Reload2", 0);
                    local v492 = u160("Reload2", v487[2], 0);

                    if not v492 then
                        return;
                    end;

                    task.wait(v492.Length / v487[2]);

                    if not (u485 and u485.Parent) then
                        return;
                    end;
                end;

                local v493 = u160("Reload3", v487[3]);

                if not v493 then
                    return;
                end;

                task.wait(Weapon.ReloadAnimTime or v493.Length / v487[3]);
            else
                local v494 = u160("Reload", ReloadAnimSpeed);

                if not v494 then
                    return;
                end;

                local v495 = os.clock();
                local v496 = Weapon.ReloadAnimTime or v494.Length / ReloadAnimSpeed;

                while os.clock() - v495 < v496 do
                    if not u90 then
                        u165("Reload");

                        return;
                    end;

                    task.wait();
                end;
            end;

            u90 = false;

            return;
        end;

        v469 = false;
        local v497 = p467 and 0.1 or Run.Heartbeat:Wait();
        local v498 = InventoryController.Fetch:Invoke();
        local v499;

        if v498 then
            local Toolbar2 = v498.Toolbar;

            if Toolbar2 then
                v499 = Toolbar2[script:GetAttribute("Equipped")];

                if v499 == nil then
                    v499 = false;
                elseif v499 == 0 then
                    v499 = false;
                end;
            else
                v499 = nil;
            end;
        else
            v499 = nil;
        end;

        v474 = script:GetAttribute("Equipped");
        v473 = (u22.Local.Reload or u22.Local.Reload1) == nil;

        if u152("Equip") or (u90 or (u152("Reload") or (u152("Bolt") or (InventoryController:GetAttribute("Open") or (script:GetAttribute("Using") or not v499))))) then
            break;
        end;

        if not u89 then
            break;
        end;

        local v500 = Items[v499.ID];
        local AmmoType = v500.AmmoType;
        v471 = v499.Ammo;

        if v500 == nil or v500.BaseMaxAmmo == nil then
            v472 = false;
        else
            v472 = math.round(v500.BaseMaxAmmo * (1 + (u44 and u44.MaxAmmoMult or 0)));
        end;

        if AmmoType then
            local v501 = InventoryController.Fetch:Invoke();
            v470 = {};

            for _, v in pairs({ "Inventory", "Toolbar" }) do
                for _, v2 in pairs(v501[v]) do
                    if v2 ~= 0 and v2.Amount > 0 then
                        local ID = v2.ID;
                        local Amount = v2.Amount;
                        local v502 = Items[ID];
                        local AmmoType2 = v502.AmmoType;

                        if v502.Type:find("Ammo") and AmmoType == AmmoType2 then
                            local v503 = false;

                            for _, v3 in pairs(v470) do
                                if v3.ID == ID then
                                    v3.Amount = v3.Amount + Amount;
                                    v503 = true;
                                    break;
                                end;
                            end;

                            if not v503 then
                                local v504 = {
                                    ID = ID,
                                    Amount = Amount
                                };
                                local v505;

                                if v471 == nil then
                                    v505 = false;
                                else
                                    v505 = v471.ID == ID;
                                end;

                                v504.IsEquipped = v505;
                                table.insert(v470, v504);
                            end;
                        end;
                    end;
                end;
            end;

            if #v470 > 0 then
                v468 = v468 + v497;

                if p467 then
                    break;
                end;
            end;
        end;
    end;

    v468 = 0;

    if not u89 then
        break;
    end;

    if p467 then
        break;
    end;
end;

local function _() -- Line: 1759
    -- upvalues: u89 (ref)
    u89 = false;
    WheelController.Close:Invoke("Reload");
end;

local function u507() -- Line: 1764
    -- upvalues: u8 (ref), u152 (copy), u90 (ref), u165 (copy), u160 (copy)
    if u8 == nil or (u152("Equip") or (u90 or (script:GetAttribute("Using") or script:GetAttribute("Aiming")))) then
        return;
    end;

    u165("Inspect");
    u160("Inspect");
end;

local function u512() -- Line: 1770
    -- upvalues: u9 (ref), Items (copy), u94 (ref), u3 (copy), u180 (copy)
    local v508 = InventoryController.Fetch:Invoke();
    local v509;

    if v508 then
        local Toolbar2 = v508.Toolbar;

        if Toolbar2 then
            v509 = Toolbar2[script:GetAttribute("Equipped")];

            if v509 == nil then
                v509 = false;
            elseif v509 == 0 then
                v509 = false;
            end;
        else
            v509 = nil;
        end;
    else
        v509 = nil;
    end;

    if not (v509 and u9) then
        return;
    end;

    local Attachments = v509.Attachments;

    if not Attachments then
        return;
    end;

    local v510 = nil;

    for _, v in pairs(Attachments) do
        local AttachmentStats = Items[v.ID].AttachmentStats;

        if AttachmentStats and AttachmentStats.Toggle then
            v.On = not v.On;
            v510 = v.ID;
        end;
    end;

    if not v510 then
        return;
    end;

    local v511 = tick();

    if v511 - u94 < 0.15 then
        return;
    end;

    u94 = v511;
    script.AttachmentToggle.PlaybackSpeed = math.random(95, 105) / 100;
    Sound:PlayLocalSound(script.AttachmentToggle);
    u3("Fire", "d\147e\1R\169#o\249,9\133\153`B4q^W\6", "S\161\235\145\2Z\164\240p\181\2x[\242\232\198\199\1\132+", v510);
    u180(v509);
end;

local function u514() -- Line: 1796
    -- upvalues: Codelock (copy), PreferredInputController (copy), Humanoid (copy), u71 (ref), u70 (ref)
    if WheelController:GetAttribute("Open") or (InteractController:GetAttribute("Dialog") or Codelock.Visible) then
        local v513 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

        if v513 then
            return;
        end;
    end;

    if not Humanoid.Parent then
        return;
    end;

    if Humanoid.SeatPart then
        Humanoid.Sit = false;
    end;

    if tick() - u71 < 0.25 or u70 then
        return;
    end;

    Humanoid.Jump = true;
end;

local function u517(u515) -- Line: 1805
    if u515.Name == "Reticle" then
        task.spawn(function() -- Line: 1807
            -- upvalues: u515 (copy)
            if not (u515 and u515.Parent) then
                return;
            end;

            local ReticleFront = u515:WaitForChild("ReticleFront", 5);

            if not ReticleFront then
                return;
            end;

            ReticleFront.Enabled = false;
        end);
        local ReticleBack = u515:WaitForChild("ReticleBack", 5);

        if not ReticleBack then
            return;
        end;

        ReticleBack.Enabled = false;
    end;

    for i = 1, 2 do
        if u515.Name == (i == 1 and "Base" or "Laser") then
            for i2 = 1, 2 do
                local u516 = u515:WaitForChild(i == 1 and (i2 == 1 and "Light" or "Extender") or "Laser", 5);

                if not u516 then
                    break;
                end;

                if i2 == 2 then
                    u516 = u516:FindFirstChild("Light");

                    if not u516 then
                        break;
                    end;
                end;

                u516.Enabled = false;
                u516:GetPropertyChangedSignal("Enabled"):Connect(function() -- Line: 1828
                    -- upvalues: u516 (ref)
                    u516.Enabled = false;
                end);

                if i == 2 then
                    break;
                end;
            end;
        end;
    end;
end;

local function u519(p518) -- Line: 1837
    -- upvalues: u517 (copy)
    if not (p518 and p518.Parent) then
        return;
    end;

    p518.ChildAdded:Connect(u517);

    for _, child in pairs(p518:GetChildren()) do
        u517(child);
    end;
end;

local function u523(p520) -- Line: 1846
    if p520.Name == "Bolt" then
        for _, child in pairs(p520:GetChildren()) do
            if child:IsA("Beam") then
                child.Enabled = false;
            end;
        end;

        p520.ChildAdded:Connect(function(p521) -- Line: 1852
            if not p521:IsA("Beam") then
                return;
            end;

            p521.Enabled = false;
        end);

        return;
    end;

    if p520:IsA("Beam") then
        p520.Enabled = false;

        return;
    end;

    if p520.Name == "LightPart" then
        for _, child in pairs(p520:GetChildren()) do
            child.Enabled = false;
            child:GetPropertyChangedSignal("Enabled"):Connect(function() -- Line: 1861
                -- upvalues: child (copy)
                child.Enabled = false;
            end);
        end;

        p520.ChildAdded:Connect(function(u522) -- Line: 1865
            u522.Enabled = false;
            u522:GetPropertyChangedSignal("Enabled"):Connect(function() -- Line: 1867
                -- upvalues: u522 (copy)
                u522.Enabled = false;
            end);
        end);
    end;
end;

local function u526(u524) -- Line: 1874
    -- upvalues: u523 (copy), u519 (copy)
    if not (u524 and (u524.Parent and u524:IsA("Model"))) then
        return;
    end;

    if u524.Name == "HolsterModel" or (u524.Name == "Crossbow" or (u524.Name == "Wooden Bow" or u524.Name == "Lighter")) then
        u524.ChildAdded:Connect(u523);

        for _, child in pairs(u524:GetChildren()) do
            u523(child);
        end;
    end;

    task.defer(function() -- Line: 1882
        -- upvalues: u524 (copy), u519 (ref)
        local Attachments = u524:WaitForChild("Attachments", 5);

        if not Attachments then
            return;
        end;

        Attachments.ChildAdded:Connect(function(p525) -- Line: 1885
            -- upvalues: u519 (ref)
            u519(p525);
        end);

        for _, child in pairs(Attachments:GetChildren()) do
            u519(child);
        end;
    end);
end;

local u527 = nil;

local function u532(p528) -- Line: 1896
    -- upvalues: u527 (ref), Main (copy)
    local v529 = p528 == true;

    if v529 and not Player:GetAttribute("Armor_NVG") then
        u527 = false;

        return;
    end;

    if v529 == u527 then
        return;
    end;

    local NVGFilmGrain = Main:FindFirstChild("NVGFilmGrain");

    if not NVGFilmGrain then
        return;
    end;

    u527 = v529;
    Main.NVGVignette.Visible = u527;
    NVGFilmGrain.Visible = u527;
    Lighting.NVG.Enabled = u527;
    Lighting.ExposureCompensation = u527 and 3.5 or 0.1;
    Lighting.Atmosphere.Glare = u527 and 1.5 or 0.82;
    Lighting.Atmosphere.Haze = u527 and 0.5 or 2.08;

    if u527 then
        local u530 = 0;
        Run:BindToRenderStep("NVG", Enum.RenderPriority.Last.Value + 1, function() -- Line: 1914
            -- upvalues: u530 (ref), NVGFilmGrain (copy)
            local v531 = os.clock();
            Lighting.Atmosphere.Density = Lighting.Atmosphere:GetAttribute("Density") * 0.7;

            if v531 - u530 < 0.020833333333333332 then
                return;
            end;

            u530 = v531;

            if NVGFilmGrain.Parent then
                NVGFilmGrain.TileSize = UDim2.new(math.random(214, 266) / 1000, 0, math.random(214, 266) / 1000, 0);

                return;
            end;

            Lighting.Atmosphere.Density = Lighting.Atmosphere:GetAttribute("Density");
            Run:UnbindFromRenderStep("NVG");
        end);

        return;
    end;

    Lighting.Atmosphere.Density = Lighting.Atmosphere:GetAttribute("Density");
    pcall(Run.UnbindFromRenderStep, Run, "NVG");
end;

InputService.InputBegan:Connect(function(p533, p534) -- Line: 1935
    -- upvalues: SettingsModule (copy), PreferredInputController (copy), Codelock (copy), GiveBed (copy), RenameBed (copy), u455 (ref), u275 (ref), u506 (copy), u512 (copy), u507 (copy), u514 (copy), u532 (copy), u527 (ref), Items (copy), ToolInfo (copy), u30 (ref), u29 (ref)
    if SettingsModule.MainMenuOpen() then
        return;
    end;

    local UserInputType = p533.UserInputType;

    if InputService:GetFocusedTextBox() then
        return;
    end;

    if WheelController:GetAttribute("Open") or TeamNavigationController:GetAttribute("MapOpen") then
        local v535 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

        if v535 then
            return;
        end;
    end;

    if UserInputType == Enum.UserInputType.MouseButton1 and not (p534 or (Codelock.Visible or (GiveBed.Visible or RenameBed.Visible))) then
        u455();

        return;
    end;

    if UserInputType == Enum.UserInputType.MouseButton2 and (SettingsModule.GetSetting("Controls", "Aim Down Sight") == "MB2" and not p534) then
        u275();

        return;
    end;

    if UserInputType == Enum.UserInputType.Keyboard or UserInputType == Enum.UserInputType.Gamepad1 then
        local KeyCode = p533.KeyCode;
        local v536 = script:GetAttribute("DebugEnableVMMovement");

        if (KeyCode.Name == SettingsModule.GetSetting("Controls", "Reload") or KeyCode.Name == SettingsModule.GetSetting("Gamepad", "Interact/Reload")) and not p534 then
            u506();

            return;
        end;

        if KeyCode.Name == SettingsModule.GetSetting("Controls", "Use Attachment") then
            if not p534 then
                u512();

                return;
            end;
        elseif KeyCode.Name == SettingsModule.GetSetting("Gamepad", "Use Attachment") then
            local v537 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

            if not v537 then
                if not p534 then
                    u512();

                    return;
                end;
            end;
        end;

        if (KeyCode.Name == SettingsModule.GetSetting("Controls", "Inspect") or KeyCode.Name == SettingsModule.GetSetting("Gamepad", "Inspect")) and not p534 then
            u507();

            return;
        end;

        if (KeyCode.Name == SettingsModule.GetSetting("Controls", "Aim Down Sight") or KeyCode.Name == SettingsModule.GetSetting("Gamepad", "Aim Down Sight")) and not p534 then
            u275();

            return;
        end;

        if (KeyCode.Name == SettingsModule.GetSetting("Controls", "Jump") or KeyCode.Name == SettingsModule.GetSetting("Gamepad", "Jump")) and not p534 then
            u514();

            return;
        end;

        if (KeyCode.Name == SettingsModule.GetSetting("Controls", "Use Armor Mod") or KeyCode.Name == SettingsModule.GetSetting("Gamepad", "Use Armor Mod")) and not p534 then
            u532(not u527);

            return;
        end;

        if KeyCode.Name == "ButtonR2" and not (p534 or TeamNavigationController:GetAttribute("MapOpen")) then
            u455();

            return;
        end;

        if KeyCode.Name == SettingsModule.GetSetting("Gamepad", "Aim Down Sight") and not (p534 or TeamNavigationController:GetAttribute("MapOpen")) then
            u275();

            return;
        end;

        if (KeyCode == Enum.KeyCode.J or (KeyCode == Enum.KeyCode.U or (KeyCode == Enum.KeyCode.K or (KeyCode == Enum.KeyCode.I or (KeyCode == Enum.KeyCode.L or KeyCode == Enum.KeyCode.O))))) and v536 then
            local v538 = InventoryController.Fetch:Invoke();
            local v539;

            if v538 then
                local Toolbar2 = v538.Toolbar;

                if Toolbar2 then
                    v539 = Toolbar2[script:GetAttribute("Equipped")];

                    if v539 == nil then
                        v539 = false;
                    elseif v539 == 0 then
                        v539 = false;
                    end;
                else
                    v539 = nil;
                end;
            else
                v539 = nil;
            end;

            if not v539 then
                return;
            end;

            local v540 = ToolInfo[Items[v539.ID].Name];

            if v540 and (v540.Offsets and v540.Offsets.Local) then
                local v541 = script:GetAttribute("DebugVMMovementAmount");
                local v542 = {
                    J = { CFrame.new(-v541, 0, 0), CFrame.Angles(0, v541, 0) },
                    U = { CFrame.new(v541, 0, 0), CFrame.Angles(0, -v541, 0) },
                    K = { CFrame.new(0, -v541, 0), CFrame.Angles(v541, 0, 0) },
                    I = { CFrame.new(0, v541, 0), CFrame.Angles(-v541, 0, 0) },
                    L = { CFrame.new(0, 0, -v541), CFrame.Angles(0, 0, v541) },
                    O = { CFrame.new(0, 0, v541), CFrame.Angles(0, 0, -v541) }
                };
                local v543 = script:GetAttribute("DebugVMRotating") and 2 or 1;

                if v542[KeyCode.Name] then
                    u30 = u30 * v542[KeyCode.Name][v543];
                    task.wait(0.25);

                    while InputService:IsKeyDown(KeyCode) do
                        u30 = u30 * v542[KeyCode.Name][v543];
                        task.wait();
                    end;
                end;
            end;
        elseif KeyCode == Enum.KeyCode.P and v536 then
            local v544 = InventoryController.Fetch:Invoke();
            local v545;

            if v544 then
                local Toolbar2 = v544.Toolbar;

                if Toolbar2 then
                    v545 = Toolbar2[script:GetAttribute("Equipped")];

                    if v545 == nil then
                        v545 = false;
                    elseif v545 == 0 then
                        v545 = false;
                    end;
                else
                    v545 = nil;
                end;
            else
                v545 = nil;
            end;

            if not v545 then
                return;
            end;

            local v546 = ToolInfo[Items[v545.ID].Name];

            if v546 and (v546.Offsets and v546.Offsets.Local) then
                local v547 = script:GetAttribute("DebugPrintRoundedDecimalPoints");
                local v548 = {};

                for i, v in pairs({ (u29 * u30):GetComponents() }) do
                    v548[i] = math.ceil(v * 10 ^ v547) / 10 ^ v547;
                end;

                print("CFrame.new(" .. table.concat(v548, ", ") .. ");");
            end;
        elseif KeyCode == Enum.KeyCode.H and (v536 or Run:IsStudio()) and not p534 then
            Player.CameraMode = Enum.CameraMode.Classic;
            Player.CameraMaxZoomDistance = 10;
        end;
    end;
end);
InputService.InputEnded:Connect(function(p549, p550) -- Line: 2015
    -- upvalues: u456 (ref), SettingsModule (copy), u276 (ref), u89 (ref), PreferredInputController (copy), u512 (copy)
    local UserInputType = p549.UserInputType;

    if UserInputType == Enum.UserInputType.MouseButton1 then
        u456();

        return;
    end;

    if UserInputType == Enum.UserInputType.MouseButton2 and SettingsModule.GetSetting("Controls", "Aim Down Sight") == "MB2" then
        u276();

        return;
    end;

    if UserInputType == Enum.UserInputType.Keyboard or UserInputType == Enum.UserInputType.Gamepad1 then
        local Name = p549.KeyCode.Name;

        if Name == SettingsModule.GetSetting("Controls", "Aim Down Sight") or Name == SettingsModule.GetSetting("Gamepad", "Aim Down Sight") then
            u276();

            return;
        end;

        if Name == SettingsModule.GetSetting("Controls", "Reload") or Name == SettingsModule.GetSetting("Gamepad", "Interact/Reload") then
            u89 = false;
            WheelController.Close:Invoke("Reload");

            return;
        end;

        if Name == "ButtonR2" then
            u456();

            return;
        end;

        local v551 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

        if v551 and (Name == SettingsModule.GetSetting("Gamepad", "Use Attachment") and not SettingsModule.MainMenuOpen()) then
            u512();
        end;
    end;
end);
PreferredInputController:GetAttributeChangedSignal("PreferredInput"):Connect(function() -- Line: 2036
    -- upvalues: PreferredInputController (copy), u9 (ref), u75 (ref)
    local v552 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

    if v552 and (u9 and u9.Parent) then
        u75 = 0.3;
    end;
end);
InputService.InputChanged:Connect(function(p553) -- Line: 2041
    -- upvalues: u55 (ref), u56 (ref), u34 (ref), SettingsModule (copy), PreferredInputController (copy)
    local UserInputType = p553.UserInputType;

    if UserInputType ~= Enum.UserInputType.MouseMovement then
        if UserInputType == Enum.UserInputType.Gamepad1 and (p553.KeyCode == Enum.KeyCode.Thumbstick2 and not InventoryController:GetAttribute("Open")) then
            local v554 = SettingsModule.GetSetting("Gamepad", "Mouse Sensitivity");

            if script:GetAttribute("Aiming") then
                v554 = SettingsModule.GetSetting("Gamepad", "Aiming Sensitivty");
            end;

            local v555 = PreferredInputController:GetAttribute("JoystickDeadzone") or 0.225;
            local v556 = p553.Position.Y < v555 and p553.Position.Y > -v555 and 0 or p553.Position.Y;
            local v557 = math.max((p553.Position.X < v555 and p553.Position.X > -v555 and 0 or p553.Position.X) * 50 * v554, -150);
            u55 = math.min(v557, 150);
            local v558 = math.max(v556 * 50 * v554, -150);
            u56 = math.min(v558, 150);
            u34 = tick();
        end;

        return;
    end;

    local v559 = math.max(p553.Delta.x * 1.5, -150);
    u55 = math.min(v559, 150);
    local v560 = math.max(p553.Delta.y * 1.5, -150);
    u56 = math.min(v560, 150);
    u34 = tick();
end);
Humanoid.StateChanged:Connect(function(p561, p562) -- Line: 2070
    -- upvalues: u66 (ref), Parent (copy), Humanoid (copy), u70 (ref), NumberUtil (copy), u71 (ref), u114 (copy)
    local v563 = p562 == Enum.HumanoidStateType.Landed;

    if p562 == Enum.HumanoidStateType.Jumping then
        u66 = 2;

        if not Parent or (not Parent.Parent or (not Humanoid or Humanoid.Health <= 0)) then
            return;
        end;

        local PrimaryPart = Parent.PrimaryPart;

        if not PrimaryPart then
            return;
        end;

        local Velocity = PrimaryPart.Velocity;
        local MoveDirection = Humanoid.MoveDirection;
        local Magnitude = Vector3.new(Velocity.X, 0, Velocity.Z).Magnitude;
        local v564 = Humanoid.WalkSpeed / 3 <= Magnitude and Vector3.new(MoveDirection.X, 0, MoveDirection.Z) or Vector3.new();

        if u70 and u70.Parent then
            u70:Destroy();
        end;

        u70 = Instance.new("BodyVelocity");
        u70.MaxForce = Vector3.new(20000, 0, 20000);
        u70.Velocity = v564 * math.clamp(Magnitude, 6, 18);
        local v565 = u70.Velocity.Magnitude <= 0.01;
        u70.Name = "JumpForce";
        u70.Parent = PrimaryPart;
        local v566 = os.clock();
        local v567 = 1;

        while v567 >= 0 do
            local v568 = Run.Heartbeat:Wait();

            if not (u70 and u70.Parent) then
                break;
            end;

            if os.clock() - v566 >= (v565 and 0.1 or 0.15) then
                local v569 = NumberUtil:Lerp(v567, 0, v568 * 1.15);
                v567 = v569 <= 0.01 and 0 or v569;
                u70.MaxForce = u70.MaxForce:Lerp(Vector3.new(), v567);
            end;
        end;
    else
        if v563 or p562 == Enum.HumanoidStateType.Running then
            u66 = 0;

            if u70 and u70.Parent then
                u71 = tick();
                u70:Destroy();
            end;

            u70 = nil;

            if v563 == false or StateController:GetAttribute("IsCrouch") then
                return;
            end;

            u114.Target = u114.Target + Vector3.new(0, -1, 0);

            return;
        end;

        if p562 == Enum.HumanoidStateType.Freefall or p561 == Enum.HumanoidStateType.Freefall then
            u66 = 1;
        end;
    end;
end);
Humanoid.Died:Connect(function() -- Line: 2118
    -- upvalues: u95 (ref), u170 (copy)
    u95:Disconnect();
    u170();
end);
Humanoid:GetAttributeChangedSignal("Downed"):Connect(u170);
Parent.ChildAdded:Connect(function(p570) -- Line: 2125
    -- upvalues: u526 (copy)
    task.wait();
    u526(p570);
end);

for _, child in pairs(Parent:GetChildren()) do
    task.defer(u526, child);
end;

Player:GetAttributeChangedSignal("ArmorSleeves"):Connect(v191);
Player:GetAttributeChangedSignal("Armor_NVG"):Connect(function() -- Line: 2135
    -- upvalues: u532 (copy)
    if not Player:GetAttribute("Armor_NVG") then
        u532(false);
    end;
end);
u532(false);
u3("Setup", "d\147e\1R\169#o\249,9\133\153`B4q^W\6", "\160\29\229\248\31\16pJ\140]\137-\250\171Z_\1\135\223#", function(p571, ...) -- Line: 2143
    -- upvalues: u236 (copy)
    local v572 = { ... };

    if p571 ~= "HitMarker" then
        return;
    end;

    u236(v572[1]);
end);
u3("Setup", "d\147e\1R\169#o\249,9\133\153`B4q^W\6", "\197s5m:\246\237\135\220Hr\235\1\239\214\\\209\212\219\219", function(p573) -- Line: 2151
    -- upvalues: u91 (ref), u90 (ref)
    u91 = u91 + 1;

    if not p573 then
        return;
    end;

    u90 = false;
end);
EquipVM.Event:Connect(function(...) -- Line: 2159
    -- upvalues: u212 (copy), u170 (copy)
    local v574 = ({ ... })[1];

    if v574 and v574 > 0 then
        u212(...);

        return;
    end;

    u170();
end);
UpdateVM.Event:Connect(u180);
PlayVMAnimation.Event:Connect(u160);
v1.TargetFilter = VFX_PARTS;
Crosshair.Up.Size = UDim2.new(0, 2, 0, 8);
Crosshair.Down.Size = UDim2.new(0, 2, 0, 8);
Crosshair.Right.Size = UDim2.new(0, 8, 0, 2);
Crosshair.Left.Size = UDim2.new(0, 8, 0, 2);
pcall(function() -- Line: 2184
    Run:UnbindFromRenderStep("ViewmodelController");
    Run:UnbindFromRenderStep("HumCamOffset");
end);
u95 = Run.Heartbeat:Connect(function(p575) -- Line: 2189
    -- upvalues: ChatController (copy), PreferredInputController (copy), u58 (ref), NumberUtil (copy), u76 (ref), HitMarker (copy), u73 (ref), u72 (ref), Items (copy), ToolInfo (copy), Humanoid (copy), Codelock (copy), SettingsModule (copy), u63 (ref), u59 (ref), u62 (ref), u114 (copy), u115 (ref), u116 (copy), u117 (ref), u106 (copy), u107 (ref), u108 (copy), u113 (ref), u100 (ref), u109 (ref), u111 (ref), u110 (ref), u112 (ref), u85 (copy), u103 (ref), u190 (copy), u9 (ref), u11 (ref), u75 (ref), Crosshair (copy), u80 (ref), u77 (ref), u152 (copy), u49 (ref), u31 (ref), u92 (ref), u44 (ref), u25 (ref), u27 (ref), u26 (ref), u28 (ref), u23 (ref), u24 (ref), u34 (ref), u55 (ref), u56 (ref), u104 (copy), u53 (ref), u54 (ref), u57 (ref), u42 (ref), u43 (ref), u37 (ref), u41 (ref), u38 (ref), u46 (ref), u17 (ref), u36 (ref), u48 (ref), u160 (copy), u165 (copy), u22 (copy), u52 (ref), u506 (copy), WeldModule (copy), u12 (ref), u68 (ref), u18 (ref), u39 (ref), u40 (ref), u66 (ref), u67 (ref), u61 (ref), u60 (ref), u78 (ref), u79 (ref), u105 (copy), u83 (ref), u84 (ref), u86 (ref), u87 (ref), u82 (ref), u90 (ref), u93 (ref), u81 (ref), Scope (copy), Size (copy), u216 (copy), Toolbar (copy), Stats (copy), GamepadControls (copy), u29 (ref), u101 (ref), u96 (ref), u30 (ref), u65 (ref), u88 (ref), u69 (ref), u97 (ref), u98 (ref), u64 (ref), u99 (ref)
    local v576 = script:GetAttribute("DebugDisableScriptAnims") or (WheelController:GetAttribute("Open") or InventoryController:GetAttribute("Open") or ChatController:GetAttribute("Typing")) and PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";
    local v577 = script:GetAttribute("Aiming");
    local v578 = script:GetAttribute("Using");
    local v579 = StateController:GetAttribute("Direction");
    local v580 = StateController:GetAttribute("IsSprint");
    local v581 = StateController:GetAttribute("IsCrouch");
    local v582 = script:GetAttribute("DebugFrameworkSpeed");
    local v583 = CameraController:GetAttribute("UI");
    local v584 = script:GetAttribute("CanUse");
    local v585 = p575 * v582;
    local v586 = v585 / 0.016666666666666666;
    local v587 = math.clamp(0.016666666666666666 / v585, 0.001, 100);

    if u58 then
        u58 = math.abs(u58 - v587) <= 0.001 and v587 and v587 or NumberUtil:Lerp(u58, v587, (math.clamp(0.25 * v586, 0, 1)));
    else
        u58 = v587;
    end;

    local v588;

    if u76 < 1 then
        v588 = v583;
    else
        v588 = false;
    end;

    if v588 then
        u76 = math.min(u76 + v585 * 5, 1);
        local v589 = u76 < 0.1 and u76 * -8 + 1 or (u76 <= 0.75 and 0.2 or (u76 * 4 - 3) * 0.8 + 0.2);

        for _, child in pairs(HitMarker:GetChildren()) do
            child.BackgroundTransparency = v589;
        end;

        local v590 = (u76 - 1) ^ 3 * -15 + 8;
        HitMarker.Up.Position = UDim2.new(0, 0, 0, -v590);
        HitMarker.Left.Position = UDim2.new(0, -v590, 0, 0);
        HitMarker.Down.Position = UDim2.new(0, 0, 0, v590 + 2);
        HitMarker.Right.Position = UDim2.new(0, v590 + 2, 0, 0);
    end;

    HitMarker.Visible = v588;
    local v591 = v580 and 5 or 0;
    u73 = math.abs(u73 - v591) <= 0.01 and v591 and v591 or NumberUtil:Lerp(u73, v591, (math.clamp(0.15 * v586, 0, 1)));
    Camera.FieldOfView = u72 + u73;
    local v592 = InventoryController.Fetch:Invoke();
    local v593;

    if v592 then
        local Toolbar2 = v592.Toolbar;

        if Toolbar2 then
            v593 = Toolbar2[script:GetAttribute("Equipped")];

            if v593 == nil then
                v593 = false;
            elseif v593 == 0 then
                v593 = false;
            end;
        else
            v593 = nil;
        end;
    else
        v593 = nil;
    end;

    local v594;

    if v593 then
        v594 = Items[v593.ID];
    else
        v594 = v593;
    end;

    local v595;

    if v594 then
        v595 = ToolInfo[v594.Name];
    else
        v595 = v594;
    end;

    local v596;

    if v595 then
        v596 = v595.Weapon;
    else
        v596 = v595;
    end;

    local v597 = v596 and (v596.VMMovementMults or {}) or {};
    local v598 = Humanoid.WalkSpeed / 10;
    local v599 = v579 == "" and 0 or math.max(v598, 0.5);
    local v600 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";
    local v601 = v600 and (InventoryController:GetAttribute("Open") or (Codelock.Visible or (SettingsModule.MainMenuOpen() or ChatController:GetAttribute("Typing")))) and 0 or v599;
    u63 = math.abs(v601 - u63) <= 0.01 and v601 and v601 or NumberUtil:Lerp(u63, v601, (math.clamp(0.15 * v586, 0, 1)));
    u59 = math.abs(u59 - v598) <= 0.01 and v598 and v598 or NumberUtil:Lerp(u59, v598, (math.clamp(0.12 * v586, 0, 1)));
    u62 = u62 + v585 * 6.5 * v598;
    local v602 = v597.Bobbing or 1;
    local v603 = (math.sin(u62) * 0.05 + math.sin(u62 * 1.6) * 0.007) * u63;
    local v604 = (math.cos(u62 * 2) * 0.0225 + math.cos(u62 * 2.2) * 0.007) * 0.9 * u63;
    local Target = u114.Target;

    if Target ~= Vector3.new() then
        u114.Target = Target.X ^ 2 + Target.Y ^ 2 + Target.Z ^ 2 <= 0.01 and Vector3.new() or Target:Lerp(Vector3.new(), (math.clamp(0.2 * v586, 0, 1)));
    end;

    u115 = u114.Position;
    local Target2 = u116.Target;

    if Target2 ~= Vector3.new() then
        u116.Target = Target2.X ^ 2 + Target2.Y ^ 2 + Target2.Z ^ 2 <= 0.01 and Vector3.new() or Target2:Lerp(Vector3.new(), (math.clamp(0.3 * v586, 0, 1)));
    end;

    u117 = u116.Position;
    u106.Target = v579 == "" and Vector3.new() or Vector3.new(v603, v604 * 1.5, 0) * -2;
    u107 = u106.Position;
    u108.Target = u113 * v586;
    local Position = u108.Position;
    u100 = CFrame.Angles(Position.Y, Position.X, Position.Z);
    u109 = u108.Target == Vector3.new() and (u109 + v585 or 0) or 0;

    if u111 <= u109 then
        local v605 = math.clamp(u110 + 0.1 * v586, 0, 1);
        u100 = u112:Lerp(CFrame.new(), 1 - (v605 - u110)):inverse();
        u110 = v605;
    else
        local v606, v607, v608 = u100:ToEulerAnglesXYZ();
        u100 = CFrame.Angles(v606, v607, v608);
    end;

    u112 = u112 * u100;

    if u85.Code then
        u85.X = math.min(u85.X + u85.Increment * v586, 90);
        local PrevPos = u85.PrevPos;
        local NewPos = u85.NewPos;
        local v609 = math.rad(u85.X);
        u85.Pos = PrevPos:Lerp(NewPos, (math.sin(v609)));
        local PrevRot = u85.PrevRot;
        local NewRot = u85.NewRot;
        local v610 = math.rad(u85.X);
        u85.Rot = PrevRot:Lerp(NewRot, (math.sin(v610)));

        if u85.X >= 90 then
            u85.Code = nil;
        end;
    end;

    if u103 then
        u103 = false;
        u190();
    end;

    local v611;

    if Humanoid.SeatPart == nil then
        v611 = false;
    else
        v611 = Humanoid.SeatPart.Name == "VehicleSeat";
    end;

    if not v593 or (not u9 or (u9.Parent ~= VM_PARTS or (type(v595) ~= "table" or not u11))) then
        u72 = SettingsModule.GetSetting("General", "Field Of View");
        local v612 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

        if v612 then
            u75 = NumberUtil:Lerp(u75, 0.3, (math.clamp(0.4 * v586, 0, 1)));
            local v613;

            if u75 < 1 then
                v613 = SettingsModule.GetSetting("Graphics", "Toggle Crosshair") == true;
            else
                v613 = false;
            end;

            Crosshair.Visible = v613;

            if Crosshair.Visible then
                for _, v in pairs({ Crosshair, unpack(Crosshair:GetChildren()) }) do
                    v.BackgroundTransparency = u75;
                end;

                u80 = v579 == "" and 12 or 18;
                Crosshair.Up.Position = UDim2.new(0, 0, 0, -u80);
                Crosshair.Left.Position = UDim2.new(0, -u80, 0, 0);
                Crosshair.Down.Position = UDim2.new(0, 0, 0, u80 + 2);
                Crosshair.Right.Position = UDim2.new(0, u80 + 2, 0, 0);

                return;
            end;
        else
            Crosshair.Visible = false;
        end;

        return;
    end;

    local Type = v594.Type;
    local Melee = v595.Melee;
    local Spread = v595.Spread;
    local Recoil = v595.Recoil;
    local Offsets = v595.Offsets;
    local v614;

    if v596 then
        v614 = v596.UsePositionTimes;
    else
        v614 = v596;
    end;

    local v615 = tick() - u77;
    local v616 = v614 and (v614.Start <= v615 and (v615 <= v614.End and (v576 == false and (v614.PlayOnMiss or not u152("Miss"))))) and "LocalUse" or "Local";

    if v616 == "Local" and Offsets[`Local{v593.Skin}`] then
        v616 = `Local{v593.Skin}`;
    end;

    local v617;

    if v596 == nil then
        v617 = false;
    else
        v617 = v596.AimDownSpeed ~= nil;
    end;

    local v618;

    if v596 == nil then
        v618 = false;
    else
        v618 = v596.IsBow;
    end;

    if v577 then
        v577 = (v618 ~= true or u49 == "AimingIn2") and true or u49 == "Holding";
    end;

    u31 = u31:Lerp(Offsets[v616], (math.clamp((v614 and v614.Alpha or 0.1) * v586, 0, 1)));
    u92 = NumberUtil:Lerp(u92, v577 and 1 + (u44.SwayMult or 0) or 1, (math.clamp(0.1 * v586, 0, 1)));
    u25 = NumberUtil:Lerp(u25, 0.0135, 0.01);
    u27 = NumberUtil:Lerp(u27, 0.015, 0.01);
    u26 = NumberUtil:Lerp(u26, 0.0025, 0.01);
    u28 = NumberUtil:Lerp(u28, 0.006, 0.01);
    local v619 = u63 * 2 + 1;
    u23 = (u23 + u25 * v619 * v586) % 6.283185307179586;
    u24 = (u24 + u27 * v619 * v586) % 6.283185307179586;
    local v620 = math.sin(u24) * (u28 * u59 * u92);
    local v621 = math.sin(u23) * (u26 * u59 * u92);

    if tick() - u34 >= 0.15 / v582 then
        u55 = NumberUtil:Lerp(u55, 0, (math.clamp(0.1 * v586, 0, 1)));
        u56 = NumberUtil:Lerp(u56, 0, (math.clamp(0.1 * v586, 0, 1)));
    end;

    u104.Target = CameraController:GetAttribute("FreeLooking") and Vector3.new() or Vector3.new(u55, u56, 0);
    local v622 = u104.Position * u58;
    u53 = v622.X / 16.666666666666668;
    u54 = v622.Y / 16.666666666666668;
    u57 = NumberUtil:Lerp(u57, v577 and 15 or 1, (math.clamp(0.1 * v586, 0, 1)));
    local v623 = (v596 == nil or not v596.AimDownSpeed) and 1 or v596.AimDownSpeed[v577 and "In" or "Out"];

    if v577 ~= u42 then
        u43 = math.clamp(v577 and 1 - u37 / 1.1 or u37 / 1.1, 0, 1);
        u42 = v577;
    end;

    u41 = NumberUtil:Lerp(u41, (v579 == "" and 7 or 5) / (v581 and 0.9 or (v580 and v579 ~= "" and 1.25 or 1)), (math.clamp((v579 == "" and 0.01 or 0.15) * v586, 0, 1)));
    local v624 = v577 and (v618 ~= true or u49 ~= "Started" and not u49:find("None")) and v585 and v585 or -v585;
    local v625 = math.min(u37 + v624 * u43 / v623, 1.1);
    u37 = math.max(0, v625);
    local v626 = math.min(u37, 1);
    u38 = u37 >= 1 and (u38 + v585 * 1.5 or 1) or 1;
    local v627 = v577 and (v617 and not (Melee or Offsets.Aim)) and (u46 or u17);

    if v627 then
        u36 = u11.CFrame:ToObjectSpace(v627.CFrame):inverse();
    end;

    if v617 then
        if Melee then
            if v577 then
                if u48 == "None" then
                    u48 = "Started";
                    u160("ThrowWindup");
                elseif u48 == "Started" and not u152("ThrowWindup") then
                    u48 = "Holding";
                    u160("ThrowHold");
                end;
            elseif u152("ThrowHold") or u152("ThrowWindup") then
                u48 = "None";
                u165("ThrowWindup");
                u165("ThrowHold");
            end;
        elseif v618 then
            local AimStart = u22.Local.AimStart;

            if script:GetAttribute("Aiming") and not u52 then
                if u49 == "None" then
                    local Ammo = v593.Ammo;
                    local v628 = nil;

                    if not (u152("AimStop") or v578) then
                        if Ammo == nil or Ammo.Amount <= 0 then
                            local v629;
                            v629, v628 = u506(true);

                            if v629 then
                                u49 = "Started";
                                u160("AimStart", 0.9);

                                if v628 then
                                    WeldModule:WeldAttachments(u12, v593, nil, nil, v628, u9:GetScale());
                                end;
                            end;
                        else
                            u49 = "Started";
                            u160("AimStart", 0.9);

                            if v628 then
                                WeldModule:WeldAttachments(u12, v593, nil, nil, v628, u9:GetScale());
                            end;
                        end;
                    end;
                elseif u152("AimStart") and AimStart.TimePosition >= 0.85 then
                    u49 = "AimingIn2";
                elseif u152("AimStart") and AimStart.TimePosition >= 0.7 then
                    u49 = "AimingIn1";
                elseif not u152("AimStart") then
                    u49 = "Holding";
                    u160("AimHold");
                end;
            elseif u49 == "Holding" or not (u49:find("None") or u152("AimStart")) then
                local v630 = tick() - u68;
                u49 = v630 >= 0.25 and v630 <= 0.45 and "NoneJump" or "None";

                if u49 == "NoneJump" then
                    task.delay(0.3, function() -- Line: 2418
                        -- upvalues: u49 (ref)
                        if u49 ~= "NoneJump" then
                            return;
                        end;

                        u49 = "None";
                    end);
                else
                    u165("AimStart");
                    u165("AimHold");
                    u160("AimStop", -1);
                end;

                u52 = false;
            end;
        end;
    end;

    local v631 = u18 and (u18:FindFirstChild("Military ACOG Sight") or u18:FindFirstChild("Bruno\'s ACOG Sight"));

    if v631 then
        local v632 = v626 >= 0.5;
        v631.ADS.Transparency = v632 and 0 or 1;
        v631.Front.Transparency = v632 and 1 or 0;
        v631.Middle.Transparency = v632 and 1 or 0;
        v631.Red.Transparency = v632 and 1 or 0;
        v631.Vignette.Transparency = v632 and 1 or 0.95;
    end;

    local v633 = v626 <= 0.5 and v626 ^ 3 * 4 or (v626 - 1) ^ 3 * 4 + 1;
    u39 = u38 > 1 and 2 ^ (-u41 * u38) * math.sin(u38 * 12.566370614359172) or NumberUtil:Lerp(u39, 0, (math.clamp(0.5 * v586, 0, 1)));
    u40 = NumberUtil:Lerp(u40, v577 and 0.1 or 1, (math.clamp(0.2 * v586, 0, 1))) * u92;

    if v580 then
        v580 = not (v584 and v578);
    end;

    local v634 = u66 >= 1 and true or (WaterController:GetAttribute("IsSwim") or v611);
    local v635;

    if v634 then
        v635 = Type ~= "Tool" and true or not v578;
    else
        v635 = v634;
    end;

    local v636 = v580 and (v597.SprintTilt or 1) or 1;
    local v637 = SettingsModule.GetSetting("General", "Field Of View");
    u72 = NumberUtil:Lerp(v637, v637 / (u44.ZoomLevel or (v596 == nil and 1 or (v596.DefaultZoomLevel or 1))), (math.min(v633 * 1.2, 1)));
    u67 = v634 and Type ~= "Tool" and tick() or u67;
    u68 = u66 >= 1 and u68 or tick();
    local v638;

    if v579:find("Forward") then
        v638 = v580 and -15 * v636 or -2;
    else
        v638 = v579:find("Backward") and 2 or 0;
    end;

    u61 = NumberUtil:Lerp(u61, math.rad((v635 and ((v580 and -5 or -15) * v636 or 0) or 0) + v638) / (v618 and (u152("AimStart") and v635) and 10 or 1), (math.clamp((v635 and 0.25 or 0.15) * v586, 0, 1)));
    local v639 = v579:find("Right") and 1 or (v579:find("Left") and -1 or 0);
    u60 = NumberUtil:Lerp(u60, math.rad(4 * v639), (math.clamp(0.1 * v586, 0, 1)));
    local v640 = nil;
    local v641 = 1;
    local v642 = v593.Ammo and Items[v642.ID];
    local v643 = (v642 and v642.AmmoStats or {})[(v577 and "Aim" or "Hip") .. "SpreadMult"] or 1;

    if Spread then
        v640 = Spread[v577 and "Aiming" or "Hip"];
        v641 = 1 + (u44[(v577 and "Aim" or "Hip") .. "SpreadMult"] or 0);
        local v644 = NumberUtil:Lerp(u78, (v640 or Spread.Hip)[v579 == "" and "Idle" or "Moving"] * v641 * v643, (math.clamp(0.2 * v586, 0, 1)));
        u78 = math.max(v644, 0);
        local Shooting = Spread.Shooting;

        if Shooting then
            if tick() - u77 >= Shooting.DecayStart / v582 then
                u79 = math.max(u79 - v585 * (1 / (Shooting.DecayEnd - Shooting.DecayStart)), 0);
            end;
        else
            u79 = 0;
        end;

        u105.Target = u85.Rot;

        if Recoil then
            Recoil = Recoil.Camera;
        end;

        if Recoil and (u83 < 1 or u84 > 0) then
            local v645 = tick() - u77;

            if Recoil.Decay.Start / v582 <= v645 then
                u83 = math.min(u83 + Recoil.Decay.Rate / (u84 * Recoil.Decay.Multiplier) * v586, 1);

                if Recoil.Decay.Bullet <= v645 then
                    local v646 = tick() - u86;
                    local v647 = 0.016666666666666666 / v582;

                    if u84 > 0 and v647 <= v646 then
                        for _ = 1, math.floor(v646 / v647) do
                            u84 = math.max(u84 - 1, 0);
                        end;

                        u86 = tick();
                    end;
                end;
            else
                u86 = tick();
                u87 = u82;
            end;
        end;
    end;

    for _, v in pairs({ Crosshair, unpack(Crosshair:GetChildren()) }) do
        v.BackgroundTransparency = u75;
    end;

    local v648 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

    if v648 and Type ~= "Gun" then
        u75 = NumberUtil:Lerp(u75, v580 and 0.5 or 0.3, (math.clamp(0.4 * v586, 0, 1)));
        local v649;

        if u75 < 1 then
            v649 = SettingsModule.GetSetting("Graphics", "Toggle Crosshair") == true;
        else
            v649 = false;
        end;

        Crosshair.Visible = v649;

        if Crosshair.Visible then
            for _, v in pairs({ Crosshair, unpack(Crosshair:GetChildren()) }) do
                v.BackgroundTransparency = u75;
            end;

            u80 = v579 == "" and 12 or 18;
            Crosshair.Up.Position = UDim2.new(0, 0, 0, -u80);
            Crosshair.Left.Position = UDim2.new(0, -u80, 0, 0);
            Crosshair.Down.Position = UDim2.new(0, 0, 0, u80 + 2);
            Crosshair.Right.Position = UDim2.new(0, u80 + 2, 0, 0);
        end;
    else
        local v650;

        if v640 == nil then
            local v651 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";
            v650 = v651 and (v580 and 0.5 or 0.3) or 1;
        elseif v580 or (u152("Equip") or (u90 or (u152("Inspect") or CameraController:GetAttribute("FreeLooking")))) then
            v650 = 1;
        else
            local v652 = v577 or v626 >= 0.8;
            v650 = v652 and Spread.Aiming.Hide and 1 or (v652 == false and Spread.Hip.Hide and 1 or 0.2);
        end;

        u75 = NumberUtil:Lerp(u75, v650, (math.clamp(0.4 * v586, 0, 1)));

        if v650 >= 1 and u75 > 0.95 then
            u75 = 1;
        end;

        local v653;

        if u75 < 1 then
            if Type == "Gun" then
                if u93 then
                    if v583 then
                        v653 = SettingsModule.GetSetting("Graphics", "Toggle Crosshair") == true;
                    else
                        v653 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad" and SettingsModule.GetSetting("Graphics", "Toggle Crosshair") == true;
                    end;
                else
                    v653 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

                    if v653 then
                        if v583 then
                            v653 = SettingsModule.GetSetting("Graphics", "Toggle Crosshair") == true;
                        else
                            v653 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad" and SettingsModule.GetSetting("Graphics", "Toggle Crosshair") == true;
                        end;
                    end;
                end;
            else
                local v654 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

                if v654 or v577 then
                    if u93 then
                        if v583 then
                            v653 = SettingsModule.GetSetting("Graphics", "Toggle Crosshair") == true;
                        else
                            v653 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad" and SettingsModule.GetSetting("Graphics", "Toggle Crosshair") == true;
                        end;
                    else
                        v653 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

                        if v653 then
                            if v583 then
                                v653 = SettingsModule.GetSetting("Graphics", "Toggle Crosshair") == true;
                            else
                                v653 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad" and SettingsModule.GetSetting("Graphics", "Toggle Crosshair") == true;
                            end;
                        end;
                    end;
                else
                    v653 = v577;
                end;
            end;
        else
            v653 = false;
        end;

        Crosshair.Visible = v653;

        if Crosshair.Visible and v640 then
            local v655 = v640.ShootingExtra * v641 * u79 * v643;
            u81 = v640[v579 == "" and "IdleExtra" or "MovingExtra"] or 0;
            u80 = math.abs(u80 - v601) <= 0.01 and u81 or NumberUtil:Lerp(u80, u81, (math.clamp(0.16 * v586, 0, 1)));
            local v656 = u78 + v655 + u80;
            Crosshair.Up.Position = UDim2.new(0, 0, 0, -v656);
            Crosshair.Left.Position = UDim2.new(0, -v656, 0, 0);
            Crosshair.Down.Position = UDim2.new(0, 0, 0, v656 + 2);
            Crosshair.Right.Position = UDim2.new(0, v656 + 2, 0, 0);
        end;
    end;

    local Scope2 = u44.Scope;
    local v657 = Scope2 and (math.clamp(1 - v633 * 1.2, 0, 1) or 1) or 1;

    if Scope2 then
        Scope.Size = NumberUtil:MultUDim2ByNum(Size, Scope2);

        for _, v in pairs({ Scope, Scope.Frame, unpack(Scope.Frame:GetChildren()) }) do
            local v658 = (v:IsA("Frame") and "Background" or "Image") .. "Transparency";
            local v659;

            if v.Name == "Grain" then
                v659 = v657 * 0.1 + 0.9 or v657;
            else
                v659 = v657;
            end;

            v[v658] = v659;
        end;
    end;

    Scope.Visible = Scope2 ~= nil;
    Scope.Position = UDim2.new(0.55, 0, 0.55, 0):Lerp(UDim2.new(0.5, 0, 0.5, 0), v633 + u39 * 15 * u92);

    if u216(v657 >= 0.8) and Scope2 then
        local v660 = u93 and CameraController:GetAttribute("UI");
        Toolbar.Visible = v660;
        local v661 = u93 and CameraController:GetAttribute("UI");
        Stats.Visible = v661;
        local v662 = u93 and (CameraController:GetAttribute("UI") and PreferredInputController) and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";
        GamepadControls.Visible = v662;
    end;

    local v663 = Camera;
    v663.CFrame = v663.CFrame * (u93 and CFrame.new() or CFrame.Angles(v620 * 0.08 * (u63 * 2 + 1), v621 * 0.16 * (u63 * 2 + 1), 0));
    u29 = u36 and u31:Lerp(u36, Scope2 and 1 - v657 or v633 + u39 * u92) or u31;
    u101 = u37 >= 0.85;
    u96 = u29 * u30 * (v576 and CFrame.new() or CFrame.Angles(v620 * u40, v621 * (u40 * 3), 0)) + (u115 or u114.Position) / -4;
    local v664;

    if v577 then
        v664 = u101 and 0.2 or 0.1;
    else
        v664 = u101 and 0.1 or 0.2;
    end;

    local v665 = math.clamp(v664 * v586, 0, 1);
    u65 = NumberUtil:Lerp(u65, u101 and 0 or 1, v665);
    u88 = NumberUtil:Lerp(u88, v577 and 0 or 1, (math.clamp(0.25 * v586, 0, 1)));
    local v666 = u105.Position * (u88 * 0.8 + 0.2);
    local v667 = u85.Pos * (u88 * 0.5 + 0.5);
    u69 = NumberUtil:Lerp(u69, v580 and 1 or 0, (math.clamp(0.25 * v586, 0, 1)));
    local v668 = (v597.SprintMoveDown or 0) * u69;
    local v669 = (v597.SprintMoveBackward or 0) * u69;
    u97 = v576 and CFrame.new() or CFrame.new(v603 * v602 * u65, v604 * v602 * u65 + u61 * v668, u61 * -v669);
    u98 = v576 and CFrame.new() or CFrame.Angles(u61 * u65 + v666.X, u60 * u65 + v666.Y, -u60 * u65 + v666.Z) * CFrame.new(v667.X, v667.Y, v667.Z);
    u64 = NumberUtil:Lerp(u64, u101 and u38 >= 1.5 and 1 or 0, v665);
    local v670 = v597.MouseSway or 1;
    u99 = v576 and CFrame.new() or CFrame.Angles(math.rad(u54) * v670 / u57 + (math.rad(v604 * v602 * 3 * v598) + u61 / 30) * u64, math.rad(u53) * v670 / u57 + (math.rad(v603 * v602 * 3 * v598) + u60 / 30) * u64, 0);
end);
Run:BindToRenderStep("HumCamOffset", Enum.RenderPriority.Camera.Value - 1, function(p671) -- Line: 2625
    -- upvalues: Humanoid (copy), u107 (ref), u106 (copy), u117 (ref), u116 (copy), u100 (ref)
    Humanoid.CameraOffset = Vector3.new(0, -0.25, 0) + (u107 or u106.Position) + (u117 or u116.Position);
    local v672 = Camera;
    v672.CFrame = v672.CFrame * u100;
end);
Run:BindToRenderStep("ViewmodelController", Enum.RenderPriority.Camera.Value + 2, function(p673) -- Line: 2630
    -- upvalues: u115 (ref), u114 (copy), u10 (ref), u22 (copy), u74 (ref), u9 (ref), u45 (ref), u16 (ref), u96 (ref), u11 (ref), u21 (ref), u97 (ref), u98 (ref), u14 (ref), u101 (ref), u15 (ref), u99 (ref)
    Camera.CFrame = Camera.CFrame + (u115 or u114.Position);
    local v674 = CFrame.new();

    if u10 then
        local Reload = u22.Local.Reload;
        local CFrame2 = u10.Root.CFrame;

        if not (Reload and (Reload.IsPlaying and CFrame2)) then
            CFrame2 = CFrame2:Lerp(CFrame.new(CFrame2.Position), 0.5);
        end;

        local v675 = Camera;
        v675.CFrame = v675.CFrame * u74:ToObjectSpace(CFrame2);
        u74 = CFrame2;
        v674 = CFrame2:ToObjectSpace(CFrame.new(CFrame2.Position));
    end;

    if not u9 or u9.Parent ~= VM_PARTS then
        return;
    end;

    local v676 = u45 or u16;
    local v677 = (CameraController:GetAttribute("ViewmodelCFrame") or Camera.CFrame) * v674 * u96;
    u9.WorldPivot = u11.CFrame;

    if u21 then
        u9:PivotTo(v677 * u97 * u98);
    else
        u9:PivotTo(v677);
        local v678, v679, v680 = v677:ToEulerAnglesXYZ();
        local CFrame2 = u14.CFrame;
        local v681 = CFrame.new(CFrame2.Position) * CFrame.Angles(v678, v679, v680);
        local v682 = v681:ToObjectSpace(CFrame2);
        u9.WorldPivot = CFrame2;
        u9:PivotTo(v681 * u97 * u98 * v682);
    end;

    local v683 = u101 and v676 and v676 or u15;
    u9.WorldPivot = v683.CFrame;
    u9:PivotTo(v683.CFrame * u99);
end);
InteractController:GetAttributeChangedSignal("Digging"):Connect(function() -- Line: 2665
    -- upvalues: u22 (copy), Parent (copy), u152 (copy), u160 (copy), SoundModule (copy), u165 (copy)
    local Dig = u22.Local.Dig;
    local PrimaryPart = Parent.PrimaryPart;
    local v684;

    if PrimaryPart then
        v684 = PrimaryPart:FindFirstChild(Dig and "DigWithShovel" or "DigWithHand");
    else
        v684 = nil;
    end;

    if InteractController:GetAttribute("Digging") then
        if Dig and not u152("Dig") then
            u160("Dig");
        end;

        if v684 then
            SoundModule:PlaySound(v684);
        end;

        return;
    end;

    u165("Dig");

    if v684 then
        SoundModule:StopSound(v684);
    end;
end);
u10 = workspace:FindFirstChild("CameraRoot");

if not u10 then
    u10 = CameraRoot:Clone();
    u10.Parent = workspace;
end;

VM_PARTS:ClearAllChildren();