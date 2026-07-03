-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local UserInputService = game:GetService("UserInputService");
local LocalPlayer = Players.LocalPlayer;
local ItemSearch = LocalPlayer.PlayerGui:WaitForChild("ItemSearchMain"):WaitForChild("ItemSearch");
local TextBox = ItemSearch:WaitForChild("TextBox");
local List = ItemSearch:WaitForChild("List");
local Cancel = ItemSearch:WaitForChild("Cancel");
local AmountFrame = ItemSearch:WaitForChild("AmountFrame");
local Accept = AmountFrame:WaitForChild("Accept");
local Cancel2 = AmountFrame:WaitForChild("Cancel");
local TextBox2 = AmountFrame:WaitForChild("TextBox");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local Values = ReplicatedStorage:WaitForChild("Values");
local Items = require(Modules:WaitForChild("Items"));
local v1 = {};
local u2 = nil;
local u3 = nil;

local function u6(p4) -- Line: 41
    -- upvalues: Items (copy), Values (copy)
    local v5 = {};

    for i, v in pairs(Items) do
        if (not v.Hidden or Values.ShowHiddenRecipes.Value) and v.Name:lower():find(p4:lower(), 1, true) then
            table.insert(v5, { i, v });

            if #v5 >= 8 then
                break;
            end;
        end;
    end;

    return v5;
end;

local u13 = {
    BeginSearch = function() -- Line: 53, Name: BeginSearch
        -- upvalues: UserInputService (copy), u2 (ref), u3 (ref), ItemSearch (copy), List (copy)
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
        UserInputService.MouseIconEnabled = true;
        u2 = nil;
        u3 = nil;
        ItemSearch.Visible = true;
        List.Visible = true;

        while ItemSearch.Visible and not (u2 and u3) do
            task.wait();
        end;

        ItemSearch.Visible = false;

        return u2, u3;
    end,

    CancelSearch = function(p7) -- Line: 67, Name: CancelSearch
        -- upvalues: UserInputService (copy), ItemSearch (copy)
        if not p7 then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
            UserInputService.MouseIconEnabled = false;
        end;

        ItemSearch.Visible = false;
    end,

    UpdateSearch = function(p8) -- Line: 75, Name: UpdateSearch
        -- upvalues: u6 (copy), List (copy), ItemSearch (copy)
        local v9 = p8 == "" and {} or u6(p8);
        local v10 = false;

        for i = 1, 8 do
            local v11 = v9[i];
            local v12 = List:FindFirstChild(i);

            if v12 then
                if v11 then
                    v12.ItemName.Text = v11[2].Name;
                    v12.ItemDesc.Text = v11[2].Description;
                    v12.ItemImage.Image = typeof(v11[2].Image) == "table" and v11[2].Image.Default or v11[2].Image;
                    v12.Visible = true;
                    v12:SetAttribute("Id", v11[1]);
                    v10 = true;
                else
                    v12.Visible = false;
                end;
            end;
        end;

        ItemSearch.NoResults.Visible = not v10;
    end,

    IsSearching = function() -- Line: 96, Name: IsSearching
        -- upvalues: ItemSearch (copy)
        return ItemSearch.Visible;
    end
};
TextBox:GetPropertyChangedSignal("Text"):Connect(function() -- Line: 101
    -- upvalues: u13 (copy), TextBox (copy)
    u13.UpdateSearch(TextBox.Text);
end);
TextBox2:GetPropertyChangedSignal("Text"):Connect(function() -- Line: 105
    -- upvalues: TextBox2 (copy)
    local Text = TextBox2.Text;

    if Text == "" then
        return;
    end;

    local u14 = 1;
    local _, _ = pcall(function() -- Line: 110
        -- upvalues: u14 (ref), Text (copy)
        u14 = tonumber(Text);
    end);

    if type(u14) == "number" then
        local v15 = math.floor(u14);
        local v16 = math.clamp(v15, 1, 100000);
        u14 = tostring(v16);

        if Text == u14 then
            return;
        end;

        TextBox2.Text = u14;
    else
        TextBox2.Text = "1";
    end;
end);
Accept.MouseButton1Click:Connect(function() -- Line: 122
    -- upvalues: TextBox2 (copy), u3 (ref), AmountFrame (copy), List (copy)
    local u17 = 1;
    local success, _ = pcall(function() -- Line: 124
        -- upvalues: u17 (ref), TextBox2 (ref)
        u17 = tonumber(TextBox2.Text);
    end);
    u3 = success and (type(u17) == "number" and (u17 > 1 and u17)) or 1;
    AmountFrame.Visible = false;
    List.Visible = true;
end);
Cancel2.MouseButton1Click:Connect(function() -- Line: 132
    -- upvalues: AmountFrame (copy), List (copy)
    AmountFrame.Visible = false;
    List.Visible = true;
end);
Cancel.MouseButton1Click:Connect(function() -- Line: 137
    -- upvalues: u2 (ref), u3 (ref), ItemSearch (copy)
    u2 = nil;
    u3 = nil;
    ItemSearch.Visible = false;
end);

for _, child in pairs(List:GetChildren()) do
    if child:IsA("ImageButton") then
        v1[child] = child.MouseButton1Click:Connect(function() -- Line: 145
            -- upvalues: u2 (ref), child (copy), AmountFrame (copy), List (copy)
            u2 = child:GetAttribute("Id");
            AmountFrame.Visible = true;
            List.Visible = false;
        end);
    end;
end;

LocalPlayer.CharacterRemoving:Connect(function() -- Line: 153
    -- upvalues: u13 (copy)
    u13.CancelSearch();
end);

return u13;