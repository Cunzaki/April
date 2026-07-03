-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local SoundService = game:GetService("SoundService");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local Attachments = ReplicatedStorage:WaitForChild("Attachments");
ReplicatedStorage:WaitForChild("Remotes");
local PlayerSounds = ReplicatedStorage:WaitForChild("PlayerSounds");
local Items = require(Modules:WaitForChild("Items"));
local SoundModule = require(Modules:WaitForChild("SoundModule"));
local u21 = {
    WeldParts = function(p1, p2, p3, p4) -- Line: 27, Name: WeldParts
        local v5;

        if p4 == "All" then
            v5 = nil;
        else
            v5 = Instance.new("Weld");
            v5.Part0 = p3;
            v5.Part1 = p2;

            if type(p4) == "string" or not p4 then
                local v6 = CFrame.new(v5.Part0.Position);
                v5.C0 = v5.Part0.CFrame:inverse() * v6;
                v5.C1 = v5.Part1.CFrame:inverse() * v6;
            else
                v5.C0 = p4;
            end;

            v5.Parent = p2;
        end;

        p2.Anchored = false;
        p2.CanCollide = false;
        p2.Massless = true;

        return v5;
    end,

    WeldModel = function(p7, p8, p9, p10) -- Line: 49, Name: WeldModel
        for _, child in pairs(p8:GetChildren()) do
            if child:IsA("BasePart") then
                if p8.PrimaryPart ~= child then
                    p7:WeldParts(child, p8.PrimaryPart, p9);
                end;

                if p10 then
                    child.CanTouch = false;
                    child.CanQuery = false;
                end;
            end;
        end;
    end,

    WeldModelToPart = function(p11, p12, p13, p14, p15) -- Line: 61, Name: WeldModelToPart
        p11:WeldModel(p12, p15 and "" or "All");

        return p11:WeldParts(p12.PrimaryPart, p13, p14);
    end,

    FullyWeldModels = function(p16, p17, p18, p19) -- Line: 66, Name: FullyWeldModels
        local v20 = {};

        for _, child in pairs(p17:GetChildren()) do
            if child:IsA("Model") then
                if p18:FindFirstChild(child.Name) then
                    child.PrimaryPart = child.PrimaryPart or child:FindFirstChild("Middle");
                    local PrimaryPart = child.PrimaryPart;
                    p16:WeldModel(child, nil, p19);
                    child.Parent = p18;
                    p16:WeldParts(PrimaryPart, p18[child.Name], CFrame.new());
                    PrimaryPart.Transparency = 1;
                    PrimaryPart.Name = child.Name;
                    child.Name = p17.Name;
                    table.insert(v20, child);
                end;
            else
                child.Parent = p18;
            end;
        end;

        p17:Destroy();

        return v20;
    end
};

