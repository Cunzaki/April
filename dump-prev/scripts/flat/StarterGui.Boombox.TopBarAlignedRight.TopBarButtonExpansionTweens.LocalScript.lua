-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local TweenService_upv_1 = game:GetService("TweenService");
local u1 = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out);
for _, value_upv_1 in pairs(script.Parent:GetChildren()) do
    if (not (value_upv_1:IsA("GuiButton"))) then
        continue;
    end;
    if (value_upv_1:FindFirstChild("HoverTextLabel")) then
        value_upv_1.MouseEnter:Connect(
            function()
                --[[
                  line: 7
                  upvalues:
                    TweenService_upv_1 (copy, index: 1)
                    value_upv_1 (copy, index: 2)
                    u1 (copy, index: 3)
                ]]
                local tbl_1 = {};
                tbl_1.Size = UDim2.fromOffset(value_upv_1.Size.Y.Offset * 3, value_upv_1.Size.Y.Offset);
                TweenService_upv_1:Create(value_upv_1, u1, tbl_1):Play();
                TweenService_upv_1:Create(value_upv_1.HoverTextLabel, u1, {}):Play();
            end
        );
        value_upv_1.MouseLeave:Connect(
            function()
                --[[
                  line: 12
                  upvalues:
                    TweenService_upv_1 (copy, index: 1)
                    value_upv_1 (copy, index: 2)
                    u1 (copy, index: 3)
                ]]
                local tbl_2 = {};
                tbl_2.Size = UDim2.fromOffset(value_upv_1.Size.Y.Offset, value_upv_1.Size.Y.Offset);
                TweenService_upv_1:Create(value_upv_1, u1, tbl_2):Play();
                TweenService_upv_1:Create(value_upv_1.HoverTextLabel, u1, {}):Play();
            end
        );
    end;
end;