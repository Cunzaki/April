-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local UserInputService = game:GetService("UserInputService");
local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local RunService = game:GetService("RunService");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local Drops = workspace:WaitForChild("Drops");
local VFX = workspace:WaitForChild("VFX");
local Animals = workspace:WaitForChild("Animals");
local Plants = workspace:WaitForChild("Plants");
local RaycastUtil = require(Modules:WaitForChild("RaycastUtil"));
local SettingsModule = require(Modules:WaitForChild("SettingsModule"));
local GamepadIconModule = require(Modules:WaitForChild("GamepadIconModule"));
local LocalPlayer = Players.LocalPlayer;
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts");
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui");
local Parent = script.Parent;
local u1 = nil;
local v2 = nil;
local u3 = nil;

while true do
    u1 = u1 or Parent:FindFirstChild("Humanoid");
    u3 = u3 or Parent:FindFirstChild("HumanoidRootPart");
    v2 = v2 or Parent:FindFirstChild("Head");

    if u1 and (u3 and v2) then
        break;
    end;

    task.wait(0.1);
end;

local ViewmodelController = Parent:WaitForChild("ViewmodelController");
local InventoryController = Parent:WaitForChild("InventoryController");
local WaterController = Parent:WaitForChild("WaterController");
local WheelController = Parent:WaitForChild("WheelController");
local TeamNavigationController = Parent:WaitForChild("TeamNavigationController");
local WeatherController = PlayerScripts:WaitForChild("WeatherController");
local PreferredInputController = PlayerScripts:WaitForChild("PreferredInputController");
local ChatController = PlayerScripts:WaitForChild("ChatController");
require(PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"));

local function getDeadzone() -- Line: 65
    -- upvalues: PreferredInputController (copy)
    return PreferredInputController:GetAttribute("JoystickDeadzone") or 0.225;
end;

local Main = PlayerGui:WaitForChild("Main");
local GamepadControls = Main:WaitForChild("GamepadControls");
local Codelock = Main:WaitForChild("Codelock");
local GamepadImage = ReplicatedStorage:WaitForChild("VFX"):WaitForChild("Info"):WaitForChild("Action"):WaitForChild("GamepadImage");
local TopControls = GamepadControls:WaitForChild("TopControls");
local ToolTip = GamepadControls:WaitForChild("ToolTip");
local Interaction = GamepadControls:WaitForChild("Interaction");
local v4 = {};

for _, child in pairs(ToolTip:GetChildren()) do
    if child:IsA("TextLabel") then
        table.insert(v4, child);
    end;
end;

local u5 = false;
local u6 = false;
local v7 = tick();
local v8 = false;
local v9 = RaycastUtil:FilterFunction("View");
local u10 = {
    Left = false,
    Right = false,
    Forward = false,
    Backward = false,
    Sprint = false,
    Crouch = false
};
GamepadIconModule.Register(TopControls.Inventory.ImageLabel, "ButtonY");
GamepadIconModule.Register(TopControls.Interact.ImageLabel, "ButtonA");
GamepadIconModule.Register(TopControls.ToggleUINavigation.ImageLabel, "ButtonB");

if v4[1] then
    GamepadIconModule.Register(v4[1].ImageLabel, "ButtonA");
end;

if v4[2] then
    GamepadIconModule.Register(v4[2].ImageLabel, "ButtonX");
end;

GamepadIconModule.Register(Interaction.xtra.ImageLabel, "ButtonX");
GamepadIconModule.Register(GamepadImage, "ButtonX");

local function v12() -- Line: 107
    -- upvalues: PreferredInputController (copy), GamepadControls (copy), TeamNavigationController (copy)
    local v11;

    if PreferredInputController:GetAttribute("PreferredInput") == "Gamepad" then
        v11 = not TeamNavigationController:GetAttribute("MapOpen");
    else
        v11 = false;
    end;

    GamepadControls.Visible = v11;
end;

local function u29() -- Line: 113
    -- upvalues: u10 (copy), PreferredInputController (copy), InventoryController (copy), WheelController (copy), TeamNavigationController (copy), Codelock (copy), SettingsModule (copy), ChatController (copy), u5 (ref), ViewmodelController (copy), WaterController (copy), u6 (ref), u1 (ref), LocalPlayer (copy), u3 (ref)
    local v13 = "";
    local Forward = u10.Forward;
    local Backward = u10.Backward;

    if Forward and not Backward then
        v13 = v13 .. "Forward";
    elseif Backward and not Forward then
        v13 = v13 .. "Backward";
    end;

    if u10.Left and not u10.Right then
        v13 = v13 .. "Left";
    elseif u10.Right and not u10.Left then
        v13 = v13 .. "Right";
    end;

    local v14 = PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";
    local v15 = InventoryController:GetAttribute("Open") and v14;
    local v16 = WheelController:GetAttribute("Open") and v14;
    local v17 = TeamNavigationController:GetAttribute("MapOpen") and v14;
    local v18 = Codelock.Visible and v14;
    local v19 = SettingsModule.MainMenuOpen() and v14;
    local v20 = ChatController:GetAttribute("Typing") and v14;
    local v21 = v13 == "Forward";

    if u10.Sprint then
        u5 = true;
    elseif not v21 then
        u5 = false;
    end;

    local v22 = ViewmodelController:GetAttribute("Aiming");
    local v23 = ViewmodelController:GetAttribute("Using");
    local v24 = WaterController:GetAttribute("IsSwim");
    local v25 = u6 or u10.Crouch;
    local v26 = u5;

    if v26 then
        if v21 then
            local v27 = v25 or (v22 or (v23 and not ViewmodelController:GetAttribute("CanUse") or (v24 or script:GetAttribute("IsClimbing"))));
            v21 = not v27;
        end;
    else
        v21 = v26;
    end;

    local v28 = (u1:GetAttribute("DamageConnections") or 0) > 0;
    script:SetAttribute("Direction", v13);
    script:SetAttribute("IsSprint", v21);
    script:SetAttribute("IsCrouch", v25);
    script:SetAttribute("IsSlowed", v28);
    u1.WalkSpeed = (v15 or (v16 or (v17 or (v18 or (v19 or v20))))) and 0 or (u1:GetAttribute("Downed") and 0 or (v25 and 6.5 or (v21 and 18 or 11)) * (v22 and 0.8 or 1) * (v28 and 0.3 or 1)) * (ViewmodelController:GetAttribute("SReduction") or 1) * (LocalPlayer:GetAttribute("Armor_HasFlippers") and (v24 and 1.5 or 0.5) or 1);
    u1.HipHeight = v25 and 1.1 or 1.6;
    u1.MaxSlopeAngle = v24 and 80 or 60;
    u1.JumpHeight = v28 and 0 or 3.25;
    u3.Size = Vector3.new(2, v25 and 2.1 or 2.5, 2);
end;

UserInputService.InputChanged:Connect(function(p30) -- Line: 161
    -- upvalues: PreferredInputController (copy), u10 (copy), u29 (copy)
    if PreferredInputController:GetAttribute("PreferredInput") ~= "Gamepad" then
        return;
    end;

    if p30.UserInputType ~= Enum.UserInputType.Gamepad1 then
        return;
    end;

    if p30.KeyCode ~= Enum.KeyCode.Thumbstick1 then
        return;
    end;

    local Position = p30.Position;
    local X = Position.X;
    local Y = Position.Y;
    local v31 = PreferredInputController:GetAttribute("JoystickDeadzone") or 0.225;
    local v32 = false;

    for i, v in {
        Forward = v31 < Y,
        Backward = Y < -v31,
        Right = v31 < X,
        Left = X < -v31
    } do
        if u10[i] ~= v then
            u10[i] = v;
            v32 = true;
        end;
    end;

    if v32 then
        u29();
    end;
end);
UserInputService.InputBegan:Connect(function(p33) -- Line: 197
    -- upvalues: SettingsModule (copy), PreferredInputController (copy), TeamNavigationController (copy), Codelock (copy), InventoryController (copy), UserInputService (copy), u10 (copy), ChatController (copy), u29 (copy)
    if SettingsModule.MainMenuOpen() then
        return;
    end;

    if PreferredInputController:GetAttribute("PreferredInput") == "Gamepad" then
        local v34 = TeamNavigationController:GetAttribute("MapOpen") or tick() - (TeamNavigationController:GetAttribute("MapClosedTick") or 0) < 0.15;
        local v35 = Codelock and Codelock.Visible;

        if InventoryController:GetAttribute("Open") or (v34 or (v35 or tick() - (InventoryController:GetAttribute("ClosedTick") or 0) < 0.15)) then
            return;
        end;
    end;

    local UserInputType = p33.UserInputType;
    local v36 = UserInputService:GetFocusedTextBox();

    if (UserInputType == Enum.UserInputType.Keyboard or UserInputType == Enum.UserInputType.Gamepad1) and not v36 then
        local Name = p33.KeyCode.Name;
        local v37 = false;

        if Name == SettingsModule.GetSetting("Controls", "Move Forward") then
            u10.Forward = true;
            v37 = true;
        elseif Name == SettingsModule.GetSetting("Controls", "Move Backward") then
            u10.Backward = true;
            v37 = true;
        elseif Name == SettingsModule.GetSetting("Controls", "Move Right") then
            u10.Right = true;
            v37 = true;
        elseif Name == SettingsModule.GetSetting("Controls", "Move Left") then
            u10.Left = true;
            v37 = true;
        elseif Name == SettingsModule.GetSetting("Controls", "Sprint") then
            u10.Sprint = not SettingsModule.GetSetting("Controls", "Toggle Sprint") and true or not u10.Sprint;
            v37 = true;
        elseif Name == SettingsModule.GetSetting("Controls", "Crouch") then
            u10.Crouch = not SettingsModule.GetSetting("Controls", "Toggle Crouch") and true or not u10.Crouch;
            v37 = true;
        elseif Name == SettingsModule.GetSetting("Gamepad", "Sprint") then
            u10.Sprint = not SettingsModule.GetSetting("Gamepad", "Toggle Sprint") and true or not u10.Sprint;
            v37 = true;
        elseif Name == SettingsModule.GetSetting("Gamepad", "Crouch") and not ChatController:GetAttribute("Typing") then
            u10.Crouch = not SettingsModule.GetSetting("Gamepad", "Toggle Crouch") and true or not u10.Crouch;
            v37 = true;
        end;

        if not v37 then
            return;
        end;

        u29();
    end;
end);
UserInputService.InputEnded:Connect(function(p38) -- Line: 238
    -- upvalues: PreferredInputController (copy), TeamNavigationController (copy), Codelock (copy), InventoryController (copy), UserInputService (copy), SettingsModule (copy), u10 (copy), u29 (copy)
    if PreferredInputController:GetAttribute("PreferredInput") == "Gamepad" then
        local v39 = TeamNavigationController:GetAttribute("MapOpen") or tick() - (TeamNavigationController:GetAttribute("MapClosedTick") or 0) < 0.15;
        local v40 = Codelock and Codelock.Visible;

        if InventoryController:GetAttribute("Open") or (v39 or (v40 or tick() - (InventoryController:GetAttribute("ClosedTick") or 0) < 0.15)) then
            return;
        end;
    end;

    local UserInputType = p38.UserInputType;
    local v41 = UserInputService:GetFocusedTextBox();

    if (UserInputType == Enum.UserInputType.Keyboard or UserInputType == Enum.UserInputType.Gamepad1) and not v41 then
        local Name = p38.KeyCode.Name;
        local v42 = false;

        if Name == SettingsModule.GetSetting("Controls", "Move Forward") then
            u10.Forward = false;
            v42 = true;
        elseif Name == SettingsModule.GetSetting("Controls", "Move Backward") then
            u10.Backward = false;
            v42 = true;
        elseif Name == SettingsModule.GetSetting("Controls", "Move Right") then
            u10.Right = false;
            v42 = true;
        elseif Name == SettingsModule.GetSetting("Controls", "Move Left") then
            u10.Left = false;
            v42 = true;
        elseif Name == SettingsModule.GetSetting("Controls", "Sprint") and not SettingsModule.GetSetting("Controls", "Toggle Sprint") then
            u10.Sprint = false;
            v42 = true;
        elseif Name == SettingsModule.GetSetting("Controls", "Crouch") and not SettingsModule.GetSetting("Controls", "Toggle Crouch") then
            u10.Crouch = false;
            v42 = true;
        elseif Name == SettingsModule.GetSetting("Gamepad", "Sprint") and not SettingsModule.GetSetting("Gamepad", "Toggle Sprint") then
            u10.Sprint = false;
            v42 = true;
        elseif Name == SettingsModule.GetSetting("Gamepad", "Crouch") and not SettingsModule.GetSetting("Gamepad", "Toggle Crouch") then
            u10.Crouch = false;
            v42 = true;
        end;

        if not v42 then
            return;
        end;

        u29();
    end;
end);
ViewmodelController.AttributeChanged:Connect(function(p43) -- Line: 280
    -- upvalues: u29 (copy)
    if p43 ~= "Aiming" and (p43 ~= "Using" and (p43 ~= "SReduction" and p43 ~= "CanUse")) then
        return;
    end;

    u29();
end);
u1.AttributeChanged:Connect(function(p44) -- Line: 286
    -- upvalues: u29 (copy)
    if p44 ~= "DamageConnections" then
        return;
    end;

    u29();
end);
u1.StateChanged:Connect(function(p45, p46) -- Line: 290
    -- upvalues: u29 (copy)
    local v47 = script:GetAttribute("IsClimbing");

    if p45 == Enum.HumanoidStateType.Climbing or p46 ~= Enum.HumanoidStateType.Climbing then
        script:SetAttribute("IsClimbing", false);

        if v47 then
            u29();
        end;

        return;
    end;

    script:SetAttribute("IsClimbing", true);

    if not v47 then
        u29();
    end;
end);
UserInputService.TextBoxFocusReleased:Connect(function(p48) -- Line: 304
    -- upvalues: u10 (copy), SettingsModule (copy), u29 (copy)
    task.wait();
    u10.Forward = false;
    u10.Backward = false;
    u10.Right = false;
    u10.Left = false;

    if not SettingsModule.GetSetting("Controls", "Toggle Sprint") then
        u10.Sprint = false;
    end;

    if not SettingsModule.GetSetting("Controls", "Toggle Crouch") then
        u10.Crouch = false;
    end;

    u29();
end);
PreferredInputController.AttributeChanged:Connect(v12);
TeamNavigationController:GetAttributeChangedSignal("MapOpen"):Connect(v12);
local u49 = nil;
u1.Seated:Connect(function(p50, u51) -- Line: 325
    -- upvalues: u49 (ref), RunService (copy), UserInputService (copy), PreferredInputController (copy)
    if u49 then
        u49:Disconnect();
        u49 = nil;
    end;

    if not (p50 and (u51 and u51:IsA("VehicleSeat"))) then
        return;
    end;

    local v52 = u51.Parent and u51.Parent:FindFirstChild("BoatController");

    if not v52 then
        return;
    end;

    u49 = RunService.Heartbeat:Connect(function() -- Line: 330
        -- upvalues: u51 (copy), u49 (ref), UserInputService (ref), PreferredInputController (ref)
        if not (u51 and (u51.Parent and u51.Occupant)) then
            u51:SetAttribute("GamepadSteer", nil);
            u51:SetAttribute("GamepadThrottle", nil);

            if u49 then
                u49:Disconnect();
                u49 = nil;
            end;

            return;
        end;

        local u53 = 0;
        local u54 = 0;
        pcall(function() -- Line: 338
            -- upvalues: UserInputService (ref), PreferredInputController (ref), u53 (ref), u54 (ref)
            for _, v in UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1) do
                if v.KeyCode == Enum.KeyCode.Thumbstick1 then
                    local X = v.Position.X;
                    local Y = v.Position.Y;

                    if math.abs(X) > (PreferredInputController:GetAttribute("JoystickDeadzone") or 0.225) then
                        u53 = X;
                    end;

                    if math.abs(Y) > (PreferredInputController:GetAttribute("JoystickDeadzone") or 0.225) then
                        u54 = Y;

                        return;
                    end;

                    break;
                end;
            end;
        end);
        u51:SetAttribute("GamepadSteer", u53);
        u51:SetAttribute("GamepadThrottle", u54);
    end);
end);

