-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local UserInputService = game:GetService("UserInputService");
local TweenService = game:GetService("TweenService");
local SoundService = game:GetService("SoundService");
local LocalPlayer = Players.LocalPlayer;
local Character = LocalPlayer.Character;
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart");
local RootRigAttachment = HumanoidRootPart:WaitForChild("RootRigAttachment");
local Bases = workspace:WaitForChild("Bases");
local Value = ReplicatedStorage:WaitForChild("Values"):WaitForChild("ElectricBenchClientUpdateSeconds").Value;
local ClientSignals = ReplicatedStorage:WaitForChild("ClientSignals");
local UpdateBenchConnections = ClientSignals:WaitForChild("UpdateBenchConnections");
local UpdateBenchPower = ClientSignals:WaitForChild("UpdateBenchPower");
local TemplateWire = script:WaitForChild("TemplateWire");
local VFX = workspace:WaitForChild("VFX");
local Wires = VFX:WaitForChild("Wires");
local WireCutters = SoundService:WaitForChild("WireCutters");
local u1 = {
    Green = ColorSequence.new(Color3.fromRGB(63, 194, 46)),
    Red = ColorSequence.new(Color3.fromRGB(194, 40, 50)),
    Black = ColorSequence.new(Color3.fromRGB(40, 40, 40))
};
local Modules = ReplicatedStorage:WaitForChild("Modules");
local Items = require(Modules:WaitForChild("Items"));
local BenchInfo = require(Modules:WaitForChild("BenchInfo"));
local NumberUtil = require(Modules:WaitForChild("NumberUtil"));
local RaycastUtil = require(Modules:WaitForChild("RaycastUtil"));
local ActiveBenchModule = require(Modules:WaitForChild("ActiveBenchModule"));
local ViewmodelController = Character:WaitForChild("ViewmodelController");
local u2 = require(Modules:WaitForChild("AssetContainer"))();
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui");
local WireCutterInfo = PlayerGui:WaitForChild("Main"):WaitForChild("WireCutterInfo");
local ConnectionsBillboardGui = PlayerGui:WaitForChild("ConnectionsBillboardGui");
local ButtonFrame = ConnectionsBillboardGui:WaitForChild("ButtonFrame");
local OpenBench = script:WaitForChild("OpenBench");
local EquipWires = script:WaitForChild("EquipWires");
local PlayVMAnimation = ViewmodelController:WaitForChild("PlayVMAnimation");
local u3 = os.clock() - Value;
shared.CachedElectricalBenchNames = {};
shared.CachedConnections = {};
local u4 = nil;
local u5 = nil;
local u6 = {};
local u7 = {};
local u8 = {};
local u9 = nil;
local u10 = nil;
local u11 = nil;
local u12 = nil;

for i, v in BenchInfo do
    local v13 = v.TypeArguments and v.TypeArguments();

    if v.Type == "Electricity" or (v.ElectricityType or v13 and v13.PowerIn ~= nil) then
        shared.CachedElectricalBenchNames[i] = true;
    end;
end;

local function u18(p14, p15) -- Line: 131
    -- upvalues: TemplateWire (copy), Wires (copy)
    local v16 = {};

    for i, v in p15 do
        if v == 0 then
            v16[i] = 0;
        elseif p14.Main and v.Main then
            if not p14.Main:FindFirstChild("WireAttachment") then
                local Attachment = Instance.new("Attachment");
                Attachment.Name = "WireAttachment";
                Attachment.Parent = p14.Main;
            end;

            if not v.Main:FindFirstChild("WireAttachment") then
                local Attachment = Instance.new("Attachment");
                Attachment.Name = "WireAttachment";
                Attachment.Parent = v.Main;
            end;

            local v17 = TemplateWire:Clone();
            v16[i] = v17;
            v17.Attachment0 = p14.Main.WireAttachment;
            v17.Attachment1 = v.Main.WireAttachment;
            v17.Enabled = script:GetAttribute("WiresEquipped");
            local WireDetail = v17:FindFirstChild("WireDetail");
            WireDetail.Attachment0 = p14.Main.WireAttachment;
            WireDetail.Attachment1 = v.Main.WireAttachment;
            WireDetail.Enabled = true;
            v17.Parent = Wires;
        else
            v16[i] = 0;
        end;
    end;

    return v16;
