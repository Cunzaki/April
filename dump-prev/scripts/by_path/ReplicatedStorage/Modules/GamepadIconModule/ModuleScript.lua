-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local PlayerScripts_1 = game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts");
local u1 = PlayerScripts_1:FindFirstChild("PreferredInputController") or (PlayerScripts_1:WaitForChild("PreferredInputController", 5));
local tbl_upv_1 = {};
tbl_upv_1.ButtonA = {};
tbl_upv_1.ButtonB = {};
tbl_upv_1.ButtonX = {};
tbl_upv_1.ButtonY = {};
local tbl_upv_2 = {};
local tbl_upv_3 = {};
tbl_upv_2.GetIcon = function(a1)
    --[[
      name: GetIcon
      line: 25
      upvalues:
        u1 (copy, index: 1)
        tbl_upv_1 (copy, index: 2)
    ]]
    if (u1) then
        local _ = u1:GetAttribute("IsPlayStation");
    end;
    local v1 = tbl_upv_1[a1];
    if (v1) then
        local v2 = (u1 and "rbxasset://textures/ui/Controls/PlayStationController/") or "rbxasset://textures/ui/Controls/XboxController/";
        return v2 .. ((u1 and (v1.PS)) or (v1.Xbox));
    end;
    return "rbxasset://textures/ui/Controls/XboxController/" .. a1 .. "@2x.png";
end;
tbl_upv_2.Register = function(a1, a2)
    --[[
      name: Register
      line: 35
      upvalues:
        tbl_upv_3 (copy, index: 1)
        tbl_upv_2 (copy, index: 2)
    ]]
    table.insert(tbl_upv_3, {Instance = a1, Button = a2});
    a1.Image = tbl_upv_2.GetIcon(a2);
end;
tbl_upv_2.UpdateAll = function()
    --[[
      name: UpdateAll
      line: 40
      upvalues:
        tbl_upv_3 (copy, index: 1)
        tbl_upv_2 (copy, index: 2)
    ]]
    for n_1 = #tbl_upv_3, 1, -1 do
        local v3;
        v3 = tbl_upv_3[n_1];
        if (not (v3.Instance)) then
            table.remove(tbl_upv_3, n_1);
            continue;
        end;
        if (v3.Instance.Parent) then
            v3.Instance.Image = tbl_upv_2.GetIcon(v3.Button);
        else
            table.remove(tbl_upv_3, n_1);
        end;
    end;
end;
if (u1) then
    u1:GetAttributeChangedSignal("IsPlayStation"):Connect(tbl_upv_2.UpdateAll);
end;
return tbl_upv_2;