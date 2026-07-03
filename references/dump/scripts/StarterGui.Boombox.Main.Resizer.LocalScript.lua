-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local UserInputService = game:GetService("UserInputService");
local GuiService = game:GetService("GuiService");
local Players = game:GetService("Players");
local Parent = script.Parent;
local Parent2 = script.Parent.Parent;
local UIScale = Instance.new("UIScale", Parent);
GuiService:GetGuiInset();
local LocalPlayer = Players.LocalPlayer;

local function isMobile() -- Line: 17
    -- upvalues: UserInputService (copy)
    return UserInputService.TouchEnabled and not UserInputService.MouseEnabled;
end;

local function deviceType() -- Line: 21
    -- upvalues: UserInputService (copy)
    if not (UserInputService.TouchEnabled and not UserInputService.MouseEnabled) then
        return "Other";
    end;

    local ViewportSize = workspace.CurrentCamera.ViewportSize;

    return (ViewportSize.X >= 1024 or ViewportSize.Y >= 1024) and "Tablet" or "Mobile";
end;

local function isVertical() -- Line: 33
    local ViewportSize = workspace.CurrentCamera.ViewportSize;

    return ViewportSize.Y > ViewportSize.X;
end;

local function updateParentFrameHeight() -- Line: 38
    -- upvalues: Parent (copy)
    Parent.Size = UDim2.new(Parent.Size.X.Scale, Parent.Size.X.Offset, 0, Parent.UIListLayout.AbsoluteContentSize.Y);
end;

local function adjustPosition() -- Line: 42
    -- upvalues: Parent (copy), UIScale (copy), Parent2 (copy)
    local v1 = Parent.AbsolutePosition.Y + Parent.AbsoluteSize.Y * UIScale.Scale;
    local Y = Parent2.AbsoluteSize.Y;

    if Y < v1 then
        Parent.Position = UDim2.new(Parent.Position.X.Scale, Parent.Position.X.Offset, 0, (math.max(0, Parent.AbsolutePosition.Y - (v1 - Y))));
    end;
end;

local function UpdateScale() -- Line: 53
    -- upvalues: UserInputService (copy), UIScale (copy), Parent (copy), adjustPosition (copy), Parent2 (copy)
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        local v2;

        if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
            local ViewportSize = workspace.CurrentCamera.ViewportSize;
            v2 = (ViewportSize.X >= 1024 or ViewportSize.Y >= 1024) and "Tablet" or "Mobile";
        else
            v2 = "Other";
        end;

        if v2 == "Mobile" then
            local ViewportSize = workspace.CurrentCamera.ViewportSize;

            if ViewportSize.Y > ViewportSize.X then
                UIScale.Scale = 1;
            end;

            local ViewportSize2 = workspace.CurrentCamera.ViewportSize;

            if ViewportSize2.Y <= ViewportSize2.X then
                UIScale.Scale = 0.55;
            end;

            Parent.Draggable = false;
            Parent.Size = UDim2.new(Parent.Size.X.Scale, Parent.Size.X.Offset, 0, Parent.UIListLayout.AbsoluteContentSize.Y);
            adjustPosition();

            return;
        end;
    end;

    local Offset = Parent.Size.Y.Offset;
    local Y = Parent2.AbsoluteSize.Y;
    local Offset2 = Parent.Size.X.Offset;
    local X = Parent2.AbsoluteSize.X;
    local v3 = math.min(Offset2 / X > 0.35 and X * 0.35 / Offset2 or 1, Offset / Y > 0.7 and Y * 0.7 / Offset or 1);

    if v3 < 0.45 then
        UIScale.Scale = 0.45;
    else
        UIScale.Scale = v3;
    end;

    Parent.Size = UDim2.new(Parent.Size.X.Scale, Parent.Size.X.Offset, 0, Parent.UIListLayout.AbsoluteContentSize.Y);
    adjustPosition();
    Parent.Draggable = true;
end;

local function updateMainPosition() -- Line: 82
    -- upvalues: Parent (copy), UserInputService (copy), adjustPosition (copy), LocalPlayer (copy)
    local Position = Parent.Position;
    local v4;

    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        local ViewportSize = workspace.CurrentCamera.ViewportSize;
        v4 = (ViewportSize.X >= 1024 or ViewportSize.Y >= 1024) and "Tablet" or "Mobile";
    else
        v4 = "Other";
    end;

    if v4 == "Mobile" then
        local ViewportSize = workspace.CurrentCamera.ViewportSize;
        local ViewportSize2 = workspace.CurrentCamera.ViewportSize;
        Parent.Position = UDim2.new(Position.X.Scale, ViewportSize.Y > ViewportSize.X and -15 or -120, Position.Y.Scale, ViewportSize2.Y > ViewportSize2.X and -110 or -30);
        Parent.Size = UDim2.new(Parent.Size.X.Scale, Parent.Size.X.Offset, 0, Parent.UIListLayout.AbsoluteContentSize.Y);
        adjustPosition();

        return;
    end;

    local v5;

    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        local ViewportSize = workspace.CurrentCamera.ViewportSize;
        v5 = (ViewportSize.X >= 1024 or ViewportSize.Y >= 1024) and "Tablet" or "Mobile";
    else
        v5 = "Other";
    end;

    if v5 ~= "Tablet" then
        Parent.Position = UDim2.new(Position.X.Scale, -15, Position.Y.Scale, -20);

        return;
    end;

    local JumpButton = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("TouchGui"):WaitForChild("TouchControlFrame"):WaitForChild("JumpButton");
    local ViewportSize = workspace.CurrentCamera.ViewportSize;
    local ViewportSize2 = workspace.CurrentCamera.ViewportSize;
    Parent.Position = UDim2.new(Position.X.Scale, ViewportSize.Y > ViewportSize.X and -15 or JumpButton.Position.Y.Offset, Position.Y.Scale, ViewportSize2.Y > ViewportSize2.X and JumpButton.Position.Y.Offset + -20 or JumpButton.Position.Y.Offset + JumpButton.Size.Y.Offset);
    Parent.Size = UDim2.new(Parent.Size.X.Scale, Parent.Size.X.Offset, 0, Parent.UIListLayout.AbsoluteContentSize.Y);
    adjustPosition();
end;

Parent:GetPropertyChangedSignal("Size"):Connect(UpdateScale);
UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(updateMainPosition);
local u6 = nil;
Parent2:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() -- Line: 116
    -- upvalues: updateMainPosition (copy), u6 (ref), UpdateScale (copy)
    updateMainPosition();

    if u6 then
        return;
    end;

    u6 = task.delay(0.1, function() -- Line: 120
        -- upvalues: UpdateScale (ref), u6 (ref)
        UpdateScale();
        u6 = nil;
    end);
end);
updateMainPosition();