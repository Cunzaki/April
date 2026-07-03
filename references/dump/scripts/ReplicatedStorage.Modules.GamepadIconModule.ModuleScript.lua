-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local PlayerScripts = game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts");
local u1 = PlayerScripts:FindFirstChild("PreferredInputController") or PlayerScripts:WaitForChild("PreferredInputController", 5);
local u2 = {
    ButtonA = {
        Xbox = "ButtonA@2x.png",
        PS = "ButtonCross@2x.png"
    },
    ButtonB = {
        Xbox = "ButtonB@2x.png",
        PS = "ButtonCircle@2x.png"
    },
    ButtonX = {
        Xbox = "ButtonX@2x.png",
        PS = "ButtonSquare@2x.png"
    },
    ButtonY = {
        Xbox = "ButtonY@2x.png",
        PS = "ButtonTriangle@2x.png"
    }
};
local u3 = {};
local u4 = {};

function u3.GetIcon(p5) -- Line: 25
    -- upvalues: u1 (copy), u2 (copy)
    local v6 = u1 and u1:GetAttribute("IsPlayStation");
    local v7 = u2[p5];

    if v7 then
        return (v6 and "rbxasset://textures/ui/Controls/PlayStationController/" or "rbxasset://textures/ui/Controls/XboxController/") .. (v6 and v7.PS or v7.Xbox);
    end;

    return "rbxasset://textures/ui/Controls/XboxController/" .. p5 .. "@2x.png";
end;

function u3.Register(p8, p9) -- Line: 35
    -- upvalues: u4 (copy), u3 (copy)
    table.insert(u4, {
        Instance = p8,
        Button = p9
    });
    p8.Image = u3.GetIcon(p9);
end;

function u3.UpdateAll() -- Line: 40
    -- upvalues: u4 (copy), u3 (copy)
    for i = #u4, 1, -1 do
        local v10 = u4[i];

        if v10.Instance and v10.Instance.Parent then
            v10.Instance.Image = u3.GetIcon(v10.Button);
        else
            table.remove(u4, i);
        end;
    end;
end;

if u1 then
    u1:GetAttributeChangedSignal("IsPlayStation"):Connect(u3.UpdateAll);
end;

return u3;