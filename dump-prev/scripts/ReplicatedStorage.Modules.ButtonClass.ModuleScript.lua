-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local RunService_upv_1 = game:GetService("RunService");
local NumberUtil_upv_1 = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("NumberUtil"));
local tbl_upv_1 = {};
tbl_upv_1.__index = tbl_upv_1;
tbl_upv_1.new = function(a1, a2, a3, a4, a5, a6, a7)
    --[[
      name: new
      line: 24
      upvalues:
        NumberUtil_upv_1 (copy, index: 1)
        tbl_upv_1 (copy, index: 2)
        RunService_upv_1 (copy, index: 3)
    ]]
    local v1 = a7 or a1;
    local tbl_2 = {};
    tbl_2.Button = a1;
    tbl_2.Property = a2;
    tbl_2.OrigSize = a1.Size;
    tbl_2.OrigColor = v1[a2];
    tbl_2.CurColor = v1[a2];
    tbl_2.TargetColor = v1[a2];
    tbl_2.HoverMult = a4 or 1.25;
    local v2 = nil;
    if (a5 == nil) then
        v2 = Color3.fromRGB(30, 154, 206);
    elseif (type(a5) ~= "number") then
        v2 = a5 or Color3.fromRGB(30, 154, 206);
    else
        v2 = NumberUtil_upv_1:MultColor3ByNum(v1[a2], a5);
        v2 = v2 or a5 or Color3.fromRGB(30, 154, 206);
    end;
    tbl_2.ClickColor = v2;
    tbl_2.Connections = {};
    tbl_2.GuiAffected = a7;
    local u1 = setmetatable(tbl_2, tbl_upv_1);
    table.insert(
        u1.Connections,
        a1.MouseEnter:Connect(
            function()
                --[[
                  line: 43
                  upvalues:
                    u1 (copy, index: 1)
                    NumberUtil_upv_1 (copy, index: 2)
                ]]
                if (not u1.Enabled) then
                    return;
                end;
                u1.MouseEntered = true;
                u1.Alpha = 0;
                u1.TargetColor = NumberUtil_upv_1:MultColor3ByNum(u1.CurColor, u1.HoverMult);
                u1:DoLoop();
            end
        )
    );
    table.insert(
        u1.Connections,
        a1.MouseLeave:Connect(
            function()
                --[[
                  line: 51
                  upvalues:
                    u1 (copy, index: 1)
                ]]
                u1.MouseEntered = false;
                u1.Alpha = 0;
                u1.TargetColor = u1.CurColor;
                u1:DoLoop();
            end
        )
    );
    for n_upv_1 = 1, 2 do
        if (n_upv_1 ~= 2 or a6) then
            table.insert(
                u1.Connections,
                a1["MouseButton" .. n_upv_1 .. "Down"]:Connect(
                    function()
                        --[[
                          line: 60
                          upvalues:
                            u1 (copy, index: 1)
                            a1 (copy, index: 2)
                            NumberUtil_upv_1 (copy, index: 3)
                            n_upv_1 (copy, index: 4)
                            RunService_upv_1 (copy, index: 5)
                        ]]
                        if (u1.Enabled) then
                            a1:TweenSize(NumberUtil_upv_1:MultUDim2ByNum(u1.OrigSize, 0.75), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true);
                            local u2 = false;
                            local v3 = a1["MouseButton" .. n_upv_1 .. "Up"]:Connect(
                                function()
                                    --[[
                                      line: 64
                                      upvalues:
                                        u2 (ref, index: 1)
                                    ]]
                                    u2 = true;
                                end
                            );
                            task.wait(0.15);
                            while (not (u2)) do
                                if (u1.MouseEntered) then
                                    RunService_upv_1.Heartbeat:Wait();
                                    continue;
                                else
                                    break;
                                end;
                            end;
                            v3:Disconnect();
                            if (a1.Parent ~= nil) then
                                a1:TweenSize(u1.OrigSize, Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.2, true);
                            end;
                        end;
                    end
                )
            );
            continue;
        else
            break;
        end;
    end;
    table.insert(
        u1.Connections,
        a1.Activated:Connect(
            function(...)
                --[[
                  line: 77
                  upvalues:
                    u1 (copy, index: 1)
                    a3 (copy, index: 2)
                ]]
                if (not u1.Enabled) then
                    return;
                end;
                a3(...);
            end
        )
    );
    if (a6) then
        table.insert(
            u1.Connections,
            a1.MouseButton2Click:Connect(
                function(...)
                    --[[
                      line: 82
                      upvalues:
                        u1 (copy, index: 1)
                        a6 (copy, index: 2)
                    ]]
                    if (not u1.Enabled) then
                        return;
                    end;
                    a6(...);
                end
            )
        );
    end;
    return u1;
end;
tbl_upv_1.ToggleButton = function(a1, a2, a3)
    --[[
      name: ToggleButton
      line: 91
      upvalues:
        NumberUtil_upv_1 (copy, index: 1)
    ]]
    if (a1.Selected ~= a2) then
        a1.Selected = a2;
        local v4 = (a2 and (a1.ClickColor)) or (a1.OrigColor);
        a1.Alpha = 0;
        a1.CurColor = v4;
        a1.TargetColor = NumberUtil_upv_1:MultColor3ByNum(v4, ((a1.MouseEntered) and (a1.HoverMult)) or 1);
        a1:DoLoop(a3);
    end;
end;
tbl_upv_1.UpdateBaseColor = function(a1, a2, a3)
    --[[
      name: UpdateBaseColor
      line: 102
    ]]
    a1.OrigColor = a2;
    a1.CurColor = a2;
    a1.TargetColor = a2;
    if (not a3) then
        return;
    end;
    a1.ClickColor = a3;
end;
tbl_upv_1.DoLoop = function(a1, a2)
    --[[
      name: DoLoop
      line: 111
      upvalues:
        NumberUtil_upv_1 (copy, index: 1)
        RunService_upv_1 (copy, index: 2)
    ]]
    local v5 = a1.GuiAffected or (a1.Button);
    local Property_1 = a1.Property;
    if (a1.DoingLoop) then
        return;
    end;
    if (a2) then
        v5[Property_1] = a1.TargetColor;
    else
        a1.DoingLoop = true;
        while (math.abs(1 - a1.Alpha) > 0.001) do
            local v6 = task.wait() / 0.016666666666666666;
            if (v5.Parent) then
                local v7 = math.clamp(0.3 * v6, 0, 1);
                a1.Alpha = NumberUtil_upv_1:Lerp(a1.Alpha, 1, v7);
                v5[Property_1] = v5[Property_1]:Lerp(a1.TargetColor, v7);
                RunService_upv_1.Heartbeat:Wait();
                continue;
            end;
            return;
        end;
        a1.DoingLoop = false;
    end;
end;
tbl_upv_1.Destroy = function(a1)
    --[[
      name: Destroy
      line: 132
    ]]
    for _, value_1 in pairs(a1.Connections) do
        value_1:Disconnect();
    end;
end;
tbl_upv_1.IsToggled = function(a1)
    --[[
      name: IsToggled
      line: 139
    ]]
    return a1.Selected;
end;
tbl_upv_1.Enable = function(a1, a2)
    --[[
      name: Enable
      line: 143
    ]]
    a1.Enabled = a2;
end;
return tbl_upv_1;