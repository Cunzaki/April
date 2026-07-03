-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local TweenService = game:GetService("TweenService");
local u1 = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out);

for _, child in pairs(script.Parent:GetChildren()) do
    if child:IsA("GuiButton") and child:FindFirstChild("HoverTextLabel") then
        child.MouseEnter:Connect(function() -- Line: 7
            -- upvalues: TweenService (copy), child (copy), u1 (copy)
            TweenService:Create(child, u1, {
                Size = UDim2.fromOffset(child.Size.Y.Offset * 3, child.Size.Y.Offset)
            }):Play();
            TweenService:Create(child.HoverTextLabel, u1, {
                TextTransparency = 0
            }):Play();
        end);
        child.MouseLeave:Connect(function() -- Line: 12
            -- upvalues: TweenService (copy), child (copy), u1 (copy)
            TweenService:Create(child, u1, {
                Size = UDim2.fromOffset(child.Size.Y.Offset, child.Size.Y.Offset)
            }):Play();
            TweenService:Create(child.HoverTextLabel, u1, {
                TextTransparency = 1
            }):Play();
        end);
    end;
end;