end;

local function u20(p19) -- Line: 175
    -- upvalues: Wires (copy)
    for _, child in Wires:GetChildren() do
        child.Enabled = p19;

        if child:FindFirstChild("WireDetail") then
            child.WireDetail.Enabled = p19;
        end;
    end;
end;

local function _() -- Line: 184
    -- upvalues: u4 (ref), u12 (ref)
    u4 = nil;
    u12 = nil;
    script:SetAttribute("Placing", false);
end;

local function u25(p21) -- Line: 190
    -- upvalues: Items (copy), WireCutterInfo (copy)
    local v22;

    if p21 then
        v22 = p21:GetAttribute("ID");
    else
        v22 = p21;
    end;

    local v23;

    if p21 then
        v23 = p21:GetAttribute("Skin");
    else
        v23 = p21;
    end;

    if v22 then
        v22 = Items[v22];
    end;

    if v22 then
        v22 = v22.Image[v23 or "Default"];
    end;

    local v24 = v22 ~= nil;
    WireCutterInfo.TopLabel.Text = v24 and "CREATING NEW CONNECTION FROM" or "[MOUSE1] ON ELECTRICITY BENCH TO SHOW CONNECTIONS";
    WireCutterInfo.ImageLabel.Image = v22 or "";
    WireCutterInfo.ImageLabel.Visible = v24;
    WireCutterInfo.ItemLabel.Text = p21 and p21.Name or "";
    WireCutterInfo.ItemLabel.Visible = v24;
    WireCutterInfo.BottomLabel.Visible = v24;
    WireCutterInfo.Visible = true;
end;

local function u26() -- Line: 205
    -- upvalues: Character (copy), HumanoidRootPart (copy), u6 (ref), Bases (copy), NumberUtil (copy)
    if not (Character and HumanoidRootPart) then
        return;
    end;

    u6 = {};

    for _, child in pairs(Bases:GetChildren()) do
        for _, child2 in child:GetChildren() do
            if shared.CachedElectricalBenchNames[child2.Name] then
                for _, child3 in pairs(child2:GetChildren()) do
                    if child3.Main and (child3.Main.Position and NumberUtil:IsWithin(child3.Main.Position, HumanoidRootPart.Position, 70)) then
                        table.insert(u6, child3);
                    end;
                end;
            end;
        end;
    end;
end;

local function u30(p27) -- Line: 224
    -- upvalues: WireCutterInfo (copy), TweenService (copy)
    local v28 = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0);
    local v29 = WireCutterInfo.Message:Clone();
    v29.Parent = WireCutterInfo;
    v29.Text = p27;
    TweenService:Create(v29, v28, {
        TextTransparency = 0.3
    }):Play();
    task.wait(4);
    v29:Destroy();
end;

local function _() -- Line: 238
    -- upvalues: u10 (ref), u3 (ref), Value (copy), u26 (copy), u6 (ref), u2 (copy), u18 (copy), Wires (copy)
    if u10 then
        task.cancel(u10);
    end;

    u10 = task.defer(function() -- Line: 240
        -- upvalues: u3 (ref), Value (ref), u26 (ref), u6 (ref), u2 (ref), u18 (ref), Wires (ref)
        while true do
            while true do
                repeat
                    task.wait(0.25);
                until os.clock() - u3 > Value;

                u3 = os.clock();
                u26();

                if #u6 ~= 0 then
                    break;
                end;

                shared.CachedConnections = {};
            end;

            local v31 = {};
            local v32 = {};

            for _, v in u2("Fire", "\16\168\31#\163\1W\225^\130b\156a\179\208\211\23\185\2266", "<\18\187]\5X\199\20\25\224V\147\5\147\1:\230D!\247", unpack(u6, 1, 300)) do
                local v33 = v[1];
                v31[v33] = {
                    PowerIn = v[2],
                    PowerOut = v[3]
                };
                local v34 = shared.CachedConnections[v33];

                if v34 and (v34.Wires and v34.PowerOut) then
                    local v35 = true;

                    if v34.PowerOut then
                        for i, v2 in v34.PowerOut do
                            if v31[v33].PowerOut[i] ~= v2 then
                                v35 = false;
                            end;
                        end;
                    end;

                    if v35 and v34.Wires then
                        v31[v33].Wires = v34.Wires;
                    else
                        v31[v33].Wires = u18(v33, v31[v33].PowerOut);
                    end;
                elseif v31[v33].PowerOut then
                    v31[v33].Wires = u18(v33, v31[v33].PowerOut);
                end;

                if v31[v33].Wires then
                    for _, v2 in v31[v33].Wires do
                        if v2 ~= 0 then
                            v32[v2] = true;
                        end;
                    end;
                end;
            end;

            shared.CachedConnections = v31;

            for _, child in Wires:GetChildren() do
                if not v32[child] then
                    child:Destroy();
                end;
            end;
        end;
    end);
