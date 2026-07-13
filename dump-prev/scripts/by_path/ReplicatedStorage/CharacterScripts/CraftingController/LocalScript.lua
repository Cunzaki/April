-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local Players_1 = game:GetService("Players");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local MarketplaceService_upv_1 = game:GetService("MarketplaceService");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local Values_upv_1 = ReplicatedStorage_1:WaitForChild("Values");
local Bases_1 = workspace:WaitForChild("Bases");
local VFX_1 = workspace:WaitForChild("VFX");
local Animals_1 = workspace:WaitForChild("Animals");
local Plants_1 = workspace:WaitForChild("Plants");
local Vegetation_1 = workspace:WaitForChild("Vegetation");
local SettingRemotes_upv_1 = ReplicatedStorage_1:WaitForChild("SettingRemotes");
local NumberUtil_upv_1 = require(Modules_1:WaitForChild("NumberUtil"));
local RecipeModule_upv_1 = require(Modules_1:WaitForChild("RecipeModule"));
local ResearchModule_upv_1 = require(Modules_1:WaitForChild("ResearchModule"));
local ButtonClass_upv_1 = require(Modules_1:WaitForChild("ButtonClass"));
local Items_upv_1 = require(Modules_1:WaitForChild("Items"));
local RaycastUtil_1 = require(Modules_1:WaitForChild("RaycastUtil"));
local SettingsModule_upv_1 = require(Modules_1:WaitForChild("SettingsModule"));
local u1 = require(Modules_1:WaitForChild("AssetContainer"))();
local LocalPlayer_upv_1 = Players_1.LocalPlayer;
local Parent_1 = script.Parent;
local PlayerGui_1 = LocalPlayer_upv_1:WaitForChild("PlayerGui");
local Humanoid_1 = Parent_1:WaitForChild("Humanoid");
local HumanoidRootPart_1 = Parent_1:WaitForChild("HumanoidRootPart");
local InventoryController_upv_1 = Parent_1:WaitForChild("InventoryController");
local StatsController_1 = Parent_1:WaitForChild("StatsController");
local Update_1 = script:WaitForChild("Update");
local Fetch_upv_1 = InventoryController_upv_1:WaitForChild("Fetch");
local CraftUpdate_upv_1 = StatsController_1:WaitForChild("CraftUpdate");
local Crafting_1 = PlayerGui_1:WaitForChild("Main"):WaitForChild("Crafting");
local Categories_upv_1 = Crafting_1:WaitForChild("Categories");
local Craftables_1 = Crafting_1:WaitForChild("Craftables");
local Information_upv_1 = Crafting_1:WaitForChild("Information");
local Materials_upv_1 = Crafting_1:WaitForChild("Materials");
local Queue_1 = Crafting_1:WaitForChild("Queue");
local Search_1 = Crafting_1:WaitForChild("Search");
local Skins_upv_1 = Crafting_1:WaitForChild("Skins");
local Content_upv_1 = Craftables_1:WaitForChild("Content");
local Content_upv_2 = Queue_1:WaitForChild("Content");
local List_upv_1 = Materials_upv_1:WaitForChild("List");
local CraftAmount_upv_1 = Materials_upv_1:WaitForChild("CraftAmount");
local TextBox_upv_1 = Search_1:WaitForChild("TextBox");
local List_upv_2 = Skins_upv_1:WaitForChild("List");
local u2 = RecipeModule_upv_1:GetCraftingCategories();
local u3 = ResearchModule_upv_1:FetchAllWorkbenches();
local u4 = "All";
local u5 = 0;
local u6 = "Default";
local tbl_upv_1 = {};
local tbl_upv_2 = {};
local tbl_upv_3 = {};
local tbl_upv_4 = {};
local u7 = "";
local u8 = nil;
local u9 = true;
local u10 = true;
local u11 = 0;
local u12 = {};
local tbl_upv_5 = {};
local u13 = nil;
local u14 = {};
local u15 = {};
local v1 = {};
local u16 = nil;
local u17 = true;
local u18 = nil;
local u19 = nil;
local tbl_upv_6 = {};
local function u20()
    --[[
      line: 102
      upvalues:
        Fetch_upv_1 (copy, index: 1)
    ]]
    local v2 = Fetch_upv_1:Invoke() or {};
    local tbl_7 = {};
    for key_1, value_1 in pairs(v2) do
        if (key_1 ~= "Inventory") then
            local v3;
            if (key_1 ~= "Toolbar") then
                continue;
            end;
        end;
        for _, value_2 in pairs(value_1) do
            if (not (value_2) or value_2 == 0) then
                continue;
            end;
            if (value_2.Amount > 0) then
                local ID_1 = value_2.ID;
                tbl_7[ID_1] = (tbl_7[ID_1] or 0) + value_2.Amount;
            end;
        end;
    end;
    return tbl_7;
