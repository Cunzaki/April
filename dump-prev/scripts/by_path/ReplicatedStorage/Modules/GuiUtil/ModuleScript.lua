-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local UserInputService_upv_1 = game:GetService("UserInputService");
local RunService_upv_1 = game:GetService("RunService");
local NumberUtil_upv_1 = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("NumberUtil"));
local tbl_upv_1 = {};
local tbl_2 = {};
tbl_2.AddScrollToFrame = function(a1, a2, a3, a4, a5, a6)
    --[[
      name: AddScrollToFrame
      line: 26
      upvalues:
        UserInputService_upv_1 (copy, index: 1)
        tbl_upv_1 (copy, index: 2)
    ]]
    local v1 = assert(a2:FindFirstChild("Frame"), "\"FRAME\" COMPONENT NOT FOUND");
    a6 = a6 or 1;
    a5 = a5 or 0.1;
    local u1 = nil;
    local tbl_3 = {};
    local tbl_upv_4 = {};
    tbl_upv_4.Connections = tbl_3;
    tbl_upv_4.Delta = Vector3.new();
    tbl_upv_4.Frame = v1;
    tbl_upv_4.Scale = a6;
    tbl_upv_4.TargetScale = a6;
    v1.Size = UDim2.new(tbl_upv_4.Scale, 0, tbl_upv_4.Scale, 0);
    table.insert(
        tbl_3,
        a2.InputBegan:Connect(
            function(a7)
                --[[
                  line: 42
                  upvalues:
                    a2 (copy, index: 1)
                    tbl_upv_4 (copy, index: 2)
                    u1 (ref,  index: 3)
                    a1 (copy, index: 4)
                ]]
                if (not a2.Visible) then
                    return;
                end;
                if (a7.UserInputType == Enum.UserInputType.MouseButton1 and not (tbl_upv_4.Held)) then
                    u1 = a7.Position;
                    tbl_upv_4.Held = true;
                    a1:StartZoomLoop(a2);
                end;
            end
        )
    );
    table.insert(
        tbl_3,
        UserInputService_upv_1.InputChanged:Connect(
            function(a8)
                --[[
                  line: 52
                  upvalues:
                    a2 (copy, index: 1)
                    tbl_upv_4 (copy, index: 2)
                    u1 (ref,  index: 3)
                    a5 (ref,  index: 4)
                    a3 (copy, index: 5)
                    a4 (copy, index: 6)
                    a1 (copy, index: 7)
                ]]
                if (a2.Visible) then
                    local v2;
                    if (not a2.Parent) then
                        return;
                    end;
                    v2 = a8.UserInputType;
                    if (v2 == Enum.UserInputType.MouseMovement and tbl_upv_4.Held and u1) then
                        local Position_1 = a8.Position;
                        tbl_upv_4.Delta = Position_1 - u1;
                        u1 = Position_1;
                        return;
                    end;
                    if (v2 == Enum.UserInputType.MouseWheel) then
                        tbl_upv_4.TargetScale = math.clamp(tbl_upv_4.TargetScale + (a8.Position.Z * a5), a3, a4);
                        a1:StartZoomLoop(a2);
                    end;
                end;
            end
        )
    );
    table.insert(
        tbl_3,
        UserInputService_upv_1.InputEnded:Connect(
            function(a9)
                --[[
                  line: 66
                  upvalues:
                    tbl_upv_4 (copy, index: 1)
                    u1 (ref,  index: 2)
                ]]
                if (a9.UserInputType ~= Enum.UserInputType.MouseButton1) then
                    return;
                end;
                if (tbl_upv_4.Held) then
                    tbl_upv_4.Held = false;
                    tbl_upv_4.Delta = a9.Position == u1 and Vector3.new() or tbl_upv_4.Delta;
                end;
            end
        )
    );
    tbl_upv_1[a2] = tbl_upv_4;
