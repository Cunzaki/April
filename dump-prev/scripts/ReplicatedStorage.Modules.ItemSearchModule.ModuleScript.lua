-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local Players_1 = game:GetService("Players");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local UserInputService_upv_1 = game:GetService("UserInputService");
local LocalPlayer_1 = Players_1.LocalPlayer;
local ItemSearch_upv_1 = LocalPlayer_1.PlayerGui:WaitForChild("ItemSearchMain"):WaitForChild("ItemSearch");
local TextBox_upv_1 = ItemSearch_upv_1:WaitForChild("TextBox");
local List_upv_1 = ItemSearch_upv_1:WaitForChild("List");
local Cancel_1 = ItemSearch_upv_1:WaitForChild("Cancel");
local AmountFrame_upv_1 = ItemSearch_upv_1:WaitForChild("AmountFrame");
local Accept_1 = AmountFrame_upv_1:WaitForChild("Accept");
local Cancel_2 = AmountFrame_upv_1:WaitForChild("Cancel");
local TextBox_upv_2 = AmountFrame_upv_1:WaitForChild("TextBox");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local Values_upv_1 = ReplicatedStorage_1:WaitForChild("Values");
local Items_upv_1 = require(Modules_1:WaitForChild("Items"));
local tbl_1 = {};
local u1 = nil;
local u2 = nil;
local tbl_upv_2 = {};
tbl_upv_2.BeginSearch = function()
    --[[
      name: BeginSearch
      line: 53
      upvalues:
        UserInputService_upv_1 (copy, index: 1)
        u1 (ref,  index: 2)
        u2 (ref,  index: 3)
        ItemSearch_upv_1 (copy, index: 4)
        List_upv_1 (copy, index: 5)
    ]]
    UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.Default;
    UserInputService_upv_1.MouseIconEnabled = true;
    u1 = nil;
    u2 = nil;
    ItemSearch_upv_1.Visible = true;
    List_upv_1.Visible = true;
    while (ItemSearch_upv_1.Visible) do
        if (not (u1)) then
            task.wait();
            continue;
        end;
        if (u2) then
            break;
        else
            task.wait();
        end;
    end;
    ItemSearch_upv_1.Visible = false;
    return u1, u2;
end;
tbl_upv_2.CancelSearch = function(a1)
    --[[
      name: CancelSearch
      line: 67
      upvalues:
        UserInputService_upv_1 (copy, index: 1)
        ItemSearch_upv_1 (copy, index: 2)
    ]]
    if (not (a1)) then
        UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
        UserInputService_upv_1.MouseIconEnabled = false;
    end;
    ItemSearch_upv_1.Visible = false;
