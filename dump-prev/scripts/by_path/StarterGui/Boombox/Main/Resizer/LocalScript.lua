-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local UserInputService_upv_1 = game:GetService("UserInputService");
local GuiService_1 = game:GetService("GuiService");
local Players_1 = game:GetService("Players");
local Parent_upv_1 = script.Parent;
local Parent_upv_2 = script.Parent.Parent;
local u1 = Instance.new("UIScale", Parent_upv_1);
local _ = GuiService_1:GetGuiInset();
local LocalPlayer_upv_1 = Players_1.LocalPlayer;
local function isMobile_1()
    --[[
      name: isMobile
      line: 17
      upvalues:
        UserInputService_upv_1 (copy, index: 1)
    ]]
    return UserInputService_upv_1.TouchEnabled and (not UserInputService_upv_1.MouseEnabled);
end;
local function deviceType_1()
    --[[
      name: deviceType
      line: 21
      upvalues:
        UserInputService_upv_1 (copy, index: 1)
    ]]
    local v1 = nil;
    if (UserInputService_upv_1.TouchEnabled and (not UserInputService_upv_1.MouseEnabled)) then
        v1 = workspace.CurrentCamera.ViewportSize;
        local Y_1 = v1.Y;
        if (v1.X < 1024 and Y_1 < 1024) then
            return "Mobile";
        end;
        return "Tablet";
    end;
    return "Other";
end;
local function isVertical_1()
    --[[
      name: isVertical
      line: 33
    ]]
    local ViewportSize_1 = workspace.CurrentCamera.ViewportSize;
    return ViewportSize_1.X < ViewportSize_1.Y;
end;
local function updateParentFrameHeight_1()
    --[[
      name: updateParentFrameHeight
      line: 38
      upvalues:
        Parent_upv_1 (copy, index: 1)
    ]]
    Parent_upv_1.Size = UDim2.new(Parent_upv_1.Size.X.Scale, Parent_upv_1.Size.X.Offset, 0, Parent_upv_1.UIListLayout.AbsoluteContentSize.Y);
end;
local function adjustPosition_upv_1()
    --[[
      name: adjustPosition
      line: 42
      upvalues:
        Parent_upv_1 (copy, index: 1)
        u1 (copy, index: 2)
        Parent_upv_2 (copy, index: 3)
    ]]
    local v2 = Parent_upv_1.AbsolutePosition.Y + Parent_upv_1.AbsoluteSize.Y * u1.Scale;
    local Y_2 = Parent_upv_2.AbsoluteSize.Y;
    if (Y_2 >= v2) then
        return;
    end;
    Parent_upv_1.Position = UDim2.new(Parent_upv_1.Position.X.Scale, Parent_upv_1.Position.X.Offset, 0, math.max(0, Parent_upv_1.AbsolutePosition.Y - (v2 - Y_2)));
end;
local function updateMainPosition_upv_1()
    --[[
      name: updateMainPosition
      line: 82
      upvalues:
        Parent_upv_1 (copy, index: 1)
        UserInputService_upv_1 (copy, index: 2)
        adjustPosition_upv_1 (copy, index: 3)
        LocalPlayer_upv_1 (copy, index: 4)
    ]]
    local Position_1 = Parent_upv_1.Position;
    local v3, v4 = nil, nil;
    if (UserInputService_upv_1.TouchEnabled and (not UserInputService_upv_1.MouseEnabled)) then
        v3 = workspace.CurrentCamera.ViewportSize;
        local Y_3 = v3.Y;
        if (v3.X >= 1024 or Y_3 >= 1024) then
            v4 = "Tablet";
        else
            v4 = "Mobile";
        end;
    else
        v4 = "Other";
    end;
    if (v4 ~= "Mobile") then
        if (UserInputService_upv_1.TouchEnabled and (not UserInputService_upv_1.MouseEnabled)) then
            v3 = workspace.CurrentCamera.ViewportSize;
            local Y_4 = v3.Y;
            if (v3.X >= 1024 or Y_4 >= 1024) then
                v4 = "Tablet";
            else
                v4 = "Mobile";
            end;
        else
            v4 = "Other";
        end;
        if (v4 ~= "Tablet") then
            Parent_upv_1.Position = UDim2.new(Position_1.X.Scale, -15, Position_1.Y.Scale, -20);
        else
            local JumpButton_1 = LocalPlayer_upv_1:WaitForChild("PlayerGui"):WaitForChild("TouchGui"):WaitForChild("TouchControlFrame"):WaitForChild("JumpButton");
            local ViewportSize_2 = workspace.CurrentCamera.ViewportSize;
            local v5 = ((ViewportSize_2.X < ViewportSize_2.Y) and -15) or (JumpButton_1.Position.Y.Offset);
            local ViewportSize_3 = workspace.CurrentCamera.ViewportSize;
            Parent_upv_1.Position = UDim2.new(Position_1.X.Scale, v5, Position_1.Y.Scale, ((ViewportSize_3.X < ViewportSize_3.Y) and (JumpButton_1.Position.Y.Offset + -20)) or (JumpButton_1.Position.Y.Offset + JumpButton_1.Size.Y.Offset));
            Parent_upv_1.Size = UDim2.new(Parent_upv_1.Size.X.Scale, Parent_upv_1.Size.X.Offset, 0, Parent_upv_1.UIListLayout.AbsoluteContentSize.Y);
            adjustPosition_upv_1();
        end;
    else
        local ViewportSize_4 = workspace.CurrentCamera.ViewportSize;
        v4 = ((ViewportSize_4.X < ViewportSize_4.Y) and -15) or -120;
        local ViewportSize_5 = workspace.CurrentCamera.ViewportSize;
        Parent_upv_1.Position = UDim2.new(Position_1.X.Scale, v4, Position_1.Y.Scale, ((ViewportSize_5.X < ViewportSize_5.Y) and -110) or -30);
        Parent_upv_1.Size = UDim2.new(Parent_upv_1.Size.X.Scale, Parent_upv_1.Size.X.Offset, 0, Parent_upv_1.UIListLayout.AbsoluteContentSize.Y);
        adjustPosition_upv_1();
    end;