function u21.WeldAttachments(p22, p23, p24, p25, p26, p27, p28) -- Line: 87
    -- upvalues: Items (copy), Attachments (copy), u21 (copy), Players (copy), PlayerSounds (copy), SoundModule (copy), SoundService (copy)
    local v29 = type(p24) == "table";
    local v30 = {};
    local Attachments2 = p23:FindFirstChild("Attachments");
    local v31 = v29 and (p24.Attachments or {}) or {};
    local v32 = p23:FindFirstChild("Arrow") or p23:FindFirstChild("ArrowMain");

    if (p23:FindFirstChild("RocketRoot") or v32) and v29 then
        local Ammo = p24.Ammo;

        if Ammo and (Ammo.Amount > 0 and not p27) then
            p27 = Ammo.ID;
        end;

        if p27 then
            p27 = Items[p27];
        end;

        local v33 = p27 and p27.Name or "";

        for _, child in pairs(p23:GetChildren()) do
            local Name = child.Name;

            if Name ~= "RocketRoot" and (Name ~= "Arrow" and (Name ~= "ArrowMain" and (not v32 or Name:find("Arrow")))) and (v32 or Name:find("Rocket")) then
                local v34 = Name == v33;
                child.Transparency = v34 and 0 or 1;

                if Name == "Combustive Arrow" then
                    local ParticleHolder = child:FindFirstChild("ParticleHolder");

                    if ParticleHolder then
                        for _, child2 in pairs(ParticleHolder:GetChildren()) do
                            child2.Enabled = v34;
                        end;
                    end;
                end;
            end;
        end;
    end;

    if not (Attachments2 and v31) then
        return;
    end;

    local v35 = {};

    for _, v in pairs(v31) do
        local v36 = Items[v.ID];

        if not v36.MaxDurability or v.Durability > 0 then
            v35[v36.Name] = v;
        end;
    end;

    for _, child in pairs(Attachments2:GetChildren()) do
        if not v35[child.Name] then
            child:Destroy();
        end;
    end;

    local v37 = 0;

    for i, v in pairs(v35) do
        local v38 = Attachments2:FindFirstChild(i);
        local AttachmentType = Items[v.ID].AttachmentType;
        v37 = AttachmentType == "Sight" and 1 or v37;
        local v39;

        if AttachmentType == "Sight" then
            if v29 then
                v39 = p24.ID == 198 and true or p24.ID == 221;
            else
                v39 = v29;
            end;
        else
            v39 = false;
        end;

        local v40;

        if v38 then
            for i2, v2 in pairs({ "AimFront", "AimBack", "FlashPart" }) do
                if v38 then
                    v40 = v38:FindFirstChild(v2);
                else
                    v40 = v38;
                end;

                if v40 then
                    v30[v2] = v40;
                end;
            end;
        else
            local v41 = p23:FindFirstChild(AttachmentType .. "Main");
            local v42 = Attachments:FindFirstChild(i);

            if v42 and v41 then
                v38 = v42:Clone();

                if p28 and p28 ~= 1 then
                    v38:ScaleTo(p28);
                end;

                v38.PrimaryPart = v38:FindFirstChild("Main");
                local Reticle = v38:FindFirstChild("Reticle");

                if Reticle and p26 then
                    for _, child in pairs(Reticle:GetChildren()) do
                        child.Enabled = false;
                    end;
                end;

                local v43 = false;

                if v39 then
                    local M4Riser = v38:FindFirstChild("M4Riser");

                    if M4Riser then
                        M4Riser.Transparency = 0;
                        v43 = true;
                    end;
                end;

                u21:WeldModelToPart(v38, v41, v43 and CFrame.new(0, 0.08, 0) or CFrame.new());
                v38.Parent = Attachments2;

                for i2, v2 in pairs({ "AimFront", "AimBack", "FlashPart" }) do
                    if v38 then
                        v40 = v38:FindFirstChild(v2);
                    else
                        v40 = v38;
                    end;

                    if v40 then
                        v30[v2] = v40;
                    end;
                end;
            end;
        end;
    end;

    local SightHide = p23:FindFirstChild("SightHide");

    if SightHide then
        SightHide.Transparency = v37;
    end;

    local RailExtender = p23:FindFirstChild("RailExtender");

    if RailExtender then
        RailExtender.Transparency = v37 == 0 and 1 or 0;
    end;

    local Silencer = v35.Silencer;

    if v29 and not p25 then
        local Parent = p23.Parent;

        if Players:GetPlayerFromCharacter(Parent) then
            local PrimaryPart = Parent.PrimaryPart;
            local v44 = Items[p24.ID];

            if PrimaryPart and v44 then
                local v45 = PlayerSounds:FindFirstChild(v44.Name);

                if v45 then
                    local v46 = p24.Skin or "Default";
                    local v47 = SoundModule.CustomSoundSkins[v46];

                    for _, v in v47 and { "", (`_{v46}`) } or { "" } do
                        local v48 = `Shoot{v}`;
                        local v49 = PrimaryPart:FindFirstChild(v44.Name .. v48);
                        local v50 = v45:FindFirstChild(v48);

                        if v49 and v50 then
                            v49.RollOffMaxDistance = Silencer and 250 or v50.RollOffMaxDistance;
                            v49.Volume = v50.Volume * (Silencer and ((v == "" or type(v47) ~= "number") and 0.95 or v47 or 1) or 1);
                            local SilencedEffect = v49:FindFirstChild("SilencedEffect");

                            if Silencer and not SilencedEffect then
                                SoundService.SilencedEffect:Clone().Parent = v49;
                            elseif SilencedEffect and not Silencer then
                                SilencedEffect:Destroy();
                            end;
                        end;
                    end;
                end;
            end;
        end;
    end;

    return v30.AimFront, v30.AimBack, v30.FlashPart;
end;

return u21;