end;
local function u3(a1)
    --[[
      line: 41
      upvalues:
        Items_upv_1 (copy, index: 1)
        Values_upv_1 (copy, index: 2)
    ]]
    local tbl_3 = {};
    for key_1, value_1 in pairs(Items_upv_1) do
        if (not (value_1.Hidden) or Values_upv_1.ShowHiddenRecipes.Value) then
            if (not (value_1.Name:lower():find(a1:lower(), 1, true))) then
                continue;
            end;
            table.insert(tbl_3, {key_1, value_1});
            if (#tbl_3 >= 8) then
                break;
            end;
        end;
    end;
    return tbl_3;
end;
tbl_upv_2.UpdateSearch = function(a1)
    --[[
      name: UpdateSearch
      line: 75
      upvalues:
        u3 (copy, index: 1)
        List_upv_1 (copy, index: 2)
        ItemSearch_upv_1 (copy, index: 3)
    ]]
    local v1 = ((a1 == "") and {}) or (u3(a1));
    local v2 = false;
    for n_1 = 1, 8 do
        local v3 = v1[n_1];
        local v4;
        v4 = List_upv_1:FindFirstChild(n_1);
        if (not (v4)) then
            continue;
        end;
        if (v3) then
            local v5 = true;
            v4.ItemName.Text = v3[2].Name;
            v4.ItemDesc.Text = v3[2].Description;
            local ItemImage_1 = v4.ItemImage;
            ItemImage_1.Image = typeof(v3[2].Image) == "table" and v3[2].Image.Default or v3[2].Image;
            v4.Visible = true;
            v4:SetAttribute("Id", v3[1]);
            v2 = v5;
        else
            v4.Visible = false;
        end;
    end;
    ItemSearch_upv_1.NoResults.Visible = not v2;
end;
tbl_upv_2.IsSearching = function()
    --[[
      name: IsSearching
      line: 96
      upvalues:
        ItemSearch_upv_1 (copy, index: 1)
    ]]
    return ItemSearch_upv_1.Visible;
end;
TextBox_upv_1:GetPropertyChangedSignal("Text"):Connect(
    function()
        --[[
          line: 101
          upvalues:
            tbl_upv_2 (copy, index: 1)
            TextBox_upv_1 (copy, index: 2)
        ]]
        tbl_upv_2.UpdateSearch(TextBox_upv_1.Text);
    end
);
TextBox_upv_2:GetPropertyChangedSignal("Text"):Connect(
    function()
        --[[
          line: 105
          upvalues:
            TextBox_upv_2 (copy, index: 1)
        ]]
        local Text_upv_1 = TextBox_upv_2.Text;
        local u4;
        if (Text_upv_1 == "") then
            return;
        end;
        u4 = 1;
        local _, v1 = pcall(
            function()
                --[[
                  line: 110
                  upvalues:
                    u4 (ref,  index: 1)
                    Text_upv_1 (copy, index: 2)
                ]]
                u4 = tonumber(Text_upv_1);
            end
        );
        if (type(u4) ~= "number") then
            TextBox_upv_2.Text = "1";
        else
            u4 = tostring(math.clamp(math.floor(u4), 1, 1e+05));
            if (Text_upv_1 == u4) then
                return;
            end;
            TextBox_upv_2.Text = u4;
        end;
    end
);
Accept_1.MouseButton1Click:Connect(
    function()
        --[[
          line: 122
          upvalues:
            TextBox_upv_2 (copy, index: 1)
            u2 (ref,  index: 2)
            AmountFrame_upv_1 (copy, index: 3)
            List_upv_1 (copy, index: 4)
        ]]
        local u5 = 1;
        local success_1, _ = pcall(
            function()
                --[[
                  line: 124
                  upvalues:
                    u5 (ref,  index: 1)
                    TextBox_upv_2 (copy, index: 2)
                ]]
                u5 = tonumber(TextBox_upv_2.Text);
            end
        );
        local v7;
        if (success_1) then
            if (type(u5) ~= "number" or u5 <= 1) then
                v7 = 1;
            else
                v7 = u5 or 1;
            end;
        else
            v7 = 1;
        end;
        u2 = v7;
        AmountFrame_upv_1.Visible = false;
        List_upv_1.Visible = true;
    end
);
Cancel_2.MouseButton1Click:Connect(
    function()
        --[[
          line: 132
          upvalues:
            AmountFrame_upv_1 (copy, index: 1)
            List_upv_1 (copy, index: 2)
        ]]
        AmountFrame_upv_1.Visible = false;
        List_upv_1.Visible = true;
    end
);
Cancel_1.MouseButton1Click:Connect(
    function()
        --[[
          line: 137
          upvalues:
            u1 (ref,  index: 1)
            u2 (ref,  index: 2)
            ItemSearch_upv_1 (copy, index: 3)
        ]]
        u1 = nil;
        u2 = nil;
        ItemSearch_upv_1.Visible = false;
    end
);
local v8 = nil;
for _, value_upv_2 in pairs(List_upv_1:GetChildren()) do
    v8 = value_upv_2:IsA("ImageButton");
    if (v8) then
        tbl_1[value_upv_2] = value_upv_2.MouseButton1Click:Connect(
            function()
                --[[
                  line: 145
                  upvalues:
                    u1 (ref,  index: 1)
                    value_upv_2 (copy, index: 2)
                    AmountFrame_upv_1 (copy, index: 3)
                    List_upv_1 (copy, index: 4)
                ]]
                u1 = value_upv_2:GetAttribute("Id");
                AmountFrame_upv_1.Visible = true;
                List_upv_1.Visible = false;
            end
        );
    end;
end;
LocalPlayer_1.CharacterRemoving:Connect(
    function()
        --[[
          line: 153
          upvalues:
            tbl_upv_2 (copy, index: 1)
        ]]
        tbl_upv_2.CancelSearch();
    end
);
return tbl_upv_2;