end;

local function u36() -- Line: 318
    -- upvalues: u8 (ref)
    for _, v in pairs(u8) do
        v:Disconnect();
    end;

    u8 = {};
end;

local function u60() -- Line: 325
    -- upvalues: u8 (ref), u5 (ref), u11 (ref), u1 (copy), u4 (ref), u12 (ref), u2 (copy), u25 (copy), u36 (copy), ButtonFrame (copy), Items (copy)
    local function v50(u37) -- Line: 326
        -- upvalues: u8 (ref), u5 (ref), u11 (ref), u1 (ref), u4 (ref), u12 (ref), u2 (ref), u25 (ref)
        table.insert(u8, u37.MouseEnter:Connect(function() -- Line: 328
            -- upvalues: u37 (copy), u5 (ref), u11 (ref), u1 (ref)
            u37:FindFirstChild("Hover").Enabled = true;
            local v38 = u37.Name:find("In");
            local v39 = string.sub(u37.Name, -1);
            local v40 = tonumber(v39);
            local v41 = shared.CachedConnections[u5];

            if not v41 or v38 and not v41.PowerIn or not (v38 or v41.PowerOut) then
                return;
            end;

            if v38 then
                local v42 = v41.PowerIn[v40];

                if v42 ~= 0 then
                    local v43 = shared.CachedConnections[v42];

                    if not v43 then
                        return;
                    end;

                    local v44 = nil;

                    for i, v in v43.PowerOut do
                        if v == u5 then
                            v44 = i;
                            break;
                        end;
                    end;

                    if not v44 then
                        return;
                    end;

                    local v45 = v43.Wires and v43.Wires[v44];

                    if not v45 or v45 == 0 then
                        return;
                    end;

                    u11 = v45;
                    u11.Color = u1.Red;
                end;
            else
                local v46 = v41.Wires and v41.Wires[v40];

                if not v46 or v46 == 0 then
                    return;
                end;

                u11 = v46;
                u11.Color = u1.Green;
            end;
        end));
        table.insert(u8, u37.MouseLeave:Connect(function() -- Line: 362
            -- upvalues: u37 (copy), u11 (ref), u1 (ref)
            u37:FindFirstChild("Hover").Enabled = false;

            if u11 then
                u11.Color = u1.Black;
                u11 = nil;
            end;
        end));
        table.insert(u8, u37.MouseButton1Click:Connect(function() -- Line: 371
            -- upvalues: u4 (ref), u37 (copy), u12 (ref), u5 (ref), u2 (ref), u25 (ref)
            local v47 = string.sub(u37.Name, -1);
            u4 = tonumber(v47);
            local v48 = string.sub(u37.Name, 1, -2);
            u12 = v48;
            local v49 = shared.CachedConnections[u5];

            if not v49 or (not v49[v48] or v49[v48][u4] == 0) then
                script:SetAttribute("Placing", true);
                u25(u5);

                return;
            end;

            u2("Fire", "\16\168\31#\163\1W\225^\130b\156a\179\208\211\23\185\2266", "\142H\187\n}UX\242}\152O[\161\206\30\154\1\139\243D", u5, v49[v48][u4], u4, u12, true);
            u4 = nil;
            u12 = nil;
            script:SetAttribute("Placing", false);
        end));
    end;

    u36();

    for _, child in ButtonFrame:GetChildren() do
        for _, child2 in child:GetChildren() do
            if child2:IsA("ImageButton") and shared.CachedConnections[u5] then
                local v51 = child2.Name:find("PowerIn") and "PowerIn" or "PowerOut";
                local v52 = string.sub(child2.Name, -1);
                local v53 = tonumber(v52);
                local v54 = shared.CachedConnections[u5][v51];

                if v54 and (not v54 or (v54 and #v54 or v54) >= v53) then
                    child2.Visible = true;

                    if v54[v53] ~= 0 then
                        local v55 = v54[v53];
                        local v56 = v55:GetAttribute("ID");
                        local v57 = v55:GetAttribute("Skin");

                        if v56 then
                            v56 = Items[v56];
                        end;

                        local v58;

                        if v56 then
                            v58 = v56.Image[v57 or "Default"];
                        else
                            v58 = v56;
                        end;

                        local v59 = v58 or v56.Image;

                        if not v59 then
                            warn("[ElectricityController] - Image not found for connection slot, bench found name : " .. v55.Name);
                        end;

                        child2.ImageLabel.Image = v59;
                    end;

                    child2.ImageLabel.Visible = v54[v53] ~= 0;
                    child2.TextLabel.Visible = v54[v53] == 0;
                    v50(child2);
                else
                    child2.Visible = false;
                end;
            end;
        end;
    end;
end;

local function _() -- Line: 438
    -- upvalues: u5 (ref), ConnectionsBillboardGui (copy), u60 (copy)
    if not u5 then
        return nil;
    end;

    ConnectionsBillboardGui.Adornee = u5:FindFirstChild("Main");
    u60();
end;

OpenBench.Event:Connect(function(p61) -- Line: 447
    -- upvalues: u5 (ref), HumanoidRootPart (copy), RaycastUtil (copy), ActiveBenchModule (copy), u30 (copy), u4 (ref), NumberUtil (copy), u2 (copy), u12 (ref), ConnectionsBillboardGui (copy), u25 (copy), u60 (copy)
    if not p61.Main then
        return;
    end;

    if u5 == p61 then
        return;
    end;

    if not HumanoidRootPart then
        return;
    end;

    local v62 = RaycastUtil:GetBaseCabinetUnder(HumanoidRootPart.Position);
    local v63;

    if v62 then
        local v64 = ActiveBenchModule.GetClientInfo(v62);

        if type(v64) == "table" then
            v63 = not v64.Access;
        else
            v63 = false;
        end;
    else
        v63 = false;
    end;

    if v63 then
        u30("You are building blocked");

        return;
    end;

    if not (u5 and u4) then
        u5 = p61;

        if not u5 then
            return;
        end;

        ConnectionsBillboardGui.Adornee = u5:FindFirstChild("Main");
        u60();

        return;
    end;

    if not NumberUtil:IsWithin(HumanoidRootPart.Position, p61.Main.Position, 40) then
        return;
    end;

    u2("Fire", "\16\168\31#\163\1W\225^\130b\156a\179\208\211\23\185\2266", "\142H\187\n}UX\242}\152O[\161\206\30\154\1\139\243D", u5, p61, u4, u12);
    ConnectionsBillboardGui.Adornee = nil;
    u5 = nil;
    u4 = nil;
    u12 = nil;
    script:SetAttribute("Placing", false);
    u25();
end);
EquipWires.Event:Connect(function(p65) -- Line: 473
    -- upvalues: u25 (copy), u10 (ref), u3 (ref), Value (copy), u26 (copy), u6 (ref), u2 (copy), u18 (copy), Wires (copy), WireCutterInfo (copy), ConnectionsBillboardGui (copy), u5 (ref), u4 (ref)
    if p65 and not script:GetAttribute("WiresEquipped") then
        u25();

        if u10 then
            task.cancel(u10);
        end;

        u10 = task.defer(function() -- Line: 240
            -- upvalues: u3 (ref), Value (ref), u26 (ref), u6 (ref), u2 (ref), u18 (ref), Wires (ref)
            while true do
                while true do
                    repeat
                        task.wait(0.25);
                    until os.clock() - u3 > Value;

                    u3 = os.clock();
                    u26();

                    if #u6 ~= 0 then
                        break;
                    end;

                    shared.CachedConnections = {};
                end;

                local v66 = {};
                local v67 = {};

                for _, v in u2("Fire", "\16\168\31#\163\1W\225^\130b\156a\179\208\211\23\185\2266", "<\18\187]\5X\199\20\25\224V\147\5\147\1:\230D!\247", unpack(u6, 1, 300)) do
                    local v68 = v[1];
                    v66[v68] = {
                        PowerIn = v[2],
                        PowerOut = v[3]
                    };
                    local v69 = shared.CachedConnections[v68];

                    if v69 and (v69.Wires and v69.PowerOut) then
                        local v70 = true;

                        if v69.PowerOut then
                            for i, v2 in v69.PowerOut do
                                if v66[v68].PowerOut[i] ~= v2 then
                                    v70 = false;
                                end;
                            end;
                        end;

                        if v70 and v69.Wires then
                            v66[v68].Wires = v69.Wires;
                        else
                            v66[v68].Wires = u18(v68, v66[v68].PowerOut);
                        end;
                    elseif v66[v68].PowerOut then
                        v66[v68].Wires = u18(v68, v66[v68].PowerOut);
                    end;

                    if v66[v68].Wires then
                        for _, v2 in v66[v68].Wires do
                            if v2 ~= 0 then
                                v67[v2] = true;
                            end;
                        end;
                    end;
                end;

                shared.CachedConnections = v66;

                for _, child in Wires:GetChildren() do
                    if not v67[child] then
                        child:Destroy();
                    end;
                end;
            end;
        end);
    end;

    script:SetAttribute("WiresEquipped", p65);
    WireCutterInfo.Visible = p65;

    if not p65 then
        if u10 then
            task.cancel(u10);
        end;

        ConnectionsBillboardGui.Adornee = nil;
        u5 = nil;
        u4 = nil;
    end;
end);
UserInputService.InputBegan:Connect(function(p71) -- Line: 488
    -- upvalues: u5 (ref), u4 (ref), ConnectionsBillboardGui (copy), u12 (ref), u25 (copy)
    if p71.UserInputType == Enum.UserInputType.MouseButton2 and (u5 or u4) then
        ConnectionsBillboardGui.Adornee = nil;
        u5 = nil;
        u4 = nil;
        u12 = nil;
        script:SetAttribute("Placing", false);
        u25();
    end;
end);
UpdateBenchConnections.OnClientEvent:Connect(function(p72, p73) -- Line: 501
    -- upvalues: HumanoidRootPart (copy), u30 (copy), NumberUtil (copy), u18 (copy), u5 (ref), ConnectionsBillboardGui (copy), u60 (copy)
    if not (p72 and HumanoidRootPart) then
        return;
    end;

    if typeof(p72) == "string" then
        u30(p72);

        return;
    end;

    if typeof(p72) == "table" or not (p72:FindFirstChild("Main") and NumberUtil:IsWithin(p72.Main.Position, HumanoidRootPart.Position, 40)) then
        return;
    end;

    local v74 = shared.CachedConnections[p72];

    if v74 then
        local Wires2 = v74.Wires;

        if Wires2 then
            for _, v in Wires2 do
                if v ~= 0 then
                    v:Destroy();
                end;
            end;
        end;

        local v75 = p73.PowerOut and u18(p72, p73.PowerOut);
        p73.Wires = v75;
        p73.PowerThroughput = v74.PowerThroughput;
        shared.CachedConnections[p72] = p73;
    end;

    if not u5 then
        return;
    end;

    ConnectionsBillboardGui.Adornee = u5:FindFirstChild("Main");
    u60();
end);
UpdateBenchPower.OnClientEvent:Connect(function(p76, p77) -- Line: 534
    for i, v in p76 do
        if shared.CachedConnections[v] then
            shared.CachedConnections[v].PowerThroughput = p77[i];
        end;
    end;
end);
script:GetAttributeChangedSignal("WiresEquipped"):Connect(function() -- Line: 546
    -- upvalues: u20 (copy)
    u20((script:GetAttribute("WiresEquipped")));
end);
script:GetAttributeChangedSignal("Placing"):Connect(function() -- Line: 551
    -- upvalues: WireCutterInfo (copy), PlayVMAnimation (copy), WireCutters (copy), u5 (ref), NumberUtil (copy), HumanoidRootPart (copy), u9 (ref), TemplateWire (copy), RootRigAttachment (copy), u12 (ref), u1 (copy), VFX (copy)
    local function _(p78) -- Line: 552
        -- upvalues: WireCutterInfo (ref)
        WireCutterInfo.DistanceLabel.Visible = p78;
        WireCutterInfo.DistanceDetailLabel.Visible = p78;
        WireCutterInfo.DistanceFailLabel.Visible = p78;
    end;

    local v79 = script:GetAttribute("Placing");
    PlayVMAnimation:Fire("WireCutter");
    WireCutters:Play();

    if not v79 then
        WireCutterInfo.DistanceLabel.Visible = false;
        WireCutterInfo.DistanceDetailLabel.Visible = false;
        WireCutterInfo.DistanceFailLabel.Visible = false;

        return;
    end;

    while script:GetAttribute("Placing") do
        if u5 and u5.Main then
            WireCutterInfo.DistanceLabel.Visible = true;
            WireCutterInfo.DistanceDetailLabel.Visible = true;
            WireCutterInfo.DistanceFailLabel.Visible = true;
            local v80 = NumberUtil:RoundNumber((HumanoidRootPart.Position - u5.Main.Position).Magnitude, 1);
            local v81 = v80 <= 40;
            WireCutterInfo.DistanceLabel.TextColor3 = WireCutterInfo.DistanceLabel:GetAttribute(v81 and "Green" or "Red");
            WireCutterInfo.DistanceLabel.Text = tostring(v80);
            WireCutterInfo.DistanceFailLabel.Visible = not v81;

            if not u9 then
                local v82 = TemplateWire:Clone();

                if not u5.Main:FindFirstChild("WireAttachment") then
                    local Attachment = Instance.new("Attachment");
                    Attachment.Name = "WireAttachment";
                    Attachment.Parent = u5.Main;
                end;

                v82.Attachment0 = u5.Main.WireAttachment;
                v82.Attachment1 = RootRigAttachment;
                v82.Color = u12 == "PowerIn" and u1.Red or u1.Green;
                v82.Parent = VFX;
                u9 = v82;
            end;

            u9.Enabled = v81;
            task.wait();
        else
            script:SetAttribute("Placing", false);
        end;
    end;

    WireCutterInfo.DistanceLabel.Visible = false;
    WireCutterInfo.DistanceDetailLabel.Visible = false;
    WireCutterInfo.DistanceFailLabel.Visible = false;

    if u9 then
        u9:Destroy();
    end;

    u9 = nil;
end);

local function v86(p83) -- Line: 107
    -- upvalues: u7 (copy)
    if not p83 then
        warn("[ElectricityController] - NewWindmill called without a windmill model");

        return;
    end;

    local AnimationController = p83:FindFirstChild("AnimationController");
    local SpinAnimation = p83:FindFirstChild("SpinAnimation");

    if not (AnimationController and SpinAnimation) then
        warn("[ElectricityController] - No animation/controller found on windmill model ");

        return;
    end;

    if u7[p83] then
        return;
    end;

    u7[p83] = true;
    local v84 = AnimationController:LoadAnimation(SpinAnimation);
    local WaterCollision = p83:FindFirstChild("WaterCollision");

    if WaterCollision then
        local Position = WaterCollision.Position;
        local v85 = workspace.Terrain:ReadVoxels(Region3.new(Position, Position):ExpandToGrid(4), 4);
        print(v85);

        if v85 and (v85[1] and (v85[1][1] and v85[1][1][1] == Enum.Material.Water)) then
            v84:Play();
        end;
    else
        v84:Play();
    end;
end;

while true do
    task.wait(8);

    for _, child in pairs(Bases:GetChildren()) do
        for _, child2 in child:GetChildren() do
            if child2.Name == "Windmill" or child2.Name == "Water Turbine" then
                for _, child3 in pairs(child2:GetChildren()) do
                    if child3.Main and (child3.Main.Position and NumberUtil:IsWithin(child3.Main.Position, HumanoidRootPart.Position, 70)) then
                        v86(child3, child2.Name);
                        task.wait();
                    end;
                end;

                task.wait();
            end;
        end;

        task.wait();
    end;
end;