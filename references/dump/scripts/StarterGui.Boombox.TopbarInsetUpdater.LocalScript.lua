-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local GuiService = game:GetService("GuiService");
local u1 = { script.Parent:WaitForChild("TopBarAlignedRight") };

local function UpdateInsets() -- Line: 4
    -- upvalues: GuiService (copy), u1 (copy)
    local TopbarInset = GuiService.TopbarInset;
    local Min = TopbarInset.Min;
    local _ = TopbarInset.Max;
    local Width = TopbarInset.Width;
    local Height = TopbarInset.Height;
    local v2 = TopbarInset.Height == 36 and 4 or 18;

    for _, v in pairs(u1) do
        v.Size = UDim2.fromOffset(Width, Height);
        v.Position = UDim2.fromOffset(Min.X, Min.Y);
        v.UIPadding.PaddingTop = UDim.new(0, v2);
    end;
end;

GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(UpdateInsets);
UpdateInsets();