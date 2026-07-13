-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local GuiService_upv_1 = game:GetService("GuiService");
local tbl_upv_1 = {script.Parent:WaitForChild("TopBarAlignedRight")};
local function UpdateInsets_1()
    --[[
      name: UpdateInsets
      line: 4
      upvalues:
        GuiService_upv_1 (copy, index: 1)
        tbl_upv_1 (copy, index: 2)
    ]]
    local TopbarInset_1 = GuiService_upv_1.TopbarInset;
    local Min_1 = TopbarInset_1.Min;
    local Width_1 = TopbarInset_1.Width;
    local Height_1 = TopbarInset_1.Height;
    local v1 = ((TopbarInset_1.Height == 36) and 4) or 18;
    for _, value_1 in pairs(tbl_upv_1) do
        value_1.Size = UDim2.fromOffset(Width_1, Height_1);
        value_1.Position = UDim2.fromOffset(Min_1.X, Min_1.Y);
        value_1.UIPadding.PaddingTop = UDim.new(0, v1);
    end;
end;
GuiService_upv_1:GetPropertyChangedSignal("TopbarInset"):Connect(UpdateInsets_1);
UpdateInsets_1();