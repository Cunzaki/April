-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local UserInputService = game:GetService("UserInputService");
local GamepadService = game:GetService("GamepadService");
local Players = game:GetService("Players");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local SettingRemotes = ReplicatedStorage:WaitForChild("SettingRemotes");
local ButtonClass = require(Modules:WaitForChild("ButtonClass"));
local PreferredInputController = Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PreferredInputController");
local Parent = script.Parent;
local TeleportBack = Parent:WaitForChild("TeleportBack");
local u1 = false;
local u2 = false;
local u3 = nil;

local function _() -- Line: 35
    -- upvalues: PreferredInputController (copy)
    local v4 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

    return v4;
end;

local function u8(p5) -- Line: 40
    -- upvalues: Parent (copy), UserInputService (copy), PreferredInputController (copy), GamepadService (copy)
    Parent.Enabled = p5;
    local v6;

    if p5 then
        v6 = Enum.MouseBehavior.Default;
    else
        v6 = Enum.MouseBehavior.LockCenter;
    end;

    UserInputService.MouseBehavior = v6;
    UserInputService.MouseIconEnabled = p5;

    if p5 then
        local v7 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

        if v7 then
            pcall(function() -- Line: 46
                -- upvalues: GamepadService (ref)
                GamepadService:EnableGamepadCursor(nil);
            end);
        end;
    else
        pcall(function() -- Line: 49
            -- upvalues: GamepadService (ref)
            GamepadService:DisableGamepadCursor();
        end);
    end;
end;

UserInputService.InputBegan:Connect(function(p9) -- Line: 53
    -- upvalues: UserInputService (copy), u8 (copy), Parent (copy), Players (copy), GamepadService (copy), u3 (ref), PreferredInputController (copy)
    if UserInputService:GetFocusedTextBox() then
        return;
    end;

    local UserInputType = p9.UserInputType;

    if UserInputType == Enum.UserInputType.Keyboard then
        if p9.KeyCode == Enum.KeyCode.P then
            u8(not Parent.Enabled);

            while Parent.Enabled do
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
                UserInputService.MouseIconEnabled = true;
                task.wait();
            end;
        end;
    elseif UserInputType == Enum.UserInputType.Gamepad1 then
        local KeyCode = p9.KeyCode;

        if KeyCode == Enum.KeyCode.DPadUp then
            local v10 = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Humanoid");

            if v10 and v10.Health <= 0 then
                return;
            end;

            if not Parent.Enabled then
                u3 = tick();
                task.delay(0.9, function() -- Line: 75
                    -- upvalues: u3 (ref), Parent (ref), UserInputService (ref), PreferredInputController (ref), GamepadService (ref)
                    if u3 and tick() - u3 >= 0.85 then
                        Parent.Enabled = true;
                        UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
                        UserInputService.MouseIconEnabled = true;
                        local v11 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

                        if v11 then
                            pcall(function() -- Line: 46
                                -- upvalues: GamepadService (ref)
                                GamepadService:EnableGamepadCursor(nil);
                            end);
                        end;

                        u3 = nil;

                        while Parent.Enabled do
                            UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
                            UserInputService.MouseIconEnabled = true;
                            task.wait();
                        end;
                    end;
                end);

                return;
            end;

            Parent.Enabled = false;
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
            UserInputService.MouseIconEnabled = false;
            pcall(function() -- Line: 49
                -- upvalues: GamepadService (ref)
                GamepadService:DisableGamepadCursor();
            end);

            return;
        end;

        if KeyCode == Enum.KeyCode.ButtonB and Parent.Enabled then
            Parent.Enabled = false;
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
            UserInputService.MouseIconEnabled = false;
            pcall(function() -- Line: 49
                -- upvalues: GamepadService (ref)
                GamepadService:DisableGamepadCursor();
            end);
        end;
    end;
end);
UserInputService.InputEnded:Connect(function(p12) -- Line: 93
    -- upvalues: u3 (ref)
    if p12.UserInputType ~= Enum.UserInputType.Gamepad1 then
        return;
    end;

    if p12.KeyCode == Enum.KeyCode.DPadUp then
        u3 = nil;
    end;
end);
Parent.Enabled = false;
UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
UserInputService.MouseIconEnabled = false;
pcall(function() -- Line: 49
    -- upvalues: GamepadService (copy)
    GamepadService:DisableGamepadCursor();
end);
PreferredInputController:GetAttributeChangedSignal("PreferredInput"):Connect(function() -- Line: 102
    -- upvalues: Parent (copy), PreferredInputController (copy), GamepadService (copy)
    if not Parent.Enabled then
        return;
    end;

    local v13 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

    if v13 then
        pcall(function() -- Line: 105
            -- upvalues: GamepadService (ref)
            GamepadService:EnableGamepadCursor(nil);
        end);

        return;
    end;

    pcall(function() -- Line: 107
        -- upvalues: GamepadService (ref)
        GamepadService:DisableGamepadCursor();
    end);
end);
ButtonClass.new(TeleportBack, "BackgroundColor3", function() -- Line: 111
    -- upvalues: u2 (ref), u1 (ref), TeleportBack (copy), SettingRemotes (copy)
    if u2 then
        return;
    end;

    if u1 then
        u2 = true;
        TeleportBack.TextLabel.Text = "TELEPORTING...";
        SettingRemotes.Teleport:FireServer();
        task.wait(30);
        TeleportBack.TextLabel.Text = "TELEPORT BACK TO MAIN MENU";
        u2 = false;

        return;
    end;

    u1 = true;

    for i = 3, 1, -1 do
        if u2 then
            break;
        end;

        TeleportBack.TextLabel.Text = `ARE YOU SURE? ({i})`;
        task.wait(1);
    end;

    u1 = false;

    if u2 then
        return;
    end;

    TeleportBack.TextLabel.Text = "TELEPORT BACK TO MAIN MENU";
end);