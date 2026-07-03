-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");
local Modules = game:GetService("ReplicatedStorage"):WaitForChild("Modules");
local NumberUtil = require(Modules:WaitForChild("NumberUtil"));
local u1 = {};

return {
    AddScrollToFrame = function(u2, u3, u4, u5, p6, p7) -- Line: 26, Name: AddScrollToFrame
        -- upvalues: UserInputService (copy), u1 (copy)
        local Frame = u3:FindFirstChild("Frame");
        local v8 = assert(Frame, "\"FRAME\" COMPONENT NOT FOUND");
        local v9 = p7 or 1;
        local u10 = p6 or 0.1;
        local u11 = nil;
        local v12 = {};
        local u13 = {
            Held = false,
            Looping = false,
            Connections = v12,
            Delta = Vector3.new(),
            Frame = v8,
            Scale = v9,
            TargetScale = v9
        };
        v8.Size = UDim2.new(u13.Scale, 0, u13.Scale, 0);
        table.insert(v12, u3.InputBegan:Connect(function(p14) -- Line: 42
            -- upvalues: u3 (copy), u13 (copy), u11 (ref), u2 (copy)
            if not u3.Visible then
                return;
            end;

            if p14.UserInputType == Enum.UserInputType.MouseButton1 and not u13.Held then
                u11 = p14.Position;
                u13.Held = true;
                u2:StartZoomLoop(u3);
            end;
        end));
        table.insert(v12, UserInputService.InputChanged:Connect(function(p15) -- Line: 52
            -- upvalues: u3 (copy), u13 (copy), u11 (ref), u10 (ref), u4 (copy), u5 (copy), u2 (copy)
            if not (u3.Visible and u3.Parent) then
                return;
            end;

            local UserInputType = p15.UserInputType;

            if UserInputType ~= Enum.UserInputType.MouseMovement or not (u13.Held and u11) then
                if UserInputType == Enum.UserInputType.MouseWheel then
                    u13.TargetScale = math.clamp(u13.TargetScale + p15.Position.Z * u10, u4, u5);
                    u2:StartZoomLoop(u3);
                end;

                return;
            end;

            local Position = p15.Position;
            u13.Delta = Position - u11;
            u11 = Position;
        end));
        table.insert(v12, UserInputService.InputEnded:Connect(function(p16) -- Line: 66
            -- upvalues: u13 (copy), u11 (ref)
            if p16.UserInputType ~= Enum.UserInputType.MouseButton1 or not u13.Held then
                return;
            end;

            u13.Held = false;
            u13.Delta = p16.Position == u11 and Vector3.new() or u13.Delta;
        end));
        u1[u3] = u13;
    end,

    StartZoomLoop = function(p17, p18) -- Line: 76, Name: StartZoomLoop
        -- upvalues: u1 (copy), RunService (copy), NumberUtil (copy)
        local v19 = u1[p18];

        if not v19 or v19.Looping then
            return;
        end;

        v19.Looping = true;

        while v19.Held or (v19.Scale ~= v19.TargetScale or v19.Delta.Magnitude >= 0.01) do
            local Delta = v19.Delta;
            local v20 = RunService.Heartbeat:Wait();
            local Frame = v19.Frame;

            if not (Frame and Frame.Parent) then
                return;
            end;

            local v21 = v19.Delta ~= Delta;

            if not v19.Held then
                v19.Delta = v19.Delta:Lerp(Vector3.new(), v20 * 10);
                v21 = true;
            end;

            local v22 = v19.Scale ~= v19.TargetScale;

            if v22 then
                v19.Scale = math.abs(v19.Scale - v19.TargetScale) <= 0.01 and v19.TargetScale or NumberUtil:Lerp(v19.Scale, v19.TargetScale, v20 * 15);
                Frame.Size = UDim2.new(v19.Scale, 0, v19.Scale, 0);
                v22 = true;
            end;

            if v21 or v22 then
                local Position = Frame.Position;
                local Delta2 = v19.Delta;
                local AbsoluteSize = p18.AbsoluteSize;
                local v23 = math.max(v19.Scale * 0.5 - 0.5, 0);
                local v24 = 0.5 - v23;
                local v25 = v23 + 0.5;
                local v26 = v22 and not v21 and 0 or 1;
                Frame.Position = UDim2.new(math.clamp(Position.X.Scale + Delta2.X / AbsoluteSize.X * v26, v24, v25), 0, math.clamp(Position.Y.Scale + Delta2.Y / AbsoluteSize.Y * v26, v24, v25), 0);
            end;
        end;

        v19.Looping = false;
    end,

    ClearScrollFrame = function(p27, p28) -- Line: 114, Name: ClearScrollFrame
        -- upvalues: u1 (copy)
        local v29 = u1[p28];

        if not v29 then
            return;
        end;

        v29.Delta = Vector3.new();
        v29.Held = false;

        for _, v in pairs(v29.Connections) do
            v:Disconnect();
        end;

        u1[p28] = nil;
    end,

    GetZoomInfo = function(p30, p31) -- Line: 124, Name: GetZoomInfo
        -- upvalues: u1 (copy)
        return u1[p31];
    end
};