end;
tbl_2.StartZoomLoop = function(a1, a2)
    --[[
      name: StartZoomLoop
      line: 76
      upvalues:
        tbl_upv_1 (copy, index: 1)
        RunService_upv_1 (copy, index: 2)
        NumberUtil_upv_1 (copy, index: 3)
    ]]
    local v4 = tbl_upv_1[a2];
    if (v4) then
        local v5 = nil;
        if (not v4.Looping) then
            v4.Looping = true;
            local v6, v7 = nil, nil;
            if (v4.Held) then
                local Delta_1 = v4.Delta;
                local v8 = RunService_upv_1.Heartbeat:Wait();
                v5 = v4.Frame;
                if (not v5 or not v5.Parent) then
                    return;
                end;
                v6 = v4.Delta ~= Delta_1;
                if (not (v4.Held)) then
                    v4.Delta = v4.Delta:Lerp(Vector3.new(), v8 * 10);
                    v6 = true;
                end;
                v7 = v4.Scale ~= v4.TargetScale;
                if (v7) then
                    local v9 = math.abs(v4.Scale - v4.TargetScale) <= 0.01 and v4.TargetScale or NumberUtil_upv_1:Lerp(v4.Scale, v4.TargetScale, v8 * 15);
                    v4.Scale = v9;
                    v5.Size = UDim2.new(v4.Scale, 0, v4.Scale, 0);
                    v7 = true;
                end;
                if (v6) then
                    local v10;
                    v10 = v5.Position;
                    local v11;
                    v11 = v4.Delta;
                    local v12;
                    v12 = a2.AbsoluteSize;
                    local v13 = math.max((v4.Scale * 0.5) - 0.5, 0);
                    local v14;
                    v14 = 0.5 - v13;
                    local v15;
                    v15 = v13 + 0.5;
                    local v16;
                    if (not (v7) or v6) then
                        v16 = 1;
                    else
                        v16 = 0;
                    end;
                    v5.Position = UDim2.new(math.clamp(v10.X.Scale + ((v11.X / v12.X) * v16), v14, v15), 0, math.clamp(v10.Y.Scale + ((v11.Y / v12.Y) * v16), v14, v15), 0);
                else
                    local v10, v11, v12, v14, v15 = nil, nil, nil, nil, nil;
                    if (v7) then
                        v10 = v5.Position;
                        v11 = v4.Delta;
                        v12 = a2.AbsoluteSize;
                        local v13 = math.max((v4.Scale * 0.5) - 0.5, 0);
                        v14 = 0.5 - v13;
                        v15 = v13 + 0.5;
                        local v16;
                        if (not (v7) or v6) then
                            v16 = 1;
                        else
                            v16 = 0;
                        end;
                        v5.Position = UDim2.new(math.clamp(v10.X.Scale + ((v11.X / v12.X) * v16), v14, v15), 0, math.clamp(v10.Y.Scale + ((v11.Y / v12.Y) * v16), v14, v15), 0);
                    end;
                end;
            elseif (v4.Scale ~= v4.TargetScale) then
                local Delta_1 = v4.Delta;
                local v8 = RunService_upv_1.Heartbeat:Wait();
                v5 = v4.Frame;
                if (not v5) then
                    return;
                end;
                if (v5.Parent) then
                    v6 = v4.Delta ~= Delta_1;
                    if (not (v4.Held)) then
                        v4.Delta = v4.Delta:Lerp(Vector3.new(), v8 * 10);
                        v6 = true;
                    end;
                    v7 = v4.Scale ~= v4.TargetScale;
                    if (v7) then
                        local v9 = math.abs(v4.Scale - v4.TargetScale) <= 0.01 and v4.TargetScale or NumberUtil_upv_1:Lerp(v4.Scale, v4.TargetScale, v8 * 15);
                        v4.Scale = v9;
                        v5.Size = UDim2.new(v4.Scale, 0, v4.Scale, 0);
                        v7 = true;
                    end;
                    if (v6) then
                        local v10;
                        v10 = v5.Position;
                        local v11;
                        v11 = v4.Delta;
                        local v12;
                        v12 = a2.AbsoluteSize;
                        local v13 = math.max((v4.Scale * 0.5) - 0.5, 0);
                        local v14;
                        v14 = 0.5 - v13;
                        local v15;
                        v15 = v13 + 0.5;
                        local v16;
                        if (not (v7) or v6) then
                            v16 = 1;
                        else
                            v16 = 0;
                        end;
                        v5.Position = UDim2.new(math.clamp(v10.X.Scale + ((v11.X / v12.X) * v16), v14, v15), 0, math.clamp(v10.Y.Scale + ((v11.Y / v12.Y) * v16), v14, v15), 0);
                    else
                        local v10, v11, v12, v14, v15 = nil, nil, nil, nil, nil;
                        if (v7) then
                            v10 = v5.Position;
                            v11 = v4.Delta;
                            v12 = a2.AbsoluteSize;
                            local v13 = math.max((v4.Scale * 0.5) - 0.5, 0);
                            v14 = 0.5 - v13;
                            v15 = v13 + 0.5;
                            local v16;
                            if (not (v7) or v6) then
                                v16 = 1;
                            else
                                v16 = 0;
                            end;
                            v5.Position = UDim2.new(math.clamp(v10.X.Scale + ((v11.X / v12.X) * v16), v14, v15), 0, math.clamp(v10.Y.Scale + ((v11.Y / v12.Y) * v16), v14, v15), 0);
                        end;
                    end;
                end;
            elseif (v4.Delta.Magnitude < 0.01) then
                v4.Looping = false;
            else
                local Delta_1 = v4.Delta;
                local v8 = RunService_upv_1.Heartbeat:Wait();
                v5 = v4.Frame;
                if (not v5 or not v5.Parent) then
                    return;
                end;
                v6 = v4.Delta ~= Delta_1;
                if (not (v4.Held)) then
                    v4.Delta = v4.Delta:Lerp(Vector3.new(), v8 * 10);
                    v6 = true;
                end;
                v7 = v4.Scale ~= v4.TargetScale;
                if (v7) then
                    local v9 = math.abs(v4.Scale - v4.TargetScale) <= 0.01 and v4.TargetScale or NumberUtil_upv_1:Lerp(v4.Scale, v4.TargetScale, v8 * 15);
                    v4.Scale = v9;
                    v5.Size = UDim2.new(v4.Scale, 0, v4.Scale, 0);
                    v7 = true;
                end;
                if (v6) then
                    local v10;
                    v10 = v5.Position;
                    local v11;
                    v11 = v4.Delta;
                    local v12;
                    v12 = a2.AbsoluteSize;
                    local v13 = math.max((v4.Scale * 0.5) - 0.5, 0);
                    local v14;
                    v14 = 0.5 - v13;
                    local v15;
                    v15 = v13 + 0.5;
                    local v16;
                    if (not (v7) or v6) then
                        v16 = 1;
                    else
                        v16 = 0;
                    end;
                    v5.Position = UDim2.new(math.clamp(v10.X.Scale + ((v11.X / v12.X) * v16), v14, v15), 0, math.clamp(v10.Y.Scale + ((v11.Y / v12.Y) * v16), v14, v15), 0);
                else
                    local v10, v11, v12, v14, v15 = nil, nil, nil, nil, nil;
                    if (v7) then
                        v10 = v5.Position;
                        v11 = v4.Delta;
                        v12 = a2.AbsoluteSize;
                        local v13 = math.max((v4.Scale * 0.5) - 0.5, 0);
                        v14 = 0.5 - v13;
                        v15 = v13 + 0.5;
                        local v16;
                        if (not (v7) or v6) then
                            v16 = 1;
                        else
                            v16 = 0;
                        end;
                        v5.Position = UDim2.new(math.clamp(v10.X.Scale + ((v11.X / v12.X) * v16), v14, v15), 0, math.clamp(v10.Y.Scale + ((v11.Y / v12.Y) * v16), v14, v15), 0);
                    end;
                end;
            end;
        end;
    end;
end;
tbl_2.ClearScrollFrame = function(a1, a2)
    --[[
      name: ClearScrollFrame
      line: 114
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    local v17 = tbl_upv_1[a2];
    if (not v17) then
        return;
    end;
    v17.Delta = Vector3.new();
    v17.Held = false;
    for _, value_1 in pairs(v17.Connections) do
        value_1:Disconnect();
    end;
    tbl_upv_1[a2] = nil;
end;
tbl_2.GetZoomInfo = function(a1, a2)
    --[[
      name: GetZoomInfo
      line: 124
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    return tbl_upv_1[a2];
end;
return tbl_2;