end;
local function UpdateScale_upv_1()
    --[[
      name: UpdateScale
      line: 53
      upvalues:
        UserInputService_upv_1 (copy, index: 1)
        u1 (copy, index: 2)
        Parent_upv_1 (copy, index: 3)
        adjustPosition_upv_1 (copy, index: 4)
        Parent_upv_2 (copy, index: 5)
    ]]
    if (UserInputService_upv_1.TouchEnabled and (not UserInputService_upv_1.MouseEnabled)) then
        local v6, v7 = nil, nil;
        if (UserInputService_upv_1.TouchEnabled and (not UserInputService_upv_1.MouseEnabled)) then
            v6 = workspace.CurrentCamera.ViewportSize;
            local Y_5 = v6.Y;
            if (v6.X >= 1024 or Y_5 >= 1024) then
                v7 = "Tablet";
            else
                v7 = "Mobile";
            end;
        else
            v7 = "Other";
        end;
        if (v7 == "Mobile") then
            local ViewportSize_6 = workspace.CurrentCamera.ViewportSize;
            if (ViewportSize_6.X < ViewportSize_6.Y) then
                u1.Scale = 1;
            end;
            local ViewportSize_7 = workspace.CurrentCamera.ViewportSize;
            if (ViewportSize_7.X >= ViewportSize_7.Y) then
                u1.Scale = 0.55;
            end;
            Parent_upv_1.Draggable = false;
            Parent_upv_1.Size = UDim2.new(Parent_upv_1.Size.X.Scale, Parent_upv_1.Size.X.Offset, 0, Parent_upv_1.UIListLayout.AbsoluteContentSize.Y);
            adjustPosition_upv_1();
            return;
        end;
    end;
    local Offset_1 = Parent_upv_1.Size.Y.Offset;
    local Y_6 = Parent_upv_2.AbsoluteSize.Y;
    local v8 = ((Offset_1 / Y_6 > 0.7) and (Y_6 * 0.7 / Offset_1)) or 1;
    local Offset_2 = Parent_upv_1.Size.X.Offset;
    local X_1 = Parent_upv_2.AbsoluteSize.X;
    local v9 = math.min(((Offset_2 / X_1 > 0.35) and (X_1 * 0.35 / Offset_2)) or 1, v8);
    if (v9 >= 0.45) then
        u1.Scale = v9;
    else
        u1.Scale = 0.45;
    end;
    Parent_upv_1.Size = UDim2.new(Parent_upv_1.Size.X.Scale, Parent_upv_1.Size.X.Offset, 0, Parent_upv_1.UIListLayout.AbsoluteContentSize.Y);
    adjustPosition_upv_1();
    Parent_upv_1.Draggable = true;
end;
Parent_upv_1:GetPropertyChangedSignal("Size"):Connect(UpdateScale_upv_1);
UserInputService_upv_1:GetPropertyChangedSignal("TouchEnabled"):Connect(updateMainPosition_upv_1);
local u2 = nil;
Parent_upv_2:GetPropertyChangedSignal("AbsoluteSize"):Connect(
    function()
        --[[
          line: 116
          upvalues:
            updateMainPosition_upv_1 (copy, index: 1)
            u2 (ref,  index: 2)
            UpdateScale_upv_1 (copy, index: 3)
        ]]
        updateMainPosition_upv_1();
        if (u2) then
            return;
        end;
        u2 = task.delay(
            0.1,
            function()
                --[[
                  line: 120
                  upvalues:
                    UpdateScale_upv_1 (copy, index: 1)
                    u2 (ref,  index: 2)
                ]]
                UpdateScale_upv_1();
                u2 = nil;
            end
        );
    end
);
updateMainPosition_upv_1();