while task.wait(0.03333333333333333) and (u3 and u3.Parent) do
    local v55 = script:GetAttribute("IsCrouch") and 2.6 or 1.7;
    local Position = u3.Position;
    local v56, v57 = RaycastUtil:Raycast(Position, Vector3.new(0, 100, 0), "Exclude", {
        Parent,
        VFX,
        Drops,
        Animals,
        Plants
    }, false, v9, true);
    local v58;

    if v56 == nil or v56.Parent == nil then
        v58 = false;
    else
        v58 = v56.CanCollide or v56.Transparency < 1;
    end;

    if v58 ~= v8 then
        WeatherController:SetAttribute("BelowCeiling", v58);
        v8 = v58;
    end;

    if v58 then
        v58 = v57.Y - Position.Y <= v55;
    end;

    if v58 ~= u6 then
        u6 = v58;
        u29();
    end;

    if tick() - v7 >= 0.4 and (v2 and v2.Parent) then
        v7 = tick();
        local v59 = Region3.new(v2.Position - 0.5 * v2.Size - Vector3.new(0, 3, 0), v2.Position + 0.5 * v2.Size - Vector3.new(0, 3, 0)):ExpandToGrid(4);
        local v60, _ = workspace.Terrain:ReadVoxels(v59, 4);

        if v60[1][1][1] == Enum.Material.Water then
            script:SetAttribute("IsWater", true);
        else
            script:SetAttribute("IsWater", false);
        end;
    end;
end;