-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local MarketplaceService = game:GetService("MarketplaceService");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local Values = ReplicatedStorage:WaitForChild("Values");
local Bases = workspace:WaitForChild("Bases");
local VFX = workspace:WaitForChild("VFX");
local Animals = workspace:WaitForChild("Animals");
local Plants = workspace:WaitForChild("Plants");
local Vegetation = workspace:WaitForChild("Vegetation");
local SettingRemotes = ReplicatedStorage:WaitForChild("SettingRemotes");
local NumberUtil = require(Modules:WaitForChild("NumberUtil"));
local RecipeModule = require(Modules:WaitForChild("RecipeModule"));
local ResearchModule = require(Modules:WaitForChild("ResearchModule"));
local ButtonClass = require(Modules:WaitForChild("ButtonClass"));
local Items = require(Modules:WaitForChild("Items"));
local RaycastUtil = require(Modules:WaitForChild("RaycastUtil"));
local SettingsModule = require(Modules:WaitForChild("SettingsModule"));
local u1 = require(Modules:WaitForChild("AssetContainer"))();
local LocalPlayer = Players.LocalPlayer;
local Parent = script.Parent;
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui");
local Humanoid = Parent:WaitForChild("Humanoid");
local HumanoidRootPart = Parent:WaitForChild("HumanoidRootPart");
local InventoryController = Parent:WaitForChild("InventoryController");
local StatsController = Parent:WaitForChild("StatsController");
local Update = script:WaitForChild("Update");
local Fetch = InventoryController:WaitForChild("Fetch");
local CraftUpdate = StatsController:WaitForChild("CraftUpdate");
local Crafting = PlayerGui:WaitForChild("Main"):WaitForChild("Crafting");
local Categories = Crafting:WaitForChild("Categories");
local Craftables = Crafting:WaitForChild("Craftables");
local Information = Crafting:WaitForChild("Information");
local Materials = Crafting:WaitForChild("Materials");
local Queue = Crafting:WaitForChild("Queue");
local Search = Crafting:WaitForChild("Search");
local Skins = Crafting:WaitForChild("Skins");
local Content = Craftables:WaitForChild("Content");
local Content2 = Queue:WaitForChild("Content");
local List = Materials:WaitForChild("List");
local CraftAmount = Materials:WaitForChild("CraftAmount");
local TextBox = Search:WaitForChild("TextBox");
local List2 = Skins:WaitForChild("List");
local u2 = RecipeModule:GetCraftingCategories();
local u3 = ResearchModule:FetchAllWorkbenches();
local u4 = "All";
local u5 = 0;
local u6 = "Default";
local u7 = {};
local u8 = {};
local u9 = {};
local u10 = {};
local u11 = "";
local u12 = nil;
local u13 = true;
local u14 = true;
local u15 = 0;
local u16 = {};
local u17 = {};
local u18 = nil;
local u19 = {};
local u20 = {};
local v21 = {};
local u22 = nil;
local u23 = true;
local u24 = nil;
local u25 = nil;
local u26 = {};

local function u29() -- Line: 102
    -- upvalues: Fetch (copy)
    local v27 = Fetch:Invoke() or {};
    local v28 = {};

    for i, v in pairs(v27) do
        if i == "Inventory" or i == "Toolbar" then
            for _, v2 in pairs(v) do
                if v2 and (v2 ~= 0 and v2.Amount > 0) then
                    local ID = v2.ID;
                    v28[ID] = (v28[ID] or 0) + v2.Amount;
                end;
            end;
        end;
    end;

    return v28;
end;

local u30 = u29();

local function u35(p31) -- Line: 123
    -- upvalues: u2 (copy), u7 (copy), Categories (copy)
    local v32 = p31 == "All";
    local v33 = 0;

    for _, v in pairs(v32 and u2 or { p31 }) do
        local v34 = u7[v];
        local Hide = v34.Hide;

        for _, v2 in pairs(v34.Recipes) do
            if Hide[v2.ID] ~= 2 then
                v33 = v33 + 1;
            end;
        end;

        if not v32 then
            v34.AvailableCount = v33;
        end;
    end;

    Categories[p31].Category.Text = `{p31} (<font color="rgb(30, 158, 255)">{v33}</font>)`;
end;

local function _() -- Line: 142
    -- upvalues: u2 (copy), u35 (copy)
    for _, v in pairs(u2) do
        u35(v);
    end;

    u35("All");
end;