end;
local u21 = u20();
local function u22()
    --[[
      line: 149
      upvalues:
        RecipeModule_upv_1 (copy, index: 1)
        u5 (ref,  index: 2)
        Fetch_upv_1 (copy, index: 3)
        u16 (ref,  index: 4)
        u15 (ref,  index: 5)
        Information_upv_1 (copy, index: 6)
        u21 (ref,  index: 7)
        CraftAmount_upv_1 (copy, index: 8)
        List_upv_1 (copy, index: 9)
        NumberUtil_upv_1 (copy, index: 10)
        tbl_upv_6 (copy, index: 11)
        MarketplaceService_upv_1 (copy, index: 12)
        LocalPlayer_upv_1 (copy, index: 13)
        Materials_upv_1 (copy, index: 14)
        u18 (ref,  index: 15)
        u19 (ref,  index: 16)
        u8 (ref,  index: 17)
        ResearchModule_upv_1 (copy, index: 18)
        Values_upv_1 (copy, index: 19)
    ]]
    local v3 = RecipeModule_upv_1:GetRecipesForItem(u5) or {};
    local v4 = v3[1];
    local v5, v6 = nil, nil;
    if (v4) then
        local _, v7 = Fetch_upv_1:Invoke();
        local BenchNeeded_1 = v4.BenchNeeded;
        u16 = table.find(u15, BenchNeeded_1);
        local v8 = (u16 and (v7[BenchNeeded_1])) or 0;
        local v9 = v4.TierNeeded or 0;
        local v10 = false;
        if (BenchNeeded_1 ~= nil) then
            v10 = v9 > 0;
        end;
        local v11 = v9 <= v8;
        local Required_1 = Information_upv_1.Required;
        local v12;
        if (v11) then
            v12 = "";
        else
            v12 = "REQUIRED!";
        end;
        Required_1.Text = v12;
        if (v10) then
            Information_upv_1.Required.Label.Text = ("%* - Tier: <font color=\"rgb(255, 248, 41)\">%*</font>"):format(BenchNeeded_1, v9);
        end;
        Information_upv_1.Required.Visible = v10;
        local v13 = tonumber(CraftAmount_upv_1.Text) or 1;
        local v14 = v11;
        v6 = nil;
        local v15 = nil;
        local v16 = nil;
        local v17 = nil;
        for v18, value_3 in pairs(v4.Costs) do
            v6 = value_3.Amount * v13;
            v15 = u21[value_3.ID] or 0;
            v16 = List_upv_1["Slot" .. v18];
            v16.ItemAmount.Text = "x" .. NumberUtil_upv_1:FormatNumber(v6);
            v16.HasAmount.Text = "x" .. NumberUtil_upv_1:FormatNumber(v15);
            v17 = v6 <= v15;
            v16.Grey.Visible = not v17;
            if (not (v17)) then
                v14 = false;
            end;
        end;
        local v19 = script:GetAttribute((v14 and "CanCraftColor") or "CannotCraftColor");
        local v20 = true;
        v5 = v4.ProductNeeded;
        local v18 = v4.GamepassNeeded;
        local v21;
        if (v5 or v18) then
            local value_3 = v5 or v18;
            v6 = tbl_upv_6[value_3];
            v15 = false;
            if (not (v6) or os.clock() - v6[1] >= 20) then
                if (not v6) then
                    v6 = {};
                    tbl_upv_6[value_3] = v6;
                end;
                v6[1] = os.clock();
                if (v5) then
                    local success_1, v22 = pcall(MarketplaceService_upv_1.PlayerOwnsAsset, MarketplaceService_upv_1, LocalPlayer_upv_1, value_3);
                    v15 = success_1 and v22;
                elseif (v18) then
                    local success_2, v23 = pcall(MarketplaceService_upv_1.UserOwnsGamePassAsync, MarketplaceService_upv_1, LocalPlayer_upv_1.UserId, value_3);
                    v15 = success_2 and v23;
                end;
                v6[2] = v15;
            else
                v15 = v6[2];
            end;
            if (v15) then
                v21 = v20;
            else
                v19 = Color3.fromRGB(255, 225, 0);
                Materials_upv_1.Craft.Text = "PURCHASE";
                Materials_upv_1.Craft.Active = true;
                Materials_upv_1.PriorityCraft.Visible = false;
                if (v5) then
                    u18 = v5;
                elseif (v18) then
                    u19 = v18;
                end;
                v21 = false;
            end;
        else
            v21 = v20;
        end;
        if (v21) then
            u18 = nil;
            u19 = nil;
            Materials_upv_1.Craft.Active = v14;
            Materials_upv_1.Craft.Text = "CRAFT";
            Materials_upv_1.PriorityCraft.Visible = v14;
        end;
        if (u8) then
            u8:UpdateBaseColor(v19);
        end;
        Materials_upv_1.Craft.BackgroundColor3 = v19;
        local v24 = 1;
        if (v8 > 0) then
            v6 = ResearchModule_upv_1:GetInfoFromName(BenchNeeded_1);
            if (v6) then
                v24 = ResearchModule_upv_1:CalculateCraftTime(v8, v9, #v6.Tiers);
            end;
        end;
        v6 = (v4.Time * v13) / Values_upv_1.CraftSpeedMult.Value * v24;
        local v25 = NumberUtil_upv_1:FormatTime(v6, "Minutes", "Seconds", true);
        local v26 = v6 % 1;
        v15 = v25:sub(1, 3) == "0m0" and v25:sub(4) or v25:sub(1, 2) == "0m" and v25:sub(3) or v25;
        if (v26 > 0 and v6 < 60) then
            local v28 = tostring(NumberUtil_upv_1:RoundNumber(v26, 2)):sub(2);
            v15 = v15:sub(1, #v15 - 1) .. v28 .. v15:sub(#v15);
        end;
        Materials_upv_1.YieldInfo.Text = ("Yields x<font color=\"rgb(255, 248, 43)\">%*</font> in <font color=\"rgb(30, 158, 255)\">%*</font>"):format(NumberUtil_upv_1:FormatNumber(v4.ReceiveAmount * v13), v15);
        return u21;
    end;
end;
local function u23(a1, a2, a3)
    --[[
      line: 250
      upvalues:
        u6 (ref,  index: 1)
        tbl_upv_4 (copy, index: 2)
        Items_upv_1 (copy, index: 3)
        Information_upv_1 (copy, index: 4)
    ]]
    local v29 = nil;
    if (u6 ~= a1) then
        v29 = tbl_upv_4[u6];
        if (v29 and v29:IsToggled()) then
            task.defer(v29.ToggleButton, v29, false);
        end;
    elseif (not (a3)) then
        return;
    end;
    local v30 = tbl_upv_4[a1];
    if (v30 and not (v30:IsToggled())) then
        task.defer(v30.ToggleButton, v30, true, a3);
    end;
    u6 = a1;
    if (a2) then
        local Image_1 = Items_upv_1[a2.ID].Image;
        local v31 = type(Image_1) == "table";
        local ItemImage_1 = Information_upv_1.ItemImage;
        local v32, v32;
        if (v31) then
            v32 = Image_1[a1];
            if (not (v32)) then
                v32 = Image_1.Default;
                v32 = v32 or Image_1;
            end;
        else
            v32 = Image_1;
        end;
        ItemImage_1.Image = v32;
    end;
end;
local function u24(a1)
    --[[
      line: 272
      upvalues:
        u5 (ref,  index: 1)
        tbl_upv_2 (copy, index: 2)
        RecipeModule_upv_1 (copy, index: 3)
        Items_upv_1 (copy, index: 4)
        Information_upv_1 (copy, index: 5)
        InventoryController_upv_1 (copy, index: 6)
        tbl_upv_4 (copy, index: 7)
        Fetch_upv_1 (copy, index: 8)
        List_upv_2 (copy, index: 9)
        ButtonClass_upv_1 (copy, index: 10)
        u6 (ref,  index: 11)
        u23 (copy, index: 12)
        SettingsModule_upv_1 (copy, index: 13)
        SettingRemotes_upv_1 (copy, index: 14)
        Skins_upv_1 (copy, index: 15)
        List_upv_1 (copy, index: 16)
        CraftAmount_upv_1 (copy, index: 17)
        u7 (ref,  index: 18)
        u22 (copy, index: 19)
    ]]
    local v33, v34, u25 = nil, nil, nil;
    if (u5 ~= a1) then
        v33 = tbl_upv_2[u5];
        if (v33) then
            v34 = v33:IsToggled();
            if (v34) then
                task.defer(v33.ToggleButton, v33, false);
            end;
        end;
        v34 = tbl_upv_2[a1];
        if (v34) then
            u25 = v34:IsToggled();
            if (not (u25)) then
                task.defer(v34.ToggleButton, v34, true);
            end;
        end;
        local v35 = RecipeModule_upv_1:GetRecipesForItem(a1) or {};
        u25 = v35[1];
        if (u25) then
            local Costs_1 = u25.Costs;
            u5 = a1;
            local v36 = Items_upv_1[a1];
            local Image_2 = v36.Image;
            local v37 = type(Image_2) == "table";
            Information_upv_1.ItemName.Text = v36.Name;
            Information_upv_1.Description.Text = v36.Description;
            InventoryController_upv_1.ItemStats:Invoke(Information_upv_1.ItemStats, a1, v36);
            if (v37) then
                local v38 = nil;
                for v39, value_4 in pairs(tbl_upv_4) do
                    v38 = value_4.Button;
                    if (v38.Parent) then
                        v38:Destroy();
                    end;
                    value_4:Destroy();
                    tbl_upv_4[v39] = nil;
                end;
                local _, v45, v40 = Fetch_upv_1:Invoke();
                local v39 = {};
                local v41 = nil;
                for key_2, value_5 in pairs(Image_2) do
                    v41 = table.find(v40 or {}, v36.Name .. "/" .. key_2);
                    if (key_2 == "Default" or v41) then
                        table.insert(v39, key_2);
                    end;
                end;
                local v42 = math.max(#v39 / 8, 1);
                List_upv_2.CanvasSize = UDim2.new((v42 * 0.95) - 0.001, 0, 0, 0);
                List_upv_2.Layout.Padding = UDim.new(0.005 / v42, 0);
                List_upv_2.Layout.Template.Size = UDim2.new(0.12 / v42, 0, 0.79, 0);
                local v43 = nil;
                for v46, value_upv_6 in v39 do
                    v43 = List_upv_2.Layout.Template:Clone();
                    v43.Name = value_upv_6;
                    v43.ItemImage.Image = Image_2[value_upv_6];
                    v43.Parent = List_upv_2;
                    tbl_upv_4[value_upv_6] = ButtonClass_upv_1.new(
                        v43,
                        "BackgroundColor3",
                        function()
                            --[[
                              line: 317
                              upvalues:
                                u6 (ref,  index: 1)
                                u23 (copy, index: 2)
                                value_upv_6 (copy, index: 3)
                                u25 (copy, index: 4)
                                SettingsModule_upv_1 (copy, index: 5)
                                a1 (copy, index: 6)
                                SettingRemotes_upv_1 (copy, index: 7)
                            ]]
                            u23(value_upv_6, u25);
                            if (u6 == u6) then
                                return;
                            end;
                            SettingsModule_upv_1.SetSkinPreset(SettingsModule_upv_1.SkinPresets, a1, value_upv_6);
                            SettingRemotes_upv_1.Update:FireServer("SkinPresets", a1, value_upv_6);
                        end,
                        1.3,
                        script:GetAttribute("SelectedSlotColor")
                    );
                end;
                List_upv_2.CanvasPosition = Vector2.new((List_upv_2.AbsoluteSize.X * 0.125) * (math.max(#v39 - 8, 0) / 2), 0);
                u23(SettingsModule_upv_1.GetSkinPreset(v40, a1, v36.Name), u25, true);
            else
                Information_upv_1.ItemImage.Image = Image_2;
            end;
            Skins_upv_1.List.Visible = v37;
            Skins_upv_1.NotAvailable.Visible = not v37;
            for _, value_7 in pairs(List_upv_1:GetChildren()) do
                if (not (value_7:IsA("ImageButton"))) then
                    continue;
                end;
                if (value_7.Name ~= "Slot1") then
                    value_7:Destroy();
                end;
            end;
            local v38, _ = nil, nil;
            for key_3, value_8 in pairs(Costs_1) do
                v38 = false;
                if (key_3 == 1) then
                    v38 = List_upv_1.Slot1;
                end;
                if (not (v38)) then
                    v38 = List_upv_1.Slot1:Clone();
                    v38.Name = "Slot" .. key_3;
                    v38.Parent = List_upv_1;
                end;
                local v44 = Items_upv_1[value_8.ID];
                local ItemImage_2 = v38.ItemImage;
                local value_5 = ((type(v44.Image) == "table") and (v44.Image.Default)) or (v44.Image);
                ItemImage_2.Image = value_5;
                v38.ItemName.Text = v44.Name;
            end;
            CraftAmount_upv_1.Text = "";
            u7 = "";
            u22();
        end;
    end;
end;
local function u26(a1)
    --[[
      line: 355
      upvalues:
        u21 (ref,  index: 2)
        u2 (copy, index: 3)
        tbl_upv_1 (copy, index: 4)
        Content_upv_1 (copy, index: 5)
        Fetch_upv_1 (copy, index: 6)
        u15 (ref,  index: 7)
        tbl_upv_2 (copy, index: 8)
        u5 (ref,  index: 9)
        u24 (copy, index: 10)
    ]]
    local tbl_8 = {};
    local tbl_9 = {};
    local v45 = nil;
    local Hide_1 = nil;
    local v46 = nil;
    local v47 = nil;
    local v48 = nil;
    for _, value_9 in pairs(u2) do
        v45 = tbl_upv_1[value_9];
        Hide_1 = v45.Hide;
        for v49, value_10 in pairs(v45.Recipes) do
            if (Hide_1[value_10.ID]) then
                continue;
            end;
            v46 = true;
            for v62, value_11 in pairs(value_10.Costs) do
                if (value_11.Amount > (u21[value_11.ID] or 0)) then
                    v46 = false;
                    break;
                end;
            end;
            if (not (v46)) then
                v47 = tbl_9;
                table.insert(v47, value_10);
                continue;
            end;
            v47 = tbl_8 or tbl_9;
            table.insert(v47, value_10);
        end;
    end;
    local v50 = math.ceil(#tbl_8 / 5);
    local v51 = math.max(((math.max((v50 + math.ceil(#tbl_9 / 5)) - 1, 0) * 0.17) + 0.09) + 0.08, 1);
    Content_upv_1.CanvasSize = UDim2.new(0, 0, v51 - 0.001, 0);
    local _, value_9 = Fetch_upv_1:Invoke();
    local v49 = nil;
    for n_1 = 1, 2 do
        local v52 = n_1 == 1;
        local v53 = -1;
        local pairs_1 = pairs;
        if ((v52) and (tbl_8)) then
            v49 = tbl_8;
        else
            v49 = tbl_9;
        end;
        local v54 = nil;
        local TierNeeded_1 = nil;
        local v55 = nil;
        local v56 = nil;
        local v57 = nil;
        local v58 = nil;
        local Lock_1 = nil;
        local v59 = nil;
        v48 = nil;
        v47 = nil;
        local v60 = nil;
        for v63, value_12 in pairs_1(v49) do
            v48 = value_12.ID;
            v47 = value_12.BenchNeeded;
            v60 = (table.find(u15, v47) and (value_9[v47])) or 0;
            TierNeeded_1 = value_12.TierNeeded;
            local v61;
            v61 = tbl_upv_2[v48];
            if (not (v61)) then
                continue;
            end;
            v53 = v53 + 1;
            v55 = v61.Button;
            v57 = UDim2.new(0.195, 0, 0.16 / v51, 0);
            v61.OrigSize = v57;
            v55.Size = v57;
            v56 = (v53 % 5) * 0.2 + 0.1;
            if (v52) then
                v58 = 0;
            else
                v58 = v50;
            end;
            v55.Position = UDim2.new(v56, 0, (0.09 + (0.17 * (v58 + math.floor(v53 / 5)))) / v51, 0);
            v55.ImageTransparency = (v52 and 0) or 0.6;
            Lock_1 = v55.Lock;
            v54 = false;
            if (v47 ~= nil) then
                v54 = v60 < TierNeeded_1;
            end;
            Lock_1.Visible = v54;
            if (v48 == u5) then
                v59 = true;
            else
                v59 = false;
            end;
            v61:ToggleButton(v59, true);
            if (u5 == 0) then
                u24(v48);
            end;
        end;
        local v61;
    end;
    return u21;
end;
local function u27(a1, a2, a3)
    --[[
      line: 412
      upvalues:
        Values_upv_1 (copy, index: 1)
        u11 (ref,  index: 2)
        u19 (ref,  index: 3)
        MarketplaceService_upv_1 (copy, index: 4)
        LocalPlayer_upv_1 (copy, index: 5)
        u18 (ref,  index: 6)
        u14 (ref,  index: 7)
        u16 (ref,  index: 8)
        u1 (copy, index: 9)
        u6 (ref,  index: 10)
    ]]
    if (not Values_upv_1.CraftingEnabled.Value or tick() - u11 < 0.08) then
        return;
    end;
    if (a1 ~= nil) then
        local v62 = nil;
        if (a1 ~= 0) then
            if (u19) then
                MarketplaceService_upv_1:PromptGamePassPurchase(LocalPlayer_upv_1, u19);
            elseif (u18) then
                MarketplaceService_upv_1:PromptPurchase(LocalPlayer_upv_1, u18);
            end;
            u11 = tick();
            local v63 = math.clamp(a2, 1, 99);
            v62 = u14[u16];
            if (typeof(v62) ~= "Instance" or not (v62.Parent)) then
                v62 = "none";
            end;
            u1("Fire", "~\155\214\004a\r\195\195G\190\172\167\001g\135\018\184\235\239\181", "\001\241\134\2053\165\212a\219\016\245\199\030R\128^M\002\2194", a1, v63, u6 or "Default", v62, (a3 and 1) or 0);
        end;
    end;
end;
local function u28(a1, a2, a3)
    --[[
      line: 435
      upvalues:
        u4 (ref,  index: 1)
        tbl_upv_3 (copy, index: 2)
        Categories_upv_1 (copy, index: 3)
        TextBox_upv_1 (copy, index: 4)
        tbl_upv_2 (copy, index: 5)
        Fetch_upv_1 (copy, index: 6)
        u2 (copy, index: 7)
        tbl_upv_1 (copy, index: 8)
        Items_upv_1 (copy, index: 9)
        Content_upv_1 (copy, index: 10)
        ButtonClass_upv_1 (copy, index: 11)
        u27 (copy, index: 12)
        u24 (copy, index: 13)
        u26 (copy, index: 14)
    ]]
    if (a1 == u4 and not (a2)) then
        return;
    end;
    if (not (a2)) then
        local v64 = tbl_upv_3[Categories_upv_1[u4]];
        if (v64:IsToggled()) then
            task.defer(v64.ToggleButton, v64, false);
        end;
    end;
    if (not (a3)) then
        local v65 = tbl_upv_3[Categories_upv_1[a1]];
        if (not (v65:IsToggled())) then
            task.defer(v65.ToggleButton, v65, true);
        end;
    end;
    local v66 = TextBox_upv_1.Text ~= "";
    if (not (a3)) then
        u4 = a1;
    end;
    if (v66 and not (a3)) then
        return;
    end;
    local v67 = true;
    if (u4 ~= "All") then
        v67 = v66;
    end;
    local v68 = nil;
    for v69, v70 in pairs(tbl_upv_2) do
        v68 = v70.Button;
        if (v68.Parent) then
            v68:Destroy();
        end;
        v70:Destroy();
        tbl_upv_2[v69] = nil;
    end;
    local v71 = false;
    local _, v72 = Fetch_upv_1:Invoke();
    local v69 = pairs;
    local v70, v70;
    if (v67) then
        v70 = u2;
        if (not (v70)) then
            local tbl_10 = {};
            tbl_10[1] = ((a1 == "All") and u4) or a1;
            v70 = tbl_10;
        end;
    else
        local tbl_10 = {};
        tbl_10[1] = ((a1 == "All") and u4) or a1;
        v70 = tbl_10;
    end;
    local v73 = v71;
    local v74 = nil;
    local Hide_2 = nil;
    local v75 = nil;
    local v76 = nil;
    local ID_upv_2 = nil;
    local v77 = nil;
    local u29 = nil;
    local new_1 = nil;
    local v78 = nil;
    local v79 = nil;
    local v80 = nil;
    local v81 = nil;
    local v82 = nil;
    local v83 = nil;
    local v84 = nil;
    for v85, value_13 in v69(v70) do
        v74 = tbl_upv_1[value_13];
        Hide_2 = v74.Hide;
        v77 = nil;
        u29 = nil;
        new_1 = nil;
        v78 = nil;
        v79 = nil;
        v80 = nil;
        v81 = nil;
        for v86, value_14 in pairs(v74.Recipes) do
            ID_upv_2 = value_14.ID;
            v80 = value_14.BenchNeeded;
            v81 = value_14.TierNeeded;
            v82 = Items_upv_1[ID_upv_2];
            if (v80) then
                v75 = false;
                if ((v72[v80] or 0) < v81) then
                    v75 = not v66;
                end;
            else
                v75 = v80;
            end;
            if (v66 and not (string.find(v82.Name:lower(), TextBox_upv_1.Text:lower(), 1, true)) or v75) then
                Hide_2[ID_upv_2] = (v75 and 2) or 1;
                continue;
            end;
            Hide_2[ID_upv_2] = nil;
            v83 = v82.Image;
            v77 = Content_upv_1.Template:Clone();
            if (type(v83) ~= "table") then
                v76 = v83;
            else
                v76 = v83.Default or v83;
            end;
            v77.Image = v76;
            v77.Name = ID_upv_2;
            v77.Parent = Content_upv_1;
            v76 = value_14.GamepassNeeded or value_14.ProductNeeded;
            if (v76) then
                v77.BackgroundColor3 = Color3.fromRGB(85, 57, 95);
            end;
            u29 = nil;
            new_1 = ButtonClass_upv_1.new;
            v78 = function()
                --[[
                  line: 492
                  upvalues:
                    u29 (ref,  index: 1)
                    u27 (copy, index: 2)
                    ID_upv_2 (copy, index: 3)
                    u24 (copy, index: 4)
                ]]
                local v84 = os.clock();
                if (u29 and v84 - u29 <= 0.2) then
                    u29 = nil;
                    u27(ID_upv_2, 1, false);
                else
                    u29 = v84;
                    u24(ID_upv_2);
                end;
            end;
            if (v76) then
                v79 = Color3.fromRGB(215, 145, 241);
            else
                v79 = script:GetAttribute("SelectedSlotColor");
            end;
            tbl_upv_2[ID_upv_2] = new_1(v77, "BackgroundColor3", v78, 1.75, v79);
            v77.Visible = true;
            v73 = true;
        end;
    end;
    if (not v73) then
        return;
    end;
    u26(v67 and "All");
end;
local function u30(a1)
    --[[
      line: 123
      upvalues:
        u2 (copy, index: 1)
        tbl_upv_1 (copy, index: 2)
        Categories_upv_1 (copy, index: 3)
    ]]
    local v85 = a1 == "All";
    local v86 = 0;
    local v87 = nil;
    local Hide_3 = nil;
    for _, value_15 in pairs(u2) do
        v87 = tbl_upv_1[value_15];
        Hide_3 = v87.Hide;
        for v88, value_16 in pairs(v87.Recipes) do
            if (Hide_3[value_16.ID] ~= 2) then
                v86 = v86 + 1;
            end;
        end;
        if (not (v85)) then
            v87.AvailableCount = v86;
        end;
    end;
    Categories_upv_1[a1].Category.Text = ("%* (<font color=\"rgb(30, 158, 255)\">%*</font>)"):format(a1, v86);
end;
local function u31(a1)
    --[[
      line: 521
      upvalues:
        u21 (ref,  index: 1)
        u20 (copy, index: 2)
        u28 (copy, index: 3)
        u4 (ref,  index: 4)
        u2 (copy, index: 5)
        u30 (copy, index: 6)
        u26 (copy, index: 7)
        u22 (copy, index: 8)
        Fetch_upv_1 (copy, index: 9)
        u15 (ref,  index: 10)
        ResearchModule_upv_1 (copy, index: 11)
        CraftUpdate_upv_1 (copy, index: 12)
    ]]
    u21 = u20();
    local v88;
    v88 = nil;
    if (a1 ~= "Research") then
        v88 = u26();
    else
        u28(u4, true);
        for _, value_17 in pairs(u2) do
            u30(value_17);
        end;
        u30("All");
    end;
    u22(v88);
    local _, v89 = Fetch_upv_1:Invoke();
    local v90 = 0;
    local v91 = nil;
    local n_2 = nil;
    local v92 = nil;
    local v93 = nil;
    for v94, value_18 in pairs(u15) do
        v93 = ResearchModule_upv_1:GetInfoFromName(value_18);
        if (not (v93)) then
            continue;
        end;
        v91 = v93.Unlocks;
        v92 = 0;
        for n_2 = 1, v89[value_18] or 0 do
            v92 = v92 + #v91[n_2];
        end;
        v90 = v90 + v92;
    end;
    CraftUpdate_upv_1:Fire("UpdateRecipes", v90);
end;
local function u32()
    --[[
      line: 549
      upvalues:
        u12 (ref,  index: 1)
        Content_upv_2 (copy, index: 2)
        NumberUtil_upv_1 (copy, index: 3)
        Items_upv_1 (copy, index: 4)
        u13 (ref,  index: 5)
        Values_upv_1 (copy, index: 6)
        CraftUpdate_upv_1 (copy, index: 7)
    ]]
    local v94 = 0;
    for n_3 = #u12, 1, -1 do
        v94 = v94 + 1;
        local u33;
        u33 = Content_upv_2:FindFirstChild("Slot" .. v94);
        local u34, u35, Speed_upv_1;
        if (not (u33)) then
            continue;
        end;
        u34 = u12[n_3];
        u33.Amount.Text = "x" .. NumberUtil_upv_1:FormatNumber(u34.Amount);
        u35 = Items_upv_1[u34.ID];
        Speed_upv_1 = u34.Speed;
        if (not (Speed_upv_1)) then
            u33.Time.Text = "";
            continue;
        end;
        if (u13) then
            task.cancel(u13);
        end;
        u13 = task.spawn(
            function()
                --[[
                  line: 571
                  upvalues:
                    u33 (copy, index: 1)
                    Speed_upv_1 (copy, index: 2)
                    u34 (copy, index: 3)
                    Values_upv_1 (copy, index: 4)
                    CraftUpdate_upv_1 (copy, index: 5)
                    u35 (copy, index: 6)
                    NumberUtil_upv_1 (copy, index: 7)
                ]]
                while (u33.Parent) do
                    if (u33.Visible) then
                        local v95 = math.abs(math.clamp(math.round(Speed_upv_1 - (u34.Paused or (Values_upv_1.ServerTick.Value))), 0, 999));
                        u33.Time.Text = v95 .. "s";
                        CraftUpdate_upv_1:Fire("UpdateCraft", ("%* (x%*)"):format(u35.Name, NumberUtil_upv_1:FormatNumber(u34.Amount)), v95);
                        task.wait(0.1);
                        continue;
                    else
                        break;
                    end;
                end;
                CraftUpdate_upv_1:Fire("RemoveCraft");
            end
        );
    end;
end;
local function u36()
    --[[
      line: 585
      upvalues:
        Content_upv_2 (copy, index: 1)
        tbl_upv_5 (copy, index: 2)
        u12 (ref,  index: 3)
        Items_upv_1 (copy, index: 4)
        u11 (ref,  index: 5)
        u1 (copy, index: 6)
        u32 (copy, index: 7)
    ]]
    local v96 = nil;
    local _ = nil;
    for v103, value_19 in pairs(Content_upv_2:GetChildren()) do
        v96 = value_19:IsA("ImageButton");
        if (not (v96)) then
            continue;
        end;
        v96 = tbl_upv_5[value_19];
        if (v96) then
            for v104, value_20 in pairs(v96) do
                value_20:Disconnect();
            end;
        end;
        if (value_19.Name ~= "Slot1") then
            value_19:Destroy();
        else
            value_19.Visible = false;
            value_19.X.Visible = false;
        end;
    end;
    local v97 = 0;
    local v98 = nil;
    v98 = v97;
    local v99 = nil;
    for n_upv_4 = #u12, 1, -1 do
        local v100;
        v100 = v98 + 1;
        local v101 = u12[n_upv_4];
        local Slot1_upv_1 = false;
        if (v100 == 1) then
            Slot1_upv_1 = Content_upv_2.Slot1;
        end;
        if (not (Slot1_upv_1)) then
            Slot1_upv_1 = Content_upv_2.Slot1:Clone();
            Slot1_upv_1.Name = "Slot" .. v100;
            Slot1_upv_1.Parent = Content_upv_2;
        end;
        local v102;
        v102 = Items_upv_1[v101.ID].Image;
        if (type(v102) ~= "table") then
            v99 = v102;
            Slot1_upv_1.Image = v99;
            tbl_upv_5[Slot1_upv_1] = {
                Slot1_upv_1.MouseEnter:Connect(
                    function()
                        --[[
                          line: 616
                          upvalues:
                            Slot1_upv_1 (ref, index: 1)
                        ]]
                        Slot1_upv_1.X.Visible = true;
                    end
                ),
                Slot1_upv_1.MouseLeave:Connect(
                    function()
                        --[[
                          line: 619
                          upvalues:
                            Slot1_upv_1 (ref, index: 1)
                        ]]
                        Slot1_upv_1.X.Visible = false;
                    end
                ),
                Slot1_upv_1.Activated:Connect(
                    function()
                        --[[
                          line: 622
                          upvalues:
                            u11 (ref,  index: 1)
                            u1 (copy, index: 2)
                            n_upv_4 (copy, index: 3)
                        ]]
                        if (tick() - u11 < 0.08) then
                            return;
                        end;
                        u11 = tick();
                        u1("Fire", "~\155\214\004a\r\195\195G\190\172\167\001g\135\018\184\235\239\181", "\001\241\134\2053\165\212a\219\016\245\199\030R\128^M\002\2194", n_upv_4);
                    end
                )
            };
            Slot1_upv_1.Visible = true;
            v98 = v100;
            continue;
        end;
        v99 = v102[v101.Skin or "Default"] or v102;
        Slot1_upv_1.Image = v99;
        tbl_upv_5[Slot1_upv_1] = {
            Slot1_upv_1.MouseEnter:Connect(
                function()
                    --[[
                      line: 616
                      upvalues:
                        Slot1_upv_1 (ref, index: 1)
                    ]]
                    Slot1_upv_1.X.Visible = true;
                end
            ),
            Slot1_upv_1.MouseLeave:Connect(
                function()
                    --[[
                      line: 619
                      upvalues:
                        Slot1_upv_1 (ref, index: 1)
                    ]]
                    Slot1_upv_1.X.Visible = false;
                end
            ),
            Slot1_upv_1.Activated:Connect(
                function()
                    --[[
                      line: 622
                      upvalues:
                        u11 (ref,  index: 1)
                        u1 (copy, index: 2)
                        n_upv_4 (copy, index: 3)
                    ]]
                    if (tick() - u11 < 0.08) then
                        return;
                    end;
                    u11 = tick();
                    u1("Fire", "~\155\214\004a\r\195\195G\190\172\167\001g\135\018\184\235\239\181", "\001\241\134\2053\165\212a\219\016\245\199\030R\128^M\002\2194", n_upv_4);
                end
            )
        };
        Slot1_upv_1.Visible = true;
        v98 = v100;
    end;
    u32();
end;
CraftAmount_upv_1:GetPropertyChangedSignal("Text"):Connect(
    function()
        --[[
          line: 638
          upvalues:
            u7 (ref,  index: 1)
            CraftAmount_upv_1 (copy, index: 2)
            u22 (copy, index: 3)
        ]]
        local num_1 = tonumber(CraftAmount_upv_1.Text);
        if (num_1) then
            if (num_1 % 1 ~= 0 or num_1 <= 0) then
                if (CraftAmount_upv_1.Text ~= "") then
                    CraftAmount_upv_1.Text = u7;
                else
                    u7 = "";
                end;
            else
                local str_1 = tostring(math.min(num_1, 99));
                CraftAmount_upv_1.Text = str_1;
                u7 = str_1;
            end;
        elseif (CraftAmount_upv_1.Text ~= "") then
            CraftAmount_upv_1.Text = u7;
        else
            u7 = "";
        end;
        if (u7 == CraftAmount_upv_1.Text) then
            return;
        end;
        u22();
    end
);
CraftAmount_upv_1.FocusLost:Connect(
    function()
        --[[
          line: 654
        ]]
        shared.LastTextBoxFocused = tick();
    end
);
TextBox_upv_1:GetPropertyChangedSignal("Text"):Connect(
    function()
        --[[
          line: 658
          upvalues:
            u28 (copy, index: 1)
        ]]
        u28("All", true, true);
    end
);
TextBox_upv_1.FocusLost:Connect(
    function()
        --[[
          line: 662
        ]]
        shared.LastTextBoxFocused = tick();
    end
);
u8 = ButtonClass_upv_1.new(
    Materials_upv_1:WaitForChild("Craft"),
    "BackgroundColor3",
    function()
        --[[
          line: 666
          upvalues:
            u27 (copy, index: 1)
            u5 (ref,  index: 2)
            CraftAmount_upv_1 (copy, index: 3)
        ]]
        u27(u5, tonumber(CraftAmount_upv_1.Text) or 1, false);
    end,
    1.3,
    1.3
);
ButtonClass_upv_1.new(
    Materials_upv_1:WaitForChild("PriorityCraft"),
    "BackgroundColor3",
    function()
        --[[
          line: 669
          upvalues:
            u27 (copy, index: 1)
            u5 (ref,  index: 2)
            CraftAmount_upv_1 (copy, index: 3)
        ]]
        u27(u5, tonumber(CraftAmount_upv_1.Text) or 1, true);
    end,
    1.3,
    1.3
);
ButtonClass_upv_1.new(
    Materials_upv_1:WaitForChild("Add"),
    "BackgroundColor3",
    function()
        --[[
          line: 673
          upvalues:
            CraftAmount_upv_1 (copy, index: 1)
            u7 (ref,  index: 2)
            u22 (copy, index: 3)
        ]]
        local v103 = tonumber(CraftAmount_upv_1.Text) or 1;
        local str_2 = tostring(math.clamp(v103 + 1, 1, 99));
        CraftAmount_upv_1.Text = str_2;
        u7 = str_2;
        if (tostring(v103) == str_2) then
            return;
        end;
        u22();
    end,
    1.25,
    1.25
);
ButtonClass_upv_1.new(
    Materials_upv_1:WaitForChild("Subtract"),
    "BackgroundColor3",
    function()
        --[[
          line: 677
          upvalues:
            CraftAmount_upv_1 (copy, index: 1)
            u7 (ref,  index: 2)
            u22 (copy, index: 3)
        ]]
        local v104 = tonumber(CraftAmount_upv_1.Text) or 1;
        local str_3 = tostring(math.clamp(v104 + -1, 1, 99));
        CraftAmount_upv_1.Text = str_3;
        u7 = str_3;
        if (tostring(v104) == str_3) then
            return;
        end;
        u22();
    end,
    1.25,
    1.25
);
ButtonClass_upv_1.new(
    Materials_upv_1:WaitForChild("MaxPossible"),
    "BackgroundColor3",
    function()
        --[[
          line: 681
          upvalues:
            u21 (ref,  index: 1)
            RecipeModule_upv_1 (copy, index: 2)
            u5 (ref,  index: 3)
            CraftAmount_upv_1 (copy, index: 4)
            u7 (ref,  index: 5)
            u22 (copy, index: 6)
        ]]
        local v105 = RecipeModule_upv_1:GetRecipesForItem(u5) or {};
        local v106 = v105[1];
        if (v106) then
            local v107 = math.huge;
            for _, value_21 in pairs(v106.Costs) do
                v107 = math.min(v107, (u21[value_21.ID] or 0) / value_21.Amount);
            end;
            v107 = math.floor(v107);
            local v108 = ((v107 <= 0) and "") or (tostring(v107));
            CraftAmount_upv_1.Text = v108;
            u7 = v108;
            if (CraftAmount_upv_1.Text == v108) then
                return;
            end;
            u22(u21);
        end;
    end,
    1.25,
    1.25
);
Update_1.Event:Connect(
    function(a1)
        --[[
          line: 700
          upvalues:
            InventoryController_upv_1 (copy, index: 1)
            u31 (copy, index: 2)
            u9 (ref,  index: 3)
        ]]
        if (InventoryController_upv_1:GetAttribute("CurOpen") == "Crafting") then
            u31(a1);
        elseif (u9 == false) then
            u9 = a1 or true;
        elseif (u9 == true and type(a1) == "string") then
            u9 = a1;
        end;
    end
);
InventoryController_upv_1:GetAttributeChangedSignal("CurOpen"):Connect(
    function()
        --[[
          line: 716
          upvalues:
            InventoryController_upv_1 (copy, index: 1)
            u17 (ref,  index: 2)
            u9 (ref,  index: 3)
            u21 (ref,  index: 4)
            u20 (copy, index: 5)
            u28 (copy, index: 6)
            u4 (ref,  index: 7)
            u2 (copy, index: 8)
            u30 (copy, index: 9)
            u31 (copy, index: 10)
            u10 (ref,  index: 11)
            u36 (copy, index: 12)
        ]]
        if (InventoryController_upv_1:GetAttribute("CurOpen") ~= "Crafting") then
            return;
        end;
        if (u17) then
            u17 = nil;
            u17 = false;
            u21 = u20();
            u28(u4, true);
            for _, value_22 in pairs(u2) do
                u30(value_22);
            end;
            u30("All");
        end;
        if (u9) then
            local v109 = u9;
            u9 = false;
            u31(v109);
        end;
        if (u10) then
            u10 = false;
            u36();
        end;
    end
);
u1(
    "Setup",
    "~\155\214\004a\r\195\195G\190\172\167\001g\135\018\184\235\239\181",
    "\001\241\134\2053\165\212a\219\016\245\199\030R\128^M\002\2194",
    function(a1, a2)
        --[[
          line: 737
          upvalues:
            u12 (ref,  index: 1)
            InventoryController_upv_1 (copy, index: 2)
            u36 (copy, index: 3)
            u10 (ref,  index: 4)
            u32 (copy, index: 5)
        ]]
        u12 = a2;
        if (a1) then
            if (InventoryController_upv_1:GetAttribute("CurOpen") ~= "Crafting") then
                u10 = true;
            else
                u36();
            end;
        else
            u32();
        end;
    end
);
local v110 = nil;
local tbl_11 = nil;
for _, value_23 in pairs(u2) do
    v110 = RecipeModule_upv_1:FetchRecipeList(value_23) or {};
    tbl_11 = {};
    for v122, value_24 in pairs(v110) do
        if (not (value_24.Hidden) or Values_upv_1.ShowHiddenRecipes.Value) then
            table.insert(tbl_11, value_24);
        end;
    end;
    tbl_upv_1[value_23] = {Recipes = tbl_11, Hide = {}};
end;
local v111 = nil;
for v112, value_25 in pairs(Categories_upv_1:GetChildren()) do
    v111 = value_25:IsA("TextButton");
    if (v111) then
        local Name_upv_1 = value_25.Name;
        tbl_upv_3[value_25] = ButtonClass_upv_1.new(
            value_25,
            "TextColor3",
            function()
                --[[
                  line: 769
                  upvalues:
                    u28 (copy, index: 1)
                    Name_upv_1 (copy, index: 2)
                ]]
                u28(Name_upv_1);
            end,
            0.9,
            script:GetAttribute("CategorySelectedColor"),
            nil,
            value_25.Category
        );
    end;
end;
local v113 = OverlapParams.new();
v113.FilterType = Enum.RaycastFilterType.Include;
v113.FilterDescendantsInstances = {Bases_1};
local u37 = RaycastUtil_1:FilterFunction("View");
v1 = nil;
local v114, v115, v115 = nil, nil, nil;
while (true) do
    local u38;
    if (not (Humanoid_1.Parent) or Humanoid_1.Health <= 0) then
        break;
    end;
    local _, v116, v117, v118 = nil, nil, nil, nil;
    if (not (HumanoidRootPart_1.Parent)) then
        break;
    end;
    local v112 = HumanoidRootPart_1.Position;
    local tbl_12 = {};
    local tbl_13 = {};
    local tbl_14 = {};
    local tbl_15 = {};
    local u39 = nil;
    local Name_2 = nil;
    for v123, value_26 in pairs(workspace:GetPartBoundsInRadius(v112, 8, v113)) do
        u38 = value_26.Parent;
        if (not (u38)) then
            continue;
        end;
        u39 = u38:GetAttribute("Comfort") ~= nil;
        if (not (u39)) then
            u38 = (u3[u38.Name]) or u38.Parent;
        else
            u38 = u39;
        end;
        Name_2 = u38.Name;
        if (u39 or u3[Name_2]) then
            if (tbl_15[u38]) then
                continue;
            end;
            if (u39 or not (table.find(tbl_12, Name_2))) then
                v116 = RaycastUtil_1:Raycast(
                    v112,
                    value_26.Position - v112,
                    "Exclude",
                    {Parent_1, VFX_1, Animals_1, Plants_1, Vegetation_1},
                    false,
                    function(a1)
                        --[[
                          line: 800
                          upvalues:
                            u39 (copy, index: 1)
                            u3 (copy, index: 2)
                            u38 (ref,  index: 3)
                            u37 (copy, index: 4)
                        ]]
                        local Parent_2 = a1.Parent;
                        if (not (u39) and not (u3[Parent_2.Name])) then
                            Parent_2 = Parent_2.Parent;
                        end;
                        local v119 = u38:GetAttribute("Comfort") ~= nil;
                        if (not (v119) and not (u3[Parent_2.Name]) or Parent_2 == u38) then
                            return u37(a1);
                        end;
                        return Parent_2;
                    end,
                    true
                );
                if (not (v116)) then
                    continue;
                end;
                v117 = v116:IsDescendantOf(u38);
                if (not (v117)) then
                    continue;
                end;
                tbl_15[u38] = true;
                if (u39) then
                    table.insert(tbl_14, u38);
                else
                    table.insert(tbl_12, Name_2);
                    table.insert(tbl_13, u38);
                end;
            end;
        end;
    end;
    local v120 = false;
    if (#tbl_14 ~= #v1) then
        v114 = true;
    elseif (#tbl_14 <= 0) then
        v114 = v120;
    else
        for v124, u38 in pairs(v1) do
            v118 = table.find(tbl_14, u38);
            v114 = (v118) or true;
        end;
    end;
    if (#tbl_12 ~= #u15) then
        v115 = true;
    else
        v115 = false;
    end;
    if (#tbl_12 > 0) then
        table.sort(tbl_12);
        table.sort(
            tbl_13,
            function(a1, a2)
                --[[
                  line: 840
                ]]
                return a1.Name < a2.Name;
            end
        );
        v115 = v115 or (table.concat(tbl_12) ~= table.concat(u15));
    end;
    u14 = tbl_13;
    u15 = tbl_12;
    if (v114 or v115) then
        local v121 = table.clone(tbl_13);
        table.move(tbl_14, 1, #tbl_14, #v121 + 1, v121);
        u1("Fire", "~\155\214\004a\r\195\195G\190\172\167\001g\135\018\184\235\239\181", "\207\127.\179\253\231h\020\001\237\238L\161\235 \205\210\a\220W", unpack(v121, 1, 100));
        if (v115) then
            u31();
        end;
        task.wait(((#u14 <= 0) and 2) or 1);
        v1 = tbl_14;
    end;
    task.wait(((#u14 <= 0) and 2) or 1);
    v1 = tbl_14;
end;