local function u60() -- Line: 149
    -- upvalues: RecipeModule (copy), u5 (ref), Fetch (copy), u22 (ref), u20 (ref), Information (copy), u30 (ref), CraftAmount (copy), List (copy), NumberUtil (copy), u26 (copy), MarketplaceService (copy), LocalPlayer (copy), Materials (copy), u24 (ref), u25 (ref), u12 (ref), ResearchModule (copy), Values (copy)
    local v36 = (RecipeModule:GetRecipesForItem(u5) or {})[1];

    if v36 then
        local _, v37 = Fetch:Invoke();
        local BenchNeeded = v36.BenchNeeded;
        u22 = table.find(u20, BenchNeeded);
        local v38 = u22 and (v37[BenchNeeded] or 0) or 0;
        local v39 = v36.TierNeeded or 0;
        local v40;

        if BenchNeeded == nil then
            v40 = false;
        else
            v40 = v39 > 0;
        end;

        local v41 = v39 <= v38;
        Information.Required.Text = v41 and "" or "REQUIRED!";

        if v40 then
            Information.Required.Label.Text = `{BenchNeeded} - Tier: <font color="rgb(255, 248, 41)">{v39}</font>`;
        end;

        Information.Required.Visible = v40;
        local v42 = u30;
        local v43 = tonumber(CraftAmount.Text) or 1;

        for i, v in pairs(v36.Costs) do
            local v44 = v.Amount * v43;
            local v45 = v42[v.ID] or 0;
            local v46 = List["Slot" .. i];
            v46.ItemAmount.Text = "x" .. NumberUtil:FormatNumber(v44);
            v46.HasAmount.Text = "x" .. NumberUtil:FormatNumber(v45);
            local v47 = v44 <= v45;
            v46.Grey.Visible = not v47;

            if not v47 then
                v41 = false;
            end;
        end;

        local v48 = script:GetAttribute(v41 and "CanCraftColor" or "CannotCraftColor");
        local v49 = true;
        local ProductNeeded = v36.ProductNeeded;
        local GamepassNeeded = v36.GamepassNeeded;

        if ProductNeeded or GamepassNeeded then
            local v50 = ProductNeeded or GamepassNeeded;
            local v51 = u26[v50];
            local v52 = false;

            if v51 and os.clock() - v51[1] < 20 then
                v52 = v51[2];
            else
                if not v51 then
                    v51 = {};
                    u26[v50] = v51;
                end;

                v51[1] = os.clock();

                if ProductNeeded then
                    local success, result = pcall(MarketplaceService.PlayerOwnsAsset, MarketplaceService, LocalPlayer, v50);
                    v52 = success and result and true or false;
                elseif GamepassNeeded then
                    local success, result = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, LocalPlayer.UserId, v50);
                    v52 = success and result and true or false;
                end;

                v51[2] = v52;
            end;

            if not v52 then
                v48 = Color3.fromRGB(255, 225, 0);
                Materials.Craft.Text = "PURCHASE";
                Materials.Craft.Active = true;
                Materials.PriorityCraft.Visible = false;

                if ProductNeeded then
                    u24 = ProductNeeded;
                    v49 = false;
                elseif GamepassNeeded then
                    u25 = GamepassNeeded;
                    v49 = false;
                else
                    v49 = false;
                end;
            end;
        end;

        if v49 then
            u24 = nil;
            u25 = nil;
            Materials.Craft.Active = v41;
            Materials.Craft.Text = "CRAFT";
            Materials.PriorityCraft.Visible = v41;
        end;

        if u12 then
            u12:UpdateBaseColor(v48);
        end;

        Materials.Craft.BackgroundColor3 = v48;
        local v53 = 1;

        if v38 > 0 then
            local v54 = ResearchModule:GetInfoFromName(BenchNeeded);

            if v54 then
                v53 = ResearchModule:CalculateCraftTime(v38, v39, #v54.Tiers);
            end;
        end;

        local v55 = v36.Time * v43 / Values.CraftSpeedMult.Value * v53;
        local v56 = NumberUtil:FormatTime(v55, "Minutes", "Seconds", true);
        local v57 = v55 % 1;
        local v58 = v56:sub(1, 3) == "0m0" and v56:sub(4);

        if v58 then
            v56 = v58;
        elseif v56:sub(1, 2) == "0m" then
            v56 = v56:sub(3) or v56;
        end;

        if v57 > 0 and v55 < 60 then
            local v59 = tostring(NumberUtil:RoundNumber(v57, 2)):sub(2);
            v56 = v56:sub(1, #v56 - 1) .. v59 .. v56:sub(#v56);
        end;

        Materials.YieldInfo.Text = `Yields x<font color="rgb(255, 248, 43)">{NumberUtil:FormatNumber(v36.ReceiveAmount * v43)}</font> in <font color="rgb(30, 158, 255)">{v56}</font>`;

        return v42;
    end;
end;

local function u67(p61, p62, p63) -- Line: 250
    -- upvalues: u6 (ref), u10 (copy), Items (copy), Information (copy)
    if u6 == p61 then
        if not p63 then
            return;
        end;
    else
        local v64 = u10[u6];

        if v64 and v64:IsToggled() then
            task.defer(v64.ToggleButton, v64, false);
        end;
    end;

    local v65 = u10[p61];

    if v65 and not v65:IsToggled() then
        task.defer(v65.ToggleButton, v65, true, p63);
    end;

    u6 = p61;

    if not p62 then
        return;
    end;

    local Image = Items[p62.ID].Image;
    local v66 = type(Image) == "table";

    if v66 then
        Image = Image[u6] or (Image.Default or Image);
    end;

    Information.ItemImage.Image = Image;
end;

local function u81(u68) -- Line: 272
    -- upvalues: u5 (ref), u8 (copy), RecipeModule (copy), Items (copy), Information (copy), InventoryController (copy), u10 (copy), Fetch (copy), List2 (copy), ButtonClass (copy), u6 (ref), u67 (copy), SettingsModule (copy), SettingRemotes (copy), Skins (copy), List (copy), CraftAmount (copy), u11 (ref), u60 (copy)
    if u5 == u68 then
        return;
    end;

    local v69 = u8[u5];

    if v69 and v69:IsToggled() then
        task.defer(v69.ToggleButton, v69, false);
    end;

    local v70 = u8[u68];

    if v70 and not v70:IsToggled() then
        task.defer(v70.ToggleButton, v70, true);
    end;

    local u71 = (RecipeModule:GetRecipesForItem(u68) or {})[1];

    if not u71 then
        return;
    end;

    local Costs = u71.Costs;
    u5 = u68;
    local v72 = Items[u68];
    local Image = v72.Image;
    local v73 = type(Image) == "table";
    Information.ItemName.Text = v72.Name;
    Information.Description.Text = v72.Description;
    InventoryController.ItemStats:Invoke(Information.ItemStats, u68, v72);

    if v73 then
        for i, v in pairs(u10) do
            local Button = v.Button;

            if Button.Parent then
                Button:Destroy();
            end;

            v:Destroy();
            u10[i] = nil;
        end;

        local _, _, v74 = Fetch:Invoke();
        local v75 = {};

        for i, _ in pairs(Image) do
            local v76 = table.find(v74 or {}, v72.Name .. "/" .. i);

            if i == "Default" or v76 then
                table.insert(v75, i);
            end;
        end;

        local v77 = math.max(#v75 / 8, 1);
        List2.CanvasSize = UDim2.new(v77 * 0.95 - 0.001, 0, 0, 0);
        List2.Layout.Padding = UDim.new(0.005 / v77, 0);
        List2.Layout.Template.Size = UDim2.new(0.12 / v77, 0, 0.79, 0);

        for _, v in v75 do
            local v78 = List2.Layout.Template:Clone();
            v78.Name = v;
            v78.ItemImage.Image = Image[v];
            v78.Parent = List2;
            u10[v] = ButtonClass.new(v78, "BackgroundColor3", function() -- Line: 317
                -- upvalues: u6 (ref), u67 (ref), v (copy), u71 (copy), SettingsModule (ref), u68 (copy), SettingRemotes (ref)
                u67(v, u71);

                if u6 == u6 then
                    return;
                end;

                SettingsModule.SetSkinPreset(SettingsModule.SkinPresets, u68, v);
                SettingRemotes.Update:FireServer("SkinPresets", u68, v);
            end, 1.3, script:GetAttribute("SelectedSlotColor"));
        end;

        List2.CanvasPosition = Vector2.new(List2.AbsoluteSize.X * 0.125 * (math.max(#v75 - 8, 0) / 2), 0);
        u67(SettingsModule.GetSkinPreset(v74, u68, v72.Name), u71, true);
    else
        Information.ItemImage.Image = Image;
    end;

    Skins.List.Visible = v73;
    Skins.NotAvailable.Visible = not v73;

    for _, child in pairs(List:GetChildren()) do
        if child:IsA("ImageButton") and child.Name ~= "Slot1" then
            child:Destroy();
        end;
    end;

    for i, v in pairs(Costs) do
        local v79;

        if i == 1 then
            v79 = List.Slot1;
        else
            v79 = false;
        end;

        if not v79 then
            v79 = List.Slot1:Clone();
            v79.Name = "Slot" .. i;
            v79.Parent = List;
        end;

        local v80 = Items[v.ID];
        v79.ItemImage.Image = type(v80.Image) == "table" and v80.Image.Default or v80.Image;
        v79.ItemName.Text = v80.Name;
    end;

    CraftAmount.Text = "";
    u11 = "";
    u60();
end;

local function u101(p82) -- Line: 355
    -- upvalues: u4 (ref), u30 (ref), u2 (copy), u7 (copy), Content (copy), Fetch (copy), u20 (ref), u8 (copy), u5 (ref), u81 (copy)
    local v83 = p82 or u4;
    local v84 = u30;
    local v85 = {};
    local v86 = {};

    for _, v in pairs(v83 == "All" and u2 or { v83 }) do
        local v87 = u7[v];
        local Hide = v87.Hide;

        for _, v2 in pairs(v87.Recipes) do
            if not Hide[v2.ID] then
                local v88 = true;

                for _, v3 in pairs(v2.Costs) do
                    if (v84[v3.ID] or 0) < v3.Amount then
                        v88 = false;
                        break;
                    end;
                end;

                table.insert(v88 and v86 and v86 or v85, v2);
            end;
        end;
    end;

    local v89 = math.ceil(#v86 / 5);
    local v90 = v89 + math.ceil(#v85 / 5) - 1;
    local v91 = math.max(v90, 0) * 0.17 + 0.09 + 0.08;
    local v92 = math.max(v91, 1);
    Content.CanvasSize = UDim2.new(0, 0, v92 - 0.001, 0);
    local _, v93 = Fetch:Invoke();

    for i = 1, 2 do
        local v94 = i == 1;
        local v95 = -1;

        for _, v in pairs(v94 and v86 and v86 or v85) do
            local ID = v.ID;
            local BenchNeeded = v.BenchNeeded;
            local v96 = table.find(u20, BenchNeeded) and (v93[BenchNeeded] or 0) or 0;
            local TierNeeded = v.TierNeeded;
            local v97 = u8[ID];

            if v97 then
                v95 = v95 + 1;
                local Button = v97.Button;
                local v98 = UDim2.new(0.195, 0, 0.16 / v92, 0);
                v97.OrigSize = v98;
                Button.Size = v98;
                local v99 = 0.09 + 0.17 * ((v94 and 0 or v89) + math.floor(v95 / 5));
                Button.Position = UDim2.new(v95 % 5 * 0.2 + 0.1, 0, v99 / v92, 0);
                Button.ImageTransparency = v94 and 0 or 0.6;
                local v100;

                if BenchNeeded == nil then
                    v100 = false;
                else
                    v100 = v96 < TierNeeded;
                end;

                Button.Lock.Visible = v100;
                v97:ToggleButton(ID == u5, true);

                if u5 == 0 then
                    u81(ID);
                end;
            end;
        end;
    end;

    return v84;
end;

local function u107(p102, p103, p104) -- Line: 412
    -- upvalues: Values (copy), u15 (ref), u25 (ref), MarketplaceService (copy), LocalPlayer (copy), u24 (ref), u19 (ref), u22 (ref), u1 (copy), u6 (ref)
    if not Values.CraftingEnabled.Value or (tick() - u15 < 0.08 or (p102 == nil or p102 == 0)) then
        return;
    end;

    if u25 then
        MarketplaceService:PromptGamePassPurchase(LocalPlayer, u25);
    elseif u24 then
        MarketplaceService:PromptPurchase(LocalPlayer, u24);
    end;

    u15 = tick();
    local v105 = math.clamp(p103, 1, 99);
    local v106 = u19[u22];
    u1("Fire", "~\155\214\4a\r\195\195G\190\172\167\1g\135\18\184\235\239\181", "\1\241\134\2053\165\212a\219\16\245\199\30R\128^M\2\2194", p102, v105, u6 or "Default", (typeof(v106) ~= "Instance" or not v106.Parent) and "none" or v106, p104 and 1 or 0);
end;

local function u127(p108, p109, p110) -- Line: 435
    -- upvalues: u4 (ref), u9 (copy), Categories (copy), TextBox (copy), u8 (copy), Fetch (copy), u2 (copy), u7 (copy), Items (copy), Content (copy), ButtonClass (copy), u107 (copy), u81 (copy), u101 (copy)
    if p108 == u4 and not p109 then
        return;
    end;

    if not p109 then
        local v111 = u9[Categories[u4]];

        if v111:IsToggled() then
            task.defer(v111.ToggleButton, v111, false);
        end;
    end;

    if not p110 then
        local v112 = u9[Categories[p108]];

        if not v112:IsToggled() then
            task.defer(v112.ToggleButton, v112, true);
        end;
    end;

    local v113 = TextBox.Text ~= "";

    if not p110 then
        u4 = p108;
    end;

    if v113 and not p110 then
        return;
    end;

    local v114 = u4 == "All" and true or v113;

    for i, v in pairs(u8) do
        local Button = v.Button;

        if Button.Parent then
            Button:Destroy();
        end;

        v:Destroy();
        u8[i] = nil;
    end;

    local v115 = false;
    local _, v116 = Fetch:Invoke();
    local v117 = v114 and u2;

    if not v117 then
        v117 = {};

        if p108 == "All" then
            p108 = u4 or p108;
        end;

        v117[1] = p108;
    end;

    for _, v in pairs(v117) do
        local v118 = u7[v];
        local Hide = v118.Hide;

        for _, v2 in pairs(v118.Recipes) do
            local ID = v2.ID;
            local BenchNeeded = v2.BenchNeeded;
            local v119 = v116[BenchNeeded] or 0;
            local TierNeeded = v2.TierNeeded;
            local v120 = Items[ID];

            if BenchNeeded then
                if v119 < TierNeeded then
                    BenchNeeded = not v113;
                else
                    BenchNeeded = false;
                end;
            end;

            if v113 and not string.find(v120.Name:lower(), TextBox.Text:lower(), 1, true) or BenchNeeded then
                Hide[ID] = BenchNeeded and 2 or 1;
            else
                Hide[ID] = nil;
                local Image = v120.Image;
                local v121 = Content.Template:Clone();

                if type(Image) == "table" then
                    Image = Image.Default or Image;
                end;

                v121.Image = Image;
                v121.Name = ID;
                v121.Parent = Content;
                local v122 = (v2.GamepassNeeded or v2.ProductNeeded) and true or false;

                if v122 then
                    v121.BackgroundColor3 = Color3.fromRGB(85, 57, 95);
                end;

                local u123 = nil;
                local new = ButtonClass.new;

                local function v125() -- Line: 492
                    -- upvalues: u123 (ref), u107 (ref), ID (copy), u81 (ref)
                    local v124 = os.clock();

                    if u123 and v124 - u123 <= 0.2 then
                        u123 = nil;
                        u107(ID, 1, false);

                        return;
                    end;

                    u123 = v124;
                    u81(ID);
                end;

                local v126;

                if v122 then
                    v126 = Color3.fromRGB(215, 145, 241);
                else
                    v126 = script:GetAttribute("SelectedSlotColor");
                end;

                u8[ID] = new(v121, "BackgroundColor3", v125, 1.75, v126);
                v121.Visible = true;
                v115 = true;
            end;
        end;
    end;

    if not v115 then
        return;
    end;

    u101(v114 and "All");
end;

local function _(p128) -- Line: 512
    -- upvalues: CraftAmount (copy), u11 (ref), u60 (copy)
    local v129 = tonumber(CraftAmount.Text) or 1;
    local v130 = math.clamp(v129 + p128, 1, 99);
    local v131 = tostring(v130);
    CraftAmount.Text = v131;
    u11 = v131;

    if tostring(v129) == v131 then
        return;
    end;

    u60();
end;

local function u138(p132) -- Line: 521
    -- upvalues: u30 (ref), u29 (copy), u127 (copy), u4 (ref), u2 (copy), u35 (copy), u101 (copy), u60 (copy), Fetch (copy), u20 (ref), ResearchModule (copy), CraftUpdate (copy)
    u30 = u29();
    local v133 = nil;

    if p132 == "Research" then
        u127(u4, true);

        for _, v in pairs(u2) do
            u35(v);
        end;

        u35("All");
    else
        v133 = u101();
    end;

    u60(v133);
    local _, v134 = Fetch:Invoke();
    local v135 = 0;

    for _, v in pairs(u20) do
        local v136 = ResearchModule:GetInfoFromName(v);

        if v136 then
            local Unlocks = v136.Unlocks;
            local v137 = 0;

            for i = 1, v134[v] or 0 do
                v137 = v137 + #Unlocks[i];
            end;

            v135 = v135 + v137;
        end;
    end;

    CraftUpdate:Fire("UpdateRecipes", v135);
end;

local function u146() -- Line: 549
    -- upvalues: u16 (ref), Content2 (copy), NumberUtil (copy), Items (copy), u18 (ref), Values (copy), CraftUpdate (copy)
    local v139 = 0;

    for i = #u16, 1, -1 do
        v139 = v139 + 1;
        local u140 = Content2:FindFirstChild("Slot" .. v139);

        if u140 then
            local u141 = u16[i];
            u140.Amount.Text = "x" .. NumberUtil:FormatNumber(u141.Amount);
            local u142 = Items[u141.ID];
            local Speed = u141.Speed;

            if Speed then
                if u18 then
                    task.cancel(u18);
                end;

                u18 = task.spawn(function() -- Line: 571
                    -- upvalues: u140 (copy), Speed (copy), u141 (copy), Values (ref), CraftUpdate (ref), u142 (copy), NumberUtil (ref)
                    while u140.Parent and u140.Visible do
                        local v143 = math.round(Speed - (u141.Paused or Values.ServerTick.Value));
                        local v144 = math.clamp(v143, 0, 999);
                        local v145 = math.abs(v144);
                        u140.Time.Text = v145 .. "s";
                        CraftUpdate:Fire("UpdateCraft", `{u142.Name} (x{NumberUtil:FormatNumber(u141.Amount)})`, v145);
                        task.wait(0.1);
                    end;

                    CraftUpdate:Fire("RemoveCraft");
                end);
            else
                u140.Time.Text = "";
            end;
        end;
    end;
end;

local function u151() -- Line: 585
    -- upvalues: Content2 (copy), u17 (copy), u16 (ref), Items (copy), u15 (ref), u1 (copy), u146 (copy)
    for _, child in pairs(Content2:GetChildren()) do
        if child:IsA("ImageButton") then
            local v147 = u17[child];

            if v147 then
                for _, v in pairs(v147) do
                    v:Disconnect();
                end;
            end;

            if child.Name == "Slot1" then
                child.Visible = false;
                child.X.Visible = false;
            else
                child:Destroy();
            end;
        end;
    end;

    local v148 = 0;

    for i = #u16, 1, -1 do
        v148 = v148 + 1;
        local v149 = u16[i];
        local u150;

        if v148 == 1 then
            u150 = Content2.Slot1;
        else
            u150 = false;
        end;

        if not u150 then
            u150 = Content2.Slot1:Clone();
            u150.Name = "Slot" .. v148;
            u150.Parent = Content2;
        end;

        local Image = Items[v149.ID].Image;

        if type(Image) == "table" then
            Image = Image[v149.Skin or "Default"] or Image;
        end;

        u150.Image = Image;
        u17[u150] = { u150.MouseEnter:Connect(function() -- Line: 616
                -- upvalues: u150 (ref)
                u150.X.Visible = true;
            end), u150.MouseLeave:Connect(function() -- Line: 619
                -- upvalues: u150 (ref)
                u150.X.Visible = false;
            end), u150.Activated:Connect(function() -- Line: 622
                -- upvalues: u15 (ref), u1 (ref), i (copy)
                if tick() - u15 < 0.08 then
                    return;
                end;

                u15 = tick();
                u1("Fire", "~\155\214\4a\r\195\195G\190\172\167\1g\135\18\184\235\239\181", "\1\241\134\2053\165\212a\219\16\245\199\30R\128^M\2\2194", i);
            end) };
        u150.Visible = true;
    end;

    u146();
end;

CraftAmount:GetPropertyChangedSignal("Text"):Connect(function() -- Line: 638
    -- upvalues: u11 (ref), CraftAmount (copy), u60 (copy)
    local v152 = u11;
    local v153 = tonumber(CraftAmount.Text);

    if v153 and (v153 % 1 == 0 and v153 > 0) then
        local v154 = math.min(v153, 99);
        local v155 = tostring(v154);
        CraftAmount.Text = v155;
        u11 = v155;
    elseif CraftAmount.Text == "" then
        u11 = "";
    else
        CraftAmount.Text = u11;
    end;

    if v152 == CraftAmount.Text then
        return;
    end;

    u60();
end);
CraftAmount.FocusLost:Connect(function() -- Line: 654
    shared.LastTextBoxFocused = tick();
end);
TextBox:GetPropertyChangedSignal("Text"):Connect(function() -- Line: 658
    -- upvalues: u127 (copy)
    u127("All", true, true);
end);
TextBox.FocusLost:Connect(function() -- Line: 662
    shared.LastTextBoxFocused = tick();
end);
u12 = ButtonClass.new(Materials:WaitForChild("Craft"), "BackgroundColor3", function() -- Line: 666
    -- upvalues: u107 (copy), u5 (ref), CraftAmount (copy)
    u107(u5, tonumber(CraftAmount.Text) or 1, false);
end, 1.3, 1.3);
ButtonClass.new(Materials:WaitForChild("PriorityCraft"), "BackgroundColor3", function() -- Line: 669
    -- upvalues: u107 (copy), u5 (ref), CraftAmount (copy)
    u107(u5, tonumber(CraftAmount.Text) or 1, true);
end, 1.3, 1.3);
ButtonClass.new(Materials:WaitForChild("Add"), "BackgroundColor3", function() -- Line: 673
    -- upvalues: CraftAmount (copy), u11 (ref), u60 (copy)
    local v156 = tonumber(CraftAmount.Text) or 1;
    local v157 = math.clamp(v156 + 1, 1, 99);
    local v158 = tostring(v157);
    CraftAmount.Text = v158;
    u11 = v158;

    if tostring(v156) == v158 then
        return;
    end;

    u60();
end, 1.25, 1.25);
ButtonClass.new(Materials:WaitForChild("Subtract"), "BackgroundColor3", function() -- Line: 677
    -- upvalues: CraftAmount (copy), u11 (ref), u60 (copy)
    local v159 = tonumber(CraftAmount.Text) or 1;
    local v160 = math.clamp(v159 + -1, 1, 99);
    local v161 = tostring(v160);
    CraftAmount.Text = v161;
    u11 = v161;

    if tostring(v159) == v161 then
        return;
    end;

    u60();
end, 1.25, 1.25);
ButtonClass.new(Materials:WaitForChild("MaxPossible"), "BackgroundColor3", function() -- Line: 681
    -- upvalues: u30 (ref), RecipeModule (copy), u5 (ref), CraftAmount (copy), u11 (ref), u60 (copy)
    local v162 = u30;
    local v163 = (RecipeModule:GetRecipesForItem(u5) or {})[1];

    if not v163 then
        return;
    end;

    local v164 = (1 / 0);

    for _, v in pairs(v163.Costs) do
        v164 = math.min(v164, (v162[v.ID] or 0) / v.Amount);
    end;

    local v165 = math.floor(v164);
    local v166 = v165 <= 0 and "" or tostring(v165);
    local Text = CraftAmount.Text;
    CraftAmount.Text = v166;
    u11 = v166;

    if Text == v166 then
        return;
    end;

    u60(v162);
end, 1.25, 1.25);
Update.Event:Connect(function(p167) -- Line: 700
    -- upvalues: InventoryController (copy), u138 (copy), u13 (ref)
    if InventoryController:GetAttribute("CurOpen") == "Crafting" then
        u138(p167);

        return;
    end;

    if u13 == false then
        u13 = p167 or true;

        return;
    end;

    if u13 == true and type(p167) == "string" then
        u13 = p167;
    end;
end);
InventoryController:GetAttributeChangedSignal("CurOpen"):Connect(function() -- Line: 716
    -- upvalues: InventoryController (copy), u23 (ref), u13 (ref), u30 (ref), u29 (copy), u127 (copy), u4 (ref), u2 (copy), u35 (copy), u138 (copy), u14 (ref), u151 (copy)
    if InventoryController:GetAttribute("CurOpen") ~= "Crafting" then
        return;
    end;

    if u23 then
        u23 = nil;
        u13 = false;
        u30 = u29();
        u127(u4, true);

        for _, v in pairs(u2) do
            u35(v);
        end;

        u35("All");
    end;

    if u13 then
        local v168 = u13;
        u13 = false;
        u138(v168);
    end;

    if u14 then
        u14 = false;
        u151();
    end;
end);
u1("Setup", "~\155\214\4a\r\195\195G\190\172\167\1g\135\18\184\235\239\181", "\1\241\134\2053\165\212a\219\16\245\199\30R\128^M\2\2194", function(p169, p170) -- Line: 737
    -- upvalues: u16 (ref), InventoryController (copy), u151 (copy), u14 (ref), u146 (copy)
    u16 = p170;

    if not p169 then
        u146();

        return;
    end;

    if InventoryController:GetAttribute("CurOpen") == "Crafting" then
        u151();

        return;
    end;

    u14 = true;
end);

for _, v in pairs(u2) do
    local v171 = RecipeModule:FetchRecipeList(v) or {};
    local v172 = {};

    for _, v2 in pairs(v171) do
        if not v2.Hidden or Values.ShowHiddenRecipes.Value then
            table.insert(v172, v2);
        end;
    end;

    u7[v] = {
        AvailableCount = 0,
        Recipes = v172,
        Hide = {}
    };
end;

for _, child in pairs(Categories:GetChildren()) do
    if child:IsA("TextButton") then
        local Name = child.Name;
        u9[child] = ButtonClass.new(child, "TextColor3", function() -- Line: 769
            -- upvalues: u127 (copy), Name (copy)
            u127(Name);
        end, 0.9, script:GetAttribute("CategorySelectedColor"), nil, child.Category);
    end;
end;

local function _(p173) -- Line: 774
    return p173:GetAttribute("Comfort") ~= nil;
end;

local v174 = OverlapParams.new();
v174.FilterType = Enum.RaycastFilterType.Include;
v174.FilterDescendantsInstances = { Bases };
local u175 = RaycastUtil:FilterFunction("View");

while true do
    if not Humanoid.Parent or (Humanoid.Health <= 0 or not HumanoidRootPart.Parent) then
        return;
    end;

    local Position = HumanoidRootPart.Position;
    local v176 = workspace:GetPartBoundsInRadius(Position, 8, v174);
    local v177 = {};
    local v178 = {};
    local v179 = {};
    local v180 = {};

    for _, v in pairs(v176) do
        local Parent2 = v.Parent;

        if Parent2 then
            local u181 = Parent2:GetAttribute("Comfort") ~= nil;

            if not (u181 or u3[Parent2.Name]) then
                Parent2 = Parent2.Parent;
            end;

            local Name = Parent2.Name;

            if (u181 or u3[Name]) and not v180[Parent2] then
                if u181 or not table.find(v177, Name) then
                    local v183 = RaycastUtil:Raycast(Position, v.Position - Position, "Exclude", {
                        Parent,
                        VFX,
                        Animals,
                        Plants,
                        Vegetation
                    }, false, function(p182) -- Line: 800
                        -- upvalues: u181 (copy), u3 (copy), Parent2 (ref), u175 (copy)
                        local Parent3 = p182.Parent;

                        if not (u181 or u3[Parent3.Name]) then
                            Parent3 = Parent3.Parent;
                        end;

                        if (Parent2:GetAttribute("Comfort") ~= nil or u3[Parent3.Name]) and Parent3 ~= Parent2 then
                            return Parent3;
                        end;

                        return u175(p182);
                    end, true);

                    if v183 and v183:IsDescendantOf(Parent2) then
                        v180[Parent2] = true;

                        if u181 then
                            table.insert(v179, Parent2);
                        else
                            table.insert(v177, Name);
                            table.insert(v178, Parent2);
                        end;
                    end;
                end;
            end;
        end;
    end;

    local v184 = false;

    if #v179 == #v21 then
        if #v179 > 0 then
            for _, v in pairs(v21) do
                if not table.find(v179, v) then
                    v184 = true;
                    break;
                end;
            end;
        end;
    else
        v184 = true;
    end;

    local v185 = #v177 ~= #u20;

    if #v177 > 0 then
        table.sort(v177);
        table.sort(v178, function(p186, p187) -- Line: 840
            return p186.Name < p187.Name;
        end);
        v185 = v185 or table.concat(v177) ~= table.concat(u20);
    end;

    u19 = v178;
    u20 = v177;

    if v184 or v185 then
        local v188 = table.clone(v178);
        table.move(v179, 1, #v179, #v188 + 1, v188);
        u1("Fire", "~\155\214\4a\r\195\195G\190\172\167\1g\135\18\184\235\239\181", "\207\127.\179\253\231h\20\1\237\238L\161\235 \205\210\7\220W", unpack(v188, 1, 100));

        if v185 then
            u138();
        end;
    end;

    task.wait(#u19 > 0 and 1 or 2);
    v21 = v179;
end;